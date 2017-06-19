;+
; NAME:
;   plugfile_plplugmap_apogee
; PURPOSE:
;   Create a plug file in the style of plPlugMapP files from APOGEE
; CALLING SEQUENCE:
;   plugfile_plplugmap_apogee, plateid
; INPUTS:
;   hdr - header from plateHoles file
;   holes - [N] holes from plateHoles file
; REVISION HISTORY:
;   10-Jun-2008  MRB, NYU
;    1-Sep-2010  Demitri Muna, NYU, Adding file test before opening files.
;   15-May-2015  Demitri Muna, Adding support for plate IDs > 9999
;-
pro plugfile_plplugmap_apogee, plateid

makesimple=0

platedir= plate_dir(plateid)
platefile= platedir+'/'+plateholes_filename(plateid=plateid)
check_file_exists, platefile, plateid=plateid
holes= yanny_readone(platefile, hdr=hdr, /anon)

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

;; holetype ACQUISITION_CENTER in holes -> 
;; holetype ACQUISITION_CENTER in plPlugMap
ihole= where(strupcase(holes.holetype) eq 'ACQUISITION_CENTER', nhole)
if(nhole gt 0) then plug[ihole].holetype= 'ACQUISITION_CENTER'

;; holetype ACQUISITION_OFFAXIS in holes -> 
;; holetype ACQUISITION_OFFAXIS in plPlugMap
ihole= where(strupcase(holes.holetype) eq 'ACQUISITION_OFFAXIS', nhole)
if(nhole gt 0) then plug[ihole].holetype= 'ACQUISITION_OFFAXIS'

plug.ra= holes.target_ra
plug.dec= holes.target_dec

;; guess optical mags from 2MASS
itmass= where(holes.tmass_j gt 0, ntmass)
if(ntmass gt 0) then $
   plug[itmass].mag=plate_tmass_to_sdss(holes[itmass].tmass_j, $
                                        holes[itmass].tmass_h, $
                                        holes[itmass].tmass_k)

;; We will ignore these likelihood columns
plug.starl=0.
plug.expl=0.
plug.devaucl=0.

;; set objtype and holetype for science
ihole= where(strmatch(strupcase(holes.targettype), 'SCIENCE*'), nhole)
if(nhole gt 0) then begin
   plug[ihole].holetype= 'OBJECT'
   ;; logic here could translate APOGEE sourcetype
   plug[ihole].objtype= 'STAR_BHB'
endif

;; set objtype and holetype for standard
ihole= where(strmatch(strupcase(holes.targettype), 'STANDARD*'), nhole)
if(nhole gt 0) then begin
   plug[ihole].holetype= 'OBJECT'
   ;; logic here could translate APOGEE sourcetype
   plug[ihole].objtype= 'SPECTROPHOTO_STD'
   plug[ihole].sectarget= 32
endif

ihole= where(strupcase(holes.targettype) eq 'SKY', nhole)
if(nhole gt 0) then begin
   plug[ihole].holetype= 'OBJECT'
   plug[ihole].objtype= 'SKY'
   plug[ihole].sectarget= 16
endif

;; xfocal and yfocal
plug.xfocal=holes.xfocal
plug.yfocal=holes.yfocal

;; spectrographid, throughput, primtarget not set
plug.spectrographid= 0
plug.throughput= 0
plug.primtarget= holes.apogee2_target1
plug.sectarget= plug.sectarget OR holes.apogee2_target2

;; no SDSS ID
plug.objid[0]= 0
plug.objid[1]= 0
plug.objid[2]= 0
plug.objid[3]= 0
plug.objid[4]= 0

;; fiber ID gets set to NEGATIVE of intended value
;; (unless it is -9999)
plug.fiberid=-9999
ihole=where(holes.fiberid ge 1, nhole)
if(nhole gt 0) then $
  plug[ihole].fiberid= -holes[ihole].fiberid

;; guide fibers get fiberid set too
ihole=where(holes.iguide ge 1, nhole)
plug[ihole].fiberid= holes[ihole].iguide

;; resort fibers
ihole= where(plug.holetype eq 'LIGHT_TRAP', nhole)
if(nhole gt 0) then begin
    newplug= plug[ihole]
    newholes= holes[ihole]
endif

ihole= where(plug.holetype eq 'GUIDE' OR $
             plug.holetype eq 'ALIGNMENT', nhole)
if(nhole gt 0) then begin
    sortstr= string(plug[ihole].fiberid, f='(i3.3)')+ $
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
        newplug= plug[ihole[isort]]
        newholes= holes[ihole[isort]]
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

ihole= where(strmatch(plug.holetype, 'ACQUISITION_*'), nhole)
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

sortedplatefile= platedir+'/'+plateholes_filename(plateid=plateid, /sorted)
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

