;+
; NAME:
;   platelines_boss
; PURPOSE:
;   write the plateLines-????.ps file for a BOSS plate
; CALLING SEQUENCE:
;   platelines_boss, plateid [, /sky, /std ]
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
pro plb_set_print, in_filebase, label, note=note

common com_plb, plateid, full, holes
common com_plb_print, pold, xold, yold, filebase, plans

filebase=in_filebase
xsize=6.559
ysize=6.559
encap=1
scale=2.21706

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

if(n_tags(plans) eq 0) then $
  plans= yanny_readone(getenv('PLATELIST_DIR')+'/platePlans.par')
iplate=where(plans.plateid eq plateid)
plan= plans[iplate]

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
djs_xyouts, [-330], [280], 'Program: '+strtrim(string(plan.programname),2), $
            charsize=0.7

djs_xyouts, [80], [325], label
if(keyword_set(note)) then $
  djs_xyouts, [100], [-325], note

arrow, -320, -320, -320, -270, /data, th=3, hsize=150
arrow, -320, -320, -270, -320, /data, th=3, hsize=150

djs_xyouts, [-335.], [-260], '+X, +RA', charsize=0.8
djs_xyouts, [-260.], [-325], '+Y, +Dec', charsize=0.8

end
;
pro plb_end_print

common com_plb_print

;; get out of postscript device
device,/close
!P=pold
!X=xold
!Y=yold
set_plot,'x'

spawn, 'convert '+filebase+'.ps '+filebase+'.png'

end
;
pro platelines_boss, in_plateid, diesoft=diesoft, sorty=sorty

common com_plb

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
      

;; basic versions
versions=['', 'sky', 'std']

;; z-offset values
zoffstr=strtrim(string((uniqtag(full, 'zoffset')).zoffset, f='(i)'),2)
inot=where(zoffstr ne '0', nnot)
if(nnot gt 0) then $
  versions=[versions, 'zoffset-'+zoffstr[inot]]

;; make various block colors
colors= ['red', 'green', 'blue', 'magenta', 'cyan']
versions= [versions, 'block-'+colors]

for k=0L, n_elements(versions)-1L do begin
    
    version=versions[k]

    postfix=''
    if(keyword_set(version)) then $
      postfix='-'+version

    filebase= platedir+'/plateLines-'+strtrim(string(f='(i6.6)',plateid),2)+ $
              postfix
    
    connect_thick=3
    circle_thick=2
    
    if(keyword_set(version) gt 0 AND $
      strmatch(version, 'block-*') eq 0) then $
      connect_thick=1

    nolines=0
    if(strmatch(version, 'zoffset-*') gt 0) then $
      nolines=1

    label='BOSS fibers'
    if(keyword_set(version)) then $
      label=label+' ('+version+')'
    note=''
    plb_set_print, filebase, label, note=note
    
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
        if(keyword_set(sorty)) then $
          isort= sort(holes[ii].yfocal)
        color= colors[i mod n_elements(colors)]
        
        ;; connect lines
        doblock=1
        if (strmatch(version,'block-*') gt 0) then begin
            colorval= (strsplit(version, '-', /extr))[1]
            if(colorval ne color) then $
              doblock=0
        endif
        if(keyword_set(nolines) eq 0 AND $
           doblock gt 0) then begin
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
                    djs_oplot, [ystart, yend], [xstart, xend], $
                               th=connect_thick, color=color
                endif
            endfor
        endif
        
        ;; draw holes; 
        for j=0L, nper-1L do begin
            theta= findgen(100)/float(99.)*!DPI*2.
            xcurr= holes[ii[j]].xfocal+ circle* cos(theta)
            ycurr= holes[ii[j]].yfocal+ circle* sin(theta)
            ncirc=1L
            if(version eq 'sky') then begin
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
            endif else if (version eq 'std') then begin
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
            endif else if (strmatch(version,'zoffset-*') gt 0) then begin

                zoffval= float((strsplit(version, '-', /extr))[1])
                
                ;; standard as thick blue
                ;; any other as thin black
                if(full[ii[j]].zoffset ne zoffval) then begin
                    currcolor='black'
                    currthick=1
                endif else begin
                    case zoffval of
                        100: begin
                            currcolor='magenta'
                            currthick=2
                            ncirc=2
                        end
                        175: begin
                            currcolor='magenta'
                            currthick=2
                            ncirc=3
                        end
                        300: begin
                            currcolor='magenta'
                            currthick=2
                            ncirc=4
                        end
                        else: begin 
                            splog, 'Unexpected ZOFFSET value '+ $
                                   strtrim(string(full[ii[j]].zoffset),2)
                            currcolor='red'
                            currthick=10
                        end
                    endcase
                endelse
            endif else begin
                ;; normally should color according to blue fiber
                currthick=circle_thick
                if(full[ii[j]].bluefiber gt 0) then begin
                    currcolor='blue'
                endif else begin
                    currcolor='red'
                endelse
                currthick=circle_thick
                
                if (strmatch(version,'block-*') gt 0) then begin
                    colorval= (strsplit(version, '-', /extr))[1]
                    if(colorval ne color) then begin
                        currcolor='black'
                        currthick=1
                    endif
                endif
            endelse
            djs_oplot, ycurr, xcurr, color=currcolor, th=currthick
            for l=1L, ncirc-1L do begin
                scale=l*0.3+1.
                xcurr= holes[ii[j]].xfocal+ scale*circle* cos(theta)
                ycurr= holes[ii[j]].yfocal+ scale*circle* sin(theta)
                djs_oplot, ycurr, xcurr, color=currcolor, th=1
            endfor
        endfor
    endfor
    
    plb_end_print
endfor

filebase= platedir+'/plateLines-'+strtrim(string(f='(i6.6)',plateid),2)+ $
          '-guide'

noguide=lonarr(16)
for i=0L, 15L do begin
    ii=where(holes.holetype eq 'GUIDE' AND $
             holes.fiberid eq i+1, nii)
    if(nii eq 0) then $
      noguide[i]=1
endfor
inone=where(noguide gt 0, nnone)
note=''
if(nnone gt 0) then begin
    note= 'No star for guide #'
    for i=0L, nnone-2L do $
          note=note+strtrim(string(inone[i]+1L),2)+','
    note=note+strtrim(string(inone[nnone-1]+1L),2)
endif

plb_set_print, filebase, 'guide fibers', note=note

;; finally, draw guides
iguide= where(holes.holetype eq 'GUIDE')
for i=0L, 15L do begin
    theta= findgen(100)/float(99.)*!DPI*2.
    xcurr= holes[iguide[i]].xfocal+ circle* cos(theta)
    ycurr= holes[iguide[i]].yfocal+ circle* sin(theta)
    djs_oplot, ycurr, xcurr, color='black', th=circle_thick

    djs_xyouts, holes[iguide[i]].yfocal+5.*buffer, $
                holes[iguide[i]].xfocal, $
                strtrim(string(holes[iguide[i]].fiberid),2), $
                align=0.5

    ;; red X if bad guy
    if(holes[iguide[i]].fiberid le 0) then begin
        djs_oplot, [holes[iguide[i]].yfocal], [holes[iguide[i]].xfocal], $
                   color='red', th=3, symsize=1.5, psym=2
    endif
endfor

plb_end_print


return
end
