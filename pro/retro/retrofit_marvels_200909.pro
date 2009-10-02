;+
; NAME:
;   retrofit_marvels_200909
; PURPOSE:
;   Retrofit MARVELS plPlugMapP files (Sep 2009)
; CALLING SEQUENCE:
;   retrofit_marvels_200909
; COMMENTS:
;   Retrofits the original plate drilling files for this set of plate
;    runs: 2009.09.b.marvels
;   We drilled for 16 guides, when there are only the original 11!
;   We reassign the original 11, and set the fiberid's of the other 5
;     to -1.
; REVISION HISTORY:
;   20-Aug-2008  MRB, NYU
;-
;------------------------------------------------------------------------------
pro retrofit_marvels_200909

plateruns=['2009.09.b.marvels']

plans= yanny_readone(getenv('PLATELIST_DIR')+'/platePlans.par', /anon)
for i=0L, n_elements(plans)-1L do begin
    ii=where(plans[i].platerun eq plateruns, nii)
    if(nii gt 0) then begin
        plateid= plans[i].plateid
        platestr= string(plateid, f='(i4.4)')
        platestr6= string(plateid, f='(i6.6)')
        platedir= plate_dir(plateid)
        
        holesfile= platedir+'/plateHoles-'+platestr6+'.par'
        origholesfile= platedir+'/plateHoles-'+platestr6+'-orig.par'

        if(file_test(origholesfile) eq 0) then $
          spawn, 'cp '+holesfile+' '+origholesfile
        
        holes= yanny_readone(origholesfile, hdr=hdr, /anon)
        iguide=where(holes.holetype eq 'GUIDE', nguide)
        if(nguide ne 16) then $
          message, 'Less (or more!) than 16 guides!!!'
        gf= gfiber_params()
        gnum= distribute_guides(gf,holes[iguide])
        ialign=lonarr(nguide)-1L
        for j=0L, nguide-1L do $
          ialign[j]= where(holes.iguide eq holes[iguide[j]].iguide AND $
                           holes.holetype eq 'ALIGNMENT')
        holes[ialign].iguide= gnum
        holes[iguide].iguide= gnum

        ;; replace header keywords: gfiber, guidenums
        hdr=['# Retrofit by retrofit_marvels_200909 by '+getenv('USER')+ $
             ' at '+systime(), hdr]
        for j=0L, n_elements(hdr)-1L do begin
            words= strsplit(hdr[j], /extr)
            if(strupcase(words[0]) eq 'GFIBERTYPE') then $
              hdr[j]='gfibertype gfiber'
            if(strupcase(words[0]) eq 'GUIDENUMS1') then begin
                if(long(yanny_par(hdr,'npointings')) eq 1) then $
                  hdr[j]='guidenums1 1 2 3 4 5 6 7 8 9 10 11' $
                else $
                  hdr[j]='guidenums1 1 3 5 7 9 11' 
            endif
            if(strupcase(words[0]) eq 'GUIDENUMS2') then begin
                if(long(yanny_par(hdr,'npointings')) eq 1) then $
                  hdr[j]='# guidenums2 entry removed (no second pointing!)' $
                else $
                  hdr[j]='guidenums2 2 4 6 8 10'
            endif
        endfor
        
        pdata= ptr_new(holes)
        yanny_write, holesfile, pdata, hdr=hdr
        ptr_free, pdata
        
        plugfile_plplugmap, plateid
        plugmapfile= platedir+'/plPlugMapP-'+platestr+'.par'
        spawn, 'cp -f '+plugmapfile+' '+getenv('PLATELIST_DIR')+'/runs/'+ $
               plateruns[ii[0]]
        
        platelines_marvels, plateid
    endif
endfor


return
end