;+
; NAME:
;   get_observatory 
; PURPOSE:
;   Return what observatory the plate is supposed to be at
; CALLING SEQUENCE:
;   observatory= get_observatory(definition, default)
; COMMENTS:
;   Crashes if not 'APO' or 'LCO'. Defaults to 'APO'
; REVISION HISTORY:
;   7-Jul-2009  MRB, NYU
;-
;------------------------------------------------------------------------------
function get_observatory, definition, default

observatory='APO'

if(tag_indx(default, 'observatory') ne -1) then $
   observatory= (default.observatory)
if(tag_indx(definition, 'observatory') ne -1) then $
   observatory= (definition.observatory)

observatory = strupcase(observatory)

if ~((observatory eq 'APO') or (observatory eq 'LCO')) then $
  message, color_string('Must set observatory to APO or LCO', 'red', 'bold')

return, observatory

end

