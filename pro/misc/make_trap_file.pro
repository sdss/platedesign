;+
; NAME:
;   make_trap_file 
; PURPOSE:
;   Make a trap file from just a list of RAs and Decs
; CALLING SEQUENCE:
;  make_trap_file, designid, filename, ra, dec
; INPUTS:
;   designid - design ID to write for
;   filename - output file name
;   ra,dec  - coordinates (J2000 deg)
; REVISION HISTORY:
;   26-Sep-2013  MRB, NYU
;-
;------------------------------------------------------------------------------
pro make_trap_file, plateid, filename, ra, dec

  platePlans_file = getenv('PLATELIST_DIR')+'/platePlans.par'
  plans= yanny_readone(platePlans_file)

  iplate=where(plans.plateid eq plateid, nplate)

  if(nplate gt 1) then begin
     message, 'Error: More than one entry for plateid (' + string(plateid) + $
              ') found in ' + platePlans_file + '.'
  endif
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
  pointing=1
  offset=0

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
  
  plate_center, definition, default, pointing, offset, $
                racen=racen, deccen=deccen
  
  trap_design= replicate(design_blank(/trap), n_elements(ra))
  trap_design.target_ra= ra
  trap_design.target_dec= dec
  trap_design.pointing= pointing
  trap_design.offset= offset
  trap_design.pmra= 0.
  trap_design.pmdec= 0.
  trap_design.epoch= default_epoch()
  
  plate_ad2xy, definition, default, pointing, offset, $
               trap_design.target_ra, $
               trap_design.target_dec, $
               trap_design.lambda_eff, $
               xf=xf, yf=yf
  trap_design.xf_default=xf
  trap_design.yf_default=yf
  
  pdata= ptr_new(trap_design)
  hdrstr=plate_struct_combine(default, definition)
  outhdr=struct2lines(hdrstr)
  outhdr=[outhdr, $
          'pointing '+strtrim(string(pointing),2), $
          'offset '+strtrim(string(offset),2), $
          'platedesign_version '+platedesign_version()]
  if(keyword_set(rerun)) then $
     outhdr=[outhdr, 'rerun '+strtrim(string(rerun),2)]
  yanny_write, filename, pdata, hdr=outhdr
  ptr_free, pdata

end
