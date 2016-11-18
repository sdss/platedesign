;+
; NAME:
;   adr
; PURPOSE:
;   Calculate observed altitude in presence of ADR, given true altitude
; CALLING SEQUENCE:
;   adr= adr( trualt [, pressure=, temperature=, lambda=, /pr72] )
; INPUTS:
;   trualt - [N] true altitude(s), in deg
; OPTIONAL KEYWORDS:
;   /pr72 - Use Peck & Reeder (1972) for refractive index
; OPTIONAL INPUTS:
;   pressure - air pressure, millibars (default 1013.25)
;   temperature - temperature, C (default 5)
;   lambda - wavelength, angstroms (default 5500)
;   fhumid - water vapor pressor, mm Hg (default 8)
; OUTPUTS:
;   adr - [N] refraction relative to 5500 in arcsec
; COMMENTS:
;   Uses formulae from Filippenko 1982, PASP, 94, 715
; REVISION HISTORY:
;   26-Jun-2009  Written by MRB, NYU
;-
;------------------------------------------------------------------------------
function adr, trualt, pressure=pressure, $
              temperature=temperature, lambda=lambda, $
              pr72=pr72, fhumid=fhumid, reflambda=reflambda

if(NOT keyword_set(reflambda)) then reflambda=5500.
if(NOT keyword_set(lambda)) then lambda=5500.
if(NOT keyword_set(pressure)) then pressure=1013.25
if(n_elements(fhumid) eq 0) then fhumid=8.
if(n_elements(temperature) eq 0) then temperature=5.

;; lambda in microns
mlambda=lambda/10000.
mreflambda=reflambda/10000.

;; 1 bar = 75.01 cmHg
;; 1 bar = 750.1 mmHg
;; 1 millibar = 0.7501 mmHg
mmhg= pressure*0.7501

if(NOT keyword_set(pr72)) then begin
   ;; Eq. 1 of Filippenko (1982), (n-1) 10^6 = ...
   irefract6= 64.328+ 29498.1/(146-(1./mlambda)^2)+ 255.4/(41.-(1./mlambda)^2)
   irefract6_ref= 64.328+ 29498.1/(146-(1./mreflambda)^2)+ $
                  255.4/(41.-(1./mreflambda)^2)
endif else begin
   ;; Eq. 3 of Peck & Reeder (1972), (n-1) 10^8 = 
   irefract8= 8060.51+(2480990./(132.274-(1./mlambda)^2))+ $
              (17455.7/(39.32957-(1./mlambda)^2))
   irefract8_ref= 8060.51+(2480990./(132.274-(1./mreflambda)^2))+ $
                  (17455.7/(39.32957-(1./mreflambda)^2))
   irefract6= irefract8*0.01
   irefract6_ref= irefract8_ref*0.01
endelse

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
fhoffset= fhumid*(0.0624-0.000680/mlambda^2)/(1.+0.003661*temperature)
irefract6_f= irefract6_tp- fhoffset
fhoffset_ref= fhumid*(0.0624-0.000680/mreflambda^2)/(1.+0.003661*temperature)
irefract6_f_ref= irefract6_tp_ref- fhoffset_ref

;; Now convert to shift
;; delta_r = (r(lambda)-r(5500)) = 206265*(n(lambda)-n(5500))*tan z
;; Yields DR relative to 5500 in arcsec
zenith=(90.D)-trualt
tanzenith=tan(zenith*!DPI/180.D)
adr= (206265.D)*(1.d-6)*(irefract6_f-irefract6_f_ref)*tanzenith

return, adr

end
