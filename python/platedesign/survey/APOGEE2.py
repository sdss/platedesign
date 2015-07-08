#!/usr/bin/env python

import numpy as np

class APOGEE2_Survey(object):
	def name(self):
		return "APOGEE 2"

class apogee_blocks():
    """
    Description of APOGEE cartridge block positions and fiber types
    
    Attributes
    ==========
    blocks 
    
    Methods
    =======
    ftype 
    fcolor
    """
    def __init__(self):
        import sdss.utilities.yanny as yanny
        import os
        blockfile=os.path.join(os.getenv('PLATEDESIGN_DIR'),'data','apogee',
                         'fiberBlocksAPOGEE.par')
        self.blocks=yanny.yanny(blockfile)
    def ftype(self, fiberid):
        isci=(np.nonzero(np.array(self.blocks['TIFIBERBLOCK']['fiberid']) 
                         == fiberid))[0]
        return self.blocks['TIFIBERBLOCK']['ftype'][isci]
    def fcolor(self, fiberid):
        ftype= self.ftype(fiberid)
        if(ftype == 'B'):
            return 'red'
        if(ftype == 'M'):
            return 'green'
        if(ftype == 'F'):
            return 'blue'
