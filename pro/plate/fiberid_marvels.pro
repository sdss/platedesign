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
function fiberid_marvels, default, fibercount, design, $
                          minstdinblock=minstdinblock, $
                          minskyinblock=minskyinblock

nfiber=60L

ifiber=shuffle_indx(n_elements(design), num_sub=nfiber)
fiberid=lonarr(n_elements(design))
fiberid[ifiber]=lindgen(nfiber)

return, fiberid

end

