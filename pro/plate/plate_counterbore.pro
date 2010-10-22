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
  printf, unit, string(f='(i5.5)', plateid)+' (SDSS PLUG-PLATE '+ $
        string(f='(i4.4)', plateid)+')'
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
     spherematch, full[icounter[i]].target_ra, full[icounter[i]].target_dec, $
                  dpos.ra, dpos.dec, 1./3600, m1, m2, max=0
     if(m1[0] eq -1) then $
        message, 'Lost hole?'
     if(n_elements(m1) gt 1) then $
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
        printf, unit, 'G43 H10 Z0.2'
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
  printf, unit, ''
  printf, unit, 'N800 G69 G20'
  printf, unit, 'N801 G00 G28 G91 Z0.0 T08 M06 (ENGRAVING TOOL)'
  printf, unit, 'N802 G54 G40 G90 X-16. Y.25 S3500 M03'
  printf, unit, 'N803 G43 Z1.000 H08'
  printf, unit, 'N804 G17 M08'
  printf, unit, 'N805 G01 Z0.100 F100.0'
  printf, unit, 'N806 G52 X-16. Y.25'
  printf, unit, 'N807 M98 P7804 ('+d1+')'
  printf, unit, 'N808 G52 X-16. Y.125'
  printf, unit, 'N809 M98 P7803 ('+d2+')'
  printf, unit, 'N810 G52 X-16. Y0.'
  printf, unit, 'N811 M98 P7802 ('+d3+')'
  printf, unit, 'N812 G52 X-16. Y-.125'
  printf, unit, 'N813 M98 P7807 ('+d4+')'
  printf, unit, 'N808 G52 X-16. Y-.25'
  printf, unit, 'N809 M98 P7899 (BLANKSPACE)'
  printf, unit, 'N816 G52 X0.0 Y0.0'
  printf, unit, 'N817 G00 Z3.000 M09'
  printf, unit, 'N818 G00 G80 G28 G91 Z0.0 T01 M06'
  printf, unit, 'N819 G00 G90 G53 X41.000 Y0.0'
  printf, unit, 'N820 M30'
  printf, unit, '%'
  
  free_lun, unit

  return
end
