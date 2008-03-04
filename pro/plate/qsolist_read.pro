;+
; NAME:
;   qsolist_read
; PURPOSE:
;   Read a QSO list of the sort from Adam Myers	
; CALLING SEQUENCE:
;   qsos= qsolist_read(file, racen=, deccen=)
; INPUTS:
;   file - filename of .coo file
; OUTPUTS:
;   racen, deccen - RA and Dec center
;   qsos - structure with information:
;            .RA
;            .DEC
; REVISION HISTORY:
;   11-Oct-2007  MRB, NYU
;-
;------------------------------------------------------------------------------
function qsolist_read, file, racen=racen, deccen=deccen

qso1 = create_struct( $
                      'RA'       , 0.D, $
                      'DEC'      , 0.D, $
                      'UMG'      , 0., $
                      'GMR'      , 0., $
                      'RMI'      , 0., $
                      'IMZ'      , 0., $
                      'G'      , 0., $
                      'AU'      , 0., $
                      'QSOPROB'      , 0., $
                      'STARPROB'      , 0., $
                      'ZLOW'      , 0., $
                      'ZPHOT'      , 0., $
                      'ZHIGH'      , 0., $
                      'ZPROB'      , 0., $
                      'PRIORITY' , 0L )

nlines=numlines(file)-1L
qsos=replicate(qso1, nlines)

words=stregex(file, 'plate.*ra(.*)dec(.*)\.dr.\.(.*)', /extr, /sub)
racen=double(words[1])
deccen=double(words[2])
type=words[3]

splog, type
if(type eq 'hipriority') then begin
    readcol, file, comment='#', $
      f='(l,l,d,d,f,f,f,f,f,f,f,f)', $
      nn, objid, ra, dec, umg, gmr, rmi, imz, g, au, qsoprob, starprob
    qsos.priority= 1
endif else begin
    readcol, file, comment='#', $
      f='(l,f,f,f,f,l,d,d,f,f,f,f,f,f,f,f)', $
      nn, zlow, zphot, zhigh, zprob, objid, ra, dec, umg, gmr, rmi, imz, $
      g, au, qsoprob, starprob
    qsos.zlow=zlow
    qsos.zhigh=zhigh
    qsos.zphot=zphot
    qsos.zprob=zprob
    qsos.priority= 100
endelse

qsos.ra=ra
qsos.dec=dec
qsos.umg=umg
qsos.gmr=gmr
qsos.rmi=rmi
qsos.imz=imz
qsos.g=g
qsos.au=au
qsos.qsoprob=qsoprob
qsos.starprob=starprob

return, qsos

end
