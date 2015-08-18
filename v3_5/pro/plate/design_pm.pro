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
  message, color_string('Usage: design_pm, design, toepoch=', 'yellow', 'bold')

;; some sanity checks
if(tag_indx(design, 'TARGET_RA') eq -1 OR $
   tag_indx(design, 'TARGET_DEC') eq -1 OR $
   tag_indx(design, 'PMRA') eq -1 OR $
   tag_indx(design, 'PMDEC') eq -1 OR $
   tag_indx(design, 'EPOCH') eq -1) then begin
    message, color_string('DESIGN structure must have RA, DEC, PMRA, PMDEC, EPOCH!', 'red', 'bold')
endif
if(n_elements(toepoch) ne 1) then $
  message, color_string('TOEPOCH must have one and only one element!', 'red', 'bold')
if(toepoch lt 1999.) then $
  message, color_string('Do not adjust proper motions for the deep past!', 'red', 'bold')
if(toepoch gt 2100.) then $
  message, color_string('Do not adjust proper motions for the far future!', 'red', 'bold')
ibad= where(design.epoch lt 1900., nbad)
if(nbad gt 0) then $
  message, color_string('Some design elements have epoch < 1900', 'red', 'bold')
ibad= where(design.epoch gt 2100., nbad)
if(nbad gt 0) then $
  message, coloar_string('Some design elements have epoch > 2100', 'red', 'bold')

toepoch=toepoch[0]
depoch= toepoch-design.epoch
dalpha= design.pmra*depoch/3600./1000.
ddelta= design.pmdec*depoch/3600./1000.
secdec=1./cos(design.target_dec*!DPI/180.)
design.target_ra= design.target_ra+dalpha*secdec
design.target_dec= design.target_dec+ddelta
design.epoch= toepoch

end 
