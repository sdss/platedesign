;+
; NAME:
;   plugfile_plplugmap_apogee_boss
; PURPOSE:
;   Create a plug file in the style of plPlugMapP files for APOGEE/BOSS
; CALLING SEQUENCE:
;   plugfile_plplugmap_apogee_boss, hdr, holes
; INPUTS:
;   hdr - header from plateHoles file
;   holes - [N] holes from plateHoles file
; REVISION HISTORY:
;   10-Jun-2008  MRB, NYU
;    1-Sep-2010  Demitri Muna, NYU, Adding file test before opening files.
;   04-Oct-2012  MRB, NYU, alterations for MaNGA
;   15-May-2015  Demitri Muna, Adding support for plate IDs > 9999
;   17-Dec-2019  MRB, NYU, alterations for APOGEE/BOSS
;-
pro plugfile_plplugmap_apogee_boss, plateid, keepoldcoords=keepoldcoords

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

racen=dblarr(npointings)
deccen=dblarr(npointings)
for pointing=1L, npointings do begin
    plate_center, definition, default, pointing, 0L, $
                  racen=tmp_racen, deccen=tmp_deccen
    racen[pointing-1L]=tmp_racen
    deccen[pointing-1L]=tmp_deccen
endfor

plug0= plplugmap_blank(enums=plugenum, struct=plugstruct)
plug= replicate(plug0, n_elements(holes))

;; set holetype

plug.sectarget= 0

;; science holes (catch all)
ihole= where(strupcase(holes.targettype) ne 'NA', nhole)
if(nhole gt 0) then begin
    plug[ihole].holetype= 'OBJECT'
    plug[ihole].objtype= 'STAR_BHB'
endif

;; skies
ihole= where(strmatch(strupcase(holes.targettype), 'SKY*'), nhole)
if(nhole gt 0) then begin
   plug[ihole].holetype= 'OBJECT'
   plug[ihole].objtype= 'SKY'
   plug[ihole].sectarget= 16
   plug[ihole].mag= 25.
endif

;; standards
ihole= where(strmatch(strupcase(holes.targettype), 'STANDARD*'), nhole)
if(nhole gt 0) then begin
   plug[ihole].holetype= 'OBJECT'
   plug[ihole].objtype= 'SPECTROPHOTO_STD'
   plug[ihole].sectarget= 32
endif

;; holetype GUIDE in holes -> 
;; holetype GUIDE in plPlugMap
ihole= where(strupcase(holes.holetype) eq 'GUIDE', nhole)
if(nhole gt 0) then plug[ihole].holetype= 'GUIDE'
if(nhole gt 0) then plug[ihole].sectarget= 64

;; holetype ALIGNMENT in holes -> 
;; holetype ALIGNMENT in plPlugMap
ihole= where(strupcase(holes.holetype) eq 'ALIGNMENT', nhole)
if(nhole gt 0) then plug[ihole].holetype= 'ALIGNMENT'

ihole= where(holes.holetype eq 'BOSS_APOGEE', nhole)
if(nhole gt 0) then plug[ihole].holetype= 'OBJECT'
if(nhole gt 0) then plug[ihole].objtype= 'QSO'

ihole= where(holes.holetype eq 'BOSS_APOGEE' and $
             strupcase(holes.targettype) eq 'STANDARD', nhole)
if(nhole gt 0) then plug[ihole].objtype= 'SPECTROPHOTO_STD'
if(nhole gt 0) then plug[ihole].sectarget= 32

ihole= where(holes.holetype eq 'BOSS_APOGEE' and $
             strupcase(holes.targettype) eq 'SKY', nhole)
if(nhole gt 0) then plug[ihole].objtype= 'SKY'
if(nhole gt 0) then plug[ihole].sectarget= 16
if(nhole gt 0) then plug[ihole].mag= 25.

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

;; guess optical mags from 2MASS
itmass= where(holes.tmass_j gt 0, ntmass)
if(ntmass gt 0) then $
   plug[itmass].mag=plate_tmass_to_sdss(holes[itmass].tmass_j, $
                                        holes[itmass].tmass_h, $
                                        holes[itmass].tmass_k)

magtype= 'FIBER2MAG'
itag= tag_indx(holes[0], magtype)
if(itag eq -1) then $
  message, 'No tag '+magtype+' in holes structure.'
isdss= where(holes.run ne 0, nsdss)
if(strmatch(strupcase(magtype), '*FLUX')) then begin
   if(nsdss gt 0) then $
      plug[isdss].mag= 22.5-2.5*alog10(holes[isdss].(itag) > 0.1)
endif else if (strmatch(strupcase(magtype), '*MAG')) then begin
   if(nsdss gt 0) then $
      plug[isdss].mag= holes[isdss].(itag) 
endif else begin
    message, 'MAGTYPE must match either *MAG or *FLUX'
endelse

;; We will ignore these likelihood columns
plug.starl=0.
plug.expl=0.
plug.devaucl=0.

