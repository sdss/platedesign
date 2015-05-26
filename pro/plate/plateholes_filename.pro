;+
; NAME:
;   plateholes_filename
; PURPOSE:
;   Return file name for plateHoles style file
; CALLING SEQUENCE:
;   filename= plateholes_filename(plateid= [, /sorted])
; INPUTS:
;   plateid - number of plate
; OPTIONAL KEYWORDS:
;   /sorted - returns plateHolesSorted instead of plateHoles
;   /swap - returns plateHolesSorted-swap instead of plateHoles
; OUTPUTS:
;   filename - name of file
;-
FUNCTION plateholes_filename, plateID=plateID, sorted=sorted, swap=swap

	filename = 'plateHoles'

  if(keyword_set(sorted)) then $
    filename = filename + 'Sorted'

	filename = filename + '-' + strtrim(string(plateid, f='(i6.6)'),2)

  if(keyword_set(swap)) then $
    filename= filename + '-swap'

	return, filename + ".par"
END
