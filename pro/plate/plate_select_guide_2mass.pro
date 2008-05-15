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
; REVISION HISTORY:
;   10-Oct-2007  Written by D. Schlegel, LBL
;-
;------------------------------------------------------------------------------
pro plate_select_guide_2mass, racen, deccen, epoch=epoch, $
  tilerad=tilerad1, guide_design=guide_design

if (n_elements(racen) NE 1 OR n_elements(deccen) NE 1 $
    OR n_elements(epoch) NE 1) then $
  message,'Must specify RACEN, DECCEN, EPOCH'
if (keyword_set(tilerad1)) then tilerad = tilerad1 $
else tilerad = 1.49

;; Read all the 2MASS objects on the plate
objt = tmass_read(racen, deccen, tilerad)

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
    jkcolor = objt.tmass_j - objt.tmass_k
    indx = where(objt.tmass_bl_flg EQ 111 $
                 AND objt.tmass_cc_flg EQ '000' $
                 AND objt.tmass_gal_contam EQ 0 $
                 AND objt.tmass_mp_flg EQ 0 $
                 AND jkcolor GT 0.4 AND jkcolor LT 0.6, ct)
    if (ct GT 0) then begin
        objt = objt[indx]
        jkcolor = jkcolor[indx]
    endif else begin
        objt = 0
    endelse
endif

if (keyword_set(objt)) then begin
    ;; Apply proper motion corrections
    ;; (Results not good at day-level precision --- 
    ;; leap years only approximated).
    ra=objt.tmass_ra
    dec=objt.tmass_dec
    from_mjd=objt.tmass_jdate-2400000.5D
    to_mjd = (epoch - 2000.)*365.25 + 51544.5d0
    plate_pmotion_correct, ra, dec, from_mjd=from_mjd, to_mjd=to_mjd
    
    ;; Now put results into a design structure
    guide_design= replicate(design_blank(/guide), n_elements(objt))
    guide_design.target_ra= ra
    guide_design.target_dec= dec
endif

return
end
;------------------------------------------------------------------------------
