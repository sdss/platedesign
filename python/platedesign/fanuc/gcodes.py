import os
import numpy as np
import pydl.pydlutils.yanny as yanny


class Gcodes(object):
    """Handles CNC code blocks for SDSS plate design

    Parameters
    ----------
    mode : str
         Drilling mode ('boss', 'manga', or 'apogee_south'); default 'boss'
    paramfile : str
         Input parameter file (e.g. 'plParam.par'); default None
    """

    def __init__(self, mode='boss', paramfile=None, parametersdir=None):
        self.mode = mode
        self.parametersdir = parametersdir
        self.param = yanny.yanny(paramfile)
        self.alignment = self._set_alignment(mode=mode)
        self.lighttrap = self._set_lighttrap(mode=mode)
        self.objects = self._set_objects(mode=mode)
        self.completion_text = self._set_completion_text(mode=mode)
        self.manga = self._set_manga(mode=mode)
        self.manga_alignment = self._set_manga_alignment(mode=mode)

        # Use different codes for movement for APOGEE south plates,
        # appropriate to drilling on a flat mandrel.
        if(self.mode == 'apogee_south'):
            self.coordcode = 'G56'
        else:
            self.coordcode = 'G54'

        # Comments in CNC code are labeled differently for MaNGA plates
        if(self.mode == 'manga'):
            self.name = 'SDSS/MaNGA'
        else:
            self.name = 'SDSS'

        self.acquisition_template = """(CAMERA MOUNTING HOLES)
G90 G56
G68 X0.0 Y0.0 R-90.0
G00 X{axy[0]:.6f} Y{axy[1]:.6f}
M98 P9775
G69
M98 P9776
M01
"""

        self.header_text = """%
O{plateId7K:d}({name} PLUG-PLATE {plateId:d})
(Drilling temperature {tempShopF:5.1f} degrees F)
(INPUT FILE NAME: {plug_name})
(CNC PROGRAM NAME: {fanuc_name})
"""

        self.first_text = str(self.coordcode) + """ G60 X{cx:.6f} Y{cy:.6f}
G43 H{drillSeq:02d} Z0.1
M08
"""
        self.hole_text = dict()
        self.hole_text['objects'] = """G83 G98 Z{cz:.6f} R{czr:.3f} L0 Q0.5 F9.0
{fixcode}G60 X{cx:.6f} Y{cy:.6f} ( {objId[0]} {objId[1]} {objId[2]} {objId[3]} {objId[4]} )
"""
        self.hole_text['lighttrap'] = self.hole_text['objects']
        self.hole_text['manga'] = self.hole_text['objects']
        self.hole_text['alignment'] = """G83 G98 Z{cz:.6f} R{czr:.3f} L0 Q0.02 F2.0
{fixcode}G60 X{cx:.6f} Y{cy:.6f} ( {objId[0]} {objId[1]} {objId[2]} {objId[3]} {objId[4]} )
"""
        self.hole_text['manga_alignment'] = """G83 G98 Z{cz:.6f} R{czr:.3f} L0 Q0.02 F1.5
{fixcode}G60 X{cx:.6f} Y{cy:.6f} ( {objId[0]} {objId[1]} {objId[2]} {objId[3]} {objId[4]} )
"""

        self.holediam_values = dict()
        self.holediam_values['OBJECT'] = np.float32(2.16662)
        self.holediam_values['COHERENT_SKY'] = np.float32(2.16662)
        self.holediam_values['GUIDE'] = np.float32(2.16662)
        self.holediam_values['LIGHT_TRAP'] = np.float32(3.175)
        self.holediam_values['ALIGNMENT'] = np.float32(1.1811)
        self.holediam_values['MANGA'] = np.float32(2.8448)
        self.holediam_values['MANGA_ALIGNMENT'] = np.float32(0.7874)
        self.holediam_values['MANGA_SINGLE'] = np.float32(3.2766)
        self.holediam_values['ACQUISITION_CENTER'] = np.float32(60.)
        self.holediam_values['ACQUISITION_OFFAXIS'] = np.float32(68.)

        self.drillSeq = dict()
        self.drillSeq['objects'] = 1
        if(self.mode == 'apogee_south'):
            self.drillSeq['objects'] = 11
        self.drillSeq['lighttrap'] = 2
        self.drillSeq['alignment'] = 3
        self.drillSeq['manga'] = 11
        self.drillSeq['manga_alignment'] = 12

    def _get_text(self, filename):
        """Gets text from a CNC template file

        Parameters
        ----------
        filename : str
            name of template file

        Returns
        -------
        text : str
            contents of file
        """
        fp = open(os.path.join(self.parametersdir, filename), 'r')
        text = fp.read()
        fp.close()
        return(text)

    def _set_alignment(self, mode='boss'):
        """Set alignment template
        """
        return(self._get_text(self.param['alignCodesFile']))

    def _set_lighttrap(self, mode='boss'):
        """Set light trap template
        """
        return(self._get_text(self.param['trapCodesFile']))

    def _set_completion_text(self, mode='boss'):
        """Set template text for completion
        """
        return(self._get_text(self.param['endCodesFile']))

    def _set_objects(self, mode='boss'):
        """Set object template
        """
        return(self._get_text(self.param['objectCodesFile']))

    def _set_manga(self, mode='boss'):
        """Set MaNGA template
        """
        if(mode == 'manga'):
            return(self._get_text(self.param['mangaCodesFile']))
        else:
            return(None)

    def _set_manga_alignment(self, mode='boss'):
        """Set MaNGA alignment template
        """
        if(mode == 'manga'):
            return(self._get_text(self.param['mangaAlignCodesFile']))
        else:
            return(None)

    def header(self, plateId=None, tempShopF=None,
               plug_name=None, fanuc_name=None):
        """Create a header of CNC file

        Parameters
        ----------
        plateId : np.int32, int
            plate ID number
        tempShopF : np.float32, float
            temperature of the shop assumed, in deg F
        plug_name : str
            name of plPlugMapP file
        fanuc_name : str
            name of plFanuc file being written to

        Returns
        -------
        text : str
            header
        """
        plateId7K = plateId % 7000
        return(self.header_text.format(name=self.name,
                                       plateId=plateId,
                                       plateId7K=plateId7K,
                                       tempShopF=tempShopF,
                                       plug_name=plug_name,
                                       fanuc_name=fanuc_name))

    def first(self, cx=None, cy=None, cz=None, czr=None, drillSeq=None):
        """Create CNC code for first hole

        Parameters
        ----------
        cx : np.float32
            X position of hole (inches)
        cy : np.float32
            Y position of hole (inches)
        cz : np.float32
            Z for hole (inches)
        czr : np.float32
            Z offset for hole (inches)
        drillSeq : np.int32, int
            drilling sequence index

        Returns
        -------
        text : str
            CNC code
        """
        return(self.first_text.format(cx=cx, cy=cy, cz=cz, czr=czr,
                                      drillSeq=drillSeq))

    def hole(self, holetype=None, cx=None, cy=None, cz=None, czr=None,
             objId=None, fixcode=None):
        """Create CNC code for holes

        Parameters
        ----------
        holetype : str
            type of hole
        cx : np.float32
            X position of hole (inches)
        cy : np.float32
            Y position of hole (inches)
        cz : np.float32
            Z for hole (inches)
        czr : np.float32
            Z offset for hole (inches)
        objId : np.int32, int
            [5]-array for object ID (relevant only for SDSS targets)

        Returns
        -------
        text : str
            CNC code
        """
        return(self.hole_text[holetype].format(cx=cx, cy=cy, cz=cz, czr=czr,
                                               objId=objId, fixcode=fixcode))

    def completion(self, plateId=None, axy=None):
        """Create CNC code for plate completion

        Parameters
        ----------
        plateId : np.int32, int
            plate ID number
        axy : (np.float32, np.float32) tuple
            X and Y drill location of off-axis acquisition camera (mm)

        Returns
        -------
        text : str
            CNC code for completion
        """
        plateId_str = "{plateId:<6}".format(plateId=plateId)
        completion_text = self.completion_text
        for digit in plateId_str:
            if(digit != " "):
                digit_int = digit
                digit_str = digit
            else:
                digit_int = "99"
                digit_str = "BLANKSPACE"
            repl = "{digit_int:0>2} ({digit_str})"
            repl = repl.format(digit_int=digit_int, digit_str=digit_str)
            completion_text = completion_text.replace("--", repl, 1)

        if((self.mode == 'apogee_south') &
           (axy[0] is not None) &
           (axy[1] is not None)):
            ax = axy[0] / 25.4
            ay = axy[1] / 25.4
            acquisition_text = self.acquisition_template.format(axy=(ax, ay))
            completion_text = completion_text.format(acquisition_text=acquisition_text)

        return(completion_text)

    def holediam(self, holetype=None, objId=None):
        """Return hole diameter in mm

        Parameters
        ----------
        holetype : str
            type of hole
        objId : np.int32, int
            [5] array of object identifies (only relevant for SDSS objects)

        Returns
        -------
        diameter : np.float32
            hole diameter in mm
        """
        if(holetype == 'QUALITY'):
            if(objId[2] == 0):
                return(3.175)
            else:
                return(2.16662)
        return(self.holediam_values[holetype])
