from platedesign.observatory import Observatory
import tempfile
import ctypes
import os
import numpy as np
import pydl.pydlutils.yanny as yanny
import subprocess


def write_plugprob(xtarget=None, ytarget=None, xfiber=None, yfiber=None,
                   fiberblockid=None, used=None, toblock=None,
                   nMax=None, limitDegree=0.8148, fiberTargetsPossible=None,
                   minAvailInBlock=None, minFibersInBlock=None,
                   maxFibersInBlock=None, blockcenx=None, blockceny=None,
                   blockconstrain=False, probfile=None, noycost=False,
                   blockylimits=None):
    """Determines positions of stars in an image.

    Parameters
    ----------
    xtarget, ytarget : np.float32
        ndarray with target locations in degrees

    Notes
    -----
    Calls write_plugprob.c in libdimage.so

    """

    # Get write_plugprob C function
    fiber_lib = ctypes.cdll.LoadLibrary(os.path.join(os.getenv("PLATEDESIGN_DIR"), "lib", "libfiber.so"))
    write_plugprob_function = fiber_lib.write_plugprob

    nTargets = ctypes.c_int(len(xtarget))
    xtarget_ptr = xtarget.ctypes.data_as(ctypes.POINTER(ctypes.c_double))
    ytarget_ptr = ytarget.ctypes.data_as(ctypes.POINTER(ctypes.c_double))

    nFibers = ctypes.c_int(len(xfiber))
    xfiber_ptr = xfiber.ctypes.data_as(ctypes.POINTER(ctypes.c_double))
    yfiber_ptr = yfiber.ctypes.data_as(ctypes.POINTER(ctypes.c_double))

    fiberblockid_ptr = fiberblockid.ctypes.data_as(ctypes.POINTER(ctypes.
                                                                  c_int))
    used_ptr = used.ctypes.data_as(ctypes.POINTER(ctypes.c_int))
    toblock_ptr = toblock.ctypes.data_as(ctypes.POINTER(ctypes.c_int))

    if(nMax is not None):
        nMax_int = ctypes.c_int(nMax)
    else:
        nMax_int = nFibers

    limitDegree_ptr = ctypes.c_double(limitDegree)

    if(fiberTargetsPossible is not None):
        inputPossible_int = ctypes.c_int(1)
    else:
        fiberTargetsPossible = np.zeros(len(xfiber) * len(xtarget),
                                        dtype=np.int32)
        inputPossible_int = ctypes.c_int(0)
    fiberTargetsPossible_ptr = fiberTargetsPossible.ctypes.data_as(ctypes.POINTER(ctypes.c_int))

    minAvailInBlock_ptr = ctypes.c_int(minAvailInBlock)
    minFibersInBlock_ptr = ctypes.c_int(minFibersInBlock)
    maxFibersInBlock_ptr = ctypes.c_int(maxFibersInBlock)

    nBlocks = ctypes.c_int(len(blockcenx))
    blockcenx_ptr = blockcenx.ctypes.data_as(ctypes.POINTER(ctypes.c_double))
    blockceny_ptr = blockceny.ctypes.data_as(ctypes.POINTER(ctypes.c_double))

    if(blockconstrain):
        blockconstrain_int = ctypes.c_int(1)
    else:
        blockconstrain_int = ctypes.c_int(0)

    probfile_ptr = ctypes.c_char_p(probfile)

    if(noycost):
        noycost_int = ctypes.c_int(1)
    else:
        noycost_int = ctypes.c_int(0)

    blockylimits_ptr = blockylimits.ctypes.data_as(ctypes.POINTER(ctypes.c_double))

    write_plugprob_function(xtarget_ptr, ytarget_ptr, nTargets,
                            xfiber_ptr, yfiber_ptr,
                            fiberblockid_ptr, used_ptr, toblock_ptr,
                            nFibers, nMax_int, limitDegree_ptr,
                            fiberTargetsPossible_ptr, inputPossible_int,
                            minAvailInBlock_ptr, minFibersInBlock_ptr,
                            maxFibersInBlock_ptr,
                            blockcenx_ptr, blockceny_ptr,
                            blockconstrain_int, nBlocks,
                            probfile_ptr, noycost_int, blockylimits_ptr)


