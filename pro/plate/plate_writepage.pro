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
printf, unit, '</head>'
printf, unit, '<body style="background-color:#ccc">'
printf, unit, '<body>'
printf, unit, '<h1>Drilling run: '+runname+'</h1>'
printf, unit, '<hr>'
printf, unit, '<h4>For most users: use platelist product!</h4>'
printf, unit, '<p>For most users, the proper way to get the'
printf, unit, 'plugging data is from the'
printf, unit, '<a href="http://trac.sdss3.org/browser/repo/platelist">platelist'
printf, unit, 'SVN product</a>.</p>'
printf, unit, '<h4>For UW plate shop: zipped, DOS-version files</h4>'
printf, unit, '<p><a href="'+runname+'.dos.zip">'+runname+'.dos.zip</a></p>'

plans= yanny_readone(getenv('PLATELIST_DIR')+'/platePlans.par')
iplate= where(plans.platerun eq runname, nplate)
plateid= plans[iplate].plateid

printf, unit, '<h4>For pluggers: plateLines plots</h4>'
printf, unit, '<ul>'
for i=0L, n_elements(plateid)-1L do begin
    plfile='plateLines-'+string(plateid[i], f='(i6.6)')+'.html'
    printf, unit, '<li>'
    printf, unit, '<a href="'+plfile+'">'+string(plateid[i], f='(i6.6)')+'</a>'
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
        linestable, 'Plate overview', plunit, tmp_files
        tmp_files= file_search(plate_dir(plateid[i])+ $
                               '/plateLines-??????-block-*.png', count=count)
        if(count gt 0) then linestable, 'Blocks by color', plunit, tmp_files
        tmp_files= file_search(plate_dir(plateid[i])+ $
                               '/plateLines-??????-zoffset-*.png', count=count)
        if(count gt 0) then linestable, 'Backstop labels', plunit, tmp_files
    endif
    printf, plunit, '</tbody>'
    printf, plunit, '</table>'
    printf, plunit, '</body>'
    printf, plunit, '</html>'
    free_lun, plunit
    
    printf, unit, '</li>'
endfor
printf, unit, '</ul>'

printf, unit, '<hr>'
printf, unit, '<p>Produced by '+getenv('USER')+' on '+getenv('HOST')+' at '+ $
  systime()+'.</p>'
printf, unit, '</body>'
printf, unit, '</html>'
free_lun, unit

return
end
