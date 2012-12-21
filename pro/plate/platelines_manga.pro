;+
; NAME:
;   platelines_manga
; PURPOSE:
;   write the plateLines-????.ps file for a MANGA plate
; CALLING SEQUENCE:
;   platelines_manga, plateid [, /sky, /std, /relaxed ]
; INPUTS:
;   plateid - plate ID to run on
; OPTIONAL KEYWORDS:
;   /relaxed - reassign fiberid #s using relaxed constraints
; COMMENTS:
;   Appropriate for MaNGA data
;   Makes a PostScript file 26.7717 by 26.7717 inches; mapping
;    should be one-to-one onto plate (x and y ranges are from -340 to
;    +340 mm).
;   Circles are 45 arcsec radius.
;   Colors of circles are blue for 8 faintest stars in block, green
;    for the 6 next brightest, and red for the 6 brightest
; BUGS:
;   Works off the plPlugMapP file, so may be fragile.
; REVISION HISTORY:
;   22-Aug-2008  MRB, NYU
;    1-Sep-2010  Demitri Muna, NYU, Adding file test before opening files.
;   31-Oct-2012  MRB, adjusted for MaNGA
;-
;------------------------------------------------------------------------------
pro platelines_manga_rearrange, full, holes

  platescale = 217.7358D        ; mm/degree
  stretch=30

  sizes= [2., 3., 5.]
  maxinblock= [6, 6, 5]

  for i=0L, n_elements(sizes)-1L do begin

      blockfile=getenv('PLATEDESIGN_DIR')+ $
        '/data/manga/fiberBlocksMaNGAProto'+ $
        strtrim(string(f='(i)', long(sizes[i])),2)+'.par'
      fiberblocks= yanny_readone(blockfile)

      isingle= where(strupcase(full.holetype) eq 'MANGA' and $
                     strupcase(full.targettype) ne 'SCIENCE' and $
                     full.fiber_size eq sizes[i], nsingle)
      if(nsingle ne n_elements(fiberblocks)) then $
        message, 'Not the right number of single fibers?'
      
      sdss_plugprob, full[isingle].xf_default, full[isingle].yf_default, $
        tmp_fiberid, reachfunc='boss_reachcheck', blockfile=blockfile, $
        minavail=0, maxinblock=maxinblock[i], stretch=stretch

      if(min(tmp_fiberid) lt 1) then $
        message, 'Some fibers unassigned'
      
      ;; NOTE THIS SCRAMBLES FIBERID VALUES RELATIVE TO
      ;; MANGA_ALIGNMENT
      full[isingle].fiberid= tmp_fiberid
      holes[isingle].fiberid= -tmp_fiberid
  endfor

end
;
pro platelines_manga_rearrange_mix, full, holes

platescale = 217.7358D          ; mm/degree
stretch=0

blockfile=getenv('PLATEDESIGN_DIR')+ $
  '/data/manga/fiberBlocksMaNGAProto.par'
fiberblocks= yanny_readone(blockfile)

isingle= where(strupcase(full.holetype) eq 'MANGA' and $
               strupcase(full.targettype) ne 'SCIENCE', nsingle)
               
if(nsingle ne n_elements(fiberblocks)) then $
  message, 'Not the right number of single fibers?'

sdss_plugprob, full[isingle].xf_default, full[isingle].yf_default, $
  tmp_fiberid, reachfunc='boss_reachcheck', blockfile=blockfile, $
  minavail=1, maxinblock=6L, stretch=stretch

if(min(tmp_fiberid) lt 1) then $
  message, 'Some fibers unassigned'

;; NOTE THIS SCRAMBLES FIBERID VALUES RELATIVE TO
;; MANGA_ALIGNMENT
full[isingle].fiberid= tmp_fiberid
holes[isingle].fiberid= -tmp_fiberid

end
;
pro platelines_manga, in_plateid, diesoft=diesoft, $
                      sorty=sorty, relaxed=relaxed, $
                      rearrange=rearrange

common com_pla, plateid, full, holes, hdr

platescale = 217.7358D          ; mm/degree
rearrange=1

blockfile=getenv('PLATEDESIGN_DIR')+ $
  '/data/manga/fiberBlocksMaNGAProto.par'
fiberblocks= yanny_readone(blockfile)

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

