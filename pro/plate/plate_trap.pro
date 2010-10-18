;+
; NAME:
;   plate_trap 
; PURPOSE:
;   Return trap for a given plate set up
; CALLING SEQUENCE:
;   trap= plate_trap(definition, default, pointing)
; BUGS:
;   Hard-coded tycvlim of 7.5
; COMMENTS:
;   Traps *always* out to 1.49 deg (maximum plate radius)
; REVISION HISTORY:
;   7-May-2008  MRB, NYU
;-
;------------------------------------------------------------------------------
function plate_trap, definition, default, pointing, offset, rerun=rerun

designid= long(definition.designid)

;; file name
outdir= design_dir(designid)
trapfile=outdir+'/plateTrap-'+ $
         string(designid, f='(i6.6)')+ $
         '-p'+strtrim(string(pointing),2)+ $
         '-o'+strtrim(string(offset),2)+'.par'

trap_design=0
if(NOT file_test(trapfile)) then begin
    ;; what is center for this pointing?
    plate_center, definition, default, pointing, offset, $
                  racen=racen, deccen=deccen

    tycvlimit = 7.5
    tycdat = tycho_read(racen=racen, deccen=deccen, radius=1.48, $
                        epoch=default_epoch())
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
        trap_design.pointing= pointing
        trap_design.offset= offset
        trap_design.pmra= tycdat.pmra
        trap_design.pmdec= tycdat.pmde
        trap_design.epoch= default_epoch()
        
        plate_ad2xy, definition, default, pointing, offset, $
                     trap_design.target_ra, $
                     trap_design.target_dec, $
                     trap_design.lambda_eff, $
                     xf=xf, yf=yf
        trap_design.xf_default=xf
        trap_design.yf_default=yf
        
        pdata= ptr_new(trap_design)
        hdrstr=struct_combine(default, definition)
        outhdr=struct2lines(hdrstr)
        outhdr=[outhdr, $
                'pointing '+strtrim(string(pointing),2), $
                'offset '+strtrim(string(offset),2), $
                'platedesign_version '+platedesign_version()]
        if(keyword_set(rerun)) then $
          outhdr=[outhdr, 'rerun '+strtrim(string(rerun),2)]
        yanny_write, trapfile, pdata, hdr=outhdr
        ptr_free, pdata
    endif
endif else begin
	check_file_exists, trapfile
    in_trap_design= yanny_readone(trapfile, /anon)
    trap_design= replicate(design_blank(), n_elements(in_trap_design))
    struct_assign, in_trap_design, trap_design, /nozero
endelse

return, trap_design

end
