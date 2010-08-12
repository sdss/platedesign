;+
; NAME:
;   make_hexpack
; PURPOSE:
;   Create a (nearly) maximally dense hexagonal-pack plate
; CALLING SEQUENCE:
;   make_hexpack
;  
; REVISION HISTORY:
;   11-Aug-2010 ASB, Utah
;   following make_gridtest 29-Jul-2008 MRB, NYU 
;-
pro make_hexpack

tilerad= 0.5 ; degrees
platescale = 217.7358D           ; mm/degree
spacing = (1. / 60.) * platescale   ; mm

; Make a comfortably over-sized baseline and downselect:
nn = 4L * ceil(platescale * tilerad / spacing) + 1L
ii = (findgen(nn) - nn/2) # replicate(1., nn)
jj = transpose(ii)
xx = spacing * (ii + 0.5 * jj)
yy = (sqrt(3.) / 2.) * spacing * jj
rr = sqrt(xx^2 + yy^2)
ikeep = where(rr lt (tilerad * platescale), nkeep)

xx = (xx[*])[ikeep]
yy = (yy[*])[ikeep]

racen= 180.
;deccen= 32.7803
deccen = 0.

design0= create_struct(design_blank(), 'ra', 0.D, 'dec', 0.D)
design0.holetype='BOSS'
design0.targettype='SKY'
design0.sourcetype='NA'
design0.pointing=1
design0.diameter=2.500
design0.buffer=0.076

design= replicate(design0, nkeep)

design.xf_default= xx
design.yf_default= yy

xyfocal2ad, design.xf_default, design.yf_default, ra, dec, $
            racen=racen, deccen=deccen, /norefrac

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
  '/inputs/gridtest/plateInput-hexpack-000098.par', pdata, hdr=hdr
ptr_free, pdata

end

