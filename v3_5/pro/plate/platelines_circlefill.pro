;+
; NAME:
;   platelines_circlefill
; PURPOSE:
;   draw a filled circle around a hole for a plateLines file
; CALLING SEQUENCE:
;   platelines_circlefill, xfocal, yfocal, circle
; INPUTS:
;   xfocal, yfocal - [N] list of X, Y positions
;   circle - radius of circle
; OPTIONAL INPUTS:
;   color - default 'white'
; REVISION HISTORY:
;   13-May-2015 MRB
;-
;------------------------------------------------------------------------------
pro platelines_circlefill, xfocal, yfocal, circle, color=color

if(keyword_set(color) eq 0) then $
   color='white'

for j=0L, n_elements(xfocal)-1L do begin
   theta= findgen(100)/float(99.)*!DPI*2.
   xcurr= xfocal[j]+ circle* cos(theta)
   ycurr= yfocal[j]+ circle* sin(theta)
   polyfill, ycurr, xcurr, color=djs_icolor(color)
endfor

end
