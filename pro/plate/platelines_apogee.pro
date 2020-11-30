;+
; NAME:
;   platelines_apogee
; PURPOSE:
;   write the plateLines-????.ps file for a APOGEE plate
; CALLING SEQUENCE:
;   platelines_apogee, plateid [, /sky, /std, /relaxed ]
; INPUTS:
;   plateid - plate ID to run on
; OPTIONAL KEYWORDS:
;   /relaxed - reassign fiberid #s using relaxed constraints
; COMMENTS:
;   Appropriate for APOGEE data
;   Makes a PostScript file 26.7717 by 26.7717 inches; mapping
;    should be one-to-one onto plate (x and y ranges are from -340 to
;    +340 mm).
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
pro set_blockcen_apogee_shared_lines, full, fiberblocks, fiberid, blockcenx, $
                                      blockceny

  platescale = get_platescale('APO')

  ;; now find the center location for each block, and limits in
  ;; y-direction of targets
  bnums= (uniqtag(fiberblocks, 'blockid')).blockid
  for i=0L, n_elements(bnums)-1L do begin
     ib= where(fiberblocks[fiberid-1].blockid eq bnums[i], nb)
     if(nb gt 0) then begin
        blockcenx[bnums[i]-1]= mean(full[ib].xf_default)/platescale
        blockceny[bnums[i]-1]= mean(full[ib].yf_default)/platescale
     endif 
  endfor
end
;
pro platelines_apogee_rearrange, full, holes, blockfile=blockfile, $
  blockname=blockname, stretch=stretch, blocks=blocks

  if(n_elements(stretch) eq 0) then $
     stretch=0.
  if(n_elements(blockname) eq 0) then $
     blockname='APOGEE'
  if(n_elements(blockfile) eq 0) then $
     blockfile = getenv('PLATEDESIGN_DIR')+'/data/boss/fiberBlocks'+ $
                 blockname+'.par'

  platescale = get_platescale('APO')
  nperblock=6L

  iapogee= where(strupcase(full.holetype) eq 'APOGEE' or $
                 strupcase(full.holetype) eq 'APOGEE_SHARED', napogee)
  if(keyword_set(blocks)) then begin
     toblock=blocks[iapogee]
  endif
  fiberblocks= yanny_readone(blockfile, /anon)
  fiberblocks.fiberid = lindgen(n_elements(fiberblocks)) + 1L
  if(napogee ne n_elements(fiberblocks)) then $
     message, 'Not the right number of APOGEE fibers?'
  nblocks=max(fiberblocks.blockid)
  blockcenx= fltarr(nblocks)
  blockceny= fltarr(nblocks)
  for i=1L, nblocks do begin
     ib= where(fiberblocks.blockid eq i, nb)
     blockcenx[i-1]= mean(fiberblocks[ib].fibercenx)
     blockceny[i-1]= mean(fiberblocks[ib].fiberceny)
  endfor

  maxiter=7L
  for iter=0L, maxiter-1L do begin
     sdss_plugprob, full[iapogee].xf_default, $
                    full[iapogee].yf_default, $
                    tmp_fiberid, $
                    reachfunc='boss_reachcheck', $
                    blockfile=blockfile, maxinblock=6, $
                    minavail=0, stretch=stretch, $
                    blockcenx=blockcenx, blockceny=blockceny, $
                    toblock=toblock
     
     if(min(tmp_fiberid) lt 1) then $
        message, 'Some fibers unassigned'
     
     full[iapogee].fiberid= tmp_fiberid
     holes[iapogee].fiberid= -tmp_fiberid
     
     set_blockcen_apogee_shared_lines, full[iapogee], fiberblocks, $
                                       tmp_fiberid, blockcenx, blockceny
  endfor

