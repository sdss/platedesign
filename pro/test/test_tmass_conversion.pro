;; code to test 2mass->sdss conversion for GUIDEs
pro test_tmass_conversion

;;objs= sdss_sweep_circle(10., 15., 1.5)
objs= sdss_sweep_circle(180., 0., 1.5)

gmr= -2.5*alog10(objs.psfflux[1]/objs.psfflux[2])
rmi= -2.5*alog10(objs.psfflux[2]/objs.psfflux[3])

umag=22.5-2.5*alog10(objs.psfflux[0]) 
gmag=22.5-2.5*alog10(objs.psfflux[1]) 
rmag=22.5-2.5*alog10(objs.psfflux[2]) 
imag=22.5-2.5*alog10(objs.psfflux[3]) 
zmag=22.5-2.5*alog10(objs.psfflux[4]) 
ii= where(gmag lt 16.5)
jj= where(gmag lt 16.5 AND objs.tmass_j ne 0. AND $
          umag eq umag AND $
          rmag eq rmag AND $
          imag eq imag AND $
          zmag eq zmag )


tmag= plate_tmass_to_sdss(objs[jj].tmass_j, objs[jj].tmass_h, $
                          objs[jj].tmass_k)
tgmr= tmag[1,*]-tmag[2,*]
trmi= tmag[2,*]-tmag[3,*]

k_print, filename='test_tmass_conversion.ps'

djs_plot, gmr[ii], rmi[ii], psym=4, xra=[-0.1, 1.7], yra=[-0.1, 0.99], $
  xtitle='!8g-r!6', ytitle='!8r-i!6'
djs_oplot, gmr[jj], rmi[jj], psym=4, color='red'
djs_oplot, tgmr, trmi, psym=4, color='green'

djs_plot, gmr[ii], gmag[ii], psym=4, xra=[-0.1, 1.7], yra=[16.5, 12.], $
  xtitle='!8g!6', ytitle='!8g-r!6'
djs_oplot, gmr[jj], gmag[jj], psym=4, color='red'
djs_oplot, tgmr, tmag[1,*], psym=4, color='green'

djs_plot, gmag[jj], tmag[1,*]-gmag[jj], psym=4, xra=[16.5, 12.], $
  yra=[-3., 0.5], xtitle='!8g!6 (SDSS)', ytitle='!8g!6(2MASS) - !8g!6(SDSS)'

djs_plot, gmr[jj], tmag[1,*]-gmag[jj], psym=4, xra=[-0.1, 1.7], $
  yra=[-3., 0.5], xtitle='!8g-r!6 (SDSS)', ytitle='!8g!6(2MASS) - !8g!6(SDSS)'

djs_plot, tmag[1,*], objs[jj].tmass_j-objs[jj].tmass_k, psym=4, $
  xra=[16.5, 12.], $
  yra=[-1., 1.5], xtitle='!8g!6 (2MASS)', ytitle='!8J-K!6'

jmk=objs[jj].tmass_j-objs[jj].tmass_k
mdiff=umag[jj]-objs[jj].tmass_j
aa=dblarr(2, n_elements(jj))
aa[0,*]=1.
aa[1,*]=(jmk-0.5)
hogg_iter_linfit, aa, mdiff, float(mdiff eq mdiff), coeffs, nsigma=4
djs_plot, jmk, mdiff, $
  psym=4, xra=[-0.1, 1.2], $
  yra=[-0.5, 4.5], ytitle='!8u-J!6', xtitle='!8J-K!6'
djs_oplot, [-0.1, 1.2], coeffs[0]+coeffs[1]*([-0.1,1.2]-0.5), th=4
print, coeffs

jmk=objs[jj].tmass_j-objs[jj].tmass_k
mdiff=gmag[jj]-objs[jj].tmass_j
aa=dblarr(2, n_elements(jj))
aa[0,*]=1.
aa[1,*]=(jmk-0.5)
hogg_iter_linfit, aa, mdiff, float(mdiff eq mdiff), coeffs, nsigma=4
djs_plot, jmk, mdiff, $
  psym=4, xra=[-0.1, 1.2], $
  yra=[-0.5, 3.5], ytitle='!8g-J!6', xtitle='!8J-K!6'
djs_oplot, [-0.1, 1.2], coeffs[0]+coeffs[1]*([-0.1,1.2]-0.5), th=4
print, coeffs

jmk=objs[jj].tmass_j-objs[jj].tmass_k
mdiff=rmag[jj]-objs[jj].tmass_j
aa=dblarr(2, n_elements(jj))
aa[0,*]=1.
aa[1,*]=(jmk-0.5)
hogg_iter_linfit, aa, mdiff, float(mdiff eq mdiff), coeffs, nsigma=4
djs_plot, jmk, mdiff, $
  psym=4, xra=[-0.1, 1.2], $
  yra=[-0.5, 3.5], ytitle='!8r-J!6', xtitle='!8J-K!6'
djs_oplot, [-0.1, 1.2], coeffs[0]+coeffs[1]*([-0.1,1.2]-0.5), th=4
print, coeffs

jmk=objs[jj].tmass_j-objs[jj].tmass_k
mdiff=imag[jj]-objs[jj].tmass_j
aa=dblarr(2, n_elements(jj))
aa[0,*]=1.
aa[1,*]=(jmk-0.5)
hogg_iter_linfit, aa, mdiff, float(mdiff eq mdiff), coeffs, nsigma=4
djs_plot, jmk, mdiff, $
  psym=4, xra=[-0.1, 1.2], $
  yra=[-0.5, 3.5], ytitle='!8i-J!6', xtitle='!8J-K!6'
djs_oplot, [-0.1, 1.2], coeffs[0]+coeffs[1]*([-0.1,1.2]-0.5), th=4
print, coeffs

jmk=objs[jj].tmass_j-objs[jj].tmass_k
mdiff=zmag[jj]-objs[jj].tmass_j
aa=dblarr(2, n_elements(jj))
aa[0,*]=1.
aa[1,*]=(jmk-0.5)
hogg_iter_linfit, aa, mdiff, float(mdiff eq mdiff), coeffs, nsigma=4
djs_plot, jmk, mdiff, $
  psym=4, xra=[-0.1, 1.2], $
  yra=[-0.5, 3.5], ytitle='!8z-J!6', xtitle='!8J-K!6'
djs_oplot, [-0.1, 1.2], coeffs[0]+coeffs[1]*([-0.1,1.2]-0.5), th=4
print, coeffs
  
k_end_print


end
