;+
; NAME:
;   plate_select_sky_sdss
; PURPOSE:
;   Given a plate center, pick appropriate sky locations from SDSS
; CALLING SEQUENCE:
;   plate_select_sky, racen, deccen, [ nsky=, $
;    tilerad=, seed=, sky_design= ]
; INPUTS:
;   racen, deccen - center of plate, J2000 degrees 
; OPTIONAL INPUTS:
;   tilerad - radius of tile in deg (default 1.49 deg)
;   nsky - number of sky fibers desired (default 64)
;   seed - random seed 
;   nper - maximum to add per cycle (default 10)
; OPTIONAL OUTPUTS:
;   sky_design - output structure with sky coordinates in J2000 [NSKY]
; REVISION HISTORY:
;   11-Oct-2007  MRB, NYU
;-
;------------------------------------------------------------------------------
pro plate_select_sky_sdss, racen, deccen, nsky=nsky, tilerad=tilerad, $
  seed=seed, sky_design=sky_design, nper=nper

if(NOT keyword_set(nper)) then nper=2L
if(NOT keyword_set(tilerad)) then tilerad=1.49
if(n_elements(in_racurr) gt 0 AND $
   n_elements(in_deccurr) gt 0) then begin
    racurr=in_racurr
    deccurr=in_deccurr
endif

ngrid=11L
rasky=0
decsky=0

;; make a grid to make sure things are nicely spaced
ragrid=dblarr(ngrid,ngrid)
decgrid=dblarr(ngrid,ngrid)
for i=0L, ngrid-1L do begin
    for j=0L, ngrid-1L do begin
        ragrid[i, j]= (racen-tilerad/cos(deccen*!DPI/180.))+ $
          2.*tilerad*(float(i)+0.5)/float(ngrid)/cos(deccen*!DPI/180.)
        decgrid[i, j]= (deccen-tilerad)+ $
          2.*tilerad*(float(j)+0.5)/float(ngrid)
    endfor
endfor
ragrid=reform(ragrid, ngrid*ngrid)
decgrid=reform(decgrid, ngrid*ngrid)

;; but only keep those actually within the tile
keep=lonarr(n_elements(ragrid))
nspace=tilerad*2./float(ngrid)
spherematch, racen, deccen, ragrid, decgrid, tilerad-0.01, $
  m1, m2, d12, max=0
keep[m2]=1
ikeep=where(keep, ngrid)
ragrid=ragrid[ikeep]
decgrid=decgrid[ikeep]

;; now, for each pick a sky location
ishuffle=shuffle_indx(ngrid, seed=seed)
i=0L
ngot=0L

if(keyword_set(doplot)) then begin
    num=100
    th=findgen(num)/float(num-1L)*!DPI*2.
    rr=racen+tilerad*cos(th)/cos(deccen*!DPI/180.)
    dd=deccen+tilerad*sin(th)
    splot,rr,dd
    soplot, ragrid, decgrid, psym=5, color='red'
endif

nremember=6L
while(i lt ngrid AND $
      ngot lt nsky) do begin
    tmp_ra=ragrid[ishuffle[i]]
    tmp_dec=decgrid[ishuffle[i]]
    use_grid=1
    if(keyword_set(old_ra)) then begin
        spherematch, tmp_ra, tmp_dec, old_ra, old_dec, tilerad*10., m1, m2,d12
        if(d12[0] lt tilerad*0.2) then use_grid=0
    endif
    if(keyword_set(use_grid)) then begin
        sky_location_candidates, tmp_ra, tmp_dec, nspace/2., $
          cand_ra, cand_dec, exclude=exclude, seed=seed
        gotone=0L
        if(keyword_set(cand_ra)) then begin
            keep=lonarr(n_elements(cand_ra))
            spherematch, racen, deccen, cand_ra, cand_dec, tilerad-0.01, $
              m1, m2, d12, max=0
            if(m1[0] ne -1) then $
              keep[m2]=1
            if(keyword_set(racurr)) then begin
                spherematch, cand_ra, cand_dec, racurr, deccurr, $
                  exclude/3600., m1, m2, d12
                if(m1[0] ne -1) then $
                  keep[m1]=0
            endif 
            ikeep=where(keep, nkeep)
            if(nkeep gt 0) then begin
                gotone=1L
                is=shuffle_indx(nkeep, num_sub=(nper<nkeep), seed=seed)
                use_ra= cand_ra[ikeep[is]]
                use_dec= cand_dec[ikeep[is]]
            endif
            
            if(gotone) then begin
                if(keyword_set(racurr)) then begin
                    racurr= [racurr, use_ra]
                    deccurr= [deccurr, use_dec]
                endif else begin
                    racurr=use_ra
                    deccurr=use_dec
                endelse 
                if(keyword_set(rasky)) then begin
                    rasky= [rasky, use_ra]
                    decsky= [decsky, use_dec]
                endif else begin
                    rasky=use_ra
                    decsky=use_dec
                endelse
                ngot=ngot+n_elements(use_ra)
                if(n_elements(old_ra) lt nremember) then begin
                    if(keyword_set(old_ra)) then begin
                        old_ra=[old_ra, tmp_ra]
                        old_dec=[old_dec, tmp_dec]
                    endif else begin
                        old_ra=tmp_ra
                        old_dec=tmp_dec
                    endelse
                endif else begin
                   old_ra=[old_ra[1:nremember-1L], tmp_ra] 
                   old_dec=[old_dec[1:nremember-1L], tmp_dec] 
                endelse
            endif
        endif
    endif
    i=(i+1) MOD ngrid
    if(keyword_set(doplot)) then $
      soplot,rasky, decsky, psym=4, th=4, color='green'
endwhile

sky_design= replicate(design_blank(), n_elements(rasky))
sky_design.target_ra= rasky
sky_design.target_dec= decsky
sky_design.targettype= 'SKY'
sky_design.sourcetype= 'NA'

end
