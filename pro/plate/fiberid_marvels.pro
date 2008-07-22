;+
; NAME:
;   fiberid_marvels
; PURPOSE:
;   assign fiberid's to a list of MARVELS targets
; CALLING SEQUENCE:
;   fiberid= fiberid_marvels(design)
; INPUTS:
;   design - [N] struct array of targets, in design_blank() form
;            Required tags are .XF_DEFAULT, .YF_DEFAULT
; OUTPUTS:
;   fiberid - [N] 1-indexed list of fibers 
; OPTIONAL OUTPUTS:
;   block - [N] block for each fiber
; OPTIONAL KEYWORDS:
;   /nosky - do not attempt to assign any of the sky fibers
;   /nostd - do not attempt to assign any of the standard fibers
;   /noscience - do not attempt to assign any of the science fibers
; COMMENTS:
;   DUMMY CODE --- WE DON'T KNOW MARVELS FIBER LAYOUT YET!
; REVISION HISTORY:
;   4-Jun-2008 MRB, NYU 
;-
function fiberid_marvels, default, fibercount, design, $
                          minstdinblock=minstdinblock, $
                          minskyinblock=minskyinblock, $
                          nosky=nosky, noscience=noscience, nostd=nostd, $
                          quiet=quiet, block=block

nfiber=60L
fiberid=lonarr(n_elements(design))
npointings= long(default.npointings)

nused=0L
if(NOT keyword_set(nostd)) then begin
    ;; assign standards, if any exist
    for i=1L, npointings do begin
        istd= where(strupcase(design.targettype) eq 'STANDARD' AND $
                    design.pointing eq i, nstd)
        if(nstd gt 0) then begin
            iinst=where(strupcase(fibercount.instruments) eq 'MARVELS', ninst)
            itype=where(strupcase(fibercount.targettypes) eq 'STANDARD', ntype)
            nmax=long(total(fibercount.ntot[iinst, itype, i-1L, *]))

            ifiber=shuffle_indx(nstd, num_sub=nmax)
            fiberid[istd[ifiber]]=nused+lindgen(nmax)+1L
            nused=nused+nmax
        endif
    endfor
endif

if(NOT keyword_set(nosky)) then begin
    ;; assign skies, if any exist
    for i=1L, npointings do begin
        isky= where(strupcase(design.targettype) eq 'SKY' AND $
                    design.pointing eq i, nsky)
        if(nsky gt 0) then begin
            iinst=where(strupcase(fibercount.instruments) eq 'MARVELS', ninst)
            itype=where(strupcase(fibercount.targettypes) eq 'SKY', ntype)
            nmax=long(total(fibercount.ntot[iinst, itype, i-1L, *]))

            ifiber=shuffle_indx(nsky, num_sub=nmax)
            fiberid[isky[ifiber]]=nused+lindgen(nmax)+1L
            nused=nused+nmax
        endif
    endfor
endif

if(NOT keyword_set(noscience)) then begin
    ileft= where(strupcase(design.targettype) ne 'SKY' AND $
                 strupcase(design.targettype) ne 'STANDARD', nleft)
    if(nleft gt 0) then begin
        iinst=where(strupcase(fibercount.instruments) eq 'MARVELS', ninst)
        itype=where(strupcase(fibercount.targettypes) eq 'SCIENCE', ntype)
        nmax=long(total(fibercount.ntot[iinst, itype, *, *]))

        ifiber=shuffle_indx(nleft, num_sub=nmax)
        fiberid[ileft[ifiber]]=nused+lindgen(nmax)+1L
        nused=nused+nmax
    endif 
endif

block= lonarr(n_elements(fiberid))+1L
        
return, fiberid

end

