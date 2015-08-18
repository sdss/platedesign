pro retrofit_bad_ra

plates=[3577, $
        3578, $
        3579, $
        4216, $
        4277, $
        4296, $
        4354, $
        4405, $
        4415, $
        4534, $
        4535]

for i=0L, n_elements(plates)-1L do $
  fix_plug_ra_range, plates[i]

end
