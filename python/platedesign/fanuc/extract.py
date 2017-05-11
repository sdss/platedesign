import os
import numpy as np


def extract(fanuc_file=None):
    """Extract X, Y, Z, ZR from Fanuc file

    Parameter
    ----------
    fanuc_file : str
        Fanuc file name

    Returns
    -------
    (x, y, z, zr) : tuple of np.float32 ndarrays
        values from Fanuc
    """
    fp = open(fanuc_file)
    lines = fp.readlines()

    x = np.zeros(0)
    y = np.zeros(0)
    z = np.zeros(0)
    zr = np.zeros(0)

    i = 0
    while (i < len(lines)):
        words = lines[i].split()
        if(len(words) > 0):
            if(words[0] == "G83"):
                cz = words[2][1:]
                czr = words[3][1:]
                i = i + 1
                words = lines[i].split()
                cx = words[1][1:]
                cy = words[2][1:]
                x = np.append(x, np.float32(cx))
                y = np.append(y, np.float32(cy))
                z = np.append(z, np.float32(cz))
                zr = np.append(zr, np.float32(czr))
        i = i + 1
    fp.close()

    return(x, y, z, zr)
