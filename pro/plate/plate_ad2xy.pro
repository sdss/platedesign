;+
; NAME:
;   plate_ad2xy
; PURPOSE:
;   Get xfocal and yfocal for targets on SDSS plate
; CALLING SEQUENCE:
;   plate_ad2xy, definition, default, pointing, offset, ra, dec, $
;     xfocal=, yfocal=
; INPUTS:
;   definition - plate definition structure
;   default - plate default structure
;   ra, dec - target coords
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
pro plate_ad2xy, definition, default, pointing, offset, ra, dec, $
                 xfocal=xfocal, yfocal=yfocal, lst=lst, airtemp=airtemp

ntargets=n_elements(ra)

;; what is our raCen and decCen for this pointing and offset
plate_center, definition, default, pointing, offset, $
              racen=racen, deccen=deccen

;; convert targets to xfocal and yfocal for this pointing, offset
ad2xyfocal, ra, dec, xfocal, yfocal, $
            racen=racen, deccen=deccen, lst=lst, $
            airtemp=airtemp

return
end
