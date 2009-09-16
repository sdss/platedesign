;+
; NAME:
;   platelines_marvels
; PURPOSE:
;   write the plateLines-????.ps file for a MARVELS plate
; CALLING SEQUENCE:
;   platelines_marvels, plateid 
; INPUTS:
;   plateid - plate ID to run on 
; COMMENTS:
;   Appropriate for MARVELS data
; BUGS:
;   Works off the plPlugMapP file, so may be fragile.
; REVISION HISTORY:
;   22-Aug-2008  MRB, NYU
;-
;------------------------------------------------------------------------------
pro platelines_marvels, in_plateid

common com_plm, plateid, full, holes, hdrstr, npointings

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
    holes= yanny_readone(plplug, hdr=hdr)
    hdrstr= lines2struct(hdr, /relaxed)
    npointings= long(hdrstr.npointings)

    fullfile= platedir+'/plateHolesSorted-'+ $
      strtrim(string(f='(i6.6)',plateid),2)+'.par'
    full= yanny_readone(fullfile)
endif

gfibertype= 'gfiber'
if(tag_indx(hdrstr, 'gfibertype') ne -1) then $
  gfibertype= hdrstr.gfibertype
gfiber= call_function(gfibertype+'_params')

if(n_tags(holes) eq 0 OR n_tags(full) eq 0) then begin
    msg='Could not find plPlugMapP or plateHolesSorted file for '+ $
      strtrim(string(plateid),2)
    if(keyword_set(diesoft) eq 0) then $
      message, msg
    splog, msg
    return
endif

filebase= platedir+'/plateLines-'+strtrim(string(f='(i6.6)',plateid),2)

platelines_start, plateid, filebase, 'MARVELS science fibers'

nblocks=15L
nper=4L
linestyles=[0,2,1]

linecolors=strarr(15,2)
linecolors[*,0]=['black', 'blue', 'green', 'red', 'yellow', $
                 'black', 'blue', 'green', 'red', 'yellow', $
                 'black', 'blue', 'green', 'red', 'yellow']
linecolors[*,1]= linecolors[(lindgen(15)+2L) MOD 15]
circlecolors= ['cyan','magenta','yellow','orange']

;; set buffer for lines, and circle size
;; (48 and 45 arcsec respectively
buffer= 48./3600. * platescale
circle= 45./3600. * platescale

for index=0L, npointings-1L do begin

    pointing_name = STRSPLIT(hdrstr.pointing_name, /extract)
    case pointing_name[index] of
        'A' : ip = 0            ;
        'B' : ip = 1            ;
        'C' : ip = 2            ;
        'D' : ip = 3            ;
        'E' : ip = 4            ;
        'F' : ip = 5            ;
        else : message, 'Invalid pointing specified (' + $
          pointing_name[index] + ')'
    endcase
    
    ;; select all fibers
    iobj= where(holes.holetype eq 'OBJECT') ; index of OBJECTs

    ;; For two pointings, the first will cover a range of fiberids
    ;; (e.g. -1 to -60), and the second pointing will be another
    ;; range (e.g. -61 to -120). "foff" determines the fiberid offset
    ;; based on the current pointing.
    foff= ip*nblocks*nper       ; fiber offset

    ;; Thus, we expect foff = 0            for pointing 1
    ;;             and foff = nblocks*nper for pointing 2
    for i=0L, nblocks-1L do begin

        ii= where(-holes[iobj].fiberid ge i*nper+1+foff and $  ; 1
                  -holes[iobj].fiberid le (i+1)*nper+foff, nii); 4
        ii=iobj[ii]
        isort= sort(abs(holes[ii].fiberid))
        linecolor= linecolors[i,ip]
        
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
                djs_oplot, [ystart, yend], [xstart, xend], th=5, $
                  color=linecolor, linestyle=linestyles[ip]
            endif
        endfor
        
        ;; draw holes & labels
        for j=0L, nper-1L do begin
            icc=abs(holes[ii[isort[j]]].fiberid)-1L-i*nper-foff
            circlecolor= circlecolors[icc]
            theta= findgen(100)/float(99.)*!DPI*2.
            xcurr= holes[ii[isort[j]]].xfocal+ circle* cos(theta)
            ycurr= holes[ii[isort[j]]].yfocal+ circle* sin(theta)
            djs_oplot, ycurr, xcurr, color=circlecolor
            numstr= strtrim(string(abs(holes[ii[isort[j]]].fiberid)),2)
            djs_xyouts, ycurr[0]+8., xcurr[0]-2., numstr, align=0.5, $
              charsize=0.5
        endfor
        
    endfor
endfor

platelines_end

platelines_guide, plateid, holes, full, hdrstr

return
end
