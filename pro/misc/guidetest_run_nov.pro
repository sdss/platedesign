pro guidetest_run_nov

platerun, '2015.10.a.apogee2-south',/supercl
excludefile=getenv('PLATEDESIGN_DIR')+'/data/apogee/exclude_fibers_a2s_nov.par'
exclude_guides, excludefile
platerun, '2015.10.a.apogee2-south',/clobber

for plate= 8770, 8772 do $
  platelines_guidetest, plate
plate_writepage, '2015.10.a.apogee2-south'

end
