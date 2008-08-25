;+
; NAME:
;   write_platelines_run
; PURPOSE:
;   write plateLines files for a run (ad hoc code)
; CALLING SEQUENCE:
;   write_platelines_run, run
; INPUTS:
;   run - run name
; COMMENTS:
;   Runs platelines_segue2 for a run and copies files into runs dir
; REVISION HISTORY:
;   25-Aug-2008  Written by MRB (NYU)
;-
;------------------------------------------------------------------------------
pro write_platelines_run, run

plans= yanny_readone(getenv('PLATELIST_DIR')+'/platePlans.par')
iin= where(plans.platerun eq run, nin)
for i=0L, nin-1L do begin
    platelines_segue2, plans[iin[i]].plateid
    spawn, 'cp -f '+plate_dir(plans[iin[i]].plateid)+ $
      '/plateLines-'+strtrim(string(f='(i6.6)', plans[iin[i]].plateid),2)+ $
      '.ps '+getenv('PLATELIST_DIR')+'/runs/'+run
endfor

end
