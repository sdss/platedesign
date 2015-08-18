pro test_segue2_inputs

ra=184.86
dec=40.369889

stars= sdss_sweep_circle(ra, dec, 1.49, type='star')

rmag=22.5-2.5*alog10(stars.psfflux[2])

ii=where(rmag gt 16. and rmag lt 20., nii)

indx=shuffle_indx(nii, num_sub=1000)

stars=stars[ii[indx]]

hdr=['targettype science', $
     'pointing 1', $
     'offset 0', $
     'racen '+strtrim(string(ra,f='(f40.20)'),2), $
     'deccen '+strtrim(string(dec,f='(f40.20)'),2), $
     'instrument SDSS']

outstr0={ra:0.D, $
         dec:0.D, $
         sourcetype:'STAR', $
         priority:1L, $
         segue2_target1:0L, $
         segue2_target2:0L, $
         run:0L, $
         rerun:' ', $
         camcol:0L, $
         field:0L, $
         id:0L, $
         psfflux:fltarr(5), $
         psfflux_ivar:fltarr(5), $
         fiberflux:fltarr(5), $
         fiberflux_ivar:fltarr(5)}
outstr= replicate(outstr0, n_elements(stars))

struct_assign, stars, outstr, /nozero

yanny_write, getenv('PLATELIST_DIR')+'/inputs/example/'+ $
  'plateInput-SEGUE2-test.par', ptr_new(outstr), hdr=hdr

end
