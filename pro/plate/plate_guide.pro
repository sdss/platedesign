;+
; NAME:
;   plate_guide 
; PURPOSE:
;   Return guide for a given plate set up
; CALLING SEQUENCE:
;   guide= plate_guide(definition, default, pointing)
; REVISION HISTORY:
;   7-May-2008  MRB, NYU
;-
;------------------------------------------------------------------------------
function plate_guide, definition, default, pointing, rerun=rerun, $
  epoch=epoch, clobber=clobber

designid= long(definition.designid)

if(tag_exist(default, 'GUIDEMAG_MINMAX')) then begin
    gminmax=float(strsplit(default.guidemag_minmax, /extr))
endif

if(tag_exist(default, 'NGUIDEMAX')) then begin
    nguidemax=long(default.nguidemax)
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

    ;; what is center for this pointing?
    plate_center, definition, default, pointing, 0L, $
                  racen=racen, deccen=deccen
    
    ;; find SDSS guide fibers 
    if(guidetype eq 'SDSS') then begin
        plate_select_guide_sdss, racen, deccen, epoch=epoch, $
          rerun=rerun, guide_design=guide_design, nguidemax=nguidemax, $
          gminmax=gminmax
        if(n_tags(guide_design) gt 0) then begin
            plate_ad2xy, definition, default, pointing, 0L, $
              guide_design.target_ra, guide_design.target_dec, $
              guide_design.lambda_eff, xf=xf, yf=yf
            guide_design.xf_default=xf
            guide_design.yf_default=yf
        endif
    endif
    
    ;; find 2MASS guide fibers 
    if(guidetype eq '2MASS') then begin
        plate_select_guide_2mass, racen, deccen, epoch=epoch, $
          guide_design=guide_design, nguidemax=nguidemax, $
          gminmax=gminmax
        if(n_tags(guide_design) gt 0) then begin
            plate_ad2xy, definition, default, pointing, 0L, $
              guide_design.target_ra, guide_design.target_dec, $
              guide_design.lambda_eff, xf=xf, yf=yf
            guide_design.xf_default=xf
            guide_design.yf_default=yf
        endif
    endif
    
    if(n_tags(guide_design) gt 0) then begin
        guide_design.pointing=pointing
        guide_design.offset=0
        
        pdata= ptr_new(guide_design)
        hdrstr=struct_combine(default, definition)
        outhdr=struct2lines(hdrstr)
        outhdr=[outhdr, $
                'pointing '+strtrim(string(pointing),2), $
                'epoch '+strtrim(string(epoch, f='(f40.8)'),2), $
                'platedesign_version '+platedesign_version()]
        if(keyword_set(rerun)) then $
          outhdr=[outhdr, 'rerun '+strtrim(string(rerun),2)]
        yanny_write, guidefile, pdata, hdr=outhdr
    endif
endif else begin
    in_guide_design= yanny_readone(guidefile, /anon)
    guide_design= replicate(design_blank(/guide), $
                            n_elements(in_guide_design))
    struct_assign, in_guide_design, guide_design, /nozero
endelse

return, guide_design

end
