;+
; NAME:
;   make_apogeeboss_blocks
; PURPOSE:
;   make APOGEE fiber blocks file for APOGEE+BOSS
; CALLING SEQUENCE:
;   make_apogee_south_blocks
; REVISION HISTORY:
;   30-May-2017 MRB, NYU 
;-
pro make_apogeeboss_v2_blocks

rows = [- 245.5, - 114.6, 114.6, 245.5]
drows = [1., 1., -1., -1.]

columns0 = 241. - 46. * findgen(12)
columns1 = 309. - 46. * findgen(15)
columns2 = 332. - 46. * findgen(15)
columns3 = 260. - 46. * findgen(12)

apogeeblocks0 = [2, 3, 6, 8, 10]
apogeeblockssub0 = [[1, 1, 0], $
                    [0, 1, 1], $
                    [0, 1, 1], $
                    [0, 1, 1], $
                    [1, 1, 1]]

apogeeblocks1 = [3, 5, 7, 9, 12]
apogeeblockssub1 = [[1, 1, 1], $
                    [1, 1, 1], $
                    [1, 1, 1], $
                    [1, 1, 1], $
                    [0, 1, 1]]

apogeeblocks2 = [1, 3, 5, 7, 9, 12]
apogeeblockssub2 = [[1, 1, 1], $
                    [1, 1, 1], $
                    [0, 1, 1], $
                    [0, 1, 1], $
                    [1, 1, 1], $
                    [0, 1, 1]]

apogeeblocks3 = [1, 3, 5, 7, 9]
apogeeblockssub3 = [[1, 1, 1], $
                    [1, 1, 0], $
                    [1, 1, 0], $
                    [1, 0, 0], $
                    [1, 1, 0]]

mblocks= replicate({TIFIBERBLOCK, blockid:0L, fiberid:0L, $
                    fibercenx:0.D, $
                    fiberceny:0.D, $
                    ftype:' '}, 300)

xf = dblarr(300)
yf = dblarr(300)

ifiber = 0L
blockid = 1L
nper = 6
inchpermm = 0.039370
fspace = 0.15/inchpermm
ftype = ['F', 'M', 'B', 'B', 'M', 'F']

row = 0
columns = columns0
apogeeblocks = apogeeblocks0
apogeeblockssub = apogeeblockssub0
for i = 0L, n_elements(apogeeblocks) - 1L do begin
   bb = apogeeblocks[i]
   cst = columns[bb]
   rst = rows[row]
   dr = drows[row]
   for j = 0, 2 do begin
      if(apogeeblockssub[j, i]) then begin
         xf[ifiber:ifiber + nper -1] = cst
         yf[ifiber:ifiber + nper -1] = rst + dr * fspace * (findgen(nper) + nper * j)
         mblocks[ifiber:ifiber + nper - 1].blockid = blockid
         mblocks[ifiber:ifiber + nper - 1].ftype = ftype
         ifiber = ifiber + nper
         blockid = blockid + 1
      endif
   endfor
endfor

row = 1
columns = columns1
apogeeblocks = apogeeblocks1
apogeeblockssub = apogeeblockssub1
for i = 0L, n_elements(apogeeblocks) - 1L do begin
   bb = apogeeblocks[i]
   cst = columns[bb]
   rst = rows[row]
   dr = drows[row]
   for j = 0, 2 do begin
      if(apogeeblockssub[j, i]) then begin
         xf[ifiber:ifiber + nper -1] = cst
         yf[ifiber:ifiber + nper -1] = rst + dr * fspace * (findgen(nper) + nper * j)
         mblocks[ifiber:ifiber + nper - 1].blockid = blockid
         mblocks[ifiber:ifiber + nper - 1].ftype = ftype
         ifiber = ifiber + nper
         blockid = blockid + 1
      endif
   endfor
endfor

row = 2
columns = columns2
apogeeblocks = apogeeblocks2
apogeeblockssub = apogeeblockssub2
for i = 0L, n_elements(apogeeblocks) - 1L do begin
   bb = apogeeblocks[i]
   cst = columns[bb]
   rst = rows[row]
   dr = drows[row]
   for j = 0, 2 do begin
      if(apogeeblockssub[j, i]) then begin
         xf[ifiber:ifiber + nper -1] = cst
         yf[ifiber:ifiber + nper -1] = rst + dr * fspace * (findgen(nper) + nper * j)
         mblocks[ifiber:ifiber + nper - 1].blockid = blockid
         mblocks[ifiber:ifiber + nper - 1].ftype = ftype
         ifiber = ifiber + nper
         blockid = blockid + 1
      endif
   endfor
endfor

row = 3
columns = columns3
apogeeblocks = apogeeblocks3
apogeeblockssub = apogeeblockssub3
for i = 0L, n_elements(apogeeblocks) - 1L do begin
   bb = apogeeblocks[i]
   cst = columns[bb]
   rst = rows[row]
   dr = drows[row]
   for j = 0, 2 do begin
      if(apogeeblockssub[j, i]) then begin
         xf[ifiber:ifiber + nper -1] = cst
         yf[ifiber:ifiber + nper -1] = rst + dr * fspace * (findgen(nper) + nper * j)
         mblocks[ifiber:ifiber + nper - 1].blockid = blockid
         mblocks[ifiber:ifiber + nper - 1].ftype = ftype
         ifiber = ifiber + nper
         blockid = blockid + 1
      endif
   endfor
endfor

platescale = get_platescale('APO')

mblocks.fiberid = lindgen(n_elements(mblocks)) + 1
mblocks.fibercenx = xf / platescale 
mblocks.fiberceny = yf / platescale 

outfile= getenv('PLATEDESIGN_DIR')+ $
         '/data/apogee/fiberBlocksAPOGEEwBOSS_v2.par'

pdata= ptr_new(mblocks)
yanny_write, outfile, pdata, hdr=hdr
ptr_free, pdata

end

