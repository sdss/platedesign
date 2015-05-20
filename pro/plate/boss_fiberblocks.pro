;+
; NAME:
;   boss_fiberblocks
; PURPOSE:
;   write our guess for the BOSS fiber blocks file for fiber placement
; CALLING SEQUENCE:
;   boss_fiberblocks
; COMMENTS:
;   Original version was based on Larry Carey's email sdss3-infrastructure/687
;   This version based on his sdss3-infrastructure/907
;   Creates the file:
;    $PLATEDESIGN_DIR/data/boss/fiberBlocksBOSS.par
;   with a structure inside with the elements:
;      .BLOCKID     (which block the fiber is in)
;      .FIBERCENX   (position in deg, +X = +RA)
;      .FIBERCENY   (position in deg, +Y = +Dec)
; REVISION HISTORY:
;   7-Aug-2008  MRB, NYU
;-
;------------------------------------------------------------------------------
pro boss_fiberblocks

platescale = platescale('APO')
mm2inch= 0.039370              ; inch per mm
inch2mm= 1./0.039370              ; mm per inch

fibers= replicate({TIFIBERBLOCK, blockid:0L, fibercenx:0.D, $
                   fiberceny:0.D}, 1000L)
nperblock=20L

rows_mm=[-114.6, -277.5]
inner_cols_mm= [-284.9, -239.1, -193.4, -147.7, -102.0, -56.3, -10.5, $
                35.2, 80.9, 126.6, 172.3, 218.1, 263.8, 309.5]
outer_cols_mm= [-216.3, -170.6, -124.8, -79.1, -33.4, $
                12.3, 58.0, 103.8, 149.5, 195.2, 240.9]
fspace=4.055

iblock=1L
offset=0L

;; do bottom row
irow=1L
for icol=0L, n_elements(outer_cols_mm)-1L do begin
    indx= offset+lindgen(nperblock)
    fibers[indx].blockid= iblock
    fibers[indx].fibercenx= outer_cols_mm[icol]
    fibers[indx].fiberceny= rows_mm[irow] $
      +fspace*findgen(nperblock)
    iblock=iblock+1L
    offset=offset+nperblock
endfor

;; do second row
irow=0
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

;; do third row (same 
irow=0
for icol=0L, n_elements(inner_cols_mm)-1L do begin
    indx= offset+lindgen(nperblock)
    fibers[indx].blockid= iblock
    fibers[indx].fibercenx= -reverse(inner_cols_mm[icol])
    fibers[indx].fiberceny= -rows_mm[irow] $
      -fspace*findgen(nperblock)
    iblock=iblock+1L
    offset=offset+nperblock
endfor

;; do top row
irow=1
for icol=0L, n_elements(outer_cols_mm)-1L do begin
    indx= offset+lindgen(nperblock)
    fibers[indx].blockid= iblock
    fibers[indx].fibercenx= -reverse(outer_cols_mm[icol])
    fibers[indx].fiberceny= -rows_mm[irow] $
      -fspace*findgen(nperblock)
    iblock=iblock+1L
    offset=offset+nperblock
endfor

fibers.fibercenx= fibers.fibercenx/platescale
fibers.fiberceny= fibers.fiberceny/platescale

hdr=['#', $
     '# Positions of fibers in harnesses in degrees on the focal plane.', $
     '#', $
     '# This file is based on Larey Carey email sdss3-infrastructure/907.', $
     '# Based on an actual cartridge.', $
     '#', $
     '# Units of fiberCenX and fiberCenY are degrees.', $
     '#', $
     '# MRB 2009-05-11', $
     '#']

pdata= ptr_new(fibers)
yanny_write, $
  getenv('PLATEDESIGN_DIR')+'/data/boss/fiberBlocksBOSS.par', $
  pdata, hdr=hdr
ptr_free, pdata

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
