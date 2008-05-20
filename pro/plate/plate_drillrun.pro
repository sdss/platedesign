;+
; NAME:
;   plate_drillrun
; PURPOSE:
;   Run the plate design for a drill run
; CALLING SEQUENCE:
;   plate_drillrun, designid, ha, temp, epoch [, /justholes]
; INPUTS:
;   designid - [Ndesign] list of design IDs to run
;   ha - [Ndesign] hour angle to drill for
;   temp - [Ndesign] temperature to drill for
;   epoch - [Ndesign] epoch 
; OPTIONAL KEYWORDS:
;   /justholes - just convert already made design into holes 
; COMMENTS:
;   Required tags in plateDefinition:
;     designID
;     raCen1
;     decCen1
;     locationID1
;     plateType
;     platedesignVersion
;     nInputs
;     plateInput[1..nInputs]
;     nPointings
;     guideNums[1..nInputs] (if nPointings>1)
;   NEED TO TRACK NUMBER OF AVAILABLE FIBERS PER INSTRUMENT!!
; REVISION HISTORY:
;   7-May-2008  MRB, NYU
;-
;------------------------------------------------------------------------------
pro plate_drillrun, designid, ha, temp, epoch, justholes=justholes, $
                    rerun=rerun

;; loop over multiple designs, etc
if(n_elements(designid) gt 1) then begin
    for i=0L, n_elements(designid)-1L do begin
        plate_drillrun, designid[i], ha[i], temp[i], epoch[i], $
                        justholes=justholes
    endfor
    return
endif

;; set random seed 
origseed=-designid
seed=origseed

;; What is the output directory?
outdir= getenv('PLATELIST_DIR')+'/designs/'+ $
        string((designid/100L)*100L, f='(i6.6)')
    
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

