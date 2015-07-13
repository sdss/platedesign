;+
; NAME:
;   plate_xy2ad
; PURPOSE:
;   Get RA and Dec from xfocal, yfocal for targets on SDSS plate
; CALLING SEQUENCE:
;   plate_xy2ad, definition, default, pointing, offset, xfocal, yfocal, $
;     lambda, ra=, dec= [, lst=, airtemp= ]
; INPUTS:
;   definition - plate definition structure
;   default - plate default structure
;   xfocal, yfocal - [N] position in focal plane in mm
;   lambda     - [N] optimum wavelength in angstroms
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
                 lambda, ra=ra, dec=dec, lst=lst, airtemp=airtemp

observatory= get_observatory(definition, default)

if(tag_indx(definition, 'PLATESCALE') ne -1) then $
  platescale= float(definition.platescale)
if(tag_indx(definition, 'PLATESCALE_CUBIC') ne -1) then $
  cubic= float(definition.platescale_cubic)
if(keyword_set(cubic) ne 0  or $
   keyword_set(platescale) ne 0) then $
  splog, 'SETTING EXPLICIT PLATE SCALE! ONLY SHOULD BE DONE FOR GUIDE TESTS!'

ntargets=n_elements(xfocal)

;; what is our raCen and decCen for this pointing and offset
plate_center, definition, default, pointing, offset, $
              racen=racen, deccen=deccen

;; convert targets to xfocal and yfocal for this pointing, offset
xyfocal2ad, observatory, xfocal, yfocal, ra, dec, $
  racen=racen, deccen=deccen, lst=lst, $
  airtemp=airtemp, lambda=lambda, platescale=platescale, $
  cubic=cubic

return
end
