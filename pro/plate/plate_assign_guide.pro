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

tilerad= get_tilerad(definition, default)

if(tag_indx(default, 'GFIBERTYPE') ge 0) then $
  gfibertype= default.gfibertype $
else $
  gfibertype= 'gfiber'
gfiber= call_function(gfibertype+'_params')

;; pick out which guides we are using
useg= lonarr(n_elements(gfiber))
for i=0L, n_elements(guidenums)-1L do begin
    ig= where(gfiber.guidenum eq guidenums[i], ng)
    if(ng eq 0) then $
      message, 'guidenum specified that does not exist!'
    useg[ig]=1
endfor
iuse= where(useg gt 0, nuse)
if(nuse eq 0) then $
  message, 'No guide numbers are specified?'

;; find non-conflicting set of guides
for i=0L, n_elements(guide_design)-1L do begin
    conflicted=check_conflicts(design, guide_design[i]) gt 0 
    if(i gt 0) then $
      conflicted= conflicted gt 0 OR $
      check_conflicts(guide_design[0:i-1], guide_design[i]) gt 0 
    if(conflicted gt 0) then $
      guide_design[i].conflicted=1
 endfor


;; find available guides that don't conflict with 
;; higher priority ones
iavailable= where(guide_design.assigned eq 0 AND $
                  guide_design.conflicted eq 0 AND $
                  guide_design.pointing eq pointing, navailable)

;; ensure that we aren't outside the plate
plate_center, definition, default, pointing, 0L, $
  racen=racen, deccen=deccen
spherematch, racen, deccen, guide_design[iavailable].target_ra, $
  guide_design[iavailable].target_dec, tilerad, m1, m2, max=0
if(m2[0] eq -1) then $
  message, 'no more available guide stars!'
iavailable=iavailable[m2]

;; assign the guides
gnum= distribute_guides(gfiber[iuse], guide_design[iavailable])

;; check there are enough
iok= where(gnum gt 0, nok)
if(nok ne n_elements(guidenums)) then $
  message, 'NOT ALL GUIDE FIBERS PLUGGABLE!'

for i=0l, n_elements(guidenums)-1L do begin
    iguide= guidenums[i]
    
    ipick= where(iguide eq gnum, npick)
    if(npick eq 0) then $
      message, 'No guide number '+strtrim(string(iguide),2)
    if(npick gt 1) then $
      message, 'More than one guide number '+strtrim(string(iguide),2)
    ipick= iavailable[ipick]

    ;; check conflicts
    conflicted=check_conflicts(design, guide_design[ipick])
    if(conflicted) then $
      message, 'Inconsistency!  Meant to remove conflicts!'
    
    ;; now add it:
    guide_design[ipick].assigned=1L
    guide_design[ipick].iguide=iguide
    if(n_tags(design) gt 0) then $
      design=[design, guide_design[ipick]] $
    else $
      design=guide_design[ipick]
endfor

return
end

