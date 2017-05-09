import os
import numpy as np
import copy
import matplotlib.pyplot as plt
import pydl.pydlutils.yanny as yanny
from platedesign.fanuc.gcodes import Gcodes
from platedesign.fanuc.optimize_path import optimize_path

# STILL NEED TO TEST Z, ZR, etc; actually, test all coords


def _fanuc_length(x=None, y=None):
    length = 0.
    if(len(x) == 1):
        return length
    for i in np.arange(len(x) - 1):
        delta = np.sqrt((x[i + 1] - x[i])**2 + (y[i + 1] - y[i])**2)
        length = length + delta
    return(length)


def _fanuc_separate(plugmap=None):
    """Separate plug map holes by type

    Parameters
    ----------
    plugmap : Yanny file object
        plPlugMapP contents

    Returns
    -------
    (objects, lighttrap, alignment) : Yanny file object
        plPlugMapP contents sorted into three types

    Notes
    -----

    Separates into LIGHT_TRAP, ALIGNMENT, and other classes (excluding
    the center hole from "other" and including it as LIGHT_TRAP).
    """
    holeType = copy.deepcopy(plugmap['PLUGMAPOBJ']['holeType'])
    iscenter = ((plugmap['PLUGMAPOBJ']['holeType'] == b'QUALITY') &
                (plugmap['PLUGMAPOBJ']['objId'][:, 0] == 0))

    ilighttrap = np.nonzero((holeType == b'LIGHT_TRAP') |
                            (iscenter == np.bool(True)))[0]
    plugmap_lighttrap = plugmap['PLUGMAPOBJ'][ilighttrap]

    ialignment = np.nonzero((holeType == b'ALIGNMENT') &
                            (iscenter == np.bool(False)))[0]
    plugmap_alignment = plugmap['PLUGMAPOBJ'][ialignment]

    iother = np.nonzero((holeType != b'ALIGNMENT') &
                        (holeType != b'LIGHT_TRAP') &
                        (iscenter == np.bool(False)))[0]
    plugmap_other = plugmap['PLUGMAPOBJ'][iother]

    return (plugmap_other, plugmap_lighttrap, plugmap_alignment)


def _fanuc_header(gcodes=None, plate=None, param=None,
                  fanuc_name=None, plug_name=None):
    """Create Fanuc header

    Parameters
    ----------
    gcodes : Gcodes object
        Contains information about how to write CNC code
    plate : Yanny object
        row entry in plObs file
    param : Yanny object
        plParam file object
    plug_name : str
        plPlugMapP file name
    fanuc_name : str
        name of Fanuc file being written to

    Returns
    -------
    (objects, lighttrap, alignment) : Yanny file object
        plPlugMapP contents sorted into three types

    Notes
    -----

    Separates into LIGHT_TRAP, ALIGNMENT, and other classes (excluding
    the center hole from "other" and including it as LIGHT_TRAP).
    """
    plateId = plate['plateId']
    tempShop = np.float32(param['tempShop'])
    tempShopF = 32. + tempShop * 1.8
    return(gcodes.header(plateId=plateId, tempShopF=tempShopF,
                         plug_name=plug_name, fanuc_name=fanuc_name))


