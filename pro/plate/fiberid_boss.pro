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
;   Uses boss_reachcheck.pro to decide if a fiber reaches a target
; REVISION HISTORY:
;   4-Jun-2008 MRB, NYU 
;-
function fiberid_boss, default, fibercount, design, $
  minstdinblock=minstdinblock, $
  minskyinblock=minskyinblock, $
  maxskyinblock=maxskyinblock, $
  nosky=nosky, nostd=nostd, noscience=noscience, $
  quiet=quiet, block=block, $
  respect_fiberid=respect_fiberid, $
  debug=debug

common com_fiberid_boss, fiberblocks

if(keyword_set(respect_fiberid)) then $
  message, 'BOSS spectrograph designs cannot respect fiberid'

if(keyword_set(minstdinblock)) then $
  message, 'Cannot set block constraints for standards in BOSS'

platescale = 217.7358           ; mm/degree
nperblock=20L
minyblocksize=0.3

if(NOT keyword_set(minstdinblock)) then minstdinblock=0L
if(NOT keyword_set(minskyinblock)) then minskyinblock=0L
if(NOT keyword_set(maxskyinblock)) then maxskyinblock=nperblock

fiberused=0L
fiberid=lonarr(n_elements(design))
npointings= long(default.npointings)
noffsets= long(default.noffsets)

;; default centers of blocks
blockfile=getenv('PLATEDESIGN_DIR')+'/data/boss/fiberBlocksBOSS.par'
if(n_tags(fiberblocks) eq 0) then $
    fiberblocks= yanny_readone(blockfile)
nblocks=max(fiberblocks.blockid)
blockcenx= fltarr(nblocks)
blockceny= fltarr(nblocks)
blockylimits= fltarr(2, nblocks)
for i=1L, nblocks do begin
    ib= where(fiberblocks.blockid eq i, nb)
    blockcenx[i-1]= mean(fiberblocks[ib].fibercenx)
    blockceny[i-1]= mean(fiberblocks[ib].fiberceny)
    blockylimits[*,i-1]= minmax(fiberblocks[ib].fiberceny)
endfor


;; first assign science and standard, and reset block centers to follow science
;; fibers; DO NOT SAVE SCIENCE PLUGGING HERE
isci= where(strupcase(design.targettype) ne 'SKY', nsci)
if(nsci gt 0) then begin
    
    ;; assign the fibers 
    sdss_plugprob, design[isci].xf_default, design[isci].yf_default, $
      tmp_fiberid, fiberused=fiberused, $
      maxinblock=nperblock-minskyinblock, $
      mininblock=nperblock-maxskyinblock, $
      blockfile=blockfile, reachfunc='boss_reachcheck'
    
    iassigned=where(tmp_fiberid ge 1, nassigned)
    if(nassigned gt 0) then begin
        if(NOT keyword_set(fiberused)) then $
          fiberused=tmp_fiberid[iassigned] $
        else $
          fiberused=[fiberused, tmp_fiberid[iassigned]] 
        fiberid[isci[iassigned]]=tmp_fiberid[iassigned]
    endif 
    
    ;; which block is each in
    block= lonarr(n_elements(tmp_fiberid))-1L
    igood= where(tmp_fiberid ge 1, ngood)
    if(ngood gt 0) then begin
        block[igood]= (tmp_fiberid[igood]-1L)/nperblock+1L
        
        ;; now find the center location for each block, and limits in
        ;; y-direction of targets
        for i=1L, nblocks do begin
            ib= where(block eq i, nb)
            if(nb gt 0) then begin
                blockcenx[i-1]= mean(design[ib].xf_default)/platescale
                blockceny[i-1]= mean(design[ib].yf_default)/platescale
                blockylimits[*,i-1]= minmax(design[ib].yf_default/platescale)
                if(blockylimits[1,i-1]-blockylimits[0,i-1] lt minyblocksize) then begin
                    my= 0.5*(blockylimits[1,i-1]+blockylimits[0,i-1])
                    blockylimits[0,i-1]=my-0.5*minyblocksize
                    blockylimits[1,i-1]=my+0.5*minyblocksize
                endif
            endif 
        endfor
    endif
endif else begin
    if(NOT keyword_set(quiet)) then $
      splog, 'No science targets in this plate.'
endelse

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
                
                ;; only use available fibers for sky, force them to be
                ;; in y-range of science targets, but don't prefer any
                ;; particular location in y-direction
                sdss_plugprob, design[isky].xf_default, $
                  design[isky].yf_default, $
                  tmp_fiberid, mininblock=minskyinblock, $
                  maxinblock=maxskyinblock, $
                  nmax=nmax, reachfunc='boss_reachcheck', $
                  blockcenx=blockcenx, blockceny=blockceny, /quiet, $
                  blockfile=blockfile, ylimits=blockylimits, $
                  /noycost, fiberused=fiberused
                
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

icomplete= where(fiberid gt 0, ncomplete)
;;if(ncomplete ne n_elements(fiberblocks)) then $
;;  message, 'Inconsistency in fiberid_boss!'

toblock= lonarr(n_elements(design))-1L
toblock[icomplete]=(fiberid[icomplete]-1L)/nperblock+1L

sdss_plugprob, design[icomplete].xf_default, $
               design[icomplete].yf_default, $
               tmp_fiberid, toblock=toblock[icomplete], $
               reachfunc='boss_reachcheck', $
               blockfile=blockfile 

all_fiberid=fiberid
all_fiberid[icomplete]= tmp_fiberid

;; make sure ALL science targets are assigned
isci=where(strupcase(design.targettype) eq 'SCIENCE', nsci)
if(nsci gt 0) then begin
    ibad= where(all_fiberid[isci] le 0, nbad)
    if(nbad gt 0) then begin
        splog, 'Parameters and target locations yield inconsistency in plugging!'
        splog, 'No solution possible for this set of targets.  Look at the '
        splog, 'distribution, and also verify that you are not being too'
        splog, 'restrictive on the block assignments (minskytinblock, maxskyinblock)'
        message, 'Bombing out for your own good!'
    endif
endif

fiberid[icomplete]= tmp_fiberid

block= lonarr(n_elements(fiberid))-1L
igood= where(fiberid ge 1, ngood)
if(ngood gt 0) then $
  block[igood]= (fiberid[igood]-1L)/nperblock+1L

return, fiberid

end

