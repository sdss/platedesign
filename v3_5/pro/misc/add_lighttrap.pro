;+
; NAME:
;   add_lighttrap
; PURPOSE:
;   Add a light trap about 5 cm north of center
; CALLING SEQUENCE:
;   add_lighttrap, design
; COMMENTS:
;   Used as hack for LCO plates
; REVISION HISTORY:
;   13-Jul-2015  Michael Blanton, NYU
;-
;------------------------------------------------------------------------------
pro add_lighttrap, designid

trapfile= sdss_filename('plateTrap', designid=designid, pointing=1, offset=0)
traps= yanny_readone(trapfile, hdr=traps_hdr)

designfile= sdss_filename('plateDesign', designid=designid, pointing=1, offset=0)
design= yanny_readone(designfile, hdr=design_hdr)

racen= (double(yanny_par(design_hdr, 'raCen')))[0]
deccen= (double(yanny_par(design_hdr, 'decCen')))[0]
observatory= 'LCO'

ad2xyfocal, observatory, racen, deccen+0.15, xf, yf, lambda=8000., $
  racen=racen, deccen=deccen, lst=racen, airtemp=12.

newtrap= design_blank(/trap)
newtrap.target_ra= racen
newtrap.target_dec= deccen+0.15
newtrap.pointing=1
newtrap.offset=0
newtrap.xf_default=xf
newtrap.yf_default=yf

if(n_tags(traps) gt 0) then begin
    traps= [traps, newtrap]
    pdata=ptr_new(traps)
    yanny_write, trapfile, pdata, hdr=traps_hdr
endif else begin
    traps= newtrap
    pdata=ptr_new(traps)
    traps_hdr=[design_hdr, $
               'pointing '+strtrim(string(1),2), $
               'offset '+strtrim(string(0),2), $
               'platedesign_version '+platedesign_version()]
    yanny_write, trapfile, pdata, hdr=traps_hdr
endelse

END
