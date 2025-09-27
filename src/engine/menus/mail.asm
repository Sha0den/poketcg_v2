; clears all PC packs in WRAM and then gives the 1st pack.
; this doesn't clear in SRAM, so it's not done to clear PC pack data.
; preserves all registers except af
InitPCPacks:
	push hl
	push bc
	xor a
	ld [wPCPackSelection], a
	ld hl, wPCPacks
	ld c, NUM_PC_PACKS
.loop_packs
	ld [hli], a
	dec c
	jr nz, .loop_packs
	inc a ; mail 1 booster pack (from PCMailBoosterPacks)
	call TryGivePCPack
	pop bc
	pop hl
	ret


_PCMenu_ReadMail:
	ld a, [wd291]
	push af
	call InitMenuScreen
	lb de, $30, $ff
	call SetupText
	lb de,  0,  0
	lb bc, 20, 12
	call DrawRegularTextBox
	lb de,  0, 12
	lb bc, 20,  6
	call DrawRegularTextBox
	ld hl, MailScreenLabels
	call PrintLabels
	call PrintObtainedPCPacks
	xor a
	ld [wCursorBlinkTimer], a
	call FlashWhiteScreen
.asm_1079c
	call DoFrameIfLCDEnabled
	ld a, [wPCPackSelection]
	call UpdateMailMenuCursor
	call BlinkUnopenedPCPacks
	ld hl, wCursorBlinkTimer
	inc [hl]
	call PCMailHandleDPadInput
	call PCMailHandleAInput
	ldh a, [hKeysPressed]
	and PAD_B
	jr z, .asm_1079c
	ld a, SFX_CANCEL
	call PlaySFX
	pop af
	ld [wd291], a
	ret


MailScreenLabels:
	db 1, 0
	tx MailText

	db 1, 14
	tx WhichMailWouldYouLikeToReadText

	db 0, 20
	tx MailNumbersText

	db $ff


; preserves de
PCMailHandleDPadInput:
	ldh a, [hDPadHeld]
	and PAD_CTRL_PAD
	ret z
	farcall GetDirectionFromDPad
	ld [wPCLastDirectionPressed], a
	ld a, [wPCPackSelection]
	push af
	call HideMailMenuCursor
.asm_107f2
	ld a, [wPCPackSelection]
	add a
	add a
	ld c, a
	ld a, [wPCLastDirectionPressed]
	add c
	ld c, a
	ld b, $00
	ld hl, PCMailTransitionTable
	add hl, bc
	ld a, [hl]
	ld [wPCPackSelection], a
	ld c, a
	ld hl, wPCPacks
	add hl, bc
	ld a, [hl]
	or a
	jr z, .asm_107f2
	pop af
	ld c, a
	ld a, [wPCPackSelection]
	cp c
	jr z, .asm_1081d
	ld a, SFX_CURSOR
	call PlaySFX
.asm_1081d
	call ShowMailMenuCursor
	xor a
	ld [wCursorBlinkTimer], a
	ret

PCMailTransitionTable:
; up, right, down, left
	table_width 4, PCMailTransitionTable
	db $0c, $01, $03, $02 ; mail 1
	db $0d, $02, $04, $00 ; mail 2
	db $0e, $00, $05, $01 ; mail 3
	db $00, $04, $06, $05 ; mail 4
	db $01, $05, $07, $03 ; mail 5
	db $02, $03, $08, $04 ; mail 6
	db $03, $07, $09, $08 ; mail 7
	db $04, $08, $0a, $06 ; mail 8
	db $05, $06, $0b, $07 ; mail 9
	db $06, $0a, $0c, $0b ; mail 10
	db $07, $0b, $0d, $09 ; mail 11
	db $08, $09, $0e, $0a ; mail 12
	db $09, $0d, $00, $0e ; mail 13
	db $0a, $0e, $01, $0c ; mail 14
	db $0b, $0c, $02, $0d ; mail 15
	assert_table_length NUM_MAILS


