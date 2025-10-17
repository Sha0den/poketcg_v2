; returns [([hWhoseTurn] ^ $1) << 8 + a] in a and in [hl],
; i.e. duelvar a of the player whose turn it is not.
; preserves bc and de
; input:
;	a = wOpponentDuelVariables constant
GetNonTurnDuelistVariable::
	ld l, a
	ldh a, [hWhoseTurn]
	ld h, OPPONENT_TURN
	cp PLAYER_TURN
	jr z, .ok
	ld h, PLAYER_TURN
.ok
	ld a, [hl]
	ret


; copies the deck pointed to by de to wPlayerDeck or wOpponentDeck (depending on whose turn it is)
; input:
;	de = deck to copy
; output:
;	carry = set:  if the deck contained less than 60 cards
CopyDeckData::
	ld hl, wPlayerDeck
	ldh a, [hWhoseTurn]
	cp PLAYER_TURN
	jr z, .copy_deck_data
	ld hl, wOpponentDeck
.copy_deck_data
	; set slot #60 to $00 (used later to check if loaded deck has at least 60 cards)
	push hl
	ld bc, DECK_SIZE - 1
	add hl, bc
	ld [hl], $0
	pop hl
	push hl
.next_card
	ld a, [de]
	inc de
	ld b, a
	or a
	jr z, .done
	ld a, [de]
	inc de
	ld c, a
.card_quantity_loop
	ld [hl], c
	inc hl
	dec b
	jr nz, .card_quantity_loop
	jr .next_card
.done
	ld hl, wDeckName
	ld a, [de]
	inc de
	ld [hli], a
	ld a, [de]
	ld [hl], a
	pop hl
	ld bc, DECK_SIZE - 1
	add hl, bc
	ld a, [hl]
	or a
	ret nz
	scf
	ret


; preserves all registers except af
; output:
;	a = how many Prize cards the turn holder has not yet drawn
CountPrizes::
	push hl
	ld a, DUELVARS_PRIZES
	get_turn_duelist_var
	ld l, a
	xor a
.count_loop
	rr l
	adc $00
	inc l
	dec l
	jr nz, .count_loop
	pop hl
	ret


; draws a card from the turn holder's deck, saving its location as CARD_LOCATION_JUST_DRAWN.
; AddCardToHand is meant to be called next (unless this function returned carry).
; preserves all registers except af
; output:
;	a = deck index (0-59) of the top card of the deck, if any
;	carry = set:  if a card couldn't be drawn because the deck was empty
DrawCardFromDeck::
	push hl
	ld a, DUELVARS_NUMBER_OF_CARDS_NOT_IN_DECK
	get_turn_duelist_var
	cp DECK_SIZE
	jr nc, .empty_deck
	inc [hl] ; increment number of cards not in deck
	add DUELVARS_DECK_CARDS ; point to top card in the deck
	ld l, a
	ld a, [hl] ; grab card's deck index (0-59) from wPlayerDeckCards or wOpponentDeckCards array
	ld l, a
	ld [hl], CARD_LOCATION_JUST_DRAWN ; temporarily write to corresponding card location variable
	pop hl
	or a
	ret
.empty_deck
	pop hl
	scf
	ret


; searches the turn holder's hand for a card, removes it,
; and then puts that card on top of the turn holder's deck.
; preserves all registers
; input:
;	a = deck index (0-59) of the card to move from the hand to the deck
MoveCardFromHandToTopOfDeck::
	call RemoveCardFromHand
;	fallthrough

; puts the given card on top of the turn holder's deck
; preserves all registers
; input:
;	a = deck index (0-59) of the card to return to the deck
ReturnCardToDeck::
	push hl
	push af
	; add card to deck array (listed top to bottom at end of w*DeckCards)
	ld a, DUELVARS_NUMBER_OF_CARDS_NOT_IN_DECK
	get_turn_duelist_var
	dec [hl] ; decrement number of cards not in deck
	add DUELVARS_DECK_CARDS - 1
	ld l, a
	; hl = pointer for next byte in deck array (top of deck)
	pop af
	ld [hl], a
	; overwrite this card's location variable
	ld l, a ; DUELVARS_CARD_LOCATIONS + index for card from input
	ld [hl], CARD_LOCATION_DECK
	pop hl
	ret


; searches the turn holder's deck for a particular card.
; if found, it's removed from the list, and the variable containing
; the number of cards not in the turn holder's deck is incremented.
; the card's location is also changed to CARD_LOCATION_JUST_DRAWN.
; preserves all registers
; input:
;	a = deck index (0-59) of the card to remove from the deck
RemoveCardFromDeck::
	push af
	push hl
	push de
	push bc
	ld c, a
	ld a, DUELVARS_NUMBER_OF_CARDS_NOT_IN_DECK
	get_turn_duelist_var
	ld a, DECK_SIZE
	sub [hl]
	or a
	jr z, .done ; done if no cards in deck
	ld b, a ; number of cards still in deck
	ld l, DUELVARS_DECK_CARDS + DECK_SIZE - 1
	ld e, l
	ld d, h
	; de = hl = last card in wPlayerDeckCards/wOpponentDeckCards array (bottom card in deck)
.next_card
	ld a, [hld]
	cp c
	jr nz, .wrong_card
	; the card from input was found, so overwrite its card location
	push hl
	ld l, c
	; hl = DUELVARS_CARD_LOCATIONS + index for card from input
	ld [hl], CARD_LOCATION_JUST_DRAWN
	; then, increment the number of cards not in the deck
	ld l, DUELVARS_NUMBER_OF_CARDS_NOT_IN_DECK
	inc [hl]
	pop hl
	jr .check_if_done
.wrong_card
	; keep any other cards in the turn holder's discard pile
	ld [de], a
	dec de
.check_if_done
	dec b
	jr nz, .next_card
.done
	pop bc
	pop de
	pop hl
	pop af
	ret


; searches the turn holder's discard pile for a card, removes it,
; and then adds that card to the turn holder's hand.
; preserves all registers
; input:
;	a = deck index (0-59) of the card to move from the discard pile to the hand
MoveCardFromDiscardPileToHand::
	call RemoveCardFromDiscardPile
	jr AddCardToHand

; searches the turn holder's deck for a card, removes it,
; and then adds that card to the turn holder's hand.
; preserves all registers
; input:
;	a = deck index (0-59) of the card to move from the deck to the hand
MoveCardFromDeckToHand::
	call RemoveCardFromDeck
;	fallthrough

; adds the given card to the turn holder's hand and increments the number of cards in the hand
; preserves all registers
; input:
;	a = deck index (0-59) of the card to add to the hand
AddCardToHand::
	push hl
	push af
	; add card to hand array (listed oldest to newest at start of w*Hand)
	ld a, DUELVARS_NUMBER_OF_CARDS_IN_HAND
	get_turn_duelist_var
	inc [hl] ; increment number of cards in hand
	add DUELVARS_HAND
	ld l, a
	; hl = pointer for next byte in hand array (first card in hand)
	pop af
	ld [hl], a
	; overwrite this card's location variable
	ld l, a ; DUELVARS_CARD_LOCATIONS + index for card from input
	ld [hl], CARD_LOCATION_HAND
	pop hl
	ret


; searches the turn holder's hand for a particular card.
; if found, it's removed from the list, and the variable containing
; the number of cards in the turn holder's hand is decremented.
; the card's location is also changed to CARD_LOCATION_JUST_DRAWN.
; preserves all registers
; input:
;	a = deck index (0-59) of the card to remove from the hand
RemoveCardFromHand::
	push af
	push hl
	push de
	push bc
	ld c, a
	ld a, DUELVARS_NUMBER_OF_CARDS_IN_HAND
	get_turn_duelist_var
	or a
	jr z, .done ; done if no cards in hand
	ld b, a ; number of cards in hand
	ld l, DUELVARS_HAND
	ld e, l
	ld d, h
	; de = hl = first card in wPlayerHand/wOpponentHand array (oldest card in hand)
.next_card
	ld a, [hli]
	cp c
	jr nz, .wrong_card
	; the card from input was found, so overwrite its card location
	push hl
	ld l, c
	; hl = DUELVARS_CARD_LOCATIONS + index for card from input
	ld [hl], CARD_LOCATION_JUST_DRAWN
	; then, decrement the number of cards in the hand
	ld l, DUELVARS_NUMBER_OF_CARDS_IN_HAND
	dec [hl]
	pop hl
	jr .check_if_done
.wrong_card
	; keep any other cards in the turn holder's hand
	ld [de], a
	inc de
