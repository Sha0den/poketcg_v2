; adds the chosen starter deck to the player's first deck configuration
; and also adds to the collection its corresponding extra cards
; input:
;	a = $0:  Charmander and Friends starter deck
;	a = $1:  Squirtle and Friends starter deck
;	a = $2:  Bulbasaur and Friends starter deck
AddStarterDeck::
	add a
	ld e, a
	ld d, 0
	ld hl, .StarterCardIDs
	add hl, de
	ld a, PLAYER_TURN
	ldh [hWhoseTurn], a
	ld a, [hli] ; main deck
	add 2
	push hl
	ld hl, sDeck1
	call CopyDeckNameAndCards
	pop hl
	rst SwapTurn
	ld a, [hli] ; extra deck
	add 2
	call LoadDeck
	rst SwapTurn

; wPlayerDeck = main starter deck
; wOpponentDeck = extra cards
	call EnableSRAM
	ld h, HIGH(sCardCollection)
	ld de, wPlayerDeck
	ld c, DECK_SIZE
.loop_main_cards
	ld a, [de]
	inc de
	ld l, a
	res CARD_NOT_OWNED_F, [hl]
	dec c
	jr nz, .loop_main_cards

	ld h, HIGH(sCardCollection)
	ld de, wOpponentDeck
	ld c, 30 ; number of extra cards
.loop_extra_cards
	ld a, [de]
	inc de
	ld l, a
	res CARD_NOT_OWNED_F, [hl]
	inc [hl]
	dec c
	jr nz, .loop_extra_cards
; ALL CARDS HACK: Uncomment the following 17 lines of code to give the Player a full collection.
;	ld c, NUM_CARDS
;.loop_debug_collection
;	ld l, c
;	res CARD_NOT_OWNED_F, [hl]
;	ld a, [hl]
;	add 16 ; 16 copies of every card
;	ld [hl], a
;	dec c
;	jr nz, .loop_debug_collection
;	ld c, DOUBLE_COLORLESS_ENERGY - 1
;.loop_debug_energies
;	ld l, c
;	ld a, [hl]
;	add 30 ; plus an additional 30 copies of each Basic Energy card
;	ld [hl], a
;	dec c
;	jr nz, .loop_debug_energies
	jp DisableSRAM

.StarterCardIDs
	; main deck, extra cards
	db CHARMANDER_AND_FRIENDS_DECK_ID, CHARMANDER_EXTRA_DECK_ID
	db SQUIRTLE_AND_FRIENDS_DECK_ID,   SQUIRTLE_EXTRA_DECK_ID
	db BULBASAUR_AND_FRIENDS_DECK_ID,  BULBASAUR_EXTRA_DECK_ID


; clears saved data (card collection/saved decks/Card Pop! data/etc)
; then adds the starter decks as saved decks and marks all cards as not owned
InitSaveData::
; clear card and deck save data
	call EnableSRAM
	ld a, PLAYER_TURN
	ldh [hWhoseTurn], a
	ld hl, sCardAndDeckSaveData
	ld bc, sCardAndDeckSaveDataEnd - sCardAndDeckSaveData
.loop_clear
	xor a
	ld [hli], a
	dec bc
	ld a, c
	or b
	jr nz, .loop_clear

; add the starter decks
	ld a, CHARMANDER_AND_FRIENDS_DECK
	ld hl, sSavedDeck1
	call CopyDeckNameAndCards
	ld a, SQUIRTLE_AND_FRIENDS_DECK
	ld hl, sSavedDeck2
	call CopyDeckNameAndCards
	ld a, BULBASAUR_AND_FRIENDS_DECK
	ld hl, sSavedDeck3
	call CopyDeckNameAndCards

; change every card in the collection to not owned
	call EnableSRAM
	ld hl, sCardCollection
	ld a, CARD_NOT_OWNED
.loop_collection
	ld [hl], a
	inc l
	jr nz, .loop_collection

	ld hl, sCurrentDuel
	xor a
	ld [hli], a
	ld [hli], a ; sCurrentDuelChecksum
	ld [hl], a

; clears Card Pop! names
	ld hl, sCardPopNameList
	ld c, CARDPOP_NAME_LIST_MAX_ELEMS
.loop_card_pop_names
	ld [hl], $0
	ld de, NAME_BUFFER_LENGTH
	add hl, de
	dec c
	jr nz, .loop_card_pop_names

; saved configuration options
	ld a, 2
	ld [sPrinterContrastLevel], a
;	ld a, TEXT_SPEED_3 ; default text speed at start of game
	ld a, TEXT_SPEED_5 ; default text speed at start of game
	ld [sTextSpeed], a
	ld [wTextSpeed], a

; clear miscellaneous save data
	ld hl, s0a004
	xor a
	ld [hli], a ; s0a004 = $00
	ld [hli], a ; sTotalCardPopsDone = $00
	inc hl      ; skip sTextSpeed
	ld [hli], a ; sAnimationsDisabled = $00
	inc hl      ; skip s0a008
	ld [hli], a ; sSkipDelayAllowed = $00
	ld [hl], a  ; sReceivedLegendaryCards = $00
	farcall InitPromotionalCardAndDeckCounterSaveData
	jp DisableSRAM


; preserves all registers except af
; input:
;	a = deck ID (*_DECK constant)
;	hl = where to copy (in SRAM)
CopyDeckNameAndCards:
	push de
	push bc
	push hl
	call LoadDeck
	jr c, .done
	call .CopyDeckName
	pop hl
	call EnableSRAM
	push hl
	ld de, wDefaultText
.loop_write_name
	ld a, [de]
	inc de
	ld [hli], a
	or a
	jr nz, .loop_write_name
	pop hl

	push hl
	ld de, DECK_NAME_SIZE
	add hl, de
	ld de, wPlayerDeck
	ld c, DECK_SIZE
.loop_write_cards
	ld a, [de]
	inc de
	ld [hli], a
	dec c
	jr nz, .loop_write_cards
	call DisableSRAM
	or a
.done
	pop hl
	pop bc
	pop de
	ret

.CopyDeckName
	ld hl, wDeckName
	ld a, [hli]
	ld h, [hl]
	ld l, a
	ld de, wDefaultText
	jp CopyText
