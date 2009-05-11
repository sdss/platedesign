pro standards_check, plateid, pointing

if(keyword_set(pointing) eq 0) then $
  pointing=''
if(pointing eq 'A') then $
  pointing=''

if(pointing eq '') then pid='1'
if(pointing eq 'B') then pid='2'

plans= yanny_readone(getenv('PLATELIST_DIR')+'/platePlans.par')
iplate= where(plans.plateid eq plateid)
designid= plans[iplate].designid

standardfile= design_dir(designid)+'/plateStandardSDSS-'+ $
  strtrim(string(f='(i6.6)', designid),2)+'-p'+pid+'-o0.par'
standards= yanny_readone(standardfile)

infile= plate_dir(plateid)+'/plPlugMapP-'+ $
  strtrim(string(f='(i4.4)', plateid),2)+pointing+'.par'
pl= yanny_readone(infile,hdr=hdr)
hdrstr= lines2struct(hdr, /relax)
racen=double(hdrstr.racen)
deccen=double(hdrstr.deccen)

usno=usno_read(racen, deccen, 1.5)

if(n_tags(standards) gt 0) then begin
  ugriz= plate_tmass_to_sdss(standards.tmass_j, standards.tmass_h, $
                             standards.tmass_k)
  red_fac = [5.155, 3.793, 2.751, 2.086, 1.479 ]
  glactc, standards.target_ra, standards.target_dec, 2000., gl, gb, 1, /deg
  ebv= dust_getval(gl,gb)
  gmag= ugriz[1,*] ;;+ebv*red_fac[1]
  spherematch, standards.target_ra, standards.target_dec, $
    usno.ra, usno.dec, 2./3600., m1, m2
endif


;;splot, gmag[m1], usno[m2].mag[1], psym=4

iobj=where(pl.holetype eq 'OBJECT')
spherematch, pl[iobj].ra, pl[iobj].dec, $
  usno.ra, usno.dec, 2./3600., m1, m2
ii=where(pl[iobj[m1]].objtype eq 'SPECTROPHOTO_STD')
help,ii
;;soplot, pl[iobj[m1[ii]]].mag[1], usno[m2[ii]].mag[1], psym=6, color='green'

jj=where(pl[iobj[m1]].objtype eq 'SERENDIPITY_MANUAL')
help,jj
;;soplot, pl[iobj[m1[jj]]].mag[1], usno[m2[jj]].mag[1], psym=6, color='yellow'

;;spherematch, standards.target_ra, standards.target_dec, $
;;  usno.ra, usno.dec, 2./3600., sm1, sm2

;;splot, usno[sm2].mag[1], standards[sm1].priority, psym=4 

splot, usno.mag[0], usno.mag[0]-usno.mag[1], psym=3, xra=[8., 16.], yra=[-0.5, 4.5]
if(n_tags(standards) gt 0) then begin
  spherematch, standards.target_ra, standards.target_dec, $
    usno.ra, usno.dec, 2./3600., sm1, sm2
  soplot, usno[sm2].mag[0], usno[sm2].mag[0]-usno[sm2].mag[1], psym=4,color='red', th= 3
endif
soplot, usno[m2[ii]].mag[0], usno[m2[ii]].mag[0]-usno[m2[ii]].mag[1],psym=6, color='green', th=2
soplot, usno[m2[jj]].mag[0], usno[m2[jj]].mag[0]-usno[m2[jj]].mag[1],psym=6, color='yellow'

end
