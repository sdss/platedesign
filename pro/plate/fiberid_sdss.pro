;+
; NAME:
;   fiberid_sdss
; PURPOSE:
;   assign fiberid's to a list of SDSS targets
; CALLING SEQUENCE:
;   fiberid= fiberid_sdss(design)
; INPUTS:
;   design - [640] struct array of targets, in design_blank() form
;            Required tags are .XF_DEFAULT, .YF_DEFAULT
; OPTIONAL INPUTS:
;   minstdinblock, minskyinblock 
;          - minimum number of standards or skies to assign to each block
;            [default 0]
; OPTIONAL OUTPUTS:
;   block - [N] block for each fiber
; OPTIONAL KEYWORDS:
;   /nosky - do not attempt to assign any of the sky fibers
;   /nostd - do not attempt to assign any of the standard fibers
;   /noscience - do not attempt to assign any of the science fibers
; OUTPUTS:
;   fiberid - 1-indexed list of fibers 
; COMMENTS:
;   Uses sdss_plugprob to solve the plugging problem.
;   First, assigns standards, guaranteeing at least one per block
;   Second, assigns skies, guaranteeing at least one per block
;   Finally, assigns all others, guaranteeing at least one per block
; REVISION HISTORY:
;   4-Jun-2008 MRB, NYU 
;-
function fiberid_sdss, default, fibercount, design, $
                       minstdinblock=minstdinblock, $
                       minskyinblock=minskyinblock, $
                       nosky=nosky, nostd=nostd, noscience=noscience, $
                       quiet=quiet, block=block

limitdegree=7.*0.1164 ;; limit of fiber reach
skylimitdegree= limitdegree ;; do not stretch as far for skies
stdlimitdegree= limitdegree ;; ... and standards

if(NOT keyword_set(minstdinblock)) then minstdinblock=0L
if(NOT keyword_set(minskyinblock)) then minskyinblock=0L

fiberused=0L
fiberid=lonarr(n_elements(design))
npointings= long(default.npointings)
noffsets= long(default.noffsets)

if(NOT keyword_set(nostd)) then begin
    ;; assign standards, if any exist
    ;; ask for minstdinblock in each block for each pointing, at least
    for ip=1L, npointings do begin
        for io=0L, noffsets do begin
            istd= where(strupcase(design.targettype) eq 'STANDARD' AND $
                        design.pointing eq ip and design.offset eq io, nstd)
            if(nstd gt 0) then begin
                iinst=where(strupcase(fibercount.instruments) eq $
                            'SDSS', ninst)
                itype=where(strupcase(fibercount.targettypes) eq $
                            'STANDARD', ntype)
                nmax=long(total(fibercount.ntot[iinst, itype, ip-1L, io]))
                
                sdss_plugprob, design[istd].xf_default, $
                               design[istd].yf_default, $
                               tmp_fiberid, mininblock=minstdinblock, $
                               minavail=1L, fiberused=fiberused, nmax=nmax, $
                               limitdegree=stdlimitdegree, /quiet
                
                iassigned=where(tmp_fiberid ge 1, nassigned)
                help, nassigned, nmax
                if(nassigned gt 0) then begin
                    if(NOT keyword_set(fiberused)) then $
                      fiberused=tmp_fiberid[iassigned] $
                    else $
                      fiberused=[fiberused, tmp_fiberid[iassigned]] 
                    fiberid[istd[iassigned]]=tmp_fiberid[iassigned]
                endif 
            endif else begin
                if(NOT keyword_set(quiet)) then $
                  splog, 'No standards in pointing '+strtrim(string(ip),2)+ $
                         ' / offset '+strtrim(string(io),2)
            endelse
        endfor
    endfor
endif

if(NOT keyword_set(nosky)) then begin
    ;; assign skies, if any exist
    ;; ask for minskyinblock in each block for each pointing, at least
    for ip=1L, npointings do begin
        for io=0L, noffsets do begin
            isky= where(strupcase(design.targettype) eq 'SKY' AND $
                        design.pointing eq ip and design.offset eq io, nsky)
            if(nsky gt 0) then begin
                iinst=where(strupcase(fibercount.instruments) eq 'SDSS', ninst)
                itype=where(strupcase(fibercount.targettypes) eq 'SKY', ntype)
                nmax=long(total(fibercount.ntot[iinst, itype, ip-1L, io]))
                
                sdss_plugprob, design[isky].xf_default, $
                               design[isky].yf_default, $
                               tmp_fiberid, mininblock=minskyinblock, $
                               minavail=1L, fiberused=fiberused, nmax=nmax, $
                               limitdegree=skylimitdegree, /quiet

                iassigned=where(tmp_fiberid ge 1, nassigned)
                help, nassigned, nmax
                if(nassigned gt 0) then begin
                    if(NOT keyword_set(fiberused)) then $
                      fiberused=tmp_fiberid[iassigned] $
                    else $
                      fiberused=[fiberused, tmp_fiberid[iassigned]] 
                    fiberid[isky[iassigned]]=tmp_fiberid[iassigned]
                endif 
            endif else begin
                if(NOT keyword_set(quiet)) then $
                  splog, 'No skies in pointing '+strtrim(string(ip),2)+ $
                         ' / offset '+strtrim(string(io),2)
            endelse
        endfor
    endfor
endif

if(NOT keyword_set(noscience)) then begin
    ;; assign the rest
    ileft= where(strupcase(design.targettype) ne 'SKY' AND $
                 strupcase(design.targettype) ne 'STANDARD', nleft)
    if(nleft gt 0) then begin
        sdss_plugprob, design[ileft].xf_default, design[ileft].yf_default, $
          tmp_fiberid, fiberused=fiberused, $
          limitdegree=limitdegree
        
        iassigned=where(tmp_fiberid ge 1, nassigned)
        help, nassigned
        if(nassigned gt 0) then begin
            if(NOT keyword_set(fiberused)) then $
              fiberused=tmp_fiberid[iassigned] $
            else $
              fiberused=[fiberused, tmp_fiberid[iassigned]] 
            fiberid[ileft[iassigned]]=tmp_fiberid[iassigned]
        endif 
    endif else begin
        if(NOT keyword_set(quiet)) then $
          splog, 'No science targets in this plate.'
    endelse
endif

block= lonarr(n_elements(fiberid))-9999L
igood= where(fiberid ge 1, ngood)
if(ngood gt 0) then begin
    block[igood]= (fiberid[igood]-1L)/20L+1L
endif
    
return, fiberid

end

