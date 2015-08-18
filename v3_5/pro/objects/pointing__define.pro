;+
; NAME:
;	POINTING
; PURPOSE:
;
; API:
;        POINTING::Init
;        POINTING::Cleanup
;        POINTING::SetInputFilename, s
;        POINTING::InputFilename
;        POINTING::SetPriority, p
;        POINTING::Priority
;        POINTING::SetHourAngle, ha
;        POINTING::HourAngle
;        POINTING::SetRaCen, newra
;        POINTING::RaCen
;        POINTING::SetDecCen, newdec
;        POINTING::DecCen
;        POINTING::SetRaOffset, newra
;        POINTING::RaOffset
;        POINTING::SetDecOffset, newdec
;        POINTING::DecOffset
;        POINTING::SetComment, c
;        POINTING::Comment
;
; CALLING SEQUENCE:
;
; INPUTS:
;
; OPTIONAL INPUTS:
;
; OPTIONAL OUTPUTS:
;
; OPTIONAL KEYWORDS:
;
; OUTPUTS:
;   None.
; COMMENTS:
; 	
; REVISION HISTORY:
;   2008.10.05 Demitri Muna, NYU 
;-

; ------------------------------------------------------------
FUNCTION POINTING::Init

	; initialisations / default values here

	self.priority   = 1
	self.ra_offset  = 0.0
	self.dec_offset = 0.0
	
	return, self
END

; ------------------------------------------------------------
; Called upon OBJ_DESTROY
; ------------------------------------------------------------
PRO POINTING::Cleanup

	; free any memory allocated here
	print, 'POINTING::Cleanup called.'
END

; ------------------------------------------------------------
PRO POINTING::SetInputFilename, s
	self.inputFilename = s
END

; ------------------------------------------------------------
FUNCTION POINTING::InputFilename
	return, self.inputFilename
END

; ------------------------------------------------------------
PRO POINTING::SetPriority, p
	self.priority = p
END

; ------------------------------------------------------------
FUNCTION POINTING::Priority
	return, self.priority
END

; ------------------------------------------------------------
PRO POINTING::SetHourAngle, ha
	self.hour_angle = ha
END

; ------------------------------------------------------------
FUNCTION POINTING::HourAngle
	return, self.hour_angle
END

; ------------------------------------------------------------
PRO POINTING::SetRaCen, newra
	self.ra_cen = newra
END

; ------------------------------------------------------------
PRO POINTING::SetDecCen, newdec
	self.dec_cen = newdec
END

; ------------------------------------------------------------
PRO Pointing::SetRaDecCenFromInputFile
	
	; Read the ra, dec from the input file.
	; -------------------------------------
	if (n_elements(self.inputFilename)) then begin
		print, 'Error: Attempt to read ra/dec from input file, but ' + $
			   'input file has not been specified. Alternatively, you can ' + $
			   'explicity set the ra/dec for this pointing.'
		stop
	end
	
	; Given the filename, find the file.
	; ----------------------------------
	fullPath = inputFilename ; we want the full path to the file.
	if (file_test(fullPath) eq 0) then begin
	
		; we only have the filename itself - attempt to find the file
		findCommand = 'find ' + getenv('PLATELIST_DIR') + ' -name ' + inputFilename + ' -print'
		spawn, findCommand, result
		
		case (n_elements(result)) of
		1:	begin
				fullPath = result
			end
		0:  begin
				print, 'Error: Could not find input file (' + self.inputFilename + ') ' + $
					  'anywhere in $PLATELIST_DIR.'
				stop
			end
		else: begin ; > 0
				print, 'Error: The input file (' + self.inputFilename + ') ' + $
					   'was found in more than one location. Please explicitly ' + $
					   'set the full file path in relation to $PLATELIST_DIR'
				stop
			  end
		endcase
		
	end

	; fullPath is now a valid file.
	dummy = yanny_readone(fullPath, hdr=hdr) ; read the input file for the header
	header = lines2struct(hdr)
	self->SetRaCen, header.racen
	self->SetDecCen, header.deccen
	
END

; ------------------------------------------------------------
FUNCTION POINTING::RaCen

	if (n_elements(ra_cen) eq 0) then $ ; if undefined, read from input file
		self->SetRaDecCenFromInputFile
		
	return, self.ra_cen
END

; ------------------------------------------------------------
FUNCTION POINTING::DecCen

	if (n_elements(dec_cen) eq 0) then $ ; if undefined, read from input file
		self->SetRaDecCenFromInputFile

	return, self.de_cen
END

; ------------------------------------------------------------
PRO POINTING::SetRaOffset, newra_offset
	self.ra_offset = newra_offset
END

; ------------------------------------------------------------
FUNCTION POINTING::RaOffset
	return, self.ra_offset
END

; ------------------------------------------------------------
PRO POINTING::SetDecOffset, newdec
	self.dec_offset = newdec
END

; ------------------------------------------------------------
FUNCTION POINTING::DecOffset
	return, self.dec_offset
END

; ------------------------------------------------------------
PRO POINTING::SetComment, c
	self.comment = c
END

; ------------------------------------------------------------
FUNCTION POINTING::Comment
	return, self.comment
END

; ------------------------------------------------------------
FUNCTION POINTING::FibersSameAsPlateID, pid
	return, self.duplicateFiberIDsOfPlate
END

; ------------------------------------------------------------
PRO POINTING::SetFibersSameAsPlateID, pid
	self.duplicateFiberIDsOfPlate = pid
END

; ------------------------------------------------------------
FUNCTION POINTING::XMLString
	xml = '<POINTING>to implement</POINTING>'
	
	return, xml
END

; ------------------------------------------------------------
; ------------------------------------------------------------
; ------------------------------------------------------------
; ------------------------------------------------------------


; ------------------------------------------------------------
PRO POINTING__define

	void = {POINTING,		 			  $ ; name of structure
		    inputFilename : '',  		  $ ;
		    priority      : 0,   		  $ ;
		    hour_angle    : 0.0D, 		  $ ;
		    ra_cen        : 0.0D, 		  $ ;
		    dec_cen       : 0.0D, 		  $ ;
		    ra_offset     : 0.0D,		  $ ;
		    dec_offset    : 0.0D,  		  $ ;
		    comment	      : '',			  $ ;
            duplicateFiberIDsOfPlate : 0L $ ;
		    }

END
