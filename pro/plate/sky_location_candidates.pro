;+
; NAME:
;   sky_location_candidates
; PURPOSE:
;   Pick sky locations within some area
; CALLING SEQUENCE:
;   sky_location_candidates, ra, dec, radius, cand_ra, cand_dec [, $
;     exclude= ]
; INPUTS:
;   ra, dec - coordinates, J2000, deg
;   radius - radius of area to search, deg
; OUTPUTS:
;   cand_ra, cand_dec - [Nout] candidate sky locations
; OPTIONAL INPUTS:
;   exclude - exclusion area around each sky in arcsec (default 120'')
; COMMENTS:
;   First checks for SDSS imaging, uses PHOTO sky objects (returns all
;     in area).  Uses datasweeps, requires $PHOTO_SWEEP to be set.
;   If SDSS isn't found, finds DSS image with querydss command,
;     returns lowest three locations (with 120'' exclusion)
; REVISION HISTORY:
;   11-Sep-2007  MRB, NYU
;-
;------------------------------------------------------------------------------
pro sky_location_candidates, ra, dec, radius, cand_ra, cand_dec, $
                             exclude=exclude, rerun=rerun, seed=seed

if(NOT keyword_set(exclude)) then exclude=120.

cand_ra=0
cand_dec=0

;; if SDSS exists, use its determinations
if(keyword_set(rerun)) then begin
    objs= sdss_sweep_circle(ra, dec, radius, type='sky', /silent)
    if(n_tags(objs) gt 0) then begin
        ing=spheregroup(objs.ra, objs.dec, exclude/3600., firstg=firstg)
        cand_ra=objs[firstg].ra
        cand_dec=objs[firstg].dec
        return
    endif else begin
        cand_ra=0
        cand_dec=0
    endelse
endif

;; if not, track down ten candidates from DSS: basically, we want to
;; make sure we don't land in any detected object, and otherwise we
;; want to be in the lowest flux part of the VERY SMOOTHED image 
;;   a. download image
ncand=10L
querydss, [ra, dec], image, hdr, survey='2r', imsize=radius*2.*60.
iz=where(image eq 0, nz)
while(float(nz)/float(n_elements(image)) gt 0.25) do begin
    querydss, [ra, dec]+randomn(seed,2)*0.01, image, hdr, $
      survey='2r', imsize=radius*2.*60.
    iz=where(image eq 0, nz)
endwhile
if(NOT keyword_set(image)) then begin
    splog, 'no DSS imaging available.'
    return
endif
nx=(size(image, /dim))[0]
ny=(size(image, /dim))[1]

;;   b. find objects 
mimage= dmedsmooth(image, box=200)
image=image-mimage
dobjects_multi, image, obj=obj, plim=1.5

;;   c. find regions isolated from objects (and edges)
mask=float(obj ge 0)
sm=20L
nzero=0L
while(float(nzero)/float(n_elements(mask)) lt 0.05 AND $
      sm gt 1) do begin 
    smask=smooth(mask, sm)
    izero=where(smask eq 0., nzero)
    sm=sm-1L
endwhile
isky= where(smask eq 0, nsky)
if(nsky eq 0) then message, 'no good sky location'
ix=isky mod nx
iy=isky / nx
ikeep=where(ix gt 30L and ix lt (nx-30L) and $
            iy gt 30L and iy lt (ny-30L), nkeep)
if(nkeep eq 0) then begin
    splog, 'NO SKY HERE'
    cand_ra=0
    cand_dec=0
    return
endif

ix=ix[ikeep]
iy=iy[ikeep]
xyad, hdr, ix, iy, tmp_ra, tmp_dec

;;   d. NOW sort by smoothed image
smbox=smooth(image, 40)
isort=sort(smbox[isky[ikeep]])
cand_ra=dblarr(ncand)
cand_dec=dblarr(ncand)
i=0L
ic=0L
while(i lt nkeep AND ic lt ncand) do begin
    curr_ra= tmp_ra[isort[i]]
    curr_dec= tmp_dec[isort[i]]
    useit=1L
    if(ic gt 0) then begin
        spherematch, curr_ra, curr_dec, cand_ra[0:ic-1], cand_dec[0:ic-1], $
          exclude/3600., m1, m2, d12
        if(m1[0] ne -1) then useit=0L
    endif
    if(useit) then begin
        cand_ra[ic]=curr_ra
        cand_dec[ic]=curr_dec
        ic=ic+1L
    endif
    i=i+1L
endwhile

if(ic eq 0) then begin
    splog, 'NO SKY HERE'
    cand_ra=0
    cand_dec=0
    return
endif

cand_ra=cand_ra[0:ic-1]
cand_dec=cand_dec[0:ic-1]

return

end
