;+
; NAME:
;   ha_quick
; PURPOSE:
;   Quickly determine HA limits of plate position
; CALLING SEQUENCE:
;   ha_quick, observatory, racen, deccen, ha, hamin=, hamax=, maxoff_arcsec=, /plot
;      [, haact= ]
; REQUIRED INPUTS:
;   observatory - 'APO' or 'LCO'
;   ra, dec - plate location
;   ha - drilling hour angle
; OPTIONAL INPUTS:
;   maxoff_arcsec - maximum offset required, arcsec (default 0.3)
;   lambda_eff - wavelength to check, angstrom (default 5400.)
;   haact - a single actual HA to try 
;   tilerad - tile radius to assume, deg (default 1.49)
;   ralim, declim - limits in ra/dec offset (default unlimited)
; OUTPUTS:
;   hamin, hamax - minimum and maximum HAs (unless haact is set)
; OPTIONAL KEYWORDS:
;   /plot - creates a splot window with results
;   /noscale - do not take out rotation scale or offset
; COMMENTS:
;   Automatically takes out rotation, scale, and offset, unless
;     /noscale is set.
;   If "haact" is set on input, it tries exactly one actual HA, 
;    and plots the distribution of offsets in the focal plane.
; REVISION HISTORY:
;   20-Oct-2008  MRB, NYU
;-
pro ha_quick, observatory, racen, deccen, ha, hamin=hamin, hamax=hamax, $
              maxoff_arcsec=maxoff_arcsec, lambda_eff=lambda_eff, $
              plot=plot, haact=haact, noscale=noscale, $
              tilerad=tilerad, ralim=ralim, declim=declim, $
              rafter=rafter, lambda_cen=lambda_cen, _EXTRA=extra_for_plot
              
if(size(observatory,/tname) ne 'STRING') then $
  message, 'observatory must be set to STRING type, with value "LCO" or "APO"'

if(strupcase(observatory) ne 'APO' and $
   strupcase(observatory) ne 'LCO') then $
  message, 'Must set observatory to APO or LCO'

if(strupcase(observatory) eq 'APO') then begin
    if(NOT keyword_set(tilerad)) then $
      tilerad=1.49D
endif

if(strupcase(observatory) eq 'LCO') then begin
    if(NOT keyword_set(tilerad)) then $
      tilerad=0.95D
endif

platescale = get_platescale(observatory)

if(NOT keyword_set(ralim)) then $
  ralim=tilerad*2.
if(NOT keyword_set(declim)) then $
  declim=tilerad*2.
if(NOT keyword_set(rafter)) then $
  rafter=0.

if(NOT keyword_set(lambda_eff)) then lambda_eff=5400.
if(NOT keyword_set(lambda_cen)) then lambda_cen=lambda_eff
if(NOT keyword_set(maxoff_arcsec)) then maxoff_arcsec=0.3
airtemp=5.

;; set up test locations
ntestper=60L
th= !DPI*2.*(dindgen(ntestper)+0.5)/float(ntestper)
rads= [0.98]
ntest=ntestper*n_elements(rads)
xtest=dblarr(ntest)
ytest=dblarr(ntest)
for i=0L, n_elements(rads)-1L do begin
    xtest[i*ntestper:(i+1L)*ntestper-1]= $
      rads[i]*tilerad*cos(th)*platescale
    ytest[i*ntestper:(i+1L)*ntestper-1]= $
      rads[i]*tilerad*sin(th)*platescale
endfor
ltest= replicate(lambda_eff, ntest)
lcen= replicate(lambda_cen, ntest)

oxtest= xtest
oytest= ytest
xtestr= xtest*cos(rafter/180.*!DPI)+ ytest*sin(rafter/180.*!DPI)
ytestr= -xtest*sin(rafter/180.*!DPI)+ ytest*cos(rafter/180.*!DPI)
xtestr= (xtestr<(ralim*platescale))>(-ralim*platescale)
ytestr= (ytestr<(declim*platescale))>(-declim*platescale)
xtest= xtestr*cos(-rafter/180.*!DPI)+ ytestr*sin(-rafter/180.*!DPI)
ytest= -xtestr*sin(-rafter/180.*!DPI)+ ytestr*cos(-rafter/180.*!DPI)

