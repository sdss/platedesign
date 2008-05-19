;+
; NAME:
;   check_conflicts
; PURPOSE:
;   Check for conflicts between a desired target and current design
; CALLING SEQUENCE:
;   conflict= check_conflicts(design, new)
; INPUTS:
;   design - [N] Structure describing current design; must have elements:
;               .XFOCAL
;               .YFOCAL
;               .DIAMETER
;               .BUFFER
;   new - Structure describing desired target, same elements
;         required
; OUTPUTS:
;   conflict - 1 if a conflict, 0 otherwise
; COMMENTS:
;   Units of DIAMETER and BUFFER are mm.
;   Conflict is registered if new target is within 
;       (DIAMETER_NEW/2+BUFFER_NEW) + (DIAMETER_OLD/2+BUFFER_OLD) 
;     of any old target
;   Design is ALWAYS assumed to have some element 
;    (since all designs will have the center hole)
; REVISION HISTORY:
;   9-May-2008 MRB, NYU (based on DJS's design_append)
;-
function check_conflicts, design, new

if(n_tags(design) eq 0) then $
  message, 'empty design structure'

xx_design=fltarr(2,n_elements(design))
xx_design[0,*]= design.xf_default
xx_design[1,*]= design.yf_default

xx_new=fltarr(2,1)
xx_new[0,0]= new.xf_default
xx_new[1,0]= new.yf_default

;; find all potential conflicts
maxconflict= max([design.diameter+2.*design.buffer, $
                  new.diameter+2.*new.buffer])
matchnd, xx_design, xx_new, maxconflict, m1=m1, m2=m2, nmatch=nmatch, $
         max=0, nd=2, /silent

;; check the close calls
for i=0L, nmatch-1L do begin
    distance= sqrt((xx_design[0,m1[i]]-xx_new[0,m2[i]])^2+ $
                   (xx_design[1,m1[i]]-xx_new[1,m2[i]])^2)
    condition=design[m1[i]].diameter*0.5+design[m1[i]].buffer+ $
              new[m2[i]].diameter*0.5+new[m2[i]].buffer
    if(distance lt condition) then $
      return, 1
endfor

;; if we made it out of the loop, no conflict found
return, 0

end

