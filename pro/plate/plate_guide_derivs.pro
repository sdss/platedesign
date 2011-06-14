;+
; NAME:
;   plate_guide_derivs
; PURPOSE:
;   Calculate guide derivatives as a function of HA
; CALLING SEQUENCE:
;   plate_guide_derivs, plateid [, pointing, guideon= ]
; INPUTS:
;   plateid - plate number
; OPTIONAL INPUTS:
;   pointing - pointing number
;   guideon - wavelength to guide on in Angstroms (default 5400.)
; COMMENTS:
;   Writes output to:
;    - plateGuideAdjust-XXXXXX-pP-lGUIDEON.par
;    - plateGuideOffsets-XXXXXX-pP-lGUIDEON.par
;   If there are no holes designed for the "guideon" wavelength,
;     then it bombs
; REVISION HISTORY:
;   10-Jun-2008  MRB, NYU
;-
pro plate_guide_derivs, in_plateid, pointing, guideon=guideon

common com_plate_guide_derivs, plateid, full, definition, default, phdr

if(NOT keyword_set(guideon)) then guideon=5400.
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

post=string(f='(i6.6)', plateid)+ $
     '-p'+strtrim(string(pointing),2)+ $
     '-l'+strtrim(string(guideon, f='(i5.5)'),2)
adjustfile= platedir+'/plateGuideAdjust-'+post+'.par'
offsetfile=platedir+'/plateGuideOffsets-'+post+'.par'

fullfile= platedir+'/plateHolesSorted-'+ $
          strtrim(string(f='(i6.6)',plateid),2)+'.par'
check_file_exists, fullfile, plateid=plateid

if(n_tags(full) eq 0) then begin
   full= yanny_readone(fullfile, hdr=phdr, /anon)
   definition= lines2struct(phdr)
   default= definition
endif

ha=float(strsplit(definition.ha, /extr))
temp=float(definition.temp)

plate_center, definition, default, pointing, offset, $
              racen=racen, deccen=deccen
igood=where(full.target_ra ne 0. or full.target_dec ne 0. and $
            full.pointing eq pointing, ngood)
ra= full[igood].target_ra
dec= full[igood].target_dec
lambda= full[igood].lambda_eff
xforig= full[igood].xfocal
yforig= full[igood].yfocal
plate_ad2xy, definition, default, pointing, offset, ra, dec, $
             lambda, xf=xfocal, yf=yfocal, lst=racen+ha[pointing-1L], $
             airtemp=temp

ifit= where(full[igood].lambda_eff eq guideon, nfit)
if(nfit eq 0) then begin
   file_delete, adjustfile, /allow
   file_delete, offsetfile, /allow
   splog, 'No holes with LAMBDA_EFF='+strtrim(string(guideon),2)
   return
endif

if(ha[pointing-1L] lt -120. OR $
   ha[pointing-1L] gt  120.) then begin
   message, 'HA desired is more than 120 deg! I refuse.'
endif

nha=17L
minha= (ha[pointing-1L]-45.)>(-80.)
maxha= (ha[pointing-1L]+45.)<(80.)
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

adjust0= {HAADJUST, delha:0.D, rot:0.D, scale:1.D, xshift:0.D, yshift:0.D}
adjust= replicate(adjust0, nha)
adjust.delha= hatest
adjust.rot= rot
adjust.scale= scale
adjust.xshift= xshift
adjust.yshift= yshift

pdata=ptr_new(adjust)
hdr= [phdr, 'lambda '+strtrim(string(guideon, f='(f40.3)'),2), $
      'pointing '+strtrim(string(pointing),2)]
yanny_write, adjustfile, pdata, hdr=hdr
ptr_free, pdata

offsets0= {HAOFFSETS, xfocal:0., yfocal:0., target_ra:0., target_dec:0., $
           pointing:0L, lambda_eff:0., iguide:0L, fiberid:0L, holetype:' ', $
           delha:fltarr(nha), xfoff:fltarr(nha), yfoff:fltarr(nha)}
offsets= replicate(offsets0, n_elements(full))
struct_assign, full, offsets
for i=0L, ngood-1L do begin
   offsets[igood[i]].delha= hatest
   offsets[igood[i]].xfoff= xfall[i,*]-xfocal[i]
   offsets[igood[i]].yfoff= yfall[i,*]-yfocal[i]
endfor

pdata=ptr_new(offsets)
yanny_write, offsetfile, pdata, hdr=hdr
ptr_free, pdata

plate_guide_derivs_plot, plateid, pointing, guideon=guideon

end
;------------------------------------------------------------------------------
