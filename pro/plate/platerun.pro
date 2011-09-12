;+
; NAME:
;   platerun
; PURPOSE:
;   Run a particular plate run
; CALLING SEQUENCE:
;   platerun, platerun [, inputs to plate_design ]
; INPUTS:
;   platerun - name of run to execute
; COMMENTS:
;   Only implemented drillstyles are "sdss", "marvels", and "boss"
;   (drillstyle set in platePlans.par file)
; REVISION HISTORY:
;   10-Jun-2008  MRB, NYU
;-
pro platerun, platerun, nolines=nolines, skip_design=skip_design, _EXTRA=extra_for_plate_design

compile_opt idl2
compile_opt logical_predicate
TRUE = 1
FALSE = 0

if(keyword_set(platerun) EQ 0) then begin
	print, 'Usage: platerun, runname [, drillstyle ]'
	return
endif

;; find plates in this platerun
plateplans_file = getenv('PLATELIST_DIR')+'/platePlans.par'
check_file_exists, plateplans_file
plans= yanny_readone(plateplans_file)
iplate= where(plans.platerun eq platerun, nplate)
if(nplate eq 0) then begin
  splog, 'No plates in platerun '+platerun
  return
endif

if (keyword_set(skip_design) eq FALSE) then begin
	;; run plate_design for each one
	plate_design, plans[iplate].plateid, succeeded=succeeded, _EXTRA=extra_for_plate_design
	
	if (~succeeded) then return
endif

;; now run the low level plate routines
drillstyle= strtrim(plans[iplate].drillstyle,2)
isort=sort(drillstyle)
iuniq=uniq(drillstyle[isort])
if(n_elements(iuniq) gt 1) then $
  message, 'cannot include more than one drillstyle in a single plate run!'
drillstyle=drillstyle[0]
call_procedure, 'platerun_'+drillstyle, platerun, plans[iplate].plateid, $
  nolines=nolines

for i=0, nplate-1 do begin
	create_derivs, plan[iplate[i]].plateid
endfor

splog, 'Completed.'

end
;------------------------------------------------------------------------------
