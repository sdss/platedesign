;+
; NAME:
;   check_fiberreach
; PURPOSE:
;   for a marvels plate, check the fiber reach
; CALLING SEQUENCE:
;   check_fiberreach, plateid
; INPUTS:
;   plateid - plate id
; COMMENTS:
;   Outputs to user which fibers are further than 8 inches
; REVISION HISTORY:
;   26-Oct-2008  Written by MRB, NYU
;-
;------------------------------------------------------------------------------
pro check_fiberreach, plateid , guide=guide

platescale = get_platescale('APO')
limitmm=8.*25.4   ;;; limit of reach in mm    

blockfile=getenv('PLATEDESIGN_DIR')+'/data/marvels/fiberBlocksMarvels.par'
fiberblocks= yanny_readone(blockfile)
xfiber= fiberblocks.fibercenx*platescale
yfiber= fiberblocks.fiberceny*platescale

platedir= plate_dir(plateid)
holes= yanny_readone(platedir+'/plateHoles-'+ $
                     strtrim(string(f='(i6.6)', plateid),2)+'.par')

im= where(holes.holetype eq 'MARVELS', nm)
if(nm eq 0) then begin
    splog, 'Not a MARVELS plate.'
    return
endif
holes=holes[im]

for pointing=1, 2 do begin
    foff=(pointing-1)*60
    ip= where(holes.pointing eq pointing, np)
    
    dist2= (xfiber[holes[ip].fiberid-1-foff]-holes[ip].xfocal)^2+ $
      (yfiber[holes[ip].fiberid-1-foff]-holes[ip].yfocal)^2
    
    iout= where(dist2 gt limitmm^2, nout)

    for i=0L, nout-1L do begin
        splog, 'fiberid '+strtrim(holes[ip[iout[i]]].fiberid)+' '+ $
          strtrim(string(f='(f40.3)',sqrt(dist2[iout[i]])/25.4),2)+' '+ $
          'inches away'
    endfor
endfor
  
return
end
