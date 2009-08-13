;+
; NAME:
;   plplugmap_blank
; PURPOSE:
;   Initialize a plPlugMapP structure
; CALLING SEQUENCE:
;   pl= plplugmap_blank(enums=)
; REVISION HISTORY:
;   9-Jun-2008 MRB, NYU (based on DJS's design_append)
;-
function plplugmap_blank, enums=enums, structs=structs

pl= yanny_readone(getenv('PLATEDESIGN_DIR')+ $
                  '/data/sdss/plPlugMapP-blank-new.par', $
                  enums=enums, structs=structs)

return, pl

end