;; get ra/decs
lst= racen+ ha
xyfocal2ad, observatory, xtest, ytest, ratest, dectest, racen=racen, deccen=deccen, $
            airtemp=airtemp, lst=lst, lambda=ltest
xyfocal2ad, observatory, oxtest, oytest, oratest, odectest, racen=racen, deccen=deccen, $
            airtemp=airtemp, lst=lst, lambda=lcen

;; cycle through HA values
if(n_elements(haact) eq 0) then begin
    dtry=1.0
    max_ha_off=50.
    ntry= (long(2.*max_ha_off/dtry)/2L)*2L+1L
    try_ha= ha+(2.*(findgen(ntry)+0.5)/float(ntry)-1.)*max_ha_off
    try_maxdist=fltarr(ntry)
endif else begin
    ntry= 1L
    try_ha= haact[0]
    try_maxdist=fltarr(ntry)
 endelse
for i=0L, ntry-1L do begin
    try_lst= racen+try_ha[i]
    ad2xyfocal, observatory, ratest, dectest, try_xf, try_yf, racen=racen, deccen=deccen, $
                airtemp=airtemp, lst=try_lst, lambda=ltest
    ad2xyfocal, observatory, oratest, odectest, otry_xf, otry_yf, $
                racen=racen, deccen=deccen, $
                airtemp=airtemp, lst=try_lst, lambda=lcen
    
    ;; rescale x's and y's to take out scale
    if(NOT keyword_set(noscale)) then begin
        ha_fit, oxtest, oytest, otry_xf, otry_yf, xnew=oxnew, ynew=oynew, $
                rot=rot, scale=scale, xshift=xshift, yshift=yshift
        ha_apply, try_xf, try_yf, xnew=xnew, ynew=ynew, $
                  rot=rot, scale=scale, xshift=xshift, yshift=yshift
        try_xf= xnew
        try_yf= ynew
    endif
    
    ;; find maximum distance
    dist= sqrt((xtest- try_xf)^2+ $
               (ytest- try_yf)^2)
    try_maxdist[i]= max(dist)
    if(abs(try_ha[i]-10.) lt 0.5) then print, try_maxdist[i]
    
endfor

if(n_elements(haact) eq 0) then begin
    
    ;; translate condition to mm
    max_off= float(maxoff_arcsec)*platescale/3600.
    
    ;; interpolate values
    dint=0.5
    nint= (long(2.*max_ha_off/dint)/2L)*2L+1L
    int_ha= ha+(2.*(findgen(nint)+0.5)/float(nint)-1.)*max_ha_off
    int_maxdist= interpol(try_maxdist, try_ha, int_ha)
    
    ;; apply condition
    ok_ha= int_maxdist lt max_off 
    iok= where(ok_ha, nok)
    if(nok eq 0) then $
       message, color_string('No valid HA choices close enough to design HA??','red', 'bold')
    cha = min(abs(int_ha - ha), icha)
    iha = icha
    while iha gt 0 do begin
       if(int_maxdist[iha - 1] gt max_off) then $
          break
       iha = iha - 1
    endwhile
    hamin = int_ha[iha]
    iha = icha
    while iha lt n_elements(int_maxdist) - 2L do begin
       if(int_maxdist[iha + 1] gt max_off) then $
          break
       iha = iha + 1
    endwhile
    hamax = int_ha[iha]
    
    if(keyword_set(plot)) then begin
        splot, int_ha, int_maxdist, xra=[-30., 30.], _EXTRA=extra_for_plot
        soplot, try_ha, try_maxdist, psym=4, _EXTRA=extra_for_plot
        soplot, [min(try_ha), max(try_ha)], [max_off, max_off], color='red', $
                _EXTRA=extra_for_plot
        soplot, [hamin, hamin], $
                [0., max_off], color='red', _EXTRA=extra_for_plot
        soplot, [hamax, hamax], $
                [0., max_off], color='red', _EXTRA=extra_for_plot
    endif
endif else begin
    if(keyword_set(plot)) then begin
        dx= (try_xf-xtest)
        dy= (try_yf-ytest)
        splot_vec, xtest, ytest, dx, dy, scale=1000., $
                   xra=tilerad*platescale*1.05*[-1.,1.], $
                   yra=tilerad*platescale*1.05*[-1.,1.], _EXTRA=extra_for_plot
    endif
endelse

end
