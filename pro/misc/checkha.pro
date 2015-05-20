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
        ad2xyfocal, 'APO', ra, dec, xf, yf, racen=locs[i].ra, deccen=locs[i].dec, $
                    airtemp=randomu(seed)*15., lst=lst
        
        lst= locs[i].ra+haobs[i]
        ad2xyfocal, 'APO', ra, dec, hxf, hyf, racen=locs[i].ra, deccen=locs[i].dec, $
                    airtemp=randomu(seed)*15., lst=lst
        

        th= (findgen(300)/300.-0.5)*20.*!DPI/180.
        offsig= fltarr(n_elements(th))
        for ith=0L, n_elements(th)-1L do begin

            pxf= hxf*cos(th[ith])+hyf*sin(th[ith])
            pyf= -hxf*sin(th[ith])+hyf*cos(th[ith])

            xoff=mean(xf-pxf)
            yoff=mean(yf-pyf)
            
            pxf=pxf+xoff
            pyf=pyf+yoff
            
            rad= sqrt(xf^2+yf^2)
            hrad= sqrt(pxf^2+pyf^2)
            scale= median(rad/hrad)
            
            pxf=pxf*scale
            pyf=pyf*scale

            offsig[ith]= djsig((xf-pxf)^2+(yf-pyf)^2)
        endfor
        minoffsig=min(offsig, imin)
        
        help, xoff, yoff, scale

        pxf= hxf*cos(th[imin])+hyf*sin(th[imin])
        pyf= -hxf*sin(th[imin])+hyf*cos(th[imin])
        
        xoff=mean(xf-pxf)
        yoff=mean(yf-pyf)
        
        pxf=pxf+xoff
        pyf=pyf+yoff
        
        rad= sqrt(xf^2+yf^2)
        hrad= sqrt(pxf^2+pyf^2)
        scale= median(rad/hrad)
        
        pxf=pxf*scale
        pyf=pyf*scale
        
        doff= sqrt((xf-pxf)^2+(yf-pyf)^2)

        mdoff[i]= max(doff)
    endfor

    mdoff=mdoff/ platescale('APO')*3600.
    
    save, filename='~/checkha-'+strtrim(string(hadesvals[k], f='(i2.2)'),2)+ $
          '.sav'
endfor

end
