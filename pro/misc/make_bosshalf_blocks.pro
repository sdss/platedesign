;+
; NAME:
;   make_bosshalf_blocks
; PURPOSE:
;   make fiber blocks file for APOGEE+BOSS
; CALLING SEQUENCE:
;   make_apogee_south_blocks
; REVISION HISTORY:
;   30-May-2017 MRB, NYU 
;-
pro make_bosshalf_blocks

rows = [- 245.5, - 114.6, 114.6, 245.5]
drows = [1., 1., -1., -1.]

columns0 = 241. - 46. * findgen(12)
columns1 = 309. - 46. * findgen(15)
columns2 = 332. - 46. * findgen(15)
columns3 = 260. - 46. * findgen(12)

bossblocks0 = [0, 2, 4, 6, 7, 10]
bossblocks1 = [3, 4, 6, 8, 10, 13, 14]
bossblocks2 = [1, 3, 6, 8, 10, 12]
bossblocks3 = [1, 3, 5, 7, 9, 11]

mblocks= replicate({TIFIBERBLOCK, blockid:0L, fiberid:0L, $
                    fibercenx:0.D, $
                    fiberceny:0.D, $
                    ftype:'B'}, 500)

xf = dblarr(500)
yf = dblarr(500)

ifiber = 0L
blockid = 1L
nper = 20
inchpermm = 0.039370
fspace = 0.15/inchpermm

row = 0
columns = columns0
bossblocks = bossblocks0
for i = 0L, n_elements(bossblocks) - 1L do begin
   bb = bossblocks[i]
   cst = columns[bb]
   rst = rows[row]
   dr = drows[row]
   xf[ifiber:ifiber + nper -1] = cst
   yf[ifiber:ifiber + nper -1] = rst + dr * fspace * findgen(nper)
   mblocks[ifiber:ifiber + nper - 1].blockid = blockid
   ifiber = ifiber + nper
   blockid = blockid + 1
endfor

row = 1
columns = columns1
bossblocks = bossblocks1
for i = 0L, n_elements(bossblocks) - 1L do begin
   bb = bossblocks[i]
   cst = columns[bb]
   rst = rows[row]
   dr = drows[row]
   xf[ifiber:ifiber + nper -1] = cst
   yf[ifiber:ifiber + nper -1] = rst + dr * fspace * findgen(nper)
   mblocks[ifiber:ifiber + nper - 1].blockid = blockid
   ifiber = ifiber + nper
   blockid = blockid + 1
endfor

row = 2
columns = columns2
bossblocks = bossblocks2
for i = 0L, n_elements(bossblocks) - 1L do begin
   bb = bossblocks[i]
   cst = columns[bb]
   rst = rows[row]
   dr = drows[row]
   xf[ifiber:ifiber + nper -1] = cst
   yf[ifiber:ifiber + nper -1] = rst + dr * fspace * findgen(nper)
   mblocks[ifiber:ifiber + nper - 1].blockid = blockid
   ifiber = ifiber + nper
   blockid = blockid + 1
endfor

row = 3
columns = columns3
bossblocks = bossblocks3
for i = 0L, n_elements(bossblocks) - 1L do begin
   bb = bossblocks[i]
   cst = columns[bb]
   rst = rows[row]
   dr = drows[row]
   xf[ifiber:ifiber + nper -1] = cst
   yf[ifiber:ifiber + nper -1] = rst + dr * fspace * findgen(nper)
   mblocks[ifiber:ifiber + nper - 1].blockid = blockid
   ifiber = ifiber + nper
   blockid = blockid + 1
endfor

platescale = get_platescale('APO')

mblocks.fibercenx = xf / platescale 
mblocks.fiberceny = yf / platescale 

outfile= getenv('PLATEDESIGN_DIR')+ $
         '/data/boss/fiberBlocksBOSSwAPOGEE.par'

pdata= ptr_new(mblocks)
yanny_write, outfile, pdata, hdr=hdr
ptr_free, pdata

end

