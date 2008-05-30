;+
; NAME:
;   platedesign_version
; PURPOSE:
;   Return the version name for the product platedesign
; CALLING SEQUENCE:
;   vers = platedesign_version()
; OUTPUTS:
;   vers       - Version name for the product platedesign
; COMMENTS:
;   Depends on shell script in $PLATEDESIGN_DIR/bin
;-
;------------------------------------------------------------------------------
function platedesign_version
   spawn, 'platedesign_version', stdout, /noshell
   return, stdout[0]
end
;------------------------------------------------------------------------------
