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
for i=0L, n_elements(platedesignskies)-1L do begin
    curr_inst=platedesignskies[i]
    iinst=where(instruments eq curr_inst, ninst)
    if(ninst eq 0) then $
      message, 'no instrument '+ curr_inst

    ;; file name
    outdir= getenv('PLATELIST_DIR')+'/designs/'+ $
            string((designid/100L)*100L, f='(i6.6)')
    skyfile=outdir+'/plateSky'+curr_inst+'-'+ $
            string(designid, f='(i6.6)')+ $
            '-p'+strtrim(string(pointing),2)+ $
            '-o'+strtrim(string(offset),2)+'.par'
    
    if(NOT file_test(skyfile)) then begin
        ;; what is center for this pointing and offset?
        plate_center, definition, default, pointing, offset, $
                      racen=racen, deccen=deccen
        
        nsky=2L*fibercounts.ntot[iinst,isky,pointing-1L,offset] 
        
        ;; find SDSS skies and assign them
        plate_select_sky_sdss, racen, deccen, $
          nsky=nsky, seed=seed, rerun=rerun, $
          sky_design=sky_design
        sky_design.pointing=pointing
        sky_design.offset=offset
        sky_design.holetype=curr_inst
        
        ;; NEED TO WRITE HEADER
        if(n_tags(sky_design) gt 0) then begin
            pdata= ptr_new(sky_design)
            yanny_write, skyfile, pdata
        endif
    endif else begin
        sky_design= yanny_readone(skyfile, /anon)
    endelse
endfor 

return, sky_design

end
