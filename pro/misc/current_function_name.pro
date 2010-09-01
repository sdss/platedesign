;+
; NAME:
;   current_function_name
; PURPOSE:
;   returns the name of the current function
; CALLING SEQUENCE:
;   current_function_filename
; INPUTS:
;   None
; OPTIONAL KEYWORDS:
;   /calling - returns the function calling the current function
; REVISION HISTORY:
;   1-Sep-2010  Demitri Muna, NYU
;-
;------------------------------------------------------------------------------
FUNCTION current_function_filename, calling=calling

	info = scope_traceback(/structure)
	n = N_ELEMENTS(info)
	;print, n
	;for i=0L, n-1 DO BEGIN
	;	print, info[i]
	;ENDFOR
	
	IF keyword_set(calling) THEN BEGIN
		RETURN, FILE_BASENAME(info[n-3].filename)
	ENDIF ELSE BEGIN
		RETURN, FILE_BASENAME(info[n-2].filename)
	ENDELSE

END
