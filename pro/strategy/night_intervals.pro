;+
; NAME:
;   night_intervals
; PURPOSE:
;   For a given night, return observing intervals for BOSS 
; CALLING SEQUENCE:
;   intervals= night_intervals([date=, night= ])
; INPUTS:
;   date - date to use (use current date by default)
;   night - night structure (overrides "date")
; COMMENTS:
;   Night structure should be output of "boss_observing_night()":
;     .MJD 
;     .DATE 
;     .MOONFRAC (illuminated fraction)
;     .LMST_EVENTWI (starting and ending times for observing)
;     .LMST_MORNTWI
;     .LMST_MOONRISE
;     .LMST_MOONSET
;   "intervals" comes as an array of structures, each of which has:
;     .MJD
;     .DATE
;     .START_LMST
;     .END_LMST
;     .CLASS (string: 'DARK', 'GREY', 'BRIGHT')
;     .MOONUP
;     .MOONFRAC
;   'Dark' means moon is not up or illumination < 25%
;   'Grey' means moon up and 25% < illumination < 60%
;   'Bright' means moon up and illumination > 60%
; REVISION HISTORY:
;   11-Sep-2007  MRB, NYU
;-
;------------------------------------------------------------------------------
function night_intervals, date=date, night=night

duration=80./60 ;; 80 minute exposures

if(n_tags(night) eq 0) then begin
    if(NOT keyword_set(date)) then begin
        mjd= current_mjd()
        mjd2datelist, mjd, datelist=date
    endif
    night=boss_observing_night(date)
endif

interval0= {mjd:night.mjd, $
            date:night.date, $
            start_lmst:0., $
            end_lmst:0., $
            class:'', $
            moonup:0, $
            moonfrac:night.moonfrac}

moonup=0
if(night.lmst_moonrise eq -99.) then begin
    if(night.lmst_moonset gt night.lmst_eventwi) then $
      moonup=1 $
    else $
      moonup=0
endif else if (night.lmst_moonset eq -99.) then begin
    if(night.lmst_moonrise lt night.lmst_eventwi) then $
      moonup=1 $
    else $
      moonup=0
endif else begin
    if(night.lmst_moonset gt night.lmst_moonrise) then begin
        if((night.lmst_morntwi gt night.lmst_eventwi AND $
            night.lmst_moonrise lt night.lmst_eventwi AND $
            night.lmst_moonset gt night.lmst_eventwi ) OR $
           (night.lmst_morntwi lt night.lmst_eventwi AND $
            (night.lmst_moonrise lt night.lmst_eventwi AND $
             (night.lmst_moonset gt night.lmst_eventwi OR $
              night.lmst_moonset lt night.lmst_morntwi)))) then $
          moonup=1
    endif else begin
        if((night.lmst_morntwi gt night.lmst_eventwi AND $
            night.lmst_moonrise gt night.lmst_morntwi AND $
            night.lmst_moonset gt night.lmst_eventwi ) OR $
           (night.lmst_morntwi lt night.lmst_eventwi AND $
            (night.lmst_moonrise lt night.lmst_eventwi AND $
             night.lmst_moonset lt night.lmst_moonrise))) then $
          moonup=1
    endelse
endelse

start_lmst=night.lmst_eventwi
end_lmst=(start_lmst+duration) MOD 24.
while((night.lmst_morntwi gt night.lmst_eventwi AND $
       end_lmst lt night.lmst_morntwi AND $
       end_lmst gt night.lmst_eventwi) OR $
      (night.lmst_morntwi lt night.lmst_eventwi AND $
       (end_lmst lt night.lmst_morntwi OR $
        end_lmst gt night.lmst_eventwi))) do begin

    ;; if moon rises during this interval, call it moony
    if(NOT moonup) then begin
        if(night.lmst_moonrise ne -99. AND $
           ((end_lmst gt start_lmst and $
             start_lmst lt night.lmst_moonrise and $
             end_lmst gt night.lmst_moonrise) OR $
            (end_lmst lt start_lmst and $
             (start_lmst lt night.lmst_moonrise OR $
              end_lmst gt night.lmst_moonrise)))) then begin
            moonup=1
        endif
    endif 

    interval0.start_lmst=start_lmst
    interval0.end_lmst=end_lmst MOD 24.
    interval0.moonup=moonup
    if(NOT moonup) then begin
        interval0.class='DARK'
    endif else begin
        if(interval0.moonfrac lt 0.25) then begin
            interval0.class='DARK'
        endif else if(interval0.moonfrac lt 0.6) then begin
            interval0.class='GREY'
        endif else begin
            interval0.class='BRIGHT'
        endelse
    endelse

    if(n_tags(intervals) eq 0) then begin
        intervals=interval0
    endif else begin
        intervals=[intervals, interval0]
    endelse
    
    ;; if moon sets during this interval, call next one dark
    if(moonup) then begin
        if(night.lmst_moonset ne -99. AND $
           ((end_lmst gt start_lmst and $
             start_lmst lt night.lmst_moonset and $
             end_lmst gt night.lmst_moonset) OR $
            (end_lmst lt start_lmst and $
             (start_lmst lt night.lmst_moonset OR $
              end_lmst gt night.lmst_moonset)))) then begin
            moonup=0
        endif
    endif 

    start_lmst=end_lmst
    end_lmst=(start_lmst+duration) MOD 24.
endwhile

if(keyword_set(verbose)) then begin
    help,/st,night
    print, intervals.start_lmst
    print, intervals.end_lmst
    print, intervals.moonfrac
    print, intervals.moonup
    print, intervals.class
endif

return, intervals

end
