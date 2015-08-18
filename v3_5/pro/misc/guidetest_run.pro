pro guidetest_run

platerun, '2015.07.b.apogee2',/supercl
excludefile=getenv('PLATEDESIGN_DIR')+'/data/apogee/exclude_fibers_a2s.par'
exclude_guides, excludefile
for design= 9077, 9086 do $
  add_lighttrap, design
platerun, '2015.07.b.apogee2',/clobber

for plate= 8641, 8650 do $
  platelines_guidetest, plate
plate_writepage, '2015.07.b.apogee2'

end