def read_plugprob(xtarget=None, ytarget=None, fiberblockid=None,
                  ansfile=None):
    """Determines positions of stars in an image.

    Parameters
    ----------
    xtarget, ytarget : np.float32
        ndarray with target locations in degrees

    Returns
    -------
    (targetFiber, targetBlock)

    Notes
    -----
    Calls write_plugprob.c in libdimage.so

    """

    # Get write_plugprob C function
    fiber_lib = ctypes.cdll.LoadLibrary(os.path.join(os.getenv("PLATEDESIGN_DIR"), "lib", "libfiber.so"))
    read_plugprob_function = fiber_lib.read_plugprob

    nTargets = ctypes.c_int(len(xtarget))
    xtarget_ptr = xtarget.ctypes.data_as(ctypes.POINTER(ctypes.c_double))
    ytarget_ptr = xtarget.ctypes.data_as(ctypes.POINTER(ctypes.c_double))

    nFibers = ctypes.c_int(len(fiberblockid))
    fiberblockid_ptr = fiberblockid.ctypes.data_as(ctypes.POINTER(ctypes.c_double))

    targetFiber = np.zeros(np.int32(nTargets), dtype=np.int32)
    targetBlock = np.zeros(np.int32(nTargets), dtype=np.int32)
    targetFiber_ptr = targetFiber.ctypes.data_as(ctypes.POINTER(ctypes.c_int))
    targetBlock_ptr = targetBlock.ctypes.data_as(ctypes.POINTER(ctypes.c_int))

    ansfile_ptr = ctypes.c_char_p(ansfile)

    quiet = ctypes.c_int(0)

    read_plugprob_function(xtarget_ptr, ytarget_ptr,
                           targetFiber_ptr, targetBlock_ptr,
                           nTargets, fiberblockid_ptr, nFibers,
                           quiet, ansfile_ptr)

    return (targetFiber, targetBlock)


def boss_reachcheck(xfiber=None, yfiber=None, xhole=None, yhole=None,
                    stretch=0):
    """Checks reach of a fiber.

    Parameters
    ----------
    xfiber, yfiber : np.float32
       starting point of a single fiber
    xhole, yhole : np.float32
       ndarray, positions of prospective holes relative to plate center

    Returns
    -------
    inreach : np.bool
       ndarray, whether each hole is within reach

    -----
    Calls write_plugprob.c in libdimage.so
    """

    xcm = np.array([25., 20., 15., 10., 5., 0., - 5., - 10., - 15., - 17.,
                    - 17., - 17., - 15., - 10., - 5., 0., 5., 10., 15., 20.,
                    25.])
    ycm = np.array([0., 15., 19., 21., 22., 22., 22., 20., 15., 2., 0.,
                    - 2., - 15., - 20., - 22., - 22., - 22., - 21., - 19.,
                    - 15., 0.])
    xmm = 10. * xcm
    ymm = 10. * ycm
    xval = xmm
    yval = ymm

    rval = np.sqrt(xval**2 + yval**2)
    thval = (np.arctan2(yval, xval) + np.pi * 2.) % (np.pi * 2.)
    thval[len(thval) - 1] = 2. * np.pi

    xoff = xhole - xfiber
    yoff = yhole - yfiber

    if(yfiber < 0.):
        xoff = - xoff

    roff = np.sqrt(xoff**2 + yoff**2)
    thoff = (np.arctan2(yoff, xoff) + np.pi * 2.) % (np.pi * 2.)

    rreach = (np.interp(thoff, thval, rval) + stretch * 25.4)

    return (rreach > roff)


