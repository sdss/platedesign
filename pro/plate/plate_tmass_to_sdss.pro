;+
; NAME:
;   plate_tmass_to_sdss
;
; PURPOSE:
;   Approximately convert 2MASS magnitudes to SDSS magnitudes
;
; CALLING SEQUENCE:
;   mag = plate_tmass_to_sdss(jmag, hmag, kmag)
;
; INPUTS:
;   jmag       - 2MASS J magnitude(s) [N]
;   hmag       - 2MASS H magnitude(s) [N]
;   kmag       - 2MASS K magnitude(s) [N]
;
; OPTIONAL INPUTS:
;
; OUTPUTS:
;   mag        - SDSS magnitudes [5,N]
;
; OPTIONAL OUTPUTS:
;
; COMMENTS:
;   These conversions are made from a very approximate fit between
;   SDSS spectroscopic star colors.
;
; EXAMPLES:
;
; BUGS:
;
; REVISION HISTORY:
;   17-Oct-2007  Written by D. Schlegel, LBL
;-
;------------------------------------------------------------------------------
function plate_tmass_to_sdss, jmag, hmag, kmag

   nstar = n_elements(jmag)
   if (nstar EQ 0) then return, 0
   if (n_elements(hmag) NE nstar OR n_elements(kmag) NE nstar) then $
    message, 'Inconsistent input dimensions'

   mag = fltarr(5,nstar)
   mag[0,*] = jmag + 0.273 + 0.0839 * (jmag - kmag)
   mag[1,*] = jmag + 0.354 + 0.1143 * (jmag - kmag)
   mag[2,*] = jmag + 0.416 + 0.1427 * (jmag - kmag)
   mag[3,*] = jmag + 0.325 + 0.2657 * (jmag - kmag)
   mag[4,*] = jmag + 0.248 + 0.4184 * (jmag - kmag)

   return, mag
end
;------------------------------------------------------------------------------
