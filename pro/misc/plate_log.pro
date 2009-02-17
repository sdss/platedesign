;+
; NAME:
;   plate_log
; PURPOSE:
;   Append to a human readable log written for each platerun run.
; CALLING SEQUENCE:
;   plate_log, plateid, log_string [, /clobber]
; INPUTS:
;   plateid - the current plate id
;   logString - string(s) to be written to the log
; OPTIONAL INPUTS:
;   n/a
; OPTIONAL OUTPUTS:
;   n/a
; OPTIONAL KEYWORDS:
;   /clobber - clear any existing log file and start over
; OUTPUTS:
;   None.
; COMMENTS:
;   Calling this routine will append the string(s) given to a common log file
;   unique for each run. It is intended to be *human readable*. Only write
;   information that is useful, be succinct. Ideally, nothing should be
;   written if the processing went well.
;
;   If reporting an error, specify what went wrong and what steps can be taken
;   to correct the problem.
;   This routine does not write anything to STDOUT unless a file cannot be written to.
; REVISION HISTORY:
;   21-Oct-2008 DNM, NYU 
;-

pro plate_log, plateid, log_string, clobber=clobber
    COMPILE_OPT logical_predicate
    COMPILE_OPT idl2
    true = 1
    false = 0

    ;;common platelog_common, logFilesHash

    ;; Checks that plateid is defined, nothing is done if not. Alternately,
    ;; this could send log strings to a "catch all" file, but this will
    ;; probably do more to mask bugs than be useful.
    if (n_elements(plateid) eq 0) then begin
        print, 'plate_log called without the plateid specified. No logging will be done.'
        return
    endif

    ;; Keys must be of type string; start by converting plateid
    ;; and trimming whitespace.
    ;; If "plateid" is already a string, make sure it is a valid intenger.
    if (datatype(plateid) eq 'STR') then begin

        ;; -------------------
        ;; Set up catch routine for data type conversion error.
        ;; For details, see:
        ;; http://www.dfanning.com/misc_tips/conversion_errors.html
        ;; -------------------
        CATCH, err_status
        if (err_status NE false) then begin
            CATCH, /cancel
            type_conversion_error:
            print, 'PLATELOG ERROR: An invalid plate id was specified; "plateid" ' + $
                   'must be an integer, you specified:'
            print, '                "' + plateid + '".'
            print, '                Calling format: plate_log, <plateid>, <log string>'
            return
        endif
        ON_IOError, type_conversion_error
        ;; -------------------

        dummy = uint(plateid) ;; will fail if not an integer

    endif

    plateid = strtrim(plateid, 2)

    ;; ==== ignore the hash stuff below ====

    ;; Parameters for the initialisation of the hash.
    ;; ----------------------------------------------
    ;; Since IDL doesn't have a "null" value or a real "undefined" test,
    ;; we define a value that we will use for such a case, i.e. the
    ;; key we request in the hash is unknown.
    ;;undefined_value = 'undefined' ;; Can be anything, hopefully this won't collide with anything
    ;;max_number_of_hash_entries = 1000 ;; OK if this is exceeded, but best not to.
 
    ;; Initial set up of logFilesHash that maps plateid to the log file path.
    ;; (This is also known as a dictionary (Perl) or map (C++)).
    ;;if (keyword_set(logFilesHash) eq false) then begin
    ;;    logFilesHash = obj_new('hashtable', $
    ;;                           LENGTH=max_number_of_hash_entries, $
   ;;                            NULL_VALUE=undefined_value)
    ;;endif
    ;; ==== end ====

    ;; Determine path + filename for plateid
    logfile = getenv('PLATELIST_DIR') + '/logs/' + 'platelog_' + plateid + '.log'

    ;; Open (or create) the log file
    ;; -----------------------------
 ;;   logFile = logFilesHash->Get(plateid)
    if (keyword_set(clobber)) then begin
        openw, lun, logFile, /get_lun, error=err ;; clears file first
    endif else begin
        openw, lun, logFile, /get_lun, error=err, /append ;; we're just appending to an existing file
    endelse

    ;; check for errors on open
    if (err ne false) then begin
        print, 'PLATELOG: An error occurred when accessing log file: '
        print, '          ' + logFile
        print, '          Error message: [' + !ERROR_STATE.MSG + ']'
        return
    endif

    ;; write a simple header if it's a new file
    if (keyword_set(clobber)) then begin
        printf, lun, '# ---------------------------------------------- #'
        get_date, dte, /timetag ;; this format could be friendlier
        printf, lun, '# Plate id = ' + plateid + ' / run on ' + dte
        printf, lun, '# ---------------------------------------------- #'
    endif

    printf, lun, log_string

    free_lun, lun ;; which will close

end
;------------------------------------------------------------------------------
