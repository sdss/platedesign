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
;   block - [N] block for each fiber
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
  debug=debug

common com_fiberid_manga, fiberblocks

if(keyword_set(respect_fiberid)) then $
  message, 'BOSS spectrograph designs cannot respect fiberid'

if(keyword_set(minstdinblock)) then $
  message, 'Cannot set block constraints for standards in BOSS'

platescale = 217.7358           ; mm/degree
nperblock=20L
;;minyblocksize=0.3

if(NOT keyword_set(minstdinblock)) then minstdinblock=0L
if(NOT keyword_set(minskyinblock)) then minskyinblock=0L
if(NOT keyword_set(maxskyinblock)) then maxskyinblock=nperblock

fiberused=0L
fiberid=lonarr(n_elements(design))
npointings= long(default.npointings)
noffsets= long(default.noffsets)

if(npointings ne 1 or noffsets ne 0) then $
   message, 'MaNGA does not support more than one pointing or offset!'

ip=1L
io=0L

iinst=where(strupcase(fibercount.instruments) eq 'MANGA', ninst)
itype=where(strupcase(fibercount.targettypes) eq 'SCIENCE', ntype)
nsci_tot=long(total(fibercount.ntot[iinst, itype, ip-1L, io]))

isci= where(strupcase(design.targettype) eq 'SCIENCE', nsci)
if(nsci ne nsci_tot) then $
   message, 'Wrong number of science targets for MaNGA!'
fiberid[isci]= 1L+lindgen(nsci_tot)

;; reset fiber numbers for single fibers
sizes= ['', '3', '5']
dithers=['', '_D1', '_D2', '_D3']
types= strarr(n_elements(sizes), n_elements(dithers))
for i=0L, n_elements(sizes)-1L do begin
    for j=0L, n_elements(dithers)-1L do begin
        types[i,j]=sizes[i]+dithers[j]
    endfor
endfor
types= reform(types, n_elements(types))

ncurr=0L
for i=0L, n_elements(types)-1L do begin
    itype=where(strupcase(fibercount.targettypes) eq 'SKY'+types[i], ntype)
    if(ntype gt 0) then $
      nsky_tot=long(total(fibercount.ntot[iinst, itype, ip-1L, io])) $
    else $
      nsky_tot=0
    itype=where(strupcase(fibercount.targettypes) eq 'STANDARD'+types[i], ntype)
    if(ntype gt 0) then $
      nstd_tot=long(total(fibercount.ntot[iinst, itype, ip-1L, io])) $
    else $
      nstd_tot=0

    istd= where(strupcase(design.targettype) eq 'STANDARD'+types[i], nstd)
    if(nstd lt nstd_tot) then $
      message, 'Not enough standard'+types[i]+' targets for MaNGA!'
    if(nstd_tot gt 0) then begin
        istd= istd[shuffle_indx(nstd, num_sub=nstd_tot)]
        fiberid[istd]= 1L+ncurr+lindgen(nstd_tot)
        ncurr+= nstd_tot
    endif

    isky= where(strupcase(design.targettype) eq 'SKY'+types[i], nsky)
    if(nsky lt nsky_tot) then $
      message, 'Not enough sky'+types[i]+'  targets for MaNGA!'
    if(nsky_tot gt 0) then begin
        isky= isky[shuffle_indx(nsky, num_sub=nsky_tot)]
        fiberid[isky]= 1L+ncurr+lindgen(nsky_tot)
        ncurr+= nsky_tot
    endif 
endfor

;; no block determinations yet
block= lonarr(n_elements(fiberid))-1L

return, fiberid

end

