;+
; NAME:
;   platerun_manga
; PURPOSE:
;   Prepare files and run the low-level plate routines for manga cartridges
; CALLING SEQUENCE:
;   platerun_manga, platerun, plateid
; INPUTS:
;   platerun - name of run to execute
;   plateid - [Nplate] plate number included in the run
; REVISION HISTORY:
;   10-Jun-2008  MRB, NYU
;-
pro platerun_manga, platerun, plateid, nolines=nolines

nolines=1L

platerun_dir= getenv('PLATELIST_DIR')+'/runs/'+platerun

spawn, 'mkdir -p '+platerun_dir

cd, platerun_dir

platerun_dir= '.'

spawn, 'cp -f '+getenv('PLATEDESIGN_DIR')+'/data/manga/plParam.par '+ $
  platerun_dir+'/plParam-'+platerun+'.par'
spawn, 'cp -f '+getenv('PLATEDESIGN_DIR')+'/data/sdss/g_codes*.txt '+ $
  platerun_dir
spawn, 'cp -f '+getenv('PLATEDESIGN_DIR')+'/data/manga/g_codes*.txt '+ $
  platerun_dir

plhdr = '# Created on ' + systime()
plhdr = [plhdr, "parametersDir " + platerun_dir]
plhdr = [plhdr, "parameters    " + "plParam-"+platerun+".par"]
plhdr = [plhdr, "plObsFile     " + platerun_dir+"/plObs-"+platerun+".par"]
plhdr = [plhdr, "outFileDir    " + platerun_dir]
plhdr = [plhdr, "tileDir       " + platerun_dir]
planname='plPlan-'+platerun+'.par'
planfile= platerun_dir+'/'+planname
yanny_write, planfile, hdr=plhdr

;;----------
;; Create the file "plObs.par" in the current directory.

plhdr = '# Created on ' + systime()
plhdr = [plhdr, "plateRun "+platerun]
plstructs = ["typedef struct {", $
             "   int plateId;", $
             "   int tileId;", $
             "   float temp;", $
             "   float haMin;", $
             "   float haMax;", $
             "   int mjdDesign", $
             "} PLOBS;"]
plobs0 = create_struct(name='PLOBS', $
                       'PLATEID'  , 0L, $
                       'TILEID'   , 0L, $
                       'TEMP'     , 0., $
                       'HAMIN'    , 0., $
                       'HAMAX'    , 0., $
                       'MJDDESIGN', current_mjd())
plobs= replicate(plobs0, n_elements(plateid))
for i=0L, n_elements(plateid)-1L do begin
    plugmap_filename = plate_dir(plateid[i])+'/plPlugMapP-'+ $
                       strtrim(string(plateid[i],f='(i4.4)'),2)+'.par'
    
    ;; Check if plug file exists - fatal error if not
    if (~file_test(plugmap_filename)) then begin
        message, color_string('plPlugMapP file does not exist as expected: ' + $
                 plugmap_filename, 'red')
    endif
    plug= yanny_readone(plugmap_filename, hdr=hdr)
    hdrstr= lines2struct(hdr, /relaxed)
    plobs[i].plateid= plateid[i]
    plobs[i].tileid= plateid[i]
    plobs[i].temp= float(hdrstr.temp)
    plobs[i].hamin= float(hdrstr.hamin)
    plobs[i].hamax= float(hdrstr.hamax)
    spawn, 'cp -f '+plate_dir(plateid[i])+'/plPlugMapP-'+ $
           strtrim(string(plateid[i], f='(i4.4)'),2)+'*.par '+ $
           platerun_dir
endfor
pdata=ptr_new(plobs)
yanny_write, platerun_dir+'/plObs-'+platerun+'.par', $
             pdata, hdr=plhdr, structs=plstructs
ptr_free, pdata

if(keyword_set(nolines) eq 0) then begin
    ;; make the plateLines files
   for i=0L, n_elements(plateid)-1L do begin
       platelines_apogee, plateid[i], /sorty
       apogee_fibervhmag, plateid[i]
       platelines_marvels_bright, plateid[i]
       platelines_guide, plateid[i]
   endfor

   ;; make the guide images
   for i=0L, n_elements(plateid)-1L do $
     plate_guide_images, plateid[i]
endif

print, 'In the "plate" product run the following commands:"'
print, '   makeFanucManga'
print, '   makeDrillPos'
print, '   use_cs3'
print, '   makePlots -skipBrightCheck'
print
setupplate = 'setup -r ~/plate'
spawn, setupplate +'; echo "source '+getenv('PLATEDESIGN_DIR')+'/tcl/makeFanucManga.tcl ;makeFanucManga -plan='+planfile+' " | plate -noTk'
spawn, setupplate +'; echo "makeDrillPos -plan='+planfile+'" | plate -noTk'
spawn, setupplate +'; echo "use_cs3 -planDir '+platerun_dir+' '+ $
       planname+'" | plate -noTk'
spawn, setupplate +'; echo "makePlots -skipBrightCheck -plan='+ $
       planfile+'" | plate -noTk'

for i=0L, n_elements(plateid)-1L do begin
    fanucfile= getenv('PLATELIST_DIR')+'/runs/'+platerun+'/plFanucUnadjusted-'+ $
      string(plateid[i],f='(i4.4)')+'.par'
    if(file_test(fanucfile) eq 0) then $
      message, color_string(fanucfile+' not successfully made!', 'red')
    if(file_test(fanucfile+'.BAD') ne 0) then $
      plate_log, plateid[i], fanucfile+'.BAD exists --- why?'
 endfor

;; make counterbores
openw, cunit, getenv('PLATELIST_DIR')+'/runs/'+platerun+'/'+ $
       'plCounterBoreList-'+platerun+'.txt', /get_lun
printf, cunit, '# List of plates in this run to be counterbored'
for i=0L, n_elements(plateid)-1L do $
   plate_counterbore_manga, platerun, plateid[i], cunit=cunit
free_lun, cunit

splog, message, color_string('"plate_writepage, ''' + platerun + '''" can now be run.', 'green', 'bold')

end
;------------------------------------------------------------------------------