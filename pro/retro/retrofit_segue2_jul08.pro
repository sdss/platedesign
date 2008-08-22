;+
; NAME:
;   retrofit_segue2_jul08
; PURPOSE:
;   Retrofit plPlugMapP files (Aug 2008)
; CALLING SEQUENCE:
;   retrofit_segue2_jul08
; COMMENTS:
;   Retrofits the original plate drilling files for this set of plate
;    runs: XXX,
;   What happened was that the platedesign code was meant to propagate
;    the fibermag input into the "mag" section of the plPlugMap files. 
;   In order to handle this difficulty, we here use the
;    plateHolesSorted file to map the holes back into the original
;    plateInput file, extract the fibermag, and use it in a new
;    plPlugMapP file.
;   The old file is first moved into 'plPlugMapP-????-orig.par'
; REVISION HISTORY:
;   20-Aug-2008  MRB, NYU
;-
;------------------------------------------------------------------------------
pro retrofit_segue2_jul08

plateruns=['jul08c', 'jul08e', 'jul08f']

plans= yanny_readone(getenv('PLATELIST_DIR')+'/platePlans.par')
for i=0L, n_elements(plans)-1L do begin
    ii=where(plans[i].platerun eq plateruns, nii)
    ;; act if it is in one of the affected plate runs
    if(nii gt 0) then begin
        plateid= plans[i].plateid
        platestr= string(plateid, f='(i4.4)')
        platedir= plate_dir(plateid)
        sortedplatefile= platedir+'/plateHolesSorted-'+ $
                         strtrim(string(f='(i6.6)',plateid),2)+'.par'
        plugmapfile= getenv('PLATELIST_DIR')+'/runs/'+plans[i].platerun+ $
                     '/plPlugMapP-'+platestr+'.par'
        origplugmapfile= getenv('PLATELIST_DIR')+'/runs/'+plans[i].platerun+ $
                         '/plPlugMapP-'+platestr+'-orig.par'
        
        ;; get definition and plateInput files
        definitiondir=getenv('PLATELIST_DIR')+'/definitions/'+ $
                      string(f='(i4.4)', (plans[i].designid/100L))+'XX'
        definitionfile=definitiondir+'/'+ $
                       'plateDefinition-'+ $
                       string(f='(i6.6)', plans[i].designid)+'.par'
        dum= yanny_readone(definitionfile, hdr=hdr)
        definition= lines2struct(hdr)
        plinput= yanny_readone(getenv('PLATELIST_DIR')+ $
                               '/inputs/'+definition.plateinput1)

        if(file_test(origplugmapfile)) then $
          message, 'already ran retrofit!'

        spawn, 'cp '+plugmapfile+' '+origplugmapfile
        
        if(NOT file_test(origplugmapfile)) then $
          message, 'could not move old file!'

        holes= yanny_readone(sortedplatefile)
        plplug= yanny_readone(origplugmapfile, hdr=hdr)

        isdss=where(holes.run gt 0, nsdss) 
        if(nsdss eq 0) then $
          message, 'not SDSS data, why are you retrofitting?'
        
        for i=0L, n_elements(holes)-1L do begin
            iin= where(holes[i].targetids eq plinput.targetids, nin)
            if(nin eq 0) then begin
                if(holes[i].targetids ne 'NA') then $
                  message, 'error in targetids'
            endif else begin
                plplug[i].mag= plinput[iin[0]].fibermag
            endelse
        endfor
        
        pdata= ptr_new(plplug)
        yanny_write, plugmapfile, pdata, hdr=hdr
        
        stop
    endif
endfor


return
end
