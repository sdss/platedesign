;+
; NAME:
;   plplugmap_blank
; PURPOSE:
;   Initialize a plPlugMapP structure
; CALLING SEQUENCE:
;   pl= plplugmap_blank(enums=)
; REVISION HISTORY:
;   9-Jun-2008 MRB, NYU (based on DJS's design_append)
;   1-Sep-2010 Demitri Muna, NYU, Adding file test before opening files.
;-
function plplugmap_blank, enums=enums, structs=structs

	filename = getenv('PLATEDESIGN_DIR') + '/data/sdss/plPlugMapP-blank.par'
	check_file_exists, filename
	pl= yanny_readone(filename, enums=enums, structs=structs)
	
	return, pl

end

