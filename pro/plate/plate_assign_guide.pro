;+
; NAME:
;   plate_assign_guide
; PURPOSE:
;   Assign guide fibers to a current plate
; CALLING SEQUENCE:
;   plate_assign_guide, definition, default, design, guide_design, $
;     pointing, [, guidenums= ]
; INPUTS:
;   definition - plate definition structure
;   default - plate default structure
;   design - design structure
;   guide_design - design structure for guide stars
;   pointing - which pointing
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
  pointing, guidenums=guidenums

tilerad=1.49

if(tag_indx(default, 'GFIBERTYPE') ge 0) then $
  gfibertype= default.gfibertype $
else $
  gfibertype= 'gfiber'
gfiber= call_function(gfibertype+'_params')

for i=0l, n_elements(guidenums)-1L do begin
    iguide= guidenums[i]

    icheck= where(design.iguide eq iguide, ncheck)
    if(ncheck gt 1) then $
      message, 'why are there two assignments for guide #'+ $
               strtrim(string(iguide),2)

    if(ncheck eq 0) then begin
        ;; find closest available guide star that isn't conflicted
        ;; or outside the plate
        conflicted=1
        while(conflicted) do begin
            iavailable= where(guide_design.assigned eq 0 AND $
                              guide_design.conflicted eq 0 AND $
                              guide_design.pointing eq pointing, navailable)
            if(navailable eq 0) then $
              message, 'no more available guide stars!'
            
            ;; ensure that we aren't outside the plate
            plate_center, definition, default, pointing, 0L, $
              racen=racen, deccen=deccen
            spherematch, racen, deccen, guide_design[iavailable].target_ra, $
              guide_design[iavailable].target_dec, tilerad, m1, m2, max=0
            if(m2[0] eq -1) then $
              message, 'no more available guide stars!'
            iavailable=iavailable[m2]
            
            ;; get distance from preferred position 
            adiff= sqrt((gfiber[iguide-1L].xprefer- $
                         guide_design[iavailable].xf_default)^2+ $
                        (gfiber[iguide-1L].yprefer- $
                         guide_design[iavailable].yf_default)^2)

            ;; then sort according to distance and priority;
            ;; essentially, set up a set of annuli in which we choose
            ;; equally according to priority
            maxprior=float(max(guide_design[iavailable].priority))
            gsortpar= $
              guide_design[iavailable].priority+ $
              maxprior*2.*float(long(adiff/80.))

            minsort = min(gsortpar, imin)
            imin= iavailable[imin]
            conflicted=check_conflicts(design, guide_design[imin])
            if(conflicted) then $
              guide_design[imin].conflicted=1
        endwhile
        
        ;; now add it:
        guide_design[imin].assigned=1L
        guide_design[imin].iguide=iguide
        design=[design, guide_design[imin]]
    endif
endfor

return
end