if(n_tags(holes) eq 0) then begin
    plplug= platedir+'/plPlugMapP-'+ $
      strtrim(string(f='(i4.4)',plateid),2)+'.par'
    check_file_exists, plplug, plateid=plateid
    holes= yanny_readone(plplug, hdr=hdr)
    hdrstr= lines2struct(hdr)
    
    fullfile= platedir+'/plateHolesSorted-'+ $
      strtrim(string(f='(i6.6)',plateid),2)+'.par'
    check_file_exists, fullfile, plateid=plateid
    full= yanny_readone(fullfile)
    
endif

full_mix= full
holes_mix= holes
if(keyword_set(rearrange)) then begin
    platelines_manga_rearrange, full, holes
    platelines_manga_rearrange_mix, full_mix, holes_mix
endif

if(n_tags(holes) eq 0 OR n_tags(full) eq 0) then begin
    msg='Could not find plPlugMapP or plateHolesSorted file for '+ $
      strtrim(string(plateid),2)
    if(keyword_set(diesoft) eq 0) then $
      message, msg
    splog, msg
    return
endif

;; basic versions
versions=['manga', 'manga.fiber2', 'manga.fiber3', 'manga.fiber5', 'manga.mix']

;; make various block colors
;;colors= ['red', 'green', 'blue', 'magenta', 'cyan']
;;versions= [versions, 'manga.block-'+colors]

