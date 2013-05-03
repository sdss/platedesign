;+
; NAME:
;   plate_counterbore_manga
; PURPOSE:
;   write the counterbore fanuc files for MaNGA
; CALLING SEQUENCE:
;   plate_counterbore_manga, plateid 
; INPUTS:
;   plateid - plate ID to run on
; COMMENTS:
;   Only writes counterbores for MaNGA holes.
; REVISION HISTORY:
;    18-Oct-2010  MRB
;-
;------------------------------------------------------------------------------
pro plate_counterbore_manga, platerun, in_plateid, cunit=cunit

  common com_plcounter, plateid, full, dpos
  
  inchpermm= 0.039370 
  platerun_dir= getenv('PLATELIST_DIR')+'/runs/'+platerun
  
  if(NOT keyword_set(in_plateid)) then $
     message, 'Plate ID must be given!'

  if(keyword_set(plateid) gt 0) then begin
     if(plateid ne in_plateid) then begin
        plateid= in_plateid
        full=0
        holes=0
     endif
  endif else begin
     plateid=in_plateid
  endelse

  platedir= plate_dir(plateid)

  if(n_tags(holes) eq 0 OR n_tags(dpos) eq 0) then begin
     fullfile= platedir+'/plateHolesSorted-'+ $
               strtrim(string(f='(i6.6)',plateid),2)+'.par'
     check_file_exists, fullfile, plateid=plateid
     full= yanny_readone(fullfile)
     dposfile= platerun_dir+'/plDrillPos-'+ $
               strtrim(string(f='(i4.4)',plateid),2)+'.par'
     check_file_exists, dposfile, plateid=plateid
     dpos= yanny_readone(dposfile)
  endif

  icounter= where(strupcase(strtrim(full.holetype,2)) eq 'MANGA' AND $
                  strupcase(strtrim(full.targettype,2)) eq 'SCIENCE', ncounter)
  
  if(ncounter eq 0) then $
     return
  
  if(keyword_set(cunit)) then $
     printf, cunit, string(plateid, f='(i4.4)')
  
  openw, unit, platerun_dir+'/plMANGACounterBore-'+string(f='(i6.6)', plateid)+'.txt', /get_lun
  
  printf, unit, '%'
  printf, unit, 'O'+string(f='(i4.4)', plateid MOD 7000)+' (SDSS PLUG-PLATE '+ $
        string(plateid)+')'
  printf, unit, '(SET Z0.0 AT 0.125" ABOVE FIXTURE SURFACE)'
  printf, unit, '(#13.  7/64" END MILL)'
  printf, unit, ''
  printf, unit, 'M00'
  printf, unit, 'N13 G20 G80 G69'
  printf, unit, 'G00 G28 G91 Z0.0 T13 M06 (7/64" END MILL)'
  printf, unit, 'G68 X0.0 Y0.0 R-90.0'
  printf, unit, 'M03 S3500'
  printf, unit, 'G00 G90 G40 G17'

  for i=0L, ncounter-1L do begin
     m2= where(abs(full[icounter[i]].xfocal-dpos.xfocal) lt 0.1 AND $
               abs(full[icounter[i]].yfocal-dpos.yfocal) lt 0.1, nm2)
     if(nm2 eq 0) then $
        message, 'Lost hole?'
     if(nm2 gt 1) then $
        message, 'Ambiguous hole?'
     m2=m2[0]
     
     ;; do not flip, and use constant depth
     xx= dpos[m2].xdrill*inchpermm
     yy= dpos[m2].ydrill*inchpermm
     depth= (0.025)
     zz= (0.1- depth)
     
     xstr= strtrim(string(xx, f='(f40.4)'),2)
     ystr= strtrim(string(yy, f='(f40.4)'),2)
     zstr= strtrim(string(zz, f='(f40.4)'),2)

     if(i eq 0) then begin
        printf, unit, 'G54 X'+xstr+' Y'+ystr  
        printf, unit, 'G43 H13 Z1.0'
        printf, unit, 'M08'
        printf, unit, 'G00 Z'+zstr
        printf, unit, 'M98 P7891'
     endif else begin
        printf, unit, 'G00 X'+xstr+' Y'+ystr  
        printf, unit, 'Z'+zstr
        printf, unit, 'M98 P7891'
     endelse
  endfor
  
  printf, unit, 'G00 Z2.000 M09'
  printf, unit, 'G00 G80 G28 G91 Z0.0 M05'
  printf, unit, 'G69'
  printf, unit, 'G00 G90 G53 X41.000 Y0.0'
  printf, unit, 'M30'
  printf, unit, '%'
  
  free_lun, unit

  return
end
