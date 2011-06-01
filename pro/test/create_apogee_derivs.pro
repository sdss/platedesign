pro create_apogee_derivs

plans= yanny_readone(getenv('PLATELIST_DIR')+'/platePlans.par')

ii=where(strmatch(plans.platerun, '*apogee*') ne 0 and plans.plateid gt 4923, nii)

nn=0L
for i=0L, nii-1L do begin
    plan= plans[ii[i]]
    
    plug= yanny_readone(plate_dir(plan.plateid)+'/plPlugMapP-'+ $
                        string(plan.plateid, f='(i4.4)')+'.par', hdr=hdr)
    
    type= yanny_par(hdr, 'platetype')
    if(strmatch(type, '*APOGEE*')) then $
      apogee=1L $
    else $
      apogee=0L

    type= yanny_par(hdr, 'platetype')
    if(strmatch(type, '*MARVELS*')) then $
      marvels=1L $
    else $
      marvels=0L

    np=yanny_par(hdr, 'npointings')
    
    for pointing=1L, np do begin
        if(pointing eq 1) then nn++
        help, plan, /st
        if(apogee) then $
          plate_guide_derivs, plan.plateid, pointing, guideon=16600.
        if(marvels) then $
          plate_guide_derivs, plan.plateid, pointing, guideon=5400.
    endfor
    
endfor

print, nii
print, nn

end
