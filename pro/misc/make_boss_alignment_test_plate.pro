; This is a one-off plate made for Larry Carey for the guide collar installation.
; See:  [SDSS3-infrastructure 893]
;
; This file generates an output file, 'plPlugMapP-3623x.par'. The proper header still
; needs to be prepended to the output file. This is contained as a comment at the end
; of this file. Once this information is prepended to the output file, change its name
; to 'plPlugMapP-3623.par'.
;
; Once in its proper place: "$PLATELIST_DIR/plates/0036XX/003623/plPlugMapP-3623.par",
; the plate is finished by running:
;
; IDL> platerun_marvels, '2009.08.b.boss', 3623, /nolines
;
; Demitri Muna, NYU 2209.08.11


pro make_boss_alignment_test_plate

compile_opt idl2
compile_opt logical_predicate

; PLATE ID = 3623

platescale = 217.7358D	; mm/degree

racen= 180.
deccen= 0.

; --------------------------------------------------------
; The drill pattern at each location is a total of 6 holes
; (at each of the 16 locations).
; Total: 96 holes
; --------------------------------------------------------
; Hole #1: the hole for the guide fiber ferrule (diameter .0853")
; Located at the positions listed below.

; units in mm
fiber_block_centers_x = [-205.74, -68.58, 22.86, 114.30, 205.74, -91.44, 0.00, 91.44, 205.74, 68.58, -22.86, -114.30, -205.74, 91.44, 0.00, -91.44]
fiber_block_centers_y = [-137.80, -137.80, -137.80, -137.80, -137.80, -277.50, -277.50, -277.50, 137.80, 137.80, 137.80, 137.80, 137.80, 277.50, 277.50, 277.50]

; Hole type: GUIDE

xyfocal2ad, fiber_block_centers_x, fiber_block_centers_y, $
	fiber_block_centers_ra, fiber_block_centers_dec, racen=racen, deccen=deccen

; Hole #2: The "index" hole (diameter .043"),
; located .101 inch "outboard"
; (greater absolute y value ... away from y=0 ..., same x value) of the fiber ferrule hole
; (This hole will azimuthally orient the collar on the guide ferrule.)

; Hole type: ALIGNMENT

index_hole_x = fiber_block_centers_x
index_hole_y = fiber_block_centers_y

idx = where(fiber_block_centers_y ge 0)
index_hole_y[idx] = fiber_block_centers_y[idx] + (0.101 * 25.4)

idx = where(fiber_block_centers_y lt 0)
index_hole_y[idx] = fiber_block_centers_y[idx] - (0.101 * 25.4)

xyfocal2ad, index_hole_x, index_hole_y, $
	index_hole_ra, index_hole_dec, racen=racen, deccen=deccen


