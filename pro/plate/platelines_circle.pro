;+
; NAME:
;   platelines_circle
; PURPOSE:
;   draw a circle around a hole for a plateLines file
; CALLING SEQUENCE:
;   platelines_circle, xfocal, yfocal, circle
; INPUTS:
;   xfocal, yfocal - [N] list of X, Y positions
;   circle - radius of circle
; OPTIONAL INPUTS:
;   color - default 'black'
;   thick - default 2
; REVISION HISTORY:
;   13-May-2015 MRB
;-
;------------------------------------------------------------------------------
pro platelines_circle, xfocal, yfocal, circle, color=color, $
                       thick=thick

if(keyword_set(thick) eq 0) then $
   thick=2
if(keyword_set(color) eq 0) then $
   color='black'

for j=0L, n_elements(xfocal)-1L do begin
   theta= findgen(100)/float(99.)*!DPI*2.
   xcurr= xfocal[j]+ circle* cos(theta)
   ycurr= yfocal[j]+ circle* sin(theta)
   djs_oplot, ycurr, xcurr, color=color, th=thick
endfor

end
