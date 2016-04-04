pro guidetest_run_may16

platerun, '2016.03.c.apogee2-south',/supercl

excludefile=getenv('PLATEDESIGN_DIR')+'/data/apogee/exclude_fibers_a2s_may16.par'
exclude_guides, excludefile
platerun, '2016.03.c.apogee2-south',/clobber

for plate= 9024, 9033 do $
  platelines_guidetest, plate
plate_writepage, '2016.04.a.apogee2s.south'

end