.check_if_done
	dec b
	jr nz, .next_card
.done
	pop bc
	pop de
	pop hl
	pop af
	ret


; puts the given card into the turn holder's discard pile,
; but only if it is currently in the turn holder's hand
; preserves bc and de
; input:
;	a = deck index (0-59) of the hand card to move to the discard pile
TryToDiscardCardFromHand::
	; a = DUELVARS_CARD_LOCATIONS + index for card from input
	get_turn_duelist_var
	cp CARD_LOCATION_HAND
	ret nz ; return if card not in hand
	ld a, l
;	fallthrough

; searches the turn holder's hand for a card, removes it,
; and then puts that card into the turn holder's discard pile.
; preserves all registers
; input:
;	a = deck index (0-59) of the card to move from the hand to the discard pile
MoveCardFromHandToDiscardPile::
	call RemoveCardFromHand
;	fallthrough

; adds the given card to the turn holder's discard pile and increments the number of cards in the discard pile
; preserves all registers
; input:
;	a = deck index (0-59) of the card to put in the discard pile
PutCardInDiscardPile::
	push hl
	push af
	; add card to discard pile array (listed oldest to newest at start of w*DeckCards)
	ld a, DUELVARS_NUMBER_OF_CARDS_IN_DISCARD_PILE
	get_turn_duelist_var
	inc [hl] ; increment number of cards in discard pile
	add DUELVARS_DECK_CARDS
	ld l, a
	; hl = pointer for next byte in discard pile array (top of discard pile)
	pop af
	ld [hl], a
	; overwrite this card's location variable
	ld l, a ; DUELVARS_CARD_LOCATIONS + index for card from input
	ld [hl], CARD_LOCATION_DISCARD_PILE
	pop hl
	ret


; searches the turn holder's discard pile for a particular card.
; if found, it's removed from the list, and the variable containing
; the number of cards in the turn holder's discard pile is decremented.
; the card's location is also changed to CARD_LOCATION_JUST_DRAWN.
; preserves all registers
; input:
;	a = deck index (0-59) of the card to remove from the discard pile
RemoveCardFromDiscardPile::
	push af
	push hl
	push de
	push bc
	ld c, a
	ld a, DUELVARS_NUMBER_OF_CARDS_IN_DISCARD_PILE
	get_turn_duelist_var
	or a
	jr z, .done ; done if no cards in discard pile
	ld b, a ; number of cards in discard pile
	ld l, DUELVARS_DECK_CARDS
	ld e, l
	ld d, h
	; de = hl = first card in wPlayerDeckCards/wOpponentDeckCards array (bottom card in discard pile)
.next_card
	ld a, [hli]
	cp c
	jr nz, .wrong_card
	; the card from input was found, so overwrite its card location
	push hl
	ld l, c
	; hl = DUELVARS_CARD_LOCATIONS + index for card from input
	ld [hl], CARD_LOCATION_JUST_DRAWN
	; then, decrement the number of cards in the discard pile
	ld l, DUELVARS_NUMBER_OF_CARDS_IN_DISCARD_PILE
	dec [hl]
	pop hl
	jr .check_if_done
.wrong_card
	; keep any other cards in the turn holder's discard pile
	ld [de], a
	inc de
.check_if_done
	dec b
	jr nz, .next_card
.done
	pop bc
	pop de
	pop hl
	pop af
	ret


; fills wDuelTempList with the turn holder's discard pile cards (their 0-59 deck indices)
; output:
;	a = number of cards in the turn holder's discard pile
;	carry = set:  if there weren't any cards in the turn holder's discard pile
;	wDuelTempList = $ff-terminated list with deck indices of all cards in the turn holder's discard pile
CreateDiscardPileCardList::
	ld a, DUELVARS_NUMBER_OF_CARDS_IN_DISCARD_PILE
	get_turn_duelist_var
	or a
	jr z, EmptyDuelTempListAndSetCarry ; return carry with empty list if no cards in discard pile
	ld c, a
	ld b, a
	add DUELVARS_DECK_CARDS - 1 ; point to last card in discard pile
	ld l, a
	ld de, wDuelTempList
.next_card_loop
	ld a, [hld]
	ld [de], a
	inc de
	dec b
	jr nz, .next_card_loop
	jr CreateDeckCardList.terminate_list


; fills wDuelTempList with the turn holder's remaining deck cards (their 0-59 deck indices)
; output:
;	a = number of cards in the turn holder's deck
;	carry = set:  if there weren't any cards in the turn holder's deck
;	wDuelTempList = $ff-terminated list with deck indices of all cards still in the turn holder's deck
CreateDeckCardList::
	ld a, DUELVARS_NUMBER_OF_CARDS_NOT_IN_DECK
	get_turn_duelist_var
	cp DECK_SIZE
	jr nc, EmptyDuelTempListAndSetCarry ; return carry with empty list if no cards in deck
	ld a, DECK_SIZE
	sub [hl]
	ld c, a
	ld b, a ; c = b = DECK_SIZE - [DUELVARS_NUMBER_OF_CARDS_NOT_IN_DECK]
	ld a, DUELVARS_DECK_CARDS
	add [hl]
	ld l, a ; l = DUELVARS_DECK_CARDS + [DUELVARS_NUMBER_OF_CARDS_NOT_IN_DECK]
	ld de, wDuelTempList
	call CopyNBytesFromHLToDE
.terminate_list
	ld a, $ff ; $ff-terminated
	ld [de], a
	ld a, c
	or a
	ret


; output:
;	a = $00
;	carry = set
;	[wDuelTempList] = $ff
EmptyDuelTempListAndSetCarry::
	ld a, $ff
	ld [wDuelTempList], a
	xor a
.set_carry
	scf
	ret


; fills wDuelTempList with every Energy card (their 0-59 deck indices)
; that is attached to the turn holder's Pokémon in a specified location
; input:
;	a = play area location offset (PLAY_AREA_* constant)
; output:
;	a & b = number of Energy cards attached to the Pokémon in the given location
;	carry = set:  if there weren't any Energy cards in the location from input
;	wDuelTempList = $ff-terminated list with deck indices of all Energy cards in input location
CreateArenaOrBenchEnergyCardList::
	or CARD_LOCATION_PLAY_AREA
	ld c, a
	xor a
	ld b, a ; initial counter = 0
	; a = DUELVARS_CARD_LOCATIONS
	get_turn_duelist_var
	; hl = starting address for turn holder's card location data
	ld de, wDuelTempList
.next_card_loop
	ld a, [hl]
	cp c
	jr nz, .skip_card ; jump if not in specified play area location
	ld a, l
	call GetCardTypeFromDeckIndex_SaveDE
	and 1 << TYPE_ENERGY_F
	jr z, .skip_card ; jump if Pokémon or Trainer card
	ld a, l
	ld [de], a ; add to wDuelTempList
	inc de
	inc b
.skip_card
	inc l
	ld a, l
	cp DECK_SIZE
	jr c, .next_card_loop
	; all cards checked
	ld a, $ff ; terminating byte
	ld [de], a
	ld a, b
	or a
	ret nz
	scf
	ret


; fills wDuelTempList with the turn holder's hand cards (their 0-59 deck indices)
; preserves c
; output:
;	a = number of cards in the turn holder's hand
;	carry = set:  if there weren't any cards in the turn holder's hand
;	wDuelTempList = $ff-terminated list with deck indices of all cards in the turn holder's hand
CreateHandCardList::
	call FindLastCardInHand
	ld a, b
	or a
	jr z, EmptyDuelTempListAndSetCarry ; return carry with empty list if no cards in hand
.check_next_card_loop
	ld a, [hld]
	ld [de], a
	inc de
	dec b
	jr nz, .check_next_card_loop
	ld a, $ff ; $ff-terminated
	ld [de], a
	ld l, DUELVARS_NUMBER_OF_CARDS_IN_HAND
	ld a, [hl]
	or a
	ret


; output:
;	b = turn holder's number of cards in hand (DUELVARS_NUMBER_OF_CARDS_IN_HAND)
;	hl = pointer to turn holder's last (newest) card in DUELVARS_HAND
;	de = wDuelTempList
FindLastCardInHand::
	ld a, DUELVARS_NUMBER_OF_CARDS_IN_HAND
	get_turn_duelist_var
	ld b, a
	add DUELVARS_HAND - 1
	ld l, a
	ld de, wDuelTempList
	ret


