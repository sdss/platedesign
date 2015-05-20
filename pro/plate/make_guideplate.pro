;+
; NAME:
;   make_guideplate
; PURPOSE:
;   Create a guider test plate
; CALLING SEQUENCE:
;   make_guideplate
; REVISION HISTORY:
;   11-May-2009 MRB, NYU 
;-
pro make_guideplate 

tilerad= 1.49
platescale = platescale('APO')
spacing= 10. ; mm
nn= long(0.5*(2.1*tilerad*platescale/spacing))*2L+1L

racen= 180.D
deccen= 0.D

design= create_struct(design_blank(/guide), 'ra', 0.D, 'dec', 0.D)
design.pointing=1

design.xf_default= 0.
design.yf_default= 0.

xyfocal2ad, 'APO', design.xf_default, design.yf_default, ra, dec, $
            racen=racen, deccen=deccen

design.target_ra= ra
design.target_dec= dec
design.ra= ra
design.dec= dec

hdr=['targettype SKY', $
     'instrument SDSS', $
     'raCen '+strtrim(string(racen,f='(f40.10)'),2), $
     'decCen '+strtrim(string(deccen,f='(f40.10)'),2), $
     'epoch 2009.5', $
     'pointing 1']

pdata= ptr_new(design)
yanny_write, design_dir(708)+'/plateGuide-000708-p1.par', pdata, hdr=hdr
ptr_free, pdata

end

