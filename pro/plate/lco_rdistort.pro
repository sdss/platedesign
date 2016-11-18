;+
; NAME:
;   lco_rdistort
; PURPOSE:
;   Account for radial distortion through the du Pont 
; CALLING SEQUENCE:
;   rfocal = lco_rdistort(theta, lambda, zoffset)
; INPUTS:
;   theta - [N] current set of radii (deg)
;   lambda - [N] current set of wavelengths (Angstroms)
;   zoffset - [N] offset from focal plane
; OUTPUTS:
;   rfocal - [N] distorted radii (mm)
; COMMENTS:
;   LCO-specific
;   Distortions are gleaned from the Zemax models of Paul Harding,
;   with a backfocal distance of 993 mm and a corrector position set 
;   for 1600 nm focus. These are designed for the centroid position
;   (which is slightly offset from the chief ray). 
; REVISION HISTORY:
;   16-Nov-2016  MRB, NYU
;-
;------------------------------------------------------------------------------
function lco_rdistort, theta, lambda, zoffset

if(n_elements(theta) ne n_elements(lambda)) then $
  message, 'THETA and LAMBDA must be same # of elements'
if(n_elements(theta) ne n_elements(zoffset)) then $
  message, 'THETA and ZOFFSET must be same # of elements'

scales = lco_scales()

rfocal = replicate(0.D, n_elements(theta))

isort = sort(lambda)
lambdas = lambda[isort(uniq(lambda[isort]))]
for i = 0L, n_elements(lambdas) - 1L do begin
    ilambda = where(lambda eq lambdas[i], nlambda)
    curr_zoffset = zoffset[ilambda]
    isort = sort(curr_zoffset)
    zoffsets = curr_zoffset[isort(uniq(curr_zoffset[isort]))]
    for j = 0, n_elements(zoffsets) - 1L do begin
        iholes = where(lambda eq lambdas[i] and $
                       zoffset eq zoffsets[j], ncurr)
        iscale = where(scales.lambda eq lambdas[i] and $
                       scales.zoffset eq zoffsets[j], nscale)
        if(nscale eq 0) then $
          message, 'LAMBDA='+strtrim(string(lambdas[i]),2)+ $
          ' and ZOFFSET='+strtrim(string(zoffsets[j]),2)+ $
          ' not valid scales'
        if(nscale gt 1) then $
          message, 'LAMBDA='+strtrim(string(lambdas[i]),2)+ $
          ' and ZOFFSET='+strtrim(string(zoffsets[j]),2)+ $
          ' appear twice in LCO scales list'
        rfocal[iholes] = scales[iscale].a0 * theta[iholes] + $
          scales[iscale].a1 * theta[iholes]^3 + $
          scales[iscale].a2 * theta[iholes]^5
    endfor
endfor

return, rfocal

end
