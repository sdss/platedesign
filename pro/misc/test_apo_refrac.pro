pro test_apo_refrac

pl= yanny_readone('plPlugMapP-1660.par', hdr=hdr)
hdrstr= lines2struct(hdr)
racen= double(hdrstr.racen)
deccen= double(hdrstr.deccen)
temp= double(hdrstr.temp)
hamin= double(hdrstr.hamin)

lst= racen+ hamin

ad2xyfocal, pl.ra, pl.dec, xf, yf, racen=racen, deccen=deccen, $
  airtemp=temp, lst=lst
  
ii=where(pl.holetype eq 'OBJECT')
splot_vec, pl[ii].xfocal, pl[ii].yfocal, $
  (xf[ii]-pl[ii].xfocal)*500., (yf[ii]-pl[ii].yfocal)*500.
  
rr= sqrt((xf[ii]-pl[ii].xfocal)^2+(yf[ii]-pl[ii].yfocal)^2)*1000.

end
