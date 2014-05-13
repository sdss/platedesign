;+
; NAME:
;   plate_assign_constrained
; PURPOSE:
;   Run plate_assign, but make sure we satisfy fiber constraints
; CALLING SEQUENCE:
;   plate_assign_constrained, definition, default, instrument, targettype,
;     fibercount, pointing, offset, design, new_design, [ seed=, $
;     [parameters for fiberid_ commands]
; REVISION HISTORY:
;   7-June-2008  MRB, NYU
;-
;------------------------------------------------------------------------------
pro plate_assign_constrained, definition, default, instrument, $
                              targettype, fibercount, pointing, offset, $
                              design, in_new_design, seed=seed, $
							  plate_obj=plate_obj, debug=debug, $
                              _EXTRA=extra_for_fiberid

;; params from default
targettypes= strsplit(default.targettypes, /extr)
instruments= strsplit(default.instruments, /extr)
iinst=where(strlowcase(instruments) eq strlowcase(instrument), ninst)

test_design= [design, in_new_design]
icurr= where(strupcase(test_design.holetype) eq strupcase(instrument) AND $
             strupcase(test_design.targettype) eq strupcase(targettype), $
             ncurr)
istd=where(strlowcase(targettypes) eq strlowcase(targettype), nstd)
nneed= fibercount.ntot[iinst,istd, pointing-1, offset]
if(ncurr lt nneed) then begin
  message, color_string('Not enough targets of type '+strupcase(targettype)+'!', 'red', 'bold')
endif

test_design=0

;; do not alter new_design ...
new_design=in_new_design

gotall=0
while(gotall eq 0) do begin

    ;; perform assignment, but allow for a few extra
    ;; to be collected, in order to we make sure we
    ;; satisfy the fiber constraints
    test_design=design
    test_fibercount=fibercount
    plate_assign, definition, default, test_fibercount, test_design, $
                  new_design, seed=seed, /collect

    ;; now assign fibers
    icurr=where(test_design.holetype eq instrument)
    fiberids= call_function('fiberid_'+instrument, $
                            default, test_fibercount, $
                            test_design[icurr], $
                            /quiet, all_design=test_design, $
							plate_obj=plate_obj, $
                            _EXTRA=extra_for_fiberid)
    
    ;; check if the standards filled up the fibers
    ion=where(fiberids ge 1 AND $
              test_design[icurr].pointing eq pointing AND $
              test_design[icurr].offset eq offset AND $
              strlowcase(test_design[icurr].targettype) $
              eq strlowcase(targettype), non)
    istd=where(strlowcase(targettypes) eq strlowcase(targettype), nstd)
        
    if(non ge test_fibercount.ntot[iinst, istd, pointing-1L, offset]) $
      then begin
        
        ;; if so, save the results
        design=test_design
        fibercount=test_fibercount
        gotall=1
        
    endif else begin
        
        ;; if we are already collecting all
        ;; possible standards, bomb
        if(fibercount.ncollect[iinst, istd, $
                               pointing-1L, offset] gt $
           n_elements(new_design)) then begin
            splog, color_string('Not enough targets for plate_assign_constrained!', 'red', 'bold')
            if(keyword_set(debug)) then stop
            return
        endif
        
        ;; if not, increase the collect factor to
        ;; get more standards
        fibercount.ncollect[iinst, istd, pointing-1L, offset]=  $
          2L*fibercount.ncollect[iinst, istd, pointing-1L, offset]
        splog, 'Increasing collection number to '+ $
               strtrim(string(fibercount.ncollect[iinst,istd, $
                                                  pointing-1L,offset]),2)
        splog, '  instrument= '+instruments[iinst]
        splog, '  pointing= '+strtrim(string(pointing),2)
        splog, '  offset= '+strtrim(string(offset),2)
    endelse

endwhile

end
