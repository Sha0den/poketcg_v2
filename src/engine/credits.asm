PlayCreditsSequence::
	ld a, MUSIC_STOP
	call PlaySong
	call Func_1d705
	call AddAllMastersToMastersBeatenList
	xor a
	ld [wOWMapEvents + 1], a
	ld a, MUSIC_CREDITS
	call PlaySong
	farcall FlashWhiteScreen
	call SetCreditsSequenceCmdPtr
.loop_cmds
	call DoFrameIfLCDEnabled
	call Func_1d765
	call ExecuteCreditsSequenceCmd
	ld a, [wSequenceDelay]
	cp $ff
	jr nz, .loop_cmds
	call WaitForSongToFinish
	ld a, PAD_START
	farcall WaitUntilKeysArePressed
	ld a, MUSIC_STOP
	call PlaySong
	farcall FadeScreenToWhite
	call ClearSpriteAnimations
	call SetWindowOff
	call Func_1d758
	call EnableLCD
	call DoFrameIfLCDEnabled
	call DisableLCD
	ld hl, wLCDC
	set 1, [hl]
	xor a
	ld [wDoFrameFunction + 0], a
	ld [wDoFrameFunction + 1], a
	ret


Func_1d705:
	call DisableLCD
	farcall LoadConsolePaletteData
	call EnableAndClearSpriteAnimations
	farcall InitMenuScreen
	call Func_1d7ee
	ld hl, Func_3e31
	call SetDoFrameFunction
	; fallthrough

; preserves all registers except af
.Func_1d720
	ld a, $91
	ld [wd647], a
	ld [wd649], a
	ld a, $01
	ld [wd648], a
	ld [wd64a], a
	call Func_1d765
	call SetWindowOn
	; fallthrough

; preserves all registers except af
.Func_1d73a
	push hl
	di
	xor a
	ld [wd657], a
	ld hl, wLCDCFunctionTrampoline + 1
	ld [hl], LOW(Func_3e44)
	inc hl
	ld [hl], HIGH(Func_3e44)
	ei

	ld hl, rSTAT
	set B_STAT_LYC, [hl]
	xor a
	ldh [rLYC], a
	ld hl, rIE
	set B_IE_STAT, [hl]
	pop hl
	ret


; preserves all registers
Func_1d758:
	push hl
	ld hl, rSTAT
	res B_STAT_LYC, [hl]
	ld hl, rIE
	res B_IE_STAT, [hl]
	pop hl
	ret


; preserves all registers except af
Func_1d765:
	push hl
	push bc
	push de
	xor a
	ldh [hWY], a

	ld hl, wd659
	ld de, wd65f
	ld a, [wd648]
	or a
	jr nz, .asm_1d785
	ld a, 160 + WX_OFS
	ldh [hWX], a
	ld [hli], a
	push hl
	ld hl, wLCDC
	set 1, [hl]
	pop hl
	jr .asm_1d7e2

.asm_1d785
	ld a, [wd647]
	or a
	jr z, .asm_1d79e
	dec a
	ld [de], a
	inc de
	ld a, 160 + WX_OFS
	ldh [hWX], a
	ld [hli], a
	push hl
	ld hl, wLCDC
	set 1, [hl]
	pop hl
	ld a, $07
	jr .asm_1d7a9

.asm_1d79e
	ld a, 0 + WX_OFS
	ldh [hWX], a
	push hl
	ld hl, wLCDC
	res 1, [hl]
	pop hl
.asm_1d7a9
	ld [hli], a
	ld a, [wd647]
	dec a
	ld c, a
	ld a, [wd648]
	add c
	ld c, a
	ld a, [wd649]
	dec a
	cp c
	jr c, .asm_1d7d4
	jr z, .asm_1d7d4
	ld a, c
	ld [de], a
	inc de
	push af
	ld a, $a7
	ld [hli], a
	pop bc
	ld a, [wd64a]
	or a
	jr z, .asm_1d7e2
	ld a, [wd649]
	dec a
	ld [de], a
	inc de
	ld a, $07
	ld [hli], a

.asm_1d7d4
	ld a, [wd649]
	dec a
	ld c, a
	ld a, [wd64a]
	add c
	ld [de], a
	inc de
	ld a, $a7
	ld [hli], a
.asm_1d7e2
	ld a, $ff
	ld [de], a
	ld a, $01
	ld [wd665], a
	pop de
	pop bc
	pop hl
	ret


Func_1d7ee:
	xor a         ; starting tile number (SYM_SPACE)
	lb de, 0, 32  ; screen coordinates for top left tile (off screen)
	lb bc, 20, 18 ; width and height of image in tiles (screen size)
	lb hl, 0, 0
	jp FillRectangle
