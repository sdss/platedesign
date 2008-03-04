;+
; NAME:
;   trial_lrgs_for_tile
; PURPOSE:
;   Create a list of LRGs usable for evaluating tiling strategy
; CALLING SEQUENCE:
;   trial_lrgs_for_tile [, /clobber ]
; COMMENTS:
;   Goes through the $PHOTO_SWEEP files and selects
;   all possible LRGs. Stores these in the file:
;     $PLATEDESIGN_DATA/strategy/lrgs/full-lrgs.fits
;   Does not remake unless not already made or unless 
;   /clobber is set.
;  
;   Then selects those lrgs with b>20, and creates the
;   file:
;     $PLATEDESIGN_DATA/strategy/lrgs/ngc-lrgs.fits
;
;   Finally, takes random positions in the proposed 
;   SGC area and creates the file
;     $PLATEDESIGN_DATA/strategy/lrgs/sgc-lrgs.fits
; 
;   These data are to be used as input for trial_tile,
;   which creates the inputs to run an initial set of 
;   tiles on.
; REVISION HISTORY:
;   25-Sep-2007  MRB, NYU
;-
;------------------------------------------------------------------------------
pro trial_lrgs_for_tile, clobber=clobber

rerun=[137, 161]

fullfile=getenv('PLATEDESIGN_DATA')+'/strategy/lrgs/full-lrgs.fits'
if(keyword_set(clobber) gt 0 OR $
   file_test(fullfile) eq 0) then begin
    runs=sdss_runlist(rerun=rerun)
    primary=sdss_flagval('RESOLVE_STATUS', 'SURVEY_PRIMARY')
    
    first=1
    for irun=0L, n_elements(runs)-1L do begin
        for camcol=1L, 6L do begin
            splog, strtrim(string(runs[irun].run),2)+'/'+ $
              strtrim(string(camcol),2)
            objs=sweep_readobj(runs[irun].run, camcol, $
                               rerun=runs[irun].rerun, $
                               type='gal')
            if(n_tags(objs) gt 0) then begin
                fibermag = 22.5 - 2.5*alog10(objs.fiberflux>0.01)
                ilist = boss_galaxy_select(objs)
                ilrg = where(ilist GT 0 AND fibermag[3,*] GT 16 AND $
                             (objs.resolve_status AND primary) gt 0, nlrg)
                if(nlrg gt 0) then begin
                    if(first eq 1) then begin
                        mwrfits, objs[ilrg], fullfile, /create
                        first=0
                    endif else begin
                        mwrfits_chunks, objs[ilrg], fullfile, /append
                    endelse
                    
                endif
            endif
        endfor
    endfor
endif

lrgs=mrdfits(fullfile, 1)

glactc, lrgs.ra, lrgs.dec, 2000., gl, gb, 1, /deg

ikeep=where(gb gt 20. AND $
            lrgs.dec gt -5. AND $
            lrgs.dec gt (-11.+(lrgs.ra-232.)*43./36.) AND $
            lrgs.dec lt (71.+(lrgs.ra-240.)*(23.-71.)/35.) AND $
            lrgs.dec lt (58.8+(lrgs.ra-118.)*(70.-58.8)/27.), nkeep)
lrgs=lrgs[ikeep]

ngcfile=getenv('PLATEDESIGN_DATA')+'/strategy/lrgs/ngc-lrgs.fits'
mwrfits, lrgs, ngcfile, /create

nsgc=300000L
lambda=randomu(seed,nsgc)*(50+60)-60.   
eta=randomu(seed,nsgc)*(160-131.)+131.
etalambda_to_radec, eta,lambda,ra,dec
slrg0=struct_trimtags(lrgs[0], except=['rerun'])

slrgs=replicate(slrg0, nsgc)
struct_assign, {junk:0}, slrgs
slrgs.ra=ra
slrgs.dec=dec

sgcfile=getenv('PLATEDESIGN_DATA')+'/strategy/lrgs/sgc-lrgs.fits'
mwrfits, slrgs, sgcfile, /create

end
