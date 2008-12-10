; docformat = 'idl'
;+
; NAME:
;	XML2DESIGN_LIST
; 
; PURPOSE:
;	Use this object to read in a plate design file that is in the
;	XML format. Use the methods defined below to extract the
;	desired data from this object. See examples below.
;
; EXAMPLE:
;	
;	xmlObj = OBJ_NEW('xml2design_list')  ; create an instance of this object
;	filename = 'path/to/xml_datafile.xml'
;	xmlObj->ParseFile, filename          ; reads the xml file into IDL objects
;	designs = xmlObj->GetDesignList()
;
;	id = designs[0]->designid() ; get the id of the first design
;	plates = designs[0]->plateplans() ; get the plates of this design
;
;	plate_id = plates[0]->plateid()  ; get the plate id of the first plate
;	plate_id = (designs[0]->plateplans())[0]->plateid ; same as above
;
; REVISION HISTORY:
;	
;	2008.10.24 Demitri Muna, NYU
;-

;; The class definition must be the last thing declared in the
;; file, but is probably best read first (by a human).

;; ---------------------------------------------------------
;; Init method
;; ---------------------------------------------------------
FUNCTION xml2design_list::Init
	compile_opt idl2
	compile_opt logical_predicate

    print, 'xml2design_list init called'
    ;; Initialize local values here
    ;self.pDesignList = PTR_NEW(/ALLOCATE_HEAP)

    ;;self.designNum = 0
    RETURN, self->IDLffxmlsax::Init() ;; call super's init method
END

;; ---------------------------------------------------------
PRO xml2design_list::FreeAllPointers
	compile_opt idl2
	compile_opt logical_predicate

	IF (PTR_VALID(self.pDesignList)) THEN BEGIN
		
		n_designs = n_elements(*self.pDesignList)
		if (n_designs gt 0) then begin
		
            ; loop over DESIGNs
            for design_idx=0L, n_designs-1 do begin

                currentDesign = (*self.pDesignList)[design_idx]

;                PTR_FREE, currentDesign.pPlateList
                PTR_FREE, currentDesign.pPointingsList
                
			endfor ; end loop over designs
		
		endif ; end test for DESIGNs array
		
		PTR_FREE, self.pDesignList
		
	ENDIF ; end test for DESIGN_LIST
	
	
;    IF (PTR_VALID(self.pDesignList)) THEN BEGIN
;
;        n_designs = n_elements(*self.pDesignList)
;        if (n_designs gt 0) then begin
;
;            ; loop over DESIGNs
;            for design_idx=0L, n_designs-1 do begin
;
;                currentDesign = (*self.pDesignList)[design_idx]
;                n_plates = n_elements(*currentDesign.pPlateList)
;                
;               	if (n_plates gt 0) then begin ; delete all plates
;
;                    ; loop over PLATE_PLANs
;                    for plate_idx=0L, n_plates-1 do begin
;
;                        currentPlate = (*currentDesign.pPlateList)[plate_idx]
;                        ; free POINTINGs array
;                        PTR_FREE, currentPlate.pPointingsList
;
;                    endfor ; end loop over PLATE_PLANs
;    
;                    PTR_FREE, currentDesign.pPlateList
;
;                endif ; end test for PLATE_PLAN array
;
;            endfor ; end loop over DESIGNs
;
;        endif ; end test for DESIGNs array
;
;        PTR_FREE, self.pDesignList
;    ENDIF ; end test for DESIGN_LIST

END

;; ---------------------------------------------------------
;; Cleanup method - called when this object is destroyed.
;; ---------------------------------------------------------
PRO xml2design_list::Cleanup
	compile_opt idl2
	compile_opt logical_predicate

;    print, 'xml2design_list called'
    ;; release pointer
;    IF (PTR_VALID(self.pDesignList)) THEN PTR_FREE, self.pDesignList

    self->FreeAllPointers
END

;; ---------------------------------------------------------
; StartDocument method
; Called when parsing of the document data begins.
;; ---------------------------------------------------------
PRO xml2design_list::StartDocument
	compile_opt idl2
	compile_opt logical_predicate

   ; Can use this opportunity to do some document initialisations.

   ;; If the array pointed to by pDesignList contains data, reinitialize it.
   ;; This may seem redundant with ::Init, but may happen if the object
   ;; is reused.
    
    self->FreeAllPointers
    self.pDesignList = PTR_NEW(/ALLOCATE_HEAP)

    ;void = TEMPORARY(*self.pDesignList) ;; Frees the memory the pointer is
                                         ; pointing to. Obviously. What
                                         ; else could "temporary" mean??

    self.current = {CURRENT} ; create new structure instance
END

