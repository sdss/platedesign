;+
; NAME:
;   platelines_apogee2s_test
; PURPOSE:
;   write plateLines-????.ps file for a APOGEE2-MANGA or MANGA-APOGEE2 plate
; CALLING SEQUENCE:
;   platelines_apogee2s_test, plateid 
; INPUTS:
;   plateid - plate ID to run on
; COMMENTS:
;   Appropriate for APOGEE data
;   Makes a PostScript file 26.7717 by 26.7717 inches; mapping
;    should be one-to-one onto plate (x and y ranges are from -340 to
;    +340 mm).
;   Circles are 80 arcsec radius. 
;   APOGEE rules:
;    * Colors of circles are blue for 8 faintest stars in block, green
;      for the 6 next brightest, and red for the 6 brightest
;   MANGA rules:
; BUGS:
;   Works off the plPlugMapP file, so may be fragile.
; REVISION HISTORY:
;   22-Aug-2008  MRB, NYU
;    1-Sep-2010  Demitri Muna, NYU, Adding file test before opening files.
;-
;------------------------------------------------------------------------------
function platelines_apogee2s_test_manga_hole_color, targettype, fiberid

common com_pla, plateid, full, holes, hdr, hdrstr, apogee_blocks
  
if(strupcase(targettype) eq 'SKY') then $
   color='blue'
if(strmid(strupcase(targettype),0,8) eq 'STANDARD') then $
   color='red'

;; should color according to fiber type
ib= where(apogee_blocks.fiberid eq fiberid, nb)
if(nb eq 0) then $
   message, 'Unknown fiber!'
if(nb gt 1) then $
   message, 'Duplicate fiber in blocks!'
curr_ftype= apogee_blocks[ib[0]].ftype 
if(curr_ftype eq 'B') then $
   color='red'
if(curr_ftype eq 'M') then $
   color='green'
if(curr_ftype eq 'F') then $
   color='blue'

return, color
  
end
;
pro platelines_apogee2s_test, in_plateid, project=project

common com_pla


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

;; Read in plate information
if(n_tags(holes) eq 0) then begin
    plplug= platedir+'/plPlugMapH-'+ $
      strtrim(string(f='(i4.4)',plateid),2)+'.par'
    if(NOT file_test(plplug)) then $
      plplug= platedir+'/plPlugMapP-'+ $
      strtrim(string(f='(i4.4)',plateid),2)+'.par'
    check_file_exists, plplug, plateid=plateid
    holes= yanny_readone(plplug, hdr=hdr)
    hdrstr= lines2struct(hdr)
    
    fullfile= platedir+'/plateHolesSorted-'+ $
      strtrim(string(f='(i6.6)',plateid),2)+'.par'
    check_file_exists, fullfile, plateid=plateid
    full= yanny_readone(fullfile)
endif

itag=tag_indx(hdrstr,'OBSERVATORY')
if(itag eq -1) then $
  platescale = get_platescale('APO') $
else $
  platescale = get_platescale(hdrstr.(itag))

connect_thick=3
circle_thick=3
trap_thick=1
     
;; set buffer for lines, and circle size
buffer= 80./3600. * platescale
circle= 75./3600. * platescale
guide_circle= 120./3600. * platescale
white_circle= 60./3600. * platescale

if(n_tags(holes) eq 0 OR n_tags(full) eq 0) then begin
    msg='Could not find plPlugMapP or plateHolesSorted file for '+ $
      strtrim(string(plateid),2)
    if(keyword_set(diesoft) eq 0) then $
      message, msg
    splog, msg
    return
endif

;;  Start lines postscript
filebase= platedir+'/plateLines-'+strtrim(string(f='(i6.6)',plateid),2)+ $
  '-all'
if(NOT keyword_set(project)) then $
   platelines_print_start, plateid, filebase, 'APOGEE', note=note $
else $
   platelines_start, plateid, filebase+'-project', 'APOGEE', note=note 

isci= where(strupcase(strtrim(full.holetype,2)) eq 'APOGEE', nsci)
if(nsci eq 0) then return
  
;; make various block colors
colors= ['red', 'green', 'blue', 'magenta', 'cyan']

