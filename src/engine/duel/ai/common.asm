; probability to return carry:
; - 50% if deck AI is playing is on the list;
; - 25% for all other decks;
; - 0% for boss decks.
; used for certain decks to randomly choose
; not to play Trainer card or use PKMN Power
AIChooseRandomlyNotToDoAction:
; boss decks always use Trainer cards.
	farcall CheckIfNotABossDeckID
	ret nc

.check_deck
	ld a, [wOpponentDeckID]
	cp MUSCLES_FOR_BRAINS_DECK_ID
	jr z, .carry_50_percent
	cp BLISTERING_POKEMON_DECK_ID
	jr z, .carry_50_percent
	cp WATERFRONT_POKEMON_DECK_ID
	jr z, .carry_50_percent
	cp BOOM_BOOM_SELFDESTRUCT_DECK_ID
	jr z, .carry_50_percent
	cp KALEIDOSCOPE_DECK_ID
	jr z, .carry_50_percent
	cp RESHUFFLE_DECK_ID
	jr z, .carry_50_percent

; carry 25 percent
	ld a, 4
	call Random
	cp 1
	ret

.carry_50_percent
	ld a, 4
	call Random
	cp 2
	ret

; runs through Player's whole deck and
; sets carry if there's any Pokemon other
; than MewtwoLv53.
CheckIfPlayerHasPokemonOtherThanMewtwoLv53:
	rst SwapTurn
	ld e, DECK_SIZE
.loop_deck
	dec e ; go through deck indices in reverse order
	ld a, e
	call LoadCardDataToBuffer2_FromDeckIndex
	ld a, [wLoadedCard2Type]
	cp TYPE_ENERGY
	jr nc, .next
	ld a, [wLoadedCard2ID]
	cp MEWTWO_LV53
	jr nz, .not_mewtwo1
.next
	ld a, e
	or a
	jr nz, .loop_deck
	; no carry
	jp SwapTurn

.not_mewtwo1
	scf
	jp SwapTurn

; lists in wDuelTempList all the basic energy cards
; in card location of a.
; outputs in a number of cards found.
; returns carry if none were found.
; input:
;   a = CARD_LOCATION_* to look
; output:
;   a = number of cards found
FindBasicEnergyCardsInLocation:
	ld [wTempAI], a
	lb de, 0, DECK_SIZE
	ld hl, wDuelTempList

; d = number of basic energy cards found
; e = current card in deck
; loop entire deck
.loop
	dec e ; go through deck indices in reverse order
	ld a, e ; DUELVARS_CARD_LOCATIONS + current deck index
	push hl
	get_turn_duelist_var
	ld hl, wTempAI
	cp [hl]
	pop hl
	jr nz, .next_card

; is in the card location we're looking for
	ld a, e
	call _GetCardIDFromDeckIndex
	cp DOUBLE_COLORLESS_ENERGY
	; only basic energy cards
	; will set carry here
	jr nc, .next_card

; is a basic energy card
; add this card to the TempList
	ld a, e
	ld [hli], a
	inc d
.next_card
	ld a, e
	or a
	jr nz, .loop

.terminate_list
	ld a, $ff ; list is $ff-terminated
	ld [hl], a ; add terminating byte to wDuelTempList
	ld a, d
	or a
	ret nz ; return no carry if there's at least one card in the list
	; list is empty, so return carry
	scf
	ret

; returns in a the card index of energy card
; attached to Pokémon in Play Area location a,
; that is to be discarded by the AI for an effect.
; outputs $ff is none was found.
; input:
;	a = PLAY_AREA_* constant of card
; output:
;	a = deck index of attached energy card chosen
AIPickEnergyCardToDiscard:
; load Pokémon's attached energy cards.
	ldh [hTempPlayAreaLocation_ff9d], a
	call CreateArenaOrBenchEnergyCardList
	or a
	jr z, PickAttachedEnergyCardToRemove.no_energy

