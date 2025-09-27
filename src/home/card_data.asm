; loads the data of a card to wLoadedCard1 by using the text ID of the card name
; input:
;	de = text ID for a card's name
; output:
;	[wLoadedCard1] = all of the card's data (65 bytes)
LoadCardDataToBuffer1_FromName::
	ld hl, CardPointers + 2 ; skip first NULL pointer
	ld a, BANK(CardPointers)
	call BankpushROM2
.find_card_loop
	ld a, [hli]
	or [hl]
	jr z, .done
	push hl
	ld a, [hld]
	ld l, [hl]
	ld h, a
	ld a, BANK(CardPointers)
	call BankpushROM2
	ld bc, CARD_DATA_NAME
	add hl, bc
	ld a, [hli]
	cp e
	jr nz, .no_match
	ld a, [hl]
	cp d
.no_match
	pop hl
	pop hl
	inc hl
	jr nz, .find_card_loop
	dec hl
	ld a, [hld]
	ld l, [hl]
	ld h, a
	ld a, BANK(CardPointers)
	call BankpushROM2
	ld de, wLoadedCard1
	ld b, PKMN_CARD_DATA_LENGTH
	call CopyNBytesFromHLToDE
	pop hl
.done
	call BankpopROM
	ret


; loads the data of a card to wLoadedCard2 by using the card ID from e
; preserves all registers except af
; input:
;	e = card ID
; output:
;	[wLoadedCard1] = all of the card's data (65 bytes)
LoadCardDataToBuffer2_FromCardID::
	push hl
	ld hl, wLoadedCard2
	jr LoadCardDataToHL_FromCardID

; loads the data of a card to wLoadedCard1 by using the card ID from e
; preserves all registers except af
; input:
;	e = card ID
; output:
;	[wLoadedCard1] = all of the card's data (65 bytes)
LoadCardDataToBuffer1_FromCardID::
	push hl
	ld hl, wLoadedCard1
;	fallthrough

LoadCardDataToHL_FromCardID::
	push de
	push bc
	push hl
	call GetCardPointer
	pop de
	jr c, .done
	ld a, BANK(CardPointers)
	call BankpushROM2
	ld b, PKMN_CARD_DATA_LENGTH
	call CopyNBytesFromHLToDE
	call BankpopROM
	or a
.done
	pop bc
	pop de
	pop hl
	ret


; preserves all registers except af
; input:
;	e = card ID
; output:
;	a = type ID of the card from input (TYPE_* constant)
GetCardType::
	push hl
	call GetCardPointer
	jr c, .done
	ld a, BANK(CardPointers)
	call BankpushROM2
	ld l, [hl]
	call BankpopROM
	ld a, l
	or a
.done
	pop hl
	ret


; preserves bc and hl
; input:
;	e = card ID
; output:
;	de = 2-byte text ID of the name of the card from input
GetCardName::
	push hl
	call GetCardPointer
	jr c, .done
	ld a, BANK(CardPointers)
	call BankpushROM2
	ld de, CARD_DATA_NAME
	add hl, de
	ld e, [hl]
	inc hl
	ld d, [hl]
	call BankpopROM
	or a
.done
	pop hl
	ret


; preserves de and hl
; input:
;	a = card ID
; output:
;	a = type of card from input (CARD_DATA_TYPE)
;	b = rarity of card from input (CARD_DATA_RARITY)
;	c = set of card from input (CARD_DATA_SET)
GetCardTypeRarityAndSet::
	push hl
	push de
	ld d, 0
	ld e, a
	call GetCardPointer
	jr c, .done
	ld a, BANK(CardPointers)
	call BankpushROM2
	ld e, [hl] ; CARD_DATA_TYPE
	ld bc, CARD_DATA_RARITY
	add hl, bc
	ld b, [hl] ; CARD_DATA_RARITY
	inc hl
	ld c, [hl] ; CARD_DATA_SET
	call BankpopROM
	ld a, e
	or a
.done
	pop de
	pop hl
	ret


; preserves bc and de
; input:
;	e = card ID
; output:
;	hl = pointer to the data of the card from input
;	carry = set:  if input e was out of bounds, so no pointer was returned
GetCardPointer::
	push de
	push bc
	ld l, e
	ld h, $0
	add hl, hl
	ld bc, CardPointers
	add hl, bc
	ld a, h
	cp HIGH(CardPointers + 2 + (2 * NUM_CARDS))
	jr nz, .nz
	ld a, l
	cp LOW(CardPointers + 2 + (2 * NUM_CARDS))
.nz
	ccf
	jr c, .out_of_bounds
	ld a, BANK(CardPointers)
	call BankpushROM2
	ld a, [hli]
	ld h, [hl]
	ld l, a
	call BankpopROM
	or a
.out_of_bounds
	pop bc
	pop de
	ret


; copies a card graphic to vram and its palette to wCardPalette
; card_gfx_index = (<Name>CardGfx - CardGraphics) / 8  (using absolute ROM addresses)
; input:
;	hl = card_gfx_index
;	de = where to load the card gfx to
;	b = number of tiles used for a card graphic (should always be $30)
;	c = number of bytes in a tile (should always be TILE_SIZE, or 16)
; output:
;	[wCardPalette] = palette of the card being loaded
LoadCardGfx::
	ldh a, [hBankROM]
	push af
	push hl
	; first, get the bank with the card gfx is at
	srl h
	srl h
	srl h
	ld a, BANK(CardGraphics)
	add h
	rst BankswitchROM
	pop hl
	; once we have the bank, get the pointer: multiply by 8 and discard the bank offset
	add hl, hl
	add hl, hl
	add hl, hl
	res 7, h
	set 6, h ; $4000 ≤ hl ≤ $7fff
	call CopyGfxData
	ld b, PAL_SIZE
	ld de, wCardPalette
	call CopyNBytesFromHLToDE
	pop af
	jp BankswitchROM
