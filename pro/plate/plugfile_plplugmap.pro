;+
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
;   REASSIGNS FIBER IDs SO RUINS SKY IN BLOCK GUARANTEES
; REVISION HISTORY:
;   10-Jun-2008  MRB, NYU
;-
pro plugfile_plplugmap, hdr, holes

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

;; WHAT ABOUT MAG!!
;;plug.mag= holes.mag

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
sdss_plugprob, plug[ihole].xfocal, plug[ihole].yfocal, fiberid
plug[ihole].fiberid=-fiberid
;;;if(nhole gt 0) then $
;;  plug[ihole].fiberid= -holes[ihole].fiberid

;; but guide fibers get fiberid set too
ihole=where(holes.iguide ge 1, nhole)
plug[ihole].fiberid= holes[ihole].iguide

;; Compute the median reddening for objects on this plate
;; (just for first pointing)
indx = where(strtrim(plug.holetype,2) EQ 'OBJECT' AND $
             holes.pointing eq 1, nobj)
euler, plug[indx].ra, plug[indx].dec, ll, bb, 1
reddenvec = [5.155, 3.793, 2.751, 2.086, 1.479] $
  * median(dust_getval(ll, bb, /interp))

;; resort fibers
ihole= where(plug.holetype eq 'LIGHT_TRAP', nhole)
if(nhole gt 0) then $
  newplug= plug[ihole]

ihole= where(plug.holetype eq 'GUIDE' OR $
             plug.holetype eq 'ALIGNMENT', nhole)
if(nhole gt 0) then begin
    sortstr= string(plug[ihole].fiberid, f='(i2.2)')+ $
      plug[ihole].holetype
    isort=sort(sortstr)
    if(n_tags(newplug) gt 0) then $
      newplug= [newplug, plug[ihole[isort]]] $
    else $
      newplug= plug[ihole[isort]]
endif

ihole= where(plug.holetype eq 'OBJECT', nhole)
if(nhole gt 0) then begin
    isort= sort(abs(plug[ihole].fiberid))
    newplug=[newplug, plug[ihole[isort]]]
endif

ihole= where(plug.holetype eq 'QUALITY', nhole)
if(nhole gt 0) then $
  newplug=[newplug, plug[ihole]]

if(n_elements(newplug) ne n_elements(plug)) then $
  message, 'Sorted plug structure messed up!'

plug=newplug

racen=dblarr(npointings)
deccen=dblarr(npointings)
for pointing=1L, npointings do begin
    plate_center, definition, default, pointing, 0L, $
                  racen=tmp_racen, deccen=tmp_deccen
    racen[pointing-1L]=tmp_racen
    deccen[pointing-1L]=tmp_deccen
endfor

pointing_post=['', 'B', 'C', 'D', 'E', 'F']
pointing_name=['A', 'B', 'C', 'D', 'E', 'F']
for pointing=1L, npointings do begin
    outhdr = ['completeTileVersion   none', $
              'reddeningMed ' + string(reddenvec,format='(5f8.4)'), $
              '# tileId is set to designid for SDSS-III plates', $
              'tileId ' + string(designid), $
              'raCen ' + string(racen[pointing-1],format='(f30.8)'), $
              'decCen ' + string(deccen[pointing-1],format='(f30.8)'), $
              'platedesign_version '+platedesign_version(), $
              'plateId ' + string(plateid)+pointing_post[pointing-1], $
              'temp ' + string(temp), $
              'haMin ' + string(ha[pointing-1]), $
              'haMax ' + string(ha[pointing-1]), $
              'mjdDesign ' + string(long(current_mjd())), $
              'pointing ' + pointing_name[pointing-1], $
              'theta 0 ', $
              hdr]
    platestr= strtrim(string(f='(i4.4)', plateid),2)
    plugmapfile= plate_dir(plateid)+'/plPlugMapP-'+platestr+ $
      pointing_post[pointing-1]+'.par' 

    thisplug=plug
    inotthis= where(thisplug.pointing ne pointing AND $
                    thisplug.pointing ne 0L, nnotthis)
    if(nnotthis gt 0L) then begin
        thisplug[inotthis].objtype= 'SKY'
        thisplug[inotthis].mag= 25.
        thisplug[inotthis].primtarget= 0
        thisplug[inotthis].sectarget= 16
    endif

    yanny_write, plugmapfile, ptr_new(thisplug), hdr=outhdr, $
      enums=plugenum, structs=plugstruct
endfor

end
;------------------------------------------------------------------------------
