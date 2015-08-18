;+
; NAME:
;   retrofit_segue2_200904
; PURPOSE:
;   Retrofit plPlugMapP files (April/May 2008)
; CALLING SEQUENCE:
;   retrofit_segue2_200904
; COMMENTS:
;   Retrofits the original plate drilling files for this set of plate
;    runs: 2009.04.d.segue2, 2009.05.d.segue2
;   The guide magnitudes were not properly set in those plates
;   In order to fix this, we rerun plugfile_plplugmap_segue2, and 
;     replace the plugmaps in the plates and runs dirs
;   The old files in the plate dir is first moved into 
;     'plPlugMapP-????-orig.par'
; REVISION HISTORY:
;   20-Aug-2008  MRB, NYU
;-
;------------------------------------------------------------------------------
pro retrofit_segue2_200904

plateruns=['2009.04.d.segue2', '2009.05.d.segue2']

plans= yanny_readone(getenv('PLATELIST_DIR')+'/platePlans.par')
for i=0L, n_elements(plans)-1L do begin
    ii=where(plans[i].platerun eq plateruns, nii)
    ;; act if it is in one of the affected plate runs
    if(nii gt 0) then begin
        plateid= plans[i].plateid
        platestr= string(plateid, f='(i4.4)')
        platedir= plate_dir(plateid)
        plugmapfile= platedir+'/plPlugMapP-'+platestr+'.par'
        origplugmapfile= platedir+'/plPlugMapP-'+platestr+'-orig.par'
        if(file_test(origplugmapfile) gt 0) then $
          message, 'Original already exists!!'
        spawn, 'cp -f '+plugmapfile+' '+origplugmapfile
        
        plugfile_plplugmap_segue2, plateid
        spawn, 'cp -f '+plugmapfile+' '+getenv('PLATELIST_DIR')+'/runs/'+ $
               plateruns[ii[0]]
    endif
endfor


return
end
