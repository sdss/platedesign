;+
; NAME:
;   plate_writepage
; PURPOSE:
;   Write the web page describing a drill run
; CALLING SEQUENCE:
;   plate_writepage, runname
; INPUTS:
;   runname - name of run
; COMMENTS:
;   Currently only posts the zipfile.
;   This routine is really just a placeholder for the final version
; REVISION HISTORY:
;   7-May-2008  MRB, NYU
;   1-Sep-2010  Demitri Muna, NYU, Adding file test before opening files.
;-
;------------------------------------------------------------------------------
pro linestable, label, plunit, files

printf, plunit, '<tr>'
printf, plunit, '<td>'+label+'</td>'
for j=0L, n_elements(files)-1L do begin
    words= strsplit(files[j], '/', /extr)
    lastwords= words[n_elements(words)-3L]+'/'+ $
               words[n_elements(words)-2L]+'/'+ $
               words[n_elements(words)-1L]
    path='../../plates/'+lastwords
    printf, plunit, '<td><a href="'+path+'">'
    printf, plunit, '<img src="'+path+'" width=300px>'
    printf, plunit, '</a></td>
endfor
printf, plunit, '</tr>

end
;;
pro plate_writepage, runname

runpath= getenv('PLATELIST_DIR')+'/runs/'+runname

spawn, 'cd '+runpath+' ; drillrun2zip '+runname

openw, unit, runpath+'/'+runname+'.html', /get_lun
printf, unit, '<html>'
printf, unit, '<head>'
printf, unit, '<title>Drilling run: '+runname+'</title>'
printf, unit,  '<STYLE type="text/css">'
printf, unit,  ' td {text-align: right}'
printf, unit,  ' td {white-space: nowrap}'
printf, unit,  ' td.blue {background-color:#ccf}'
printf, unit,  ' td.pink {background-color:#fcc}'
printf, unit,  '</STYLE>'
printf, unit, '</head>'
printf, unit, '<body style="background-color:#ccc">'
printf, unit, '<body>'
printf, unit, '<h1>Drilling run: '+runname+'</h1>'
printf, unit, '<hr>'
printf, unit, '<h4>For most users: use platelist product!</h4>'
printf, unit, '<p>For most users, the proper way to get the'
printf, unit, 'plugging data is from the'
printf, unit, '<a href="http://trac.sdss3.org/browser/repo/platelist">platelist'
printf, unit, 'SVN product</a>. Note that some of the information listed here'
printf, unit, 'can be out-of-date, and the definitive source is in the plateHolesSorted'
printf, unit, 'and platePlans.par files.</p>'
printf, unit, '<h4>For UW plate shop: zipped, DOS-version files</h4>'
printf, unit, '<p><a href="'+runname+'.dos.zip">'+runname+'.dos.zip</a></p>'

plateplans_file = getenv('PLATELIST_DIR')+'/platePlans.par'
check_file_exists, plateplans_file
plans= yanny_readone(plateplans_file)
iplate= where(plans.platerun eq runname, nplate)
plateid= plans[iplate].plateid


printf, unit, '<h4>For pluggers: plateLines plots</h4>'
printf, unit, '<table border="1" cellspacing="3">'
printf, unit, '<thead>'
printf, unit, '<tr>'
printf, unit, '<td>Plate ID</td>'
printf, unit, '<td>Tile ID</td>'
printf, unit, '<td>Location ID</td>'
printf, unit, '<td>Pointing</td>'
printf, unit, '<td>RA</td>'
printf, unit, '<td>Dec</td>'
printf, unit, '<td>HA (deg E)</td>'
printf, unit, '<td>HA<sub>min</sub></td>'
printf, unit, '<td>HA<sub>max</sub></td>'
printf, unit, '<td>Guides</td>'
printf, unit, '<td>plugmap link</td>'
printf, unit, '<td>Instrument</td>'
printf, unit, '<td>N<sub>sci</sub></td>'
printf, unit, '<td>N<sub>std</sub></td>'
printf, unit, '<td>N<sub>sky</sub></td>'
printf, unit, '</tr>'
printf, unit, '</thead>'
printf, unit, '<tbody>'
classes=['pink', 'blue']