; load card's ID and type.
	ldh a, [hTempPlayAreaLocation_ff9d]
	add DUELVARS_ARENA_CARD
	get_turn_duelist_var
	call LoadCardDataToBuffer1_FromDeckIndex
	ld [wTempCardID], a
	ld a, [wLoadedCard1Type]
	or TYPE_ENERGY
	ld [wTempCardType], a

; find a card that is not useful.
; if none is found, just return the first energy card attached.
	ld hl, wDuelTempList
.loop
	ld a, [hli]
	cp $ff
	jr z, PickAttachedEnergyCardToRemove.random_energy
	farcall CheckIfEnergyIsUseful
	jr c, .loop

.found
	dec hl
	ld a, [hl]
	ret

; returns in a the deck index of an energy card attached to card
; in player's Play Area location a to remove.
; prioritizes double colorless energy, then any useful energy,
; then defaults to the first energy card attached if neither
; of those are found.
; returns $ff in a if there are no energy cards attached.
; input:
;   a = Play Area location to check
; output:
;   a = deck index of attached energy card
PickAttachedEnergyCardToRemove:
; construct energy list and check if there are any energy cards attached
	ldh [hTempPlayAreaLocation_ff9d], a
	call CreateArenaOrBenchEnergyCardList
	or a
	jr z, .no_energy

; load card data and store its type
	ldh a, [hTempPlayAreaLocation_ff9d]
	add DUELVARS_ARENA_CARD
	get_turn_duelist_var
	call LoadCardDataToBuffer1_FromDeckIndex
	ld [wTempCardID], a
	ld a, [wLoadedCard1Type]
	or TYPE_ENERGY
	ld [wTempCardType], a

; first look for any double colorless energy
	ld hl, wDuelTempList
.loop_1
	ld a, [hli]
	cp $ff
	jr z, .check_useful
	call _GetCardIDFromDeckIndex
	cp DOUBLE_COLORLESS_ENERGY
	jr nz, .loop_1

.found
	dec hl
	ld a, [hl]
	ret

; then look for any energy cards that are useful
.check_useful
	ld hl, wDuelTempList
.loop_2
	ld a, [hli]
	cp $ff
	jr z, .random_energy
	farcall CheckIfEnergyIsUseful
	jr c, .found ; the current Energy card is useful, so pick that
	jr .loop_2

; if none were found with the above criteria,
; just return a random Energy
.random_energy
	call CountCardsInDuelTempList
	ld hl, wDuelTempList
	call ShuffleCards
	ld a, [hl]
	ret

; return $ff if no energy cards attached
.no_energy
	ld a, $ff
	ret

; stores in wTempAI and wCurCardCanAttack the deck indices
; of energy cards attached to card in Play Area location a.
; prioritizes double colorless energy, then any useful energy,
; then defaults to the first two energy cards attached if neither
; of those are found.
; returns $ff in a if there are no energy cards attached.
; input:
;   a = Play Area location to check
; output:
;   [wTempAI] = deck index of attached energy card
;   [wCurCardCanAttack] = deck index of attached energy card
PickTwoAttachedEnergyCards:
	ldh [hTempPlayAreaLocation_ff9d], a
	call CreateArenaOrBenchEnergyCardList
	cp 2
	jr c, PickAttachedEnergyCardToRemove.no_energy

; load card data and store its type
	ldh a, [hTempPlayAreaLocation_ff9d]
	add DUELVARS_ARENA_CARD
	get_turn_duelist_var
	call LoadCardDataToBuffer1_FromDeckIndex
	ld [wTempCardID], a
	ld a, [wLoadedCard1Type]
	or TYPE_ENERGY
	ld [wTempCardType], a
	ld a, $ff
	ld [wTempAI], a
	ld [wCurCardCanAttack], a

; first look for any double colorless energy
	ld hl, wDuelTempList
