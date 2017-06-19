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
;         plate before running.
; REVISION HISTORY:
;   7-May-2008 MRB, NYU
;  23-Jan-2008 Demitri Muna, NYU, added superclobber option
;   1-Sep-2010 Demitri Muna, NYU, Adding file test before opening files.
;   3-Jan-2011 Demitri Muna, NYU, Adding color_string output so errors stand out.
;-
;------------------------------------------------------------------------------
;
; Gets position in definition structure for a given input number
function itag_input, definition, iplateinput, inputtype=inputtype

platetag= tag_indx(definition, $
                   'plateInput'+strtrim(string(iplateinput),2))
skytag= tag_indx(definition, $
                 'skyInput'+strtrim(string(iplateinput),2))
if(platetag eq -1 and skytag eq -1) then $
  message, 'no plateInput'+strtrim(string(iplateinput),2)+ $
  ' or skyInput'+strtrim(string(iplateinput),2)+' param set'
if(platetag ge 0 and skytag ge 0) then $
  message, 'both plateInput'+strtrim(string(iplateinput),2)+ $
  ' or skyInput'+strtrim(string(iplateinput),2)+' params set; must '+ $
  'set one or other but not both'
if(platetag ge 0) then begin
    itag=platetag
    inputtype='plateInput'
endif 
if(skytag ge 0) then begin
    itag=skytag
    inputtype='skyInput'
endif 

return, itag

end
;
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

  plate_obj = obj_new('hashtable')
  plate_obj->add, 'id', plateid

  splog, '================================================'
  splog, 'Working on plateid: '+ color_string(strtrim(string(plateid),2), 'green', 'bold')
  splog, '================================================'

;; read plan file for settings
  platePlans_file = getenv('PLATELIST_DIR')+'/platePlans.par'
  check_file_exists, platePlans_file, plateid=plateid
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
	 obj_destroy, plate_obj
     return
  endif

  plan=plans[iplate]
  designid=plan.designid
  ha=plan.ha
  temp=plan.temp
  epoch=plan.epoch

  plate_obj->add, 'plan', plan
  plate_obj->add, 'designid', designid

  ;; sanity check for other plates with this designid
  iother= where(plans.designid eq designid AND $
                plans.plateid ne plateid, nother)
  if(nother gt 0) then begin
      ibad= where(plans[iother].racen ne plan.racen OR $
                  plans[iother].deccen ne plan.deccen OR $
                  plans[iother].platedesignversion ne plan.platedesignversion OR $
                  plans[iother].survey ne plan.survey OR $
                  plans[iother].programname ne plan.programname OR $
                  plans[iother].drillstyle ne plan.drillstyle, $
                  nbad)
      if(nbad gt 0) then begin 
        message, color_string('Inconsistency in plan file between this plate and previous from same designid!', 'red', 'bold')
		STOP
	   endif
  endif

;; Check for correct drill style. Valid values:
;;
;; - "boss" indicates a BOSS cart
;; - "bright" indicates an APOGEE-only plate
;; - "manga" indicates a MaNGA/APOGEE or APOGEE/MaNGA plate
if (strpos(plan.platerun, 'manga') gt -1) then begin
    ;; This is a MaNGA plate - check drillstyle which must be 'manga'
    if (strmatch(plan.drillstyle, 'manga') eq 0) then $
        message, color_string('The drill style for a MaNGA plate must be "manga", but is "' + plan.drillstyle + '".', 'red', 'bold')
endif

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

  plate_obj->add, 'platedir', platedir
  plate_obj->add, 'designdir', designdir

;; Delete any output files from a previous run
  if (keyword_set(superclobber)) then begin
     old_files = file_search(designdir + '/*', count=old_files_count)
     if (old_files_count gt 0) then file_delete, old_files

     old_files = file_search(platedir + '/*', count=old_files_count)
     if (old_files_count gt 0) then file_delete, old_files
     
     old_files = file_search(getenv('PLATELIST_DIR') + '/runs/' $
          + plan.platerun + '/*' + strtrim(plateid,2) + '*', count=old_files_count)
     if (old_files_count gt 0) then file_delete, old_files
  endif

;; Always delete the log file when rerunning a plate
  old_log = file_search(getenv('PLATELIST_DIR') + '/logs/platelog_' + $
                        strtrim(string(plateid),2) + '.log', count=old_log_count)
  if (old_log_count eq 1) then file_delete, old_log

