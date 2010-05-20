;+
; NAME:
;   test_marvels_fiberblocks
; PURPOSE:
;   write the MARVELS fiber blocks file for fiber placement
; CALLING SEQUENCE:
;   marvels_fiberblocks
; COMMENTS:
;   Tests for Brian Lee.
;   Creates the file:
;    $PLATEDESIGN_DIR/data/marvels/fiberBlocksMarvelsTest60.par
;   with a structure inside with the elements:
;      .BLOCKID     (which block the fiber is in)
;      .FIBERCENX   (position in deg, +X = +RA)
;      .FIBERCENY   (position in deg, +Y = +Dec)
; REVISION HISTORY:
;   10-Sept-2008  MRB, NYU
;-
;------------------------------------------------------------------------------
pro test_marvels_fiberblocks

platescale = 217.7358D           ; mm/degree
inchpermm= 0.039370              ; inch per mm

mblocks= replicate({TIFIBERBLOCK, blockid:0L, fibercenx:0.D, $
                    fiberceny:0.D}, 60)

ypos=[-9.133, -3.933, 3.937, 9.137]
sign=[1., 1., -1., -1.]
xpos=ptrarr(n_elements(ypos))
xpos[0]= ptr_new([-0.05])
xpos[1]= ptr_new([-11.50, -6.25, 5.30, 10.55])
xpos[2]= ptr_new([-11.82, -5.25, 3.15, 11.5])
xpos[3]= ptr_new([-0.05])

fspace=0.25

nper=6L

i=0L
for iy=0L, n_elements(ypos)-1L do begin
    for ix=0L, n_elements(*(xpos[iy]))-1L do begin
        mblocks[i*nper:(i+1)*nper-1L].blockid= i+1L
        mblocks[i*nper:(i+1)*nper-1L].fibercenx= (*xpos[iy])[ix]
        mblocks[i*nper:(i+1)*nper-1L].fiberceny= ypos[iy]+ $
          sign[iy]*fspace*(dindgen(nper)-1.5)
        i=i+1L
    endfor
endfor
mblocks.fibercenx= mblocks.fibercenx/inchpermm/platescale
mblocks.fiberceny= mblocks.fiberceny/inchpermm/platescale


hdr=['#', $
     '# Positions of fibers in harnesses in degrees on the focal plane.', $
     '#', $
     '# This file is based on French Leger measurements.', $
     '# Individual cartridges do vary in block position by an inch or so.', $
     '#', $
     '# Units of fiberCenX and fiberCenY are degrees.', $
     '#', $
     '# MRB 2008-07-23', $
     '#']

pdata= ptr_new(mblocks)
yanny_write, $
  getenv('PLATEDESIGN_DIR')+'/data/marvels/fiberBlocksMarvelsTest60.par', $
  pdata, hdr=hdr
ptr_free, pdata

mblocks2=mblocks
mblocks2.blockid= mblocks2.blockid+10L
mblocks2= [mblocks, mblocks2]

pdata= ptr_new(mblocks2)
yanny_write, $
  getenv('PLATEDESIGN_DIR')+'/data/marvels/fiberBlocksMarvelsTest120.par', $
  pdata, hdr=hdr
ptr_free, pdata

return
end
