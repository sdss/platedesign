;+
; NAME:
;   gfiber_apogeesouthtest_params
; PURPOSE:
;   Return parameters associated with the new guide fibers (Fall 2009)
; CALLING SEQUENCE:
;   gfiber=gfiber_apogeesouthtest_params()
; OUTPUTS:
;   gfiber - parameters for each guide fiber:
;                  .XREACH - point of origin (X)
;                  .YREACH - point of origin (Y)
;                  .RREACH - maximum radius of reach
;                  .XPREFER - preferred location (X)
;                  .YPREFER - preferred location (Y)
;                  .BLOCK - block ID
; COMMENTS:
;   Returns 48 guide positions; just the regular 48 repeated 3 times. 
;   Calls gfiber2_params and replicates 3 times (incrementing guide
;     numbers)
; REVISION HISTORY:
;   10-Jun-2008  MRB, NYU
;    1-Sep-2010  Demitri Muna, NYU, Adding file test before opening files.
;   21-Apr-2015  Altered for 144 guide star case MRB, NYU
;-
function gfiber_apogeesouthtest_params

;; get real guide fiber configuration
gfiberorig= gfiber2_params()
gfiberorig= struct_addtags(gfiberorig, $
                           replicate({block:-1L}, n_elements(gfiberorig)))

;; replicate it nine times, incrementing guide number
gfiber= [gfiberorig, gfiberorig, gfiberorig, $
         gfiberorig, gfiberorig, gfiberorig, $
         gfiberorig, gfiberorig, gfiberorig]
for i=0L, 8L do begin
    offset= float((i mod 3)-1L)*20.
    gfiber[i*16:(i+1)*16-1].yprefer= gfiber[i*16:(i+1)*16-1].yprefer+offset 
    gfiber[i*16:(i+1)*16-1].block=  $
      gfiber[i*16:(i+1)*16-1].guidenum 
    gfiber[i*16:(i+1)*16-1].guidenum=  $
      gfiber[i*16:(i+1)*16-1].guidenum + i*n_elements(gfiberorig)
endfor

return, gfiber

end
;------------------------------------------------------------------------------
