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
pro plate_drillrun, designid, ha, temp, epoch, justholes=justholes

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
                           '_'+strtrim(string(targettypes[i]),2))
            if(itag eq -1) then $
              message, 'must specify n'+ $
                       strtrim(string(instruments[i]),2)+ $
                       '_'+strtrim(string(targettypes[i]),2)
            ntot[i,j,*,*]= long(default.(itag))
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
            target2design, definition, default, tmp_design, tmp_targets, $
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
    if(definition.platedesignguides gt 0) then begin
        
        for pointing= 1L, npointings do begin

            ;; what is center for this pointing?
            plate_center, definition, default, pointing, 0L, $
                          racen=racen, deccen=deccen

            ;; which guide fibers for this pointing?
            if(npointings gt 1) then begin
                iguides=tag_indx(default, 'guidenums'+ $
                                 strtrim(string(pointing),2))
                if(iguides eq -1) then $
                  message, 'Must specify guide fiber numbers for pointing '+ $
                           strtrim(string(pointing),2)
                guidenums= long(strsplit(default.(iguides), /extr))
            endif 
            
            ;; find SDSS guide fibers and try to assign them
            plate_select_guide_sdss, racen, deccen, epoch=epoch, $
              rerun=rerun, guide_design=guide_design_sdss
            plate_assign_guide, definition, default, design, $
                                guide_design_sdss, guidenums=guidenums
            
            ;; find 2MASS guide fibers and try to assign them
            plate_select_guide_2mass, racen, deccen, epoch=epoch, $
              rerun=rerun, guide_design=guide_design_2mass
            plate_assign_guide, definition, default, design, $
                                guide_design_2mass, guidenums=guidenums
        endfor
    endif

    ;; Find standard stars and assign them
    ;; DO WE HAVE CONSTRAINTS ON THE PLACEMENT?
    ;; HOW DO WE ALLOCATE AMONG POINTINGS?
    ;; HOW DO WE ALLOCATE AMONG OFFSETS? (RIGHT NOW, JUST OFFSET 0)
    ;; SHOULD WE SOMEHOW CACHE THE STANDARDS?
    if(tag_exist(definition.platedesignstandards)) then begin
        itype= where(fibercount.targettype eq 'standard', ntype)
        if(ntype eq 0) then $
          message, 'no standard target type' 

        platedesignstandards= strsplit(definition.platedesignstandards, /extr)
        standardtype= strsplit(definition.standardtype, /extr)
        for i=0L, n_elements(platedesignstandards)-1L do begin
            curr_inst=platedesignstandards[i]
            curr_type=standardtype[i]
            iinst=where(fibercount.instruments eq curr_inst, ninst)
            if(ninst eq 0) then $
              message, 'no instrument '+ curr_inst

            npointings= long(default.npointings)
            noffsets= long(default.noffsets)
            for pointing= 1L, npointings do begin
                
                for offset= 0L, noffsets do begin
                    ;; what is center for this pointing and offset?
                    plate_center, definition, default, pointing, offset, $
                                  racen=racen, deccen=deccen
                    
                    if(curr_type eq 'SDSS') then begin
                        ;; find SDSS standards and assign them
                        plate_select_sphoto_sdss, racen, deccen, rerun=rerun, $
                          sphoto_mag=sphoto_mag, $
                          sphoto_design= sphoto_design_sdss
                        sphoto_design_sdss.pointing=pointing
                        sphoto_design_sdss.offset=offset
                        sphoto_design_sdss.holetype=curr_inst
                        plate_assign, fibercount, design, $
                                      sphoto_design_sdss, seed=seed
                    endif 
                    
                    if(curr_type eq '2MASS') then begin
                        ;; find 2MASS standards and assign them
                        plate_select_sphoto_2mass, racen, deccen, $
                          sphoto_mag=sphoto_mag, $
                          sphoto_design= sphoto_design_2mass
                        sphoto_design_2mass.pointing=pointing
                        sphoto_design_2mass.offset=offset
                        sphoto_design_2mass.holetype=curr_inst
                        plate_assign, fibercount, design, $
                                      sphoto_design_2mass, seed=seed
                    endif
                endfor
            endfor
        endfor
    endif

    ;; Find sky fibers and assign them
    ;; DO WE HAVE CONSTRAINTS ON THE PLACEMENT?
    if(definition.platedesignskies gt 0) then begin
        itype= where(fibercount.targettype eq 'sky', ntype)
        if(ntype eq 0) then $
          message, 'no sky target type' 

        platedesignskies= strsplit(definition.platedesignskies, /extr)
        skytype= strsplit(definition.skytype, /extr)
        for i=0L, n_elements(platedesignskies)-1L do begin
            curr_inst=platedesignskies[i]
            curr_type=skytype[i]
            iinst=where(fibercount.instruments eq curr_inst, ninst)
            if(ninst eq 0) then $
              message, 'no instrument '+ curr_inst
            isky=where(fibercount.targettype eq 'sky', nsky)
            if(nsky eq 0) then $
              message, 'no target type sky'

            npointings= long(default.npointings)
            noffsets= long(default.noffsets)
            for pointing= 1L, npointings do begin
                
                for offset= 0L, noffsets do begin
                    ;; what is center for this pointing and offset?
                    plate_center, definition, default, pointing, offset, $
                                  racen=racen, deccen=deccen
                    
                    nsky=2L*fibercounts.ntot[iinst,isky,pointing-1L,offset] 

                    if(curr_type eq 'SDSS') then begin
                        ;; find SDSS skies and assign them
                        plate_select_sky_sdss, racen, deccen, $
                          nsky=nsky, seed=seed, rerun=rerun, $
                          sky_design=sky_design
                        sky_design.pointing=pointing
                        sky_design.offset=offset
                        sky_design.holetype=curr_inst
                        plate_assign, fibercount, design, $
                                      sky_design, seed=seed
                    endif 
                endfor
            endfor
        endfor
    endif
    
    ;; WHAT DO WE DO WITH EXTRA FIBERS HERE!!

    ;; Find light traps and assign them
    ;; (Note that assignment here checks for conflicts:
    ;; so if a light trap overlaps an existing hole, the
    ;; light trap is not drilled)
    if(definition.platedesigntraps gt 0) then begin
        ;; find bright stars

        ;; assign them 

    endif

    ;; Re-sort fibers
    
    ;; Write out plate assignments to 
    ;;   $PLATELIST_DIR/designs/plateDesign-[designid] file
    outdir= getenv('PLATELIST_DIR')+'/designs/'+ $
            string((designid/100L)*100L, f='(i6.6)')
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
