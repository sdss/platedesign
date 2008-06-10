;+
; NAME:
;   plate_drillrun
; PURPOSE:
;   Run the plate design for a drill run
; CALLING SEQUENCE:
;   plate_drillrun, plateid [, /debug, /clobber]
; INPUTS:
;   plateid - plateid number
; OPTIONAL KEYWORDS:
;   /debug - run in debug mode 
;   /clobber - clobber the existing design files 
;              (otherwise uses existing designs for a given designid)
; REVISION HISTORY:
;   7-May-2008  MRB, NYU
;-
;------------------------------------------------------------------------------
pro plate_drillrun, plateid, debug=debug, clobber=clobber

;; loop over multiple designs, etc
if(n_elements(plateid) gt 1) then begin
    for i=0L, n_elements(designid)-1L do begin
        plate_drillrun, plateid[i], debug=debug, clobber=clobber
    endfor
    return
endif

;; read plan file for settings
plans= yanny_readone(getenv('PLATELIST_DIR')+'/platePlans.par')
iplate=where(plans.plateid eq plateid, nplate)
if(nplate ne 1) then $
  message, 'error in platePlans.par file!'
plan=plans[iplate]
designid=plan.designid
ha=plan.ha
temp=plan.temp
epoch=plan.epoch
rerun=strsplit(plan.rerun, /extr)

;; set random seed 
origseed=-designid
seed=origseed

;; What are the output directories?
designdir= design_dir(designid)
spawn, 'mkdir -p '+designdir
platedir= getenv('PLATELIST_DIR')+'/plates/'+ $
  string((plateid/100L), f='(i4.4)')+'XX/'+ $
  string(plateid, f='(i6.6)')
spawn, 'mkdir -p '+platedir
    
;; Read in the plate definition file
;; Should be at 
;;   $PLATELIST_DIR/definitions/[did/100]00/plateDefinition-[did].par
;; as in 
;;   $PLATELIST_DIR/definitions/001000/plateDefinition-001045.par
definitiondir=getenv('PLATELIST_DIR')+'/definitions/'+ $
              string(f='(i4.4)', (designid/100L))+'XX'
definitionfile=definitiondir+'/'+ $
               'plateDefinition-'+ $
               string(f='(i6.6)', designid)+'.par'
dum= yanny_readone(definitionfile, hdr=hdr)
if(NOT keyword_set(hdr)) then begin
    message, 'no plateDefinition file '+definitionfile
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

;; Now do some sanity checks
racen= double((strsplit(definition.racen,/extr))[0])
deccen= double((strsplit(definition.deccen,/extr))[0])
if(abs(racen-plan.racen) gt 1./3600. OR $
   abs(deccen-plan.deccen) gt 1./3600.) then begin
    message, 'platePlans.par file disagrees with plateDefinition file on plate center'
endif

;; Make design file if it doesn't already exist
designfile=designdir+'/plateDesign-'+ $
  string(designid, f='(i6.6)')+'.par'
