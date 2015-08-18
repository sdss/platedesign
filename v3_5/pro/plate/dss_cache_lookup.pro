; Given the inputs [ra, dec, radius, exclude],
; returns the outputs [cand_ra, cand_dec, input_id]
PRO dss_cache_lookup, ra, dec, radius, exclude,		$ ; inputs
					  cand_ra, cand_dec,			$ ;
					  input_id
	
	COMPILE_OPT idl2
	COMPILE_OPT logical_predicate
	
	COMMON common_dss_cache

	input_id = 0
	cand_ra  = 0
	cand_dec = 0
	
	; Convert inputs to strings for convenience
	ra_s = strtrim(string(ra),2)
	dec_s = strtrim(string(dec),2)
	radius_s = strtrim(string(radius),2)
	exclude_s = strtrim(string(exclude),2)

	; Look up inputs in database
	command = dss_cache.sqlite3 + dss_cache.database + ' "' + $
		  'SELECT id FROM input WHERE ' + $
		  'ra = ' + ra_s + ' AND ' + $
		  'dec = ' + dec_s + ' AND ' + $
		  'radius = ' + radius_s + ' AND ' + $
		  'exclusion_area = ' + exclude_s + ';"'
	spawn, command, result
	;print, command
	
	if (keyword_set(result)) then begin
	
		if (n_elements(result) gt 1) then begin
			splog, 'More than one input for the same values found! (id = ' + result + ')'
			stop
		end
		
		input_id = result
		;splog, 'Found entry in db, input.id = ' + input_id
		
		command = dss_cache.sqlite3 + dss_cache.database + ' "' + $
			'SELECT ra, dec FROM sky_candidate WHERE input_id = ' + toString(result) + ';"'
		spawn, command, result
		
		n_candidates = n_elements(result)
		cand_ra = dblarr(n_candidates)
		cand_dec = dblarr(n_candidates)
		
		for i=0, n_candidates-1 do begin
			values = strsplit(result[i], '|', /extract)
			cand_ra[i] = values[0]
			cand_dec[i] = values[1]
		endfor
		
	endif else begin
		splog, 'ra/dec not found in DSS cache.'
		
		; create a new input record
;		command = dss_cache.sqlite3 + dss_cache.database + ' ' + $
;			'"INSERT INTO input (ra, dec, radius, exclusion_area) VALUES (' + $
;			strjoin([ra_s,dec_s,radius_s,exclude_s], ',') + $
;			');"'
;		spawn, command, result
		
		; get the input.id that was just created
;		command = dss_cache.sqlite3 + dss_cache.database + ' ' + $
;			'"SELECT last_insert_rowid()"'
;		spawn, command, result
		
	endelse
	
END
