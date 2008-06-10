;+
; NAME:
;   design_dir
; PURPOSE:
;   Return the directory associated with a given design
; CALLING SEQUENCE:
;   dir= design_dir(designid)
; INPUTS:
;   designid - design number
; COMMENTS:
;   Directory is of the form:
;    $PLATELIST/designs/[DDDD]XX/[DDDDDD]
;   Eg. for designid 12345 it would return
;    $PLATELIST/designs/0123XX/012345
; REVISION HISTORY:
;   7-May-2008  MRB, NYU
;-
;------------------------------------------------------------------------------
function design_dir, designid

designdir= getenv('PLATELIST_DIR')+'/designs/'+ $
  string((designid/100L), f='(i4.4)')+'XX/'+ $
  string(designid, f='(i6.6)')
return, designdir

end
