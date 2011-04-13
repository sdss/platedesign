;+
; NAME:
;   plate_select_guide_2mass
; PURPOSE:
;   Select guide stars for a single plate from SDSS
; CALLING SEQUENCE:
;   plate_select_guide_2mass, racen, deccen, epoch= $
;    [ rerun=, tilerad=, guide_design= ]
; INPUTS:
;   racen      - RA center for tile [J2000 deg]
;   deccen     - DEC center for tile [J2000 deg]
;   epoch      - Epoch for output stars, for applying proper motion [yr]
; OPTIONAL INPUTS:
;   tilerad    - Tile radius; default to 1.49 deg
; OPTIONAL OUTPUTS:
;   guide_design   - Output structure with sky coordinates in J2000 [NSKY]
; COMMENTS:
;   2MASS guide stars are selected as follows:
;     0.4 < J-K < 0.6
;   All magnitudes and colors are without extinction-correction.
;   Keeps stars away from edge (limits at 1.45 deg)
; REVISION HISTORY:
;   10-Oct-2007  Written by D. Schlegel, LBL
;-
;------------------------------------------------------------------------------
pro test_2mass_usnob, ra, dec, dra=dra, ddec=ddec

tilerad=0.5

objt = tmass_read(ra, dec, tilerad)

info= usno_read(ra, dec, tilerad)

;; Trim to good observations of isolated stars (no neighbors within 6 arcsec)
if (keyword_set(objt)) then begin
    mdist = 6./3600
    ingroup = spheregroup(objt.tmass_ra, objt.tmass_dec, mdist, $
                          multgroup=multgroup, firstgroup=firstgroup, $
                          nextgroup=nextgroup, chunksize=0.05)
    indx = where(multgroup[ingroup] EQ 1, ct)
    if (ct GT 0) then objt = objt[indx] else objt = 0
endif

spherematch, info.ra, info.dec, objt.tmass_ra, objt.tmass_dec, 1./3600., m1, m2
splot, 3600.*(objt[m2].tmass_ra-info[m1].ra)*cos(!DPI/180.*objt[m2].tmass_dec), $ 
  3600.*(objt[m2].tmass_dec-info[m1].dec), $ 
  psym=3

soplot, [-0., -0.], [-10., 10.], th=2, color='red'
soplot, [-10., 10.], [0., 0.], th=2, color='red'

dra= median(3600.*(objt[m2].tmass_ra-info[m1].ra)*cos(!DPI/180.*objt[m2].tmass_dec))
ddec= median(3600.*(objt[m2].tmass_dec-info[m1].dec))

return
end
;------------------------------------------------------------------------------
