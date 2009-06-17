pro splot_rbs, tiles

splot, tiles.ra, tiles.dec, psym=3, xra=[360., 0.]
ii=where(tiles.dark gt 0, nii)
if(nii gt 0) then $
  soplot, tiles[ii].ra, tiles[ii].dec, psym=3, color='red'

year=long(strmid(tiles.date, 7, 4))
months=['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', $
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec']
month= strmid(tiles.date, 3, 3)
imonth=lonarr(n_elements(month))
for i=0L, n_elements(month)-1L do $
  imonth[i]=strtrim(string(where(month[i] eq months)+1L),2)

colors=['red', 'yellow', 'green', 'cyan', 'blue', 'white']

;; for each observing season display Fall
for i=2009L, 2014L do begin
    ii=where((year eq i and imonth ge 9), nii)
    if(nii gt 0) then begin
        soplot, tiles[ii].ra, tiles[ii].dec, psym=4, color=colors[i-2009]
    endif
    ii=where((year eq i and imonth ge 9) and tiles.dark gt 0, nii)
    if(nii gt 0) then begin
        soplot, tiles[ii].ra, tiles[ii].dec, psym=4, color=colors[i-2009], $
          th=3
    endif
endfor

;; for each observing season display Spring
for i=2010L, 2014L do begin
    ii=where(year eq i and imonth le 8, nii)
    if(nii gt 0) then begin
        soplot, tiles[ii].ra, tiles[ii].dec, psym=5, color=colors[i-2010]
    endif
    ii=where(year eq i and imonth le 8 and tiles.dark gt 0, nii)
    if(nii gt 0) then begin
        soplot, tiles[ii].ra, tiles[ii].dec, psym=5, color=colors[i-2010], $
          th=3
    endif
endfor

end
