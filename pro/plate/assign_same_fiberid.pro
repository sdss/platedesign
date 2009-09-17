;+
; NAME:
;   assign_same_fiberid
; PURPOSE:
;   create new plateInput file with fiberid assigned
; CALLING SEQUENCE:
;   assign_same_fiberid, inputfile, outputfile, plate , /radec
; INPUTS:
;   inputfile - name of input file
;   outputfile - name of output file
;   plate - plate to get fiberid assignments from 
; OPTIONAL KEYWORDS:
;   /radec - matches on /radec
; REVISION HISTORY:
;   20-Nov-2008  MRB, NYU
;-
;------------------------------------------------------------------------------
pro assign_same_fiberid, inputfile, outputfile, plate, radec=radec

if(plate lt 3074) then begin
    message, 'fiber assignments not necessarily correct!'
endif

;; read in fiberid from old plate
oldfibersfile=plate_dir(plate)+ '/plateHolesSorted-'+ $
  strtrim(string(f='(i6.6)', plate),2)+'.par'
oldfibers= yanny_readone(oldfibersfile, hdr=hdr, /anon)

if (size(oldfibers, /tname) ne 'STRUCT') then begin ; test if the return value is a struct
	message, 'The input file for the plate id specified could not be found; double check the plate id given.'
	stop
endif

;; read in current input file
plinput= yanny_readone(inputfile, hdr=hdr, /anon)
if(tag_indx(plinput[0], 'fiberid') eq -1) then $
  plinputnew= replicate(create_struct(plinput[0], 'fiberid', -9999L), $
                        n_elements(plinput)) $
else $
  plinputnew= replicate(plinput[0], n_elements(plinput))

;; create output structure
struct_assign, plinput, plinputnew, /nozero

;; for each element in the new file, try to find its 
;; old fiberid.  if there is no old fiberid, then move
;; the target to low priority (HACK ALERT)
nmatch=0L
if(keyword_set(radec)) then begin
    splog, 'Matching on RA/Dec'
endif else begin
    splog, 'Matching on TARGETIDS'
endelse
for i=0L, n_elements(plinputnew)-1L do begin 
    if(strtrim(plinputnew[i].targetids,2) ne 'NA') then begin 
        if(keyword_set(radec)) then begin
            spherematch, plinputnew[i].ra, plinputnew[i].dec, $
              oldfibers.target_ra, oldfibers.target_dec, 3./3600, $
              m1, m2, max=0L
            if(m2[0] eq -1) then begin
                ii=-1L
                nii=0L
            endif else begin
                if(n_elements(m2) gt 1) then begin
                    ii=m2[0]
                    splog, 'Multiple matches!'
                    splog, 'Picked old: '+oldfibers[ii].targetids
                    splog, 'for new: '+plinputnew[i].targetids
                endif else begin
                    ii=m2[0]
                    nii=1L
                endelse
            endelse
        endif else begin
            ii=where(strtrim(plinputnew[i].targetids,2) eq $
                     strtrim(oldfibers.targetids,2), nii) 
        endelse
        if(nii gt 1) then $
          message, 'this target id appears more than once in the old file!'
        if(nii eq 1) then begin
            plinputnew[i].fiberid= oldfibers[ii].fiberid 
            nmatch=nmatch+1L
        endif else begin
            plinputnew[i].priority= plinputnew[i].priority+1000L 
        endelse
    endif 
endfor
splog, 'Matched '+strtrim(string(nmatch),2)+' objects.'

yanny_write, outputfile, ptr_new(plinputnew), hdr=hdr

end