; shuffles the turn holder's deck
; if less than 60 cards remain in the deck, it makes sure that the rest are ignored
; preserves de and c
ShuffleDeck::
	ld a, DUELVARS_NUMBER_OF_CARDS_NOT_IN_DECK
	get_turn_duelist_var
	ld a, DECK_SIZE
	sub [hl]
	ld b, a
	ld a, DUELVARS_DECK_CARDS
	add [hl]
	ld l, a ; hl = DUELVARS_DECK_CARDS + [DUELVARS_NUMBER_OF_CARDS_NOT_IN_DECK]
	ld a, b ; a = number of cards in the deck
;	fallthrough

; shuffles a list of cards by swapping the position of each card
; with the position of another random card in the list
; preserves all registers except af
; input:
;	a  = how many cards to shuffle
;	hl = list of cards to shuffle
ShuffleCards::
	or a
	ret z ; return if the list is empty
	push hl
	push de
	push bc
	ld c, a
	ld b, a
	ld e, l
	ld d, h
.shuffle_next_card_loop
	push bc
	push de
	ld a, c
	call Random
	add e
	ld e, a
	ld a, $0
	adc d
	ld d, a
	ld a, [de]
	ld b, [hl]
	ld [hl], a
	ld a, b
	ld [de], a
	pop de
	pop bc
	inc hl
	dec b
	jr nz, .shuffle_next_card_loop
	pop bc
	pop de
	pop hl
	ret


; sorts an $ff-terminated list of deck index cards in wDuelTempList by ID (lowest to highest ID).
; input:
;	[wDuelTempList] = start of an $ff-terminated list of cards (deck indices)
SortCardsInDuelTempListByID::
	ld hl, hTempListPtr_ff99
	ld [hl], LOW(wDuelTempList)
	inc hl
	ld [hl], HIGH(wDuelTempList)
;	fallthrough

; sorts an $ff-terminated list of deck index cards by ID (lowest to highest ID).
; sorting by ID rather than deck index means that the order of equal (same ID) cards does not matter,
; even if they have a different deck index.
; input:
;	[hTempListPtr_ff99] = pointer for an $ff-terminated list with deck indices of cards (2 bytes)
SortCardsInListByID::
	ld hl, hTempListPtr_ff99
	ld a, [hli]
	ld h, [hl]
	ld l, a
	bit 7, [hl] ; check for the list terminator ($ff)
	ret nz

	ld e, l
	ld d, h
	; get ID of card with deck index at [de]
	ld a, [de]
	call _GetCardIDFromDeckIndex
	ldh [hTempCardID_ff9b], a
	inc hl
	; hl = [hTempListPtr_ff99] + 1
	jr .check_list_end

.next_card_in_list
	ld a, [hl]
	call _GetCardIDFromDeckIndex
	ld c, a
	ldh a, [hTempCardID_ff9b]
	cp c
	jr c, .not_lower_id
	; this card has the lowest ID of those checked so far
	ld e, l
	ld d, h
	ld a, c
	ldh [hTempCardID_ff9b], a
.not_lower_id
	inc hl
.check_list_end
	bit 7, [hl] ; check for the list terminator ($ff)
	jr z, .next_card_in_list
	; reached list terminator
	ld hl, hTempListPtr_ff99
	push hl
	ld a, [hli]
	ld h, [hl]
	ld l, a
	; swap the lowest ID card found with the card in the current list position
	ld c, [hl]
	ld a, [de]
	ld [hl], a
	ld a, c
	ld [de], a
	pop hl
	; [hTempListPtr_ff99] += 1 (point hl to next card in list)
	inc [hl]
	jr nz, SortCardsInListByID
	inc hl
	inc [hl]
	jr SortCardsInListByID


; preserves af, bc, and hl
; input:
;	a = deck index (0-59) of the card to identify
; output:
;	de = card ID from input deck index
GetCardIDFromDeckIndex::
	push af
	call _GetCardIDFromDeckIndex
	ld e, a
	ld d, $0
	pop af
	ret


; preserves all registers except af
; input:
;	a = deck index (0-59) of the card to identify
; output:
;	a = card ID from input deck index
_GetCardIDFromDeckIndex::
	push de
	push hl
	ld e, a
	ld d, $0
	ld hl, wPlayerDeck
	ldh a, [hWhoseTurn]
	cp PLAYER_TURN
	jr z, .load_card_from_deck
	ld hl, wOpponentDeck
.load_card_from_deck
	add hl, de
	ld a, [hl]
	pop hl
	pop de
	ret


; preserves all registers except af
; input:
;	a = deck index of the card to identify
; output:
;	a = type ID of the card from input (TYPE_* constant)
GetCardTypeFromDeckIndex_SaveDE::
	push de
	call GetCardIDFromDeckIndex
	call GetCardType
	pop de
	ret


; loads the data of a card to wLoadedCard1 by using its deck index
; preserves all registers except af
; input:
;	a = card's deck index (0-59)
; output:
;	a = card's ID
;	[wLoadedCard1] = all of the card's data (65 bytes)
LoadCardDataToBuffer1_FromDeckIndex::
	push hl
	push de
	push bc
	ld l, a
	call GetCardIDFromDeckIndex
	call LoadCardDataToBuffer1_FromCardID
	ldh a, [hWhoseTurn]
	ld h, a
	ld a, [hl] ; given card's location
	bit CARD_LOCATION_PLAY_AREA_F, a
	jr z, .done
	; this card is in the play area, so check if it has alternate card data
	ld a, l
	ld hl, wLoadedCard1
.after_load
	farcall ConvertSpecialTrainerCardToPokemon ; located in engine/duel/effect_functions2.asm
.done
	ld a, e
	pop bc
	pop de
	pop hl
	ret


; loads the data of a card to wLoadedCard2 by using its deck index
; preserves all registers except af
; input:
;	a = card's deck index (0-59)
; output:
;	a = card's ID
;	[wLoadedCard2] = all of the card's data (65 bytes)
LoadCardDataToBuffer2_FromDeckIndex::
	push hl
	push de
	push bc
	ld l, a
	call GetCardIDFromDeckIndex
	call LoadCardDataToBuffer2_FromCardID
	ldh a, [hWhoseTurn]
	ld h, a
	ld a, [hl] ; given card's location
	bit CARD_LOCATION_PLAY_AREA_F, a
	jr z, LoadCardDataToBuffer1_FromDeckIndex.done
	; this card is in the play area, so check if it has alternate card data
	ld a, l
	ld hl, wLoadedCard2
	jr LoadCardDataToBuffer1_FromDeckIndex.after_load


; loads the effect commands of a (Trainer or Energy) card with deck index (0-59)
; at hTempCardIndex_ff9f into wLoadedAttackEffectCommands.
; this is only ever used for Trainer cards in the base game.
; preserves bc
; input:
;	[hTempCardIndex_ff9f] = Trainer or Energy card to load
; output:
;	[wLoadedCard1] = all of the given card's data (card_data_struct)
;	[wLoadedAttackEffectCommands] = given card's effect command data (2 bytes)
LoadNonPokemonCardEffectCommands::
	ldh a, [hTempCardIndex_ff9f]
	call LoadCardDataToBuffer1_FromDeckIndex
	ld hl, wLoadedCard1EffectCommands
	ld de, wLoadedAttackEffectCommands
	ld a, [hli]
	ld [de], a
	inc de
	ld a, [hl]
	ld [de], a
	ret


; input:
;	d = deck index of the Pokémon with the information to copy
;	e = which attack to copy (0 = first attack, 1 = second attack)
; output:
;	[wSelectedAttack] = e
;	[hTempCardIndex_ff9f] = d
;	[wLoadedCard1] = all of the given card's data (card_data_struct)
;	[wLoadedAttack] = given card's attack data (atk_data_struct)
;	[wDamage] = attack's listed damage
;	[wNoDamageOrEffect] = 0
;	[wDealtDamage] = 0
CopyAttackDataAndDamage_FromDeckIndex::
	ld a, e
	ld [wSelectedAttack], a
	ld a, d
	ldh [hTempCardIndex_ff9f], a
	call LoadCardDataToBuffer1_FromDeckIndex
	ld a, [wLoadedCard1ID]
	ld [wTempCardID_ccc2], a
	ld hl, wLoadedCard1Atk1
	dec e ; cp SECOND_ATTACK
	jr nz, .got_atk
	ld hl, wLoadedCard1Atk2
.got_atk
	ld de, wLoadedAttack
	ld c, CARD_DATA_ATTACK2 - CARD_DATA_ATTACK1
.copy_loop
	ld a, [hli]
	ld [de], a
	inc de
	dec c
	jr nz, .copy_loop
	ld a, [wLoadedAttackDamage]
	ld hl, wDamage
	ld [hli], a
	xor a
	ld [hl], a
	ld [wNoDamageOrEffect], a
	ld hl, wDealtDamage
	ld [hli], a
	ld [hl], a
	ret


