;+
; NAME:
;   plate_assign
; PURPOSE:
;   Assign targets to a current plate
; CALLING SEQUENCE:
;   plate_assign, fibercount, design, new_design [, seed= ]
; INPUTS:
;   fibercount - structure with number of science, sky, standards 
;                used and total for each instrument:
;                  .INSTRUMENTS[NINSTRUMENT]
;                  .NSCIENCE_TOT[NINSTRUMENT]
;                  .NSCIENCE_USED[NINSTRUMENT]
;                  .NSTANDARD_TOT[NINSTRUMENT]
;                  .NSTANDARD_USED[NINSTRUMENT]
;                  .NSKY_TOT[NINSTRUMENT]
;                  .NSKY_USED[NINSTRUMENT]
;   design - [Nalready] design structure
;   new_design - [Nnew] target structure
; OPTIONAL INPUTS:
;   seed - random seed for shuffling
;   nmax - maximum number to assign
; COMMENTS:
;   Objects of identical priority are shuffled randomly before being
;     selected --- any preference MUST be expressed in the priorities!
; REVISION HISTORY:
;   8-May-2008  Written by MRB, NYU
;-
pro plate_assign, fibercount, design, new_design, seed=seed

;; step through targets in order of priority;
;; at this step we shuffle the targets to remove 
;; any funny sorting of the inputs
ishuffle= shuffle_indx(ntargets)
isort=sort(new_design[ishuffle].priority)
for i=0L, ntargets-1L do begin
    icurr= ishuffle[isort[i]]

    ;; are there any more of these sorts of holes available?
    ;; special types are SKY and STANDARD; all others interpreted
    ;; as SCIENCE
    curr_holetype= new_design[icurr].holetype
    curr_targettype= new_design[icurr].targettype
    curr_sourcetype= new_design[icurr].sourcetype
    curr_pointing= new_design[icurr].pointing
    curr_offset= new_design[icurr].offset

    ;; which type of instrument is this target for?
    iinstrument= where(curr_holetype eq fibercount.instruments, $
                       ninstruments)
    if(ninstrument gt 1) then $
      message, 'multiple instruments specified of type '+curr_holetype
    if(ninstrument eq 0) then $
      message, 'no such instrument for type of hole '+curr_holetype

    ;; which target type is this?
    itarget= where(curr_targettype eq fibercount.targettypes, $
                   ntargettypes)
    if(ninstrument gt 1) then $
      message, 'multiple target types specified of type '+curr_targettype
    if(ninstrument eq 0) then $
      message, 'no such target types for type of hole '+curr_targettype

    ;; if there are fewer fibers used from this instrument than
    ;; available, see if you can assign it
    if((fibercount.nused[iinstrument, itarget, $
                         curr_pointing-1L, curr_offset] lt $
        fibercount.ntot[iinstrument, itarget, $
                        curr_pointing-1L, curr_offset]) then begin
        
        ;; CHECK HERE IF SOURCETYPE IS "STANDARD"
        ;; DO WE HAVE CONSTRAINTS ON THE PLACEMENT?
        
        ;; CHECK HERE IF SOURCETYPE IS "SKY"
        ;; DO WE HAVE CONSTRAINTS ON THE PLACEMENT?

        ;; if this target is not conflicted with a previous target,
        ;; mark it as assigned, increment the number of fibers of this
        ;; type in use, and add it to the design list
        new_design[icurr].conflicted= $
          check_conflicts(design, new_design[icurr])
        if(new_design[icurr].conflicted eq 0) then begin
            new_design[icurr[i]].assigned=1
            fibercount.nused[iinstrument, itarget, $
                             curr_pointing-1L, curr_offset]= $
              fibercount.nused[iinstrument, itarget, $
                               curr_pointing-1L, curr_offset]+1L
            design= [design, new_design[icurr[i]]
        endif
    endif else begin
        new_design[icurr[i]].ranout=1
    endelse
endfor

return
end

