;+
; NAME:
;   minmaxinblock
; PURPOSE:
;   Pull min and max in block #s from default and definition 
; CALLING SEQUENCE:
;   minmaxinblock, default, definition, instrument, type, mininblock=,
;      maxinblock=
; INPUTS:
;   default, definition - default and definition structures for plate
;   instrument - instrument name (typically 'BOSS' or 'MARVELS' or
;                'APOGEE')
;   type - type of target (typically 'sky' or 'std')
; OUTPUTS:
;   maxinblock - max value returned
;   mininblock - min value returned
; REVISION HISTORY:
;  30-Sep-2009, MRB, NYU
;-
;------------------------------------------------------------------------------
pro minmaxinblock, default, definition, instrument, type, $
                   mininblock=mininblock, maxinblock=maxinblock

itagminstd=tag_indx(definition, 'min'+type+'inblock'+instrument)
if(itagminstd eq -1) then begin
    itagminstd=tag_indx(default, 'min'+type+'inblock'+instrument)
    if(itagminstd eq -1) then $
      mininblock=0L $
    else $
      mininblock=long(default.(itagminstd))
endif else begin
    mininblock=long(definition.(itagminstd))
endelse

itagmaxstd=tag_indx(definition, 'max'+type+'inblock'+instrument)
if(itagmaxstd eq -1) then begin
    itagmaxstd=tag_indx(default, 'max'+type+'inblock'+instrument)
    if(itagmaxstd eq -1) then $
      maxinblock=0L $
    else $
      maxinblock=long(default.(itagmaxstd))
endif else begin
    maxinblock=long(definition.(itagmaxstd))
endelse

return
end
