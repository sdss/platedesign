; docformat = 'idl'
;+
; NAME:
;	PLATE_DESIGN
;
; PURPOSE:
;	An IDL object that contains the details of a plate design.
;	It is dynamic as it can contain a variable number of
;	pointings and plate plans (e.g. arrays of "POINTING" and
;	"PLATE_PLAN" objects).
;
; 	Valid drill styles are defined in the init method (Plate_Design::Init).
;
; EXAMPLE:
;
;	design = OBJ_NEW('PLATE_DESIGN')
;	design->SetDesignID, 12345
;
;	plate = OBJ_NEW('PLATE_PLAN')
;	plate->SetPlateID, 8675309
;	
;	pointing = OBJ_NEW('POINTING')
;	pointing->SetRaCen, 25.0
;
;	design->AddPlatePlan, plate
;	design->AddPointing, pointing
;
;	;accessing values
;	print, design->DesignID()
;	print, design->n_PlatePlans()
;
; REVISION HISTORY:
;   2008.11.04 Demitri Muna, NYU 
;-


; ------------------------------------------------------------
FUNCTION Plate_Design::Init

;	example = OBJ_NEW('PLATE_PLAN') ; mgArrayList needs an example of what is to be stored.
	self.pPlateList = OBJ_NEW('MGARRAYLIST', example=obj_new()) ; PTR_NEW(/ALLOCATE_HEAP)
;	OBJ_DESTROY, example
	
	self.pPointingsList = PTR_NEW(/ALLOCATE_HEAP)
	
	; Define valid drill styles.
	; (Case insensitive comparison, but set them as lowercase here).
	self.pValidDrillStyles = PTR_NEW(/ALLOCATE_HEAP)
;	ds = *self.pValidDrillStyles
	*self.pValidDrillStyles = ['sdss'] ; first defines array
	*self.pValidDrillStyles = [*self.pValidDrillStyles, 'marvels'] ; add further styles like this
		
	return, self
END


; ------------------------------------------------------------
; Called upon OBJ_DESTROY
; ------------------------------------------------------------
PRO Plate_Design::Cleanup

	print, 'Plate_Design cleanup called'

	; This might be overkill - it certainly seems messy
	;IF PTR_VALID(self.pPlateList) THEN BEGIN
	;	PTR_FREE, self.pPlateList ; free variable pointed to by pointer
	;	HEAP_FREE, self.pPlateList ; free pointer itself
	;END
	OBJ_DESTROY, pPlateList
	
	IF PTR_VALID(self.pPointingsList) THEN BEGIN
		PTR_FREE, self.pPointingsList
		HEAP_FREE, self.pPointingsList
	END
	IF PTR_VALID(self.pValidDrillStyles) THEN BEGIN
		PTR_FREE, self.pValidDrillStyles
		HEAP_FREE, self.pValidDrillStyles
	END
END

; ------------------------------------------------------------
FUNCTION Plate_Design::PlatePlans, plate_run, count_returned=count_returned
	
	if (~keyword_set(plate_run)) then begin $
		count_returned = self.pPlateList->Count()
		return, self.pPlateList->get(/all) ;*self.pPlateList
	end
	
	; A plate run has been specified - only return plans that
	; are in the given run.

	n_plates = self->N_PlatePlans()
	if (n_plates eq 0) then return, 0

	platelist = OBJ_NEW('MGARRAYLIST', example=obj_new())

	list_iter = OBJ_NEW('mgArrayListIterator', self.pPlateList)
	while (list_iter->hasNext()) do begin
		next_plate = list_iter->next()
		if (strcmp(next_plate->plateRun(), plate_run, /FOLD_CASE)) then $
			platelist->add, next_plate
	end ; end loop over all plate plans
	OBJ_DESTROY, list_iter

	count_returned = platelist->count()
	if (count_returned gt 0) then begin
		platesToReturn = platelist->get(/all)
		OBJ_DESTROY, platelist
		return, platesToReturn
	endif else begin
		OBJ_DESTROY, platelist
		return, 0
	end

	

;	platelist = OBJ_NEW() ; add a dummy value to the array
	
;	for i=0, n_plates-1 do begin
;		if STRCMP((*self.pPlateList)[i]->PlateRun(), plate_run, /FOLD_CASE) then $
;			platelist = [platelist, *self.pPlateList[i]]
;	end

;	if (n_elements(platelist) eq 1) then $
;		return, 0 $ ; only dummy plate found
;	else $
;		return, platelist[1:*] ; return all after removing dummy value

END

; ------------------------------------------------------------
FUNCTION Plate_Design::N_PlatePlans
	return, self.pPlateList->count()
	;if (PTR_VALID(self.pPlateList)) then $
	;	return, n_elements(*self.pPlateList) $
	;else $
	;	return, 0
END

; ------------------------------------------------------------
PRO Plate_Design::AddPlatePlan, newPlatePlan
	self.pPlateList->add, newPlatePlan
	;if (n_elements(*self.pPlateList) eq 0) then $
	;	*self.pPlateList = newPlatePlan $
	;else $
	;	*self.pPlateList = [*self.pPlateList, newPlatePlan]
END

