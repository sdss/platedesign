pro bad_plates

plans= yanny_readone(getenv('PLATELIST_DIR')+'/platePlans.par')

isdss= where(plans.plateid ge 3015, nsdss)

k_print, filename='bad_plates.ps'
temparr= fltarr(nsdss)
haminarr= fltarr(nsdss)
sigdiffarr= fltarr(nsdss)
maxdiffarr= fltarr(nsdss)
for i=0L, nsdss-1L do begin
    plan= plans[isdss[i]]
    plugfile= plate_dir(plan.plateid)+'/plPlugMapP-'+ $
      strtrim(string(plan.plateid, f='(i4.4)'),2)+'.par'
    if(file_test(plugfile)) then begin
        plug=yanny_readone(plugfile, hdr=hdr)
        
        hdrstr= lines2struct(hdr, /relaxed)
        racen= double(hdrstr.racen)
        deccen= double(hdrstr.deccen)
        temp= double(hdrstr.temp)
        hamin= double(hdrstr.hamin)
        
        lst= racen+ hamin
        
        ad2xyfocal, plug.ra, plug.dec, xf, yf, racen=racen, deccen=deccen, $
          airtemp=temp, lst=lst
        
        ii=where(plug.holetype eq 'OBJECT', nii)
        
        if(nii gt 0) then begin
            xdiff= (xf[ii]-plug[ii].xfocal)*1000.
            ydiff= (yf[ii]-plug[ii].yfocal)*1000.
            rdiff= sqrt(xdiff^2+ydiff^2)
            title=strtrim(string(plan.plateid),2)+' HA='+ $
              strtrim(string(plan.ha[0]),2)
            plothist, rdiff, xra=[0.,180.], title=title, $
              xtitle= 'offset (microns)', ytitle='Nfiber'
            temparr[i]=temp
            haminarr[i]=hamin
            sigdiffarr[i]=total(rdiff^2)/float(n_elements(rdiff))
            maxdiffarr[i]=max(rdiff)
        endif
    endif
    
endfor

k_end_print

save, filename='data_bad_plates.sav'

end
