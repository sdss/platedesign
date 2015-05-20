;+
; NAME:
;   ad2xyfocal
; PURPOSE:
;   Take RA and DEC values and return XFOCAL and YFOCAL for a plate
; CALLING SEQUENCE:
;   ad2xyfocal, observatory, ra, dec, xfocal, yfocal, racen=, $
;     deccen=, airtemp=, lst=, /norefrac, /nodistort
; INPUTS:
;   observatory - 'APO' or 'LCO'
;   ra,dec     - [N] arrays of locations (J2000 deg)
;   racen      - RA center for tile (J2000 deg)
;   deccen     - DEC center for tile (J2000 deg)
; OPTIONAL INPUTS:
;   lst        - LST of observation (defaults to racen)
;   airtemp    - Design temperature (in C, default to 5 for APO,
;                                    12 for LCO)
;   lambda     - scalar or [N], optimum wavelength in angstroms
;                (default 5500 for APO, 8000 for LCO)
;   clambda    - wavelength to assume for plate center diffraction
;                (default 5500 for APO, 8000 for LCO)
; OPTIONAL KEYWORDS:
;   /norefrac - do not account for refraction
;   /nodistort - do not account for optical plate distortion
;   /nordistort - do not account for wavelength dependence of 
;                 optical plate distortion
; OUTPUTS:
;   xfocal, yfocal - [N] arrays of focal plane positions
; COMMENTS:
;   HA= LST-RA
;   Designed for the SDSS 2.5m at APO or the du Pont Telescope at LCO
;   PA=0 ALWAYS
;   Technique copied from plMakePlateFromTile (plPlateDesign.c) 
;     and plCoordTransform (plPlateUtils.c) in the plate product
;     (due to Steve Kent, Aronne Merrelli, Ron Kollgaard, Bob Nichol)
;   Normally "clambda" should have no practical effect, i.e. will just
;     be a shift in XFOCAL, YFOCAL, but no rotation or scale. It is
;     included to facilitate comparisons to old results from plate.
;   For APO, XFOCAL increases to the East, YFOCAL to the North
;   For LCO, XFOCAL increases to the West, YFOCAL to the South
; REVISION HISTORY:
;   26-Oct-2006  Written by MRB, NYU
;-
;------------------------------------------------------------------------------
pro altaz2rpa, alt, az, altcen, azcen, rfocal, posang

common com_ad2xyfocal, platescale

xx= -sin(az*!DPI/180.) * sin(((90.D)-alt)*!DPI/180.)
yy= -cos(az*!DPI/180.) * sin(((90.D)-alt)*!DPI/180.)
zz= cos(((90.D)-alt)*!DPI/180.)
xi= -xx*cos(azcen*!DPI/180.) + yy*sin(azcen*!DPI/180.)
yi= -yy*cos(azcen*!DPI/180.) - xx*sin(azcen*!DPI/180.)
zi= zz
xl= xi
yl= yi*sin((90.-altcen)*!DPI/180.) + zi*cos((90.-altcen)*!DPI/180.)
zl= zi*sin((90.-altcen)*!DPI/180.) - yi*cos((90.-altcen)*!DPI/180.)

rfocal=asin(sqrt(xl^2+zl^2))*(180.D)/!DPI*platescale
posang=atan(-xl, zl)

end
;;
pro ad2xyfocal, observatory, ra, dec, xfocal, yfocal, racen=racen, deccen=deccen, $
                airtemp=airtemp, lst=lst, norefrac=norefrac, $
                nodistort=nodistort, lambda=lambda, height=height, $
                clambda=clambda, nordistort=nordistort, pressure=pressure

common com_ad2xyfocal

if(size(observatory,/tname) ne 'STRING') then $
  message, 'observatory must be set to STRING type, with value "LCO" or "APO"'

if(strupcase(observatory) ne 'APO' and $
   strupcase(observatory) ne 'LCO') then $
  message, 'Must set observatory to APO or LCO'

platescale = get_get_platescale(observatory)
print, observatory

