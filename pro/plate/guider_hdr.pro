;+
; NAME:
;   guider_hdr
; PURPOSE:
;   Return info to add to header to help guider
; CALLING SEQUENCE:
;   hdr = guider_hdr(plateid)
; INPUTS:
;   plateid - which plate
; OUTPUTS:
;   hdr - lines to add to header
; COMMENTS:
;   Currently, 
; REVISION HISTORY:
;   25-Aug-2009  MRB, NYU
;-
function guider_hdr, plateid

designscale, plateid, altscale=altscale, azscale=azscale, pa=pa

hdr= ['# Following keywords meant for guider', $
      'design_platescale_alt '+strtrim(string(altscale, f='(f40.7)'),2), $
      'design_platescale_az '+strtrim(string(azscale, f='(f40.7)'),2), $
      'design_parallactic_angle '+strtrim(string(pa, f='(f40.7)'),2), $
      'guider_coeff_0 0.', $
      'guider_coeff_1 0.', $
      'guider_coeff_2 0.', $
      'guider_coeff_3 0.', $
      'guider_coeff_4 0.', $
      'guider_coeff_5 0.', $
      'guider_coeff_6 0.', $
      'guider_coeff_7 0.', $
      'guider_coeff_8 0.', $
      'guider_coeff_9 0.']

return, hdr

end
;------------------------------------------------------------------------------
