;+
; NAME:
;   cmm_fit_plot
; PURPOSE:
;   Plot CMM fitting results
; CALLING SEQUENCE:
;   cmm_fit_plot
; REVISION HISTORY:
;   22-Sep-2008  MRB, NYU
;-
;------------------------------------------------------------------------------
pro cmm_fit_plot, tilt=tilt, squash=squash, fix=fix

postfix=''
if(keyword_set(tilt)) then $
   postfix=postfix+'_tilt'
if(keyword_set(squash)) then $
   postfix=postfix+'_squash'
if(keyword_set(fix)) then $
   postfix=postfix+'_fix'

cmm= mrdfits('cmm_fit_all'+postfix+'.fits',1)

k_print, filename='cmm_history'+postfix+'.ps', xsize= 10., ysize=10.

hogg_usersym, 20, /fill
djs_plot, cmm.mjd, 1000.*cmm.sig, xra=[52601., 55900.], $
  yra=[-0.001, 0.016]*1000., xtitle='MJD of measurement', $
  ytitle='Total residual after scale/shift/rotate (microns)', $
  psym=8, symsize=0.45, xcharsize=0.9, ycharsize=1.2


month='09'
day='09'
year='2010'
mjd= julday(month,day,year)-2400000L
djs_oplot,[mjd, mjd], [-1000., 1000.], th=2, color='grey'
djs_xyouts, mjd, !Y.CRANGE[0], year+'-'+month+'-'+day, orient=90. , $
  charsize=0.7

month='05'
day='01'
year='2010'
mjd= julday(month,day,year)-2400000L
djs_oplot,[mjd, mjd], [-1000., 1000.], th=2, color='grey'
djs_xyouts, mjd, !Y.CRANGE[0], year+'-'+month+'-'+day, orient=90. , $
  charsize=0.7

month='12'
day='17'
year='2010'
mjd= julday(month,day,year)-2400000L
djs_oplot,[mjd, mjd], [-4000., 4000.], th=2, color='grey'
djs_xyouts, mjd, !Y.CRANGE[0], year+'-'+month+'-'+day, orient=90. , $
  charsize=0.6

k_end_print

k_print, filename='cmm_fit_history'+postfix+'.ps', xsize= 14., ysize=14.

if(keyword_set(tilt)) then begin
   !P.MULTI=[7,1,7]
endif else if(keyword_set(squash)) then begin
   !P.MULTI=[6,1,6]
endif else begin
   !P.MULTI=[4,1,4]
endelse
!Y.MARGIN=0
!x.MARGIN=[10,0]

csize=1.5

hogg_usersym, 20, /fill
djs_plot, cmm.mjd, 1000.*cmm.xoff, xra=[52601., 55900.], $
  yra=[-0.39, 0.39]*1000., xtitle='MJD of measurement', $
  ytitle='X-shift (microns)', $
  psym=8, symsize=0.45, xcharsize=0.0001, ycharsize=csize


month='09'
day='09'
year='2010'
mjd= julday(month,day,year)-2400000L
djs_oplot,[mjd, mjd], [-1000., 1000.], th=2, color='grey'
djs_xyouts, mjd, !Y.CRANGE[0], year+'-'+month+'-'+day, orient=90. , $
  charsize=0.6

month='05'
day='01'
year='2010'
mjd= julday(month,day,year)-2400000L
djs_oplot,[mjd, mjd], [-1000., 1000.], th=2, color='grey'
djs_xyouts, mjd, !Y.CRANGE[0], year+'-'+month+'-'+day, orient=90. , $
  charsize=0.6

month='12'
day='17'
year='2010'
mjd= julday(month,day,year)-2400000L
djs_oplot,[mjd, mjd], [-4000., 4000.], th=2, color='grey'
djs_xyouts, mjd, !Y.CRANGE[0], year+'-'+month+'-'+day, orient=90. , $
  charsize=0.6