;; xfocal and yfocal
plug.xfocal=holes.xfocal
plug.yfocal=holes.yfocal

;; spectrographid, throughput not set
plug.spectrographid= 0
plug.throughput= 0

isdss= where(holes.run ne 0, nsdss)
if(nsdss gt 0) then begin
   plug[isdss].objid[0]= holes[isdss].run
   plug[isdss].objid[2]= holes[isdss].camcol
   plug[isdss].objid[3]= holes[isdss].field
   plug[isdss].objid[4]= holes[isdss].id
   rerun_values = strtrim(holes[isdss].rerun, 2) ; 2 = trim both ends
   inotblank = where(rerun_values ne '', nnotblank)
   if(nnotblank gt 0) then $
      plug[isdss[inotblank]].objid[1]= long(holes[isdss[inotblank]].rerun)
endif

;; spectrographid, throughput, primtarget not set
iapogee=where(strupcase(holes.holetype) eq 'APOGEE_BOSS', napogee)
if(napogee gt 0) then begin
   plug[iapogee].primtarget= holes[iapogee].apogee2_target1
   plug[iapogee].sectarget= plug[iapogee].sectarget OR $
                            holes[iapogee].apogee2_target2
endif

iboss=where(strupcase(holes.holetype) eq 'BOSS_APOGEE', nboss)
if(nboss gt 0) then begin
   plug[iboss].primtarget= holes[iboss].boss_target1
   plug[iboss].sectarget= plug[iboss].sectarget OR $
                          holes[iboss].boss_target2
endif

;; fiber ID gets set to NEGATIVE of intended value
;; (unless it is -9999)
plug.fiberid=-9999
ihole=where(holes.fiberid ge 1, nhole)

;; Reassign fiberid to space nicely.
if(nhole gt 0) then $
  plug[ihole].fiberid= -holes[ihole].fiberid

;; but guide fibers get fiberid set too
;; this assumes guides are SDSS
ihole=where(holes.iguide ge 1, nhole)
plug[ihole].fiberid= holes[ihole].iguide

;; Compute the median reddening for objects on this plate
;; (just for first pointing)
indx = where(strtrim(plug.holetype,2) EQ 'OBJECT' AND $
             holes.pointing eq 1, nobj)
if(nobj gt 0) then begin
    euler, plug[indx].ra, plug[indx].dec, ll, bb, 1
    ;reddenvec = [5.155, 3.793, 2.751, 2.086, 1.479] $
	reddenvec = reddening() $
      * median(dust_getval(ll, bb, /interp))
endif else begin
   euler, racen[0], deccen[0], ll, bb, 1
   ;reddenvec = [5.155, 3.793, 2.751, 2.086, 1.479] $
   reddenvec = reddening() $
               * (dust_getval(ll, bb, /interp))
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

ihole= where(holes.holetype eq 'BOSS_APOGEE', nhole)
if(nhole gt 0) then begin
    isort= sort(abs(plug[ihole].fiberid))
    newplug=[newplug, plug[ihole[isort]]]
    newholes=[newholes, holes[ihole[isort]]]
endif

ihole= where(holes.holetype eq 'APOGEE_BOSS', nhole)
if(nhole gt 0) then begin
    isort= sort(abs(plug[ihole].fiberid))
    newplug=[newplug, plug[ihole[isort]]]
    newholes=[newholes, holes[ihole[isort]]]
endif

ihole= where(plug.holetype eq 'QUALITY', nhole)
if(nhole gt 0) then begin
    newplug=[newplug, plug[ihole]]
    newholes=[newholes, holes[ihole]]
endif

if(n_elements(newplug) ne n_elements(plug)) then $
  message, 'Sorted plug structure messed up!'

plug=newplug
holes=newholes

sortedplatefile= platedir+'/'+plateholes_filename(plateid=plateid, /sorted)
pdata= ptr_new(holes)
yanny_write, sortedplatefile, pdata, hdr=hdr
ptr_free, pdata

;; Make plPlugMapH and plPlugMapP files
pointing_post=['', 'B', 'C', 'D', 'E', 'F']
pointing_name=['A', 'B', 'C', 'D', 'E', 'F']
for pointing=1L, npointings do begin

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

	plugmapfile_p = plate_dir(plateid) + '/' + $
			plugmap_filename(plateID=plateid, type='P')

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
    if(NOT keyword_set(keepoldcoords)) then begin
        plate_xy2ad, definition, default, pointing, 0L, thisplug.xfocal, $
          thisplug.yfocal, holes.lambda_eff, ra=ra, dec=dec, $
          lst=racen[pointing-1]+ha[pointing-1], airtemp= temp, $
          zoffset=holes.zoffset
        thisplug.ra= ra
        thisplug.dec= dec
    endif
    
    ;; write out the plPlugMapH file for plate
    pdata=ptr_new(thisplug)
    yanny_write, plugmapfile_p, pdata, hdr=outhdr, $
      enums=plugenum, structs=plugstruct
    ptr_free, pdata
    
endfor


end
;------------------------------------------------------------------------------