def sdss_plugprob(xtarget=None, ytarget=None, minavail=None,
                  mininblock=0, maxinblock=6, fiberused=None,
                  nmax=None, limitDegree=0.8148, toblock=None,
                  blockfile=None, noycost=False,
                  ylimits=None, reachfunc=None, stretch=0,
                  observatory=None, blockcenx=None, blockceny=None):
    """Determines positions of stars in an image.

    Parameters
    ----------
    xtarget, ytarget : np.float32
    ndarray with target locations in degrees

    Returns
    -------
    fiberid
    ndarray with fiber IDs for each target
    toblock
           ndarray with block IDs for each target

    Notes
    -----
    Calls write_plugprob.c in libdimage.so
    """

    assert len(xtarget) == len(ytarget)

    if(toblock is None):
        toblock = np.zeros(len(xtarget), dtype=np.int32)

    if(nmax is None):
        nmax = len(xtarget)

    if(minavail is None):
        if(maxinblock < 8):
            minavail = maxinblock
        else:
            minavail = 8

    if(blockfile is None):
        blockfile = os.path.join(os.getenv('PLATEDESIGN_DIR'),
                                 'data', 'apogee', 'fiberBlocksAPOGEE.par')

    if(observatory is None):
        observatory = Observatory(name='APO')

    fiberblocks = yanny.yanny(blockfile)
    fiberlist = fiberblocks['TIFIBERBLOCK']
    nblocks = fiberlist['blockid'].max()

    # Set block centers
    blockconstrain = True
    if(blockcenx is None or blockceny is None):
        blockcenx = np.zeros(nblocks, dtype=np.float64)
        blockceny = np.zeros(nblocks, dtype=np.float64)
        for block in (np.arange(nblocks) + 1):
            ib = np.nonzero(fiberlist['blockid'] == block)[0]
            blockcenx[block - 1] = np.mean(fiberlist['fibercenx'][ib])
            blockceny[block - 1] = np.mean(fiberlist['fiberceny'][ib])
        blockconstrain = False

    if(ylimits is None):
        ylimits = np.zeros((nblocks, 2), dtype=np.float64)
        ylimits[:, 0] = - 10.
        ylimits[:, 1] = 10.

    xfiber = np.array(fiberlist['fibercenx'], dtype=np.float64)
    yfiber = np.array(fiberlist['fiberceny'], dtype=np.float64)
    fiberblockid = np.array(fiberlist['blockid'], dtype=np.int32)

    xtarget_deg = xtarget / observatory.platescale
    ytarget_deg = ytarget / observatory.platescale

    used = np.zeros(len(xfiber), dtype=np.int32)
    if(fiberused is not None):
        used[fiberused - 1] = 1

    fiberTargetsPossible = None
    fiberTargetsPossible = np.zeros((len(xtarget), len(xfiber)),
                                    dtype=np.int32)
    for j in np.arange(len(xfiber)):
        fiberTargetsPossible[:, j] = boss_reachcheck(xfiber[j] * observatory.platescale,
                                                     yfiber[j] * observatory.platescale,
                                                     xtarget, ytarget, stretch=stretch)

    probfile = tempfile.mkstemp()[1]

    write_plugprob(xtarget=xtarget_deg, ytarget=ytarget_deg,
                   xfiber=xfiber, yfiber=yfiber,
                   fiberblockid=fiberblockid, used=used, toblock=toblock,
                   nMax=None, limitDegree=limitDegree,
                   fiberTargetsPossible=fiberTargetsPossible,
                   minAvailInBlock=0, minFibersInBlock=mininblock,
                   maxFibersInBlock=maxinblock, blockcenx=blockcenx,
                   blockceny=blockceny, blockconstrain=blockconstrain,
                   probfile=probfile, noycost=noycost,
                   blockylimits=ylimits)

    ansfile = tempfile.mkstemp()[1]

    pfp = open(probfile, mode="r")
    afp = open(ansfile, mode="w")

    cs2_path = os.path.join(os.getenv('PLATEDESIGN_DIR'),
                            'src', 'cs2', 'cs2')
    subprocess.call(cs2_path, stdin=pfp, stdout=afp)

    afp.close()
    pfp.close()

    (targetFiber, targetBlock) = read_plugprob(xtarget=xtarget_deg,
                                               ytarget=ytarget_deg,
                                               fiberblockid=fiberblockid,
                                               ansfile=ansfile)

    # os.remove(ansfile)
    # os.remove(probile)

    return(targetFiber, targetBlock, fiberTargetsPossible)


