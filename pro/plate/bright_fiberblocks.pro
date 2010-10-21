;+
; NAME:
;   bright_fiberblocks
; PURPOSE:
;   write the APOGEE fiber blocks file for fiber placement
; CALLING SEQUENCE:
;   bright_fiberblocks
; COMMENTS:
;   Uses Paul's numbers for the new bright time cartridges
;    $PLATEDESIGN_DIR/data/apogee/JointAnchorBlockPositionsR4.dat
;   Creates the files:
;    $PLATEDESIGN_DIR/data/marvels/fiberBlocksMARVELSBright.par
;    $PLATEDESIGN_DIR/data/apogee/fiberBlocksAPOGEE.par
;    $PLATEDESIGN_DIR/data/apogee/fiberBlocksBrightAPOGEE.par
;    $PLATEDESIGN_DIR/data/apogee/fiberBlocksMediumAPOGEE.par
;    $PLATEDESIGN_DIR/data/apogee/fiberBlocksFaintAPOGEE.par
;   with a structure inside with the elements:
;      .BLOCKID     (which block the fiber is in)
;      .FIBERCENX   (position in deg, +X = +RA)
;      .FIBERCENY   (position in deg, +Y = +Dec)
; REVISION HISTORY:
;   5-Oct-2010  MRB, NYU
;-
;------------------------------------------------------------------------------
pro bright_fiberblocks

platescale = 217.7358D           ; mm/degree
inchpermm= 0.039370              ; inch per mm
fspace=0.15/inchpermm

adir= getenv('PLATEDESIGN_DIR')+'/data/apogee'

bfile= adir+'/JointAnchorBlockPositionsR4.dat'
readcol, comment='#', f='(f,f,a)', bfile, orig_xbase, orig_ybase, orig_type

iapo= where(orig_type eq 'A', napo)
if(napo ne 50) then $
   message, 'Expected 50 blocks!'
xbase=orig_xbase[iapo]
ybase=orig_ybase[iapo]
type=orig_type[iapo]

mblocks= replicate({TIFIBERBLOCK, blockid:0L, fiberid:0L, $
                    fibercenx:0.D, $
                    fiberceny:0.D, $
                    ftype:' '}, 300)

nper=6L
for i=0L, n_elements(xbase)-1L do begin
   ifiber= i*nper+lindgen(nper)
   mblocks[ifiber].blockid=i+1L
   mblocks[ifiber].fiberid=ifiber+1L
   mblocks[ifiber].fibercenx=xbase[i]
   if(ybase[i] ge 0) then begin
      mblocks[ifiber].fiberceny=ybase[i]-fspace*findgen(nper)
   endif else begin
      mblocks[ifiber].fiberceny=ybase[i]+fspace*findgen(nper)
   endelse
   mblocks[ifiber].ftype= ['F', 'M', 'B', 'B', 'M', 'F']
endfor
mblocks.fibercenx= mblocks.fibercenx/platescale
mblocks.fiberceny= mblocks.fiberceny/platescale

hdr=['#', $
     '# Positions of fibers in harnesses in degrees on the focal plane.', $
     '#', $
     '# This file is based on the Paul Harding JointAnchorBlockPositionsR4.dat.', $
     '# Individual cartridges do vary.', $
     '#', $
     '# Units of fiberCenX and fiberCenY are degrees.', $
     '#', $
     '# MRB 2010-10-05', $
     '#']

pdata= ptr_new(mblocks)
yanny_write, $
  getenv('PLATEDESIGN_DIR')+'/data/apogee/fiberBlocksAPOGEE.par', $
  pdata, hdr=hdr
ptr_free, pdata

ibright= where(mblocks.ftype eq 'B')
pdata=ptr_new(mblocks[ibright])
yanny_write, $
  getenv('PLATEDESIGN_DIR')+'/data/apogee/fiberBlocksBrightAPOGEE.par', $
  pdata, hdr=hdr
