pro test_ad2xy, plfile

platescale= platescale('APO')

pl= yanny_readone(plfile, hdr=hdr)
hstr= lines2struct(hdr)

help,/st,hstr

ad2xyfocal, 'APO', pl.ra, pl.dec, xf, yf, racen= double(hstr.racen), $
  deccen=double(hstr.deccen), airtemp= double(hstr.temp), $
  lst=double(hstr.racen) +double(hstr.hamin)

ad2xyfocal, 'APO', pl.ra, pl.dec, xf2, yf2, racen= double(hstr.racen), $
  deccen=double(hstr.deccen), airtemp= double(hstr.temp), $
  lst=double(hstr.racen)

;;ad2xyfocal, pl.ra, pl.dec, xf2, yf2, racen= double(hstr.racen), $
  ;;deccen=double(hstr.deccen), airtemp= double(hstr.temp), $
  ;;lst=double(hstr.racen)

ii=where(pl.ra ne 0.)

splot_vec, pl[ii].xfocal, pl[ii].yfocal, $
  (xf[ii]-xf2[ii])*500., $
  (yf[ii]-yf2[ii])*500.
return
;;splot, $
;;  (xf[ii]-xf2[ii])/platescale*3600., $
;;  (yf[ii]-yf2[ii])/platescale*3600.

;;splot, (pl[ii].xfocal- 1./1.*xf[ii])/platescale*3600., $
  ;;(pl[ii].yfocal- 1./1.*yf[ii])/platescale*3600., $
  ;;psym=3

print, sqrt(total( (pl[ii].xfocal- 1./1.*xf[ii])^2)/n_elements(ii))/ $
  platescale*3600.
print, sqrt(total( (pl[ii].yfocal- 1./1.*yf[ii])^2)/n_elements(ii))/ $
  platescale*3600.
splot_vec, pl[ii].xfocal, pl[ii].yfocal, $
  (pl[ii].xfocal- 1./1.*xf[ii])*500., $
  (pl[ii].yfocal- 1./1.*yf[ii])*500.

return


plate_refrac, 'APO', pl.ra, pl.dec, double(hstr.racen), $
  double(hstr.deccen), rar, decr, airtemp=double(hstr.temp), $
  lst=double(hstr.racen)+double(hstr.hamin)

splot, (rar- pl.ra)*3600., (decr-pl.dec)*3600., psym=3
splot_vec, pl[ii].ra, pl[ii].dec, $
  (rar[ii]-pl[ii].ra)*500., $
  (decr[ii]-pl[ii].dec)*500.

end
