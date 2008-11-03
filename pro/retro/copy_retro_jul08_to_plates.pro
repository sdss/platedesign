;+
; NAME:
;   copy_retro_jul08_to_plates
; PURPOSE:
;   copy retro-fit files to plate from jul08c,e,f and aug08d
; REVISION HISTORY:
;   3-Nov-2008  MRB, NYU
;-
;------------------------------------------------------------------------------
pro copy_retro_jul08_to_plates

plateruns=['jul08e', 'jul08c', 'jul08f', 'aug08d']

plans= yanny_readone(getenv('PLATELIST_DIR')+'/platePlans.par')
for i=0L, n_elements(plans)-1L do begin
    ii=where(plans[i].platerun eq plateruns, nii)
    ;; act if it is in one of the affected plate runs
    if(nii gt 0) then begin
        plateid= plans[i].plateid
        platestr= string(plateid, f='(i4.4)')
        platedir= plate_dir(plateid)

        platesplugmapfile= platedir+'/plPlugMapP-'+platestr+'.par'
        origplatesplugmapfile= platedir+'/plPlugMapP-'+platestr+'-orig.par'
        newplugmapfile= getenv('PLATELIST_DIR')+'/runs/'+plans[i].platerun+ $
          '/plPlugMapP-'+platestr+'.par'

        spawn, 'mv '+platesplugmapfile+' '+origplatesplugmapfile
        spawn, 'cp '+newplugmapfile+' '+platesplugmapfile
    endif
endfor


return
end
