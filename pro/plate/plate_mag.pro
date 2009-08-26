;+
; NAME:
;   plate_mag
; PURPOSE:
;   Return "mag" values to use given a HOLES structure
; CALLING SEQUENCE:
;   mag= plate_mag(holes [, default=, type=] )
; INPUTS:
;   holes - [N] holes from plateHoles file
; OPTIONAL INPUTS:
;   default - structure with defaults to use
; OUTPUTS:
;   mag - [5,N] magnitude to use as fiber mags
; OPTIONAL OUTPUTS:
;   type - [N] string describing what type of magnitude
; COMMENTS:
;   In order of decreasing preference, uses the following:
;   - for TARGETTYPE= "SKY" objects, mag=25
;   - holes."BOSSMAGTYPE" (if the default structure defines
;     "BOSSMAGTYPE"); "BOSSMAGTYPE" must end in "FLUX" or "MAG", as in
;     "FIBER2FLUX" or "FIBER2MAG"; automatically translates any tag
;     that ends in FLUX to magnitudes (type = BOSSMAGTYPE)
;   - if RUN is non-zero, then based on rerun do the following:
;         RERUN<100 - use FIBERMAG  (type = "FIBERMAG")
;         100<=RERUN<300 - translate FIBERFLUX to magnitude 
;                          (type = "FIBERFLUX")
;         RERUN>=300 - translate FIBER2FLUX to magnitude
;                      (type = "FIBER2FLUX")
;   - if GSC_VMAG>0, then assumes TMASS_[JHK], TYC_BMAG are also set
;     (as appropriate for MARVELS targets) translate JHK into
;     approximate uiz values for stars, and g=TYC_MAG, r=GSC_VMAG
;     (type = "MARVELS")
;   - if TMASS_J>0, then assumes TMASS_[HK] also set, and translates
;     these into approximate ugriz for stars (type = "2MASS")
;   If none of these things are true, then that object has the 
;   mag set to 25 in all bands.
; REVISION HISTORY:
;   25-Aug-2009  MRB, NYU
;-
function plate_mag, holes, default=default

mag= fltarr(5, n_elements(holes))+25.
type= strarr(n_elements(holes))

;; first assign JHK-based mags where possible
;; (these will be overridden if ANYTHING better)
itmass= where(holes.tmass_j gt 0, ntmass)
if(ntmass gt 0) then begin
    mag[*,itmass]= plate_tmass_to_sdss(holes[itmass].tmass_j, $
                                     holes[itmass].tmass_h, $
                                     holes[itmass].tmass_k)
    type[itmass]='2MASS'
endif

;; second, if the B,V values from Tycho and GSC are there, use those 
;; (this is for MARVELS-type targets generall)
imarvels= where(holes.gsc_vmag gt 0, nmarvels)
if(nmarvels gt 0) then begin
    mag[*,imarvels]= $
      plate_tmass_to_sdss(holes[imarvels].tmass_j, $
                          holes[imarvels].tmass_h, $
                          holes[imarvels].tmass_k)
    mag[1,imarvels]= holes[imarvels].tyc_bmag
    mag[2,imarvels]= holes[imarvels].gsc_vmag
    type[itmass]='MARVELS'
endif

;; third, if RUN is set, let us ASSUME:
;;     fibermag is set (if rerun<100),
;;  OR fiberflux is set (if 100<=rerun<300)
;;  OR fiber2flux is set (if rerun>=300)
igd= where(strtrim(holes.rerun,2) ne '', ngd)
if(ngd gt 0) then begin
    isdss= where(holes[igd].run gt 0 AND $
                 long(holes[igd].rerun) lt 100, nsdss)
    if(nsdss gt 0) then begin
        mag[*,igd[isdss]]= holes[igd[isdss]].fibermag
        type[igd[isdss]]='FIBERMAG'
    endif
    isdss= where(holes[igd].run gt 0 AND $
                 long(holes[igd].rerun) ge 100 AND $
                 long(holes[igd].rerun) lt 300, nsdss)
    if(nsdss gt 0) then begin
        mag[*,igd[isdss]]= 22.5-2.5*alog10(holes[igd[isdss]].fiberflux > 0.1) 
        type[igd[isdss]]='FIBERFLUX'
    endif
    isdss= where(holes[igd].run gt 0 AND $
                 long(holes[igd].rerun) ge 300, nsdss)
    if(nsdss gt 0) then begin
        mag[*,igd[isdss]]= 22.5-2.5*alog10(holes[igd[isdss]].fiber2flux > 0.1) 
        type[igd[isdss]]='FIBER2FLUX'
    endif
endif

if(keyword_set(default)) then begin

    ;; if BOSSMAGTYPE is set, then use that as override
    ;; on all BOSS instrument targets
    if(tag_indx(default,'BOSSMAGTYPE') ge 0) then begin
        
        magtype=default.bossmagtype
        iboss= where(strupcase(holes.holetype) eq 'BOSS', nboss)
        if(nboss gt 0) then begin
            itag= tag_indx(holes[0], magtype)
            if(itag eq -1) then $
              message, 'No tag '+magtype+' in holes structure.'
            if(strmatch(strupcase(magtype), '*FLUX')) then begin
                mag[*,iboss]= 22.5-2.5*alog10(holes[iboss].(itag) > 0.1)
                type[iboss]= magtype
            endif else if (strmatch(strupcase(magtype), '*MAG')) then begin
                mag[*,iboss]= holes[iboss].(itag) 
                type[iboss]= magtype
            endif else begin
                message, 'MAGTYPE must match either *MAG or *FLUX'
            endelse
        endif
    endif
endif

isky= where(strupcase(holes.targettype) eq 'SKY', nsky)
if(nsky gt 0) then $
  mag[*,isky]=25.

return, mag

end
;------------------------------------------------------------------------------
