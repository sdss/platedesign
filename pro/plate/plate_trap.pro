;+
; NAME:
;   plate_trap 
; PURPOSE:
;   Return trap for a given plate set up
; CALLING SEQUENCE:
;   trap= plate_trap(definition, default, pointing)
; BUGS:
;   Hard-coded 1.49 deg and tycvlim of 7.5
; REVISION HISTORY:
;   7-May-2008  MRB, NYU
;-
;------------------------------------------------------------------------------
function plate_trap, definition, default, pointing, offset, rerun=rerun

designid= long(definition.designid)

;; file name
outdir= getenv('PLATELIST_DIR')+'/designs/'+ $
        string((designid/100L)*100L, f='(i6.6)')
trapfile=outdir+'/plateTrap-'+ $
         string(designid, f='(i6.6)')+ $
         '-p'+strtrim(string(pointing),2)+ $
         '-o'+strtrim(string(offset),2)+'.par'

if(NOT file_test(trapfile)) then begin
    ;; what is center for this pointing?
    plate_center, definition, default, pointing, offset, $
                  racen=racen, deccen=deccen

    tycvlimit = 7.5
    tycdat = tycho_read(racen=racen, deccen=deccen, radius=1.49)
    if (keyword_set(tycdat)) then begin
        ;; Sort so that we add the brightest Tycho stars first.
        tycdat = tycdat[sort(tycdat.vtmag)]
        indx = where(tycdat.vtmag LT tycvlimit, ct)
        if (ct EQ 0) then tycdat = 0 $
        else tycdat = tycdat[indx]
    endif

    if(n_tags(tycdat) gt 0) then begin
        trap_design= replicate(design_blank(/trap), n_elements(tycdat))
        trap_design.target_ra= tycdat.ramdeg
        trap_design.target_dec= tycdat.demdeg
        
        plate_ad2xy, definition, default, pointing, 0L, $
                     trap_design.target_ra, $
                     trap_design.target_dec, $
                     xf=xf, yf=yf
        trap_design.xf_default=xf
        trap_design.yf_default=yf
        
        ;; NEED TO WRITE HEADER
        pdata= ptr_new(trap_design)
        yanny_write, trapfile, pdata
    endif
endif else begin
    in_trap_design= yanny_readone(trapfile, /anon)
    trap_design= replicate(design_blank(), n_elements(in_trap_design))
    struct_assign, in_trap_design, trap_design, /nozero
endelse

return, trap_design

end
