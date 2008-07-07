;+
; NAME:
;   sdss_plugprob
; PURPOSE:
;   assign targets to fibers and blocks for SDSS style cartridge
; CALLING SEQUENCE:
;   sdss_plugprob, xtarget, ytarget, fiberid, [fiberused=, $
;      mininblock=, minavail=, nmax= ]
; INPUTS:
;   xtarget, ytarget - focal plane positions (mm)
; OPTIONAL INPUTS:
;   fiberused - [N] 1-indexed indices of already used fibers
;   mininblock - minimum numbers of fibers to assign per block
;                [default 0]
;   mininblock - maximum numbers of fibers to assign per block
;                [default 20]
;   minavail - don't assign a fiber to a target unless more than
;              minavail fibers in the same block can also reach it
;              [default 8]
;   nmax - use at most this many fibers total
;   toblock - [N] assign each fiber to this particular block (0 for
;             no constraint)
;   blockcenx, blockceny - [20] centers of cost for assigning a fiber
;                          in each block to a target (if set, this cost used
;                          instead of normal distance-to-fiber cost)
; OPTIONAL KEYWORDS:
;   /quiet - be quiet about warnings
; OUTPUTS:
;   fiberid - 1-indexed list of assigned fibers 
; COMMENTS:
;   Uses $PLATEDESIGN_DIR/data/sdss/fiberBlocks.par to find closest 
;     fiber position for each target.
;   If you have already assigned fibers, pass fiberused to exclude
;     them from the selection
;   The minavail option avoids highly tuned pluggings, by guaranteeing
;     that if a target is assigned to a block it is reachable by
;     several fibers in that block.
; REVISION HISTORY:
;   4-Jun-2008 MRB, NYU 
;-
pro sdss_plugprob, in_xtarget, in_ytarget, fiberid, minavail=minavail, $
                   mininblock=mininblock, fiberused=fiberused, $
                   nmax=nmax, quiet=in_quiet, limitdegree=limitdegree, $
                   toblock=toblock, blockcenx=blockcenx, blockceny=blockceny, $
                   maxinblock=maxinblock

common com_plugprob, fiberblocks

platescale = 217.7358           ; mm/degree
if(NOT keyword_set(limitdegree)) then $
  limitdegree= 7.*0.1164        ; limit of fiber reach
if(NOT keyword_set(toblock)) then toblock= lonarr(n_elements(in_xtarget))
if(NOT keyword_set(mininblock)) then mininblock= 0L
if(NOT keyword_set(maxinblock)) then maxinblock= 20L
if(NOT keyword_set(minavail)) then minavail= 8L
quiet= long(keyword_set(in_quiet))

if(n_tags(fiberblocks) eq 0) then $
  fiberblocks= yanny_readone(getenv('PLATEDESIGN_DIR')+ $
                             '/data/sdss/fiberBlocks.par')

;; default centers of blocks
blockconstrain=1L
if(keyword_set(blockcenx) eq 0 OR $
   keyword_set(blockceny) eq 0) then begin
    nblocks=max(fiberblocks.blockid)
    blockcenx= fltarr(nblocks)
    blockceny= fltarr(nblocks)
    for i=1L, nblocks do begin
        ib= where(fiberblocks.blockid eq i, nb)
        blockcenx[i-1]= mean(fiberblocks[ib].fibercenx)
        blockceny[i-1]= mean(fiberblocks[ib].fiberceny)
    endfor
    blockconstrain=0L
endif

;; get fiber positions
xfiber= double(fiberblocks.fibercenx)
yfiber= double(fiberblocks.fiberceny)
nfibers=n_elements(xfiber)
if(NOT keyword_set(nmax)) then nmax= nfibers
iblock=where(fiberblocks.blockid eq 1, nfibersblock)

;; convert target positions from mm to deg
xtarget=double(in_xtarget/platescale)
ytarget=double(in_ytarget/platescale)
ntargets=n_elements(xtarget)

;; signal fibers that are used
used=lonarr(nfibers)
if(keyword_set(fiberused)) then $
  used[fiberused-1]=1

tmpdir=getenv('PLATELIST_DIR')+'/tmp'

probfile=tmpdir+'/tmp_prob.txt'
soname = filepath('libfiber.'+idlutils_so_ext(), $
                  root_dir=getenv('PLATEDESIGN_DIR'), subdirectory='lib')
retval = call_external(soname, 'idl_write_plugprob', $
                       double(xtarget), double(ytarget), long(ntargets), $
                       double(xfiber), double(yfiber), long(used), $
                       long(toblock), long(nfibers), long(nmax), $
                       long(nfibersblock), double(limitdegree), $
                       long(minavail), long(mininblock), long(maxinblock), $
                       double(blockcenx), double(blockceny), $
                       long(blockconstrain), string(probfile))

spawn, 'cat '+tmpdir+'/tmp_prob.txt | '+ $
  getenv('PLATEDESIGN_DIR')+'/src/cs2/cs2 '+ $
  ' > '+tmpdir+'/tmp_ans.txt'

ansfile=tmpdir+'/tmp_ans.txt'
targetfiber=lonarr(ntargets)
fiberblock=lonarr(ntargets)

retval = call_external(soname, 'idl_read_plugprob', $
                       double(xtarget), double(ytarget), long(targetfiber), $
                       long(fiberblock), long(ntargets), $
                       long(nfibersblock), long(nfibers), $
                       long(quiet), string(ansfile))

fiberid=targetfiber+1L

end

