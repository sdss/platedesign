;+
; NAME:
;   plate_definition
; PURPOSE:
;   Return the contents of the definition file for a given plate id or definition number.
; CALLING SEQUENCE:
;   definition_struct = plate_definition(plateid=1234)
;      OR
;   definition_struct = plate_definition(designid=1234)
; INPUTS:
;   Only one input  should be specified
;   plateID - the plate ID
;   designID - the design/definition ID
;   plate_obj - a hash representing the plate - must contain 'definition' or 'designid'
; OPTIONAL KEYWORDS:
;   /filename - return just the filepath+filename
; OUTPUTS:
;   The contents of the definition file as read by yanny_readone()
; REVISION HISTORY:
;   28 January 2014 Demitri Muna, original version
;-
;------------------------------------------------------------------------
function plate_definition, plateid=plateid, designid=designid, plate_obj=plate_obj, filename=filename

COMPILE_OPT idl2
COMPILE_OPT logical_predicate

platelist_dir = getenv('PLATELIST_DIR')

if keyword_set(plateid) then begin
	; get the definition id from the plate id
	platePlans_filename = platelist_dir+'/platePlans.par'
	check_file_exists, platePlans_filename, plateid=plateid
	plans = yanny_readone(platePlans_filename)
	idx = where(plans.plateid eq plateid, nplate)
	if (nplate gt 1) then begin
	    message, color_string('Error: More than one entry for plateid (' + string(plateid) + $
	    					  ') found in ' + platePlans_filename + '.', 'red', 'bold')
	endif else if (nplate eq 0) then begin
		 message, color_string('Error: The plate id given (' + string(plateid) + $
		 		  			   ') was not found in ' + platePlans_filename + '.', $
							   'red', 'bold')
	endif else begin
		 definitionid = plans[idx].designid
	endelse

endif else if keyword_set(designid) then begin
	definitionid = designid

endif else if keyword_set(plate_obj) then begin
	; get the information needed from the plate object
	if plate_obj->iscontained('definition') then begin
	    if keyword_set(filename) then begin
	    	definitionid = plate_obj->get('designid')
	    endif else $
	        return, plate_obj->get('definition')
	endif else if plate_obj->iscontained('designid') then begin
	    definitionid = plate_obj->get('designid')
	endif else begin
	    message, color_string('Could not determine definition id from specified "plate_obj".', $
							  'red', 'bold')
	endelse
endif

;; have definition id at this point
;; 
;; Should be at (with did = designid)
;;   $PLATELIST_DIR/definitions/[did/100]00/plateDefinition-[did].par
;; as in 
;;   $PLATELIST_DIR/definitions/001000/plateDefinition-001045.par

definition_dir = platelist_dir + '/definitions/' + $
				 string(f='(i4.4)', (definitionid/100L))+'XX'
definition_filename = definition_dir + '/' + 'plateDefinition-' + $
				 string(f='(i6.6)', definitionid)+'.par'

if keyword_set(filename) then $
	return, definition_filename

check_file_exists, definition_filename
dummy_value = yanny_readone(definition_filename, hdr=hdr)
if (~keyword_set(hdr)) then begin
    message, color_string('Error: plateDefinition file "' + definition_filename + '" does not appear to be valid.' ,$
						  'red', 'bold')
endif
return, lines2struct(hdr)

end

