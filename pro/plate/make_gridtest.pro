;+
; NAME:
;   make_gridtest
; PURPOSE:
;   Create a grid fiber test plate
; CALLING SEQUENCE:
;   make_gridtest
;  
; REVISION HISTORY:
;   29-Jul-2008 MRB, NYU 
;-
pro make_gridtest 

tilerad= 1.49
platescale = platescale('APO') ; mm/degree
spacing= 10. ; mm
nn= long(0.5*(2.1*tilerad*platescale/spacing))*2L+1L

racen= 180.
deccen= 0.

design0= create_struct(design_blank(), 'ra', 0.D, 'dec', 0.D)
design0.holetype='MARVELS'
design0.targettype='SKY'
design0.sourcetype='NA'
design0.pointing=1
design0.diameter=2.500
design0.buffer=0.076

space= spacing*(findgen(nn)-float(nn/2L))

design= replicate(design0, nn*nn)

design.xf_default= reform(space#replicate(1.,nn), nn*nn)
design.yf_default= reform(replicate(1.,nn)#space, nn*nn)

rr= sqrt(design.xf_default^2+design.yf_default^2)
ikeep=where(rr lt 324.500)
design=design[ikeep]

xyfocal2ad, 'APO', design.xf_default, design.yf_default, ra, dec, $
            racen=racen, deccen=deccen

design.target_ra= ra
design.target_dec= dec
design.ra= ra
design.dec= dec

hdr=['targettype SKY', $
     'instrument SDSS', $
     'raCen '+strtrim(string(racen,f='(f40.10)'),2), $
     'decCen '+strtrim(string(deccen,f='(f40.10)'),2), $
     'epoch 2009.', $
     'pointing 1']

pdata= ptr_new(design)
yanny_write, getenv('PLATELIST_DIR')+ $
  '/inputs/gridtest/plateInput-gridtest-000098.par', pdata, hdr=hdr
ptr_free, pdata

end

