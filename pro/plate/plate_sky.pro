;+
; NAME:
;   plate_sky 
; PURPOSE:
;   Return sky for a given plate set up
;   This script writes the 'plateSky<instrument>-<designid>-<pointing>-<offset>.par file.
; RETURN VALUE
;   Returns a structure of the plateSky file.
; CALLING SEQUENCE:
;   sky= plate_sky(definition, default, pointing, offset )
; REVISION HISTORY:
;   7-May-2008  MRB, NYU
;    1-Sep-2010 Demitri Muna, NYU, Adding file test before opening files.
;-
;------------------------------------------------------------------------------
function plate_sky, definition, default, instrument, pointing, offset, $
                    seed=seed
if(NOT tag_exist(default, 'PLATEDESIGNSKIES')) then begin
    return, 0
endif 

designid= long(definition.designid)

;; what instruments are we designing skies for?
platedesignskies= strsplit(default.platedesignskies, /extr)

for i=0L, n_elements(platedesignskies)-1L do begin
    if(strupcase(platedesignskies[i]) ne 'NONE' AND $
       strupcase(platedesignskies[i]) ne 'BOSS' AND $
       strupcase(platedesignskies[i]) ne 'BOSSHALF' AND $
       strupcase(platedesignskies[i]) ne 'SDSS' AND $
       strupcase(platedesignskies[i]) ne 'MANGA' AND $
       strupcase(platedesignskies[i]) ne 'MANGA_SINGLE' AND $
       strupcase(platedesignskies[i]) ne 'MARVELS' AND $
       strupcase(platedesignskies[i]) ne 'APOGEE') then begin
        message, 'No such instrument '+platedesignskies[i]+'; '+ $
          'plateDesignSkies must specify NONE, BOSS, BOSSHALF, SDSS, MARVELS, '+ $
          'or APOGEE'
    endif
endfor

;; check if the current instrument is included, if not, return
iinst= where(instrument eq platedesignskies, ninst)
if(ninst eq 0) then begin
    return, 0
endif

;; what type of sky should we use?
if(NOT tag_exist(default, 'SKYTYPE')) then begin
    skytype= 'SDSS'
endif else begin
    skytype= strsplit(default.skytype, /extr)
    skytype= skytype[pointing-1]
endelse

;; what diameter and buffer do we set?
ferrulesize= get_ferrulesize(definition, default, instrument)
buffersize= get_buffersize(definition, default, instrument)

itag= tag_indx(default, 'n'+ $
               strtrim(string(instrument),2)+ $
               '_sky')
npointings= long(default.npointings)
noffsets= long(default.noffsets)
nsky= (reform(long(strsplit(default.(itag),/extr)), npointings, $
              noffsets+1L))[pointing-1L, offset]

;; increase maximum # of skies by collection factor * 2
if(tag_exist(default, 'COLLECTFACTOR')) then $
  collectfactor= long(default.collectfactor) $
else $
  collectfactor= 10L
nsky=nsky*collectfactor*2L

sky_design=0
if(nsky gt 0) then begin
    ;; file name
    outdir= design_dir(designid)
    skyfile=outdir+'/plateSky'+instrument+'-'+ $
            string(designid, f='(i6.6)')+ $
            '-p'+strtrim(string(pointing),2)+ $
            '-o'+strtrim(string(offset),2)+'.par'
    
    if(file_test(skyfile) eq 0) then begin
        ;; what is center for this pointing and offset?
        plate_center, definition, default, pointing, offset, $
                      racen=racen, deccen=deccen
        
        ;; find skies and assign them
        case skytype of 
            'SDSS': $
              plate_select_sky_sdss, racen, deccen, $
                nsky=nsky, seed=seed, $
                sky_design=sky_design
            'DSS': $
              plate_select_sky_sdss, racen, deccen, $
                nsky=nsky, seed=seed, $
                sky_design=sky_design, /nosdss
            '2MASS': $
              plate_select_sky_tmass, racen, deccen, $
                nsky=nsky, seed=seed, sky_design=sky_design
            'BOSS': $
              plate_select_sky_boss, racen, deccen, $
                nsky=nsky, seed=seed, sky_design=sky_design
            else: $
              message, 'No such skytype '+skytype
        endcase
        sky_design.pointing=pointing
        sky_design.offset=offset
        sky_design.holetype=instrument
        plate_ad2xy, definition, default, pointing, offset, $
          sky_design.target_ra, sky_design.target_dec, $
          sky_design.lambda_eff, xf=xf, yf=yf, $
          zoffset=sky_design.zoffset
        sky_design.xf_default=xf
        sky_design.yf_default=yf
        sky_design.diameter= ferrulesize
        sky_design.buffer= buffersize
        sky_design.bluefiber= 1
        
        if(n_tags(sky_design) gt 0) then begin
            pdata= ptr_new(sky_design)
            hdrstr=plate_struct_combine(default, definition)
            outhdr=struct2lines(hdrstr)
            outhdr=[outhdr, $
                    'pointing '+strtrim(string(pointing),2), $
                    'platedesign_version '+platedesign_version()]
            yanny_write, skyfile, pdata, hdr=outhdr
            ptr_free, pdata
        endif
    endif else begin
    	check_file_exists, skyfile, plateid=plateid
      in_sky_design= yanny_readone(skyfile, /anon)
      sky_design= replicate(design_blank(), n_elements(in_sky_design))
      struct_assign, in_sky_design, sky_design, /nozero
    endelse
endif

return, sky_design

end
