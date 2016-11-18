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
;   - if SOURCE_ID>0 then set MAG = G_MAG for all bands
;   If none of these things are true, then that object has the 
;   mag set to 25 in all bands.
; REVISION HISTORY:
;   25-Aug-2009  MRB, NYU
;-
function plate_mag, holes, default=default

mag= fltarr(5, n_elements(holes))+25.
type= strarr(n_elements(holes))

igaia = where(holes.source_id ne 0, ngaia)
if(ngaia gt 0) then begin
   for i = 0L, 4L do $
      mag[i,igaia] = holes[igaia].phot_g_mean_mag
endif

;; first assign JHK-based mags where possible
;; (these will be overridden if ANYTHING better)
itmass= where(holes.tmass_j gt 0, ntmass)
if(ntmass gt 0) then begin
    mag[*,itmass]= plate_tmass_to_sdss(holes[itmass].tmass_j, $
                                     holes[itmass].tmass_h, $
                                     holes[itmass].tmass_k)
    type[itmass]='2MASS'
 endif

;; second, if USNOB and 2MASS values are set, offset from g
iusnob= where(holes.usnob_mag[2] gt 0 and $
              holes.usnob_mag[2] lt 25. and $
              holes.tmass_j gt 0., nusnob)
if(nusnob gt 0) then begin
   glactc, holes[iusnob].target_ra, holes[iusnob].target_dec, 2000., gl, gb, 1, /deg
   ebv= dust_getval(gl, gb, /noloop)
   jmag= (holes[iusnob].tmass_j - ebv*0.902) 
   hmag= (holes[iusnob].tmass_h - ebv*0.576)
   kmag= (holes[iusnob].tmass_k - ebv*0.367)
   jkcolor= jmag-kmag
   tmp_mag= plate_tmass_to_sdss(jmag, hmag, kmag)
   ;red_fac = [5.155, 3.793, 2.751, 2.086, 1.479 ]
   red_fac = reddening()
   tmp_mag= tmp_mag+ red_fac#ebv

   goffset= holes[iusnob].usnob_mag[2]-tmp_mag[1,*] 
   roffset= holes[iusnob].usnob_mag[3]-tmp_mag[2,*] 
   ioffset= holes[iusnob].usnob_mag[4]-tmp_mag[3,*] 

   offset = goffset 

   ;; for holes designed for blue, offset to g
   iblue = where(holes[iusnob].lambda_eff lt 6000., nblue)
   if(nblue gt 0) then begin
       offset[iblue] = goffset[iblue]
   endif
   
   ;; for holes designed for red, offset to i
   ;; (N) or from r-band equivalent (F) if N is bad
   ired = where(holes[iusnob].lambda_eff ge 6000., nred)
   if(nred gt 0) then begin
       offset[ired] = ioffset[ired]
       ibad = where(holes[iusnob[ired]].usnob_mag[4] eq 0. and $
                    holes[iusnob[ired]].usnob_mag[3] gt 0., nbad)
       if(nbad gt 0) then $
         offset[ired[ibad]] = roffset[ired[ibad]]
   endif

   ;; apply offsets
   for i=0L, 4L do $
     mag[i,iusnob]= tmp_mag[i,*]+offset
   type[iusnob]='USNOB'
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
