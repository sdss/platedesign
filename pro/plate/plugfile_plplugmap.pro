;+]
; NAME:
;   plugfile_plplugmap
; PURPOSE:
;   Create a plug file in the style of plPlugMapP files from SDSS-II
; CALLING SEQUENCE:
;   plugfile_plplugmap, hdr, holes
; INPUTS:
;   hdr - header from plateHoles file
;   holes - [N] holes from plateHoles file
; BUGS:
;   CLASSIFIES ALL SOURCES AS STARS!!
; REVISION HISTORY:
;   10-Jun-2008  MRB, NYU
;-
pro plugfile_plplugmap, plateid

platedir= plate_dir(plateid)
platefile= platedir+'/plateHoles-'+ $
  strtrim(string(f='(i6.6)',plateid),2)+'.par'
holes= yanny_readone(platefile, hdr=hdr, /anon)

; Read definition
definition= lines2struct(hdr)
default= definition

designid= long(definition.designid)
platerun= definition.platerun
plateid= long(definition.plateid)
temp= float(definition.temp)
ha= float(strsplit(definition.ha, /extr))
npointings= long(definition.npointings)

plug0= plplugmap_blank(enums=plugenum, struct=plugstruct)
plug= replicate(plug0, n_elements(holes))

;; set holetype

plug.sectarget= 0

;; anything which is based on a target is called
;; an OBJECT in plPlugMap
ihole= where(strupcase(holes.targettype) ne 'NA', nhole)
if(nhole gt 0) then plug[ihole].holetype= 'OBJECT'

;; holetype GUIDE in holes -> 
;; holetype GUIDE in plPlugMap
ihole= where(strupcase(holes.holetype) eq 'GUIDE', nhole)
if(nhole gt 0) then plug[ihole].holetype= 'GUIDE'
if(nhole gt 0) then plug[ihole].sectarget= 64

;; holetype ALIGNMENT in holes -> 
;; holetype ALIGNMENT in plPlugMap
ihole= where(strupcase(holes.holetype) eq 'ALIGNMENT', nhole)
if(nhole gt 0) then plug[ihole].holetype= 'ALIGNMENT'

;; holetype CENTER in holes -> 
;; holetype QUALITY in plPlugMap
ihole= where(strupcase(holes.holetype) eq 'CENTER', nhole)
if(nhole gt 0) then plug[ihole].holetype= 'QUALITY'

;; holetype TRAP in holes -> 
;; holetype LIGHT_TRAP in plPlugMap
ihole= where(strupcase(holes.holetype) eq 'TRAP', nhole)
if(nhole gt 0) then plug[ihole].holetype= 'LIGHT_TRAP'

plug.ra= holes.target_ra
plug.dec= holes.target_dec

;; Bad conversion of mags ...
itmass= where(holes.tmass_j gt 0, ntmass)
if(ntmass gt 0) then begin
    plug[itmass].mag= plate_tmass_to_sdss(holes[itmass].tmass_j, $
                                          holes[itmass].tmass_h, $
                                          holes[itmass].tmass_k)
endif
imarvels= where(holes.gsc_vmag gt 0, nmarvels)
if(nmarvels gt 0) then begin
    plug[imarvels].mag= $
      plate_tmass_to_sdss(holes[imarvels].tmass_j, $
                          holes[imarvels].tmass_h, $
                          holes[imarvels].tmass_k)
    plug[imarvels].mag[1]= holes[imarvels].tyc_bmag
    plug[imarvels].mag[2]= holes[imarvels].gsc_vmag
endif
isdss= where(holes.run gt 0, nsdss)
if(nsdss gt 0) then begin
    plug[isdss].mag= 22.5-2.5*alog10(holes[isdss].fiberflux > 0.1)
endif

;; We will ignore these likelihood columns
plug.starl=0.
plug.expl=0.
plug.devaucl=0.

;; set objtype
;; !! SOURCETYPE ISN'T BEING SET SO WE'RE STILL ON MANUAL!

ihole= where(strupcase(holes.targettype) eq 'SCIENCE', nhole)
if(nhole gt 0) then plug[ihole].holetype= 'OBJECT'
if(nhole gt 0) then plug[ihole].objtype= 'SERENDIPITY_MANUAL'


