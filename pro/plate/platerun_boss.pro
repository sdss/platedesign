;+
; NAME:
;   platerun_boss
; PURPOSE:
;   Prepare files and run the low-level plate routines for BOSS 
; CALLING SEQUENCE:
;   platerun_boss, platerun, plateid
; INPUTS:
;   platerun - name of run to execute
;   plateid - [Nplate] plate number included in the run
; REVISION HISTORY:
;   10-Jun-2008  MRB, NYU
;-
pro platerun_boss, platerun, plateid

platerun_dir= getenv('PLATELIST_DIR')+'/runs/'+platerun

spawn, 'mkdir -p '+platerun_dir

spawn, 'cp -f '+getenv('PLATEDESIGN_DIR')+'/data/sdss/plParam.par '+ $
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
                       strtrim(string(plateid[i],f='(i4.4)'),2)+'.par'
    
    ;; Check if plug file exists - fatal error if not
    if (~file_test(plugmap_filename)) then begin
        message, 'plPlugMapP file does not exist as expected: ' + $
                 plugmap_filename
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
yanny_write, platerun_dir+'/plObs-'+platerun+'.par', $
             ptr_new(plobs), hdr=plhdr, structs=plstructs

print, 'In the "plate" product run the following commands:"'
print, '   makeFanuc'
print, '   makeDrillPos'
print, '   use_cs3'
print, '   makePlots -skipBrightCheck'
print
setupplate = 'setup plate'
spawn, setupplate +'; echo "makeFanuc -plan='+planfile+' " | plate -noTk'
spawn, setupplate +'; echo "makeDrillPos -plan='+planfile+'" | plate -noTk'
spawn, setupplate +'; echo "use_cs3 -planDir '+platerun_dir+' '+ $
       planname+'" | plate -noTk'
spawn, setupplate +'; echo "makePlots -skipBrightCheck -plan='+ $
       planfile+'" | plate -noTk'

splog, '"plate_writepage, ' + platerun + '" can now be run.'

end
;------------------------------------------------------------------------------