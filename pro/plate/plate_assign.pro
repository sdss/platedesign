;+
; NAME:
;   plate_assign
; PURPOSE:
;   Assign targets to a current plate
; CALLING SEQUENCE:
;   plate_assign, definition, default, design, targets, info=
; INPUTS:
;   definition - plate definition structure
;   default - plate default structure
;   design - design structure
;   targets - target structure
; OPTIONAL INPUTS:
;   info - structure with information tags for various options
;   seed - random seed for shuffling
; COMMENTS:
;   Required in default structure:
;     nPointings
;     nOffsets
;   Required in definition structure:
;     raCen1 [, ... as necessary]
;     decCen1 [, ... as necessary]
;   Defaults to 3 arcsec buffer 
;   Objects of identical priority are shuffled randomly before being
;     selected --- any preference MUST be expressed in the priorities!
; REVISION HISTORY:
;   8-May-2008  Written by MRB, NYU
;-
pro plate_assign, definition, default, design, targets, info=info, $
                  seed=seed

platescale = 217.7358           ; mm/degree

ntargets=n_elements(targets)

;; which pointing are we adding these targets to?
pointing= 1L
if(tag_exists(info, 'pointing')) then $
  pointing=long(info.pointing)
if(pointing gt long(default.npointings)) then $
  message, 'pointing '+strtrim(string(pointing),2)+' does not exist'

;; which offset are we adding these targets to?
offset= 0L
if(tag_exists(info, 'offset')) then $
  offset=long(info.offset)
if(pointing gt long(default.noffsets)) then $
  message, 'pointing '+strtrim(string(pointing),2)+' does not exist'

;; which offset are we adding these targets to?
offset= 0L
if(tag_exists(info, 'offset')) then $
  offset=long(info.offset)

;; therefore, what is our raCen and decCen
plate_center, definition, default, pointing, offset, $
              racen=racen, deccen=deccen

;; convert targets
radec_to_xyfocal, targets.ra, targets.dec, xf_default, yf_default, $
                  racen=racen, deccen=deccen

;; create structure for targets
new_design= replicate(design_blank(), ntargets)

;; add per plateInput data 
new_design.holetype= definition.holetype
new_design.pointing=pointing
new_design.offset=offset

;; get hole size for this type
ferrulestr= 'ferruleSize'+strtrim(definition.holetype,2)
iferrule= tag_indx(definition, ferrulestr)
ferrulesize= float(definition.(iferrule))

;; add per target data 
new_design.sourcetype= targets.sourcetype
new_design.target_ra= targets.ra
new_design.target_dec= targets.dec
new_design.xf_default=xfocal
new_design.yf_default=yfocal
new_design.diameter=ferrulesize
new_design.buffer=platescale*3./3600.  ;; default to 3 arcsec buffer
new_design.priority=targets.priority
new_design.assigned=0
new_design.conflicted=0

;; CHECK HERE IF HOLETYPE IS "GUIDE" -> 
;;   NEED PLACEMENT TO BE SPECIAL
;;   NEED EXTRA ALIGNMENT HOLE

;; CHECK HERE IF HOLETYPE IS "STANDARD"
;; DO WE HAVE CONSTRAINTS ON THE PLACEMENT?

;; CHECK HERE IF HOLETYPE IS "SKY"
;; DO WE HAVE CONSTRAINTS ON THE PLACEMENT?

