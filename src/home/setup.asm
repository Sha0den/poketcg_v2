; initializes scroll, window, and lcdc registers, sets trampoline functions
; for the lcdc and vblank interrupts, latches clock data, and enables SRAM/RTC
; preserves bc and de
SetupRegisters::
	xor a
	ldh [rSCY], a
	ldh [rSCX], a
	ldh [rWY], a
	ldh [rWX], a
	ldh [hSCX], a
	ldh [hSCY], a
	ldh [hWX], a
	ldh [hWY], a
	ld hl, wcab0
	ld [hli], a
	ld [hli], a
	ld [hl], a
	ld [wReentrancyFlag], a
	ld a, $c3            ; $c3 = jp nn
	ld [wLCDCFunctionTrampoline], a
	ld hl, wVBlankFunctionTrampoline
	ld [hli], a
	ld [hl], LOW(NoOp)   ;
	inc hl               ; load `jp NoOp`
	ld [hl], HIGH(NoOp)  ;
	ld a, LCDC_BG_ON | LCDC_OBJ_ON | LCDC_OBJ_16 | LCDC_WIN_9C00
	ld [wLCDC], a
	ld a, $1
	ld [rRTCLATCH], a
	ld a, RAMG_SRAM_ENABLE
	ld [rRAMG], a
NoOp::
	ret


; sets wConsole and, if CGB, selects WRAM bank 1 and switches to double speed mode
DetectConsole::
	ld b, CONSOLE_CGB
	cp BOOTUP_A_CGB
	jr z, .got_console
	call DetectSGB
	ld b, CONSOLE_DMG
	jr nc, .got_console
	call InitSGB
	ld b, CONSOLE_SGB
.got_console
	ld a, b
	ld [wConsole], a
	cp CONSOLE_CGB
	ret nz
	ld a, $01
	ldh [rWBK], a
	jp SwitchToCGBDoubleSpeed


; initializes the palettes (both monochrome and color)
SetupPalettes::
	ld hl, wBGP
	ldgbpal a, SHADE_WHITE, SHADE_LIGHT, SHADE_DARK, SHADE_BLACK
	ldh [rBGP], a
	ld [hli], a ; wBGP
	ldh [rOBP0], a
	ldh [rOBP1], a
	ld [hli], a ; wOBP0
	ld [hl], a ; wOBP1
	xor a
	ld [wFlushPaletteFlags], a
	ld a, [wConsole]
	cp CONSOLE_CGB
	ret nz
	ld de, wBackgroundPalettesCGB
	ld c, 16
.copy_pals_loop
	ld hl, InitialPalette
	ld b, PAL_SIZE
	call CopyNBytesFromHLToDE
	dec c
	jr nz, .copy_pals_loop
	jp FlushAllCGBPalettes

InitialPalette::
	rgb 28, 28, 24
	rgb 21, 21, 16
	rgb 10, 10, 08
	rgb 00, 00, 00


; clears VRAM tile data ([wTileMapFill] should be an empty tile)
; preserves de
SetupVRAM::
	call FillTileMap
	call CheckForCGB
	jr c, .vram0
	call BankswitchVRAM1
	call .vram0
	call BankswitchVRAM0
.vram0
	ld hl, v0Tiles0
	ld bc, v0BGMap0 - v0Tiles0
;	fallthrough

; preserves de
; input:
;	bc = number of bytes to clear
;	hl = address from which to start clearing
ClearData::
	xor a
	ld [hli], a
	dec bc
	ld a, c
	or b
	jr nz, ClearData
	ret


; fills VRAM0 BG map 0 with [wTileMapFill] and VRAM1 BG map 0 with $00
; preserves de
FillTileMap::
	call BankswitchVRAM0
	ld hl, v0BGMap0
	ld bc, v0BGMap1 - v0BGMap0
.vram0_loop
	ld a, [wTileMapFill]
	ld [hli], a
	dec bc
	ld a, c
	or b
	jr nz, .vram0_loop
	ld a, [wConsole]
	cp CONSOLE_CGB
	ret nz
	call BankswitchVRAM1
	ld hl, v1BGMap0
	ld bc, v1BGMap1 - v1BGMap0
	call ClearData
	jp BankswitchVRAM0


; zeroes work RAM, stack area, and high RAM ($C000-$DFFF, $FF80-$FFEF)
; preserves de
ZeroRAM::
	ld hl, $c000
	ld bc, $e000 - $c000
	call ClearData
	ld c, LOW($ff80)
	ld b, $fff0 - $ff80
	; a = $00
.zero_hram_loop
	ld [$ff00+c], a
	inc c
	dec b
	jr nz, .zero_hram_loop
	ret