; Holes #3 thru 6: (.125 diameter) holes for mounting the installation
; plate that will hold the collar in place while attaching it to the
; guide ferrule. (located at 90 deg. increments around the ferrule hole;
; radius = 1.237")

; Let's call these holes north, south, east, west...

; Hole type: LIGHT_TRAP

r = 1.237 * 25.4 ; convert inches to mm

north_holes_x = fiber_block_centers_x
north_holes_y = fiber_block_centers_y + r

south_holes_x = fiber_block_centers_x
south_holes_y = fiber_block_centers_y - r

east_holes_x = fiber_block_centers_x + r
east_holes_y = fiber_block_centers_y

west_holes_x = fiber_block_centers_x - r
west_holes_y = fiber_block_centers_y

xyfocal2ad, north_holes_x, north_holes_y, $
	north_holes_ra, north_holes_dec, racen=racen, deccen=deccen

xyfocal2ad, south_holes_x, south_holes_y, $
	south_holes_ra, south_holes_dec, racen=racen, deccen=deccen

xyfocal2ad, east_holes_x, east_holes_y, $
	east_holes_ra, east_holes_dec, racen=racen, deccen=deccen

xyfocal2ad, west_holes_x, west_holes_y, $
	west_holes_ra, west_holes_dec, racen=racen, deccen=deccen

; Define the PLUGMAPOBJ structure

plPlugMapStruct = {plugMapObj, objId:intarr(5), holeType:'x', ra:0.D, dec:0.D, $
		mag:fltarr(5), starL:0.D, expL:0.D, deVaucL:0.D, objType:'x', xFocal:0.D, $
		yFocal:0.D, spectrographId:0, fiberId:0, throughput:0, primTarget:0, secTarget:0}

guide_holes = replicate(plPlugMapStruct, 16) ; all values are initialized to 0 (evidently)
guide_holes.holeType = 'GUIDE'
guide_holes.ra = fiber_block_centers_ra
guide_holes.dec = fiber_block_centers_dec
guide_holes.objType = 'NA'
guide_holes.xFocal = fiber_block_centers_x
guide_holes.yFocal = fiber_block_centers_y
guide_holes.fiberID = indgen(16) + 1

index_holes = replicate(plPlugMapStruct, 16)
index_holes.holeType = 'ALIGNMENT'
index_holes.ra = index_hole_ra
index_holes.dec = index_hole_dec
index_holes.objType = 'NA'
index_holes.xFocal = index_hole_x
index_holes.yFocal = index_hole_y
index_holes.fiberID = indgen(16) + 1

direction_holes = replicate(plPlugMapStruct, 4*16)
direction_holes.holeType = 'LIGHT_TRAP'
direction_holes.ra = [north_holes_ra, south_holes_ra, east_holes_ra, west_holes_ra]
direction_holes.dec = [north_holes_dec, south_holes_dec, east_holes_dec, west_holes_dec]
direction_holes.objType = 'NA'
direction_holes.xFocal = [north_holes_x, south_holes_x, east_holes_x, west_holes_x]
direction_holes.yFocal = [north_holes_y, south_holes_y, east_holes_y, west_holes_y]
direction_holes.fiberID = (-1 * indgen(4*16) - 1)

center_hole = replicate(plPlugMapStruct, 1)
center_hole.holeType = 'QUALITY'
center_hole.ra = racen
center_hole.dec = deccen
center_hole.objType = 'NA'
center_hole.xFocal = 0.0D
center_hole.yFocal = 0.0D
center_hole.fiberID = -9999

all_holes = [guide_holes, index_holes, direction_holes, center_hole]

dummy = yanny_readone(getenv('PLATEDESIGN_DIR') + '/data/sdss/plPlugMapP-blank.par', hdr=hdr, structs=structs)
yanny_write, 'plPlugMapP-3623x.par', ptr_new(all_holes), structs=structs, hdr=hdr

end


; Prepend the lines below the *** (uncommented of course) to the output of this script.
; The only important changes were to the lines:
;
; platerun
; raCen
; decCen
; plateID (listed twice for some reason)
; locationID -1
; designid -1
; plateInput
;
; Everything else is superfluous.
;

; ***

;completeTileVersion   none
;reddeningMed   0.1691  0.1244  0.0903  0.0684  0.0485
;# tileId is set to designid for SDSS-III plates
;tileId   -1
;raCen    180.
;decCen   0.00000000
;platedesign_version trunk
;plateId         3623
;temp       5.00000
;haMin       0.00000
;haMax       0.00000
;mjdDesign        55050
;pointing A
;mag_quality bad
;theta 0 
;plateid 3623
;ha 0.000 0.000 0.000 0.000 0.000 0.000
;temp 5.000
;locationID -1
;instruments BOSS
;targettypes science sky standard
;npointings 1
;noffsets 0
;nboss_science 900
;nboss_sky 80
;nboss_standard 20
;minstdinblockboss 0
;minskyinblockboss 1
;maxskyinblockboss 2
;gfibertype gfiber2
;guidetype SDSS
;guidenums1 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16
;guidemag_minmax 13. 15.5
;ferrulesizeboss 3.738
;buffersizeboss 0.006
;ferrulesizeguide 6.9555
;buffersizeguide 0.3
;platedesignstandards BOSS
;standardtype SDSS
;standardmag_minmax_boss 15.5 17.0
;platedesignskies BOSS
;skytype BOSS
;plugmapstyle plplugmap_boss
;bossmagtype fibermag
;designid -1
;platedesignversion v1
;platetype BOSS
;ninputs 1
;plateinput1 xxxx
;priority 1
;platerun 2009.08.b.boss
;platedesign_version trunk
;
;typedef enum {
; OBJECT,
; COHERENT_SKY,
; GUIDE,
; LIGHT_TRAP,
; ALIGNMENT,
; QUALITY
;} HOLETYPE;
;typedef enum {
; GALAXY,
; QSO,
; STAR_BHB,
; STAR_CARBON,
; STAR_BROWN_DWARF,
; STAR_SUB_DWARF,
; STAR_CATY_VAR,
; STAR_RED_DWARF,
; STAR_WHITE_DWARF,
; REDDEN_STD,
; SPECTROPHOTO_STD,
; HOT_STD,
; ROSAT_A,
; ROSAT_B,
; ROSAT_C,
; ROSAT_D,
; SERENDIPITY_BLUE,
; SERENDIPITY_FIRST,
; SERENDIPITY_RED,
; SERENDIPITY_DISTANT,
; SERENDIPITY_MANUAL,
; QA,
; SKY,
; NA
;} OBJTYPE;
;
