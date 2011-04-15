;+
; NAME:
;   fix_plug_ra_range
; PURPOSE:
;   Fix plPlugMapP ra range issue
; CALLING SEQUENCE:
;   fix_plug_ra_range, plate 
; COMMENTS:
;   Fixes in three places:
;      $PLATELIST_DIR/plates
;      $PLATELIST_DIR/runs
;   and, after searching platelist for observation date:
;      $SPECLOG_DIR
; REVISION HISTORY:
;   20-Aug-2008  MRB, NYU
;-
;------------------------------------------------------------------------------
pro fix_file, filename

pl= yanny_readone(filename, hdr=hdr, enums=enums, structs=structs)
pl.ra= ra_in_range(pl.ra)
pdata= ptr_new(pl)
yanny_write, filename, pdata, hdr=hdr, enums=enums, structs=structs

end
;
pro fix_plug_ra_range, plate

common com_fix_plug_ra_range, plist, plans

if(n_tags(plist) eq 0) then $
  plist= mrdfits(getenv('BOSS_SPECTRO_REDUX')+'/platelist.fits',1)
if(n_tags(plans) eq 0) then $
  plans= yanny_readone(getenv('PLATELIST_DIR')+'/platePlans.par')

pdir= plate_dir(plate)
plugfile1= pdir+'/plPlugMapP-'+string(f='(i4.4)', plate)+'.par'
splog, plugfile1
fix_file, plugfile1

iplan= where(plans.plateid eq plate, nplan)
prun= plans[iplan].platerun
plugfile2= getenv('PLATELIST_DIR')+'/runs/'+prun+ $
  '/plPlugMapP-'+string(f='(i4.4)', plate)+'.par'
splog, plugfile2
fix_file, plugfile2

ilist= where(plist.plate eq plate, nlist)
for i=0L, nlist-1L do begin
    splog, plist[ilist[i]].mjd
    mjds=strsplit(plist[ilist[i]].mjdlist, /extr)
    for j=0L, n_elements(mjds)-1L do begin
        files= file_search(getenv('SPECLOG_DIR')+'/'+ $
                           mjds[j]+'/plPlugMapM-'+ $
                           string(f='(i4.4)', plate)+'*.par')
        splog, files
        fix_file, files
    endfor
endfor

return
end
