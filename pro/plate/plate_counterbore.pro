;+
; NAME:
;   plate_counterbore
; PURPOSE:
;   write the counterbore fanuc files
; CALLING SEQUENCE:
;   plate_counterbore, plateid 
; INPUTS:
;   plateid - plate ID to run on
; COMMENTS:
;   Only writes counterbores for APOGEE holes.
; REVISION HISTORY:
;    18-Oct-2010  MRB
;-
;------------------------------------------------------------------------------
pro plate_counterbore, platerun, in_plateid, cunit=cunit

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

  ;; find apogee holes needing counterbore (> 200 mm from center)
  rr= sqrt(full.xfocal^2+ full.yfocal^2)
  icounter= where(strupcase(strtrim(full.holetype,2)) eq 'APOGEE' AND $
                  rr gt 200., ncounter)
  
  if(ncounter eq 0) then $
     return

  if(keyword_set(cunit)) then $
     printf, cunit, string(plateid, f='(i4.4)')
  
  openw, unit, platerun_dir+'/plCounterBore-'+string(f='(i6.6)', plateid)+'.txt', /get_lun
  
  printf, unit, '%'
  printf, unit, 'O'+string(f='(i4.4)', plateid MOD 7000)+' (SDSS PLUG-PLATE '+ $
        string(plateid)+')'
  printf, unit, '(SET Z0.0 AT 0.125" ABOVE FIXTURE SURFACE)'
  printf, unit, '(#10.  5/64" END MILL)'
  printf, unit, ''
  printf, unit, 'M00'
  printf, unit, 'N10 G20 G80 G69'
  printf, unit, 'G00 G28 G91 Z0.0 T10 M06 (5/64" END MILL)'
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
     
     xx= -dpos[m2].xdrill*inchpermm
     yy= dpos[m2].ydrill*inchpermm
     depth= (0.00486*(rr[icounter[i]]-200.))*inchpermm
     zz= (0.1- depth)
     
     xstr= strtrim(string(xx, f='(f40.4)'),2)
     ystr= strtrim(string(yy, f='(f40.4)'),2)
     zstr= strtrim(string(zz, f='(f40.4)'),2)

     if(i eq 0) then begin
        printf, unit, 'G54 X'+xstr+' Y'+ystr  
        printf, unit, 'G43 H10 Z1.0'
        printf, unit, 'M08'
        printf, unit, 'G00 Z'+zstr
        printf, unit, 'M98 P7890'
     endif else begin
        printf, unit, 'G00 X'+xstr+' Y'+ystr  
        printf, unit, 'Z'+zstr
        printf, unit, 'M98 P7890'
     endelse
  endfor
  
  pstr= string(plateid, f='(i4.4)')
  d1= strmid(pstr,0,1)
  d2= strmid(pstr,1,1)
  d3= strmid(pstr,2,1)
  d4= strmid(pstr,3,1)
  
  printf, unit, 'G00 Z2.000 M09'
  printf, unit, 'G00 G80 G28 G91 Z0.0 M05'
  printf, unit, 'G69'
  printf, unit, 'G00 G90 G53 X41.000 Y0.0'
  printf, unit, 'M30'
  printf, unit, '%'
  
  free_lun, unit

  return
end
