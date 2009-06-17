;+
; NAME:
;   boss_strategy_mostopt
; PURPOSE:
;   Pick the tile closest to its minimum possible airmass
; CALLING SEQUENCE:
;   itile= boss_strategy_mostopt(class, tiles, airmass)
; INPUTS:
;   class - interval class ('DARK', 'GREY' or 'BRIGHT'	)
;   tiles - [N] available tiles
;   airmass - airmass it would be observed at
; OUTPUTS:
;   itile - which tile to pick (zero-indexed)
; REVISION HISTORY:
;   11-Sep-2007  MRB, NYU
;-
;------------------------------------------------------------------------------
function boss_strategy_mostopt, class, tiles, airmass

apodec= 32.7803D

min_possible= 1./cos((abs(tiles.dec-apodec)>1.e-6)*!DPI/180.D)
min_diff=min(airmass-min_possible, imin)

return, imin

end
