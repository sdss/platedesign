;+
; NAME:
;   plate_pmotion_star
; PURPOSE:
;   Find any available proper motion for a star
; CALLING SEQUENCE:
;   plate_pmotion_star, ra, dec, pmra=, pmdec=, src=
; INPUTS:
;   ra, dec - [N] J2000 deg coords
; OUTPUTS:
;   pmra, pmdec - [N] mas/yr
;   src - [N] source used (e.g. 'USNO-B')
; REVISION HISTORY:
;   10-Aug-2009  Written by D. Schlegel, LBL
;-
;------------------------------------------------------------------------------
pro plate_pmotion_star, ra, dec, pmra=pmra, pmdec=pmdec

matchrad = 2./3600
pmra=dblarr(n_elements(ra))
pmdec=dblarr(n_elements(ra))
src=strarr(n_elements(ra))
for i=0L, n_elements(ra)-1L do begin
    dat1 = usno_read(ra[i], dec[i], matchrad)
    if (n_elements(dat1) EQ 1) then begin
        if (tag_exist(dat1,'MURA') EQ 0) then $
          message, 'Old version of USNO catalog is set up!'
        pmra[i]= dat1.mura
        pmdec[i]= dat1.mudec
        src[i]= 'USNO-B'
    endif
endfor

return
end
;------------------------------------------------------------------------------
