;+
; NAME:
;   baseline_tiles
; PURPOSE:
;   Return a baseline tiling
; CALLING SEQUENCE:
;   tiles= baseline_tiles()
; COMMENTS:
;   Reads $BOSSTILELIST_DIR/geometry/boss_locations.fits
; REVISION HISTORY:
;   11-Sep-2007  MRB, NYU
;-
;------------------------------------------------------------------------------
function baseline_tiles

read_fits_polygons, getenv('BOSSTILELIST_DIR')+$
                    '/geometry/boss_locations.fits', ti

tiles0={l:0.D, b:0.D, ra:0.D, dec:0.D, tavailable:0., $
        dark:0L, sn2min:20., sn2obs:0., observed:0, mjd:0., $
        airmass:0., date:''}

tiles=replicate(tiles0, n_elements(ti))

tiles.ra=ti.ra
tiles.dec=ti.dec

glactc, tiles.ra, tiles.dec, 2000., gl, gb, 1, /deg
tiles.l=gl
tiles.b=gb

tiles.dark=0

tavailable, tiles

return, tiles

end
