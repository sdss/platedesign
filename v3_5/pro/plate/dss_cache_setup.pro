
; Although this is called setup, all of the DSS cache functionality is
; in this file. It's named for the first function typically called.

pro dss_cache_setup

	COMPILE_OPT idl2
	COMPILE_OPT logical_predicate
	
	COMMON common_dss_cache, dss_cache
	
	dss_cache = { path : '', 			$ ; the directory the cache is located in
				  database_name : '',	$ ; the name of the database
				  database : '',		$ ; the full path + database name
				  schema : '',			$ ; the db schema in a text file
				  sqlite3 : ''			$ ; the executable plus any options/flags
				}
	
	;; ----------------------------------------
	;; Setup database cache paths and filenames
	;; ----------------------------------------
	platelist_dir = getenv('PLATELIST_DIR')
	if (~keyword_set(platelist_dir)) then begin
		splog, '$PLATELIST_DIR not defined! I''m going to stop now -- ' + $
			   'you''ll probably want to fix that...'
		stop
	endif

	dss_cache.path = platelist_dir + '/dss_cache/'
	dss_cache.database_name = 'dss_cache_db.sqlite'
	dss_cache.schema = 'dss_cache_db.sql'
	dss_cache.sqlite3 = 'sqlite3 -init ' + dss_cache.path + 'sqlite-init ' ; make sure a blank trails
	
	dss_cache.database = dss_cache.path + "/" + dss_cache.database_name

	; Test if DSS cache database exists, if not, create it.
	; -----------------------------------------------------
	if (~file_test(dss_cache.path + '/' + dss_cache.database_name)) then begin
		
		command = 'cat ' + dss_cache.path + "/" + dss_cache.schema + $
				  ' | ' + dss_cache.sqlite3 + dss_cache.database
		;print, command
		spawn, command
		
	endif else begin
		splog, 'DSS cache database found.'
	endelse

end
