pro test_apo_refrac

files= file_search(getenv('SDSS_TILING')+'/opdb/drillRuns/dr*.[0-9]/plPlugMapP-*.par')

nums=strarr(n_elements(files))
for i=0L, n_elements(files)-1L do begin
    words= strsplit(files[i], '/', /extr)
    nums[i]= (stregex(words[n_elements(words)-1], 'plPlugMapP-(.*)\.par', $
                      /sub, /extr))[1]
endfor
files=files[sort(nums)]

temparr= fltarr(n_elements(files))
haminarr= fltarr(n_elements(files))
sigdiffarr= fltarr(n_elements(files))
maxdiffarr= fltarr(n_elements(files))
sdiffarr= fltarr(n_elements(files))
sigsdiffarr= fltarr(n_elements(files))
maxsdiffarr= fltarr(n_elements(files))
for i=0L, n_elements(files)-1L do begin

    words= strsplit(files[i], '/', /extr)
    pnum= (stregex(words[n_elements(words)-1], 'plPlugMapP-(.*)\.par', $
                   /sub, /extr))[1]
    k_print, filename='ps/apo-refrac-'+pnum+'.ps', xsize=8., ysize=10.
    
    !P.MULTI=[12,3,4]
    !Y.MARGIN=0

    pl= yanny_readone(files[i], hdr=hdr)
    hdrstr= lines2struct(hdr)
    racen= double(hdrstr.racen)
    deccen= double(hdrstr.deccen)
    temp= double(hdrstr.temp)
    hamin= double(hdrstr.hamin)
    
    lst= racen+ hamin
    
    lambda=replicate(5000., n_elements(pl))
    ad2xyfocal, 'APO', pl.ra, pl.dec, xf, yf, racen=racen, deccen=deccen, $
      airtemp=temp, lst=lst, lambda=lambda, clambda=5000., $
      /nordistort
    ad2xyfocal, 'APO', pl.ra, pl.dec, sxf, syf, racen=racen, deccen=deccen, $
      airtemp=temp, lst=lst, height=1., lambda=lambda, clambda=5000., $
      /nordistort
    
    ii=where(pl.holetype eq 'OBJECT', nii)

    if(nii gt 0) then begin
        xdiff= (xf[ii]-pl[ii].xfocal)*1000.
        ydiff= (yf[ii]-pl[ii].yfocal)*1000.
        scale= sqrt(xf[ii]^2+yf[ii]^2)/ $
          sqrt(pl[ii].xfocal^2+pl[ii].yfocal^2)
        rdiff= sqrt(xdiff^2+ydiff^2)
        decstr= strtrim(string(f='(f40.1)', deccen),2)
        hastr= strtrim(string(f='(f40.1)', hamin),2)
        tempstr= strtrim(string(f='(f40.2)', temp),2)
        ff= pnum+' dec= '+decstr+ ' HA= '+hastr+ $
          ' temp='+tempstr
        plothist, rdiff, xra=[0.,60.], title=ff, $
          xtitle= 'offset (microns)', ytitle='Nfiber', $
          xcharsize=0.0001
        temparr[i]=temp
        haminarr[i]=hamin
        sigdiffarr[i]=total(rdiff^2)/float(n_elements(rdiff))
        maxdiffarr[i]=max(rdiff)
        sdiffarr[i]=median(scale)

        hogg_usersym, 20, /fill
        djs_plot, xdiff, ydiff, xra=[-50., 50.], yra= [-50., 50.], $
          /topaxis, psym=8, symsize=0.3

        xst=!X.CRANGE[0]+0.1*(!X.CRANGE[1]-!X.CRANGE[0])
        yst=!Y.CRANGE[0]+0.9*(!Y.CRANGE[1]-!Y.CRANGE[0])
        djs_xyouts, xst, yst, 'APO pressure, no scaling', $
          charsize=0.7

        hogg_usersym, 20, /fill
        djs_plot, xf[ii], yf[ii], xra=[-330., 330.], yra= [-330., 330.], $
          /topaxis, /rightaxis, psym=8, symsize=0.3
        vscale=2.
        for j=0L, nii-1L do $
          djs_oplot, xf[ii[j]]+[0.,1.]*xdiff[j]*vscale, $
          yf[ii[j]]+[0.,1.]*ydiff[j]*vscale 
        
        xsdiff= (xf[ii]-pl[ii].xfocal*sdiffarr[i])*1000.
        ysdiff= (yf[ii]-pl[ii].yfocal*sdiffarr[i])*1000.
        rsdiff= sqrt(xsdiff^2+ysdiff^2)
        sigsdiffarr[i]=total(rsdiff^2)/float(n_elements(rsdiff))
        maxsdiffarr[i]=max(rsdiff)

        plothist, rsdiff, xra=[0.,60.], $
          xtitle= 'offset (microns)', ytitle='Nfiber', xcharsize=0.0001

        hogg_usersym, 20, /fill
        djs_plot, xsdiff, ysdiff, xra=[-50., 50.], yra= [-50., 50.], $
          psym=8, symsize=0.3, xcharsize=0.001, ycharsize=0.001

        xst=!X.CRANGE[0]+0.1*(!X.CRANGE[1]-!X.CRANGE[0])
        yst=!Y.CRANGE[0]+0.9*(!Y.CRANGE[1]-!Y.CRANGE[0])
        djs_xyouts, xst, yst, 'APO pressure', $
          charsize=0.7
        yst=!Y.CRANGE[0]+0.8*(!Y.CRANGE[1]-!Y.CRANGE[0])
        djs_xyouts, xst, yst, 'Scaling of '+ $
          strtrim(string(f='(f40.6)', sdiffarr[i]),2), $
          charsize=0.7

        hogg_usersym, 20, /fill
        djs_plot, xf[ii], yf[ii], xra=[-330., 330.], yra= [-330., 330.], $
          psym=8, symsize=0.3, /rightaxis
        for j=0L, nii-1L do $
          djs_oplot, xf[ii[j]]+[0.,1.]*xsdiff[j]*vscale, $
          yf[ii[j]]+[0.,1.]*ysdiff[j]*vscale 

        sxdiff= (sxf[ii]-pl[ii].xfocal)*1000.
        sydiff= (syf[ii]-pl[ii].yfocal)*1000.
        srdiff= sqrt(sxdiff^2+sydiff^2)

        plothist, srdiff, xra=[0.,60.], $
          xtitle= 'offset (microns)', ytitle='Nfiber', $
          xcharsize=0.0001

        hogg_usersym, 20, /fill
        djs_plot, sxdiff, sydiff, xra=[-50., 50.], yra= [-50., 50.], $
          xcharsize=0.001, ycharsize=0.001, psym=8, symsize=0.3

        xst=!X.CRANGE[0]+0.1*(!X.CRANGE[1]-!X.CRANGE[0])
        yst=!Y.CRANGE[0]+0.9*(!Y.CRANGE[1]-!Y.CRANGE[0])
        djs_xyouts, xst, yst, 'Sea-level pressure, no scaling', $
          charsize=0.7

        hogg_usersym, 20, /fill
        djs_plot, xf[ii], yf[ii], xra=[-330., 330.], yra= [-330., 330.], $
          /rightaxis, psym=8, symsize=0.3
        for j=0L, nii-1L do $
          djs_oplot, xf[ii[j]]+[0.,1.]*sxdiff[j]*vscale, $
          yf[ii[j]]+[0.,1.]*sydiff[j]*vscale 

        scale= median(sqrt(sxf[ii]^2+syf[ii]^2)/ $
                      sqrt(pl[ii].xfocal^2+pl[ii].yfocal^2))
        sxsdiff= (sxf[ii]-pl[ii].xfocal*scale)*1000.
        sysdiff= (syf[ii]-pl[ii].yfocal*scale)*1000.
        srsdiff= sqrt(sxsdiff^2+sysdiff^2)

        plothist, srsdiff, xra=[0.,60.], $
          xtitle= 'offset (microns)', ytitle='Nfiber'

        hogg_usersym, 20, /fill
        djs_plot, sxsdiff, sysdiff, xra=[-50., 50.], yra= [-50., 50.], $
          /bottomaxis, psym=8, symsize=0.3

        xst=!X.CRANGE[0]+0.1*(!X.CRANGE[1]-!X.CRANGE[0])
        yst=!Y.CRANGE[0]+0.9*(!Y.CRANGE[1]-!Y.CRANGE[0])
        djs_xyouts, xst, yst, 'Sea-level pressure', $
          charsize=0.7
        yst=!Y.CRANGE[0]+0.8*(!Y.CRANGE[1]-!Y.CRANGE[0])
        djs_xyouts, xst, yst, 'Scaling of '+ $
          strtrim(string(f='(f40.6)', scale),2), $
          charsize=0.7

        hogg_usersym, 20, /fill
        djs_plot, xf[ii], yf[ii], xra=[-330., 330.], yra= [-330., 330.], $
          /bottomaxis, /rightaxis, psym=8, symsize=0.3
        for j=0L, nii-1L do $
          djs_oplot, xf[ii[j]]+[0.,1.]*sxsdiff[j]*vscale, $
          yf[ii[j]]+[0.,1.]*sysdiff[j]*vscale 
        
    endif

    k_end_print

    spawn, 'convert ps/apo-refrac-'+pnum+'.ps apo-refrac-'+pnum+'.jpg'

    
