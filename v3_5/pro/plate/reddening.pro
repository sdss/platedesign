;+
; NAME:
;   reddening
; PURPOSE:
;   Return extinction values.
; CALLING SEQUENCE:
;   reddenvec = reddening()
; INPUTS:
;   none
; OPTIONAL INPUTS:
;   survey - specify the survey
; OUTPUTS:
;   extinction vector - [u, g, r, i, z]
; COMMENTS:
;   The purpose of this file is to centralize the extinction
;   values used in various parts of the platedesign pipeline.
;   The optional parameter "survey" can be used to return
;   the values used in SDSS-III.
; REVISION HISTORY:
;   17-June-2014 Demitri Muna, OSU
;-
function reddening, survey=survey

	if (keyword_set(survey)) then begin
		if (survey eq 'sdss3') then return, [5.155, 3.793, 2.751, 2.086, 1.479]
	endif

	; These are the Galactic extinction coefficients in
	; Schlafly & Finkbeiner:
	; Ref: http://arxiv.org/abs/1012.4804
	;
	return, [4.239, 3.303, 2.285, 1.698, 1.263]
end
; -----------------------------------------------------------------------

