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

; By default, optimize guiding for 5400 Angstroms light
; Assume this is pointing number one
if(NOT keyword_set(guideon)) then guideon=5400.
if(NOT keyword_set(pointing)) then pointing=1L
offset=0L

; If this plateid is the same as the last one, we won't read
; in the plate information again; but if it is a different one,
; we reset these variables (and will therefore read in new files
; below)
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
fullfile= platedir+'/'+plateholes_filename(plateid=plateid, /sorted)
check_file_exists, fullfile, plateid=plateid

; Parse contents of input file,
; the input file has a global header and a data entry with multiple fields for each fiber
if(n_tags(full) eq 0) then begin
   full= yanny_readone(fullfile, hdr=phdr, /anon)
   definition= lines2struct(phdr)
   default= definition
endif

; Read design hour angle, temperature
; Temperature is set per plate in the platePlans.par file
ha=float(strsplit(definition.ha, /extr))
temp=float(definition.temp)

; Calculate ra and dec for center of the plate
; The values are accessible through 'racen' and 'deccen' after this
; This is necessary for handling multiple pointing plates (and
; we keep it general for multi-offset plates).
plate_center, definition, default, pointing, offset, $
              racen=racen, deccen=deccen

; Select "good" targets/fibers, this is a list of array indices
igood=where(full.target_ra ne 0. or full.target_dec ne 0. and $
            full.pointing eq pointing, ngood)
; Collect ra/dec/lambda/x/y info for each target
ra= full[igood].target_ra
dec= full[igood].target_dec
lambda= full[igood].lambda_eff ;; e.g., 5400 for LRGs, 4000 for QSOs, 16600 for APOGEE targets
xforig= full[igood].xfocal
yforig= full[igood].yfocal
zoffset= full[igood].zoffset

; Calculate xfocal and yfocal for this pointing (should be similar
; to xforig/yforig up to round-off)
plate_ad2xy, definition, default, pointing, offset, ra, dec, $
             lambda, xf=xfocal, yf=yfocal, lst=racen+ha[pointing-1L], $
             airtemp=temp, zoffset=zoffset

; I'm pretty sure this would grab all fibers with with lambda_eff at 5400, so basically
;  everything except the QSOs
; I propose something like:
;  guidefibers = where(full[goodfibers].holetype eq 'GUIDE', nguide)
; MRB: I would check how stable this is first; it may be that my code
;  is actually worse behaved for low N than the guider is, and that is
;  worth checking before using these for corrections; this is a
;  critical issue for APOGEE and can't be changed without
;  thorough testing.
ifit= where(full[igood].lambda_eff eq guideon, nfit)
if(nfit eq 0) then begin
   file_delete, adjustfile, /allow
   file_delete, offsetfile, /allow
   ;print, 'No holes with LAMBDA_EFF='+strtrim(string(guideon),2)
   print, color_string('No holes with LAMBDA_EFF='+strtrim(string(guideon),2), 'yellow')
   return
endif

; Set up hour angle window for guiding optimization and offset calculations
if(ha[pointing-1L] lt -120. OR $
   ha[pointing-1L] gt  120.) then begin
   ;message, color_string('HA desired is more than 120 deg! I refuse.', 'red', 'bold')
   print, color_string('HA desired is more than 120 deg! Double check that this is intended.', 'yellow', 'blink')
endif

ha_obs_min = float(strsplit(definition.ha_observable_min, /extr))
ha_obs_max = float(strsplit(definition.ha_observable_max, /extr))

minha= (ha[pointing-1L]-45.)>(-80.)
maxha= (ha[pointing-1L]+45.)<(80.)

; Correct minha, maxha in case the observing window is larger than deltaHA -45 to 45
if minha gt ha_obs_min[pointing-1L] then minha = ha_obs_min[pointing-1L] - 5
if maxha lt ha_obs_max[pointing-1L] then maxha = ha_obs_max[pointing-1L] + 5

nha=17L
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
   ;; Calculate xtmp, ytmp (all igood targets) at this hour angle
   plate_ad2xy, definition, default, pointing, offset, ra, dec, $
                lambda, xf=xtmp, yf=ytmp, lst=racen+hatest[i], $
                airtemp=temp, zoffset=zoffset
   ;; Fit rotation, scale, shift parameters in guide targets
   ha_fit, xfocal[ifit], yfocal[ifit], xtmp[ifit], ytmp[ifit], $
           xnew=xtmp2, ynew=ytmp2, rot=rottmp, scale=scaletmp, $
           xshift=xshifttmp, yshift=yshifttmp
   ;; Save rotation, scale, shift parameters at this hour angle
   rot[i]=rottmp
   scale[i]=scaletmp
   xshift[i]=xshifttmp
   yshift[i]=yshifttmp
   ;; Apply rotation, scale, shift adjustments (all igood targets)
   ha_apply, xtmp, ytmp, xnew=xnew, ynew=ynew, rot=rot[i], scale=scale[i], $
             xshift=xshift[i], yshift=yshift[i]
   ;; Save x,y position (all igood targets) at this hour angle
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
