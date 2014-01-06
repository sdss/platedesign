;+
; NAME:
;   fiberid_dummy
; PURPOSE:
;   assign fiberid's for a list of dummy targets
; CALLING SEQUENCE:
;   fiberid= fiberid_dummy(default, fibercount, design)
; INPUTS:
;   default - default structure
;   fibercount - fibercount structure for tracking #s
;   design - [N] struct array of targets, in design_blank() form
; OPTIONAL KEYWORDS:
;   /nosky - do not attempt to assign any of the sky fibers
;   /nostd - do not attempt to assign any of the standard fibers
;   /noscience - do not attempt to assign any of the science fibers
; OUTPUTS:
;   fiberid - 1-indexed list of fibers 
; COMMENTS:
;   Just assigns according to lindgen, no real assignment.
; REVISION HISTORY:
;   4-Jun-2008 MRB, NYU 
;-
function fiberid_dummy, default, fibercount, design, $
  minstdinblock=minstdinblock, $
  minskyinblock=minskyinblock, $
  maxskyinblock=maxskyinblock, $
  nosky=nosky, nostd=nostd, noscience=noscience, $
  quiet=quiet, block=block, $
  respect_fiberid=respect_fiberid, all_design=all_design

if(keyword_set(respect_fiberid)) then $
  message, 'dummy designs cannot respect fiberid'

block= replicate(1L, n_elements(design))
return, lindgen(n_elements(design))+1L

end

