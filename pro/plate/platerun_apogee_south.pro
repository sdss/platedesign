;+
; NAME:
;   platerun_apogee_south
; PURPOSE:
;   Prepare files and run the low-level plate routines for bright cartridges
; CALLING SEQUENCE:
;   platerun_iapogee_south, platerun, plateid
; INPUTS:
;   platerun - name of run to execute
;   plateid - [Nplate] plate number included in the run
; REVISION HISTORY:
;   30-Nov-2015  MRB, NYU
;-
pro platerun_apogee_south, platerun, plateid, nolines=nolines

platerun_dir= getenv('PLATELIST_DIR')+'/runs/'+platerun

spawn, 'mkdir -p '+platerun_dir

cd, platerun_dir

platerun_dir= '.'

spawn, 'cp -f '+getenv('PLATEDESIGN_DIR')+'/data/sdss/plParam_LCO.par '+ $
  platerun_dir+'/plParam-'+platerun+'.par'
spawn, 'cp -f '+getenv('PLATEDESIGN_DIR')+'/data/sdss/g_codes*.txt '+ $
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
                       strtrim(string(plateid[i]),2)+'.par'

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

    ;; copy plugmap files from the individual plate directories
    spawn, 'cp -f '+plate_dir(plateid[i])+'/plPlugMapP-'+ $
           strtrim(string(plateid[i]),2)+'*.par '+ $
           platerun_dir

endfor
pdata=ptr_new(plobs)
yanny_write, platerun_dir+'/plObs-'+platerun+'.par', $
             pdata, hdr=plhdr, structs=plstructs
ptr_free, pdata

if(keyword_set(nolines) eq 0) then begin
   ;; make the plateLines files
   for i=0L, n_elements(plateid)-1L do begin
       platelines_apogee_south, plateid[i], /sortx
       apogee_fibervhmag, plateid[i], holetype='APOGEE_SOUTH'
       platelines_guide, plateid[i]
       spawn, /noshell, ['plate_overlay', '--plate', strtrim(string(plateid[i]),2), '--png']

       ;; copy the pdf overlays from the individual plate directories
       spawn, 'cp -f '+plate_dir(plateid[i])+'/plateLines-'+ $
              strtrim(string(plateid[i], FORMAT='(I6)'),2)+'-*.pdf '+ $
              platerun_dir
   endfor
endif

;; make the guide images
for i=0L, n_elements(plateid)-1L do begin
    plugmap_filename = plate_dir(plateid[i])+'/plPlugMapP-'+ $
      strtrim(string(plateid[i]),2)+'.par'
    plug= yanny_readone(plugmap_filename, hdr=hdr)
    npointings= long(yanny_par(hdr, 'npointings'))
    for pointing= 1, npointings do $
      plate_guide_images, plateid[i], pointing=pointing
endfor

spawn, /nosh, ['make_fanuc', '--mode=apoge_south', '--plan-file=' + planfile]

;; This is the old call to the plate product to create the fanuc files
;;print, 'In the "plate" product run the following commands:"'
;;print, '   makeFanuc'
;;print, '   makeDrillPos'
;;print, '   use_cs3'
;;print, '   makePlots -skipBrightCheck'
;;print
;; setupplate = 'setup plate'
;; spawn, setupplate +'; echo "makeFanuc -gcode=G56 -plan='+planfile+' " | plate -noTk'
;; spawn, setupplate +'; echo "makeDrillPos -plan='+planfile+'" | plate -noTk'
;; spawn, setupplate +'; echo "use_cs3 -planDir '+platerun_dir+' '+ $
;;       planname+'" | plate -noTk', outcs3
;;for i=0L, n_elements(outcs3)-1L do begin
;;    bad= strmatch(outcs3[i], 'collision*')
;;    if(bad) then begin
;;        print, outcs3
;;        message, 'Final plate collision check failed!'
;;    endif
;;endfor
;;spawn, setupplate +'; echo "makePlots -skipBrightCheck -plan='+ $
;;''       planfile+'" | plate -noTk'

for i=0L, n_elements(plateid)-1L do begin
    fanucfile= getenv('PLATELIST_DIR')+'/runs/'+platerun+'/plFanucUnadjusted-'+ $
      strtrim(string(plateid[i]),2)+'.par'
    if(file_test(fanucfile) eq 0) then $
      message, color_string(fanucfile+' not successfully made!', 'red')
    if(file_test(fanucfile+'.BAD') ne 0) then begin
       plate_log, plateid[i], fanucfile+'.BAD exists --- why?'
    endif else begin
       newfanucfile= getenv('PLATELIST_DIR')+'/runs/'+platerun+ $
                     '/plSouthFanucUnadjusted-'+ $
                     strtrim(string(plateid[i]),2)+'.par'
       cmd = ['mv', fanucfile, newfanucfile]
       spawn, /nosh, cmd
    endelse
 endfor

splog, message, color_string('"plate_writepage, ''' + platerun + '''" can now be run.', 'green', 'bold')

end
;------------------------------------------------------------------------------