;; ---------------------------------------------------------
; Characters method
; -----------------
; The Characters method is called when the parser
; encounters character data inside an element. As it parses the
; character data in an element, the parser will read characters
; until it reaches the end of the text section. Here, we simply
; add the current characters to the charBuffer field of the
; object's instance data structure. 
;; ---------------------------------------------------------
PRO xml2design_list::characters, data
    self.charBuffer = self.charBuffer + data
END

;; ---------------------------------------------------------
; StartElement method
; Called when the parser encounters the start of an <> element.
;; ---------------------------------------------------------
PRO xml2design_list::StartElement, URI, local, strName, attrName, attrValue
	compile_opt idl2
	compile_opt logical_predicate
    
    ;strName = strlowcase(strName) ; XML is case sensitive!
;    print, 'Keyword found: ' + strName

    case strName OF
        'DESIGN_LIST' : ; root object, do nothing

        ; ====== DESIGN =====

        ; create a new design object and save a reference to it
        'DESIGN'         : BEGIN
			self.current.design = OBJ_NEW('PLATE_DESIGN')
;           self.current.design = {DESIGN}
;           self.current.design.pPlateList = PTR_NEW(/ALLOCATE_HEAP)
;           self.current.design.pPointingsList = PTR_NEW(/ALLOCATE_HEAP)
        END
        'DESIGN_ID'      : self.charBuffer = '' ; reset the character buffer for new data
        'DESIGN_COMMENT' : self.charBuffer = ''
        'LOCATION_ID'    : self.charBuffer = ''
        'DRILL_STYLE'    : self.charBuffer = ''

        ; ====== PLATE_PLAN =====

		'PLATE_PLAN'    :self.current.platePlan = OBJ_NEW('PLATE_PLAN')
;       'PLATE_PLAN'   : self.current.platePlan = {PLATE_PLAN}

        'PLATEID'     	: self.charBuffer = ''
        'TEMP'        	: self.charBuffer = ''
        'EPOCH'       	: self.charBuffer = ''
        'RERUN'       	: self.charBuffer = ''
        'PLATE_RUN'     : self.charBuffer = ''
        'PLATE_NAME'    : self.charBuffer = ''
        'PLATE_COMMENT' : self.charBuffer = ''

        ; ====== POINTING =====

        'POINTING'          : self.current.pointing = OBJ_NEW('POINTING')
;       'POINTING'          : self.current.pointing = {POINTING}
        'FILENAME'          : self.charBuffer = ''
        'POINTING_PRIORITY' : self.charBuffer = ''
        'HOUR_ANGLE'        : self.charBuffer = ''
        'RA_CEN'     		: self.charBuffer = ''
        'DEC_CEN'     		: self.charBuffer = ''
        'RA_OFFSET'			: self.charBuffer = ''
        'DEC_OFFSET'		: self.charBuffer = ''
        'POINTING_COMMENT'  : self.charBuffer = ''

    endcase
END

; -------------------------------------------------------------------
PRO xml2design_list::EndElement, URI, Local, strName
 	compile_opt idl2
	compile_opt logical_predicate
   
;    strName = strlowcase(strName)

    ; Note the lack of validation in this methods. Validation is
    ; performed by the DTD or schema. If something is wrong in
    ; the file, the XML parser will let us know. Probably in a
    ; cryptic message, and in flames.

    CASE strName OF

        'DESIGN_LIST' : ; root object, do nothing

        ; ====== DESIGN =====

        'DESIGN' : BEGIN
            ; add completed design to the list
            if (n_elements(*self.pDesignList) eq 0) then $
                *self.pDesignList = self.current.design $
            else $
                *self.pDesignList = [*self.pDesignList, self.current.design]
            print, 'design count: ' + string(n_elements(*self.pDesignList))
            END

		'DESIGN_ID'      : self.current.design->SetDesignID, ulong(self.charBuffer)
        'DESIGN_COMMENT' : self.current.design->SetComment, self.charBuffer
        'LOCATION_ID'    : self.current.design->SetLocationID, ulong(self.charBuffer)
        'DRILL_STYLE'    : self.current.design->SetDrillStyle, self.charBuffer

;       'DESIGN_ID' : self.current.design.designid = ulong(self.charBuffer)
;       'DESIGN_COMMENT' : self.current.design.comment = self.charBuffer
;       'LOCATION_ID'    : self.current.design.locationid = ulong(self.charBuffer)
;       'DRILL_STYLE'    : self.current.design.drillStyle = self.charBuffer

        ; ====== PLATE_PLAN =====

        'PLATE_PLAN' : BEGIN ; saved as an array in DESIGN
            ;pPlatePlanList = self.current.design.pPlateList