hogg_usersym, 20, /fill
djs_plot, cmm.mjd, 1000.*cmm.yoff, xra=[52601., 55900.], $
  yra=[-0.39, 0.39]*1000., xtitle='MJD of measurement', $
  ytitle='Y-shift (microns)', $
  psym=8, symsize=0.45, xcharsize=0.0001, ycharsize=csize


month='09'
day='09'
year='2010'
mjd= julday(month,day,year)-2400000L
djs_oplot,[mjd, mjd], [-1000., 1000.], th=2, color='grey'
djs_xyouts, mjd, !Y.CRANGE[0], year+'-'+month+'-'+day, orient=90. , $
  charsize=0.6

month='05'
day='01'
year='2010'
mjd= julday(month,day,year)-2400000L
djs_oplot,[mjd, mjd], [-1000., 1000.], th=2, color='grey'
djs_xyouts, mjd, !Y.CRANGE[0], year+'-'+month+'-'+day, orient=90. , $
  charsize=0.6

month='12'
day='17'
year='2010'
mjd= julday(month,day,year)-2400000L
djs_oplot,[mjd, mjd], [-4000., 4000.], th=2, color='grey'
djs_xyouts, mjd, !Y.CRANGE[0], year+'-'+month+'-'+day, orient=90. , $
  charsize=0.6

hogg_usersym, 20, /fill
djs_plot, cmm.mjd, cmm.angle*180./!DPI, xra=[52601., 55900.], $
  yra=[-0.01, 0.01], xtitle='MJD of measurement', $
  ytitle='Angle (deg)', $
  psym=8, symsize=0.45, xcharsize=0.0001, ycharsize=csize


month='09'
day='09'
year='2010'
mjd= julday(month,day,year)-2400000L
djs_oplot,[mjd, mjd], [-1000., 1000.], th=2, color='grey'
djs_xyouts, mjd, !Y.CRANGE[0], year+'-'+month+'-'+day, orient=90. , $
  charsize=0.6

month='05'
day='01'
year='2010'
mjd= julday(month,day,year)-2400000L
djs_oplot,[mjd, mjd], [-1000., 1000.], th=2, color='grey'
djs_xyouts, mjd, !Y.CRANGE[0], year+'-'+month+'-'+day, orient=90. , $
  charsize=0.6

month='12'
day='17'
year='2010'
mjd= julday(month,day,year)-2400000L
djs_oplot,[mjd, mjd], [-4000., 4000.], th=2, color='grey'
djs_xyouts, mjd, !Y.CRANGE[0], year+'-'+month+'-'+day, orient=90. , $
  charsize=0.6

last= keyword_set(tilt) eq 0 AND keyword_set(squash) eq 0
hogg_usersym, 20, /fill
djs_plot, cmm.mjd, cmm.scale-1., xra=[52601., 55900.], $
  yra=[-0.0001, 0.0001], xtitle='MJD of measurement', $
  ytitle='Scale factor - 1', $
  psym=8, symsize=0.45, xcharsize=csize*(1.*last+0.001), $
  ycharsize=csize


month='09'
day='09'
year='2010'
mjd= julday(month,day,year)-2400000L
djs_oplot,[mjd, mjd], [-1000., 1000.], th=2, color='grey'
djs_xyouts, mjd, !Y.CRANGE[0], year+'-'+month+'-'+day, orient=90. , $
  charsize=0.6

month='05'
day='01'
year='2010'
mjd= julday(month,day,year)-2400000L
djs_oplot,[mjd, mjd], [-1000., 1000.], th=2, color='grey'
djs_xyouts, mjd, !Y.CRANGE[0], year+'-'+month+'-'+day, orient=90. , $
  charsize=0.6

month='12'
day='17'
year='2010'
mjd= julday(month,day,year)-2400000L
djs_oplot,[mjd, mjd], [-4000., 4000.], th=2, color='grey'
djs_xyouts, mjd, !Y.CRANGE[0], year+'-'+month+'-'+day, orient=90. , $
  charsize=0.6

