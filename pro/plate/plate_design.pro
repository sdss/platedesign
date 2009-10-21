;+
; NAME:
;   plate_design
; PURPOSE:
;   Run the plate design for a drill run
; CALLING SEQUENCE:
;   plate_design, plateid [, /debug, /clobber, /superclobber]
; INPUTS:
;   plateid - plateid number
; OPTIONAL KEYWORDS:
;   /debug - run in debug mode 
;   /clobber - clobber the existing design files 
;              (otherwise uses existing designs for a given designid)
;   /superclobber - delete any and all output files associated with this
;					plate before running.
; REVISION HISTORY:
;   7-May-2008  MRB, NYU
;  23-Jan-2008, Demitri Muna, NYU - added superclobber option
;-
;------------------------------------------------------------------------------
pro plate_design, plateid, debug=debug, clobber=clobber, $
                  superclobber=superclobber, succeeded=succeeded

COMPILE_OPT idl2
COMPILE_OPT logical_predicate

true = 1
false = 0

succeeded = false

;; loop over multiple designs, etc
if(n_elements(plateid) gt 1) then begin
    for i=0L, n_elements(plateid)-1L do begin
        plate_design, plateid[i], debug=debug, clobber=clobber, $
                  superclobber=superclobber, succeeded=succeeded
    endfor
    return
endif

splog, 'Working on plateid= '+strtrim(string(plateid),2)

;; read plan file for settings
platePlans_file = getenv('PLATELIST_DIR')+'/platePlans.par'
plans= yanny_readone(platePlans_file)

iplate=where(plans.plateid eq plateid, nplate)

; === Check performed in preflight - to remove ===
if(nplate gt 1) then begin
  message, 'Error: More than one entry for plateid (' + string(plateid) + $
    ') found in ' + platePlans_file + '.'
endif
; ===

if (nplate eq 0) then begin
    message, 'Error: The plate id given (' + string(plateid) + $
      ') was not found in ' + platePlans_file + '.'
    return
endif

plan=plans[iplate]
designid=plan.designid
ha=plan.ha
temp=plan.temp
epoch=plan.epoch

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

;; Delete any output files from a previous run
if (keyword_set(superclobber)) then begin
	
	old_files = file_search(designdir + "/*", count=old_files_count)
	if (old_files_count gt 0) then file_delete, old_files

	old_files = file_search(platedir + "/*", count=old_files_count)
	if (old_files_count gt 0) then file_delete, old_files
endif

;; Read in the plate definition file
;; Should be at (with did = designid)
;;   $PLATELIST_DIR/definitions/[did/100]00/plateDefinition-[did].par
;; as in 
;;   $PLATELIST_DIR/definitions/001000/plateDefinition-001045.par
definitiondir=getenv('PLATELIST_DIR')+'/definitions/'+ $
              string(f='(i4.4)', (designid/100L))+'XX'
definitionfile=definitiondir+'/'+ $
               'plateDefinition-'+ $
               string(f='(i6.6)', designid)+'.par'
dum= yanny_readone(definitionfile, hdr=hdr)
if(~keyword_set(hdr)) then begin
    message, 'Error: plateDefinition file not found: ' + $
      definitionfile + ' (plate id: (' + string(plateid) + ')'
endif
definition= lines2struct(hdr)

;; Read in the plate defaults file
;; (reset any tags that are overwritten by plateDefinition)
defaultdir= getenv('PLATEDESIGN_DIR')+'/defaults'
defaultfile= defaultdir+'/plateDefault-'+ $
             definition.platetype+'-'+ $
             definition.platedesignversion+'.par'
dum= yanny_readone(defaultfile, hdr=hdr)
if(~keyword_set(hdr)) then begin
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

;; see if we should respect the fiberid
if(tag_exist(definition, 'RESPECT_FIBERID')) then begin
    respect_fiberid= long(definition.respect_fiberid)
endif

;; see if we should replace fibers
if(tag_exist(definition, 'REPLACE_FIBERS')) then begin
    replace_fibers= long(definition.replace_fibers)
endif

;; special flag to omit guide fibers
if(tag_exist(default, 'OMIT_GUIDES')) then begin
    omit_guides= long(default.omit_guides)
