;+
; NAME:
;   retrofit_boss_200908
; PURPOSE:
;   Retrofit plPlugMapP files (Aug 2009)
; CALLING SEQUENCE:
;   retrofit_segue2_200908
; COMMENTS:
;   Retrofits the original plate drilling files for this set of plate
;    runs: 2009.08.a.boss
;   The desired guide numbering has changed.
;   In order to fix this, we rerun plugfile_plplugmap_boss, and 
;     replace the plugmaps in the plates and runs dirs
;   The old files in the plate dir is first moved into 
;     'plPlugMapP-????-orig.par'
; REVISION HISTORY:
;   20-Aug-2008  MRB, NYU
;-
;------------------------------------------------------------------------------
pro retrofit_boss_200908

plateruns=['2009.08.a.boss']
newg= yanny_readone(getenv('PLATEDESIGN_DIR')+'/data/sdss/sdss_newguide.par', $
                    /anon)

plans= yanny_readone(getenv('PLATELIST_DIR')+'/platePlans.par', /anon)
for i=0L, n_elements(plans)-1L do begin
    ii=where(plans[i].platerun eq plateruns, nii)
    ;; act if it is in one of the affected plate runs
    if(nii gt 0) then begin
        plateid= plans[i].plateid
        platestr= string(plateid, f='(i4.4)')
        platestr6= string(plateid, f='(i6.6)')
        platedir= plate_dir(plateid)

        holesfile= platedir+'/plateHoles-'+platestr6+'.par'
        origholesfile= platedir+'/plateHoles-'+platestr6+'-orig.par'

        holes= yanny_readone(origholesfile, hdr=hdr, /anon)
        iguide=where(holes.holetype eq 'GUIDE', nguide)
        if(nguide ne 16) then $
          message, 'Less (or more!) than 16 guides!!!'
        gf= gfiber2_params()
        gnum= distribute_guides(gf,holes[iguide])
        ialign=lonarr(nguide)-1L
        for j=0L, nguide-1L do $
              ialign[j]= where(holes.iguide eq holes[iguide[j]].iguide AND $
                               holes.holetype eq 'ALIGNMENT')
        holes[ialign].iguide= gnum
        holes[iguide].iguide=gnum

        ;; add header keywords:
        ;;  pointing_name
        ;;  tileID
        ;;  theta
        ;;  reddenmed
        iobj=where(holes.holetype eq 'BOSS')
        extinct= reddenmed(holes[iobj].target_ra, holes[iobj].target_dec)
        hdr= [hdr, guider_hdr(plateid), $
              'pointing_name A B C D E F', $
              'theta 0', $
              'tileId '+strtrim(string(plans[i].tileid),2), $
              'reddeningMed '+string(extinct,format='(5f8.4)')]
        
        fixcaps=['raCen', 'decCen', 'plateId', 'tileId']
        for j=0L, n_elements(hdr)-1L do begin 
            words= strsplit(hdr[j], /extr) 
            for k=0L, n_elements(fixcaps)-1L do begin 
                if(strupcase(words[0]) eq strupcase(fixcaps[k])) then $
                  words[0]=fixcaps[k] 
            endfor 
            hdr[j]=strjoin(words, ' ') 
        endfor

        ;; add column mag
        holes0= create_struct(design_blank(), 'XFOCAL', 0.D, 'YFOCAL', 0.D)
        new_holes= replicate(holes0, n_elements(holes))
        struct_assign, holes, new_holes, /nozero
        holes=new_holes
        default={bossmagtype:'fiber2mag'}
        holes.mag= plate_mag(holes, default=default)
        
        pdata= ptr_new(holes)
        yanny_write, holesfile, pdata, hdr=hdr
        ptr_free, pdata
        
        plugfile_plplugmap_boss, plateid
        plugmapfile= platedir+'/plPlugMapP-'+platestr+'.par'
        spawn, 'cp -f '+plugmapfile+' '+getenv('PLATELIST_DIR')+'/runs/'+ $
               plateruns[ii[0]]
        
        platelines_boss, plateid
    endif
endfor


return
end
