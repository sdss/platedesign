;+
; NAME:
;   ha_apply
; PURPOSE:
;   Apply rotation, scale, and offset 
; CALLING SEQUENCE:
;   ha_fit, ximage, yimage, rot=, scale=, xshift=, yshift=, xnew=, ynew=
; REQUIRED INPUTS:
;   ximage, yimage - [N] positions of image 
;   xshift, yshift - shift applied in X and Y
;   rot - rotation applied (deg)
;   scale - scale applied 
; OUTPUTS:
;   xnew, ynew - [N] rotated, scaled, shifted image positions
; COMMENTS:
;   First scales, then rotates, then shifts.
; REVISION HISTORY:
;   20-Dec-2008  MRB, NYU
;-
pro ha_apply, ximage, yimage, rot=rot, scale=scale, xshift=xshift, $
              yshift=yshift, xnew=xnew, ynew=ynew

if(n_elements(rot) eq 0) then $
  rot=0.
if(n_elements(scale) eq 0) then $
  scale=1.
if(n_elements(xshift) eq 0) then $
  xshift=0.
if(n_elements(yshift) eq 0) then $
  yshift=0.

xtmp= ximage*scale
ytmp= yimage*scale

xtmp2= xtmp*cos(!DPI/180.*rot)+ ytmp*sin(!DPI/180.*rot)
ytmp2= ytmp*cos(!DPI/180.*rot)- xtmp*sin(!DPI/180.*rot)

xnew= xtmp2+ xshift
ynew= ytmp2+ yshift

end