ptr_free, pdata

imedium= where(mblocks.ftype eq 'M')
pdata=ptr_new(mblocks[imedium])
yanny_write, $
  getenv('PLATEDESIGN_DIR')+'/data/apogee/fiberBlocksMediumAPOGEE.par', $
  pdata, hdr=hdr
ptr_free, pdata

ifaint= where(mblocks.ftype eq 'F')
pdata=ptr_new(mblocks[ifaint])
yanny_write, $
  getenv('PLATEDESIGN_DIR')+'/data/apogee/fiberBlocksFaintAPOGEE.par', $
  pdata, hdr=hdr
ptr_free, pdata

imarvels= where(strupcase(orig_type) eq 'M', nmarvels)
if(nmarvels ne 20) then $
   message, 'Expected 20 blocks!'
xbase=orig_xbase[imarvels]
ybase=orig_ybase[imarvels]
type=orig_type[imarvels]

mblocks= replicate({TIFIBERBLOCK, blockid:0L, fiberid:0L, $
                    fibercenx:0.D, $
                    fiberceny:0.D, $
                    ftype:' '}, 120)

nper=6L
ysortpar= long(ybase)*1000L+long(xbase)*10L+long(type eq 'm')
isort= sort(ysortpar)
xbase= xbase[isort]
ybase= ybase[isort]
type= type[isort]

imid= 4L+lindgen(6)
xbase[imid]= xbase[reverse(imid)]
ybase[imid]= ybase[reverse(imid)]
type[imid]= type[reverse(imid)]

imid= 16+lindgen(4L)
xbase[imid]= xbase[reverse(imid)]
ybase[imid]= ybase[reverse(imid)]
type[imid]= type[reverse(imid)]

for i=0L, n_elements(xbase)-1L do begin
   ifiber= i*nper+lindgen(nper)
   mblocks[ifiber].blockid=(i / 2)+1L
   mblocks[ifiber].fiberid=(type[i] eq 'm')*60L+(i/2L)*nper+lindgen(nper)+1L
   mblocks[ifiber].fibercenx=xbase[i]
   if(ybase[i] ge 0) then begin
      mblocks[ifiber].fiberceny=ybase[i]-fspace*findgen(nper)
   endif else begin
      mblocks[ifiber].fiberceny=ybase[i]+fspace*findgen(nper)
   endelse
   if(type[i] eq 'M') then $
      mblocks[ifiber].ftype='A' $
   else $
      mblocks[ifiber].ftype='B' 
endfor
mblocks.fibercenx= mblocks.fibercenx/platescale
mblocks.fiberceny= mblocks.fiberceny/platescale

hdr=['#', $
     '# Positions of fibers in harnesses in degrees on the focal plane.', $
     '#', $
     '# This file is based on the Paul Harding JointAnchorBlockPositionsR4.dat.', $
     '# Individual cartridges do vary.', $
     '#', $
     '# Units of fiberCenX and fiberCenY are degrees.', $
     '#', $
     '# MRB 2010-10-05', $
     '#']

pdata= ptr_new(mblocks)
yanny_write, $
  getenv('PLATEDESIGN_DIR')+'/data/marvels/fiberBlocksMARVELSBright.par', $
  pdata, hdr=hdr
ptr_free, pdata

ia= where(mblocks.ftype eq 'A')
pdata=ptr_new(mblocks[ia])
yanny_write, $
  getenv('PLATEDESIGN_DIR')+'/data/marvels/fiberBlocksMARVELSBrightA.par', $
  pdata, hdr=hdr
ptr_free, pdata

ib= where(mblocks.ftype eq 'B')
pdata=ptr_new(mblocks[ib])
yanny_write, $
  getenv('PLATEDESIGN_DIR')+'/data/marvels/fiberBlocksMARVELSBrightB.par', $
  pdata, hdr=hdr
ptr_free, pdata

return
end
