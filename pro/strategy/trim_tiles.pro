;+
; NAME:
;   trim_tiles
; PURPOSE:
;   Takes tile output for simple tiling, trims it, and changes format
; CALLING SEQUENCE:
;   trim_tiles
; COMMENTS:
;   Reads in $PLATEDESIGN_DATA/strategy/lrgs/tiling/tile.par
;   Writes out $PLATEDESIGN_DIR/data/strategy/tile-simple.par
;   The output is ultimately read by baseline_tiles()
; REVISION HISTORY:
;   27-Sep-2007  MRB, NYU
;-
;------------------------------------------------------------------------------
pro trim_tiles

tile=yanny_readone(getenv('PLATEDESIGN_DATA')+ $
                   '/strategy/lrgs/tiling/tile.par')

ikeep=where((tile.ntargets lt 450. AND  $
             (abs(tile.racen-180.) lt 140 OR $
              (tile.deccen) gt 15. OR $
              tile.deccen lt -10.)) eq 0) 

tile=tile[ikeep]

pdata=ptr_new(tile)
yanny_write, getenv('PLATEDESIGN_DIR')+'/data/strategy/tile-simple.par', $
  pdata

end
