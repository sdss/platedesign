;+
; NAME:
;   platelines_boss
; PURPOSE:
;   write the plateLines-????.ps file for a BOSS plate
; CALLING SEQUENCE:
;   platelines_boss, plateid [, /fullsize, /sky, /std ]
; INPUTS:
;   plateid - plate ID to run on
; COMMENTS:
;   Appropriate for BOSS data
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
pro platelines_boss, in_plateid, fullsize=fullsize, sky=sky, std=std, $
                     diesoft=diesoft

common com_plb, plateid, full, holes

platescale = 217.7358D           ; mm/degree

if(NOT keyword_set(in_plateid)) then $
  message, 'Plate ID must be given!'

if(keyword_set(plateid) gt 0) then begin
    if(plateid ne in_plateid) then begin
        plateid= in_plateid
        full=0
        holes=0
    endif
endif else begin
    plateid=in_plateid
endelse

platedir= plate_dir(plateid)

if(n_tags(holes) eq 0) then begin
    plplug= platedir+'/plPlugMapP-'+ $
      strtrim(string(f='(i4.4)',plateid),2)+'.par'
    holes= yanny_readone(plplug)
    fullfile= platedir+'/plateHolesSorted-'+ $
      strtrim(string(f='(i6.6)',plateid),2)+'.par'
    full= yanny_readone(fullfile)
endif

if(n_tags(holes) eq 0 OR n_tags(full) eq 0) then begin
    msg='Could not find plPlugMapP or plateHolesSorted file for '+ $
      strtrim(string(plateid),2)
    if(keyword_set(diesoft) eq 0) then $
      message, msg
    splog, msg
    return
endif
      

if(keyword_set(sky) gt 0 AND $
   keyword_set(std) gt 0) then $
  message, 'Must set at most one of /SKY and /STD'

postfix=''
if(keyword_set(sky)) then $
  postfix='-sky'
if(keyword_set(std)) then $
  postfix='-std'

filename= platedir+'/plateLines-'+strtrim(string(f='(i6.6)',plateid),2)+ $
  postfix+'.ps'

if(keyword_set(fullsize)) then begin
    xsize=26.7717 ;; in inches
    ysize=26.7717 ;; in inches
    encap=1
    connect_thick=5
    circle_thick=2
endif else begin
    xsize=6.559
    ysize=6.559
    encap=0
    connect_thick=3
    circle_thick=2
endelse

if(keyword_set(sky)) then $
  connect_thick=1
if(keyword_set(std)) then $
  connect_thick=1

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
nblocks=50L
nper=20L
for i=0L, nblocks-1L do begin
    ii= where(-holes.fiberid ge i*nper+1L and $
              -holes.fiberid le (i+1L)*nper, nii)
    isort= lindgen(nii)
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
            djs_oplot, [xstart, xend], [ystart, yend], th=connect_thick, $
                       color=color
        endif
    endfor

    ;; draw holes; 
    for j=0L, nper-1L do begin
        theta= findgen(100)/float(99.)*!DPI*2.
        xcurr= holes[ii[j]].xfocal+ circle* cos(theta)
        ycurr= holes[ii[j]].yfocal+ circle* sin(theta)
        if(keyword_set(sky)) then begin
            ;; SKY as thick RED, 
            ;; any other as thin black
            case strupcase(holes[ii[j]].objtype) of
                'SKY': begin
                    currcolor='red'
                    currthick=4
                end
                else: begin 
                    currcolor='black'
                    currthick=1
                end
            endcase
        endif else if (keyword_set(std)) then begin
            ;; standard as thick blue
            ;; any other as thin black
            case strupcase(holes[ii[j]].objtype) of
                'SPECTROPHOTO_STD': begin
                    currcolor='blue'
                    currthick=4
                end
                else: begin 
                    currcolor='black'
                    currthick=1
                end
            endcase
        endif else begin
            ;; normally should color according to blue fiber
            currthick=circle_thick
            if(full[ii[j]].bluefiber gt 0) then begin
                currcolor='blue'
            endif else begin
                currcolor='red'
            endelse
            currthick=circle_thick
        endelse
        djs_oplot, xcurr, ycurr, color=currcolor, th=currthick
    endfor

endfor

;; finally, draw guides
iguide= where(holes.holetype eq 'GUIDE')
for i=0L, 15L do begin
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
