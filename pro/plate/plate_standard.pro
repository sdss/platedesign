;+
; NAME:
;   plate_standard 
; PURPOSE:
;   Return standards for a given plate set up
; CALLING SEQUENCE:
;   stds= plate_standard(definition, default, pointing, offset)
; REVISION HISTORY:
;   7-May-2008  MRB, NYU
;-
;------------------------------------------------------------------------------
function plate_standard, definition, default, pointing, offset, rerun=rerun

if(NOT tag_exist(default, 'PLATEDESIGNSTANDARDS')) then begin
    return, 0
endif 

designid= long(definition.designid)

;; what instruments
instruments= strsplit(default.instruments, /extr)
platedesignstandards= strsplit(default.platedesignstandards, /extr)
standardtype= strsplit(default.standardtype, /extr)
for i=0L, n_elements(platedesignstandards)-1L do begin
    curr_inst=platedesignstandards[i]
    curr_type=standardtype[i]
    iinst=where(instruments eq curr_inst, ninst)
    if(ninst eq 0) then $
      message, 'no instrument '+ curr_inst
    
    ;; file name
    outdir= getenv('PLATELIST_DIR')+'/designs/'+ $
            string((designid/100L)*100L, f='(i6.6)')
    stdfile=outdir+'/plateStandard'+curr_inst+'-'+ $
            string(designid, f='(i6.6)')+ $
            '-p'+strtrim(string(pointing),2)+ $
            '-o'+strtrim(string(offset),2)+'.par'
    
    ;; if file is already made, just read it in
    if(NOT file_test(stdfile)) then begin
        ;; what is center for this pointing and offset?
        plate_center, definition, default, pointing, offset, $
                      racen=racen, deccen=deccen
        
        if(curr_type eq 'SDSS') then begin
            ;; find SDSS standards and assign them
            plate_select_sphoto_sdss, racen, deccen, $
              rerun=rerun, sphoto_mag=sphoto_mag, $
              sphoto_design= sphoto_design, tilerad=tilerad
        endif 
        
        if(curr_type eq '2MASS') then begin
            ;; find 2MASS standards and assign them
            plate_select_sphoto_2mass, racen, deccen, $
              sphoto_mag=sphoto_mag, $
              sphoto_design= sphoto_design, tilerad=tilerad
        endif

        if(n_tags(sphoto_design) gt 0) then begin
            sphoto_design.pointing=pointing
            sphoto_design.offset=offset
            sphoto_design.holetype=curr_inst
            plate_ad2xy, definition, default, pointing, offset, $
                         sphoto_design.target_ra, $
                         sphoto_design.target_dec, $
                         xf=xf, yf=yf
            sphoto_design.xf_default=xf
            sphoto_design.yf_default=yf
        endif
        
        ;; NEED TO WRITE HEADER
        if(n_tags(sphoto_design) gt 0) then begin
            pdata= ptr_new(sphoto_design)
            yanny_write, stdfile, pdata
        endif
    endif else begin
        in_sphoto_design= yanny_readone(stdfile, /anon)
        sphoto_design= replicate(design_blank(), n_elements(in_sphoto_design))
        struct_assign, in_sphoto_design, sphoto_design, /nozero
    endelse
endfor

return, sphoto_design

end
