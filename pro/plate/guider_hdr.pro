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

altstr= ''
for i=0L, n_elements(altscale)-1L do $
      altstr=altstr+strtrim(string(altscale[i], f='(f40.7)'),2)+' '

azstr= ''
for i=0L, n_elements(azscale)-1L do $
      azstr=azstr+strtrim(string(azscale[i], f='(f40.7)'),2)+' '

pastr= ''
for i=0L, n_elements(pa)-1L do $
      pastr=pastr+strtrim(string(pa[i], f='(f40.7)'),2)+' '

hdr= ['# Following keywords meant for guider', $
      'design_platescale_alt '+altstr, $
      'design_platescale_az '+azstr, $
      'design_parallactic_angle '+pastr, $
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
