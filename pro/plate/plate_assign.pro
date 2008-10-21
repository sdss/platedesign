;+
; NAME:
;   plate_assign
; PURPOSE:
;   Assign targets to a current plate
; CALLING SEQUENCE:
;   plate_assign, definition, fibercount, design, new_design [, seed= ]
; INPUTS:
;   definition - structure with plate definition info (required to
;                have .RACEN and .DECCEN)
;   fibercount - structure with number of science, sky, standards 
;                used and total for each instrument:
;   design - [Nalready] design structure
;   new_design - [Nnew] target structure
; OPTIONAL INPUTS:
;   nextra - number of extra fibers to collect
;   seed - random seed for shuffling
;   nmax - maximum number to assign
; COMMENTS:
;   Objects of identical priority are shuffled randomly before being
;     selected --- any preference MUST be expressed in the priorities!
; REVISION HISTORY:
;   8-May-2008  Written by MRB, NYU
;-
pro plate_assign, definition, default, fibercount, design, new_design, $
                  seed=seed, collect=collect, nextra=nextra

tilerad=1.49

;; normally limit by number of available fibers; however, in some
;; cases we want to collect a large set of non-colliding ones (for
;; skies and standards) before choosing a few out; we set /collect for
;; such cases
nlimit=fibercount.ntot
if(keyword_set(collect)) then $
  nlimit=fibercount.ncollect
if(keyword_set(nextra)) then begin
    for i=0L, n_elements(nextra)-1L do begin
        nlimit[*,*,i,*]=nlimit[*,*,i,*]+nextra[i]
    endfor
endif

;; step through targets in order of priority;
;; at this step we shuffle the targets to remove 
;; any funny sorting of the inputs
ntargets=n_elements(new_design)
ishuffle= shuffle_indx(ntargets, seed=seed)
isort=sort(new_design[ishuffle].priority)
for i=0L, ntargets-1L do begin
    icurr= ishuffle[isort[i]]

    ;; are there any more of these sorts of holes available?
    curr_holetype= new_design[icurr].holetype
    curr_targettype= new_design[icurr].targettype
    curr_sourcetype= new_design[icurr].sourcetype
    curr_pointing= new_design[icurr].pointing
    curr_offset= new_design[icurr].offset

    ;; which type of instrument is this target for?
    iinstrument= $
      where(strcmp(curr_holetype, fibercount.instruments, /fold) gt 0, $
            ninstruments)
    if(ninstruments gt 1) then $
      message, 'multiple instruments specified of type '+curr_holetype
    if(ninstruments eq 0) then $
      message, 'no such instrument for type of hole '+curr_holetype

    ;; which target type is this?
    itarget= $
      where(strcmp(curr_targettype, fibercount.targettypes, /fold) gt 0, $
            ntargettypes)
    if(ntargettypes gt 1) then $
      message, 'multiple target types specified of type '+curr_targettype
    if(ntargettypes eq 0) then $
      message, 'no such target types for type of hole '+curr_targettype

    ;; if this fiber is outside the radius, discount it altogether
    plate_center, definition, default, curr_pointing, curr_offset, $
      racen=racen, deccen=deccen
    spherematch, racen, deccen, new_design[icurr].target_ra, $
      new_design[icurr].target_dec, tilerad, m1, m2
    if(m1[0] ne -1) then begin
        ;; if there are fewer fibers used from this instrument than
        ;; available, see if you can assign it
        if(fibercount.nused[iinstrument,itarget, $
                            curr_pointing-1L,curr_offset] lt $
           nlimit[iinstrument,itarget, $
                  curr_pointing-1L,curr_offset]) then begin
            
            ;; if this target is not conflicted with a previous target,
            ;; mark it as assigned, increment the number of fibers of this
            ;; type in use, and add it to the design list
            new_design[icurr].conflicted= $
              check_conflicts(design, new_design[icurr])
            if(new_design[icurr].conflicted eq 0) then begin
                new_design[icurr].assigned=1
                fibercount.nused[iinstrument, itarget, $
                                 curr_pointing-1L, curr_offset]= $
                  fibercount.nused[iinstrument, itarget, $
                                   curr_pointing-1L, curr_offset]+1L
                design= [design, new_design[icurr]]
            endif
        endif else begin
            new_design[icurr].ranout=1
        endelse
    endif else begin
        new_design[icurr].outside=1
    endelse
endfor

return
end

