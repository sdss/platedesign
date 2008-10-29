;+
; NAME:
;   platelines_segue2
; PURPOSE:
;   write the plateLines-????.ps file for a SEGUE-2 plate
; CALLING SEQUENCE:
;   platelines_segue2, plateid
; INPUTS:
;   plateid - plate ID to run on 
; COMMENTS:
;   Appropriate for SEGUE-2 data
;   Makes a PostScript file 26.7717 by 26.7717 inches; mapping
;    should be one-to-one onto plate (x and y ranges are from -340 to
;    +340 mm).
;   Some lines cross each other, due to enforcement of
;    one-sky-per-block constraints.
;   Circles are 45 arcsec radius.
;   Colors of circles are blue for 8 faintest stars in block, green
;    for the 6 next brightest, and red for the 6 brightest
; BUGS:
;   Works off the plPlugMapP file, so may be fragile.
; REVISION HISTORY:
;   22-Aug-2008  MRB, NYU
;-
;------------------------------------------------------------------------------
pro platelines_segue2, plateid

platescale = 217.7358D           ; mm/degree

platedir= plate_dir(plateid)
plplug= platedir+'/plPlugMapP-'+ $
  strtrim(string(f='(i4.4)',plateid),2)+'.par'
holes= yanny_readone(plplug)

filename= platedir+'/plateLines-'+strtrim(string(f='(i6.6)',plateid),2)+'.ps'

xsize=26.7717 ;; in inches
ysize=26.7717 ;; in inches
encap=1

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
device, file=filename,/inches,xsize=xsize,ysize=ysize, $
  xoffset=(8.5-xsize)/2.0,yoffset=(11.0-ysize)/2.0,/color, $
  bits_per_pixel=64, encap=encap
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

colors= ['black', 'red', 'green', 'blue', 'magenta', 'cyan', 'purple']

;; set buffer for lines, and circle size
;; (48 and 45 arcsec respectively
buffer= 48./3600. * platescale
circle= 45./3600. * platescale

;; set colors of each brightness fiber
brightcolor= 'red'
medcolor= 'green'
faintcolor= 'blue'
fibercolors= [ replicate(faintcolor, 8), $
               replicate(medcolor, 6), $
               replicate(brightcolor, 6)]

nblocks=32L
nper=20L
for i=0L, nblocks-1L do begin
    ii= where(-holes.fiberid ge i*nper+1L and $
              -holes.fiberid le (i+1L)*nper, nii)
    isort= sort(holes[ii].yfocal)
    color= colors[i mod n_elements(colors)]

    ;; connect lines
    for j=0L, nper-2L do begin
        xhole1= holes[ii[isort[j]]].xfocal
        xhole2= holes[ii[isort[j+1]]].xfocal
        yhole1= holes[ii[isort[j]]].yfocal
        yhole2= holes[ii[isort[j+1]]].yfocal
        length= sqrt((xhole2-xhole1)^2+(yhole2-yhole1)^2)
        sbuffer=buffer 
        ebuffer=(length-buffer) 
        if(ebuffer gt sbuffer) then begin
            xdir= (xhole2-xhole1)/length
            ydir= (yhole2-yhole1)/length
            xstart= (xhole1+sbuffer*xdir) 
            ystart= (yhole1+sbuffer*ydir) 
            xend= (xhole1+ebuffer*xdir) 
            yend= (yhole1+ebuffer*ydir) 
            djs_oplot, [xstart, xend], [ystart, yend], th=5, color=color
        endif
    endfor

    ;; draw holes; sort from faintest to brightest, and color
    ;; according to fibercolors
    mag= 0.5*(holes[ii].mag[1]+holes[ii].mag[3])
    izero= where(mag eq 0, nzero)
    if(nzero gt 0) then $
      mag[izero]=30.
    isort= reverse(sort(mag))
    for j=0L, nper-1L do begin
        theta= findgen(100)/float(99.)*!DPI*2.
        xcurr= holes[ii[isort[j]]].xfocal+ circle* cos(theta)
        ycurr= holes[ii[isort[j]]].yfocal+ circle* sin(theta)
        djs_oplot, xcurr, ycurr, color=fibercolors[j]
    endfor

endfor

;; finally, draw guides
iguide= where(holes.holetype eq 'GUIDE')
for i=0L, 10L do begin
    djs_xyouts, holes[iguide[i]].xfocal+2.*buffer, $
      holes[iguide[i]].yfocal, $
      strtrim(string(holes[iguide[i]].fiberid),2), align=0.5
endfor

;; get out of postscript device
device,/close
!P=pold
!X=xold
!Y=yold
set_plot,'x'

return
end
