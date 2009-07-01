;+
; NAME:
;   adr
; PURPOSE:
;   Calculate observed altitude in presence of ADR, given true altitude
; CALLING SEQUENCE:
;   adr= adr( trualt [, height=, pressure=, temperature=, lambda=] )
; INPUTS:
;   trualt - [N] true altitude(s), in deg
; OPTIONAL INPUTS:
;   height - height of observing location, meters (default 0)
;   pressure - air pressure, millibars (default 1013.25)
;   temperature - temperature, C (default 5)
;   lambda - wavelength, angstroms (default 5500)
; OUTPUTS:
;   adr - [N] refraction relative to 5500 in arcsec
; COMMENTS:
;   Uses formulae from Filippenko 1982, PASP, 94, 715
; REVISION HISTORY:
;   26-Jun-2009  Written by MRB, NYU
;-
;------------------------------------------------------------------------------
function adr, trualt, height=height, pressure=pressure, $
              temperature=temperature, lambda=lambda

reflambda=5013.
if(NOT keyword_set(lambda)) then lambda=5500.
if(NOT keyword_set(height)) then height=0.
if(NOT keyword_set(pressure)) then pressure=1013.25
if(n_elements(temperature) eq 0) then temperature=5.

;; lambda in microns
mlambda=lambda/10000.
mreflambda=reflambda/10000.

;; 1 bar = 75.01 cmHg
;; 1 bar = 750.1 mmHg
;; 1 millibar = 0.7501 mmHg
mmhg= pressure*0.7501

;; Eq. 1 of Filippenko (1982), (n-1) 10^6 = ...
irefract6= 64.328+ 29498.1/(146-(1./mlambda)^2)+ 255.4/(41.-(1./mlambda)^2)
irefract6_ref= 64.328+ 29498.1/(146-(1./mreflambda)^2)+ $
               255.4/(41.-(1./mreflambda)^2)

;; Eq. 2 of Filippenko (1982), (n-1)_TP = (n-1) x ...
tpfact=(mmhg*(1.+(1.049-0.0157*temperature)*1.e-6*mmhg))/ $
       (720.883*(1.+0.003661*temperature))
irefract6_tp= irefract6* tpfact
irefract6_tp_ref= irefract6_ref* tpfact

;; Eq. 3 of Filippenko (1982), (n-1)_f = (n-1)_TP - ...
;; [I *think*! Both Filippenko and the original Barrell 1951 article
;; are ambiguously worded. I looked at the relevant pages of the
;; enormous Barrell & Sears (1939) article, but I couldn't make much
;; sense of it].
fhumid= 8. ;; in mm Hg, typical value
fhoffset= fhumid*(0.0624-0.000680/mlambda^2)/(1.+0.003661*temperature)
irefract6_f= irefract6_tp- fhoffset
irefract6_f_ref= irefract6_tp_ref- fhoffset

;; Now convert to shift
;; delta_r = (r(lambda)-r(5500)) = 206265*(n(lambda)-n(5500))*tan z
;; Yields DR relative to 5500 in arcsec
zenith=(90.D)-trualt
tanzenith=tan(zenith*!DPI/180.D)
adr= (206265.D)*(1.d-6)*(irefract6_f-irefract6_f_ref)*tanzenith

return, adr

end
