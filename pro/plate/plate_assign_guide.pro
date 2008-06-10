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

gfiber= gfiber_params()

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
            adiff= sqrt((gfiber[iguide-1L].xprefer- $
                         guide_design[iavailable].xf_default)^2+ $
                        (gfiber[iguide-1L].yprefer- $
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

