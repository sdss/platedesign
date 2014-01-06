;+
; NAME:
;   plate_add_washers
; PURPOSE:
;   Add washers to a plate 
; CALLING SEQUENCE:
;   plate_add_washers, plateid
; COMMENTS:
;   Adds washers to a plate as per Kyle's requests.
;   Bombs if plate is not in run 2009.05.b.boss (for safety!)
; REVISION HISTORY:
;   30-Jun-2011  Demitri Muna, NYU
;-
;------------------------------------------------------------------------------
pro plate_add_washers, plateid, bluefix=bluefix

common com_plate_add_washers, plans

if(n_tags(plans) eq 0) then $
  plans= yanny_readone(getenv('PLATELIST_DIR')+'/platePlans.par')

iplan =where(plans.plateid eq plateid, nplan)
plan= plans[iplan[0]]

if(nplan gt 1) then $
  message, 'More than one plate '+string(plateid)
if(plan.platerun ne '2009.05.b.boss') then $
  message, 'Only run this on plates from 2009.05.b.boss'

platedir=plate_dir(plateid)

holes= yanny_readone(platedir+'/plateHoles-'+ $
                     string(plateid, f='(i6.6)')+'.par', $
                     enum=enum, struct=struct, hdr=hdr)
sholes= yanny_readone(platedir+'/plateHolesSorted-'+ $
                      string(plateid, f='(i6.6)')+'.par', $
                      enum=senum, struct=sstruct, hdr=shdr)


isci= where(sholes.holetype eq 'BOSS', nsci)
iscih= where(holes.holetype eq 'BOSS', nsci)

sholes[isci].zoffset=0.
sholes[isci].bluefiber=0.
holes[iscih].zoffset=0.
holes[iscih].bluefiber=0.

iodd=lindgen(10)*2L+1
for block=1L, 50L do begin
    iblock= where(sholes[isci].block eq block, nblock)
    if(nblock ne 20) then $
      message, 'Bad block'
    indx= shuffle_indx(nblock)
    ithin=indx[0:4]
    ithick=indx[5:9]
    sholes[isci[iblock[ithin]]].zoffset=175.
    sholes[isci[iblock[ithick]]].zoffset=300.
    if(keyword_set(bluefix)) then begin
        isort=sort(sholes[isci[iblock]].yfocal)
        sholes[isci[iblock[isort[iodd]]]].bluefiber=1
    endif
endfor

spherematch, sholes[isci].target_ra, sholes[isci].target_dec, $
  holes[iscih].target_ra, holes[iscih].target_dec, 1./3600., m1, m2
if(n_elements(m1) ne 1000) then $
  message, 'ack'

holes[iscih[m2]].zoffset= sholes[isci[m1]].zoffset
holes[iscih[m2]].bluefiber= sholes[isci[m1]].bluefiber

pdata= ptr_new(sholes)
yanny_write, platedir+'/plateHolesSorted-'+string(plateid, f='(i6.6)')+'.par', $
  pdata, enum=senum, struct=sstruct, hdr=shdr
ptr_free, pdata

pdata= ptr_new(holes)
yanny_write, platedir+'/plateHoles-'+string(plateid, f='(i6.6)')+'.par', $
  pdata, enum=enum, struct=struct, hdr=hdr
ptr_free, pdata


end
