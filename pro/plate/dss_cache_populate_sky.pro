PRO dss_cache_populate_sky, ra, dec, radius, exclude, cand_ra, cand_dec

	COMPILE_OPT idl2
	COMPILE_OPT logical_predicate
	
	COMMON common_dss_cache

	; Convert inputs to strings for convenience
	ra_s = strtrim(string(ra),2)
	dec_s = strtrim(string(dec),2)
	radius_s = strtrim(string(radius),2)
	exclude_s = strtrim(string(exclude),2)

	; Create a new input row
	command = dss_cache.sqlite3 + dss_cache.database + ' "' + $
		'INSERT INTO input (ra, dec, radius, exclusion_area) VALUES (' + $
		strjoin([ra_s, dec_s, radius_s, exclude_s], ',') + $
		');"'
	spawn, command, result

	; Get the input.id that was just created
	command = dss_cache.sqlite3 + dss_cache.database + ' "' + $
;		'SELECT last_insert_rowid()"'
		'SELECT max(id) FROM input' + '"'
	spawn, command, result
	
	if (~keyword_set(result)) then begin
		splog, 'Attempted to create a new input record in database failed.'
		return
	endif
	
	; Populate the sky candidates...
	input_id = strtrim(string(result),2) ; "result" should be the new input.id
	for i=0, n_elements(cand_ra)-1 do begin

		command = dss_cache.sqlite3 + dss_cache.database + ' "' + $
			'INSERT INTO sky_candidate (input_id, ra, dec) VALUES (' + $
			strjoin([input_id, toString(cand_ra[i]), toString(cand_dec[i])], ',') + $
			');"'
		spawn, command, result

	endfor
	

END