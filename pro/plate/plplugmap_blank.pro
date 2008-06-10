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
function plplugmap_blank, enums=enums

pl= yanny_readone(getenv('PLATEDESIGN_DIR')+ $
                  '/data/sdss/plPlugMapP-blank.par', $
                  enums=enums)

return, pl

end

