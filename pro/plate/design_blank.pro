;+
; NAME:
;   design_blank
; PURPOSE:
;   Initialize a design structure
; CALLING SEQUENCE:
;   design= design_blank([/center])
; OPTIONAL KEYWORDS:
;   /center - return a center hole
;   /guide - return a guide hole
; OUTPUTS:
;   design - structure containing center hole information
; COMMENTS:
;   Assumes center hole is 3.175 mm
; BUGS:
;   Need to revisit GUIDE and CENTER diameters and buffers
; REVISION HISTORY:
;   9-May-2008 MRB, NYU (based on DJS's design_append)
;-
function design_blank, center=center, guide=guide

design0={holetype:'NA', $
         sourcetype:'NA', $
         target_ra:0.D, $
         target_dec:0.D, $
         iplateinput:-1L, $
         pointing:0L, $
         offset:0L, $
         fiberid:-9999L, $
         iguide:-9999L, $
         xf_default:0., $
         yf_default:0., $
         diameter:0., $
         buffer:0., $
         priority:0L, $
         assigned:0L}

if(keyword_set(center)) then begin
    design0.holetype='CENTER'
    design0.diameter=2.*3.175
    design0.buffer=0.94
endif
if(keyword_set(center)) then begin
    design0.holetype='GUIDE'
    design0.source='STAR'
    design0.diameter=2.*3.32
    design0.buffer=7.0
endif

return, design0

end

