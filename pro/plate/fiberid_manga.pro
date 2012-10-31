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
itype=where(strupcase(fibercount.targettypes) eq 'STANDARD', ntype)
nstd_tot=long(total(fibercount.ntot[iinst, itype, ip-1L, io]))
itype=where(strupcase(fibercount.targettypes) eq 'SKY', ntype)
nsky_tot=long(total(fibercount.ntot[iinst, itype, ip-1L, io]))
itype=where(strupcase(fibercount.targettypes) eq 'STANDARD_3', ntype)
nstd3_tot=long(total(fibercount.ntot[iinst, itype, ip-1L, io]))
itype=where(strupcase(fibercount.targettypes) eq 'SKY_3', ntype)
nsky3_tot=long(total(fibercount.ntot[iinst, itype, ip-1L, io]))
itype=where(strupcase(fibercount.targettypes) eq 'STANDARD_5', ntype)
nstd5_tot=long(total(fibercount.ntot[iinst, itype, ip-1L, io]))
itype=where(strupcase(fibercount.targettypes) eq 'SKY_5', ntype)
nsky5_tot=long(total(fibercount.ntot[iinst, itype, ip-1L, io]))

isci= where(strupcase(design.targettype) eq 'SCIENCE', nsci)
if(nsci ne nsci_tot) then $
   message, 'Wrong number of science targets for MaNGA!'
fiberid[isci]= 1L+lindgen(nsci_tot)
ncurr=0L

istd= where(strupcase(design.targettype) eq 'STANDARD', nstd)
if(nstd lt nstd_tot) then $
   message, 'Not enough standard targets for MaNGA!'
if(nstd_tot gt 0) then begin
   istd= istd[shuffle_indx(nstd, num_sub=nstd_tot)]
   fiberid[istd]= 1L+ncurr+lindgen(nstd_tot)
   ncurr+= nstd_tot
endif

isky= where(strupcase(design.targettype) eq 'SKY', nsky)
if(nsky lt nsky_tot) then $
   message, 'Not enough standard targets for MaNGA!'
if(nsky_tot gt 0) then begin
   isky= isky[shuffle_indx(nsky, num_sub=nsky_tot)]
   fiberid[isky]= 1L+ncurr+lindgen(nsky_tot)
   ncurr+= nsky_tot
endif 

istd3= where(strupcase(design.targettype) eq 'STANDARD_3', nstd3)
if(nstd3 lt nstd3_tot) then $
   message, 'Not enough standard targets for MaNGA!'
if(nstd3_tot gt 0) then begin
   istd3= istd3[shuffle_indx(nstd3, num_sub=nstd3_tot)]
   fiberid[istd3]= 1L+ncurr+lindgen(nstd3_tot)
   ncurr+= nstd3_tot
endif

isky3= where(strupcase(design.targettype) eq 'SKY_3', nsky3)
if(nsky3 lt nsky3_tot) then $
   message, 'Not enough standard targets for MaNGA!'
if(nsky3_tot gt 0) then begin
   isky3= isky3[shuffle_indx(nsky3, num_sub=nsky3_tot)]
   fiberid[isky3]= 1L+ncurr+lindgen(nsky3_tot)
   ncurr+= nsky3_tot
endif 

istd5= where(strupcase(design.targettype) eq 'STANDARD_5', nstd5)
if(nstd5 lt nstd5_tot) then $
   message, 'Not enough standard targets for MaNGA!'
if(nstd5_tot gt 0) then begin
   istd5= istd5[shuffle_indx(nstd5, num_sub=nstd5_tot)]
   fiberid[istd5]= 1L+ncurr+lindgen(nstd5_tot)
   ncurr+= nstd5_tot
endif

isky5= where(strupcase(design.targettype) eq 'SKY_5', nsky5)
if(nsky5 lt nsky5_tot) then $
   message, 'Not enough standard targets for MaNGA!'
if(nsky5_tot gt 0) then begin
   isky5= isky5[shuffle_indx(nsky5, num_sub=nsky5_tot)]
   fiberid[isky5]= 1L+ncurr+lindgen(nsky5_tot)
   ncurr+= nsky5_tot
endif 

;; no block determinations yet
block= lonarr(n_elements(fiberid))-1L

return, fiberid

end