;            if (n_elements(self.current.design.pPlateList) eq 0) then $
;                *self.current.design.pPlateList = self.current.platePlan $
;            else $
;                *self.current.design.pPlateList = $
;                        [*self.current.design.pPlateList, self.current.platePlan]

			self.current.design->AddPlatePlan, self.current.platePlan

            END

        'PLATEID'    	: self.current.platePlan->SetPlateID, ulong(self.charBuffer)
        'TEMP'       	: self.current.platePlan->SetTemp, float(self.charBuffer)
        'EPOCH'      	: self.current.platePlan->SetEpoch, float(self.charBuffer)
        'RERUN'      	: self.current.platePlan->SetRerun, self.charBuffer
        'PLATE_RUN'  	: self.current.platePlan->SetPlateRun, self.charBuffer
        'PLATE_NAME'    : self.current.platePlan->SetName, self.charBuffer
        'PLATE_COMMENT' : self.current.platePlan->SetComment, self.charBuffer

;        'PLATEID'    	: self.current.platePlan.plateid = ulong(self.charBuffer)
;        'TEMP'       	: self.current.platePlan.temp = float(self.charBuffer)
;        'EPOCH'      	: self.current.platePlan.epoch = float(self.charBuffer)
;        'RERUN'      	: self.current.platePlan.rerun = self.charBuffer
;        'PLATE_RUN'  	: self.current.platePlan.platerun = self.charBuffer
;        'PLATE_NAME'    : self.current.platePlan.name = self.charBuffer
;        'PLATE_COMMENT' : self.current.platePlan.comment = self.charBuffer

        ; ====== POINTING =====

        'POINTING' : BEGIN ; saved as an array in PLATE_PLAN

			self.current.design->AddPointing, self.current.pointing

;            pPointingsList = self.current.design.pPointingsList
;            if (n_elements(*pPointingsList) eq 0) then $
;                *pPointingsList = self.current.pointing $
;            else $
;                *pPointingsList = [*pPointingsList, self.current.pointing]
            END
        
        'FILENAME' 			: self.current.pointing->SetFilename, self.charBuffer
        'POINTING_PRIORITY' : self.current.pointing->SetPriority, fix(self.charBuffer)
        'HOUR_ANGLE'     	: self.current.pointing->SetHourAngle, double(self.charBuffer)
        'RA_CEN'     		: self.current.pointing->SetRaCen, double(self.charBuffer)
        'DEC_CEN'    		: self.current.pointing->SetDecCen, double(self.charBuffer)
        'RA_OFFSET'  	    : self.current.pointing->SetRaOffset, double(self.charBuffer)
        'DEC_OFFSET'    	: self.current.pointing->SetDecOffset, double(self.charBuffer)
        'POINTING_COMMENT' 	: self.current.pointing->SetComment, self.charBuffer

;        'FILENAME' 			: self.current.pointing.filename = self.charBuffer
;        'POINTING_PRIORITY' : self.current.pointing.priority = fix(self.charBuffer)
;        'HOUR_ANGLE'     	: self.current.pointing.hour_angle  = double(self.charBuffer)
;        'RA_CEN'     		: self.current.pointing.ra_cen  = double(self.charBuffer)
;        'DEC_CEN'    		: self.current.pointing.dec_cen = double(self.charBuffer)
;        'RA_OFFSET'  	    : self.current.pointing.ra_offset  = double(self.charBuffer)
;        'DEC_OFFSET'    	: self.current.pointing.dec_offset = double(self.charBuffer)
;        'POINTING_COMMENT' 	: self.current.pointing.comment = self.charBuffer

    ENDCASE
    

END

; ============================
; Convenience methods
; ============================
FUNCTION xml2design_list::GetDesignList
	compile_opt idl2
	compile_opt logical_predicate

    if (n_elements(*self.pDesignList) gt 0) then $
        return, *self.pDesignList $
    else return, -1
END

;; =============================================================
;; Convenience function to "flatten" structures one level,
;; returning a list of all plates rather than a list of designs.
;; Note that design info is lost here - if you want to keep that
;; grab the design structure.
;;
;; The "plate_run" parameter is optional. If specified, it will
;; filter out any plates not in the specified run.
;; Example:
;; oct_plates = obj->GetAllPlates('oct08c')
;;
;; If no plates match the run, "0" is returned. 
;; =============================================================
FUNCTION xml2Design_list::GetAllPlates, plate_run ; add n_returned here?
	compile_opt idl2
	compile_opt logical_predicate

	design_list = *self.pDesignList
	n_designs = n_elements(design_list)
    if (n_designs eq 0) then return, 0

	;print, string(n_designs) + " designs found"

	;; IDL doesn't have the concept of an empty list, so create a dummy
	;; plate here to get things started. This element will be removed
	;; before returning.
	platelist = OBJ_NEW()

	for design_idx=0L, n_designs-1 do begin
		
		currentDesign = design_list[design_idx]

		n_plates = currentDesign->N_PlatePlans()
		
		if (n_plates gt 0) then begin
			
			if (keyword_set(plate_run)) then $
				plates = currentDesign->PlatePlans(plate_run, count_returned=count) $
			else $
				plates = currentDesign->PlatePlans(count_returned=count)
				
			if (count gt 0) then $
