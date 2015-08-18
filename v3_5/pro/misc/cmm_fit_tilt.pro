;+
; NAME:
;   cmm_fit_tilt
; PURPOSE:
;   Fit CMM data in a file, report offset, scale, rotation, residuals
; CALLING SEQUENCE:
;   fit= cmm_fit_tilt(filename, /plot)
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
;           .TILT - angle of tilt (rad)
;           .RTILT - X origin of tilt
;           .THTILT - Y origin of tilt
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
pro cmm_apply_tilt, cmm, pst

cmm.angle= pst[0]
cmm.scale= (1.D)+(pst[1])
cmm.xoff= pst[2]
cmm.yoff= pst[3]
cmm.tilt= pst[4]
cmm.rtilt= pst[5]
cmm.thtilt= pst[6]

;; tilt
xtilt= cmm.rtilt*cos(cmm.thtilt)
ytilt= cmm.rtilt*sin(cmm.thtilt)
x0= cmm.rtilt
if(x0 gt 0.) then begin
   xdot= (xtilt*cmm.xnom+ytilt*cmm.ynom)/x0
   qx= (x0-xdot)*xtilt/x0
   qy= (x0-xdot)*ytilt/x0
   xnew= cmm.xnom+qx*0.5*cmm.tilt^2
   ynew= cmm.ynom+qy*0.5*cmm.tilt^2
endif

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
function cmm_deviates_tilt, pst

common com_cmm_fit_tilt, cmm

cmm_apply_tilt, cmm, pst

deviates= reform([(cmm.xfit-cmm.xmeas)[0:cmm.nhole-1], $
                  (cmm.yfit-cmm.ymeas)[0:cmm.nhole-1]], $
                 cmm.nhole*2)

return, deviates

end
;
function cmm_fit_tilt, filename, plot=plot

common com_cmm_fit_tilt

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
      tilt:0., $
      rtilt:0., $
      thtilt:0., $
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
;; rotation (radians), scale-1., xshift, yshift, tilt, rtilt, thtilt
pst= [0.D, 0.D, 0.D, 0.D, 0.01, 0.1D, 0.D]
parinfo0={value:0., fixed:0L, limited:bytarr(2), limits:fltarr(2), step:0.}
parinfo= replicate(parinfo0, n_elements(pst))
parinfo.value= pst
parinfo.step=1.e-4
parinfo[4].step=1.e-3
parinfo[5].step=10.
parinfo[6].step=1.
parinfo[0:1].limited=1L
parinfo[0].limits= 4.*!DPI*[-1., 1.]
parinfo[1].limits= [-0.2, 0.2]
parinfo[2:3].limited=0L
parinfo[2].limits= [-0.1, 0.1]
parinfo[3].limits= [-0.1, 0.1]
parinfo[4:6].limited=1L
parinfo[4].limits= [-1., 1.]
parinfo[5].limits= [0.01, 1.e+6]
parinfo[6].limits= 4.*!DPI*[-1., 1.]

;; run minimization
pmin= mpfit('cmm_deviates_tilt', pst, auto=1, parinfo=parinfo, status=status, $
           /quiet, ftol=1.d-6)

;; parse outputs
cmm_apply_tilt, cmm, pmin

if(keyword_set(plot)) then begin
   splot_vec, cmm.xnom, cmm.ynom, cmm.dxfit*1000., cmm.dyfit*1000.
endif

return, cmm

end
