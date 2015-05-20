;; create a plMeas file with xDrill, yDrill instead of xFlat, yFlat.
;; assumes you are in the run directory
pro make_flat_plate, plate

drillpos= yanny_readone('plDrillPos-'+strtrim(string(plate),2)+'.par')

openw, unit, 'plMeasFlat-'+strtrim(string(plate),2)+'.par', /get_lun
for i=0L, n_elements(drillpos)-1L do begin
    printf, unit, strtrim(string(drillpos[i].objid[0]), 2)+' '+ $
      strtrim(string(drillpos[i].objid[1]), 2)+' '+ $
      strtrim(string(drillpos[i].objid[2]), 2)+' '+ $
      strtrim(string(drillpos[i].objid[3]), 2)+' '+ $
      strtrim(string(drillpos[i].objid[4]), 2)+', '+ $
      strtrim(string(drillpos[i].xdrill, f='(f17.12)'),2)+', '+$
      strtrim(string(drillpos[i].ydrill, f='(f17.12)'),2)+', '+$
      strtrim(string(drillpos[i].holediam, f='(f8.5)'),2)
endfor
free_lun, unit

end