.loop_1
	ld a, [hl]
	cp $ff
	jr z, .check_useful
	call _GetCardIDFromDeckIndex
	cp DOUBLE_COLORLESS_ENERGY
	jr z, .found_double_colorless
	inc hl
	jr .loop_1
.found_double_colorless
	ld a, [wTempAI]
	cp $ff
	jr nz, .already_chosen
	ld a, [hli]
	ld [wTempAI], a
	jr .loop_1
.already_chosen
	ld a, [hl]
	ld [wCurCardCanAttack], a
	jr .done

; then look for any energy cards that are useful
.check_useful
	ld hl, wDuelTempList
.loop_2
	ld a, [hl]
	cp $ff
	jr z, .default
	farcall CheckIfEnergyIsUseful
	jr c, .found_useful
	inc hl
	jr .loop_2
.found_useful
	ld a, [wTempAI]
	cp $ff
	jr nz, .already_chosen
	ld a, [hli]
	ld [wTempAI], a
	jr .loop_2

; if none were found with the above criteria,
; just return the first 2 options
.default
	ld hl, wDuelTempList
	ld a, [wTempAI]
	cp $ff
	jr nz, .pick_one_card

; pick 2 cards
	ld a, [hli]
	ld [wTempAI], a
	ld a, [hl]
	ld [wCurCardCanAttack], a
	jr .done
.pick_one_card
	ld a, [wTempAI]
	ld b, a
.loop_3
	ld a, [hli]
	cp b
	jr z, .loop_3 ; already picked
	ld [wCurCardCanAttack], a

.done
	ld b, a
	ld a, [wTempAI]
	ret


; copies an $ff-terminated list from hl to de
; preserves bc
; input:
;	hl = address from which to start copying the data
;	de = where to copy the data
CopyListWithFFTerminatorFromHLToDE_Bank8:
	ld a, [hli]
	ld [de], a
	cp $ff
	ret z
	inc de
	jr CopyListWithFFTerminatorFromHLToDE_Bank8


; zeroes a bytes starting from hl.
; this function is identical to 'ClearNBytesFromHL' in Bank $2,
; as well as ClearMemory_Bank5' and 'ClearMemory_Bank6'.
; preserves all registers
; input:
;	a = number of bytes to clear
;	hl = where to begin erasing
ClearMemory_Bank8:
	push af
	push bc
	push hl
	ld b, a
	xor a
.loop
	ld [hli], a
	dec b
	jr nz, .loop
	pop hl
	pop bc
	pop af
	ret


; converts an HP value or amount of damage to the number of equivalent damage counters
; preserves all registers except af
; input:
;	a = number to convert to damage counters
; output:
;	a = number of damage counters
ConvertHPToDamageCounters_Bank8:
	push bc
	ld c, 0
.loop
	sub 10
	jr c, .done
	inc c
	jr .loop
.done
	ld a, c
	pop bc
	ret


; calculates floor(hl / 10)
; preserves bc and de
; input:
;	hl = number
CalculateWordTensDigit:
	push bc
	push de
	lb bc, $ff, -10
	lb de, $ff, -1
.asm_229b8
	inc de
	add hl, bc
	jr c, .asm_229b8
	ld h, d
	ld l, e
	pop de
	pop bc
	ret


; returns in a the division of b by a, rounded down
; preserves all registers except af
; input:
;	b = dividend
;	a = divisor
; output:
;	a = quotient (without remainder)
CalculateBDividedByA_Bank8:
	push bc
	ld c, a
	ld a, b ; a = input b
	ld b, c ; b = input a
	ld c, 0
.loop
	sub b
	jr c, .done
	inc c
	jr .loop
.done
	ld a, c
	pop bc
	ret


; input:
;   a = CARD_LOCATION_* constant
;   e = card ID to look for
; output:
;	a & e = deck index of a matching card, if any
;	carry = set:  if the given card was found in the given location
LookForCardIDInLocation_Bank8:
	ld b, a
	ld c, e
	ld e, DECK_SIZE
