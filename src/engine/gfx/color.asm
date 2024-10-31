; loads wConsolePaletteData depending on the console
; every entry in the list is $00
; preserves all registers except af
LoadConsolePaletteData:
	push hl
	ld a, [wConsole]
	add LOW(.PaletteDataTable)
	ld l, a
	ld a, HIGH(.PaletteDataTable)
	adc 0
	ld h, a
	ld a, [hl]
	ld [wConsolePaletteData], a
	xor a
	ld [wd317], a
	pop hl
	ret

.PaletteDataTable:
	db $00 ; CONSOLE_DMG
	db $00 ; CONSOLE_SGB
	db $00 ; CONSOLE_CGB


FadeScreenToWhite:
	ld a, [wLCDC]
	bit LCDC_ENABLE_F, a
	jr z, .lcd_off
	ld a, [wConsolePaletteData]
	ld [wTempBGP], a
	ld [wTempOBP0], a
	ld [wTempOBP1], a
	ld de, PALRGB_WHITE
	ld hl, wTempBackgroundPalettesCGB
	ld bc, NUM_BACKGROUND_PALETTES palettes
	call FillMemoryWithDE
	call RestoreFirstColorInOBPals
	call FadeScreenToTempPals
	jp DisableLCD

.lcd_off
	ld a, [wConsolePaletteData]
	ld [wBGP], a
	ld [wOBP0], a
	ld [wOBP1], a
	ld de, PALRGB_WHITE
	ld hl, wBackgroundPalettesCGB
	ld bc, NUM_BACKGROUND_PALETTES palettes
	call FillMemoryWithDE
	jp FlushAllPalettes


FadeScreenFromWhite:
	call BackupPalsAndSetWhite
	call RestoreFirstColorInOBPals
	call FlushAllPalettes
	call EnableLCD
;	fallthrough

FadeScreenToTempPals:
	ld a, [wVBlankCounter]
	push af
	ld c, $10
.loop
	push bc
	ld a, c
	and %11
	cp 0
	call z, Func_10b85
	call FadeBGPalIntoTemp3
	call FadeOBPalIntoTemp
	call FlushAllPalettes
	call DoFrameIfLCDEnabled
	pop bc
	dec c
	dec c
	jr nz, .loop
	pop af
	ld b, a
	ld a, [wVBlankCounter]
	sub b
	ret


BackupPalsAndSetWhite:
	ld a, [wBGP]
	ld [wTempBGP], a
	ld a, [wOBP0]
	ld [wTempOBP0], a
	ld a, [wOBP1]
	ld [wTempOBP1], a
	ld hl, wBackgroundPalettesCGB
	ld de, wTempBackgroundPalettesCGB
	ld b, NUM_BACKGROUND_PALETTES palettes + NUM_OBJECT_PALETTES palettes
	call CopyNBytesFromHLToDE
;	fallthrough

; fills wBackgroundPalettesCGB with pure white palettes
SetWhitePalettes:
	ld a, [wConsolePaletteData]
	ld [wBGP], a
	ld [wOBP0], a
	ld [wOBP1], a
	ld de, PALRGB_WHITE
	ld hl, wBackgroundPalettesCGB
	ld bc, NUM_BACKGROUND_PALETTES palettes
	jp FillMemoryWithDE


; gets the first color of each palette from backup OB palettes
; and writes them in wObjectPalettesCGB
RestoreFirstColorInOBPals:
	ld hl, wTempObjectPalettesCGB
	ld de, wObjectPalettesCGB
	ld c, NUM_OBJECT_PALETTES
.loop_pals
	push bc
	ld a, [hli]
	ld [de], a
	inc de
	ld a, [hl]
	ld [de], a
	ld bc, CGB_PAL_SIZE - 1
	add hl, bc
	ld a, c
	add e
	ld e, a
	ld a, b
	adc d
	ld d, a
	pop bc
	dec c
	jr nz, .loop_pals
	ret


; does something with wBGP given wTempBGP
; mixes them into a single value?
; preserves bc
Func_10b85:
	push bc
	ld c, $03
	ld hl, wBGP
	ld de, wTempBGP
.asm_10b8e
	push bc
	ld b, [hl]
	ld a, [de]
	ld c, a
	call .Func_10b9e
	ld [hl], a
	pop bc
	inc de
	inc hl
	dec c
	jr nz, .asm_10b8e
	pop bc
	ret

; preserves all registers except af
.Func_10b9e
	push bc
	push de
	lb de, $00, 4
.loop
	call .Func_10bba
	or d
	rlca
	rlca
	ld d, a
	rlc b
	rlc b
	rlc c
	rlc c
	dec e
	jr nz, .loop
	ld a, d
	pop de
	pop bc
	ret

