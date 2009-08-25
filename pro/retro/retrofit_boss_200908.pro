;+
; NAME:
;   retrofit_boss_200908
; PURPOSE:
;   Retrofit plPlugMapP files (Aug 2009)
; CALLING SEQUENCE:
;   retrofit_segue2_200908
; COMMENTS:
;   Retrofits the original plate drilling files for this set of plate
;    runs: 2009.08.a.boss
;   The desired guide numbering has changed.
;   In order to fix this, we rerun plugfile_plplugmap_boss, and 
;     replace the plugmaps in the plates and runs dirs
;   The old files in the plate dir is first moved into 
;     'plPlugMapP-????-orig.par'
; REVISION HISTORY:
;   20-Aug-2008  MRB, NYU
;-
;------------------------------------------------------------------------------
pro retrofit_boss_200908

plateruns=['2009.08.a.boss']
newg= yanny_readone(getenv('PLATEDESIGN_DIR')+'/data/sdss/sdss_newguide.par')

plans= yanny_readone(getenv('PLATELIST_DIR')+'/platePlans.par')
for i=0L, n_elements(plans)-1L do begin
    ii=where(plans[i].platerun eq plateruns, nii)
    ;; act if it is in one of the affected plate runs
    if(nii gt 0) then begin
        plateid= plans[i].plateid
        platestr= string(plateid, f='(i4.4)')
        platestr6= string(plateid, f='(i6.6)')
        platedir= plate_dir(plateid)

        holesfile= platedir+'/plateHoles-'+platestr6+'.par'
        origholesfile= platedir+'/plateHoles-'+platestr6+'-orig.par'
        if(file_test(origholesfile) gt 0) then $
          message, 'Original already exists!!'
        spawn, 'cp -f '+holesfile+' '+origholesfile

        sholesfile= platedir+'/plateHolesSorted-'+platestr6+'.par'
        origsholesfile= platedir+'/plateHolesSorted-'+platestr6+'-orig.par'
        if(file_test(origsholesfile) gt 0) then $
          message, 'Original already exists!!'
        spawn, 'cp -f '+sholesfile+' '+origsholesfile

        plugmapfile= platedir+'/plPlugMapP-'+platestr+'.par'
        origplugmapfile= platedir+'/plPlugMapP-'+platestr+'-orig.par'
        if(file_test(origplugmapfile) gt 0) then $
          message, 'Original already exists!!'
        spawn, 'cp -f '+plugmapfile+' '+origplugmapfile

        holes= yanny_readone(holesfile, hdr=hdr)
        iguide=where(holes.holetype eq 'GUIDE', nguide)
        if(nguide ne 16) then $
          message, 'Less than 16 guides!!!'
        for j=0L, nguide-1L do begin
            imatch= where(holes[iguide[j]].iguide eq newg.firstmatch, nmatch)
            if(nmatch eq 0) then $
              message, 'Inconsistency in guides!'
            holes[iguide[j]].iguide= newg[imatch].guidenum
        endfor
        
        pdata= ptr_new(holes)
        yanny_write, holesfile, pdata, hdr=hdr
        ptr_free, pdata
        
        plugfile_plplugmap_boss, plateid
        spawn, 'cp -f '+plugmapfile+' '+getenv('PLATELIST_DIR')+'/runs/'+ $
               plateruns[ii[0]]
        
        platelines_boss, plateid
    endif
endfor


return
end
