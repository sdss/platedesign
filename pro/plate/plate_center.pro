;+
; NAME:
;   plate_center
; PURPOSE:
;   Return plate center for a given pointing and offset
; CALLING SEQUENCE:
;   plate_center, definition, default, pointing, offset, racen=, deccen=
; INPUTS:
;   definition - plate definition
;   default - plate defaults
;   pointing - which pointing?
;   offset - which offset?
; OUTPUTS:
;   racen, deccen - centers to use
; COMMENTS:
;   definition must have elements:
;      .RACENp
;      .DECCENp
;   default must have elements:
;      .DRAo
;      .DDECo
;   where "p" and "o" are pointing and offset numbers
; 
;   DRA and DDEC are taken to be in COORDINATE, not proper, units
; REVISION HISTORY:
;   9-May-2008 MRB, NYU 
;-
pro plate_center, definition, default, pointing, offset, $
                  racen=racen, deccen=deccen

racenstr= 'racen'+strtrim(string(pointing),2)
deccenstr= 'deccen'+strtrim(string(pointing),2)

iracen=tag_indx(definition, racenstr)
ideccen=tag_indx(definition, cencenstr)

racen= double(definition.(iracen))
deccen= double(definition.(ideccen))

if(offset gt 0) then begin
    racenstr= 'racen'+strtrim(string(pointing),2)
    deccenstr= 'deccen'+strtrim(string(pointing),2)
    idra=tag_indx(default, racenstr)
    iddec=tag_indx(default, cencenstr)

    racen= racen+ double(default.(idra))
    deccen= deccen+ double(default.(iddec))
endif

end

