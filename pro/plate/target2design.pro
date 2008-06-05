;+
; NAME:
;   target2design
; PURPOSE:
;   Convert target structure to design structure
; CALLING SEQUENCE:
;   target2design, definition, default, targets, design, info=
; INPUTS:
;   definition - plate definition structure
;   default - plate default structure
;   targets - target structure
;   design - design structure
;   info - structure with information tags for various options
; COMMENTS:
;   Designed to be run at first input of plateInput file in plate_drillrun
;   Required in default structure:
;     nPointings
;     nOffsets
;   Required in definition structure:
;     raCen1 [, ... as necessary]
;     decCen1 [, ... as necessary]
;   Defaults to 3 arcsec buffer 
; REVISION HISTORY:
;   8-May-2008  Written by MRB, NYU
;-
pro target2design, definition, default, targets, design, info=info

;; which pointing are we adding these targets to?
pointing= 1L
if(tag_exist(info, 'pointing')) then $
  pointing=long(info.pointing)
if(pointing gt long(default.npointings)) then $
  message, 'pointing '+strtrim(string(pointing),2)+' does not exist'

;; which offset are we adding these targets to?
offset= 0L
if(tag_exist(info, 'offset')) then $
  offset=long(info.offset)
if(offset gt long(default.noffsets)) then $
  message, 'pointing '+strtrim(string(pointing),2)+' does not exist'

;; Get default xf_default and yf_default
;; (not particular position for this LST and temp)
plate_ad2xy, definition, default, pointing, offset, targets.ra, $
             targets.dec, xfocal=xf_default, yfocal=yf_default

;; create structure for targets
ntargets=n_elements(targets)
design= replicate(design_blank(), ntargets)

;; now copy all appropriate tags to design from the target list
struct_assign, targets, design, /nozero

;; add per plateInput data 
instruments=strsplit(default.instruments, /extr)
iinst=where(info.instrument eq instruments, ninst)
if(ninst eq 0) then $
  message, 'no instrument '+info.instrument+' in this plate!'
design.holetype= info.instrument

targettypes=strsplit(default.targettypes, /extr)
itt=where(info.targettype eq targettypes, ntt)
if(ntt eq 0) then $
  message, 'no targettype '+info.targettype+' in this plate!'
design.targettype= info.targettype

design.pointing=pointing
design.offset=offset

;; get hole size for this type
ferrulestr= 'ferruleSize'+strtrim(info.instrument,2)
iferrule= tag_indx(default, ferrulestr)
ferrulesize= float(default.(iferrule))

;; get hole size for this type
bufferstr= 'bufferSize'+strtrim(info.instrument,2)
ibuffer= tag_indx(default, bufferstr)
buffersize= float(default.(ibuffer))

;; add per target data 
design.sourcetype= targets.sourcetype
design.target_ra= targets.ra
design.target_dec= targets.dec
design.xf_default=xf_default
design.yf_default=yf_default
design.diameter=ferrulesize
design.buffer=buffersize 
design.priority=targets.priority
design.assigned=0
design.conflicted=0

return
end