.loop
	dec e ; go through deck indices in reverse order
	ld a, e ; DUELVARS_CARD_LOCATIONS + current deck index
	get_turn_duelist_var
	cp b
	jr nz, .next
	ld a, e
	call _GetCardIDFromDeckIndex
	cp c
	ld a, e
	scf
	ret z ; return carry with deck index in a if a match was found
.next
	or a
	jr nz, .loop
	; none found, so return no carry
	ret


; checks the AI's hand for a specific card
; input:
;	a = card ID
; output:
;	a = deck index for a copy of the given card in the turn holder's hand ($ff if none)
;	carry = set:  if the given card ID was found in the turn holder's hand
LookForCardIDInHandList_Bank8:
	ld [wTempCardIDToLook], a
	call CreateHandCardList
	ld hl, wDuelTempList

.loop
	ld a, [hli]
	cp $ff
	ret z
	ldh [hTempCardIndex_ff98], a
	call GetCardIDFromDeckIndex
	ld a, [wTempCardIDToLook]
	cp e
	jr nz, .loop

	ldh a, [hTempCardIndex_ff98]
	scf
	ret


; checks the AI's hand and play area for a specific card.
; input:
;	a = card ID
; output:
;	carry = set:  if the given card ID was found in the turn holder's hand or
;	              if the given card ID was found in the turn holder's play area
LookForCardIDInHandAndPlayArea:
	ld b, a
	push bc
	call LookForCardIDInHandList_Bank8
	pop bc
	ret c

	ld a, b
	ld b, PLAY_AREA_ARENA
;	fallthrough

; checks the AI's play area for a specific card.
; preserves de
; input:
;	a = card ID
;	b = play area location offset to start with (PLAY_AREA_* constant)
; output:
;	a = the given card's play area location offset (first copy, more might exist)
;	  = $ff:  if none of the Pokémon in the turn holder's play area have the given card ID
;	carry = set:  if the given card ID was found in the turn holder's play area
LookForCardIDInPlayArea_Bank8:
	ld c, a
.loop
	ld a, DUELVARS_ARENA_CARD
	add b
	get_turn_duelist_var
	cp $ff
	ret z
	call _GetCardIDFromDeckIndex
	cp c
	jr z, .found
	inc b
	jr .loop

.found
	ld a, b
	scf
	ret


; searches in deck for card ID 1 in a, and
; if found, searches in Hand/Play Area for card ID 2 in b, and
; if found, searches for card ID 1 in Hand/Play Area, and
; if none found, return carry and output deck index
; of the card ID 1 in deck.
; input:
;   a = card ID 1
;   b = card ID 2
; output:
;   a = index of card ID 1 in deck
LookForCardIDInDeck_GivenCardIDInHandAndPlayArea:
; store a in wCurCardCanAttack
; and b in wTempAI
	ld [wCurCardCanAttack], a
	ld hl, wTempAI
	ld [hl], b

; look for the card ID 1 in deck
	ld e, a
	ld a, CARD_LOCATION_DECK
	call LookForCardIDInLocation_Bank8
	ret nc

; was found, store its deck index in memory
	ld [wTempAIPokemonCard], a

; look for the card ID 2
; in Hand and Play Area, return if not found.
	ld a, [wTempAI]
	call LookForCardIDInHandAndPlayArea
	ret nc

; look for the card ID 1 in the Hand and Play Area
; if any card is found, return no carry.
	ld a, [wCurCardCanAttack]
	call LookForCardIDInHandAndPlayArea
	ccf
	ld a, [wTempAIPokemonCard]
	ret


