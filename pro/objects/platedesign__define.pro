; docformat = 'idl'
;+
; NAME:
;	PLATEDESIGN
;
; PURPOSE:
;	An IDL object that contains the details of a plate design.
;	It is dynamic as it can contain a variable number of
;	pointings and plate plans (e.g. arrays of "POINTING" and
;	"PLATE_PLAN" objects).
;
; 	Valid drill styles are defined in the init method (PlateDesign::Init).
;
; EXAMPLE:
;
;	design = OBJ_NEW('PLATEDESIGN')
;	design->SetDesignID(12345)
;
;	plate = OBJ_NEW('PLATE_PLAN')
;	plate->SetPlateID(8675309)
;	
;	pointing = OBJ_NEW('POINTING')
;	pointing->SetRaCen(25.0)
;
;	design->AddPlatePlan(plate)
;	design->AddPointing(pointing)
;
; REVISION HISTORY:
;   2008.11.04 Demitri Muna, NYU 
;-


; ------------------------------------------------------------
FUNCTION PlateDesign::Init

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
PRO PlateDesign::Cleanup

	print, 'PlateDesign cleanup called'

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
FUNCTION PlateDesign::PlatePlans, plate_run, count_returned=count_returned
	
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
FUNCTION PlateDesign::N_PlatePlans
	return, self.pPlateList->count()
	;if (PTR_VALID(self.pPlateList)) then $
	;	return, n_elements(*self.pPlateList) $
	;else $
	;	return, 0
END

; ------------------------------------------------------------
PRO PlateDesign::AddPlatePlan, newPlatePlan
	self.pPlateList->add, newPlatePlan
	;if (n_elements(*self.pPlateList) eq 0) then $
	;	*self.pPlateList = newPlatePlan $
	;else $
	;	*self.pPlateList = [*self.pPlateList, newPlatePlan]
END

; ------------------------------------------------------------
PRO PlateDesign::ClearPlatePlans
	;if PTR_VALID(self.pPlateList) then begin
	;	PTR_FREE, self.pPlateList ; free variable pointed to by pointer
	;	HEAP_FREE, self.pPlateList ; free pointer itself
	;end
	;self.pPointingsList = PTR_NEW(/ALLOCATE_HEAP)
	self.pPlateList->remove, /all
END

; ------------------------------------------------------------
FUNCTION PlateDesign::Pointings
	return, *self.pPointingsList
END

; ------------------------------------------------------------
PRO PlateDesign::AddPointing, new_pointing
	if (n_elements(*self.pPointingsList) eq 0) then $
		*self.pPointingsList = new_pointing $
	else $
		*self.pPointingsList = [*self.pPointingsList, new_pointing]
END

; ------------------------------------------------------------
PRO PlateDesign::ClearPointings
	IF PTR_VALID(self.pPointingsList) THEN BEGIN
		PTR_FREE, self.pPointingsList
		HEAP_FREE, self.pPointingsList
	END
	self.pPointingsList = PTR_NEW(/ALLOCATE_HEAP)
END

; ------------------------------------------------------------
FUNCTION PlateDesign::DesignID
	return, self.designid
END

; ------------------------------------------------------------
PRO PlateDesign::SetDesignID, id

	print, 'PlateDesign: setting id'

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
		print, 'PlateDesign: id set'
	END
END

; ------------------------------------------------------------
FUNCTION PlateDesign::LocationID
	return, self.locationid
END

; ------------------------------------------------------------
PRO PlateDesign::SetLocationID, id
	self.locationid = id
END

; ------------------------------------------------------------
FUNCTION PlateDesign::DrillStyle
	return, self.drillStyle
END

; ------------------------------------------------------------
PRO PlateDesign::SetDrillStyle, drillStyle
	
	; Test data type - should be string
	if (datatype(drillStyle) ne 'STR') THEN BEGIN
		print, 'PlateDesign validation error: drillStyle specified must ' + $
			   'be a string data type.'
		stop
	end

	if (where(*self.pValidDrillStyles eq strlowcase(drillStyle)) eq -1) then begin
		print, 'PlateDesign validation error: drillStyle ' + drillStyle + $
			   ' unknown.'
		stop
	end
	
	self.drillStyle = drillStyle
END

; ------------------------------------------------------------
FUNCTION PlateDesign::Comment
	return, self.comment
END

; ------------------------------------------------------------
PRO PlateDesign::SetComment, c
	self.comment = c
END

; ------------------------------------------------------------
FUNCTION PlateDesign::n_Pointings
	IF (PTR_VALID(self.pPointingsList)) THEN $
		return, n_elements(*self.pPointingsList) $
	ELSE $
		return, 0
END


; ------------------------------------------------------------
PRO platedesign__define
	
	; TO DO - fill in defaults
	
	; Declaration of class instances.
	; Refer to this within this file as self.instance
	; (e.g. self.comment = 'Oh dear, squirrel in telescope')
	void = {PLATEDESIGN,				$  ; name of structure
            designid   : 0L,        	$  ;
            locationid : 0L, 	    	$  ;
            drillStyle : '', 	    	$  ;
            comment    : '', 	    	$  ;
            pPlateList : OBJ_NEW(),     $  ; will be mgArrayList
            pPointingsList : PTR_NEW(), $  ; pointer to array of POINTINGs

			; below here are local instances defined for convenience
			; and are not part of the data model

            pValidDrillStyles : PTR_NEW() } ; 


END