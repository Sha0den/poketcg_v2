; palette data are read by LoadPaletteData, expected to be structured as so:
; the first byte has possible values of 0, 1 or 2
; - if 0, nothing is done;
; - if 1, then the next byte is written to OBP0 (or to OBP1 if wd4ca == $1);
; - if 2, then the next 2 bytes are written to OBP0 and OBP1 respectively
;   (or only the first written to OBP1 if wd4ca == $1, skipping the second byte)
; next there is a byte declaring the size of the palette data
; indicating the number of palettes


; initial palettes that are used for all of the maps
Palette0::
	db 1
	gbpal SHADE_WHITE, SHADE_LIGHT, SHADE_DARK, SHADE_BLACK ; OBP0

	db 8

	rgb 28, 28, 24
	rgb 20, 20, 16
	rgb  8,  8,  8
	rgb  0,  0,  0

	rgb  0,  0,  0
	rgb 28,  0,  0
	rgb 28, 12,  0
	rgb 28, 28,  0

	rgb  0,  0,  0
	rgb 28,  0,  0
	rgb 28, 12,  0
	rgb 28, 28,  0

	rgb  0,  0,  0
	rgb 28,  0,  0
	rgb 28, 12,  0
	rgb 28, 28,  0

	rgb  0,  0,  0
	rgb 28,  0,  0
	rgb 28, 12,  0
	rgb 28, 28,  0

	rgb  0,  0,  0
	rgb 28,  0,  0
	rgb 28, 12,  0
	rgb 28, 28,  0

	rgb  0,  0,  0
	rgb 28,  0,  0
	rgb 28, 12,  0
	rgb 28, 28,  0

	rgb  0,  0,  0
	rgb 28,  0,  0
	rgb 28, 12,  0
	rgb 28, 28,  0


; palletes that are used for the Overworld map
Palette1::
	db 0
	db 8

	rgb 31, 31, 31
	rgb 20, 20, 16
	rgb  8,  8,  8
	rgb  0,  0,  0

	rgb 31, 31, 31
	rgb  8, 26,  0
	rgb  9,  3, 31
	rgb  1,  0,  5

	rgb 31, 31, 31
	rgb  8, 26,  0
	rgb  1, 15,  0
	rgb  1,  0,  5

	rgb 31, 31, 31
	rgb 25, 18,  6
	rgb 15,  6,  0
	rgb  1,  0,  5

	rgb 31, 31, 31
	rgb  8, 26,  0
	rgb 31,  0,  0
	rgb  1,  0,  5

	rgb 31, 31, 31
	rgb  8, 26,  0
	rgb 25, 18,  6
	rgb  1,  0,  5

	rgb 31, 31, 31
	rgb 31, 29,  0
	rgb 25, 18,  6
	rgb  1,  0,  5

	rgb 31, 31, 31
	rgb 25, 18,  6
	rgb  9,  3, 31
	rgb  1,  0,  5


; palettes that are used for the Mason Laboratory maps
Palette2::
	db 0
	db 8

	rgb 31, 31, 31
	rgb 20, 20, 16
	rgb  8,  8,  8
	rgb  0,  0,  0

	rgb 25, 31, 31
	rgb  9, 21, 31
	rgb 24, 13,  0
	rgb  5,  3,  0

	rgb 28, 28, 28
	rgb 25, 20,  0
	rgb  8,  6,  1
	rgb  0,  0,  0

	rgb 30, 27, 15
	rgb 24, 13,  0
	rgb 14,  8,  0
	rgb  0,  0,  0

	rgb 28, 28, 28
	rgb  1, 20,  0
	rgb  8,  6,  1
	rgb  0,  0,  0

	rgb 25, 31, 31
	rgb  9, 21, 31
	rgb  5,  7, 31
	rgb  0,  0,  5

	rgb 25, 31, 31
	rgb  9, 21, 31
	rgb 31,  0, 31
	rgb  0,  0,  5

	rgb 25, 31, 31
	rgb  9, 21, 31
	rgb  4, 21,  1
	rgb  1, 10,  0


; palettes that are used for the Ishihara's House map
Palette3::
	db 0
	db 8

	rgb 31, 31, 31
	rgb 20, 20, 16
	rgb  8,  8,  8
	rgb  0,  0,  0

	rgb 31, 30, 21
	rgb 30, 15,  5
	rgb  9,  0,  0
	rgb  0,  0,  0

	rgb 31, 29, 15
	rgb 23, 17,  7
	rgb  1, 22,  0
	rgb  0,  8,  0

	rgb 31, 31, 31
	rgb 31, 26, 20
	rgb 25, 16,  2
	rgb  5,  2,  0

	rgb 31, 29, 15
	rgb 23, 17,  7
	rgb 22, 11,  6
	rgb  6,  6,  3

	rgb 31, 31, 31
	rgb  8, 15, 31
	rgb  0,  3, 23
	rgb 28, 28,  0

	rgb  0,  0,  0
	rgb 28,  0,  0
	rgb 28, 12,  0
	rgb 28, 28,  0

	rgb  0,  0,  0
	rgb 28,  0,  0
	rgb 28, 12,  0
	rgb 28, 28,  0


; palettes that are used for the Fighting Club Entrance map and the Challenge Hall Entrance map
Palette4::
	db 0
	db 8

	rgb 31, 31, 31
	rgb 20, 20, 16
	rgb  8,  8,  8
	rgb  0,  0,  0

	rgb 31, 31, 31
	rgb 24, 21,  6
	rgb 11,  8,  5
	rgb  0,  0,  0

	rgb 27, 31, 22
	rgb  0, 31,  6
	rgb  0, 21, 10
	rgb  0,  0,  0

	rgb 31, 30, 22
	rgb 28, 12,  0
	rgb 13,  5,  0
	rgb  4,  1,  0

	rgb 31, 31, 17
	rgb  0, 31,  6
	rgb 31,  2,  0
	rgb 12,  2,  0

	rgb 27, 31, 22
	rgb  0, 31,  6
	rgb 31,  2,  0
	rgb 12,  2,  0

	rgb 27, 31, 22
	rgb  0, 31,  6
	rgb  4, 21,  1
	rgb  1, 10,  0

	rgb 27, 31, 22
	rgb  0, 31,  6
	rgb 24, 13,  0
	rgb  5,  3,  0


; palettes that are used for the Rock Club Entrance map
Palette5::
	db 0
	db 8

	rgb 31, 31, 31
	rgb 20, 20, 16
	rgb  8,  8,  8
	rgb  0,  0,  0

	rgb 31, 31, 31
	rgb 24, 21,  6
	rgb 11,  8,  5
	rgb  0,  0,  0

	rgb 27, 31, 22
	rgb  0, 31,  6
	rgb  0, 21, 10
	rgb  0,  0,  0

	rgb 27, 25, 23
	rgb 22, 16, 12
	rgb 14,  8,  4
	rgb  4,  1,  0

	rgb 31, 31, 17
	rgb  0, 31,  6
	rgb 31,  2,  0
	rgb 12,  2,  0

	rgb 27, 31, 22
	rgb  0, 31,  6
	rgb 31,  2,  0
	rgb 12,  2,  0

	rgb 27, 31, 22
	rgb  0, 31,  6
	rgb  4, 21,  1
	rgb  1, 10,  0

	rgb 31, 31, 31
	rgb  0, 31,  6
	rgb 24, 13,  0
	rgb  5,  3,  0


; palettes that are used for the Water Club Entrance map
Palette6::
	db 0
	db 8

	rgb 31, 31, 31
	rgb 20, 20, 16
	rgb  8,  8,  8
	rgb  0,  0,  0

	rgb 31, 31, 31
	rgb 24, 21,  6
	rgb 11,  8,  5
	rgb  0,  0,  0

	rgb 27, 31, 22
	rgb  0, 31,  6
	rgb  0, 21, 10
	rgb  0,  0,  0

	rgb 31, 31, 31
	rgb  0, 31, 30
	rgb  0, 14, 31
	rgb  0,  2,  5

	rgb 31, 31, 17
	rgb  0, 31,  6
	rgb 31,  2,  0
	rgb 12,  2,  0

	rgb 27, 31, 22
	rgb  0, 31,  6
	rgb 31,  2,  0
	rgb 12,  2,  0

	rgb 27, 31, 22
	rgb  0, 31,  6
	rgb  4, 21,  1
	rgb  1, 10,  0

	rgb 27, 31, 22
	rgb  0, 31,  6
	rgb 24, 13,  0
	rgb  5,  3,  0


; palettes that are used for the Lightning Club Entrance map
Palette7::
	db 0
	db 8

	rgb 31, 31, 31
	rgb 20, 20, 16
	rgb  8,  8,  8
	rgb  0,  0,  0

	rgb 31, 31, 31
	rgb 24, 21,  6
	rgb 11,  8,  5
	rgb  0,  0,  0

	rgb 27, 31, 22
	rgb  0, 31,  6
	rgb  0, 21, 10
	rgb  0,  0,  0

	rgb 31, 31, 31
	rgb 31, 31,  0
	rgb 31, 20,  0
	rgb  7,  4,  0

	rgb 31, 31, 17
	rgb  0, 31,  6
	rgb 31,  2,  0
	rgb 12,  2,  0

	rgb 27, 31, 22
	rgb  0, 31,  6
	rgb 31,  2,  0
	rgb 12,  2,  0

	rgb 27, 31, 22
	rgb  0, 31,  6
	rgb  4, 21,  1
	rgb  1, 10,  0

	rgb 27, 31, 22
	rgb  0, 31,  6
	rgb 24, 13,  0
	rgb  5,  3,  0


; palettes that are used for the Grass Club Entrance map
Palette8::
	db 0
	db 8

	rgb 31, 31, 31
	rgb 20, 20, 16
	rgb  8,  8,  8
	rgb  0,  0,  0

	rgb 31, 31, 31
	rgb 24, 21,  6
	rgb 11,  8,  5
	rgb  0,  0,  0

	rgb 27, 31, 22
	rgb  0, 31,  6
	rgb  0, 21, 10
	rgb  0,  0,  0

	rgb 31, 31, 31
	rgb 19, 31,  5
	rgb  0, 19,  4
	rgb  0,  4,  1

	rgb 31, 31, 17
	rgb  0, 31,  6
	rgb 31,  2,  0
	rgb 12,  2,  0

	rgb 27, 31, 22
	rgb  0, 31,  6
	rgb 31,  2,  0
	rgb 12,  2,  0

	rgb 27, 31, 22
	rgb  0, 31,  6
	rgb  4, 21,  1
	rgb  1, 10,  0

	rgb 27, 31, 22
	rgb  0, 31,  6
	rgb 24, 13,  0
	rgb  5,  3,  0


