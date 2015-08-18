;+
; NAME:
;   plate_guide_images
; PURPOSE:
;   Create guide star finding chart images
; CALLING SEQUENCE:
;   plate_guide_images, plateid [, /fits]
; INPUTS:
;   plateid - plate number
; OPTIONAL KEYWORDS:
;   /fits - produce FITS images too
; COMMENTS:
;   Uses querydss to retrieve DSS images from the "web"
;   Writes images into:
;     $PLATELIST_DIR/plates/PLATEID6XX/PLATEID6/guideDSS-r2-PLATEID6.png
;   And create web page:
;     $PLATELIST_DIR/plates/PLATEID6XX/PLATEID6/guideDSS-PLATEID6.html
; REVISION HISTORY:
;   10-Jun-2008  MRB, NYU
;   11-May-2011  Demitri Muna, NYU - Have QUERYDSS check POSS-1 if an image wasn't found in POSS-2.
;-
pro plate_guide_images, in_plateid, pointing=pointing, fits=fits

common com_plate_guide_images, plateid, full

if(NOT keyword_set(pointing)) then pointing=1L

if(keyword_set(plateid)) then begin
   if(in_plateid ne plateid) then begin
      full=0L
   endif
endif 
plateid= in_plateid

platedir= (plate_dir(plateid))[0]

fullfile= platedir+'/'+plateholes_filename(plateid=plateid, /sorted)
check_file_exists, fullfile, plateid=plateid

if(n_tags(full) eq 0) then $
   full= yanny_readone(fullfile, hdr=phdr, /anon)

iguide= where(full.holetype eq 'GUIDE' and full.pointing eq pointing, nguide)
isort= sort(full[iguide].iguide)

openw, unit, platedir+'/guideDSS-'+string(f='(i6.6)', plateid[0])+'-p'+ $
  strtrim(string(pointing),2)+'.html', /get_lun

printf, unit, '<html>'
printf, unit, '<head>'
printf, unit, '<title>DSS r2 images of guide fibers for plate '+ $
        strtrim(string(plateid[0]),2)+'</title>'
printf, unit, '</head>'
printf, unit, '<body style="background-color:#ccc">'

printf, unit, '<h1>DSS r2 images of guide fibers for plate '+ $
        strtrim(string(plateid[0]),2)+'</h1>'

printf, unit, '<p>Scaling of images are not constant stretch; please NB the'
printf, unit, 'guide fiber magnitudes (which are approximate).  The images are'
printf, unit, '3 arcmin by 3 arcmin in size.</p>'

printf, unit, '<table border="1" cellspacing="3">'
printf, unit, '<tbody>'

ncol= 4L
for i=0L, nguide-1L do begin
   if((i mod ncol) eq 0) then $
      printf, unit, '<tr>'
   icurr= iguide[isort[i]]
   post=string(f='(i6.6)', plateid[0])+ $
     '-p'+strtrim(string(pointing),2)+ $
     '-'+string(f='(i3.3)', full[icurr].iguide)
   filebase= platedir+'/guideDSS-r2-'+post
   querydss, [full[icurr].target_ra, full[icurr].target_dec], $
             image, hdr, survey='2r', imsize=3.
   
   ; If the image was not found, try again with a different survey.
   ; "image" will either be an array or "0" (which both test to 'integer')
   if (n_elements(image) eq 1) then begin
      querydss, [full[icurr].target_ra, full[icurr].target_dec], $
             image, hdr, survey='1', imsize=3.
      if (n_elements(image) eq 1) then $
      	message, color_string('QUERYDSS failed to retrieving an image!', 'red', 'bold') $
      else $
      	splog, color_string('QUERYDSS failed to retrieve an image on the first try, but found one now. Ignore above error.', 'green', 'normal')
   endif
   
   sig= djsig(image)
   image=image-median(image)
   nw_rgb_make, image, image, image, name=filebase+'.png', $
                nonlin=1.5, scale=[1.,1.,1.]*0.1/sig, /png
   if(keyword_set(fits)) then $
      mwrfits, image, filebase+'.fits', hdr, /create
   printf, unit, '<td>'
   printf, unit, '#'+strtrim(string(full[icurr].iguide),2)+ $
           ' g='+strtrim(string(f='(f40.2)', full[icurr].mag[1]),2)+'<br/>'
   printf, unit, '<a href="guideDSS-r2-'+post+'.png">'
   printf, unit, '<img src="guideDSS-r2-'+post+'.png" width=180px />'
   printf, unit, '</a>'
   printf, unit, '</td>'
   if((i mod ncol) eq ncol-1L OR i eq nguide-1L) then $
      printf, unit, '</tr>'
endfor
printf, unit, '</tbody>'

free_lun, unit

end
;------------------------------------------------------------------------------