PCMailHandleAInput:
	ldh a, [hKeysPressed]
	and PAD_A
	ret z
	ld a, SFX_CONFIRM
	call PlaySFX
	call PrintObtainedPCPacks
	call ShowMailMenuCursor
	ld a, [wPCPackSelection]
	ld c, a
	ld b, $00
	ld hl, wPCPacks
	add hl, bc
	ld a, [hl]
	ld [wSelectedPCPack], a
	and $7f ; mask out PACK_UNOPENED_F
	ld [hl], a
	or a
	ret z
	add a
	add a
	ld c, a
	ld hl, PCMailTextPages
	add hl, bc
	ld a, [hli]
	push hl
	ld h, [hl]
	ld l, a
	ld a, [wPCPackSelection]
	call GetPCPackNameTextID
	call PrintScrollableText_WithTextBoxLabel
	call TryOpenPCMailBoosterPack
	call InitMenuScreen
	lb de, $30, $ff
	call SetupText
	lb de,  0,  0
	lb bc, 20, 12
	call DrawRegularTextBox
	ld hl, MailScreenLabels
	call PrintLabels
	call PrintObtainedPCPacks
	call ShowMailMenuCursor
	call FlashWhiteScreen
	pop hl
	inc hl
	ld a, [hli]
	ld h, [hl]
	ld l, a
	or h
	jr z, .no_page_two
	ld a, [wPCPackSelection]
	call GetPCPackNameTextID
	call PrintScrollableText_WithTextBoxLabel
.no_page_two
	lb de,  0, 12
	lb bc, 20,  6
	call DrawRegularTextBox
	ld hl, MailScreenLabels
	call PrintLabels
	jp DoFrameIfLCDEnabled


PCMailTextPages:
	; unused
	dw NULL
	dw NULL

	; mail 1
	tx Mail1Part1Text
	tx Mail1Part2Text

	; mail 2
	tx Mail2Part1Text
	tx Mail2Part2Text

	; mail 3
	tx Mail3Part1Text
	tx Mail3Part2Text

	; mail 4
	tx Mail4Part1Text
	tx Mail4Part2Text

	; mail 5
	tx Mail5Part1Text
	tx Mail5Part2Text

	; mail 6
	tx Mail6Part1Text
	tx Mail6Part2Text

	; mail 7
	tx Mail7Part1Text
	tx Mail7Part2Text

	; mail 8
	tx Mail8Part1Text
	tx Mail8Part2Text

	; mail 9
	tx Mail9Part1Text
	tx Mail9Part2Text

	; mail 10
	tx Mail10Part1Text
	dw NULL

	; mail 11
	tx Mail11Part1Text
	dw NULL

	; mail 12
	tx Mail12Part1Text
	dw NULL

	; mail 13
	tx Mail13Part1Text
	dw NULL

	; mail 14
	tx Mail14Part1Text
	dw NULL

	; mail 15
	tx Mail15Part1Text
	dw NULL


TryOpenPCMailBoosterPack:
	xor a ; FALSE
	ld [wAnotherBoosterPack], a
	ld a, [wSelectedPCPack]
	bit PACK_UNOPENED_F, a
	jr z, .booster_already_open
	and $7f ; mask out PACK_UNOPENED_F
	add a
	ld c, a
	ld b, $00
	ld hl, PCMailBoosterPacks
	add hl, bc
	ld a, [hli]
	push hl
	call GiveBoosterPack
	ld a, TRUE
	ld [wAnotherBoosterPack], a
	pop hl
	ld a, [hl]
	or a
	call nz, GiveBoosterPack
	jp DisableLCD

.booster_already_open
	call InitMenuScreen
	lb de, $30, $ff
	call SetupText
	ldtx hl, MailBoosterPackAlreadyOpenedText
	call PrintScrollableText_NoTextBoxLabel
	jp DisableLCD

