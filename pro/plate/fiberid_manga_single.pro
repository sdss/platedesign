
; PURPOSE:
;   assign fiberid's to a list of MaNGA targets
; CALLING SEQUENCE:
;   fiberid= fiberid_manga_single(design)
; INPUTS:
;   design - [1000] struct array of targets, in design_blank() form
;            Required tags are .XF_DEFAULT, .YF_DEFAULT
;			 This is the list being considered for potential assignment.
;   all_design - full list of the design structure
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
;	block
; COMMENTS:
;   Uses sdss_plugprob to solve the plugging problem for skies.
;   First, assigns standards
;   Second, assigns skies
;   Finally, assigns all others
; REVISION HISTORY:
;   4-Jun-2008 MRB, NYU 
;   1-Sep-2010 Demitri Muna, NYU, Adding file test before opening files.
;   20-Sep-2012 MRB, NYU, altered from BOSS for MaNGA
;   Feb 2015, Demitri Muna, altered to accept survey-selected sky fibers per IFU
;-
function fiberid_manga_single, default, fibercount, design, $
  minstdinblock=minstdinblock, $
  minskyinblock=minskyinblock, $
  maxskyinblock=maxskyinblock, $
  nosky=nosky, nostd=nostd, noscience=noscience, $
  quiet=quiet, block=block, $
  respect_fiberid=respect_fiberid, $
  plate_obj=plate_obj, $
  debug=debug, all_design=all_design, respect_ifuid=respect_ifuid

common com_fiberid_manga, fiberblocks

;; Check for custom value for number of skies per IFU.
IF tag_exist(plate_obj->get('definition'),'skiesPerIFU') THEN $
	skies_per_ifu = long((plate_obj->get('definition')).skiesPerIFU)

if(keyword_set(respect_fiberid)) then $
  message, color_string('BOSS spectrograph designs cannot respect fiberid', 'yellow', 'bold')

if(keyword_set(minstdinblock)) then $
  message, color_string('Cannot set block constraints for standards in BOSS', 'yellow', 'bold')

platescale = 217.7358           ; mm/degree
nsky_tot= 92L
nsci_tot= 29L
skyradius= 14./60.

fiberused=0L
fiberid=lonarr(n_elements(design))
npointings= long(default.npointings)
noffsets= long(default.noffsets)

if(npointings ne 1 or noffsets ne 0) then $
   message, color_string('MaNGA does not support more than one pointing or offset!', 'red', 'bold')

ip=1L
io=0L

;; assign science
;;    isci - indices of science or standard targets
block= lonarr(n_elements(fiberid))-1L
isci= where(strupcase(all_design.holetype) eq 'MANGA' and $
            (strupcase(all_design.targettype) eq 'SCIENCE' or $
             strupcase(all_design.targettype) eq 'STANDARD') and $
            (all_design.fiberid gt 0 OR keyword_set(noscience) ne 0) and $
            all_design.pointing eq ip and $
            all_design.offset eq io, nsci)

;; picking skies
fnames= yanny_readone(getenv('MANGACORE_DIR')+'/cartmaps/manga_ferrule_names.par')
curr_fiberid= 1L+nsci+1L
for i=0L, nsci-1L do begin

	ifu = all_design[isci[i]] ; current IFU
	ifudesign = ifu.ifudesign

    ;; how many skies needed?
    ifnames= where(fnames.ifudesign eq ifudesign, nfnames)
    if(nfnames eq 0) then $
          message, color_string('Non-existent IFUDESIGN: '+strtrim(string(ifudesign),2), 'yellow', 'bold')
    if(nfnames gt 1) then $
      message, color_string('More than one IFUDESIGN: '+strtrim(string(ifudesign),2), 'yellow', 'bold')

	IF n_elements(skies_per_ifu) THEN $
	  nsky_curr = skies_per_ifu $
	ELSE $
	  nsky_curr = fnames[ifnames[0]].nsky

    ;; find still-free skies
	;; isky indices are of 'design' for this file.  available skies, i.e. available_skies = design[isky]
    isky= where(strupcase(design.holetype) eq 'MANGA_SINGLE' and fiberid eq 0 and $
                design.pointing eq ip and design.offset eq io, nsky)

    ;; check if the sky fibers are provided by ID
    if tag_exist(plate_obj->get('definition'), 'RESPECTIFUID') then begin
		;; reduce available skies to ones that match the ifudesign value
		idx = where(design[isky].ifuid eq ifudesign, nidx)
		if nidx eq 0 then $
		    print, color_string('Warning: expected to find skies assigned for ifudesign=' + $
			                    strtrim(string(ifudesign),2) + ', but none were found.', 'yellow', 'normal')
		isky = isky[idx] ; update indices of available skies
    endif
    
	;; find available skies
    spherematch, ifu.target_ra, ifu.target_dec, $
      design[isky].target_ra, design[isky].target_dec, skyradius, m1, m2, d12, max=0
    if(m1[0] eq -1) then $
      message, color_string('No available skies!', 'red', 'bold')
	
    if(n_elements(m1) lt nsky_curr) then $
      message, color_string('Only '+strtrim(string(n_elements(m1)),2)+' skies, when '+ $
         strtrim(string(nsky_curr),2)+' are needed for IFUDESIGN '+ $
         strtrim(string(ifudesign), 2), 'red', 'bold')

	;; filter out fibers that didn't match
	isky = isky[m2]
    
    ;; get angular distribution of available skies
    sky_curr=lonarr(nsky_curr)-1L
    sky_dx= design[isky].xf_default-ifu.xf_default
    sky_dy= design[isky].yf_default-ifu.yf_default
    sky_dr= sqrt(sky_dx^2+sky_dy^2)
    sky_dx= sky_dx/sky_dr
    sky_dy= sky_dy/sky_dr
    
    ;; divide skies into appropriate bins
    sky_angles_start= 2.*!DPI*findgen(nsky_curr)/float(nsky_curr)
    sky_dx_start= cos(sky_angles_start)
    sky_dy_start= sin(sky_angles_start)
    for j=0L, nsky_curr-1L do begin
        iok= where(fiberid[isky] eq 0, nok)
        if(nok eq 0) then $
          message, color_string('Ran out of skies! Should not have been possible. Sign of a bug!', 'red', 'bold')
        dotp= sky_dx_start[j]*sky_dx[iok]+sky_dy_start[j]*sky_dy[iok]
        isort= reverse(sort(dotp))
        fiberid[isky[iok[isort[0]]]]= curr_fiberid+j
        block[isky[iok[isort[0]]]]= ifudesign
    endfor
    
    curr_fiberid= curr_fiberid+ nsky_curr

endfor

return, fiberid

end

