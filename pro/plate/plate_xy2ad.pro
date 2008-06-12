;+
; NAME:
;   plate_xy2ad
; PURPOSE:
;   Get RA and Dec from xfocal, yfocal for targets on SDSS plate
; CALLING SEQUENCE:
;   plate_xy2ad, definition, default, pointing, offset, xfocal, yfocal, $
;     ra=, dec=
; INPUTS:
;   definition - plate definition structure
;   default - plate default structure
;   xfocal, yfocal - position in focal plane in mm
;   pointing - pointing # 
;   offset - offset # 
; OPTIONAL INPUTS:
;   lst        - LST of observation (defaults to racen)
;   airtemp    - Design temperature (in C, default to 5)
; OUTPUTS:
;   ra, dec - target coords
; COMMENTS:
;   Required in definition structure:
;     raCen[npointings]
;     decCen[npointings]
;     dRa[noffsets]
;     dDec[noffsets]
; REVISION HISTORY:
;   8-May-2008  Written by MRB, NYU
;-
pro plate_xy2ad, definition, default, pointing, offset, xfocal, yfocal, $
                 ra=ra, dec=dec, lst=lst, airtemp=airtemp

ntargets=n_elements(xfocal)

;; what is our raCen and decCen for this pointing and offset
plate_center, definition, default, pointing, offset, $
              racen=racen, deccen=deccen

;; convert targets to xfocal and yfocal for this pointing, offset
xyfocal2ad, xfocal, yfocal, ra, dec, $
  racen=racen, deccen=deccen, lst=lst, $
  airtemp=airtemp

return
end
