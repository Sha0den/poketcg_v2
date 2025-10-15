; sets up the initial hand for a boss deck.
; always draws at least 2 Basic Pokémon cards and 2 Energy cards.
; also sets up so that the next cards to be drawn have
; some minimum number of Basic Pokémon and Energy cards.
SetUpBossStartingHandAndDeck:
; shuffle all hand cards into the deck
	ld a, DUELVARS_HAND
	get_turn_duelist_var
	ld b, STARTING_HAND_SIZE
.loop_hand
	ld a, [hl]
	call MoveCardFromHandToTopOfDeck
	dec b
	jr nz, .loop_hand
	jr .count_energy_basic

.shuffle_deck
	call ShuffleDeck

; count the number of Basic Pokémon and Energy cards
; in the top STARTING_HAND_SIZE (7) cards of the deck.
.count_energy_basic
	xor a
	ld [wAISetupBasicPokemonCount], a
	ld [wAISetupEnergyCount], a

	ld a, DUELVARS_DECK_CARDS
	get_turn_duelist_var
	ld b, STARTING_HAND_SIZE
	call .Loop_Deck

; tally the number of Basic Pokémon and Energy cards,
; and if any of them is smaller than 2, re-shuffle deck.
	ld a, [wAISetupBasicPokemonCount]
	cp 2
	jr c, .shuffle_deck
	ld a, [wAISetupEnergyCount]
	cp 2
	jr c, .shuffle_deck

; now check the following 6 cards (potential Prize cards).
; re-shuffle the deck if any of these cards is listed in wAICardListAvoidPrize.
	ld b, 6
.check_card_ids
	ld a, [hli]
	ld d, a
	push hl
	ld hl, wAICardListAvoidPrize
	ld a, [hli]
	ld h, [hl]
	ld l, a
	or h
	ld a, d
	call nz, .CheckIfIDIsInList ; only check if pointer isn't null
	pop hl
	jr c, .shuffle_deck
	dec b
	jr nz, .check_card_ids

; finally, check 6 cards after that.
; if Energy or Basic Pokémon counter is below 4
; (counting with the ones found in the initial hand)
; then re-shuffle deck.
	ld b, 6
	call .Loop_Deck

	ld a, [wAISetupBasicPokemonCount]
	cp 4
	jr c, .shuffle_deck
	ld a, [wAISetupEnergyCount]
	cp 4
	jr c, .shuffle_deck

; draw the new starting hand
	ld a, DUELVARS_DECK_CARDS
	get_turn_duelist_var
	ld b, STARTING_HAND_SIZE
.draw_loop
	ld a, [hli]
	call MoveCardFromDeckToHand
	dec b
	jr nz, .draw_loop
	ret


; preserves bc
; input:
;	a = deck index of the card that should be checked
;	hl = $00-terminated list of card IDs
; output:
;	carry = set:  if the card ID corresponding to the given deck index was in the given list
.CheckIfIDIsInList
	call GetCardIDFromDeckIndex
.loop_id_list
	ld a, [hli]
	or a
	ret z ; return no carry if there are no more card IDs to check
	cp e
	jr nz, .loop_id_list
	scf
	ret


; looks at b cards from the list of deck indices at hl and
; counts how many of them are Basic Pokémon and Energy cards.
; preserves de
; input:
;	hl = list with deck indices of cards to check
;	 b = number of cards to check from the list
; output:
;	[wAISetupEnergyCount] += number of Energy cards that were found
;	[wAISetupBasicPokemonCount] += number of Basic Pokémon that were found
.Loop_Deck
	ld a, [hli]
	call LoadCardDataToBuffer1_FromDeckIndex
	ld a, [wLoadedCard1Type]
	cp TYPE_ENERGY
	jr c, .pokemon_card
	cp TYPE_TRAINER
	jr z, .next_card_deck

; energy card
	ld a, [wAISetupEnergyCount]
	inc a
	ld [wAISetupEnergyCount], a
	jr .next_card_deck

.pokemon_card
	ld a, [wLoadedCard1Stage]
	or a ; cp BASIC
	jr nz, .next_card_deck
	ld a, [wAISetupBasicPokemonCount]
	inc a
	ld [wAISetupBasicPokemonCount], a

.next_card_deck
	dec b
	jr nz, .Loop_Deck
	ret
