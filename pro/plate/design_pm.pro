;+
; NAME:
;   design_pm
; PURPOSE:
;   Adjust design structures for proper motions
; CALLING SEQUENCE:
;   design_pm, design, toepoch=
; INPUTS:
;   design - [N] design structure, with elements:
;              .RA, .DEC - J2000 deg
;              .PMRA, .PMDEC - mas/yr
;              .EPOCH - years AD that RA, DEC are for
;   toepoch - epoch to design at for proper motions 
; OUTPUTS:
;   design - [N] structure adjusted in place with new RA, DEC, EPOCH
; REVISION HISTORY:
;   11-Aug-2011  Written by MRB, NYU
;-
pro design_pm, design, toepoch=toepoch

if(n_tags(design) eq 0) then $
  message, 'Usage: design_pm, design, toepoch='

;; some sanity checks
if(tag_indx(design, 'TARGET_RA') eq -1 OR $
   tag_indx(design, 'TARGET_DEC') eq -1 OR $
   tag_indx(design, 'PMRA') eq -1 OR $
   tag_indx(design, 'PMDEC') eq -1 OR $
   tag_indx(design, 'EPOCH') eq -1) then begin
    message, 'DESIGN structure must have RA, DEC, PMRA, PMDEC, EPOCH!'
endif
if(n_elements(toepoch) ne 1) then $
  message, 'TOEPOCH must have one and only one element!'
if(toepoch lt 1999.) then $
  message, 'Do not adjust proper motions for the deep past!'
if(toepoch gt 2100.) then $
  message, 'Do not adjust proper motions for the far future!'
ibad= where(design.epoch lt 1900., nbad)
if(nbad gt 0) then $
  message, 'Some design elements have epoch < 1900'
ibad= where(design.epoch gt 2100., nbad)
if(nbad gt 0) then $
  message, 'Some design elements have epoch > 2100'

toepoch=toepoch[0]
depoch= toepoch-design.epoch
dalpha= design.pmra*depoch/3600./1000.
ddelta= design.pmdec*depoch/3600./1000.
secdec=1./cos(design.target_dec*!DPI/180.)
design.target_ra= design.target_ra+dalpha*secdec
design.target_dec= design.target_dec+ddelta
design.epoch= toepoch

end 
