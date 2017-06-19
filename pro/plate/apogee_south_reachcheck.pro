;+
; NAME:
;   apogee_south_reachcheck
; PURPOSE:
;   Checks whether a point is within reach of a fiber
; CALLING SEQUENCE:
;   inreach= apogee_south_reachcheck(xfiber, yfiber, xhole, yhole [, /stretch])
; INPUTS:
;   xfiber, yfiber - fiber position relative to plate center (mm)
;   xhole, yhole - [N] position relative to plate center (mm)
; OPTIONAL KEYWORDS:
;   /stretch - add some reach (e.g. for certain guide star plates)
; OUTPUTS:
;   inreach - [N] 1 if within reach, 0 otherwise
; COMMENTS:
;   Uses reach values reported by boss_reachvalues.pro
;     (assumes +Y exit for fiber if xfiber>=0, -Y otherwise)
;   Basically a rotated version of boss_reachcheck
;   Interpolates to desired angle and checks radius there.
; REVISION HISTORY:
;   7-Aug-2008  MRB, NYU
;   22-Oct-2015  MRB, NYU (altered from boss_reachcheck)
;-
;------------------------------------------------------------------------------
function apogee_south_reachcheck, xfiber, yfiber, xhole, yhole, stretch=stretch

common com_reachcheck, rval, thval

if(n_elements(rval) eq 0) then begin
    ;; Use the regular APO values, but rotate 90 deg
    boss_reachvalues, xval=tmp_xval, yval=tmp_yval 
    xval= tmp_yval
    yval= -tmp_xval
    rval= sqrt(xval^2+yval^2)
    thval= (atan(yval, xval)+!DPI*2.) mod (!DPI*2.)
    thval[n_elements(thval)-1L]=2.*!DPI
    isort = sort(thval)
    rval = rval[isort]
    thval = thval[isort]
endif

if(n_elements(xfiber) ne 1 OR $
   n_elements(yfiber) ne 1) then $
  message, 'Handles one fiber at a time'

xoff=xhole-xfiber[0]
yoff=yhole-yfiber[0]

if(yfiber lt 0.) then $
  xoff=-xoff

roff= sqrt(xoff^2+yoff^2)
thoff= (atan(yoff, xoff)+!DPI*2.) mod (!DPI*2.)

rreach= interpol(rval, thval, thoff, /spline)

if(keyword_set(stretch)) then $
  rreach = rreach + 25.4*float(stretch)

return, rreach gt roff

end