;			if (plates ne 0 && n_elements(plates) gt 0) then $
				platelist = [platelist, plates]
		
		end ; end test for plate count > 0
;; ---			
;			begin
;				plates = currentDesign->PlatePlans()
;				if (~keyword_set(plate_run)) then $
;					for plate_idx=0, n
;				platelist = [platelist, currentDesign->PlatePlans()]
;			end
;		else $
;			platelist = [platelist, currentDesign->PlatePlans()]
;		endif
		
;		n_plates = n_elements(*currentDesign.pPlateList)
;		for plate_idx=0, n_plates-1 do begin
;			platelist = [platelist, *currentDesign.pPlatelist[plate_idx]]
;		end ;; end loop over plates
		
	end ;; end loop over design list
	
	if (n_elements(platelist) gt 1) then begin
		platelist = platelist[1:*] ; pop the dummy off the top of the list (see above)
		return, platelist
	endif else return, 0 ; no plate plans were found (only the dummy added above is present)

	;; return all plates
;	if (~keyword_set(plate_run)) then return, platelist


;;	if (n_elements(plate_run) eq 1) then begin
;		plate_idx = where(platelist.platerun eq plate_run, n_plates_found)
;		if (n_plates_found gt 0) then $ ; make sure match is not null
;			return, platelist[plate_idx] $
;		else return, 0
;;	endif
	
	; many plate runs specified - necessary?
	; p = {PLATE_PLAN} ; same trick as above

END

;; =========================================================
;; Object class definition method (must be the last thing declared in the file.
;; =========================================================
PRO xml2design_list__define
	compile_opt idl2
	compile_opt logical_predicate
   
    ;; Note: Object instance data is contained in named IDL structures.

    ;; ----------------------------------------------------------
    ;; Here we define all of the objects that we will be reading.
    ;; ----------------------------------------------------------

    ;; At the top level, we want an array of DESIGN objects.
    ;; This will be defined as a pointer since we don't know
    ;; how many will be read in before runtime.

	;; NOTE: These values are not set as defaults when a new
	;;       structure is created. IDL uses them only for the data type.

    ;; Definition: DESIGN object
    ;; ----------------------------------------------------------------
;    void = {DESIGN,                 	$  ; name of class
;            designid   : 0L,        	$  ;
;            locationid : 0L, 	    	$  ;
;            drillStyle : '', 	    	$  ;
;            comment    : '', 	    	$  ;
;            pPlateList : PTR_NEW(),     $  ;
;            pPointingsList : PTR_NEW() }   ; pointer to array of POINTINGs

    ;; Definition: PLATE_PLAN object
    ;; ----------------------------------------------------------------
;    void = {PLATE_PLAN, $               ; name of class
;            plateid       : 0L, $       ;
;            temp          : 0., $       ;
;            epoch         : 0., $       ;
;            rerun         : '', $       ;
;            platerun      : '', $       ;
;            name          : '', $       ;
;            comment       : ''  $
;            }

    ;; Definition: POINTING object
    ;; ----------------------------------------------------------------
;    void = {POINTING,         $ ; name of structure
;           filename    : '', $ ;
;           priority    : 1,  $ ;
;           hour_angle  : 0., $ ;
;           ra_cen      : 0., $ ;
;           dec_cen     : 0., $ ;
;			ra_offset   : 0., $ ;
;			dec_offset  : 0., $ ;
;			comment     : ''  $ ;
;			}
		
			
    ; A structure to be used for bookkeeping
    ; --------------------------------------
    void = {CURRENT, 			   $ ; name of structure
            design    : OBJ_NEW(), $  ; {PLATE_DESIGN}, 	$ ; 
            platePlan : OBJ_NEW(), $  ; {PLATE_PLAN},	$ ; 
            pointing  : OBJ_NEW()  $  ; {POINTING} 		$ ; 
            }

    ;; ----------------------------------------------------------------
    ;; Definition: DESIGN_LIST object
    ;;             -- charBuffer
    ;;             -- pDesignList : pointer to array of DESIGN objects
    ;; These are the instances of this class. Not that obvious.
    ;; ----------------------------------------------------------------
    void = {xml2design_list,         $ ; name of class
            INHERITS IDLffXMLSAX,    $
            pDesignList : PTR_NEW(), $ ; array of designs
            current     : {CURRENT}, $ ; to help with bookkeeping
            charBuffer  : ''}  ; Temporary variable to hold
                               ; strings as they are read in.

END
