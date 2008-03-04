;+
; NAME:
;   plate_qsos_feb08
; PURPOSE:
;   run plate for the October 2007 MARVELS plate run
; CALLING SEQUENCE:
;   plate_marvels_oct07
; REVISION HISTORY:
;   11-Oct-2007  MRB, NYU
;-
;------------------------------------------------------------------------------
pro plate_qsos_feb08,doplot=doplot

cd, getenv('PLATEDESIGN_DIR')+'/data/inputs/boss/feb-2008'
epoch = 2008.13

filebases=['plate1943ra144.579895dec32.577969', $
           'plate1949ra149.856903dec32.124512', $
           'plate890ra118.400299dec31.940149', $
           'plate1209ra130.422195dec32.249088', $
           'plate1592ra139.6978dec32.798649', $
           'plate861ra123.218803dec31.58687']

pst=2957L
tst=9567L
for i=0L, n_elements(filebases)-1L do begin
    plate_qsos, filebases[i], tilenum=tst+i, platenum=pst+i, epoch=epoch, $
      doplot=doplot
endfor

return

end
