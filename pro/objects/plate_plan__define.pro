; docformat = 'idl'
;+
; NAME:
;	PLATE_PLAN
;
; PURPOSE:
;	A plate plan as an IDL object.
;
; PROCEDURE:
;	Use this object to encapsulate as much logic relating to the
;   plate plan as possible.
;
; EXAMPLE:
;	plate = OBJ_NEW('PLATE_PLAN')
;	plate->SetPlateID(12345)
;	plate->SetTemp(10.0)
; 	
; REVISION HISTORY:
;   2008.11.07 Demitri Muna, NYU 
;-

; +
; PURPOSE:
;	object initialisations / defaults
; -
FUNCTION PLATE_PLAN::Init

	; initialisations here

	return, self
END

; +
; PURPOSE:
;	Called upon OBJ_DESTROY (overidden from superclass)
; -
PRO PLATE_PLAN::Cleanup

	; free any memory allocated here

END

; +
; Set method for plate id
; -
PRO PLATE_PLAN::SetPlateID, plate_id
	self.plateid = plate_id
END

; ------------------------------------------------------------
; +
; Returns the plate id
; -
FUNCTION PLATE_PLAN::PlateID
	return, self.plateid
END

; ------------------------------------------------------------
; +
; Set method for the temperature
; -
PRO PLATE_PLAN::SetTemp, temp
	self.temp = temp
END

; ------------------------------------------------------------
; +
; returns the temperature
; -
FUNCTION PLATE_PLAN::Temp
	return, self.temp
END

; ------------------------------------------------------------
; +
; set method for the epoch
; -
PRO PLATE_PLAN::SetEpoch, epoch
	self.epoch = epoch
END

; ------------------------------------------------------------
; +
; returns the epoch
; -
FUNCTION PLATE_PLAN::Epoch
	return, self.epoch
END

; ------------------------------------------------------------
; +
; set method for the rerun
; -
PRO PLATE_PLAN::SetRerun, rerun
	self.rerun = rerun
END

; ------------------------------------------------------------
; +
; returns the rerun
; -
FUNCTION PLATE_PLAN::Rerun
	return, self.rerun
END

; ------------------------------------------------------------
; +
; Set method for the plate run. Prior to Jan 2009, the format
; of the palte run was: 'mmmyyn' (e.g. 'oct08a') . Starting Jan 2009
; the format is 'yyyy.mm.n', (e.g. '2009.01.b') to allow for
; more natural sorting.
; -
PRO PLATE_PLAN::SetPlateRun, plate_run
	self.platerun = plate_run
END

; ------------------------------------------------------------
; +
; Returns the plate run
; -
FUNCTION PLATE_PLAN::PlateRun
	return, self.platerun
END

; ------------------------------------------------------------
; +
; Set method for the plate name
; -
PRO PLATE_PLAN::SetName, plate_name
	self.name = plate_name
END

; ------------------------------------------------------------
; +
; returns the plate name
; -
FUNCTION PLATE_PLAN::Name
	return, self.name
END

; ------------------------------------------------------------
; +
; set method for any comments
; -
PRO PLATE_PLAN::SetComment, comment
	self.comment = comment
END

; ------------------------------------------------------------
; +
; returns the plate comment field
; -
FUNCTION PLATE_PLAN::Comment
	return, self.comment
END

; ------------------------------------------------------------
; +
; 
; -
PRO PLATE_PLAN__define

	void = {PLATE_PLAN,		$ ; name of structure
		   plateid	: 0L,	$ ;
		   temp		: 0.0D,	$ ;
		   epoch	: 0.0D,	$ ;
		   rerun	: '',	$ ;
		   platerun	: '',	$ ;
		   name		: '',	$ ;
		   comment	: ''	$ ;
		   }

END
