;+
; NAME:
;   plate_guide_images
; PURPOSE:
;   Create guide star finding chart images
; CALLING SEQUENCE:
;   plate_guide_images, plateid 
; INPUTS:
;   plateid - plate number
; COMMENTS:
; REVISION HISTORY:
;   10-Jun-2008  MRB, NYU
;-
pro plate_guide_images, in_plateid

common com_plate_guide_images, plateid, full

if(keyword_set(plateid)) then begin
   if(in_plateid ne plateid) then begin
      full=0L
   endif
endif 
plateid= in_plateid

platedir= (plate_dir(plateid))[0]

fullfile= platedir+'/plateHolesSorted-'+ $
          strtrim(string(f='(i6.6)',plateid),2)+'.par'
check_file_exists, fullfile, plateid=plateid

if(n_tags(full) eq 0) then $
   full= yanny_readone(fullfile, hdr=phdr, /anon)

iguide= where(full.holetype eq 'GUIDE', nguide)

for i=0L, nguide-1L do begin
    post=string(f='(i6.6)', plateid[0])+ $
      '-'+string(f='(i2.2)', full[iguide[i]].iguide)
    filebase= platedir+'/guideDSS-r2-'+post
    querydss, [full[iguide[i]].target_ra, full[iguide[i]].target_dec], $
      image, hdr, survey='2r', imsize=3.
    sig= djsig(image)
    image=image-median(image)
    nw_rgb_make, image, image, image, name=filebase+'.png', $
      nonlin=1.5, scale=[1.,1.,1.]*0.1/sig, /png
    mwrfits, image, filebase+'.fits', hdr, /create
endfor

end
;------------------------------------------------------------------------------