if(keyword_set(tilt)) then begin
   hogg_usersym, 20, /fill
   djs_plot, cmm.mjd, abs(cmm.tilt*180./!DPI), xra=[52601., 55900.], $
             yra=[-0.2, 1.22], xtitle='MJD of measurement', $
             ytitle='Tilt (deg)', $
             psym=8, symsize=0.45, xcharsize=0.001, ycharsize=csize
   
   month='09'
   day='09'
   year='2010'
   mjd= julday(month,day,year)-2400000L
   djs_oplot,[mjd, mjd], [-1000., 1000.], th=2, color='grey'
   djs_xyouts, mjd, !Y.CRANGE[0], year+'-'+month+'-'+day, orient=90. , $
               charsize=0.6
   
   month='05'
   day='01'
   year='2010'
   mjd= julday(month,day,year)-2400000L
   djs_oplot,[mjd, mjd], [-1000., 1000.], th=2, color='grey'
   djs_xyouts, mjd, !Y.CRANGE[0], year+'-'+month+'-'+day, orient=90. , $
               charsize=0.6
   
   month='12'
   day='17'
   year='2010'
   mjd= julday(month,day,year)-2400000L
   djs_oplot,[mjd, mjd], [-4000., 4000.], th=2, color='grey'
   djs_xyouts, mjd, !Y.CRANGE[0], year+'-'+month+'-'+day, orient=90. , $
               charsize=0.6

   hogg_usersym, 20, /fill
   djs_plot, cmm.mjd, cmm.rtilt, xra=[52601., 55900.], $
             yra=[-3.02, 3000.02], xtitle='MJD of measurement', $
             ytitle='R_{tilt} (mm)', $
             psym=8, symsize=0.45, xcharsize=0.001, ycharsize=csize
   
   month='09'
   day='09'
   year='2010'
   mjd= julday(month,day,year)-2400000L
   djs_oplot,[mjd, mjd], [-4000., 4000.], th=2, color='grey'
   djs_xyouts, mjd, !Y.CRANGE[0], year+'-'+month+'-'+day, orient=90. , $
               charsize=0.6
   
   month='05'
   day='01'
   year='2010'
   mjd= julday(month,day,year)-2400000L
   djs_oplot,[mjd, mjd], [-4000., 4000.], th=2, color='grey'
   djs_xyouts, mjd, !Y.CRANGE[0], year+'-'+month+'-'+day, orient=90. , $
               charsize=0.6
   
   month='12'
   day='17'
   year='2010'
   mjd= julday(month,day,year)-2400000L
   djs_oplot,[mjd, mjd], [-4000., 4000.], th=2, color='grey'
   djs_xyouts, mjd, !Y.CRANGE[0], year+'-'+month+'-'+day, orient=90. , $
               charsize=0.6

   hogg_usersym, 20, /fill
   thout= (cmm.thtilt*180./!DPI+720.) mod 360
   ithout= where(thout gt 180., nthout) 
   if(nthout gt 0) then $
     thout[ithout]= thout[ithout]-180.
   djs_plot, cmm.mjd, thout, xra=[52601., 55900.], $
             yra=[-0.99, 180.99], xtitle='MJD of measurement', $
             ytitle='\theta_{tilt} (deg)', $
             psym=8, symsize=0.45, xcharsize=csize, ycharsize=csize
   
   month='09'
   day='09'
   year='2010'
   mjd= julday(month,day,year)-2400000L
   djs_oplot,[mjd, mjd], [-1000., 1000.], th=2, color='grey'
   djs_xyouts, mjd, !Y.CRANGE[0], year+'-'+month+'-'+day, orient=90. , $
               charsize=0.6
   
   month='05'
   day='01'
   year='2010'
   mjd= julday(month,day,year)-2400000L
   djs_oplot,[mjd, mjd], [-1000., 1000.], th=2, color='grey'
   djs_xyouts, mjd, !Y.CRANGE[0], year+'-'+month+'-'+day, orient=90. , $
               charsize=0.6
   
   month='12'
   day='17'
   year='2010'
   mjd= julday(month,day,year)-2400000L
   djs_oplot,[mjd, mjd], [-4000., 4000.], th=2, color='grey'
   djs_xyouts, mjd, !Y.CRANGE[0], year+'-'+month+'-'+day, orient=90. , $
               charsize=0.6
   
