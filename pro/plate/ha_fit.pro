;+
; NAME:
;   ha_fit
; PURPOSE:
;   Apply rotation, scale, and offset to minimize offsets
; CALLING SEQUENCE:
;   ha_fit, xhole, yhole, ximage, yimage, xnew=, ynew=, rot=, scale=, $
;    xshift=, yshift=
; REQUIRED INPUTS:
;   xorig, yorig - [N] original hole positions
;   ximage, yimage - [N] positions of image in new configuration
; OUTPUTS:
;   xnew, ynew - [N] rotated, scaled, shifted image positions
;   xshift, yshift - shift applied in X and Y
;   rot - rotation applied (deg)
;   scale - scale applied 
; COMMENTS:
;   Uses ha_apply.pro to apply offsets.
; REVISION HISTORY:
;   20-Dec-2008  MRB, NYU
;-
function ha_deviates, pst

common com_ha_fit, ha_xhole, ha_yhole, ha_ximage, ha_yimage

rot= pst[0]*180./!DPI
scale= (1.D)+(pst[1])
xshift= pst[2]
yshift= pst[3]

ha_apply, ha_ximage, ha_yimage, rot=rot, scale=scale, xshift=xshift, $
          yshift=yshift, xnew=xnew, ynew=ynew

deviates= [xnew-ha_xhole, ynew-ha_yhole]

return, deviates

end
;
pro ha_fit, xhole, yhole, ximage, yimage, xnew=xnew, ynew=ynew, $
              rot=rot, scale=scale, xshift=xshift, yshift=yshift

common com_ha_fit

ha_xhole= xhole
ha_yhole= yhole
ha_ximage= ximage
ha_yimage= yimage

;; pars are:
;; rotation (radians), scale-1., xshift, yshift
pst= [0.D, 0.D, 0.D, 0.D]
parinfo0={value:0., fixed:0L, limited:bytarr(2), limits:fltarr(2), step:0.}
parinfo= replicate(parinfo0, 4)
parinfo.value= pst
parinfo.step=1.e-6
parinfo[0:1].limited=1L
parinfo[0].limits= 4.*!DPI/180.*[-1., 1.]
parinfo[1].limits= [-0.1, 0.1]

;; run minimization
pmin= mpfit('ha_deviates', pst, auto=1, parinfo=parinfo, status=status, /quiet)
            

;; parse outputs
rot= pmin[0]*180./!DPI
scale= (1.D)+pmin[1]
xshift= pmin[2]
yshift= pmin[3]
ha_apply, ximage, yimage, rot=rot, scale=scale, xshift=xshift, $
          yshift=yshift, xnew=xnew, ynew=ynew

end
