pro fix_kyle

ralist=[311., 315., 330., 341.D, 356., 11., 26., 45., 60., 75.]

for i=0L, n_elements(ralist)-1L do begin
    ra=ralist[i]
    name='RA'+strtrim(string(long(ra)),2)
    newname='plateInput_commiss_'+name+'.par'
    spname='plateInput_specphoto_'+name+'.par'
    oldname='origPlateInput_commiss_'+name+'.par'
    
    old= yanny_readone(oldname, hdr=hdr)
    issp= lonarr(n_elements(old))
    
    spherematch, ra, 0.D, old.ra, old.dec, 1.49, m1, m2, max=0
    sp=old[m2]
    ing=spheregroup(sp.ra, sp.dec, 65./3600., firstg=firstg)
    ng= max(ing)+1L
    firstg=firstg[0:ng-1L]
    sp= sp[firstg]
    
    isort= sort(sp.priority)
    indx=lindgen(20)
    sp=sp[isort[indx]]
    issp[m2[firstg[isort[indx]]]]=1
    
    inot= where(issp eq 0) 
    new=old[inot]
    
    pdata= ptr_new(new)
    yanny_write, newname, pdata, hdr=hdr
    
    pdata= ptr_new(sp)
    yanny_write, spname, pdata, hdr=hdr
endfor
    
end
