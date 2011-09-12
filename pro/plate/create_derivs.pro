;+
; NAME:
;   create_derivs
; PURPOSE:
;   Wrapper to call plate_guide_derivs for a given plate id
; CALLING SEQUENCE:
;   create_derivs, plateid
; INPUTS:
;   plateid - plate id to generate plateGuideOffsets files for
; COMMENTS:
;   guideon value for BOSS is 5400, APOGEE 16600
;	Both are generated for all plates in case they are needed.
; REVISION HISTORY:
;   12-Sep-2011 Michael Blanton & Demitri Muna, NYU
;
pro create_derivs, plateid

; get number of pointings (np) for given plateid
plug= yanny_readone(plate_dir(plateid)+'/plPlugMapP-'+ $
					string(plateid, f='(i4.4)')+'.par', hdr=hdr)

np=yanny_par(hdr, 'npointings')

for pointing=1L, np do begin
	help, plan, /st
	plate_guide_derivs, plateid, pointing, guideon=16600.
	plate_guide_derivs, plateid, pointing, guideon=5400.
endfor

end