def _fanuc_xyz(plugmap=None, plate=None, param=None):
    """Return CNC X, Y, Z positions

    Parameters
    ----------
    plugmap : Yanny object
        plPlugMapP file object for this plate
    plate : Yanny object
        row entry in plObs file
    param : Yanny object
        plParam file object

    Returns
    -------
    (x, y, z, zr) : np.float32
        arrays containing positions necessary for CNC, in inches

    Notes
    -----

    Applies distortion correction for plate bending on mandrel, and
    thermal expansion correction. Converts plugmap mm information into
    inches.
    """
    deltaT = np.float32(param['tempShop']) - np.float32(plate['temp'])
    thermExpFactor = np.float32(param['thermalExpand']) * deltaT

    # Note that we do not apply parity or X/Y center shifts, even
    # though these are parameters in the plParam file. This is the
    # same as the Fanuc-generating code in the original plate product;
    # the plDrillPos values *did* have those applied in that code,
    # though it never mattered in practice.
    x = copy.deepcopy(plugmap['xFocal'])
    y = copy.deepcopy(plugmap['yFocal'])
    r = np.sqrt(x**2 + y**2)

    # Calculate radial correction for plate bending
    correction = np.zeros(len(plugmap))
    bendDistCoeff = np.float32(param['bendDistCoeff'].split())
    for i in np.arange(len(bendDistCoeff)):
        correction = correction + bendDistCoeff[i] * r**(i)

    # Calulate and apply correction to Z position for plate bending
    shape = np.zeros(len(plugmap))
    plateShapeCoeff = np.float32(param['plateShapeCoeff'].split())
    for i in np.arange(len(bendDistCoeff)):
        shape = shape + plateShapeCoeff[i] * r**(i)
    z = shape

    # Apply correction to radial position for plate bending
    r = (1. + thermExpFactor) * r - correction

    # Now check for holes outside the radius
    ibad = np.nonzero(r > np.float32(param['maxRadius']))[0]
    if(len(ibad) > 0):
        print("fanuc: some holes are further than {maxRadius} mm".format(maxRadius=param['maxRadius']))
        exit()

    # For any holes not exactly at center, calculate X and Y
    igt0 = np.nonzero(r > 0)[0]
    correction[igt0] = correction[igt0] / r[igt0]
    x[igt0] = x[igt0] + (thermExpFactor - correction[igt0]) * x[igt0]
    y[igt0] = y[igt0] + (thermExpFactor - correction[igt0]) * y[igt0]

    # Convert to inches
    x = x / 25.4
    y = y / 25.4
    z_original = z / 25.4

    # Apply offset to Z position
    z = z_original + np.float32(param['ZOffset']) / 25.4
    zr = z_original + np.float32(param['ZOffsetR']) / 25.4

    return(x, y, z, zr)


def _fanuc_measure(gcodes=None, plugmap=None, plate=None, param=None,
                   xdrill=None, ydrill=None):
    """Return CMM X, Y, and diameters for measurement

    Parameters
    ----------
    gcodes : Gcodes object
        Contains information about how to write CNC code
    plugmap : Yanny object
        plPlugMapP file object for this plate
    plate : Yanny object
        row entry in plObs file
    param : Yanny object
        plParam file object
    xdrill : np.float32
        array of X drilling locations (inches)
    ydrill : np.float32
        array of Y drilling locations (inches)

    Returns
    -------
    (xflat, yflat, diameter) : np.float32
        arrays containing positions necessary for CMM, in inches,
        and hole diameter, in mm

    Notes
    -----

    Applies distortion correction for plate bending on mandrel, and
    thermal expansion correction. Converts plugmap mm information into
    inches.
    """

    # Apply center and parity (in practice this is always the identity
    # matrix) before the radial correction
    xflat = xdrill * 25.4 - (np.float32(param['flatDistXcenter']) *
                             np.float32(param['flatDistParity']))
    yflat = ydrill * 25.4 - np.float32(param['flatDistYcenter'])
    rflat = np.sqrt(xflat**2 + yflat**2)
    pa = np.arctan2(xflat, yflat)

    # Calculate radial correction to get to flat plate
    correction = np.zeros(len(xdrill))
    flatDistCoeff = np.float32(param['flatDistCoeff'].split())
    for i in np.arange(len(flatDistCoeff)):
        correction = correction + flatDistCoeff[i] * rflat**(i)
    rflat = rflat - correction

    # Now apply correction and get flat conditions
    xflat = rflat * np.sin(pa) + (np.float32(param['flatDistXcenter']) *
                                  np.float32(param['flatDistParity']))
    yflat = rflat * np.cos(pa) + np.float32(param['flatDistYcenter'])

    # Decide on hole diameter
    holediam = np.zeros(len(xflat))
    for i in np.arange(len(holediam)):
        holediam[i] = gcodes.holediam(holetype=plugmap['holeType'][i].decode(),
                                      objId=plugmap['objId'][i])

    return(xflat, yflat, holediam)


def _fanuc_codes(gcodes=None, x=None, y=None, z=None, zr=None,
                 objId=None, drillSeq=1):
    """Write codes for list of holes

    Parameters
    ----------
    gcodes : Gcodes object
        information about how to write CNC for this type of plate
    x : np.float32
        array of X positions to drill
    y : np.float32
        array of Y positions to drill
    z : np.float32
        array of Z positions to drill
    zr : np.float32
        an offset set of Z positions
    objId : np.int32
        [5]-array of object identifiers (only meaningful
        for SDSS imaging targets )
    drillSeq : np.int32
        drilling sequence number (used to select bit)
    """
    codes = gcodes.first(cx=x[0], cy=y[0], cz=z[0], czr=zr[0],
                         drillSeq=drillSeq)
    for cx, cy, cz, czr, cobjId in zip(x, y, z, zr, objId):
        code = gcodes.hole(cx=cx, cy=cy, cz=cz, czr=czr, objId=cobjId)
        codes += code
    return(codes)


