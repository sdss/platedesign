;+
; NAME:
;   plate_marvels_oct07
; PURPOSE:
;   run plate for the October 2007 MARVELS plate run
; CALLING SEQUENCE:
;   plate_marvels_oct07
; REVISION HISTORY:
;   11-Oct-2007  MRB, NYU
;-
;------------------------------------------------------------------------------
pro plate_marvels_oct07,doplot=doplot

cd, getenv('PLATEDESIGN_DIR')+'/data/inputs/marvels/oct-2007'
epoch = 2007.9

files=['WASP1.Segue.coo', $
       'HD68988.Segue.coo', $
       'HD43691.Segue.coo', $
       'HD37605.Segue.coo', $
       'HD209458.Segue.coo', $
       'HD17156.Segue.coo', $
       'HD17092.Segue.coo', $
       'HATP1.Segue.coo', $
       'GL273.Segue.coo', $
       'HD49674.Segue.coo']

pst=2838L
tst=9556L
;for i=9L, n_elements(files)-1L do begin
for i=8L, 8L do begin
    plate_marvels, files[i], tilenum=tst+i, platenum=pst+i, epoch=epoch, $
      doplot=doplot
endfor

return

end
