;+
; NAME:
;   alignment_fiber
; PURPOSE:
;   Return xfocal and yfocal of alignment fiber given guide location
; CALLING SEQUENCE:
;   alignment_fiber, gnum, xf_guide, yf_guide, xf_align, yf_align
; INPUTS:
;   gnum - guide fiber number
;   xf_guide, yf_guide - focal plane location of guide fiber (mm)
; OUTPUTS:
;   xf_align, yf_align - focal plane location of alignment fiber (mm)
; REVISION HISTORY:
;   10-Jun-2008  MRB, NYU
;-
pro alignment_fiber, gnum, xf_guide, yf_guide, xf_align, yf_align, $
                     gfibertype=gfibertype

if(keyword_set(gfibertype) eq 0) then $
  gfibertype='gfiber'

gfiber= call_function(gfibertype+'_params')

dradeg= 180.D/!DPI

twist_coeff=0.45
align_hole_dist=2.54

if(gfiber[gnum-1].yreach gt 0.) then $
  thisang= (90.D) + twist_coeff*(yf_guide - gfiber[gnum-1].yreach) $
else $
  thisang= -(90.D) - twist_coeff*(yf_guide - gfiber[gnum-1].yreach) 
  
xf_align= xf_guide+align_hole_dist*cos(thisang/dradeg)
yf_align= yf_guide+align_hole_dist*sin(thisang/dradeg)

end
;------------------------------------------------------------------------------
