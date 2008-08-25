;+
; NAME:
;   radec2kml
; PURPOSE:
;   create kml file with placemarks for a set of RAs and Decs
; CALLING SEQUENCE:
;   radec2kml, ra, dec, kmlfile 
; INPUTS:
;   ra, dec - J2000 coords, deg
; COMMENTS:
;   Puts outputs into the file kmlfile.
; REVISION HISTORY:
;   01-May-2008  Written by MRB (NYU)
;-
;------------------------------------------------------------------------------
pro radec2kml, ra, dec, kmlfile, description=description, $
               color=color, name=name

words=strsplit(kmlfile, '/', /extr)
kmlfilelast=words[n_elements(words)-1]

openw, unit, kmlfile, /get_lun

printf, unit, '<?xml version="1.0" encoding="UTF-8"?>'
printf, unit, '<kml xmlns="http://earth.google.com/kml/2.2" hint="target=sky">'
printf, unit, '<Document>'
printf, unit, '<name>'+kmlfilelast+'</name>'
printf, unit, '<description>Trying ra and dec.</description>'

offset=180.
ramoffset=ra-offset
printf, unit, '<Style id="circleIcon">'
printf, unit, '<IconStyle>'
if(keyword_set(color)) then begin
    printf, unit, '<color>'+color+'</color>'
endif
printf, unit, '<Icon><href>'+getenv('PLATEDESIGN_DIR')+'/data/test/icon.png</href></Icon>'
printf, unit, '</IconStyle>'    
printf, unit, '</Style>'    

for i=0L, n_elements(ramoffset)-1L do begin
    printf, unit, '<Placemark id="ID">'
    printf, unit, '<styleUrl>#circleIcon</styleUrl>
    if(keyword_set(description)) then begin
        printf, unit, '<description><![CDATA['
        printf, unit, description[i]
        printf, unit, ']]></description>'
    endif
    if(keyword_set(name)) then begin
        printf, unit, '<name>'
        printf, unit, name[i]
        printf, unit, '</name>'
    endif
    printf, unit, '<Point>'
    printf, unit, '<coordinates>'
    rastr=strtrim(string(ramoffset[i],f='(f16.10)'),2)
    decstr=strtrim(string(dec[i],f='(f16.10)'),2)
    outline=rastr+','+decstr+',0'
    printf, unit, outline
    printf, unit, '</coordinates>'
    printf, unit, '</Point>'
    printf, unit, '</Placemark>'
endfor
printf, unit, '</Document>'
printf, unit, '</kml>'

free_lun, unit

end
