;+
; NAME:
;   plate_guide_derivs
; PURPOSE:
;   Calculate guide derivatives as a function of HA
; CALLING SEQUENCE:
;   plate_guide_derivs, plateid [, pointing]
; INPUTS:
;   plateid - plate number
; OPTIONAL INPUTS:
;   pointing - pointing number
; COMMENTS:
;   Makes the following plots:
;    - paths of objects as a function of HA
;    - paths of just guides as a function of HA
; REVISION HISTORY:
;   10-Jun-2008  MRB, NYU
;-
pro plate_guide_derivs, in_plateid, pointing

common com_plate_guide_derivs, plateid, full, definition, default

if(NOT keyword_set(pointing)) then pointing=1L
offset=0L

if(keyword_set(plateid)) then begin
   if(in_plateid ne plateid) then begin
      full=0L
      definition=0L
      default=0L
   endif
endif 
plateid= in_plateid

platedir= plate_dir(plateid)

fullfile= platedir+'/plateHolesSorted-'+ $
          strtrim(string(f='(i6.6)',plateid),2)+'.par'
check_file_exists, fullfile, plateid=plateid

if(n_tags(full) eq 0) then begin
   full= yanny_readone(fullfile, hdr=hdr, /anon)
   definition= lines2struct(hdr)
   default= definition
endif

ha=float(strsplit(definition.ha, /extr))
temp=float(definition.temp)

plate_center, definition, default, pointing, offset, $
              racen=racen, deccen=deccen
igood=where(full.target_ra ne 0. or full.target_dec ne 0., ngood)
ra= full[igood].target_ra
dec= full[igood].target_dec
lambda= full[igood].lambda_eff
xforig= full[igood].xfocal
yforig= full[igood].yfocal
plate_ad2xy, definition, default, pointing, offset, ra, dec, $
             lambda, xf=xfocal, yf=yfocal, lst=racen+ha[pointing-1L], $
             airtemp=temp

if(ha[pointing-1L] lt -80. OR $
   ha[pointing-1L] gt  80.) then begin
   message, 'HA desired is more than 80 deg! I refuse.'
endif

nha=11L
maxha= (ha[pointing-1L]-30.)>(-80.)
minha= (ha[pointing-1L]+30.)<(80.)
hatest= minha+(maxha-minha)*(findgen(nha)/float(nha-1L))
xfall= fltarr(ngood, nha)
yfall= fltarr(ngood, nha)

rot=fltarr(nha)
scale=fltarr(nha)
xshift=fltarr(nha)
yshift=fltarr(nha)
for i=0L, nha-1L do begin
   plate_ad2xy, definition, default, pointing, offset, ra, dec, $
                lambda, xf=xtmp, yf=ytmp, lst=racen+hatest[i], $
                airtemp=temp
   ifit= where(full[igood].lambda_eff eq 5400.)
   ha_fit, xfocal[ifit], yfocal[ifit], xtmp[ifit], ytmp[ifit], $
           xnew=xtmp2, ynew=ytmp2, rot=rottmp, scale=scaletmp, $
           xshift=xshifttmp, yshift=yshifttmp
   rot[i]=rottmp
   scale[i]=scaletmp
   xshift[i]=xshifttmp
   yshift[i]=yshifttmp
   ha_apply, xtmp, ytmp, xnew=xnew, ynew=ynew, rot=rot[i], scale=scale[i], $
             xshift=xshift[i], yshift=yshift[i]
   
   xfall[*,i]= xnew
   yfall[*,i]= ynew
endfor

save

platelines_start, plateid, 'derivs_all', 'offsets (\DeltaHA= -30 to +30)'

hogg_usersym, 10, /fill
djs_oplot, yforig, xforig, psym=8, symsize=0.15

for i=0L, ngood-1L do begin
   xoff= (xfall[i,*]-xfocal[i])*1000.
   yoff= (yfall[i,*]-yfocal[i])*1000.
   if(lambda[i] lt 5000.) then $
      color='blue' $
   else $
      color='red'
   if(full[igood[i]].holetype eq 'GUIDE') then $
      thick=5 $
   else $
      thick=1
   if(full[igood[i]].holetype eq 'GUIDE') then $
      hsize=300. $
   else $
      hsize=100.
   djs_oplot, yfocal[i]+yoff, xfocal[i]+xoff, color=color, thick=thick
   hogg_arrow, yfocal[i]+yoff[nha-2], $
               xfocal[i]+xoff[nha-2], $
               yfocal[i]+yoff[nha-1], $
               xfocal[i]+xoff[nha-1], $
               /data,  color=djs_icolor(color), hthick=thick, /solid, $
               thick=1, head_angle=20., hsize=hsize
endfor

djs_xyouts, [245.], [-300.], '!860 \mum', charsize=0.9
djs_oplot, [240., 300.], [-310., -310.], th=4
djs_oplot, [240., 240.], [-313., -307.], th=4
djs_oplot, [300., 300.], [-313., -307.], th=4

platelines_end

p_print, filename='corrections.ps', xsize= 10., ysize=10.

!P.MULTI= [4,1,4]
!Y.MARGIN=0
!X.OMARGIN=[4, 1]

djs_plot, hatest, rot, th=4, /leftaxis, $
          ytitle='!8\theta!6'
djs_plot, hatest, scale, th=4, /leftaxis, $
          ytitle='!6scale'
djs_plot, hatest, xshift, th=4, /leftaxis, $
          ytitle='!8\Deltax!6'
djs_plot, hatest, yshift, th=4, $
          ytitle='!8\Deltay!6'

p_end_print

filebase='corrections'
spawn, 'convert '+filebase+'.ps '+filebase+'.png'
file_delete, filebase+'.ps'


end 
;------------------------------------------------------------------------------