if(NOT keyword_set(justholes)) then begin

    ;; Initialize design structure, including a center hole
    design=design_blank(/center)

    ;; What instruments are being used, and how many science,
    ;; standard and sky fibers do we assign to each?
    npointings= long(default.npointings)
    noffsets= long(default.noffsets)
    instruments= strsplit(default.instruments, /extr)
    ninstruments= n_elements(instruments)
    targettypes= strsplit(default.targettypes, /extr)
    ntargettypes= n_elements(targettypes)
    ntot=lonarr(ninstruments, ntargettypes, npointings, noffsets+1L)
    nused=lonarr(ninstruments, ntargettypes, npointings, noffsets+1L)
    for i=0L, ninstruments-1L do begin
        for j=0L, ntargettypes-1L do begin
            itag= tag_indx(default, 'n'+ $
                           strtrim(string(instruments[i]),2)+ $
                           '_'+strtrim(string(targettypes[j]),2))
            if(itag eq -1) then $
              message, 'must specify n'+ $
                       strtrim(string(instruments[i]),2)+ $
                       '_'+strtrim(string(targettypes[j]),2)
            ntot[i,j,*,*]= long(strsplit(default.(itag),/extr))
        endfor
    endfor
    fibercount= {instruments:instruments, $
                 targettypes:targettypes, $
                 ntot:ntot, $
                 nused:nused}
    
    ;; For each class of input priorities, run plate_assign 
    ;; Note input files root path is $PLATELIST_DIR/inputs

    ;; first, convert inputs into priority list
    ninputs= long(definition.ninputs)
    priority=lindgen(ninputs)
    if(tag_exist(definition, 'priority')) then $
      priority= long(strsplit(definition.priority, /extr))

    ;; second, treat each priority list separately
    isort=sort(priority)
    iuniq=uniq(priority[isort])
    istart=0L
    for i=0L, n_elements(iuniq)-1L do begin
        iend=iuniq[i]
        icurr=isort[istart:iend]
        ncurr=n_elements(icurr)
        
        ;; read in each plateInput file at this priority level
        new_design=0
        for j=0L, ncurr-1L do begin
            k=icurr[j]
            itag=tag_indx(definition, 'plateInput'+strtrim(string(k+1),2))
            if(itag eq -1) then $
              message, 'no plateInput'+strtrim(string(k+1),2)+' param set'
            infile=getenv('PLATELIST_DIR')+ $
                   '/inputs/'+definition.(itag)
            tmp_targets= yanny_readone(infile, hdr=hdr)
            if(n_tags(tmp_targets) eq 0) then $
              message, 'empty plateInput file '+infile
            hdrstr=lines2struct(hdr)
            
            ;; convert target information to design structure
            ;; (record which plate input file this came from)
            target2design, definition, default, tmp_targets, tmp_design, $
                           info=hdrstr
            tmp_design.iplateinput= k
            
            if(n_tags(new_design) eq 0) then begin
                new_design=tmp_design 
            endif else begin
                new_design=[new_design, tmp_design]
            endelse
        endfor
        
        ;; assign holes to each plateInput file
        plate_assign, fibercount, design, new_design, seed=seed
        
        istart=iend+1L
    endfor

    ;; Find guide fibers and assign them (if we're supposed to)
    ;; Make sure to assign proper guides to each pointing
    for pointing=1L, npointings do begin
        iguidenums= $
          tag_indx(default, 'guideNums'+strtrim(string(pointing),2))
        if(iguidenums eq -1) then $
          message, 'Must specify guide fiber numbers for pointing '+ $
                   strtrim(string(pointing),2)
        guidenums=long(strsplit(default.(iguidenums),/extr))
        guide_design= plate_guide(definition, default, pointing)
        if(n_tags(guide_design) gt 0) then $
          plate_assign_guide, definition, default, design, guide_design, $
                              guidenums=guidenums
    endfor

    ;; Assign standards 
    ;; DO WE HAVE CONSTRAINTS ON THE PLACEMENT?
    for pointing=1L, npointings do begin
        for offset=0L, noffsets do begin
            sphoto_design= plate_standard(definition, default, $
                                          pointing, offset)
            if(n_tags(sphoto_design) gt 0) then $
              plate_assign, fibercount, design, sphoto_design, seed=seed
        endfor 
    endfor
    
    ;; Find sky fibers and assign them
    ;; DO WE HAVE CONSTRAINTS ON THE PLACEMENT?
    for pointing=1L, npointings do begin
        for offset=0L, noffsets do begin
            sky_design= plate_sky(definition, default, pointing, offset)
            if(n_tags(sky_design) gt 0) then $
              plate_assign, fibercount, design, sky_design, seed=seed
        endfor 
    endfor
    
    ;; WHAT DO WE DO WITH EXTRA FIBERS HERE!!

    ;; Find light traps and assign them
    ;; (Note that assignment here checks for conflicts:
    ;; so if a light trap overlaps an existing hole, the
    ;; light trap is not drilled)
    for pointing=1L, npointings do begin
        for offset=0L, noffsets do begin
            ;; find bright stars
            trap_design= plate_trap(definition, default, pointing, offset)
            
            ;; assign them 
            if(n_tags(trap_design) gt 0) then $
               plate_assign, fibercount, design, trap_design, seed=seed
        endfor
    endfor

    ;; Re-sort fibers
    
    ;; Write out plate assignments to 
    ;;   $PLATELIST_DIR/designs/plateDesign-[designid] file
    outfile=outdir+'/plateDesign-'+ $
            string(designid, f='(i6.6)')+'.par'
    pdata= ptr_new(design)
    spawn, 'mkdir -p '+outdir
    yanny_write, outfile, pdata

    ;; Update $PLATELIST_DIR/plateDesigns.par
    

endif

;; Convert plateDesign to plateHoles
;;  -- recall to add ALIGNMENT
;;plate_holes, designid, plateid, ha, temp

;; Produce standard-style plPlugMap files
;;plate_plplugmap, plateid

;; Run low-level plate routines

return
end
