pro set_fiberid_brians

oldplates= [3055, 3056, 3060, 3061]

inputdir=getenv('PLATELIST_DIR')+'/inputs/marvels/'+ $
  'postselection/survey/oct08'
for i=0L, n_elements(oldplates)-1L do begin
    oldfibersfile= inputdir+'/plateHolesSorted-'+ $
      string(oldplates[i], f='(i4.4)')+'-brian.par'
    oldfibers= yanny_readone(oldfibersfile, hdr=hdr)
    hdrstr= lines2struct(hdr)
    
    words1= strsplit(hdrstr.plateinput1, '/', /extr)
    plinputfile_1= words1[n_elements(words1)-1L]

    words1= strsplit(plinputfile_1, '.', /extr)
    plinputnewfile_1= words1[0:n_elements(words1)-2L]+'-fiberid.par'
    
    plinput_1= yanny_readone(inputdir+'/'+plinputfile_1, hdr=hdr)
    plinputnew_1= replicate(create_struct(plinput_1[0], 'fiberid', -9999L), $
                            n_elements(plinput_1))
    struct_assign, plinput_1, plinputnew_1, /nozero

    for j=0L, n_elements(plinputnew_1)-1L do begin
        if(strtrim(plinputnew_1[j].targetids,2) ne 'NA') then begin 
            ii=where(strtrim(plinputnew_1[j].targetids,2) eq $
                     strtrim(oldfibers.targetids,2), nii) 
            if(nii gt 1) then stop 
            if(nii eq 1) then $
              plinputnew_1[j].fiberid= oldfibers[ii].fiberid  $
            else $
              plinputnew_1[j].priority= plinputnew_1[j].priority+1000L
        endif
    endfor
    yanny_write, inputdir+'/'+plinputnewfile_1, ptr_new(plinputnew_1), hdr=hdr


    words2= strsplit(hdrstr.plateinput2, '/', /extr)
    plinputfile_2= words2[n_elements(words2)-1L]
    words2= strsplit(plinputfile_2, '.', /extr)
    plinputnewfile_2= words2[0:n_elements(words2)-2L]+'-fiberid.par'
    
    plinput_2= yanny_readone(inputdir+'/'+plinputfile_2, hdr=hdr)
    plinputnew_2= replicate(create_struct(plinput_2[0], 'fiberid', -9999L), $
                            n_elements(plinput_2))
    struct_assign, plinput_2, plinputnew_2, /nozero

    for j=0L, n_elements(plinputnew_2)-1L do begin
        if(strtrim(plinputnew_2[j].targetids,2) ne 'NA') then begin 
            ii=where(strtrim(plinputnew_2[j].targetids,2) eq $
                     strtrim(oldfibers.targetids,2), nii) 
            if(nii gt 1) then stop 
            if(nii eq 1) then $
              plinputnew_2[j].fiberid= oldfibers[ii].fiberid $
            else $
              plinputnew_2[j].priority= plinputnew_2[j].priority+1000L
        endif
    endfor
    yanny_write, inputdir+'/'+plinputnewfile_2, ptr_new(plinputnew_2), hdr=hdr
    
endfor

end