end
;
pro platelines_apogee, in_plateid, diesoft=diesoft, sorty=sorty, relaxed=relaxed, $
                       blockname=blockname, rearrange=rearrange, stretch=stretch, blocks=blocks

  common com_pla, plateid, full, holes, hdr, hdrstr

  if(NOT keyword_set(in_plateid)) then $
     message, 'Plate ID must be given!'
  if(NOT keyword_set(blockname)) then $
     blockname = 'APOGEE'
  if(NOT keyword_set(stretch)) then $
     stretch = 0.

  if(keyword_set(plateid) gt 0) then begin
     if(plateid ne in_plateid) then begin
        plateid= in_plateid
        full=0
        holes=0
     endif
  endif else begin
     plateid=in_plateid
  endelse

  full_blockfile=getenv('PLATEDESIGN_DIR')+'/data/apogee/fiberBlocks'+blockname+'.par'
  fiberblocks= yanny_readone(full_blockfile)
  fiberblocks.fiberid = lindgen(n_elements(fiberblocks)) + 1L

  platedir= plate_dir(plateid)

  if(n_tags(holes) eq 0) then begin
      plplug= platedir+'/plPlugMapH-'+ $
        strtrim(string(plateid),2)+'.par'
      if(NOT file_test(plplug)) then $
        plplug= platedir+'/plPlugMapP-'+ $
        strtrim(string(plateid),2)+'.par'
      check_file_exists, plplug, plateid=plateid
      holes= yanny_readone(plplug, hdr=hdr)
      hdrstr= lines2struct(hdr)
      
      fullfile= platedir+'/'+plateholes_filename(plateid=plateid, /sorted)
      check_file_exists, fullfile, plateid=plateid
      full= yanny_readone(fullfile)
      
  endif
  
  itag=tag_indx(hdrstr,'OBSERVATORY')
  if(itag eq -1) then $
    observatory = 'APO' $
  else $
    observatory = hdrstr.(itag)
  platescale = get_platescale(observatory)
  
  isci= where(strupcase(strtrim(full.holetype,2)) eq 'APOGEE' OR $
              strupcase(strtrim(full.holetype,2)) eq 'APOGEE_SHARED', nsci)

  if(keyword_set(relaxed) ne 0 and nsci gt 0) then begin
      plug= yanny_readone(plplug, hdr=hdr)
      default= lines2struct(hdr, /relaxed)
      if(tag_indx(default, 'relaxed_fiber_classes') eq -1) then $
        default=create_struct(default, 'relaxed_fiber_classes', 1L)
      default.relaxed_fiber_classes=1L
      ifix= where(strmatch(strupcase(full[isci].targettype), 'SCIENCE*'), nfix)
      if(nfix gt 0) then $
        full[isci[ifix]].targettype='SCIENCE'
      ifix= where(strmatch(strupcase(full[isci].targettype), 'STANDARD*'), nfix)
      if(nfix gt 0) then $
        full[isci[ifix]].targettype='STANDARD'
      fiberid= fiberid_apogee(default, fibercount, full[isci])
      full[isci].fiberid= fiberid
      holes[isci].fiberid= -fiberid
  endif

  if(n_tags(holes) eq 0 OR n_tags(full) eq 0) then begin
     msg='Could not find plPlugMapP or plateHolesSorted file for '+ $
         strtrim(string(plateid),2)
     if(keyword_set(diesoft) eq 0) then $
        message, msg
     splog, msg
     return
  endif

;; if desired, rearrange APOGEE fibers
if(keyword_set(rearrange) ne 0) then $
   platelines_apogee_rearrange, full, holes, blockfile=full_blockfile, $
                                stretch=stretch, blocks=blocks
  
;; basic versions
  versions=['apogee', 'apogee.sky', 'apogee.std', 'traps']