def epsilon_plugprob(xtarget=None, ytarget=None, gang=None,
                     minavail=None,
                     mininblock=0, maxinblock=24, fiberused=None,
                     nmax=None, limitDegree=0.8148, toblock=None,
                     blockfile=None, noycost=False,
                     ylimits=None, reachfunc=None, stretch=0,
                     observatory=None, blockcenx=None, blockceny=None,
                     gangcheck=True):
    """Test AS4 epsilon plugging problem

    Parameters
    ----------
    xtarget, ytarget : np.float32
    ndarray with target locations in degrees

    Returns
    -------
    fiberid
    ndarray with fiber IDs for each target
    toblock
           ndarray with block IDs for each target

    Notes
    -----
    Calls write_plugprob.c in libdimage.so
    """

    assert len(xtarget) == len(ytarget)

    if(toblock is None):
        toblock = np.zeros(len(xtarget), dtype=np.int32)

    if(nmax is None):
        nmax = len(xtarget)

    if(minavail is None):
        if(maxinblock < 8):
            minavail = maxinblock
        else:
            minavail = 8

    if(blockfile is None):
        blockfile = os.path.join(os.getenv('PLATEDESIGN_DIR'),
                                 'data', 'apogee',
                                 'fiberBlocksAPOGEEepsilon.par')

    if(observatory is None):
        observatory = Observatory(name='APO')

    fiberblocks = yanny.yanny(blockfile)
    fiberlist = fiberblocks['TIFIBERBLOCK']
    nblocks = fiberlist['blockid'].max()

    # Set block centers
    blockconstrain = True
    if(blockcenx is None or blockceny is None):
        blockcenx = np.zeros(nblocks, dtype=np.float64)
        blockceny = np.zeros(nblocks, dtype=np.float64)
        for block in (np.arange(nblocks) + 1):
            ib = np.nonzero(fiberlist['blockid'] == block)[0]
            blockcenx[block - 1] = np.mean(fiberlist['fibercenx'][ib])
            blockceny[block - 1] = np.mean(fiberlist['fiberceny'][ib])
        blockconstrain = False

    if(ylimits is None):
        ylimits = np.zeros((nblocks, 2), dtype=np.float64)
        ylimits[:, 0] = - 10.
        ylimits[:, 1] = 10.

    xfiber = np.array(fiberlist['fibercenx'], dtype=np.float64)
    yfiber = np.array(fiberlist['fiberceny'], dtype=np.float64)
    fiberblockid = np.array(fiberlist['blockid'], dtype=np.int32)
    fgang = np.array(fiberlist['gang'], dtype=np.str_)

    xtarget_deg = xtarget / observatory.platescale
    ytarget_deg = ytarget / observatory.platescale

    used = np.zeros(len(xfiber), dtype=np.int32)
    if(fiberused is not None):
        used[fiberused - 1] = 1

    fiberTargetsPossible = None
    fiberTargetsPossible = np.zeros((len(xtarget), len(xfiber)),
                                    dtype=np.int32)
    for j in np.arange(len(xfiber)):
        if(gangcheck):
            igang = np.nonzero(gang == fgang[j])[0]
        else:
            igang = np.arange(len(xtarget))
        reachable = boss_reachcheck(xfiber[j] * observatory.platescale,
                                    yfiber[j] * observatory.platescale,
                                    xtarget[igang], ytarget[igang],
                                    stretch=stretch)
        fiberTargetsPossible[igang, j] = reachable

    probfile = tempfile.mkstemp()[1]

    write_plugprob(xtarget=xtarget_deg, ytarget=ytarget_deg,
                   xfiber=xfiber, yfiber=yfiber,
                   fiberblockid=fiberblockid, used=used, toblock=toblock,
                   nMax=None, limitDegree=limitDegree,
                   fiberTargetsPossible=fiberTargetsPossible,
                   minAvailInBlock=0, minFibersInBlock=mininblock,
                   maxFibersInBlock=maxinblock, blockcenx=blockcenx,
                   blockceny=blockceny, blockconstrain=blockconstrain,
                   probfile=probfile, noycost=noycost,
                   blockylimits=ylimits)

    ansfile = tempfile.mkstemp()[1]

    pfp = open(probfile, mode="r")
    afp = open(ansfile, mode="w")

    cs2_path = os.path.join(os.getenv('PLATEDESIGN_DIR'),
                            'src', 'cs2', 'cs2')
    subprocess.call(cs2_path, stdin=pfp, stdout=afp)

    afp.close()
    pfp.close()

    (targetFiber, targetBlock) = read_plugprob(xtarget=xtarget_deg,
                                               ytarget=ytarget_deg,
                                               fiberblockid=fiberblockid,
                                               ansfile=ansfile)

    # os.remove(ansfile)
    # os.remove(probile)

    return(targetFiber, targetBlock, fiberTargetsPossible)
