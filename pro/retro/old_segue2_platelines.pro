pro old_segue2_platelines

plans= yanny_readone(getenv('PLATELIST_DIR')+'/platePlans.par')

iseg= where((plans.plateid ge 3100 and plans.plateid le 3162) OR $
            plans.platerun eq 'nov08c', nseg)

for i=0L, nseg-1L do $
  if(file_test(plate_dir(plans[iseg[i]].plateid)) gt 0) then $
  platelines_segue2, plans[iseg[i]].plateid

end
