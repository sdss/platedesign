;+
; NAME:
;   platelines_boss
; PURPOSE:
;   write the plateLines-????.ps file for a BOSS plate
; CALLING SEQUENCE:
;   platelines_boss, plateid [, /diesoft, /sorty, /rearrange ]
; INPUTS:
;   plateid - plate ID to run on
; COMMENTS:
;   Appropriate for BOSS data
;   Makes a PostScript file 26.7717 by 26.7717 inches; mapping
;    should be one-to-one onto plate (x and y ranges are from -340 to
;    +340 mm).
;   Some lines cross each other, due to enforcement of
;    one-sky-per-block constraints.
;   Circles are 45 arcsec radius.
;   Colors of circles are blue for 8 faintest stars in block, green
;    for the 6 next brightest, and red for the 6 brightest
; BUGS:
;   Works off the plPlugMapP file, so may be fragile.
; REVISION HISTORY:
;   22-Aug-2008  MRB, NYU
;    1-Sep-2010  Demitri Muna, NYU, Adding file test before opening files.
;-
;------------------------------------------------------------------------------
pro platelines_rearrange, full, holes, blockfile=blockfile, $
  blockname=blockname

  if(n_elements(blockname) eq 0) then $
     blockname='BOSS'
  if(n_elements(blockfile) eq 0) then $
     blockfile = getenv('PLATEDESIGN_DIR')+'/data/boss/fiberBlocks'+ $
                 blockname+'.par'

  platescale = get_platescale('APO')
  maxiter=3L
  nperblock=20L
  minyblocksize=0.3

  iboss= where(strupcase(full.holetype) eq 'BOSS', nboss)
  fiberblocks= yanny_readone(blockfile, /anon)
  if(nboss ne n_elements(fiberblocks)) then $
     message, 'Not the right number of BOSS fibers?'
  nblocks=max(fiberblocks.blockid)
  blockcenx= fltarr(nblocks)
  blockceny= fltarr(nblocks)
  for i=1L, nblocks do begin
     ib= where(fiberblocks.blockid eq i, nb)
     blockcenx[i-1]= mean(fiberblocks[ib].fibercenx)
     blockceny[i-1]= mean(fiberblocks[ib].fiberceny)
  endfor
  sdss_plugprob, full[iboss].xf_default, $
                 full[iboss].yf_default, $
                 tmp_fiberid, $
                 reachfunc='boss_reachcheck', $
                 blockfile=blockfile, minavail=0

  ;; section for optimizing centers; commented out since it doesn't 
  ;; do much better than just the regular fit.
  if(0) then begin
     for iter=0L, maxiter-1L do begin
        splog, 'iter='+string(iter)
        block= (tmp_fiberid-1L)/nperblock+1L
        ;; now find the center location for each block, and limits in
        ;; y-direction of targets
        for i=1L, nblocks do begin
           ib= where(block eq i, nb)
           if(nb gt 0) then begin
              blockcenx[i-1]= mean(full[iboss[ib]].xf_default)/platescale
              blockceny[i-1]= mean(full[iboss[ib]].yf_default)/platescale
           endif 
        endfor
        tmp_fiberid=0
        sdss_plugprob, full[iboss].xf_default, $
                       full[iboss].yf_default, $
                       tmp_fiberid, $
                       reachfunc='boss_reachcheck', $
                       blockfile=blockfile, $
                       blockcenx=blockcenx, blockceny=blockceny, /quiet
     endfor
     if(min(tmp_fiberid) lt 1) then $
        message, 'Some fibers unassigned'
     
     block= (tmp_fiberid-1L)/nperblock+1L
     tmp_fiberid=0
     sdss_plugprob, full[iboss].xf_default, $
                    full[iboss].yf_default, $
                    tmp_fiberid, $
                    reachfunc='boss_reachcheck', $
                    blockfile=blockfile, toblock=block
  endif

  if(min(tmp_fiberid) lt 1) then $
     message, 'Some fibers unassigned'

  full[iboss].fiberid= tmp_fiberid
  holes[iboss].fiberid= -tmp_fiberid

end
;
pro platelines_boss, in_plateid, diesoft=diesoft, sorty=sorty, $
                     rearrange=rearrange, relax_lines=relax_lines, $
                     blockfile=blockfile, blockname=blockname

common com_plb, plateid, full, holes, hdr, hdrstr

if(n_elements(blockname) eq 0) then $
   blockname='BOSS'
if(n_elements(blockfile) eq 0) then $
   blockfile = getenv('PLATEDESIGN_DIR')+'/data/boss/fiberBlocks'+ $
               blockname+'.par'