; calculates ((b & %11) << 2) | (c & %11)
; that is, %0000xxyy, where x and y are the 2 lower bits of b and c respectively
; and outputs the entry from a table given that value
; preserves all registers except af
.Func_10bba
	push hl
	push bc
	ld a, %11
	and b
	add a
	add a
	ld b, a
	ld a, %11
	and c
	or b
	ld c, a
	ld b, $00
	ld hl, .data_10bd1
	add hl, bc
	ld a, [hl]
	pop bc
	pop hl
	ret

.data_10bd1
	db %00 ; b = %00 | c = %00
	db %01 ; b = %00 | c = %01
	db %01 ; b = %00 | c = %10
	db %01 ; b = %00 | c = %11
	db %00 ; b = %01 | c = %00
	db %01 ; b = %01 | c = %01
	db %10 ; b = %01 | c = %10
	db %10 ; b = %01 | c = %11
	db %01 ; b = %10 | c = %00
	db %01 ; b = %10 | c = %01
	db %10 ; b = %10 | c = %10
	db %11 ; b = %10 | c = %11
	db %10 ; b = %11 | c = %00
	db %10 ; b = %11 | c = %01
	db %10 ; b = %11 | c = %10
	db %11 ; b = %11 | c = %11


; fades object palettes 0-3
; preserves bc
FadeOBPalIntoTemp:
	push bc
	ld c, 4 palettes
	ld hl, wObjectPalettesCGB
	ld de, wTempObjectPalettesCGB
	jr FadePalIntoAnother

; fades background palettes 0 and 1
; preserves bc
FadeBGPalIntoTemp1:
	push bc
	ld c, 2 palettes
	ld hl, wBackgroundPalettesCGB
	ld de, wTempBackgroundPalettesCGB
	jr FadePalIntoAnother

; fades background palettes 4 and 5
; preserves bc
FadeBGPalIntoTemp2:
	push bc
	ld c, 2 palettes
	ld hl, wBackgroundPalettesCGB + 4 palettes
	ld de, wTempBackgroundPalettesCGB + 4 palettes
	jr FadePalIntoAnother

; fades background palettes 0-3
; preserves bc
FadeBGPalIntoTemp3:
	push bc
	ld c, 4 palettes
	ld hl, wBackgroundPalettesCGB
	ld de, wTempBackgroundPalettesCGB
;	fallthrough

; input:
;	c = number of palettes to fade
;	hl = input palette(s) to modify
;	de = palette to fade into
FadePalIntoAnother:
	push bc
	ld a, [de]
	inc de
	ld c, a
	ld a, [de]
	inc de
	ld b, a
	push de
	push bc
	ld c, [hl]
	inc hl
	ld b, [hl]
	pop de
	call .GetFadedColor
	; overwrite with new color
	ld [hld], a
	ld [hl], c
	inc hl
	inc hl
	pop de
	pop bc
	dec c
	jr nz, FadePalIntoAnother
	pop bc
	ret

; fades palette bc to de
; preserves de and hl
; input:
;	bc = first palette
;	de = second palette
; output:
;	c = first half of resulting palette
;	a = second half of resulting palette
.GetFadedColor
	push hl
	ld a, c
	cp e
	jr nz, .unequal
	ld a, b
	cp d
	jr z, .skip

.unequal
	; red
	ld a, e
	and %11111
	ld l, a
	ld a, c
	and %11111
	call .FadeColor
	ldh [hffb6], a

	; green
	ld a, e
	and %11100000
	ld l, a
	ld a, d
	and %11
	or l
	swap a
	rrca
	ld l, a
	ld a, c
	and %11100000
	ld h, a
	ld a, b
	and %11
	or h
	swap a
	rrca
	call .FadeColor
	rlca
	swap a
	ld h, a
	and %11
	ldh [hffb7], a
	ld a, %11100000
	and h
	ld h, a
	ldh a, [hffb6]
	or h
	ld h, a

	; blue
	ld a, d
	and %1111100
	rrca
	rrca
	ld l, a
	ld a, b
	and %1111100
	rrca
	rrca
	call .FadeColor
	rlca
	rlca
	ld b, a
	ldh a, [hffb7]
	or b
	ld c, h
.skip
	pop hl
	ret

; compares colors in a and in l.  if a is smaller/greater than l,
; then increase/decrease its value up to l, up to a maximum of 4.
; preserves all registers except af
; input:
;	a = palette color (red, green or blue)
;	l = palette color (red, green or blue)
.FadeColor
	cp l
	ret z ; same value
	jr c, .incr_a
