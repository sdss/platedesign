;+
; NAME:
;   plate_select_sky_tmass
; PURPOSE:
;   Given a plate center, pick appropriate sky locations from SDSS
; CALLING SEQUENCE:
;   plate_select_sky_tmass, racen, deccen, [ nsky=, $
;    tilerad=, seed=, sky_design= ]
; INPUTS:
;   racen, deccen - center of plate, J2000 degrees 
; OPTIONAL INPUTS:
;   tilerad - radius of tile in deg (default 1.49 deg)
;   nsky - number of sky fibers desired (default 64)
;   seed - random seed 
; OPTIONAL OUTPUTS:
;   sky_design - output structure with sky coordinates in J2000 [NSKY]
; COMMENTS:
;   Just gives a set of points that are greater than 10 arcsec
;     from any 2MASS source.
;   Not as robust as SDSS skies, but a heck of a lot quicker.
; REVISION HISTORY:
;   11-Oct-2007  MRB, NYU
;-
;------------------------------------------------------------------------------
pro plate_select_sky_tmass, racen, deccen, nsky=nsky, tilerad=tilerad, $
  seed=seed, sky_design=sky_design

if(NOT keyword_set(tilerad)) then tilerad=1.49

exclusion=10./3600. ;; exclude 
safetyfactor=10L

tmass= tmass_read(racen, deccen, tilerad*1.1)

;; just make sure we have actually the right number of points
while(n_elements(rasky) lt nsky) do begin

    ;; pick some random points in a square
    tmp_rasky= racen+ (2.*randomu(seed, nsky*safetyfactor)-1.)/ $
      cos(!DPI/180.*deccen)*tilerad
    tmp_decsky= deccen+ (2.*randomu(seed, nsky*safetyfactor)-1.)*tilerad
    
    ;; close it off into a circle
    spherematch, racen, deccen, tmp_rasky, tmp_decsky, tilerad, m1, m2, max=0
    if(m2[0] ne -1) then begin
        tmp_rasky=tmp_rasky[m2]
        tmp_decsky=tmp_decsky[m2]

        ;; find points that are far from any 2MASS
        spherematch, tmass.tmass_ra, tmass.tmass_dec, tmp_rasky, tmp_decsky, $
          10./3600., m1, m2
        keep=bytarr(n_elements(tmp_rasky))+1
        keep[m2]=0
        ikeep=where(keep, nkeep)
        if(nkeep gt 0) then begin
            if(n_elements(rasky) eq 0) then begin
                rasky= tmp_rasky[ikeep]
                decsky= tmp_decsky[ikeep]
            endif else begin
                rasky= [rasky, tmp_rasky[ikeep]]
                decsky= [decsky, tmp_decsky[ikeep]]
            endelse
        endif
    endif

    splog, 'found '+strtrim(string(n_elements(rasky)),2)+' so far'
endwhile

indx=shuffle_indx(n_elements(rasky), num_sub=nsky)
rasky=rasky[indx]
decsky=decsky[indx]

sky_design= replicate(design_blank(), nsky)
sky_design.target_ra= rasky
sky_design.target_dec= decsky
sky_design.targettype= 'SKY'
sky_design.sourcetype= 'NA'

end