;; step through targets in order of priority;
;; at this step we shuffle the targets to remove 
;; any funny sorting of the inputs
ishuffle= shuffle_indx(ntargets)
isort=sort(new_design[ishuffle].priority)
for i=0L, ntargets-1L do begin
    icurr= ishuffle[isort[i]]

    ;; if this target is not conflicted with a previous target
    new_design[icurr].conflicted= $
      check_conflicts(design, new_design[icurr])
    if(new_design[icurr].conflicted eq 0) then $
      design= [design, new_design[icurr[i]]
endfor


end

;------------------------------------------------------------------------------
; Search for conflicts between an existing list of drill holes and one
; more potential object.  Return the existing list with the new object
; appended if there was no conflict.
function design_append, allplug, oneplug, nadd=nadd

if (n_elements(oneplug) NE 1) then $ 
  message, 'ONEPLUG must contain only one element'
if (NOT keyword_set(oneplug)) then oneplug = 0
nadd = 0L



end

;------------------------------------------------------------------------------
; Search for conflicts between an existing list of drill holes and one
; more potential object.  Return the existing list with the new object
; appended if there was no conflict.
function design_append, allplug, oneplug, nadd=nadd

if (n_elements(oneplug) NE 1) then $ 
  message, 'ONEPLUG must contain only one element'
if (NOT keyword_set(oneplug)) then oneplug = 0
nadd = 0L

platescale = 217.7358           ; mm/degree

; Add more space around GUIDE fibers and LIGHT_TRAP holes.
case strtrim(oneplug.holetype,2) of
    'GUIDE': morespace = 7.0    ; in mm
    'LIGHT_TRAP': morespace = 4.0 ; in mm
    else: morespace = 0.
endcase

;----------
; If this is the 1st object in the list, then we can always keep it

if (NOT keyword_set(allplug)) then begin
    nadd = 1L
    return, oneplug
endif

;----------
; Discard objects within 68 arcsec of the center hole or more
; then 1.49 deg from the plate center (pad to 75 arcsec).

thisrad = sqrt(oneplug.xfocal^2 + oneplug.yfocal^2)
if (thisrad LE platescale*75./3600.+morespace $ 
    OR thisrad GE platescale*1.49-morespace) then begin
    splog, 'bad radius: '+strtrim(string(f='(f40.3)',thisrad),2)
    return, allplug
endif

;----------
; Discard objects within 55 arcsec of existing objects.
; Do this based upon XFOCAL,YFOCAL positions. 
; The closest two fibers can be is PLATESCALE * 55/3600(deg) = 3.32652 mm

if (keyword_set(allplug)) then begin
    r2 = (allplug.xfocal - oneplug.xfocal)^2 $
         + (allplug.yfocal - oneplug.yfocal)^2
    mindist = min(sqrt(r2))
    if (mindist LT platescale*55./3600.+morespace) then begin
        splog, 'found conflict'
        return, allplug
    endif 
endif

;----------
; Discard objects within 7.0 mm of existing guide fibers.

if (keyword_set(allplug)) then begin
    iguide = where(strtrim(allplug.holetype) EQ 'GUIDE', ct)
    if (ct GT 0) then begin
        r2 = (allplug[iguide].xfocal - oneplug.xfocal)^2 $
             + (allplug[iguide].yfocal - oneplug.yfocal)^2
        mindist = min(sqrt(r2))
        if (mindist LT 7.0+morespace) then return, allplug
    endif
endif

nadd = 1L
return, [allplug, oneplug]
end

;------------------------------------------------------------------------------
; Group fibers into NXBIN by NYBIN groups, and return the group number
; between [0,NXBIN*NYBIN-1] for each fiber.
; NXBIN can either be a scalar representing the number of groupings in X
; for each slice in Y, or it can be an array with a different number of
; grouping for each slice in Y.
function design_groupfibers, allplug, nxbin1, nybin

if (n_elements(nxbin1) EQ nybin) then nxbin = nxbin1 $
else nxbin = replicate(nxbin1,nybin)

nobj = n_elements(allplug)
groupnum = lonarr(n_elements(allplug)) - 1L

isort = sort(allplug.dec)
igroup = 0L
i0 = 0L
tnxbin=total(nxbin)
for iy=0, nybin-1 do begin
                                ; Select objects in this declination slice
    nsamp = long((nxbin[iy] / tnxbin) * nobj) > 1
    ii = isort[i0:i0+nsamp-1L]
    if(nxbin[iy] gt nsamp) then nxbin[iy]=nsamp
    for ix=0, nxbin[iy]-1 do begin
                                ; Select objects in some RA box within this declination slice
        jsort = ii[ sort(allplug[ii].ra) ]
        jj = jsort[ $
             where(allplug[jsort].ra GE allplug[jsort[nsamp*float(ix)/nxbin[iy]]].ra $
                   AND allplug[jsort].ra LE allplug[jsort[nsamp*float(ix+1)/nxbin[iy]-1]].ra $
                   AND groupnum[jsort] EQ -1) ]
        groupnum[jj] = igroup
        igroup = igroup + 1
    endfor
    i0 = i0 + nsamp
endfor

return, groupnum
end
;------------------------------------------------------------------------------
pro plate_design, stardata1, racen=racen, deccen=deccen, $
                  tilenums=tilenum, platenums=platenum, airtemp=airtemp, nstd=nstd, $
                  nminsky=nminsky, lst=lst, ntotal=ntotal, southern=southern

if (NOT keyword_set(tilenum)) then tilenum = 1L
if (NOT keyword_set(platenum)) then platenum = tilenum
if (n_elements(racen) EQ 0 OR n_elements(deccen) EQ 0) then $
  message, 'RACEN,DECCEN must be specified'
if (n_elements(airtemp) EQ 0) then airtemp = 5.0
if (n_elements(nstd) eq 0) then nstd = 16L
if (n_elements(nminsky) eq 0) then nminsky = 32L
if (n_elements(lst) eq 0) then lst = racen
if (NOT keyword_set(ntotal)) then ntotal = 640L
ntot = ntotal
nsci = ntot - nstd - nminsky    ; Max number of science targets to add

plugmappfile = 'plPlugMapP-' + string(platenum,format='(i4.4)') + '.par'
maxpriority = 2L^31 - 1         ; Maximum value; this is the value for GUIDE stars
paramdir = concat_dir(getenv('IDLSPEC2D_DIR'), 'examples')

                                ;----------
                                ; If the priorities of targets are not specified in the input structure,
                                ; then assign random priorities between 1 and 100.

if ((where(tag_names(stardata1) EQ 'PRIORITY'))[0] NE -1) then $
  priority = (stardata1.priority > 1L) < (maxpriority-2) $
else $
  priority = long(randomu(24680, n_elements(stardata1)) * 100) + 1

                                ;----------
                                ; Add the tags XFOCAL,YFOCAL to the structure of object data.

radec_to_xyfocal, stardata1.ra, stardata1.dec, xfocal, yfocal, $
                  racen=racen, deccen=deccen, airtemp=airtemp
xydata = replicate(create_struct('XFOCAL', 0D, 'YFOCAL', 0D), $
                   n_elements(stardata1))
xydata.xfocal = xfocal
xydata.yfocal = yfocal
if(tag_indx(stardata1, 'XFOCAL') EQ -1) then begin
    stardata = struct_addtags(stardata1, xydata) 
endif else begin
    stardata=stardata1
    struct_assign, xydata, stardata, /nozero
endelse

                                ;----------
                                ; Read a template plugmap structure

blankplug = (yanny_readone( $
            filepath('plPlugMapT-XXXX.par', root_dir=paramdir), pp, $
            hdr=plughdr, enums=plugenum, structs=plugstruct))[0]
struct_assign, {junk:0}, blankplug

;----------
; Set up info for guide fibers.
;
; The following info is from the "plate" product in the
; file "$PLATE_DIR/test/plParam.par".
;   XREACH,YREACH = Center of the fiber reach [mm]
;   RREACH = Radius of the fiber reach [mm]
;   XPREFER,YREACH = Preferred position for the fiber [mm]
; Note that the plate scale is approx 217.7358 mm/degree.
; Moving +RA is +XFOCAL, +DEC is +YFOCAL.

gfiber = create_struct( $
         'xreach'   , 0.0, $
         'yreach'   , 0.0, $
         'rreach'   , 0.0, $
         'xprefer'  , 0.d, $
         'yprefer'  , 0.d )
nguide = 11
gfiber = replicate(gfiber, nguide)

platescale = 217.7358           ; mm/degree
guideparam = [[  1,  199.0,  -131.0,  165.0,  199.0,  -131.0 ], $
              [  2,   93.0,  -263.0,  165.0,   93.0,  -263.0 ], $
              [  3, -121.0,  -263.0,  165.0, -121.0,  -263.0 ], $
              [  4, -227.0,  -131.0,  165.0, -227.0,  -131.0 ], $
              [  5, -199.0,   131.0,  165.0, -199.0,   131.0 ], $
              [  6,  -93.0,   263.0,  165.0,  -93.0,   263.0 ], $
              [  7,  121.0,   263.0,  165.0,  121.0,   263.0 ], $
              [  8,  227.0,   131.0,  165.0,  227.0,   131.0 ], $
              [  9,   14.0,   131.0,  139.5,   14.0,    65.0 ], $
              [ 10,  -14.0,  -131.0,  165.0,  -14.0,   -65.0 ], $
              [ 11,   93.0,  -131.0,  139.5,   93.0,  -131.0 ] ]
gfiber.xreach = transpose(guideparam[1,*])
gfiber.yreach = transpose(guideparam[2,*])
gfiber.rreach = transpose(guideparam[3,*])
gfiber.xprefer = transpose(guideparam[4,*])
gfiber.yprefer = transpose(guideparam[5,*])

;----------
; Add science objects

ct = 2
while (n_elements(allplug) LT ntot - nminsky AND ct GT 1) do begin
    indx = where(strtrim(stardata.holetype,2) EQ 'OBJECT' $
                 AND strtrim(stardata.objtype,2) NE 'SKY' $
                 AND strtrim(stardata.objtype,2) NE 'SPECTROPHOTO_STD' $
                 AND strtrim(stardata.objtype,2) NE 'REDDEN_STD' $
                 AND priority GT 0, ct)
    if (ct GT 0) then begin
        junk = max(priority[indx], ibest)
        addplug = blankplug
        struct_assign, stardata[indx[ibest]], addplug
        addplug.holetype = 'OBJECT'

        allplug = design_append(allplug, addplug)

        priority[indx[ibest]] = 0 ; Don't try to target again
    endif
endwhile

;----------
; Add guide fibers

for iguide=0, nguide-1 do begin
;----------
; Assign the nearest available guide fiber(s) to this guide position.

    print, 'Assigning guide fiber number ', iguide+1

    nadd1 = 0
    while (nadd1 EQ 0) do begin
        indx = where(strtrim(stardata.holetype,2) EQ 'GUIDE' $
                     AND priority GT 0, ct)
        if (ct EQ 0) then $
          message, 'No guide stars for guide #', iguide
        if (ct GT 0) then begin
            adiff = sqrt( $
                    (gfiber[iguide].xprefer - stardata[indx].xfocal)^2 $
                    + (gfiber[iguide].yprefer - stardata[indx].yfocal)^2 )

            junk = min(adiff, ibest)
            addplug = blankplug
            struct_assign, stardata[indx[ibest]], addplug
            addplug.holetype = 'GUIDE'
            addplug.objtype = 'NA'
            addplug.sectarget = 64L
            addplug.fiberid = iguide+1
            allplug = design_append(allplug, addplug, nadd=nadd1)
            ntot = ntot + nadd1
            priority[indx[ibest]] = 0 ; Don't try to target again

            if (nadd1 EQ 1) then begin
; Now add the alignment hole for this guide fiber
                DRADEG = 180.d0/!dpi
                twist_coeff = 0.46
                align_hole_dist = 2.54
                if (addplug.yfocal GT 0) then $
                  thisang = 90.d0 + twist_coeff * (addplug.yfocal $
                                                   - gfiber[iguide].yreach) $
                else $
                  thisang = -90.d0 - twist_coeff * (addplug.yfocal $
                                                    - gfiber[iguide].yreach)
                xfocal = addplug.xfocal + align_hole_dist * cos(thisang/DRADEG)
                yfocal = addplug.yfocal + align_hole_dist * sin(thisang/DRADEG)
                addplug = blankplug
                addplug.holetype = 'ALIGNMENT'
                addplug.objtype = 'NA'
                addplug.xfocal = xfocal
                addplug.yfocal = yfocal
                addplug.throughput = -9999
                addplug.fiberid = iguide+1
                allplug = [allplug, addplug] ; Add this hole with no checking!
                ntot = ntot + nadd1
            endif
        endif
    endwhile
endfor

;----------
; Add SPECTROPHOTO_STD and REDDEN_STD stars
nadd = 0L
nxbin = 4
nybin = 2
indx = where(strtrim(allplug.holetype,2) EQ 'OBJECT', nobj)
groupnum = design_groupfibers(allplug[indx], nxbin, nybin)
for igroup=0, max(groupnum) do begin
    nthisbox = 0L
    jj = where(groupnum EQ igroup)
    ra_range = minmax(allplug[indx[jj]].ra)
    dec_range = minmax(allplug[indx[jj]].dec)
; Attempt to add up to NSTD/(NXBIN*NYBIN*2) of each flavor of
; calibration star in this region of the plate.
    ntry1 = nstd / (nxbin * nybin * 2) > 1
    ntry2 = nstd / (nxbin * nybin * 2)
    i1 = where(strtrim(stardata.holetype,2) EQ 'OBJECT' $
               AND strtrim(stardata.objtype,2) EQ 'SPECTROPHOTO_STD' $
               AND stardata.ra GE ra_range[0] AND stardata.ra LE ra_range[1] $
               AND stardata.dec GE dec_range[0] AND stardata.dec LE dec_range[1] $
               AND priority GT 0, ct1)
    i2 = where(strtrim(stardata.holetype,2) EQ 'OBJECT' $
               AND strtrim(stardata.objtype,2) EQ 'REDDEN_STD' $
               AND stardata.ra GE ra_range[0] AND stardata.ra LE ra_range[1] $
               AND stardata.dec GE dec_range[0] AND stardata.dec LE dec_range[1] $
               AND priority GT 0, ct2)
    if (ntry1 GT 0 AND ct1 GT 0) then begin
; First try adding the best SPECTROPHOTO_STD stars
        while (total(priority[i1] NE 0) GT 0 AND nthisbox LT ntry1) do begin
            junk = max(priority[i1], ibest)
            addplug = blankplug
            struct_assign, stardata[i1[ibest]], addplug
            addplug.primtarget = 0
            addplug.sectarget = sdss_flagval('TTARGET', addplug.objtype)
            allplug = design_append(allplug, addplug, nadd=nadd1)
            nadd = nadd + nadd1
            nthisbox = nthisbox + nadd1
            priority[i1[ibest]] = 0 ; Don't try to target again
        endwhile
    endif
    if (ntry2 GT 0 AND ct2 GT 0) then begin
; Next try adding the best REDDEN_STD stars
        while (total(priority[i2] NE 0) GT 0 $
               AND nthisbox LT ntry1+ntry2) do begin
            junk = max(priority[i2], ibest)
            addplug = blankplug
            struct_assign, stardata[i2[ibest]], addplug
            addplug.primtarget = 0
            addplug.sectarget = sdss_flagval('TTARGET', addplug.objtype)
            allplug = design_append(allplug, addplug, nadd=nadd1)
            nadd = nadd + nadd1
            nthisbox = nthisbox + nadd1
            priority[i2[ibest]] = 0 ; Don't try to target again
        endwhile
    endif
endfor

; If we have not assigned all of the requested standard stars,
; then attempt adding more anywhere on the plate, sorted by priority.
indx = where(strtrim(stardata.holetype,2) EQ 'OBJECT' $
             AND (strtrim(stardata.objtype,2) EQ 'SPECTROPHOTO_STD' $
                  OR strtrim(stardata.objtype,2) EQ 'REDDEN_STD') $
             AND priority GT 0, ct)
if (ct EQ 0) then $
  message, 'No standard stars!'
while (total(priority[indx] NE 0) GT 0 AND nadd LT nstd) do begin
    junk = max(priority[indx], ibest)
    addplug = blankplug
    struct_assign, stardata[indx[ibest]], addplug
    addplug.primtarget = 0
    addplug.sectarget = sdss_flagval('TTARGET', addplug.objtype)
    allplug = design_append(allplug, addplug, nadd=nadd1)
    nadd = nadd + nadd1
    priority[indx[ibest]] = 0   ; Don't try to target again
endwhile

;----------
; Add skies

nsky = ntot - n_elements(allplug) ; Number of sky fibers to be added here
; Construct a list of preferred RA,DEC positions for the sky fibers
; that is evenly spaced with respect to the object positions.
ra_prefer = dblarr(nsky)
dec_prefer = dblarr(nsky)
nxbin = floor(sqrt(nsky))
nybin = floor(nsky / nxbin)
indx = where(strtrim(allplug.holetype,2) EQ 'OBJECT', nobj)
groupnum = design_groupfibers(allplug[indx], nxbin, nybin)
for igroup=0, max(groupnum) do begin
    jj = where(groupnum EQ igroup, njj)
    if(njj gt 1) then begin
        ra_prefer[igroup] = median(allplug[indx[jj]].ra)
        dec_prefer[igroup] = median(allplug[indx[jj]].dec)
    endif else begin
        ra_prefer[igroup] = allplug[indx[jj]].ra
        dec_prefer[igroup] = allplug[indx[jj]].dec
    endelse
endfor

; Add any additional preferred sky positions
nmore = nsky - nxbin * nybin
if (nmore GT 0) then begin
    jj = long(nobj*randomu(1234,nmore))
    ra_prefer[nsky-nmore:nsky-1] = allplug[indx[jj]].ra
    dec_prefer[nsky-nmore:nsky-1] = allplug[indx[jj]] .dec
endif

for isky=0L, nsky-1L do begin
    nadd1 = 0
    while (nadd1 EQ 0) do begin
        indx = where(strtrim(stardata.holetype,2) EQ 'OBJECT' $
                     AND strtrim(stardata.objtype,2) EQ 'SKY' $
                     AND priority GT 0, ct)
        if (ct EQ 0) then $
          message, 'Ran out of sky targets!'

; Attempt to assign the closest sky fiber to the preferred position
        adist = djs_diff_angle(stardata[indx].ra, stardata[indx].dec, $
                               ra_prefer[isky], dec_prefer[isky])
        junk = min(adist, ibest)

        addplug = blankplug
        struct_assign, stardata[indx[ibest]], addplug
        addplug.holetype = 'OBJECT'
        addplug.objtype = 'SKY'
        addplug.sectarget = 16L

        allplug = design_append(allplug, addplug, nadd=nadd1)
        priority[indx[ibest]] = 0 ; Don't try to target again, even if this
                                ; fiber was not assigned
    endwhile
endfor

;----------
; Add LIGHT_TRAP stars

tycvlimit = 7.5
tycdat = tycho_read(racen=racen, deccen=deccen, radius=1.49)
if (keyword_set(tycdat)) then begin
; Sort so that we add the brightest Tycho stars first.
    tycdat = tycdat[sort(tycdat.vtmag)]
    indx = where(tycdat.vtmag LT tycvlimit, ct)
    if (ct EQ 0) then tycdat = 0 $
    else tycdat = tycdat[indx]
endif
if (keyword_set(tycdat)) then begin
    radec_to_xyfocal, tycdat.radeg, tycdat.dedeg, xfocal, yfocal, $
                      racen=racen, deccen=deccen, airtemp=airtemp
    for ityc=0, n_elements(tycdat)-1 do begin
        addplug = blankplug
        addplug.holetype = 'LIGHT_TRAP'
        addplug.objtype = 'NA'
        addplug.ra = tycdat[ityc].radeg
        addplug.dec = tycdat[ityc].dedeg
        addplug.xfocal = xfocal[ityc]
        addplug.yfocal = yfocal[ityc]
        addplug.mag = [0, tycdat[ityc].btmag, tycdat[ityc].vtmag, 0, 0]
        allplug = design_append(allplug, addplug, nadd=nadd1)
        nadd = nadd + nadd1
    endfor
endif


return
end
  ;------------------------------------------------------------------------------
