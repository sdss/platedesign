;+
; NAME:
;   plate_select_sphoto_2mass
; PURPOSE:
;   Select spectro-photo stars for a single plate from 2MASS
; CALLING SEQUENCE:
;   plate_select_sphoto_2mass, racen, deccen, [ tilerad=, $
;    sphoto_mag=, sphoto_design= ]
; INPUTS:
;   racen - RA center for pointing [J2000 deg]
;   deccen - DEC center for pointing [J2000 deg]
; OPTIONAL INPUTS:
;   rerun - Rerun name(s)
;   tilerad - Tile radius; default to 1.49 deg
;   sphoto_mag - Magnitude range for SPECTROPHOTO_STD stars; default
;                to 15.5 < g < 17
; OPTIONAL OUTPUTS:
;   sphoto_design   - Output structure with sky coordinates in J2000 [NSKY]
; COMMENTS:
;   2MASS spectro-photo stars are selected as follows:
;     0.3 < J-H < 0.4
;   All magnitudes and colors are extinction-correction.
;   Prioritize brighter stars according to J magnitudes.
;   We assume that no proper motions are necessary for these stars.
; REVISION HISTORY:
;   10-Oct-2007  Written by D. Schlegel, LBL
;-
;------------------------------------------------------------------------------
pro plate_select_sphoto_2mass, racen, deccen, rerun=rerun, tilerad=tilerad1, $
  sphoto_mag=sphoto_mag1, sphoto_design=sphoto_design

if (n_elements(racen) NE 1 OR n_elements(deccen) NE 1) then $
  message,' Must specify RACEN, DECCEN'
if (keyword_set(tilerad1)) then tilerad = tilerad1 $
else tilerad = 1.49
if (keyword_set(sphoto_mag1)) then sphoto_mag = sphoto_mag1 $
else sphoto_mag = [15.5,17]
if(NOT keyword_set(rerun)) then $
  message, 'Must specify RERUN'

;; Read all the 2MASS objects on the plate
objt = tmass_read(racen, deccen, tilerad)

;; Extinction-correct the 2MASS magnitudes
euler, objt.tmass_ra, objt.tmass_dec, ll, bb, 1
ebv = dust_getval(ll, bb, /interp, /noloop)
objt.tmass_j -= 0.902 * ebv
objt.tmass_h -= 0.576 * ebv
objt.tmass_k -= 0.367 * ebv

;; Trim to good observations of isolated stars (no neighbors within 6 arcsec)
if (keyword_set(objt)) then begin
    mdist = 6./3600
    ingroup = spheregroup(objt.tmass_ra, objt.tmass_dec, mdist, $
                          multgroup=multgroup, firstgroup=firstgroup, $
                          nextgroup=nextgroup)
    indx = where(multgroup[ingroup] EQ 1, ct)
    if (ct GT 0) then objt = objt[indx] else objt = 0
endif

;; Trim to stars in the desired magnitude + color boxes
if (keyword_set(objt)) then begin
    jhcolor = objt.tmass_j - objt.tmass_h
    indx = where(objt.tmass_bl_flg EQ 111 $
                 AND objt.tmass_cc_flg EQ '000' $
                 AND objt.tmass_gal_contam EQ 0 $
                 AND objt.tmass_mp_flg EQ 0 $
                 AND jhcolor GT 0.3 AND jhcolor LT 0.4, ct)
    if (ct GT 0) then begin
        objt = objt[indx]
        jhcolor = jhcolor[indx]
    endif else begin
        objt = 0
    endelse
endif

;; Prioritize the **brightest** stars
;; Priority values between [1,100]
if (keyword_set(objt)) then begin
    priority_t = 1 + floor( 100. * (max(objt.tmass_j) - objt.tmass_j) $
                            / (max(objt.tmass_j) - min(objt.tmass_j) + 0.1) )
    
    sphoto_design= replicate(design_blank(), n_elements(objt))
    sphoto_design.target_ra= objt.ra
    sphoto_design.target_dec= objt.dec
    sphoto_design.priority= priority_t
    sphoto_design.targettype= 'STANDARD'
    sphoto_design.sourcetype= 'STAR'
endif

return
end
;------------------------------------------------------------------------------
