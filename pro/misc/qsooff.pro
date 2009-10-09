;+
; NAME:
;   qsooff
; PURPOSE:
;   Plot offsets relative to expected for a plate
; CALLING SEQUENCE:
;   qsooff, plate
; REVISION HISTORY:
;   22-Sep-2008  MRB, NYU
;-
;------------------------------------------------------------------------------
pro qsooff, plate

holes= yanny_readone(getenv('PLATELIST_DIR')+'/plates/'+ $
                     strtrim(string(plate/100L, f='(i4.4)'),2)+'XX/'+ $
                     strtrim(string(plate, f='(i6.6)'),2)+'/'+ $
                     'plateHolesSorted-'+ $
                     strtrim(string(plate, f='(i6.6)'),2)+'.par', hdr=hdr)
hstr= lines2struct(hdr)
np= long(hstr.npointings)
ha= long(strsplit(hstr.ha, /extr))
temp= float(hstr.temp)

itarg= where(strupcase(holes.targettype) ne 'NA', ntarg)

xf= dblarr(ntarg)
yf= dblarr(ntarg)
for pointing=1L, np do begin
    lst= double(hstr.racen)+ha[pointing-1]
    ip=where(holes[itarg].pointing eq pointing, ncurr)
    lambda= fltarr(ncurr)+5400.
    plate_ad2xy, hstr, hstr, pointing, 0L, holes[itarg[ip]].target_ra, $
      holes[itarg[ip]].target_dec, lambda, xf=tmp_xf, yf=tmp_yf, lst=lst, $
      airtemp= temp
    xf[ip]=tmp_xf
    yf[ip]=tmp_yf
endfor

dx= holes[itarg].xfocal-xf
dy= holes[itarg].yfocal-yf
splot_vec, holes[itarg].xfocal, holes[itarg].yfocal, dx*1000., dy*1000., $
  xra=[330., -330.], yra=[-330., 330]

iqso= where(strtrim(holes[itarg].sourcetype,2) eq 'QSO')
soplot, holes[itarg[iqso]].xfocal, holes[itarg[iqso]].yfocal, psym=4, $
  color='green', th=2

dr= sqrt(dx^2+dy^2)
drmean= mean(dr[iqso])

platescale = 217.7358D           ; mm/degree
splog, 'Mean QSO offset= '+ $
  strtrim(string(f='(f40.3)',drmean/platescale*3600.),2)+' arcsec'

end
