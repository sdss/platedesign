import numpy as np
import fitsio
import os
import pydl.pydlutils.spheregroup as spheregroup


def _radec_to_xyz(ra, dec):
    """Converts ra and dec to Cartesian coordinates

    Parameters
    ----------
    ra: np.float64
        ndarray with right ascension in degrees
    dec: np.float64
        ndarray with declination in degrees

    Returns
    -----
    x: np.float64
        ndarray with X on unit sphere
    y: np.float64
        ndarray with Y on unit sphere
    z: np.float64
        ndarray with Z on unit sphere
    """
    ra_rad = ra * np.pi /180.
    dec_rad = dec * np.pi /180.
    x = np.cos(dec_rad) * np.cos(ra_rad)
    y = np.cos(dec_rad) * np.sin(ra_rad)
    z = np.sin(dec_rad)
    return (x, y, z)

def _angle_sep(ra1, dec1, ra2, dec2):
    """Calculates angle separating two RA, Dec positions

    Parameters
    ----------
    ra1: np.float64
        right ascension in degrees
    dec1: np.float64
        declination in degrees
    ra2: np.float64
        right ascension in degrees
    dec2: np.float64
        declination in degrees

    Returns
    -----
    sep: np.float64
        great circle separation in degrees
    """
    (x1, y1, z1) = _radec_to_xyz(ra1, dec1)
    (x2, y2, z2) = _radec_to_xyz(ra2, dec2)
    xcross = y1 * z2 - y2 * z1
    ycross = - x1 * z2 + x2 * z1
    zcross = x1 * y2 - x2 * y1
    cross = np.sqrt(xcross**2 + ycross**2 + zcross**2)
    dot = x1 * x2 + y1 * y2 + z1*z2
    return np.arctan(cross / dot) * 180. / np.pi

def _partition_filename(ira, idec, dr='dr1'):
    """Return file name for partition file

    Parameters
    ----------
    ira:  np.int32
        integer indicating RA bin
    idec:  np.int32
        integer indicating Dec bin
    dr : string
        name of data release (default 'dr1')

    Returns
    -----
    filename: string
        full path and name of partition file
    """
    out_path= os.path.join(os.getenv('GAIA_DATA'), dr,
                           'gaia_source', 'fits_sorted')
    filename = 'gaia-'+dr+'-'+str(ira)+'-'+str(idec)+'.fits'
    return os.path.join(out_path, filename)

def _partition_gaia(filename=None, dr='dr1'):
    """Partition a Gaia source FITS files

    Parameters
    ----------
    filename: string
        base name of partition file
    dr : string
        name of data release (default 'dr1')

    Comments
    --------
    Breaks file into RA and Dec bins. Creates or adds to Gaia partition files..
    """
    gaia = fitsio.read(filename, ext=1)
    ira = np.int32(gaia['ra'])
    idec = np.int32((gaia['dec'] + 90.))
    isp = np.nonzero(idec == 0)[0]
    ira[isp] = 0
    inp = np.nonzero(idec == 179)[0]
    ira[inp] = 0
    ifile = idec * 360 + ira
    uniqs, iuniqs = np.unique(ifile, return_index=True)
    for iuniq in iuniqs:
        cra = ira[iuniq]
        cdec = idec[iuniq]
        cgaia = np.nonzero((ira == cra) & (idec == cdec))[0]
        filename = _partition_filename(cra, cdec, dr=dr)
        if(os.path.isfile(filename)):
            fits = fitsio.FITS(filename, 'rw')
            fits[-1].append(gaia[cgaia])
            fits.close()
        else:
            fitsio.write(filename, gaia[cgaia])
    return

def gaia_run(dr='dr1'):
    """Partition all Gaia source fits files

    Parameters
    ----------
    dr : string
        name of data release (default 'dr1')

    Comments
    --------
    For all Gaia source file, partitions them into RA/Dec bins.
    This makes it more convenient to read them in by RA/Dec.
    The function gaia_read() uses these files.
    """
    gaia_path= os.path.join(os.getenv('GAIA_DATA'), dr,
                            'gaia_source', 'fits')
    out_path= os.path.join(os.getenv('GAIA_DATA'), dr,
                           'gaia_source', 'fits_sorted')
    gaia_files = [f for f in os.listdir(gaia_path)
                  if (os.path.isfile(os.path.join(gaia_path, f)) and
                      ("GaiaSource_" in f))]
    dtype= np.dtype([('ira', np.int32),
                     ('idec', np.int32),
                     ('racen', np.float64),
                     ('deccen', np.float64)])
    data= np.zeros(0, dtype=dtype)
    tmp_data= np.zeros(1, dtype=dtype)
    tmp_data['ira'] = 0
    tmp_data['idec'] = 0
    tmp_data['racen'] = 0.
    tmp_data['deccen'] = -89.99
    data = np.append(data, tmp_data)
    tmp_data['ira'] = 0
    tmp_data['idec'] = 179
    tmp_data['racen'] = 0.
    tmp_data['deccen'] = 89.99
    data = np.append(data, tmp_data)
    for idec in np.arange(178) + 1:
        for ira in np.arange(360):
            tmp_data['ira'] = ira
            tmp_data['idec'] = idec
            tmp_data['racen'] = np.float64(ira) + 0.5
            tmp_data['deccen'] = -90. + np.float64(idec) + 0.5
            data = np.append(data, tmp_data)
    fitsio.write(os.path.join(out_path, 'gaia-index.fits'), data,
                 clobber=True)
    for gaia_file in gaia_files:
        print gaia_file
        filename = os.path.join(gaia_path, gaia_file)
        _partition_gaia(filename)
    return

def gaia_read(ra, dec, radius, dr='dr1'):
    """Partition all Gaia source fits files

    Parameters
    ----------
    ra : np.float64
        right ascension to search around (degrees, J2000)
    dec : np.float64
        declination to search around (degrees, J2000)
    radius : np.float64
        radius of search (degrees)
    dr : string
        name of data release (default 'dr1')

    Returns
    -------
    data : ndarray
        array with Gaia data for matching objects

    Comments
    --------
    Requires data in $GAIA_DATA to have been processed by gaia_run()
    into files partitioned by RA/Dec
    """
    gaia_path= os.path.join(os.getenv('GAIA_DATA'), dr,
                            'gaia_source', 'fits_sorted')
    gaia_index = fitsio.read(os.path.join(gaia_path, 'gaia-index.fits'))
    ra_arr = np.array([np.float64(ra)])
    dec_arr = np.array([np.float64(dec)])
    (iindex, i0, dindex) = spheregroup.spherematch(gaia_index['racen'],
                                                   gaia_index['deccen'],
                                                   ra_arr, dec_arr,
                                                   np.float64(radius) + 1.,
                                                   maxmatch=0)
    if(len(iindex) == 0):
        return None
    data = None
    for (ira, idec) in zip(gaia_index['ira'][iindex],
                           gaia_index['idec'][iindex]):
        filename = _partition_filename(ira, idec)
        if(os.path.isfile(filename)):
            gaia = fitsio.read(filename, ext=1)
            (igaia, i0, dgaia) = spheregroup.spherematch(gaia['ra'],
                                                         gaia['dec'],
                                                         ra_arr, dec_arr,
                                                         np.float64(radius),
                                                         maxmatch=0)
            if(len(igaia) > 0):
                tmp_data = gaia[igaia]
                if(data is None):
                    data = np.zeros(0, dtype=gaia[0].dtype)
                data = np.append(data, tmp_data)
    return data
