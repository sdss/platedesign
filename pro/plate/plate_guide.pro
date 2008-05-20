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
function plate_guide, definition, default, pointing, rerun=rerun

if(NOT tag_exist(default.guidetype)) then begin
    return, 0
endif 

;; file name
guidefile=outdir+'/plateGuide-'+ $
          string(designid, f='(i6.6)')+ $
          '-p'+strtrim(string(pointing),2)+'.par'

if(NOT file_test(guidefile)) then begin
    ;; what is center for this pointing?
    plate_center, definition, default, pointing, 0L, $
                  racen=racen, deccen=deccen
    
    ;; find SDSS guide fibers 
    if(default.guidetype eq 'SDSS') then begin
        plate_select_guide_sdss, racen, deccen, epoch=epoch, $
          rerun=rerun, guide_design=guide_design
        if(n_tags(guide_design) gt 0) then begin
            plate_ad2xy, definition, default, pointing, 0L, $
                         guide_design.target_ra, $
                         guide_design.target_dec, $
                         xf=xf, yf=yf
            guide_design.xf_default=xf
            guide_design.yf_default=yf
        endif
    endif
    
    ;; find 2MASS guide fibers 
    if(default.guidetype eq '2MASS') then begin
        plate_select_guide_2mass, racen, deccen, epoch=epoch, $
          guide_design=guide_design
        if(n_tags(guide_design) gt 0) then begin
            plate_ad2xy, definition, default, pointing, 0L, $
                         guide_design.target_ra, $
                         guide_design.target_dec, $
                         xf=xf, yf=yf
            guide_design.xf_default=xf
            guide_design.yf_default=yf
        endif
    endif
    
    ;; NEED TO WRITE HEADER
    if(n_tags(guide_design) gt 0) then begin
        pdata= ptr_new(guide_design)
        yanny_write, stdfile, pdata
    endif
endif else begin
    guide_design= yanny_readone(guidefile)
endelse

return, guide_design

end
