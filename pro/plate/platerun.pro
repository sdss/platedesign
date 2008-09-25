;+
; NAME:
;   platerun
; PURPOSE:
;   Run a particular plate run
; CALLING SEQUENCE:
;   platerun, platerun  [, inputs to plate_design ]
; INPUTS:
;   platerun - name of run to execute
; COMMENTS:
;   Only implemented drillstyles are "sdss" and "marvels"
;   (drillstyle set in platePlans.par file)
; REVISION HISTORY:
;   10-Jun-2008  MRB, NYU
;-
pro platerun, platerun, _EXTRA=extra_for_plate_design

if(keyword_set(platerun) EQ 0) then begin
    print, 'Usage: platerun, runname [, drillstyle ]'
    return
endif

;; find plates in this platerun
plans= yanny_readone(getenv('PLATELIST_DIR')+'/platePlans.par')
iplate= where(plans.platerun eq platerun, nplate)
if(nplate eq 0) then begin
  splog, 'No plates in platerun '+platerun
  return
endif
  
;; run plate_design for each one
plate_design, plans[iplate].plateid, _EXTRA=extra_for_plate_design

;; now run the low level plate routines
drillstyle= strtrim(plans[iplate].drillstyle,2)
isort=sort(drillstyle)
iuniq=uniq(drillstyle[isort])
if(n_elements(iuniq) gt 1) then $
  message, 'cannot include more than one drillstyle in a single plate run!'
drillstyle=drillstyle[0]
call_procedure, 'platerun_'+drillstyle, platerun, plans[iplate].plateid

end
;------------------------------------------------------------------------------