; tries to remove a specific card from wDuelTempList
; preserves all registers except af
; input:
;	a = deck index of the card to remove
;	wDuelTempList = $ff-terminated list
; output:
;	a = number of items remaining in wDuelTempList
;	carry = set:  if wDuelTempList is now empty
RemoveCardFromDuelTempList::
	push hl
	push de
	push bc
	ld hl, wDuelTempList
	ld e, l
	ld d, h
	ld c, a
	ld b, $00
.next
	ld a, [hli]
	cp $ff
	jr z, .end_of_list
	cp c
	jr z, .next ; found the deck index from input
	ld [de], a
	inc de
	inc b
	jr .next
.end_of_list
	ld [de], a
	ld a, b
	or a
	jr nz, .done
	scf
.done
	pop bc
	pop de
	pop hl
	ret


; preserves all registers except af
; input:
;	wDuelTempList = $ff-terminated list
; output:
;	a = number of cards in wDuelTempList
CountCardsInDuelTempList::
	push hl
	push bc
	ld hl, wDuelTempList
	ld b, -1
.loop
	inc b
	ld a, [hli]
	inc a ; cp $ff
	jr nz, .loop
	ld a, b
	pop bc
	pop hl
	ret


; checks if the Pokémon at location e can evolve into the Pokémon with deck index d.
; also checks whether the Pokémon being evolved has been in play for a full turn
; preserves bc and de
; input:
;	d = deck index of the Evolution card being considered (0-59)
;	e = play area location offset of the Pokémon being evolved (PLAY_AREA_* constant)
; output:
;	carry = set:   if the evolution wasn't possible
;	z flag = set:  if the evolution wasn't possible because the two Pokémon were incompatible
;	z flag != set: if the evolution wasn't possible because the Pokémon in the given location was put into play this turn
CheckIfCanEvolveInto::
	push de
	ld a, e
	add DUELVARS_ARENA_CARD
	get_turn_duelist_var
	call LoadCardDataToBuffer2_FromDeckIndex
	ld a, d
	call LoadCardDataToBuffer1_FromDeckIndex
	ld hl, wLoadedCard2Name
	ld de, wLoadedCard1PreEvoName
	ld a, [de]
	cp [hl]
	jr nz, .cant_evolve ; jump if they are incompatible to evolve
	inc de
	inc hl
	ld a, [de]
	cp [hl]
	jr nz, .cant_evolve ; jump if they are incompatible to evolve
	pop de
	ld a, e
	add DUELVARS_ARENA_CARD_FLAGS
	get_turn_duelist_var
	and CAN_EVOLVE_THIS_TURN
	ret nz ; return without carry set if the evolution is possible
	; CAN_EVOLVE_THIS_TURN flag wasn't set, so return carry with the z flag unset
	ld a, $01
	or a
	scf
	ret
.cant_evolve
	pop de
	xor a
	scf
	ret


; tries to evolve a turn holder's in-play Pokémon
; input:
;	[hTempCardIndex_ff98] = deck index of the Evolution card (0-59)
;	[hTempPlayAreaLocation_ff9d] = play area location offset of the Pokémon being evolved (PLAY_AREA_* constant)
; output:
;	carry = set:  if the evolution wasn't possible
EvolvePokemonCardIfPossible::
	; first make sure the attempted evolution is viable
	ldh a, [hTempCardIndex_ff98]
	ld d, a
	ldh a, [hTempPlayAreaLocation_ff9d]
	ld e, a
	call CheckIfCanEvolveInto
	ret c ; return if it's not capable of evolving into the selected Pokémon
;	fallthrough

; evolves a turn holder's in-play Pokémon
; preserves b and d
; input:
;	[hTempCardIndex_ff98] = deck index of the Evolution card (0-59)
;	[hTempPlayAreaLocation_ff9d] = play area location offset of the Pokémon being evolved (PLAY_AREA_* constant)
; output:
;	[wPreEvolutionPokemonCard] = deck index of the play area Pokémon that was evolved
EvolvePokemonCard::
; place the evolution card in the play area location of the pre-evolution
	ldh a, [hTempPlayAreaLocation_ff9d]
	ld e, a
	add DUELVARS_ARENA_CARD
	get_turn_duelist_var
	ld [wPreEvolutionPokemonCard], a ; store pre-evolution's deck index
	call LoadCardDataToBuffer2_FromDeckIndex
	ldh a, [hTempCardIndex_ff98]
	ld [hl], a
	call LoadCardDataToBuffer1_FromDeckIndex
	ldh a, [hTempCardIndex_ff98]
	call PutHandCardInPlayArea
	; set the new evolution stage of the card
	ld a, e
	add DUELVARS_ARENA_CARD_STAGE
	get_turn_duelist_var
	ld a, [wLoadedCard1Stage]
	ld [hl], a
	; update the Pokémon's HP with the difference
	ld a, e
	add DUELVARS_ARENA_CARD_HP
	get_turn_duelist_var
	ld a, [wLoadedCard2HP]
	ld c, a
	ld a, [wLoadedCard1HP]
	sub c
	add [hl]
	ld [hl], a
	; clear changed type variable and any temporary flags, like CAN_EVOLVE_THIS_TURN
	ld a, e
	add DUELVARS_ARENA_CARD_FLAGS
	ld l, a
	ld [hl], $00
	ld a, e
	add DUELVARS_ARENA_CARD_CHANGED_TYPE
	ld l, a
	ld [hl], $00
	; reset status and Arena-specific variables if evolving the Active Pokémon
	ld a, e
	or a ; cp PLAY_AREA_ARENA
	ret nz ; return if the Pokémon is on the Bench
;	fallthrough

; clears the status, all substatuses, and temporary duelvars of the turn holder's
; Active Pokémon. called when sending a new Pokémon into the Arena.
; does not reset Headache, since it targets a player rather than a Pokémon.
; relies on the temporary Arena card variables being listed in a certain order.
; preserves all registers except af
ClearAllStatusConditions::
	push hl
	ldh a, [hWhoseTurn]
	ld h, a
	xor a
	ld l, DUELVARS_ARENA_CARD_STATUS
	ld [hl], a ; NO_STATUS
	ld l, DUELVARS_ARENA_CARD_SUBSTATUS1
	ld [hl], a
	ld l, DUELVARS_ARENA_CARD_SUBSTATUS2
	ld [hl], a
	ld l, DUELVARS_ARENA_CARD_CHANGED_WEAKNESS
	ld [hl], a
	ld l, DUELVARS_ARENA_CARD_CHANGED_RESISTANCE
	ld [hl], a
	ld l, DUELVARS_ARENA_CARD_SUBSTATUS3
	res SUBSTATUS3_THIS_TURN_DOUBLE_DAMAGE_F, [hl]
	ld l, DUELVARS_ARENA_CARD_DISABLED_ATTACK_INDEX
	ld [hli], a
	ld [hli], a ; DUELVARS_ARENA_CARD_LAST_TURN_DAMAGE
	ld [hli], a ; DUELVARS_ARENA_CARD_LAST_TURN_DAMAGE + 1
	ld [hli], a ; DUELVARS_ARENA_CARD_LAST_TURN_STATUS
	ld [hli], a ; DUELVARS_ARENA_CARD_LAST_TURN_SUBSTATUS2
	ld [hli], a ; DUELVARS_ARENA_CARD_LAST_TURN_CHANGE_WEAK
	ld [hli], a ; DUELVARS_ARENA_CARD_LAST_TURN_EFFECT
	ld [hl], a  ; ?
	pop hl
	ret


