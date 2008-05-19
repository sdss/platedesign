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

racens= double(strsplit(definition.racen, /extr))
deccens= double(strsplit(definition.deccen, /extr))

racen= racens[pointing-1L]
deccen= deccens[pointing-1L]

if(offset gt 0) then begin
    dras= double(strsplit(definition.dra, /extr))
    ddecs= double(strsplit(definition.ddec, /extr))

    racen= racen+ dras[offset-1]
    deccen= deccen+ ddecs[offset-1]
endif

end

