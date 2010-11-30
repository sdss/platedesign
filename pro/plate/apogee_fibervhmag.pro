;+
; NAME:
;   apogee_fibervhmag
; PURPOSE:
;   plot hmag vs fiberid for an APOGEE design
; CALLING SEQUENCE:
;   apogee_fibervhmag, plateid
; INPUTS:
;   plateid - plate ID to run on
; COMMENTS:
;   Appropriate for APOGEE data
;   Makes a PostScript file 26.7717 by 26.7717 inches; mapping
;    should be one-to-one onto plate (x and y ranges are from -340 to
;    +340 mm).
; REVISION HISTORY:
;   22-Aug-2008  MRB, NYU
;    1-Sep-2010  Demitri Muna, NYU, Adding file test before opening files.
;-
;------------------------------------------------------------------------------
pro apogee_fibervhmag, in_plateid

  common com_afvh, plateid, full

  platescale = 217.7358D        ; mm/degree

  full_blockfile=getenv('PLATEDESIGN_DIR')+'/data/apogee/fiberBlocksAPOGEE.par'
  blocks= yanny_readone(full_blockfile)
  blocks=blocks[sort(blocks.fiberid)]

  if(NOT keyword_set(in_plateid)) then $
     message, 'Plate ID must be given!'

  if(keyword_set(plateid) gt 0) then begin
     if(plateid ne in_plateid) then begin
        plateid= in_plateid
        full=0
     endif
  endif else begin
     plateid=in_plateid
  endelse

  platedir= plate_dir(plateid)

  if(n_tags(full) eq 0) then begin

     fullfile= platedir+'/plateHolesSorted-'+ $
               strtrim(string(f='(i6.6)',plateid),2)+'.par'
     check_file_exists, fullfile, plateid=plateid
     full= yanny_readone(fullfile)

  endif
	
  isci= where(strupcase(strtrim(full.holetype,2)) eq 'APOGEE', nsci)
  if(nsci eq 0) then return

  filebase= platedir+'/apogeeMagVsFiber-'+strtrim(string(f='(i6.6)',plateid),2)
     
  xsize=12.559
  ysize=6.559
  encap=1
  scale=2.21706
  
  ;; setup postscript device
  pold=!P
  xold=!X
  yold=!Y
  !P.FONT= -1
  set_plot, "PS"
  if(NOT keyword_set(axis_char_scale)) then axis_char_scale= 1.75
  if(NOT keyword_set(tiny)) then tiny=1.d-4
  !P.BACKGROUND= djs_icolor('white')
  !P.COLOR= djs_icolor('black')
  device, file=filebase+'.ps',/inches,xsize=xsize,ysize=ysize, $
          xoffset=(8.5-xsize)/2.0,yoffset=(11.0-ysize)/2.0,/color, $
          bits_per_pixel=64, encap=encap, scale=scale
  !P.THICK= 2.0
  !P.CHARTHICK= !P.THICK & !X.THICK= !P.THICK & !Y.THICK= !P.THICK
  !P.CHARSIZE= 1.0
  !P.PSYM= 0
  !P.LINESTYLE= 0
  !P.TITLE= ''
  !X.STYLE= 1
  !X.CHARSIZE= axis_char_scale
  !X.MARGIN= 0
  !X.OMARGIN= 10
  !X.RANGE= 0
  !X.TICKS= 0
  !Y.STYLE= 1
  !Y.CHARSIZE= !X.CHARSIZE
  !Y.MARGIN= 5.
  !Y.OMARGIN= 0.
  !Y.RANGE= 0
  !Y.TICKS= !X.TICKS
  !P.MULTI= [1,1,1]
  xyouts, 0,0,'!6'
  colorname= ['red','green','blue','magenta','cyan','dark yellow', $
              'purple','light green','orange','navy','light magenta', $
              'yellow green']
  ncolor= n_elements(colorname)
  loadct,0

  !P.POSITION=[0.1, 0.2, 0.98, 0.98]
  
  djs_plot, [0], [0], /nodata, xra=[-9., 309.], yra=[5., 15.], $
            xtitle='Fiber ID', ytitle='H magnitude'
  
  hogg_usersym, 10, /fill
  types=['F', 'M', 'B']
  colors=['blue', 'green', 'red']
  for i=0L, 49L do begin
     ii= where(full.holetype eq 'APOGEE' and $
               full.fiberid ge (i*6L)+1L and $
               full.fiberid lt (i+1L)*6L+1L, nii)
     isort= sort(full[ii].fiberid)
     hmag= full[ii[isort]].tmass_h
     ibad=where(hmag eq -9999, nbad)
     if(nbad gt 0) then $
        hmag[ibad]=14.
     djs_oplot, ((float(i)+1.)*6.+0.5)*[1.,1.], [0., 20.], th=4, color='grey'
     djs_oplot, full[ii[isort]].fiberid, hmag
     for j=0L, n_elements(types)-1L do begin
        itype= where(types[j] eq blocks[full[ii[isort]].fiberid-1].ftype)
        djs_oplot, full[ii[isort[itype]]].fiberid, hmag[itype], psym=8, symsize=0.4, $
                   color=colors[j]
     endfor
  endfor
  
  device,/close
  !P=pold
  !X=xold
  !Y=yold
  set_plot,'x'
  
  spawn, 'convert '+filebase+'.ps '+filebase+'.png'
  file_delete, filebase+'.ps'
  
  return
end
