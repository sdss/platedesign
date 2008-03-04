;+
; NAME:
;   plate_select_guide
;
; PURPOSE:
;   Select guide stars for a single plate
;
; CALLING SEQUENCE:
;   plate_select_guide, racen, deccen, epoch= $
;    [ rerun=, tilerad=, stardata= ]
;
; INPUTS:
;   racen      - RA center for tile [J2000 deg]
;   deccen     - DEC center for tile [J2000 deg]
;   epoch      - Epoch for output stars, for applying proper motion [yr]
;
; OPTIONAL INPUTS:
;   rerun      - Rerun name(s); if not specified, then only select guide
;                stars from 2MASS
;   tilerad    - Tile radius; default to 1.49 deg
;
; OUTPUTS:
;
; OPTIONAL OUTPUTS:
;   stardata   - Output structure with sky coordinates in J2000 [NSKY]
;
; COMMENTS:
;   SDSS guide stars are selected as follows:
;     13.0 < g < 15.5
;     0.3 < g-r < 1.4
;     0.0 < r-i < 0.7
;     -0.4 < i-z < 1.0
;   All magnitudes and colors are without extinction-correction.
;   Priority is given to those stars bluest in g-r color, from [101,200].
;
;   2MASS guide stars are selected as follows:
;     0.4 < J-K < 0.6
;   All magnitudes and colors are without extinction-correction.
;   Priority is given to those stars bluest in J-K color, from [1,100].
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
pro plate_select_guide, racen, deccen, epoch=epoch, $
 rerun=rerun, tilerad=tilerad1, stardata=stardata

   if (n_elements(racen) NE 1 OR n_elements(deccen) NE 1 $
    OR n_elements(epoch) NE 1) then $
    message,' Must specify RACEN, DECCEN, EPOCH'
   if (keyword_set(tilerad1)) then tilerad = tilerad1 $
    else tilerad = 1.49

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

      ; Apply proper motion corrections
      plate_pmotion_correct, objs, epoch=epoch

      ; Prioritize the **bluest** stars in (g-r) color, which is
      ; the opposite of what SDSS-I did.
      ; Priority values between [101,200]
      if (keyword_set(objs)) then begin
         priority_s = 101 + 99 * round((max(grcolor) - grcolor) $
          / (max(grcolor) - min(grcolor) + 0.01))
      endif
   endif

   ;---------------------------------------------------------------------------
   ; 2MASS OBJECTS
   ;---------------------------------------------------------------------------

   ; Read all the 2MASS objects on the plate
   objt = tmass_read(racen, deccen, tilerad)

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

   ; Apply proper motion corrections
   plate_pmotion_correct, objt, epoch=epoch

   ; Prioritize the **bluest** stars in (J-K) color
   ; Priority values between [1,100]
   if (keyword_set(objt)) then begin
      priority_t = 1 + 99 * round((max(jkcolor) - jkcolor) $
       / (max(jkcolor) - min(jkcolor) + 0.01))
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
   stardata.holetype = 'GUIDE'
   stardata.objtype = 'NA'

   return
end
;------------------------------------------------------------------------------