endfor

racen=dblarr(n_elements(files))
deccen=dblarr(n_elements(files))
for i=0L, n_elements(files)-1L do begin & $
splog, i & $
    yanny_read, files[i], hdr=hdr & $
    hdrstr= lines2struct(hdr) & $
   racen[i]=hdrstr.racen & $
   deccen[i]=hdrstr.deccen & $
  endfor


save, filename='apo_refrac.sav'

for i=0L, n_elements(jj)-1 do begin & $
tt= files[jj[20]] & $
pl=yanny_readone(tt, hdr=hdr) & $
    hdrstr= lines2struct(hdr) & $
    racen= double(hdrstr.racen) & $
    deccen= double(hdrstr.deccen) & $
    temp= double(hdrstr.temp) & $
    hamin= double(hdrstr.hamin) & $
    lst= racen+ hamin & $
    ad2xyfocal, 'APO', pl.ra, pl.dec, xf, yf, racen=racen, deccen=deccen, $
      airtemp=temp, lst=lst & $
    ii=where(pl.holetype eq 'OBJECT', nii) & $
       xdiff= (xf[ii]-pl[ii].xfocal)*1000. & $
        ydiff= (yf[ii]-pl[ii].yfocal)*1000. & $
splot_vec, xf[ii], yf[ii], xdiff, ydiff & $
  endfor
end
