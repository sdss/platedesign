;+
; NAME:
;   plate_select_guide_usnob
; PURPOSE:
;   Select guide stars for a single plate from USNOB
; CALLING SEQUENCE:
;   plate_select_guide_usnob, racen, deccen, epoch= $
;    [ rerun=, tilerad=, guide_design= ]
; INPUTS:
;   racen      - RA center for tile [J2000 deg]
;   deccen     - DEC center for tile [J2000 deg]
;   epoch      - Epoch for output stars, for applying proper motion [yr]
; OPTIONAL INPUTS:
;   tilerad    - Tile radius; default to 1.49 deg
;   gminmax_mag - magnitude limits for guides (default [13., 14.5]
;   gminmax_band - band for mag limits (default 'g')
;   jkminmax - obsolete
;   nguidemax - maximum number of guides to seek (default infinite)
; OPTIONAL OUTPUTS:
;   guide_design   - Output structure with sky coordinates in J2000 [NSKY]
; COMMENTS:
;   Only includes objects with 2MASS detection, and 
;   uses the 2MASS coordinates.
; REVISION HISTORY:
;   7-Apr-2011  Mike Blanton, NYU
;-
;------------------------------------------------------------------------------
pro plate_select_guide_usnob, racen, deccen, epoch=epoch, $
                              tilerad=tilerad1, guide_design=guide_design, $
                              gminmax_mag=gminmax_mag, nguidemax=nguidemax, $
                              jkminmax=jkminmax, seed=seed, gminmax_band=gminmax_band, $
                              star_require=star_require


if (n_elements(racen) NE 1 OR n_elements(deccen) NE 1 $
    OR n_elements(epoch) NE 1) then $
  message,'Must specify RACEN, DECCEN, EPOCH'
if (keyword_set(tilerad1)) then tilerad = tilerad1 $
else tilerad = 1.45

;; make sure we're not TOO close to the edge
tilerad= tilerad < 1.45

if(NOT keyword_set(gminmax_mag)) then $
  gminmax_mag=[13., 14.5]

if(NOT keyword_set(gminmax_band)) then begin
    gminmax_band = 1
endif
igminmax_band = filternum(gminmax_band)

;; Read all the 2MASS objects on the plate
objt = tmass_read(racen, deccen, tilerad)
usnob = usno_read(racen, deccen, tilerad*3.)

;; restrict USNO-B to stars
if(keyword_set(star_require)) then begin
    istar= where(usnob.sg[2] gt 5)
    usnob= usnob[istar]
endif

spherematch, racen, deccen, usnob.ra, usnob.dec, tilerad, m1, m2, max=0
usnob= usnob[m2]

;; Trim 2MASS to good observations 
if (keyword_set(objt)) then begin
    indx = where(objt.tmass_bl_flg EQ 111 $
                 AND objt.tmass_cc_flg EQ '000' $
                 AND objt.tmass_gal_contam EQ 0 $
                 AND objt.tmass_mp_flg EQ 0 , ct)
    if (ct GT 0) then begin
        objt = objt[indx] 
    endif else begin
        return
    endelse
endif

;; Trim USNO-B to observations of isolated stars (no neighbors within
;; 6 arcsec and 1.5 mag)
if (keyword_set(usnob)) then begin
    spherematch, usnob.ra, usnob.dec, usnob.ra, usnob.dec, 6./3600., $
      m1, m2, max=0L

    idiff=where(m1 ne m2, ndiff)
    if(ndiff gt 0) then begin
        m1=m1[idiff]
        m2=m2[idiff]

        keep= bytarr(n_elements(usnob))+1L
        
        isort= sort(m1)
        iuniq= uniq(m1[isort])
        ist=0L
        for i=0L, n_elements(iuniq)-1L do begin
            ind= iuniq[i]
            icurr= isort[ist:ind]
            mag1= usnob[m1[icurr[0]]].mag[2]
            mag2= usnob[m2[icurr]].mag[2]
            iclose= where(mag2 lt mag1+1.5, nclose)
            if(nclose gt 0) then $
              keep[m1[icurr[0]]]=0
            ist= ind+1L
        endfor

        ikeep= where(keep, ct)
        if(ct eq 0) then return
        usnob= usnob[ikeep]
    endif
endif

spherematch, objt.tmass_ra, objt.tmass_dec, usnob.ra, usnob.dec, 1./3600., m1, m2
if(m1[0] eq -1) then return
objt=objt[m1]
usnob=usnob[m2]

;; set magnitudes (a true hack!)
glactc, objt.tmass_ra, objt.tmass_dec, 2000., gl, gb, 1, /deg
ebv= dust_getval(gl, gb, /noloop)
jmag= (objt.tmass_j - ebv*0.902) 
hmag= (objt.tmass_h - ebv*0.576)
kmag= (objt.tmass_k - ebv*0.367)
jkcolor= jmag-kmag
mag= plate_tmass_to_sdss(jmag, hmag, kmag)
;red_fac = [5.155, 3.793, 2.751, 2.086, 1.479 ]
red_fac = reddening()
mag= mag+ red_fac#ebv
goffset= usnob.mag[2]-mag[1,*] 
roffset= usnob.mag[3]-mag[2,*] 
ioffset= usnob.mag[4]-mag[3,*] 

;; if g-band guide mag limits, offset from the equivalent in USNO-B
;; (J)
if(igminmax_band eq 1) then begin
    offset = goffset 
endif 

;; if i-band guide mag limits, offset from equivalent in 
;; (N) or from r-band equivalent (F) if N is bad
if(igminmax_band eq 3) then begin
    offset = ioffset 
    ibad = where(usnob.mag[4] eq 0. and $
                 usnob.mag[3] gt 0., nbad)
    if(nbad gt 0) then $
      offset[ibad] = roffset[ibad]
endif 

;; apply offsets
for i=0L, 4L do $
   mag[i,*]= mag[i,*]+offset

indx = where(mag[igminmax_band, *] gt gminmax_mag[0] AND $
             mag[igminmax_band, *] lt gminmax_mag[1], ct) 
if (ct eq 0) then return
usnob=usnob[indx]
objt=objt[indx]
mag=mag[*,indx]

;; Trim back number to maximum; only allow brightest
if(keyword_set(nguidemax)) then begin
    if(nguidemax lt n_elements(objt)) then begin
        isort= sort(mag[igminmax_band, *])
        indx= isort[0:nguidemax-1]
        usnob=usnob[indx]
        objt=objt[indx]
        mag=mag[*,indx]
    endif
endif

;; Apply proper motion corrections
;; (Results not good at day-level precision --- 
;; leap years only approximated).
ra=objt.tmass_ra
dec=objt.tmass_dec
from_mjd=objt.tmass_jdate-2400000.5D
to_mjd = (epoch - 2000.)*365.25 + 51544.5d0
plate_pmotion_correct, ra, dec, from_mjd=from_mjd, to_mjd=to_mjd, $
  mura=mura, mudec=mudec, racen=racen, deccen=deccen, tilerad=tilerad

;; Now put results into a design structure
guide_design= replicate(design_blank(/guide), n_elements(objt))
struct_assign, objt, guide_design, /nozero
guide_design.target_ra= ra
guide_design.target_dec= dec
guide_design.epoch=epoch
guide_design.pmra=mura
guide_design.pmdec=mudec
guide_design.usnob_mag=usnob.mag
guide_design.mag=mag

;; Finally, set priority; note that for guide stars priority is
;; used differently than elsewhere (see plate_assign_guide.pro)
isort= sort(guide_design.mag[igminmax_band])
guide_design[isort].priority= 1L+lindgen(n_elements(isort))

return
end
;------------------------------------------------------------------------------
