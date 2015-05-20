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

observatory= get_observatory(definition, default)

;; what is our raCen and decCen for this pointing and offset
plate_center, definition, default, pointing, offset, $
  racen=racen, deccen=deccen

;; convert targets to xfocal and yfocal for this pointing, offset
ad2xyfocal, observatory, in_ra, in_dec, xfocal, yfocal, lambda=lambda, $
  racen=racen, deccen=deccen, lst=lst, airtemp=airtemp

return
end
