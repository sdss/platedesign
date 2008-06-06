;+
; NAME:
;   plate_sky 
; PURPOSE:
;   Return sky for a given plate set up
; CALLING SEQUENCE:
;   sky= plate_sky(definition, default, pointing, offset )
; REVISION HISTORY:
;   7-May-2008  MRB, NYU
;-
;------------------------------------------------------------------------------
function plate_sky, definition, default, pointing, offset, rerun=rerun

if(NOT tag_exist(default, 'PLATEDESIGNSKIES')) then begin
    return, 0
endif 

designid= long(definition.designid)

;; what instruments
instruments= strsplit(default.instruments, /extr)
platedesignskies= strsplit(default.platedesignskies, /extr)
standardtype= strsplit(default.standardtype, /extr)
all_sky_design=0
for i=0L, n_elements(platedesignskies)-1L do begin
    curr_inst=platedesignskies[i]
    iinst=where(instruments eq curr_inst, ninst)
    if(ninst eq 0) then $
      message, 'no instrument '+ curr_inst

    itag= tag_indx(default, 'n'+ $
                   strtrim(string(curr_inst),2)+ $
                   '_sky')
    npointings= long(default.npointings)
    noffsets= long(default.noffsets)
    nsky= 4L*(reform(long(strsplit(default.(itag),/extr)), npointings, $
                     noffsets+1L))[pointing-1L, offset]
    
    if(nsky gt 0) then begin
        ;; file name
        outdir= getenv('PLATELIST_DIR')+'/designs/'+ $
          string((designid/100L)*100L, f='(i6.6)')
        skyfile=outdir+'/plateSky'+curr_inst+'-'+ $
          string(designid, f='(i6.6)')+ $
          '-p'+strtrim(string(pointing),2)+ $
          '-o'+strtrim(string(offset),2)+'.par'
        
        if(file_test(skyfile) eq 0) then begin
            ;; what is center for this pointing and offset?
            plate_center, definition, default, pointing, offset, $
              racen=racen, deccen=deccen
            
            ;; find SDSS skies and assign them
            plate_select_sky_sdss, racen, deccen, $
              nsky=nsky, seed=seed, rerun=rerun, $
              sky_design=sky_design
            sky_design.pointing=pointing
            sky_design.offset=offset
            sky_design.holetype=curr_inst
            plate_ad2xy, definition, default, pointing, offset, $
              sky_design.target_ra, $
              sky_design.target_dec, $
              xf=xf, yf=yf
            sky_design.xf_default=xf
            sky_design.yf_default=yf
            
            if(n_tags(sky_design) gt 0) then begin
                pdata= ptr_new(sky_design)
                hdrstr=struct_combine(default, definition)
                outhdr=struct2lines(hdrstr)
                outhdr=[outhdr, $
                        'pointing '+strtrim(string(pointing),2), $
                        'epoch '+strtrim(string(epoch, f='(f40.8)'),2), $
                        'platedesign_version '+platedesign_version()]
                if(keyword_set(rerun)) then $
                  outhdr=[outhdr, 'rerun '+strtrim(string(rerun),2)]
                yanny_write, skyfile, pdata, hdr=outhdr
            endif
        endif else begin
            in_sky_design= yanny_readone(skyfile, /anon)
            sky_design= replicate(design_blank(), n_elements(in_sky_design))
            struct_assign, in_sky_design, sky_design, /nozero
        endelse
    endif

    if(n_tags(sky_design) gt 0) then begin

        if(n_tags(all_sky_design) eq 0) then $
          all_sky_design=sky_design $
        else $
          all_sky_design=[all_sky_design, sky_design]
    endif
endfor 

return, all_sky_design

end
