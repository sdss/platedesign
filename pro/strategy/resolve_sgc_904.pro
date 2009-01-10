pro resolve_sgc_904

runlist= sdss_runlist(rerun=904)

ikeep= where(runlist.run ge 7000)

ssruns= [1022, 1035, 1043, 1045, 1659, 1663, 1666, $
        1729, 1737, 1738, 1739, 1740, 1741, 1749, $
        1754, 1755, 1854, 1855, 1862, 1869, 1888, $
        1893, 1904, 2073, 2385, 2506, 2507, 2566, $
        2575, 2576, 2659, 2873, 3322, 3438, 4192, $
        4203, 4207, 4263, 4822, 4858, 4874, 5042, $
        5052]


rerun= [replicate('904', n_elements(ikeep)), $
        replicate('137', n_elements(ssruns))]

runs= [runlist[ikeep].run, ssruns]

resolve_dir = getenv('PHOTO_RESOLVE')
cd, resolve_dir

; run window
logfile = djs_filepath('window.log', root_dir=getenv('PHOTO_RESOLVE'))
t0 = systime(1)
splog, filename=logfile, 'Begun at ', systime(), /append

; first make the full field list
window_fieldlist, runs, rerun=rerun
window_read, flist=flist

; now do the rest of window
window_score
window_balkanize
window_findx
window_assign

; and then resolve
resolve_reobj
resolve_global_primary, /no_cache

; sweep them
window_read, flist=flist
funiq=(uniqtag(flist,'run'))
for i=0, n_elements(funiq)-1 do $
  for camcol=1, 6 do $
  datasweep, funiq[i].run, camcol, rerun=funiq[i].rerun, catalog='', $
    output=['GALS_ALL','STARS_ALL','SKY_ALL']

end
