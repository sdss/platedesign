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
pro plate_writepage, runname

path= getenv('PLATELIST_DIR')+'/runs/'+runname

spawn, 'cd '+path+' ; drillrun2zip '+runname


openw, unit, path+'/'+runname+'.html', /get_lun
printf, unit, '<html>'
printf, unit, '<head>'
printf, unit, '<title>Drilling run: '+runname+'</title>'
printf, unit, '</head>'
printf, unit, '<body>'
printf, unit, '<h1>Drilling run: '+runname+'</h1>'
printf, unit, '<hr>'
printf, unit, '<h4>Zipped, DOS-version files for UW plate shop</h4>'
printf, unit, '<p><a href="'+runname+'.dos.zip">'+runname+'.dos.zip</a></p>'

printf, unit, '<h4>Overlay plots</h4>'
overlayfiles= file_search(path+'/plOverlay-*.ps')
printf, unit, '<ul>'
for i=0L, n_elements(overlayfiles)-1L do begin
    words=strsplit(overlayfiles[i], '/',/extr)
    filename=words[n_elements(words)-1]
    printf, unit, '<li><a href="'+filename+'">'+filename+ '</a></li>'
endfor
printf, unit, '</ul>'

platelinesfiles= file_search(path+'/plateLines-*.ps')
if(keyword_set(platelinesfiles)) then begin
    printf, unit, '<h4>plateLines plots</h4>'
    printf, unit, '<ul>'
    for i=0L, n_elements(platelinesfiles)-1L do begin
        words=strsplit(platelinesfiles[i], '/',/extr)
        filename=words[n_elements(words)-1]
        printf, unit, '<li><a href="'+filename+'">'+filename+ '</a></li>'
    endfor
    printf, unit, '</ul>'
endif

printf, unit, '<h4>plPlugMapP files</h4>'
printf, unit, '<ul>'
plplugfiles= file_search(path+'/plPlugMapP-????.par')
for i=0L, n_elements(plplugfiles)-1L do begin
    words=strsplit(plplugfiles[i], '/',/extr)
    filename=words[n_elements(words)-1]
    printf, unit, '<li><a href="'+filename+'">'+filename+ '</a></li>'
endfor
printf, unit, '</ul>'

printf, unit, '<hr>'
printf, unit, '<p>Produced by '+getenv('USER')+' on '+getenv('HOST')+' at '+ $
  systime()+'.</p>'
printf, unit, '</body>'
printf, unit, '</html>'
free_lun, unit

spawn, 'ssh sdss.physics.nyu.edu mkdir -p /var/www/html/as2/drillruns/'+runname
spawn, 'scp -p '+path+'/'+runname+'.html sdss.physics.nyu.edu:/var/www/html/as2/drillruns/'+runname
spawn, 'scp -p '+path+'/'+runname+'.dos.zip sdss.physics.nyu.edu:/var/www/html/as2/drillruns/'+runname
spawn, 'scp -p '+path+'/plOverlay-*.ps sdss.physics.nyu.edu:/var/www/html/as2/drillruns/'+runname
spawn, 'scp -p '+path+'/plateLines-*.ps sdss.physics.nyu.edu:/var/www/html/as2/drillruns/'+runname
spawn, 'scp -p '+path+'/plPlugMapP-????.par sdss.physics.nyu.edu:/var/www/html/as2/drillruns/'+runname

return
end
