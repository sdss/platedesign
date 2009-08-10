;+
; NAME:
;   sdss_rdistort
; PURPOSE:
;   Account for radial distortion through the telescope relative to 5500 A
; CALLING SEQUENCE:
;   rdistort= sdss_rdistort(rfocal, lambda)
; INPUTS:
;   rfocal - [N] current set of radii (mm)
;   lambda - [N] current set of wavelengths (Angstroms)
; OUTPUTS:
;   rdistort - [N] distorted radii
; COMMENTS:
;   Uses $PLATEDESIGN_DIR/data/sdss/image-heights.txt
;   Supplied by Jim Gunn, message sdss3-boss/1016
; REVISION HISTORY:
;   7-Aug-2008  MRB, NYU
;-
;------------------------------------------------------------------------------
function sdss_rdistort, rfocal, inlambda

common com_reachcheck, radii, lambda, fracd

if(n_elements(rfocal) ne n_elements(inlambda)) then $
  message, 'RFOCAL and LAMBDA must be same # of elements'

platescale = 217.7358D           ; mm/degree

if(n_elements(radii) eq 0) then begin
    sinradii= findgen(10.)*10./60.*(!DPI/180.)
    radii= ((180.D)/!DPI)*asin(sinradii)*platescale
    readcol, comment='#', getenv('PLATEDESIGN_DIR')+ $
             '/data/sdss/image-heights.txt', lambda, off0, off1, off2, $
             off3, off4, off5, off6, off7, off8, off9

    ;; reinterpret as fractional offsets relative to 5300
    nl= n_elements(lambda)
    isort= sort(lambda)
    lambda=lambda[isort]
    fracd=dblarr(nl, 10)
    fracd[*,0]=off1[isort]/off1[0]
    fracd[*,1]=off1[isort]/off1[0]
    fracd[*,2]=off2[isort]/off2[0]
    fracd[*,3]=off3[isort]/off3[0]
    fracd[*,4]=off4[isort]/off4[0]
    fracd[*,5]=off5[isort]/off5[0]
    fracd[*,6]=off6[isort]/off6[0]
    fracd[*,7]=off7[isort]/off7[0]
    fracd[*,8]=off8[isort]/off8[0]
    fracd[*,9]=off9[isort]/off9[0]
    fracd[1L,*]=0.

    ;; now offset to be fractional relative to 5500.  ignores
    ;; second-order effects, just does a linear offset between 5300
    ;; and 5500 (would be less accurate for a larger offset)
    i5500=2L
    for i=0L, 9L do $
          fracd[*,i]=fracd[*,i]-fracd[i5500,i]
endif

rdistort=dblarr(n_elements(rfocal))
for i=0L, n_elements(rfocal)-1L do begin
    ;; interpolate grid to lambda
    fracdistort= dblarr(n_elements(radii))
    for j=0L, n_elements(radii)-1L do $
          fracdistort[j]= interpol(fracd[*,j], lambda, inlambda[i])
    rdistort[i]= rfocal[i]* $
                 ((1.D)+interpol(fracdistort, radii, rfocal[i], /spline))
endfor

return, rdistort

end
