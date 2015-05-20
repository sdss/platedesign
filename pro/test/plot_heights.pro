pro plot_heights

nr=200L
radii= (findgen(nr)+0.5)/float(nr)*1.51
racen=180.
deccen=0.
ra= replicate(racen, 200L)
dec= deccen+radii

ad2xyfocal, 'APO', ra, dec, xf, yf, racen=racen, deccen=deccen, $
            /norefrac 

offset= findgen(10)/9.*90.
heights= [0.00, 36.26, $
          72.53, 108.84, $
          145.18, 181.53, $
          217.90, 254.29, $
          290.77, 327.44]
;;hfix= [0.000 , 0.003  , 0.005  , 0.006  , 0.006  , 0.004  , 0.001 , -0.004 , -0.010 , -0.021]
;;heights=heights*0.99975
;;heights= heights+hfix*4.

k_print, filename='heights.ps'

!P.MULTI=[2,1,2]

!Y.MARGIN=0

platescale = platescale('APO')

poff= (yf/platescale-dec)*3600.
joff= (heights/platescale-offset/60.)*3600.
sinoffset= asin(offset/60.*!DPI/180.)*180.*60./!DPI
joffsin= (heights/platescale-sinoffset/60.)*3600.
poffinterp= interpol(poff, dec*60., sinoffset)

rcoeffs=[-0.000137627D, -0.00125238D, 1.5447D-09, 8.23673D-08, $
         -2.74584D-13, -1.53239D-12, 6.04194D-18, 1.38033D-17, $
         -2.97064D-23, -3.58767D-23] 
rfocal=dec*platescale
correction=replicate(rcoeffs[0], n_elements(rfocal))
for i=1L, n_elements(rcoeffs)-1L do begin
    correction=correction+rcoeffs[i]*((double(rfocal))^(double(i)))
endfor
rfocal= rfocal+correction
roff= (rfocal/platescale-dec)*3600.
roffinterp= interpol(roff, dec*60., offset)

djs_plot, dec*60., poff, $
          xra=[-0.05, 95.], yra=[-3.1, 14.], $
          xtitle='!6radius from center (arcmin)', $
          ytitle='!6distortion (arcsec)', $
          /leftaxis, title='Assuming Jim heights are versus radius on sphere', $
          charsize=0.9
djs_oplot, offset, joff, psym=4
djs_plot, offset, joff-poffinterp, $
          xra=[-0.05, 95.], yra=[-2.1, 2.1], $
          xtitle='!6radius from center (arcmin)', $
          ytitle='!6(jim-plate) (arcsec)', $
          charsize=0.9

djs_plot, dec*60., poff, $
          xra=[-0.05, 95.], yra=[-3.1, 14.], $
          xtitle='!6radius from center (arcmin)', $
          ytitle='!6distortion (arcsec)', $
          /leftaxis, title='Assuming Jim heights are versus sin of radius', $
          charsize=0.9
djs_oplot, offset, joffsin, psym=4
djs_plot, offset, joffsin-poffinterp, $
          xra=[-0.05, 95.], yra=[-2.1, 2.1], $
          xtitle='!6radius from center (arcmin)', $
          ytitle='!6(jim-plate) (arcsec)', $
          charsize=0.9

djs_plot, dec*60., roff, $
          xra=[-0.05, 95.], yra=[-3.1, 14.], $
          xtitle='!6radius from center (arcmin)', $
          ytitle='!6distortion (arcsec)', $
          /leftaxis, title='Assuming Jim heights are versus sin of radius', $
          charsize=0.9
djs_oplot, offset, joffsin, psym=4
djs_plot, offset, joffsin-roffinterp, $
          xra=[-0.05, 95.], yra=[-2.1, 2.1], $
          xtitle='!6radius from center (arcmin)', $
          ytitle='!6(jim-plate) (arcsec)', $
          charsize=0.9

k_end_print

end
