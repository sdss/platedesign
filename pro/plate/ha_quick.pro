;+
; NAME:
;   ha_quick
; PURPOSE:
;   Quickly determine HA limits of plate position
; CALLING SEQUENCE:
;   ha_quick, racen, deccen, ha, hamin=, hamax=, maxoff_arcsec=, /plot
; REQUIRED INPUTS:
;   plateid - plate ID number
; OPTIONAL INPUTS:
;   maxoff_arcsec - maximum offset required, arcsec (default 0.3)
;   lambda_eff - wavelength to check, angstrom (default 5400.)
; OPTIONAL KEYWORDS:
;   /plot - creates a splot window with results
; REVISION HISTORY:
;   20-Oct-2008  MRB, NYU
;-
pro ha_quick, racen, deccen, ha, hamin=hamin, hamax=hamax, $
              maxoff_arcsec=maxoff_arcsec, lambda_eff=lambda_eff, $
              plot=plot

platescale = 217.7358D           ; mm/degree
tilerad=1.49D

if(NOT keyword_set(lambda_eff)) then lambda_eff=5400.
if(NOT keyword_set(maxoff_arcsec)) then maxoff_arcsec=0.3
airtemp=5.

;; set up test locations
ntest=100L
th= !DPI*2.*(dindgen(ntest)+0.5)/float(ntest)
xtest= 0.98*tilerad*cos(th)*platescale
ytest= 0.98*tilerad*sin(th)*platescale
ltest= replicate(lambda_eff, ntest)

;; get ra/decs
lst= racen+ ha
xyfocal2ad, xtest, ytest, ratest, dectest, racen=racen, deccen=deccen, $
            airtemp=airtemp, lst=lst, lambda=ltest
ad2xyfocal, ratest, dectest, xtest2, ytest2, racen=racen, deccen=deccen, $
            airtemp=airtemp, lst=lst, lambda=ltest

;; cycle through HA values
dtry=1.0
max_ha_off=60.
ntry= (long(2.*max_ha_off/dtry)/2L)*2L+1L
try_ha= ha+(2.*(findgen(ntry)+0.5)/float(ntry)-1.)*max_ha_off
try_maxdist=fltarr(ntry)
for i=0L, ntry-1L do begin
    try_lst= racen+try_ha[i]
    ad2xyfocal, ratest, dectest, try_xf, try_yf, racen=racen, deccen=deccen, $
                airtemp=airtemp, lst=try_lst, lambda=ltest
    
    ;; rescale x's and y's to take out scale
    rf= sqrt(xtest^2+ytest^2)
    try_rf= sqrt(try_xf^2+try_yf^2)
    scale= median(rf/try_rf)
    try_xf=try_xf*scale
    try_yf=try_yf*scale
    try_rf=try_rf*scale
    
    ;; find maximum distance
    dist= sqrt((xtest- try_xf)^2+ $
               (ytest- try_yf)^2)
    try_maxdist[i]= max(dist)
endfor

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
    splot, int_ha, int_maxdist
    soplot, try_ha, try_maxdist, psym=4
    soplot, [min(try_ha), max(try_ha)], [max_off, max_off], color='red'
    soplot, [hamin, hamin], $
            [0., max_off], color='red'
    soplot, [hamax, hamax], $
            [0., max_off], color='red'
endif

end
