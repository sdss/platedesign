;+
; NAME:
;   boss_observing_night
; PURPOSE:
;   Given a date, return an observing night structure
; CALLING SEQUENCE:
;   night=boss_observing_night(date)
; INPUT:
;   date - string date in form '10-Sep-2007'
; OUTPUT:
;   night - structure derived from skycalc:
;     .MJD 
;     .DATE 
;     .MOONFRAC (illuminated fraction)
;     .LMST_EVENTWI (starting and ending times for observing)
;     .LMST_MORNTWI
;     .LMST_MOONRISE
;     .LMST_MOONSET
; COMMENTS:
;   Uses skycalc, which it assumes to be at:
;      $PLATEDESIGN_DIR/bin/skycalc
; REVISION HISTORY:
;   11-Sep-2007  MRB, NYU
;-
;------------------------------------------------------------------------------
function boss_observing_night, date

months=['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', $
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec']
iyear= strmid(date, 7, 4)
month= strmid(date, 3, 3)
iday= strmid(date, 0, 2)
imonth=strtrim(string(where(month eq months)+1L),2)

jdcnv, iyear, imonth, iday, 0., jd
mjd=jd[0]-2400000.5

night={mjd:mjd, $
       date:date, $
       moonfrac:0., $
       lmst_eventwi:0., $
       lmst_morntwi:0., $
       lmst_moonrise:0., $
       lmst_moonset:0.}

alm= apo_almanac(date=night.date)
night.moonfrac= alm.moonfrac
night.lmst_eventwi= alm.lmst_eventwi
night.lmst_morntwi= alm.lmst_morntwi
if(alm.moonrise eq -99.) then begin
    night.lmst_moonrise=-99.
endif else begin
    night.lmst_moonrise= $
      ((alm.moonrise+alm.lmst_eventwi-alm.eventwi)+24.) mod 24.
endelse
if(alm.moonset eq -99.) then begin
    night.lmst_moonset=-99.
endif else begin
    night.lmst_moonset= $
      ((alm.moonset+alm.lmst_eventwi-alm.eventwi)+24.) mod 24.
endelse

return, night

end
