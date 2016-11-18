;+
; NAME:
;   lco_scales
; PURPOSE:
;   Return LCO scales
; CALLING SEQUENCE:
;   scales = lco_scales()
; OUTPUTS:
;   scales - [N] structure with scales for given LAMBDA, ZOFFSET, with
;            columns: LAMBDA, ZOFFSET, A0, A1, A2
; COMMENTS:
;   LCO-specific
;   Distortions are gleaned from the Zemax models of Paul Harding,
;    with a backfocal distance of 993 mm and a corrector position set 
;    for 1600 nm focus. These are designed for the centroid position
;    (which is slightly offset from the chief ray). 
;   LAMBDA is in Angstroms
;   ZOFFSET is in microns away from sky side of plate (so - is towards
;    sky, + away)
;   The scales are for the formula:
;     rfocal = a0 * theta + a1 * theta^3 + a2 * theta^5
;   where rfocal is in mm and theta is in deg
; REVISION HISTORY:
;   16-Nov-2016  MRB, NYU
;-
;------------------------------------------------------------------------------
function lco_scales

common com_lco_scales, scales

if(n_tags(scales) eq 0) then begin
    scales0 = {lambda:0.D, zoffset:0.D, a0:0.D, a1:0.D, a2:0.D}
    scales = replicate(scales0, 4)

    scales[0].lambda = 16600.
    scales[0].zoffset = 0.
    scales[0].a0 = 329.342
    scales[0].a1 = 2.109
    scales[0].a2 = 0.033

    scales[1].lambda = 7600.
    scales[1].zoffset = 0.
    scales[1].a0 = 329.297
    scales[1].a1 = 2.168
    scales[1].a2 = 0.021

    scales[2].lambda = 7600.
    scales[2].zoffset = -600.
    scales[2].a0 = 329.274
    scales[2].a1 = 2.167
    scales[2].a2 = 0.012

    scales[3].lambda = 7600.
    scales[3].zoffset = 600.
    scales[3].a0 = 329.321
    scales[3].a1 = 2.168
    scales[3].a2 = 0.031
endif

return, scales

end