;; Read in the plate definition file
;; Should be at (with did = designid)
;;   $PLATELIST_DIR/definitions/[did/100]00/plateDefinition-[did].par
;; as in 
;;   $PLATELIST_DIR/definitions/001000/plateDefinition-001045.par
;  definitiondir=getenv('PLATELIST_DIR')+'/definitions/'+ $
;                string(f='(i4.4)', (designid/100L))+'XX'
;  definitionfile=definitiondir+'/'+ $
;                 'plateDefinition-'+ $
;                 string(f='(i6.6)', designid)+'.par'
;  check_file_exists, definitionfile, plateid=plateid
;  dum= yanny_readone(definitionfile, hdr=hdr)
;  if(~keyword_set(hdr)) then begin
;     message, 'Error: plateDefinition file not found: ' + $
;              definitionfile + ' (plate id: (' + string(plateid) + ')'
;  endif
;  definition= lines2struct(hdr)
definition = plate_definition(designid=designid)

  plate_obj->add, 'definition', definition

  if(tag_indx(definition, 'platedesignversion') ge 0) then begin
      if(definition.platedesignversion ne plan.platedesignversion) then $
        message, color_string('Plan file plateDesignVersion ("' + strtrim(string(plan.platedesignversion),2) + $
					'") inconsistent with (obsolete) definition file value ("' + strtrim(string(definition.platedesignversion),2) + '")', 'red', 'bold')
  endif

;; Read in the plate defaults file
;; (reset any tags that are overwritten by plateDefinition)
  defaultdir= getenv('PLATEDESIGN_DIR')+'/defaults'
  defaultfile= defaultdir+'/plateDefault-'+ $
               definition.platetype+'-'+ $
			   plan.plateDesignVersion+'.par'
  check_file_exists, defaultfile, plateid=plateid             
  dum= yanny_readone(defaultfile, hdr=hdr)
  if(~keyword_set(hdr)) then begin
     message, color_string('no plateDefaults file '+defaultfile, 'red', 'bold')
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

  plate_obj->add, 'default', default

;; see if we should select guides at highest priority
  if(tag_exist(default, 'GUIDES_FIRST')) then begin
     guides_first= long(default.guides_first)
  endif
  if(tag_exist(definition, 'GUIDES_FIRST')) then begin
     guides_first= long(definition.guides_first)
  endif

  if(tag_exist(default, 'GUIDE_LAMBDA_EFF')) then begin
      guide_lambda_eff=float(default.guide_lambda_eff)
  endif

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

;; set center post size
  if(tag_exist(default, 'CENTER_DIAMETER')) then begin
     center_diameter= float(default.center_diameter)
 endif

;; tag for acquisition camera
  if(tag_exist(default, 'ACQUISITION_CAMERA')) then begin
     acquisition_camera= long(default.acquisition_camera)
 endif

;; Get number of offsets, instruments, target types
  noffsets= long(default.noffsets) 
  instruments= strsplit(default.instruments, /extr)
  ninstruments= n_elements(instruments)
  targettypes= strsplit(default.targettypes, /extr)
  ntargettypes= n_elements(targettypes)

;; Now do some sanity checks
  racen= double((strsplit(definition.racen,/extr))[0])
  deccen= double((strsplit(definition.deccen,/extr))[0])
  if(abs(racen-plan.racen) gt 1./3600. OR $
     abs(deccen-plan.deccen) gt 1./3600.) then begin
     message, color_string('platePlans.par file disagrees with plateDefinition file on plate center', 'red', 'bold')
  endif
  if(designid ne long(definition.designid)) then begin
     message, color_string('plateDefinition file has wrong designid', 'red', 'bold')
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
  nextrafibers=lonarr(ninstruments, npointings)

  plate_obj->add, 'designfile', designfile

