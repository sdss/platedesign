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
;   gminmax_mag - magnitude limits for guides (default [13., 14.5]
;   gminmax_band - band for mag limits (default 'g')
;   jkminmax - obsolete
;   nguidemax - maximum number of guides to seek (default infinite)
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
;   It uses rerun 301 by default.
;   Keeps stars away from edge (limits at 1.45 deg)
; REVISION HISTORY:
;   10-Oct-2007  Written by D. Schlegel, LBL
;-
;------------------------------------------------------------------------------
pro plate_select_guide_sdss, racen, deccen, epoch=epoch, $
                             rerun=rerun, tilerad=tilerad1, $
                             guide_design=guide_design, $
                             gminmax_mag=gminmax_mag, nguidemax=nguidemax, $
                             seed=seed, gminmax_band=gminmax_band

if (n_elements(racen) NE 1 OR n_elements(deccen) NE 1 $
    OR n_elements(epoch) NE 1) then $
  message,'Must specify RACEN, DECCEN, EPOCH'
if (keyword_set(tilerad1)) then tilerad = tilerad1 $
else tilerad = 1.45
if(NOT keyword_set(rerun)) then rerun='301'

;; make sure we're not TOO close to the edge
tilerad= tilerad < 1.45

if(NOT keyword_set(gminmax_mag)) then $
  gminmax_mag=[13., 14.5]

if(NOT keyword_set(gminmax_band)) then begin
    gminmax_band = 1
endif
igminmax_band = filternum(gminmax_band)

;; Find all SDSS objects in the footprint
objs= sdss_sweep_circle(racen, deccen, tilerad, type='star', /silent)

;; check that objects were returned
if (n_tags(objs) eq 0) then $
	message, color_string('sdss_sweep_circle returned no objects - is ra, dec ('+strtrim(string(racen),2)+', '+strtrim(string(deccen),2)+') within the SDSS imaging?', 'red', 'bold')

;; Use rerun 301 only
orerun = strtrim(objs.rerun,2)
irerun = where(orerun eq rerun, nrerun)
if(nrerun eq 0) then $
  message, 'No guide stars from sought SDSS photometric rerun '+string(rerun)
objs = objs[irerun]

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
    indx = where(mag[igminmax_band,*] GT gminmax_mag[0] AND mag[igminmax_band,*] LT gminmax_mag[1] $
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
            indx= shuffle_indx(n_elements(objs), num_sub=nguidemax, seed=seed)
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
	  ;; message, guide_design.fibermag+0.5 - this returns an error - why is this here?
	  ;; if finite(guide_design.fiber2mag) eq 0 then stop
	  x = where(finite(guide_design.fiber2mag) eq 0, nan_count)
	  if nan_count GT 0 then begin
	    message, color_string('NaN values were found.', 'red', 'bold')
		stop
	  endif
    endif else begin
      sdss_flux2lups, objs.fiber2flux, objs.fiber2flux_ivar, counts_err, $
        fiber2mag, fiber2mag_err
		;message, fiber2mag
      guide_design.fiber2mag= fiber2mag
	  x = where(finite(guide_design.fiber2mag) eq 0, nan_count)
	  if nan_count GT 0 then begin
		message, color_string('NaN values were found.', 'red', 'bold')
		stop
	  endif
    endelse

    ;; Finally, set priority; note that for guide stars priority is
    ;; used differently than elsewhere (see plate_assign_guide.pro)
    isort= reverse(sort(guide_design.psfflux[igminmax_band]))
    guide_design[isort].priority= 1L+lindgen(n_elements(isort))
endif

return
end
;------------------------------------------------------------------------------