; ------------------------------------------------------------
PRO Plate_Design::ClearPlatePlans
	;if PTR_VALID(self.pPlateList) then begin
	;	PTR_FREE, self.pPlateList ; free variable pointed to by pointer
	;	HEAP_FREE, self.pPlateList ; free pointer itself
	;end
	;self.pPointingsList = PTR_NEW(/ALLOCATE_HEAP)
	self.pPlateList->remove, /all
END

; ------------------------------------------------------------
FUNCTION Plate_Design::Pointings
	return, *self.pPointingsList
END

; ------------------------------------------------------------
PRO Plate_Design::AddPointing, new_pointing
	if (n_elements(*self.pPointingsList) eq 0) then $
		*self.pPointingsList = new_pointing $
	else $
		*self.pPointingsList = [*self.pPointingsList, new_pointing]
END

; ------------------------------------------------------------
PRO Plate_Design::ClearPointings
	IF PTR_VALID(self.pPointingsList) THEN BEGIN
		PTR_FREE, self.pPointingsList
		HEAP_FREE, self.pPointingsList
	END
	self.pPointingsList = PTR_NEW(/ALLOCATE_HEAP)
END

; ------------------------------------------------------------
FUNCTION Plate_Design::DesignID
	return, self.designid
END

; ------------------------------------------------------------
PRO Plate_Design::SetDesignID, id

	;print, 'Plate_Design: setting id'

	; Test data type - should be long int

	;; -------------------
	;; Set up catch routine for data type conversion error.
	;; For details, see:
	;; http://www.dfanning.com/misc_tips/conversion_errors.html
	;; -------------------
	ON_IOError, TYPE_CONVERSION_ERROR; parameter is just a label

;	if (err_status NE false) then begin
;		type_conversion_error:
	id = ulong(id)

	GOTO, DONE ; IDL is pretty
	
TYPE_CONVERSION_ERROR:
	BEGIN
		print, 'PLATELOG ERROR: An invalid design id was specified; "id" ' + $
			   'must be an integer, you specified:'
		print, '                "' + id + '".'
	END
;	CATCH, /cancel
;	return
;	endif
	;; -------------------
DONE: 
	BEGIN
		self.designid = id
		;print, 'Plate_Design: id set'
	END
END

; ------------------------------------------------------------
FUNCTION Plate_Design::LocationID
	return, self.locationid
END

; ------------------------------------------------------------
PRO Plate_Design::SetLocationID, id
	self.locationid = id
END

; ------------------------------------------------------------
FUNCTION Plate_Design::DrillStyle
	return, self.drillStyle
END

; ------------------------------------------------------------
PRO Plate_Design::SetDrillStyle, drillStyle
	
	; Test data type - should be string
	if (datatype(drillStyle) ne 'STR') THEN BEGIN
		print, 'Plate_Design validation error: drillStyle specified must ' + $
			   'be a string data type.'
		stop
	end

	if (where(*self.pValidDrillStyles eq strlowcase(drillStyle)) eq -1) then begin
		print, 'Plate_Design validation error: drillStyle ' + drillStyle + $
			   ' unknown.'
		stop
	end
	
	self.drillStyle = drillStyle
END

; ------------------------------------------------------------
FUNCTION Plate_Design::Comment
	return, self.comment
END

; ------------------------------------------------------------
PRO Plate_Design::SetComment, c
	self.comment = c
END

; ------------------------------------------------------------
FUNCTION Plate_Design::n_Pointings
	IF (PTR_VALID(self.pPointingsList)) THEN $
		return, n_elements(*self.pPointingsList) $
	ELSE $
		return, 0
END

; ------------------------------------------------------------
FUNCTION Plate_Design::XMLString
	xml = '<DESIGN>'
	xml = [xml, '    <DESIGN_ID>' + strcompress(self.designid, /remove) + '<DESIGN_ID>']
	xml = [xml, '    <LOCATION_ID>' + strcompress(self.locationid, /remove) + '</LOCATION_ID>']
	xml = [xml, '    <DRILL_STYLE>' + self.drillStyle + '</DRILL_STYLE>']
	xml = [xml, '    <COMMENT>' + self.comment + '</COMMENT>']

	platelist = self->PlatePlans(count_returned=n_plates)
	for i=0, n_plates-1 do begin
		plate = platelist[i]
		xml = [xml, plate->XMLString()]
	end

	xml = [xml, '</DESIGN>' + string("15b)]
	return, xml
END

; ------------------------------------------------------------
PRO Plate_Design__define
	
	; TO DO - fill in defaults
	
	; Declaration of class instances.
	; Refer to this within this file as self.instance
	; (e.g. self.comment = 'Oh dear, squirrel in telescope')
	void = {PLATE_DESIGN,				   $  ; name of structure
            designid   : 0L,        	   $  ;
            locationid : 0L, 	    	   $  ;
            drillStyle : '', 	    	   $  ;
            comment    : '', 	    	   $  ;
            pPlateList : OBJ_NEW(),        $  ; will be mgArrayList
            pPointingsList : PTR_NEW(),    $  ; pointer to array of POINTINGs

			; below here are local instances defined for convenience
			; and are not part of the data model

            pValidDrillStyles : PTR_NEW() } ; 


END
