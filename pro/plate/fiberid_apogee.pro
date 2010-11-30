;+
; NAME:
;   fiberid_marvels
; PURPOSE:
;   assign fiberid's to a list of APOGEE targets
; CALLING SEQUENCE:
;   fiberid= fiberid_apogee(design)
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
;   Assigns bright, medium, and faint targets separately (100 each)
;   Keywords minstd, minstd, /nosky, etc ignored.
; REVISION HISTORY:
;   4-Oct-2010 MRB, adjusted for APOGEE
;-
pro set_blockcen_apogee, design, blocks, fiberid, blockcenx, blockceny
  platescale = 217.7358         ; mm/degree

  ;; now find the center location for each block, and limits in
  ;; y-direction of targets
  bnums= (uniqtag(blocks, 'blockid')).blockid
  for i=0L, n_elements(bnums)-1L do begin
     ib= where(blocks[fiberid-1].blockid eq bnums[i], nb)
     if(nb gt 0) then begin
        blockcenx[bnums[i]-1]= mean(design[ib].xf_default)/platescale
        blockceny[bnums[i]-1]= mean(design[ib].yf_default)/platescale
     endif 
  endfor
end
;;
function fiberid_apogee, default, fibercount, design, $
                         minstdinblock=minstdinblock, $
                         minskyinblock=minskyinblock, $
                         maxskyinblock=maxskyinblock, $
                         nosky=nosky, nostd=nostd, noscience=noscience, $
                         quiet=quiet, block=block, $
                         respect_fiberid=respect_fiberid, $
                         debug=debug

common com_fiberid_apogee, fiberblocks

if(keyword_set(respect_fiberid)) then $
  message, 'APOGEE spectrograph designs cannot respect fiberid'

if(keyword_set(minstdinblock)) then $
  message, 'Cannot set block constraints for standards in APOGEE'

if(keyword_set(minskyinblock)) then $
  message, 'Cannot set block constraints for sky in APOGEE'

if(keyword_set(maxskyinblock)) then $
  message, 'Cannot set block constraints for sky in APOGEE'

if(keyword_set(nosky)) then $
  message, 'No version in APOGEE that ignores sky'

if(keyword_set(nostd)) then $
  message, 'No version in APOGEE that ignores standards'

if(keyword_set(noscience)) then $
  message, 'No version in APOGEE that ignores science'

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

full_blockfile=getenv('PLATEDESIGN_DIR')+'/data/apogee/fiberBlocksAPOGEE.par'
bright_blockfile=getenv('PLATEDESIGN_DIR')+'/data/apogee/fiberBlocksBrightAPOGEE.par'
medium_blockfile=getenv('PLATEDESIGN_DIR')+'/data/apogee/fiberBlocksMediumAPOGEE.par'
faint_blockfile=getenv('PLATEDESIGN_DIR')+'/data/apogee/fiberBlocksFaintAPOGEE.par'

blocks= yanny_readone(full_blockfile)
bblocks= yanny_readone(bright_blockfile)
mblocks= yanny_readone(medium_blockfile)
fblocks= yanny_readone(faint_blockfile)

relaxed_fiber_classes=0
if(tag_indx(default, 'relaxed_fiber_classes') ge 0) then begin
   if(long(default.relaxed_fiber_classes) gt 0) then begin
      relaxed_fiber_classes=1
   endif
endif


