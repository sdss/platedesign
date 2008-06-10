;+
; NAME:
;   plugfile_plplugmap
; PURPOSE:
;   Create a plug file in the style of plPlugMapP files from SDSS-II
; CALLING SEQUENCE:
;   plugfile_plplugmap, definition, default, holes
; INPUTS:
;   definition - plate definition structure
;   default - plate default structure
;   holes - [N] holes
; BUGS:
;   CLASSIFIES ALL SOURCES AS STARS!!
; REVISION HISTORY:
;   10-Jun-2008  MRB, NYU
;-
pro plugfile_plplugmap, definition, default, holes

plug0= plplugmap_blank(enums=enums)
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
if(nhole gt 0) then $
  plug[ihole].fiberid= -holes[ihole].fiberid

;; but guide fibers get fiberid set too
ihole=where(holes.iguide ge 1, nhole)
plug[ihole].fiberid= holes[ihole].fiberid

;; Compute the median reddening for objects on this plate
;; (just for first pointing)
indx = where(strtrim(plug.holetype,2) EQ 'OBJECT' AND $
             holes.pointing eq 1, nobj)
euler, plug[indx].ra, plug[indx].dec, ll, bb, 1
reddenvec = [5.155, 3.793, 2.751, 2.086, 1.479] $
  * median(dust_getval(ll, bb, /interp))

;; resort fibers
sortstring = plug.holetype
sortstring = repstr(sortstring, 'LIGHT_TRAP', 'AAA')
sortstring = repstr(sortstring, 'GUIDE', 'BBB')
sortstring = repstr(sortstring, 'ALIGNMENT', 'BBB')
sortstring = repstr(sortstring, 'OBJECT', 'CCC')
sortstring = repstr(sortstring, 'QUALITY', 'DDD')
plug = plug[sort(sortstring)]

outhdr = ['completeTileVersion   v0', $
          'reddeningMed ' + string(reddenvec,format='(5f8.4)'), $
          'tileId ' + string(tilenum), $
          'raCen ' + string(racen,format='(f10.6)'), $
          'decCen ' + string(deccen,format='(f10.6)'), $
          'plateVersion v0', $
          'plateId ' + string(platenum), $
          'temp ' + string(airtemp), $
          'haMin ' + string(lst-racen), $
          'haMax ' + string(lst-racen), $
          'mjdDesign ' + string(long(current_mjd())), $
          'theta 0 ' ]
yanny_write, plugmappfile, ptr_new(allplug), hdr=outhdr, $
  enums=plugenum, structs=plugstruct

;;----------
;; Create the file "plPlan.par" in the current directory.

cd, current=thisdir
cd, thisdir
plhdr = '# Created on ' + systime()
plhdr = [plhdr, "parametersDir " + paramdir]
plhdr = [plhdr, "parameters    " + "plParam.par"]
plhdr = [plhdr, "plObsFile     " + "plObs.par"]
plhdr = [plhdr, "outFileDir    " + thisdir]
plhdr = [plhdr, "tileDir       " + thisdir]
yanny_write, 'plPlan.par', hdr=plhdr

;;----------
;; Create the file "plObs.par" in the current directory.

plhdr = '# Created on ' + systime()
plhdr = [plhdr, "plateRun special"]
plstructs = ["typedef struct {", $
             "   int plateId;", $
             "   int tileId;", $
             "   float temp;", $
             "   float haMin;", $
             "   float haMax;", $
             "   int mjdDesign", $
             "} PLOBS;"]
plobs = create_struct(name='PLOBS', $
                      'PLATEID'  , platenum, $
                      'TILEID'   , tilenum, $
                      'TEMP'     , airtemp, $
                      'HAMIN'    , (lst-racen), $
                      'HAMAX'    , (lst-racen), $
                      'MJDDESIGN', current_mjd())
yanny_write, 'plObs.par', ptr_new(plobs), hdr=plhdr, structs=plstructs

end
;------------------------------------------------------------------------------
