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

; Adjust the files to compensate for the drill machine quadrupole.
cmd = [getenv('ADJUSTFANUCFILES_DIR') + '/bin/adjustFanucScript.py', $
       getenv('PLATELIST_DIR')+'/runs/' + platerun]
spawn, /nosh, cmd
splog, 'Drill files adjusted for quadrupole'

; Generate CMM machine files.
cmd = [getenv('GENERATECMMDATA_DIR') + '/bin/generateCMMDataScript.py', $
       getenv('PLATELIST_DIR')+'/runs/' + platerun]
spawn, /nosh, cmd
splog, 'CMM files created'

;; create plateGuideOffsets, default wavelengths defined in create_derivs
;for i=0, nplate-1 do begin
;	create_derivs, plans[iplate[i]].plateid
;endfor

;; look for additional wavelengths requested in defintion file
for i=0, nplate-1 do begin
	plateid = plans[iplate[i]].plateid
	; read definition file
	definition = plate_definition(plateid=plateid)
	if (tag_exist(definition, 'guide_on_wavelengths') eq 1) then begin
		wavelengths = strsplit(definition.guide_on_wavelengths, /extract)
		create_derivs, plateid, wavelengths=wavelengths
	endif else begin
		create_derivs, plateid
	endelse
endfor

splog, 'Completed.'

end
;------------------------------------------------------------------------------
