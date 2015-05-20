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
;   9-Dec-2008 Demitri Muna, NYU - commented out nosky, nostd, noscience blocks which are not relevent for MARVELS.
;   1-Sep-2010 Demitri Muna, NYU, Adding file test before opening files.
;-
function fiberid_marvels, default, fibercount, design, $
                          minstdinblock=minstdinblock, $
                          minskyinblock=minskyinblock, $
                          maxskyinblock=maxskyinblock, $
                          nosky=nosky, nostd=nostd, noscience=noscience, $
                          quiet=quiet, block=block, $
						  plate_obj=plate_obj, $
                          respect_fiberid=respect_fiberid, all_design=all_design

  true = 1
  false = 0

  platescale = platescale('APO')
  nperblock=6L

  if(keyword_set(minstdinblock) eq false) then minstdinblock=0L
  if(keyword_set(minskyinblock) eq false) then minskyinblock=0L
  if(keyword_set(maxskyinblock) eq false) then maxskyinblock=0L

  if(tag_indx(default, 'pointing_name') ne -1) then begin
     pointing_name = STRSPLIT(default.pointing_name, /extract)
  endif else begin
     pointing_name= ['A', 'B', 'C', 'D', 'E', 'F']
  endelse
  
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
  blockbase=getenv('PLATEDESIGN_DIR')+'/data/marvels/fiberBlocksMARVELSBright'

; -------------------------------------------
; MARVELS does not assign standards or skies, so resetting the
; block centers is irrelevant.
; -------------------------------------------
  if (keyword_set(noscience) eq true) then begin
     
     logString = 'FIBERID_MARVELS: Request to reset block centers to follow science fibers ' + $
                 'in a MARVELS pointing is not necessary and will have no effect - ' + $
                 'are you sure this is what you wanted?'
     
                                ; To do: use platelog, but I need to get the plate id which
                                ; I don't have here!
                                ; platelog, plateid, logString
     
     print, logString
     
  endif

; -------------------------------------------
; MARVELS does not assign standards.
; -------------------------------------------
  if (keyword_set(nostd) eq true) then begin
     
     logString = 'FIBERID_MARVELS: Request to assign standards to a MARVELS ' + $
                 'pointing. This has no effect - are you sure this is what you wanted?'
     
                                ; To do: use platelog, but I need to get the plate id which
                                ; I don't have here!
                                ; platelog, plateid, logString
     
     print, logString
     
  endif

; -------------------------------------------
; MARVELS does not assign skies.
; -------------------------------------------
  if (keyword_set(nosky) eq true) then begin
     
     logString = 'FIBERID_MARVELS: Request to assign skies to a MARVELS ' + $
                 'pointing. This has no effect - are you sure this is what you wanted?'
     
     ;; To do: use platelog, but I need to get the plate id which I don't have here!
     ;; platelog, plateid, logString
     print, logString
     
  endif

; finally, assign science again
  if(keyword_set(noscience) eq false) then begin
     for ip=1L, npointings do begin

        pname= pointing_name[ip-1]

        blockfile= blockbase+pname+'.par'
        check_file_exists, blockfile
        
        fiberblocks= yanny_readone(blockfile)
        nblocks=max(fiberblocks.blockid)
        blockcenx= fltarr(nblocks)
        blockceny= fltarr(nblocks)
        for i=1L, nblocks do begin
           ib= where(fiberblocks.blockid eq i, nb)
           blockcenx[i-1]= mean(fiberblocks[ib].fibercenx)
           blockceny[i-1]= mean(fiberblocks[ib].fiberceny)
        endfor
        
        isci= where(strupcase(design.holetype) eq 'MARVELS' AND $
                    strupcase(design.targettype) ne 'SKY' AND $
                    strupcase(design.targettype) ne 'STANDARD' AND $
                    fiberid le 0 AND $
                    design.pointing eq ip, nsci)
        tmp_fiberused=0
        if(keyword_set(fiberused[ip-1])) then $
           tmp_fiberused=*fiberused[ip-1]
        fiber_offset= n_elements(fiberblocks)*(ip-1)
        if(nsci gt 0) then begin
           
           ;; assign the fibers
           tmp_fiberid=0
           sdss_plugprob, design[isci].xf_default, design[isci].yf_default, $
                          tmp_fiberid, fiberused=tmp_fiberused, $
                          blockfile=blockfile, reachfunc='boss_reachcheck', $
                          minavail=0L, maxinblock=nperblock
           
           ;;for i=0L, nblocks-1L do begin
              ;;ib= where(fiberblocks[tmp_fiberid-1].blockid eq i+1, nb)
              ;;if(nb gt 0) then begin
                 ;;blockcenx[i]= mean(design[isci[ib]].xf_default)/platescale
                 ;;blockceny[i]= mean(design[isci[ib]].yf_default)/platescale
              ;;endif 
           ;;endfor

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
           if(keyword_set(quiet) eq false) then $
              splog, 'No science targets in this plate/pointing ' + $
                     'or else redesigning an existing plug map.'
        endelse
        if(keyword_set(tmp_fiberused)) then $
           fiberused[ip-1]= ptr_new(tmp_fiberused)
     endfor
  endif
  
  ;; set blocks
  block= lonarr(n_elements(fiberid))-1L
  for ip=1L, npointings do begin
     igood= where(fiberid ge 1 and design.pointing eq ip, ngood)
     fiber_offset= n_elements(fiberblocks)*(ip-1)
     if(ngood gt 0) then $
        block[igood]= (fiberid[igood]-1L-fiber_offset)/nperblock+1L
  endfor

  return, fiberid

end