; decr a
	dec a
	cp l
	ret z
	dec a
	cp l
	ret z
	dec a
	cp l
	ret z
	dec a
	ret

.incr_a
	inc a
	cp l
	ret z
	inc a
	cp l
	ret z
	inc a
	cp l
	ret z
	inc a
	ret


; fades screen to white, then if c = 0, fade back in (otherwise keep white)
FlashScreenToWhite:
	ldh a, [hBankSRAM]
	push af
	push bc
	ld a, BANK("SRAM1")
	call BankswitchSRAM
	call CopyPalsToSRAMBuffer
	call FadeScreenToWhite
	pop bc
	ld a, c
	or a
	jr nz, .skip_fade_in
	call LoadPalsFromSRAMBuffer
	call FadeScreenFromWhite
.skip_fade_in
	call EnableLCD
	pop af
	call BankswitchSRAM
	jp DisableSRAM


; copies current BG and OB palettes, wBackgroundPalettesCGB, and wObjectPalettesCGB into sGfxBuffer2
CopyPalsToSRAMBuffer:
	ldh a, [hBankSRAM]

	push af
	ld a, BANK("SRAM1")
	call BankswitchSRAM
	ld hl, sGfxBuffer2
	ld a, [wBGP]
	ld [hli], a
	ld a, [wOBP0]
	ld [hli], a
	ld a, [wOBP1]
	ld [hli], a
	ld e, l
	ld d, h
	ld hl, wBackgroundPalettesCGB
	ld bc, NUM_BACKGROUND_PALETTES palettes + NUM_OBJECT_PALETTES palettes
	call CopyDataHLtoDE_SaveRegisters
	pop af

	call BankswitchSRAM
	jp DisableSRAM


; loads BG and OB palettes, wBackgroundPalettesCGB, and wObjectPalettesCGB from sGfxBuffer2
LoadPalsFromSRAMBuffer:
	ldh a, [hBankSRAM]

	push af
	ld a, BANK("SRAM1")
	call BankswitchSRAM
	ld hl, sGfxBuffer2
	ld a, [hli]
	ld [wBGP], a
	ld a, [hli]
	ld [wOBP0], a
	ld a, [hli]
	ld [wOBP1], a
	ld de, wBackgroundPalettesCGB
	ld bc, NUM_BACKGROUND_PALETTES palettes + NUM_OBJECT_PALETTES palettes
	call CopyDataHLtoDE_SaveRegisters
	pop af

	call BankswitchSRAM
	jp DisableSRAM


; backs up all palettes and overwrites 4 background palettes with a white palette
Func_10d17:
	ld a, [wBGP]
	ld [wTempBGP], a
	ld a, [wOBP0]
	ld [wTempOBP0], a
	ld a, [wOBP1]
	ld [wTempOBP1], a
	ld hl, wBackgroundPalettesCGB
	ld de, wTempBackgroundPalettesCGB
	ld b, NUM_BACKGROUND_PALETTES palettes + NUM_OBJECT_PALETTES palettes
	call CopyNBytesFromHLToDE

	ld a, [wConsolePaletteData]
	ld [wBGP], a
	ld de, PALRGB_WHITE
	ld hl, wBackgroundPalettesCGB
	ld bc, 4 palettes
	call FillMemoryWithDE
	call FlushAllPalettes

	ld a, $10
	ld [wd317], a
	ret


Func_10d50:
	ld a, [wConsolePaletteData]
	ld [wTempBGP], a
	ld a, [wOBP0]
	ld [wTempOBP0], a
	ld a, [wOBP1]
	ld [wTempOBP1], a
	ld de, PALRGB_WHITE
	ld hl, wTempBackgroundPalettesCGB
	ld bc, 4 palettes
	call FillMemoryWithDE
	ld a, $10
	ld [wd317], a
	ret


; returns without doing anything if wd317 = 0
; if wd317 > 0, has different effects depending on the bottom 2 bits:
;	- if equal to %01, modify wBGP
;	- if bottom bit not set, fade BG palettes 0 and 1
;	- if bottom bit is set, fade BG palettes 4 and 5 and then flush all palettes
; after applying the variable effects, wd317 is decremented.
Func_10d74:
	ld a, [wd317]
	or a
	ret z
	and %11
	ld c, a
	cp $1
	call z, Func_10b85
	bit 0, c
	call z, FadeBGPalIntoTemp1
	bit 0, c
	call nz, FadeBGPalIntoTemp2
	bit 0, c
	call nz, FlushAllPalettes
	ld a, [wd317]
	dec a
	ld [wd317], a
	ret