;; Design the plate if "clobber" is not set or if the output file doesn't exist.
  if (keyword_set(clobber) OR ~file_test(designfile)) then begin

     ;; The algorithm to assign fibers to targets.
     ;; If any fibers remain unassigned, add additional targets to
     ;; the list to use the remaining fibers. Initialise the flag
     ;; that indicates this to start the loop.
     needmorefibers=1

     while(keyword_set(needmorefibers) gt 0) do begin

        ;; Initialize design structure, including a center hole
        if(~keyword_set(omit_center)) then begin
            design=design_blank(/center)
            if(keyword_set(guide_lambda_eff)) then $
              design.lambda_eff = guide_lambda_eff
            if(keyword_set(center_diameter)) then $
              design.diameter = center_diameter
            design.epoch= epoch
        endif 

        if(keyword_set(acquisition_camera)) then begin
            if(n_tags(design) gt 0) then $
              message, 'Acquisition cameras are placed at center - no hole should be present yet'
            design = acquisition(definition, default)
        endif

		;plate_obj->add, 'design', design
        
        ;; What instruments are being used, and how many science,
        ;; standard and sky fibers do we assign to each?
        ntot=lonarr(ninstruments, ntargettypes, npointings, noffsets+1L)
        nused=lonarr(ninstruments, ntargettypes, npointings, noffsets+1L)
        for i=0L, ninstruments-1L do begin
           for j=0L, ntargettypes-1L do begin
              itag= tag_indx(default, 'n'+ $
                             strtrim(string(instruments[i]),2)+ $
                             '_'+strtrim(string(targettypes[j]),2))
              if(itag eq -1) then $
                 message, color_string('must specify n'+ $
                          strtrim(string(instruments[i]),2)+ $
                          '_'+strtrim(string(targettypes[j]),2), 'red', 'bold')
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
              message, color_string('Only expect one instance of BOSS in instruments!','red', 'bold')
           ntotboss= long(total(fibercount.ntot[iboss,*,*,*]))
           if(ntotboss ne 1000) then $
              message, color_string('Expect a total of 1000 fibers for BOSS', 'red', 'bold')
        endif
        isdss= where(strupcase(fibercount.instruments) eq 'SDSS', nm)
        if(nm gt 0) then begin
           if(nm gt 1) then $
              message, color_string('Only expect one instance of SDSS in instruments!', 'red', 'bold')
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
        iapogee= where(strupcase(fibercount.instruments) eq 'APOGEE', nm)
        if(nm gt 0) then begin
           if(nm gt 1) then $
              message, color_string('Only expect one instance of APOGEE in instruments!', 'red', 'bold')
           ntotapogee= long(total(fibercount.ntot[iapogee,*,*,*]))
           if(ntotapogee ne 300) then $
              message, color_string('Expect a total of 300 fibers for APOGEE', 'red', 'bold')
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
        
        ;; Find guide fibers and assign them (if we're supposed to)
        ;; Make sure to assign proper guides to each pointing
        if(keyword_set(omit_guides) eq 0 and $
           keyword_set(guides_first) gt 0) then begin
           for pointing=1L, npointings do begin
              iguidenums= $
                 tag_indx(default, 'guideNums'+strtrim(string(pointing),2))
              if(iguidenums eq -1) then $
                 message, color_string('Must specify guide fiber numbers for pointing '+ $
                          strtrim(string(pointing),2), 'red', 'bold')
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
                 message, color_string('there are no guide fibers! aborting!', 'red', 'bold')
              endelse
           endfor
        endif
        
        
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
              current_inputtype=''
              current_pointing=-1L
              current_offset=-1L
              current_instrument=''
              for j=0L, ncurr-1L do begin
                 k=icurr[j]
                 ;; Get tag number in structure for input file
                 ;; (either skyInput or plateInput)
                 itag= itag_input(definition, k+1, inputtype=inputtype)
                 current_inputtype=inputtype
                 
                 ;; Read in file and header
                 infile=getenv('PLATELIST_DIR')+ $
                        '/inputs/'+definition.(itag)
                 splog, 'Reading input: '+infile
                 check_file_exists, infile, plateid=plateid
                 tmp_targets= yanny_readone(infile, hdr=hdr, /anon)
                 if(n_tags(tmp_targets) eq 0) then $
                    message, 'empty plateInput file '+infile
                 hdrs[k]=ptr_new(hdr)
                 hdrstr=lines2struct(hdr)

                 ;; Make sure for skyInput cases it is the only input
                 ;; at this priority
                 if(inputtype eq 'skyInput') then begin
                     if(ncurr gt 1) then $
                       message, 'Only one skyInput file allowed at a given priority level'
                     current_pointing=hdrstr.pointing
                     current_instrument=hdrstr.instrument
                     ioff= tag_indx(hdrstr, 'OFFSET') 
                     if(ioff ge 0) then $
                       current_offset=hdrstr.(ioff) $
                     else $
                       current_offset=0
                 endif
                 
                 ;; check that if skyInput is set, we are actually
                 ;; looking at sky targets
                 if(current_inputtype eq 'skyInput' and $
                    strlowcase(hdrstr.targettype) ne 'sky') then $
                   message, 'skyInput is being specified for non-sky targettype'
                 
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
              if(current_inputtype eq 'plateInput') then begin
                  splog, 'Assigning holes (checking geometric constraints)'
                  plate_assign, definition, default, fibercount, design, $
                    new_design, seed=seed, nextra=nextrafibers
              endif else if (current_inputtype eq 'skyInput') then begin
                  splog, 'Assigning holes as if these were native platedesign skies'
                  splog, 'Assigning initial fibers for skies in '+ $
                    'pointing #'+strtrim(string(current_pointing),2)+ $
                    ', offset #'+strtrim(string(current_offset),2)
                  iinst= where(instruments eq current_instrument, ninst)
                  if(ninst eq 0) then $
                    message, 'No such instrument '+current_instrument
                  iinst=iinst[0]
                  plate_assign_constrained, default, $
                    instruments[iinst],'sky', fibercount, current_pointing, $
                    current_offset, design, $
                    new_design, seed=seed, minstdinblock=minstdinblock[iinst], $
                    minskyinblock=minskyinblock[iinst], $
                    maxskyinblock=maxskyinblock[iinst], $
                    plate_obj=plate_obj, $
                    /nostd, /noscience, debug=debug
              endif else begin
                  message, 'No such input type '+inputtype
              endelse
                  
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
                    itag= itag_input(definition, iplate)
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
        if(keyword_set(omit_guides) eq 0 and $
           keyword_set(guides_first) eq 0) then begin
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
                       plate_assign_constrained, default, $
                                                 instruments[iinst], $
                                                 'standard', fibercount, pointing, offset, $
                                                 design, sphoto_design, seed=seed, $
                                                 minstdinblock=minstdinblock[iinst], $
                                                 minskyinblock=minskyinblock[iinst], $
                                                 maxskyinblock=maxskyinblock[iinst], $
                                                 /nosky, /noscience, debug=debug
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

                    plate_assign_constrained, default, $
                                              instruments[iinst], $
                                              'sky', fibercount, pointing, offset, design, $
                                              sky_design, seed=seed, $
                                              minstdinblock=minstdinblock[iinst], $
                                              minskyinblock=minskyinblock[iinst], $
                                              maxskyinblock=maxskyinblock[iinst], $
											  plate_obj=plate_obj, $
                                              /nostd, /noscience, debug=debug
                 endif
              endfor 
           endfor 
        endfor

        ;; Check for extra fibers
        iunused=where(fibercount.nused lt fibercount.ntot, nunused)
        if(nunused gt 0) then begin
           nused=lonarr(ninstruments, ntargettypes, npointings, noffsets+1L)
           splog, color_string('Unused fibers found.', 'yellow', 'bold')
           for pointing=1L, npointings do begin
              for offset=0L, noffsets do begin
                 for iinst=0L, ninstruments-1L do begin
                    for itarg=0L, ntargettypes-1L do begin
                       nu=fibercount.nused[iinst,itarg, pointing-1,offset] 
                       nt=fibercount.ntot[iinst,itarg, pointing-1,offset] 
                       if(nu lt nt) then begin
                          msg = '- only '+strtrim(string(nu),2)+'/'+ $
                                 strtrim(string(nt),2)+' assigned for '+ $
                                 instruments[iinst]+' '+targettypes[itarg]+ $
                                 ' targets (pointing='+ $
                                 strtrim(string(pointing),2)+', offset='+ $
                                 strtrim(string(offset),2)+')'
                           splog, color_string(msg, 'yellow', 'bold')
                       endif
                    endfor
                 endfor
              endfor
           endfor
           
           splog, color_string('Not completing plate design '+strtrim(string(designid),2), 'red', 'bold')
           plate_log, plateid, 'Unused fibers found. Please specify more targets!'
           plate_log, plateid, 'Not completing plate design '+ strtrim(string(designid),2)
           if(keyword_set(debug) eq false) then begin
		       obj_destroy, plate_obj
			   return
		   endif else begin
		       stop
		   endelse

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
                                      respect_fiberid=respect_fiberid, $
									  plate_obj=plate_obj, $
                                      all_design=design)
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
                    splog, color_string('Some fibers not assigned to targets! ', 'yellow', 'bold')
                    plate_log, plateid, $
                               'Some fibers not assigned to targets! ' 
                    if(keyword_set(debug) eq false) then begin
                       if(keyword_set(replace_fibers) eq false) then begin
                          msg= 'Not completing plate design '+ $
                               strtrim(string(designid),2) + $
                               '. Rerun with keyword "replace_fibers" '+ $
                               'to attempt to assign unallocated fibers.'
                          splog, color_string(msg, 'red', 'bold')
                          plate_log, plateid, msg
						  obj_destroy, plate_obj
                          return
                       endif else begin
                          nextrafibers[iinst,ip-1]=nextrafibers[iinst,ip-1]+1L
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
           hdrstr=plate_struct_combine(default, definition)
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

  obj_destroy, plate_obj

  return
end
