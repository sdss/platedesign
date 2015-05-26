;+
; NAME:
;   platelines_guidetest
; PURPOSE:
;   write the plateLines-????.ps file for guides for APOGEE-South test
; CALLING SEQUENCE:
;   platelines_guide, plateid 
; INPUTS:
;   plateid - plate ID to run on 
; REVISION HISTORY:
;   22-Aug-2008  MRB, NYU
;    1-Sep-2010  Demitri Muna, NYU, Adding file test before opening files.
;   27-Apr-2015  MRB, NYU
;-
;------------------------------------------------------------------------------
pro platelines_guidetest, plateid, holes, full, hdrstr

platedir= plate_dir(plateid)

if(n_tags(holes) eq 0 OR n_tags(hdrstr) eq 0 or n_tags(full) eq 0) then begin
    plplug= platedir+'/plPlugMapP-'+ $
      strtrim(string(f='(i4.4)',plateid),2)+'.par'
    if(NOT file_test(plplug)) then $
      plplug= platedir+'/plPlugMapH-'+ $
      strtrim(string(f='(i4.4)',plateid),2)+'.par'
    check_file_exists, plplug, plateid=plateid
    holes= yanny_readone(plplug, hdr=hdr)
    hdrstr= lines2struct(hdr, /relaxed)
    
    fullfile= platedir+'/'+plateholes_filename(plateid=plateid, /sorted)
    check_file_exists, fullfile, plateid=plateid 
    full= yanny_readone(fullfile)
endif

itag=tag_indx(hdrstr,'OBSERVATORY')
if(itag eq -1) then $
  platescale = get_platescale('APO') $
else $
  platescale = get_platescale(hdrstr.(itag))

gfibertype= 'gfiber'
if(tag_indx(hdrstr, 'gfibertype') ne -1) then $
  gfibertype= hdrstr.gfibertype
gfiber= call_function(gfibertype+'_params')

if(n_tags(holes) eq 0) then begin
    msg='Could not find plPlugMapP file for '+ $
      strtrim(string(plateid),2)
    if(keyword_set(diesoft) eq 0) then $
      message, msg
    splog, msg
    return
endif

circle= 45./3600. * platescale
buffer= 48./3600. * platescale
connect_thick= 2

filebase= platedir+'/plateLines-'+strtrim(string(f='(i6.6)',plateid),2)+ $
          '-guide'

noguide=lonarr(n_elements(gfiber))
for i=0L, n_elements(gfiber)-1L do begin
    ii=where(holes.holetype eq 'GUIDE' AND $
             holes.fiberid eq gfiber[i].guidenum, nii)
    if(nii eq 0) then $
      noguide[i]=1
endfor
inone=where(noguide gt 0, nnone)
note=''
if(nnone gt 0) then begin
    note= 'No star for guide #'
    for i=0L, nnone-2L do $
          note=note+strtrim(string(gfiber[inone[i]].guidenum),2)+','
    note=note+strtrim(string(gfiber[inone[nnone-1]].guidenum),2)
endif

pointing_name= ['A', 'B', 'C', 'D', 'E', 'F']
if(tag_indx(hdrstr, 'pointing_name') ne -1) then $
  pointing_name= strsplit(hdrstr.pointing_name, /extr)

platelines_start, plateid, filebase, 'guide fibers', note=note

;; write magnitudes (in yellow and first so they don't
;; interfere
;; for i=0L, ngstar-1L do begin
;; magstr= strtrim(string(f='(f40.2)', holes[iguide[i]].mag[1]),2)
;; djs_xyouts, holes[iguide[i]].yfocal+5.*buffer, $
;; holes[iguide[i]].xfocal-1.5*buffer, $
;; '(g='+magstr+')', align=0., charsize=0.4, $
;; color='yellow'
;; endfor

;; finally, draw guides
iguide= where(holes.holetype eq 'GUIDE', ngstar)

nguide=16L
nper=3L
holecolors= ['green', 'blue', 'magenta']
connect_colors= ['black', 'brown', 'red']

if(nper*nguide*hdrstr.npointings ne ngstar) then $
  message, 'Bad number of guide stars'

for pointing=1L, hdrstr.npointings do begin
    iguide_all= where(holes.holetype eq 'GUIDE' and $
                      full.pointing eq pointing, nstars)
    for guidenum=1L, nguide do begin
        iguide= iguide_all[where(gfiber[holes[iguide_all].fiberid-1].block $
                                 eq guidenum, ncurr)]

        isort=sort(holes[iguide].yfocal)
        iguide=iguide[isort]

        if(ncurr ne nper) then $
          message, 'Bad number of options per pointing per guide fiber'
        for i=0L, nper-1L do begin
            theta= findgen(100)/float(99.)*!DPI*2.
            xcurr= holes[iguide[i]].xfocal+ circle* cos(theta)
            ycurr= holes[iguide[i]].yfocal+ circle* sin(theta)
            djs_oplot, ycurr, xcurr, color=holecolors[i], th=circle_thick
        endfor

        for i=0L, (nper-2L) do begin
            xhole1= holes[iguide[i]].xfocal
            xhole2= holes[iguide[i+1]].xfocal
            yhole1= holes[iguide[i]].yfocal
            yhole2= holes[iguide[i+1]].yfocal
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
                  th=connect_thick, color=connect_colors[pointing-1]
            endif
        endfor

        label=strtrim(string(gfiber[holes[iguide[0]].fiberid-1].block),2)
        if(long(hdrstr.npointings) gt 1 OR $
           pointing_name[0] ne 'A') then $
          label= label+ pointing_name[full[iguide[0]].pointing-1]
        djs_xyouts, holes[iguide[0]].yfocal-5.*buffer, $
          holes[iguide[0]].xfocal, $
          label, align=0.5, charsize= 0.6, color=connect_colors[pointing-1]
    endfor
endfor 

platelines_end

return
end