; palettes that are used for the Psychic Club Entrance map
Palette9::
	db 0
	db 8

	rgb 31, 31, 31
	rgb 20, 20, 16
	rgb  8,  8,  8
	rgb  0,  0,  0

	rgb 31, 31, 31
	rgb 24, 21,  6
	rgb 11,  8,  5
	rgb  0,  0,  0

	rgb 27, 31, 22
	rgb  0, 31,  6
	rgb  0, 21, 10
	rgb  0,  0,  0

	rgb 31, 31, 31
	rgb 31,  5, 31
	rgb 20,  0, 31
	rgb  1,  0,  5

	rgb 31, 31, 17
	rgb  0, 31,  6
	rgb 31,  2,  0
	rgb 12,  2,  0

	rgb 27, 31, 22
	rgb  0, 31,  6
	rgb 31,  2,  0
	rgb 12,  2,  0

	rgb 27, 31, 22
	rgb  0, 31,  6
	rgb  4, 21,  1
	rgb  1, 10,  0

	rgb 27, 31, 22
	rgb  0, 31,  6
	rgb 24, 13,  0
	rgb  5,  3,  0


; palettes that are used for the Science Club Entrance map
Palette10::
	db 0
	db 8

	rgb 31, 31, 31
	rgb 20, 20, 16
	rgb  8,  8,  8
	rgb  0,  0,  0

	rgb 31, 31, 31
	rgb 24, 21,  6
	rgb 11,  8,  5
	rgb  0,  0,  0

	rgb 27, 31, 22
	rgb  0, 31,  6
	rgb  0, 21, 10
	rgb  0,  0,  0

	rgb 31, 31, 31
	rgb  0, 31,  6
	rgb  0, 23,  4
	rgb  0,  7,  2

	rgb 31, 31, 17
	rgb  0, 31,  6
	rgb 31,  2,  0
	rgb 12,  2,  0

	rgb 27, 31, 22
	rgb  0, 31,  6
	rgb 31,  2,  0
	rgb 12,  2,  0

	rgb 27, 31, 22
	rgb  0, 31,  6
	rgb  4, 21,  1
	rgb  1, 10,  0

	rgb 27, 31, 22
	rgb  0, 31,  6
	rgb 24, 13,  0
	rgb  5,  3,  0


; palettes that are used for the Fire Club Entrance map
Palette11::
	db 0
	db 8

	rgb 31, 31, 31
	rgb 20, 20, 16
	rgb  8,  8,  8
	rgb  0,  0,  0

	rgb 31, 31, 31
	rgb 24, 21,  6
	rgb 11,  8,  5
	rgb  0,  0,  0

	rgb 27, 31, 22
	rgb  0, 31,  6
	rgb  0, 21, 10
	rgb  0,  0,  0

	rgb 31, 31, 31
	rgb 31, 20,  0
	rgb 31,  0,  0
	rgb  8,  0,  0

	rgb 31, 31, 17
	rgb  0, 31,  6
	rgb 31,  2,  0
	rgb 12,  2,  0

	rgb 27, 31, 22
	rgb  0, 31,  6
	rgb 31,  2,  0
	rgb 12,  2,  0

	rgb 27, 31, 22
	rgb  0, 31,  6
	rgb  4, 21,  1
	rgb  1, 10,  0

	rgb 27, 31, 22
	rgb  0, 31,  6
	rgb 24, 13,  0
	rgb  5,  3,  0


; palettes that are used for all of the Club Lobby maps
Palette12::
	db 0
	db 8

	rgb 31, 31, 31
	rgb 20, 20, 16
	rgb  8,  8,  8
	rgb  0,  0,  0

	rgb 31, 31, 31
	rgb 24, 21,  6
	rgb 11,  8,  5
	rgb  0,  0,  0

	rgb 27, 31, 22
	rgb  0, 31,  6
	rgb  4, 21,  1
	rgb  1, 10,  0

	rgb 31, 31, 31
	rgb 28, 12,  0
	rgb 11,  8,  5
	rgb  0,  0,  6

	rgb 27, 31, 22
	rgb  0, 31,  6
	rgb 31,  2,  0
	rgb 12,  2,  0

	rgb 31, 31, 31
	rgb  9, 21, 31
	rgb  5,  7, 31
	rgb  0,  0,  5

	rgb 31, 31, 31
	rgb 31, 31,  4
	rgb 28, 12,  0
	rgb  6,  4,  0

	rgb 27, 31, 22
	rgb  0, 25,  6
	rgb 28, 12,  0
	rgb  0,  0,  6


; palettes that are used for the (top) Fighting Club map
Palette13::
	db 0
	db 8

	rgb 31, 31, 31
	rgb 20, 20, 16
	rgb  8,  8,  8
	rgb  0,  0,  0

	rgb 31, 31, 31
	rgb 26, 22,  9
	rgb 12,  5,  1
	rgb  0,  7,  0

	rgb 31, 31, 31
	rgb 18, 18, 24
	rgb  6,  5, 18
	rgb  0,  0,  0

	rgb 22, 31, 22
	rgb  5, 31,  0
	rgb  0, 19,  2
	rgb  0,  0,  0

	rgb 31, 31, 31
	rgb 26, 22,  9
	rgb 31,  2,  0
	rgb 12,  5,  1

	rgb 22, 31, 22
	rgb  5, 31,  0
	rgb 11, 10, 10
	rgb  0,  0,  0

	rgb 22, 31, 22
	rgb  5, 31,  0
	rgb  8,  9,  8
	rgb 31,  2,  0

	rgb 31, 31, 31
	rgb 18, 18, 24
	rgb  5, 31, 25
	rgb  0,  0,  6


; palettes that are used for the (top) Rock Club map
Palette14::
	db 0
	db 8

	rgb 31, 31, 31
	rgb 20, 20, 16
	rgb  8,  8,  8
	rgb  0,  0,  0

	rgb 31, 31, 31
	rgb 31, 16, 11
	rgb 10,  8, 25
	rgb  0,  0,  6

	rgb 31, 31, 31
	rgb 17, 25, 31
	rgb  0,  6, 27
	rgb 31, 31,  0

	rgb 31, 31, 31
	rgb 29, 20,  3
	rgb 16,  5,  0
	rgb  3,  2,  0

	rgb  0,  0,  0
	rgb 31,  0,  0
	rgb 31, 13,  0
	rgb 31, 25,  3

	rgb 31, 31, 31
	rgb 31, 25,  3
	rgb 31,  2,  0
	rgb 12,  2,  0

	rgb 31, 31, 31
	rgb 31, 25,  3
	rgb 20, 13,  0
	rgb  3,  2,  0

	rgb  0,  0,  0
	rgb 31,  0,  0
	rgb 31, 13,  0
	rgb 31, 31,  0


; palettes that are used for the (top) Water Club map
Palette15::
	db 0
	db 8

	rgb 31, 31, 31
	rgb 20, 20, 16
	rgb  8,  8,  8
	rgb  0,  0,  0

	rgb 31, 31, 31
	rgb  0, 21, 31
	rgb  3,  0, 31
	rgb  0,  0,  8

	rgb 31, 31, 20
	rgb 31, 16,  0
	rgb 31, 31, 31
	rgb  0,  0,  8

	rgb 31, 31, 20
	rgb 31, 16,  0
	rgb 31,  2,  0
	rgb  0,  0,  8

	rgb 31, 31, 31
	rgb  0, 21, 31
	rgb 31,  2,  0
	rgb 12,  2,  0

	rgb 31, 31, 20
	rgb 31, 16,  0
	rgb  0, 31,  0
	rgb  0,  4,  0

	rgb 31, 31, 20
	rgb 31, 16,  0
	rgb 24, 13,  0
	rgb  5,  3,  0

	rgb 31, 31, 31
	rgb  0, 31,  0
	rgb  4, 21,  1
	rgb  1, 10,  0


; palettes that are used for the (top) Lightning Club map
Palette16::
	db 0
	db 8

	rgb 31, 31, 31
	rgb 20, 20, 16
	rgb  8,  8,  8
	rgb  0,  0,  0

	rgb 31, 31, 21
	rgb 31, 23,  4
	rgb 10,  3,  0
	rgb  0,  0,  0

	rgb 31, 31, 27
	rgb  0, 23, 31
	rgb  3,  0, 20
	rgb  0,  0,  4

	rgb 31, 31, 31
	rgb 28, 17,  0
	rgb 31,  0,  5
	rgb  3,  0, 10

	rgb 31, 31, 27
	rgb 21,  0, 12
	rgb  3,  0, 20
	rgb  0,  0,  4

	rgb 31, 31, 27
	rgb 21,  0, 12
	rgb  0, 23, 31
	rgb  3,  0, 20

	rgb 31, 31, 31
	rgb 28, 17,  0
	rgb 14,  0,  8
	rgb  3,  0, 10

	rgb  0,  0,  0
	rgb 28,  0,  0
	rgb 28, 12,  0
	rgb 28, 28,  0


; palettes that are used for the (top) Grass Club map
Palette17::
	db 0
	db 8

	rgb 31, 31, 30
	rgb 20, 20, 16
	rgb  8,  8,  8
	rgb  0,  0,  0

	rgb 31, 31, 16
	rgb  4, 29,  4
	rgb  0, 12,  0
	rgb 12,  2,  0

	rgb 31, 31, 31
	rgb  4, 29,  4
	rgb  0, 12,  0
	rgb 19, 19, 19

	rgb 30, 24, 10
	rgb  4, 29,  4
	rgb  0, 12,  0
	rgb 12,  2,  0

	rgb 31, 31, 31
	rgb  0, 31,  6
	rgb 31,  2,  0
	rgb 12,  2,  0

	rgb 31, 31,  0
	rgb 10, 28, 31
	rgb 10, 12, 31
	rgb  0,  0, 11

	rgb 31, 22, 31
	rgb  4, 29,  4
	rgb 24, 13,  0
	rgb 12,  2,  0

	rgb 30, 24, 10
	rgb 27, 19,  6
	rgb 20, 10,  0
	rgb 11,  2,  0


; palettes that are used for the (top) Psychic Club map
Palette18::
	db 0
	db 8

	rgb 31, 31, 31
	rgb 20, 20, 16
	rgb  8,  8,  8
	rgb  0,  0,  0

	rgb 31, 31, 19
	rgb 30, 21,  0
	rgb 23,  8,  0
	rgb  0,  0,  0

	rgb 31, 31, 31
	rgb 19, 13, 31
	rgb  0,  0, 31
	rgb  0,  0, 10

	rgb 31, 31, 19
	rgb 30, 21,  0
	rgb 31,  0,  0
	rgb 11,  0,  0

	rgb 31, 31, 19
	rgb 19, 13, 31
	rgb 30, 21,  0
	rgb  0,  0, 10

	rgb  0,  0,  0
	rgb 28,  0,  0
	rgb 28, 12,  0
	rgb 28, 28,  0

	rgb  0,  0,  0
	rgb 28,  0,  0
	rgb 28, 12,  0
	rgb 28, 28,  0

	rgb  0,  0,  0
	rgb 28,  0,  0
	rgb 28, 12,  0
	rgb 28, 28,  0


