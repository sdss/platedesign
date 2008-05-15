;+
; NAME:
;   plate_assign
; PURPOSE:
;   Assign targets to a current plate
; CALLING SEQUENCE:
;   plate_assign, definition, default, design, new_design
; INPUTS:
;   definition - plate definition structure
;   default - plate default structure
;   design - design structure
;   new_design - target structure
; OPTIONAL INPUTS:
;   seed - random seed for shuffling
; COMMENTS:
;   All 
;   Objects of identical priority are shuffled randomly before being
;     selected --- any preference MUST be expressed in the priorities!
; REVISION HISTORY:
;   8-May-2008  Written by MRB, NYU
;-
pro plate_assign, definition, default, design, new_design, seed=seed

;; CHECK HERE IF HOLETYPE IS "STANDARD"
;; DO WE HAVE CONSTRAINTS ON THE PLACEMENT?

;; CHECK HERE IF HOLETYPE IS "SKY"
;; DO WE HAVE CONSTRAINTS ON THE PLACEMENT?

;; step through targets in order of priority;
;; at this step we shuffle the targets to remove 
;; any funny sorting of the inputs
ishuffle= shuffle_indx(ntargets)
isort=sort(new_design[ishuffle].priority)
for i=0L, ntargets-1L do begin
    icurr= ishuffle[isort[i]]

    ;; if this target is not conflicted with a previous target
    new_design[icurr].conflicted= $
      check_conflicts(design, new_design[icurr])
    if(new_design[icurr].conflicted eq 0) then begin
        new_design[icurr[i]].assigned=1
        design= [design, new_design[icurr[i]]
    endif
endfor

return
end

