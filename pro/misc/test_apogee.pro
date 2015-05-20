pro test_apogee

;; test GC 
ra=266.4
dec= -28.9

;; Standard idea (2ish hrs)
ha_quick, 'APO', ra, dec, 0., lambda=15000., tilerad=0.5, /plot
ha_quick, 'APO', ra, dec, 0., lambda=15000., haact=15., tilerad=0.5, /plot

;; Absolute maximal radius (1ish hrs)
ha_quick, 'APO', ra, dec, 0., lambda=15000., tilerad=0.8, /plot
ha_quick, 'APO', ra, dec, 0., lambda=15000., haact=15., tilerad=0.8, /plot

;; Expanded radius with cutoff in Dec (1.4ish hrs)
ha_quick, 'APO', ra, dec, 0., lambda=15000., tilerad=0.65, declim=0.5, /plot
ha_quick, 'APO', ra, dec, 0., lambda=15000., haact=15., tilerad=0.65, declim=0.5, /plot

end