; palettes that are used for the (top) Science Club map
Palette19::
	db 0
	db 8

	rgb 31, 31, 31
	rgb 20, 20, 16
	rgb  8,  8,  8
	rgb  0,  0,  0

	rgb 28, 22, 31
	rgb 21, 13, 31
	rgb 13,  0, 31
	rgb  0,  0,  0

	rgb 31, 31,  0
	rgb  0, 31,  0
	rgb  0,  0, 31
	rgb 31,  0,  0

	rgb 31, 31, 31
	rgb 28, 12,  3
	rgb 11,  2,  1
	rgb  4,  1,  1

	rgb 31, 31, 31
	rgb 10, 28, 31
	rgb  0, 18,  8
	rgb  0,  0,  2

	rgb 28, 22, 31
	rgb 10, 11, 31
	rgb  2,  4, 31
	rgb  6,  0,  0

	rgb 28, 22, 31
	rgb 21, 13, 31
	rgb 31,  2,  0
	rgb 12,  2,  0

	rgb  0,  0,  0
	rgb 28,  0,  0
	rgb 28, 12,  0
	rgb 28, 28,  0


; palettes that are used for the (top) Fire Club map
Palette20::
	db 0
	db 8

	rgb 31, 31, 31
	rgb 20, 20, 16
	rgb  8,  8,  8
	rgb  0,  0,  0

	rgb 31, 26, 31
	rgb  8, 20, 31
	rgb  0,  0, 28
	rgb  0,  0,  5

	rgb 31, 31, 24
	rgb 31, 19,  7
	rgb 16, 31,  7
	rgb  0, 11,  6

	rgb 31, 31, 24
	rgb 31, 19,  7
	rgb 31,  0,  0
	rgb 16,  0,  0

	rgb  0,  0,  0
	rgb 28,  0,  0
	rgb 28, 12,  0
	rgb 28, 28,  0

	rgb  0,  0,  0
	rgb 28,  0,  0
	rgb 28, 12,  0
	rgb 28, 28,  0

	rgb  0,  0,  0
	rgb 28,  0,  0
	rgb 28, 12,  0
	rgb 28, 28,  0

	rgb  0,  0,  0
	rgb 28,  0,  0
	rgb 28, 12,  0
	rgb 28, 28,  0


; palettes that are used for the (top) Challenge Hall map
Palette21::
	db 0
	db 8

	rgb 31, 31, 31
	rgb 20, 20, 16
	rgb  8,  8,  8
	rgb  0,  0,  0

	rgb 31, 31, 31
	rgb 31, 22,  7
	rgb  0, 23,  0
	rgb  1, 10,  0

	rgb 31, 31, 21
	rgb 31, 22,  7
	rgb 22,  8,  0
	rgb  5,  3,  0

	rgb 31, 31, 21
	rgb 31, 26,  0
	rgb 31,  0, 31
	rgb  0,  0,  3

	rgb 31, 31, 31
	rgb 31, 30,  0
	rgb 31,  0,  0
	rgb  2,  0,  0

	rgb 31, 31, 31
	rgb  8, 31, 31
	rgb  0, 23,  0
	rgb  4,  2,  1

	rgb 31, 31, 31
	rgb 31, 30,  0
	rgb 24, 13,  0
	rgb  2,  0,  0

	rgb 31, 31, 23
	rgb 31, 22,  7
	rgb 22,  8,  0
	rgb  5,  3,  0


; palettes that are used for the Pokemon Dome Entrance map
Palette22::
	db 0
	db 8

	rgb 31, 31, 31
	rgb 20, 20, 16
	rgb  8,  8,  8
	rgb  0,  0,  0

	rgb 31, 28, 16
	rgb 31,  0,  0
	rgb 20,  0,  0
	rgb 11,  1,  4

	rgb 31, 28, 16
	rgb 31,  0,  0
	rgb  4, 21,  1
	rgb  1, 10,  0

	rgb 31, 28, 16
	rgb 31,  0,  0
	rgb 24, 13,  0
	rgb  5,  3,  0

	rgb 31, 31, 31
	rgb  9, 21, 31
	rgb  5,  7, 31
	rgb  0,  0,  5

	rgb 30, 27, 15
	rgb 24, 13,  0
	rgb 14,  8,  0
	rgb  0,  0,  0

	rgb 31, 31, 31
	rgb 31, 25,  0
	rgb  6,  4,  0
	rgb  0,  0,  0

	rgb 31, 31, 31
	rgb 23, 12,  0
	rgb  6,  4,  0
	rgb  2,  0,  0


; palettes that are used for the main Pokemon Dome map
Palette23::
	db 0
	db 8

	rgb 31, 31, 31
	rgb 20, 20, 16
	rgb  8,  8,  8
	rgb  0,  0,  0

	rgb 31, 28, 16
	rgb 31,  0,  0
	rgb 20,  0,  0
	rgb 11,  1,  4

	rgb 31, 28, 16
	rgb 31,  0,  0
	rgb  4, 21,  1
	rgb  1, 10,  0

	rgb 31, 28, 16
	rgb 31,  0,  0
	rgb 24, 13,  0
	rgb  5,  3,  0

	rgb 31, 31,  0
	rgb 31,  0,  0
	rgb 13, 10, 31
	rgb  3,  3, 20

	rgb 31, 31, 31
	rgb 23, 12,  0
	rgb  0, 23,  0
	rgb  0,  8,  0

	rgb 31, 31, 31
	rgb 25, 21,  0
	rgb 31,  0,  0
	rgb  2,  0,  0

	rgb 31, 31, 31
	rgb 23, 12,  0
	rgb  6,  4,  0
	rgb  2,  0,  0


; palettes that are used for the Hall of Honor map
Palette24::
	db 0
	db 8

	rgb 31, 31, 31
	rgb 20, 20, 16
	rgb  8,  8,  8
	rgb  0,  0,  0

	rgb 31, 31, 31
	rgb 31,  0,  0
	rgb 20,  0,  0
	rgb 11,  1,  4

	rgb 31, 31, 31
	rgb 31, 28,  0
	rgb 31, 20,  6
	rgb 29,  6,  0

	rgb 31, 31, 31
	rgb 15, 16, 31
	rgb  7,  8, 20
	rgb  0,  0, 10

	rgb 31, 31, 31
	rgb 15, 16, 31
	rgb 31, 28,  0
	rgb  0,  0, 10

	rgb 31, 31, 31
	rgb 31, 28,  0
	rgb 20,  0,  0
	rgb 29,  6,  0

	rgb 31, 31, 31
	rgb 15, 16, 31
	rgb 31,  0,  0
	rgb  0,  0, 10

	rgb 31, 31, 31
	rgb 23, 12,  0
	rgb  6,  4,  0
	rgb  4,  2,  1


; palettes that are used for the title screen
Palette25::
	db 0
	db 8

	rgb 28, 28, 24
	rgb 18, 18, 16
	rgb  8,  8,  8
	rgb  0,  0,  0

	rgb 28, 28, 24
	rgb 31, 22,  0
	rgb  0, 10, 27
	rgb  0,  0,  3

	rgb 28, 28, 24
	rgb 31,  0,  0
	rgb  0, 10, 27
	rgb  0,  0,  0

	rgb 28, 28, 24
	rgb 31, 22,  0
	rgb 31,  0,  0
	rgb  0,  0,  0

	rgb 28, 28, 24
	rgb 26, 23, 13
	rgb 31,  0,  0
	rgb  0,  0,  0

	rgb 28, 28, 24
	rgb 31, 16,  0
	rgb  0, 10, 27
	rgb  0,  0,  3

	rgb 28, 28, 24
	rgb 31, 22,  0
	rgb 26, 23, 13
	rgb  0,  0,  3

	rgb  0,  0,  0
	rgb 31,  0,  0
	rgb 31, 13,  0
	rgb 31, 31,  0


; palettes that are used for the Copyright scene
Palette26::
	db 0
	db 8

	rgb 27, 27, 24
	rgb 20, 20, 17
	rgb 12, 12, 10
	rgb  5,  5,  3

	rgb 27, 27, 24
	rgb 31,  0,  0
	rgb 31, 13,  0
	rgb  0,  0, 31

	rgb  0,  0,  0
	rgb 31,  0,  0
	rgb 31, 13,  0
	rgb 31, 31,  0

	rgb  0,  0,  0
	rgb 31,  0,  0
	rgb 31, 13,  0
	rgb 31, 31,  0

	rgb  0,  0,  0
	rgb 31,  0,  0
	rgb 31, 13,  0
	rgb 31, 31,  0

	rgb  0,  0,  0
	rgb 31,  0,  0
	rgb 31, 13,  0
	rgb 31, 31,  0

	rgb  0,  0,  0
	rgb 31,  0,  0
	rgb 31, 13,  0
	rgb 31, 31,  0

	rgb  0,  0,  0
	rgb 31,  0,  0
	rgb 31, 13,  0
	rgb 31, 31,  0


; palettes that are used for the Nintendo scene
Palette27::
	db 0
	db 8

	rgb 28, 28, 24
	rgb 21, 21, 16
	rgb 10, 10,  8
	rgb  0,  0,  0

	rgb  0,  0,  0
	rgb 31,  0,  0
	rgb 31, 13,  0
	rgb 31, 31,  0

	rgb  0,  0,  0
	rgb 31,  0,  0
	rgb 31, 13,  0
	rgb 31, 31,  0

	rgb  0,  0,  0
	rgb 31,  0,  0
	rgb 31, 13,  0
	rgb 31, 31,  0

	rgb  0,  0,  0
	rgb 31,  0,  0
	rgb 31, 13,  0
	rgb 31, 31,  0

	rgb  0,  0,  0
	rgb 31,  0,  0
	rgb 31, 13,  0
	rgb 31, 31,  0

	rgb  0,  0,  0
	rgb 31,  0,  0
	rgb 31, 13,  0
	rgb 31, 31,  0

	rgb  0,  0,  0
	rgb 31,  0,  0
	rgb 31, 13,  0
	rgb 31, 31,  0


; palettes that are used for the Companies scene
Palette28::
	db 0
	db 8

	rgb 27, 27, 24
	rgb 20, 20, 17
	rgb 12, 12, 10
	rgb  5,  5,  3

	rgb  0,  0,  0
	rgb 31,  0,  0
	rgb 31, 13,  0
	rgb 31, 31,  0

	rgb  0,  0,  0
	rgb 31,  0,  0
	rgb 31, 13,  0
	rgb 31, 31,  0

	rgb  0,  0,  0
	rgb 31,  0,  0
	rgb 31, 13,  0
	rgb 31, 31,  0

	rgb  0,  0,  0
	rgb 31,  0,  0
	rgb 31, 13,  0
	rgb 31, 31,  0

	rgb  0,  0,  0
	rgb 31,  0,  0
	rgb 31, 13,  0
	rgb 31, 31,  0

	rgb  0,  0,  0
	rgb 31,  0,  0
	rgb 31, 13,  0
	rgb 31, 31,  0

	rgb  0,  0,  0
	rgb 31,  0,  0
	rgb 31, 13,  0
	rgb 31, 31,  0