PCMailBoosterPacks:
	table_width 2, PCMailBoosterPacks
	db $00, $00 ; unused
	db BOOSTER_COLOSSEUM_NEUTRAL, $00                       ; mail 1
	db BOOSTER_LABORATORY_PSYCHIC, $00                      ; mail 2
	db BOOSTER_EVOLUTION_GRASS, $00                         ; mail 3
	db BOOSTER_MYSTERY_LIGHTNING_COLORLESS, $00             ; mail 4
	db BOOSTER_EVOLUTION_FIGHTING, $00                      ; mail 5
	db BOOSTER_COLOSSEUM_FIRE, $00                          ; mail 6
	db BOOSTER_LABORATORY_PSYCHIC, $00                      ; mail 7
	db BOOSTER_LABORATORY_PSYCHIC, $00                      ; mail 8
	db BOOSTER_MYSTERY_WATER_COLORLESS, $00                 ; mail 9
	db BOOSTER_COLOSSEUM_NEUTRAL, BOOSTER_EVOLUTION_NEUTRAL ; mail 10
	db BOOSTER_MYSTERY_NEUTRAL, BOOSTER_LABORATORY_NEUTRAL  ; mail 11
	db BOOSTER_COLOSSEUM_TRAINER, $00                       ; mail 12
	db BOOSTER_EVOLUTION_TRAINER, $00                       ; mail 13
	db BOOSTER_MYSTERY_TRAINER_COLORLESS, $00               ; mail 14
	db BOOSTER_LABORATORY_TRAINER, $00                      ; mail 15
	assert_table_length NUM_MAILS + 1


; preserves de and hl
ShowMailMenuCursor:
	ld a, SYM_CURSOR_R
	jr DrawMailMenuCursor

; preserves de and hl
UpdateMailMenuCursor:
	ld a, [wCursorBlinkTimer]
	and $10
	jr z, ShowMailMenuCursor
;	fallthrough

; preserves de and hl
HideMailMenuCursor:
	xor a ; SYM_SPACE
;	fallthrough

; preserves de and hl
; input:
;	a = tile to draw
DrawMailMenuCursor:
	push af
	call GetPCPackSelectionCoordinates
	pop af
	jp WriteByteToBGMap0


; prints all of the PC packs that the player has already obtained.
; preserves bc
PrintObtainedPCPacks:
	ld e, $0
	ld hl, wPCPacks
.loop_packs
	ld a, [hli]
	or a
	jr z, .next_pack
	ld a, e
	call PrintPCPackName
.next_pack
	inc e
	ld a, e
	cp NUM_PC_PACKS
	jr c, .loop_packs
	ret


; preserves bc and hl
; input:
;	a = e-mail index (1-15)
; output:
;	de = text ID corresponding to the name of the mail from input
GetPCPackNameTextID:
	push hl
	add a
	ld e, a
	ld d, $00
	ld hl, .PCPackNameTextIDs
	add hl, de
	ld e, [hl]
	inc hl
	ld d, [hl]
	pop hl
	ret

.PCPackNameTextIDs:
	table_width 2, GetPCPackNameTextID.PCPackNameTextIDs
	tx Mail1Text
	tx Mail2Text
	tx Mail3Text
	tx Mail4Text
	tx Mail5Text
	tx Mail6Text
	tx Mail7Text
	tx Mail8Text
	tx Mail9Text
	tx Mail10Text
	tx Mail11Text
	tx Mail12Text
	tx Mail13Text
	tx Mail14Text
	tx Mail15Text
	assert_table_length NUM_MAILS


; prints on screen the name of the PC pack from input in a
; preserves all registers except af
; input:
;	a = e-mail index (1-15)
PrintPCPackName:
	push hl
	push bc
	push de
	push af
	call GetPCPackNameTextID
	ld l, e
	ld h, d
	pop af
	call GetPCPackCoordinates
	ld e, c
	ld d, b
	call InitTextPrinting_PrintTextNoDelay
	pop de
	pop bc
	pop hl
	ret


