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
; COMMENTS:
;   Default scale is for 5400 A at APO, but 16000 A at LCO
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

if(strupcase(observatory) eq 'LCO') then begin
    scales = lco_scales()
    iscale = where(scales.lambda eq 16600. and scales.zoffset eq 0., nscale)
    if(nscale eq 0) then $
      message, 'LCO scales does not have default scales in it'
    if(nscale gt 1) then $
      message, 'LCO scales has too many default scale entries'
    platescale = scales[iscale].a0
endif

return, platescale
end