; palettes that are used for the NPC sprites?
Palette29::
	db 2
	gbpal SHADE_BLACK, SHADE_WHITE, SHADE_LIGHT, SHADE_BLACK ; OBP0
	gbpal SHADE_BLACK, SHADE_WHITE, SHADE_DARK, SHADE_BLACK ; OBP1

	db 8

	rgb  6, 14, 11
	rgb 30, 27, 24
	rgb  6, 15, 25
	rgb  0,  0,  0

	rgb  6, 14, 11
	rgb 30, 27, 24
	rgb 30, 13, 18
	rgb  0,  0,  0

	rgb  6, 14, 11
	rgb 30, 27, 24
	rgb 28, 24,  5
	rgb  0,  0,  0

	rgb  6, 14, 11
	rgb 30, 27, 24
	rgb  4, 19,  3
	rgb  0,  0,  0

	rgb  6, 14, 11
	rgb 30, 27, 24
	rgb 30,  5,  9
	rgb  0,  0,  0

	rgb  6, 14, 11
	rgb 30, 27, 24
	rgb 15,  8, 26
	rgb  0,  0,  0

	rgb  6, 14, 11
	rgb 30, 27, 24
	rgb 31, 31, 31
	rgb  0,  0,  0

	rgb  6, 14, 11
	rgb 30, 27, 24
	rgb  9,  9, 27
	rgb  0,  0,  0


; palettes that are used for the title screen sprites
Palette30::
	db 2
	gbpal SHADE_DARK, SHADE_WHITE, SHADE_LIGHT, SHADE_BLACK ; OBP0
	gbpal SHADE_BLACK, SHADE_BLACK, SHADE_BLACK, SHADE_BLACK ; OBP1

	db 8

	rgb  0,  0,  0
	rgb 28, 28, 24
	rgb  5, 19,  6
	rgb  1,  0,  5

	rgb  0,  0,  0
	rgb 28, 28, 24
	rgb 31,  2,  4
	rgb  1,  0,  5

	rgb  0,  0,  0
	rgb 28, 28, 24
	rgb  7, 23, 31
	rgb  1,  0,  5

	rgb  0,  0,  0
	rgb 28, 28, 24
	rgb 25, 24, 31
	rgb  1,  0,  5

	rgb  0,  0,  0
	rgb 28, 28, 24
	rgb 31, 31,  0
	rgb  1,  0,  5

	rgb  0,  0,  0
	rgb 28, 28, 24
	rgb 27, 18, 31
	rgb  1,  0,  5

	rgb  0,  0,  0
	rgb 28, 28, 24
	rgb 23, 11,  7
	rgb  1,  0,  5

	rgb  0,  0,  0
	rgb 31,  0,  0
	rgb 31, 13,  0
	rgb 31, 31,  0


; applied to the Glow duel animation
Palette31::
	db 1
	gbpal SHADE_DARK, SHADE_WHITE, SHADE_LIGHT, SHADE_BLACK ; OBP0

	db 1

	rgb  0,  0,  0
	rgb 31, 31,  7
	rgb 31, 24,  6
	rgb 11,  3,  0


; applied to the Paralysis duel animation
Palette32::
	db 1
	gbpal SHADE_DARK, SHADE_WHITE, SHADE_LIGHT, SHADE_BLACK ; OBP0

	db 1

	rgb  0,  0,  0
	rgb 28, 28, 24
	rgb 28, 20, 12
	rgb  0,  0,  0


; applied to the Sleep duel animation
Palette33::
	db 1
	gbpal SHADE_DARK, SHADE_WHITE, SHADE_LIGHT, SHADE_BLACK ; OBP0

	db 1

	rgb  0,  0,  0
	rgb 31, 31, 31
	rgb 28, 20, 12
	rgb  0,  0,  0


; applied to the Confusion duel animation
Palette34::
	db 1
	gbpal SHADE_DARK, SHADE_WHITE, SHADE_LIGHT, SHADE_BLACK ; OBP0

	db 1

	rgb  0,  0,  0
	rgb 31, 31,  0
	rgb 31, 13,  0
	rgb 11,  4,  0


; applied to the Poison duel animation
Palette35::
	db 1
	gbpal SHADE_DARK, SHADE_WHITE, SHADE_LIGHT, SHADE_BLACK ; OBP0

	db 1

	rgb  0,  0,  0
	rgb 17, 17, 29
	rgb  8,  8, 24
	rgb  0,  0, 10


; applied to the Hit duel animations
Palette36::
	db 1
	gbpal SHADE_DARK, SHADE_WHITE, SHADE_LIGHT, SHADE_BLACK ; OBP0

	db 1

	rgb  0,  0,  0
	rgb 31, 23, 23
	rgb 31,  6,  7
	rgb  0,  0,  0


; applied to the Show Damage duel animation
Palette37::
	db 1
	gbpal SHADE_DARK, SHADE_WHITE, SHADE_LIGHT, SHADE_BLACK ; OBP0

	db 1

	rgb  0,  0,  0
	rgb 31, 31, 31
	rgb 15, 15, 15
	rgb  0,  0,  0


; applied to the Thunder Shock duel animations
Palette38::
	db 1
	gbpal SHADE_DARK, SHADE_WHITE, SHADE_WHITE, SHADE_BLACK ; OBP0

	db 1

	rgb  0,  0,  0
	rgb 31, 31, 31
	rgb 31, 26,  0
	rgb  0,  0,  0


; applied to the Lightning duel animation
Palette39::
	db 1
	gbpal SHADE_DARK, SHADE_WHITE, SHADE_WHITE, SHADE_BLACK ; OBP0

	db 1

	rgb  0,  0,  0
	rgb 31, 31, 31
	rgb 31, 26,  0
	rgb  0,  0,  0


; applied to the Border Spark duel animation
Palette40::
	db 1
	gbpal SHADE_DARK, SHADE_WHITE, SHADE_LIGHT, SHADE_BLACK ; OBP0

	db 1

	rgb  0,  0,  0
	rgb 31, 31, 31
	rgb 31, 31,  0
	rgb  0,  0,  0


; applied to the Big Lightning duel animation
Palette41::
	db 1
	gbpal SHADE_DARK, SHADE_WHITE, SHADE_WHITE, SHADE_BLACK ; OBP0

	db 1

	rgb  0,  0,  0
	rgb 31, 31, 31
	rgb 31, 26,  0
	rgb  0,  0,  0


; applied to the Flame duel animations
Palette42::
	db 1
	gbpal SHADE_DARK, SHADE_WHITE, SHADE_LIGHT, SHADE_BLACK ; OBP0

	db 1

	rgb  0,  0,  0
	rgb 30, 28, 13
	rgb 31, 17,  8
	rgb 12,  0,  0


; applied to the Fire Spin duel animation
Palette43::
	db 1
	gbpal SHADE_DARK, SHADE_WHITE, SHADE_LIGHT, SHADE_BLACK ; OBP0

	db 1

	rgb  0,  0,  0
	rgb 30, 28, 13
	rgb 31, 17,  8
	rgb 12,  0,  0


; applied to the Dive Bomb/Firegiver duel animations
Palette44::
	db 1
	gbpal SHADE_DARK, SHADE_WHITE, SHADE_LIGHT, SHADE_BLACK ; OBP0

	db 1

	rgb  0,  0,  0
	rgb 30, 28, 13
	rgb 31, 17,  8
	rgb 12,  0,  0


; applied to the Water Jets duel animation
Palette45::
	db 1
	gbpal SHADE_DARK, SHADE_WHITE, SHADE_DARK, SHADE_BLACK ; OBP0

	db 1

	rgb 16, 23, 20
	rgb 20, 31, 31
	rgb  6, 14, 31
	rgb 14,  0, 31


; applied to the Water Gun duel animation
Palette46::
	db 1
	gbpal SHADE_DARK, SHADE_WHITE, SHADE_LIGHT, SHADE_BLACK ; OBP0

	db 1

	rgb  0,  0,  0
	rgb  0, 31, 31
	rgb  0, 15, 31
	rgb  0,  0, 21


; applied to the Whirlpool duel animation
Palette47::
	db 1
	gbpal SHADE_DARK, SHADE_WHITE, SHADE_LIGHT, SHADE_DARK ; OBP0

	db 1

	rgb 11, 11, 11
	rgb  0, 31, 31
	rgb  0, 15, 31
	rgb  0,  0,  9


; applied to the Hydro Pump duel animation
Palette48::
	db 1
	gbpal SHADE_DARK, SHADE_WHITE, SHADE_LIGHT, SHADE_BLACK ; OBP0

	db 1

	rgb  0,  0,  0
	rgb  0, 31, 31
	rgb  0, 15, 31
	rgb  0,  0, 21


; applied to the Blizzard/Quick Freeze duel animations
Palette49::
	db 1
	gbpal SHADE_DARK, SHADE_WHITE, SHADE_LIGHT, SHADE_BLACK ; OBP0

	db 1

	rgb  0,  0,  0
	rgb 31, 31, 31
	rgb  0, 15, 31
	rgb  0, 15, 31


; applied to the Psychic duel animation
Palette50::
	db 1
	gbpal SHADE_DARK, SHADE_WHITE, SHADE_DARK, SHADE_BLACK ; OBP0

	db 1

	rgb  0,  0,  0
	rgb  7, 20, 31
	rgb  5, 13, 27
	rgb  0,  1,  8


; applied to the Leer duel animation
Palette51::
	db 1
	gbpal SHADE_DARK, SHADE_WHITE, SHADE_LIGHT, SHADE_BLACK ; OBP0

	db 1

	rgb 28, 28, 24
	rgb 31, 31, 31
	rgb 31,  0,  8
	rgb  7,  0,  3


; applied to the Beam duel animation
Palette52::
	db 1
	gbpal SHADE_DARK, SHADE_WHITE, SHADE_LIGHT, SHADE_BLACK ; OBP0

	db 1

	rgb  0,  0,  0
	rgb 28, 20, 20
	rgb 28, 12, 12
	rgb 12,  4,  4


; applied to the Hyper Beam duel animation
Palette53::
	db 1
	gbpal SHADE_DARK, SHADE_WHITE, SHADE_LIGHT, SHADE_BLACK ; OBP0

	db 1

	rgb  0,  0,  0
	rgb 31, 31, 22
	rgb 28, 20, 12
	rgb  0,  0,  0


; applied to the Rock Throw/Stone Barrage duel animations
Palette54::
	db 1
	gbpal SHADE_DARK, SHADE_WHITE, SHADE_LIGHT, SHADE_BLACK ; OBP0

	db 1

	rgb 28, 28, 24
	rgb 31, 31, 31
	rgb 21, 13,  0
	rgb  0,  0,  0


; applied to the punching duel animations
Palette55::
	db 1
	gbpal SHADE_DARK, SHADE_WHITE, SHADE_DARK, SHADE_BLACK ; OBP0

	db 1

	rgb 28, 28, 24
	rgb 31, 12,  0
	rgb 28,  0,  0
	rgb  8,  0,  0


; applied to the Stretch Kick duel animation
Palette56::
	db 1
	gbpal SHADE_DARK, SHADE_WHITE, SHADE_LIGHT, SHADE_BLACK ; OBP0

	db 1

	rgb  0,  0,  0
	rgb 31, 31, 31
	rgb 28, 20, 12
	rgb  0,  0,  0


; applied to the Slash/Fury Swipes duel animations
Palette57::
	db 1
	gbpal SHADE_DARK, SHADE_WHITE, SHADE_LIGHT, SHADE_BLACK ; OBP0

	db 1

	rgb  0,  0,  0
	rgb 31, 31, 18
	rgb 18, 19,  4
	rgb  6,  7,  0


