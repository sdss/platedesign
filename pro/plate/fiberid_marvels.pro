;+
; NAME:
;   fiberid_marvels
; PURPOSE:
;   assign fiberid's to a list of SDSS targets
; CALLING SEQUENCE:
;   fiberid= fiberid_marvels(design)
; INPUTS:
;   design - [N] struct array of targets, in design_blank() form
;            Required tags are .XF_DEFAULT, .YF_DEFAULT
; OPTIONAL INPUTS:
;   minstdinblock, minskyinblock 
;          - minimum number of standards or skies to assign to each block
;            [default 0]
;   pointing - which pointing(s) to design (default to all)
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
;   Steps through each pointing successively, to guarantee
;     that the correct set of fibers is used for each one
;   Note that for MARVELS, changing pointings means changing the fiber
;     couplers out, so that is why we need to specify the sets of
;     fibers used.
; REVISION HISTORY:
;   4-Jun-2008 MRB, NYU 
;-
function fiberid_marvels, default, fibercount, design, $
                          minstdinblock=minstdinblock, $
                          minskyinblock=minskyinblock, $
                          nosky=nosky, nostd=nostd, noscience=noscience, $
                          quiet=quiet, block=block, $
  respect_fiberid=respect_fiberid

true = 1
false = 0

platescale = 217.7358       ;; mm/degree
limitdegree=9.*0.1164       ;; limit of fiber reach in degrees (n * degrees/inch)
skylimitdegree= limitdegree ;; stretch just as far for skies
stdlimitdegree= limitdegree ;; ... and standards
nperblock=4L

if(keyword_set(minstdinblock) eq false) then minstdinblock=0L
if(keyword_set(minskyinblock) eq false) then minskyinblock=0L

fiberid=lonarr(n_elements(design))
npointings= long(default.npointings)
noffsets= long(default.noffsets)
fiberused=ptrarr(npointings)

if(keyword_set(respect_fiberid)) then begin
    for ip=1L, npointings do begin
        iset= where(design.fiberid ge 1 AND design.pointing eq ip, nset)
        fiber_offset= n_elements(fiberblocks)*(ip-1)
        if(nset gt 0) then begin
            fiberid[iset]=design[iset].fiberid
            fiberused[ip-1]=ptr_new(fiberid[iset]-fiber_offset)
        endif
    endfor
endif

;; default centers of blocks
blockfile=getenv('PLATEDESIGN_DIR')+'/data/marvels/fiberBlocksMarvels.par'
fiberblocks= yanny_readone(blockfile)
nblocks=max(fiberblocks.blockid)
blockcenx= fltarr(nblocks, npointings)
blockceny= fltarr(nblocks, npointings)
for i=1L, nblocks do begin
    ib= where(fiberblocks.blockid eq i, nb)
    blockcenx[i-1,*]= mean(fiberblocks[ib].fibercenx)
    blockceny[i-1,*]= mean(fiberblocks[ib].fiberceny)
endfor

;; first assign science, and reset block centers to follow science
;; fibers; DO NOT SAVE SCIENCE PLUGGING HERE
if(keyword_set(noscience) eq false) then begin
    for ip=1L, npointings do begin
        tmp_fiberused=0
        if(keyword_set(fiberused[ip-1])) then $
          tmp_fiberused=*fiberused[ip-1]
        ;; right now doesn't work well if only SOME of the 
        ;; fibers are respected. 

        isci= where(strupcase(design.targettype) ne 'SKY' AND $
                    strupcase(design.targettype) ne 'STANDARD' AND $
                    design.pointing eq ip, nsci)

        block_offset=(ip-1L)*nblocks
        if(nsci gt 0) then begin
            
            ;; assign the fibers 
            sdss_plugprob, design[isci].xf_default, design[isci].yf_default, $
              tmp_fiberid, limitdegree=limitdegree, $
              maxinblock=nperblock-minstdinblock-minskyinblock, $
              blockfile=blockfile
            
            ;; which block is each in
            block= lonarr(n_elements(tmp_fiberid))-1L
            igood= where(tmp_fiberid ge 1, ngood)
            if(ngood gt 0) then begin
                block[igood]= (tmp_fiberid[igood]-1L)/nperblock+1L
                
                ;; now find the center location for each block
                for i=1L, nblocks do begin
                    ib= where(block eq i, nb)
                    if(nb gt 0) then begin
                        blockcenx[i-1, ip-1]= $
                          mean(design[ib].xf_default)/platescale
                        blockceny[i-1, ip-1]= $
                          mean(design[ib].yf_default)/platescale
                    endif 
                endfor
            endif
        endif else begin
            if(keyword_set(quiet) eq false) then $
              splog, 'No science targets in this plate/pointing.'
        endelse
    endfor
endif

