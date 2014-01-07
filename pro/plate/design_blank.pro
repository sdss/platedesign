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
         block:-9999L, $
         iguide:-9999L, $
         xf_default:0., $
         yf_default:0., $
         lambda_eff:5400., $
         zoffset:0., $
         bluefiber:0, $
         chunk:0L, $
         ifinal:-1L, $
         origfile:' ', $
         fileindx:-1L, $
         diameter:1000., $
         buffer:0., $
         priority:0L, $
         assigned:0L, $
         conflicted:0L, $
         ranout:0L, $
         outside:0L, $
         mangaid:' ', $
         ifudesign:0L, $
         ifudesignsize:0L, $
         bundle_size:1L, $
         fiber_size:2., $
         tmass_j:-9999., $
         tmass_h:-9999., $
         tmass_k:-9999., $
         gsc_vmag:-9999., $
         tyc_bmag:-9999., $
         tyc_vmag:-9999., $
         mfd_mag:fltarr(6), $
         usnob_mag:fltarr(5), $
         sp_param_source:'NA', $
         sp_params:fltarr(4), $
         sp_param_err:fltarr(4), $
         marvels_target1:0L, $
         marvels_target2:0L, $
         boss_target1:long64(0), $
         boss_target2:long64(0), $
         ancillary_target1:long64(0), $
         ancillary_target2:long64(0), $
         segue2_target1:0L, $
         segue2_target2:0L, $
         segueb_target1:0L, $
         segueb_target2:0L, $
         apogee_target1:0L, $
         apogee_target2:0L, $
         manga_target1:0L, $
         manga_target2:0L, $
         eboss_target0:long64(0), $
         run:0L, $
         rerun:' ', $
         camcol:0L, $
         field:0L, $
         id:0L, $
         psfflux:fltarr(5), $
         psfflux_ivar:fltarr(5), $
         fiberflux:fltarr(5), $
         fiberflux_ivar:fltarr(5), $
         fiber2flux:fltarr(5), $
         fiber2flux_ivar:fltarr(5), $
         psfmag:fltarr(5), $
         fibermag:fltarr(5), $
         fiber2mag:fltarr(5), $
         mag:fltarr(5), $
         epoch:default_epoch(), $
         pmra:0., $
         pmdec:0., $
         targetids:'NA' $
        }

if(keyword_set(center)) then begin
    design0.holetype='CENTER'
    design0.diameter=4.87
    design0.buffer=1.1
endif

if(keyword_set(guide)) then begin
    design0.holetype='GUIDE'
    design0.sourcetype='STAR'
    design0.diameter=3.175
    design0.buffer=3.75
    design0.lambda_eff=5400.
endif

if(keyword_set(trap)) then begin
    design0.holetype='TRAP'
    design0.sourcetype='NA'
    design0.diameter=4.87
    design0.buffer=2.
endif

return, design0

end

