;+
; NAME:
;   get_ferrulesize 
; PURPOSE:
;   Return size of ferrule appropriate to this instrument
; CALLING SEQUENCE:
;   ferrulesize= get_ferrulesize(definition, default, instrument)
; COMMENTS:
;   Returns in mm
; REVISION HISTORY:
;   7-Jul-2009  MRB, NYU
;-
;------------------------------------------------------------------------------
function get_ferrulesize, definition, default, instrument

ferrulestr= 'ferruleSize'+strtrim(instrument,2)
iferrule= tag_indx(definition, ferrulestr)
if(iferrule eq -1) then begin
    iferrule= tag_indx(default, ferrulestr)
    if(iferrule eq -1) then begin
        message, 'No ferrule size specified for instrument '+instrument
    endif else begin
        ferrulesize= float(default.(iferrule))
    endelse
endif else begin
    ferrulesize= float(definition.(iferrule))
endelse

return, ferrulesize

end
