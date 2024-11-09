;----------------------------------------
;  THIS FILE WAS REMOVED FROM THE BUILD
;----------------------------------------

Func_12661:
	xor a
	ld [wDebugMenuSelection], a
	ld [wDebugBoosterSelection], a
	ld a, $03
	ld [wDebugSGBBorder], a
.asm_1266d
	call DisableLCD
	ld a, $00
	ld [wTileMapFill], a
	call EmptyScreen
	call LoadSymbolsFont
	lb de, $30, $7f
	call SetupText
	call EnableAndClearSpriteAnimations
	farcall Func_12871
	ld a, SINGLE_SPACED
	ld [wLineSeparation], a
	ld a, [wDebugMenuSelection]
	ld hl, Unknown_128f7
	call InitAndPrintMenu
	call EnableLCD
.asm_12698
	call DoFrameIfLCDEnabled
	call HandleMenuInput
	jr nc, .asm_12698
	bit 7, a
	jr nz, .asm_12698
	ld [wDebugMenuSelection], a
	xor a ; DOUBLE_SPACED
	ld [wLineSeparation], a
	call Func_126b3
	jr c, .asm_1266d
	ret

Unknown_128f7:
	db  0,  0 ; start menu coordinates
	db 16, 18 ; start menu text box dimensions

	db  2, 2 ; text alignment for InitTextPrinting
	tx DebugMenuText
	db $ff

	db 1, 2 ; cursor x, cursor y
	db 1 ; y displacement between items
	db 11 ; number of items
	db SYM_CURSOR_R ; cursor tile number
	db SYM_SPACE ; tile behind cursor
	dw NULL ; function pointer if non-0


Func_126b3:
	ldh a, [hCurMenuItem]
	ld hl, Unknown_126bb
	jp JumpToFunctionInTable


Unknown_126bb:
	dw _GameLoop
	dw DebugDuelMode
	dw MainMenu_ContinueFromDiary
	dw DebugCGBTest
	dw DebugSGBFrame
	dw DebugStandardBGCharacter
	dw DebugLookAtSprite
	dw DebugVEffect
	dw DebugCreateBoosterPack
	dw DebugCredits
	dw DebugQuit
