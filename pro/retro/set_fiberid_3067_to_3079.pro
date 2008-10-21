pro set_fiberid_3067_to_3079

inputdir=getenv('PLATELIST_DIR')+'/inputs/marvels/'+ $
  'postselection/survey/oct08'
oldfibersfile_1=inputdir+ '/plateHolesSorted-003067_p1.par'
oldfibers_1= yanny_readone(oldfibersfile_1)

plinputfile_1= inputdir+'/plateInput-HD37605__15-09-2008.par'
plinputnewfile_1= inputdir+'/plateInput-HD37605__15-09-2008-fiberid.par'
plinput_1= yanny_readone(plinputfile_1, hdr=hdr)
plinputnew_1= replicate(create_struct(plinput_1[0], 'fiberid', -9999L), $
                        n_elements(plinput_1))
struct_assign, plinput_1, plinputnew_1, /nozero

for i=0L, n_elements(plinputnew_1)-1L do begin 
    if(strtrim(plinputnew_1[i].targetids,2) ne 'NA') then begin 
        ii=where(strtrim(plinputnew_1[i].targetids,2) eq $
                 strtrim(oldfibers_1.targetids,2), nii) 
        if(nii gt 1) then stop 
        if(nii eq 1) then $
          plinputnew_1[i].fiberid= oldfibers_1[ii].fiberid $
        else $
          plinputnew_1[i].priority= plinputnew_1[i].priority+1000L 
    endif 
endfor

yanny_write, plinputnewfile_1, ptr_new(plinputnew_1), hdr=hdr

inputdir=getenv('PLATELIST_DIR')+'/inputs/marvels/'+ $
  'postselection/survey/oct08'
oldfibersfile_2=inputdir+ '/plateHolesSorted-003067_p2.par'
oldfibers_2= yanny_readone(oldfibersfile_2)

plinputfile_2= inputdir+'/plateInput-GL273__15-09-2008.par'
plinputnewfile_2= inputdir+'/plateInput-GL273__15-09-2008-fiberid.par'
plinput_2= yanny_readone(plinputfile_2, hdr=hdr)
plinputnew_2= replicate(create_struct(plinput_2[0], 'fiberid', -9999L), $
                        n_elements(plinput_2))
struct_assign, plinput_2, plinputnew_2, /nozero

for i=0L, n_elements(plinputnew_2)-1L do begin 
  if(strtrim(plinputnew_2[i].targetids,2) ne 'NA') then begin 
  ii=where(strtrim(plinputnew_2[i].targetids,2) eq $
           strtrim(oldfibers_2.targetids,2), nii) 
  if(nii gt 1) then stop 
 if(nii eq 1) then $
  plinputnew_2[i].fiberid= oldfibers_2[ii].fiberid+60 $
else $
  plinputnew_2[i].priority= plinputnew_2[i].priority+1000L 
  endif 
endfor

yanny_write, plinputnewfile_2, ptr_new(plinputnew_2), hdr=hdr


end