for k=0L, n_elements(versions)-1L do begin
    
    version=versions[k]
    
    postfix=''
    if(keyword_set(version)) then $
      postfix='-'+version

    filebase= platedir+'/plateLines-'+strtrim(string(f='(i6.6)',plateid),2)+ $
      postfix
    
    connect_thick=3
    circle_thick=2
    
    if(version ne 'manga' AND $
       (strmatch(version, 'manga.block-*') eq 0 OR $
        strmatch(version, 'traps') ne 0)) then $
      connect_thick=1

    if(version eq 'manga') then $
      label='MANGA bundle'
    note=''
    platelines_start, plateid, filebase, label, note=note
    
    ;; set buffer for lines, and circle size
    ;; (48 and 45 arcsec respectively
    buffer= 48./3600. * platescale
    circle= 45./3600. * platescale
    
    ibundle= where(strupcase(strtrim(full.holetype,2)) eq 'MANGA' and $
                   strupcase(strtrim(full.targettype,2)) eq 'SCIENCE', $
                   nbundle)
    for i=0L, nbundle-1L do begin
        theta= findgen(100)/float(99.)*!DPI*2.
        xcurr= holes[ibundle[i]].xfocal+ circle* cos(theta)
        ycurr= holes[ibundle[i]].yfocal+ circle* sin(theta)
        djs_oplot, ycurr, xcurr, color='black', th=circle_thick

        ialign= where(holes.holetype eq 'MANGA_ALIGNMENT' AND $
                      holes.fiberid eq holes[ibundle[i]].fiberid, nalign)
        if(nalign eq 0) then $
          message, 'No alignment hole!'
        if(nalign gt 1) then begin
            splog, 'More than one alignment hole!'
            ialign= ialign[0]
        endif
        dx= holes[ialign].xfocal- holes[ibundle[i]].xfocal
        dy= holes[ialign].yfocal- holes[ibundle[i]].yfocal
        djs_oplot, holes[ibundle[i]].yfocal+[0., dy]*3., $
          holes[ibundle[i]].xfocal+[0., dx]*3., th=2

        if(strmatch(version, 'manga')) then begin
            djs_xyouts, holes[ibundle[i]].yfocal+5, holes[ibundle[i]].xfocal+5, $
              strtrim(string(full[ibundle[i]].bundle_id),2)+' ('+ $
              strtrim(full[ibundle[i]].sourcetype,2)+')', charsize=0.9
        endif
    endfor

    isingle= where(strupcase(strtrim(full.holetype,2)) eq 'MANGA' and $
                   strupcase(strtrim(full.targettype,2)) ne 'SCIENCE', $
                   nsingle)
    for i=0L, nsingle-1L do begin
        if(strmatch(strupcase(full[isingle[i]].targettype), $
                    'STANDARD*')) then $
          color='dark grey' $
        else $
          color='light grey'
          
        theta= findgen(100)/float(99.)*!DPI*2.
        xcurr= holes[isingle[i]].xfocal+ circle* cos(theta)
        ycurr= holes[isingle[i]].yfocal+ circle* sin(theta)
        djs_oplot, ycurr, xcurr, color=color, th=1

        ialign= where(holes.holetype eq 'MANGA_ALIGNMENT', nalign)
        spherematch, holes[isingle[i]].ra, holes[isingle[i]].dec, $
          holes[ialign].ra, holes[ialign].dec, 0.1, m1, m2
        dx= holes[ialign[m2]].xfocal- holes[isingle[i]].xfocal
        dy= holes[ialign[m2]].yfocal- holes[isingle[i]].yfocal
        djs_oplot, holes[isingle[i]].yfocal+[0., dy]*3., $
          holes[isingle[i]].xfocal+[0., dx]*3., th=1, $
          color=color
    endfor

    sizes= [2., 3., 5.]
    maxinblock=[6,6,5]
    for i=0L, n_elements(sizes)-1L do begin
        isingle= where(strupcase(full.holetype) eq 'MANGA' and $
                       strupcase(full.targettype) ne 'SCIENCE' and $
                       full.fiber_size eq sizes[i], nsingle)
        block= (full[isingle].fiberid-1L)/long(maxinblock[i])+1L
        for iblock=1L, max(block) do begin
            iin= where(block eq iblock, nin)
            if(nin ne maxinblock[i]) then $
              message, 'Uh oh! Not right number in block.'
            isort= sort(full[isingle[iin]].yfocal)
            djs_oplot, full[isingle[iin[isort]]].yfocal, $
              full[isingle[iin[isort]]].xfocal, color='light grey', th=1
        endfor
    endfor

    if(strmatch(version, 'manga.*')) then begin 
        type= strupcase((stregex(version, 'manga\.(.*)', /sub, /extr))[1])
        case type of
            'FIBER2': begin
                maxinblock=6
                fiber_size= 2.
                standard_color='dark red'
                sky_color='light red'
            end
            'FIBER3': begin
                maxinblock=6
                fiber_size= 3.
                standard_color='dark green'
                sky_color='light green'
            end
            'FIBER5': begin
                maxinblock=5
                fiber_size= 5.
                standard_color='dark blue'
                sky_color='light blue'
            end
            'MIX': begin
                fiber_size= full_mix.fiber_size
                standard_color='dark blue'
                sky_color='light blue'
            end
        endcase

        isingle= where(strupcase(strtrim(full.holetype,2)) eq 'MANGA' and $
                       strupcase(strtrim(full.targettype,2)) ne 'SCIENCE' and $
                       full.fiber_size eq fiber_size, nsingle) 
        for i=0L, nsingle-1L do begin
            if(strmatch(strupcase(full[isingle[i]].targettype), $
                        'STANDARD*')) then $
              color=standard_color $
            else $
              color=sky_color
            theta= findgen(100)/float(99.)*!DPI*2.
            xcurr= holes[isingle[i]].xfocal+ circle* cos(theta)
            ycurr= holes[isingle[i]].yfocal+ circle* sin(theta)
            djs_oplot, ycurr, xcurr, color=color, th=4
        endfor
        
        if(type eq 'MIX') then begin
            colors=['black', 'red', 'blue', 'green', 'cyan', 'magenta']
            isingle= where(strupcase(full_mix.holetype) eq 'MANGA' and $
                           strupcase(strtrim(full_mix.targettype,2)) ne 'SCIENCE')
            block= fiberblocks[full_mix[isingle].fiberid-1L].blockid
            for iblock=1L, max(block) do begin
                iin= where(block eq iblock, nin)
                isort= sort(full_mix[isingle[iin]].yfocal)
                color= colors[iblock mod n_elements(colors)]
                djs_oplot, full_mix[isingle[iin[isort]]].yfocal, $
                  full_mix[isingle[iin[isort]]].xfocal, color=color, th=3
            endfor
        endif else begin
            isingle= where(strupcase(full.holetype) eq 'MANGA' and $
                           strupcase(strtrim(full.targettype,2)) ne 'SCIENCE' and $
                           full.fiber_size eq fiber_size, nsingle) 
            block= (full[isingle].fiberid-1L)/long(maxinblock)+1L
            for iblock=1L, max(block) do begin
                iin= where(block eq iblock, nin)
                if(nin ne maxinblock) then $
                  message, 'Uh oh! Not right number in block.'
                isort= sort(full[isingle[iin]].yfocal)
                djs_oplot, full[isingle[iin[isort]]].yfocal, $
                  full[isingle[iin[isort]]].xfocal, color=color, th=3
            endfor
        endelse
    endif
    
    platelines_end
endfor

return
end
