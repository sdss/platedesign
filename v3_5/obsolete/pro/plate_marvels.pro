;+
; NAME:
;   plate_marvels
; PURPOSE:
;   design a marvels plate based on a .coo file
; CALLING SEQUENCE:
;   plate_marvels, coofile [, tilenum=, platenum=, epoch=, rerun=, $
;    tilerad=, /doplot ]
; INPUTS:
;   coofile - filename of .coo file
; OPTIONAL INPUTS:
;   tilenum - tile number (default to whatever plate_design.pro does)
;   platenum - plate number (default to whatever plate_design.pro does)
;   epoch - epoch for guide stars + spectro-photo stars; default to 2007.9
;   rerun - rerun name(s) for select guide + spectro-photo stars;
;           default to [137,161]
;   tilerad - tile radius; default to 1.49
;   doplot - plotting option
; COMMENTS:
;   Writes output files from plate_design.pro into local directory
; REVISION HISTORY:
;   11-Oct-2007  MRB, NYU
;-
;------------------------------------------------------------------------------
pro plate_marvels, coofile, tilenum=tile, platenum=plate, epoch=epoch1, $
 rerun=rerun1, tilerad=tilerad1, doplot=doplot

   seed = -12L
   if (keyword_set(epoch1)) then epoch = epoch1 $
    else epoch = 2007.9
   if (keyword_set(rerun1)) then rerun = rerun1 $
    else rerun = [137,161]
   nstd = 50L
   if (keyword_set(tilerad1)) then tilerad = tilerad1 $
    else tilerad = 1.49

   ; Read in .coo files, and trim to only science targets
   cstars = coo_read(coofile, racen=racen, deccen=deccen)
   indx = where(strmatch(cstars.objtype,'SERENDIPITY_MANUAL*'), nscience)
   if (nscience EQ 0) then $
    message, 'No targets in file!'
   cstars = cstars[indx]

   ; Estimates the science target magnitudes from Tycho or 2MASS
   ; (Magnitudes based upon Tycho will overwrite those based upon 2MASS)
   objt = tmass_read(racen, deccen, tilerad)
   if (keyword_set(objt)) then begin
      spherematch, cstars.ra, cstars.dec, objt.tmass_ra, objt.tmass_dec, $
       2./3600, i1, i2, d12
      if (i1[0] NE -1) then $
       cstars[i1].mag = plate_tmass_to_sdss(objt[i2].tmass_j, $
        objt[i2].tmass_h, objt[i2].tmass_k)
   endif
   tycdat = tycho_read(racen=racen, deccen=deccen, radius=tilerad, epoch=epoch)
   if (keyword_set(tycdat)) then begin
      spherematch, cstars.ra, cstars.dec, tycdat.ramdeg, tycdat.demdeg, $
       3./3600, i1, i2, d12
      if (i1[0] NE -1) then begin
          cstars[i1].mag = $
            plate_tycho_to_sdss(tycdat[i2].btmag, tycdat[i2].vtmag)
          ;; let us also fix coords
          cstars[i1].ra = tycdat[i2].ramdeg
          cstars[i1].dec = tycdat[i2].demdeg
      endif
   endif

   ; Select sky targets
   nsky = 640 - nscience + 20
   coobase=(stregex(coofile, '(.*)\.coo', /extr, /sub))[1]
   skyfile=coobase+'.sky.fits'
   if(NOT file_test(skyfile)) then begin
       plate_select_sky, racen, deccen, nsky=nsky, $
         racurr=cstars.ra, deccurr=cstars.dec, seed=seed, $
         doplot=doplot, stardata=sstars, rerun=rerun
       mwrfits, sstars, skyfile, /create
   endif else begin
       sstars=mrdfits(skyfile,1)
   endelse

   ; Select guide star targets
   plate_select_guide, racen, deccen, epoch=epoch, rerun=rerun, $
    tilerad=tilerad, stardata=gstars

   ;; fix their coords based on Tycho if they exist
   if (keyword_set(tycdat)) then begin
      spherematch, gstars.ra, gstars.dec, tycdat.ramdeg, tycdat.demdeg, $
       2./3600, i1, i2, d12
      if (i1[0] NE -1) then begin
          help,i1
          gstars[i1].ra = tycdat[i2].ramdeg
          gstars[i1].dec = tycdat[i2].demdeg
      endif
   endif

   ; Select spectro-photo star targets
   plate_select_sphoto, racen, deccen, epoch=epoch, rerun=rerun, $
    tilerad=tilerad, stardata=pstars, sphoto_mag=[10.5,14.], redden_mag=[0,0]

   ;; fix their coords based on Tycho if they exist
   if (keyword_set(tycdat)) then begin
      spherematch, pstars.ra, pstars.dec, tycdat.ramdeg, tycdat.demdeg, $
       2./3600, i1, i2, d12
      if (i1[0] NE -1) then begin
          help,i1
          pstars[i1].ra = tycdat[i2].ramdeg
          pstars[i1].dec = tycdat[i2].demdeg
      endif
   endif

   alldata = cstars
   alldata = struct_append(alldata, sstars)
   alldata = struct_append(alldata, gstars)
   alldata = struct_append(alldata, pstars)

   plate_design, alldata, racen=racen, deccen=deccen, tile=tile, $
    plate=plate, nstd=nstd

   return
end
;------------------------------------------------------------------------------