fiberblocks= yanny_readone(blockfile, /anon)
nblocks=max(fiberblocks.blockid)
nper=n_elements(fiberblocks) / nblocks
nperblue= nper / 2L

if(NOT keyword_set(in_plateid)) then $
  message, 'Plate ID must be given!'

if(keyword_set(plateid) gt 0) then begin
    if(plateid ne in_plateid) then begin
        plateid= in_plateid
        full=0
        holes=0
    endif
endif else begin
    plateid=in_plateid
endelse

platedir= plate_dir(plateid)

if(n_tags(holes) eq 0) then begin
   plplug= platedir+'/plPlugMapP-'+ $
           strtrim(string(plateid),2)+'.par'
   check_file_exists, plplug, plateid=plateid
   holes= yanny_readone(plplug)
   
   fullfile= platedir+'/'+plateholes_filename(plateid=plateid, /sorted)
   check_file_exists, fullfile, plateid=plateid
   full= yanny_readone(fullfile)
endif

platescale = get_platescale('APO') 

if(n_tags(holes) eq 0 OR n_tags(full) eq 0) then begin
   msg='Could not find plPlugMapP or plateHolesSorted file for '+ $
       strtrim(string(plateid),2)
   if(keyword_set(diesoft) eq 0) then $
      message, msg
   splog, msg
   return
endif

;; if desired, rearrange BOSS fibers
if(keyword_set(rearrange) ne 0) then $
   platelines_rearrange, full, holes
      
;; basic versions
versions=['', 'sky', 'std']

;; z-offset values
zoffstr=strtrim(string((uniqtag(full, 'zoffset')).zoffset, f='(i)'),2)
inot=where(zoffstr ne '0', nnot)
if(nnot gt 0) then $
   versions=[versions, 'zoffset-'+zoffstr[inot]] $
else $
   versions=[versions, 'zoffset-none']

;; make various block colors
colors= ['red', 'green', 'blue', 'magenta', 'brown']
versions= [versions, 'block-'+colors]

;; skip creation if no actual object holes
iany= where(-holes.fiberid ge 0 and -holes.fiberid le nblocks*nper, nany)
if(nany eq 0) then begin
   versions=['']
   splog, 'No actual object holes!'
endif

