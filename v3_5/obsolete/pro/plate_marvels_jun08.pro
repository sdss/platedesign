;+
; NAME:
;   plate_marvels_jun08
; PURPOSE:
;   run plate for the June 2008 MARVELS plate run
; CALLING SEQUENCE:
;   plate_marvels_jun08
; REVISION HISTORY:
;   11-Oct-2007  MRB, NYU
;   12-May-2008  PH,  CWRU : added the 15 fieldnames
;-
;------------------------------------------------------------------------------
pro plate_marvels_jun08,doplot=doplot, nodesign=nodesign

cd, getenv('PLATEDESIGN_DIR')+'/data/inputs/marvels/june-2008'
epoch = 2008.564

fieldnames=[ '47UMA', $            ;;0
             'GJ436', $            ;;1 
             'HD118203', $         ;;2 
             'HAT-P-3', $          ;;3 
             'HAT-P-4', $          ;;4 
             'XO-1', $             ;;5 
             'KEPLER3.TRES-2', $   ;;6 
             'HD178911B', $        ;;7 
             'KEPLER2', $          ;;8 
             'HD185144', $         ;;9 
             'K14', $              ;;10
             'HD209458', $         ;;11
             '51PEG', $            ;;12
             'HAT-P-1', $          ;;13
             'HD219828']           ;;14

has= [ 4., $
       3., $
       1.5, $
       1.5, $
       1.5, $
       0., $
       0., $
       0., $
       0., $
       0., $
       0., $
       -1.5,  $
       -2.5, $
       -2.5, $
       -2.5]

pst=3000L
tst=9600L
for i=0L, n_elements(fieldnames)-1L do begin
    plate_marvels_new, fieldnames[i], tilenum=tst+i, platenum=pst+i, $
      epoch=epoch, doplot=doplot, nodesign=nodesign, ha=has[i]
endfor

return

end
