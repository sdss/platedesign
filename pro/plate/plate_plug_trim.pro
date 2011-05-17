;+
; NAME:
;   plate_plug_trim
; PURPOSE:
;   Trim unnecessary plPlugMapP files
; CALLING SEQUENCE:
;   plate_plug_trim, platerun
; INPUTS:
;   platerun - plate run name
; COMMENTS:
;   Makes sure there are only plPlugMapP files for the relevant
;   pointing. (E.g. do not allow plPlugMapP files to have an 
;   inconsistency between the name and the pointing).
; REVISION HISTORY:
;   18-May-2011  MRB, NYU
;-
pro plate_plug_trim, platerun

plateplans_file = getenv('PLATELIST_DIR')+'/platePlans.par'
check_file_exists, plateplans_file
plans= yanny_readone(plateplans_file)
iplate= where(plans.platerun eq platerun, nplate)
if(nplate eq 0) then begin
  splog, 'No plates in platerun '+platerun
  return
endif

for i=0L, nplate-1L do begin
    plateid= plans[iplate[i]].plateid
    platedir= (plate_dir(plateid))[0]

    files= file_search(platedir+'/plPlugMapP-'+ $
                       string(f='(i4.4)', plateid)+'*.par')
    for j=0L, n_elements(files)-1L do begin
        basename= file_basename(files[j])
        extract= stregex(basename, 'plPlugMapP-[0-9][0-9][0-9][0-9](.*)\.par', /extr, /sub)
        if(keyword_set(extract[1])) then $
          letter=extract[1] $
        else $
          letter='A'
        pl= yanny_readone(files[j], hdr=hdr)
        pointing= yanny_par(hdr, 'pointing')
        if(pointing ne letter) then begin
            if(letter ne 'A') then $
              message, 'We only expect spare A files to be around to be deleted!'
            otherfile= file_search(platedir+'/plPlugMapP-'+ $
                                   string(f='(i4.4)', plateid)+pointing+'.par')
            if(NOT file_test(otherfile)) then $
              message, 'We expect the REAL file to exist!'
            spawn, /nosh, ['diff', '-q', files[j], otherfile], diffout
            if(keyword_set(diffout)) then $
              message, 'We expect the REAL file to be identifical!'
            splog, 'Deleting A file in plates dir '+files[j]
            file_delete, files[j]
            runfile= getenv('PLATELIST_DIR')+'/runs/'+platerun+'/'+basename
            splog, 'Deleting A file in runs dir '+runfile
            file_delete, runfile
        endif
    endfor
    
endfor


end
;------------------------------------------------------------------------------
