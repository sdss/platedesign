;+
; NAME:
;   acquisition
; PURPOSE:
;   Add acquisition holes to design
; CALLING SEQUENCE:
;   a = acquisition(definition, default)
; INPUTS:
;   definition - plate definition structure
;   default - plate default structure
; REVISION HISTORY:
;	26-May-2017  Mike Blanton
;-
function acquisition, definition, default

infile=getenv('PLATELIST_DIR')+'/inputs/'+definition.acquisitionInput

splog, 'Reading input: '+infile
check_file_exists, infile
tmp_targets= yanny_readone(infile, hdr=hdr, /anon)
if(n_tags(tmp_targets) eq 0) then $
  message, 'empty plateInput file '+infile
hdrstr=lines2struct(hdr)

;; check data type of ra and dec -- abort if they are not
;; typed double
if(size(tmp_targets[0].ra, /tname) ne 'DOUBLE' OR $
   size(tmp_targets[0].dec, /tname) ne 'DOUBLE') then begin
    message, $
      'Aborting: RA and Dec MUST be typed as '+ $
      'double precision!'
endif

target2design, definition, default, tmp_targets, tmp_design, info=hdrstr, $
  /relax_targettype

;; fix holetype
racen = double(definition.racen)
deccen = double(definition.deccen)
spherematch, racen, deccen, tmp_design.target_ra, tmp_design.target_dec, $
  1./3600., m1, m2, d12
if(m1[0] eq -1) then $
  message, 'Expected an acquisition camera at plate center!'
if(n_elements(m1) gt 1) then $
  message, 'Expected only one entry at plate center!'

tmp_design.holetype = 'ACQUISITION_OFFAXIS'
ferrulesize= get_ferrulesize(definition, default, 'ACQUISITION_OFFAXIS')
tmp_design.diameter = ferrulesize
buffersize= get_buffersize(definition, default, 'ACQUISITION_OFFAXIS')
tmp_design.buffer = buffersize

tmp_design[m2].holetype = 'ACQUISITION_CENTER'
ferrulesize= get_ferrulesize(definition, default, 'ACQUISITION_CENTER')
tmp_design[m2].diameter = ferrulesize
buffersize= get_buffersize(definition, default, 'ACQUISITION_CENTER')
tmp_design[m2].buffer = buffersize

return, tmp_design

end

