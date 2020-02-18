;+
; NAME:
;   platerun_bosshalf
; PURPOSE:
;   Prepare files and run the low-level routines for BOSS cartridges
;   with fibres for only one spectrograph.
; CALLING SEQUENCE:
;   platerun_bosshalf, platerun, plateid
; INPUTS:
;   platerun - name of run to execute
;   plateid - [Nplate] plate number included in the run
; REVISION HISTORY:
;   10-Jun-2008  MRB, NYU
;   28-Dec-2019  altered for apogee_boss, MRB, NYU
;   17-Feb-2020  altered for bosshalf, JSG, UW
;-
pro platerun_bosshalf, platerun, plateid, nolines=nolines

platerun_dir= getenv('PLATELIST_DIR')+'/runs/'+platerun

spawn, 'mkdir -p '+platerun_dir

cd, platerun_dir

platerun_dir= '.'

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

;; Assumes only one pointing per plate!
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
    spawn, 'cp -f '+plugmap_filename+' '+ $
      platerun_dir+ $
      '/plPlugMapP-'+strtrim(string(plateid[i]),2)+'.par'
endfor
pdata=ptr_new(plobs)
yanny_write, platerun_dir+'/plObs-'+platerun+'.par', $
             pdata, hdr=plhdr, structs=plstructs
ptr_free, pdata

if(keyword_set(nolines) eq 0) then begin
   ;; make the plateLines files
   for i=0L, n_elements(plateid)-1L do begin
       platelines_boss, plateid[i], blockname='BOSSwAPOGEE'
       platelines_guide, plateid[i]
   endfor

   ;; make the guide images
   for i=0L, n_elements(plateid)-1L do $
      plate_guide_images, plateid[i]
endif

spawn, /nosh, ['make_fanuc', '--mode=boss', '--plan-file=' + planfile]

for i=0L, n_elements(plateid)-1L do begin
    fanucfile= getenv('PLATELIST_DIR')+'/runs/'+platerun+'/plFanucUnadjusted-'+ $
      strtrim(string(plateid[i]),2)+'.par'
    if(file_test(fanucfile) eq 0) then $
      message, color_string(fanucfile+' not successfully made!', 'red')
    if(file_test(fanucfile+'.BAD') ne 0) then begin
      plate_log, plateid[i], fanucfile+'.BAD exists --- why?'
    endif else begin
       newfanucfile= getenv('PLATELIST_DIR')+'/runs/'+platerun+ $
                     '/plNorthFanucUnadjusted-'+ $
                     strtrim(string(plateid[i]),2)+'.par'
       cmd = ['mv', fanucfile, newfanucfile]
       spawn, /nosh, cmd
    endelse
 endfor

splog, message, color_string('"plate_writepage, ''' + platerun + '''" can now be run.', 'green', 'bold')

end
;------------------------------------------------------------------------------
