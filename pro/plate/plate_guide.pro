;+
; NAME:
;   plate_guide 
; PURPOSE:
;   Return guide for a given plate set up
; CALLING SEQUENCE:
;   guide= plate_guide(definition, default, pointing)
; REVISION HISTORY:
;   7-May-2008  MRB, NYU
;   1-Sep-2010  Demitri Muna, NYU, Adding file test before opening files.
;-
;------------------------------------------------------------------------------
function plate_guide, definition, default, pointing, rerun=rerun, $
  epoch=epoch, clobber=clobber, seed=seed

designid= long(definition.designid)

tilerad= get_tilerad(definition, default)

if(tag_exist(default, 'GUIDEMAG_MINMAX')) then begin
   gminmax_mag=float(strsplit(default.guidemag_minmax, /extr))
endif
if(tag_exist(definition, 'GUIDEMAG_MINMAX')) then begin
   gminmax_mag=float(strsplit(definition.guidemag_minmax, /extr))
endif

if(tag_exist(default, 'GUIDE_JKMINMAX')) then begin
    jkminmax=float(strsplit(default.guide_jkminmax, /extr))
endif
if(tag_exist(definition, 'GUIDE_JKMINMAX')) then begin
    jkminmax=float(strsplit(definition.guide_jkminmax, /extr))
endif

if(tag_exist(default, 'NGUIDEMAX')) then begin
    nguidemax=long(default.nguidemax)
endif

if(tag_exist(default, 'GUIDEMAG_MINMAX_BAND')) then begin
    gminmax_band=default.guidemag_minmax_band
endif
if(tag_exist(definition, 'GUIDEMAG_MINMAX_BAND')) then begin
    gminmax_band=definition.guidemag_minmax_band
endif

if(tag_exist(default, 'GUIDE_LAMBDA_EFF')) then begin
    guide_lambda_eff=float(default.guide_lambda_eff)
endif

;; file name
outdir= design_dir(designid)
guidefile=outdir+'/plateGuide-'+ $
          string(designid, f='(i6.6)')+ $
          '-p'+strtrim(string(pointing),2)+'.par'

if(file_test(guidefile) eq 0 OR $
   keyword_set(clobber) gt 0) then begin

    ;; if there is no file, and we haven't specified type,
    ;; then abort
    if(NOT tag_exist(default, 'GUIDETYPE')) then begin
        return, 0
    endif 

    guidetype= (strsplit(default.guidetype, /extr))[pointing-1]

    if(strupcase(guidetype) ne 'SDSS' AND $
       strupcase(guidetype) ne 'USNOB' AND $
       strupcase(guidetype) ne '2MASS') then $
      message, color_string('No such guide type '+guidetype+'!', 'red', 'bold')

    ;; what is center for this pointing?
    plate_center, definition, default, pointing, 0L, $
                  racen=racen, deccen=deccen
    
    ;; find SDSS guide fibers 
    if(strupcase(guidetype) eq 'SDSS') then begin
        plate_select_guide_sdss, racen, deccen, epoch=epoch, $
          rerun=rerun, guide_design=guide_design, nguidemax=nguidemax, $
          gminmax_mag=gminmax_mag, tilerad=tilerad, seed=seed, $
          gminmax_band=gminmax_band
    endif
    
    ;; find 2MASS guide fibers 
    if(strupcase(guidetype) eq '2MASS') then begin
        plate_select_guide_2mass, racen, deccen, epoch=epoch, $
          guide_design=guide_design, nguidemax=nguidemax, $
          gminmax_mag=gminmax_mag, tilerad=tilerad, jkminmax=jkminmax, seed=seed, $
          gminmax_band=gminmax_band
    endif

    ;; find USNOB guide fibers 
    if(strupcase(guidetype) eq 'USNOB') then begin
        plate_select_guide_usnob, racen, deccen, epoch=epoch, $
          guide_design=guide_design, nguidemax=nguidemax, $
          gminmax_mag=gminmax_mag, tilerad=tilerad, jkminmax=jkminmax, seed=seed, $
          gminmax_band=gminmax_band
    endif

    if(n_tags(guide_design) gt 0) then begin
        guide_design.pointing=pointing
        guide_design.offset=0

        if(keyword_set(guide_lambda_eff)) then $
          guide_design.lambda_eff= guide_lambda_eff

        plate_ad2xy, definition, default, pointing, 0L, $
          guide_design.target_ra, guide_design.target_dec, $
          guide_design.lambda_eff, xf=xf, yf=yf
        guide_design.xf_default=xf
        guide_design.yf_default=yf
        
        pdata= ptr_new(guide_design)
        hdrstr=plate_struct_combine(default, definition)
        outhdr=struct2lines(hdrstr)
        outhdr=[outhdr, $
                'pointing '+strtrim(string(pointing),2), $
                'epoch '+strtrim(string(epoch, f='(f40.8)'),2), $
                'platedesign_version '+platedesign_version()]
        if(keyword_set(rerun)) then $
          outhdr=[outhdr, 'rerun '+strtrim(string(rerun),2)]
        yanny_write, guidefile, pdata, hdr=outhdr
        ptr_free, pdata
    endif
endif else begin
	check_file_exists, guidefile, plateid=plateid
    in_guide_design= yanny_readone(guidefile, /anon)
    guide_design= replicate(design_blank(/guide), $
                            n_elements(in_guide_design))
    struct_assign, in_guide_design, guide_design, /nozero
endelse

if(n_tags(guide_design) eq 0) then $
  message, color_string('No guides found!', 'red', 'bold')

return, guide_design

end
