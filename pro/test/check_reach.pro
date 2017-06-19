;+
; NAME:
;   check_reach
; PURPOSE:
;   Check reach for a plate
; INPUTS:
;   plugfile - plPlugMapP file
; OPTIONAL INPUTS:
;   blockfile - file to read in for fibers
;   reachfunc - code to call to check whether a fiber reaches target
;               (e.g. boss_checkreach)
; OUTPUTS:
;   Ok - 1 if OK
; COMMENTS:
;   Uses $PLATEDESIGN_DIR/data/sdss/fiberBlocks.par to find closest 
;     fiber position for each target by default.
;   If you have already assigned fibers, pass fiberused to exclude
;     them from the selection
;   The minavail option avoids highly tuned pluggings, by guaranteeing
;     that if a target is assigned to a block it is reachable by
;     several fibers in that block.
; REVISION HISTORY:
;   26-May-2017 MRB, NYU 
;-
pro check_reach, plateid, $
                 blockfile=in_blockfile, $
                 reachfunc=reachfunc, $
                 stretch=stretch, platescale=platescale, $
                 plot=plot, verbose=verbose

common com_plugprob, fiberblocks, blockfile

platestr = strtrim(string(plateid),2)
pointing_post = ''
plugfile= plate_dir(plateid)+'/plPlugMapP-'+platestr+ $
  pointing_post+'.par' 

if(NOT keyword_set(platescale)) then $
  platescale= get_platescale('LCO')

if(~keyword_set(in_blockfile)) then $
  in_blockfile=getenv('PLATEDESIGN_DIR')+'/data/apogee/fiberBlocksAPOGEE_SOUTH.par'
if(~keyword_set(reachfunc)) then $
  reachfunc='apogee_south_reachcheck'

quiet= long(keyword_set(in_quiet))

reload=0L
if(n_tags(fiberblocks) eq 0) then reload=1
if(keyword_set(blockfile) eq 0) then begin
    reload=1
endif else begin
    if(blockfile ne in_blockfile) then reload=1
endelse
if(keyword_set(reload)) then begin
    blockfile= in_blockfile
    fiberblocks= yanny_readone(blockfile)
endif
fiberblockid= fiberblocks.blockid
nblocks= max(fiberblocks.blockid)

;; get fiber positions
xfiber= double(fiberblocks.fibercenx) * platescale
yfiber= double(fiberblocks.fiberceny) * platescale
nfibers=n_elements(xfiber)
iblock=where(fiberblocks.blockid eq 1, nfibersblock)

;; target positions in deg not mm
plug = yanny_readone(plugfile)
ihole = where(plug.holetype eq 'OBJECT')
xtarget = double(plug[ihole].xfocal)
ytarget = double(plug[ihole].yfocal)
fiberid = - plug[ihole].fiberid
ntargets=n_elements(xtarget)

;; set whether fibers reach targets, if using reachfunc
fibertargetspossible=lonarr(nfibers, ntargets)
for i=0L, nfibers-1L do begin
    j = where(fiberblocks[i].fiberid eq fiberid)
    reaches = call_function(reachfunc, xfiber[i], $
                            yfiber[i], $
                            xtarget[j], $
                            ytarget[j], stretch=stretch)
    if(~reaches) then begin
        if(keyword_set(plot)) then begin
            splot, xfiber, yfiber, psym=5, color='red'
            soplot, xtarget, ytarget, psym=4
            soplot, [xfiber[i], xtarget[j]], $
              [yfiber[i], ytarget[j]], th=4, color='yellow'
            reaches = call_function(reachfunc, xfiber[i], $
                                    yfiber[i], $
                                    xtarget, $
                                    ytarget, stretch=stretch)
            ireach = where(reaches)
            soplot, xtarget[ireach], ytarget[ireach], $
              psym=4, color='cyan'
        endif
        
        print, platestr + ' does not reach'
        return
    endif

endfor

if(keyword_set(verbose)) then $
  print, platestr + ' reaches.'

end

