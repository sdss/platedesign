;+
; NAME:
;   distribute_guides
; PURPOSE:
;   distribute guides among available locations
; CALLING SEQUENCE:
;   gnum= distribute_guides(gfiber, design)
; INPUTS:
;   gfiber - [Nguide] structure containing:
;                .GUIDENUM
;                .XREACH
;                .YREACH
;                .RREACH
;                .XPREFER
;                .YPREFER
;                .GUIDETYPE
;   design - [Ntarget] design structure with potential guides; require
;            at least:
;                .XF_DEFAULT
;                .YF_DEFAULT
; OUTPUTS:
;   gnum - [Ntarget] guide numbers for each target (-1 if not
;          assigned)
; REVISION HISTORY:
;   4-Sep-2008 MRB, NYU 
;-
function distribute_guides, gfiber, design, plot=plot

nguide= n_elements(gfiber)
ntarget= n_elements(design)

nnode= nguide+ntarget+2L
narc= nguide+ntarget

matches=ptrarr(nguide)
costs=ptrarr(nguide)
nmtot=0L
ismatched= lonarr(ntarget)
platescale = 217.7358D          ; mm/degree
coff=lonarr(n_elements(gfiber))+90000L
ibig= where(gfiber.guidetype eq 'A', nbig)
if(nbig eq 0) then $
  message, 'No acquisition fibers! Senseless.'
coff[ibig]=0L
for i=0L, n_elements(gfiber)-1L do begin
    inrange= boss_reachcheck(gfiber[i].xreach/platescale, $
                             gfiber[i].yreach/platescale, $
                             design.xf_default/platescale, $
                             design.yf_default/platescale)
    imatch=where(inrange gt 0, nmatch)
    if(nmatch eq 0) then begin
        splog, 'No guide star available at ALL for #'+ $
               strtrim(string(gfiber[i].guidenum),2)+'!'
    endif else begin
        matches[i]= ptr_new(imatch)
        distance=sqrt((gfiber[i].xprefer-design[imatch].xf_default)^2+ $
                      (gfiber[i].yprefer-design[imatch].yf_default)^2)
        cdist2= coff[i]+ long(distance^2)

        ;; for anything closer than 6 cm, decide based on priority
        dlim= 80.
        iclose= where(distance lt dlim, nclose)
        if(nclose gt 1) then begin
            pmax= max(design[imatch[iclose]].priority)
            pmin= min(design[imatch[iclose]].priority)
            pscaled= (float(design[imatch[iclose]].priority)-float(pmin))/ $
              (float(pmax)-float(pmin))* dlim^2
            cdist2[iclose]= coff[i]+ long(design[imatch[iclose]].priority)
        endif

        costs[i]= ptr_new(cdist2)
        nmtot= nmtot+nmatch
        ismatched[imatch]=1
    endelse
endfor
narc= narc+nmtot

narc=narc+1L

tmpdir=getenv('PLATELIST_DIR')+'/tmp'
openw, unit, tmpdir+'/tmp_prob.txt', /get_lun

printf, unit, 'c Max flow problem for guides'
printf, unit, 'p min '+strtrim(string(nnode),2)+' '+strtrim(string(narc),2)
printf, unit, 'c source node'
printf, unit, 'n 0 '+strtrim(string(nguide),2)
printf, unit, 'c sink node'
printf, unit, 'n '+strtrim(string(nnode-1),2)+' -'+strtrim(string(nguide),2)
printf, unit, 'c source to guide arcs'
for i=0L, nguide-1L do $
      printf, unit, 'a 0 '+strtrim(string(i+1L),2)+' 0 1 0'
printf, unit, 'c guide to target arcs'
for i=0L, nguide-1L do begin
    if(keyword_set(matches[i])) then begin
        tmp_matches= *matches[i]
        tmp_costs= *costs[i]
        for j=0L, n_elements(tmp_costs)-1L do $
              printf, unit, 'a '+strtrim(string(i+1L),2)+' '+ $
                      strtrim(string(tmp_matches[j]+nguide+1L),2)+' 0 1 '+ $
                      strtrim(string(tmp_costs[j]),2)
    endif
endfor
printf, unit, 'c target to sink arcs'
for i=0L, ntarget-1L do $
      printf, unit, 'a '+strtrim(string(i+1L+nguide),2)+' '+ $
              strtrim(string(nnode-1L),2)+' 0 1 0'
printf, unit, 'c overflow arc'
printf, unit, 'a 0 '+strtrim(string(nnode-1L),2)+' 0 '+ $
        strtrim(string(nguide),2)+' 10000000'
printf, unit, 'c end of flow problem'
free_lun, unit

spawn, 'cat '+tmpdir+'/tmp_prob.txt | '+ $
  getenv('PLATEDESIGN_DIR')+'/src/cs2/cs2 '+ $
  ' > '+tmpdir+'/tmp_ans.txt'

nlines= numlines(tmpdir+'/tmp_ans.txt')
openr, unit, tmpdir+'/tmp_ans.txt', /get_lun
line=' '
gnum= lonarr(ntarget)-1L
for i=0L, nlines-1L do begin
    readf, unit, line
    if(strmid(line, 0, 1) eq 'f') then begin
        words=strsplit(line, /extr)
        flow= long(words[3])
        st= long(words[1])
        nd= long(words[2])
        if(flow gt 0 and st ge 1L and st le nguide) then begin
            gnum[nd-1L-nguide]= gfiber[st-1].guidenum
        endif
    endif
endfor
free_lun, unit

if(keyword_set(plot)) then begin
    splot, design.xf_default, design.yf_default, psym=4
    soplot, gfiber.xreach, gfiber.yreach, psym=4,color='red', th=2
    sxyouts, gfiber.xreach, gfiber.yreach, $
             strtrim(string(gfiber.guidenum),2), charsize=2.
    for i=0L, nguide-1L do begin
        ii=where(gnum eq gfiber[i].guidenum,nii)
        if(nii gt 0) then $
          soplot, [design[ii].xf_default, gfiber[i].xreach], $
                  [design[ii].yf_default, gfiber[i].yreach]
    endfor
endif

return, gnum

end

