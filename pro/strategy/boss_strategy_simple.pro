;+
; NAME:
;   boss_strategy_simple
; PURPOSE:
;   Pick an available tile using simple strategy: lowest airmass available
; CALLING SEQUENCE:
;   itile= boss_strategy_simple(class, tiles, airmass)
; INPUTS:
;   class - interval class ('DARK', 'GREY' or 'BRIGHT'	)
;   tiles - [N] available tiles
;   intervals - [N] airmass each tile would be observed at
; OUTPUTS:
;   itile - which tile to pick (zero-indexed)
; COMMENTS:
; REVISION HISTORY:
;   11-Sep-2007  MRB, NYU
;-
;------------------------------------------------------------------------------
function boss_strategy_simple, class, tiles, airmass

if(class eq 'DARK') then begin
    idark=where(tiles.dark gt 0, ndark)
    if(ndark gt 0) then begin
        min_airmass=min(airmass[idark], imin)
        return, idark[imin]
    endif
endif

min_airmass=min(airmass, imin)

return, imin

end
