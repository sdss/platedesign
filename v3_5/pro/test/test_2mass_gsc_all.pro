;+
; NAME:
;   plate_select_guide_2mass
; PURPOSE:
;   Select guide stars for a single plate from SDSS
; CALLING SEQUENCE:
;   plate_select_guide_2mass, racen, deccen, epoch= $
;    [ rerun=, tilerad=, guide_design= ]
; INPUTS:
;   racen      - RA center for tile [J2000 deg]
;   deccen     - DEC center for tile [J2000 deg]
;   epoch      - Epoch for output stars, for applying proper motion [yr]
; OPTIONAL INPUTS:
;   tilerad    - Tile radius; default to 1.49 deg
; OPTIONAL OUTPUTS:
;   guide_design   - Output structure with sky coordinates in J2000 [NSKY]
; COMMENTS:
;   2MASS guide stars are selected as follows:
;     0.4 < J-K < 0.6
;   All magnitudes and colors are without extinction-correction.
;   Keeps stars away from edge (limits at 1.45 deg)
; REVISION HISTORY:
;   10-Oct-2007  Written by D. Schlegel, LBL
;-
;------------------------------------------------------------------------------
pro test_2mass_gsc_all

plans= yanny_readone(getenv('PLATELIST_DIR')+'/platePlans.par')

im= where(strlowcase(plans.survey) eq 'marvels',nm)

dra= fltarr(nm)
ddec= fltarr(nm)
dtot= fltarr(nm)
for i=0L, nm-1L do begin
    test_2mass_gsc, plans[im[i]].racen, plans[im[i]].deccen, $
      dra=tmp_dra, ddec=tmp_ddec
    dra[i]=tmp_dra
    ddec[i]=tmp_ddec
    dtot[i]=sqrt(dra[i]^2+ddec[i]^2)
endfor

save, filename='~/test-2mass-gsc-all.sav'

return
end
;------------------------------------------------------------------------------
