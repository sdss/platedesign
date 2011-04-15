;+
; NAME:
;   check_photoplate 
; PURPOSE:
;   Check existence and validity of a BOSS photoPlate file
; CALLING SEQUENCE:
;   ok= check_photoplate(plate)
; REVISION HISTORY:
;   15-Apr-2011  MRB, NYU
;-
;------------------------------------------------------------------------------
function check_photoplate_file, filename

spawn, /nosh, ['fitsverify', filename], output
if(n_elements(output) lt 2) then $
   return, 0
if(output[2] ne 'OK:') then $
   return, 0

hdr= headfits(filename, ext=1)
if(long(sxpar(hdr, 'NAXIS2')) ne 1000) then $
   return, 0

return, 1

end
;
function check_photoplate, plate

  pstr=strtrim(string(f='(i4.4)',plate),2)
  
  resolve= file_basename(getenv('PHOTO_RESOLVE'))
  pdir= getenv('PHOTOPLATE_DIR')+'/'+resolve+'/'+pstr
  
  ok=check_photoplate_file(pdir+'/photoPlate-'+pstr+'.fits')
  if(NOT ok) then begin
     splog, 'photoPlate-'+pstr+'.fits not OK!'
     return, 0
  endif
     
  ok=check_photoplate_file(pdir+'/photoPosPlate-'+pstr+'.fits')
  if(NOT ok) then begin
     splog, 'photoPosPlate-'+pstr+'.fits not OK!'
     return, 0
  endif

  ok=check_photoplate_file(pdir+'/photoMatchPlate-'+pstr+'.fits')
  if(NOT ok) then begin
     splog, 'photoMatchPlate-'+pstr+'.fits not OK!'
     return, 0
  endif
  
  return, 1

end
