;+
; NAME:
;   create_derivs
; PURPOSE:
;   Wrapper to call plate_guide_derivs for a given plate id
; CALLING SEQUENCE:
;   create_derivs, plateid
; INPUTS:
;   plateid - plate id to generate plateGuideOffsets files for
;   wavelengths - a list of wavelengths to generate plateGuideOffsets-* files for
; COMMENTS:
;   guideon value for BOSS is 5400, APOGEE 16600
;	Both are generated for all plates in case they are needed.
; REVISION HISTORY:
;   12-Sep-2011 Michael Blanton & Demitri Muna, NYU
;   10-Aug-2016 Demitri Muna, Added wavelengths parameter, behaves as before without it
;   14-Dec-2020 Jose Gallego, Added 16000A wavelength
;
pro create_derivs, plateid, wavelengths=wavelengths

; set default wavelengths
if ~KEYWORD_SET(wavelengths) THEN wavelengths = [5400., 16600., 16000.]

; get number of pointings (np) for given plateid
plug= yanny_readone(plate_dir(plateid)+'/plPlugMapP-'+ $
					strtrim(string(plateid),2)+'.par', hdr=hdr)

np=yanny_par(hdr, 'npointings')

for pointing=1L, np do begin
	for w_idx=0, n_elements(wavelengths)-1 do begin
	    plate_guide_derivs, plateid, pointing, guideon=wavelengths[w_idx]
	    ; plate_guide_derivs, plateid, pointing, guideon=16600.
	    ; plate_guide_derivs, plateid, pointing, guideon=5400.
	endfor
endfor

end
