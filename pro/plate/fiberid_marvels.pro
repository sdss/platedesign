;+
; NAME:
;   fiberid_marvels
; PURPOSE:
;   assign fiberid's to a list of MARVELS targets
; CALLING SEQUENCE:
;   fiberid= fiberid_marvels(design)
; INPUTS:
;   design - [60] struct array of targets, in design_blank() form
;            Required tags are .XF_DEFAULT, .YF_DEFAULT
; OUTPUTS:
;   fiberid - 1-indexed list of fibers 
; COMMENTS:
;   DUMMY CODE --- WE DON'T KNOW MARVELS FIBER LAYOUT YET!
; REVISION HISTORY:
;   4-Jun-2008 MRB, NYU 
;-
function fiberid_marvels, design

fiberid=lindgen(n_elements(design))+1L

return, fiberid

end

