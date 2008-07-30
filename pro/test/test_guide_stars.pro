;; code to produce QA files for guide star selection
pro test_tmass_conversion

plate_select_guide_sdss, 180.0, 9.5, epoch=2008., guide_design=sg
plate_select_guide_2mass, 180.0, 9.5, epoch=2008., guide_design=tg

mwrfits, sg, getenv('PLATEDESIGN_DIR')+'/data/test/guide_sdss.fits', /create
mwrfits, tg, getenv('PLATEDESIGN_DIR')+'/data/test/guide_2mass.fits', /create



end
