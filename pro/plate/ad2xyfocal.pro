;+
; NAME:
;   ad2xyfocal
; PURPOSE:
;   Take RA and DEC values and return XFOCAL and YFOCAL for a plate
; CALLING SEQUENCE:
;   ad2xyfocal, ra, dec, xfocal, yfocal, racen=, $
;     deccen=, airtemp=, lst=, /norefrac, /nodistort
; INPUTS:
;   ra,dec     - [N] arrays of locations (J2000 deg)
;   racen      - RA center for tile (J2000 deg)
;   deccen     - DEC center for tile (J2000 deg)
; OPTIONAL INPUTS:
;   lst        - LST of observation (defaults to racen)
;   airtemp    - Design temperature (in C, default to 5)
;   lambda     - scalar or [N], optimum wavelength in angstroms
;                (default 5500)
; OPTIONAL KEYWORDS:
;   /norefrac - do not account for refraction
;   /nodistort - do not account for optical plate distortion
; OUTPUTS:
;   xfocal, yfocal - [N] arrays of focal plane positions
; COMMENTS:
;   HA= LST-RA
;   Designed for the SDSS 2.5m at APO
;   PA=0 ALWAYS
;   Technique copied from plMakePlateFromTile (plPlateDesign.c) 
;     and plCoordTransform (plPlateUtils.c) in the plate product
;     (due to Steve Kent, Aronne Merrelli, Ron Kollgaard, Bob Nichol)
; REVISION HISTORY:
;   26-Oct-2006  Written by MRB, NYU
;-
;------------------------------------------------------------------------------
pro altaz2rpa, alt, az, altcen, azcen, rfocal, posang

platescale = 217.7358D           ; mm/degree

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
pro ad2xyfocal, ra, dec, xfocal, yfocal, racen=racen, deccen=deccen, $
                airtemp=airtemp, lst=lst, norefrac=norefrac, $
                nodistort=nodistort, lambda=lambda

if(n_elements(lambda) eq 0) then $
  lambda=replicate(5500., n_elements(ra))

if n_elements(airtemp) EQ 0 then airtemp = 5.
airtemp_k=airtemp+273.155  ; C to Kelvin
if n_elements(height) EQ 0 then height = 2788.D
if n_elements(pressure) EQ 0 then $
  pressure= 1013.25 * exp(-height/(29.3*airtemp_k))

if(n_elements(lambda) ne 1 AND $
   n_elements(lambda) ne n_elements(ra)) then $
  message, 'LAMBDA must have same number of elements as RA'

;; from $PLATE_DIR/test/plParam.par
rcoeffs=[-0.000137627D, -0.00125238D, 1.5447D-09, 8.23673D-08, $
         -2.74584D-13, -1.53239D-12, 6.04194D-18, 1.38033D-17, $
         -2.97064D-23, -3.58767D-23] 

;; set fiducial point 1.5 deg north (to peg rotation)
rafid= racen
decfid= deccen+1.5D

;; deal with atmospheric refraction and get to alt/az for 5500
;; angstroms
plate_apo_refrac, ra, dec, lst=lst, airtemp=airtemp, $
  alt=alt, az=az, norefrac=norefrac, pressure=pressure
plate_apo_refrac, rafid, decfid, lst=lst, airtemp=airtemp, $
  alt=altfid, az=azfid, norefrac=norefrac, pressure=pressure
plate_apo_refrac, racen, deccen, lst=lst, airtemp=airtemp, $
  alt=altcen, az=azcen, norefrac=norefrac, pressure=pressure

;; handle differential refraction relative to 5500
adrval= adr(alt, lambda=lambda, temperature=airtemp, pressure=pressure)
alt= alt+ adrval/3600.

;; and convert to focal plane position
;; (adjusting position angle to be relative to N)
altaz2rpa, alt, az, altcen, azcen, rfocal, posang
altaz2rpa, altfid, azfid, altcen, azcen, rfocal_fid, posang_fid
posang= posang-posang_fid

;; apply radial distortions
if(NOT keyword_set(nodistort)) then begin
    correction=replicate(rcoeffs[0], n_elements(rfocal))
    for i=1L, n_elements(rcoeffs)-1L do begin
        correction=correction+rcoeffs[i]*((double(rfocal))^(double(i)))
    endfor
    rfocal= rfocal+correction

    ;; now wavelength dependence in radial distortion due to the
    ;; telescope optics
    rfocal= sdss_rdistort(rfocal, lambda)
endif

xfocal= rfocal*sin(posang) 
yfocal= rfocal*cos(posang)

return
end