apogee_full_blockfile=getenv('PLATEDESIGN_DIR')+ $
                      '/data/apogee/fiberBlocksAPOGEE.par'
apogee_blocks= yanny_readone(apogee_full_blockfile)
     
;; set colors of each brightness fiber
nblocks=50L
nper=6L
for i=0L, nblocks-1L do begin
   ii= where(-holes[isci].fiberid ge i*nper+1L and $
             -holes[isci].fiberid le (i+1L)*nper, nii)
   
   ;; connect the lines
   if(nii gt 0) then begin
      isort= sort(holes[isci[ii]].yfocal) 
      color= colors[i mod n_elements(colors)]
      
      ;; connect lines
      platelines_connect, holes[isci[ii[isort]]].xfocal, $
                          holes[isci[ii[isort]]].yfocal, $
                          buffer=buffer, thick=connect_thick, $
                          color=color
   endif
   
   ;; draw holes
   for j=0L, nii-1L do begin
      current_hole= full[isci[ii[j]]]
      color=platelines_apogee2s_test_hole_color(current_hole.targettype, $
                                                current_hole.fiberid)
      platelines_circle, current_hole.xfocal, current_hole.yfocal, $
                         circle, color=color
   endfor
endfor

;; Draw traps
ii= where(holes.holetype eq 'LIGHT_TRAP', nii)
color='purple'
platelines_circle, holes[ii].xfocal, holes[ii].yfocal, circle, $
                   color=color, thick=trap_thick

;; Draw guides
gfibertype= 'gfiber'
if(tag_indx(hdrstr, 'gfibertype') ne -1) then $
  gfibertype= hdrstr.gfibertype
gfiber= call_function(gfibertype+'_params')

iguide= where(holes.holetype eq 'GUIDE', ngstar)
platelines_circle, holes[iguide].xfocal, holes[iguide].yfocal, $
                   guide_circle, color='black', th=circle_thick

;; red X if bad guy
for i=0L, ngstar-1L do begin
   if(holes[iguide[i]].fiberid le 0) then begin
      djs_oplot, [holes[iguide[i]].yfocal], [holes[iguide[i]].xfocal], $
                 color='red', th=3, symsize=1.5, psym=2
   endif else begin
      
      ;; draw path to alignment
      ialign= where(holes.holetype eq 'ALIGNMENT' AND $
                    holes.fiberid eq holes[iguide[i]].fiberid, nalign)
      if(nalign eq 0) then $
         message, 'No alignment hole!'
      if(nalign gt 1) then $
         message, 'More than one alignment hole!'
      dx= holes[ialign].xfocal- holes[iguide[i]].xfocal
      dy= holes[ialign].yfocal- holes[iguide[i]].yfocal
      djs_oplot, holes[iguide[i]].yfocal+[0., dy]*3., $
                 holes[iguide[i]].xfocal+[0., dx]*3., th=2
      
      ;; draw path to anchor block
      ig=where(gfiber.guidenum eq holes[iguide[i]].fiberid, ng)
      if(ng eq 0) then $
         message, 'No location for guide anchor!'
      if(nalign gt 1) then $
         message, 'More than one location for guide anchor!'
      djs_oplot, [gfiber[ig].yreach], [gfiber[ig].xreach], psym=1, $
                 color='red'
      djs_oplot, [gfiber[ig].yreach, holes[iguide[i]].yfocal], $
                 [gfiber[ig].xreach, holes[iguide[i]].xfocal], $
                 linest=1, color='red'
      if(tag_indx(gfiber, 'guidetype') ne -1) then $
         djs_xyouts, [gfiber[ig].yreach+5.*buffer], [gfiber[ig].xreach], $
                     gfiber[ig].guidetype, align=0.5, color='red'
      
   endelse
endfor

;; whiteout all holes
platelines_circlefill, holes.xfocal, holes.yfocal, white_circle, color='white'

;; test with thin black line
;platelines_circle, holes.xfocal, holes.yfocal, white_circle, color='black', $
  ;th=1

   
if(NOT keyword_set(project)) then $
   platelines_print_end $
else $
   platelines_end

return
end
