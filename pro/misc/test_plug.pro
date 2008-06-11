pro test_plug

platescale = 217.7358           ; mm/degree
th= randomu(seed, 640)*2.*!DPI
r2= randomu(seed, 640)*1.49
xx= platescale*sqrt(r2)*cos(th)
yy= platescale*sqrt(r2)*sin(th)

a=yanny_readone('plPlugMapP-0001.par')
ii=where(a.fiberid le -1 and a.fiberid ge -640)
a=a[ii]

xx=a.xfocal
yy=a.yfocal

indx=shuffle_indx(640, num_sub=300)
first=lonarr(640)
first[indx]=1


indx1=where(first eq 1)
a1=a[indx1]
xx1=a1.xfocal
yy1=a1.yfocal

indx2=where(first eq 0)
a2=a[indx2]
xx2=a2.xfocal
yy2=a2.yfocal

sdss_plugprob, xx1, yy1, fiberid1, limitdegree=0.2, /quiet

sdss_plugprob, xx2, yy2, fiberid2, fiberused=fiberid1

fiberid=lonarr(640)
fiberid[indx1]=fiberid1
fiberid[indx2]=fiberid2

block= (fiberid-1L)/20L+1L
;;block= (abs(a.fiberid)-1L)/20L+1L

splot, xx, yy, psym=3

colors=['green', 'red', 'cyan', 'yellow', 'white']
for i=1L, 32L do begin 
    ii=where(block eq i)
    isort=ii[sort(fiberid[ii])]
    color=colors[(i-1) mod n_elements(colors)]
    soplot, xx[isort], yy[isort], th=3, color=color
endfor

end
