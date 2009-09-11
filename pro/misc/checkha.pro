pro checkha

locs= mrdfits(getenv('BOSSTILELIST_DIR')+'/geometry/boss_locations.fits',1)

hadesvals=[ 0., 15., 30.]

for k=0L, n_elements(hadesvals)-1L do begin
    hades= fltarr(n_elements(locs))+hadesvals[k]
    haobs= hades+randomu(seed, n_elements(locs))*120.-45.
    
    nfib=250L
    mdoff= fltarr(n_elements(locs))
    for i=0L, n_elements(locs)-1L do begin
        radius2= randomu(seed, nfib)*1.49^2
        radius= sqrt(radius2)
        theta= !DPI*2.*randomu(seed, nfib)
        xx= radius*cos(theta)
        yy= radius*sin(theta)
        ra= locs[i].ra+xx/cos(!DPI/180.*locs[i].dec)
        dec= locs[i].dec+yy
        
        lst= locs[i].ra+hades[i]
        ad2xyfocal, ra, dec, xf, yf, racen=locs[i].ra, deccen=locs[i].dec, $
                    airtemp=randomu(seed)*15., lst=lst
        
        lst= locs[i].ra+haobs[i]
        ad2xyfocal, ra, dec, hxf, hyf, racen=locs[i].ra, deccen=locs[i].dec, $
                    airtemp=randomu(seed)*15., lst=lst
        
        xoff=mean(xf-hxf)
        yoff=mean(yf-hyf)
        
        hxf=hxf+xoff
        hyf=hyf+yoff
        
        rad= sqrt(xf^2+yf^2)
        hrad= sqrt(hxf^2+hyf^2)
        scale= median(rad/hrad)
        
        hxf=hxf*scale
        hyf=hyf*scale
        
        help, xoff, yoff, scale
        
        doff= sqrt((xf-hxf)^2+(yf-hyf)^2)
        mdoff[i]= max(doff)
    endfor

    mdoff=mdoff/ 217.7*3600.
    
    save, filename='~/checkha-'+strtrim(string(hadesvals[k], f='(i2.2)'),2)+ $
          '.sav'
endfor

end
