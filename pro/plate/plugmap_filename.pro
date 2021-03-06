;+
; NAME:
;   plugmap_filename
; PURPOSE:
;   Return file name for plPlugMap style file
; CALLING SEQUENCE:
;   filename= plugmap_filename(plateid= [, type=, pointing=]
; INPUTS:
;   plateid - number of plate
;   type - 'P' or 'H' depending on if a plPlugMapP or plPlugMapH file
;          (default 'P')
; OPTIONAL INPUTS:
;   pointing - pointing name ('A', 'B', etc) (default 'A'
; OUTPUTS:
;   filename - name of file
;-
FUNCTION plugmap_filename, plateID=plateID, type=type, pointing=pointing

	filename = 'plPlugMap'

	; validation
	if strlen(type) gt 1 || size(type, /tname) ne 'STRING' || $
		~(strlowcase(type) eq 'p' or strlowcase(type) eq 'h') then $
		message, color_string('An invalid plugmap type was specified.', 'red', 'bold')

	; Handle the plugmap file type
	if strlowcase(type) EQ 'p' then $
		filename = filename + 'P'
	if strlowcase(type) EQ 'h' then $
		filename = filename + 'H'

	filename = filename + '-'

	; add the plate id
	filename = filename + strtrim(string(plateid),2)

	; Handle the pointing
	if keyword_set(pointing) then begin

		; validatation
		if size(pointing, /type) ne 'STRING' || strlen(pointing) gt 1 then $
			message, color_string('An invalid pointing value was specified.', 'red', 'bold')

		if pointing eq 'A' then begin
		endif

		if strlen(pointing) eq 1 then begin
			if pointing eq 'B' || pointing eq 'C' || pointing eq 'D' || $
			   pointing eq 'E' || pointing eq 'F' then $
			   filename = filename + pointing
		endif
	endif

	return, filename + ".par"
END
