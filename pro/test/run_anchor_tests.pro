pro run_anchor_tests

nran=60L
platescale = 217.7358D           ; mm/degree

ntest=500L
nfail=0L

openw, unit, 'anchor_tests.txt', /get_lun

for i=0L, ntest-1L do begin
    rr2= randomu(seed,nran)*(1.49D*platescale)^2
    theta= randomu(seed,nran)*!DPI*2.D
    rr= sqrt(rr2)
    xt= rr*cos(theta)
    yt= rr*sin(theta)
    
    blockfile= getenv('PLATEDESIGN_DIR')+'/data/marvels/'+ $
               'fiberBlocksMarvels.par'
    sdss_plugprob, xt, yt, fiberid, blockfile=blockfile, $
                   maxinblock=4, limitdegree=9.*0.1164

    ii=where(fiberid le 0, nii)
    if(nii gt 0) then nfail=nfail+1L
    
endfor

printf, unit, 'In standard case, '+strtrim(string(nfail),2)+'/'+ $
        strtrim(string(ntest),2)+' fail'

for i=0L, ntest-1L do begin
    rr2= randomu(seed,nran)*(1.49D*platescale)^2
    theta= randomu(seed,nran)*!DPI*2.D
    rr= sqrt(rr2)
    xt= rr*cos(theta)
    yt= rr*sin(theta)
    
    blockfile= getenv('PLATEDESIGN_DIR')+'/data/marvels/'+ $
               'fiberBlocksMarvelsTest60.par'
    sdss_plugprob, xt, yt, fiberid, blockfile=blockfile, $
                   maxinblock=6, limitdegree=9.*0.1164

    ii=where(fiberid le 0, nii)
    if(nii gt 0) then nfail=nfail+1L
    
endfor

printf, unit, 'In new 60 fiber test case, '+strtrim(string(nfail),2)+'/'+ $
        strtrim(string(ntest),2)+' fail'

nran=120L
for i=0L, ntest-1L do begin
    rr2= randomu(seed,nran)*(1.49D*platescale)^2
    theta= randomu(seed,nran)*!DPI*2.D
    rr= sqrt(rr2)
    xt= rr*cos(theta)
    yt= rr*sin(theta)
    
    blockfile= getenv('PLATEDESIGN_DIR')+'/data/marvels/'+ $
               'fiberBlocksMarvelsTest120.par'
    sdss_plugprob, xt, yt, fiberid, blockfile=blockfile, $
                   maxinblock=6, limitdegree=9.*0.1164

    ii=where(fiberid le 0, nii)
    if(nii gt 0) then nfail=nfail+1L
    
endfor

printf, unit, 'In new 120 fiber test case, '+strtrim(string(nfail),2)+'/'+ $
        strtrim(string(ntest),2)+' fail'

nran=60L
for i=0L, ntest-1L do begin
    rr2= randomu(seed,nran)*(1.49D*platescale)^2
    theta= randomu(seed,nran)*!DPI*2.D
    rr= sqrt(rr2)
    xt= rr*cos(theta)
    yt= rr*sin(theta)
    
    blockfile= getenv('PLATEDESIGN_DIR')+'/data/marvels/'+ $
               'fiberBlocksMarvels.par'
    sdss_plugprob, xt, yt, fiberid, blockfile=blockfile, $
                   maxinblock=4, reachfunc='boss_reachcheck'

    ii=where(fiberid le 0, nii)
    if(nii gt 0) then nfail=nfail+1L
    
endfor

printf, unit, 'With BOSS reach, in standard case, '+strtrim(string(nfail),2)+'/'+ $
        strtrim(string(ntest),2)+' fail'

for i=0L, ntest-1L do begin
    rr2= randomu(seed,nran)*(1.49D*platescale)^2
    theta= randomu(seed,nran)*!DPI*2.D
    rr= sqrt(rr2)
    xt= rr*cos(theta)
    yt= rr*sin(theta)
    
    blockfile= getenv('PLATEDESIGN_DIR')+'/data/marvels/'+ $
               'fiberBlocksMarvelsTest60.par'
    sdss_plugprob, xt, yt, fiberid, blockfile=blockfile, $
                   maxinblock=6, reachfunc='boss_reachcheck'

    ii=where(fiberid le 0, nii)
    if(nii gt 0) then nfail=nfail+1L
    
endfor

printf, unit, 'With BOSS reach, in new 60 fiber test case, '+strtrim(string(nfail),2)+'/'+ $
        strtrim(string(ntest),2)+' fail'

nran=120L
for i=0L, ntest-1L do begin
    rr2= randomu(seed,nran)*(1.49D*platescale)^2
    theta= randomu(seed,nran)*!DPI*2.D
    rr= sqrt(rr2)
    xt= rr*cos(theta)
    yt= rr*sin(theta)
    
    blockfile= getenv('PLATEDESIGN_DIR')+'/data/marvels/'+ $
               'fiberBlocksMarvelsTest120.par'
    sdss_plugprob, xt, yt, fiberid, blockfile=blockfile, $
                   maxinblock=6, reachfunc='boss_reachcheck'

    ii=where(fiberid le 0, nii)
    if(nii gt 0) then nfail=nfail+1L
    
endfor

printf, unit, 'With BOSS reach, in new 120 fiber test case, '+strtrim(string(nfail),2)+'/'+ $
        strtrim(string(ntest),2)+' fail'

free_lun, unit

end
