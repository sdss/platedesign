;+
; NAME:
;   platerun
; PURPOSE:
;   Run a particular plate run
; CALLING SEQUENCE:
;   platerun, platerun  [, drillstyle= , inputs to plate_design ]
; INPUTS:
;   platerun - name of run to execute
; OPTIONAL INPUTS:
;   drillstyle - make drilling files using this style (default 'sdss')
; COMMENTS:
;   Only implemented drillstyles are "sdss" and "marvels"
; REVISION HISTORY:
;   10-Jun-2008  MRB, NYU
;-
pro platerun, platerun, drillstyle, _EXTRA=extra_for_plate_design

if(keyword_set(platerun) EQ 0) then begin
    print, 'Usage: platerun, runname [, drillstyle ]'
    return
endif

if(keyword_set(drillstyle) eq 0) then $
  drillstyle='sdss'

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
call_procedure, 'platerun_'+drillstyle, platerun, plans[iplate].plateid

end
;------------------------------------------------------------------------------
