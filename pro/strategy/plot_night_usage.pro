pro plot_night_usage, nint=nint, nuse=nuse

nights=yanny_readone(getenv('PLATEDESIGN_DIR')+ $
                     '/data/strategy/boss_observing_nights.par')

months=['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', $
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec']

ipos=lonarr(n_elements(nights))
for i=0L, n_elements(nights)-1L do begin
    month= strmid(nights[i].date, 3, 3)
    iyear= long(strmid(nights[i].date, 7, 4))
    imonth=where(month eq months)
    ipos[i]=iyear*12L+imonth
endfor

pos=lonarr(10L*12L)
nint_pos=lonarr(10L*12L)
nuse_pos=lonarr(10L*12L)
for i=0L, n_elements(nint_pos)-1L do begin
    pos[i]=2005L*12L+i
    ii=where(ipos eq pos[i], nii)
    if(nii gt 0) then begin
        nint_pos[i]=total(nint[ii])
        nuse_pos[i]=total(nuse[ii])
    endif
endfor

k_print, filename=getenv('PLATEDESIGN_DIR')+'/data/strategy/night_usage.ps'
!P.MULTI=[2,1,2]
!Y.MARGIN=0
djs_plot, float(pos)/12., nint_pos, psym=10, th=4, $
  xra=[2009.5, 2014.6], xcharsize=0.0001, yti='!6available and used', $
  yra=[-5, 105], title='!6Usage of 80min intervals'
djs_oplot, float(pos)/12., nuse_pos, psym=10, th=2
djs_plot, float(pos)/12., float(nuse_pos)/float(nint_pos), psym=10, th=4, $
  xra=[2009.5, 2014.6], yra=[-0.05, 1.05], yti='!6fraction used'
k_end_print

end
