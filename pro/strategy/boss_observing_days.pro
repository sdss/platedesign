;+
; NAME:
;   boss_observing_nights
; PURPOSE:
;   Create the full list of BOSS observing nights
; CALLING SEQUENCE:
;   boss_observing_nights
; COMMENTS:
;   Put results in:
;     $PLATEDESIGN_DIR/data/strategy/boss_observing_nights.par
;   Lists each night separately, with the following data:
;     .MJD 
;     .DATE 
;     .MOONFRAC (illuminated fraction)
;     .LMST_EVENTWI (starting and ending times for observing)
;     .LMST_MORNTWI
;     .LMST_MOONRISE
;     .LMST_MOONSET
;   Conventional definitions of DARK, GREY, BRIGHT are
;       DARK - MOONFRAC<0.25
;       GREY - 0.25<MOONFRAC<0.6
;       BRIGHT - MOONFRAC>0.6
;   Starts observing Sep 1, 2009
;   Ends observing July 15, 2014
;   Always skips last half of July and all of August
; REVISION HISTORY:
;   11-Sep-2007  MRB, NYU
;-
;------------------------------------------------------------------------------
pro boss_observing_nights

mjdstart= 55075.
mjdend= 56853.
mjd2datelist, mjdstart, mjdend, mjdlist=mjds, datelist=dates, $
  step='day'

keep=bytarr(n_elements(dates))+1
months=strmid(dates, 3,3)
days=long(strmid(dates, 0,2))
iexclude=where(months eq 'Aug' OR $
               (months eq 'Jul' AND days gt 15), nexclude)
keep[iexclude]=0

ikeep=where(keep)
mjds=mjds[ikeep]
dates=dates[ikeep]

nights=replicate({mjd:0., $
                  date:'', $
                  moonfrac:0., $
                  lmst_eventwi:0., $
                  lmst_morntwi:0., $
                  lmst_moonrise:0., $
                  lmst_moonset:0.}, n_elements(dates))

for i=0L, n_elements(dates)-1L do begin
    nights[i].mjd= mjds[i]
    nights[i].date= dates[i]
    alm= apo_almanac(date=nights[i].date)
    nights[i].moonfrac= alm.moonfrac
    nights[i].lmst_eventwi= alm.lmst_eventwi
    nights[i].lmst_morntwi= alm.lmst_morntwi
    nights[i].lmst_moonrise= alm.eventwi
    nights[i].lmst_moonset= alm.morntwi
endfor

pdata=ptr_new(nights)
yanny_write, getenv('PLATEDESIGN_DIR')+'/data/strategy/boss_observing_nights.par')

end
