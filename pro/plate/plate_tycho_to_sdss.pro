;+
; NAME:
;   plate_tycho_to_sdss
;
; PURPOSE:
;   Approximately convert Tycho magnitudes to SDSS magnitudes
;
; CALLING SEQUENCE:
;   mag = plate_tycho_to_sdss(bmag, vmag)
;
; INPUTS:
;   bmag       - Tycho B magnitude(s) [N]
;   vmag       - Tycho V magnitude(s) [N]
;
; OPTIONAL INPUTS:
;
; OUTPUTS:
;   mag        - SDSS magnitudes [5,N]
;
; OPTIONAL OUTPUTS:
;
; COMMENTS:
;   These conversions are based upon the posting sdss-spectro/766.
;
; EXAMPLES:
;
; BUGS:
;
; REVISION HISTORY:
;   17-Oct-2007  Written by D. Schlegel, LBL
;-
;------------------------------------------------------------------------------
function plate_tycho_to_sdss, bmag, vmag

   nstar = n_elements(bmag)
   if (nstar EQ 0) then return, 0
   if (n_elements(vmag) NE nstar) then $
    message, 'Inconsistent input dimensions'

   mag = fltarr(5,nstar)
   mag[0,*] = vmag - 0.024 + 2.317 * (bmag - vmag)
   mag[1,*] = vmag - 0.081 + 0.544 * (bmag - vmag)
   mag[2,*] = vmag + 0.140 - 0.477 * (bmag - vmag)
   mag[3,*] = vmag + 0.341 - 1.002 * (bmag - vmag)
   mag[4,*] = vmag + 0.509 - 1.360 * (bmag - vmag)

   return, mag
end
;------------------------------------------------------------------------------
