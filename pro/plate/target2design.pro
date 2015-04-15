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
;   Writes in XF_DEFAULT, YF_DEFAULT, which are the positions to
;     assume for the sake of collisions. They are zero-hour angle, 5C
;     epoch 2011. results. (Actually, the epoch is whatever is
;     returned by default_epoch())
; REVISION HISTORY:
;   8-May-2008  Written by MRB, NYU
;	12-July-2011  Colorized error messages, Demitri Muna, NYU
;-
pro target2design, definition, default, targets, design, info=info

;; which pointing are we adding these targets to?
pointing= 1L
if(tag_exist(info, 'pointing')) then $
  pointing=long(info.pointing)
if(pointing gt long(default.npointings)) then $
  message, color_string('Requesting pointing '+strtrim(string(pointing),2)+ $
  			' when the design specifies ' + strtrim(string(default.npointings),2) + ' pointing(s)!', 'red', 'bold')

;; which offset are we adding these targets to?
offset= 0L
if(tag_exist(info, 'offset')) then $
  offset=long(info.offset)
if(offset gt long(default.noffsets)) then $
  message, color_string('pointing '+strtrim(string(pointing),2)+' does not exist', 'yellow', 'normal')

if(tag_exist(info, 'racen') gt 0 OR $
   tag_exist(info, 'deccen') gt 0) then begin
    if(tag_exist(info, 'racen') gt 0 AND $
       tag_exist(info, 'deccen') gt 0) then begin
        racen= double((strsplit(definition.racen,/extr)))
        deccen= double((strsplit(definition.deccen,/extr)))
        if(abs(racen[pointing-1]-double(info.racen)) gt 1./3600. OR $
           abs(deccen[pointing-1]-double(info.deccen)) gt 1./3600.) then begin
            message, color_string('plateInput file has raCen, decCen inconsistent with its pointing; aborting!', 'red', 'bold')
        endif
    endif else begin
        message, color_string('Suspicious: racen OR deccen is set in plateInput file, but not BOTH; aborting!', 'red', 'bold')
    endelse
endif

;; Use PMRA, PMDEC, EPOCH if they exist
if(tag_exist(targets, 'PMRA') ne tag_exist(targets, 'PMDEC')) then $
  message, color_string('Must have both PMRA and PMDEC or neither in input target list!', 'yellow', 'normal')
if(tag_exist(targets, 'PMRA') gt 0 AND $
   tag_exist(targets, 'EPOCH') eq 0) then $
  message, color_string('If PMRA and PMDEC are set, EPOCH must be set as well! Please update the input file listed immediate above this line.', 'yellow', 'normal')
if(tag_exist(targets, 'PMRA')) then begin
    pmra= targets.pmra
    pmdec= targets.pmdec
    epoch= targets.epoch
endif else begin
    pmra= fltarr(n_elements(targets))
    pmdec= fltarr(n_elements(targets))
    epoch= replicate(default_epoch(), n_elements(targets))
endelse

;; create structure for targets
ntargets=n_elements(targets)
design= replicate(design_blank(), ntargets)

;; now copy all appropriate tags to design from the target list
struct_assign, targets, design, /nozero

;; Get default xf_default and yf_default
;; (not particular position for this LST and temp)
plate_ad2xy, definition, default, pointing, offset, targets.ra, $
             targets.dec, design.lambda_eff, xfocal=xf_default, $
             yfocal=yf_default

;; add per plateInput data 
instruments=strsplit(default.instruments, /extr)
iinst=where(info.instrument eq instruments, ninst)
if(ninst eq 0) then $
  message, color_string('no instrument '+info.instrument+' in this plate!', 'yellow', 'normal')
design.holetype= info.instrument

targettypes=strsplit(default.targettypes, /extr)
itt=where(strlowcase(info.targettype) eq strlowcase(targettypes), ntt)
if(ntt eq 0) then $
  message, color_string('no targettype '+info.targettype+' in this plate!', 'yellow', 'normal')
design.targettype= strlowcase(info.targettype)

design.pointing=pointing
design.offset=offset

;; get hole size for this type
ferrulesize= get_ferrulesize(definition, default, info.instrument)

;; get hole size for this type
buffersize= get_buffersize(definition, default, info.instrument)

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