; Removes a Pokémon from the hand and places it in the Arena or else
; the first available Bench slot. If the Pokémon is placed in the Arena,
; then the status conditions affecting the player's Active Pokémon are cleared.
; Relies on the play area location variables being listed in a certain order.
; preserves bc and d
; input:
;	a = deck index of the Pokémon to put into play
; output:
;	a & e = the given Pokémon's new play area location offset (PLAY_AREA_* constant)
;	carry = set:  if there wasn't space for the Pokémon (i.e. already 6 Pokémon in the play area)
PutHandPokemonCardInPlayArea::
	push af
	; check if there's an open play area slot
	ld a, DUELVARS_NUMBER_OF_POKEMON_IN_PLAY_AREA
	get_turn_duelist_var
	cp MAX_PLAY_AREA_POKEMON
	jr nc, .already_max_pkmn_in_play

	; remove card from hand and set new card location
	inc [hl] ; increment number of play area Pokémon
	ld e, a ; play area offset to place card
	pop af
	push af
	call PutHandCardInPlayArea
	ld a, e
	add DUELVARS_ARENA_CARD
	ld l, a
	pop af
	ld [hl], a ; set card in arena or benchx
	call LoadCardDataToBuffer2_FromDeckIndex

	; reset variable for specific card flags (e.g. CAN_EVOLVE_THIS_TURN_F)
	push de
	ld de, DUELVARS_ARENA_CARD_FLAGS - DUELVARS_ARENA_CARD
	add hl, de ; l = DUELVARS_ARENA_CARD_FLAGS + e
	ld [hl], d ; [w*CardFlags] = $00 (all flags unset)

	; set Pokémon HP variable
	ld e, MAX_PLAY_AREA_POKEMON ; offset for all other play area location variables
	add hl, de ; l = DUELVARS_ARENA_CARD_HP + e
	ld a, [wLoadedCard2HP]
	ld [hl], a ; [w*CardHP] = max HP value of card being played

	; set Pokémon Stage variable
	add hl, de ; l = DUELVARS_ARENA_CARD_STAGE + e
	ld a, [wLoadedCard2Stage]
	ld [hl], a ; [w*CardStage] = CARD_DATA_STAGE constant of card being played

	; reset changed type/color variable
	add hl, de ; l = DUELVARS_ARENA_CARD_CHANGED_TYPE + e
	ld [hl], d ; [w*CardChangedType] = $00

	; reset variable for the number of attached Defender cards
	add hl, de ; l = DUELVARS_ARENA_CARD_ATTACHED_DEFENDER + e
	ld [hl], d ; [w*CardAttachedDefender] = $00

	; reset variable for the number of attached PlusPower cards
	add hl, de ; l = DUELVARS_ARENA_CARD_ATTACHED_PLUSPOWER + e
	ld [hl], d ; [w*CardAttachedPluspower] = $00
	pop de

	; check if this card is the new Active Pokémon, and if so, clear temporary status
	ld a, e
	or a ; cp PLAY_AREA_ARENA
	call z, ClearAllStatusConditions ; only call if Pokémon is being placed in the Arena
	ld a, e
	or a
	ret

.already_max_pkmn_in_play
	pop af
	scf
	ret


; Removes a card from the hand and changes its location to Arena or Bench.
; Given that DUELVARS_ARENA_CARD or DUELVARS_BENCH aren't affected,
; this function is only meant for Energy, Trainer, or Evolution cards.
; preserves bc and de
; input:
;	a = deck index of the card
;	e = play area location offset (PLAY_AREA_* constant)
; output:
;	a = CARD_LOCATION_PLAY_AREA + e
PutHandCardInPlayArea::
	call RemoveCardFromHand
	; a = DUELVARS_CARD_LOCATIONS + index for card from input
	get_turn_duelist_var
	ld a, e
	or CARD_LOCATION_PLAY_AREA
	ld [hl], a
	ret


; moves the turn holder's Pokémon in location e to the discard pile
; preserves bc and de
; input:
;	e = play area location offset (PLAY_AREA_* constant)
MovePlayAreaCardToDiscardPile::
	call EmptyPlayAreaSlot
	ld l, DUELVARS_NUMBER_OF_POKEMON_IN_PLAY_AREA
	dec [hl]
	ld l, DUELVARS_CARD_LOCATIONS + DECK_SIZE
.next_card
	dec l ; go through deck indices in reverse order
	ld a, e
	or CARD_LOCATION_PLAY_AREA
	cp [hl]
	jr nz, .not_in_location
	ld a, l
	call PutCardInDiscardPile
.not_in_location
	ld a, l
	or a
	jr nz, .next_card
	ret


; initializes a turn holder's play area slot to empty.
; which slot (arena or benchx) is determined by the input in e.
; relies on the play area location variables being listed in a certain order.
; preserves bc and de
; input:
;	e = play area location offset (PLAY_AREA_* constant)
EmptyPlayAreaSlot::
	push de
	; clear Pokémon card's deck index
	ld d, -1
	ld a, DUELVARS_ARENA_CARD
	add e
	get_turn_duelist_var
	ld [hl], d ; [w*Card] = -1 (empty)

	; reset variable for specific card flags (e.g. CAN_EVOLVE_THIS_TURN_F)
	ld de, DUELVARS_ARENA_CARD_FLAGS - DUELVARS_ARENA_CARD
	add hl, de ; l = DUELVARS_ARENA_CARD_FLAGS + e
	ld [hl], d ; [w*CardFlags] = $00 (all flags unset)

	; reset Pokémon HP variable
	ld e, MAX_PLAY_AREA_POKEMON ; offset for all other play area location variables
	add hl, de ; l = DUELVARS_ARENA_CARD_HP + e
	ld [hl], d ; [w*CardHP] = $00 (0 HP)

	; reset Pokémon Stage variable
	add hl, de ; l = DUELVARS_ARENA_CARD_STAGE + e
	ld [hl], d ; [w*CardStage] = $00 (BASIC)

	; reset changed type/color variable
	add hl, de ; l = DUELVARS_ARENA_CARD_CHANGED_TYPE + e
	ld [hl], d ; [w*CardChangedType] = $00

	; reset variable for the number of attached Defender cards
	add hl, de ; l = DUELVARS_ARENA_CARD_ATTACHED_DEFENDER + e
	ld [hl], d ; [w*CardAttachedDefender] = $00

	; reset variable for the number of attached PlusPower cards
	add hl, de ; l = DUELVARS_ARENA_CARD_ATTACHED_PLUSPOWER + e
	ld [hl], d ; [w*CardAttachedPluspower] = $00
	pop de
	ret


; shifts play area Pokémon of both players to the first available play area (arena + benchx) slots
; preserves bc
ShiftAllPokemonToFirstPlayAreaSlots::
	rst SwapTurn
	call ShiftTurnPokemonToFirstPlayAreaSlots
	rst SwapTurn
;	fallthrough

; shifts play area Pokémon of the turn holder to the first available play area (arena + benchx) slots
; preserves bc
ShiftTurnPokemonToFirstPlayAreaSlots::
	ld a, DUELVARS_ARENA_CARD
	get_turn_duelist_var
	lb de, PLAY_AREA_ARENA, PLAY_AREA_ARENA
.next_play_area_slot
	bit 7, [hl] ; cp -1
	jr nz, .empty_slot
	call SwapPlayAreaPokemon
	inc e
.empty_slot
	inc hl
	inc d
	ld a, d
	cp MAX_PLAY_AREA_POKEMON
	jr nz, .next_play_area_slot
	ret


; swaps the data of the turn holder's Active Pokémon with the
; data of the turn holder's Benched Pokémon in location e.
; reset the status and all substatuses of the Active Pokémon before swapping.
; preserves all registers except af and d
; input:
;	e = play area location offset of the Benched Pokémon (PLAY_AREA_* constant)
SwapArenaWithBenchPokemon::
	call ClearAllStatusConditions
	ld d, PLAY_AREA_ARENA
;	fallthrough

; swaps the data of the turn holder's Pokémon in location d with the
; data of the turn holder's Pokémon in location e.
; preserves all registers except af
; input:
;	d = play area location offset of the first Pokémon (PLAY_AREA_* constant)
;	e = play area location offset of the second Pokémon (PLAY_AREA_* constant)
SwapPlayAreaPokemon::
	push bc
	push de
	push hl
	ld a, e
	cp d
	jr z, .done
	ldh a, [hWhoseTurn]
	ld h, a
	ld b, a
	ld a, DUELVARS_ARENA_CARD
	call .swap_duelvar
	ld a, DUELVARS_ARENA_CARD_HP
	call .swap_duelvar
	ld a, DUELVARS_ARENA_CARD_FLAGS
	call .swap_duelvar
	ld a, DUELVARS_ARENA_CARD_STAGE
	call .swap_duelvar
	ld a, DUELVARS_ARENA_CARD_CHANGED_TYPE
	call .swap_duelvar
	ld a, DUELVARS_ARENA_CARD_ATTACHED_PLUSPOWER
	call .swap_duelvar
	ld a, DUELVARS_ARENA_CARD_ATTACHED_DEFENDER
	call .swap_duelvar
	set CARD_LOCATION_PLAY_AREA_F, d
	set CARD_LOCATION_PLAY_AREA_F, e
	ld l, DUELVARS_CARD_LOCATIONS + DECK_SIZE
