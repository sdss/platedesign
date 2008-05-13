;+
; NAME:
;   plate_writepage
; PURPOSE:
;   Write the web page describing a drill run
; CALLING SEQUENCE:
;   plate_writepage, runname, path
; INPUTS:
;   runname - name of run
;   path - path to results
; COMMENTS:
;   Currently only posts the zipfile.
;   This routine is really just a placeholder for the final version
; REVISION HISTORY:
;   7-May-2008  MRB, NYU
;-
;------------------------------------------------------------------------------
pro plate_writepage, runname, path

if(NOT keyword_set(path)) then path='./'

spawn, 'cd '+path+' ; drillrun2zip '+runname

openw, unit, path+'/'+runname+'.html', /get_lun
printf, unit, '<html>'
printf, unit, '<head>'
printf, unit, '<title>Drilling run: '+runname+'</title>'
printf, unit, '</head>'
printf, unit, '<body>'
printf, unit, '<h1>Drilling run: '+runname+'</h1>'
printf, unit, '<hr>'
printf, unit, '<h4>Zipped, DOS-version files</h4>'
printf, unit, '<a href="'+runname+'.dos.zip">'+runname+'.dos.zip</a>'
printf, unit, '<hr>'
printf, unit, '<p>Produced by '+getenv('USER')+' on '+getenv('HOST')+' at '+ $
  systime()+'.</p>'
printf, unit, '</body>'
printf, unit, '</html>'
free_lun, unit

spawn, 'scp -p '+path+'/'+runname+'.html sdss.physics.nyu.edu:/var/www/html/as2/drillruns/'
spawn, 'scp -p '+path+'/'+runname+'.dos.zip sdss.physics.nyu.edu:/var/www/html/as2/drillruns/'

return
end
