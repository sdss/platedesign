;+
; NAME:
;   assign_same_fiberid
; PURPOSE:
;   create new plateInput file with fiberid assigned
; CALLING SEQUENCE:
;   assign_same_fiberid, inputfile, outputfile, plate
; INPUTS:
;   inputfile - name of input file
;   outputfile - name of output file
;   plate - plate to get fiberid assignments from 
; COMMENTS
; REVISION HISTORY:
;   20-Nov-2008  MRB, NYU
;-
;------------------------------------------------------------------------------
pro assign_same_fiberid, inputfile, outputfile, plate

if(plate lt 3074) then begin
    message, 'fiber assignments not necessarily correct!'
endif

;; read in fiberid from old plate
oldfibersfile=plate_dir(plate)+ '/plateHolesSorted-'+ $
  strtrim(string(f='(i6.6)', plate),2)+'.par'
oldfibers= yanny_readone(oldfibersfile, hdr=hdr, /anon)

if (size(oldfibers, /type) ne 8) then begin ; test if the return value is a struct
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
for i=0L, n_elements(plinputnew)-1L do begin 
    if(strtrim(plinputnew[i].targetids,2) ne 'NA') then begin 
        ii=where(strtrim(plinputnew[i].targetids,2) eq $
                 strtrim(oldfibers.targetids,2), nii) 
        if(nii gt 1) then $
          message, 'this target id appears more than once in the old file!'
        if(nii eq 1) then $
          plinputnew[i].fiberid= oldfibers[ii].fiberid $
        else $
          plinputnew[i].priority= plinputnew[i].priority+1000L 
    endif 
endfor

yanny_write, outputfile, ptr_new(plinputnew), hdr=hdr

end
