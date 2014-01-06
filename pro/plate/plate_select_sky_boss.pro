;+
; NAME:
;   plate_select_sky_boss
; PURPOSE:
;   Given a plate center, pick appropriate sky locations from SDSS
; CALLING SEQUENCE:
;   plate_select_sky, racen, deccen, [ nsky=, $
;    tilerad=, seed=, sky_design= ]
; INPUTS:
;   racen, deccen - center of plate, J2000 degrees 
; OPTIONAL INPUTS:
;   tilerad - radius of tile in deg (default 1.49 deg)
;   nsky - number of sky fibers desired (default 64)
;   seed - random seed 
; OPTIONAL OUTPUTS:
;   sky_design - output structure with sky coordinates in J2000 [NSKY]
; REVISION HISTORY:
;   11-Oct-2007  MRB, NYU
;-
;------------------------------------------------------------------------------
pro plate_select_sky_boss, racen, deccen, nsky=nsky, tilerad=tilerad, $
  seed=seed, sky_design=sky_design

if(NOT keyword_set(tilerad)) then tilerad=1.49

objs= sdss_sweep_circle(racen, deccen, tilerad, type='sky', /all, /silent)
if(n_tags(objs) eq 0) then $
   message, 'No sky objects!'

indx= shuffle_indx(n_elements(objs), num_sub=nsky<n_elements(objs), seed=seed)
objs=objs[indx]

sky_design= replicate(design_blank(), n_elements(objs))
sky_design.target_ra= objs.ra
sky_design.target_dec= objs.dec
sky_design.targettype= 'SKY'
sky_design.sourcetype= 'NA'
sky_design.fibermag=25.
sky_design.psfmag=25.

return

end
