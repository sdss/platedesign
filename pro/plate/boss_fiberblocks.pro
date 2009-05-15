;+
; NAME:
;   boss_fiberblocks
; PURPOSE:
;   write our guess for the BOSS fiber blocks file for fiber placement
; CALLING SEQUENCE:
;   boss_fiberblocks
; COMMENTS:
;   Based on Larry Carey's email sdss3-infrastructure/687
;     I just spoke with French. The model on the WIKI is obsolete. The
;     new anchor rails are designed to mount 16 science harnesses (20
;     fibers per harness) equally spaced on the inner rail and 9
;     harnesses equally spaced on the outer rail. there is a limited
;     adjustment of final position that is possible, but based on the
;     experience with SDSS1 and 2 the intent is to evenly space the
;     harnesses at 1.8" increments along each rail. The mounting
;     positions on the outer rail are staggered relative to the inner
;     rail. I'm getting a model from French today and will try to get you
;     a dimensioned drawing by tomorrow of the proposed mounting
;     positions, with fiber positions relative to mounting positions.
;   Creates the file:
;    $PLATEDESIGN_DIR/data/boss/fiberBlocksBOSS.par
;   with a structure inside with the elements:
;      .BLOCKID     (which block the fiber is in)
;      .FIBERCENX   (position in deg, +X = +RA)
;      .FIBERCENY   (position in deg, +Y = +Dec)
; REVISION HISTORY:
;   10-Sept-2008  MRB, NYU
;-
;------------------------------------------------------------------------------
pro boss_fiberblocks

platescale = 217.7358D           ; mm/degree
mm2inch= 0.039370              ; inch per mm
inch2mm= 1./0.039370              ; mm per inch

fibers= replicate({TIFIBERBLOCK, blockid:0L, fibercenx:0.D, $
                   fiberceny:0.D}, 1000L)
nperblock=20L

rows_mm=[-10.35, -5.15, 5.15, 10.35]*inch2mm
outer_cols_mm= (-7.2+findgen(9)*1.8)*inch2mm
inner_cols_mm= (-13.5+findgen(16)*1.8)*inch2mm
fspace=4.055

iblock=1L
offset=0L
irow=0L

;; do bottom row
for icol=0L, n_elements(outer_cols_mm)-1L do begin
    indx= offset+lindgen(nperblock)
    fibers[indx].blockid= iblock
    fibers[indx].fibercenx= outer_cols_mm[icol]
    fibers[indx].fiberceny= rows_mm[irow] $
      +fspace*findgen(nperblock)
    iblock=iblock+1L
    offset=offset+nperblock
endfor
irow=irow+1L

;; do second row
for icol=0L, n_elements(inner_cols_mm)-1L do begin
    indx= offset+lindgen(nperblock)
    fibers[indx].blockid= iblock
    fibers[indx].fibercenx= inner_cols_mm[icol]
    fibers[indx].fiberceny= rows_mm[irow] $
      +fspace*findgen(nperblock)
    iblock=iblock+1L
    offset=offset+nperblock
endfor
irow=irow+1L

;; do third row
for icol=0L, n_elements(inner_cols_mm)-1L do begin
    indx= offset+lindgen(nperblock)
    fibers[indx].blockid= iblock
    fibers[indx].fibercenx= inner_cols_mm[icol]
    fibers[indx].fiberceny= rows_mm[irow] $
      -fspace*findgen(nperblock)
    iblock=iblock+1L
    offset=offset+nperblock
endfor
irow=irow+1L

;; do top row
for icol=0L, n_elements(outer_cols_mm)-1L do begin
    indx= offset+lindgen(nperblock)
    fibers[indx].blockid= iblock
    fibers[indx].fibercenx= outer_cols_mm[icol]
    fibers[indx].fiberceny= rows_mm[irow] $
      -fspace*findgen(nperblock)
    iblock=iblock+1L
    offset=offset+nperblock
endfor
irow=irow+1L

fibers.fibercenx= fibers.fibercenx/platescale
fibers.fiberceny= fibers.fiberceny/platescale

hdr=['#', $
     '# Positions of fibers in harnesses in degrees on the focal plane.', $
     '#', $
     '# This file is based on Larey Carey email sdss3-infrastructure/687.', $
     '# Real cartridges may vary.', $
     '#', $
     '# Units of fiberCenX and fiberCenY are degrees.', $
     '#', $
     '# MRB 2009-05-11', $
     '#']

pdata= ptr_new(fibers)
yanny_write, $
  getenv('PLATEDESIGN_DIR')+'/data/boss/fiberBlocksBOSS.par', $
  pdata, hdr=hdr

;; now create PS file for QA
xmm= fibers.fibercenx*platescale
ymm= fibers.fiberceny*platescale

k_print, filename=getenv('PLATEDESIGN_DIR')+'/data/boss/fiberBlocksBOSS.ps'
hogg_usersym, 20, /fill
th=findgen(1001)/1000.*!DPI*2.
xc= 1.49*platescale*cos(th)
yc= 1.49*platescale*sin(th)
djs_plot, xc, yc, th=2, xra=[-401, 401], yra=[-401, 401]
djs_oplot, xmm, ymm, psym=8, symsize=0.3, color='red'
for i=0L, 49L do begin
    xb= mean(xmm[i*nperblock:(i+1)*nperblock-1])
    yb= mean(ymm[i*nperblock:(i+1)*nperblock-1])
    djs_xyouts, [xb]+5., [yb], strtrim(string(i+1),2)
endfor
k_end_print

return
end
