;+
; NAME:
;   ha_quick
; PURPOSE:
;   Quickly determine HA limits of plate position
; CALLING SEQUENCE:
;   ha_quick, racen, deccen, ha, hamin=, hamax=, maxoff_arcsec=, /plot
;      [, haact= ]
; REQUIRED INPUTS:
;   plateid - plate ID number
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
pro ha_quick, racen, deccen, ha, hamin=hamin, hamax=hamax, $
              maxoff_arcsec=maxoff_arcsec, lambda_eff=lambda_eff, $
              plot=plot, haact=haact, noscale=noscale, $
              tilerad=tilerad, ralim=ralim, declim=declim, $
              rafter=rafter
              

platescale = 217.7358D           ; mm/degree
if(NOT keyword_set(tilerad)) then $
  tilerad=1.49D
if(NOT keyword_set(ralim)) then $
  ralim=tilerad*2.
if(NOT keyword_set(declim)) then $
  declim=tilerad*2.
if(NOT keyword_set(rafter)) then $
  rafter=0.

if(NOT keyword_set(lambda_eff)) then lambda_eff=5400.
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
xyfocal2ad, xtest, ytest, ratest, dectest, racen=racen, deccen=deccen, $
            airtemp=airtemp, lst=lst, lambda=ltest
xyfocal2ad, oxtest, oytest, oratest, odectest, racen=racen, deccen=deccen, $
            airtemp=airtemp, lst=lst, lambda=ltest

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
    ad2xyfocal, ratest, dectest, try_xf, try_yf, racen=racen, deccen=deccen, $
                airtemp=airtemp, lst=try_lst, lambda=ltest
    ad2xyfocal, oratest, odectest, otry_xf, otry_yf, $
                racen=racen, deccen=deccen, $
                airtemp=airtemp, lst=try_lst, lambda=ltest
    
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
      message, 'No valid HA choices close enough to design HA??'
    hamin= min(int_ha[iok])
    hamax= max(int_ha[iok])
    
    if(keyword_set(plot)) then begin
        splot, int_ha, int_maxdist, xra=[-30., 30.]
        soplot, try_ha, try_maxdist, psym=4
        soplot, [min(try_ha), max(try_ha)], [max_off, max_off], color='red'
        soplot, [hamin, hamin], $
                [0., max_off], color='red'
        soplot, [hamax, hamax], $
                [0., max_off], color='red'
    endif
endif else begin
    if(keyword_set(plot)) then begin
        dx= (try_xf-xtest)
        dy= (try_yf-ytest)
        splot_vec, xtest, ytest, dx, dy, scale=1000., $
                   xra=tilerad*platescale*1.05*[-1.,1.], $
                   yra=tilerad*platescale*1.05*[-1.,1.]
    endif
endelse

end
