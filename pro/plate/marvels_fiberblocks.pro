;+
; NAME:
;   marvels_fiberblocks
; PURPOSE:
;   write the MARVELS fiber blocks file for fiber placement
; CALLING SEQUENCE:
;   marvels_fiberblocks
; COMMENTS:
;   Based on French Leger's diagrams and Brian Lee's sketches, stored
;   in:
;    $PLATEDESIGN_DIR/data/marvels/anchor-block-map-2008-09-10.pdf
;    $PLATEDESIGN_DIR/data/marvels/anchordiagram.jpg
;   Creates the file:
;    $PLATEDESIGN_DIR/data/marvels/fiberBlocksMarvels.par
;   with a structure inside with the elements:
;      .BLOCKID     (which block the fiber is in)
;      .FIBERCENX   (position in deg, +X = +RA)
;      .FIBERCENY   (position in deg, +Y = +Dec)
; REVISION HISTORY:
;   10-Sept-2008  MRB, NYU
;-
;------------------------------------------------------------------------------
pro marvels_fiberblocks

platescale = platescale('APO')
inchpermm= 0.039370              ; inch per mm

mblocks= replicate({TIFIBERBLOCK, blockid:0L, fibercenx:0.D, $
                    fiberceny:0.D}, 60)

xpos=[-9.133, -3.933, 3.937, 9.137]
sign=[1., 1., -1., -1.]
ypos=ptrarr(n_elements(xpos))
ypos[0]= ptr_new([-9.4, -0.05, 8.45])
ypos[1]= ptr_new([-11.50, -6.25, -0.45, 5.30, 10.55])
ypos[2]= ptr_new([-11.82, -5.25, 3.15, 11.5])
ypos[3]= ptr_new([-8.45, -0.05, 9.4])

fspace=0.25

i=0L
for ix=0L, n_elements(xpos)-1L do begin
    for iy=0L, n_elements(*ypos[ix])-1L do begin
        mblocks[i*4L:i*4L+3L].blockid= i+1L
        mblocks[i*4L:i*4L+3L].fibercenx= xpos[ix]+ $
          sign[ix]*fspace*(dindgen(4)-1.5)
        mblocks[i*4L:i*4L+3L].fiberceny= (*ypos[ix])[iy]
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
  getenv('PLATEDESIGN_DIR')+'/data/marvels/fiberBlocksMarvels.par', $
  pdata, hdr=hdr
ptr_free, pdata

return
end
