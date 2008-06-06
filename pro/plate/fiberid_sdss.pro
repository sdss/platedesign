;+
; NAME:
;   fiberid_sdss
; PURPOSE:
;   assign fiberid's to a list of SDSS targets
; CALLING SEQUENCE:
;   fiberid= fiberid_sdss(design)
; INPUTS:
;   design - [640] struct array of targets, in design_blank() form
;            Required tags are .XF_DEFAULT, .YF_DEFAULT
; OUTPUTS:
;   fiberid - 1-indexed list of fibers 
; COMMENTS:
;   Uses sdss_plugprob to solve the plugging problem.
;   First, assigns standards, guaranteeing at least one per block
;   Second, assigns skies, guaranteeing at least one per block
;   Finally, assigns all others, guaranteeing at least one per block
; REVISION HISTORY:
;   4-Jun-2008 MRB, NYU 
;-
function fiberid_sdss, design

fiberused=0L
fiberid=lonarr(n_elements(design))

;; assign standards, if any exist
;; ask for 1 in each block at least
istd= where(design.targettype eq 'STANDARD', nstd)
if(nstd gt 0) then begin
    sdss_plugprob, design[istd].xf_default, design[istd].yf_default, $
      tmp_fiberid, mininblock=1, fiberused=fiberused
    
    iassigned=where(tmp_fiberid ge 1, nassigned)
    if(nassigned gt 0) then begin
        if(keyword_set(fiberused)) then $
          fiberused=tmp_fiberid[iassigned] $
        else $
          fiberused=[fiberused, tmp_fiberid[iassigned]] 
    endif 
    
    fiberid[istd]=tmp_fiberid
endif else begin
    splog, 'No standards in this plate, I hope you meant to do that.'
endelse

;; assign skies, if any exist
;; ask for 1 in each block at least
isky= where(design.targettype eq 'SKY', nsky)
if(nsky gt 0) then begin
    sdss_plugprob, design[isky].xf_default, design[isky].yf_default, $
      tmp_fiberid, mininblock=1, fiberused=fiberused
    
    iassigned=where(tmp_fiberid ge 1, nassigned)
    if(nassigned gt 0) then begin
        if(keyword_set(fiberused)) then $
          fiberused=tmp_fiberid[iassigned] $
        else $
          fiberused=[fiberused, tmp_fiberid[iassigned]] 
    endif 
    
    fiberid[isky]=tmp_fiberid
endif else begin
    splog, 'No skies in this plate, I hope you meant to do that.'
endelse

;; assign the rest
ileft= where(fiberid eq 0, nleft)
if(nleft gt 0) then begin
    sdss_plugprob, design[ileft].xf_default, design[ileft].yf_default, $
      tmp_fiberid, fiberused=fiberused
    
    iassigned=where(tmp_fiberid ge 1, nassigned)
    if(nassigned gt 0) then begin
        if(keyword_set(fiberused)) then $
          fiberused=tmp_fiberid[iassigned] $
        else $
          fiberused=[fiberused, tmp_fiberid[iassigned]] 
    endif 
    
    fiberid[ileft]=tmp_fiberid
endif else begin
    splog, 'No science targets in this plate, I hope you meant to do that.'
endelse

return, fiberid

end

