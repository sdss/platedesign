;+
; NAME:
;   gfiber_params
; PURPOSE:
;   Return parameters associated with the guide fibers 
; CALLING SEQUENCE:
;   gfiber=gfiber_params()
; OUTPUTS:
;   gfiber - parameters for each guide fiber:
;                  .XREACH - point of origin (X)
;                  .YREACH - point of origin (Y)
;                  .RREACH - maximum radius of reach
;                  .XPREFER - preferred location (X)
;                  .YPREFER - preferred location (Y)
; COMMENTS:
;   The info is from the "plate" product in the
;     file "$PLATE_DIR/test/plParam.par".
;   All units in mm
;   Moving +RA is +XFOCAL, +DEC is +YFOCAL.
; REVISION HISTORY:
;   10-Jun-2008  MRB, NYU
;-
function gfiber_params

nguide = 11
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

guideparam = [[  1,  199.0,  -131.0,  165.0,  199.0,  -131.0 ], $
              [  2,   93.0,  -263.0,  165.0,   93.0,  -263.0 ], $
              [  3, -121.0,  -263.0,  165.0, -121.0,  -263.0 ], $
              [  4, -227.0,  -131.0,  165.0, -227.0,  -131.0 ], $
              [  5, -199.0,   131.0,  165.0, -199.0,   131.0 ], $
              [  6,  -93.0,   263.0,  165.0,  -93.0,   263.0 ], $
              [  7,  121.0,   263.0,  165.0,  121.0,   263.0 ], $
              [  8,  227.0,   131.0,  165.0,  227.0,   131.0 ], $
              [  9,   14.0,   131.0,  139.5,   14.0,    65.0 ], $
              [ 10,  -14.0,  -131.0,  165.0,  -14.0,   -65.0 ], $
              [ 11,   93.0,  -131.0,  139.5,   93.0,  -131.0 ] ]
gfiber.guidenum = transpose(guideparam[0,*])
gfiber.xreach = transpose(guideparam[1,*])
gfiber.yreach = transpose(guideparam[2,*])
gfiber.rreach = transpose(guideparam[3,*])
gfiber.xprefer = transpose(guideparam[4,*])
gfiber.yprefer = transpose(guideparam[5,*])

return, gfiber

end
;------------------------------------------------------------------------------
