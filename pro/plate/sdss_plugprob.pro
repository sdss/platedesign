;+
; NAME:
;   sdss_plugprob
; PURPOSE:
;   assign targets to fibers and blocks for SDSS style cartridge
; CALLING SEQUENCE:
;   sdss_plugprob, xtarget, ytarget, fiberid, [fiberused=, $
;      mininblock=, maxinblock=, minavail=, nmax=, blockfile= ]
; INPUTS:
;   xtarget, ytarget - [Ntarg] focal plane positions (mm)
; OPTIONAL INPUTS:
;   fiberused - [Nused] 1-indexed indices of already used fibers
;   mininblock - minimum numbers of fibers to assign per block
;                [default 0]
;   maxinblock - maximum numbers of fibers to assign per block
;                [default 20]
;   minavail - don't assign a fiber to a target unless more than
;              minavail fibers in the same block can also reach it
;              [default 8, or maxinblock if < 8]
;   nmax - use at most this many fibers total
;   toblock - [Ntarg] assign each fiber to this particular block (0 for
;             no constraint)
;   blockcenx, blockceny - [20] centers of cost for assigning a fiber
;                          in each block to a target (if set, this cost used
;                          instead of normal distance-to-fiber cost)
;   blockfile - file to read in for fibers
;   reachfunc - code to call to check whether a fiber reaches target
;               (e.g. boss_checkreach)
;   limitdegree - maximal radial reach, degrees (if reachfunc not set)
; OPTIONAL KEYWORDS:
;   /noycost - don't reward for being closer than necessary in y
;              [useful to keep skies spread out OK]
;   /quiet - be quiet about warnings
; OUTPUTS:
;   fiberid - 1-indexed list of assigned fibers 
; COMMENTS:
;   Uses $PLATEDESIGN_DIR/data/sdss/fiberBlocks.par to find closest 
;     fiber position for each target by default.
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
                   maxinblock=maxinblock, blockfile=in_blockfile, $
                   noycost=noycost, ylimits=ylimits, reachfunc=reachfunc, $
                   stretch=stretch, platescale=platescale

common com_plugprob, fiberblocks, blockfile

if(NOT keyword_set(platescale)) then $
  platescale= get_platescale('APO')

if(~keyword_set(limitdegree) AND ~keyword_set(reachfunc)) then $
  limitdegree= 7.*0.1164
if(~keyword_set(toblock)) then toblock= lonarr(n_elements(in_xtarget))
if(~keyword_set(mininblock)) then mininblock= 0L
if(~keyword_set(maxinblock)) then maxinblock= 20L
if(~keyword_set(minavail)) then minavail= (8L) < maxinblock
if(~keyword_set(in_blockfile)) then $
  in_blockfile=getenv('PLATEDESIGN_DIR')+'/data/sdss/fiberBlocks.par'
if(~keyword_set(noycost)) then noycost=0
quiet= long(keyword_set(in_quiet))

if(keyword_set(limitdegree) gt 0 AND $
   keyword_set(reachfunc) gt 0) then $
  message, 'Both LIMITDEGREE and REACHFUNC should not be set, use one or other'

reload=0L
if(n_tags(fiberblocks) eq 0) then reload=1
if(keyword_set(blockfile) eq 0) then begin
    reload=1
endif else begin
    if(blockfile ne in_blockfile) then reload=1
endelse
if(keyword_set(reload)) then begin
    blockfile= in_blockfile
    fiberblocks= yanny_readone(blockfile, /anon)
endif
fiberblockid= fiberblocks.blockid
nblocks= max(fiberblocks.blockid)

;; default centers of blocks
blockconstrain=1L
if(keyword_set(blockcenx) eq 0 OR $
   keyword_set(blockceny) eq 0) then begin
    blockcenx= fltarr(nblocks)
    blockceny= fltarr(nblocks)
    for i=1L, nblocks do begin
        ib= where(fiberblocks.blockid eq i, nb)
        blockcenx[i-1]= mean(fiberblocks[ib].fibercenx)
        blockceny[i-1]= mean(fiberblocks[ib].fiberceny)
    endfor
    blockconstrain=0L
endif

if(keyword_set(ylimits) eq 0) then begin
    ylimits=dblarr(2, nblocks)
    ylimits[0,*]=-10.
    ylimits[1,*]=+10.
endif

;; get fiber positions
xfiber= double(fiberblocks.fibercenx)
yfiber= double(fiberblocks.fiberceny)
nfibers=n_elements(xfiber)
if(~keyword_set(nmax)) then nmax= nfibers
iblock=where(fiberblocks.blockid eq 1, nfibersblock)

;; target positions in deg not mm
xtarget=double(in_xtarget/platescale)
ytarget=double(in_ytarget/platescale)
ntargets=n_elements(xtarget)

;; signal fibers that are used
used=lonarr(nfibers)
if(keyword_set(fiberused)) then $
  used[fiberused-1]=1

if(keyword_set(reachfunc)) then begin
    ;; set whether fibers reach targets, if using reachfunc
    fibertargetspossible=lonarr(nfibers, ntargets)
    for i=0L, nfibers-1L do $
          fibertargetspossible[i,*]= $
            call_function(reachfunc, xfiber[i]*platescale, $
                          yfiber[i]*platescale, $
                          xtarget*platescale, $
                          ytarget*platescale, stretch=stretch)
    inputpossible=1L
    limitdegree=0.
endif else begin
    ;; otherwise, still need to set the array up
    fibertargetspossible=lonarr(nfibers, ntargets)
    inputpossible=0L
endelse


tmpdir=getenv('PLATELIST_DIR')+'/tmp'

spawn, /nosh, ['uuidgen'], uid
uid=uid[0]

probfile=tmpdir+'/tmp_prob_'+uid+'.txt'
soname = filepath('libfiber.'+idlutils_so_ext(), $
                  root_dir=getenv('PLATEDESIGN_DIR'), subdirectory='lib')
retval = call_external(soname, 'idl_write_plugprob', $
                       double(xtarget), double(ytarget), long(ntargets), $
                       double(xfiber), double(yfiber), long(fiberblockid), $
                       long(used), long(toblock), long(nfibers), long(nmax), $
                       double(limitdegree), long(fibertargetspossible), $
                       long(inputpossible), long(minavail), long(mininblock), $
                       long(maxinblock), double(blockcenx), double(blockceny), $
                       long(blockconstrain), long(nblocks), $
                       string(probfile), long(noycost), $
                       double(ylimits))

cs2_path = getenv('PLATEDESIGN_DIR') + '/src/cs2/cs2'
check_file_exists, cs2_path, plateid=0
spawn, 'cat '+tmpdir+'/tmp_prob_'+uid+'.txt | '+ $
  cs2_path + ' > '+tmpdir+'/tmp_ans_'+uid+'.txt'

ansfile=tmpdir+'/tmp_ans_'+uid+'.txt'
targetfiber=lonarr(ntargets)
targetblock=lonarr(ntargets)

retval = call_external(soname, 'idl_read_plugprob', $
                       double(xtarget), double(ytarget), long(targetfiber), $
                       long(targetblock), long(ntargets), $
                       long(fiberblockid), long(nfibers), $
                       long(quiet), string(ansfile))
fiberid=targetfiber+1L

;; clean up temporary files
file_delete, probfile 
file_delete, ansfile

end

