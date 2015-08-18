;+
; NAME:
;   default_epoch
; PURPOSE:
;   Return default epoch to use for XF_DEFAULT, YF_DEFAULT
; CALLING SEQUENCE:
;   toepoch= default_epoch()
; COMMENTS:
;   Used by routines building the plateDesign files, so that they pick
;     appropriate defaults.
; REVISION HISTORY:
;   8-May-2008  Written by MRB, NYU
;-
function default_epoch

return, 2011.

end