; searches in deck for card ID 1 in a, and
; if found, searches in Hand Area for card ID 2 in b, and
; if found, searches for card ID 1 in Hand/Play Area, and
; if none found, return carry and output deck index
; of the card ID 1 in deck.
; input:
;   a = card ID 1
;   b = card ID 2
; output:
;   a = index of card ID 1 in deck
LookForCardIDInDeck_GivenCardIDInHand:
; store a in wCurCardCanAttack
; and b in wTempAI
	ld [wCurCardCanAttack], a
	ld hl, wTempAI
	ld [hl], b

; look for the card ID 1 in deck
	ld e, a
	ld a, CARD_LOCATION_DECK
	call LookForCardIDInLocation_Bank8
	ret nc

; was found, store its deck index in memory
	ld [wTempAIPokemonCard], a

; look for the card ID 2 in hand, return if not found.
	ld a, [wTempAI]
	call LookForCardIDInHandList_Bank8
	ret nc

; look for the card ID 1 in the Hand and Play Area
; if any card is found, return no carry.
	ld a, [wCurCardCanAttack]
	call LookForCardIDInHandAndPlayArea
	ccf
	ld a, [wTempAIPokemonCard]
	ret


; runs through list avoiding card in e.
; removes first card in list not equal to e
; and that has a type allowed to be removed, in d.
; returns carry if successful in finding a card.
; input:
;   d = type of card allowed to be removed
;       ($00 = Trainer, $01 = Pokemon, $02 = Energy)
;   e = card deck index to avoid removing
; output:
;   a = card index of removed card
RemoveFromListDifferentCardOfGivenType:
	push hl
	push de
	call CountCardsInDuelTempList
	call ShuffleCards

; loop list until a card with
; deck index different from e is found.
.loop_list
	ld a, [hli]
	cp $ff
	jr z, .no_carry
	cp e
	jr z, .loop_list

; get this card's type
	ldh [hTempCardIndex_ff98], a
	call GetCardTypeFromDeckIndex_SaveDE
	cp TYPE_ENERGY
	jr c, .pkmn_card
	cp TYPE_TRAINER
	jr nz, .energy

; only remove from list specific type.

; trainer
	ld a, d
	or a
	jr nz, .loop_list
	jr .remove_card
.energy
	ld a, d
	cp $02
	jr nz, .loop_list
	jr .remove_card
.pkmn_card
	ld a, d
	cp $01
	jr nz, .loop_list
	; fallthrough

.remove_card
	ld d, h
	ld e, l
	dec hl
.loop_remove
	ld a, [de]
	inc de
	ld [hli], a
	cp $ff
	jr nz, .loop_remove

; success
	ldh a, [hTempCardIndex_ff98]
	pop de
	pop hl
	scf
	ret
.no_carry
	pop de
	pop hl
	or a
	ret

; used in Pokemon Trader checks to look for a specific
; card in the deck to trade with a card in hand that
; has a card ID different from e.
; returns carry if successful.
; input:
;   a = card ID 1
;   e = card ID 2
; output:
;   a = deck index of card ID 1 found in deck
;   e = deck index of Pokemon card in hand different than card ID 2
LookForCardIDToTradeWithDifferentHandCard:
	ld hl, wCurCardCanAttack
	ld [hl], e
	ld [wTempAI], a

; if card ID 1 is in hand, return no carry.
	call LookForCardIDInHandList_Bank8
	ccf
	ret nc

; if card ID 1 is not in deck, return no carry.
	ld a, [wTempAI]
	ld e, a
	ld a, CARD_LOCATION_DECK
	call LookForCardIDInLocation_Bank8
	ret nc

; store its deck index
	ld [wTempAI], a

; look in hand for Pokemon card ID that
; is different from card ID 2.
	ld a, [wCurCardCanAttack]
	ld c, a
	call CreateHandCardList
	ld hl, wDuelTempList

.loop_hand
	ld a, [hli]
	cp $ff
	ret z ; nc
	ld e, a
	call LoadCardDataToBuffer1_FromDeckIndex
	cp c
	jr z, .loop_hand
	ld a, [wLoadedCard1Type]
	cp TYPE_ENERGY
	jr nc, .loop_hand

