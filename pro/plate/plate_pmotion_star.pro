;+
; NAME:
;   plate_pmotion_star
; PURPOSE:
;   Find any available proper motion for a star
; CALLING SEQUENCE:
;   plate_pmotion_star, ra, dec, pmra=, pmdec=, src= [, racen=, $
;      deccen=, tilerad= ]
; INPUTS:
;   ra, dec - [N] J2000 deg coords
; OPTIONAL INPUTS:
;   racen, deccen, tilerad - J2000 deg, bounding coords
; OUTPUTS:
;   pmra, pmdec - [N] mas/yr
;   src - [N] source used (e.g. 'USNO-B')
; COMMENTS:
;   Much faster if RACEN, DECCEN, TILERAD are specified, and all RA
;   and DEC values live within TILERAD of RACEN, DECCEN.
; REVISION HISTORY:
;   10-Aug-2009  Written by D. Schlegel, LBL
;-
;------------------------------------------------------------------------------
pro plate_pmotion_star, ra, dec, pmra=pmra, pmdec=pmdec, src=src, $
                        racen=racen, deccen=deccen, tilerad=tilerad

matchrad = 2./3600
pmra=dblarr(n_elements(ra))
pmdec=dblarr(n_elements(ra))
src=strarr(n_elements(ra))

;; if RACEN, DECCEN, TILERAD specified, we can do only one USNO_READ
;; call, which is much faster.
if(n_elements(racen) gt 0 OR $
   n_elements(deccen) gt 0 OR $
   n_elements(tilerad) gt 0) then begin

    ;; sanity checks
    if(n_elements(racen) eq 0 OR $
       n_elements(deccen) eq 0 OR $
       n_elements(tilerad) eq 0) then $
      message, 'If one of RACEN, DECCEN, TILERAD is set, all must be'
    if(n_elements(racen) ne 1 OR $
       n_elements(deccen) ne 1 OR $
       n_elements(tilerad) ne 1) then $
      message, 'RACEN, DECCEN, TILERAD must all have ONE element'
    spherematch, racen, deccen, ra, dec, tilerad, m1, m2, max=0
    if(n_elements(m1) ne n_elements(ra)) then $
      message, 'RA, DEC values further than TILERAD of RACEN,DECCEN!'

    dat= usno_read(racen, deccen, tilerad)
    spherematch, ra, dec, dat.ra, dat.dec, matchrad, m1, m2, max=0
    isort= sort(m1)
    iuniq= uniq(m1[isort])
    istart=0L
    for i=0L, n_elements(iuniq)-1L do begin
        iend=iuniq[i]
        icurr= isort[istart:iend]
        iusno= m2[icurr[0]]
        pmra[m1[icurr]]= dat[iusno].mura
        pmdec[m1[icurr]]= dat[iusno].mudec
        src[m1[icurr]]= 'USNO-B'
        istart=iend+1L
    endfor
    
    return
endif

;; otherwise assume nothing and do each individually
for i=0L, n_elements(ra)-1L do begin
    dat1 = usno_read(ra[i], dec[i], matchrad)
    if (n_elements(dat1) EQ 1) then begin
        if (tag_exist(dat1,'MURA') EQ 0) then $
          message, 'Old version of USNO catalog is set up!'
        pmra[i]= dat1.mura
        pmdec[i]= dat1.mudec
        src[i]= 'USNO-B'
    endif
endfor

return
end
;------------------------------------------------------------------------------