; prints empty characters on screen corresponding to the PC pack in a,
; in order to create the blinking effect of unopened PC packs.
; preserves all registers except af
; input:
;	a = e-mail index (1-15)
PrintEmptyPCPackName:
	push hl
	push bc
	push de
	call GetPCPackCoordinates
	ld e, c
	ld d, b
	ldtx hl, EmptyMailNameText
	call InitTextPrinting_PrintTextNoDelay
	pop de
	pop bc
	pop hl
	ret


; preserves bc
BlinkUnopenedPCPacks:
	ld e, $00
	ld hl, wPCPacks
.loop_packs
	ld a, [hl]
	or a
	jr z, .next_pack
	bit PACK_UNOPENED_F, a
	jr z, .next_pack
	ld a, [wCursorBlinkTimer]
	and $0c
	jr z, .show
	cp $0c
	jr nz, .next_pack
; hide
	ld a, e
	call PrintEmptyPCPackName
	jr .next_pack
.show
	ld a, e
	call PrintPCPackName
.next_pack
	inc hl
	inc e
	ld a, e
	cp NUM_PC_PACKS
	jr c, .loop_packs
	ret


; preserves de and hl
; input:
;	a = e-mail index (1-15)
; output:
;	bc = coordinates corresponding to the PC pack from input
GetPCPackCoordinates:
	ld c, a
	ld a, [wPCPackSelection]
	push af
	ld a, c
	ld [wPCPackSelection], a
	call GetPCPackSelectionCoordinates
	inc b
	pop af
	ld [wPCPackSelection], a
	ret


; preserves de and hl
; input:
;	[wPCPackSelection] = e-mail index (1-15)
; output:
;	bc = coordinates corresponding to the PC pack from input
GetPCPackSelectionCoordinates:
	push hl
	ld a, [wPCPackSelection]
	add a
	ld c, a
	ld b, $00
	ld hl, PCMailCoordinates
	add hl, bc
	ld a, [hli]
	ld b, a
	ld c, [hl]
	pop hl
	ret

PCMailCoordinates:
	table_width 2, PCMailCoordinates
	db  1,  2 ; mail 1
	db  7,  2 ; mail 2
	db 13,  2 ; mail 3
	db  1,  4 ; mail 4
	db  7,  4 ; mail 5
	db 13,  4 ; mail 6
	db  1,  6 ; mail 7
	db  7,  6 ; mail 8
	db 13,  6 ; mail 9
	db  1,  8 ; mail 10
	db  7,  8 ; mail 11
	db 13,  8 ; mail 12
	db  1, 10 ; mail 13
	db  7, 10 ; mail 14
	db 13, 10 ; mail 15
	assert_table_length NUM_MAILS


; assigns a booster pack entry to a mail slot in wPCPacks.
; preserves all registers except af
; input:
;	a = e-mail index (1-15)
TryGivePCPack:
	push hl
	push bc
	ld b, a
	ld c, NUM_PC_PACKS
	ld hl, wPCPacks
.searchLoop1
	ld a, [hli]
	and $7f ; mask out PACK_UNOPENED_F
	cp b
	jr z, .quit ; exit if this booster pack was already assigned
	dec c
	jr nz, .searchLoop1
	ld c, NUM_PC_PACKS
	ld hl, wPCPacks
.findFreeSlotLoop
	ld a, [hl]
	and $7f ; mask out PACK_UNOPENED_F
	jr z, .foundFreeSlot
	inc hl
	dec c
	jr nz, .findFreeSlotLoop
	jr .quit

.foundFreeSlot
	ld a, b
	or PACK_UNOPENED ; mark pack as unopened
	ld [hl], a
.quit
	pop bc
	pop hl
	ret


;----------------------------------------
;        UNREFERENCED FUNCTIONS
;----------------------------------------
;
;Unknown_107c2:
;	db $01, $00, $00, $4a, $21, $b5, $42, $e0
;	db $03, $4a, $29, $94, $52, $fF, $7f, $00
