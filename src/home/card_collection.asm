; preserves bc and de
; output:
;	hl = total amount of cards owned anywhere, including duplicates
GetAmountOfCardsOwned::
	push de
	push bc
	call EnableSRAM
	ld hl, $0000
	ld de, sDeck1Cards
	ld c, NUM_DECKS
.next_deck
	ld a, [de]
	or a
	jr z, .skip_deck ; jump if deck empty
	ld a, c
	ld bc, DECK_SIZE
	add hl, bc
	ld c, a
.skip_deck
	ld a, sDeck2Cards - sDeck1Cards
	add e
	ld e, a
	ld a, $0
	adc d
	ld d, a ; de = sDeck*Cards[x]
	dec c
	jr nz, .next_deck
	; hl = DECK_SIZE * (number of non-empty decks)
	ld de, sCardCollection
	ld b, $00
.next_card
	ld a, [de]
	bit CARD_NOT_OWNED_F, a
	jr nz, .skip_card
	ld c, a ; card count in sCardCollection
	add hl, bc
.skip_card
	inc e
	jr nz, .next_card ; assumes sCardCollection is $100 bytes long (CARD_COLLECTION_SIZE)
	pop bc
	pop de
	jp DisableSRAM


; preserves all registers except af
; input:
;	a = card ID to check
; output:
;	a = total number of that card owned by the player
;	carry = set: the count of the card with ID from input was 0,
;	             in sCardCollection as well as all of the player's decks (sDeck*)
GetCardCountInCollectionAndDecks::
	push hl
	push de
	push bc
	call EnableSRAM
	ld c, a
	ld b, 0 ; initial counter
	ld hl, sDeck1Cards
	ld d, NUM_DECKS
.next_deck
	ld a, [hl]
	or a
	jr z, .deck_done ; jump if deck empty
	push hl
	ld e, DECK_SIZE
.next_card
	ld a, [hli]
	cp c
	jr nz, .no_match
	inc b ; this deck card matches card c
.no_match
	dec e
	jr nz, .next_card
	pop hl
.deck_done
	ld a, d
	ld de, sDeck2Cards - sDeck1Cards
	add hl, de
	ld d, a
	dec d
	jr nz, .next_deck
	; all decks done
	ld h, HIGH(sCardCollection)
	ld l, c
	ld a, [hl]
	bit CARD_NOT_OWNED_F, a
	jr nz, .done
	add b ; if card seen, add b to count
.done
	and CARD_COUNT_MASK
	call DisableSRAM
	pop bc
	pop de
	pop hl
	or a
	ret nz
	scf
	ret


; preserves all registers except af
; input:
;	a = card ID to check
; output:
;	a = number of that card owned by the player (outside of decks)
;	carry = set:  if the card from input's sCardCollection count was 0
GetCardCountInCollection::
	push hl
	call EnableSRAM
	ld h, HIGH(sCardCollection)
	ld l, a
	ld a, [hl]
	call DisableSRAM
	pop hl
	and CARD_COUNT_MASK
	ret nz
	scf
	ret


; creates a list at wTempCardCollection of every card the player owns
; along with how many of each card is owned
CreateTempCardCollection::
	call EnableSRAM
	ld hl, sCardCollection
	ld de, wTempCardCollection
	ld bc, CARD_COLLECTION_SIZE
	call CopyDataHLtoDE
	ld de, sDeck1Name
	call .AddDeckCards
	ld de, sDeck2Name
	call .AddDeckCards
	ld de, sDeck3Name
	call .AddDeckCards
	ld de, sDeck4Name
	call .AddDeckCards
	jp DisableSRAM

; adds the cards from a deck to wTempCardCollection given de = sDeck*Name
; input:
;	de = sDeck*Name
.AddDeckCards
	ld a, [de]
	or a
	ret z ; return if there isn't a deck name (assumes the deck is empty)
	ld hl, sDeck1Cards - sDeck1Name
	add hl, de
	ld e, l
	ld d, h
	ld h, HIGH(wTempCardCollection)
	ld c, DECK_SIZE
.next_card_loop
	ld a, [de] ; count of current card being added
	inc de ; move to next card for next iteration
	ld l, a
	inc [hl] ; increment count
	dec c
	jr nz, .next_card_loop
	ret


; adds card with ID given in a to sCardCollection, provided that
; the player has less than MAX_AMOUNT_OF_CARD (99) of them
; preserves all registers except af
; input:
;	a = card ID for the card to add
AddCardToCollection::
	push hl
	push de
	push bc
	ld l, a
	push hl
	call CreateTempCardCollection
	pop hl
	call EnableSRAM
	ld h, HIGH(wTempCardCollection)
	ld a, [hl]
	and CARD_COUNT_MASK
	cp MAX_AMOUNT_OF_CARD
	jr nc, .already_max
	ld h, HIGH(sCardCollection)
	ld a, [hl]
	and CARD_COUNT_MASK
	inc a
	ld [hl], a
.already_max
	pop bc
	pop de
	pop hl
	jp DisableSRAM


; removes a card with ID given in a from sCardCollection (decrement its count if non-0)
; preserves all registers except af
; input:
;	a = card ID for the card to remove
RemoveCardFromCollection::
	push hl
	call EnableSRAM
	ld h, HIGH(sCardCollection)
	ld l, a
	ld a, [hl]
	and CARD_COUNT_MASK
	jr z, .zero
	dec a
	ld [hl], a
.zero
	pop hl
	jp DisableSRAM


; preserves bc and hl
; output:
;	d = number of different cards that the player has collected
;	e = NUM_CARDS minus 1 if VENUSAUR_LV64 or MEW_LV15 has not been collected (minus 2 if neither)
GetCardAlbumProgress::
	push hl
	call EnableSRAM
	ld e, NUM_CARDS
	ld h, HIGH(sCardCollection)
	ld l, VENUSAUR_LV64
	bit CARD_NOT_OWNED_F, [hl]
	jr z, .next1
	dec e ; if VENUSAUR_LV64 isn't owned
.next1
	ld l, MEW_LV15
	bit CARD_NOT_OWNED_F, [hl]
	jr z, .next2
	dec e ; if MEW_LV15 isn't owned
.next2
	ld d, 0 ; initial card counter
	ld l, d ; LOW(sCardCollection)
.next_card
	bit CARD_NOT_OWNED_F, [hl]
	jr nz, .skip
	inc d ; if this card is owned
.skip
	inc l
	jr nz, .next_card ; assumes sCardCollection is $100 bytes long (CARD_COLLECTION_SIZE)
	pop hl
	jp DisableSRAM
