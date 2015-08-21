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
pro platelines_manga, in_plateid, diesoft=diesoft, $
                      sorty=sorty, relaxed=relaxed, $
                      rearrange=rearrange, swap=swap

common com_plm, plateid, full, hdr, hdrstr

fnames= yanny_readone(getenv('MANGACORE_DIR')+'/cartmaps/manga_ferrule_names.par')

rearrange=1

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
    fullfile= platedir+'/'+plateholes_filename(plateid=plateid, /sorted,  $
                                               swap=swap)
    check_file_exists, fullfile, plateid=plateid
    full= yanny_readone(fullfile, hdr=hdr)
    hdrstr= lines2struct(hdr)
endif

itag=tag_indx(hdrstr,'OBSERVATORY')
if(itag eq -1) then $
  platescale = get_platescale('APO') $
else $
  platescale = get_platescale(hdrstr.(itag))

if(n_tags(full) eq 0) then begin
    msg='Could not find plateHolesSorted file for '+ $
      strtrim(string(plateid),2)
    if(keyword_set(diesoft) eq 0) then $
      message, msg
    splog, msg
    return
endif

label='MaNGA IFUs'
version='manga'
    
postfix=''
if(keyword_set(version)) then $
  postfix='-'+version

filebase= platedir+'/plateLines-'+strtrim(string(f='(i6.6)',plateid),2) + postfix

connect_thick=3
circle_thick=2

platelines_start, plateid, filebase, label, note=note

;; set buffer for lines, and circle size
;; (48 and 45 arcsec respectively
buffer= 48./3600. * platescale
circle= 45./3600. * platescale

iifu= where(strupcase(strtrim(full.holetype,2)) eq 'MANGA', nifu)
colors=['black', 'blue', 'red', 'green', 'magenta']
for i=0L, nifu-1L do begin
    curr_color= colors[i mod n_elements(colors)]

    theta= findgen(100)/float(99.)*!DPI*2.
    xcurr= full[iifu[i]].xfocal+ circle* cos(theta) 
    ycurr= full[iifu[i]].yfocal+ circle* sin(theta)
    djs_oplot, ycurr, xcurr, color=curr_color, th=circle_thick
     
    ialign= where(full.holetype eq 'MANGA_ALIGNMENT' AND $
                  full.fiberid eq full[iifu[i]].fiberid, nalign)
    if(nalign eq 0) then $
      message, 'No alignment hole!'
    if(nalign gt 1) then begin
        splog, 'More than one alignment hole!'
        ialign= ialign[0]
    endif
    dx= full[ialign].xfocal- full[iifu[i]].xfocal
    dy= full[ialign].yfocal- full[iifu[i]].yfocal
    djs_oplot, full[iifu[i]].yfocal+[0., dy]*3., $
      full[iifu[i]].xfocal+[0., dx]*3., th=2

    if(strmatch(version, 'manga')) then begin
        kk=where(fnames.ifudesign eq full[iifu[i]].ifudesign,nkk)
        if(nkk eq 0) then $
          message, 'No IFUDESIGN found: '+ $
          strtrim(string(full[iifu[i]].ifudesign),2)
        djs_xyouts, full[iifu[i]].yfocal+5, full[iifu[i]].xfocal+5, $
          strtrim(string(fnames[kk].frlplug),2)
    endif

    isky= where(strupcase(strtrim(full.holetype,2)) eq 'MANGA_SINGLE' and $
                full.block eq full[iifu[i]].block, nsky)
    if(nsky eq 0) then $
      message, 'No skies for IFUDESIGN: '+strtrim(string(full[iifu[i]].ifudesign),2)

    for j=0L, nsky-1L do begin
        theta= findgen(100)/float(99.)*!DPI*2.
        xcurr= full[isky[j]].xfocal+ circle* cos(theta)
        ycurr= full[isky[j]].yfocal+ circle* sin(theta)
        djs_oplot, ycurr, xcurr, color='grey', th=circle_thick
        xvec= [full[iifu[i]].xfocal, full[isky[j]].xfocal]
        yvec= [full[iifu[i]].yfocal, full[isky[j]].yfocal]
        djs_oplot, yvec, xvec, th=2, color=curr_color
    endfor
    
endfor

platelines_end

colors=['black', 'blue', 'red', 'green', 'magenta']
for k=0L, n_elements(colors)-1L do begin
    platelines_start, plateid, filebase+'.groups-'+colors[k], label, note=note

    ;; set buffer for lines, and circle size
    ;; (48 and 45 arcsec respectively
    buffer= 48./3600. * platescale
    circle= 45./3600. * platescale
    
    iifu= where(strupcase(strtrim(full.holetype,2)) eq 'MANGA', nifu)
    for i=0L, nifu-1L do begin
        if((i mod n_elements(colors)) eq k) then begin
            curr_color= colors[i mod n_elements(colors)]
            
            theta= findgen(100)/float(99.)*!DPI*2.
            xcurr= full[iifu[i]].xfocal+ circle* cos(theta) 
            ycurr= full[iifu[i]].yfocal+ circle* sin(theta)
            djs_oplot, ycurr, xcurr, color=curr_color, th=circle_thick
            
            ialign= where(full.holetype eq 'MANGA_ALIGNMENT' AND $
                          full.fiberid eq full[iifu[i]].fiberid, nalign)
            if(nalign eq 0) then $
              message, 'No alignment hole!'
            if(nalign gt 1) then begin
                splog, 'More than one alignment hole!'
                ialign= ialign[0]
            endif
            dx= full[ialign].xfocal- full[iifu[i]].xfocal
            dy= full[ialign].yfocal- full[iifu[i]].yfocal
            djs_oplot, full[iifu[i]].yfocal+[0., dy]*3., $
              full[iifu[i]].xfocal+[0., dx]*3., th=2
            
            if(strmatch(version, 'manga')) then begin
                kk=where(fnames.ifudesign eq full[iifu[i]].ifudesign,nkk)
                if(nkk eq 0) then $
                  message, 'No IFUDESIGN found: '+ $
                  strtrim(string(full[iifu[i]].ifudesign),2)
                djs_xyouts, full[iifu[i]].yfocal+5, full[iifu[i]].xfocal+5, $
                  strtrim(string(fnames[kk].frlplug),2)
            endif
            
            isky= where(strupcase(strtrim(full.holetype,2)) eq 'MANGA_SINGLE' and $
                        full.block eq full[iifu[i]].block, nsky)
            if(nsky eq 0) then $
              message, 'No skies for IFUDESIGN: '+strtrim(string(full[iifu[i]].ifudesign),2)
            
            for j=0L, nsky-1L do begin
                theta= findgen(100)/float(99.)*!DPI*2.
                xcurr= full[isky[j]].xfocal+ circle* cos(theta)
                ycurr= full[isky[j]].yfocal+ circle* sin(theta)
                djs_oplot, ycurr, xcurr, color='grey', th=circle_thick
                xvec= [full[iifu[i]].xfocal, full[isky[j]].xfocal]
                yvec= [full[iifu[i]].yfocal, full[isky[j]].yfocal]
                djs_oplot, yvec, xvec, th=2, color=curr_color
            endfor
        endif
    endfor

    platelines_end
endfor

return
end