endif

;; special flag to omit guide fibers
if(tag_exist(default, 'OMIT_CENTER')) then begin
    omit_center= long(default.omit_center)
endif

;; special flag to omit traps
if(tag_exist(default, 'OMIT_TRAPS')) then begin
    omit_traps= long(default.omit_traps)
endif

;; Now do some sanity checks
racen= double((strsplit(definition.racen,/extr))[0])
deccen= double((strsplit(definition.deccen,/extr))[0])
if(abs(racen-plan.racen) gt 1./3600. OR $
   abs(deccen-plan.deccen) gt 1./3600.) then begin
    message, 'platePlans.par file disagrees with plateDefinition file on plate center'
endif
if(designid ne long(definition.designid)) then begin
    message, 'plateDefinition file has wrong designid'
endif

;; Warn us if we do not have a condition to set min/max HA 
if(tag_indx(default, 'max_off_fiber_for_ha') eq -1) then begin
    default= create_struct(default, 'max_off_fiber_for_ha', '0.5')
    plate_log, plateid, 'WARNING: max_off_fiber_for_ha not set in default file'
    plate_log, plateid, 'WARNING: setting max_off_fiber_for_ha='+ $
               default.max_off_fiber_for_ha+' arcsec'
endif 

;; Make design file if it doesn't already exist
designfile=designdir+'/plateDesign-'+ $
           string(designid, f='(i6.6)')+'.par'
npointings= long(default.npointings)
nextrafibers=lonarr(npointings)

