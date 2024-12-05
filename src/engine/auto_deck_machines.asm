INCLUDE "data/auto_deck_card_lists.asm"
INCLUDE "data/auto_deck_machines.asm"

; writes to sAutoDecks all the deck configurations
; from the Auto Deck Machine in wCurAutoDeckMachine
ReadAutoDeckConfiguration:
	call EnableSRAM
	ld a, [wCurAutoDeckMachine]
	ld l, a
	ld h, 6 * NUM_DECK_MACHINE_SLOTS
	call HtimesL
	ld bc, AutoDeckMachineEntries
	add hl, bc
	ld b, 0 ; initial index (first deck)
.loop_decks
	push hl
	ld l, b
	ld h, DECK_STRUCT_SIZE
	call HtimesL
	ld de, sAutoDecks
	add hl, de
	ld d, h
	ld e, l
	pop hl
	; de = pointer for sAutoDecksX, where X is b + 1
	; hl = card list pointer from AutoDeckMachineEntries

; write the deck configuration in SRAM by reading the given deck list
	push hl
	push bc
	push de
	push de
	ld e, [hl]
	inc hl
	ld d, [hl]
	pop hl
	; de = initial card list address from AutoDeckMachineEntries
	; hl = pointer for sAutoDecksX, where X is b + 1
	ld bc, DECK_NAME_SIZE
	add hl, bc
.loop_create_deck
	ld a, [de]
	inc de
	ld b, a ; card count
	or a
	jr z, .done_create_deck
	ld a, [de]
	inc de
	; a = card ID
.loop_card_count
	ld [hli], a
	dec b
	jr nz, .loop_card_count
	jr .loop_create_deck
.done_create_deck
	pop de
	pop bc
	pop hl
	inc hl
	inc hl
	; hl = deck name text pointer from AutoDeckMachineEntries

; write the deck name in wDismantledDeckName and sAutoDecks*
	push hl
	push de
	ld a, [hli]
	ld h, [hl]
	ld l, a
	ld de, wDismantledDeckName
	call CopyText
	pop hl
	; hl = pointer for sAutoDecksX, where X is b + 1
	ld de, wDismantledDeckName
.loop_copy_name
	ld a, [de]
	inc de
	ld [hli], a
	or a
	jr nz, .loop_copy_name
	pop hl
	inc hl
	inc hl
	; hl = deck description text pointer from AutoDeckMachineEntries

	; store deck description text ID in WRAM
	push hl
	ld de, wAutoDeckMachineTextDescriptions
	ld h, b
	ld l, 2
	call HtimesL
	add hl, de
	ld d, h
	ld e, l
	pop hl
	ld a, [hli]
	ld [de], a
	inc de
	ld a, [hli]
	ld [de], a
	inc b
	ld a, b
	cp NUM_DECK_MACHINE_SLOTS
	jr nz, .loop_decks
	jp DisableSRAM
