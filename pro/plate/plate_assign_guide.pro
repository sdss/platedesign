;+
; NAME:
;   plate_assign_guide
; PURPOSE:
;   Assign guide fibers to a current plate
; CALLING SEQUENCE:
;   plate_assign_guide, definition, default, design, guide_design [, $
;      guidenums= ]
; INPUTS:
;   definition - plate definition structure
;   default - plate default structure
;   design - design structure
;   guide_design - design structure for guide stars
; OPTIONAL INPUTS:
;   guidenums - guide numbers to assign to (default to [0,1, .. 10])
; OUTPUTS:
;   design - (with guide fibers added)
; COMMENTS:
;   Because this is called before plate_holes, it doesn't add
;    alignment holes yet. Those get assigned once the actual xfocal 
;    and yfocal of the guides is known.
;   This only adds fibers for guide fibers that don't already have 
;    assignments yet.
; REVISION HISTORY:
;   8-May-2008  Written by MRB, NYU (based on DJS's plate_design.pro)
;-
pro plate_assign_guide, definition, default, design, guide_design, $
  guidenums=guidenums

;;----------
;; Set up info for guide fibers.
;;
;; The following info is from the "plate" product in the
;; file "$PLATE_DIR/test/plParam.par".
;;   XREACH,YREACH = Center of the fiber reach [mm]
;;   RREACH = Radius of the fiber reach [mm]
;;   XPREFER,YREACH = Preferred position for the fiber [mm]
;; Note that the plate scale is approx 217.7358 mm/degree.
;; Moving +RA is +XFOCAL, +DEC is +YFOCAL.

nguide = 11
if(n_elements(guidenums) eq 0) then $
  guidenums= lindgen(nguide)

gfiber = create_struct( $
         'xreach'   , 0.0, $
         'yreach'   , 0.0, $
         'rreach'   , 0.0, $
         'xprefer'  , 0.d, $
         'yprefer'  , 0.d )
gfiber = replicate(gfiber, nguide)

platescale = 217.7358           ; mm/degree
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
gfiber.xreach = transpose(guideparam[1,*])
gfiber.yreach = transpose(guideparam[2,*])
gfiber.rreach = transpose(guideparam[3,*])
gfiber.xprefer = transpose(guideparam[4,*])
gfiber.yprefer = transpose(guideparam[5,*])

for i=0l, n_elements(guidenums)-1L do begin
    iguide= guidenums[i]

    icheck= where(design.iguide eq iguide, ncheck)
    if(ncheck gt 1) then $
      message, 'why are there two assignments for guide #'+ $
               strtrim(string(iguide),2)

    if(ncheck eq 0) then begin
        ;; find closest available guide star that isn't conflicted
        conflicted=1
        while(conflicted) do begin
            iavailable= where(guide_design.assigned eq 0 AND $
                              guide_design.conflicted eq 0, navailable)
            if(navailable eq 0) then $
              message, 'no more available guide stars!'
            adiff= sqrt((gfiber[iguide].xprefer- $
                         guide_design[iavailable].xf_default)^2+ $
                        (gfiber[iguide].yprefer- $
                         guide_design[iavailable].yf_default)^2)
            minadiff = min(adiff, iclosest)
            iclosest= iavailable[iclosest]
            conflicted=check_conflicts(design, guide_design[iclosest])
            if(conflicted) then $
              guide_design[iclosest].conflicted=1
        endwhile
        
        ;; now add it:
        guide_design[iclosest].assigned=1L
        guide_design[iclosest].iguide=iguide
        design=[design, guide_design[iclosest]]
    endif
endfor

return
end

