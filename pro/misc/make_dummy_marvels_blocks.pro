;+
; NAME:
;   make_dummy_marvels_blocks
; PURPOSE:
;   make dummy marvels blocks file
; REVISION HISTORY:
;   Jul 23, 2008, MRB, NYU
;-
;------------------------------------------------------------------------------
pro make_dummy_marvels_blocks

sblocks= yanny_readone(getenv('PLATEDESIGN_DIR')+'/data/sdss/fiberBlocks.par')

xcen= dblarr(15)
ycen= dblarr(15)

for i=0L, 7L do begin 
    ii=where(sblocks.blockid eq i*2L OR sblocks.blockid eq i*2L+1L) 
    xcen[i]=mean(sblocks[ii].fiberCenX) 
    ycen[i]=mean(sblocks[ii].fiberCenY) 
endfor

for i=8L, 11L do begin 
    ii=where(sblocks.blockid eq i*2L+1 OR sblocks.blockid eq i*2L+2L )
    xcen[i]=mean(sblocks[ii].fiberCenX) 
    ycen[i]=mean(sblocks[ii].fiberCenY) 
endfor

for i=12L, 14L do begin 
    ii=where(sblocks.blockid eq i*2L+2 OR sblocks.blockid eq i*2L+3L )
    xcen[i]=mean(sblocks[ii].fiberCenX) 
    ycen[i]=mean(sblocks[ii].fiberCenY) 
endfor

splot, sblocks.fibercenx, sblocks.fiberceny, psym=4
soplot, xcen, ycen, psym=5, color='red', th=4

mblocks= replicate({TIFIBERBLOCK, blockid:0L, fibercenx:0.D, fiberceny:0.D}, 60)

for i=0L, 14L do begin
    mblocks[i*4L:i*4L+3L].blockid= i+1L
    mblocks[i*4L:i*4L+3L].fibercenx= xcen[i]
    mblocks[i*4L:i*4L+3L].fiberceny= ycen[i]+0.018*(dindgen(4)-1.5)
endfor

soplot, mblocks.fibercenx, mblocks.fiberceny, psym=4, color='green'

hdr=['#', $
     '# Positions of fibers in harnesses in degrees on the focal plane.', $
     '#', $
     '# This file is a wild-ass guess, since it was written before the ', $
     '# creation of the actual MARVELS fiber blocks.', $
     '# ', $
     '# The assumption is that it is 15 blocks of 4 fibers "distributed', $
     '# evenly across the focal plane".', $
     '#', $
     '# Units of fiberCenX and fiberCenY are degrees.', $
     '#', $
     '# MRB 2008-07-23', $
     '#']

pdata= ptr_new(mblocks)

yanny_write, getenv('PLATEDESIGN_DIR')+'/data/marvels/fiberBlocksMarvelsDummy.par', $
  pdata,  hdr=hdr

end
