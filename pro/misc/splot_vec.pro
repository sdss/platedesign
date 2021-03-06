pro splot_vec, x, y, dx, dy, scale=scale, _EXTRA=_extra_for_splot

if(NOT keyword_set(scale)) then scale=1.

splot, x, y, psym=4, symsize=0.9, color='red', _EXTRA=_extra_for_splot
for i=0L, n_elements(x)-1L do begin
    soplot, x[i]+[0.,dx[i]]*scale, $
      y[i]+[0.,dy[i]]*scale
endfor

end