; found, output deck index of card ID 1 in deck
; and deck index of card found in hand, and return carry
	ld a, [wTempAI]
	ret

; returns carry if at least one card in the hand
; has the card ID of input. Outputs its index.
; input:
;   a = card ID to look for
; output:
;   a = deck index of card in hand found
CheckIfHasCardIDInHand:
	ld [wTempCardIDToLook], a
	call CreateHandCardList
	ld hl, wDuelTempList
	ld c, 0

.loop_hand
	ld a, [hli]
	cp $ff
	ret z
	ldh [hTempCardIndex_ff98], a
	call GetCardIDFromDeckIndex
	ld a, [wTempCardIDToLook]
	cp e
	jr nz, .loop_hand
	ld a, c
	or a
	jr nz, .set_carry
	inc c
	jr .loop_hand

.set_carry
	ldh a, [hTempCardIndex_ff98]
	scf
	ret

; outputs in a total number of Pokemon cards in hand
; plus Pokemon in Turn Duelist's Play Area.
CountPokemonCardsInHandAndInPlayArea:
	ld a, DUELVARS_NUMBER_OF_POKEMON_IN_PLAY_AREA
	get_turn_duelist_var
	ld [wTempAI], a
	call CreateHandCardList
	ld hl, wDuelTempList
.loop_hand
	ld a, [hli]
	cp $ff
	jr z, .done
	call GetCardIDFromDeckIndex
	call GetCardType
	cp TYPE_ENERGY
	jr nc, .loop_hand
	ld a, [wTempAI]
	inc a
	ld [wTempAI], a
	jr .loop_hand
.done
	ld a, [wTempAI]
	ret

; returns carry if a duplicate Pokemon card is found in hand.
; outputs in a the deck index of one of them.
FindDuplicatePokemonCards:
	call CreateHandCardList
	ld hl, wDuelTempList
	push hl

.loop_hand_outer
	pop hl
	ld a, [hli]
	cp $ff
	ret z ; nc
	call _GetCardIDFromDeckIndex
	ld b, a
	push hl

.loop_hand_inner
	ld a, [hli]
	cp $ff
	jr z, .loop_hand_outer
	ld c, a
	call GetCardIDFromDeckIndex
	ld a, e
	cp b
	jr nz, .loop_hand_inner

; found two cards with same ID,
; if Pokémon, return carry with deck index in a.
	call GetCardType
	cp TYPE_ENERGY
	jr nc, .loop_hand_outer
	pop hl
	ld a, c
	ret

; finds duplicates in card list in hl.
; if a duplicate of Pokemon cards are found, return in
; a the deck index of the second one.
; otherwise, if a duplicate of non-Pokemon cards are found
; return in a the deck index of the second one.
; if no duplicates found, return carry.
; input:
;   hl = list to look in
; output:
;   a = deck index of duplicate card
FindDuplicateCards:
	push hl
	ld a, $ff
	ld [wce0f], a

.loop_outer
; get ID of current card
	pop hl
	ld a, [hli]
	cp $ff
	jr z, .check_found
	call _GetCardIDFromDeckIndex
	ld b, a
	push hl

; loop the rest of the list to find
; another card with the same ID
.loop_inner
	ld a, [hli]
	cp $ff
	jr z, .loop_outer
	ld c, a
	call GetCardIDFromDeckIndex
	ld a, e
	cp b
	jr nz, .loop_inner

; found two cards with same ID
	call GetCardType
	cp TYPE_ENERGY
	jr nc, .not_pokemon

; they are Pokémon cards, so return carry
; with the found deck index in a
	pop hl
	ld a, c
	ret

; they are energy or trainer cards
.not_pokemon
; loads wce0f with this card deck index
	ld a, c
	ld [wce0f], a
	jr .loop_outer

