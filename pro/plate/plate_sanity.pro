; Test the values in a plPlugMap file
;------------------------------------------------------------------------------
pro plate_sanity, filename, epoch=epoch1

   if (keyword_set(epoch1)) then epoch = epoch1 $
    else epoch = 2007.9
   plug = yanny_readone(filename, hdr=hdr)
   if (NOT keyword_set(plug)) then $
    message, 'No file or empty'
   racen = yanny_par(hdr, 'raCen')
   deccen = yanny_par(hdr, 'decCen')

   qcenter = strmatch(plug.holetype,'QUALITY*') $
    AND strmatch(plug.objtype,'NA*') AND plug.xfocal EQ 0 AND plug.yfocal EQ 0
   qtrap = strmatch(plug.holetype,'LIGHT_TRAP*') $
    AND strmatch(plug.objtype,'NA*')
   qguide = strmatch(plug.holetype,'GUIDE*') $
    AND strmatch(plug.objtype,'NA*')
   qalign = strmatch(plug.holetype,'ALIGNMENT*') $
    AND strmatch(plug.objtype,'NA*')
   qsky = strmatch(plug.holetype,'OBJECT*') $
    AND strmatch(plug.objtype,'SKY*')
   qfstar = strmatch(plug.holetype,'OBJECT*') $
    AND (strmatch(plug.objtype,'SPECTROPHOTO_STD*') $
    OR strmatch(plug.objtype,'REDDEN_STD*'))
   qsci = strmatch(plug.holetype,'OBJECT*') $
    AND (qsky EQ 0 AND qfstar EQ 0)

   icenter = where(qcenter, ncenter)
   itrap = where(qtrap, ntrap)
   iguide = where(qguide, nguide)
   ialign = where(qalign, nalign)
   isky = where(qsky, nsky)
   ifstar = where(qfstar, nfstar)
   isci = where(qsci, nsci)

   splog, 'Number of center holes = ', ncenter
   splog, 'Number of LIGHT_TRAP = ', ntrap
   splog, 'Number of GUIDE = ', nguide
   splog, 'Number of ALIGNMENT = ', nalign
   splog, 'Number of SKY = ', nsky
   splog, 'Number of SPECTROPHOTO_STD/REDDEN_STD = ', nfstar
   splog, 'Number of science targets = ', nsci
   splog, 'Number of unknown entries in this file =', $
    n_elements(plug) - ncenter - ntrap - nguide - nalign - nsky - nfstar - nsci
   splog, 'Total number of regular fibers = ', nsky + nfstar + nsci, $
    ' (should be 640)'

   splot, plug.xfocal, plug.yfocal, xrange=[330,-330], yrange=[-330,330], $
    /xstyle, /ystyle, xtitle='X focal', ytitle='Y focal', psym=3
   soplot, plug[iguide].xfocal, plug[iguide].yfocal, psym=4, color='blue'
   sxyouts, plug[iguide].xfocal, plug[iguide].yfocal, $
    '  '+strtrim(string(plug[iguide].fiberid),2), color='blue', charsize=2
   soplot, plug[ifstar].xfocal, plug[ifstar].yfocal, psym=4, color='green'
   soplot, plug[isky].xfocal, plug[isky].yfocal, psym=4, color='red'

   splog, ''
   j = 1 ; filter for these magnitudes
   iguide2 = where(qguide AND plug.mag[j] NE 0, nguide2)
   ifstar2 = where(qfstar AND plug.mag[j] NE 0, nfstar2)
   isci2 = where(qsci AND plug.mag[j] NE 0, nsci2)
   if (nguide2 GT 0) then $
    splog, 'Mag range of GUIDE stars = ', minmax(plug[iguide2].mag[1])
   if (nfstar2 GT 0) then $
    splog, 'Mag range of calib stars = ', minmax(plug[ifstar2].mag[1])
   if (nsci2 GT 0) then $
    splog, 'Mag range of science targets = ', minmax(plug[isci2].mag[1])

   ; Match positions against Tycho at specified epoch, and report differences
   tycdat = tycho_read(racen=racen, deccen=deccen, radius=1.5, epoch=epoch)
   if (keyword_set(tycdat)) then begin
      spherematch, plug.ra, plug.dec, tycdat.ramdeg, tycdat.demdeg, 5./3600, $
       i1, i2, d12
      if (i1[0] NE -1) then begin
         dpos = fltarr(n_elements(plug))
         dpos[i1] = 3600. * djs_diff_angle(plug[i1].ra, plug[i1].dec, $
          tycdat[i2].ramdeg, tycdat[i2].demdeg)

         iguide3 = where(qguide AND dpos NE 0, nguide3)
         ifstar3 = where(qfstar AND dpos NE 0, nfstar3)
         isci3 = where(qsci AND dpos NE 0, nsci3)

         splog, ''
         splog, 'Number of Tycho matches = ', n_elements(i1)
         if (nguide3 GT 0) then $
          splog, 'RMS/max of GUIDE star positions = ', djsig(dpos[iguide3]), $
           max(dpos[iguide3]), ' arcsec'
         if (nfstar3 GT 0) then $
          splog, 'RMS/max of calib star positions = ', djsig(dpos[ifstar3]), $
           max(dpos[ifstar3]), ' arcsec'
         if (nsci3 GT 0) then $
          splog, 'RMS/max of science target positions = ', djsig(dpos[isci3]), $
           max(dpos[isci3]), ' arcsec'
      endif
   endif

   return
end
;------------------------------------------------------------------------------

