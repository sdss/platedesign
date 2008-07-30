;+
; NAME:
;   plate_select_sphoto_sdss
; PURPOSE:
;   Select spectro-photo stars for a single plate from SDSS
; CALLING SEQUENCE:
;   plate_select_sphoto_sdss, racen, deccen, [ tilerad=, $
;    sphoto_mag=, sphoto_design= ]
; INPUTS:
;   racen - RA center for pointing [J2000 deg]
;   deccen - DEC center for pointing [J2000 deg]
; OPTIONAL INPUTS:
;   tilerad - Tile radius; default to 1.49 deg
;   sphoto_mag - Magnitude range for SPECTROPHOTO_STD stars; default
;                to 15.5 < g < 17
; OPTIONAL OUTPUTS:
;   sphoto_design   - Output structure with sky coordinates in J2000 [NSKY]
; COMMENTS:
;   SDSS spectro-photo stars are selected as follows:
;     0.6 < u-g < 1.2
;     0.0 < g-r < 0.6
;     g-r > 0.75 * (u-g) - 0.45
;   All magnitudes and colors are extinction-correction.
;   Prioritize stars closest in color to BD+17:
;     u-g = 0.934
;     g-r = 0.280
;     r-i = 0.101
;     i-z = 0.013
;   We assume that no proper motions are necessary for these stars.
;   Changed to use datasweeps; requires $PHOTO_SWEEP to be set.
;     (rerun input still allowed, but ignored)
; REVISION HISTORY:
;   10-Oct-2007  Written by D. Schlegel, LBL
;-
;------------------------------------------------------------------------------
pro plate_select_sphoto_sdss, racen, deccen, rerun=rerun, tilerad=tilerad1, $
  sphoto_mag=sphoto_mag1, sphoto_design=sphoto_design, gminmax=gminmax

if (n_elements(racen) NE 1 OR n_elements(deccen) NE 1) then $
  message,' Must specify RACEN, DECCEN'
if (keyword_set(tilerad1)) then tilerad = tilerad1 $
else tilerad = 1.49
if (keyword_set(sphoto_mag1)) then sphoto_mag = sphoto_mag1 $
else sphoto_mag = [15.5,17]

if(NOT keyword_set(gminmax)) then $
  gminmax=[15.5, 17.]

;; Find all SDSS objects in the footprint
objs= sdss_sweep_circle(racen, deccen, tilerad, type='star', /silent)

;; if sweep fails, see if there is anything NOT in the sweep to find
if(NOT keyword_set(objs)) then begin
    objs= sdss_circle(racen, deccen, tilerad, rerun=rerun)
endif

;; Trim to good observations of isolated stars
if (keyword_set(objs)) then begin
    indx = sdss_selectobj(objs, ancestry='single', objtype='star', $
                          /trim, count=ct)
    if (ct GT 0) then objs = objs[indx] else objs = 0
endif

;; Trim to stars in the desired magnitude + color boxes
if (keyword_set(objs)) then begin
    mag = 22.5 - 2.5*alog10(objs.psfflux>0.1) - objs.extinction
    ugcolor = mag[0,*] - mag[1,*]
    grcolor = mag[1,*] - mag[2,*]
    ricolor = mag[2,*] - mag[3,*]
    izcolor = mag[3,*] - mag[4,*]
    indx = where( $
                  mag[1,*] gt gminmax[0] AND mag[1,*] lt gminmax[1] AND $
                  ugcolor GT 0.6 AND grcolor LT 1.2 $
                  AND grcolor GT 0.0 AND grcolor LT 0.6 $
                  AND grcolor GT 0.75 * ugcolor - 0.45, ct)
    if (ct GT 0) then objs = objs[indx] else objs = 0
endif

;; Prioritize stars closest in color to BD+17.
;; Priority values between [101,200]
if (keyword_set(objs)) then begin
    cdist = abs(ugcolor[indx] - 0.934) $
            + abs(grcolor[indx] - 0.280) $
            + abs(ricolor[indx] - 0.101) $
            + abs(izcolor[indx] - 0.013)
    priority_s = 101 + round(99.*(cdist-min(cdist)) $
                             / (max(cdist) - min(cdist) + 0.01))
    
    sphoto_design= replicate(design_blank(), n_elements(objs))
    struct_assign, objs, sphoto_design, /nozero
    sphoto_design.target_ra= objs.ra
    sphoto_design.target_dec= objs.dec
    sphoto_design.priority= priority_s
    sphoto_design.targettype= 'STANDARD'
    sphoto_design.sourcetype= 'STAR'
    
endif

return
end
;------------------------------------------------------------------------------
