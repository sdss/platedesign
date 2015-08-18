pro jan_segue2_platelines

plans= yanny_readone(getenv('PLATELIST_DIR')+'/platePlans.par')

iseg= where(plans.platerun eq '2009.01.a.segue2', nseg)

for i=0L, nseg-1L do $
  if(file_test(plate_dir(plans[iseg[i]].plateid)) gt 0) then $
  platelines_segue2, plans[iseg[i]].plateid

for i=0L, nseg-1L do $
  spawn, 'cp -f '+plate_dir(plans[iseg[i]].plateid)+'/plateLines*.ps '+ $
  getenv('PLATELIST_DIR')+'/runs/2009.01.a.segue2'

end
