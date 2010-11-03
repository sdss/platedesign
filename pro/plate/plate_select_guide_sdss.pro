;+
; NAME:
;   plate_select_guide_sdss
; PURPOSE:
;   Select guide stars for a single plate from SDSS
; CALLING SEQUENCE:
;   plate_select_guide_sdss, racen, deccen, epoch= $
;    [ tilerad=, guide_design= ]
; INPUTS:
;   racen      - RA center for tile [J2000 deg]
;   deccen     - DEC center for tile [J2000 deg]
;   epoch      - Epoch for output stars, for applying proper motion [yr]
; OPTIONAL INPUTS:
;   rerun      - Rerun name(s)
;   tilerad    - Tile radius; default to 1.49 deg
; OPTIONAL OUTPUTS:
;   guide_design   - Output structure with sky coordinates in J2000 [NSKY]
; COMMENTS:
;   SDSS guide stars are selected as follows:
;     13.0 < g < 15.5
;     0.3 < g-r < 1.4
;     0.0 < r-i < 0.7
;     -0.4 < i-z < 1.0
;   All magnitudes and colors are without extinction-correction.
;   Changed to use datasweeps; requires $PHOTO_SWEEP to be set.
;     (rerun input still allowed, but ignored)
;   Keeps stars away from edge (limits at 1.45 deg)
; REVISION HISTORY:
;   10-Oct-2007  Written by D. Schlegel, LBL
;-
;------------------------------------------------------------------------------
pro plate_select_guide_sdss, racen, deccen, epoch=epoch, $
                             rerun=rerun, tilerad=tilerad1, $
                             guide_design=guide_design, $
                             gminmax=gminmax, nguidemax=nguidemax

if (n_elements(racen) NE 1 OR n_elements(deccen) NE 1 $
    OR n_elements(epoch) NE 1) then $
  message,'Must specify RACEN, DECCEN, EPOCH'
if (keyword_set(tilerad1)) then tilerad = tilerad1 $
else tilerad = 1.45

;; make sure we're not TOO close to the edge
tilerad= tilerad < 1.45

if(NOT keyword_set(gminmax)) then $
  gminmax=[13., 14.5]

;; Find all SDSS objects in the footprint
objs= sdss_sweep_circle(racen, deccen, tilerad, type='star', /silent)

help,objs
;; Trim to good observations of isolated stars
if (keyword_set(objs)) then begin
    indx = sdss_selectobj(objs, ancestry='single', objtype='star', $
                          /trim, count=ct)
    if (ct GT 0) then objs = objs[indx] else objs = 0
endif
help,objs

;; Trim to stars in the desired magnitude + color boxes
if (keyword_set(objs)) then begin
    mag = 22.5 - 2.5*alog10(objs.psfflux>0.1)
    grcolor = transpose( mag[1,*] - mag[2,*] )
    ricolor = transpose( mag[2,*] - mag[3,*] )
    izcolor = transpose( mag[3,*] - mag[4,*] )
    indx = where(mag[1,*] GT gminmax[0] AND mag[1,*] LT gminmax[1] $
                 AND grcolor GT 0.3 AND grcolor LT 1.4 $
                 AND ricolor GT 0.0 AND ricolor LT 0.7 $
                 AND izcolor GT -0.4 AND izcolor LT 1.0, ct)
    if (ct GT 0) then begin
        objs = objs[indx]
        mag = mag[*,indx]
        grcolor = grcolor[indx]
        ricolor = ricolor[indx]
        izcolor = izcolor[indx]
    endif else begin
        objs = 0
    endelse
endif

if (keyword_set(objs)) then begin

    ;; Trim back number to maximum
    if(keyword_set(nguidemax)) then begin
        if(nguidemax lt n_elements(objs)) then begin
            indx= shuffle_indx(n_elements(objs), num_sub=nguidemax)
            objs=objs[indx]
        endif
    endif

    ;; Apply proper motion corrections
    ;; (Results not good at day-level precision --- 
    ;; leap years only approximated).
    ra=objs.ra
    dec=objs.dec
    from_mjd=sdss_run2mjd(objs.run)
    to_mjd = (epoch - 2000.)*365.25 + 51544.5d0
    plate_pmotion_correct, ra, dec, from_mjd=from_mjd, to_mjd=to_mjd, $
      mura=mura, mudec=mudec, racen=racen, deccen=deccen, tilerad=tilerad
    
    ;; Now put results into a design structure
    guide_design= replicate(design_blank(/guide), n_elements(objs))
    struct_assign, objs, guide_design, /nozero
    guide_design.target_ra= ra
    guide_design.target_dec= dec
    guide_design.epoch=epoch
    guide_design.pmra=mura
    guide_design.pmdec=mudec

    ;; Transfer psf and fiber fluxes to mags for completeness
    counts_err=fltarr(5, n_elements(objs))+1.
    sdss_flux2lups, objs.psfflux, objs.psfflux_ivar, counts_err, $
      psfmag, psfmag_err
    sdss_flux2lups, objs.fiberflux, objs.fiberflux_ivar, counts_err, $
      fibermag, fibermag_err
    guide_design.psfmag= psfmag
    guide_design.fibermag= fibermag

    if(tag_indx(objs, 'fiber2flux') eq -1) then begin
      guide_design.fiber2mag= guide_design.fibermag+0.5
    endif else begin
      sdss_flux2lups, objs.fiber2flux, objs.fiber2flux_ivar, counts_err, $
        fiber2mag, fiber2mag_err
      guide_design.fiber2mag= fiber2mag
    endelse

    ;; Finally, set priority; note that for guide stars priority is
    ;; used differently than elsewhere (see plate_assign_guide.pro)
    isort= reverse(sort(guide_design.psfflux[1]))
    guide_design[isort].priority= 1L+lindgen(n_elements(isort))
endif

return
end
;------------------------------------------------------------------------------
