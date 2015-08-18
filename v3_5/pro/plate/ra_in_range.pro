;+
; NAME:
;   ra_in_range
; PURPOSE:
;   For RA back into range
; CALLING SEQUENCE:
;   outra= ra_in_range(inra)
; INPUTS:
;   inra - [N] RA values
; OUTPUTS:
;   outra - [N] output values within [0, 360)
; REVISION HISTORY:
;   15-Apr-2011  Written by MRB, NYU
;-
function ra_in_range, inra

outra= inra

ibad= where(outra lt 0. or outra ge 360., nbad)

while(nbad gt 0) do begin
    ilo= where(outra lt 0., nlo)
    if(nlo gt 0) then $
      outra[ilo]=outra[ilo]+360.
    ihi= where(outra ge 360., nhi)
    if(nhi gt 0) then $
      outra[ihi]=outra[ihi]-360.
    ibad= where(outra lt 0. or outra ge 360., nbad)
endwhile

return, outra

end
