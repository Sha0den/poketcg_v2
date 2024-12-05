LoadCollectedMedalTilemaps:
	xor a
	ld [wd291], a
	lb de,  0,  8
	ld a, [wMedalScreenYOffset]
	add e
	ld e, a
	lb bc, 20, 10
	call DrawRegularTextBox
	lb de, 6, 9
	ld a, [wMedalScreenYOffset]
	add e
	ld e, a
	call AdjustCoordinatesForBGScroll
	ldtx hl, PlayerStatusMedalsTitleText
	call InitTextPrinting_PrintTextNoDelay
	ld hl, MedalCoordsAndTilemaps
	ld a, EVENT_MEDAL_FLAGS
	farcall GetEventValue
	or a
	ret z ; no medals?

; load tilemaps of only the collected medals
	ld c, NUM_MEDALS
.loop_medals
	push bc
	push hl
	push af
	bit 7, a
	jr z, .skip_medal
	ld b, [hl]
	inc hl
	ld a, [wMedalScreenYOffset]
	add [hl]
	ld c, a
	inc hl
	ld a, [hli]
	ld [wCurTilemap], a
	farcall LoadTilemap_ToVRAM
.skip_medal
	pop af
	rlca
	pop hl
	ld bc, $3
	add hl, bc
	pop bc
	dec c
	jr nz, .loop_medals

	ld a, $80
	ld [wd4ca], a
	xor a
	ld [wd4cb], a
	farcall LoadTilesetGfx
	xor a
	ld [wd4ca], a
	inc a ; $01
	ld [wd4cb], a
	ld a, $76
	farcall SetBGPAndLoadedPal
	ret

MedalCoordsAndTilemaps:
; x, y, tilemap
	table_width 3, MedalCoordsAndTilemaps
	db  1, 10, TILEMAP_GRASS_MEDAL
	db  6, 10, TILEMAP_SCIENCE_MEDAL
	db 11, 10, TILEMAP_FIRE_MEDAL
	db 16, 10, TILEMAP_WATER_MEDAL
	db  1, 14, TILEMAP_LIGHTNING_MEDAL
	db  6, 14, TILEMAP_PSYCHIC_MEDAL
	db 11, 14, TILEMAP_ROCK_MEDAL
	db 16, 14, TILEMAP_FIGHTING_MEDAL
	assert_table_length NUM_MEDALS


FlashReceivedMedal:
	xor a
	ld [wd291], a
	ld hl, MedalCoordsAndTilemaps
	ld a, [wWhichMedal]
	ld c, a
	add a
	add c
	ld c, a
	ld b, $00
	add hl, bc
	ld b, [hl]
	inc hl
	ld a, [wMedalScreenYOffset]
	add [hl]
	ld c, a
	ld a, [wMedalDisplayTimer]
	bit 4, a
	jr z, .show
; hide
	xor a ; SYM_SPACE
	ld e, c ; y coordinate
	ld d, b ; x coordinate
	lb bc, 3, 3 ; width and height of a medal icon
	lb hl, 0, 0
	jp FillRectangle

.show
	inc hl
	ld a, [hl]
	ld [wCurTilemap], a
	farcall LoadTilemap_ToVRAM
	ret


PrintPlayTime:
	ld a, [wPlayTimeCounter + 2]
	ld [wPlayTimeHourMinutes], a
	ld a, [wPlayTimeCounter + 3]
	ld [wPlayTimeHourMinutes + 1], a
	ld a, [wPlayTimeCounter + 4]
	ld [wPlayTimeHourMinutes + 2], a
;	fallthrough

; input:
;	bc = screen coordinates for printing text
PrintPlayTime_SkipUpdateTime:
	push bc
	ld hl, wPlayTimeHourMinutes + 1
	ld a, [hli]
	ld h, [hl]
	ld l, a
	call ThreeDigitNumberToTxSymbol_TrimLeadingZeros
	pop bc
	push bc
	call BCCoordToBGMap0Address
	ld hl, wDecimalChars
	ld b, 3
	call SafeCopyDataHLtoDE
	ld a, [wPlayTimeHourMinutes]
	add 100
	ld l, a
	ld a, 0
	adc 0
	ld h, a
	call ThreeDigitNumberToTxSymbol_TrimLeadingZeros
	pop bc
	ld a, b
	add 4
	ld b, a
	call BCCoordToBGMap0Address
	ld hl, wDecimalChars + 1
	ld b, 2
	jp SafeCopyDataHLtoDE


; converts the three-digit number at hl to TX_SYMBOL text format and
; writes it to wDecimalChars, replacing any leading zeros with SYM_SPACE.
; input:
;	hl = number to convert to symbol font
;	[wDecimalChars] = number in text symbol format (3 bytes)
ThreeDigitNumberToTxSymbol_TrimLeadingZeros:
	ld de, wDecimalChars
	ld bc, -100 ; hundreds
	call GetTxSymbolDigit
	ld bc, -10 ; tens
	call GetTxSymbolDigit
	ld a, l ; ones
	add SYM_0
	ld [de], a

; remove leading zeroes
	ld hl, wDecimalChars
	ld c, 2
.loop_digits
	ld a, [hl]
	cp SYM_0
	ret nz ; reached a non-zero digit?
	ld [hl], SYM_SPACE
	inc hl
	dec c
	jr nz, .loop_digits
	ret


; prints album progress in coordinates bc
; input:
;	bc = screen coordinates for printing text
PrintAlbumProgress:
	push bc
	call GetCardAlbumProgress
	pop bc
;	fallthrough

; input:
;	bc = screen coordinates for printing text
;	d = number of different cards that the player has collected
;	e = total number of cards in the game
PrintAlbumProgress_SkipGetProgress:
	push bc
	push de
	push bc
	ld l, d ; number of different cards collected
	ld h, $00
	call ThreeDigitNumberToTxSymbol_TrimLeadingZeros
	pop bc
	call BCCoordToBGMap0Address
	ld hl, wDecimalChars
	ld b, 3
	call SafeCopyDataHLtoDE
	pop de
	ld l, e ; total number of cards
	ld h, $00
	call ThreeDigitNumberToTxSymbol_TrimLeadingZeros
	pop bc
	ld a, b
	add 4
	ld b, a
	call BCCoordToBGMap0Address
	ld hl, wDecimalChars
	ld b, 3
	jp SafeCopyDataHLtoDE


; prints the number of medals collected in bc
; input:
;	bc = screen coordinates for printing text
PrintMedalCount:
	farcall TryGiveMedalPCPacks
	ld a, EVENT_MEDAL_COUNT
	farcall GetEventValue
	add SYM_0
	jp WriteByteToBGMap0
