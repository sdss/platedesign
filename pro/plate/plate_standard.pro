;+
; NAME:
;   plate_standard 
; PURPOSE:
;   Return standards for a given plate set up
; CALLING SEQUENCE:
;   stds= plate_standard(definition, default, instrument, pointing, offset)
; REVISION HISTORY:
;   7-May-2008  MRB, NYU
;-
;------------------------------------------------------------------------------
function plate_standard, definition, default, instrument, $
                         pointing, offset, rerun=rerun

if(NOT tag_exist(default, 'PLATEDESIGNSTANDARDS')) then begin
    return, 0
endif 

designid= long(definition.designid)

;; what instruments are we designing standards for?
platedesignstandards= strsplit(default.platedesignstandards, /extr)
standardtype= strsplit(default.standardtype, /extr)

;; check if the current instrument is included, if not, return
iinst= where(strupcase(instrument) eq $
             strupcase(platedesignstandards), ninst)
if(ninst eq 0) then begin
    return, 0
endif
standardtype= standardtype[pointing-1L]

;; file name
outdir= design_dir(designid)
stdfile=outdir+'/plateStandard'+instrument+'-'+ $
  string(designid, f='(i6.6)')+ $
  '-p'+strtrim(string(pointing),2)+ $
  '-o'+strtrim(string(offset),2)+'.par'

;; if file is already made, just read it in
sphoto_design=0
if(NOT file_test(stdfile)) then begin
    ;; what is center for this pointing and offset?
    plate_center, definition, default, pointing, offset, $
      racen=racen, deccen=deccen
    
    if(standardtype eq 'SDSS') then begin
        ;; find SDSS standards and assign them
        plate_select_sphoto_sdss, racen, deccen, $
          rerun=rerun, sphoto_mag=sphoto_mag, $
          sphoto_design= sphoto_design, tilerad=tilerad
    endif 
    
    if(standardtype eq '2MASS') then begin
        ;; find 2MASS standards and assign them
        plate_select_sphoto_2mass, racen, deccen, $
          sphoto_mag=sphoto_mag, $
          sphoto_design= sphoto_design, tilerad=tilerad
    endif
    
    if(n_tags(sphoto_design) gt 0) then begin
        sphoto_design.pointing=pointing
        sphoto_design.offset=offset
        sphoto_design.holetype=instrument
        plate_ad2xy, definition, default, pointing, offset, $
          sphoto_design.target_ra, $
          sphoto_design.target_dec, $
          xf=xf, yf=yf
        sphoto_design.xf_default=xf
        sphoto_design.yf_default=yf
    endif
    
    if(n_tags(sphoto_design) gt 0) then begin
        pdata= ptr_new(sphoto_design)
        hdrstr=struct_combine(default, definition)
        outhdr=struct2lines(hdrstr)
        outhdr=[outhdr, $
                'pointing '+strtrim(string(pointing),2), $
                'platedesign_version '+platedesign_version()]
        if(keyword_set(rerun)) then $
          outhdr=[outhdr, 'rerun '+strtrim(string(rerun),2)]
        yanny_write, stdfile, pdata, hdr=outhdr
    endif
endif else begin
    in_sphoto_design= yanny_readone(stdfile, /anon)
    sphoto_design= replicate(design_blank(), n_elements(in_sphoto_design))
    struct_assign, in_sphoto_design, sphoto_design, /nozero
endelse

return, sphoto_design

end
