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
; OPTIONAL KEYWORDS:
;   /nosdss - do not use SDSS even if it is available
; COMMENTS:
;   First checks for SDSS imaging, uses PHOTO sky objects (returns all
;     in area).  Uses datasweeps, requires $PHOTO_SWEEP to be set.
;   If SDSS isn't found, finds DSS image with querydss command,
;     returns lowest three locations (with 120'' exclusion)
; REVISION HISTORY:
;   11-Sep-2007  MRB, NYU
;-
;------------------------------------------------------------------------------
pro sky_location_candidates, ra, dec, radius,   $ ; inputs
                             cand_ra, cand_dec, $ ; output
                             exclude=exclude, seed=seed, nosdss=nosdss ; options

COMPILE_OPT idl2
COMPILE_OPT logical_predicate

common common_dss_cache, dss_cache

true = 1
false = 0

if (~keyword_set(dss_cache)) then $
	dss_cache_setup

if (~keyword_set(exclude)) then exclude=60 ;; 120. ;; fiber exclusion area in arcsec

; Look in database cache to see if we have done this lookup before.
; If nothing is found, input_id = 0.
dss_cache_lookup, ra, dec, radius, exclude, cand_ra, cand_dec, input_id

;splog, 'testing input_id: ' + toString(input_id)
if (input_id) then begin
	; we have the result, cand_ra and cand_dec are defined, can just return!
	splog, 'ra/dec found in local cache: ' + toString(ra) + "," + toString(dec)
	return
endif

splog, 'ra     = ' + string(ra)
splog, 'dec    = ' + string(dec)
;splog, 'radius = ' + string(radius)
;splog, 'rerun/seed = ' + toString(rerun) + '/' + toString(seed)

cand_ra=0
cand_dec=0

;; if SDSS exists, use its determinations
if(keyword_set(getenv('PHOTO_SWEEP')) gt 0 AND $
   keyword_set(nosdss) eq 0) then begin
    objs= sdss_sweep_circle(ra, dec, sqrt(2.)*radius, type='sky', $
                            /all, /silent)
    if(n_elements(objs) gt 10) then begin
        ;;ing=spheregroup(objs.ra, objs.dec, exclude/3600., firstg=firstg)
        ;;nmult=max(ing)+1L
        cand_ra=objs.ra   ;; objs[firstg[0:nmult-1]].ra
        cand_dec=objs.dec ;; objs[firstg[0:nmult-1]].dec
        return
    endif else begin
        cand_ra=0
        cand_dec=0
    endelse
endif

;; If not, track down ten candidates from DSS: basically, we want to
;; make sure we don't land in any detected object, and otherwise we
;; want to be in the lowest flux part of the VERY SMOOTHED image 
;;   a. download image
ncand=25L 
splog, 'Querying DSS.'
querydss, [ra, dec], image, hdr, survey='2r', imsize=radius*2.*60.
iz=where(image eq 0, nz)

iteration_count = 0

while((float(nz)/float(n_elements(image)) gt 0.25) AND iteration_count lt 6) do begin
    querydss, [ra, dec]+randomn(seed,2)*0.01, image, hdr, $
      survey='2r', imsize=radius*2.*60.
    iz=where(image eq 0, nz)
    iteration_count = iteration_count + 1
endwhile
if(~keyword_set(image)) then begin
    splog, 'no DSS imaging available.'
    return
endif
nx=(size(image, /dim))[0]
ny=(size(image, /dim))[1]

;;   b. find objects 
splog, 'Finding objects.'
mimage= dmedsmooth(image, box=200)
image=image-mimage
dobjects_multi, image, obj=obj, plim=1.5

;;   c. find regions isolated from objects (and edges)
splog, 'Finding isolated regions.'
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

    dss_cache_no_sky_for_input, ra, dec, radius, exclude

    return
endif

ix=ix[ikeep]
iy=iy[ikeep]
xyad, hdr, ix, iy, tmp_ra, tmp_dec

;;   d. NOW sort by smoothed image
splog, 'Pick keepers.'
smbox=smooth(image, 40)
isort=sort(smbox[isky[ikeep]])
cand_ra=dblarr(ncand)
cand_dec=dblarr(ncand)
cand_ra=ra_in_range(cand_ra)
i=0L
ic=0L

iteration_count = 0

while((i lt nkeep) AND (ic lt ncand) AND (iteration_count lt 10000)) do begin
    curr_ra= tmp_ra[isort[i]]
    curr_dec= tmp_dec[isort[i]]
	curr_ra = ra_in_range(curr_ra)
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

	;if ((iteration_count mod 150) eq 0) then $
	;	print, 'iteration step: ' + strtrim(string(iteration_count), 2)
	iteration_count = iteration_count + 1
	
endwhile

;splog, 'Iteration count: ' + strtrim(string(iteration_count), 2)

splog, 'Done.'

if(ic eq 0) then begin
    splog, 'NO SKY HERE'
    cand_ra=0
    cand_dec=0
    
    dss_cache_no_sky_for_input, ra, dec, radius, exclude
    
    return
endif

cand_ra=cand_ra[0:ic-1]
cand_dec=cand_dec[0:ic-1]

if (ra eq 0 or dec eq 0) then begin
	splog, 'sky candidates ra, dec = 0, not caching.'
endif else begin
	dss_cache_populate_sky, ra, dec, radius, exclude, cand_ra, cand_dec
endelse

return

end

; ===========================================================

