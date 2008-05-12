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
pro plate_marvels_jun08,doplot=doplot, nodesign=nodesign

cd, getenv('PLATEDESIGN_DIR')+'/data/inputs/marvels/june-2008'
epoch = 2008.564

fieldnames=[ '47UMA', $  ;; FEW TARGETS! NOT ENOUGH SKY GOTTEN
'51PEG', $
'FIELD1068', $
'FIELD1096', $
'FIELD1110', $
'FIELD1348', $
'FIELD1349', $
'FIELD1360', $
'FIELD1572', $
'FIELD1623', $
'FIELD1631', $
'FIELD1656', $
'FIELD1661', $
'FIELD1664', $
'GJ176', $
'GJ436', $
'GL273', $
'HAT-P-3', $
'HAT-P-4', $
'HD118203', $
'HD17092', $
'HD17156', $
'HD178911B', $
'HD185144', $
'HD219828', $
'HD30339', $
'HD37605', $
'HD4203', $
'HD43691', $
'HD46375', $
'HD49674', $
'HD68988', $
'HD80606', $
'HD88133', $
'HD89307', $
'HD89744', $
'HIP14810', $
'K10', $
'K14', $
'K15', $
'K19', $
'K20', $
'K21', $
'K4', $
'K5', $
'K7', $
'K8', $
'K9', $
'KEPLER2', $
'KEPLER3.TRES-2', $
'KEPLER4', $
'WASP-1', $
'XO-1', $
'XO-2']


pst=3000L
tst=9900L
for i=0L, n_elements(fieldnames)-1L do begin
    plate_marvels_new, fieldnames[i], tilenum=tst+i, platenum=pst+i, $
      epoch=epoch, doplot=doplot, nodesign=nodesign
endfor

return

end
