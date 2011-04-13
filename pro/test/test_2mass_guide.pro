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
pro test_2mass_guide

racen= 262.580120D
deccen= -26.79813D
racen= 50.580120D
deccen= 26.79813D
epoch=2011.

tilerad1= 0.5

if (n_elements(racen) NE 1 OR n_elements(deccen) NE 1 $
    OR n_elements(epoch) NE 1) then $
  message,'Must specify RACEN, DECCEN, EPOCH'
if (keyword_set(tilerad1)) then tilerad = tilerad1 $
else tilerad = 1.45

;; make sure we're not TOO close to the edge
tilerad= tilerad < 1.45

if(NOT keyword_set(gminmax)) then $
  gminmax=[13., 14.5]

;; Read all the 2MASS objects on the plate
objt = tmass_read(racen, deccen, tilerad)

info= querygsc([racen, deccen], tilerad*60.)
sdss= sdss_sweep_circle(racen, deccen, tilerad)

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
    glactc, objt.tmass_ra, objt.tmass_dec, 2000., gl, gb, 1, /deg
    ebv= dust_getval(gl, gb, /noloop)
    jmag= (objt.tmass_j - ebv*0.902) 
    hmag= (objt.tmass_h - ebv*0.576)
    kmag= (objt.tmass_k - ebv*0.367)

    jkcolor= jmag-kmag
    mag= plate_tmass_to_sdss(jmag, hmag, kmag)
    red_fac = [5.155, 3.793, 2.751, 2.086, 1.479 ]
    mag= mag+ red_fac#ebv
    
    indx = where(objt.tmass_bl_flg EQ 111 $
                 AND mag[1,*] gt gminmax[0] $
                 AND mag[1,*] lt gminmax[1] $
                 AND objt.tmass_cc_flg EQ '000' $
                 AND objt.tmass_gal_contam EQ 0 $
                 AND objt.tmass_mp_flg EQ 0 $
                 AND jkcolor GT 0.4 AND jkcolor LT 1.75, ct)

endif

ii=where(info.fpgmag ne 99.99 and info.jpgmag ne 99.99)
spherematch, info[ii].ra, info[ii].dec, objt.tmass_ra, objt.tmass_dec, 1./3600., m1, m2
splot, mag[1,m2], info[ii[m1]].fpgmag, psym=3
jj=where(sdss.psfflux[1] gt 0.)
spherematch, sdss[jj].ra, sdss[jj].dec, objt.tmass_ra, objt.tmass_dec, 1./3600., sm1, sm2
soplot, mag[1,sm2], 22.5-2.5*alog10(sdss[jj[sm1]].psfflux[1]), psym=3, color='red'
soplot, [0., 30.], [0.,30.]

splot, 3600.*(objt[m2].tmass_ra-info[ii[m1]].ra), $ 
  3600.*(objt[m2].tmass_dec-info[ii[m1]].dec), $ 
  psym=3

soplot, 3600.*(objt[sm2].tmass_ra-sdss[jj[sm1]].ra), $ 
  3600.*(objt[sm2].tmass_dec-sdss[jj[sm1]].dec), $ 
  psym=3, color='red'
              

save, filename='hilat.sav'

return
end
;------------------------------------------------------------------------------