ihole= where(strupcase(holes.targettype) eq 'SKY', nhole)
if(nhole gt 0) then plug[ihole].holetype= 'OBJECT'
if(nhole gt 0) then plug[ihole].objtype= 'SKY'
if(nhole gt 0) then plug[ihole].sectarget= 16

ihole= where(strupcase(holes.targettype) eq 'STANDARD', nhole)
if(nhole gt 0) then plug[ihole].holetype= 'OBJECT'
if(nhole gt 0) then plug[ihole].objtype= 'SPECTROPHOTO_STD'
if(nhole gt 0) then plug[ihole].sectarget= 32

;; xfocal and yfocal
plug.xfocal=holes.xfocal
plug.yfocal=holes.yfocal

;; spectrographid, throughput, primtarget not set
plug.spectrographid= 0
plug.throughput= 0
plug.primtarget= 0

;; fiber ID gets set to NEGATIVE of intended value
;; (unless it is -9999)
plug.fiberid=-9999
ihole=where(holes.fiberid ge 1, nhole)
;; Reassign fiberid to space nicely.
;;sdss_plugprob, plug[ihole].xfocal, plug[ihole].yfocal, fiberid
;;plug[ihole].fiberid=-fiberid
if(nhole gt 0) then $
  plug[ihole].fiberid= -holes[ihole].fiberid

;; but guide fibers get fiberid set too
ihole=where(holes.iguide ge 1, nhole)
if(nhole gt 0) then $
  plug[ihole].fiberid= holes[ihole].iguide

;; Compute the median reddening for objects on this plate
;; (just for first pointing)
indx = where(strtrim(plug.holetype,2) EQ 'OBJECT' AND $
             holes.pointing eq 1, nobj)
if(nobj gt 0) then begin
    euler, plug[indx].ra, plug[indx].dec, ll, bb, 1
    reddenvec = [5.155, 3.793, 2.751, 2.086, 1.479] $
                * median(dust_getval(ll, bb, /interp))
endif else begin
    reddenvec= [0., 0., 0., 0., 0.]
endelse

;; resort fibers
ihole= where(plug.holetype eq 'LIGHT_TRAP', nhole)
if(nhole gt 0) then begin
    newplug= plug[ihole]
    newholes= holes[ihole]
endif

ihole= where(plug.holetype eq 'GUIDE' OR $
             plug.holetype eq 'ALIGNMENT', nhole)
if(nhole gt 0) then begin
    sortstr= string(plug[ihole].fiberid, f='(i2.2)')+ $
      plug[ihole].holetype
    isort=sort(sortstr)
    if(n_tags(newplug) gt 0) then begin
        newplug= [newplug, plug[ihole[isort]]] 
        newholes= [newholes, holes[ihole[isort]]] 
    endif else begin
        newplug= plug[ihole[isort]]
        newholes= holes[ihole[isort]]
    endelse
endif

ihole= where(plug.holetype eq 'OBJECT', nhole)
if(nhole gt 0) then begin
    isort= sort(abs(plug[ihole].fiberid))
    if(n_tags(newplug) gt 0) then begin
        newplug=[newplug, plug[ihole[isort]]]
        newholes=[newholes, holes[ihole[isort]]]
    endif else begin
        newplug=plug[ihole[isort]]
        newholes=holes[ihole[isort]]
    endelse
endif

ihole= where(plug.holetype eq 'QUALITY', nhole)
if(nhole gt 0) then begin
    if(n_tags(newplug) gt 0) then begin
        newplug=[newplug, plug[ihole]]
        newholes=[newholes, holes[ihole]]
    endif else begin
        newplug=plug[ihole]
        newholes=holes[ihole]
    endelse
endif

if(n_elements(newplug) ne n_elements(plug)) then $
  message, 'Sorted plug structure messed up!'

plug=newplug
holes=newholes

sortedplatefile= platedir+'/plateHolesSorted-'+ $
  strtrim(string(f='(i6.6)',plateid),2)+'.par'
pdata= ptr_new(holes)
yanny_write, sortedplatefile, pdata, hdr=hdr
ptr_free, pdata