if(strupcase(observatory) eq 'APO') then begin
    if(n_elements(lambda) eq 0) then $
      lambda=replicate(5500., n_elements(ra))
    if n_elements(airtemp) EQ 0 then airtemp = 5.
    airtemp_k=airtemp+273.155   ; C to Kelvin
    if n_elements(height) EQ 0 then height = 2797.D
    if n_elements(pressure) EQ 0 then $
      pressure= 1013.25 * exp(-height/(29.3*airtemp_k))
   ;; from $PLATE_DIR/test/plParam.par
    rcoeffs=[-0.000137627D, -0.00125238D, 1.5447D-09, 8.23673D-08, $
             -2.74584D-13, -1.53239D-12, 6.04194D-18, 1.38033D-17, $
             -2.97064D-23, -3.58767D-23] 
endif

if(strupcase(observatory) eq 'LCO') then begin
    if(n_elements(lambda) eq 0) then $
      lambda=replicate(8000., n_elements(ra))
    if n_elements(airtemp) EQ 0 then airtemp = 12.
    airtemp_k=airtemp+273.155   ; C to Kelvin
    if n_elements(height) EQ 0 then height = 2380.D
    if n_elements(pressure) EQ 0 then $
      pressure= 1013.25 * exp(-height/(29.3*airtemp_k))
    ;; TBD, to be supplied by Guillermo!!
    rcoeffs=[0.0, 1.0, 0., 0.]
endif

if(n_elements(lambda) ne 1 AND $
   n_elements(lambda) ne n_elements(ra)) then $
  message, 'LAMBDA must have same number of elements as RA'

;; set fiducial point 1.5 deg north (to peg rotation)
rafid= racen
decfid= deccen+1.5D

;; deal with atmospheric refraction and get to alt/az for default 
;; wavelength
plate_refrac, observatory, ra, dec, lst=lst, airtemp=airtemp, $
  alt=alt, az=az, norefrac=norefrac, pressure=pressure
plate_refrac, observatory, rafid, decfid, lst=lst, airtemp=airtemp, $
  alt=altfid, az=azfid, norefrac=norefrac, pressure=pressure
plate_refrac, observatory, racen, deccen, lst=lst, airtemp=airtemp, $
  alt=altcen, az=azcen, norefrac=norefrac, pressure=pressure

;; handle differential refraction relative to default wavelength
adrval= adr(alt, lambda=lambda, temperature=airtemp, pressure=pressure)
alt= alt+ adrval/3600.

;; differentially refract the CENTER too, if desired
if(keyword_set(clambda)) then begin
    adrcenval= adr(altcen, lambda=clambda, temperature=airtemp, $
                   pressure=pressure)
    altcen= altcen+adrcenval/3600.
    adrfidval= adr(altfid, lambda=clambda, temperature=airtemp, $
                   pressure=pressure)
    altfid= altfid+adrfidval/3600.
endif

;; and convert to focal plane position
;; (adjusting position angle to be relative to N)
altaz2rpa, alt, az, altcen, azcen, rfocal, posang
altaz2rpa, altfid, azfid, altcen, azcen, rfocal_fid, posang_fid
posang= posang-posang_fid

;; apply radial distortions
if(NOT keyword_set(nodistort)) then begin

    ;; note that these distortions are appropriate for 5000 Angstroms
    correction=replicate(rcoeffs[0], n_elements(rfocal))
    for i=1L, n_elements(rcoeffs)-1L do begin
        correction=correction+rcoeffs[i]*((double(rfocal))^(double(i)))
    endfor
    rfocal= rfocal+correction

    ;; now wavelength dependence in radial distortion due to the
    ;; telescope optics. note that ASSUMES that the fibers are
    ;; backstopped appropriately
    if(NOT keyword_set(nordistort)) then begin
        rf5000= apo_rdistort(rfocal, replicate(5000., n_elements(rfocal)))
        rfthis= apo_rdistort(rfocal, lambda)
        rfoff= rfthis-rf5000
        rfocal= rfocal+rfoff
    endif
        
endif

xfocal= rfocal*sin(posang) 
yfocal= rfocal*cos(posang)

return
end
