;+
; NAME:
;   boss_efficiency_half
; PURPOSE:
;   Pick which intervals in a night are useable, using "half" efficiency model
; CALLING SEQUENCE:
;   useable= boss_efficiency_half(night, intervals)
; INPUTS:
;   night - structure from boss_observing_night()
;   intervals - [Nint] structure from night_intervals()
; OUTPUTS:
;   useable - [Nint] which are useable 
; COMMENTS:
;   This efficiency model gives a 50% chance of the night being good.
;   If the night is good, ALL of the intervals are useable.
;   If not, NONE of the intervals are useable.
; REVISION HISTORY:
;   11-Sep-2007  MRB, NYU
;-
;------------------------------------------------------------------------------
function boss_efficiency_half, night

if(randomu(seed) lt 0.5) then $
  useable=1 $
else $
  useable=0

return, useable

end