for k=0L, n_elements(versions)-1L do begin
   
   version=versions[k]

   postfix=''
   if(keyword_set(version)) then $
      postfix='-'+version

   filebase= platedir+'/plateLines-'+strtrim(string(f='(i6.6)',plateid),2)+ $
             postfix
   
   connect_thick=3
   circle_thick=2
   
   if(keyword_set(version) gt 0 AND $
      strmatch(version, 'block-*') eq 0) then $
         connect_thick=1

   nolines=0
   if(strmatch(version, 'zoffset-*') gt 0) then $
      nolines=1

   label='BOSS fibers'
   if(keyword_set(version)) then $
      label=label+' ('+version+')'
   note=''
   platelines_start, plateid, filebase, label, note=note
   
   ;; set buffer for lines, and circle size
   ;; (48 and 45 arcsec respectively
   buffer= 48./3600. * platescale
   circle= 45./3600. * platescale

   if(version eq 'zoffset-none') then begin
      djs_xyouts, -200., 0., 'No washers for this plate!', charsize=2.
      platelines_end
      continue
   endif
   
   ;; set colors of each brightness fiber
   for i=0L, nblocks-1L do begin
      ii= where(-holes.fiberid ge i*nper+1L and $
                -holes.fiberid le (i+1L)*nper and $
                ((full.holetype eq 'BOSS_APOGEE') or $
                 (full.holetype eq 'BOSS')), nii)
      if(nii eq nper) then begin
         isort= lindgen(nii)
         if(keyword_set(sorty)) then $
            isort= sort(holes[ii].yfocal)
         color= colors[i mod n_elements(colors)]
         
         bluefiber= lonarr(nii)
         iblue=where(full[ii].bluefiber gt 0, nblue)
         if(nblue gt nperblue) then begin
            iblue= iblue[shuffle_indx(nblue, num_sub=nperblue, $
                                      seed=plateid+i)]
         endif
         if(nblue lt nperblue) then begin
            ired= where(full[ii].bluefiber eq 0, nred)
            ish= shuffle_indx(nred, num_sub=nperblue-nblue, $
                              seed=plateid+i)
            if(nblue eq 0) then $
               iblue = ired[ish] $
            else $
               iblue= [iblue, ired[ish]]
         endif
         if(n_elements(iblue) ne nperblue) then $
            message, 'Inconsistency in iblue!'
         nblue=nperblue
         bluefiber[iblue]=1
         
         ;; connect lines
         doblock=1
         if (strmatch(version,'block-*') gt 0) then begin
            colorval= (strsplit(version, '-', /extr))[1]
            if(colorval ne color) then $
               doblock=0
         endif
         if(keyword_set(nolines) eq 0 AND $
            doblock gt 0) then begin
            for j=0L, nper-2L do begin
               xhole1= holes[ii[isort[j]]].xfocal
               xhole2= holes[ii[isort[j+1]]].xfocal
               yhole1= holes[ii[isort[j]]].yfocal
               yhole2= holes[ii[isort[j+1]]].yfocal
               length= sqrt((xhole2-xhole1)^2+(yhole2-yhole1)^2)
               sbuffer=buffer 
               ebuffer=(length-buffer) 
               if(ebuffer gt sbuffer) then begin
                  xdir= (xhole2-xhole1)/length
                  ydir= (yhole2-yhole1)/length
                  xstart= (xhole1+sbuffer*xdir) 
                  ystart= (yhole1+sbuffer*ydir) 
                  xend= (xhole1+ebuffer*xdir) 
                  yend= (yhole1+ebuffer*ydir) 
                  djs_oplot, [ystart, yend], [xstart, xend], $
                             th=connect_thick, color=color
               endif
            endfor
         endif
         
         ;; draw holes; 
         for j=0L, nper-1L do begin
            theta= findgen(100)/float(99.)*!DPI*2.
            xcurr= holes[ii[j]].xfocal+ circle* cos(theta)
            ycurr= holes[ii[j]].yfocal+ circle* sin(theta)
            ncirc=1L
            if(version eq 'sky') then begin
               ;; SKY as thick RED, 
               ;; any other as thin black
               case strupcase(holes[ii[j]].objtype) of
                  'SKY': begin
                     currcolor='red'
                     currthick=4
                  end
                  else: begin 
                     currcolor='black'
                     currthick=1
                  end
               endcase
            endif else if (version eq 'std') then begin
               ;; standard as thick blue
               ;; any other as thin black
               case strupcase(holes[ii[j]].objtype) of
                  'SPECTROPHOTO_STD': begin
                     currcolor='blue'
                     currthick=4
                  end
                  else: begin 
                     currcolor='black'
                     currthick=1
                  end
               endcase
            endif else if (strmatch(version,'zoffset-*') gt 0 and $
                           version ne 'zoffset-none') then begin
               
               zoffval= float((strsplit(version, '-', /extr))[1])
               
               ;; standard as thick blue
               ;; any other as thin black
               if(full[ii[j]].zoffset ne zoffval) then begin
                  currcolor='black'
                  currthick=1
               endif else begin
                  case zoffval of
                     100: begin
                        currcolor='magenta'
                        currthick=2
                        ncirc=2
                     end
                     175: begin
                        currcolor='magenta'
                        currthick=2
                        ncirc=3
                     end
                     300: begin
                        currcolor='magenta'
                        currthick=2
                        ncirc=4
                     end
                     else: begin 
                        splog, 'Unexpected ZOFFSET value '+ $
                               strtrim(string(full[ii[j]].zoffset),2)
                        currcolor='red'
                        currthick=10
                     end
                  endcase
               endelse
            endif else begin
               ;; normally should color according to blue fiber
               currthick=circle_thick
               if(bluefiber[j] gt 0) then begin
                  currcolor='blue'
               endif else begin
                  currcolor='red'
               endelse
               currthick=circle_thick
               
               if (strmatch(version,'block-*') gt 0) then begin
                  colorval= (strsplit(version, '-', /extr))[1]
                  if(colorval ne color) then begin
                     currcolor='black'
                     currthick=1
                  endif
               endif
            endelse
            djs_oplot, ycurr, xcurr, color=currcolor, th=currthick
            for l=1L, ncirc-1L do begin
               scale=l*0.3+1.
               xcurr= holes[ii[j]].xfocal+ scale*circle* cos(theta)
               ycurr= holes[ii[j]].yfocal+ scale*circle* sin(theta)
               djs_oplot, ycurr, xcurr, color=currcolor, th=1
            endfor
         endfor
      endif else begin
         ii= where(-holes.fiberid ge 1L and $
                   -holes.fiberid le nper*nblocks, nii)
         if(nii gt 0) then $
            message, 'Not the right number of holes for this block!'
      endelse
   endfor
   
   platelines_end
endfor

platelines_guide, plateid, holes, full, hdrstr

return
end
