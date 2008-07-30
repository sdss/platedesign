;; code to produce QA files for guide star selection
pro test_guide_stars

sgfile=getenv('PLATEDESIGN_DIR')+'/data/test/guide_sdss.fits'
tgfile=getenv('PLATEDESIGN_DIR')+'/data/test/guide_2mass.fits'


if(file_test(sgfile) eq 0 OR file_test(tgfile) eq 0) then begin
    plate_select_guide_sdss, 180.0, 9.5, epoch=2008., guide_design=sg
    plate_select_guide_2mass, 180.0, 9.5, epoch=2008., guide_design=tg
    mwrfits, sg, sgfile, /create
    mwrfits, tg, tgfile, /create
endif else begin
    sg=mrdfits(sgfile,1)
    tg=mrdfits(tgfile,1)
endelse

radec2kml, sg.target_ra, sg.target_dec, getenv('PLATEDESIGN_DIR')+ $
  '/data/test/guide_sdss.kml', $
  description=replicate('SDSS-based guide', n_elements(sg)), $
  color='#ffffffff'

radec2kml, tg.target_ra, tg.target_dec, getenv('PLATEDESIGN_DIR')+ $
  '/data/test/guide_2mass.kml', $
  description=replicate('2MASS-based guide', n_elements(tg)), $
  color='#ff00ffff'

end
