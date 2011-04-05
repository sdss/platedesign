;+
; NAME:
;   pangle
; PURPOSE:
;   returns parallactic angle
; CALLING SEQUENCE:
;   pa= pangle(ha, dec, lat)
; INPUTS:
;   ha - hour angle in deg
;   dec - dec in deg
; OPTIONAL INPUTS:
;   lat - lat in deg (default 32.780278, APO)
; OUTPUTS:
;   pa - PA in deg E of N
; REVISION HISTORY:
;   1-Apr-2011  Michael Blanton, NYU
;-
;------------------------------------------------------------------------------
function pangle, ha, dec, lat

if(n_elements(lat) eq 0) then $
  lat= replicate(32.780278, n_elements(ha))

rha= ha/180.*!DPI
rdec= dec/180.*!DPI
rlat= lat/180.*!DPI

;; from Meuus 
tanq= sin(rha)/(tan(rlat)*cos(rdec)- sin(rdec)*cos(rha))

return, atan(tanq)*180./!DPI

END
