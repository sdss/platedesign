;
;
; toString - just a convenience method, this is how I think string() should work.
;
; Demitri Muna, NYU 11 Feb 2009

FUNCTION tostring, s
	return, strtrim(string(s), 2)
END