;+
; NAME:
;   plate_ad2xy
; PURPOSE:
;   Get xfocal and yfocal for targets on SDSS plate
; CALLING SEQUENCE:
;   plate_ad2xy, definition, default, pointing, offset, ra, dec, $
;     lambda, xfocal=, yfocal=
; INPUTS:
;   definition - plate definition structure
;   default - plate default structure
;   ra, dec - [N] target coords
;   lambda - [N] desired wavelengths
;   pointing - pointing # 
;   offset - offset # 
; OPTIONAL INPUTS:
;   lst        - LST of observation (defaults to racen)
;   airtemp    - Design temperature (in C, default to 5)
;   pmra, pmdec, fromepoch - [N] proper motions in mas/yr, and epoch of
;                            given ra, dec values in yrs AD (must ALL
;                            be set if ANY are)
;   toepoch - epoch to design at for proper motions (must be set if
;             any of PMRA, PMDEC, FROMEPOCH are set)
; OUTPUTS:
;   xfocal, yfocal - position in focal plane in mm
; COMMENTS:
;   Required in definition structure:
;     raCen[npointings]
;     decCen[npointings]
;     dRa[noffsets]
;     dDec[noffsets]
; REVISION HISTORY:
;   8-May-2008  Written by MRB, NYU
;-
pro plate_ad2xy, definition, default, pointing, offset, in_ra, in_dec, $
                 lambda, xfocal=xfocal, yfocal=yfocal, lst=lst, $
                 airtemp=airtemp, pmra=pmra, pmdec=pmdec, $
                 fromepoch=fromepoch, toepoch=toepoch

ntargets=n_elements(in_ra)
if(n_elements(in_dec) ne ntargets OR $
   n_elements(lambda) ne ntargets) then $
  message, 'RA, DEC and LAMBDA must all have same # of elements!'

ra=in_ra
dec=in_dec

;; adjust for proper motions
if((n_elements(pmra) gt 0 OR n_elements(pmdec) gt 0 OR $
    n_elements(fromepoch) gt 0 OR n_elements(toepoch) gt 0) AND $
   (n_elements(pmra) eq 0 OR n_elements(pmdec) eq 0 OR $
    n_elements(fromepoch) eq 0 OR n_elements(toepoch) eq 0)) then $
  message, 'Set either all or none of PMRA, PMDEC, FROMEPOCH, TOEPOCH'
if(n_elements(pmra) gt 0) then begin
    if(n_elements(pmra) ne ntargets OR $
       n_elements(pmdec) ne ntargets OR $
       n_elements(fromepoch) ne ntargets) then $
        message, 'PMRA, PMDEC, FROMEPOCH must have same number of '+ $
                 'elements as RA, DEC'
    if(n_elements(toepoch) ne 1) then $
        message, 'TOEPOCH must have only one element!'
    toepoch=toepoch[0]
    depoch= toepoch-fromepoch
    dalpha= pmra*depoch
    ddelta= pmdec*depoch
    secdec=1./cos(dec*!DPI/180.)
    ra= ra+dalpha*secdec
    dec= dec+ddelta
endif 

;; what is our raCen and decCen for this pointing and offset
plate_center, definition, default, pointing, offset, $
              racen=racen, deccen=deccen

;; convert targets to xfocal and yfocal for this pointing, offset
ad2xyfocal, ra, dec, xfocal, yfocal, lambda=lambda, $
            racen=racen, deccen=deccen, lst=lst, $
            airtemp=airtemp, lambda=lambda

return
end
