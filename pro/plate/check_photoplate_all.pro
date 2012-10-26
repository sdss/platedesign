;+
; NAME:
;   check_photoplate_all
; PURPOSE:
;   Check existence and validity of all BOSS photoPlate files
; CALLING SEQUENCE:
;   check_photoplate_all 
; REVISION HISTORY:
;   15-Apr-2011  MRB, NYU
;   26-Oct-2012 Demitri Muna, NYU, no longer selects on "programname='boss'
;-
;------------------------------------------------------------------------------
pro check_photoplate_all

plans= yanny_readone(getenv('PLATELIST_DIR')+'/platePlans.par')
iboss= where(plans.survey eq 'boss', nboss)

for i=0L, nboss-1L do begin
		ok= check_photoplate(plans[iboss[i]].plateid)
    if(~ ok) then $
      splog, 'bad photoPlate for '+strtrim(string(plans[iboss[i]].plateid),2)
endfor

end
