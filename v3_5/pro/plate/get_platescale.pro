;+
; NAME:
;   get_platescale
; PURPOSE:
;   Return average plate scale for APO or LCO
; CALLING SEQUENCE:
;   scale= get_platescale(observatory)
; INPUTS:
;   observatory - 'APO' or 'LCO'
; OUTPUTS:
;   scale - plate scale in mm/deg
; REVISION HISTORY:
;   20-May-2015  Written by MRB, NYU
;-
;------------------------------------------------------------------------------
function get_platescale, observatory

if(size(observatory,/tname) ne 'STRING') then $
  message, 'observatory must be set to STRING type, with value "LCO" or "APO"'

if(strupcase(observatory) ne 'APO' and $
   strupcase(observatory) ne 'LCO') then $
  message, 'Must set observatory to APO or LCO'

if(strupcase(observatory) eq 'APO') then $
  platescale = 217.7358D        ; mm/degree

;; Number from Guillermo Damke and Mike Blanton analyses
;; of the March 2015 engring run.
if(strupcase(observatory) eq 'LCO') then $
  platescale = 328.589265D          ; mm/degree

return, platescale
end
