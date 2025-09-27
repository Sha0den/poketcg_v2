; same as SetDefaultConsolePalettes except it
; forces all wBGP, wOBP0 and wOBP1 to be the default.
; preserves all registers except af
SetDefaultPalettes::
	push hl
	push bc
	push de
	ld hl, wBGP
	ldgbpal a, SHADE_WHITE, SHADE_LIGHT, SHADE_DARK, SHADE_BLACK
	ld [hli], a ; wBGP
	ld [hli], a ; wOBP0
	ld [hl], a  ; wOBP1
	call SetDefaultConsolePalettes
	call FlushAllPalettes
	pop de
	pop bc
	pop hl
	ret


; sets the default game palettes for all three systems
SetDefaultConsolePalettes::
	ldh a, [hBankROM]
	push af
	ld a, BANK(_SetDefaultConsolePalettes)
	rst BankswitchROM
	call _SetDefaultConsolePalettes
	pop af
	jp BankswitchROM


; Flushes all non-CGB and CGB palettes
; preserves all registers except af
FlushAllPalettes::
	ld a, FLUSH_ALL_PALS
	jr FlushPalettes

; Flushes non-CGB palettes and a single CGB palette,
; provided in a as an index between 0-7 (BGP) or 8-15 (OBP)
; preserves all registers except af
; input:
;	a = CGB palette to flush
FlushPalette::
	or FLUSH_ONE_PAL
	jr FlushPalettes

; Sets wBGP to the specified value, then flushes non-CGB palettes and the first CGB palette.
; preserves all registers except af
; input:
;	a = value to copy into wBGP
SetBGP::
	ld [wBGP], a
;	fallthrough

; Flushes non-CGB palettes and the first CGB palette
; preserves all registers except af
FlushPalette0::
	ld a, FLUSH_ONE_PAL
;	fallthrough

; input:
;	a = wFlushPaletteFlags ID (FLUSH_* constant)
FlushPalettes::
	ld [wFlushPaletteFlags], a
	ld a, [wLCDC]
	rla
	ret c ; return if LCD is on
	push hl
	push de
	push bc
	call FlushPalettesIfRequested
	pop bc
	pop de
	pop hl
	ret

; Sets wOBP0 to the specified value, then flushes non-CGB palettes and the first CGB palette.
; preserves all registers except af
; input:
;	a = value to copy into wOBP0
SetOBP0::
	ld [wOBP0], a
	jr FlushPalette0

; Sets wOBP1 to the specified value, then flushes non-CGB palettes and the first CGB palette.
; preserves all registers except af
; input:
;	a = value to copy into wOBP1
SetOBP1::
	ld [wOBP1], a
	jr FlushPalette0


; Flushes non-CGB palettes from [wBGP], [wOBP0], and [wOBP1].
; Also flushes CGB palettes from [wBackgroundPalettesCGB..wBackgroundPalettesCGB+$3f] (BG palette)
; and [wObjectPalettesCGB+$00..wObjectPalettesCGB+$3f] (sprite palette).
; Only flushes if [wFlushPaletteFlags] is nonzero, and only flushes
; a single CGB palette if bit6 of that location is reset.
FlushPalettesIfRequested::
	ld a, [wFlushPaletteFlags]
	or a
	ret z
	; flush grayscale (non-CGB) palettes
	ld hl, wBGP
	ld a, [hli]
	ldh [rBGP], a
	ld a, [hli]
	ldh [rOBP0], a
	ld a, [hl]
	ldh [rOBP1], a
	ld a, [wConsole]
	cp CONSOLE_CGB
	jr z, .CGB
.done
	xor a
	ld [wFlushPaletteFlags], a
	ret
.CGB
	; flush a single CGB BG or OB palette
	; if bit6 (FLUSH_ALL_PALS_F) of [wFlushPaletteFlags] is set, flush all 16 of them
	ld a, [wFlushPaletteFlags]
	bit FLUSH_ALL_PALS_F, a
	jr nz, FlushAllCGBPalettes
	ld b, PAL_SIZE
	call CopyCGBPalettes
	jr .done

FlushAllCGBPalettes::
	; flush 8 BGP palettes
	xor a ; start with BGP0 (wBackgroundPalettesCGB)
	ld b, 8 palettes
	call CopyCGBPalettes
	; flush 8 OBP palettes
	ld a, NUM_BACKGROUND_PALETTES ; skip all background palettes and start with OBP0 (wObjectPalettesCGB)
	ld b, 8 palettes
	call CopyCGBPalettes
	jr FlushPalettesIfRequested.done


; copies b bytes of CGB palette data starting at
; (wBackgroundPalettesCGB + a palettes) into rBGPD or rOBPD.
; input:
;	a = offset for wBackgroundPalettesCGB
;	b = number of bytes to copy
CopyCGBPalettes::
	add a ; *2
	add a ; *4
	add a ; *8 (PAL_SIZE)
	ld e, a
	ld d, $0
	ld hl, wBackgroundPalettesCGB
	add hl, de
	ld c, LOW(rBGPI)
	bit 6, a ; was a between 0-7 (BGP), or between 8-15 (OBP)?
	jr z, .copy
	ld c, LOW(rOBPI)
.copy
	and %10111111
	ld e, a
.next_byte
	ld a, e
	ld [$ff00+c], a
	inc c
.wait
	ldh a, [rSTAT]
	and STAT_BUSY ; wait until hblank or vblank
	jr nz, .wait
	ld a, [hl]
	ld [$ff00+c], a
	ld a, [$ff00+c]
	cp [hl]
	jr nz, .wait
	inc hl
	dec c
	inc e
	dec b
	jr nz, .next_byte
	ret
