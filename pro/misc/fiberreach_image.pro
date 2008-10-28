function fiberreach_image

limitdegree=8.*0.1164 ;; limit of fiber reach in degrees (n * degrees/inch)

blockfile=getenv('PLATEDESIGN_DIR')+'/data/marvels/fiberBlocksMarvels.par'
fiberblocks= yanny_readone(blockfile)

nn=801L
cen=float(nn/2L)

image= fltarr(nn, nn)
scale=((findgen(nn)-cen)/float(nn)*1.50*2.)
xx=scale#replicate(1., nn)
yy=replicate(1., nn)#scale

for i=0L, n_elements(fiberblocks)-1L do begin
    rr2= (fiberblocks[i].fibercenx-xx)^2+(fiberblocks[i].fiberceny-yy)^2
    iin= where(rr2 lt limitdegree^2, nin)
    if(nin gt 0) then $
      image[iin]=image[iin]+1L
endfor

rr2= xx^2+yy^2
iout= where(rr2 gt 1.49^2, nout)
if(nout gt 0) then $
  image[iout]=-1.

return, image

end
