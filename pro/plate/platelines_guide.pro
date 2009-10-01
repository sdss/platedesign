;+
; NAME:
;   platelines_guide
; PURPOSE:
;   write the plateLines-????.ps file for guides
; CALLING SEQUENCE:
;   platelines_guide, plateid 
; INPUTS:
;   plateid - plate ID to run on 
; REVISION HISTORY:
;   22-Aug-2008  MRB, NYU
;-
;------------------------------------------------------------------------------
pro platelines_guide, plateid, holes, full, hdrstr

platescale = 217.7358D           ; mm/degree

platedir= plate_dir(plateid)

if(n_tags(holes) eq 0 OR n_tags(hdrstr) eq 0 or n_tags(full) eq 0) then begin
    plplug= platedir+'/plPlugMapP-'+ $
      strtrim(string(f='(i4.4)',plateid),2)+'.par'
    holes= yanny_readone(plplug, hdr=hdr)
    hdrstr= lines2struct(hdr, /relaxed)

    fullfile= platedir+'/plateHolesSorted-'+ $
      strtrim(string(f='(i6.6)',plateid),2)+'.par'
    full= yanny_readone(fullfile)
endif

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
iguide= where(holes.holetype eq 'GUIDE')
for i=0L, n_elements(gfiber)-1L do begin
    magstr= strtrim(string(f='(f40.2)', holes[iguide[i]].mag[1]),2)
    djs_xyouts, holes[iguide[i]].yfocal+5.*buffer, $
      holes[iguide[i]].xfocal-1.5*buffer, $
      '(g='+magstr+')', align=0., charsize=0.4, $
      color='yellow'
endfor

;; finally, draw guides
for i=0L, n_elements(gfiber)-1L do begin
    theta= findgen(100)/float(99.)*!DPI*2.
    xcurr= holes[iguide[i]].xfocal+ circle* cos(theta)
    ycurr= holes[iguide[i]].yfocal+ circle* sin(theta)
    djs_oplot, ycurr, xcurr, color='black', th=circle_thick

    label=strtrim(string(holes[iguide[i]].fiberid),2)
    if(long(hdrstr.npointings) gt 1 OR $
       pointing_name[0] ne 'A') then $
      label= label+ pointing_name[full[iguide[i]].pointing-1]
    djs_xyouts, holes[iguide[i]].yfocal+5.*buffer, $
                holes[iguide[i]].xfocal, $
                label, align=0.5

    ;; red X if bad guy
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
          [gfiber[ig].xreach, holes[iguide[i]].xfocal], linest=1, color='red'
        if(tag_indx(gfiber, 'guidetype') ne -1) then $
          djs_xyouts, [gfiber[ig].yreach+5.*buffer], [gfiber[ig].xreach], $
          gfiber[ig].guidetype, align=0.5, color='red'

    endelse

endfor

;; plot unused guide anchor blocks
for j=0L, nnone-1L do begin
    djs_oplot, [gfiber[inone[j]].yreach], [gfiber[inone[j]].xreach], $
      psym=1, color='red'
    if(tag_indx(gfiber, 'guidetype') ne -1) then $
      djs_xyouts, [gfiber[inone[j]].yreach+5.*buffer], $
      [gfiber[inone[j]].xreach], gfiber[inone[j]].guidetype, align=0.5, $
      color='red'
endfor

platelines_end

return
end
