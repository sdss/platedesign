;+
; NAME:
;   cmm_fit_all
; PURPOSE:
;   Fit all CMM data available in file starting with 'D'
; CALLING SEQUENCE:
;   cmm_fit_all
; OUTPUTS:
;   Writes out cmm_fit_all.fits, structure with details of fit for
;   each plate:
;           .NHOLE - number of holes
;           .XOFF - best-fit X offset (add to nominal)
;           .YOFF - best-fit Y offset (add to nominal)
;           .ANGLE - best-fit angle of rotation (clockwise after shift)
;           .SCALE - best-fit rescale (multiply to nominal after
;                    shift/rotate)
;           .SIGX - X residual after rescaling
;           .SIGY - Y residual after rescaling
;           .SIG - total residual after rescaling
;           .XMEAS[2000] - position of measured hole
;           .YMEAS[2000] - 
;           .XNOM[2000] - nominal position of hole
;           .YNOM[2000] - 
;           .DX[2000] - measured minus nominal residual
;           .DY[2000] - 
;           .XFIT[2000] - position of nominal hole fit to measured
;           .YFIT[2000] - 
;           .DXFIT[2000] - residual left after recaling
;           .DYFIT[2000] - 
; REVISION HISTORY:
;   22-Sep-2008  MRB, NYU
;-
;------------------------------------------------------------------------------
pro cmm_fit_all, tilt=tilt, squash=squash, fix=fix

files= file_search('D*')
for i=0L, n_elements(files)-1L do begin
   if(keyword_set(tilt)) then $
      cmm0= cmm_fit_tilt(files[i]) $
   else if(keyword_set(squash)) then $
      cmm0= cmm_fit_squash(files[i], fix=fix) $
   else $
      cmm0= cmm_fit(files[i])
   if(n_tags(cmm) eq 0) then $
      cmm= cmm0 $
   else $
      cmm= [cmm, cmm0]
endfor

cmm= cmm[sort(cmm.mjd)]

if(keyword_set(tilt)) then begin
    mwrfits, cmm, 'cmm_fit_all_tilt.fits', /create 
endif else if(keyword_set(squash)) then begin
    if(keyword_set(fix)) then $
      mwrfits, cmm, 'cmm_fit_all_squash_fix.fits', /create  $
    else $
      mwrfits, cmm, 'cmm_fit_all_squash.fits', /create  
endif else begin 
    mwrfits, cmm, 'cmm_fit_all.fits', /create
endelse

end
