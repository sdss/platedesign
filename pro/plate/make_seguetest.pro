;+
; NAME:
;   make_seguetest
; PURPOSE:
;   Create a SEGUE fiber test plate
; CALLING SEQUENCE:
;   make_seguetest
; COMMENTS:
;   Prepares designid 99, by producing the files:
;      $PLATELIST_DIR/inputs/seguetest/plateInput-SEGUEtest-000099.par
;      $PLATELIST_DIR/designs/0000XX/000099/plateGuide-000099-p1.par
; REVISION HISTORY:
;   29-Jul-2008 MRB, NYU 
;    1-Sep-2010 Demitri Muna, NYU, Adding file test before opening files.
;-
pro make_seguetest 

platescale = 217.7358D           ; mm/degree
fiberblocks_file = getenv('PLATEDESIGN_DIR')+'/data/sdss/fiberBlocks.par'
check_file_exists, fiberblocks_file
fibers= yanny_readone(fiberblocks_file)

racen= 180.
deccen= 0.

design0= create_struct(design_blank(), 'ra', 0.D, 'dec', 0.D)
design0.holetype='SDSS'
design0.targettype='SKY'
design0.sourcetype='NA'
design0.pointing=1
design0.diameter=3.175
design0.buffer=0.076

design= replicate(design0, n_elements(fibers))
design.target_ra= racen+ fibers.fibercenx
design.target_dec= deccen+ fibers.fiberceny
design.ra= design.target_ra
design.dec= design.target_dec

hdr=['targettype SKY', $
     'instrument SDSS', $
     'raCen '+strtrim(string(racen,f='(f40.10)'),2), $
     'decCen '+strtrim(string(deccen,f='(f40.10)'),2), $
     'epoch 2009.', $
     'pointing 1']

pdata= ptr_new(design)
yanny_write, getenv('PLATELIST_DIR')+ $
  '/inputs/seguetest/plateInput-SEGUEtest-000099.par', pdata, hdr=hdr
ptr_free, pdata

gfiber= gfiber_params()

guide0= create_struct(design_blank(/guide), 'ra', 0.D, 'dec', 0.D)
guide0.diameter=6.9555
guide0.buffer=0.3000 
guide0.pointing=1

guide=replicate(guide0, 11)
guide.target_ra= racen+gfiber.xprefer/platescale
guide.target_dec= deccen+gfiber.yprefer/platescale
guide.ra= guide.target_ra
guide.dec= guide.target_dec

ad2xyfocal, guide.ra, guide.dec, xf, yf, racen=racen, deccen=deccen
guide.xf_default= xf
guide.yf_default= yf

pdata= ptr_new(guide)
yanny_write, getenv('PLATELIST_DIR')+ $
  '/designs/0000XX/000099/plateGuide-000099-p1.par', pdata, hdr=hdr
ptr_free, pdata

end

