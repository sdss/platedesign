;+
; NAME:
;   fiberid_manga
; PURPOSE:
;   assign fiberid's to a list of MaNGA targets
; CALLING SEQUENCE:
;   fiberid= fiberid_manga(design)
; INPUTS:
;   design - [1000] struct array of targets, in design_blank() form
;            Required tags are .XF_DEFAULT, .YF_DEFAULT
; OPTIONAL INPUTS:
;   minstdinblock, minskyinblock, maxskyinblock
;          - nominally, min/max number of standards or skies to assign
;            to each block, in fact ignored [default 0]
; OPTIONAL OUTPUTS:
;   block - [N] IFUDESIGN associated with each fiber (set for skies
;           too)
; OPTIONAL KEYWORDS:
;   /nosky - do not attempt to assign any of the sky fibers
;   /nostd - do not attempt to assign any of the standard fibers
;   /noscience - do not attempt to assign any of the science fibers
; OUTPUTS:
;   fiberid - 1-indexed list of fibers 
; COMMENTS:
;   Uses sdss_plugprob to solve the plugging problem for skies.
;   First, assigns standards
;   Second, assigns skies
;   Finally, assigns all others
; REVISION HISTORY:
;   4-Jun-2008 MRB, NYU 
;   1-Sep-2010 Demitri Muna, NYU, Adding file test before opening files.
;   20-Sep-2012 MRB, NYU, altered from BOSS for MaNGA
;-
function fiberid_manga, default, fibercount, design, $
  minstdinblock=minstdinblock, $
  minskyinblock=minskyinblock, $
  maxskyinblock=maxskyinblock, $
  nosky=nosky, nostd=nostd, noscience=noscience, $
  quiet=quiet, block=block, $
  respect_fiberid=respect_fiberid, $
  plate_obj=plate_obj, $
  debug=debug, all_design=all_design

common com_fiberid_manga, fiberblocks

if(keyword_set(respect_fiberid)) then $
  message, 'BOSS spectrograph designs cannot respect fiberid'

if(keyword_set(minstdinblock)) then $
  message, 'Cannot set block constraints for standards in BOSS'

platescale = platescale('APO')
nsky_tot= 92L
nsci_tot= 29L
skyradius= 14./60.

fiberused=0L
fiberid=lonarr(n_elements(design))
npointings= long(default.npointings)
noffsets= long(default.noffsets)

if(npointings ne 1 or noffsets ne 0) then $
   message, 'MaNGA does not support more than one pointing or offset!'

ip=1L
io=0L

;; assign science
block= lonarr(n_elements(fiberid))-1L
isci= where(design.pointing eq ip and $
            design.offset eq io, nsci)
fiberid[isci]= 1L+lindgen(nsci)
block[isci]= design[isci].ifudesign

return, fiberid

end

