;+
; NAME:
;   design_blank
; PURPOSE:
;   Initialize a design structure
; CALLING SEQUENCE:
;   design= design_blank([/center])
; OPTIONAL KEYWORDS:
;   /center - return a center hole
; OUTPUTS:
;   design - structure containing center hole information
; COMMENTS:
;   Assumes center hole is 
; REVISION HISTORY:
;   9-May-2008 MRB, NYU (based on DJS's design_append)
;-
function design_blank, center=center

design0={holetype:'NA', $
         sourcetype:'NA', $
         target_ra:0.D, $
         target_dec:0.D, $
         pointing:0L, $
         offset:0L, $
         fiberid:-9999L, $
         xf_default:0., $
         yf_default:0., $
         diameter:0., $
         buffer:0., $
         priority:0L, $
         assigned:0L}

if(keyword_set(center)) then begin
    design0.holetype='CENTER'
    design0.diameter=3.175
    design0.buffer=0.94
endif

return, design0

end

