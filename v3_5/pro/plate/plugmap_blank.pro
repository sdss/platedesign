;+
; NAME:
;   plugmap_blank
; PURPOSE:
;   Initialize a plugMap structure
; CALLING SEQUENCE:
;   pl= plugmap_blank(enums=)
; REVISION HISTORY:
;   25-Aug-2009 MRB, NYU 
;-
function plugmap_blank, enums=enums, structs=structs

pl= yanny_readone(getenv('PLATEDESIGN_DIR')+ $
                  '/data/sdss/plugMap-blank.par', $
                  enums=enums, structs=structs)

return, pl

end

