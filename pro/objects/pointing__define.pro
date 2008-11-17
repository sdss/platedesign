;+
; NAME:
;	POINTING
; PURPOSE:
;
; API:
;        POINTING::Init
;        POINTING::Cleanup
;        POINTING::SetFilename, s
;        POINTING::Filename
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

	; initialisations here

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
PRO POINTING::SetFilename, s
	self.filename = s
END

; ------------------------------------------------------------
FUNCTION POINTING::Filename
	return, self.filename
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
FUNCTION POINTING::RaCen
	return, self.ra_cen
END

; ------------------------------------------------------------
PRO POINTING::SetDecCen, newdec
	self.dec_cen = newdec
END

; ------------------------------------------------------------
FUNCTION POINTING::DecCen
	return, self.de_cen
END

; ------------------------------------------------------------
PRO POINTING::SetRaOffset, newra
	self.ra_offset = newra
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
; ------------------------------------------------------------
; ------------------------------------------------------------
; ------------------------------------------------------------


; ------------------------------------------------------------
PRO POINTING__define

	void = {POINTING,		  $ ; name of structure
		    filename   : '',  $ ;
		    priority   : 0,   $ ;
		    hour_angle : 0.0D,  $ ;
		    ra_cen     : 0.0D,  $ ;
		    dec_cen    : 0.0D,  $ ;
		    ra_offset  : 0.0D,  $ ;
		    dec_offset : 0.0D,  $ ;
		    comment	   : ''  $
		    }

END
