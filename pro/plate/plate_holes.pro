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
; REVISION HISTORY:
;   10-Jun-2008  MRB, NYU
;-
pro plate_holes, designid, plateid, ha, temp

;; import design file and settings in header
designdir= design_dir(designid)
designfile=designdir+'/plateDesign-'+ $
  string(designid, f='(i6.6)')+'.par'
designs= yanny_readone(designfile, hdr=hdr)
definition= lines2struct(hdr)
default= definition

;; create output structure
holes0= create_struct(design_blank(), 'XFOCAL', 0., 'YFOCAL', 0.)
holes= replicate(holes0, n_elements(designs))
struct_assign, designs, holes
holes.xfocal= holes.xf_default
holes.yfocal= holes.yf_default

;; for each pointing and offset, find the final
;; xfocal and yfocal and set them
npointings= long(default.npointings)
noffsets= long(default.noffsets)
for pointing=1L, npointings do begin
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
endfor



end
;------------------------------------------------------------------------------
