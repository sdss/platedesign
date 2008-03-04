;+
; NAME:
;   run_boss_strategy
; PURPOSE:
;   Run an observing strategy for a set of tiles
; CALLING SEQUENCE:
;   run_boss_strategy, tiles [, strategy=, efficiency= ]
; INPUTS/OUTPUTS:
;   tiles - structure with .RA, .DEC, .OBSERVED; .OBSERVED is reset on output
; OPTIONAL INPUTS:
;   strategy - string indicating strategy to use, default (and only
;              current option) is 'simple' -- see COMMENTS
;   efficiency - string indicating model for efficiency, default (and
;                only current option) is 'half' -- see COMMENTS
; COMMENTS:
;   Uses the boss_observing_nights.par file for the nights.
;   Uses night_intervals() to get available intervals per night.
;   Assumes DARK and GREY nights are available.
;   Strategies:
;     - 'simple' picks the lowest airmass observable tile for each interval
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
                       nintervals=nintervals, nused=nused

if(NOT keyword_set(strategy)) then strategy='simple'
if(NOT keyword_set(efficiency)) then efficiency='half'

nights=yanny_readone(getenv('PLATEDESIGN_DIR')+ $
                     '/data/strategy/boss_observing_nights.par')

k=0L
nintervals=lonarr(n_elements(nights))
nused=lonarr(n_elements(nights))
for i=0L, n_elements(nights)-1L do begin
    ints= night_intervals(night=nights[i])
    useable= call_function('boss_efficiency_'+efficiency, nights[i], $
                           ints)
    iuse=where(useable, nuse)
    if(nuse gt 0) then begin
        ints=ints[iuse]
        nintervals[i]=0L
        for j=0L, n_elements(ints)-1L do begin
            if(ints[j].class ne 'BRIGHT') then begin
                obs= apo_in_interval(ints[j], tiles.ra, tiles.dec, $
                                     airmass=airmass)
                ican= where(obs gt 0 and tiles.observed eq 0 and $
                            (ints[j].class eq 'DARK' OR $
                             tiles.dark eq 0), ncan)
                if(ncan gt 0) then begin
                    cantiles=tiles[ican]
                    canairmass=airmass[ican]
                    itile= call_function('boss_strategy_'+strategy, $
                                         ints[j].class, $
                                         cantiles, $
                                         canairmass)
                    tiles[ican[itile]].observed=k+1
                    tiles[ican[itile]].mjd=nights[i].mjd
                    tiles[ican[itile]].date=nights[i].date
                    nused[i]=nused[i]+1L
                    k=k+1
                endif else begin
                    splog, 'cannot use interval in night '+nights[i].date
                endelse
                nintervals[i]=nintervals[i]+1L
            endif
        endfor
    endif 
endfor

end