def _fanuc_drillpos(gcodes=None, plugmap=None, plate=None, param=None):
    """Write codes for list of holes

    Parameters
    ----------
    gcodes : Gcodes object
        information about how to write CNC for this type of plate
    plugmap : Yanny object
        plPlugMapP file object for this plate
    plate : Yanny object
        row entry in plObs file
    param : Yanny object
        plParam file object

    Notes
    -----
    Writes plDrillPos and plMeas files
    """
    drillpos_template = 'plDrillPos-{plate}.par'
    meas_template = 'plMeas-{plate}.par'
    drillpos_name = drillpos_template.format(plate=plate['plateId'])
    meas_name = meas_template.format(plate=plate['plateId'])

    qdrill = _fanuc_xyz(plugmap=plugmap['PLUGMAPOBJ'],
                        plate=plate, param=param)
    (xdrill, ydrill, zdrill, zrdrill) = qdrill
    qmeasure = _fanuc_measure(gcodes, plugmap=plugmap['PLUGMAPOBJ'],
                              plate=plate, param=param,
                              xdrill=xdrill, ydrill=ydrill)
    (xflat, yflat, diameter) = qmeasure
    dtype_drillpos = np.dtype([('holeType', np.str_, 20),
                               ('objId', np.int32, 5),
                               ('ra', np.float64),
                               ('dec', np.float64),
                               ('xFocal', np.float64),
                               ('yFocal', np.float64),
                               ('xFlat', np.float64),
                               ('yFlat', np.float64),
                               ('xDrill', np.float64),
                               ('yDrill', np.float64),
                               ('zDrill', np.float64),
                               ('holeDiam', np.float64)])
    enum_holetype = ('HOLETYPE', ('OBJECT', 'COHERENT_SKY', 'GUIDE',
                                  'LIGHT_TRAP', 'ALIGNMENT', 'QUALITY',
                                  'MANGA', 'MANGA_SINGLE',
                                  'MANGA_ALIGNMENT'))
    enums_drillpos = {'holeType': enum_holetype}
    drillpos = np.zeros(len(xdrill), dtype=dtype_drillpos)
    drillpos['holeType'] = plugmap['PLUGMAPOBJ']['holeType']
    drillpos['objId'] = plugmap['PLUGMAPOBJ']['objId']
    drillpos['ra'] = plugmap['PLUGMAPOBJ']['ra']
    drillpos['dec'] = plugmap['PLUGMAPOBJ']['dec']
    drillpos['xFocal'] = plugmap['PLUGMAPOBJ']['xFocal']
    drillpos['yFocal'] = plugmap['PLUGMAPOBJ']['yFocal']
    drillpos['xFlat'] = xflat
    drillpos['yFlat'] = yflat
    drillpos['xDrill'] = xdrill
    drillpos['yDrill'] = ydrill
    drillpos['zDrill'] = zdrill
    drillpos['holeDiam'] = diameter
    hdr = dict()
    hdr['plateId'] = plate['plateId']
    hdr['raCen'] = plugmap['raCen']
    hdr['decCen'] = plugmap['decCen']
    hdr['theta'] = plugmap['theta']
    if(os.path.isfile(drillpos_name)):
        os.remove(drillpos_name)
    yanny.write_ndarray_to_yanny(drillpos_name, drillpos,
                                 structnames='DRILLPOS',
                                 enums=enums_drillpos,
                                 hdr=hdr)

    mfp = open(meas_name, 'w')
    line_template = "{objId[0]:d} {objId[1]:d} {objId[2]:d} {objId[3]:d} {objId[4]:d}, {xFlat:f}, {yFlat:f}, {holeDiam:f}\n"
    for dpos in drillpos:
        line = line_template.format(objId=dpos['objId'],
                                    xFlat=dpos['xFlat'],
                                    yFlat=dpos['yFlat'],
                                    holeDiam=dpos['holeDiam'])
        mfp.write(line)
    mfp.close()


