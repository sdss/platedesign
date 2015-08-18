;+
; NAME:
;   get_tilerad 
; PURPOSE:
;   Return radius of tile 
; CALLING SEQUENCE:
;   tilerad= get_tilerad(definition, default)
; COMMENTS:
;   Returns in deg
; REVISION HISTORY:
;   7-Jul-2009  MRB, NYU
;-
;------------------------------------------------------------------------------
function get_tilerad, definition, default

tilerad=1.49D

if(tag_indx(default, 'tilerad') ne -1) then $
   tilerad= double(default.tilerad)
if(tag_indx(definition, 'tilerad') ne -1) then $
   tilerad= double(definition.tilerad)

return, tilerad

end
