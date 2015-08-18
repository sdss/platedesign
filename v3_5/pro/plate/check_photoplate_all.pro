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
;   06-Sep-2014 Joel Brownstein, Utah, generalize to eBOSS via survey keyword
;-
;------------------------------------------------------------------------------
pro check_photoplate_all, survey=survey

if ~keyword_set(survey) then survey='boss'

plans= yanny_readone(getenv('PLATELIST_DIR')+'/platePlans.par')
isurvey= where(plans.survey eq survey and $
	~strmatch(plans.programname, '*_test'), nsurvey)

for i=0L, nsurvey-1L do begin
		ok= check_photoplate(plans[isurvey[i]].plateid)
    if(~ ok) then $
      splog, 'bad photoPlate for '+strtrim(string(plans[isurvey[i]].plateid),2)
endfor

end
