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
function fiberid_manga_single, default, fibercount, design, $
  minstdinblock=minstdinblock, $
  minskyinblock=minskyinblock, $
  maxskyinblock=maxskyinblock, $
  nosky=nosky, nostd=nostd, noscience=noscience, $
  quiet=quiet, block=block, $
  respect_fiberid=respect_fiberid, $
  debug=debug, all_design=all_design

common com_fiberid_manga, fiberblocks

if(keyword_set(respect_fiberid)) then $
  message, 'BOSS spectrograph designs cannot respect fiberid'

if(keyword_set(minstdinblock)) then $
  message, 'Cannot set block constraints for standards in BOSS'

platescale = 217.7358           ; mm/degree
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
isci= where(strupcase(all_design.holetype) eq 'MANGA' and $
            strupcase(all_design.targettype) eq 'SCIENCE' and $
            (all_design.fiberid gt 0 OR keyword_set(noscience) ne 0) and $
            all_design.pointing eq ip and $
            all_design.offset eq io, nsci)

;; picking skies
fnames= yanny_readone(getenv('MANGACORE_DIR')+'/cartmaps/manga_ferrule_names.par')
curr_fiberid= 1L+nsci+1L
for i=0L, nsci-1L do begin
    ;; how many skies needed?
    ifnames= where(fnames.ifudesign eq all_design[isci[i]].ifudesign, nfnames)
    if(nfnames eq 0) then $
          message, 'Non-existent IFUDESIGN: '+strtrim(string(all_design[isci[i]].ifudesign),2)
    if(nfnames gt 1) then $
      message, 'More than one IFUDESIGN: '+strtrim(string(all_design[isci[i]].ifudesign),2)
    nsky_curr= fnames[ifnames[0]].nsky
    
    ;; find still-free skies
    isky= where(strupcase(design.holetype) eq 'MANGA_SINGLE' and fiberid eq 0 and $
                design.pointing eq ip and design.offset eq io, nsky)
    
    ;; find available skies
    spherematch, all_design[isci[i]].target_ra, all_design[isci[i]].target_dec, $
      design[isky].target_ra, design[isky].target_dec, skyradius, m1, m2, d12, $
      max=0
    if(m1[0] eq -1) then $
      message, 'No available skies!'
    if(n_elements(m1) lt nsky_curr) then $
      message, 'Only '+strtrim(string(n_elements(m1)),2)+' skies, when '+ $
      strtrim(string(nsky_curr),2)+' are needed for IFUDESIGN '+ $
      strtrim(string(all_design[isci[i]].ifudesign),2)
    
    ;; get angular distribution of available skies
    sky_curr=lonarr(nsky_curr)-1L
    sky_dx= design[isky[m2]].xf_default-all_design[isci[i]].xf_default
    sky_dy= design[isky[m2]].yf_default-all_design[isci[i]].yf_default
    sky_dr= sqrt(sky_dx^2+sky_dy^2)
    sky_dx= sky_dx/sky_dr
    sky_dy= sky_dy/sky_dr
    
    ;; divide skies into appropriate bins
    sky_angles_start= 2.*!DPI*findgen(nsky_curr)/float(nsky_curr)
    sky_dx_start= cos(sky_angles_start)
    sky_dy_start= sin(sky_angles_start)
    for j=0L, nsky_curr-1L do begin
        iok= where(fiberid[isky[m2]] eq 0, nok)
        if(nok eq 0) then $
          message, 'Ran out of skies! Should not have been possible. Sign of a bug!'
        dotp= sky_dx_start[j]*sky_dx[iok]+sky_dy_start[j]*sky_dy[iok]
        isort= reverse(sort(dotp))
        fiberid[isky[m2[iok[isort[0]]]]]= curr_fiberid+j
        block[isky[m2[iok[isort[0]]]]]= all_design[isci[i]].ifudesign
    endfor
    
    curr_fiberid= curr_fiberid+ nsky_curr
endfor

return, fiberid

end
