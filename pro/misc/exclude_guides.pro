pro exclude_guides, filename

exclude= yanny_readone(filename)

designids= (uniqtag(exclude, 'designid')).designid
for i=0L, n_elements(designids)-1L do begin
    idesignid= where(exclude.designid eq designids[i])
    pointings= (uniqtag(exclude[idesignid], 'pointing')).pointing
    for j= 0L, n_elements(pointings)-1L do begin
        designid= designids[i]
        pointing= pointings[j]
        iexclude= where(exclude.designid eq designid and $
                        exclude.pointing eq pointing, nexclude)
        curr= exclude[iexclude]
        guidefile=sdss_filename('plateGuide', designid=designid, $
                                pointing=pointing, offset=0)
        origfile= guidefile+'.orig'
        if(NOT file_test(origfile)) then $
          spawn, /nosh, ['mv', guidefile, origfile]
        guides= yanny_readone(origfile, hdr=hdr)
        keep= bytarr(n_elements(guides))+1
        design= yanny_readone(sdss_filename('plateDesign', designid=designid))
        for k=0L, nexclude-1L do begin
            iguide= where(design.iguide eq curr[k].iguide, nguide)
            if(nguide eq 0) then $
              message, 'No such guide number'
            spherematch, guides.target_ra, guides.target_dec, $
              design[iguide].target_ra, design[iguide].target_dec, 0.5/3600., m1, m2
            if(m2[0] eq -1) then $
              message, 'Guide missing from guide file'
            keep[m1]= 0
        endfor

        ikeep= where(keep)
        newguides= guides[ikeep]
        pdata= ptr_new(newguides)
        yanny_write, guidefile, pdata, hdr=hdr
    endfor
endfor

end
