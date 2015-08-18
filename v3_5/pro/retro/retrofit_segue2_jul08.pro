;+
; NAME:
;   retrofit_segue2_jul08
; PURPOSE:
;   Retrofit plPlugMapP files (Aug 2008)
; CALLING SEQUENCE:
;   retrofit_segue2_jul08
; COMMENTS:
;   Retrofits the original plate drilling files for this set of plate
;    runs: jul08c, jul08e, jul08f
;   What happened was that the platedesign code was meant to propagate
;    the fibermag input into the "mag" section of the plPlugMap files. 
;   We also copy over the objid and primTarget and secTarget from 
;    segue2_target1, segue2_target2
;   In order to handle this difficulty, we here use the
;    plateHolesSorted file to map the holes back into the original
;    plateInput file, extract the fibermag, and use it in a new
;    plPlugMapP file.
;   The old file is first moved into 'plPlugMapP-????-orig.par'
;   3102 had to be treated as a special case, since we appear somehow
;    to have "lost" the design info for that.
; REVISION HISTORY:
;   20-Aug-2008  MRB, NYU
;-
;------------------------------------------------------------------------------
pro retrofit_segue2_jul08

plateruns=['jul08e', 'jul08c', 'jul08f']

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

        if(file_test(origplugmapfile) eq 0) then begin
            spawn, 'cp '+plugmapfile+' '+origplugmapfile
            if(NOT file_test(origplugmapfile)) then $
              message, 'could not move old file!'
        endif

        holes= yanny_readone(sortedplatefile)
        plplug= yanny_readone(origplugmapfile, hdr=hdr)

        if(n_tags(holes) gt 0) then begin
            isdss=where(holes.run gt 0, nsdss) 
            if(nsdss eq 0) then $
              message, 'not SDSS data, why are you retrofitting?'
        endif
        
        for j=0L, n_elements(holes)-1L do begin
            if(n_tags(holes) gt 0) then begin
                iin= where(holes[j].targetids eq plinput.targetids, nin)
            endif else begin
                nin=n_elements(plinput)
                iin= lindgen(nin)
            endelse
            if(nin eq 0) then begin
                if(holes[j].targetids ne 'NA') then $
                  message, 'error in targetids'
            endif else begin
                ido=0L
                if(nin gt 0) then begin
                    spherematch, plplug[j].ra, plplug[j].dec, $
                                 plinput[iin].ra, plinput[iin].dec, $
                                 1./3600., m1, m2, d12
                    ido=m2[0]
                endif
                if(ido eq -1 AND n_tags(holes) ne 0) then $
                  message, 'mismatch in bad place!'
                if(ido ne -1) then begin
                    plplug[j].objid[0]= plinput[iin[ido]].run
                    plplug[j].objid[1]= long(plinput[iin[ido]].rerun)
                    plplug[j].objid[2]= plinput[iin[ido]].camcol
                    plplug[j].objid[3]= plinput[iin[ido]].field
                    plplug[j].objid[4]= plinput[iin[ido]].id
                    plplug[j].mag= plinput[iin[ido]].fibermag
                    plplug[j].primtarget= plinput[iin[ido]].segue2_target1
                    plplug[j].sectarget= plinput[iin[ido]].segue2_target2
                endif
            endelse
        endfor
        
        pdata= ptr_new(plplug)
        yanny_write, plugmapfile, pdata, hdr=hdr
        
    endif
endfor


return
end
