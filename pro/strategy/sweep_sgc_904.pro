pro sweep_sgc_904

; sweep them
window_read, flist=flist
funiq=(uniqtag(flist,'run'))
for i=0, n_elements(funiq)-1 do $
  for camcol=1, 6 do $
  datasweep, funiq[i].run, camcol, rerun=funiq[i].rerun, catalog='', $
    output=['GALS_ALL','STARS_ALL','SKY_ALL']

end