if(keyword_set(nostd) eq false) then begin
    ;; assign standards, if any exist
    ;; ask for minstdinblock in each block for each pointing, at least
    for ip=1L, npointings do begin
        tmp_fiberused=0
        if(keyword_set(fiberused[ip-1])) then $
          tmp_fiberused=*fiberused[ip-1]
        fiber_offset= n_elements(fiberblocks)*(ip-1)
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
                  minavail=nperblock, fiberused=tmp_fiberused, nmax=nmax, $
                  limitdegree=stdlimitdegree, $
                  blockcenx=blockcenx[*,ip-1], blockceny=blockceny[*,ip-1], $
                  /quiet, blockfile=blockfile
                
                iassigned=where(tmp_fiberid ge 1, nassigned)
                help, nassigned, nmax
                if(nassigned gt 0) then begin
                    if(keyword_set(tmp_fiberused) eq false) then $
                      tmp_fiberused=tmp_fiberid[iassigned] $
                    else $
                      tmp_fiberused=[fiberused, tmp_fiberid[iassigned]] 
                    fiberid[istd[iassigned]]= $
                      fiber_offset+tmp_fiberid[iassigned]
                endif 
            endif else begin
                if(keyword_set(quiet) eq false) then $
                  splog, 'No standards in pointing '+strtrim(string(ip),2)+ $
                         ' / offset '+strtrim(string(io),2)
            endelse
        endfor
        if(keyword_set(tmp_fiberused)) then $
          fiberused[ip-1]= ptr_new(tmp_fiberused)
    endfor
endif

if(keyword_set(nosky) eq false) then begin
    ;; assign skies, if any exist
    ;; ask for minskyinblock in each block for each pointing, at least
    for ip=1L, npointings do begin
        tmp_fiberused=0
        if(keyword_set(fiberused[ip-1])) then $
          tmp_fiberused=*fiberused[ip-1]
        fiber_offset= n_elements(fiberblocks)*(ip-1)
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
                  minavail=nperblock, fiberused=tmp_fiberused, nmax=nmax, $
                  limitdegree=skylimitdegree, $
                  blockcenx=blockcenx[*,ip-1], blockceny=blockceny[*,ip-1], $
                  /quiet, blockfile=blockfile
                
                iassigned=where(tmp_fiberid ge 1, nassigned)
                help, nassigned, nmax
                if(nassigned gt 0) then begin
                    if(keyword_set(tmp_fiberused) eq false) then $
                      tmp_fiberused=tmp_fiberid[iassigned] $
                    else $
                      tmp_fiberused=[fiberused, tmp_fiberid[iassigned]] 
                    fiberid[isky[iassigned]]=$
                      fiber_offset+tmp_fiberid[iassigned]
                endif 
            endif else begin
                if(keyword_set(quiet) eq false) then $
                  splog, 'No skies in pointing '+strtrim(string(ip),2)+ $
                         ' / offset '+strtrim(string(io),2)
            endelse
        endfor
        if(keyword_set(tmp_fiberused)) then $
          fiberused[ip-1]= ptr_new(tmp_fiberused)
    endfor
endif

;; finally, assign science again
if(keyword_set(noscience) eq false) then begin
    for ip=1L, npointings do begin
        isci= where(strupcase(design.targettype) ne 'SKY' AND $
                    strupcase(design.targettype) ne 'STANDARD' AND $
                    fiberid le 0 AND $
                    design.pointing eq ip, nsci)
        tmp_fiberused=0
        if(keyword_set(fiberused[ip-1])) then $
          tmp_fiberused=*fiberused[ip-1]
        fiber_offset= n_elements(fiberblocks)*(ip-1)
        if(nsci gt 0) then begin
            
            ;; assign the fibers 
            sdss_plugprob, design[isci].xf_default, design[isci].yf_default, $
              tmp_fiberid, fiberused=tmp_fiberused, limitdegree=limitdegree, $
              blockfile=blockfile, maxinblock=nperblock
            
            ;; do store results
            iassigned=where(tmp_fiberid ge 1, nassigned)
            help, ip, nassigned
            if(nassigned gt 0) then begin
                if(keyword_set(tmp_fiberused) eq false) then $
                  tmp_fiberused=tmp_fiberid[iassigned] $
                else $
                  tmp_fiberused=[tmp_fiberused, tmp_fiberid[iassigned]] 
                fiberid[isci[iassigned]]= $
                  fiber_offset+tmp_fiberid[iassigned]
            endif 
            
        endif else begin
            if(keyword_set(quiet) false) then $
              splog, 'No science targets in this plate/pointing.'
        endelse
        if(keyword_set(tmp_fiberused)) then $
          fiberused[ip-1]= ptr_new(tmp_fiberused)
    endfor
endif
    
block= lonarr(n_elements(fiberid))-1L
for ip=1L, npointings do begin
    igood= where(fiberid ge 1 and design.pointing eq ip, ngood)
    fiber_offset= n_elements(fiberblocks)*(ip-1)
    if(ngood gt 0) then begin
        block[igood]= (fiberid[igood]-1L-fiber_offset)/nperblock+1L
        
        ;; now we have all the fibers assigned, and satisfy the number per
        ;; block constraints. as a last step, we will reassign KEEPING THE
        ;; BLOCK ASSIGNMENTS FIXED
        ii=where(design[igood].targettype eq 'SKY' OR $
                 design[igood].targettype eq 'STANDARD', nii)
        if(nii gt 0) then begin
            toblock=lonarr(n_elements(design))
            toblock[igood[ii]]=block[igood[ii]]
            sdss_plugprob, design[igood].xf_default, $
                           design[igood].yf_default, $
                           tmp_fiberid, toblock=toblock[igood], $
                           limitdegree=limitdegree, $
                           blockfile=blockfile
            fiberid[igood]= fiber_offset+tmp_fiberid
        endif
    endif
endfor

return, fiberid

end