isort= sort(plateid)
for indx=0L, n_elements(plateid)-1L do begin
    i= isort[indx]

    plateholesfile= plate_dir(plateid[i])+'/plateHolesSorted-'+ $
                    string(f='(i6.6)', plateid[i])+'.par'
    yanny_read, plateholesfile, hdr=hdr
    npointings= long(yanny_par(hdr, 'npointings'))
    pointing_name= yanny_par(hdr, 'pointing_name')
    tileid= yanny_par(hdr, 'tileId')
    instruments= yanny_par(hdr, 'instruments')
    targets= yanny_par(hdr, 'targettypes')
    locid= yanny_par(hdr, 'locationId')
    ha= yanny_par(hdr, 'ha')
    hamin= yanny_par(hdr, 'ha_observable_min')
    hamax= yanny_par(hdr, 'ha_observable_max')
    racen= yanny_par(hdr, 'raCen')
    deccen= yanny_par(hdr, 'decCen')
    nsci= strarr(n_elements(instruments), npointings)
    nstd= strarr(n_elements(instruments), npointings)
    nsky= strarr(n_elements(instruments), npointings)
    for it=0L, n_elements(instruments)-1L do begin
        nsci[it,*]= yanny_par(hdr, 'n'+strlowcase(instruments[it])+'_science')
        itar= where(strmatch(strupcase(targets), 'STANDARD*'), ntar)
        if(ntar gt 0) then $
          nstd[it,*]= $
          strtrim(string(long(yanny_par(hdr, 'n'+strlowcase(instruments[it])+'_standard'))+ $
                         long(yanny_par(hdr, 'n'+strlowcase(instruments[it])+'_standard_bright'))+ $
                         long(yanny_par(hdr, 'n'+strlowcase(instruments[it])+'_standard_medium'))+ $
                         long(yanny_par(hdr, 'n'+strlowcase(instruments[it])+'_standard_faint'))+ $
                         long(yanny_par(hdr, 'n'+strlowcase(instruments[it])+'_standard3'))+ $
                         long(yanny_par(hdr, 'n'+strlowcase(instruments[it])+'_standard5'))),2)
        itar= where(strmatch(strupcase(targets), 'SKY*'), ntar)
        if(ntar gt 0) then $
          nsky[it,*]= $
          strtrim(string(long(yanny_par(hdr, 'n'+strlowcase(instruments[it])+'_sky'))+ $
                         long(yanny_par(hdr, 'n'+strlowcase(instruments[it])+'_sky_bright'))+ $
                         long(yanny_par(hdr, 'n'+strlowcase(instruments[it])+'_sky_medium'))+ $
                         long(yanny_par(hdr, 'n'+strlowcase(instruments[it])+'_sky_faint'))+ $
                         long(yanny_par(hdr, 'n'+strlowcase(instruments[it])+'_sky3'))+ $
                         long(yanny_par(hdr, 'n'+strlowcase(instruments[it])+'_sky5'))),2)
    endfor
    guides= ptrarr(npointings)
    for ip=0L, npointings-1L do $
           guides[ip]= ptr_new(yanny_par(hdr, $
                                         'guidenums'+strtrim(string(ip+1L),2)))

    plfile='plateLines-'+string(plateid[i], f='(i6.6)')+'.html'

    class= classes[i mod n_elements(classes)]
    tdst= '<td class="'+class+'">'
    for ip= 0L, npointings-1L do begin
        for it= 0L, n_elements(instruments)-1L do begin
            printf, unit, '<tr>'
            if(ip eq 0 AND it eq 0) then begin
                printf, unit, tdst
                printf, unit, '<a href="'+plfile+'">'+ $
                        string(plateid[i], f='(i6.6)')+'</a>'
                printf, unit, '</td>'
                printf, unit, tdst
                printf, unit, tileid
                printf, unit, '</td>'
                printf, unit, tdst
                printf, unit, locid
                printf, unit, '</td>'
            endif else begin
                printf, unit, '<td></td>'
                printf, unit, '<td></td>'
                printf, unit, '<td></td>'
            endelse
            
            if(it eq 0) then begin
                printf, unit, tdst
                printf, unit, pointing_name[ip]
                printf, unit, '</td>'
                
                printf, unit, tdst
                printf, unit, racen[ip]
                printf, unit, '</td>'

                printf, unit, tdst
                printf, unit, deccen[ip]
                printf, unit, '</td>'

                printf, unit, tdst
                printf, unit, ha[ip]
                printf, unit, '</td>'

                printf, unit, tdst
                printf, unit, hamin[ip]
                printf, unit, '</td>'

                printf, unit, tdst
                printf, unit, hamax[ip]
                printf, unit, '</td>'

                plugname='plPlugMapP-'+ $
                          string(f='(i4.4)', plateid[i])
                if(pointing_name[ip] ne 'A') then $
                  plugname= plugname+pointing_name[ip]
                plugname=plugname+'.par'
                plugfile= plate_dir(plateid[i])+'/'+plugname

                words= strsplit(plugfile, '/', /extr)
                lastwords= words[n_elements(words)-3L]+'/'+ $
                           words[n_elements(words)-2L]+'/'+ $
                           words[n_elements(words)-1L]
                path='../../plates/'+lastwords
                
                lastwords= words[n_elements(words)-3L]+'/'+ $
                           words[n_elements(words)-2L]
                gpath= '../../plates/'+lastwords
                ghtml= 'guideDSS-'+ string(f='(i6.6)', plateid[i])+ $
                  '-p'+strtrim(string(ip+1L),2)+'.html'
                
                printf, unit, tdst
                if(file_test(plate_dir(plateid[i])+'/'+ghtml) gt 0) then $
                  printf, unit, '<a href="'+gpath+'/'+ghtml+'">'
                printf, unit, *guides[ip]
                if(file_test(plate_dir(plateid[i])+'/'+ghtml) gt 0) then $
                  printf, unit, '</a>'
                printf, unit, '</td>'

                printf, unit, tdst+'<a href="'+path+'">'+plugname
                printf, unit, '</a></td>'
            endif else begin
                printf, unit, '<td></td>'
                printf, unit, '<td></td>'
                printf, unit, '<td></td>'
                printf, unit, '<td></td>'
                printf, unit, '<td></td>'
                printf, unit, '<td></td>'
                printf, unit, '<td></td>'
                printf, unit, '<td></td>'
            endelse
                
            printf, unit, tdst
            printf, unit, instruments[it]
            printf, unit, '</td>'
            printf, unit, tdst
            printf, unit, nsci[it,ip]
            printf, unit, '</td>'
            printf, unit, tdst
            printf, unit, nstd[it,ip]
            printf, unit, '</td>'
            printf, unit, tdst
            printf, unit, nsky[it,ip]
            printf, unit, '</td>'

            printf, unit, '</tr>'
        endfor 
    endfor 
            
            
    openw, plunit, runpath+'/'+plfile, /get_lun
    printf, plunit, '<html>'
    printf, plunit, '<head>'
    printf, plunit, '<title>plateLines-'+string(plateid[i], f='(i6.6)')+ $
            ' from drilling run: '+runname+'</title>'
    printf, plunit, '</head>'
    printf, plunit, '<h1>plateLines-'+string(plateid[i], f='(i6.6)')+ $
            ' from drilling run: '+runname+'</h1>'
    printf, plunit, '</head>'
    printf, plunit, '<body style="background-color:#ccc">'
    printf, plunit, '<body>'
    printf, plunit, '<table border="0" cellspacing="3">'
    printf, plunit, '<tbody>'
    tmp_files= file_search(plate_dir(plateid[i])+'/plateLines-??????.png', $
                           count=count)
    if(count gt 0) then begin
        tmp_files2= file_search(plate_dir(plateid[i])+ $
                                '/plateLines-??????-guide.png', count=count2)
        if(count2 gt 0) then tmp_files= [tmp_files, tmp_files2]
        tmp_files2= file_search(plate_dir(plateid[i])+ $
                                '/plateLines-??????-???.png', $
                                count=count2)
        if(count2 gt 0) then tmp_files= [tmp_files, tmp_files2]
        tmp_files2= file_search(plate_dir(plateid[i])+ $
                                '/plateLines-??????-traps.png', $
                                count=count2)
        if(count2 gt 0) then tmp_files= [tmp_files, tmp_files2]
        linestable, 'Plate overview', plunit, tmp_files
        tmp_files= file_search(plate_dir(plateid[i])+ $
                               '/plateLines-??????-block-*.png', count=count)
        if(count gt 0) then linestable, 'Blocks by color', plunit, tmp_files
        tmp_files= file_search(plate_dir(plateid[i])+ $
                               '/plateLines-??????-zoffset-*.png', count=count)
        if(count gt 0) then linestable, 'Backstop labels', plunit, tmp_files
     endif
    ptypes=['marvels', 'apogee', 'manga']
    for iptype=0L, n_elements(ptypes)-1L do begin
       ptype=ptypes[iptype]
       tmp_files= file_search(plate_dir(plateid[i])+'/plateLines-??????-'+ptype+'.png', $
                              count=count)
       if(count gt 0) then begin
          tmp_files2= file_search(plate_dir(plateid[i])+ $
                                  '/plateLines-??????-guide.png', count=count2)
          if(count2 gt 0) then tmp_files= [tmp_files, tmp_files2]
          tmp_files2= file_search(plate_dir(plateid[i])+ $
                                  '/plateLines-??????-'+ptype+'.???.png', $
                                  count=count2)
          if(count2 gt 0) then tmp_files= [tmp_files, tmp_files2]
          tmp_files2= file_search(plate_dir(plateid[i])+ $
                                  '/plateLines-??????-traps.png', $
                                  count=count2)
          if(count2 gt 0) then tmp_files= [tmp_files, tmp_files2]
          linestable, 'Plate overview', plunit, tmp_files
          tmp_files2= file_search(plate_dir(plateid[i])+ $
                                 '/plateLines-??????-'+ptype+'.block-*.png', count=count2)
          if(count2 gt 0) then linestable, 'Blocks by color', plunit, tmp_files2
          tmp_files2= file_search(plate_dir(plateid[i])+ $
                                 '/plateLines-??????-'+ptype+'.groups-*.png', count=count2)
          if(count2 gt 0) then linestable, 'Grouped by color', plunit, tmp_files2
       endif
    endfor
    tmp_files= file_search(plate_dir(plateid[i])+'/apogeeMagVsFiber-??????.png', $
                           count=count)
    if(count gt 0) then $
       linestable, 'APOGEE fiber class QA', plunit, tmp_files
    
    printf, plunit, '</tbody>'
    printf, plunit, '</table>'
    printf, plunit, '</body>'
    printf, plunit, '</html>'
    free_lun, plunit
    
    printf, unit, '</tr>'
endfor
printf, unit, '</tbody>'
printf, unit, '</table>'

printf, unit, '<hr>'
printf, unit, '<p>Produced by '+getenv('USER')+' on '+getenv('HOST')+' at '+ $
  systime()+'.</p>'
printf, unit, '</body>'
printf, unit, '</html>'
free_lun, unit

return
end