; applied to the Whip duel animation
Palette58::
	db 1
	gbpal SHADE_DARK, SHADE_WHITE, SHADE_DARK, SHADE_BLACK ; OBP0

	db 1

	rgb  0,  0,  0
	rgb 31, 31, 18
	rgb 31, 13,  0
	rgb  6,  7,  0


; applied to the Sonicboom duel animation
Palette59::
	db 1
	gbpal SHADE_DARK, SHADE_WHITE, SHADE_LIGHT, SHADE_BLACK ; OBP0

	db 1

	rgb  0,  0,  0
	rgb 31, 31, 18
	rgb 18, 19,  4
	rgb  6,  7,  0


; applied to the Drill duel animation
Palette60::
	db 1
	gbpal SHADE_DARK, SHADE_WHITE, SHADE_LIGHT, SHADE_BLACK ; OBP0

	db 1

	rgb  0,  0,  0
	rgb 28, 28, 28
	rgb 20, 20, 20
	rgb  6,  7,  0


; applied to the Pot Smash duel animation
Palette61::
	db 1
	gbpal SHADE_DARK, SHADE_WHITE, SHADE_LIGHT, SHADE_BLACK ; OBP0

	db 1

	rgb 16, 23, 20
	rgb 31, 31,  0
	rgb 31, 20,  0
	rgb  7,  1,  0


; applied to the Bonemerang duel animation
Palette62::
	db 1
	gbpal SHADE_DARK, SHADE_WHITE, SHADE_LIGHT, SHADE_BLACK ; OBP0

	db 1

	rgb  0,  0,  0
	rgb 31, 31, 31
	rgb 20, 20, 16
	rgb  6,  7,  0


; applied to the Seismic Toss duel animation
Palette63::
	db 1
	gbpal SHADE_DARK, SHADE_WHITE, SHADE_LIGHT, SHADE_BLACK ; OBP0

	db 1

	rgb  0,  0,  0
	rgb  1, 10, 23
	rgb 26, 31, 18
	rgb  6,  7,  0


; applied to the Needles duel animation
Palette64::
	db 1
	gbpal SHADE_DARK, SHADE_WHITE, SHADE_DARK, SHADE_BLACK ; OBP0

	db 1

	rgb  0,  0,  0
	rgb 28, 25, 31
	rgb 16, 14, 22
	rgb  0,  0, 13


; applied to the White Gas duel animation
Palette65::
	db 1
	gbpal SHADE_DARK, SHADE_WHITE, SHADE_LIGHT, SHADE_BLACK ; OBP0

	db 1

	rgb 11, 11, 11
	rgb 30, 31, 29
	rgb 25, 25, 25
	rgb  1,  1,  1


; applied to the Powder duel animation
Palette66::
	db 1
	gbpal SHADE_DARK, SHADE_WHITE, SHADE_LIGHT, SHADE_BLACK ; OBP0

	db 1

	rgb 11, 11, 11
	rgb 31, 31, 30
	rgb 31, 31, 24
	rgb 10,  9,  0


; applied to the Goo duel animation
Palette67::
	db 1
	gbpal SHADE_DARK, SHADE_WHITE, SHADE_LIGHT, SHADE_BLACK ; OBP0

	db 1

	rgb  0,  0,  0
	rgb 26, 31, 18
	rgb 19, 23, 13
	rgb  6,  7,  0


; applied to the Bubble duel animation
Palette68::
	db 1
	gbpal SHADE_DARK, SHADE_WHITE, SHADE_LIGHT, SHADE_BLACK ; OBP0

	db 1

	rgb  0,  0,  0
	rgb 26, 29, 31
	rgb 13, 16, 28
	rgb  6,  7,  0


; applied to the String Shot duel animation
Palette69::
	db 1
	gbpal SHADE_DARK, SHADE_WHITE, SHADE_LIGHT, SHADE_BLACK ; OBP0

	db 1

	rgb  0,  0,  0
	rgb 27, 31, 27
	rgb 13, 16, 28
	rgb  6,  7,  0


; applied to the Boyfriends duel animation
Palette70::
	db 1
	gbpal SHADE_DARK, SHADE_WHITE, SHADE_LIGHT, SHADE_BLACK ; OBP0

	db 1

	rgb 11, 11, 11
	rgb 31, 26, 31
	rgb 31, 16, 27
	rgb 14,  0,  5


; applied to the Lure duel animation
Palette71::
	db 1
	gbpal SHADE_DARK, SHADE_WHITE, SHADE_LIGHT, SHADE_BLACK ; OBP0

	db 1

	rgb 11, 11, 11
	rgb 31, 31, 30
	rgb 27, 16, 23
	rgb  0,  0,  2


; applied to the Toxic duel animation
Palette72::
	db 1
	gbpal SHADE_DARK, SHADE_WHITE, SHADE_DARK, SHADE_BLACK ; OBP0

	db 1

	rgb 11, 11, 11
	rgb 31, 31, 30
	rgb 11, 10, 10
	rgb  0,  0,  2


; applied to the Confuse Ray duel animation
Palette73::
	db 1
	gbpal SHADE_DARK, SHADE_WHITE, SHADE_LIGHT, SHADE_BLACK ; OBP0

	db 1

	rgb 11, 11, 11
	rgb 31, 31, 24
	rgb 31, 28, 18
	rgb 13, 10,  0


; applied to the Sing duel animation
Palette74::
	db 1
	gbpal SHADE_DARK, SHADE_WHITE, SHADE_LIGHT, SHADE_BLACK ; OBP0

	db 1

	rgb 11, 11, 11
	rgb 31, 31, 30
	rgb 31, 31, 30
	rgb  5,  2,  0


; applied to the Supersonic duel animation
Palette75::
	db 1
	gbpal SHADE_DARK, SHADE_WHITE, SHADE_LIGHT, SHADE_BLACK ; OBP0

	db 1

	rgb  0,  0,  0
	rgb 31, 31, 23
	rgb 26, 26,  4
	rgb 16,  3,  0


; applied to the Petal Dance duel animation
Palette76::
	db 1
	gbpal SHADE_DARK, SHADE_WHITE, SHADE_LIGHT, SHADE_BLACK ; OBP0

	db 1

	rgb 11, 11, 11
	rgb 31, 28, 31
	rgb 31, 22, 29
	rgb 19,  8, 12


; applied to the Protect duel animation
Palette77::
	db 1
	gbpal SHADE_DARK, SHADE_WHITE, SHADE_LIGHT, SHADE_BLACK ; OBP0

	db 1

	rgb  0,  0,  0
	rgb 31, 31, 23
	rgb 26, 26,  4
	rgb  6,  7,  0


; applied to the Barrier duel animation
Palette78::
	db 1
	gbpal SHADE_DARK, SHADE_WHITE, SHADE_LIGHT, SHADE_BLACK ; OBP0

	db 1

	rgb 11, 11, 11
	rgb 31, 31, 28
	rgb 13, 23, 30
	rgb  1, 11,  8


; applied to the Speed duel animation
Palette79::
	db 1
	gbpal SHADE_DARK, SHADE_WHITE, SHADE_DARK, SHADE_BLACK ; OBP0

	db 1

	rgb 11, 11, 11
	rgb 30, 31, 31
	rgb  8,  8, 12
	rgb  0,  0,  5


; applied to the Whirlwind duel animations
Palette80::
	db 1
	gbpal SHADE_DARK, SHADE_WHITE, SHADE_LIGHT, SHADE_BLACK ; OBP0

	db 1

	rgb 11, 11, 11
	rgb 27, 29, 31
	rgb 18, 20, 31
	rgb  8,  4, 10


; applied to the Cry duel animation
Palette81::
	db 1
	gbpal SHADE_DARK, SHADE_WHITE, SHADE_WHITE, SHADE_BLACK ; OBP0

	db 1

	rgb 11, 11, 11
	rgb 31, 31, 30
	rgb 18, 26, 30
	rgb  0,  0,  3


; applied to the Question Mark duel animation
Palette82::
	db 1
	gbpal SHADE_DARK, SHADE_WHITE, SHADE_LIGHT, SHADE_BLACK ; OBP0

	db 1

	rgb 11, 11, 11
	rgb 31, 31, 30
	rgb 31,  4,  4
	rgb 12,  2,  0


; applied to the Selfdestruct/Explosion duel animations
Palette83::
	db 1
	gbpal SHADE_DARK, SHADE_WHITE, SHADE_LIGHT, SHADE_BLACK ; OBP0

	db 1

	rgb 11, 11, 11
	rgb 31, 31, 26
	rgb 23, 21, 22
	rgb  3,  3,  3


; applied to the Heal duel animations
Palette84::
	db 1
	gbpal SHADE_DARK, SHADE_WHITE, SHADE_LIGHT, SHADE_BLACK ; OBP0

	db 1

	rgb  0,  0,  0
	rgb 31, 31, 31
	rgb 26, 26,  4
	rgb  6,  7,  0


; applied to the Drain duel animation
Palette85::
	db 1
	gbpal SHADE_DARK, SHADE_WHITE, SHADE_DARK, SHADE_BLACK ; OBP0

	db 1

	rgb  0,  0,  0
	rgb 29, 24, 24
	rgb 17,  5,  5
	rgb  6,  7,  0


; applied to the Dark Gas duel animation
Palette86::
	db 1
	gbpal SHADE_DARK, SHADE_LIGHT, SHADE_DARK, SHADE_BLACK ; OBP0

	db 1

	rgb 11, 11, 11
	rgb 25, 23, 23
	rgb 14, 13, 13
	rgb  3,  3,  3


; applied to the Bench Glow duel animation
Palette87::
	db 1
	gbpal SHADE_DARK, SHADE_WHITE, SHADE_LIGHT, SHADE_BLACK ; OBP0

	db 1

	rgb  0,  0,  0
	rgb 31, 31,  7
	rgb 31, 24,  6
	rgb 11,  3,  0


; applied to the Expand duel animation
Palette88::
	db 1
	gbpal SHADE_DARK, SHADE_WHITE, SHADE_LIGHT, SHADE_BLACK ; OBP0

	db 1

	rgb  0,  0,  0
	rgb 31, 31, 31
	rgb 20, 20, 16
	rgb  6,  7,  0


; applied to the Cat Punch duel animation
Palette89::
	db 1
	gbpal SHADE_DARK, SHADE_WHITE, SHADE_DARK, SHADE_BLACK ; OBP0

	db 1

	rgb 28, 28, 24
	rgb 31, 31,  0
	rgb 31, 17,  0
	rgb  9,  3,  0


; applied to the Thunder Wave duel animation
Palette90::
	db 1
	gbpal SHADE_DARK, SHADE_WHITE, SHADE_LIGHT, SHADE_BLACK ; OBP0

	db 1

	rgb  0,  0,  0
	rgb 31, 31, 31
	rgb 20, 20, 16
	rgb  6,  7,  0


; applied to the deck animations (e.g. drawing a card, shuffling)
Palette91::
	db 1
	gbpal SHADE_DARK, SHADE_LIGHT, SHADE_DARK, SHADE_BLACK ; OBP0

	db 1

	rgb 16, 16, 20
	rgb 28, 28, 24
	rgb 12, 12, 20
	rgb  0,  0,  0


