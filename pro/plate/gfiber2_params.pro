;+
; NAME:
;   gfiber2_params
; PURPOSE:
;   Return parameters associated with the new guide fibers (Fall 2009)
; CALLING SEQUENCE:
;   gfiber=gfiber2_params()
; OUTPUTS:
;   gfiber - parameters for each guide fiber:
;                  .XREACH - point of origin (X)
;                  .YREACH - point of origin (Y)
;                  .RREACH - maximum radius of reach
;                  .XPREFER - preferred location (X)
;                  .YPREFER - preferred location (Y)
; COMMENTS:
;   The info is from Larry Carey, sdss3-infrastructure/672 and following
;   PDF is in $PLATEDESIGN_DIR/docs/SDSS3GdFbrAnchrPtandRch955.pdf
;   Output units in mm
;   Moving +RA is +XFOCAL, +DEC is +YFOCAL.
;   Guides 1-14 are SMALL
;   Guides 15-16 are LARGE
; REVISION HISTORY:
;   10-Jun-2008  MRB, NYU
;-
function gfiber2_params

nguide = 16
if(n_elements(guidenums) eq 0) then $
  guidenums= lindgen(nguide)

gfiber = create_struct( $
         'guidenum' , 0L, $
         'xreach'   , 0.0, $
         'yreach'   , 0.0, $
         'rreach'   , 0.0, $
         'xprefer'  , 0.d, $
         'yprefer'  , 0.d )
gfiber = replicate(gfiber, nguide)

inch2mm= 25.4

rows_mm=[-10.35, -5.15, 5.15, 10.35]*inch2mm

innercols_mm= inch2mm*[-9.20, -3.68, 2.58, 8.10] ;; sign needs to be verified
outercols_mm= inch2mm*[-5.00, -0.55, 3.90] ;; sign needs to be verified

small_rreach_mm= 165.0  ;; needs to be verified
large_rreach_mm= 139.5  ;; needs to be verified

gfiber.guidenum = lindgen(nguide)+1L

;; bottom row
gfiber[0:2].xreach= outercols_mm
gfiber[0:2].yreach= rows_mm[0]

;; second row
gfiber[3:6].xreach= innercols_mm
gfiber[3:6].yreach= rows_mm[1]

;; third row
gfiber[7:10].xreach= innercols_mm
gfiber[7:10].yreach= rows_mm[2]

;; top row
gfiber[11:13].xreach= outercols_mm
gfiber[11:13].yreach= rows_mm[3]

;; set all reaches the same
gfiber[0:13].rreach = small_rreach_mm

;; set the large guide fibers
gfiber[14].xreach= 0.
gfiber[14].yreach= rows_mm[1]
gfiber[14].rreach= large_rreach_mm
gfiber[15].xreach= 0.
gfiber[15].yreach= rows_mm[2]
gfiber[15].rreach= large_rreach_mm

;; make preferred location same as reach center ...
gfiber.xprefer = gfiber.xreach
gfiber.yprefer = gfiber.yreach

;; ... except for large ones, where we push inwards a bit
gfiber[14].yprefer= rows_mm[1]*0.5
gfiber[15].yprefer= rows_mm[2]*0.5

return, gfiber

end
;------------------------------------------------------------------------------