maxiter=7L
for iter=0L, maxiter-1L do begin
   
   if(relaxed_fiber_classes eq 0) then begin
      ;; brights 
      ibright= where(strupcase(design.holetype) eq 'APOGEE' AND $
                     (strupcase(design.targettype) eq 'STANDARD_BRIGHT' OR $
                      strupcase(design.targettype) eq 'SCIENCE_BRIGHT'), nbright)
      sdss_plugprob, design[ibright].xf_default, $
                     design[ibright].yf_default, tmp_fiberid, $
                     reachfunc='boss_reachcheck', maxinblock=2L, $
                     minavail=0L, blockfile=bright_blockfile, $
                     blockcenx=blockcenx, blockceny=blockceny
      ibad= where(tmp_fiberid le 0, nbad)
      if(nbad gt 0) then begin
         message, 'Failed to assign all bright targets!'
      endif
      fiberid[ibright]=bblocks[tmp_fiberid-1L].fiberid
      idone= where(fiberid gt 0, ndone)
      set_blockcen_apogee, design[idone], blocks, fiberid[idone], $
                           blockcenx, blockceny
      if(keyword_set(debug)) then begin
         splot, design.xf_default, design.yf_default, psym=4
         bnums= (uniqtag(blocks[fiberid[idone]-1],'blockid')).blockid
         for i=0L, n_elements(bnums)-1L do begin
            ib=where(blocks[fiberid[idone]-1].blockid eq bnums[i])
            isort= sort(design[idone[ib]].yf_default)
            soplot, design[idone[ib[isort]]].xf_default, $
                    design[idone[ib[isort]]].yf_default
            soplot, blockcenx[bnums[i]-1]*platescale, $
                    blockceny[bnums[i]-1]*platescale, psym=4, $
                    color='red'
         endfor
      endif
      
      ;; mediums
      imedium= where(strupcase(design.holetype) eq 'APOGEE' AND $
                     (strupcase(design.targettype) eq 'STANDARD_MEDIUM' OR $
                      strupcase(design.targettype) eq 'SCIENCE_MEDIUM'), nmedium)
      sdss_plugprob, design[imedium].xf_default, $
                     design[imedium].yf_default, tmp_fiberid, $
                     reachfunc='boss_reachcheck', maxinblock=2L, $
                     minavail=0L, blockfile=medium_blockfile, $
                     blockcenx=blockcenx, blockceny=blockceny
      ibad= where(tmp_fiberid le 0, nbad)
      if(nbad gt 0) then begin
         message, 'Failed to assign all medium targets!'
      endif
      fiberid[imedium]=tmp_fiberid
      fiberid[imedium]=mblocks[tmp_fiberid-1L].fiberid
      idone= where(fiberid gt 0, ndone)
      set_blockcen_apogee, design[idone], blocks, fiberid[idone], $
                           blockcenx, blockceny
      if(keyword_set(debug)) then begin
         splot, design.xf_default, design.yf_default, psym=4
         bnums= (uniqtag(blocks[fiberid[idone]-1],'blockid')).blockid
         for i=0L, n_elements(bnums)-1L do begin
            ib=where(blocks[fiberid[idone]-1].blockid eq bnums[i])
            isort= sort(design[idone[ib]].yf_default)
            soplot, design[idone[ib[isort]]].xf_default, $
                    design[idone[ib[isort]]].yf_default
            soplot, blockcenx[bnums[i]-1], blockceny[bnums[i]-1], psym=4, $
                    color='red'
         endfor
      endif
      
      ;; faints
      ifaint= where(strupcase(design.holetype) eq 'APOGEE' AND $
                    (strupcase(design.targettype) eq 'STANDARD_FAINT' OR $
                     strupcase(design.targettype) eq 'SCIENCE_FAINT' OR $
                     strupcase(design.targettype) eq 'SKY'), nfaint)
      sdss_plugprob, design[ifaint].xf_default, $
                     design[ifaint].yf_default, tmp_fiberid, $
                     reachfunc='boss_reachcheck', maxinblock=2L, $
                     minavail=0L, blockfile=faint_blockfile, $
                     blockcenx=blockcenx, blockceny=blockceny 
      ibad= where(tmp_fiberid le 0, nbad)
      if(nbad gt 0) then begin
         message, 'Failed to assign all faint targets!'
      endif
      fiberid[ifaint]=fblocks[tmp_fiberid-1L].fiberid
      idone= where(fiberid gt 0, ndone)
      set_blockcen_apogee, design[idone], blocks, fiberid[idone], $
                           blockcenx, blockceny
      if(keyword_set(debug)) then begin
         splot, design.xf_default, design.yf_default, psym=4
         bnums= (uniqtag(blocks[fiberid[idone]-1],'blockid')).blockid
         for i=0L, n_elements(bnums)-1L do begin
            ib=where(blocks[fiberid[idone]-1].blockid eq bnums[i])
            isort= sort(design[idone[ib]].yf_default)
            soplot, design[idone[ib[isort]]].xf_default, $
                    design[idone[ib[isort]]].yf_default
            soplot, blockcenx[bnums[i]-1], blockceny[bnums[i]-1], psym=4, $
                    color='red'
         endfor
      endif
   endif else begin
      ;; all in one go
      iapogee= where(strupcase(design.holetype) eq 'APOGEE' AND $
                     (strupcase(design.targettype) eq 'STANDARD' OR $
                      strupcase(design.targettype) eq 'SCIENCE' OR $
                      strupcase(design.targettype) eq 'SKY'), napogee)
      sdss_plugprob, design[iapogee].xf_default, $
                     design[iapogee].yf_default, tmp_fiberid, $
                     reachfunc='boss_reachcheck', maxinblock=6L, $
                     minavail=0L, blockfile=full_blockfile, $
                     blockcenx=blockcenx, blockceny=blockceny 
      ibad= where(tmp_fiberid le 0, nbad)
      if(nbad gt 0) then begin
         message, 'Failed to assign all targets!'
      endif
      fiberid[iapogee]=blocks[tmp_fiberid-1L].fiberid
      idone= where(fiberid gt 0, ndone)
      set_blockcen_apogee, design[idone], blocks, fiberid[idone], $
                           blockcenx, blockceny
      if(keyword_set(debug)) then begin
         splot, design.xf_default, design.yf_default, psym=4
         bnums= (uniqtag(blocks[fiberid[idone]-1],'blockid')).blockid
         for i=0L, n_elements(bnums)-1L do begin
            ib=where(blocks[fiberid[idone]-1].blockid eq bnums[i])
            isort= sort(design[idone[ib]].yf_default)
            soplot, design[idone[ib[isort]]].xf_default, $
                    design[idone[ib[isort]]].yf_default
            soplot, blockcenx[bnums[i]-1], blockceny[bnums[i]-1], psym=4, $
                    color='red'
         endfor
      endif
   endelse
   
