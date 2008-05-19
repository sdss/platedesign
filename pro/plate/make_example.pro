;+
; NAME:
;   make_example
; PURPOSE:
;   make input files for example
; CALLING SEQUENCE:
;   make_example
; REVISION HISTORY:
;   17-May-2008  MRB, NYU
;-
;------------------------------------------------------------------------------
pro make_example

racen= 101.537
deccen= 60. 

usnob= usno_read(racen, deccen, 1.49)
target1={ra:0.D, $
         dec:0.D, $
         sourcetype:'STAR', $
         priority:10L}

indx=shuffle_indx(n_elements(usnob), num_sub=1000)
targets=replicate(target1, n_elements(indx))
targets.ra= usnob[indx].ra
targets.dec= usnob[indx].dec
pdata= ptr_new(targets)
hdr=['pointing 1', 'offset 0', 'instrument SDSS', 'targettype science']
yanny_write, getenv('PLATELIST_DIR')+ $
             '/inputs/example/plateInput-000000-usno.par', $
             pdata, hdr=hdr

tycho= tycho_read(racen=racen, deccen=deccen, radius=1.49)
targets=replicate(target1, n_elements(tycho))
targets.ra= tycho.ramdeg
targets.dec= tycho.demdeg
pdata= ptr_new(targets)
hdr=['pointing 1', 'offset 1', 'instrument SDSS', 'targettype science']
yanny_write, getenv('PLATELIST_DIR')+ $
             '/inputs/example/plateInput-000000-tycho1.par', $
             pdata, hdr=hdr

racen= 150.001
deccen= 10.001

tmass= tmass_read(racen, deccen, 1.49)
indx=shuffle_indx(n_elements(tmass), num_sub=1000)
targets=replicate(target1, n_elements(indx))
targets.ra= tmass[indx].tmass_ra
targets.dec= tmass[indx].tmass_dec
pdata= ptr_new(targets)
hdr=['pointing 2', 'offset 0', 'instrument SDSS', 'targettype science']
yanny_write, getenv('PLATELIST_DIR')+ $
             '/inputs/example/plateInput-000000-tmass.par', $
             pdata, hdr=hdr

tycho= tycho_read(racen=racen, deccen=deccen, radius=1.49)
targets=replicate(target1, n_elements(tycho))
targets.ra= tycho.ramdeg
targets.dec= tycho.demdeg
pdata= ptr_new(targets)
hdr=['pointing 2', 'offset 1', 'instrument SDSS', 'targettype science']
yanny_write, getenv('PLATELIST_DIR')+ $
             '/inputs/example/plateInput-000000-tycho2.par', $
             pdata, hdr=hdr

         

end
;------------------------------------------------------------------------------
