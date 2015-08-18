pro guides_check, plateid, pointing

if(keyword_set(pointing) eq 0) then $
  pointing=''
if(pointing eq 'A') then $
  pointing=''

if(pointing eq '') then pid='1'
if(pointing eq 'B') then pid='2'

plans= yanny_readone(getenv('PLATELIST_DIR')+'/platePlans.par')
iplate= where(plans.plateid eq plateid)
designid= plans[iplate].designid

infile= plate_dir(plateid)+'/plPlugMapP-'+ $
  strtrim(string(f='(i4.4)', plateid),2)+pointing+'.par'
pl= yanny_readone(infile,hdr=hdr)
hdrstr= lines2struct(hdr, /relax)
racen=double(hdrstr.racen)
deccen=double(hdrstr.deccen)

usno=usno_read(racen, deccen, 1.5)

iguide=where(pl.holetype eq 'GUIDE')
spherematch, pl[iguide].ra, pl[iguide].dec, $
  usno.ra, usno.dec, 2./3600., m1, m2
help,m1
print,pl[iguide].fiberid
print,pl[iguide[m1]].fiberid
splot, pl[iguide[m1]].mag[1], usno[m2].mag[1], psym=6


end
