;+
; NAME:
;   plate_qsos
; PURPOSE:
;   design a QSO test plate
; CALLING SEQUENCE:
;   plate_qsos, filebase [, tilenum=, platenum=, epoch=, rerun=, $
;    tilerad=, /doplot ]
; INPUTS:
;   filebase - file base name
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
pro plate_qsos, filebase, tilenum=tile, platenum=plate, epoch=epoch1, $
                rerun=rerun1, tilerad=tilerad1, doplot=doplot

common com_pq, tycdat

seed = -12L
if (keyword_set(epoch1)) then epoch = epoch1 $
else epoch = 2008.13
if (keyword_set(rerun1)) then rerun = rerun1 $
else rerun = [137]
nstd = 16L
nminsky = 64L
if (keyword_set(tilerad1)) then tilerad = tilerad1 $
else tilerad = 1.49

;; Read in files and trim to objects in tile
qso_hi= qsolist_read(filebase+'.dr5.hipriority', racen=racen, deccen=deccen)
spherematch, racen, deccen, qso_hi.ra, qso_hi.dec, 1.49, m1, m2, max=0
qso_hi=qso_hi[m2]
qso_lo= qsolist_read(filebase+'.dr6.lopriority')
spherematch, racen, deccen, qso_lo.ra, qso_lo.dec, 1.49, m1, m2, max=0
qso_lo=qso_lo[m2]
qso_loest= qsolist_read('HIGHERDENSITY'+filebase+'.dr6.lopriority')
spherematch, racen, deccen, qso_loest.ra, qso_loest.dec, 1.49, m1, m2, max=0
qso_loest=qso_loest[m2]

qso1= create_struct( $
                     'RA'       , 0.D, $
                     'DEC'      , 0.D, $
                     'MAG'      , fltarr(5), $
                     'HOLETYPE' , 'OBJECT', $
                     'OBJTYPE'  , 'QSO', $
                     'PRIORITY' , 0L )

qsos_hi=replicate(qso1, n_elements(qso_hi))
struct_assign, /nozero, qso_hi, qsos_hi
qsos_hi.priority=200
qsos_hi.mag[1]=qso_hi.g
qsos_hi.mag[0]=qsos_hi.mag[1]+qso_hi.umg
qsos_hi.mag[2]=qsos_hi.mag[1]-qso_hi.gmr
qsos_hi.mag[3]=qsos_hi.mag[2]-qso_hi.rmi
qsos_hi.mag[4]=qsos_hi.mag[3]-qso_hi.imz

iz=where(qso_lo.zphot ge 2. and $
         qso_lo.zphot le 3.5, nz)
qsos_lo=replicate(qso1, nz)
struct_assign, /nozero, qso_lo[iz], qsos_lo
qsos_lo.priority=151
qsos_lo.mag[1]=qso_lo[iz].g
qsos_lo.mag[0]=qsos_lo.mag[1]+qso_lo[iz].umg
qsos_lo.mag[2]=qsos_lo.mag[1]-qso_lo[iz].gmr
qsos_lo.mag[3]=qsos_lo.mag[2]-qso_lo[iz].rmi
qsos_lo.mag[4]=qsos_lo.mag[3]-qso_lo[iz].imz

ilast=where(qso_lo.zphot lt 2. OR $
            qso_lo.zphot gt 3.5, nlast)
qsos_last=replicate(qso1, nlast)
struct_assign, /nozero, qso_lo[ilast], qsos_last
starprob= (qso_lo[ilast].starprob < 1.)>1.e-6
lprob=(alog(starprob)-min(alog(starprob)))/ $
  (max(alog(starprob))-min(alog(starprob)))
qsos_last.priority=round(101.+49.*(1.-lprob))
qsos_last.mag[1]=qso_lo[ilast].g
qsos_last.mag[0]=qsos_last.mag[1]+qso_lo[ilast].umg
qsos_last.mag[2]=qsos_last.mag[1]-qso_lo[ilast].gmr
qsos_last.mag[3]=qsos_last.mag[2]-qso_lo[ilast].rmi
qsos_last.mag[4]=qsos_last.mag[3]-qso_lo[ilast].imz

iz=where(qso_loest.zphot ge 2. and $
         qso_loest.zphot le 3.5, nz)
qsos_loest=replicate(qso1, nz)
struct_assign, /nozero, qso_loest[iz], qsos_loest
qsos_loest.priority=51
qsos_loest.mag[1]=qso_loest[iz].g
qsos_loest.mag[0]=qsos_loest.mag[1]+qso_loest[iz].umg
qsos_loest.mag[2]=qsos_loest.mag[1]-qso_loest[iz].gmr
qsos_loest.mag[3]=qsos_loest.mag[2]-qso_loest[iz].rmi
qsos_loest.mag[4]=qsos_loest.mag[3]-qso_loest[iz].imz

ilastest=where(qso_loest.zphot lt 2. OR $
               qso_loest.zphot gt 3.5, nlastest)
qsos_lastest=replicate(qso1, nlastest)
struct_assign, /nozero, qso_loest[ilastest], qsos_lastest
starprob= (qso_loest[ilastest].starprob < 1.)>1.e-6
lprob=(alog(starprob)-min(alog(starprob)))/ $
  (max(alog(starprob))-min(alog(starprob)))
qsos_lastest.priority=round(1.+49.*(1.-lprob))
qsos_lastest.mag[1]=qso_loest[ilastest].g
qsos_lastest.mag[0]=qsos_lastest.mag[1]+qso_loest[ilastest].umg
qsos_lastest.mag[2]=qsos_lastest.mag[1]-qso_loest[ilastest].gmr
qsos_lastest.mag[3]=qsos_lastest.mag[2]-qso_loest[ilastest].rmi
qsos_lastest.mag[4]=qsos_lastest.mag[3]-qso_loest[ilastest].imz

qsos=[qsos_hi, qsos_lo, qsos_last, qsos_loest, qsos_lastest]

tycdat = tycho_read(racen=racen, deccen=deccen, radius=tilerad, epoch=epoch)

;; Select sky targets
nsky = 300L
skyfile=filebase+'.sky.fits'
if(NOT file_test(skyfile)) then begin
    plate_select_sky, racen, deccen, nsky=nsky, $
      racurr=[qso_lo.ra, qso_hi.ra], $
      deccurr=[qso_lo.dec, qso_hi.dec], seed=seed, $
      doplot=doplot, stardata=skies, rerun=rerun
    mwrfits, skies, skyfile, /create
endif else begin
    skies=mrdfits(skyfile,1)
endelse

;; Select guide star targets
guidefile=filebase+'.guide.fits'
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
stdfile=filebase+'.std.fits'
if(NOT file_test(stdfile)) then begin
    plate_select_sphoto, racen, deccen, epoch=epoch, rerun=rerun, $
      tilerad=tilerad, stardata=standards, sphoto_mag=[16.,18.], $
      redden_mag=[0,0]
    isdss=where(standards.priority ge 101 and $
                standards.priority le 200, nsdss)
    standards=standards[isdss]

    mwrfits, standards, stdfile, /create
endif else begin
    standards=mrdfits(stdfile,1)
endelse

alldata = qsos
alldata = struct_append(alldata, skies)
alldata = struct_append(alldata, guides)
alldata = struct_append(alldata, standards)

plate_design, alldata, racen=racen, deccen=deccen, tile=tile, $
  plate=plate, nstd=nstd, nminsky=nminsky

return
end
;------------------------------------------------------------------------------
