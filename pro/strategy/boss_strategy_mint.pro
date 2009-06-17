;+
; NAME:
;   boss_strategy_mint
; PURPOSE:
;   Pick the tile closest to its minimum possible airmass
; CALLING SEQUENCE:
;   itile= boss_strategy_mint(class, tiles, airmass)
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
function boss_strategy_mint, class, tiles, airmass

apodec= 32.7803D

mint=min(tiles.tavailable, imint)

return, imint

end