; applied to the coin toss animations
Palette92::
	db 1
	gbpal SHADE_WHITE, SHADE_LIGHT, SHADE_DARK, SHADE_BLACK ; OBP0

	db 1

	rgb 28, 28, 24
	rgb 31, 19,  0
	rgb 23, 10,  0
	rgb  0,  0,  0


; applied to the duel results screen animations
Palette93::
	db 1
	gbpal SHADE_LIGHT, SHADE_DARK, SHADE_WHITE, SHADE_BLACK ; OBP0

	db 1

	rgb 20, 20, 16
	rgb 31,  0,  0
	rgb 31, 31,  0
	rgb  0,  0,  0


; palettes that are used for the black/red gradient scene
Palette94::
	db 0
	db 8

	rgb  0,  0,  0
	rgb  1,  0,  0
	rgb  2,  0,  0
	rgb  3,  0,  0

	rgb  4,  0,  0
	rgb  5,  0,  0
	rgb  6,  0,  0
	rgb  7,  0,  0

	rgb  8,  0,  0
	rgb  9,  0,  0
	rgb 10,  0,  0
	rgb 11,  0,  0

	rgb 12,  0,  0
	rgb 13,  0,  0
	rgb 14,  0,  0
	rgb 15,  0,  0

	rgb 16,  0,  0
	rgb 17,  0,  0
	rgb 18,  0,  0
	rgb 19,  0,  0

	rgb 20,  0,  0
	rgb 21,  0,  0
	rgb 22,  0,  0
	rgb 23,  0,  0

	rgb 24,  0,  0
	rgb 25,  0,  0
	rgb 26,  0,  0
	rgb 27,  0,  0

	rgb 28,  0,  0
	rgb 29,  0,  0
	rgb 30,  0,  0
	rgb 31,  0,  0


; palettes that are used for the white/red gradient scene
Palette95::
	db 0
	db 8

	rgb 31, 31, 31
	rgb 31, 30, 30
	rgb 31, 29, 29
	rgb 31, 28, 28

	rgb 31, 27, 27
	rgb 31, 26, 26
	rgb 31, 25, 25
	rgb 31, 24, 24

	rgb 31, 23, 23
	rgb 31, 22, 22
	rgb 31, 21, 21
	rgb 31, 20, 20

	rgb 31, 19, 19
	rgb 31, 18, 18
	rgb 31, 17, 17
	rgb 31, 16, 16

	rgb 31, 15, 15
	rgb 31, 14, 14
	rgb 31, 13, 13
	rgb 31, 12, 12

	rgb 31, 11, 11
	rgb 31, 10, 10
	rgb 31,  9,  9
	rgb 31,  8,  8

	rgb 31,  7,  7
	rgb 31,  6,  6
	rgb 31,  5,  5
	rgb 31,  4,  4

	rgb 31,  3,  3
	rgb 31,  2,  2
	rgb 31,  1,  1
	rgb 31,  0,  0


; palettes that are used for the black/green gradient scene
Palette96::
	db 0
	db 8

	rgb  0,  0,  0
	rgb  0,  1,  0
	rgb  0,  2,  0
	rgb  0,  3,  0

	rgb  0,  4,  0
	rgb  0,  5,  0
	rgb  0,  6,  0
	rgb  0,  7,  0

	rgb  0,  8,  0
	rgb  0,  9,  0
	rgb  0, 10,  0
	rgb  0, 11,  0

	rgb  0, 12,  0
	rgb  0, 13,  0
	rgb  0, 14,  0
	rgb  0, 15,  0

	rgb  0, 16,  0
	rgb  0, 17,  0
	rgb  0, 18,  0
	rgb  0, 19,  0

	rgb  0, 20,  0
	rgb  0, 21,  0
	rgb  0, 22,  0
	rgb  0, 23,  0

	rgb  0, 24,  0
	rgb  0, 25,  0
	rgb  0, 26,  0
	rgb  0, 27,  0

	rgb  0, 28,  0
	rgb  0, 29,  0
	rgb  0, 30,  0
	rgb  0, 31,  0


; palettes that are used for the white/green gradient scene
Palette97::
	db 0
	db 8

	rgb 31, 31, 31
	rgb 30, 31, 30
	rgb 29, 31, 29
	rgb 28, 31, 28

	rgb 27, 31, 27
	rgb 26, 31, 26
	rgb 25, 31, 25
	rgb 24, 31, 24

	rgb 23, 31, 23
	rgb 22, 31, 22
	rgb 21, 31, 21
	rgb 20, 31, 20

	rgb 19, 31, 19
	rgb 18, 31, 18
	rgb 17, 31, 17
	rgb 16, 31, 16

	rgb 15, 31, 15
	rgb 14, 31, 14
	rgb 13, 31, 13
	rgb 12, 31, 12

	rgb 11, 31, 11
	rgb 10, 31, 10
	rgb  9, 31,  9
	rgb  8, 31,  8

	rgb  7, 31,  7
	rgb  6, 31,  6
	rgb  5, 31,  5
	rgb  4, 31,  4

	rgb  3, 31,  3
	rgb  2, 31,  2
	rgb  1, 31,  1
	rgb  0, 31,  0


; palettes that are used for the color wheel scene
Palette98::
	db 0
	db 8

	rgb 31, 31, 31
	rgb 31,  0,  0
	rgb 31,  6,  0
	rgb 31, 12,  0

	rgb 31, 19,  0
	rgb 31, 25,  0
	rgb 31, 31,  0
	rgb 25, 31,  0

	rgb 19, 31,  0
	rgb 12, 31,  0
	rgb  6, 31,  0
	rgb  0, 31,  0

	rgb  0, 31,  6
	rgb  0, 31, 12
	rgb  0, 31, 19
	rgb  0, 31, 25

	rgb  0, 31, 31
	rgb  0, 25, 31
	rgb  0, 19, 31
	rgb  0, 12, 31

	rgb  0,  6, 31
	rgb  0,  0, 31
	rgb  6,  0, 31
	rgb 12,  0, 31

	rgb 19,  0, 31
	rgb 25,  0, 31
	rgb 31,  0, 31
	rgb 31,  0, 25

	rgb 31,  0, 19
	rgb 31,  0, 12
	rgb 31,  0,  6
	rgb  0,  0,  0


; palettes that are used for the color test scene
Palette99::
	db 0
	db 8

	rgb 31, 31, 31
	rgb 15, 15, 15
	rgb 28, 28, 28
	rgb  0,  0, 15

	rgb 29, 29, 29
	rgb 13, 13, 13
	rgb 31, 31,  0
	rgb 31, 31, 31

	rgb 27, 27, 27
	rgb 11, 11, 11
	rgb  0, 31, 31
	rgb 15,  0, 15

	rgb 25, 25, 25
	rgb  9,  9,  9
	rgb  0, 31,  0
	rgb  0,  0,  0

	rgb 23, 23, 23
	rgb  7,  7,  7
	rgb 31,  0, 31
	rgb  4,  0,  0

	rgb 21, 21, 21
	rgb  5,  5,  5
	rgb 31,  0,  0
	rgb  0,  4,  0

	rgb 19, 19, 19
	rgb  3,  3,  3
	rgb  0,  0, 31
	rgb  0,  0,  4

	rgb 17, 17, 17
	rgb  1,  1,  1
	rgb  0,  0,  0
	rgb  0, 31,  0


; palettes that are used for the 2nd Japanese Title Screen scene
Palette100::
	db 0
	db 8

	rgb 31, 31, 31
	rgb 31, 25,  4
	rgb  5,  5, 31
	rgb  1,  0,  5

	rgb 31, 31, 31
	rgb 31, 25,  4
	rgb 31,  0,  0
	rgb  1,  0,  5

	rgb 31, 31, 31
	rgb 31,  2,  4
	rgb  5,  5, 31
	rgb  1,  0,  5

	rgb 31, 31, 31
	rgb 25, 24, 31
	rgb  5,  5, 31
	rgb  1,  0,  5

	rgb 31, 31, 31
	rgb  7, 23, 31
	rgb  5, 19,  6
	rgb  1,  0,  5

	rgb 31, 31, 31
	rgb 27, 18, 31
	rgb 23, 11,  7
	rgb  1,  0,  5

	rgb 31, 31, 31
	rgb 31, 26,  4
	rgb  5,  5, 31
	rgb 31,  0,  0

	rgb  0,  0,  0
	rgb 31,  0,  0
	rgb 31, 13,  0
	rgb 31, 31,  0


; palettes that are used for the Colosseum booster pack scene
Palette101::
	db 0
	db 7

	rgb 28, 28, 28
	rgb 28, 28,  0
	rgb 28, 16,  0
	rgb  4,  0,  0

	rgb 28, 28, 28
	rgb  0,  0, 28
	rgb  0,  0,  4
	rgb  4,  0,  0

	rgb 28, 28, 28
	rgb 24,  4,  0
	rgb 28, 16,  0
	rgb  4,  0,  0

	rgb 28, 28, 28
	rgb 28, 28,  0
	rgb 24,  4,  0
	rgb  4,  0,  0

	rgb 28, 28, 28
	rgb  4, 12,  0
	rgb 28, 16,  0
	rgb  4,  0,  0

	rgb  0,  0,  0
	rgb 28,  0,  0
	rgb 28, 12,  0
	rgb 28, 28,  0

	rgb  0,  0,  0
	rgb 28,  0,  0
	rgb 28, 12,  0
	rgb 28, 28,  0


; palettes that are used for the Evolution booster pack scene
Palette102::
	db 0
	db 7

	rgb 28, 28, 28
	rgb 28, 24, 16
	rgb 28,  8,  4
	rgb  4,  0,  0

	rgb 28, 28, 28
	rgb  0, 20, 28
	rgb  0,  0, 28
	rgb  0,  0,  8

	rgb 28, 28, 28
	rgb  4, 16, 12
	rgb 28,  8,  4
	rgb  4,  0,  0

	rgb  0,  0,  0
	rgb 28,  0,  0
	rgb 28, 12,  0
	rgb 28, 28,  0

	rgb  0,  0,  0
	rgb 28,  0,  0
	rgb 28, 12,  0
	rgb 28, 28,  0

	rgb  0,  0,  0
	rgb 28,  0,  0
	rgb 28, 12,  0
	rgb 28, 28,  0

	rgb  0,  0,  0
	rgb 28,  0,  0
	rgb 28, 12,  0
	rgb 28, 28,  0


; palettes that are used for the Mystery booster pack scene
Palette103::
	db 0
	db 7

	rgb 28, 28, 28
	rgb 12, 24, 28
	rgb  0, 12, 24
	rgb  0,  0,  8

	rgb 28, 28, 28
	rgb  0,  4, 28
	rgb  0, 12, 24
	rgb  0,  0,  8

	rgb 28, 28, 28
	rgb 28, 28,  0
	rgb  8,  4,  0
	rgb  0,  0,  8

	rgb  0,  0,  0
	rgb 28,  0,  0
	rgb 28, 12,  0
	rgb 28, 28,  0

	rgb  0,  0,  0
	rgb 28,  0,  0
	rgb 28, 12,  0
	rgb 28, 28,  0

	rgb  0,  0,  0
	rgb 28,  0,  0
	rgb 28, 12,  0
	rgb 28, 28,  0

	rgb  0,  0,  0
	rgb 28,  0,  0
	rgb 28, 12,  0
	rgb 28, 28,  0


