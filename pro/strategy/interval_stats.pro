;+
; NAME:
;   interval_stats
; PURPOSE:
;   Report number of bright/grey/dark observing intervals
; CALLING SEQUENCE:
;   interval_stats
; REVISION HISTORY:
;   11-Sep-2007  MRB, NYU
;-
;------------------------------------------------------------------------------
pro interval_stats

nights=yanny_readone(getenv('PLATEDESIGN_DIR')+ $
                     '/data/strategy/boss_observing_nights.par')

ntot_dark=0L
ntot_grey=0L
ntot_bright=0L
for i=0L, n_elements(nights)-1L do begin
    ints=night_intervals(night=nights[i])
    idark=where(ints.class eq 'DARK', ndark)
    ntot_dark= ntot_dark+ndark
    igrey=where(ints.class eq 'GREY', ngrey)
    ntot_grey= ntot_grey+ngrey
    ibright=where(ints.class eq 'BRIGHT', nbright)
    ntot_bright= ntot_bright+nbright
endfor

help,/st,ntot_dark
help,/st,ntot_grey
help,/st,ntot_bright

end
