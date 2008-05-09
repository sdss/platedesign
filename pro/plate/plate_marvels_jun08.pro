;+
; NAME:
;   plate_marvels_jun08
; PURPOSE:
;   run plate for the October 2007 MARVELS plate run
; CALLING SEQUENCE:
;   plate_marvels_jun08
; REVISION HISTORY:
;   11-Oct-2007  MRB, NYU
;-
;------------------------------------------------------------------------------
pro plate_marvels_jun08,doplot=doplot

cd, getenv('PLATEDESIGN_DIR')+'/data/inputs/marvels/june-2008'
epoch = 2008.564

fieldnames=['testE2008']

pst=3000L
tst=9900L
for i=0L, n_elements(fieldnames)-1L do begin
    plate_marvels_new, fieldnames[i], tilenum=tst+i, platenum=pst+i, $
      epoch=epoch, doplot=doplot
endfor

return

end