;; make various block colors
  colors= ['red', 'green', 'blue', 'magenta', 'cyan']
  versions= [versions, 'apogee.block-'+colors]

  for k=0L, n_elements(versions)-1L do begin
     
     version=versions[k]

     postfix=''
     if(keyword_set(version)) then $
        postfix='-'+version

     filebase= platedir+'/plateLines-'+strtrim(string(f='(i6.6)',plateid),2)+ $
               postfix
     
     connect_thick=3
     circle_thick=2
     
     if(version ne 'apogee' AND $
        (strmatch(version, 'apogee.block-*') eq 0 OR $
         strmatch(version, 'traps') ne 0)) then $
           connect_thick=1

     label='APOGEE fibers'
     if(version ne 'apogee') then $
        label=label+' ('+version+')'
     note=''
     platelines_start, plateid, filebase, label, note=note, observatory=observatory
     
     ;; set buffer for lines, and circle size
     ;; (48 and 45 arcsec respectively
     buffer= 48./3600. * platescale
     circle= 45./3600. * platescale
     
     ;; set colors of each brightness fiber
     if(nsci gt 0) then begin
         nblocks=50L
         nper=6L
         for i=0L, nblocks-1L do begin
             ii= where(-holes[isci].fiberid ge i*nper+1L and $
                       -holes[isci].fiberid le (i+1L)*nper, nii)
             if(nii gt 0) then begin
                 if(keyword_set(sorty)) then $
                   isort= sort(holes[isci[ii]].yfocal) $
                 else $
                   isort= sort(-holes[isci[ii]].fiberid) 
                 color= colors[i mod n_elements(colors)]
                 
                 ;; connect lines
                 doblock=1
                 if (strmatch(version,'apogee.block-*') gt 0) then begin
                     colorval= (strsplit(version, '-', /extr))[1]
                     if(colorval ne color) then $
                       doblock=0
                 endif
                 if (strmatch(version,'traps') ne 0) then begin
                     doblock=0
                 endif
                 if(doblock gt 0) then begin
                     for j=0L, (nper-2L) do begin
                         xhole1= holes[isci[ii[isort[j]]]].xfocal
                         xhole2= holes[isci[ii[isort[j+1]]]].xfocal
                         yhole1= holes[isci[ii[isort[j]]]].yfocal
                         yhole2= holes[isci[ii[isort[j+1]]]].yfocal
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
                 for j=0L, (nper-1L) do begin
                     theta= findgen(100)/float(99.)*!DPI*2.
                     xcurr= holes[isci[ii[j]]].xfocal+ circle* cos(theta)
                     ycurr= holes[isci[ii[j]]].yfocal+ circle* sin(theta)
                     ncirc=1L
                     if(version eq 'apogee.sky') then begin
                         ;; SKY as thick RED, 
                         ;; any other as thin black
                         case strupcase(full[isci[ii[j]]].targettype) of
                             'SKY': begin
                                 currcolor='blue'
                                 currthick=4
                                 end
                             else: begin 
                                 currcolor='black'
                                 currthick=1
                             end
                         endcase
                     endif else if (version eq 'apogee.std') then begin
                         ;; standard as thick blue
                         ;; any other as thin black
                         case strmid(strupcase(full[isci[ii[j]]].targettype),0,8) of
                             'STANDARD': begin
                                 currcolor='red'
                                 currthick=4
                                 end
                             else: begin 
                                 currcolor='black'
                                 currthick=1
                             end
                         endcase
                     endif else if (version eq 'traps') then begin
                         currcolor='black'
                         currthick=1
                     endif else begin
                         ;; should color according to fiber type
                         currthick=circle_thick
                         currthick=circle_thick
                         ib= where(fiberblocks.fiberid eq abs(holes[isci[ii[j]]].fiberid), nb)
                         if(nb eq 0) then $
                           message, 'Unknown fiber!'
                         if(nb gt 1) then $
                           message, 'Duplicate fiber in blocks!'
                         curr_ftype= fiberblocks[ib[0]].ftype 
                         if(curr_ftype eq 'B') then $
                           currcolor='red'
                         if(curr_ftype eq 'M') then $
                           currcolor='green'
                         if(curr_ftype eq 'F') then $
                           currcolor='blue'
                         
                         if (strmatch(version,'apogee.block-*') gt 0) then begin
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
                         xcurr= holes[isci[ii[j]]].xfocal+ scale*circle* cos(theta)
                         ycurr= holes[isci[ii[j]]].yfocal+ scale*circle* sin(theta)
                         djs_oplot, ycurr, xcurr, color=currcolor, th=1
                     endfor
                 endfor
             endif
         endfor 
     endif

     ;; draw traps in traps case
     if(version eq 'traps') then begin
        ii= where(holes.holetype eq 'LIGHT_TRAP', nii)
        for j=0L, nii-1L do begin
           currcolor='purple'
           currthick=4
           theta= findgen(100)/float(99.)*!DPI*2.
           xcurr= holes[ii[j]].xfocal+ circle* cos(theta)
           ycurr= holes[ii[j]].yfocal+ circle* sin(theta)
           djs_oplot, ycurr, xcurr, color=currcolor, th=currthick
        endfor
     endif
     
     platelines_end
  endfor

  blocks = lonarr(n_elements(full))
  for i = 0L, n_elements(full) - 1L do begin
     if(strupcase(full[i].holetype) eq 'APOGEE' or $
        strupcase(full[i].holetype) eq 'APOGEE_SHARED') then begin
        ib = where(fiberblocks.fiberid eq full[i].fiberid)
        blocks[i] = fiberblocks[ib[0]].blockid
     endif
  endfor

  return
end
