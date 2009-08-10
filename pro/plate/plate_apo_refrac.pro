;+
; NAME:
;   plate_apo_refrac
; PURPOSE:
;   Convert RA/DEC to ALT/AZ with refraction at APO 
; CALLING SEQUENCE:
;   plate_apo_refrac, ra, dec [, lat=, airtemp=, lst=, alt=, az=, /norefrac]
; INPUTS:
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
pro plate_apo_refrac, ra, dec, lat=lat, airtemp=airtemp, lst=lst, $
  alt=alt, az=az, norefrac=norefrac, pressure=pressure

if n_elements(lat) EQ 0 then lat = 32.7803D
if n_elements(lst) EQ 0 then lst = double(ra)
if n_elements(height) EQ 0 then height = 2788.D
if n_elements(airtemp) EQ 0 then airtemp = 5.D
airtemp_k=airtemp+273.155  ; C to Kelvin
if n_elements(pressure) EQ 0 then $
  pressure= 1013.25 * exp(-height/(29.3*airtemp_k))

ha = lst - ra
hadec2altaz, ha, dec, lat, alt, az
if(NOT keyword_set(norefrac)) then $
  alt= plate_refract_list(alt, epsilon=0.00001, temperature=airtemp_k, $
                          /to_observed, pressure=pressure)

end
