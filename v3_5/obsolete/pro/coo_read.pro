;+
; NAME:
;   coo_read
; PURPOSE:
;   Read a MARVELS style .coo files
; CALLING SEQUENCE:
;   coo= coo_read(file [, racen=, deccen=])
; INPUTS:
;   file - filename of .coo file
; OUTPUTS:
;   racen, deccen - RA and Dec center
;   coo - structure with information:
;            .RA
;            .DEC
;            .HOLETYPE
;            .OBJTYPE
; COMMENTS:
;   HOLETYPE is: 'OBJECT' for any sort of target with a regular fiber
;                'GUIDE' for guide fibers
;   OBJTYPE is: 'SERENDIPITY_MANUAL' for MARVELS targets
;               'REDDEN_STD' for reddening standards  
;               'SPECTROPHOTO_STD' for spectrophotometric standards  
;               'SKY' for blank sky fibers
; REVISION HISTORY:
;   11-Oct-2007  MRB, NYU
;-
;------------------------------------------------------------------------------
function coo_read, file, racen=racen, deccen=deccen

   stardata1 = create_struct( $
    'RA'       , 0.D, $
    'DEC'      , 0.D, $
    'MAG'      , fltarr(5), $
    'HOLETYPE' , '', $
    'OBJTYPE'  , '', $
    'PRIORITY' , 0L )

nlines=numlines(file)
coo=replicate(stardata1, nlines)

openr, unit, file, /get_lun

center=''
while(strmatch(center, 'Center:*') eq 0) do begin
    readf, unit, center
endwhile
words=strsplit(center,/extr)
racen=double(words[1])
deccen=double(words[2])

targets=''
while(strmatch(targets, 'Targets:*') eq 0) do begin
    readf, unit, targets
endwhile
readf, unit, targets

iobj=0L
incoord=''
readf, unit, incoord
while(incoord ne ' ') do begin
    words=strsplit(incoord,/extr)
    coo[iobj].ra=double(words[0])
    coo[iobj].dec=double(words[1])
    coo[iobj].holetype='OBJECT'
    coo[iobj].objtype='SERENDIPITY_MANUAL'
    iobj=iobj+1L
    readf, unit, incoord
endwhile
readf, unit, incoord
readf, unit, incoord

incoord=''
readf, unit, incoord
while(incoord ne ' ') do begin
    words=strsplit(incoord,/extr)
    coo[iobj].ra=double(words[0])
    coo[iobj].dec=double(words[1])
    coo[iobj].holetype='GUIDE'
    coo[iobj].objtype='NA'
    iobj=iobj+1L
    readf, unit, incoord
endwhile
readf, unit, incoord
readf, unit, incoord

incoord=''
readf, unit, incoord
while(incoord ne ' ') do begin
    words=strsplit(incoord,/extr)
    coo[iobj].ra=double(words[0])
    coo[iobj].dec=double(words[1])
    coo[iobj].holetype='OBJECT'
    coo[iobj].objtype='REDDEN_STD'
    iobj=iobj+1L
    readf, unit, incoord
endwhile
readf, unit, incoord
readf, unit, incoord

incoord=''
readf, unit, incoord
while(incoord ne ' ') do begin
    words=strsplit(incoord,/extr)
    coo[iobj].ra=double(words[0])
    coo[iobj].dec=double(words[1])
    coo[iobj].holetype='OBJECT'
    coo[iobj].objtype='SPECTROPHOTO_STD'
    iobj=iobj+1L
    readf, unit, incoord
endwhile
readf, unit, incoord
readf, unit, incoord

incoord=''
readf, unit, incoord
while(incoord ne ' ') do begin
    words=strsplit(incoord,/extr)
    coo[iobj].ra=double(words[0])
    coo[iobj].dec=double(words[1])
    coo[iobj].holetype='OBJECT'
    coo[iobj].objtype='SKY'
    iobj=iobj+1L
    if(NOT eof(unit)) then $
      readf, unit, incoord $
    else $
      incoord=' '
endwhile

free_lun, unit

coo=coo[0:iobj-1]

return, coo

end
