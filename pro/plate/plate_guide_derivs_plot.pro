;+
; NAME:
;   plate_guide_derivs_plot
; PURPOSE:
;   Plot guide derivatives as a function of HA
; CALLING SEQUENCE:
;   plate_guide_derivs_plot, plateid [, pointing, guideon= ]
; INPUTS:
;   plateid - plate number
; OPTIONAL INPUTS:
;   pointing - pointing number
;   guideon - wavelength to guide on in Angstroms (default 5400.)
; COMMENTS:
;   Reads data from 
;    - plateGuideOffsets-XXXXXX-pP-lGUIDEON.par
;   Makes the following plots:
;    - plateGuide-XXXXXX-pP-lGUIDEON.png: paths of objects as a function of HA
;    - plateGuideCorrections-pP-lGUIDEON.png: corrections assumed 
; REVISION HISTORY:
;   10-Jun-2008  MRB, NYU
;-
pro plate_guide_derivs_plot, plateid, pointing, guideon=guideon

if(NOT keyword_set(guideon)) then guideon=5400.
if(NOT keyword_set(pointing)) then pointing=1L
offset=0L

platedir= plate_dir(plateid)

if(n_tags(hdrstr) eq 0) then begin
   plplug= platedir+'/plPlugMapP-'+ $
           strtrim(string(plateid),2)+'.par'
   if(NOT file_test(plplug)) then $
      plplug= platedir+'/plPlugMapH-'+ $
              strtrim(string(plateid),2)+'.par'
   check_file_exists, plplug, plateid=plateid
   holes= yanny_readone(plplug, hdr=hdr)
   hdrstr= lines2struct(hdr, /relaxed)
endif

itag=tag_indx(hdrstr,'OBSERVATORY')
if(itag eq -1) then $
  observatory = 'APO' $
else $
  observatory = hdrstr.(itag)

post=string(f='(i6.6)', plateid)+ $
     '-p'+strtrim(string(pointing),2)+ $
     '-l'+strtrim(string(guideon, f='(i5.5)'),2)
off= yanny_readone(platedir+'/plateGuideOffsets-'+post+'.par')
adjust= yanny_readone(platedir+'/plateGuideAdjust-'+post+'.par')

nha=n_elements(adjust)
label = 'offsets (\DeltaHA= '+strtrim(string(adjust[0].delha, f='(i)'),2)+ $
        ' to '+strtrim(string(adjust[nha-1].delha, f='(i)'),2)+')'
platelines_start, plateid, platedir+'/plateGuide-'+post, label, $
                  observatory=observatory

hogg_usersym, 10, /fill 
djs_oplot, off.yfocal, off.xfocal, psym=8, symsize=0.15

for i=0L, n_elements(off)-1L do begin 
   if(off[i].target_ra ne 0. OR off[i].target_dec ne 0. and $
      off[i].pointing eq pointing) then begin
      xoff= (off[i].xfoff)*1000.
      yoff= (off[i].yfoff)*1000.
      if(off[i].lambda_eff eq guideon) then $
         color='red' $
      else $
         color='blue'
      if(off[i].holetype eq 'GUIDE') then $
         thick=5 $
      else $
         thick=1
      if(off[i].holetype eq 'GUIDE') then $
         hsize=300. $
      else $
         hsize=100.
      djs_oplot, off[i].yfocal+yoff, off[i].xfocal+xoff, color=color, thick=thick
      hogg_arrow, off[i].yfocal+yoff[nha-2], $
                  off[i].xfocal+xoff[nha-2], $
                  off[i].yfocal+yoff[nha-1], $
                  off[i].xfocal+xoff[nha-1], $
                  /data,  color=djs_icolor(color), hthick=thick, /solid, $
                  thick=1, head_angle=20., hsize=hsize
   endif
endfor

djs_xyouts, [245.], [-300.], '!860 \mum', charsize=0.9
djs_oplot, [240., 300.], [-310., -310.], th=4
djs_oplot, [240., 240.], [-313., -307.], th=4
djs_oplot, [300., 300.], [-313., -307.], th=4

platelines_end

filebase= platedir+'/plateGuideCorrections-'+post
p_print, filename=filebase+'.ps', xsize= 10., ysize=10.

!P.MULTI= [4,1,4]
!Y.MARGIN=0
!X.OMARGIN=[22, 1]

djs_plot, adjust.delha, adjust.rot, th=4, /leftaxis, $
          ytitle='!8\theta!6 (deg)'
djs_plot, adjust.delha, adjust.scale, th=4, /leftaxis, $
          ytitle='!6scale'
djs_plot, adjust.delha, adjust.xshift*1000., th=4, /leftaxis, $
          ytitle='!8\Delta!8x!6 (\mum)'
djs_plot, adjust.delha, adjust.yshift*1000., th=4, $
          ytitle='!8\Delta!8y!6 (\mum)'

p_end_print

spawn, 'convert '+filebase+'.ps '+filebase+'.png'
file_delete, filebase+'.ps'


end 
;------------------------------------------------------------------------------