.update_card_locations_loop
	; update card locations of the two swapped cards
	dec l ; go through deck indices in reverse order
	ld a, [hl]
	cp e
	jr nz, .next1
	ld a, d
	jr .update_location
.next1
	cp d
	jr nz, .next2
	ld a, e
.update_location
	ld [hl], a
.next2
	ld a, l
	or a
	jr nz, .update_card_locations_loop
.done
	pop hl
	pop de
	pop bc
	ret

.swap_duelvar
	ld c, a
	add e ; play area location offset of card 2
	ld l, a
	ld a, c
	add d ; play area location offset of card 1
	ld c, a
	ld a, [bc]
	push af
	ld a, [hl]
	ld [bc], a
	pop af
	ld [hl], a
	ret


; calculates the damage and maximum HP of the Pokémon at location e.
; preserves all registers except af and c
; input:
;	e = play area location offset of the Pokémon to check (PLAY_AREA_* constant)
; output:
;	a = damage
;	c = maximum HP value
;	[wLoadedCard2] = all of the card data for the Pokémon in the given location (card_data_struct)
GetCardDamageAndMaxHP::
	push hl
	ld a, DUELVARS_ARENA_CARD
	add e
	get_turn_duelist_var
	call LoadCardDataToBuffer2_FromDeckIndex
	ld a, DUELVARS_ARENA_CARD_HP
	add e
	get_turn_duelist_var
	ld a, [wLoadedCard2HP]
	ld c, a
	sub [hl]
	pop hl
	ret


; Finds which and how many Energy cards are attached to the turn holder's
; Active or Benched Pokémon, depending on the value of register e.
; preserves all registers except af
; input:
;	e = play area location offset (PLAY_AREA_* constant)
; output:
;	a & [wTotalAttachedEnergies] = total amount of Energy attached to the Pokémon
;	[wAttachedEnergies] (8 bytes) = how many Energy of each type is attached to the Pokémon
GetPlayAreaCardAttachedEnergies::
	push hl
	push de
	push bc
	xor a
	ld c, NUM_TYPES
	ld hl, wAttachedEnergies
.zero_energies_loop
	ld [hli], a
	dec c
	jr nz, .zero_energies_loop
	ld b, a              ; b  = $00
	; a = DUELVARS_CARD_LOCATIONS
	get_turn_duelist_var ; hl = starting address for turn holder's card location data
	ld d, DECK_SIZE      ; d  = number of cards to check (60)
	set CARD_LOCATION_PLAY_AREA_F, e ; convert PLAY_AREA_* constant to CARD_LOCATION_* constant
.loop_all_cards
	ld a, [hl]
	cp e
	jr nz, .next_card ; skip if wrong location
	ld a, l
	call GetCardTypeFromDeckIndex_SaveDE
	bit TYPE_ENERGY_F, a
	jr z, .next_card ; skip if wrong card type
	and TYPE_PKMN ; zero bit 3 to extract the type
	ld c, a
	push hl
	ld hl, wAttachedEnergies
	add hl, bc
	inc [hl] ; increment the number of Energy cards of this type
	cp COLORLESS
	jr nz, .not_colorless
	inc [hl] ; each Colorless Energy counts as two
.not_colorless
	pop hl
.next_card
	inc l
	dec d
	jr nz, .loop_all_cards
	; all 60 cards checked
	ld hl, wAttachedEnergies
	ld c, NUM_TYPES
	xor a
.sum_attached_energies_loop
	add [hl]
	inc hl
	dec c
	jr nz, .sum_attached_energies_loop
	ld [hl], a ; save to wTotalAttachedEnergies
	pop bc
	pop de
	pop hl
	ret


; finds the Retreat Cost of one of the turn holder's in-play Pokémon,
; adjusting for any Retreat Aid Pokémon Power that is active.
; preserves de and b
; input:
;	[hTempPlayAreaLocation_ff9d] = play area location offset of the Pokémon to check (PLAY_AREA_* constant)
; output:
;	a = Retreat Cost of the Pokémon in the given location, after applying any modifiers
;	[wLoadedCard1] = all of the card data for the Pokémon in the given location (card_data_struct)
GetPlayAreaCardRetreatCost::
	ldh a, [hTempPlayAreaLocation_ff9d]
	add DUELVARS_ARENA_CARD
	get_turn_duelist_var
	call LoadCardDataToBuffer1_FromDeckIndex
;	fallthrough

; finds the Retreat Cost of the card in wLoadedCard1
; preserves de and b
; input:
;	[wLoadedCard1] = all of the card data for the Pokémon being checked (card_data_struct)
; output:
;	a = given Pokémon's Retreat Cost, after applying any modifiers
GetLoadedCard1RetreatCost::
	ld c, 0 ; Dodrio counter
	ld a, DUELVARS_BENCH
	get_turn_duelist_var
.check_bench_loop
	ld a, [hli]
	cp -1 ; empty play area slot?
	jr z, .no_more_bench
	call _GetCardIDFromDeckIndex
	cp DODRIO
	jr nz, .check_bench_loop
	inc c
	jr .check_bench_loop

.no_more_bench
	ld a, c
	or a
	jr nz, .dodrio_found
.use_default_retreat_cost
	ld a, [wLoadedCard1RetreatCost]
	ret

.dodrio_found
	call CheckIfPkmnPowersAreCurrentlyDisabled
	ld a, [wLoadedCard1RetreatCost]
	ret c ; return with normal Retreat Cost if Pokémon Powers are currently disabled
	sub c ; subtract 1 for each Dodrio on the turn holder's Bench (because of Retreat Aid)
	ret nc ; return if the Pokémon's Retreat Cost isn't a negative number
	xor a ; set the Pokémon's Retreat Cost to 0
	ret


; preserves bc and de
; input:
;	e = card ID to search
;	b = location to consider (CARD_LOCATION_* constant)
; output:
;	a = how many of the given card exists in the given location
CountCardIDInLocation::
	push bc
	xor a
	ld c, a ; initial counter = 0
	; a = DUELVARS_CARD_LOCATIONS
	get_turn_duelist_var
	; hl = starting address for turn holder's card location data
.loop_all_cards
	ld a, [hl]
	cp b
	jr nz, .next_card ; skip if wrong location
	ld a, l
	call _GetCardIDFromDeckIndex
	cp e
	jr nz, .next_card ; skip if wrong card ID
	inc c
.next_card
	inc l
	ld a, l
	cp DECK_SIZE
	jr c, .loop_all_cards
	ld a, c
	pop bc
	ret


; the turn holder's Active Pokémon does a given amount of damage to itself
; because of an attack effect (e.g. Thrash, Selfdestruct).
; also displays the recoil attack animation.
; input:
;	a = damage to deal to self
DealRecoilDamageToSelf::
	push af
	ld a, ATK_ANIM_RECOIL_HIT
	ld [wLoadedAttackAnimation], a
	pop af
;	fallthrough

; the turn holder's Active Pokémon does a given amount of damage to itself.
; also displays the animation at wLoadedAttackAnimation (e.g. ATK_ANIM_CONFUSION_HIT)
; input:
;	a = damage to deal to self
;	[wLoadedAttackAnimation] = which attack animation to play (ATK_ANIM_* constant)
DealDamageToSelf::
	ld hl, wDamage
	ld [hli], a
	ld [hl], 0
	ld a, [wNoDamageOrEffect]
	push af
	xor a ; FALSE
	ld [wNoDamageOrEffect], a
	ld [wAttackAnimationIsPlaying], a
	ld a, [wTempNonTurnDuelistCardID]
	push af
	ld a, [wTempTurnDuelistCardID]
	ld [wTempNonTurnDuelistCardID], a
	call ApplyDamageModifiers_DamageToSelf
	ld a, [wDamageEffectiveness]
	ld c, a
	ld b, PLAY_AREA_ARENA
	ld a, DUELVARS_ARENA_CARD_HP
	get_turn_duelist_var
	bank1call PlayAttackAnimation_DealAttackDamageSimple
	call PrintKnockedOutIfHLZero
	pop af
	ld [wTempNonTurnDuelistCardID], a
	pop af
	ld [wNoDamageOrEffect], a
	ret


; doubles wDamage if the turn holder's Active Pokémon has Weakness
; to its own type/color and reduces wDamage by 30 if the turn holder's
; Active Pokémon has Resistance to its own type/color.
; sets the damage to 0 if reduction would result in a negative value.
; input:
;	[wDamage] = damage value to modify
; output:
;	de = updated damage value
ApplyDamageModifiers_DamageToSelf::
	xor a
	ld [wDamageEffectiveness], a
	ld hl, wDamage
	ld a, [hli]
	or [hl]
	or a
	jr z, .no_damage
	ld d, [hl]
	dec hl
	ld e, [hl]
	call GetArenaCardColor
	call TranslateColorToWR
	ld b, a
	call GetArenaCardWeakness
	and b
	jr z, .not_weak
	sla e
	rl d
	ld hl, wDamageEffectiveness
	set WEAKNESS, [hl]