endif else if(keyword_set(squash)) then begin
   hogg_usersym, 20, /fill
   djs_plot, cmm.mjd, alog10(1.-cmm.axisratio), xra=[52601., 55900.], $
             yra=[-5.4, -3.9], xtitle='MJD of measurement', $
             ytitle='log_{10}(!81-b/a!6)', $
             psym=8, symsize=0.45, xcharsize=0.001, ycharsize=csize
   
   month='09'
   day='09'
   year='2010'
   mjd= julday(month,day,year)-2400000L
   djs_oplot,[mjd, mjd], [-1000., 1000.], th=2, color='grey'
   djs_xyouts, mjd, !Y.CRANGE[0], year+'-'+month+'-'+day, orient=90. , $
               charsize=0.6
   
   month='05'
   day='01'
   year='2010'
   mjd= julday(month,day,year)-2400000L
   djs_oplot,[mjd, mjd], [-1000., 1000.], th=2, color='grey'
   djs_xyouts, mjd, !Y.CRANGE[0], year+'-'+month+'-'+day, orient=90. , $
               charsize=0.6
   
   month='12'
   day='17'
   year='2010'
   mjd= julday(month,day,year)-2400000L
   djs_oplot,[mjd, mjd], [-4000., 4000.], th=2, color='grey'
   djs_xyouts, mjd, !Y.CRANGE[0], year+'-'+month+'-'+day, orient=90. , $
               charsize=0.6

   hogg_usersym, 20, /fill
   thout= (cmm.theta*180./!DPI+720.) mod 360
   ithout= where(thout gt 180., nthout) 
   if(nthout gt 0) then $
     thout[ithout]= thout[ithout]-180.
   djs_plot, cmm.mjd, thout, xra=[52601., 55900.], $
             yra=[-0.99, 180.99], xtitle='MJD of measurement', $
             ytitle='\theta (deg)', $
             psym=8, symsize=0.45, xcharsize=csize, ycharsize=csize
   
   month='09'
   day='09'
   year='2010'
   mjd= julday(month,day,year)-2400000L
   djs_oplot,[mjd, mjd], [-1000., 1000.], th=2, color='grey'
   djs_xyouts, mjd, !Y.CRANGE[0], year+'-'+month+'-'+day, orient=90. , $
               charsize=0.6
   
   month='05'
   day='01'
   year='2010'
   mjd= julday(month,day,year)-2400000L
   djs_oplot,[mjd, mjd], [-1000., 1000.], th=2, color='grey'
   djs_xyouts, mjd, !Y.CRANGE[0], year+'-'+month+'-'+day, orient=90. , $
               charsize=0.6
   
   month='12'
   day='17'
   year='2010'
   mjd= julday(month,day,year)-2400000L
   djs_oplot,[mjd, mjd], [-4000., 4000.], th=2, color='grey'
   djs_xyouts, mjd, !Y.CRANGE[0], year+'-'+month+'-'+day, orient=90. , $
               charsize=0.6
   
endif

k_end_print

spawn, /nosh, ['convert', 'cmm_history'+postfix+'.ps', '-quality', '100', 'cmm_history'+postfix+'.jpg']
spawn, /nosh, ['convert', 'cmm_fit_history'+postfix+'.ps', '-quality', '100', 'cmm_fit_history'+postfix+'.jpg']

openw, unit, 'cmm'+postfix+'.html', /get_lun

printf, unit, '<html>'


