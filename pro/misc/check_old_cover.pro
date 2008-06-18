;+
; NAME:
;   check_old_cover
;-
;------------------------------------------------------------------------------
pro check_old_cover

cd, getenv('PLATELIST_DIR')+'/sdss2plates/june-2008'

fieldnames=[ '47UMA', $            ;;0
             'GJ436', $            ;;1 
             'HD118203', $         ;;2 
             'HAT-P-3', $          ;;3 
             'HAT-P-4', $          ;;4 
             'XO-1', $             ;;5 
             'KEPLER3.TRES-2', $   ;;6 
             'HD178911B', $        ;;7 
             'KEPLER2', $          ;;8 
             'HD185144', $         ;;9 
             'K14', $              ;;10
             'HD209458', $         ;;11
             '51PEG', $            ;;12
             'HAT-P-1', $          ;;13
             'HD219828']           ;;14

pst=3000L
for i=0L, n_elements(fieldnames)-1L do begin
    help, 'plateInput-'+fieldnames[i]+'.par'
    help, 'plPlugMapP-'+strtrim(string(f='(i4.4)',pst+i),2)+ $
                      '.par'
    inp=yanny_readone('plateInput-'+fieldnames[i]+'.par', /anon)
    des=yanny_readone('plPlugMapP-'+strtrim(string(f='(i4.4)',pst+i),2)+ $
                      '.par', /anon)
    spherematch, inp.ra, inp.dec, des.ra, des.dec, 1./3600., m1, m2
    got=lonarr(n_elements(inp))
    got[m1]=1
    help, got
    help, where(got)
    print, got
endfor

end
