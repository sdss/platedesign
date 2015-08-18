;+
; NAME:
;   check_file_exists
; PURPOSE:
;   When about to open a file, checks to see if the file exists.
;	If not, it logs it with plate_log and exits.
; CALLING SEQUENCE:
;   read_file_test, filename, plateid, current_function
; INPUTS:
;   filename - name of file to check existance of
; OPTIONAL KEYWORDS:
;	plateid - if a plateid is specified, an error is written to plate_log
; REVISION HISTORY:
;   1-Sep-2010  Demitri Muna, NYU
;	15-Jul-2011 Demitri Muna, NYU, Colorized the string output.
;-
;------------------------------------------------------------------------------
PRO check_file_exists, filename, plateid=plateid

	; Error checking
	IF (~FILE_TEST(filename)) THEN BEGIN
		logstring = 'Error! ' + current_function_filename(/calling) + ' attempted to open a file that ' + $
			'was not found (''' + filename + ''')... exiting.'
		splog, color_string(logstring, 'red', 'bold')
		
		IF KEYWORD_SET(plateid) THEN plate_log, plateid, logstring

		STOP

	ENDIF
END
