import os
import ctypes
import numpy as np


def optimize_path(x=None, y=None, tfactor=0.9):
    """Optimize path through 2D set of points with simulated annealing

    Parameters
    ----------
    x : np.float32
        X positions of points
    y : np.float32
        Y positions of points
    tfactor: np.float32

    Returns
    -------
    (order) : np.int32
         ndarrays 0-indexed order of optimized path (to minimize length)

    Notes
    -----
    Calls anneal.c in libanneal.so
    Returns original order if number of points is <= 3

    """

    # don't bother for short list
    if(len(x) <= 3):
        return(np.arange(len(x)))

    sopath = os.path.join(os.getenv('PLATEDESIGN_DIR'), 'lib')
    anneal_lib = ctypes.cdll.LoadLibrary(os.path.join(sopath, "libanneal.so"))
    anneal_function = anneal_lib.anneal

    if(x.dtype != np.float32):
        x_float32 = x.astype(np.float32)
    else:
        x_float32 = x
    x_ptr = x_float32.ctypes.data_as(ctypes.POINTER(ctypes.c_float))

    if(y.dtype != np.float32):
        y_float32 = y.astype(np.float32)
    else:
        y_float32 = y
    y_ptr = y_float32.ctypes.data_as(ctypes.POINTER(ctypes.c_float))

    npts_ptr = ctypes.c_int(np.int32(len(x)))
    tfactor_ptr = ctypes.c_float(tfactor)
    iorder = np.arange(len(x), dtype=np.int32) + 1
    iorder_ptr = iorder.ctypes.data_as(ctypes.POINTER(ctypes.c_int))

    anneal_function(x_ptr, y_ptr, iorder_ptr, npts_ptr, tfactor_ptr)
    iorder = iorder - 1

    return(iorder)
