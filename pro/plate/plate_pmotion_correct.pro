;+
; NAME:
;   plate_pmotion_correct
;
; PURPOSE:
;   Apply proper motion corrections from USNO-B1.0, for objects that match
;
; CALLING SEQUENCE:
;   plate_pmotion_correct, objs, epoch=
;
; INPUTS:
;   objs       - Structure with SDSS objects, or 2MASS objects
;   epoch      - Epoch for applying proper motion [yr]
;
; OPTIONAL INPUTS:
;
; OUTPUTS:
;   objs       - (Modified)
;
; COMMENTS:
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
pro plate_pmotion_correct, objs, epoch=epoch

   if (NOT keyword_set(objs)) then return
   if (n_elements(epoch) NE 1) then $
    message,' Must specify EPOCH'

   ; Define J2000 == JD 2451545 == MJD 51544.5
   newmjd = (epoch - 2000.)*365. + 51544.5d0

   if (tag_exist(objs, 'RA')) then begin
      thisra = objs.ra
      thisdec = objs.dec
      thismjd = objs.mjd
   endif else if (tag_exist(objs,'TMASS_RA')) then begin
      thisra = objs.tmass_ra
      thisdec = objs.tmass_dec
      thismjd = objs.tmass_jdate - 2400000.5D
   endif else begin
      message, 'Unknown input structure OBJS'
   endelse

   matchrad = 2./3600
   for i=0L, n_elements(thisra)-1L do begin
      dat1 = usno_read(thisra[i], thisdec[i], matchrad)
      if (n_elements(dat1) EQ 1) then begin
         if (tag_exist(dat1,'MURA') EQ 0) then $
          message, 'Old version of USNO catalog is set up!'
         thisra[i] += (newmjd - thismjd[i])/365. * dat1.mura/3600./1000.
         thisdec[i] += (newmjd - thismjd[i])/365. * dat1.mudec/3600./1000.
      endif
   endfor

   if (tag_exist(objs, 'RA')) then begin
      objs.ra = thisra
      objs.dec = thisdec
      objs.mjd = thismjd
   endif else if (tag_exist(objs,'TMASS_RA')) then begin
      objs.tmass_ra = thisra
      objs.tmass_dec = thisdec
      objs.tmass_jdate = 2400000.5D + thismjd
   endif

   return
end
;------------------------------------------------------------------------------
