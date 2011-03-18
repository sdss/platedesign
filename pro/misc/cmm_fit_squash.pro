;+
; NAME:
;   cmm_fit_squash
; PURPOSE:
;   Fit CMM data in a file, report offset, scale, rotation, residuals
; CALLING SEQUENCE:
;   fit= cmm_fit_squash(filename, /plot)
; INPUTS:
;   filename - file with data from CMM
; OUTPUTS:
;   fit - structure with details of fit
;           .NHOLE - number of holes
;           .XOFF - best-fit X offset (add to nominal)
;           .YOFF - best-fit Y offset (add to nominal)
;           .ANGLE - best-fit angle of rotation (ccw after shift)
;           .SCALE - best-fit rescale (multiply to nominal after
;                    shift/rotate)
;           .AXISRATIO - b/a of squash
;           .THETA - angle of squash (radians)
;           .SIGX - X residual after rescaling
;           .SIGY - Y residual after rescaling
;           .SIG - total residual after rescaling
;           .XMEAS[2000] - position of measured hole
;           .YMEAS[2000] - 
;           .XNOM[2000] - nominal position of hole
;           .YNOM[2000] - 
;           .DX[2000] - measured minus nominal residual
;           .DY[2000] - 
;           .XFIT[2000] - position of nominal hole fit to measured
;           .YFIT[2000] - 
;           .DXFIT[2000] - residual left after recaling
;           .DYFIT[2000] - 
; OPTIONAL KEYWORDS:
;   /plot - splot the residuals
; REVISION HISTORY:
;   22-Sep-2008  MRB, NYU
;-
;------------------------------------------------------------------------------
pro cmm_apply_squash, cmm, pst

cmm.angle= pst[0]
cmm.scale= (1.D)+(pst[1])
cmm.xoff= pst[2]
cmm.yoff= pst[3]
cmm.axisratio= 1.-exp(pst[4])
cmm.theta= pst[5]

;; squash
xtmp= cmm.xnom*cos(cmm.theta)+cmm.ynom*sin(cmm.theta)
ytmp= cmm.ynom*cos(cmm.theta)-cmm.xnom*sin(cmm.theta)
ytmp= ytmp*cmm.axisratio
xnew= xtmp*cos(cmm.theta)-ytmp*sin(cmm.theta)
ynew= ytmp*cos(cmm.theta)+xtmp*sin(cmm.theta)

;; shift
xnew= xnew+cmm.xoff
ynew= ynew+cmm.yoff

;; rotate
tmpx=  xnew*cos(cmm.angle)-ynew*sin(cmm.angle)
tmpy=  xnew*sin(cmm.angle)+ynew*cos(cmm.angle)
xnew= tmpx
ynew= tmpy

;; scale
cmm.xfit[0:cmm.nhole-1]= xnew[0:cmm.nhole-1]*cmm.scale
cmm.yfit[0:cmm.nhole-1]= ynew[0:cmm.nhole-1]*cmm.scale

cmm.dxfit= cmm.xmeas-cmm.xfit
cmm.dyfit= cmm.ymeas-cmm.yfit

cmm.sigx= sqrt(total((cmm.dxfit)^2)/float(cmm.nhole))
cmm.sigy= sqrt(total((cmm.dyfit)^2)/float(cmm.nhole))
cmm.sig= sqrt(total((cmm.dxfit)^2+(cmm.dyfit)^2)/float(cmm.nhole))

end
;
function cmm_deviates_squash, pst

common com_cmm_fit_squash, cmm

cmm_apply_squash, cmm, pst

deviates= reform([(cmm.xfit-cmm.xmeas)[0:cmm.nhole-1], $
                  (cmm.yfit-cmm.ymeas)[0:cmm.nhole-1]], $
                 cmm.nhole*2)

return, deviates

end
;
function cmm_fit_squash, filename, plot=plot, fix=fix

common com_cmm_fit_squash

