;+
; NAME:
;   boss_reachvalues
; PURPOSE:
;   Returns set of reach values for fibers in BOSS cartridges
; CALLING SEQUENCE:
;   boss_reachvalues, xval=, yval=
; OUTPUTS:
;   xval, yval - [N] positions of furthest reach (mm)
; COMMENTS:
;   Reach values measured by Larry Carey, sdss3-infrastructure/907
;   See the PDFs in $PLATEDESIGN_DIR/data/boss
;   Positions are given in degrees relative to the fiber positions 
;    (i.e. those in $PLATEDESIGN_DIR/data/boss/fiberBlocksBOSS.par 
;   In X-Y plane, points are given in counter-clockwise order,
;     starting with Y=0 in the +X direction. This point is repeated 
;     at the end to close the loop.
; REVISION HISTORY:
;   7-Aug-2008  MRB, NYU
;-
;------------------------------------------------------------------------------
pro boss_reachvalues, xval=xval, yval=yval

xcm= [25., 20., 15., 10., 5., 0., -5., -10., -15., -17., -17., $
      -17., -15., -10., -5., 0., 5., 10., 15., 20., 25.]
ycm= [0., 15., 19., 21., 22., 22., 22., 20., 15., 2., 0., $
      -2., -15., -20., -22., -22., -22., -21., -19., -15., 0.]

xmm= 10.*xcm
ymm= 10.*ycm

xval= xmm
yval= ymm

return
end
