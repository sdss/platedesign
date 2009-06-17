;+
; NAME:
;   tavailable
; PURPOSE:
;   Count how much time each tile is available for (minimum 10 minute)
; CALLING SEQUENCE:
;   tavailable, tiles
; COMMENTS:
;   Sets the "tavailable" tag in the structure "tiles"
; REVISION HISTORY:
;   15-Jun-2009  MRB, NYU
;-
;------------------------------------------------------------------------------
pro tavailable, tiles, minmjd=minmjd

duration=20./60.
tiles.tavailable=0.

nights=yanny_readone(getenv('PLATEDESIGN_DIR')+ $
                     '/data/strategy/boss_observing_nights.par')

if(keyword_set(minmjd)) then begin
    ikeep= where(nights.mjd gt minmjd, nkeep)
    if(nkeep eq 0) then return
    nights=nights[ikeep]
endif

for i=0L, n_elements(nights)-1L do begin
    ints= night_intervals(night=nights[i], duration=duration, $
                          overhead=0., minexp=20.)
    for j=0L, n_elements(ints)-1L do begin
        if(ints[j].class ne 'BRIGHT') then begin
            obs= apo_in_interval(ints[j], tiles.ra, tiles.dec, $
                                 airmass=airmass)
            ican= where(obs gt 0 and tiles.observed eq 0 and $
                        (ints[j].class eq 'DARK' OR $
                         tiles.dark eq 0), ncan)
            if(ncan gt 0) then begin
                tiles[ican].tavailable= $
                  tiles[ican].tavailable+ints[j].exptime
            endif
        endif
    endfor
endfor

end
