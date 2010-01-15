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
;   The original info as from Larry Carey, sdss3-infrastructure/672.
;   Numbers updated from Harding, based on Carey's
;   sdss3-infrastructure/904
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

gfiber0 = create_struct( $
                         'guidenum' , 0L, $
                         'xreach'   , 0.0, $
                         'yreach'   , 0.0, $
                         'rreach'   , 0.0, $
                         'xprefer'  , 0.d, $
                         'yprefer'  , 0.d, $
                         'guidetype', ' ')
gfiber = replicate(gfiber0, nguide)

rows_mm= [-277.5, -137.8, 137.8, 277.5]

;; S = Short ferrule
;; F = In Focus ferrule
;; A =  1.5mm acquisition fiber
;; L =  Long ferrule
innercols_mm= [-205.74, -68.58, 114.30, 205.74]   ;; [S,F,A,L,F]
outercols_mm= [-91.4, 0, 91.4]    ;; [L,F,S]

;; reaches are in reality larger: 170 mm is the minimum
small_rreach_mm= 170.0  
large_rreach_mm= 170.0  

gfiber.guidenum = lindgen(nguide)+1L

;; bottom row
gfiber[0:2].xreach= outercols_mm
gfiber[0:2].yreach= rows_mm[0]

;; second row
gfiber[3:6].xreach= innercols_mm
gfiber[3:6].yreach= rows_mm[1]
gfiber[3].yreach= rows_mm[1]+70.
gfiber[6].yreach= rows_mm[1]+70.

;; third row
gfiber[7:10].xreach= -innercols_mm
gfiber[7:10].yreach= rows_mm[2]
gfiber[7].yreach= rows_mm[2]-70.
gfiber[10].yreach= rows_mm[2]-70.

;; top row
gfiber[11:13].xreach= -outercols_mm
gfiber[11:13].yreach= rows_mm[3]

;; set all reaches the same
gfiber[0:13].rreach = small_rreach_mm

;; set the large guide fibers
gfiber[14].xreach= 22.86
gfiber[14].yreach= rows_mm[1]
gfiber[14].rreach= large_rreach_mm
gfiber[15].xreach= -22.86
gfiber[15].yreach= rows_mm[2]
gfiber[15].rreach= large_rreach_mm

;; make preferred location same as reach center ...
gfiber.xprefer = gfiber.xreach
gfiber.yprefer = gfiber.yreach

;; ... except for large ones, where we push inwards a bit
gfiber[14].yprefer= rows_mm[1]*0.5
gfiber[15].yprefer= rows_mm[2]*0.5

;; finally, resort them to the final ordering
newg= yanny_readone(getenv('PLATEDESIGN_DIR')+'/data/sdss/sdss_newguide.par')
newgfiber = replicate(gfiber0, nguide)
newgfiber[newg.guidenum-1L]=gfiber[newg.firstmatch-1L]
gfiber=newgfiber
gfiber.guidenum=newg.guidenum
gfiber.guidetype=newg.guidetype
newgfiber=0

return, gfiber

end
;------------------------------------------------------------------------------