.check_found
	ld a, [wce0f]
	cp $ff
	ret z ; return no carry if no duplicate cards were found
	; two non-Pokémon cards with the same ID were found
	scf
	ret

; searches the list at hl for the deck index in a
; and if found, that card is removed from the list.
; preserves all registers except af and b
; input:
;	a  = item to remove from the list
;	hl = pointer to an $ff-terminated list
FindAndRemoveCardFromList:
	push hl
	ld b, a
.loop_duplicate
	ld a, [hli]
	cp $ff
	jr z, .done
	cp b
	jr nz, .loop_duplicate
	call RemoveCardFromList
.done
	pop hl
	ret

; remove an element from the list
; and shortens it accordingly
; input:
;   hl = pointer to element after the one to remove
RemoveCardFromList:
	push de
	ld d, h
	ld e, l
	dec hl
	push hl
.loop_remove
	ld a, [de]
	ld [hli], a
	cp $ff
	jr z, .done_remove
	inc de
	jr .loop_remove
.done_remove
	pop hl
	pop de
	ret

; return carry flag if attack is high recoil.
AICheckIfAttackIsHighRecoil:
	farcall AIProcessButDontUseAttack
	ret nc
	ld a, [wSelectedAttack]
	ld e, a
	ld a, DUELVARS_ARENA_CARD
	get_turn_duelist_var
	ld d, a
	call CopyAttackDataAndDamage_FromDeckIndex
	ld a, ATTACK_FLAG1_ADDRESS | HIGH_RECOIL_F
	jp CheckLoadedAttackFlag

; checks every Pokémon with attached Energy in the turn holder's play area,
; starting with e. compares each Pokémon that's found and stores the greatest
; amount of damage that any of these Pokémon can do to the Defending Pokémon in wce06.
; the location of the Pokémon with the highest damaging attack is stored in wce08.
; input:
;	e = play area location offset of the first Pokémon to check (PLAY_AREA_* constant)
; output:
;	[wce06] = greatest amount of damage that one of the turn holder's Pokémon
;	          with any attached Energy can do to the Defending Pokémon
;	[wce08] = play area location offset of the Pokémon with attached Energy that
;	          can do the most damage to the Defending Pokémon (PLAY_AREA_ARENA if none)
FindEnergizedPokemonWithHighestDamagingAttack:
	xor a
	ld [wce06], a
	ld [wce08], a
.loop_play_area
	ld a, DUELVARS_ARENA_CARD
	add e
	get_turn_duelist_var
	cp $ff
	ret z ; return when there are no more Pokémon to check in the turn holder's play area
	call GetPlayAreaCardAttachedEnergies
	or a
	call nz, .check_attacks_for_current_pokemon
	inc e
	jr .loop_play_area

; preserves de
; input:
;	e = play area location offset of the Pokémon to check (PLAY_AREA_* constant)
.check_attacks_for_current_pokemon
	ld a, e
	ldh [hTempPlayAreaLocation_ff9d], a
	xor a ; FIRST_ATTACK_OR_PKMN_POWER
	call .compare_this_attack_with_one_stored
	ld a, SECOND_ATTACK
;	fallthrough

; preserves de
; input:
;	a = which attack to check (0 = first attack, 1 = second attack)
;	[hTempPlayAreaLocation_ff9d] = play area location offset of the Pokémon to check (PLAY_AREA_* constant)
; output:
;	carry = set:  if this attack's damage was higher than the one stored in wce06
.compare_this_attack_with_one_stored
	push de
	farcall EstimateDamage_VersusDefendingCard
	ld a, [wDamage]
	or a
	jr z, .skip
	ld e, a
	ld a, [wce06]
	cp e
	jr nc, .skip
	ld a, e
	ld [wce06], a ; store this damage value
	pop de
	ld a, e
	ld [wce08], a ; store this location
	ret
.skip
	pop de
	ret
