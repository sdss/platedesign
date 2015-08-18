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

if(strupcase(observatory) ne 'APO' and $
   strupcase(observatory) ne 'LCO') then $
  message, 'Must set observatory to APO or LCO'

return, observatory

end
