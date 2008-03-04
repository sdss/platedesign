;+
; NAME:
;   apo_in_interval
; PURPOSE:
;   given an interval structure, report whether RA/Decs are observable
; CALLING SEQUENCE:
;   observable= apo_in_interval(interval, ra, dec)
; INPUTS:
;   interval - structure from night_intervals(), with tags
;     .MJD
;     .DATE
;     .START_LMST
;     .END_LMST
;     .CLASS (string: 'DARK', 'GREY', 'BRIGHT')
;     .MOONUP
;     .MOONFRAC
;   ra, dec - [N] J2000 coordinates, degrees
; OUTPUT:
;   observable - [N] 0 or 1 if observable or not
; COMMENTS:
;   Called "observable" when airmass is less than 1.6 over 
;   entire interval.
; REVISION HISTORY:
;   11-Sep-2007  MRB, NYU
;-
;------------------------------------------------------------------------------
function apo_in_interval, interval, ra, dec, airmass=airmass

max_airmass=1.6
apolat=32.7803

hast= ra-interval.start_lmst*360./24.
hadec2altaz, hast, dec, apolat, altst, azst
hand= ra-interval.end_lmst*360./24.
hadec2altaz, hand, dec, apolat, altnd, aznd

airmass_st= 1./cos((90.-altst)*!DPI/180.)
airmass_nd= 1./cos((90.-altnd)*!DPI/180.)
airmass=0.5*(airmass_st+airmass_nd)

observable=(airmass_st lt max_airmass) AND (airmass_nd lt max_airmass) AND $
  (altst gt 0.) AND (altnd gt 0.)

return, observable

end
