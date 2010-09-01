;+
; NAME:
;   platelines_boss_all
; PURPOSE:
;   Create plateLines files for a BOSS run
; CALLING SEQUENCE:
;   platelines_boss_all, platerun
; INPUTS:
;   platerun - name of run to execute
; REVISION HISTORY:
;   10-Aug-2008  MRB, NYU
;    1-Sep-2010  Demitri Muna, NYU, Adding file test before opening files.
;-
pro platelines_boss_all, platerun

;; find plates in this platerun
plateplans_file = getenv('PLATELIST_DIR')+'/platePlans.par'
check_file_exists, plateplans_file, plateid=plateid
plans= yanny_readone(plateplans_file)
iplate= where(plans.platerun eq platerun, nplate)
if(nplate eq 0) then begin
  splog, 'No plates in platerun '+platerun
  return
endif
  
;; run plate_design for each one
for i=0L, nplate-1L do begin
    platelines_boss, plans[iplate[i]].plateid, /diesoft
endfor

end
;------------------------------------------------------------------------------