endfor

nperblock=6L
block=blocks[fiberid-1L].blockid

;; if fiber classes are relaxed, set exact number according
;; to the H-band magnitude
if(relaxed_fiber_classes gt 0) then begin
   nblocks= 50L
   for i=0L, nblocks-1L do begin
      idesign= where(block eq i+1, nii)
      if(nii ne nperblock) then $
         message, 'Not enough targets in block!'
      ifiber= where(blocks.blockid eq i+1, nii)
      if(nii ne nperblock) then $
         message, 'Not enough fibers in block!'
      hmag= design[iapogee[idesign]].tmass_h
      ibad= where(hmag eq -9999, nbad)
      if(nbad gt 0) then $
         hmag[ibad]=9999.
      ihmagsort= sort(hmag)
      relaxed_ftypes=strarr(nperblock)
      relaxed_ftypes[ihmagsort]=['B', 'B', 'M', 'M', 'F', 'F']
      usedit= bytarr(nperblock)
      for j=0L, nperblock-1L do begin
         ipick= where(relaxed_ftypes[j] eq blocks[ifiber].ftype AND $
                      usedit eq 0, npick)
         if(npick eq 0) then $
            message, 'Ran out of this type!'
         usedit[ipick[0]]=1
         fiberid[iapogee[idesign[j]]]= blocks[ifiber[ipick[0]]].fiberid
      endfor
   endfor
endif

return, fiberid

end
