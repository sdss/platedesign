;+
; NAME:
;   plate_dir
; PURPOSE:
;   Return the directory associated with a given plate
; CALLING SEQUENCE:
;   dir= plate_dir(plateid)
; INPUTS:
;   plateid - plate number
; COMMENTS:
;   Directory is of the form:
;    $PLATELIST/plates/[PPPP]XX/[PPPPPP]
;   Eg. for plateid 12345 it would return
;    $PLATELIST/plates/0123XX/012345
; REVISION HISTORY:
;   7-May-2008  MRB, NYU
;-
;------------------------------------------------------------------------------
function plate_dir, plateid

platedir= getenv('PLATELIST_DIR')+'/plates/'+ $
  string((plateid/100L), f='(i4.4)')+'XX/'+ $
  string(plateid, f='(i6.6)')
return, platedir

end
