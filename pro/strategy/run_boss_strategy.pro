;+
; NAME:
;   run_boss_strategy
; PURPOSE:
;   Run an observing strategy for a set of tiles
; CALLING SEQUENCE:
;   run_boss_strategy, tiles [, strategy=, efficiency=, nintervals=, $
;       nused=, duration=, minexp=, overhead= ]
; INPUTS/OUTPUTS:
;   tiles - structure with .RA, .DEC, .OBSERVED; .OBSERVED is reset on output
; OPTIONAL INPUTS:
;   strategy - string indicating strategy to use, default is 'mint'
;              --- see COMMENTS
;   efficiency - string indicating model for efficiency, default (and
;                only current option) is 'half' -- see COMMENTS
;   duration - desired length of exposures, hours (default 82./60.)
;   minexp - minimum acceptable exposure time, hours (default 30./60.)
;   overhead - overhead required per exposure, hours (default 20./60.)
; COMMENTS:
;   Uses the boss_observing_nights.par file for the nights.
;   Uses night_intervals() to get available intervals per night.
;   Assumes DARK and GREY nights are available.
;   Strategies:
;     - 'simple' picks the lowest airmass observable tile for each interval
;     - 'mint' picks the tile with lowest time available for each interval
;   Efficiency models (generally by NIGHT):
;     - 'half' assumes 50% of *nights* are good
; BUGS:
;   Does not deal with QSO/non-QSO tile differences.
;   DOes not track UNUSED intervals (i.e. inefficiencies)
; REVISION HISTORY:
;   11-Sep-2007  MRB, NYU
;-
;------------------------------------------------------------------------------
pro run_boss_strategy, tiles, strategy=strategy, efficiency=efficiency, $
  nintervals=nintervals, nused=nused, duration=duration, minexp=minexp, $
  overhead=overhead

if(NOT keyword_set(strategy)) then strategy='mint'
if(NOT keyword_set(efficiency)) then efficiency='half'

if(n_elements(duration) eq 0) then $
  duration=82./60.
if(n_elements(minexp) eq 0) then $
  minexp=30./60.
if(n_elements(overhead) eq 0) then $
  overhead=20./60.

sn2perhour=21./duration

nights=yanny_readone(getenv('PLATEDESIGN_DIR')+ $
                     '/data/strategy/boss_observing_nights.par')

k=0L
ttotal=fltarr(n_elements(nights))
tused=fltarr(n_elements(nights))
for i=0L, n_elements(nights)-1L do begin
    useable= call_function('boss_efficiency_'+efficiency, nights[i])
    if(useable gt 0) then begin
        interval=0L
        start_lmst=0.
        while(done eq 0) do begin
            next_interval, nights[i], interval, duration=duration, $
                           minexp=minexp, overhead=overhead

            if(n_tags(interval) gt 0) then begin
                if(interval.class ne 'BRIGHT') then begin
                    obs= apo_in_interval(interval, tiles.ra, tiles.dec, $
                                         airmass=airmass)
                    
                    ican= where(obs gt 0 and $
                                tiles.sn2obs lt tiles.sn2min and $
                                (ints[j].class eq 'DARK' OR $
                                 tiles.dark eq 0), ncan)
                    if(ncan gt 0) then begin
                        cantiles=tiles[ican]
                        canairmass=airmass[ican]
                        itile= call_function('boss_strategy_'+strategy, $
                                             interval.class, $
                                             cantiles, $
                                             canairmass)
                        
                        if(tiles[ican[itile]].sn2obs gt 0) then begin
                            interval.exptime= $
                              1.05*(tiles[ican[itile]].sn2min- $
                                    tiles[ican[itile]].sn2obs)/sn2perhour
                            interval.end_lmst= $
                              (interval.start_lmst+interval.exptime+overhead)
                        endif
                        
                        tiles[ican[itile]].observed=k+1
                        tiles[ican[itile]].sn2obs= $
                          tiles[ican[itile]].sn2obs+ $
                          sn2perhour*interval.exptime
                        tiles[ican[itile]].mjd=nights[i].mjd
                        tiles[ican[itile]].date=nights[i].date
                        tiles[ican[itile]].airmass=canairmass[itile]
                        tused[i]=tused[i]+interval.exptime
                        k=k+1
                    endif else begin
                        splog, 'Cannot use interval in night '+nights[i].date
                    endelse
                    ttotal[i]=ttotal[i]+interval.exptime
                endif
            endif else begin
                done=1
            endelse
        endwhile
    endif 
endfor

end