;; Design the plate if "clobber" is not set or if the output file doesn't exist.
if (keyword_set(clobber) OR ~file_test(designfile)) then begin

    ;; The algorithm to assign fibers to targets.
    ;; If any fibers remain unassigned, add additional targets to
    ;; the list to use the remaining fibers. Initialise the flag
    ;; that indicates this to start the loop.
    needmorefibers=1

    while(keyword_set(needmorefibers) gt 0) do begin

        ;; Initialize design structure, including a center hole
        if(~keyword_set(omit_center)) then $
          design=design_blank(/center)
        design.epoch= epoch
        
        ;; What instruments are being used, and how many science,
        ;; standard and sky fibers do we assign to each?
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
          collectfactor= 10L
        fibercount= {instruments:instruments, $
                     targettypes:targettypes, $
                     ntot:ntot, $
                     nused:nused, $
                     ncollect:ntot*collectfactor}

        ;; Sanity check known instruments 
        iboss= where(strupcase(fibercount.instruments) eq 'BOSS', nm)
        if(nm gt 0) then begin
            if(nm gt 1) then $
              message, 'Only expect one instance of BOSS in instruments!'
            ntotboss= long(total(fibercount.ntot[iboss,*,*,*]))
            if(ntotboss ne 1000) then $
              message, 'Expect a total of 1000 fibers for BOSS'
        endif
        isdss= where(strupcase(fibercount.instruments) eq 'SDSS', nm)
        if(nm gt 0) then begin
            if(nm gt 1) then $
              message, 'Only expect one instance of SDSS in instruments!'
            ntotsdss= long(total(fibercount.ntot[isdss,*,*,*]))
            if(ntotsdss ne 640) then $
              message, 'Expect a total of 640 fibers for SDSS'
        endif
        imarvels= where(strupcase(fibercount.instruments) eq 'MARVELS', nm)
        if(nm gt 0) then begin
            if(nm gt 1) then $
              message, 'Only expect one instance of MARVELS in instruments!'
            ntotmarvels= long(total(fibercount.ntot[imarvels,*,*,*]))
            if(ntotmarvels ne 60 and ntotmarvels ne 120) then $
              message, 'Expect a total of 60 or 120 fibers for MARVELS'
        endif
        
        ;; What conditions on fiber placement exist for each instrument?
        minstdinblock=lonarr(ninstruments) ;; how many standards per block?
        maxstdinblock=lonarr(ninstruments) ;; how many standards per block?
        minskyinblock=lonarr(ninstruments) ;; how many skies per block?
        maxskyinblock=lonarr(ninstruments) ;; how many skies per block?
        for iinst=0L, ninstruments-1L do begin
            
            ;; get values for the sky 
            minmaxinblock, default, definition, instruments[iinst], $
              'sky', mininblock=minsky, maxinblock=maxsky
            minskyinblock[iinst]=minsky
            maxskyinblock[iinst]=maxsky
            
            ;; get values for the standards
            minmaxinblock, default, definition, instruments[iinst], $
              'std', mininblock=minstd, maxinblock=maxstd
            minstdinblock[iinst]=minstd
            maxstdinblock[iinst]=maxstd
            
        endfor
        
        ;; For each class of input priorities, run plate_assign 
        ;; Note input files root path is $PLATELIST_DIR/inputs
    
        ;; first, convert inputs into priority list
        ninputs= long(definition.ninputs)
        splog, 'Reading input files'
        if(ninputs gt 0) then begin
            hdrs=ptrarr(ninputs)
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
                    itag=tag_indx(definition, $
                                  'plateInput'+strtrim(string(k+1),2))
                    if(itag eq -1) then $
                      message, 'no plateInput'+strtrim(string(k+1),2)+ $
                               ' param set'
                    infile=getenv('PLATELIST_DIR')+ $
                           '/inputs/'+definition.(itag)
                    splog, 'Reading '+infile
                    tmp_targets= yanny_readone(infile, hdr=hdr, /anon)
                    if(n_tags(tmp_targets) eq 0) then $
                      message, 'empty plateInput file '+infile
                    hdrs[k]=ptr_new(hdr)
                    hdrstr=lines2struct(hdr)
                    
                    ;; check data type of ra and dec -- abort if they are not
                    ;; typed double
                    if(size(tmp_targets[0].ra, /tname) ne 'DOUBLE' OR $
                       size(tmp_targets[0].dec, /tname) ne 'DOUBLE') then begin
                        message, $
                          'Aborting: RA and Dec MUST be typed as '+ $
                          'double precision!'
                    endif
                    
                    ;; convert target information to design structure
                    ;; (record which plate input file this came from)
                    target2design, definition, default, tmp_targets, $
                                   tmp_design, info=hdrstr
                    tmp_design.iplateinput= k+1L

                    if(n_tags(new_design) eq 0) then begin
                        ifirst= [0]
                        new_design=tmp_design 
                    endif else begin
                        ifirst= [ifirst, n_elements(new_design)]
                        new_design=[new_design, tmp_design]
                    endelse
                endfor

                ;; apply proper motions to the designs
                splog, 'Applying proper motions'
                design_pm, new_design, toepoch=epoch
                
                ;; assign holes to each plateInput file
                splog, 'Assigning holes (checking geometric constraints)'
                plate_assign, definition, default, fibercount, design, $
                              new_design, seed=seed, nextra=nextrafibers

                ;; if first entry is a conflict, AND this is highest
                ;; priority level, that is fishy: flag a warning
                for j=0L, n_elements(ifirst)-1L do begin
                    if(new_design[ifirst[j]].conflicted gt 0 and $
                       i eq 0) then begin
                        plate_log, plateid, $
                          'WARNING: First target in a file conflicted '+ $
                          'with center!'
                    endif
                endfor
                
                ;; output results for this set
                splog, 'Writing results to the plateInput-output file(s)'
                iplate=(uniqtag(new_design, 'iplateinput')).iplateinput
                for j=0L, n_elements(iplate)-1L do begin
                    ithis= where(new_design.iplateinput eq iplate[j], nthis)
                    if(nthis gt 0) then begin
                        outstr= new_design[ithis]
                        pdata= ptr_new(outstr)
                        itag=tag_indx(definition, 'plateInput'+ $
                                      strtrim(string(iplate[j]),2))
                        if(itag eq -1) then $
                          message, 'no plateInput'+ $
                                   strtrim(string(iplate[j]+1),2)+ $
                                   ' param set'
                        infile=getenv('PLATELIST_DIR')+ '/inputs/'+ $
                               definition.(itag)
                        filebase= (stregex(infile, '.*\/([^/]*)\.par$', $
                                           /extr, /sub))[1]
                        yanny_write, designdir+'/'+filebase+'-output.par', $
                                     pdata, hdr=(*hdrs[iplate[j]-1])
                        ptr_free, pdata
                    endif
                endfor
                
                istart=iend+1L
            endfor
        endif
            
        ;; Find guide fibers and assign them (if we're supposed to)
        ;; Make sure to assign proper guides to each pointing
        if(~keyword_set(omit_guides)) then begin
            for pointing=1L, npointings do begin
                iguidenums= $
                  tag_indx(default, 'guideNums'+strtrim(string(pointing),2))
                if(iguidenums eq -1) then $
                  message, 'Must specify guide fiber numbers for pointing '+ $
                           strtrim(string(pointing),2)
                guidenums=long(strsplit(default.(iguidenums),/extr))
                splog, 'Finding guides for pointing #'+ $
                  strtrim(string(pointing),2)
                guide_design= plate_guide(definition, default, pointing, $
                                          epoch=epoch)
                if(n_tags(guide_design) gt 0) then begin
                    splog, 'Applying proper motions for pointing #'+ $
                      strtrim(string(pointing),2)
                    design_pm, guide_design, toepoch=epoch
                    splog, 'Assigning guides to fibers for pointing #'+ $
                      strtrim(string(pointing),2)
                    plate_assign_guide, definition, default, design, $
                      guide_design, pointing, guidenums=guidenums 
                endif else begin
                    message, 'there are no guide fibers! aborting!'
                endelse
            endfor
        endif
    
        ;; Assign standards 
        for pointing=1L, npointings do begin
            for offset=0L, noffsets do begin
                for iinst=0L, ninstruments-1L do begin
    
                    ;; get appropriate list of standards, and apply
                    ;; proper motions
                    splog, 'Finding standards for pointing #'+ $
                      strtrim(string(pointing),2)+', offset #'+ $
                      strtrim(string(offset),2)
                    sphoto_design= plate_standard(definition, default, $
                                                  instruments[iinst], $
                                                  pointing, offset)
                    
                    if(n_tags(sphoto_design) gt 0) then begin

                        ;; apply proper motions
                        design_pm, sphoto_design, toepoch=epoch

                        ;; assign, applying constraints imposed in the
                        ;; "FIBERID_[INSTRUMENT]" procedure; this code
                        ;; slowly increases number of considered targets 
                        ;; until constraints are satisfied; because
                        ;; pointing and offsets are considered separately,
                        ;; this does not constitute a guarantee on the
                        ;; final design
                        splog, 'Assigning initial fibers for standards in '+ $
                          'pointing #'+strtrim(string(pointing),2)+ $
                          ', offset #'+strtrim(string(offset),2)
                        if(minstdinblock[iinst] gt 0) then begin
                            plate_assign_constrained, definition, default, $
                              instruments[iinst], $
                              'standard', fibercount, pointing, offset, $
                              design, sphoto_design, seed=seed, $
                              minstdinblock=minstdinblock[iinst], $
                              minskyinblock=minskyinblock[iinst], $
                              maxskyinblock=maxskyinblock[iinst], $
                              /nosky, /noscience
                        endif else begin
                            plate_assign, definition, default, fibercount, $
                              design, sphoto_design, seed=seed, $
                              nextra=nextrafibers
                        endelse
                    endif 
                endfor
            endfor 
        endfor
        
        ;; Find sky fibers and assign them
        for pointing=1L, npointings do begin
            for offset=0L, noffsets do begin
                for iinst=0L, ninstruments-1L do begin
                    splog, 'Finding skies for pointing #'+ $
                      strtrim(string(pointing),2)+', offset #'+ $
                      strtrim(string(offset),2)
                    sky_design= plate_sky(definition, default, $
                                          instruments[iinst], pointing, $
                                          offset, seed=seed)
                    if(n_tags(sky_design) gt 0) then begin

                        ;; set epoch arbitarily current
                        sky_design.epoch=epoch

                        ;; assign, applying constraints imposed in the
                        ;; "FIBERID_[INSTRUMENT]" procedure; this code
                        ;; slowly increases number of considered targets 
                        ;; until constraints are satisfied; because
                        ;; pointing and offsets are considered separately,
                        ;; this does not constitute a guarantee on the
                        ;; final design
                        splog, 'Assigning initial fibers for skies in '+ $
                          'pointing #'+strtrim(string(pointing),2)+ $
                          ', offset #'+strtrim(string(offset),2)
                        plate_assign_constrained, definition, default, $
                          instruments[iinst], $
                          'sky', fibercount, pointing, offset, design, $
                          sky_design, seed=seed, $
                          minstdinblock=minstdinblock[iinst], $
                          minskyinblock=minskyinblock[iinst], $
                          maxskyinblock=maxskyinblock[iinst], $
                          /nostd, /noscience
                    endif
                endfor 
            endfor 
        endfor
        
        ;; Check for extra fibers
        iunused=where(fibercount.nused lt fibercount.ntot, nunused)
        if(nunused gt 0) then begin
        nused=lonarr(ninstruments, ntargettypes, npointings, noffsets+1L)
            splog, 'Unused fibers found.' 
            for pointing=1L, npointings do begin
                for offset=0L, noffsets do begin
                    for iinst=0L, ninstruments-1L do begin
                        for itarg=0L, ntargettypes-1L do begin
                            nu=fibercount.nused[iinst,itarg, pointing-1,offset] 
                            nt=fibercount.ntot[iinst,itarg, pointing-1,offset] 
                            if(nu lt nt) then $
                              splog, '- only '+strtrim(string(nu),2)+'/'+ $
                              strtrim(string(nt),2)+' assigned for '+ $
                              instruments[iinst]+' '+targettypes[itarg]+ $
                              ' targets (pointing='+ $
                              strtrim(string(pointing),2)+', offset='+ $
                              strtrim(string(offset),2)+')'
                        endfor
                    endfor
                endfor
            endfor
            
            splog, 'Not completing plate design '+strtrim(string(designid),2)
            plate_log, plateid, 'Unused fibers found. Please specify more '+ $
              'targets!'
            plate_log, plateid, 'Not completing plate design '+ $
              strtrim(string(designid),2)
            if(keyword_set(debug) eq false) then return else stop
        endif
    
        ;; Find light traps and assign them
        ;; (Note that assignment here checks for conflicts:
        ;; so if a light trap overlaps an existing hole, the
        ;; light trap is not drilled)
        splog, 'Finding bright stars for light traps'
        if(~keyword_set(omit_traps)) then begin
            for pointing=1L, npointings do begin
                for offset=0L, noffsets do begin
                    ;; find bright stars
                    trap_design= plate_trap(definition, default, $
                                            pointing, offset)
                    
                    ;; add them if they don't conflict
                    if(n_tags(trap_design) gt 0) then begin
                        design_pm, trap_design, toepoch=epoch
                        for i=0L, n_elements(trap_design)-1L do begin
                            trap_design[i].conflicted= $
                              check_conflicts(design, trap_design[i])
                            if(trap_design[i].conflicted eq false) then $
                              design= [design, trap_design[i]]
                        endfor
                    endif
                endfor
            endfor
        endif
            
        ;; Assign fiberid's for each instrument
        keep=lonarr(n_elements(design))+1L
        needmorefibers=0
        for iinst=0L, ninstruments-1L do begin
            icurr= where(design.holetype eq instruments[iinst], ncurr)
    
            if(ncurr gt 0) then begin
                splog, 'Final fiber assignment for '+instruments[iinst]
                keep[icurr]=0L
                fiberids= call_function('fiberid_'+instruments[iinst], $
                                        default, fibercount, design[icurr], $
                                        minstdinblock=minstdinblock[iinst], $
                                        minskyinblock=minskyinblock[iinst], $
                                        maxskyinblock=maxskyinblock[iinst], $
                                        block=block, $
                                        respect_fiberid=respect_fiberid)
                design[icurr].fiberid= fiberids
                design[icurr].block= block
                for ip=1L, npointings do begin 
                    iassigned= where(design[icurr].fiberid ge 1 AND $
                                    design[icurr].pointing eq ip, nassigned)
                    if(nassigned gt 0) then $
                        keep[icurr[iassigned]]=1L
                    if(nassigned ne $
                       long(total(fibercount.ntot[iinst,*,ip-1,*]))) $
                    then begin
                        splog, 'Some fibers not assigned to targets! ' 
                        plate_log, plateid, $
                          'Some fibers not assigned to targets! ' 
                        if(keyword_set(debug) eq false) then begin
                            if(keyword_set(replace_fibers) eq false) then begin
                                msg= 'Not completing plate design '+ $
                                    strtrim(string(designid),2) + $
                                  '. Rerun with keyword "replace_fibers" '+ $
                                  'to attempt to assign unallocated fibers.'
                                splog, msg
                                plate_log, plateid, msg
                                return
                            endif else begin
                                nextrafibers[ip-1]=nextrafibers[ip-1]+1L
                                needmorefibers=1
                            endelse
                        endif else begin
                            message, '/debug set, so stopping'
                        endelse
                    endif 
                endfor ;; end loop over pointings
            endif 
        endfor ;; end loop over instruments
        ikeep=where(keep gt 0, nkeep)
        design=design[ikeep]
    
        ;; Write out plate assignments to 
        ;;   $PLATELIST_DIR/designs/plateDesign-[designid] file
        if(keyword_set(needmorefibers) eq false) then begin
            splog, 'Writing plateDesign file.'

            ;; sanity check EPOCHs
            ibad=where(design.epoch lt 1900. OR design.epoch gt 2100., nbad)
            if(nbad gt 0) then $
              message, 'EPOCH found <1900 or >2100, not realistic!'

            ;; get median reddening
            iobj= where(strupcase(design.targettype) eq 'SCIENCE', nobj)
            if(nobj eq 0) then begin
                plate_log, plateid, 'WARNING: no science targets!'
                iobj= lindgen(n_elements(design))
            endif
            extinct= reddenmed(design[iobj].target_ra, design[iobj].target_dec)
            
            ;; set SOS-style magnitude (lots of logic in there!)
            design.mag= plate_mag(design, default=default)

            pdata= ptr_new(design)
            spawn, 'mkdir -p '+designdir
            hdrstr=struct_combine(default, definition)
            outhdr=struct2lines(hdrstr)
            outhdr=[outhdr, $
                    'reddeningMed '+string(extinct,format='(5f8.4)'), $
                    'tileId '+strtrim(string(plan.tileid),2), $
                    'theta 0 ', $
                    'platerun '+plan.platerun, $
                    'platedesign_version '+platedesign_version()]
            if(tag_indx(hdrstr, 'POINTING_NAME') eq -1) then $
              outhdr= [outhdr, $
                       'pointing_name A B C D E F']
        
            fixcaps=['raCen', 'decCen', 'plateId', 'tileId']
            for j=0L, n_elements(outhdr)-1L do begin 
                words= strsplit(outhdr[j], /extr) 
                for k=0L, n_elements(fixcaps)-1L do begin 
                    if(strupcase(words[0]) eq strupcase(fixcaps[k])) then $
                      words[0]=fixcaps[k] 
                endfor 
                outhdr[j]=strjoin(words, ' ') 
            endfor

            yanny_write, designfile, pdata, hdr=outhdr
            ptr_free, pdata
        endif
        
    endwhile ;; end loop if fibers unassigned

endif ;; end of clobber & file exists tests

;; ----------------------------------------
;; Convert plateDesign to plateHoles
;; ----------------------------------------
splog, 'Writing plateHoles'
plate_holes, designid, plateid, ha, temp, epoch

;; ----------------------------------------
;; Produce plugfiles of desired style
;; ----------------------------------------
splog, 'Writing plug mapping files'
if(tag_exist(default, 'plugmapstyle') eq false) then $
  plugmapstyle='plplugmap' $
else $
  plugmapstyle= default.plugmapstyle
call_procedure, 'plugfile_'+plugmapstyle, plateid

;; ----------------------------------------
;; Generate platelines files (SEGUE-2 only)
;; ----------------------------------------
if (strpos(strlowcase(plan.platerun), 'segue2') gt -1) then begin
	
	platelines_segue2, plateid

	spawn, 'mkdir -p '+ getenv('PLATELIST_DIR') + '/runs/' + plan.platerun

	spawn, 'cp -f ' + plate_dir(plateid) + '/plateLines*.ps ' + $
		getenv('PLATELIST_DIR') + '/runs/' + plan.platerun + '/'
end

succeeded = true

return
end
