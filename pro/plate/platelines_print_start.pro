;+
; NAME:
;   platelines_start
; PURPOSE:
;   begin a platelines file
; CALLING SEQUENCE:
;   platelines_start, filebase, label [, note= ]
; REVISION HISTORY:
;   22-Sep-2008  MRB, NYU
;-
;------------------------------------------------------------------------------
pro platelines_print_end

common com_pl_print, pold, xold, yold, filebase, plans

;; get out of postscript device
device,/close
!P=pold
!X=xold
!Y=yold
set_plot,'x'

spawn, 'convert -units PixelsPerInch '+filebase+'.ps '+ $
       '-density 100 '+filebase+'.png'
file_delete, filebase+'.ps'
end
;
pro platelines_print_start, plateid, in_filebase, label, note=note

common com_pl_print

filebase=in_filebase
xsize=6.559
ysize=6.559
encap=1
scale=2*2.21706*1.27903

;; setup postscript device
pold=!P
xold=!X
yold=!Y
!P.FONT= -1
set_plot, "PS"
if(NOT keyword_set(axis_char_scale)) then axis_char_scale= 1.75
if(NOT keyword_set(tiny)) then tiny=1.d-4
!P.BACKGROUND= djs_icolor('white')
!P.COLOR= djs_icolor('black')
device, file=filebase+'.ps',/inches,xsize=xsize,ysize=ysize, $
  xoffset=(8.5-xsize)/2.0,yoffset=(11.0-ysize)/2.0,/color, $
  bits_per_pixel=64, encap=encap, scale=scale
!P.THICK= 2.0
!P.CHARTHICK= !P.THICK & !X.THICK= !P.THICK & !Y.THICK= !P.THICK
!P.CHARSIZE= 1.0
!P.PSYM= 0
!P.LINESTYLE= 0
!P.TITLE= ''
!X.STYLE= 5
!X.CHARSIZE= axis_char_scale
!X.MARGIN= 0
!X.OMARGIN= 0
!X.RANGE= 0
!X.TICKS= 0
!Y.STYLE= 5
!Y.CHARSIZE= !X.CHARSIZE
!Y.MARGIN= 0.
!Y.OMARGIN= 0.
!Y.RANGE= 0
!Y.TICKS= !X.TICKS
!P.MULTI= [1,1,1]
xyouts, 0,0,'!6'
colorname= ['red','green','blue','magenta','cyan','dark yellow', $
            'purple','light green','orange','navy','light magenta', $
            'yellow green']
ncolor= n_elements(colorname)
loadct,0

djs_plot, [0], [0], /nodata, xra=[-340., 340.], yra=[-340., 340.], $
  xstyle=5, ystyle=5

radius=324.426
theta= findgen(1000)/float(99.)*!DPI*2.
xcurr= radius* cos(theta)
ycurr= radius* sin(theta)
djs_oplot, ycurr, xcurr

if(n_tags(plans) eq 0) then begin
  plateplans_file = getenv('PLATELIST_DIR')+'/platePlans.par'
  check_file_exists, plateplans_file, plateid=plateid
  plans= yanny_readone(plateplans_file)
endif
iplate=where(plans.plateid eq plateid)
plan= plans[iplate]

if(0) then begin
djs_xyouts, [-330], [330], 'Plate: '+strtrim(string(plateid),2), $
            charsize=0.7
djs_xyouts, [-330], [320], 'Chunk: '+strtrim(string(plan.chunk),2), $
            charsize=0.7
djs_xyouts, [-330], [310], 'Tile: '+strtrim(string(plan.tileid),2), $
            charsize=0.7
djs_xyouts, [-330], [300], 'Plate run: '+strtrim(string(plan.platerun),2), $
            charsize=0.7
djs_xyouts, [-330], [290], 'Survey: '+strtrim(string(plan.survey),2), $
            charsize=0.7
xyouts, [-330], [280], 'Program: '+strtrim(string(plan.programname),2), $
  charsize=0.7
djs_xyouts, [-330], [270], 'RA (p1): '+ $
            strtrim(string(plan.racen,f='(f30.3)'),2), $
            charsize=0.7
djs_xyouts, [-330], [260], 'Dec (p1): '+ $
            strtrim(string(plan.deccen,f='(f30.3)'),2), $
            charsize=0.7
djs_xyouts, [-330], [250], 'HA (p1): '+ $
            strtrim(string(plan.ha[0],f='(f30.1)'),2), $
            charsize=0.7

djs_xyouts, [80], [325], label
if(keyword_set(note)) then $
  djs_xyouts, [100], [-325], note

arrow, -320, -320, -320, -270, /data, th=3, hsize=150
arrow, -320, -320, -270, -320, /data, th=3, hsize=150

djs_xyouts, [-335.], [-260], '+X, +RA', charsize=0.8
djs_xyouts, [-260.], [-325], '+Y, +Dec', charsize=0.8
endif

end
