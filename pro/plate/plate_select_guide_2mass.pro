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
pro plate_select_guide_2mass, racen, deccen, epoch=epoch, $
                              tilerad=tilerad1, guide_design=guide_design, $
                              gminmax=gminmax, nguidemax=nguidemax

if (n_elements(racen) NE 1 OR n_elements(deccen) NE 1 $
    OR n_elements(epoch) NE 1) then $
  message,'Must specify RACEN, DECCEN, EPOCH'
if (keyword_set(tilerad1)) then tilerad = tilerad1 $
else tilerad = 1.45

if(NOT keyword_set(gminmax)) then $
  gminmax=[13., 14.5]

;; Read all the 2MASS objects on the plate
objt = tmass_read(racen, deccen, tilerad)

;; Trim to good observations of isolated stars (no neighbors within 6 arcsec)
if (keyword_set(objt)) then begin
    mdist = 6./3600
    ingroup = spheregroup(objt.tmass_ra, objt.tmass_dec, mdist, $
                          multgroup=multgroup, firstgroup=firstgroup, $
                          nextgroup=nextgroup, chunksize=0.05)
    indx = where(multgroup[ingroup] EQ 1, ct)
    if (ct GT 0) then objt = objt[indx] else objt = 0
endif

;; Trim to stars in the desired magnitude + color boxes
if (keyword_set(objt)) then begin
    jkcolor = objt.tmass_j - objt.tmass_k

    mag= plate_tmass_to_sdss(objt.tmass_j, objt.tmass_h, objt.tmass_k)

    indx = where(objt.tmass_bl_flg EQ 111 $
                 AND mag[1,*] gt gminmax[0] $
                 AND mag[1,*] lt gminmax[1] $
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

    ;; Trim back number to maximum; only allow brightest
    if(keyword_set(nguidemax)) then begin
        if(nguidemax lt n_elements(objt)) then begin
            isort= sort(objt.tmass_j)
            indx= isort[0:nguidemax-1]
            objt=objt[indx]
        endif
    endif

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
    struct_assign, objt, guide_design, /nozero
    guide_design.target_ra= ra
    guide_design.target_dec= dec

    ;; Finally, set priority; note that for guide stars priority is
    ;; used differently than elsewhere (see plate_assign_guide.pro)
    isort= sort(guide_design.tmass_j)
    guide_design[isort].priority= 1L+lindgen(n_elements(isort))
endif

return
end
;------------------------------------------------------------------------------
