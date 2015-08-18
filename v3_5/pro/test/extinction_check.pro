pro extinction_check

files= file_search('plPlugMapP-*.par')

;red_fac = [5.155, 3.793, 2.751, 2.086, 1.479 ]
red_fac = reddening()
 
for i=0L, n_elements(files)-1L do begin
    pl=yanny_readone(files[i], hdr=hdr)
    hdrstr= lines2struct(hdr, /relax)
    glactc, double(hdrstr.racen), double(hdrstr.deccen), 2000., $
      gl, gb, 1, /deg
    ebv= dust_getval(gl, gb)
    splog, files[i]+': extinction= '+ $
      strtrim(string(f='(f40.3)', red_fac[0]*ebv),2)+' '+ $
      strtrim(string(f='(f40.3)', red_fac[1]*ebv),2)+' '+ $
      strtrim(string(f='(f40.3)', red_fac[2]*ebv),2)+' '+ $
      strtrim(string(f='(f40.3)', red_fac[3]*ebv),2)+' '+ $
      strtrim(string(f='(f40.3)', red_fac[4]*ebv),2)
endfor


end
