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
tmass= tmass_read(racen, deccen, 1.49)
tycho= tycho_read(racen=racen, deccen=deccen, radius=1.49)


end
;------------------------------------------------------------------------------