;; Compute the median reddening for objects on this plate
;; (just for first pointing). If there are no science objects
;; just use center of the plate. 
indx = where(strtrim(plug.holetype,2) EQ 'OBJECT' AND $
             holes.pointing eq 1, nobj)
if(nobj gt 0) then $
  euler, plug[indx].ra, plug[indx].dec, ll, bb, 1 $
else $
  euler, racen[0], deccen[0], ll, bb, 1
reddenvec = reddening() $
  * median([dust_getval(ll, bb, /interp)]) 

pointing_name = strsplit(definition.pointing_name, /extract)
for pointing=1L, npointings do begin
   pointing_post = pointing_name[pointing-1]
   if (pointing_post eq 'A') then pointing_post = ''

   ;; add header keywords
   inotradec= where(strmatch(hdr, 'racen *', /fold_case) eq 0 AND $
                    strmatch(hdr, 'deccen *', /fold_case) eq 0, nnotradec)
   khdr= hdr[inotradec]
   outhdr = ['completeTileVersion   none', $
             'mjdDesign ' + string(long(current_mjd())), $
             'pointing ' + pointing_name[pointing-1], $
             'mag_quality bad',  $
             khdr]
   if(keyword_set(yanny_par(outhdr, 'reddeningMed')) eq 0) then $
      outhdr=[outhdr, 'reddeningMed ' + string(reddenvec,format='(5f8.4)')]
   if(keyword_set(yanny_par(outhdr, 'haMin')) eq 0) then $
      outhdr=[outhdr, 'haMin ' + strtrim(string(ha[pointing-1], $
                                                format='(f40.4)'),2)]
   if(keyword_set(yanny_par(outhdr, 'haMax')) eq 0) then $
      outhdr=[outhdr, 'haMax ' + strtrim(string(ha[pointing-1], $
                                                format='(f40.4)'),2)]
   if(keyword_set(yanny_par(outhdr, 'theta')) eq 0) then $
      outhdr=[outhdr, 'theta 0']
   if(keyword_set(yanny_par(outhdr, 'plateId')) eq 0) then $
      outhdr=[outhdr, 'plateId ' + strtrim(string(plateid),2)]
   if(keyword_set(yanny_par(outhdr, 'raCen')) eq 0) then $
      outhdr=[outhdr, 'raCen ' + string(racen[pointing-1],format='(f30.8)')]
   if(keyword_set(yanny_par(outhdr, 'decCen')) eq 0) then $
      outhdr=[outhdr, 'decCen ' + string(deccen[pointing-1],format='(f30.8)')]
   if(keyword_set(yanny_par(outhdr, 'temp')) eq 0) then $
      outhdr= ['temp ' + string(temp)]
   if(keyword_set(yanny_par(outhdr, 'platedesign_version')) eq 0) then $
      outhdr= [outhdr, 'platedesign_version '+platedesign_version()]
   
   ;; output file name
   ;if(plateid ge 10000) then begin
   ;   splog, 'plateid exceeds 10000, which breaks data model'
   ;   stop
   ;   platestr= strtrim(string(plateid),2)
   ;endif else begin
   ;   platestr= strtrim(string(f='(i4.4)', plateid),2)
   ;endelse
   ;plugmapfile= plate_dir(plateid)+'/plPlugMapP-'+platestr+ $
   ;             pointing_post+'.par' 
   plugmapfile = plate_dir(plateid) + '/' + $
   		plugmap_filename(plateID=plateid, type='P', pointing=pointing_post)

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
     lst=racen[pointing-1]+ha[pointing-1], airtemp= temp, $
     zoffset=holes.zoffset
   thisplug.ra= ra
   thisplug.dec= dec

   ibadmag= where(finite(thisplug.mag) eq 0, nbadmag)
   if(nbadmag gt 0) then $
     message, 'Infinite or NaN magnitude values in plugmap.'
   
   ;; write out the plPlugMapP file for plate
   pdata=ptr_new(thisplug)
   yanny_write, plugmapfile, pdata, hdr=outhdr, $
     enums=plugenum, structs=plugstruct
   ptr_free, pdata
   
   ;; now make simple plugging file
   if(keyword_set(makesimple)) then begin
      plugsimplefile= plate_dir(plateid)+'/plugMap-'+platestr+ $
                      pointing_post+'.par' 
      plugsimple0= plugmap_blank(enums=plugenum, struct=plugstruct)
      plugsimple= replicate(plugsimple0, n_elements(thisplug))
      struct_assign, thisplug, plugsimple
      plugsimple.sourcetype= holes.sourcetype
      plugsimple[inotthis].sourcetype= 'SKY'
      pdata=ptr_new(plugsimple)
      yanny_write, plugsimplefile, pdata, hdr=outhdr, $
                   enums=plugenum, structs=plugstruct
      ptr_free, pdata
   endif
   
endfor

end
;------------------------------------------------------------------------------
