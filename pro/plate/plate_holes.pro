;+
; NAME:
;   plate_holes
; PURPOSE:
;   Create plateHoles file for a given plateid
; CALLING SEQUENCE:
;   plate_holes, designid, plateid, ha, temp
; INPUTS:
;   designid - designid to read from
;   plateid - plateid to write to
;   ha - hour angle to use
;   temp - temperature
; COMMENTS:
; REVISION HISTORY:
;   10-Jun-2008  MRB, NYU
;    1-Sep-2010  Demitri Muna, NYU, Adding file test before opening files.
;-
pro plate_holes, designid, plateid, ha, temp, epoch

true = 1
false = 0

platescale = 217.7358D           ; mm/degree

;; import design file and settings in header
designdir= design_dir(designid)
designfile=designdir+'/plateDesign-'+ $
  string(designid, f='(i6.6)')+'.par'
check_file_exists, designfile, plateid=plateid
designs= yanny_readone(designfile, hdr=hdr, /anon)
definition= lines2struct(hdr)
default= definition

;; Warn us if we do not have a condition to set min/max HA 
if(tag_indx(default, 'max_off_fiber_for_ha') eq -1) then begin
    default= create_struct(default, 'max_off_fiber_for_ha', '0.5')
    plate_log, plateid, 'WARNING: max_off_fiber_for_ha not set in default file'
    plate_log, plateid, 'WARNING: setting max_off_fiber_for_ha='+ $
               default.max_off_fiber_for_ha+' arcsec'
endif 

;; special flag to omit guide fibers
if(tag_exist(default, 'OMIT_GUIDES')) then $
  omit_guides= long(default.omit_guides)
if(tag_exist(default, 'GFIBERTYPE')) then $
  gfibertype= default.gfibertype $
else $
  gfibertype='gfiber'

;; adjust design for new epoch
design_pm, designs, toepoch=epoch

;; create output structure
holes0= create_struct(design_blank(), 'XFOCAL', 0.D, 'YFOCAL', 0.D)
holes= replicate(holes0, n_elements(designs))
struct_assign, designs, holes, /nozero
holes.xfocal= holes.xf_default
holes.yfocal= holes.yf_default

;; for each pointing and offset, find the final
;; xfocal and yfocal and set them
npointings= long(default.npointings)
noffsets= long(default.noffsets)
for pointing=1L, npointings do begin

    ;; for each offset, do the holes there
    for offset=0L, noffsets do begin
        iin= where(holes.pointing eq pointing AND $
                   holes.offset eq offset, nin)
        plate_center, definition, default, pointing, offset, $
          racen=racen, deccen=deccen
        if(nin gt 0) then begin
            plate_ad2xy, definition, default, pointing, offset, $
              holes[iin].target_ra, holes[iin].target_dec, $
              holes[iin].lambda_eff, lst=racen+ha[pointing-1L], $
              airtemp=temp, xfocal=xf, yfocal=yf
            holes[iin].xfocal= xf
            holes[iin].yfocal= yf
        endif
    endfor

    ;; for each guide fiber, make an alignment hole
    iguide= where(holes.pointing eq pointing AND $
                  strupcase(holes.holetype) eq 'GUIDE', nguide)
    if(nguide eq 0) then begin
        if(keyword_set(omit_guides) eq 0) then $
          message, 'Each pointing needs some guide fibers!'
    endif
    for i=0L, nguide-1L do begin
        alignment_fiber, holes[iguide[i]].iguide, $
          holes[iguide[i]].xfocal, holes[iguide[i]].yfocal, $
          xf_align, yf_align, gfibertype=gfibertype
        align0= holes0
        align0.holetype= 'ALIGNMENT'
        align0.pointing=pointing
        align0.iguide=holes[iguide[i]].iguide
        align0.diameter=0.1
        align0.xfocal= xf_align
        align0.yfocal= yf_align
        if(n_tags(align) eq 0) then $
          align=align0 $
        else $
          align=[align, align0]
     endfor

    ;; check for MaNGA bundles, and add alignment holes for those
    imanga= where(holes.holetype eq 'MANGA', nmanga)
    for i=0L, nmanga-1L do begin
       align_manga0= holes0
       align_manga0.holetype= 'MANGA_ALIGNMENT'
       align_manga0.pointing= pointing
       align_manga0.fiberid= holes[imanga[i]].fiberid
       align_manga0.diameter= 0.1
       align_manga0.xfocal= holes[imanga[i]].xfocal+float(default.dxalignmentmanga)
       align_manga0.yfocal= holes[imanga[i]].yfocal+float(default.dyalignmentmanga)
       if(n_tags(align_manga) eq 0) then $
          align_manga=align_manga0 $
       else $
          align_manga=[align_manga, align_manga0]
    endfor

endfor

;; determine HA limits
ha_limits, plateid, design=designs, hamin=hamin, hamax=hamax, $
           maxoff_arcsec= float(default.max_off_fiber_for_ha)

if(n_tags(align) gt 0) then $
  holes= [holes, align]
if(n_tags(align_manga) gt 0) then $
  holes= [holes, align_manga]

tmpstr= lines2struct(hdr)
if(tag_exist(tmpstr, 'locationid') eq false) then begin
	plateplans_file = getenv('PLATELIST_DIR')+'/platePlans.par'
	check_file_exists, plateplans_file, plateid=plateid
    plans= yanny_readone(plateplans_file)
    iplate= where(plans.plateid eq plateid, nplate)
    if(nplate eq 0) then $
      message, 'plate '+strtrim(string(plateid),2)+' not in platePlans.par!'
    if(nplate gt 1) then $
      message, 'plate '+strtrim(string(plateid),2)+ $
      ' has multiple entries in platePlans.par!'
    locationid= plans[iplate[0]].locationid
    hdr=['locationId '+strtrim(string(locationid),2), hdr]
endif

outhdr=['plateId '+strtrim(string(plateid),2), $
        'ha '+strjoin(strtrim(string(ha, f='(f40.3)'),2)+' '), $
        'ha_observable_min '+strjoin(strtrim(string(hamin, f='(f40.3)'),2)+' '), $
        'ha_observable_max '+strjoin(strtrim(string(hamax, f='(f40.3)'),2)+' '), $
        'temp '+strtrim(string(temp, f='(f40.3)'),2), $
        guider_hdr(plateid), $
        hdr]
pdata= ptr_new(holes)
platedir= plate_dir(plateid)
platefile=platedir+'/plateHoles-'+ $
  string(plateid, f='(i6.6)')+'.par'
yanny_write, platefile, pdata, hdr=outhdr
ptr_free, pdata

end
;------------------------------------------------------------------------------