; palettes that are used for the Laboratory booster pack scene
Palette104::
	db 0
	db 7

	rgb 28, 28, 28
	rgb 21, 15, 31
	rgb 20,  0,  8
	rgb  4,  0,  0

	rgb 28, 28, 28
	rgb 10,  3, 30
	rgb 20,  0,  8
	rgb  4,  0,  0

	rgb 28, 28, 28
	rgb 31,  7,  6
	rgb 14,  0,  6
	rgb  4,  0,  0

	rgb  0,  0,  0
	rgb 28,  0,  0
	rgb 28, 12,  0
	rgb 28, 28,  0

	rgb  0,  0,  0
	rgb 28,  0,  0
	rgb 28, 12,  0
	rgb 28, 28,  0

	rgb  0,  0,  0
	rgb 28,  0,  0
	rgb 28, 12,  0
	rgb 28, 28,  0

	rgb  0,  0,  0
	rgb 28,  0,  0
	rgb 28, 12,  0
	rgb 28, 28,  0


; palettes that are used for the Base Set's booster pack scene (with Charizard artwork)
Palette105::
	db 0
	db 7

	rgb  0,  0,  4
	rgb 31, 18,  7
	rgb  4,  7, 15
	rgb 31, 24,  0

	rgb  0,  0,  4
	rgb 31, 18,  7
	rgb  4,  7, 15
	rgb 31, 28, 18

	rgb  0,  0,  4
	rgb 11, 17, 31
	rgb  4,  7, 15
	rgb 26, 30, 31

	rgb  0,  0,  4
	rgb 31, 18,  7
	rgb 18,  8,  4
	rgb 31, 28, 18

	rgb  0,  0,  4
	rgb 31, 18,  7
	rgb 25,  7,  0
	rgb 31, 31, 31

	rgb  0,  0,  4
	rgb 31, 18,  7
	rgb 18,  8,  4
	rgb  4,  7, 15

	rgb  0,  0,  4
	rgb 18,  8,  4
	rgb  4,  7, 15
	rgb 31, 24,  0


; palettes that are used for the Jungle set's booster pack scene (with Scyther artwork)
Palette106::
	db 0
	db 7

	rgb  8,  1,  1
	rgb 10, 23,  9
	rgb  7,  9, 18
	rgb 31, 26,  0

	rgb  8,  1,  1
	rgb 10, 23,  9
	rgb  5, 14,  4
	rgb 31, 26,  0

	rgb  8,  1,  1
	rgb  5, 14,  4
	rgb 24,  2,  1
	rgb 26, 26, 27

	rgb  8,  1,  1
	rgb 26, 26, 27
	rgb  5, 14,  4
	rgb 31, 26,  0

	rgb  8,  1,  1
	rgb 10, 23,  9
	rgb  5, 14,  4
	rgb 28, 31, 19

	rgb  8,  1,  1
	rgb 10, 23,  9
	rgb 24,  2,  1
	rgb 26, 26, 27

	rgb  0,  0,  0
	rgb 31,  0,  0
	rgb 31, 13,  0
	rgb 31, 31,  0


; palettes that are used for the Fossil set's booster pack scene (with Aerodactyl artwork)
Palette107::
	db 0
	db 7

	rgb  3,  1,  1
	rgb 30, 23, 20
	rgb 18, 12, 12
	rgb 25, 30, 31

	rgb  0,  0,  6
	rgb 30, 23, 20
	rgb  7,  7, 15
	rgb 31, 27,  0

	rgb  0,  0,  6
	rgb 30, 23, 20
	rgb 23,  2,  2
	rgb 30, 30, 30

	rgb  3,  1,  1
	rgb 30, 23, 20
	rgb 18, 12, 12
	rgb 31, 26,  0

	rgb  3,  1,  1
	rgb 30, 23, 20
	rgb 18, 12, 12
	rgb  6,  6, 15

	rgb  0,  0,  0
	rgb 31,  0,  0
	rgb 31, 13,  0
	rgb 31, 31,  0

	rgb  0,  0,  0
	rgb 31,  0,  0
	rgb 31, 13,  0
	rgb 31, 31,  0


; used for all of the booster pack scenes
Palette108::
	db 1
	gbpal SHADE_WHITE, SHADE_LIGHT, SHADE_DARK, SHADE_BLACK ; OBP0

	db 0


; used for the 2nd Japanese Title Screen scene
Palette109::
	db 1
	gbpal SHADE_WHITE, SHADE_LIGHT, SHADE_DARK, SHADE_BLACK ; OBP0

	db 0


; used for the color palette scene
Palette110::
	db $00, $00


; palettes that are used for the link cable scenes
Palette111::
	db 1
	gbpal SHADE_WHITE, SHADE_LIGHT, SHADE_DARK, SHADE_BLACK ; OBP0

	db 8

	rgb 28, 28, 24
	rgb 20, 20, 16
	rgb  8,  8,  8
	rgb  0,  0,  0

	rgb 28, 28, 24
	rgb 31, 24,  0
	rgb  3,  3,  8
	rgb  0,  0,  0

	rgb 28, 28, 24
	rgb 25, 14,  0
	rgb  4,  4, 10
	rgb  0,  0,  0

	rgb  0,  0,  0
	rgb 31,  0,  0
	rgb 31, 13,  0
	rgb 31, 31,  0

	rgb 28, 28, 24
	rgb 30, 29,  0
	rgb 31, 13,  0
	rgb  0,  0,  0

	rgb 28, 28, 24
	rgb 31, 31, 31
	rgb 29, 16, 16
	rgb 29,  0,  0

	rgb  0,  0,  0
	rgb 31,  0,  0
	rgb 31, 13,  0
	rgb 31, 31,  0

	rgb  0,  0,  0
	rgb 31,  0,  0
	rgb 31, 13,  0
	rgb 31, 31,  0


; palettes that are used for the Game Boy Printer scenes
Palette112::
	db 1
	gbpal SHADE_WHITE, SHADE_LIGHT, SHADE_DARK, SHADE_BLACK ; OBP0

	db 8

	rgb 28, 28, 24
	rgb 20, 20, 16
	rgb  8,  8,  8
	rgb  0,  0,  0

	rgb 23, 18, 22
	rgb 17,  2,  7
	rgb  4,  4,  7
	rgb  0,  0,  0

	rgb 28, 28, 24
	rgb 25, 14,  0
	rgb  3,  3,  8
	rgb  0,  0,  0

	rgb 28, 28, 24
	rgb 31, 24,  0
	rgb  3,  3,  8
	rgb  0,  0,  0

	rgb 28, 28, 24
	rgb 30, 29,  0
	rgb 31, 13,  0
	rgb  0,  0,  0

	rgb 28, 28, 24
	rgb 16, 12, 17
	rgb  4,  4,  7
	rgb  0,  0,  0

	rgb 23, 18, 22
	rgb 16, 12, 17
	rgb  4,  4,  7
	rgb  0,  0,  0

	rgb 28, 28, 24
	rgb 31, 24,  0
	rgb  3,  3,  8
	rgb 25, 14,  0


; palettes that are used for the CardPop! scenes
Palette113::
	db 1
	gbpal SHADE_WHITE, SHADE_LIGHT, SHADE_DARK, SHADE_BLACK ; OBP0

	db 8

	rgb 28, 28, 24
	rgb 20, 20, 16
	rgb  8,  8,  8
	rgb  0,  0,  0

	rgb 28, 28, 24
	rgb 31, 24,  0
	rgb  3,  3,  8
	rgb  0,  0,  0

	rgb 28, 28, 24
	rgb 25, 14,  0
	rgb  3,  3,  8
	rgb  0,  0,  0

	rgb  3,  3,  8
	rgb 31, 24,  0
	rgb 25, 14,  0
	rgb  0,  0,  0

	rgb 28, 28, 24
	rgb 30, 29,  0
	rgb 31, 13,  0
	rgb  0,  0,  0

	rgb 28, 28, 24
	rgb 31, 24,  0
	rgb 25, 14,  0
	rgb  0,  0,  0

	rgb 28, 28, 24
	rgb 31, 27,  0
	rgb 31,  0,  0
	rgb  0,  0,  0

	rgb  0,  0,  0
	rgb 31,  0,  0
	rgb 31, 13,  0
	rgb 31, 31,  0


; palettes that are used for some of the link cable scenes
Palette114::
	db 2
	gbpal SHADE_WHITE, SHADE_LIGHT, SHADE_DARK, SHADE_BLACK ; OBP0
	gbpal SHADE_BLACK, SHADE_WHITE, SHADE_WHITE, SHADE_WHITE ; OBP1

	db 4

	rgb  0,  0,  0
	rgb 31, 31, 31
	rgb 29, 16, 16
	rgb 29,  0,  0

	rgb  0,  0,  0
	rgb  0, 31, 31
	rgb 30, 30, 30
	rgb  0,  0, 29

	rgb  0,  0,  0
	rgb 31,  0,  0
	rgb 31, 13,  0
	rgb 31, 31,  0

	rgb  0,  0,  0
	rgb 31,  0,  0
	rgb 31, 13,  0
	rgb 31, 31,  0


; palettes that are used for the Game Boy Printer scenes
Palette115::
	db 2
	gbpal SHADE_WHITE, SHADE_LIGHT, SHADE_DARK, SHADE_BLACK ; OBP0
	gbpal SHADE_BLACK, SHADE_WHITE, SHADE_WHITE, SHADE_WHITE ; OBP1

	db 4

	rgb 28, 28, 24
	rgb 31,  0,  0
	rgb  0, 31,  0
	rgb  0, 14,  0

	rgb 28, 28, 24
	rgb 31,  0,  0
	rgb 31, 13,  0
	rgb 29,  0,  0

	rgb  0,  0,  0
	rgb 31,  0,  0
	rgb 31, 13,  0
	rgb 31, 31,  0

	rgb  0,  0,  0
	rgb 31,  0,  0
	rgb 31, 13,  0
	rgb 31, 31,  0


; palettes that are used for the CardPop! scenes
Palette116::
	db 2
	gbpal SHADE_DARK, SHADE_WHITE, SHADE_LIGHT, SHADE_BLACK ; OBP0
	gbpal SHADE_WHITE, SHADE_LIGHT, SHADE_DARK, SHADE_BLACK ; OBP1

	db 4

	rgb 28, 28, 24
	rgb 31, 31, 31
	rgb  0, 31, 31
	rgb  0, 13, 31

	rgb 28, 28, 24
	rgb 31, 31,  0
	rgb 31, 31,  0
	rgb 31,  0,  0

	rgb  0,  0,  0
	rgb 31,  0,  0
	rgb 31, 13,  0
	rgb 31, 31,  0

	rgb  0,  0,  0
	rgb 31,  0,  0
	rgb 31, 13,  0
	rgb 31, 31,  0


; applied to the OAM logo in the booster pack scenes
Palette117::
	db 0
	db 1

	rgb 27, 27, 24
	rgb 31, 31,  0
	rgb 31,  0,  0
	rgb  0,  8, 19


