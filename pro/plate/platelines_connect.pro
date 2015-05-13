;+
; NAME:
;   platelines_connect
; PURPOSE:
;   connect a list of holes
; CALLING SEQUENCE:
;   platelines_connect, xfocal, yfocal [, buffer=, thick= ]
; INPUTS:
;   xfocal, yfocal - [N] list of X, Y positions
; OPTIONAL INPUTS:
;   buffer - buffer value (default 105./3600.*platescale)
;   thick - default 2
;   color - default 'black'
; REVISION HISTORY:
;   13-May-2015 MRB
;-
;------------------------------------------------------------------------------
pro platelines_connect, xfocal, yfocal, buffer=buffer, thick=thick, $
                        color=color

platescale = 217.7358D          ; mm/degree

if(keyword_set(buffer) eq 0) then $
   buffer= 105./3600.*platescale
if(keyword_set(thick) eq 0) then $
   thick=2
if(keyword_set(color) eq 0) then $
   color='black'

for j=0L, (n_elements(xfocal)-2L) do begin
   xhole1= xfocal[j]
   xhole2= xfocal[j+1]
   yhole1= yfocal[j]
   yhole2= yfocal[j+1]
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
                 th=thick, color=color
   endif
endfor

end
