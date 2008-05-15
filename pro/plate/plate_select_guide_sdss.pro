;+
; NAME:
;   plate_select_guide_sdss
; PURPOSE:
;   Select guide stars for a single plate from SDSS
; CALLING SEQUENCE:
;   plate_select_guide_sdss, racen, deccen, epoch= $
;    [ rerun=, tilerad=, guide_design= ]
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
; REVISION HISTORY:
;   10-Oct-2007  Written by D. Schlegel, LBL
;-
;------------------------------------------------------------------------------
pro plate_select_guide_sdss, racen, deccen, epoch=epoch, $
  rerun=rerun, tilerad=tilerad1, guide_design=guide_design

if (n_elements(racen) NE 1 OR n_elements(deccen) NE 1 $
    OR n_elements(epoch) NE 1) then $
  message,'Must specify RACEN, DECCEN, EPOCH'
if (keyword_set(tilerad1)) then tilerad = tilerad1 $
else tilerad = 1.49

if(NOT keyword_set(rerun)) then $
  message, 'Must specify RERUN'

;; Find all SDSS objects in the footprint
flist = sdss_astr2fields(radeg=racen, decdeg=deccen, radius=tilerad, $
                         rerun=rerun)
if (keyword_set(flist)) then begin
    objs = sdss_readobj(flist.run, flist.camcol, flist.field, $
                        rerun=flist.rerun)
    spherematch, racen, deccen, objs.ra, objs.dec, tilerad, m1, m2, max=0
    if(m1[0] eq -1) then $
      objs=0 $
    else $
      objs=objs[m2]
endif

;; Trim to good observations of isolated stars
if (keyword_set(objs)) then begin
    indx = sdss_selectobj(objs, ancestry='single', objtype='star', $
                          /trim, count=ct)
    if (ct GT 0) then objs = objs[indx] else objs = 0
endif

;; Trim to stars in the desired magnitude + color boxes
if (keyword_set(objs)) then begin
    mag = 22.5 - 2.5*alog10(objs.psfflux>0.1)
    grcolor = transpose( mag[1,*] - mag[2,*] )
    ricolor = transpose( mag[2,*] - mag[3,*] )
    izcolor = transpose( mag[3,*] - mag[4,*] )
    indx = where(mag[1,*] GT 13. AND mag[1,*] LT 15.5 $
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
    ;; Apply proper motion corrections
    ;; (Results not good at day-level precision --- 
    ;; leap years only approximated).
    ra=objs.ra
    dec=objs.dec
    from_mjd=objs.mjd
    to_mjd = (epoch - 2000.)*365.25 + 51544.5d0
    plate_pmotion_correct, ra, dec, from_mjd=from_mjd, to_mjd=to_mjd
    
    ;; Now put results into a design structure
    guide_design= replicate(design_blank(/guide), n_elements(objs))
    guide_design.target_ra= ra
    guide_design.target_dec= dec
endif

return
end
;------------------------------------------------------------------------------