.not_weak
	call GetArenaCardResistance
	and b
	jr z, .not_resistant
	ld hl, -30 ; Resistance is always -30 in this game
	add hl, de
	ld e, l
	ld d, h
	ld hl, wDamageEffectiveness
	set RESISTANCE, [hl]
.not_resistant
	ld b, CARD_LOCATION_ARENA
	call ApplyAttachedPluspower
	ld b, CARD_LOCATION_ARENA
	call ApplyAttachedDefender
	bit 7, d ; test for underflow
	ret z
.no_damage
	ld de, 0 ; caps damage to 0
	ret


; increases de by 10 points for each Pluspower found in location b
; preserves bc
; input:
;	b = location to consider (CARD_LOCATION_* constant)
;	de = base damage
; output:
;	de = updated damage
ApplyAttachedPluspower::
	push de
	ld de, PLUSPOWER
	call CountCardIDInLocation
	ld l, a
	ld h, 10
	call HtimesL
	pop de
	add hl, de
	ld e, l
	ld d, h
	ret


; reduces de by 20 points for each Defender found in location b
; preserves bc
; input:
;	b = location to consider (CARD_LOCATION_* constant)
;	de = base damage
; output:
;	de = updated damage
ApplyAttachedDefender::
	push de
	ld de, DEFENDER
	call CountCardIDInLocation
	ld l, a
	ld h, 20
	call HtimesL
	pop de
	ld a, e
	sub l
	ld e, a
	ld a, d
	sbc h
	ld d, a
	ret


; preserves all registers except af
; input:
;	hl = address from which to subtract the HP
;	de = how much HP to subtract (damage to deal)
; output:
;	carry = set:  if the HP value is still greater than 0
SubtractHP::
	ld a, [hl]
	sub e
	ld [hl], a
	ld a, $0
	sbc d
	and $80
	jr z, .no_underflow
	ld [hl], 0
.no_underflow
	ld a, [hl]
	or a
	ret z ; return nc if the Pokémon is Knocked Out
	scf
	ret


; given a play area location offset in a, checks if the turn holder's Pokémon
; in that location has 0 HP, and if so, prints that it was Knocked Out.
; input:
;	a = play area location offset (PLAY_AREA_* constant)
; output:
;	carry = set:  if the Pokémon was Knocked Out
PrintPlayAreaCardKnockedOutIfNoHP::
	ld e, a
	add DUELVARS_ARENA_CARD_HP
	get_turn_duelist_var
	or a
	ret nz ; return if the target Pokémon has more than 0 HP
	ld a, [wTempNonTurnDuelistCardID]
	push af
	ld a, e
	add DUELVARS_ARENA_CARD
	get_turn_duelist_var
	call _GetCardIDFromDeckIndex
	ld [wTempNonTurnDuelistCardID], a
	call PrintKnockedOut
	pop af
	ld [wTempNonTurnDuelistCardID], a
	scf
	ret


; input:
;	[hl] = Pokémon's remaining HP value
; output:
;	carry = set:  if the Pokémon was Knocked Out
PrintKnockedOutIfHLZero::
	ld a, [hl] ; this is supposed to point to a remaining HP value after some form of damage calculation
	or a
	ret nz
;	fallthrough

; prints in a 20x6 text box that the Pokémon at wTempNonTurnDuelistCardID
; was Knocked Out and then waits 40 frames
; input:
;	[wTempNonTurnDuelistCardID] = card ID of the Pokémon that was KO'd
; output:
;	carry = set
PrintKnockedOut::
	ld a, [wTempNonTurnDuelistCardID]
	ld e, a
	call LoadCardDataToBuffer1_FromCardID
	ld hl, wLoadedCard1Name
	ld a, [hli]
	ld h, [hl]
	ld l, a
	call LoadTxRam2
	ldtx hl, WasKnockedOutText
	call DrawWideTextBox_PrintText
	ld a, 40 ; frames to delay
	call DoAFrames
	scf
	ret


; deals damage to the turn holder's Pokémon at a specified location.
; plays the default attack animation on the defending player's play area screen
; when dealing the damage, instead of the main duel interface.
; preserves all registers except af
; input:
;	b = play area location offset of Pokémon being damaged (PLAY_AREA_* constant)
;	de = amount of damage being dealt
;	[wLoadedAttack] = Attacking Pokémon card's attack data (atk_data_struct)
DealDamageToPlayAreaPokemon_RegularAnim::
	ld a, ATK_ANIM_BENCH_HIT
	ld [wLoadedAttackAnimation], a
;	fallthrough

; deals damage to the turn holder's Pokémon at a specified location.
; plays the loaded attack animation on the defending player's play area screen
; when dealing the damage, instead of the main duel interface.
; preserves all registers except af
; input:
;	b = play area location offset of Pokémon being damaged (PLAY_AREA_* constant)
;	de = amount of damage being dealt
;	[wLoadedAttack] = Attacking Pokémon card's attack data (atk_data_struct)
DealDamageToPlayAreaPokemon::
	ld a, b
	ld [wTempPlayAreaLocation_cceb], a
	or a ; cp PLAY_AREA_ARENA
	jr nz, .skip_no_damage_or_effect_check
	ld a, [wNoDamageOrEffect]
	or a
	ret nz
.skip_no_damage_or_effect_check
	push hl
	push de
	push bc
	xor a
	ld [wNoDamageOrEffect], a
	ld a, [wTempPlayAreaLocation_cceb]
	add DUELVARS_ARENA_CARD
	get_turn_duelist_var
	call _GetCardIDFromDeckIndex
	ld [wTempNonTurnDuelistCardID], a
	ld a, [wLoadedAttackCategory]
	cp POKEMON_POWER
	jr z, .skip_defender
	ld a, [wTempPlayAreaLocation_cceb]
	or a ; cp PLAY_AREA_ARENA
	jr nz, .next
	ld a, [wIsDamageToSelf]
	or a
	jr z, .turn_swapped
	ld b, CARD_LOCATION_ARENA
	call ApplyAttachedPluspower
	jr .next
.turn_swapped
	rst SwapTurn
	ld b, CARD_LOCATION_ARENA
	call ApplyAttachedPluspower
	rst SwapTurn
.next
	ld a, [wTempPlayAreaLocation_cceb]
	or CARD_LOCATION_PLAY_AREA
	ld b, a
	call ApplyAttachedDefender
.skip_defender
	ld a, [wTempPlayAreaLocation_cceb]
	or a ; cp PLAY_AREA_ARENA
	jr nz, .in_bench
	push de
	call HandleNoDamageOrEffectSubstatus
	pop de
	call HandleDamageReduction
.in_bench
	bit 7, d
	call nz, PreventAllDamage ; set damage in de to 0 if it's a negative number
	call HandleDamageReductionOrNoDamageFromPkmnPowerEffects
	ld a, [wTempPlayAreaLocation_cceb]
	ld b, a
	or a ; cp PLAY_AREA_ARENA
	jr nz, .benched
	; if it's the Active Pokémon, add damage at de to [wDealtDamage]
	ld hl, wDealtDamage
	ld a, e
	add [hl]
	ld [hli], a
	ld a, d
	adc [hl]
	ld [hl], a
.benched
	ld c, $00
	add DUELVARS_ARENA_CARD_HP
	get_turn_duelist_var
	push af
	bank1call PlayAttackAnimation_DealAttackDamageSimple
	pop af
	or a
	jr z, .skip_knocked_out
	push de
	call PrintKnockedOutIfHLZero
	pop de
.skip_knocked_out
	call HandleStrikesBack_AgainstDamagingAttack
	pop bc
	pop de
	pop hl
	ret


