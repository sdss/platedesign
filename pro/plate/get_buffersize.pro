;+
; NAME:
;   get_buffersize 
; PURPOSE:
;   Return size of buffer appropriate to this instrument
; CALLING SEQUENCE:
;   buffersize= get_buffersize(definition, default, instrument)
; COMMENTS:
;   Returns in mm
; REVISION HISTORY:
;   7-Jul-2009  MRB, NYU
;-
;------------------------------------------------------------------------------
function get_buffersize, definition, default, instrument

bufferstr= 'bufferSize'+strtrim(instrument,2)
ibuffer= tag_indx(definition, bufferstr)
if(ibuffer eq -1) then begin
    ibuffer= tag_indx(default, bufferstr)
    if(ibuffer eq -1) then begin
        message, 'No buffer size specified for instrument '+instrument
    endif else begin
        buffersize= float(default.(ibuffer))
    endelse
endif else begin
    buffersize= float(definition.(ibuffer))
endelse

return, buffersize

end
