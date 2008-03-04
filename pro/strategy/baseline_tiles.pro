;+
; NAME:
;   baseline_tiles
; PURPOSE:
;   Return a baseline tiling
; CALLING SEQUENCE:
;   tiles= baseline_tiles()
; COMMENTS:
;   Reads $PLATEDESIGN_DIR/data/strategy/tile-simple.par, produced by
;   trim_tiles.  This is based on the 8192 tile sphere output by
;   tiling.  The entire NGC tiling of this actually has imaging, the
;   SGC is based (more or less) on the plan posted by Schlegel
;   (as2-lss/184).
;
;   There are 1535 tiles in the NGC here, and 518 in the SGC.
;  
; REVISION HISTORY:
;   11-Sep-2007  MRB, NYU
;-
;------------------------------------------------------------------------------
function baseline_tiles


ti=yanny_readone(getenv('PLATEDESIGN_DIR')+'/data/strategy/tile-simple.par')

tiles0={l:0.D, b:0.D, ra:0.D, dec:0.D, $
        dark:0L, observed:0, mjd:0., date:''}

tiles=replicate(tiles0, n_elements(ti))

tiles.ra=ti.racen
tiles.dec=ti.deccen

glactc, tiles.ra, tiles.dec, 2000., gl, gb, 1, /deg
tiles.l=gl
tiles.b=gb

ingc=where(abs(tiles.ra-180.) lt 100., nngc)
help, ingc
isgc=where(abs(tiles.ra-180.) gt 100., nsgc)
help, isgc

isdark=where(tiles[isgc].dec lt 8.5, nsdark)
help, isdark
tiles[isgc[isdark]].dark=1

indark=where(tiles[ingc].b gt 39., nndark)
help, indark
tiles[ingc[indark]].dark=1

return, tiles


end