; called after an attack effect does damage to an opponent's Pokémon (even Benched).
; if the damage was greater than 0 and that Pokémon has an active Strikes Back power,
; then the Attacking Pokémon (turn holder's Active Pokémon) also receives 10 damage.
; this function could be moved to another bank if the home bank becomes full.
; doing so would free up over 80 bytes at the cost of a single farcall.
; preserves de and hl
; input:
;	de = amount of damage being dealt
;	[wLoadedAttack] = Attacking Pokémon card's attack data (atk_data_struct)
;	[wTempNonTurnDuelistCardID] = card ID of the Pokémon being attacked
;	[wTempPlayAreaLocation_cceb] = play area location offset of the Pokémon being attacked
; output:
;	[wTempNonTurnDuelistCardID] = Attacking Pokémon's card ID:  if Strikes Back power was used
HandleStrikesBack_AgainstDamagingAttack::
	ld a, e
	or d
	ret z ; return nc if no damage is being dealt
	ld a, [wIsDamageToSelf]
	or a
	ret nz ; return if the damage isn't being dealt by an opponent's Pokémon
	ld a, [wTempNonTurnDuelistCardID]
	cp MACHAMP
	ret nz ; return if the Pokémon being attacked isn't a Machamp
	ld a, [wLoadedAttackCategory]
	cp POKEMON_POWER
	ret z ; return if the damage is being dealt by a Pokémon Power
	ld a, [wTempPlayAreaLocation_cceb]
	call CheckIsIncapableOfUsingPkmnPower
	ret c ; return if Pokémon Power can't be used because of status or Toxic Gas
	push hl
	push de
	; subtract 10 HP from Attacking Pokémon (turn holder's Active Pokémon)
	rst SwapTurn
	ld a, DUELVARS_ARENA_CARD
	get_turn_duelist_var
	call LoadCardDataToBuffer2_FromDeckIndex
	ld a, DUELVARS_ARENA_CARD_HP
	get_turn_duelist_var
	push af
	push hl
	ld de, 10
	call SubtractHP
	ld a, [wLoadedCard2ID]
	ld [wTempNonTurnDuelistCardID], a
	ld hl, 10
	call LoadTxRam3
	ld hl, wLoadedCard2Name
	ld a, [hli]
	ld h, [hl]
	ld l, a
	call LoadTxRam2
	ldtx hl, ReceivesDamageDueToStrikesBackText
	call DrawWideTextBox_WaitForInput
	pop hl
	pop af
	or a
	jr z, .not_knocked_out
	xor a ; PLAY_AREA_ARENA
	call PrintPlayAreaCardKnockedOutIfNoHP
.not_knocked_out
	pop de
	pop hl
	jp SwapTurn


; plays an attack animation
; preserves all registers except af
; input:
;	b = play area location offset (PLAY_AREA_* constant), if applicable
;	c = wDamageEffectiveness constant (to print WEAK or RESIST if necessary)
;	de = damage dealt by the attack (to display the animation with the number)
;	h = hWhoseTurn constant (for animation screen coordinates)
;	[wLoadedAttackAnimation] = which animation to play (ATK_ANIM_* constant)
PlayAttackAnimation::
	ldh a, [hWhoseTurn]
	push af
	push hl
	push de
	push bc
	ld a, c
	ld [wDamageAnimEffectiveness], a
	ld a, [wWhoseTurn]
	ldh [hWhoseTurn], a
	cp h
	jr z, .got_location
	; on the non-turn duelist's side
	set 7, b
.got_location
	ld a, b
	ld [wDamageAnimPlayAreaLocation], a
	ld a, [wWhoseTurn]
	ld [wDamageAnimPlayAreaSide], a
	ld a, [wTempNonTurnDuelistCardID]
	ld [wDamageAnimCardID], a
	ld hl, wDamageAnimAmount
	ld [hl], e
	inc hl
	ld [hl], d

; if damage >= 70, ATK_ANIM_HIT becomes ATK_ANIM_BIG_HIT
	ld a, [wLoadedAttackAnimation]
	cp ATK_ANIM_HIT
	jr nz, .got_anim
	ld a, e
	cp 70
	jr c, .got_anim
	ld a, ATK_ANIM_BIG_HIT
	ld [wLoadedAttackAnimation], a

.got_anim
	farcall PlayAttackAnimationCommands
	pop bc
	pop de
	pop hl
	pop af
	ldh [hWhoseTurn], a
	ret


; if [wLoadedAttackAnimation] != 0 (ATK_ANIM_NONE), then wait until the animation is over.
; preserves all registers except af
WaitAttackAnimation::
	ld a, [wLoadedAttackAnimation]
	or a
	ret z
.anim_loop
	call DoFrame
	call CheckAnyAnimationPlaying
	jr c, .anim_loop
	ret


; checks if a flag of wLoadedAttack is set
; preserves all registers except af
; input:
;	a = %fffffbbb (fffff = flag address counting from wLoadedAttackFlag1,
;	               bbb = flag bit)
;	[wLoadedAttack] = attack data for the Pokémon being checked (atk_data_struct)
; output:
;	carry = set:  if the flag from input was set
CheckLoadedAttackFlag::
	push hl
	push de
	push bc
	ld c, a ; %fffffbbb
	and $07
	ld e, a
	ld d, $00
	ld hl, PowersOf2
	add hl, de
	ld b, [hl]
	ld a, c
	rra
	rra
	rra
	and $1f
	ld e, a ; %000fffff
	ld hl, wLoadedAttackFlag1
	add hl, de
	ld a, [hl]
	and b
	jr z, .done
	scf ; set carry if the attack has this flag set
.done
	pop bc
	pop de
	pop hl
	ret

PowersOf2::
	db $01, $02, $04, $08, $10, $20, $40, $80


; uses a card's deck index to check whether or not it is a Basic Pokémon
; preserves all registers except af
; input:
;	a = deck index (0-59) of the card being checked
; output:
;	carry = set:  if the card was a Basic Pokémon
;	[wLoadedCard2] = all of the given card's data (card_data_struct)
CheckDeckIndexForBasicPokemon::
	call LoadCardDataToBuffer2_FromDeckIndex
	ld a, [wLoadedCard2Type]
	cp TYPE_ENERGY
	ret nc ; return if it isn't a Pokémon
	ld a, [wLoadedCard2Stage]
	or a
	ret nz ; return if its Stage isn't Basic
	; is Basic
	scf
	ret


; preserves bc and de
InitPlayAreaScreenVars::
	ld hl, wExcludeArenaPokemon
	xor a ; FALSE
	ld [hli], a ; wExcludeArenaPokemon  = FALSE
	ld [hli], a ; wPlayAreaScreenLoaded = FALSE
	ld [hl], a  ; wPlayAreaSelectAction = FALSE
	ret


; preserves bc and de
InitPlayAreaScreenVars_OnlyBench::
	ld hl, wExcludeArenaPokemon
	ld a, TRUE
	ld [hli], a ; wExcludeArenaPokemon  = TRUE
	xor a ; FALSE
	ld [hli], a ; wPlayAreaScreenLoaded = FALSE
	ld [hl], a  ; wPlayAreaSelectAction = FALSE
	ret


;----------------------------------------
;        UNREFERENCED FUNCTIONS
;----------------------------------------
;
;; searches the turn holder's discard pile for a card, removes it,
;; and then puts that card on top of the turn holder's deck.
;; preserves all registers
;; input:
;;	a = deck index (0-59) of the discarded card to return to the deck
;MoveCardFromDiscardPileToTopOfDeck::
;	call RemoveCardFromDiscardPile
;	jp ReturnCardToDeck
;
;
;; searches the turn holder's deck for a card, removes it,
;; and then puts that card into the turn holder's discard pile.
;; preserves all registers
;; input:
;;	a = deck index (0-59) of the card to discard from the deck
;MoveCardFromDeckToDiscardPile::
;	call RemoveCardFromDeck
;	jp PutCardInDiscardPile
;
;
;; puts the top card of the turn holder's deck into the turn holder's discard pile
;; preserves all registers except af
;DiscardACardFromTopOfDeck::
;	call DrawCardFromDeck
;	ret c ; return if there are no cards in the deck
;	jp PutCardInDiscardPile
;
;
;; returns in the z flag whether the turn holder's prize in a (0-7) has been drawn or not
;; preserves bc
;; input:
;;	a = Prize card (0-7)
;; output:
;;	z = set:  if the Prize card has already been drawn
;CheckPrizeTaken::
;	ld e, a
;	ld d, 0
;	ld hl, PowersOf2
;	add hl, de
;	ld a, [hl]
;	ld e, a
;	cpl
;	ld d, a
;	ld a, DUELVARS_PRIZES
;	get_turn_duelist_var
;	and e
;	ret
;
;
;; input:
;;	hl = ID for notification text
;Func_17ed::
;	call DrawWideTextBox_WaitForInput
;	xor a
;	ld hl, wDamage
;	ld [hli], a
;	ld [hl], a
;	ld a, NO_DAMAGE_OR_EFFECT_ATTACK
;	ld [wNoDamageOrEffect], a
;	bank1call HandleAfterDamageEffects
;	ret
