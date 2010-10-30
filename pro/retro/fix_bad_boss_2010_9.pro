;+
; NAME:
;   fix_bad_boss_2010_9
; PURPOSE:
;   Fix some bad BOSS overlays from 2010.9.c.boss
; CALLING SEQUENCE:
;   fix_bad_boss_2010_9
; COMMENTS:
;   Retrofits the overlays from plates in:
;    2010.09.c.boss
;   Only plates: 4284 4295 4306 4308 4320 4323
;   These had bundles crossing, due to the sky
;   fiber constraint messing up the code.  This 
;   version relaxes the constraint and overwrites
;   the overlay files. (Other plates had bundles
;   crossing but have already been marked).
;   This addresses Ticket #510.
; REVISION HISTORY:
;   28-Oct-2010  MRB, NYU
;-
;------------------------------------------------------------------------------
pro fix_bad_boss_2010_9

plates= [4284, 4295, 4306, 4308, 4320, 4323]

for i=0L, n_elements(plates)-1L do $
   platelines_boss, plates[i], /rearr, /sorty

return
end
