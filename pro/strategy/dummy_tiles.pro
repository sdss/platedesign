;+
; NAME:
;   dummy_tiles
; PURPOSE:
;   Return a REALLY stupid baseline tiling
; CALLING SEQUENCE:
;   tiles= dummy_tiles()
; REVISION HISTORY:
;   11-Sep-2007  MRB, NYU
;-
;------------------------------------------------------------------------------
function dummy_tiles

spacing=2.5

bmin=20.
bmax=89.5
nb=long((bmax-bmin)/spacing)
bspacing=(bmax-bmin)/float(nb)

lmin=0.
lmax=360.-spacing

tiles0={l:0.D, b:0.D, ra:0.D, dec:0.D, $
        dark:0L, observed:0, mjd:0., date:''}

for ib=0L, nb-1L do begin
    bb=bmin+(bmax-bmin)*float(ib)/float(nb-1L)
    nl=long((lmax-lmin)/(bspacing/cos(!DPI/180.*bb)))
    for il=0L, nl-1L do begin
        ll=lmin+(lmax-lmin)*float(il)/float(nl-1L)
        tiles0.l=ll
        tiles0.b=bb
        if(n_tags(tiles) eq 0) then begin
            tiles=tiles0
        endif else begin
            tiles=[tiles, tiles0]
        endelse
    endfor
endfor

bmin=-89.5
bmax=-30.
nb=long((bmax-bmin)/spacing)
bspacing=(bmax-bmin)/float(nb)

for ib=0L, nb-1L do begin
    bb=bmin+(bmax-bmin)*float(ib)/float(nb-1L)
    nl=long((lmax-lmin)/(bspacing/cos(!DPI/180.*bb)))
    for il=0L, nl-1L do begin
        ll=lmin+(lmax-lmin)*float(il)/float(nl-1L)
        tiles0.l=ll
        tiles0.b=bb
        if(n_tags(tiles) eq 0) then begin
            tiles=tiles0
        endif else begin
            tiles=[tiles, tiles0]
        endelse
    endfor
endfor

glactc, ra, dec, 2000., tiles.l, tiles.b, 2, /deg
tiles.ra=ra
tiles.dec=dec

ikeep=where(tiles.dec gt -12., nkeep)

tiles=tiles[ikeep]

idark=where(tiles.b gt 50. OR $
            (tiles.b lt 0. and tiles.dec lt 10.))
tiles[idark].dark=1

return, tiles


end
