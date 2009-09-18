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
pro platelines_boss, in_plateid, diesoft=diesoft, sorty=sorty

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
    platelines_start, plateid, filebase, label, note=note
    
    ;; set buffer for lines, and circle size
    ;; (48 and 45 arcsec respectively
    buffer= 48./3600. * platescale
    circle= 45./3600. * platescale
    
    ;; set colors of each brightness fiber
    nblocks=50L
    nper=20L
    nperblue=10L
    for i=0L, nblocks-1L do begin
        ii= where(-holes.fiberid ge i*nper+1L and $
                  -holes.fiberid le (i+1L)*nper, nii)
        isort= lindgen(nii)
        if(keyword_set(sorty)) then $
          isort= sort(holes[ii].yfocal)
        color= colors[i mod n_elements(colors)]

        bluefiber= lonarr(nii)
        iblue=where(full[ii].bluefiber, nblue)
        if(nblue gt nperblue) then $
          iblue= iblue[shuffle_indx(nblue, num_sub=nperblue, $
                                    seed=plateid+i)]
        if(nblue gt 0) then $
          bluefiber[iblue]=1
        
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
                if(bluefiber[j] gt 0) then begin
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
    
    platelines_end
endfor

platelines_guide, plateid, holes, full, hdrstr

return
end
