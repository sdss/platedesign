;+
; NAME:
;   apo_almanac
; PURPOSE:
;   Return a structure with the almanac for APO on a given night
; CALLING SEQUENCE:
;   alm= apo_almanac([mjd=, date=, /verbose ])
; INPUTS:
;   mjd - desired mjd (default to current; overrides "date")
;   date - desired date (default to current, style: '01-Apr-2007')
; OPTIONAL KEYWORD:
;   /verbose - spew almanac output to screen
; COMMENTS:
;   Runs skycalc in $PLATEDESIGN_DIR/bin to get data
;   Returned structure contains:
;     .DATE - Date
;     .UT_MID - UT at midnight
;     .JD_MID - Julian day at midnight
;     .LMST_MID - Local Mean Sidereal Time at midnight
;     .SUNSET - Sunset time (local)
;     .SUNRISE - Sunrise time (local)
;     .EVENTWI - Evening twilight time (local)
;     .MORNTWI - Morning twilight time (local)
;     .LMST_EVENTWI - Evening twilight LMST
;     .LMST_MORNTWI - Morning twilight LMST
;     .MOONRISE - Moonrise time (local; -99. for never)
;     .MOONSET - Moonset time (local; -99. for never)
;     .MOONFRAC - Sunset time (local)
;   All times are given in decimal hours relative to midnight.
;   Assumes APO is on Mountain Standard Time always
; REVISION HISTORY:
;   11-Sep-2007  MRB, NYU
;-
;------------------------------------------------------------------------------
function apo_almanac, mjd=mjd, date=date, verbose=verbose

if(NOT keyword_set(mjd)) then begin
    if(NOT keyword_set(date)) then begin
        mjd= current_mjd()
        mjd2datelist, mjd, datelist=date
    endif 
endif
              
almanac={date:'', $
         ut_mid:0., $
         jd_mid:0.D, $
         lmst_mid:0., $
         sunset:0., $
         sunrise:0., $
         eventwi:0., $
         morntwi:0., $
         lmst_eventwi:0., $
         lmst_morntwi:0., $
         moonrise:-99., $
         moonset:-99., $
         moonfrac:0.}

months=['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', $
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec']

almanac.date= date

iyear= strmid(almanac.date, 7, 4)
month= strmid(almanac.date, 3, 3)
iday= strmid(almanac.date, 0, 2)
imonth=strtrim(string(where(month eq months)+1L),2)

openw, unit, 'tmp-skycalc.dat', /get_lun
printf, unit, 'n'
printf, unit, '105 49 13'
printf, unit, '32 46 49'
printf, unit, '2788'
printf, unit, '500'
printf, unit, 'APO'
printf, unit, '7'
printf, unit, 'Mountain'
printf, unit, 'M'
printf, unit, '0'
printf, unit, 'y '+iyear+' '+imonth+' '+iday+' a'
printf, unit, 'Q'
free_lun, unit

spawn, 'cat tmp-skycalc.dat | '+ $
  getenv('PLATEDESIGN_DIR')+'/bin/skycalc', unit=unit

line=''
while(line ne 'Almanac for APO:') do begin
    readf, unit, line
endwhile

while(line ne 'Goodbye.') do begin
    readf, unit, line
    if(keyword_set(verbose)) then $
      print, line
    words=strsplit(line, /extr)
    if(strmid(line, 0, 14) eq 'Local midnight') then begin
        almanac.ut_mid= float(words[6])
        almanac.jd_mid= double(words[11])
    endif
    if(strmid(line, 0, 14) eq 'Local Mean Sid') then begin
        almanac.lmst_mid= float(words[7])+float(words[8])/60. $
          +float(words[9])/3600.
    endif
    if(strmid(line, 0, 6) eq 'Sunset') then begin
        almanac.sunset= float(words[5])+float(words[6])/60.
        almanac.sunrise= float(words[9])+float(words[10])/60.
    endif
    if(strmid(line, 0, 7) eq 'Evening') then begin
        almanac.eventwi= float(words[2])+float(words[3])/60.
        almanac.lmst_eventwi= float(words[9])+float(words[10])/60.
    endif
    if(strmid(line, 0, 7) eq 'Morning') then begin
        almanac.morntwi= float(words[2])+float(words[3])/60.
        almanac.lmst_morntwi= float(words[9])+float(words[10])/60.
    endif
    if(strmid(line, 0, 7) eq 'Moonset') then begin
        almanac.moonset= float(words[2])+float(words[3])/60.
        if(n_elements(words) gt 5) then $
          almanac.moonrise= float(words[6])+float(words[7])/60.
    endif
    if(strmid(line, 0, 8) eq 'Moonrise') then begin
        almanac.moonrise= float(words[1])+float(words[2])/60.
        if(n_elements(words) gt 4) then $
          almanac.moonset= float(words[6])+float(words[7])/60.
    endif
    if(strmid(line, 0, 8) eq 'Moon at ') then begin
        almanac.moonfrac= float(words[6])
    endif
endwhile
free_lun, unit

return, almanac

end
