pro check_collisions

midlst=180.
maxha=50.
mindec=-15.
maxdec=75.
mintemp=-10.
maxtemp=15.
nplates=1000L
seed=1001L
nobj=3000L
tilerad=1.49

lst=midlst+(randomu(seed, nplates)-0.5)*2.*maxha
racen= replicate(180., nplates)
deccen= mindec+(maxdec-mindec)*randomu(seed, nplates)
airtemp= mintemp+(maxtemp-mintemp)*randomu(seed, nplates)

for i=0L, nplates-1L do begin
    help, i
    radius2= tilerad^2*randomu(seed, nobj)
    radius= sqrt(radius2)
    theta= randomu(seed, nobj)*!DPI*2.
    dra= radius*cos(theta)
    ddec= radius*sin(theta)
    
    ra=racen[i]+dra/cos(!DPI/180.*deccen[i])
    dec=deccen[i]+ddec
    
    lambda= replicate(5500., nobj)
    indx=shuffle_indx(nobj, num_sub=nobj/2L)
    lambda[indx]=4000.

    ad2xyfocal, ra, dec, xf, yf, racen=racen[i], deccen=deccen[i], $
      airtemp=airtemp[i], lst=lst[i], lambda=lambda

    spherematch, ra, dec, ra, dec, 65./3600., m1, m2, d12, max=0
    ii=where(m1 ne m2, nii)
    if(nii gt 0) then begin
        m1=m1[ii]
        m2=m2[ii]
        tmp_dangle= d12[ii]*3600.
        tmp_dfocal= sqrt((xf[m1]-xf[m2])^2+(yf[m1]-yf[m2])^2)
        if(n_elements(dangle) gt 0) then begin
            dangle=[dangle,tmp_dangle]
            dfocal=[dfocal,tmp_dfocal]
            dlambda=[dlambda, lambda[ii]]
            dha=[dha, replicate(lst[i]-racen[i], nii)]
            sdec=[sdec, replicate(deccen[i], nii)]
            stemp=[stemp, replicate(airtemp[i], nii)]
        endif else begin
            dangle=tmp_dangle
            dfocal=tmp_dfocal
            dlambda= lambda[ii]
            dha=replicate(lst[i]-racen[i], nii)
            sdec=replicate(deccen[i], nii)
            stemp=replicate(airtemp[i], nii)
        endelse
    endif
endfor


;; On plate 3523, these objects collided:
;; IDL> help,/st,a[m1[14]]
;; ** Structure PLUGMAPOBJ, 16 tags, length=144, data length=136:
   ;; OBJID           LONG      Array[5]
   ;; HOLETYPE        STRING    'OBJECT'
   ;; RA              DOUBLE           25.400679
   ;; DEC             DOUBLE           1.1697189
   ;; MAG             FLOAT     Array[5]
   ;; STARL           FLOAT           0.00000
   ;; EXPL            FLOAT           0.00000
   ;; DEVAUCL         FLOAT           0.00000
   ;; OBJTYPE         STRING    'SPECTROPHOTO_STD'
   ;; XFOCAL          DOUBLE          -130.59111
   ;; YFOCAL          DOUBLE           254.89040
   ;; SPECTROGRAPHID  LONG                 0
   ;; FIBERID         LONG              -854
   ;; THROUGHPUT      LONG                 0
   ;; PRIMTARGET      LONG                 0
   ;; SECTARGET       LONG                 0
;; IDL> help,/st,a[m2[14]]
;; ** Structure PLUGMAPOBJ, 16 tags, length=144, data length=136:
   ;; OBJID           LONG      Array[5]
   ;; HOLETYPE        STRING    'OBJECT'
   ;; RA              DOUBLE           25.394545
   ;; DEC             DOUBLE           1.1855685
   ;; MAG             FLOAT     Array[5]
   ;; STARL           FLOAT           0.00000
   ;; EXPL            FLOAT           0.00000
   ;; DEVAUCL         FLOAT           0.00000
   ;; OBJTYPE         STRING    'SKY'
   ;; XFOCAL          DOUBLE          -131.93589
   ;; YFOCAL          DOUBLE           258.36130
   ;; SPECTROGRAPHID  LONG                 0
   ;; FIBERID         LONG              -856
   ;; THROUGHPUT      LONG                 0
   ;; PRIMTARGET      LONG                 0
   ;; SECTARGET       LONG                 0
;; Schlegel claimed to be able to plug them. Their focal plane
;; distance from each other was 3.72231 mm, or 61.18 arcsec in this
;; case.


k_print, filename='check_collisions.ps'

hogg_usersym, 20, /fill
djs_plot, dangle, dfocal, psym=8, symsize=0.15, xra=[60., 65.], $
  xti='Angular distance (arcsec)', yti='Focal plane distance (mm)'
djs_oplot, [61.18, 61.18], [3.72231, 3.72231], psym=8, symsize=0.8, color='red'
djs_oplot, [61.18, 63.], [3.72231, 3.72231], linest=0, th=2, color='red'
djs_oplot, [63., 63.], [0., 5.], color='red', th=2

k_end_print

save

end
