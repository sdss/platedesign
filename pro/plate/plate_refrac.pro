;+
; NAME:
;   plate_refrac
; PURPOSE:
;   Convert RA/DEC to ALT/AZ with refraction at APO 
; CALLING SEQUENCE:
;   plate_refrac, observatory, ra, dec [, lat=, airtemp=, lst=, 
;     alt=, az=, /norefrac]
; INPUTS:
;   observatory - 'APO' or 'LCO'
;   ra,dec     - [N] arrays of true locations (J2000 deg)
; OPTIONAL INPUTS:
;   lat        - latitude of observatory (default to 32.7803 deg, APO)
;   airtemp    - air temperature (in C; default to 5)
;   lst        - anticipated LST of observation (in deg; default to
;                ra, that is HA=0)
; OPTIONAL KEYWORDS:
;   /norefrac  - just do transformation to ALT/AZ, no refraction
; OUTPUTS:
;   alt        - altitude from horizon (deg)
;   az         - azimuth east of north (deg)
; COMMENTS:
;   HA= LST-RA
;   Without setting LST explicitly, it assumes that you will observe
;     at an hour angle of 0. 
;   Assumes pressure = 1013.25 millbars *
;      exp(-2788./(29.3*airtemp+273.155)) (unless input)
;   Assumes wavelength near 5500 angstroms
; REVISION HISTORY:
;   26-Oct-2006  Written by MRB, NYU (cribbed from PRIMUS code by Burles)
;-
;------------------------------------------------------------------------------
pro plate_refrac, observatory, ra, dec, lat=lat, airtemp=airtemp, lst=lst, $
  alt=alt, az=az, norefrac=norefrac, pressure=pressure

if(size(observatory,/tname) ne 'STRING') then $
  message, 'observatory must be set to STRING type, with value "LCO" or "APO"'

if(strupcase(observatory) ne 'APO' and $
   strupcase(observatory) ne 'LCO') then $
  message, 'Must set observatory to APO or LCO'

if n_elements(lst) EQ 0 then lst = double(ra)

if(strupcase(observatory) eq 'APO') then begin
    if n_elements(lat) EQ 0 then lat = 32.7797556D
    if n_elements(height) EQ 0 then height = 2797.D
    if n_elements(airtemp) EQ 0 then airtemp = 5.D
    airtemp_k=airtemp+273.155   ; C to Kelvin
    if n_elements(pressure) EQ 0 then $
      pressure= 1013.25 * exp(-height/(29.3*airtemp_k))
endif 

if(strupcase(observatory) eq 'LCO') then begin
    if n_elements(lat) EQ 0 then lat = -29.0146D
    if n_elements(height) EQ 0 then height = 2380.D
    if n_elements(airtemp) EQ 0 then airtemp = 12.D
    airtemp_k=airtemp+273.155   ; C to Kelvin
    if n_elements(pressure) EQ 0 then $
      pressure= 1013.25 * exp(-height/(29.3*airtemp_k))
endif 

ha = lst - ra
hadec2altaz, ha, dec, lat, alt, az
if(NOT keyword_set(norefrac)) then $
  alt= plate_refract_list(alt, epsilon=0.00001, temperature=airtemp_k, $
                          /to_observed, pressure=pressure, $
                          altitude=height)

end
