;+
; NAME:
;   ha_limits
; PURPOSE:
;   Determine HA limits of a plate
; CALLING SEQUENCE:
;   ha_limits, plateid, design=, hamin=, hamax=, maxoff_arcsec=, /plot
; REQUIRED INPUTS:
;   plateid - plate ID number
;   maxoff_arcsec - maximum offset required
; OPTIONAL INPUTS:
;   design - [N] design structure (if not input, reads in design file)
; OPTIONAL KEYWORDS:
;   /plot - creates a splot window with results
; REVISION HISTORY:
;   20-Oct-2008  MRB, NYU
;    1-Sep-2010  Demitri Muna, NYU, Adding file test before opening files.
;	15-May-2015  Demitri Muna, Adding support for plate IDs > 9999
;-
pro ha_limits, plateid, design=design, $
               hamin=hamin, hamax=hamax, maxoff_arcsec=maxoff_arcsec, $
               plot=plot, lambda=lambda

common com_ha_limits, plans

;; read in plans
if(n_tags(plans) eq 0) then begin
	platePlans_file = getenv('PLATELIST_DIR')+'/platePlans.par'
	check_file_exists, platePlans_file, plateid=plateid
	plans= yanny_readone(platePlans_file)
endif
iplan= where(plans.plateid eq plateid, nplan)
if(nplan gt 1) then $
	message, color_string('Multiple entries in platePlans for plateid='+ $
		string(plateid), 'red', 'bold')

if(nplan eq 0) then begin

	; "plans" is in a common block - reload the file to see if
	; it has changed since this was first run.
	platePlans_file = getenv('PLATELIST_DIR')+'/platePlans.par'
	check_file_exists, platePlans_file, plateid=plateid
	plans= yanny_readone(platePlans_file)
	iplan= where(plans.plateid eq plateid, nplan)
	
	; try again
	if(nplan eq 0) then $
		message, color_string('No entries in platePlans for plateid='+ $
			string(plateid), 'red', 'bold')
endif

;; set design values
designid= plans[iplan].designid
ha= plans[iplan].ha
temp=plans[iplan].temp
epoch=plans[iplan].epoch

;; import design file and settings in header
designdir= design_dir(designid)
designfile=designdir+'/plateDesign-'+ $
           string(designid, f='(i6.6)')+'.par'
check_file_exists, designfile, plateid=plateid
if(n_tags(design) eq 0) then $
  design= yanny_readone(designfile, hdr=hdr, /anon) $ 
else $
  yanny_read, designfile, hdr=hdr
definition= lines2struct(hdr)
default= definition

platescale = get_observatory(definition, default)

;; handle old-style without lambda_eff
lambda_eff= fltarr(n_elements(design))+5400.
if(tag_indx(design, 'lambda_eff') ge 0) then begin
    lambda_eff= design.lambda_eff
endif
if(keyword_set(lambda)) then $
  lambda_eff[*]= lambda

;; get regular pointing of all holes
npointings= long(default.npointings)
noffsets= long(default.noffsets)
hamin= fltarr(n_elements(ha))
hamax= fltarr(n_elements(ha))
xfocal= fltarr(n_elements(design))
yfocal= fltarr(n_elements(design))
for pointing=1L, npointings do begin
    
    ;; for each offset, do the holes there
    for offset=0L, noffsets do begin
        iin= where(design.pointing eq pointing AND $
                   design.offset eq offset, nin)
        plate_center, definition, default, pointing, offset, $
                      racen=racen, deccen=deccen
        if(nin gt 0) then begin
            plate_ad2xy, definition, default, pointing, offset, $
                         design[iin].target_ra, design[iin].target_dec, $
                         lambda_eff[iin], lst=racen+ha[pointing-1L], $
                         airtemp=temp, xfocal=xf, yfocal=yf
            xfocal[iin]= xf
            yfocal[iin]= yf
        endif
    endfor
endfor

npointings= long(default.npointings)
noffsets= long(default.noffsets)
hamin= fltarr(n_elements(ha))
hamax= fltarr(n_elements(ha))
for pointing=1L, npointings do begin

    ;; find hamin and hamax for this pointing 
    iin= where(design.pointing eq pointing, nin)
    if(nin gt 0) then begin

        ;; now cycle through HA values
        dtry=5.
        max_ha_off=60.
        ntry= (long(2.*max_ha_off/dtry)/2L)*2L+1L
        try_ha= ha[pointing-1]+(2.*(findgen(ntry)+0.5)/float(ntry)-1.)*max_ha_off
        try_maxdist=fltarr(ntry)
        for i=0L, ntry-1L do begin
            try_xf= fltarr(nin)
            try_yf= fltarr(nin)
            
            ;; find new xf, yf values (loop over all offsets)
            for offset=0L, noffsets do begin
                plate_center, definition, default, pointing, offset, $
                              racen=racen, deccen=deccen
                
                ioff= where(design[iin].offset eq offset, noff)
                if(noff gt 0) then begin
                    icurr= iin[ioff]
                    plate_ad2xy, definition, default, pointing, offset, $
                                 design[icurr].target_ra, $
                                 design[icurr].target_dec, $
                                 lambda_eff[icurr], lst=racen+try_ha[i], $
                                 airtemp=temp, xfocal=xf, yfocal=yf
                    try_xf[ioff]= xf
                    try_yf[ioff]= yf
                endif
            endfor
            
            ;; rescale x's and y's to take out scale
            ha_fit, xfocal[iin], yfocal[iin], try_xf, try_yf, $
                    xnew=xnew, ynew=ynew, rot=rot, scale=scale, $
                    xshift=xshift, yshift=yshift
            try_xf= xnew
            try_yf= ynew
            
            ;; find maximum distance
            dist= sqrt((xfocal[iin]- try_xf)^2+ $
                       (yfocal[iin]- try_yf)^2)
            try_maxdist[i]= max(dist)
        endfor
        
        ;; translate condition to mm
        max_off= float(maxoff_arcsec)*platescale/3600.

        ;; interpolate values
        dint=0.5
        nint= (long(2.*max_ha_off/dint)/2L)*2L+1L
        int_ha= ha[pointing-1]+(2.*(findgen(nint)+0.5)/float(nint)-1.)*max_ha_off
        int_maxdist= interpol(try_maxdist, try_ha, int_ha)

        ;; apply condition
        ok_ha= int_maxdist lt max_off 
        iok= where(ok_ha, nok)
        if(nok eq 0) then $
          message, color_string('No valid HA choices close enough to design HA??','red', 'bold')
        hamin[pointing-1]= min(int_ha[iok])
        hamax[pointing-1]= max(int_ha[iok])

        if(keyword_set(plot)) then begin
            splot, int_ha, int_maxdist
            soplot, try_ha, try_maxdist, psym=4
            soplot, [min(try_ha), max(try_ha)], [max_off, max_off], color='red'
            soplot, [hamin[pointing-1], hamin[pointing-1]], $
                    [0., max_off], color='red'
            soplot, [hamax[pointing-1], hamax[pointing-1]], $
                    [0., max_off], color='red'
        endif
        
    endif else begin
        plate_log, plateid, 'No targets in pointing: '+strtrim(string(pointing),2)
    endelse
endfor


end
;------------------------------------------------------------------------------
