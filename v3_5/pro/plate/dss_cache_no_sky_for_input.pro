; After the sky_local_candidates search, no sky was found.
; Mark as such in database.

PRO dss_cache_no_sky_for_input, ra, dec, radius, exclude

	COMPILE_OPT idl2
	COMPILE_OPT logical_predicate
	
	COMMON common_dss_cache

	; Convert inputs to strings for convenience
	ra_s = strtrim(string(ra),2)
	dec_s = strtrim(string(dec),2)
	radius_s = strtrim(string(radius),2)
	exclude_s = strtrim(string(exclude),2)
	no_cand_found = '1'
	
	command = dss_cache.sqlite3 + dss_cache.database + ' "' + $
		'INSERT INTO input (ra, dec, radius, exclusion_area, no_candidates_found) VALUES (' + $
		strjoin([ra_s, dec_s, radius_s, exclude_s, no_cand_found], ',') + $
		');"'
	spawn, command, result

END


