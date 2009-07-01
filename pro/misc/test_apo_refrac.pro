pro test_apo_refrac

files= file_search('/global/data/sdss/tiling/opdb/drillRuns/dr*.[0-9]/plPlugMapP-*.par')

k_print, filename='apo_refrac.ps'

!P.MULTI=[2,1,2]

temparr= fltarr(n_elements(files))
haminarr= fltarr(n_elements(files))
sigdiffarr= fltarr(n_elements(files))
maxdiffarr= fltarr(n_elements(files))
sdiffarr= fltarr(n_elements(files))
sigsdiffarr= fltarr(n_elements(files))
maxsdiffarr= fltarr(n_elements(files))
for i=0L, n_elements(files)-1L do begin
    pl= yanny_readone(files[i], hdr=hdr)
    hdrstr= lines2struct(hdr)
    racen= double(hdrstr.racen)
    deccen= double(hdrstr.deccen)
    temp= double(hdrstr.temp)
    hamin= double(hdrstr.hamin)
    
    lst= racen+ hamin
    
    ad2xyfocal, pl.ra, pl.dec, xf, yf, racen=racen, deccen=deccen, $
      airtemp=temp, lst=lst
    
    ii=where(pl.holetype eq 'OBJECT', nii)

    if(nii gt 0) then begin
        xdiff= (xf[ii]-pl[ii].xfocal)*1000.
        ydiff= (yf[ii]-pl[ii].yfocal)*1000.
        scale= sqrt(xf[ii]^2+yf[ii]^2)/ $
          sqrt(pl[ii].xfocal^2+pl[ii].yfocal^2)
        rdiff= sqrt(xdiff^2+ydiff^2)
        words= strsplit(files[i], '/', /extr)
        ff= words[n_elements(words)-1]
        plothist, rdiff, xra=[0.,60.], title=ff, $
          xtitle= 'offset (microns)', ytitle='Nfiber', $
          xcharsize=0.0001
        temparr[i]=temp
        haminarr[i]=hamin
        sigdiffarr[i]=total(rdiff^2)/float(n_elements(rdiff))
        maxdiffarr[i]=max(rdiff)
        sdiffarr[i]=median(scale)
        
        xsdiff= (xf[ii]-pl[ii].xfocal*sdiffarr[i])*1000.
        ysdiff= (yf[ii]-pl[ii].yfocal*sdiffarr[i])*1000.
        rsdiff= sqrt(xsdiff^2+ysdiff^2)
        sigsdiffarr[i]=total(rsdiff^2)/float(n_elements(rsdiff))
        maxsdiffarr[i]=max(rsdiff)

        plothist, rsdiff, xra=[0.,60.], $
          xtitle= 'scaled offset (microns)', ytitle='Nfiber'
        xst=!X.CRANGE[0]+0.6*(!X.CRANGE[1]-!X.CRANGE[0])
        yst=!Y.CRANGE[0]+0.8*(!Y.CRANGE[1]-!Y.CRANGE[0])
        djs_xyouts, xst, yst, 'Scaling of '+$
          strtrim(string(f='(f40.6)', sdiffarr[i]),2)
        
    endif
    
endfor
k_end_print

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
    ad2xyfocal, pl.ra, pl.dec, xf, yf, racen=racen, deccen=deccen, $
      airtemp=temp, lst=lst & $
    ii=where(pl.holetype eq 'OBJECT', nii) & $
       xdiff= (xf[ii]-pl[ii].xfocal)*1000. & $
        ydiff= (yf[ii]-pl[ii].yfocal)*1000. & $
splot_vec, xf[ii], yf[ii], xdiff, ydiff & $
  endfor
end
