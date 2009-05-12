;+
; NAME:
;   fiberid_boss
; PURPOSE:
;   assign fiberid's to a list of BOSS targets
; CALLING SEQUENCE:
;   fiberid= fiberid_boss(design)
; INPUTS:
;   design - [1000] struct array of targets, in design_blank() form
;            Required tags are .XF_DEFAULT, .YF_DEFAULT
; OPTIONAL INPUTS:
;   minstdinblock, minskyinblock, maxskyinblock
;          - min/max number of standards or skies to assign to each block
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
function fiberid_boss, default, fibercount, design, $
  minstdinblock=minstdinblock, $
  minskyinblock=minskyinblock, $
  maxskyinblock=maxskyinblock, $
  nosky=nosky, nostd=nostd, noscience=noscience, $
  quiet=quiet, block=block, $
  respect_fiberid=respect_fiberid

common com_fiberid_boss, fiberblocks

if(keyword_set(respect_fiberid)) then $
  message, 'BOSS spectrograph designs cannot respect fiberid'

platescale = 217.7358           ; mm/degree
limitdegree=7.*0.1164 ;; limit of fiber reach
skylimitdegree= limitdegree ;; stretch just as far for skies
stdlimitdegree= limitdegree ;; ... and standards
nperblock=40L

if(NOT keyword_set(minstdinblock)) then minstdinblock=0L
if(NOT keyword_set(minskyinblock)) then minskyinblock=0L
if(NOT keyword_set(maxskyinblock)) then maxskyinblock=nperblock

fiberused=0L
fiberid=lonarr(n_elements(design))
npointings= long(default.npointings)
noffsets= long(default.noffsets)

;; default centers of blocks
if(n_tags(fiberblocks) eq 0) then $
    fiberblocks= yanny_readone(getenv('PLATEDESIGN_DIR')+ $
                               '/data/boss/fiberBlocksBOSS.par')
nblocks=max(fiberblocks.blockid)
blockcenx= fltarr(nblocks)
blockceny= fltarr(nblocks)
for i=1L, nblocks do begin
    ib= where(fiberblocks.blockid eq i, nb)
    blockcenx[i-1]= mean(fiberblocks[ib].fibercenx)
    blockceny[i-1]= mean(fiberblocks[ib].fiberceny)
endfor

;; first assign science, and reset block centers to follow science
;; fibers; DO NOT SAVE SCIENCE PLUGGING HERE
if(NOT keyword_set(noscience)) then begin
    isci= where(strupcase(design.targettype) ne 'SKY' AND $
                strupcase(design.targettype) ne 'STANDARD', nsci)
    if(nsci gt 0) then begin
        
        ;; assign the fibers 
        sdss_plugprob, design[isci].xf_default, design[isci].yf_default, $
          tmp_fiberid, fiberused=fiberused, limitdegree=limitdegree, $
          maxinblock=nperblock-minstdinblock-minskyinblock
        
        ;; which block is each in
        block= lonarr(n_elements(tmp_fiberid))-1L
        igood= where(tmp_fiberid ge 1, ngood)
        if(ngood gt 0) then begin
            block[igood]= (tmp_fiberid[igood]-1L)/nperblock+1L
            
            ;; now find the center location for each block
            for i=1L, nblocks do begin
                ib= where(block eq i, nb)
                ;;if(nb gt 0) then begin
                    ;;blockcenx[i-1]= mean(design[ib].xf_default)/platescale
                    ;;blockceny[i-1]= mean(design[ib].yf_default)/platescale
                ;;endif 
            endfor
        endif
    endif else begin
        if(NOT keyword_set(quiet)) then $
          splog, 'No science targets in this plate.'
    endelse
endif

if(NOT keyword_set(nostd)) then begin
    ;; assign standards, if any exist
    ;; ask for minstdinblock in each block for each pointing, at least
    for ip=1L, npointings do begin
        for io=0L, noffsets do begin
            istd= where(strupcase(design.targettype) eq 'STANDARD' AND $
                        design.pointing eq ip and design.offset eq io, nstd)
            if(nstd gt 0) then begin
                iinst=where(strupcase(fibercount.instruments) eq $
                            'BOSS', ninst)
                itype=where(strupcase(fibercount.targettypes) eq $
                            'STANDARD', ntype)
                nmax=long(total(fibercount.ntot[iinst, itype, ip-1L, io]))
                
                sdss_plugprob, design[istd].xf_default, $
                  design[istd].yf_default, $
                  tmp_fiberid, mininblock=minstdinblock, $
                  minavail=8L, fiberused=fiberused, nmax=nmax, $
                  limitdegree=stdlimitdegree, $
                  blockcenx=blockcenx, blockceny=blockceny, /quiet
                
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
                iinst=where(strupcase(fibercount.instruments) eq 'BOSS', ninst)
                itype=where(strupcase(fibercount.targettypes) eq 'SKY', ntype)
                nmax=long(total(fibercount.ntot[iinst, itype, ip-1L, io]))
                
                sdss_plugprob, design[isky].xf_default, $
                  design[isky].yf_default, $
                  tmp_fiberid, mininblock=minskyinblock, $
                               maxinblock=maxskyinblock, $
                  minavail=8L, fiberused=fiberused, nmax=nmax, $
                  limitdegree=skylimitdegree, $
                  blockcenx=blockcenx, blockceny=blockceny, /quiet
                
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

;; finally, assign science again
if(NOT keyword_set(noscience)) then begin
    isci= where(strupcase(design.targettype) ne 'SKY' AND $
                strupcase(design.targettype) ne 'STANDARD', nsci)
    if(nsci gt 0) then begin
        
        ;; assign the fibers 
        sdss_plugprob, design[isci].xf_default, design[isci].yf_default, $
          tmp_fiberid, fiberused=fiberused, limitdegree=limitdegree
        
        ;; do store results
        iassigned=where(tmp_fiberid ge 1, nassigned)
        help, nassigned
        if(nassigned gt 0) then begin
            if(NOT keyword_set(fiberused)) then $
              fiberused=tmp_fiberid[iassigned] $
            else $
              fiberused=[fiberused, tmp_fiberid[iassigned]] 
            fiberid[isci[iassigned]]=tmp_fiberid[iassigned]
        endif 
        
    endif else begin
        if(NOT keyword_set(quiet)) then $
          splog, 'No science targets in this plate.'
    endelse
endif

block= lonarr(n_elements(fiberid))-1L
igood= where(fiberid ge 1, ngood)
if(ngood gt 0) then begin
    block[igood]= (fiberid[igood]-1L)/nperblock+1L

    ;; now we have all the fibers assigned, and satisfy the number per
    ;; block constraints. as a last step, we will reassign KEEPING THE
    ;; BLOCK ASSIGNMENTS FIXED
    ii=where(design[igood].targettype eq 'SKY' OR $
             design[igood].targettype eq 'STANDARD', nii)
    if(nii gt 0) then begin
        toblock=lonarr(n_elements(design))
        toblock[igood[ii]]=block[igood[ii]]
        sdss_plugprob, design[igood].xf_default, design[igood].yf_default, $
          tmp_fiberid, toblock=toblock[igood], limitdegree=limitdegree
        fiberid[igood]= tmp_fiberid
    endif
endif

    
return, fiberid

end

