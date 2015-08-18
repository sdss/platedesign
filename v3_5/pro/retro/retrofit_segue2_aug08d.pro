;+
; NAME:
;   retrofit_segue2_aug08d
; PURPOSE:
;   Retrofit plPlugMapP files (Oct 2008)
; CALLING SEQUENCE:
;   retrofit_segue2_aug08d
; COMMENTS:
;   Retrofits the original plate drilling files for this set of plate
;    runs: aug08d
;   We make sure that the OBJID and primTarget and secTarget columns
;    are filled in appropriately.
;   In order to handle this difficulty, we here use the
;    plateHolesSorted file to map the holes back into the original
;    plateInput file, extract the fibermag, and use it in a new
;    plPlugMapP file.
;   The old file is first moved into 'plPlugMapP-????-orig.par'
; REVISION HISTORY:
;   20-Aug-2008  MRB, NYU
;-
;------------------------------------------------------------------------------
pro retrofit_segue2_aug08d

plateruns=['aug08d']

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

        if(file_test(origplugmapfile) eq 0) then begin
            spawn, 'cp '+plugmapfile+' '+origplugmapfile
            if(NOT file_test(origplugmapfile)) then $
              message, 'could not move old file!'
        endif

        holes= yanny_readone(sortedplatefile)
        plplug= yanny_readone(origplugmapfile, hdr=hdr)

        plplug.objid[0]= holes.run
        plplug.objid[1]= long(holes.rerun)
        plplug.objid[2]= holes.camcol
        plplug.objid[3]= holes.field
        plplug.objid[4]= holes.id
        plplug.primtarget= holes.segue2_target1
        plplug.sectarget= holes.segue2_target2
        
        pdata= ptr_new(plplug)
        yanny_write, plugmapfile, pdata, hdr=hdr
        
    endif
endfor


return
end
