;+
; NAME:
;   plate_select_sphoto
;
; PURPOSE:
;   Select spectro-photo stars for a single plate
;
; CALLING SEQUENCE:
;   plate_select_sphoto, racen, deccen, [ rerun=, tilerad=, $
;    sphoto_mag=, redden_mag=, stardata= ]
;
; INPUTS:
;   racen      - RA center for tile [J2000 deg]
;   deccen     - DEC center for tile [J2000 deg]
;
; OPTIONAL INPUTS:
;   rerun      - Rerun name(s); if not specified, then only select guide
;                stars from 2MASS
;   tilerad    - Tile radius; default to 1.49 deg
;   sphoto_mag - Magnitude range for SPECTROPHOTO_STD stars; default
;                to 15.5 < g < 17
;   redden_mag - Magnitude range for REDDEN_STD stars; default
;                to 17 < g < 18.5
;
; OUTPUTS:
;
; OPTIONAL OUTPUTS:
;   stardata   - Output structure with sky coordinates in J2000 [NSKY]
;
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
;
;   2MASS spectro-photo stars are selected as follows:
;     0.3 < J-H < 0.4
;   All magnitudes and colors are extinction-correction.
;   Prioritize brighter stars according to J magnitudes.
;
;   The g-band magnitude ranges are only approximately known for 2MASS sources.
;
;   We assume that no proper motions are necessary for these stars.
;
; EXAMPLES:
;
; BUGS:
;
; PROCEDURES CALLED:
;
; INTERNAL SUPPORT ROUTINES:
;
; REVISION HISTORY:
;   10-Oct-2007  Written by D. Schlegel, LBL
;-
;------------------------------------------------------------------------------
pro plate_select_sphoto, racen, deccen, rastar, decstar, epoch=epoch, $
 rerun=rerun, tilerad=tilerad1, sphoto_mag=sphoto_mag1, $
 redden_mag=redden_mag1, stardata=stardata

   if (n_elements(racen) NE 1 OR n_elements(deccen) NE 1) then $
    message,' Must specify RACEN, DECCEN'
   if (keyword_set(tilerad1)) then tilerad = tilerad1 $
    else tilerad = 1.49
   if (keyword_set(sphoto_mag1)) then sphoto_mag = sphoto_mag1 $
    else sphoto_mag = [15.5,17]
   if (keyword_set(redden_mag1)) then redden_mag = redden_mag1 $
    else redden_mag = [17,18.5]

   ;---------------------------------------------------------------------------
   ; SDSS OBJECTS
   ;---------------------------------------------------------------------------

   ; If RERUN is specified, then read all SDSS objects on the plate
   if (keyword_set(rerun)) then begin
      ; Find all SDSS objects in the footprint
      flist = sdss_astr2fields(radeg=racen, decdeg=deccen, radius=tilerad, $
       rerun=rerun)
      if (keyword_set(flist)) then begin
         objs = sdss_readobj(flist.run, flist.camcol, flist.field, $
          rerun=flist.rerun)
         indx = where(djs_diff_angle(objs.ra,objs.dec,racen,deccen) $
          LT tilerad, ct)
         if (ct GT 0) then objs = objs[indx] else objs = 0
      endif

      ; Trim to good observations of isolated stars
      if (keyword_set(objs)) then begin
         indx = sdss_selectobj(objs, ancestry='single', objtype='star', $
          /trim, count=ct)
         if (ct GT 0) then objs = objs[indx] else objs = 0
      endif

      ; Trim to stars in the desired magnitude + color boxes
      if (keyword_set(objs)) then begin
         mag = 22.5 - 2.5*alog10(objs.psfflux>0.1) - objs.extinction
         ugcolor = mag[0,*] - mag[1,*]
         grcolor = mag[1,*] - mag[2,*]
         ricolor = mag[2,*] - mag[3,*]
         izcolor = mag[3,*] - mag[4,*]
         indx = where( $
              ugcolor GT 0.6 AND grcolor LT 1.2 $
          AND grcolor GT 0.0 AND grcolor LT 0.6 $
          AND grcolor GT 0.75 * ugcolor - 0.45, ct)
         if (ct GT 0) then objs = objs[indx] else objs = 0
      endif

      ; Prioritize stars closest in color to BD+17.
      ; Priority values between [101,200]
      if (keyword_set(objs)) then begin
         cdist = abs(ugcolor[indx] - 0.934) $
          + abs(grcolor[indx] - 0.280) $
          + abs(ricolor[indx] - 0.101) $
          + abs(izcolor[indx] - 0.013)
         priority_s = 101 + round(99.*(max(cdist) - cdist) $
                                  / (max(cdist) - min(cdist) + 0.01))
      endif
   endif

   ;---------------------------------------------------------------------------
   ; 2MASS OBJECTS
   ;---------------------------------------------------------------------------

   ; Read all the 2MASS objects on the plate
   objt = tmass_read(racen, deccen, tilerad)

   ; Extinction-correct the 2MASS magnitudes
   euler, objt.tmass_ra, objt.tmass_dec, ll, bb, 1
   ebv = dust_getval(ll, bb, /interp, /noloop)
   objt.tmass_j -= 0.902 * ebv
   objt.tmass_h -= 0.576 * ebv
   objt.tmass_k -= 0.367 * ebv

   ; Trim to good observations of isolated stars (no neighbors within 6 arcsec)
   if (keyword_set(objt)) then begin
      mdist = 6./3600
      ingroup = spheregroup(objt.tmass_ra, objt.tmass_dec, mdist, $
       multgroup=multgroup, firstgroup=firstgroup, nextgroup=nextgroup)
      indx = where(multgroup[ingroup] EQ 1, ct)
      if (ct GT 0) then objt = objt[indx] else objt = 0
   endif

   ; Trim to stars in the desired magnitude + color boxes
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

   ; Prioritize the **brightest** stars
   ; Priority values between [1,100]
   if (keyword_set(objt)) then begin
      priority_t = 1 + floor( 100. * (max(objt.tmass_j) - objt.tmass_j) $
       / (max(objt.tmass_j) - min(objt.tmass_j) + 0.1) )
   endif

   ;---------------------------------------------------------------------------
   ; Combine both lists into one output structure
   ;---------------------------------------------------------------------------

   stardata1 = create_struct( $
    'RA'       , 0.D, $
    'DEC'      , 0.D, $
    'MAG'      , fltarr(5), $
    'HOLETYPE' , '', $
    'OBJTYPE'  , '', $
    'PRIORITY' , 0L )
   nobj1 = n_elements(objs)
   nobj2 = n_elements(objt)
   stardata = replicate(stardata1, nobj1+nobj2)
   if (nobj1 GT 0) then begin
      stardata[0:nobj1-1].ra = objs.ra
      stardata[0:nobj1-1].dec = objs.dec
      stardata[0:nobj1-1].priority = priority_s
      stardata[0:nobj1-1].mag = 22.5 - 2.5*alog10(objs.fiberflux>0.1)
   endif
   if (nobj2 GT 0) then begin
      stardata[nobj1:nobj1+nobj2-1].ra = objt.tmass_ra
      stardata[nobj1:nobj1+nobj2-1].dec = objt.tmass_dec
      stardata[nobj1:nobj1+nobj2-1].priority = priority_t
      stardata[nobj1:nobj1+nobj2-1].mag = $
       plate_tmass_to_sdss(objt.tmass_j, objt.tmass_h, objt.tmass_k)
   endif

   stardata.holetype = 'OBJECT'
   indx1 = where(stardata.mag[1] GE sphoto_mag[0] $
    AND stardata.mag[1] LT sphoto_mag[1], ct1)
   if (ct1 GT 0) then stardata[indx1].objtype = 'SPECTROPHOTO_STD'
   indx2 = where(stardata.mag[1] GE redden_mag[0] $
    AND stardata.mag[1] LT redden_mag[1], ct2)
   if (ct2 GT 0) then stardata[indx2].objtype = 'REDDEN_STD'
   indx = where(stardata.objtype NE '', ct)
   if (ct GT 0) then stardata = stardata[indx] $
    else stardata = 0

   return
end
;------------------------------------------------------------------------------
