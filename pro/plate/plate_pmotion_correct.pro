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
  mura=mura, mudec=mudec, racen=racen, deccen=deccen, tilerad=tilerad

plate_pmotion_star, ra, dec, pmra=mura, pmdec=mudec, src=src, racen=racen, $
  deccen=deccen, tilerad=tilerad

for i=0L, n_elements(ra)-1L do begin
    cosd= cos(dec[i]*!DPI/180.)
    ra[i] += (to_mjd - from_mjd[i])/365. * mura[i]/3600./1000./cosd
    dec[i] += (to_mjd - from_mjd[i])/365. * mudec[i]/3600./1000.
endfor

return
end
;------------------------------------------------------------------------------
