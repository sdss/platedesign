pro fix_for_pm

epoch=2009.75
ralist=[311., 315., 330., 341.D, 356., 11., 26., 45., 60., 75.]
types= ['commiss', 'specphoto']

for i=0L, n_elements(ralist)-1L do begin
    ra=ralist[i]
    name='RA'+strtrim(string(long(ra)),2)
 
    for j=0L,1L do begin
      type= types[j]

      newname='plateInput_pmcorrect_'+type+'_'+name+'.par'
      oldname='plateInput_'+type+'_'+name+'.par'
    
      old= yanny_readone(oldname, hdr=hdr)
      new0= create_struct(old[0], 'mura', 0.D, 'mudec', 0.D, $
                          'orig_ra', 0.D, 'orig_dec', 0.D, $
                          'mjd', 0., 'orig_mjd', 0.)
      new= replicate(new0, n_elements(old))
      struct_assign, old, new
       
      ra=new.ra
      dec=new.dec
      new.orig_ra=new.ra
      new.orig_dec=new.dec
      new.orig_mjd=sdss_run2mjd(new.run)
      new.mjd = (epoch - 2000.)*365.25 + 51544.5d0
      mjd=new[0].mjd

      plate_pmotion_correct, ra, dec, from_mjd= new.orig_mjd, $
       to_mjd= mjd, mura=mura, mudec=mudec

      new.ra=ra
      new.dec=dec
      new.mura=mura
      new.mudec=mudec

      pdata= ptr_new(new)
      yanny_write, newname, pdata, hdr=hdr

   endfor
    
endfor
    
end