openr, unit, filename, /get_lun
line=' '
readf, unit, line
words= strsplit(line, /extr)
plate= long(words[2])
readf, unit, line
if(keyword_set(line)) then  begin
    words= strsplit(line, /extr)
    datestring= words[1]
    words= strsplit(datestring, '-', /extr)
    jday= julday(long(words[1]), long(words[2]), long(words[0]))
    mjd= jday- 2400000L
endif else begin
    datestring= ' '
    mjd= 0L
endelse
free_lun, unit

readcol, filename, skip=4, f='(f,f,f,f,f,f)', mx, my, nx, ny, ex, ey

nhole= n_elements(mx)
nmax=2000L
cmm= {plate:plate, $
      datestring:datestring, $
      file:filename, $
      mjd:mjd, $
      nhole:nhole, $
      xoff:0., $
      yoff:0., $
      axisratio:0., $
      theta:0., $
      angle:0., $
      scale:0., $
      sigx:0., $
      sigy:0., $
      sig:0., $
      xmeas:fltarr(nmax), $
      ymeas:fltarr(nmax), $
      xnom:fltarr(nmax), $
      ynom:fltarr(nmax), $
      dx:fltarr(nmax), $
      dy:fltarr(nmax), $
      xfit:fltarr(nmax), $
      yfit:fltarr(nmax), $
      dxfit:fltarr(nmax), $
      dyfit:fltarr(nmax)}

cmm.xnom[0:nhole-1]= nx
cmm.ynom[0:nhole-1]= ny
cmm.xmeas[0:nhole-1]= mx
cmm.ymeas[0:nhole-1]= my
cmm.dx= cmm.xmeas-cmm.xnom
cmm.dy= cmm.ymeas-cmm.ynom
cmm.dyfit= cmm.ymeas-cmm.ynom
cmm.dyfit= cmm.ymeas-cmm.ynom

;; parameters are:
;; rotation (radians), scale-1., xshift, yshift, ln(1-axisratio),
;; theta (radians)
pst= [0.D, 0.D, 0.D, 0.D, -5., 0.D]
parinfo0={value:0., fixed:0L, limited:bytarr(2), limits:fltarr(2), step:0.}
parinfo= replicate(parinfo0, n_elements(pst))
parinfo.value= pst
parinfo.step=1.e-4
parinfo[4].step=0.1
parinfo[5].step=1.e-3
parinfo[0:1].limited=1L
parinfo[0].limits= 4.*!DPI*[-1., 1.]
parinfo[1].limits= [-0.2, 0.2]
parinfo[2:3].limited=0L
parinfo[2].limits= [-0.1, 0.1]
parinfo[3].limits= [-0.1, 0.1]
parinfo[5].limited=1L
parinfo[5].limits= 4.*!DPI*[-1., 1.]

if(keyword_set(fix)) then begin
    parinfo[4:5].fixed= 1
    pst[4]= -10.*alog(10)
    pst[5]= 0.
    month='09'
    day='09'
    year='2010'
    mjd_sep10= julday('09','09','2010')-2400000L
    mjd_dec10= julday('12','17','2010')-2400000L
    if(mjd gt mjd_sep10) then begin
        pst[4]= -4.25*alog(10)
        pst[5]= 175.*!DPI/180.
    endif 
    if(mjd gt mjd_dec10) then begin
        pst[4]= -4.15*alog(10)
        pst[5]= 135.*!DPI/180.
    endif 
endif

;; run minimization
pmin= mpfit('cmm_deviates_squash', pst, auto=1, parinfo=parinfo, status=status, $
           /quiet, ftol=1.d-6)

;; parse outputs
cmm_apply_squash, cmm, pmin

if(keyword_set(plot)) then begin
   splot_vec, cmm.xnom, cmm.ynom, cmm.dxfit*1000., cmm.dyfit*1000.
endif

return, cmm

end
