;----------------------------------------
;  THIS FILE WAS REMOVED FROM THE BUILD
;----------------------------------------

DebugLookAtSprite:
	farcall Func_80cd7
	scf
	ret


DebugVEffect:
;	farcall Func_80cd6 ; this function was commented out by the developers
	scf
	ret


DebugCreateBoosterPack:
.go_back
	ld a, [wDebugBoosterSelection]
	ld hl, Unknown_12919
	call InitAndPrintMenu
.input_loop_1
	call DoFrameIfLCDEnabled
	call HandleMenuInput
	jr nc, .input_loop_1
	cp e ; compare hCurMenuItem with wCurMenuItem
	jr nz, .cancel
	ld [wDebugBoosterSelection], a
	add a
	ld c, a
	ld b, $00
	ld hl, Unknown_127f1
	add hl, bc
	ld a, [hli]
	ld h, [hl]
	ld l, a
	xor a
	call InitAndPrintMenu
.input_loop_2
	call DoFrameIfLCDEnabled
	call HandleMenuInput
	jr nc, .input_loop_2
	cp e ; compare hCurMenuItem with wCurMenuItem
	jr nz, .go_back
	ld a, [wDebugBoosterSelection]
	ld c, a
	ld b, $00
	ld hl, Unknown_127fb
	add hl, bc
	ld a, [hl]
	add e
	farcall GenerateBoosterPack
	farcall OpenBoosterPack
.cancel
	scf
	ret


Unknown_12919:
	db  0,  0 ; start menu coordinates
	db 12, 12 ; start menu text box dimensions

	db  2, 2 ; text alignment for InitTextPrinting
	tx DebugBoosterPackMenuText
	db $ff

	db 1, 2 ; cursor x, cursor y
	db 2 ; y displacement between items
	db 5 ; number of items
	db SYM_CURSOR_R ; cursor tile number
	db SYM_SPACE ; tile behind cursor
	dw NULL ; function pointer if non-0


Unknown_127f1:
	dw Unknown_1292a
	dw Unknown_1292a
	dw Unknown_1293b
	dw Unknown_1294c
	dw Unknown_1295d


Unknown_1292a:
	db 12,  0 ; start menu coordinates
	db  4, 16 ; start menu text box dimensions

	db 14, 2 ; text alignment for InitTextPrinting
	tx DebugBoosterPackColosseumEvolutionMenuText
	db $ff

	db 13, 2 ; cursor x, cursor y
	db 2 ; y displacement between items
	db 7 ; number of items
	db SYM_CURSOR_R ; cursor tile number
	db SYM_SPACE ; tile behind cursor
	dw NULL ; function pointer if non-0


Unknown_1293b:
	db 12,  0 ; start menu coordinates
	db  4, 14 ; start menu text box dimensions

	db 14, 2 ; text alignment for InitTextPrinting
	tx DebugBoosterPackMysteryMenuText
	db $ff

	db 13, 2 ; cursor x, cursor y
	db 2 ; y displacement between items
	db 6 ; number of items
	db SYM_CURSOR_R ; cursor tile number
	db SYM_SPACE ; tile behind cursor
	dw NULL ; function pointer if non-0


Unknown_1294c:
	db 12,  0 ; start menu coordinates
	db  4, 12 ; start menu text box dimensions

	db 14, 2 ; text alignment for InitTextPrinting
	tx DebugBoosterPackLaboratoryMenuText
	db $ff

	db 13, 2 ; cursor x, cursor y
	db 2 ; y displacement between items
	db 5 ; number of items
	db SYM_CURSOR_R ; cursor tile number
	db SYM_SPACE ; tile behind cursor
	dw NULL ; function pointer if non-0


Unknown_1295d:
	db 12,  0 ; start menu coordinates
	db  4, 10 ; start menu text box dimensions

	db 14, 2 ; text alignment for InitTextPrinting
	tx DebugBoosterPackEnergyMenuText
	db $ff

	db 13, 2 ; cursor x, cursor y
	db 2 ; y displacement between items
	db 4 ; number of items
	db SYM_CURSOR_R ; cursor tile number
	db SYM_SPACE ; tile behind cursor
	dw NULL ; function pointer if non-0


Unknown_127fb:
	db BOOSTER_COLOSSEUM_NEUTRAL
	db BOOSTER_EVOLUTION_NEUTRAL
	db BOOSTER_MYSTERY_NEUTRAL
	db BOOSTER_LABORATORY_NEUTRAL
	db BOOSTER_ENERGY_LIGHTNING_FIRE


DebugCredits:
	farcall PlayCreditsSequence
	scf
	ret


DebugCGBTest:
;	farcall Func_1c865 ; this function was commented out by the developers
	scf
	ret


DebugSGBFrame:
	call DisableLCD
	ld a, [wDebugSGBBorder]
	farcall SetSGBBorder
	ld a, [wDebugSGBBorder]
	inc a
	cp $04
	jr c, .asm_1281f
	xor a
.asm_1281f
	ld [wDebugSGBBorder], a
	scf
	ret


DebugDuelMode:
	call EnableSRAM
	ld a, [sDebugDuelMode]
	and $01
	ld [sDebugDuelMode], a
	ld hl, Unknown_12908
	call InitAndPrintMenu
.input_loop
	call DoFrameIfLCDEnabled
	call HandleMenuInput
	jr nc, .input_loop
	cp e ; compare hCurMenuItem with wCurMenuItem
	jr nz, .input_loop
	and $01
	ld [sDebugDuelMode], a
	scf
	jp DisableSRAM

Unknown_12908:
	db 10, 0 ; start menu coordinates
	db 10, 6 ; start menu text box dimensions

	db 12, 2 ; text alignment for InitTextPrinting
	tx DebugDuelModeMenuText
	db $ff

	db 11, 2 ; cursor x, cursor y
	db 2 ; y displacement between items
	db 2 ; number of items
	db SYM_CURSOR_R ; cursor tile number
	db SYM_SPACE ; tile behind cursor
	dw NULL ; function pointer if non-0


DebugStandardBGCharacter:
	ld a, $80
	ld de, $0
	lb bc, 16, 16
	lb hl,  1, 16
	call FillRectangle
	ld a, PAD_BUTTONS | PAD_CTRL_PAD
	call WaitUntilKeysArePressed
	scf
	ret


DebugQuit:
	or a
	ret
