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
;   /trap - return a trap hole
; OUTPUTS:
;   design - structure containing center hole information
; COMMENTS:
;   Assumes center hole is 3.175 mm
; BUGS:
;   Need to review diameters and buffers
;   Need to revisit GUIDE and CENTER diameters and buffers
; REVISION HISTORY:
;   9-May-2008 MRB, NYU (based on DJS's design_append)
;-
function design_blank, center=center, guide=guide, trap=trap

design0={DESIGN_TARGET, $
         holetype:'NA', $
         targettype:'NA', $
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
         diameter:3.32, $
         buffer:0., $
         priority:0L, $
         assigned:0L, $
         conflicted:0L, $
         ranout:0L, $
         sp_param_source:'NA', $
         sp_params:fltarr(4), $
         sp_param_err:fltarr(4), $
         marvels_target1:0L, $
         marvels_target2:0L, $
         boss_target1:0L, $
         boss_target2:0L, $
         segue2_target1:0L, $
         segue2_target2:0L, $
         segueb_target1:0L, $
         segueb_target2:0L, $
         apogee_target1:0L, $
         apogee_target2:0L, $
         run:0L, $
         rerun:' ', $
         camcol:0L, $
         field:0L, $
         id:0L, $
         targetids:'NA' $
        }

if(keyword_set(center)) then begin
    design0.holetype='CENTER'
    design0.diameter=2.*3.175
    design0.buffer=0.94
endif

if(keyword_set(guide)) then begin
    design0.holetype='GUIDE'
    design0.sourcetype='STAR'
    design0.diameter=2.*3.32
    design0.buffer=7.0
endif

if(keyword_set(trap)) then begin
    design0.holetype='TRAP'
    design0.sourcetype='NA'
    design0.diameter=2.*3.32
    design0.buffer=7.0
endif

return, design0

end

