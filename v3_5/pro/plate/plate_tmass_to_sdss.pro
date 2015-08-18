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
;   21-Jul-2008  Parameters changed by MRB, NYU
;-
;------------------------------------------------------------------------------
function plate_tmass_to_sdss, jmag, hmag, kmag

   nstar = n_elements(jmag)
   if (nstar EQ 0) then return, 0
   if (n_elements(hmag) NE nstar OR n_elements(kmag) NE nstar) then $
    message, 'Inconsistent input dimensions'

   mag = fltarr(5,nstar)
   mag[0,*] = jmag + 3.516 + 5.9443 * ((jmag - kmag)-0.5)
   mag[1,*] = jmag + 1.895 + 3.2425 * ((jmag - kmag)-0.5)
   mag[2,*] = jmag + 1.259 + 1.6908 * ((jmag - kmag)-0.5)
   mag[3,*] = jmag + 1.039 + 1.1022 * ((jmag - kmag)-0.5)
   mag[4,*] = jmag + 0.939 + 0.6665 * ((jmag - kmag)-0.5)

   return, mag
end
;------------------------------------------------------------------------------
