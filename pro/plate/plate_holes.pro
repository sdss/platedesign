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
;   NO ALIGNMENT HOLES!!
; REVISION HISTORY:
;   10-Jun-2008  MRB, NYU
;-
pro plate_holes, designid, plateid, ha, temp
true = 1
false = 0

;; import design file and settings in header
designdir= design_dir(designid)
designfile=designdir+'/plateDesign-'+ $
  string(designid, f='(i6.6)')+'.par'
designs= yanny_readone(designfile, hdr=hdr)
definition= lines2struct(hdr)
default= definition

;; special flag to omit guide fibers
if(tag_exist(default, 'OMIT_GUIDES')) then $
  omit_guides= long(default.omit_guides)

;; create output structure
holes0= create_struct(design_blank(), 'XFOCAL', 0.D, 'YFOCAL', 0.D)
holes= replicate(holes0, n_elements(designs))
struct_assign, designs, holes
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
              lst=racen+ha[pointing-1L], airtemp=temp, xfocal=xf, yfocal=yf
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
          xf_align, yf_align
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
    
endfor

if(n_tags(align) gt 0) then $
  holes= [holes, align]

tmpstr= lines2struct(hdr)
if(tag_exist(tmpstr, 'locationid') eq false) then begin
    plans= yanny_readone(getenv('PLATELIST_DIR')+'/platePlans.par')
    iplate= where(plans.plateid eq plateid, nplate)
    if(nplate eq 0) then $
      message, 'plate '+strtrim(string(plateid),2)+' not in platePlans.par!'
    if(nplate gt 1) then $
      message, 'plate '+strtrim(string(plateid),2)+ $
      ' has multiple entries in platePlans.par!'
    locationid= plans[iplate[0]].locationid
    hdr=['locationID '+strtrim(string(locationid),2), hdr]
endif
    
outhdr=['plateid '+strtrim(string(plateid),2), $
        'ha '+strjoin(strtrim(string(ha, f='(f40.3)'),2)+' '), $
        'temp '+strtrim(string(temp, f='(f40.3)'),2), $
        hdr]
pdata= ptr_new(holes)
platedir= plate_dir(plateid)
platefile=platedir+'/plateHoles-'+ $
  string(plateid, f='(i6.6)')+'.par'
yanny_write, platefile, pdata, hdr=outhdr

end
;------------------------------------------------------------------------------
