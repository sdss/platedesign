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

; ??
common com_plate_guide_derivs, plateid, full, definition, default, phdr

; By default, optimize guiding for 5400 Angstroms light
; Assume this is pointing number one
if(NOT keyword_set(guideon)) then guideon=5400.
if(NOT keyword_set(pointing)) then pointing=1L
offset=0L

; I assume this has something do with that common statement earlier
; This seems strange, some combination of checking input variables and initializing variables
if(keyword_set(plateid)) then begin
   if(in_plateid ne plateid) then begin
      full=0L
      definition=0L
      default=0L
   endif
endif 
plateid= in_plateid

; Set path to directory for the specified plate number
platedir= plate_dir(plateid)

; Construct paths for two output files:
;    ...plateGuideAdjust... : guider corrections for optimal guiding
;    ...plateGuideOffsets... : target positions on plate as function of HA
post=string(f='(i6.6)', plateid)+ $
     '-p'+strtrim(string(pointing),2)+ $
     '-l'+strtrim(string(guideon, f='(i5.5)'),2)
adjustfile= platedir+'/plateGuideAdjust-'+post+'.par'
offsetfile=platedir+'/plateGuideOffsets-'+post+'.par'

; Construct path to input plateHoles file, contains fiber positions and other relevant information
fullfile= platedir+'/plateHolesSorted-'+ $
          strtrim(string(f='(i6.6)',plateid),2)+'.par'
check_file_exists, fullfile, plateid=plateid

; Parse contents of input file, 
; the input file has a global header and a data entry with multiple fields for each fiber
if(n_tags(full) eq 0) then begin
   full= yanny_readone(fullfile, hdr=phdr, /anon)
   definition= lines2struct(phdr)
   default= definition
endif

; Read design hour angle, temperature
; Temperature is always 5 C?
ha=float(strsplit(definition.ha, /extr))
temp=float(definition.temp)

; This syntax really bugs me, calculate ra and dec for center of the plate
; The values are accessible through 'racen' and 'deccen' after this?
plate_center, definition, default, pointing, offset, $
              racen=racen, deccen=deccen

; Select "good" targets/fibers, this is a list of array indices
; I suppose since this is a list of indicies that is what the "i" prefix denotes
; since we are going to use more list of indicies in a little bit 
; I would suggest something like goodfibers/goodtargets but its not a big deal
igood=where(full.target_ra ne 0. or full.target_dec ne 0. and $
            full.pointing eq pointing, ngood)
; Collect ra/dec/lambda/x/y info for each target
ra= full[igood].target_ra
dec= full[igood].target_dec
lambda= full[igood].lambda_eff; typically, 5400 for most targets, 4000 for QSOs
xforig= full[igood].xfocal
yforig= full[igood].yfocal

; Calculate xfocal and yfocal ?? did we just read these in?
plate_ad2xy, definition, default, pointing, offset, ra, dec, $
             lambda, xf=xfocal, yf=yfocal, lst=racen+ha[pointing-1L], $
             airtemp=temp

; I'm pretty sure this would grab all fibers with with lambda_eff at 5400, so basically
; everything except the QSOs
; I propose something like:
; guidefibers = where(full[goodfibers].holetype eq 'GUIDE', nguide)
ifit= where(full[igood].lambda_eff eq guideon, nfit)
if(nfit eq 0) then begin
   file_delete, adjustfile, /allow
   file_delete, offsetfile, /allow
   splog, 'No holes with LAMBDA_EFF='+strtrim(string(guideon),2)
   return
endif

; Set up hour angle window for guiding optimization and offset calculations
if(ha[pointing-1L] lt -120. OR $
   ha[pointing-1L] gt  120.) then begin
   message, 'HA desired is more than 120 deg! I refuse.'
endif

nha=17L
minha= (ha[pointing-1L]-45.)>(-80.)
maxha= (ha[pointing-1L]+45.)<(80.)
hatest= minha+(maxha-minha)*(findgen(nha)/float(nha-1L))

; Create empty arrays to store guiding corrections and position offsets at each hour angle value
xfall= fltarr(ngood, nha)
yfall= fltarr(ngood, nha)

rot=fltarr(nha)
scale=fltarr(nha)
xshift=fltarr(nha)
yshift=fltarr(nha)

; Iterate over HA array
for i=0L, nha-1L do begin
   	; Calculate xtmp, ytmp (all igood targets) at this hour angle
   plate_ad2xy, definition, default, pointing, offset, ra, dec, $
                lambda, xf=xtmp, yf=ytmp, lst=racen+hatest[i], $
                airtemp=temp
    ; Fit rotation, scale, shift parameters in guide targets
   ha_fit, xfocal[ifit], yfocal[ifit], xtmp[ifit], ytmp[ifit], $
           xnew=xtmp2, ynew=ytmp2, rot=rottmp, scale=scaletmp, $
           xshift=xshifttmp, yshift=yshifttmp
    ; Save rotation, scale, shift parameters at this hour angle
   rot[i]=rottmp
   scale[i]=scaletmp
   xshift[i]=xshifttmp
   yshift[i]=yshifttmp
    ; Apply rotation, scale, shift adjustments (all igood targets)
   ha_apply, xtmp, ytmp, xnew=xnew, ynew=ynew, rot=rot[i], scale=scale[i], $
             xshift=xshift[i], yshift=yshift[i]
    ; Save x,y position (all igood targets) at this hour angle
   xfall[*,i]= xnew
   yfall[*,i]= ynew
endfor

; Create structure to save adjustment parameters
adjust0= {HAADJUST, delha:0.D, rot:0.D, scale:1.D, xshift:0.D, yshift:0.D}
adjust= replicate(adjust0, nha)
adjust.delha= hatest-ha[pointing-1]
adjust.rot= rot
adjust.scale= scale
adjust.xshift= xshift
adjust.yshift= yshift

; Write adjustments to file
pdata=ptr_new(adjust)
hdr= [phdr, 'lambda '+strtrim(string(guideon, f='(f40.3)'),2), $
      'pointing '+strtrim(string(pointing),2)]
yanny_write, adjustfile, pdata, hdr=hdr
ptr_free, pdata

; Create structure to save target position offsets as function of hour angle
offsets0= {HAOFFSETS, xfocal:0., yfocal:0., target_ra:0., target_dec:0., $
           pointing:0L, lambda_eff:0., iguide:0L, fiberid:0L, holetype:' ', $
           delha:fltarr(nha), xfoff:fltarr(nha), yfoff:fltarr(nha)}
offsets= replicate(offsets0, n_elements(full))
struct_assign, full, offsets
for i=0L, ngood-1L do begin
   offsets[igood[i]].delha= hatest-ha[pointing-1]
   offsets[igood[i]].xfoff= xfall[i,*]-xfocal[i]
   offsets[igood[i]].yfoff= yfall[i,*]-yfocal[i]
endfor

; Write target offsets to file
pdata=ptr_new(offsets)
yanny_write, offsetfile, pdata, hdr=hdr
ptr_free, pdata

plate_guide_derivs_plot, plateid, pointing, guideon=guideon

end
;------------------------------------------------------------------------------
