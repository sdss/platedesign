;+
; NAME:
;   copydef
; PURPOSE:
;   Copy one definition file to another
; CALLING SEQUENCE:
;   copydef, oldid, newid [, reset=, /clobber]
; INPUTS:
;   oldid - [N] old ID number(s)
;   newid - [N] new ID number(s) (won't overwrite unless /clobber set)
; OPTIONAL KEYWORDS:
;   /clobber - overwrite new ID design file if it exists
; OPTIONAL INPUTS:
;   reset - [M] string header array; replace any already
;           listed keywords and add new ones
; COMMENTS:
;   Resets the "designid" field appropriately.
;   Also, any keyword set in "reset" input is added to
;     the new design file (replacing the old one if it 
;     already exists. 
;   Won't overwrite existing file under newid unless 
;     /clobber is set
;   Checks with platePlans.par to make sure that the new
;     designID exists (spawns warning) and if so that RA 
;     and Dec make sense (spawns error and doesn't create
;     new definition file)
; REVISION HISTORY:
;   1-Oct-2009 MRB, NYU 
;-
pro copydef, oldid, newid, reset=reset, clobber=clobber

if(n_elements(oldid) ne n_elements(newid)) then begin
    splog, 'OLDID and NEWID must have same # of elements!'
    return
endif

for i=0L, n_elements(reset)-1L do begin
    words= strsplit(reset[i], /extr)
    if(strupcase(words[0]) eq 'RACEN' OR $
       strupcase(words[0]) eq 'DECCEN') then begin
        splog, 'Do NOT try to reset RACEN or DECCEN. Aborting'
        return
    endif
endfor

plans= yanny_readone(getenv('PLATELIST_DIR')+'/platePlans.par')
if(n_tags(plans) eq 0) then $
  message, 'Could not find platePlans.par'

for i=0L, n_elements(oldid)-1L do begin
    olddir= getenv('PLATELIST_DIR')+'/definitions/'+ $
      string((oldid[i]/100L), f='(i4.4)')+'XX'
    oldfile= olddir+'/plateDefinition-'+ $
      string(oldid[i], f='(i6.6)')+'.par'
    
    newdir= getenv('PLATELIST_DIR')+'/definitions/'+ $
      string((newid[i]/100L), f='(i4.4)')+'XX'
    newfile= newdir+'/plateDefinition-'+ $
      string(newid[i], f='(i6.6)')+'.par'
    
    iold= where(plans.designid eq oldid[i], nold)
    if(nold eq 0) then begin
        splog, 'No (old) design id '+strtrim(string(oldid),2)+ $
          ' in platePlans! Aborting.'
        return
    endif
    if(nold gt 1) then begin
        splog, 'More than one (old) design id '+strtrim(string(oldid),2)+ $
          ' in platePlans! Aborting.'
        return
    endif

    inew= where(plans.designid eq newid[i], nnew)
    if(nnew eq 0) then begin
        splog, 'No (new) design id '+strtrim(string(newid),2)+ $
          ' in platePlans! Continuing nevertheless.'
    endif
    if(nnew gt 1) then begin
        splog, 'More than one (new) design id '+strtrim(string(newid),2)+ $
          ' in platePlans! Aborting.'
        return
    endif
    if(nnew eq 1) then begin
        nra= plans[inew].racen
        ndec= plans[inew].deccen
        ora= plans[iold].racen
        odec= plans[iold].deccen
        if(abs(nra-ora) gt 1.e-6) then begin
            splog, 'New and old RA values disagree in platePlans! Aborting.'
            return
        endif
        if(abs(ndec-odec) gt 1.e-6) then begin
            splog, 'New and old Dec values disagree in platePlans! Aborting.'
            return
        endif
    endif
    
    yanny_read,oldfile, hdr=hdr
    if(NOT keyword_set(hdr)) then $
      message, 'No data in old design file '+oldfile
    ra= double(strsplit(yanny_par(hdr, 'raCen'), /extr))
    dec= double(strsplit(yanny_par(hdr, 'decCen' ), /extr))
    if(abs(nra-ra) gt 1.e-6) then begin
        splog, 'Design file RA value ('+ $
          strtrim(string(f='(f40.6)', ra),2)+ $
          ') disagrees with platePlans ('+ $
          strtrim(string(f='(f40.6)', nra),2)+ $
          ')! Aborting.'
        return
    endif
    if(abs(ndec-dec) gt 1.e-6) then begin
        splog, 'Design file RA value ('+ $
          strtrim(string(f='(f40.6)', dec),2)+ $
          ') disagrees with platePlans ('+ $
          strtrim(string(f='(f40.6)', ndec),2)+ $
          ')! Aborting.'
        return
    endif
    
    if(file_test(newfile) eq 0 OR $
       keyword_set(clobber) gt 0) then begin
        if(file_test(newfile) gt 0) then $
          splog, 'Overwriting existing file: '+newfile
        
        comment1='# Created using COPYDEF by '+getenv('USER')+' at '+ $
          systime()
        comment2='# Copied from definition file for designId '+ $
          strtrim(string(oldid[i]),2)
        
        line=''
        if(n_elements(reset) gt 0) then $
          used= bytarr(n_elements(reset))
        
        nlines= file_lines(oldfile)
        openr, inunit, oldfile, /get_lun
        openw, outunit, newfile, /get_lun
        printf, outunit, comment1
        printf, outunit, comment2
        
        for j=0L, nlines-1L do begin
            readf, inunit, line
            if(strmid(line, 0, 1) ne '#') then begin
                words= strsplit(line, /extr)
                for k=0L, n_elements(reset)-1L do begin
                    rwords= strsplit(reset[k], /extr)
                    if(strupcase(rwords[0]) eq strupcase(words[0])) then begin
                        line=reset[k]
                        if(used[k]) then $
                          splog, 'WARNING: duplicate in reset!'
                        used[k]=1
                    endif
                endfor
                if(strupcase(words[0]) eq 'DESIGNID') then begin
                    line= 'designId '+strtrim(string(newid[i]),2)
                endif
            endif 
            printf, outunit, line
        endfor
        
        if(n_elements(reset) gt 0) then begin
            inot= where(used eq 0, nnot)
            for j=0L, nnot-1L do begin
                printf, outunit, reset[inot[j]]
            endfor
        endif
        
        free_lun, inunit
        free_lun, outunit
    endif else begin
        splog, 'Not overwriting existing file: '+newfile
    endelse
    
endfor

end
;------------------------------------------------------------------------------
