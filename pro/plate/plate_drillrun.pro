;+
; NAME:
;   plate_drillrun
; PURPOSE:
;   Run the plate design for a drill run
; CALLING SEQUENCE:
;   plate_drillrun, designid, ha, temp
; INPUTS:
;   designid - [Ndesign] list of design IDs to run
;   ha - [Ndesign] hour angle to drill for
;   temp - [Ndesign] temperature to drill for
; COMMENTS:
;   Required tags in plateDefinition:
;     designID
;     raCen1
;     decCen1
;     locationID1
;     plateType
;     platedesignVersion
;     nInputs
; REVISION HISTORY:
;   7-May-2008  MRB, NYU
;-
;------------------------------------------------------------------------------
pro plate_drillrun, designid, ha, temp, justholes=justholes

if(n_elements(designid) gt 1) then begin
    for i=0L, n_elements(designid)-1L do begin
        plate_drillrun, designid[i], ha[i], temp[i]
    endfor
    return
endif

if(NOT keyword_set(justholes)) then begin
    
    ;; Read in the plate definition file
    ;; Should be at 
    ;;   $PLATELIST_DIR/definitions/[did/100]00/plateDefinition-[did].par
    ;; as in 
    ;;   $PLATELIST_DIR/definitions/001000/plateDefinition-001045.par
    definitiondir=getenv('PLATELIST_DIR')+'/definitions/'+ $
      string(f='(i6.6)', (designid/100L)*100L)
    definitionfile=definitiondir+'/'+ $
      'plateDefinition-'+ $
      string(f='(i6.6)', designid)+'.par'
    dum= yanny_readone(definitionfile, hdr=hdr)
    if(NOT keyword_set(hdr)) then begin
        message, 'no plateDefaults file '+definitionfile
    endif
    definition= lines2struct(hdr)

    ;; Read in the plate defaults file
    ;; (reset any tags that are overwritten by plateDefinition)
    defaultdir= getenv('PLATEDESIGN_DIR')+'/defaults'
    defaultfile= defaultdir+'/plateDefault-'+ $
      definition.platetype+'-'+ $
      definition.platedesignversion+'.par'
    dum= yanny_readone(defaultfile, hdr=hdr)
    if(NOT keyword_set(hdr)) then begin
        message, 'no plateDefaults file '+defaultfile
    endif
    default= lines2struct(hdr)
    defaultnames=tag_names(default)
    definitionnames=tag_names(definition)
    for i=0L, n_tags(default)-1L do begin
        for j=0L, n_tags(definition)-1L do begin
            if(defaultnames[i] eq definitionnames[j]) then $
              default.(i)= definition.(j)
        endfor
    endfor
    
    ;; For each class of input priorities, run plate_assign 
    ;; Note input files root path is $PLATELIST_DIR/inputs
    ninputs= long(definition.ninputs)
    for i=0L, ninputs-1L do begin
        itag=tag_indx(definition, 'plateInput'+strtrim(string(i+1),2))
        if(itag eq -1) then $
          message, 'no plateInput'+strtrim(string(i+1),2)+' param set'
        targets= yanny_readone(getenv('PLATELIST_DIR')+ $
                               '/inputs/'+definition.(itag))
        ;; RUN PLATE_ASSIGN HERE
    endfor

    ;; Find guide fibers and assign them
    if(definition.platedesignguides gt 0) then begin
        ;; find guide fibers 

        ;; assign them 

    endif

    ;; Find standard stars and assign them
    if(definition.platedesignstandards gt 0) then begin
        ;; find sky fibers 

        ;; assign them 

    endif

    ;; Find sky fibers and assign them
    if(definition.platedesignskies gt 0) then begin
        ;; find sky fibers 

        ;; assign them 

    endif

    ;; Find light traps and assign them
    if(definition.platedesignskies gt 0) then begin
        ;; find sky fibers 

        ;; assign them 

    endif

    ;; Re-sort fibers
    
    ;; Write out plate assignments to 
    ;;   $PLATELIST_DIR/designs/plateDesign-[designid] file

    ;; Update $PLATELIST_DIR/plateDesigns.par
    

endif

;; Convert plateDesign to plateHoles
plate_holes, designid, ha, temp

;; Produce standard-style plPlugMap files
plate_holes, designid, ha, temp

;; Run low-level plate routines

return
end