if(keyword_set(clobber) gt 0 OR $
   file_test(designfile) eq 0) then begin
    
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
    if(tag_exist(default, 'COLLECTFACTOR')) then $
      collectfactor= long(default.collectfactor) $
    else $
      collectfactor= 5L
    fibercount= {instruments:instruments, $
                 targettypes:targettypes, $
                 ntot:ntot, $
                 nused:nused, $
                 ncollect:ntot*collectfactor}

    ;; What conditions on fiber placement exist for each instrument?
    minstdinblock=lonarr(ninstruments) ;; how many standards per block?
    minskyinblock=lonarr(ninstruments) ;; how many skies per block?
    for iinst=0L, ninstruments-1L do begin
        ;; get minimum number of standards per block per pointing, if desired
        itagminstd=tag_indx(default, 'minstdinblock'+instruments[iinst])
        if(itagminstd eq -1) then $
          minstdinblock[iinst]=0L $
        else $
          minstdinblock[iinst]=long(default.(itagminstd))

        ;; get minimum number of skies per block per pointing, if desired
        itagminsky=tag_indx(default, 'minskyinblock'+instruments[iinst])
        if(itagminsky eq -1) then $
          minskyinblock[iinst]=0L $
        else $
          minskyinblock[iinst]=long(default.(itagminsky))
    endfor
    
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
            tmp_design.iplateinput= k+1L
            
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
        guide_design= plate_guide(definition, default, pointing, $
                                  rerun=rerun, epoch=epoch)
        if(n_tags(guide_design) gt 0) then $
          plate_assign_guide, definition, default, design, guide_design, $
                              guidenums=guidenums
    endfor

    ;; Assign standards 
    for pointing=1L, npointings do begin
        for offset=0L, noffsets do begin
            for iinst=0L, ninstruments-1L do begin

                ;; get appropriate list of standards
                sphoto_design= plate_standard(definition, default, $
                                              instruments[iinst], $
                                              pointing, offset, $
                                              rerun=rerun)

                if(n_tags(sphoto_design) gt 0) then begin
                    ;; assign, applying constraints imposed in the
                    ;; "FIBERID_[INSTRUMENT]" procedure; this code
                    ;; slowly increases number of considered targets 
                    ;; until constraints are satisfied; because
                    ;; pointing and offsets are considered separately,
                    ;; this does not constitute a guarantee on the
                    ;; final design
                    plate_assign_constrained, default, instruments[iinst], $
                      'standard', fibercount, pointing, offset, design, $
                      sphoto_design, seed=seed, $
                      minstdinblock=minstdinblock[iinst], $
                      minskyinblock=minskyinblock[iinst], $
                      /nosky, /noscience
                endif
            endfor
        endfor 
    endfor
    
    ;; Find sky fibers and assign them
    for pointing=1L, npointings do begin
        for offset=0L, noffsets do begin
            for iinst=0L, ninstruments-1L do begin
                sky_design= plate_sky(definition, default, $
                                      instruments[iinst], pointing, offset, $
                                      rerun=rerun)
                if(n_tags(sky_design) gt 0) then begin
                    ;; assign, applying constraints imposed in the
                    ;; "FIBERID_[INSTRUMENT]" procedure; this code
                    ;; slowly increases number of considered targets 
                    ;; until constraints are satisfied; because
                    ;; pointing and offsets are considered separately,
                    ;; this does not constitute a guarantee on the
                    ;; final design
                    plate_assign_constrained, default, instruments[iinst], $
                      'sky', fibercount, pointing, offset, design, $
                      sky_design, seed=seed, $
                      minstdinblock=minstdinblock[iinst], $
                      minskyinblock=minskyinblock[iinst], $
                      /nostd, /noscience
                endif
            endfor 
        endfor 
    endfor
    
    ;; Check for extra fibers
    iunused=where(fibercount.nused lt fibercount.ntot, nunused)
    if(nunused gt 0) then begin
        splog, 'Unused fibers found. Please specify more targets!'
        splog, 'Not completing plate design '+strtrim(string(designid),2)
        if(keyword_set(debug)) then stop
        return
    endif

    ;; Find light traps and assign them
    ;; (Note that assignment here checks for conflicts:
    ;; so if a light trap overlaps an existing hole, the
    ;; light trap is not drilled)
    for pointing=1L, npointings do begin
        for offset=0L, noffsets do begin
            ;; find bright stars
            trap_design= plate_trap(definition, default, pointing, offset)
            
            ;; add them if they don't conflict
            if(n_tags(trap_design) gt 0) then begin
                for i=0L, n_elements(trap_design)-1L do begin
                    trap_design[i].conflicted= $
                      check_conflicts(design, trap_design[i])
                    if(NOT trap_design[i].conflicted) then $
                      design= [design, trap_design[i]]
                endfor
            endif
        endfor
    endfor

    ;; Assign fiberid's for each instrument
    keep=lonarr(n_elements(design))+1L
    for iinst=0L, ninstruments-1L do begin
        icurr= where(design.holetype eq instruments[iinst], ncurr)

        if(ncurr gt 0) then begin
            keep[icurr]=0L
            fiberids= call_function('fiberid_'+instruments[iinst], $
                                    default, fibercount, design[icurr], $
                                    minstdinblock=minstdinblock[iinst], $
                                    minskyinblock=minskyinblock[iinst])
            design[icurr].fiberid= fiberids
            iassigned= where(design[icurr].fiberid ge 1, nassigned)
            if(nassigned gt 0) then $
              keep[icurr[iassigned]]=1L
            if(nassigned ne long(total(fibercount.ntot[iinst,*,*,*]))) $
              then begin
                splog, 'Some fibers not assigned to targets!'
                if(keyword_set(debug)) then stop
                splog, 'Not completing plate design '+ $
                       strtrim(string(designid),2)
                return
            endif
        endif
    endfor
    ikeep=where(keep gt 0, nkeep)
    design=design[ikeep]
    
    ;; Write out plate assignments to 
    ;;   $PLATELIST_DIR/designs/plateDesign-[designid] file
    pdata= ptr_new(design)
    spawn, 'mkdir -p '+designdir
    hdrstr=struct_combine(default, definition)
    outhdr=struct2lines(hdrstr)
    outhdr=[outhdr, 'platedesign_version '+platedesign_version()]
    yanny_write, designfile, pdata, hdr=outhdr
    
endif

;; Convert plateDesign to plateHoles
;;  -- recall to add ALIGNMENT
plate_holes, designid, plateid, ha, temp

;; Produce plugfiles of desired style
if(NOT tag_exist(default, 'plugmapstyle')) then $
  plugmapstyle='plplugmap' $
else $
  plugmapstyle= default.plugmapstyle
platedir= plate_dir(plateid)
platefile= platedir+'/plateHoles-'+ $
  strtrim(string(f='(i6.6)',plateid),2)+'.par'
holes= yanny_readone(platefile, hdr=hdr)
hdrstr= lines2struct(hdr)
call_procedure, 'plugfile_'+plugmapstyle, hdrstr, hdrstr, holes 

;; Run low-level plate routines

return
end
