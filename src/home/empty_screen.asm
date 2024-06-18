; initializes the screen by emptying the tilemap.
; used during screen transitions.
EmptyScreen::
	call DisableLCD
	call FillTileMap
	xor a
	ld [wDuelDisplayedScreen], a
	ld a, [wConsole]
	cp CONSOLE_SGB
	ret nz
	call EnableLCD
	ld hl, AttrBlkPacket_EmptyScreen
	call SendSGB
	jp DisableLCD

AttrBlkPacket_EmptyScreen::
	sgb ATTR_BLK, 1 ; sgb_command, length
	db 1 ; number of data sets
	; Control Code, Color Palette Designation, X1, Y1, X2, Y2
	db ATTR_BLK_CTRL_INSIDE + ATTR_BLK_CTRL_LINE, 0 << 0 + 0 << 2, 0, 0, 19, 17 ; data set 1
	ds 6 ; data set 2
	ds 2 ; data set 3
