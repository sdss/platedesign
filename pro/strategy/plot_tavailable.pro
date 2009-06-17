pro plot_tavailable, tiles

read_fits_polygons, getenv('BOSSTILELIST_DIR')+$
                    '/geometry/boss_locations.fits', ti

minc=20.
maxc=235.

mint= min(tiles.tavailable)
maxt= max(tiles.tavailable)

colors= long(minc+(maxc-minc)/(maxt-mint)*(tiles.tavailable-mint))

k_print, filename='tavailable.ps', xsize=11., ysize=7.

plot_poly, ti, offset=100., xra=[359.999, 0.0001], yra=[-15., 71.], $
           /fill, color=colors

!P.POSITION=[0.15, 0.7, 0.4, 0.77]
image= (findgen(maxc-minc+1L)+minc)#replicate(1.,10)
djs_plot, [0], [0], /nodata, /bottomaxis, xra=[mint, maxt], /noerase, $
          xcharsize=1.1, xtitle='Available dark/grey time, hours'
tvimage, image, /overplot

k_end_print

end