printf, unit, '<p><a href="cmm_fit_all'+postfix+ $
        '.fits">Full results in FITS format</a>'
printf, unit, '<p><a href="cmm_history'+postfix+'.jpg"></p>'
printf, unit, '<img src="cmm_history'+postfix+'.jpg" width=500 /></a></p>'
printf, unit, '<p><a href="cmm_fit_history'+postfix+'.jpg"></p>'
printf, unit, '<img src="cmm_fit_history'+postfix+'.jpg" width=500 /></a></p>'

printf, unit, '<table>'
for j=0L, n_elements(cmm)-1L do begin
    
    outbase= 'cmm-'+strtrim(cmm[j].file,2)+postfix

    k_print, filename=outbase+'.ps', xsize=10., ysize=10.
    
    x= cmm[j].xnom[0:cmm[j].nhole-1]
    y= cmm[j].ynom[0:cmm[j].nhole-1]
    dx= cmm[j].dxfit[0:cmm[j].nhole-1]
    dy= cmm[j].dyfit[0:cmm[j].nhole-1]

    djs_plot, x, y, psym=8, symsize=0.4, $
      xtitle='X (mm)', ytitle='Y (mm)', $
      title=strtrim(cmm[j].file,2)+' residuals from '+cmm[j].datestring+' (microns) ; sigma='+$
      strtrim(string(f='(f40.1)', cmm[j].sig*1000.),2), $
      xcharsize=0.95, ycharsize=0.95, charsize=0.95, $
      xra=[-330., 330.], yra=[-330., 330.]
    for i=0L, n_elements(x)-1L do begin
        djs_oplot, x[i]+[0.,dx[i]]*1000., $
          y[i]+[0.,dy[i]]*1000.
    endfor
    
    k_end_print

    spawn, /nosh, ['convert', outbase+'.ps', '-quality', '100', outbase+'.jpg']
    spawn, /nosh, ['convert', outbase+'.jpg', '-geometry', '200', outbase+'.thumb.jpg']

    k_print, filename=outbase+'-justshift.ps', xsize=10., ysize=10.
    
    x= cmm[j].xnom[0:cmm[j].nhole-1]
    y= cmm[j].ynom[0:cmm[j].nhole-1]
    dx= cmm[j].dx[0:cmm[j].nhole-1]-cmm[j].xoff
    dy= cmm[j].dy[0:cmm[j].nhole-1]-cmm[j].yoff

    djs_plot, x, y, psym=8, symsize=0.4, $
      xtitle='X (mm)', ytitle='Y (mm)', $
      title=strtrim(cmm[j].file,2)+' residuals from '+cmm[j].datestring+' (microns) ; sigma='+$
      strtrim(string(f='(f40.1)', cmm[j].sig*1000.),2), $
      xcharsize=0.95, ycharsize=0.95, charsize=0.95, $
      xra=[-330., 330.], yra=[-330., 330.]
    for i=0L, n_elements(x)-1L do begin
        djs_oplot, x[i]+[0.,dx[i]]*1000., $
          y[i]+[0.,dy[i]]*1000.
    endfor
    
    k_end_print

    spawn, /nosh, ['convert', outbase+'-justshift.ps', '-quality', '100', outbase+'-justshift.jpg']
    spawn, /nosh, ['convert', outbase+'-justshift.jpg', '-geometry', '200', outbase+'-justshift.thumb.jpg']

    if((j mod 5) eq 0) then $
      printf, unit, '<tr>'
    
    printf, unit, '<td>'
    printf, unit, '<a href="'+outbase+'.jpg">'
    printf, unit, '<img src="'+outbase+'.thumb.jpg" />'
    printf, unit, '</a>'
    printf, unit, '</td>'
    
    if((j mod 5) eq 4 OR j eq n_elements(cmm)-1L) then $
      printf, unit, '</tr>'
    
endfor
printf, unit, '</table>'

printf, unit, '</html>'

free_lun, unit

end
