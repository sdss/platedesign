;+
; NAME:
;   check_photoplate_all
; PURPOSE:
;   Check existence and validity of all BOSS photoPlate files
; CALLING SEQUENCE:
;   check_photoplate_all 
; REVISION HISTORY:
;   15-Apr-2011  MRB, NYU
;-
;------------------------------------------------------------------------------
pro check_photoplate_all

plans= yanny_readone(getenv('PLATELIST_DIR')+'/platePlans.par')
iboss= where(plans.survey eq 'boss' and $
	plans.programname eq 'boss', nboss)

for i=0L, nboss-1L do begin
		ok= check_photoplate(plans[iboss[i]].plateid)
    if(NOT ok) then $
      splog, 'bad photoPlate for '+strtrim(string(plans[iboss[i]].plateid),2)
endfor

end
