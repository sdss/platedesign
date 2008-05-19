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
; OPTIONAL KEYWORDS:
;   /norefrac - do not account for refraction
;   /nodistort - do not account for optical plate distortion
; OUTPUTS:
;   xfocal, yfocal - [N] arrays of focal plane positions
; COMMENTS:
;   Designed for the SDSS 2.5m at APO
;   PA=0 ALWAYS
; REVISION HISTORY:
;   26-Oct-2006  Written by MRB, NYU
;-
;------------------------------------------------------------------------------
pro ad2xyfocal, ra, dec, xfocal, yfocal, racen=racen, deccen=deccen, $
                airtemp=airtemp, lst=lst, norefrac=norefrac, $
                nodistort=nodistort

platescale = 217.7358D           ; mm/degree
fudge=1.D/1.0003D

;; from $PLATE_DIR/test/plParam.par
rcoeffs=[-0.000137627D, -0.00125238D, 1.5447D-09, 8.23673D-08, $
         -2.74584D-13, -1.53239D-12, 6.04194D-18, 1.38033D-17, $
         -2.97064D-23, -3.58767D-23] 

;; deal with atmospheric refraction
if(NOT keyword_set(norefrac)) then begin
    plate_apo_refrac, ra, dec, racen, deccen, ra_refrac, dec_refrac, lst=lst, $
                      airtemp=airtemp
endif else begin
    ra_refrac=ra
    dec_refrac=dec
endelse

;; convert to focal coordinates
xx= -sin(ra_refrac*!DPI/180.) * sin((90.-dec_refrac)*!DPI/180.)
yy= -cos(ra_refrac*!DPI/180.) * sin((90.-dec_refrac)*!DPI/180.)
zz= cos((90.-dec_refrac)*!DPI/180.)
xi= -xx*cos(racen*!DPI/180.) + yy*sin(racen*!DPI/180.)
yi= -yy*cos(racen*!DPI/180.) - xx*sin(racen*!DPI/180.)
zi= zz
xl= xi
yl= yi*sin((90.-deccen)*!DPI/180.) + zi*cos((90.-deccen)*!DPI/180.)
zl= zi*sin((90.-deccen)*!DPI/180.) - yi*cos((90.-deccen)*!DPI/180.)
rfocal=asin(sqrt(xl^2+zl^2))*180/!DPI*platescale
posang=atan(-xl, zl)

if(NOT keyword_set(nodistort)) then begin
    correction=replicate(rcoeffs[0], n_elements(rfocal))
    for i=1L, n_elements(rcoeffs)-1L do begin
        correction=correction+rcoeffs[i]*((double(rfocal))^(double(i)))
    endfor
    rfocal= rfocal+correction
endif

xfocal= -rfocal*sin(posang)*fudge
yfocal= rfocal*cos(posang)

return
end
