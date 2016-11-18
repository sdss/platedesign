;+
; NAME:
;   plate_select_guide_gaia
; PURPOSE:
;   Select guide stars for a single plate from Gaia
; CALLING SEQUENCE:
;   plate_select_guide_gaia, racen, deccen, epoch= $
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
; REVISION HISTORY:
;   18-Nov-2016  Written by MRB
;-
;------------------------------------------------------------------------------
pro plate_select_guide_gaia, racen, deccen, epoch=epoch, $
                             tilerad=tilerad1, guide_design=guide_design, $
                             gminmax=gminmax, nguidemax=nguidemax, $
                             seed=seed
  
  if (n_elements(racen) NE 1 OR n_elements(deccen) NE 1 $
      OR n_elements(epoch) NE 1) then $
         message,'Must specify RACEN, DECCEN, EPOCH'
  if (keyword_set(tilerad1)) then tilerad = tilerad1 $
  else tilerad = 1.45
  
  ;; make sure we're not TOO close to the edge
  tilerad= tilerad < 1.45

  if(NOT keyword_set(gminmax)) then $
     gminmax=[11., 15.0]

  ;; Read all the 2MASS objects on the plate
  objg = gaia_read(racen, deccen, tilerad)

  ;; Trim to stars in the desired magnitude + color boxes
  if (keyword_set(objg)) then begin
     indx = where(objg.phot_g_mean_mag gt gminmax[0] and $
                  objg.phot_g_mean_mag lt gminmax[1], ct)

     if (ct GT 0) then begin
        objg = objg[indx]
     endif else begin
        message, 'No good Gaia stars in magnitude range!'
     endelse
  endif

  ;; Trim back number to maximum; only allow brightest
  if(keyword_set(nguidemax)) then begin
     if(nguidemax lt n_elements(objg)) then begin
        isort= sort(objg.phot_g_mean_mag)
        indx= isort[0:nguidemax-1]
        objg=objg[indx]
     endif
  endif

  ra = objg.ra
  dec = objg.dec
  iok = where(objg.pmra eq objg.pmra AND $
              objg.pmdec eq objg.pmdec, nok)
  depoch = epoch - objg.ref_epoch
  if(nok gt 0) then begin
     ra[iok] = ra[iok] + $
               depoch[iok] * objg[iok].pmra / 1000. / $
               cos(!DPI * objg[iok].dec / 180.)
     dec[iok] = dec[iok] + depoch[iok] * objg[iok].pmdec / 1000.
  endif
  
  ;; Now put results into a design structure
  guide_design= replicate(design_blank(/guide), n_elements(objg))
  struct_assign, objg, guide_design, /nozero
  guide_design.target_ra= ra
  guide_design.target_dec= dec
  guide_design.epoch=epoch
  guide_design.pmra=objg.pmra
  guide_design.pmdec=objg.pmdec
  
  ;; Finally, set priority; note that for guide stars priority is
  ;; used differently than elsewhere (see plate_assign_guide.pro)
  isort= sort(guide_design.phot_g_mean_mag)
  guide_design[isort].priority= 1L+lindgen(n_elements(isort))
  
  return

end
;------------------------------------------------------------------------------