def fanuc(mode='boss', planfile=None):
    """Create plFanuc file for plates

    Parameters
    ----------
    planfile : str
        name of plan file (e.g. 'plPlan-test.par')
    mode : str
        plate run type ('boss', 'manga', or 'apogee_south'; default 'boss')

    Notes
    -----

    Creates plFanucUnadjusted files with CNC code for drilling SDSS plates.

    """

    # Read in files
    plan = yanny.yanny(planfile)
    parametersdir = plan['parametersDir']
    paramfile = os.path.join(parametersdir, plan['parameters'])
    param = yanny.yanny(paramfile)
    obs = yanny.yanny(plan['plObsFile'])

    # Set up templates for CNC code
    gcodes = Gcodes(mode=mode, paramfile=paramfile,
                    parametersdir=parametersdir)

    # Loop through the plates
    plug_dir = plan['outFileDir']
    plug_template = 'plPlugMapP-{plate}.par'
    fanuc_template = 'plFanucUnadjusted-{plate}.par.test'
    png_template = 'plFanucUnadjusted-{plate}.png'
    for plate in obs['PLOBS']:
        plug_name = plug_template.format(plate=plate['plateId'])
        fanuc_name = fanuc_template.format(plate=plate['plateId'])
        png_name = png_template.format(plate=plate['plateId'])

        # Read in plug map file
        plugmap = yanny.yanny(os.path.join(plug_dir, plug_name))

        # Make plDrillPos file
        _fanuc_drillpos(gcodes=gcodes, plugmap=plugmap,
                        plate=plate, param=param)

        # Separate into types for sorting
        (objects, lighttraps, alignment) = _fanuc_separate(plugmap)

        # Open Fanuc file and write header
        ffp = open(fanuc_name, 'w')
        hdr = _fanuc_header(gcodes=gcodes, plate=plate, param=param,
                            fanuc_name=fanuc_name, plug_name=plug_name)
        ffp.write(hdr)

        # Open drilling path PNG
        plt.figure(dpi=150, figsize=(5, 5))
        plt.title("plate {plateId}".format(plateId=plate['plateId']))
        plt.xlim((-16., 16.))
        plt.ylim((-16., 16.))
        plt.xlabel("X drill")
        plt.ylabel("Y drill")

        # Now start in with science-sized holes
        iorder = optimize_path(objects['xFocal'], objects['yFocal'])
        ffp.write(gcodes.objects)
        (x, y, z, zr) = _fanuc_xyz(plugmap=objects[iorder], plate=plate,
                                   param=param)
        length = _fanuc_length(x, y)
        codes = _fanuc_codes(gcodes=gcodes, x=x, y=y, z=z, zr=zr,
                             objId=objects['objId'][iorder], drillSeq=1)
        ffp.write(codes)
        label = "object holes ({length:>.0f} inches)".format(length=length)
        plt.plot(x, y, color='red', label=label)

        ffp.write(gcodes.lighttrap)
        iorder = optimize_path(lighttraps['xFocal'], lighttraps['yFocal'])
        (x, y, z, zr) = _fanuc_xyz(plugmap=lighttraps[iorder], plate=plate,
                                   param=param)
        codes = _fanuc_codes(gcodes=gcodes, x=x, y=y, z=z, zr=zr,
                             objId=lighttraps['objId'][iorder], drillSeq=2)
        ffp.write(codes)
        length = _fanuc_length(x, y)
        label = "traps/center ({length:>.0f} inches)".format(length=length)
        plt.plot(x, y, color='green', label=label)

        ffp.write(gcodes.align)
        iorder = optimize_path(alignment['xFocal'], alignment['yFocal'])
        (x, y, z, zr) = _fanuc_xyz(plugmap=alignment[iorder], plate=plate,
                                   param=param)
        codes = _fanuc_codes(gcodes=gcodes, x=x, y=y, z=z, zr=zr,
                             objId=alignment['objId'][iorder], drillSeq=3)
        ffp.write(codes)
        length = _fanuc_length(x, y)
        label = "alignment ({length:>.0f} inches)".format(length=length)
        plt.plot(x, y, color='blue', label=label)

        completion = gcodes.completion(plateId=plate['plateId'])
        ffp.write(completion)
        ffp.write("%\n")

        ffp.close()

        plt.legend(fontsize=6)
        plt.savefig(png_name)
