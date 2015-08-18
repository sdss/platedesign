;+
; NAME:
;   design_plates
; PURPOSE:
;   Run a particular list of plates given by plateid
; CALLING SEQUENCE:
;   design_plates, platerun, plateids [, inputs to plate_design ]
; INPUTS:
;   platerun - name of run to execute
;	plateids - list of plateids to run
; COMMENTS:
;	Runs plate_design for a list of given plates.
;	It is expected that platerun be run afterwards.
; REVISION HISTORY:
;   1-Dec-2010  Demitri Muna, NYU
;-
pro design_plates, plates, _EXTRA=extra_for_plate_design

compile_opt idl2
compile_opt logical_predicate
TRUE = 1
FALSE = 0

;; validation
if (n_elements(plates) eq 0) then begin
	splog, 'No plates specified. Usage:'
	splog, 'design_plates, [3000, 3001, 30002]'
	return
endif

;; get plate plans
plateplans_file = getenv('PLATELIST_DIR')+'/platePlans.par'
check_file_exists, plateplans_file
plans = yanny_readone(plateplans_file)
match, plans.plateid, plates, iplate, iplates, count=nplate

;; if none found
if(nplate eq 0) then begin
  splog, 'No plates found for given ids.'
  return
endif

;; print plateruns involved (for sanity check)
all_platerun_names = plans[iplate].platerun
inames = uniq(all_platerun_names, sort(all_platerun_names))
if (n_elements(inames) eq 1) then begin
	splog, 'Running plates from run: ' + string(strtrim(plates,2), /print)
endif else begin
	newline = string(10B) ; classy idl, classy
	splog, 'Running plates from run(s): '
	splog, '        ' + string(strtrim(plates,2)) + newline
endelse

;; run plate_design for each one
plate_design, plans[iplate].plateid, succeeded=succeeded, _EXTRA=extra_for_plate_design
if (~succeeded) then return

;; Print finished message
splog, 'Plates [' + string(strtrim(plates,2), /print) + '] finished.'
if (n_elements(inames) eq 1) then begin
	splog, 'When all the plates of this run are finished, run "platerun, ''' + all_platerun_names[iname] + ''', /skip_design"'
endif else begin
	splog, 'When all of the plates of these runs are finished, run "platerun, <platerun_name>, /skip_design"'
endelse

end
;------------------------------------------------------------------------------