racen=dblarr(npointings)
deccen=dblarr(npointings)
for pointing=1L, npointings do begin
    plate_center, definition, default, pointing, 0L, $
                  racen=tmp_racen, deccen=tmp_deccen
    racen[pointing-1L]=tmp_racen
    deccen[pointing-1L]=tmp_deccen
endfor

pointing_name = strsplit(definition.pointing_name, /extract)
for pointing=1L, npointings do begin

    ;; add header keywords
    inotradec= where(strmatch(hdr, 'racen *', /fold_case) eq 0 AND $
                     strmatch(hdr, 'deccen *', /fold_case) eq 0, nnotradec)
    khdr= hdr[inotradec]
    outhdr = ['completeTileVersion   none', $
              'haMin ' + string(ha[pointing-1]), $
              'haMax ' + string(ha[pointing-1]), $
              'mjdDesign ' + string(long(current_mjd())), $
              'pointing ' + pointing_name[pointing-1], $
              'mag_quality bad',  $
              khdr]
    if(keyword_set(yanny_par(outhdr, 'reddeningMed')) eq 0) then $
      outhdr=[outhdr, 'reddeningMed ' + string(reddenvec,format='(5f8.4)')]
    if(keyword_set(yanny_par(outhdr, 'theta')) eq 0) then $
      outhdr=[outhdr, 'theta 0']
    if(keyword_set(yanny_par(outhdr, 'plateId')) eq 0) then $
      outhdr=[outhdr, 'plateId ' + strtrim(string(plateid),2)]
    if(keyword_set(yanny_par(outhdr, 'raCen')) eq 0) then $
      outhdr=[outhdr, 'raCen ' + string(racen[pointing-1],format='(f30.8)')]
    if(keyword_set(yanny_par(outhdr, 'decCen')) eq 0) then $
      outhdr=[outhdr, 'decCen ' + string(deccen[pointing-1],format='(f30.8)')]
    if(keyword_set(yanny_par(outhdr, 'temp')) eq 0) then $
      outhdr= [outhdr, 'temp ' + string(temp)]
    if(keyword_set(yanny_par(outhdr, 'platedesign_version')) eq 0) then $
      outhdr= [outhdr, 'platedesign_version '+platedesign_version()]


    ;; output file name
    if(plateid ge 10000) then begin
        splog, 'plateid exceeds 10000, which breaks data model'
        stop
        platestr= strtrim(string(plateid),2)
    endif else begin
        platestr= strtrim(string(f='(i4.4)', plateid),2)
    endelse
    
    pointing_post = pointing_name[pointing-1]
    if (pointing_post eq 'A') then pointing_post = ''
    plugmapfile= plate_dir(plateid)+'/plPlugMapP-'+platestr+ $
      pointing_post+'.par' 
    
    ;; for holes that aren't in this pointing, replace values with sky
    ;; values
    thisplug=plug
    inotthis= where(holes.pointing ne pointing AND $
                    holes.pointing ne 0L, nnotthis)
    if(nnotthis gt 0L) then begin
        thisplug[inotthis].objtype= 'SKY'
        thisplug[inotthis].mag= 25.
        thisplug[inotthis].primtarget= 0
        thisplug[inotthis].sectarget= 16
    endif

    ;; Now set ACTUAL RA and Dec (for the non-offset position anyway)
    plate_xy2ad, definition, default, pointing, 0L, thisplug.xfocal, $
      thisplug.yfocal, holes.lambda_eff, ra=ra, dec=dec, $
      lst=racen[pointing-1]+ha[pointing-1], airtemp= temp
    thisplug.ra= ra
    thisplug.dec= dec
    
    pdata= ptr_new(thisplug)
    yanny_write, plugmapfile, pdata, hdr=outhdr, $
      enums=plugenum, structs=plugstruct
    ptr_free, pdata
endfor

plain_plug_map_name = plate_dir(plateid)+'/plPlugMapP-'+platestr+'.par'
if (~file_test(plain_plug_map_name)) then begin
	file_link, 'plPlugMapP-'+platestr+ pointing_post+'.par', $
      plain_plug_map_name
endif

end
;------------------------------------------------------------------------------
