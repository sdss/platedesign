;+
; NAME:
;   reddenmed
; PURPOSE:
;   Return the median extinction in ugriz for a set of RA/Dec
; CALLING SEQUENCE:
;   extinct= reddenmed(ra, dec)
; INPUTS:
;   ra, dec - [N] coords in J2000 deg
; OUTPUTS:
;   extinct - [5] median extinction
; REVISION HISTORY:
;   25-Aug-2008  MRB, NYU
;-
function reddenmed, ra, dec

euler, ra, dec, ll, bb, 1
;reddenvec = [5.155, 3.793, 2.751, 2.086, 1.479] $
reddenvec = reddening() $
            * median(dust_getval(ll, bb, /interp))

return, reddenvec

end
;------------------------------------------------------------------------------
