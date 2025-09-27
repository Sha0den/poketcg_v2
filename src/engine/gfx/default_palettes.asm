; sets the default game palettes for all three systems
; BGP and OBP0 on DMG
; SGB0 and SGB1 on SGB
; BGP0 to BGP5 and OBP1 on CGB
_SetDefaultConsolePalettes::
	ld a, [wConsole]
	cp CONSOLE_SGB
	jr z, .sgb
	cp CONSOLE_CGB
	jr z, .cgb
	ldgbpal a, SHADE_WHITE, SHADE_LIGHT, SHADE_DARK, SHADE_BLACK
	ld [wOBP0], a
	ld [wBGP], a
	ld a, $01 ; equivalent to FLUSH_ONE_PAL
	ld [wFlushPaletteFlags], a
	ret
.cgb
	ld a, $04
	ld [wTextBoxFrameType], a
	ld de, CGBDefaultPalettes
	ld hl, wBackgroundPalettesCGB
	ld c, 5 palettes
	call CopyNBytesFromDEToHL
	ld de, CGBDefaultPalettes
	ld hl, wObjectPalettesCGB
	ld c, PAL_SIZE
	call CopyNBytesFromDEToHL
	jp FlushAllPalettes
.sgb
	ld a, $04
	ld [wTextBoxFrameType], a
	ld a, PAL01 << 3 + 1
	ld hl, wTempSGBPacket
	push hl
	ld [hli], a
	ld de, Pal01Packet_Default
	ld c, $0e
	call CopyNBytesFromDEToHL
	ld [hl], c
	pop hl
	jp SendSGB


; no entries for background palettes 5-7 or object palettes 1-7
CGBDefaultPalettes:
; BGP0 and OBP0
	rgb 28, 28, 24 ; [e0e0c0] (cream, background color)
	rgb 21, 21, 16 ; [a8a880] (darker cream)
	rgb 10, 10, 8  ; [505040] (even darker cream)
	rgb 0, 0, 0    ; [000000] (black)
; BGP1
	rgb 28, 28, 24 ; [e0e0c0] (cream, background color)
	rgb 30, 29, 0  ; [f0e800] (yellow, Lightning Energy icon color)
	rgb 30, 3, 0   ; [f01800] (red, Fire Energy icon color)
	rgb 0, 0, 0    ; [000000] (black)
; BGP2
	rgb 28, 28, 24 ; [e0e0c0] (cream, background color)
	rgb 0, 18, 0   ; [009000] (green, Grass Energy icon color)
	rgb 12, 11, 20 ; [6058a0] (blue, Water Energy icon color)
	rgb 0, 0, 0    ; [000000] (black)
; BGP3
	rgb 28, 28, 24 ; [e0e0c0] (cream, background color)
	rgb 22, 0, 22  ; [b000b0] (magenta, Psychic Energy icon color)
	rgb 27, 7, 3   ; [d83818] (dark orange, Fighting Energy icon color)
	rgb 0, 0, 0    ; [000000] (black)
; BGP4
	rgb 28, 28, 24 ; [e0e0c0] (cream, background color)
	rgb 26, 10, 0  ; [d05000] (orange, menu border color)
	rgb 28, 0, 0   ; [e00000] (red, menu border color)
	rgb 0, 0, 0    ; [000000] (black)


; first and last byte of the packet not contained here (see SetDefaultConsolePalettes.sgb)
Pal01Packet_Default:
; SGB0
	rgb 28, 28, 24
	rgb 21, 21, 16
	rgb 10, 10, 8
	rgb 0, 0, 0
; SGB1
	rgb 26, 10, 0
	rgb 28, 0, 0
	rgb 0, 0, 0
