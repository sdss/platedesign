;+
; NAME:
;   plate_marvels_new
; PURPOSE:
;   design a marvels plate (circa May 2008)
; CALLING SEQUENCE:
;   plate_marvels_new, fieldname [, tilenum=, platenum=, epoch=, rerun=, $
;    tilerad=, /doplot ]
; INPUTS:
;   fieldname - field name
; OPTIONAL INPUTS:
;   tilenum - tile number (default to whatever plate_design.pro does)
;   platenum - plate number (default to whatever plate_design.pro does)
;   epoch - epoch for guide stars + spectro-photo stars; default to 2007.9
;   rerun - rerun name(s) for select guide + spectro-photo stars;
;           default to [137]
;   tilerad - tile radius; default to 1.49
;   doplot - plotting option
; COMMENTS:
;   Writes output files from plate_design.pro into local directory
; REVISION HISTORY:
;   11-Oct-2007  MRB, NYU
;-
;------------------------------------------------------------------------------
pro plate_marvels_new, fieldname, tilenum=tile, platenum=plate, epoch=epoch1, $
                       rerun=rerun1, tilerad=tilerad1, doplot=doplot

common com_pq, tycdat

seed = -12L
if (keyword_set(epoch1)) then epoch = epoch1 $
else epoch = 2008.564
if (keyword_set(rerun1)) then rerun = rerun1 $
else rerun = [137]
nstd = 16L
nminsky = 64L
if (keyword_set(tilerad1)) then tilerad = tilerad1 $
else tilerad = 1.49

targets= yanny_readone('plateInput-'+fieldname+'.par', hdr=hdr)
hdrstr=lines2struct(hdr)
racen=double(hdrstr.racen)
deccen=double(hdrstr.deccen)

tycdat = tycho_read(racen=racen, deccen=deccen, radius=tilerad, epoch=epoch)

;; Select sky targets
nsky = 300L
skyfile=fieldname+'.sky.fits'
if(NOT file_test(skyfile)) then begin
    plate_select_sky, racen, deccen, nsky=nsky, $
      racurr=[targets.ra, targets.ra], $
      deccurr=[targets.dec, targets.dec], seed=seed, $
      doplot=doplot, stardata=skies, rerun=rerun
    mwrfits, skies, skyfile, /create
endif else begin
    skies=mrdfits(skyfile,1)
endelse

;; Select guide star targets
guidefile=fieldname+'.guide.fits'
if(NOT file_test(guidefile)) then begin
    plate_select_guide, racen, deccen, epoch=epoch, rerun=rerun, $
      tilerad=tilerad, stardata=guides
    
;; fix their coords based on Tycho if they exist
    if (keyword_set(tycdat)) then begin
        spherematch, guides.ra, guides.dec, tycdat.ramdeg, tycdat.demdeg, $
          2./3600, i1, i2, d12
        if (i1[0] NE -1) then begin
            help,i1
            guides[i1].ra = tycdat[i2].ramdeg
            guides[i1].dec = tycdat[i2].demdeg
        endif
    endif

    mwrfits, guides, guidefile, /create
endif else begin
    guides=mrdfits(guidefile,1)
endelse

;; Select spectro-photo star targets
stdfile=fieldname+'.std.fits'
if(NOT file_test(stdfile)) then begin
    plate_select_sphoto, racen, deccen, epoch=epoch, rerun=rerun, $
      tilerad=tilerad, stardata=standards, sphoto_mag=[10.5,14.], $
      redden_mag=[0,0]
    isdss=where(standards.priority ge 101 and $
                standards.priority le 200, nsdss)
    standards=standards[isdss]

    mwrfits, standards, stdfile, /create
endif else begin
    standards=mrdfits(stdfile,1)
endelse

alldata = targets
alldata = struct_append(alldata, skies)
alldata = struct_append(alldata, guides)
alldata = struct_append(alldata, standards)

plate_design, alldata, racen=racen, deccen=deccen, tile=tile, $
  plate=plate, nstd=nstd, nminsky=nminsky

return
end
;------------------------------------------------------------------------------
