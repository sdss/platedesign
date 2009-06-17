;+
; NAME:
;   next_interval
; PURPOSE:
;   Return the next interval in the night and its properties
; CALLING SEQUENCE:
;   next_interval, night, interval, [, duration=, minexp=, overhead= ])
; INPUTS:
;   night - night structure (overrides "date")
; OPTIONAL INPUTS
;   duration - duration of allowed interval (default 82./60.)
;   overhead - duration of allowed interval (default 20./60.)
;   minexp - duration of allowed interval (default 30./60.)
; INPUT/OUPUTS
;   interval - input is current interval (or 0 for beginning of
;              night); output is next interval
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
;     .EXPTIME
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
pro next_interval, night, interval, duration=duration, overhead=overhead, $
                   minexp=minexp

if(n_elements(minexp) eq 0) then $
  minexp=30./60 
if(n_elements(duration) eq 0) then $
  duration=82./60 
if(n_elements(overhead) eq 0) then $
  overhead=20./60 

if(n_tags(interval) eq 0) then begin

    ;; if this is the first interval, start up the night
    interval= {mjd:night.mjd, $
               date:night.date, $
               start_lmst:0., $
               end_lmst:0., $
               exptime:0., $
               class:'', $
               moonup:0, $
               moonfrac:night.moonfrac}
    
    ;; check if moon is up at the start of the night
    interval.moonup=0
    if(night.lmst_moonrise eq -99.) then begin
        if(night.lmst_moonset gt night.lmst_eventwi) then $
          interval.moonup=1 $
        else $
          interval.moonup=0
    endif else if (night.lmst_moonset eq -99.) then begin
        if(night.lmst_moonrise lt night.lmst_eventwi) then $
          interval.moonup=1 $
        else $
          interval.moonup=0
    endif else begin
        if(night.lmst_moonset gt night.lmst_moonrise) then begin
            if((night.lmst_morntwi gt night.lmst_eventwi AND $
                night.lmst_moonrise lt night.lmst_eventwi AND $
                night.lmst_moonset gt night.lmst_eventwi ) OR $
               (night.lmst_morntwi lt night.lmst_eventwi AND $
                (night.lmst_moonrise lt night.lmst_eventwi AND $
                 (night.lmst_moonset gt night.lmst_eventwi OR $
                  night.lmst_moonset lt night.lmst_morntwi)))) then $
              interval.moonup=1
        endif else begin
            if((night.lmst_morntwi gt night.lmst_eventwi AND $
                night.lmst_moonrise gt night.lmst_morntwi AND $
                night.lmst_moonset gt night.lmst_eventwi ) OR $
               (night.lmst_morntwi lt night.lmst_eventwi AND $
                (night.lmst_moonrise lt night.lmst_eventwi AND $
                 night.lmst_moonset lt night.lmst_moonrise))) then $
              interval.moonup=1
        endelse
    endelse

    ;; by default start at twilight
    interval.start_lmst= night.lmst_eventwi
    interval.moonup= moonup

endif else begin

    ;; if moon set during last interval, it isn't moony now
    if(interval.moonup gt 0) then begin
        if(night.lmst_moonset ne -99. AND $
           ((interval.end_lmst gt interval.start_lmst and $
             interval.start_lmst lt night.lmst_moonset and $
             end_lmst gt night.lmst_moonset) OR $
            (interval.end_lmst lt interval.start_lmst and $
             (interval.start_lmst lt night.lmst_moonset OR $
              interval.end_lmst gt night.lmst_moonset)))) then begin
            interval.moonup=0
        endif
    endif 

    ;; if we are moving on to the next interval, then reset
    interval.start_lmst= interval.end_lmst

endelse

;; try this exposure at full duration
interval.end_lmst= (interval.start_lmst+duration+overhead) MOD 24.
interval.exptime= duration
    
;; check if this exceeds the available time, and if it does whether we
;; can squeeze in an exposure longer than the minimum
if((night.lmst_morntwi gt night.lmst_eventwi AND $
    (interval.end_lmst gt night.lmst_morntwi OR $
     interval.end_lmst lt night.lmst_eventwi)) OR $
   (night.lmst_morntwi lt night.lmst_eventwi AND $
    (interval.end_lmst gt night.lmst_morntwi AND $
     interval.end_lmst lt night.lmst_eventwi))) then begin
    
    ;; force interval to end at morning twilight
    interval.end_lmst= night.lmst_morntwi
    
    ;; set exposure time
    if(interval.start_lmst gt interval.end_lmst) then $
      interval.exptime= $
        interval.end_lmst+(24.-interval.start_lmst)-overhead $
    else $
      interval.exptime= $
        interval.end_lmst-interval.start_lmst-overhead
    
    ;; if exposure time is less than minimum allowed,
    ;; no interval is available
    if(interval.exptime lt minexp) then begin
        interval=0
        return
    endif
endif

;; if moon rises during this interval, call it moony
if(interval.moonup eq 0) then begin
    if(night.lmst_moonrise ne -99. AND $
       ((interval.end_lmst gt interval.start_lmst and $
         interval.start_lmst lt night.lmst_moonrise and $
         interval.end_lmst gt night.lmst_moonrise) OR $
        (interval.end_lmst lt interval.start_lmst and $
         (interval.start_lmst lt night.lmst_moonrise OR $
          interval.end_lmst gt night.lmst_moonrise)))) then begin
        interval.moonup=1
    endif
endif 

;; set class
if(interval.moonup eq 0) then begin
    interval.class='DARK'
endif else begin
    if(interval.moonfrac lt 0.25) then begin
        interval.class='DARK'
    endif else if(interval0.moonfrac lt 0.6) then begin
        interval.class='GREY'
    endif else begin
        interval.class='BRIGHT'
    endelse
endelse
    
return
end
