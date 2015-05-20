
FUNCTION plugmap_filename, plateID=plateID, type=type, pointing=pointing

	filename = 'plPlugMap'

	; validation
	if strlen(type) gt 1 || typename(type) ne 'STRING' || $
		~(strlowcase(type) eq 'p' or strlowcase(type) eq 'h') then $
		message, color_string('An invalid plugmap type was specified.', 'red', 'bold')

	; Handle the plugmap file type
	if strlowcase(type) EQ 'p' then $
		filename = filename + 'P'
	if strlowcase(type) EQ 'h' then $
		filename = filename + 'H'

	filename = filename + '-'

	; add the plate id
	filename = filename + str(plateid)

	; Handle the pointing
	if keyword_set(pointing) then begin

		; validatation
		if typename(pointing) ne 'STRING' || strlen(pointing) gt 1 then $
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
