;+
; NAME:
;   lrgs2tiinput
; PURPOSE:
;   Put LRG files into tiInput format
; CALLING SEQUENCE:
;   lrgs2tiinput
; REVISION HISTORY:
;   25-Sep-2007  MRB, NYU
;-
;------------------------------------------------------------------------------
pro lrgs2tiinput

ti0=mrdfits(getenv('PLATEDESIGN_DIR')+'/data/strategy/tiInputFormat.fit',1)

sgcfile=getenv('PLATEDESIGN_DATA')+'/strategy/lrgs/sgc-lrgs.fits'
slrgs=mrdfits(sgcfile, 1)

sti=replicate(ti0, n_elements(slrgs))
struct_assign, slrgs, sti
slrgs=0

ngcfile=getenv('PLATEDESIGN_DATA')+'/strategy/lrgs/ngc-lrgs.fits'
nlrgs=mrdfits(ngcfile, 1)

nti=replicate(ti0, n_elements(nlrgs))
struct_assign, nlrgs, nti
nlrgs=0

ti=[nti, sti]
nti=0
sti=0
ti.priority=1.

spawn, 'mkdir -p '+getenv('PLATEDESIGN_DATA')+'/strategy/lrgs/tiling'
mwrfits, ti, getenv('PLATEDESIGN_DATA')+'/strategy/lrgs/tiling/tiInput.fit', $
  /create

end
