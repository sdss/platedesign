;+
; NAME:
;   xyfocal2ad
; PURPOSE:
;   Take XFOCAL AND YFOCAL and RA and DEC 
; CALLING SEQUENCE:
;   xyfocal2ad, observatory, xfocal, yfocal, ra, dec,  racen=, deccen= [, $
;      params for ad2xyfocal]
; INPUTS:
;   xfocal, yfocal - [N] arrays of focal plane positions
;   racen      - RA center for tile (J2000 deg)
;   deccen     - DEC center for tile (J2000 deg)
; OPTIONAL INPUTS:
;   lst        - LST of observation (defaults to racen)
;   airtemp    - Design temperature (in C, default to 5)
; OPTIONAL KEYWORDS:
;   /norefrac - do not account for refraction
;   /nodistort - do not account for optical plate distortion
; OUTPUTS:
;   ra,dec     - [N] arrays of locations (J2000 deg)
; COMMENTS:
;   Designed for the SDSS 2.5m at APO
;   PA=0 ALWAYS
; REVISION HISTORY:
;   26-Oct-2006  Written by MRB, NYU
;-
;------------------------------------------------------------------------------
function xyfocal2ad_func, params

common com_xfa, observatory, racen, deccen, xfocal, yfocal, lambda, zoffset, extra_for_ad2xyfocal

ra=params[0]
dec=params[1]

ad2xyfocal, observatory, ra, dec, xfocal_fit, yfocal_fit, racen=racen, $
  deccen=deccen, lambda=lambda, zoffset=zoffset, _EXTRA=extra_for_ad2xyfocal

deviates= [ xfocal_fit-xfocal, yfocal_fit-yfocal ]

return, deviates

end
;;
pro xyfocal2ad, in_observatory, in_xfocal, in_yfocal, ra, dec, $
                racen=in_racen, deccen=in_deccen, $
                lambda=in_lambda, zoffset=in_zoffset, $
                _EXTRA=in_extra_for_ad2xyfocal

common com_xfa

if(n_elements(in_lambda) eq 0) then $
  in_lambda= replicate(5500., n_elements(in_xfocal))

if(n_elements(in_zoffset) eq 0) then $
  in_zoffset= replicate(0., n_elements(in_xfocal))

if(size(in_observatory,/tname) ne 'STRING') then $
  message, 'observatory must be set to STRING type, with value "LCO" or "APO"'

if(strupcase(in_observatory) ne 'APO' and $
   strupcase(in_observatory) ne 'LCO') then $
  message, 'Must set observatory to APO or LCO'

observatory= in_observatory

platescale = get_platescale(observatory)

racen= in_racen
deccen= in_deccen
if(keyword_set(in_extra_for_ad2xyfocal)) then $
  extra_for_ad2xyfocal= in_extra_for_ad2xyfocal

ra=dblarr(n_elements(in_xfocal))
dec=dblarr(n_elements(in_xfocal))

for i=0L, n_elements(in_xfocal)-1L do begin
    xfocal= in_xfocal[i]
    yfocal= in_yfocal[i]
    lambda= in_lambda[i]
    zoffset= in_zoffset[i]

    raguess= racen+xfocal/platescale/cos(!DPI/180.*deccen)
    decguess= deccen+yfocal/platescale
    
    start=[raguess, decguess]
    params = mpfit('xyfocal2ad_func', start, maxiter=maxiter, $
                   autoderivative=1, /quiet)

    ra[i]=params[0]
    dec[i]=params[1]
endfor

; force RA into range
ra= ra_in_range(ra)

; explicitly undefine "extra_for_ad2xyfocal"
if(keyword_set(extra_for_ad2xyfocal) gt 0) then $
  temp = size(temporary(extra_for_ad2xyfocal))

return
end
