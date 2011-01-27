;+
; NAME:
;   color_string
; PURPOSE:
;   create a string that will print in color on the console
; CALLING SEQUENCE:
;   new_string = color_string, input_string
; INPUTS:
;   input_string - the string to color
; OPTIONAL INPUTS:
;	color - the color to display the text in
;			Can specify color as a string, one of:
;				[black, red, green, yellow, blue, magenta, cyan, grey, normal]
;			or as an integer, serving as an index of the above list.
;			ANY integer value is accepted; if out of range, the mod is calculated.
;			Default value: magenta (has to be a color, otherwise, what's the point?)
;	attribute - display attribute, one of [normal, bold, underline, blink, inverse]
;			Accepts a string value from the list above, or else the
;			equivalent terminal attribute code (but the string's probably more friendly).
;			Please think twice before using blink.
; OUTPUTS:
;   string with escape characters to display as color
; COMMENTS:
;	The color codes are detailed in the code below and are largely shared
;	with the standard bash shell color values.
;	This should work fairly well across vt100 emulators and xterm, but
;	maybe not 100% (e.g. xterm doesn't support blink. Don't use blink.) 
;	Useful reference of bash shell color codes:
;		http://networking.ringofsaturn.com/Unix/Bash-prompts.php
;
;	To see a test of all colors on your screen, set the color parameter to 'test':
;		print, color_string('any string, 'test')
;
;	Future enhancement: implement foreground/background colors.
;
; REVISION HISTORY:
;   2011.01.03 Demitri Muna
;-

function color_string, input_string, color, attribute

	COMPILE_OPT idl2
	COMPILE_OPT logical_predicate
	
	; From bash:
	;
	;  \e[	ANSI escape sequence indicator
	;  0;	use the default attribute (i.e., no bold, underline, etc.)
	;  34	use blue for the foreground color
	;  [m	end of ANSI escape indicator, all attributes off
	
	; The IDL equivalent
	;
	;  string(27b)	escape character
	;  [0;			attribute (0 = normal, 1 = bold, 4 = underline)
	;  34m			blue color
	;  [m			end of escape sequence

	; For example, you could change the IDL prompt to be in color (place in IDL startup file):
	; !PROMPT=string(27b)+'[1;34mIDL> '+string(27b)+'[m'

	esc = string(27b)

	; define color constants
	colors = ['black', 'red', 'green', 'yellow', 'blue', 'magenta', 'cyan', 'grey', 'normal']
	color_values = ['30m', '31m', '32m', '33m', '34m', '35m', '36m', '37m', '39m']

	; define attribute constants
	normal_code = '[0;'
	bold_code = '[1;'
	underline_code = '[4;'
	blink_code = '[5;'
	inverse_code = '[7;'	

	; set default values - only overridden if sensible values found.
	color_code = '35m' 	; magenta color
	attribute_code = normal_code

	; TEST
	if (strlowcase(color) eq 'test') then begin
		
		print, 'Color test:'
		print, ''
		for i=0, n_elements(colors)-1 do begin
			print, '    ' + esc + normal_code + color_values[i] + colors[i] + esc + '[m'
		end
		print, '    ---'
		for i=0, n_elements(colors)-1 do begin
			print, '    ' + esc + bold_code + color_values[i] + colors[i] + ' bold' + esc + '[m'
		end

		print, ''
		print, 'If some colors are wrong, they may be overridden by your terminal program''s settings.'
		print, ''
	
	endif

	; Color/attribute can either be a string value or else a number.
	; If the color number is out of range, the values will wrap around.

	; determine type of color input
	if (size(color, /type) eq 2 or size(color, /type) eq 3) then begin

		; color parameter is either an int or long int

		idx = abs(color mod n_elements(color_values))
		color_code = color_values[idx]
	
	endif else if (size(color, /type) eq 7) then begin
		
		; color parameter is a string

		idx = where(colors eq strlowcase(color), count)
		if (count gt 0) then $
			color_code = color_values[idx]
		
	endif
	
	; determine type of attribute input
	if (size(attribute, /type) eq 7) then begin
	
		; attribute parameter is a string
		case strlowcase(attribute) of
			'normal' 	: attribute_code = normal_code
			'bold' 		: attribute_code = bold_code
			'underline' : attribute_code = underline_code
			'blink' 	: attribute_code = blink_code
			'inverse' 	: attribute_code = inverse_code
		endcase
		
	endif else if (size(attribute, /type) eq 2 or size(attribute, /type) eq 3) then begin

		; color parameter is either an int or long int
		case attribute of
			0 : attribute_code = normal_code
			1 : attribute_code = bold_code
			4 : attribute_code = underline_code
			5 : attribute_code = blink_code
			7 : attribute_code = inverse_code
		endcase
		
	endif
	
	output_string = esc + attribute_code + color_code + input_string + esc + '[m'

	return, output_string
end