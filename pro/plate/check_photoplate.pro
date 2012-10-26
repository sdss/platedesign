;+
; NAME:
;   check_photoplate 
; PURPOSE:
;   Check existence and validity of a BOSS photoPlate file
; CALLING SEQUENCE:
;   ok= check_photoplate(plate)
; REVISION HISTORY:
;   15-Apr-2011  MRB, NYU
;-
;------------------------------------------------------------------------------
function check_photoplate_file, filename

	compile_opt idl2
	compile_opt logical_predicate

	if(~ file_test(filename)) then begin
		splog, 'File not found: '+filename
		return, 0 
	endif
	
	spawn, /noshell, ['fitsverify', '-q', filename], output
	words= strsplit(output, /extr)
	if(words[1] ne 'OK:') then begin
		splog, 'Not good FITS: '+filename
		return, 0
	endif
	
	hdr= headfits(filename, ext=1)
	if(long(sxpar(hdr, 'NAXIS2')) ne 1000) then begin
		splog, 'Wrong number of rows'
		return, 0
	endif
	
	return, 1

end
;
function check_photoplate, plate

	compile_opt idl2
	compile_opt logical_predicate

	pstr = strtrim(string(f='(i4.4)',plate),2)
	
	pdir = getenv('PHOTOPLATE_DIR')+'/'+pstr
	
	ok = check_photoplate_file(pdir+'/photoPlate-'+pstr+'.fits')
	if (~ ok) then begin
		splog, 'photoPlate-'+pstr+'.fits not OK!'
		return, 0
	endif
	 
	ok = check_photoplate_file(pdir+'/photoPosPlate-'+pstr+'.fits')
	if (~ ok) then begin
		splog, 'photoPosPlate-'+pstr+'.fits not OK!'
		return, 0
	endif
	
	ok = check_photoplate_file(pdir+'/photoMatchPlate-'+pstr+'.fits')
	if (~ ok) then begin
		splog, 'photoMatchPlate-'+pstr+'.fits not OK!'
		return, 0
	endif
	
	return, 1

end