; unreferenced?
Palette118::
	db 0
	db 6

	rgb 28, 28, 24
	rgb  4, 30, 20
	rgb  8, 16,  8
	rgb  0,  0,  0

	rgb 28, 28, 24
	rgb 31, 11, 10
	rgb 19,  9,  8
	rgb  0,  0,  0

	rgb 28, 28, 24
	rgb  6, 20, 28
	rgb  8,  8, 31
	rgb  0,  0,  0

	rgb 28, 28, 24
	rgb 31, 21,  0
	rgb 24, 13,  8
	rgb  0,  0,  0

	rgb 28, 28, 24
	rgb 23, 14,  6
	rgb 15, 15,  0
	rgb  0,  0,  0

	rgb 28, 28, 24
	rgb 29, 11, 30
	rgb 19,  0, 25
	rgb  0,  0,  0


; applied to Mark's duelist portrait
Palette119::
	db 0
	db 1

	rgb 31, 28, 23 ; light peach, used for Mark's skin/T-shirt and highlights
	rgb 28, 16, 12 ; dark peach, used for shading Mark's skin
	rgb 28,  4,  8 ; red, used for Mark's bandana/outer shirt and the background
	rgb  0,  0,  8 ; blue/black, used for Mark's hair and outlines


; applied to a link opponent's duel portrait
Palette120::
	db 0
	db 1

	rgb 31, 28, 23 ; light peach, used for player's skin and highlights
	rgb 27, 16,  9 ; light brown, used for shading
	rgb  0, 17,  0 ; green, used for player's clothing and the background
	rgb  0,  0,  0 ; black, used for player's hair and outlines


; applied to Ronald's duelist portrait
Palette121::
	db 0
	db 1

	rgb 31, 28, 23 ; light peach, used for Ronald's skin/T-shirt and highlights
	rgb 28, 16, 12 ; dark peach, used for shading
	rgb  4,  8, 28 ; blue, used for Ronald's hair and the background
	rgb  0,  0, 12 ; dark blue, used for Ronald's shirt and outlines


; applied to Tech Sam's duelist portrait
Palette122::
	db 0
	db 1

	rgb 24, 28, 24
	rgb 12, 20, 12
	rgb  4, 12,  8
	rgb  0,  4,  0


; applied to Strange Life-form Imakuni?'s duelist portrait
Palette123::
	db 0
	db 1

	rgb 28, 28, 24
	rgb 28, 20,  4
	rgb 20,  8,  0
	rgb  4,  0,  0


; applied to Grass Club Master Nikki's duelist portrait
Palette124::
	db 0
	db 1

	rgb 21, 30, 17
	rgb 14, 22,  8
	rgb  8, 12,  0
	rgb  5,  0,  0


; applied to Science Club Master Rick's duelist portrait
Palette125::
	db 0
	db 1

	rgb 21, 30, 17
	rgb 14, 22,  8
	rgb  8, 12,  0
	rgb  5,  0,  0


; applied to Fire Club Master Ken's duelist portrait
Palette126::
	db 0
	db 1

	rgb 28, 28, 24
	rgb 28, 20, 12
	rgb 28,  4,  0
	rgb  5,  0,  0


; applied to Water Club Master Amy's duelist portrait
Palette127::
	db 0
	db 1

	rgb 24, 31, 31
	rgb  0, 26, 31
	rgb  5,  5, 29
	rgb  5,  0,  0


; applied to Lightning Club Master Isaac's duelist portrait
Palette128::
	db 0
	db 1

	rgb 31, 31, 12
	rgb 31, 21,  0
	rgb 14, 11,  0
	rgb  3,  1,  1


; applied to Fighting Club Master Mitch's duelist portrait
Palette129::
	db 0
	db 1

	rgb 28, 28, 24
	rgb 28, 20,  7
	rgb 28, 10,  0
	rgb  4,  1,  0


; applied to Rock Club Master Gene's duelist portrait
Palette130::
	db 0
	db 1

	rgb 28, 28, 24
	rgb 25, 17,  8
	rgb 18,  8,  0
	rgb  4,  0,  0


; applied to Psychic Club Master Murray's duelist portrait
Palette131::
	db 0
	db 1

	rgb 25, 18, 31
	rgb 17,  9, 24
	rgb 10,  0, 18
	rgb  5,  0,  0


; applied to Grand Master Courtney's duelist portrait
Palette132::
	db 0
	db 1

	rgb 28, 28, 24
	rgb 28, 20, 12
	rgb 28,  4,  0
	rgb  5,  0,  0


; applied to Grand Master Steve's duelist portrait
Palette133::
	db 0
	db 1

	rgb 31, 31, 25
	rgb 31, 23,  0
	rgb 28, 12,  0
	rgb  2,  2,  0


; applied to Grand Master Jack's duelist portrait
Palette134::
	db 0
	db 1

	rgb 24, 31, 31
	rgb  0, 26, 31
	rgb  5,  5, 29
	rgb  0,  0,  2


; applied to Grand Master Rod's duelist portrait
Palette135::
	db 0
	db 1

	rgb 20, 31, 20
	rgb  9, 24, 14
	rgb  0, 17, 10
	rgb  0,  3,  0


; applied to Science Club Member Joseph's duelist portrait
Palette136::
	db 0
	db 1

	rgb 28, 28, 28
	rgb 20, 24, 16
	rgb  0, 12,  0
	rgb  0,  1,  0


; applied to Science Club Member David's duelist portrait
Palette137::
	db 0
	db 1

	rgb 28, 28, 28
	rgb 20, 24, 16
	rgb  0, 12,  0
	rgb  0,  1,  0


; applied to Science Club Member Erik's duelist portrait
Palette138::
	db 0
	db 1

	rgb 28, 28, 28
	rgb 20, 24, 16
	rgb  0, 12,  0
	rgb  0,  1,  0


; applied to Fire Club Member John's duelist portrait
Palette139::
	db 0
	db 1

	rgb 28, 28, 24
	rgb 28, 20,  8
	rgb 28,  4,  0
	rgb  4,  0,  0


; applied to Fire Club Member Adam's duelist portrait
Palette140::
	db 0
	db 1

	rgb 28, 28, 24
	rgb 28, 20,  8
	rgb 28,  4,  0
	rgb  4,  0,  0


; applied to Fire Club Member Jonathan's duelist portrait
Palette141::
	db 0
	db 1

	rgb 28, 28, 24
	rgb 28, 20,  8
	rgb 28,  4,  0
	rgb  4,  0,  0


; applied to Water Club Member Joshua's duelist portrait
Palette142::
	db 0
	db 1

	rgb 20, 28, 28
	rgb 12, 20, 24
	rgb  8,  8, 20
	rgb  0,  0,  4


; applied to Lightning Club Member Nicholas's duelist portrait
Palette143::
	db 0
	db 1

	rgb 28, 28, 12
	rgb 24, 16,  8
	rgb  8,  8,  4
	rgb  2,  1,  1


; applied to Lightning Club Member Brandon's duelist portrait
Palette144::
	db 0
	db 1

	rgb 28, 28, 12
	rgb 24, 16,  8
	rgb  8,  8,  4
	rgb  2,  1,  1


; applied to Rock Club Member Matthew's duelist portrait
Palette145::
	db 0
	db 1

	rgb 24, 24, 24
	rgb 20, 16, 12
	rgb 24,  8,  4
	rgb  2,  0,  0


; applied to Rock Club Member Ryan's duelist portrait
Palette146::
	db 0
	db 1

	rgb 24, 24, 24
	rgb 20, 16, 12
	rgb 24,  8,  4
	rgb  2,  0,  0


; applied to Rock Club Member Andrew's duelist portrait
Palette147::
	db 0
	db 1

	rgb 24, 24, 24
	rgb 20, 16, 12
	rgb 24,  8,  4
	rgb  2,  0,  0


; applied to Fighting Club Member Chris's duelist portrait
Palette148::
	db 0
	db 1

	rgb 28, 24, 24
	rgb 20, 12, 12
	rgb 12,  4,  8
	rgb  2,  0,  0


; applied to Fighting Club Member Michael's duelist portrait
Palette149::
	db 0
	db 1

	rgb 28, 24, 24
	rgb 20, 12, 12
	rgb 12,  4,  8
	rgb  2,  0,  0


; applied to Psychic Club Member Daniel's duelist portrait
Palette150::
	db 0
	db 1

	rgb 28, 20, 24
	rgb 20, 16, 16
	rgb 16,  8, 12
	rgb  2,  1,  1


; applied to Psychic Club Member Robert's duelist portrait
Palette151::
	db 0
	db 1

	rgb 28, 20, 24
	rgb 20, 16, 16
	rgb 16,  8, 12
	rgb  2,  1,  1


; applied to Grass Club Member Brittany's duelist portrait
Palette152::
	db 0
	db 1

	rgb 24, 28, 16
	rgb 16, 20, 12
	rgb  8, 16,  4
	rgb  0,  2,  0


; applied to Grass Club Member Kristin's duelist portrait
Palette153::
	db 0
	db 1

	rgb 24, 28, 16
	rgb 16, 20, 12
	rgb  8, 16,  4
	rgb  0,  2,  0


; applied to Grass Club Member Heather's duelist portrait
Palette154::
	db 0
	db 1

	rgb 24, 28, 16
	rgb 16, 20, 12
	rgb  8, 16,  4
	rgb  0,  2,  0


; applied to Water Club Member Sara's duelist portrait
Palette155::
	db 0
	db 1

	rgb 20, 28, 28
	rgb 12, 20, 24
	rgb  8,  8, 20
	rgb  0,  0,  2


; applied to Water Club Member Amanda's duelist portrait
Palette156::
	db 0
	db 1

	rgb 20, 28, 28
	rgb 12, 20, 24
	rgb  8,  8, 20
	rgb  0,  0,  2


; applied to Lightning Club Member Jennifer's duelist portrait
Palette157::
	db 0
	db 1

	rgb 28, 28, 12
	rgb 24, 16,  8
	rgb  8,  8,  4
	rgb  2,  1,  1


; applied to Fighting Club Member Jessica's duelist portrait
Palette158::
	db 0
	db 1

	rgb 28, 24, 24
	rgb 20, 12, 12
	rgb 12,  4,  8
	rgb  1,  0,  0


; applied to Psychic Club Member Stephanie's duelist portrait
Palette159::
	db 0
	db 1

	rgb 28, 20, 24
	rgb 20, 16, 16
	rgb 16,  8, 12
	rgb  2,  1,  1


; applied to Tech Aaron's duelist portrait
Palette160::
	db 0
	db 1

	rgb 29, 22, 25
	rgb 31, 12, 16
	rgb 22,  0, 10
	rgb  3,  0,  2


; applied to Mint's duelist portrait
Palette161::
	db 0
	db 1

	rgb 31, 28, 23 ; light peach, used for Mint's skin and highlights
	rgb 27, 16,  9 ; light brown, used for Mint's hair and shading
	rgb  0, 12, 31 ; blue, used for Mint's clothing and the background
	rgb  5,  0,  0 ; dark brown, used for shading Mint's hair and outlines
