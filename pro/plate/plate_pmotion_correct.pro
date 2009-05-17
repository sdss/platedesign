;+
; NAME:
;   plate_pmotion_correct
; PURPOSE:
;   Apply proper motion corrections from USNO-B1.0, for objects that match
; CALLING SEQUENCE:
;   plate_pmotion_correct, ra, dec, from_mjd=, to_mjd=
; INPUTS:
;   ra, dec - [N] J2000 deg coords
;   from_mjd - [N] mjd of given coords [yr]
;   to_mjd - mjd to transfer coords to [yr]
; OUTPUTS:
;   ra, dec - [N] (Modified)
; COMMENTS:
;   Results not good at day-level precision (leap years ignored).
;   Usual Celestial Pole issue in applying proper motions.
; REVISION HISTORY:
;   10-Oct-2007  Written by D. Schlegel, LBL
;-
;------------------------------------------------------------------------------
pro plate_pmotion_correct, ra, dec, from_mjd=from_mjd, to_mjd=to_mjd, $
  mura=mura, mudec=mudec

matchrad = 2./3600
mura=dblarr(n_elements(ra))
mudec=dblarr(n_elements(ra))
for i=0L, n_elements(ra)-1L do begin
    dat1 = usno_read(ra[i], dec[i], matchrad)
    if (n_elements(dat1) EQ 1) then begin
        if (tag_exist(dat1,'MURA') EQ 0) then $
          message, 'Old version of USNO catalog is set up!'
        tmp_mura= dat1.mura
        tmp_mudec= dat1.mudec
        cosd= cos(dec[i]*!DPI/180.)
        ra[i] += (to_mjd - from_mjd[i])/365. * tmp_mura/3600./1000./cosd
        dec[i] += (to_mjd - from_mjd[i])/365. * tmp_mudec/3600./1000.
        mura[i]=tmp_mura
        mudec[i]=tmp_mudec
    endif
endfor

return
end
;------------------------------------------------------------------------------
