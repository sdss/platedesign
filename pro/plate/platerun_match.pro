;+
; NAME:
;   platerun_match
; PURPOSE:
;   Run plate matching for a run
; CALLING SEQUENCE:
;   platerun_match, platerun
; INPUTS:
;   platerun - name of run to execute
; REVISION HISTORY:
;   5-May-2010  MRB, NYU
;-
pro platerun_match, platerun

if(NOT keyword_set(platerun)) then $
  message, 'Must set PLATERUN!'

if(strtrim(getenv('PLATELIST_DIR'),2) eq '') then $
  message, 'Must have setup platelist'

if(strtrim(getenv('BOSS_PHOTOOBJ'),2) eq '') then $
  message, 'Must have set environmental variable BOSS_PHOTOOBJ'

if(strtrim(getenv('PHOTO_RESOLVE'),2) eq '') then $
  message, 'Must have set environmental variable BOSS_PHOTOOBJ'

plansfile=getenv('PLATELIST_DIR')+'/platePlans.par')
if(file_test(plansfile) eq 0) then $
  message, 'platePlans.par file does not exist at path '+plansfile

plans= yanny_readone(plansfile)
if(n_tags(plans) eq 0) then $
  message, 'platePlans.par empty!)

irun= where(plans.platerun eq platerun, nrun)
if(nrun eq 0) then $
  message, 'No plates found in run '+platerun

for i=0L, nrun-1L do begin
    sdss_plate_match, plans[irun[i]].plate
    sdss_plate_photo, plans[irun[i]].plate
endfor

end
;------------------------------------------------------------------------------
