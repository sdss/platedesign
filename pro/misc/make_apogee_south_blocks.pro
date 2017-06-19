;+
; NAME:
;   make_apogee_south_blocks
; PURPOSE:
;   make APOGEE South fiber blocks file
; CALLING SEQUENCE:
;   make_apogee_south_blocks
; REVISION HISTORY:
;   30-May-2017 MRB, NYU 
;-
pro make_apogee_south_blocks, cart22=cart22


if(not keyword_set(cart22)) then $
   infile= getenv('PLATEDESIGN_DIR')+ $
   '/data/apogee/fiberBlocksSouth-2017-05-30.dat' $
else $
   infile= getenv('PLATEDESIGN_DIR')+ $
   '/data/apogee/fiberBlocksSouth-Cart22-2017-06-01.dat' 
readcol, infile, f='(d,f,f)', block, xn, yn 

xf_block = yn * 25.4
yf_block = - xn * 25.4

inchpermm = 0.039370
fspace = 0.15/inchpermm

ftype = ['F', 'M', 'B', 'B', 'M', 'F']

mblocks= replicate({TIFIBERBLOCK, blockid:0L, fiberid:0L, $
                    fibercenx:0.D, $
                    fiberceny:0.D, $
                    ftype:' '}, 300)

xf = dblarr(300)
yf = dblarr(300)

ifiber = 0L

for i = 0L, n_elements(xn) - 1L do begin
    if(xf_block[i] lt 0.) then $
      sign = 1. $
    else $
      sign = -1.

    for j = 0, 5 do begin
        xf[ifiber] = xf_block[i] + sign * float(j) * fspace
        yf[ifiber] = yf_block[i]
        mblocks[ifiber].blockid = block[i]
        mblocks[ifiber].fiberid = ifiber + 1
        mblocks[ifiber].ftype = ftype[j]
        ifiber = ifiber + 1
    endfor

endfor

platescale = get_platescale('LCO')

mblocks.fibercenx = xf / platescale 
mblocks.fiberceny = yf / platescale 

if(not keyword_set(cart22)) then $
  outfile= getenv('PLATEDESIGN_DIR')+ $
  '/data/apogee/fiberBlocksAPOGEE_SOUTH.par' $
else $
  outfile= getenv('PLATEDESIGN_DIR')+ $
  '/data/apogee/fiberBlocksAPOGEE_SOUTH_CART22.par'

pdata= ptr_new(mblocks)
yanny_write, outfile, pdata, hdr=hdr
ptr_free, pdata

end

