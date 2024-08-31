; runs through Player's whole deck and
; sets carry if there's any Pokemon other
; than MewtwoLv53.
CheckIfPlayerHasPokemonOtherThanMewtwoLv53:
	rst SwapTurn
	ld e, 0
.loop_deck
	ld a, e
	call LoadCardDataToBuffer2_FromDeckIndex
	ld a, [wLoadedCard2Type]
	cp TYPE_ENERGY
	jr nc, .next
	ld a, [wLoadedCard2ID]
	cp MEWTWO_LV53
	jr nz, .not_mewtwo1
.next
	inc e
	ld a, DECK_SIZE
	cp e
	jr nz, .loop_deck

; no carry
	or a
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
	lb de, 0, 0
	ld hl, wDuelTempList

; d = number of basic energy cards found
; e = current card in deck
; loop entire deck
.loop
	ld a, DUELVARS_CARD_LOCATIONS
	add e
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
	inc e
	ld a, DECK_SIZE
	cp e
	jr nz, .loop

; check if any were found
	ld a, d
	or a
	jr z, .set_carry

; some were found, add the termination byte on TempList
	ld a, $ff
	ld [hl], a
	ld a, d
	ret

.set_carry
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
	ldh a, [hTempPlayAreaLocation_ff9d]
	ld e, a
	call GetPlayAreaCardAttachedEnergies
;	ld a, [wTotalAttachedEnergies] ; already loaded
	or a
	jr z, .no_energy

; load card's ID and type.
	ldh a, [hTempPlayAreaLocation_ff9d]
	ld b, a
	ld a, DUELVARS_ARENA_CARD
	add b
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
	ld a, [hl]
	cp $ff
	jr z, .not_found
	farcall CheckIfEnergyIsUseful
	jr nc, .found
	inc hl
	jr .loop

.not_found
	ld hl, wDuelTempList
.found
	ld a, [hl]
	ret
.no_energy
	ld a, $ff
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
	ldh a, [hTempPlayAreaLocation_ff9d]
	ld e, a
	call GetPlayAreaCardAttachedEnergies
;	ld a, [wTotalAttachedEnergies] ; already loaded
	or a
	jr z, .no_energy

; load card data and store its type
	ldh a, [hTempPlayAreaLocation_ff9d]
	ld b, a
	ld a, DUELVARS_ARENA_CARD
	add b
	get_turn_duelist_var
	call LoadCardDataToBuffer1_FromDeckIndex
	ld [wTempCardID], a
	ld a, [wLoadedCard1Type]
	or TYPE_ENERGY
	ld [wTempCardType], a

; first look for any double colorless energy
	ld hl, wDuelTempList
.loop_1
	ld a, [hl]
	cp $ff
	jr z, .check_useful
	call _GetCardIDFromDeckIndex
	cp DOUBLE_COLORLESS_ENERGY
	jr z, .found
	inc hl
	jr .loop_1

; then look for any energy cards that are useful
.check_useful
	ld hl, wDuelTempList
.loop_2
	ld a, [hl]
	cp $ff
	jr z, .default
	farcall CheckIfEnergyIsUseful
	jr c, .found ; the current Energy card is useful, so pick that
	inc hl
	jr .loop_2

; if none were found with the above criteria,
; just return the first option
.default
	ld hl, wDuelTempList
.found
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
	ldh a, [hTempPlayAreaLocation_ff9d]
	ld e, a
	call CountNumberOfEnergyCardsAttached_Bank8
	cp 2
	jr c, PickAttachedEnergyCardToRemove.no_energy

; load card data and store its type
	ldh a, [hTempPlayAreaLocation_ff9d]
	ld b, a
	ld a, DUELVARS_ARENA_CARD
	add b
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
	ld a, [wCurCardCanAttack]
	ld b, a
	ld a, [wTempAI]
	ret


; returns in a the number of Energy cards attached to Pokémon
; at the play area location in e. assumes that Colorless are paired,
; meaning that every Colorless Energy card provides 2 Colorless Energy.
; preserves all registers except af
; input:
;	e = play area location offset to check (PLAY_AREA_* constant)
; output:
;	a = number of Energy cards attached to the Pokémon in the given location
CountNumberOfEnergyCardsAttached_Bank8:
	call GetPlayAreaCardAttachedEnergies
;	ld a, [wTotalAttachedEnergies] ; already loaded
	or a
	ret z

	xor a
	push hl
	push bc
	ld b, NUM_COLORED_TYPES
	ld hl, wAttachedEnergies
; sum all of the attached Energy cards
.loop
	add [hl]
	inc hl
	dec b
	jr nz, .loop

	ld b, [hl]
	srl b
; counts Colorless and halves it
	add b
	pop bc
	pop hl
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


; counts number of energy cards found in hand
; and outputs result in a
; sets carry if none are found
; output:
;	a = number of energy cards found
CountOppEnergyCardsInHand:
	farcall CreateEnergyCardListFromHand
	ret c
	ld b, -1
	ld hl, wDuelTempList
.loop
	inc b
	ld a, [hli]
	cp $ff
	jr nz, .loop
	ld a, b
	or a
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
;	lb de, 0, 0 ; d is never used
	ld e, 0
.loop
	ld a, DUELVARS_CARD_LOCATIONS
	add e
	get_turn_duelist_var
	cp b
	jr nz, .next
	ld a, e
	call _GetCardIDFromDeckIndex
	cp c
	jr z, .found
.next
	inc e
	ld a, DECK_SIZE
	cp e
	jr nz, .loop

; not found
	or a
	ret

.found
	ld a, e
	scf
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
	call LoadCardDataToBuffer1_FromDeckIndex
	ld b, a
	ld a, [wTempCardIDToLook]
	cp b
	jr nz, .loop

	ldh a, [hTempCardIndex_ff98]
	scf
	ret


; checks the AI's play area for a specific card.
; preserves de
; input:
;	a = card ID
;	b = play area location offset to start with (PLAY_AREA_* constant)
; output:
;	a = the given card's play area location offset (first copy, more might exist)
;	carry = set:  if the given card ID was found in the turn holder's play area
LookForCardIDInPlayArea_Bank8:
	ld [wTempCardIDToLook], a
.loop
	ld a, DUELVARS_ARENA_CARD
	add b
	get_turn_duelist_var
	cp $ff
	ret z
	call LoadCardDataToBuffer1_FromDeckIndex
	ld c, a
	ld a, [wTempCardIDToLook]
	cp c
	jr z, .found
	inc b
	ld a, MAX_PLAY_AREA_POKEMON
	cp b
	jr nz, .loop

	ld b, $ff
	or a
	ret

.found
	ld a, b
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
	call LookForCardIDInPlayArea_Bank8
	ret c
	or a
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
	ld c, a
	ld a, b
	ld [wTempAI], a
	ld a, c
	ld [wCurCardCanAttack], a

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
	jr c, .no_carry
; none found

	ld a, [wTempAIPokemonCard]
	scf
	ret

.no_carry
	or a
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
	ld c, a
	ld a, b
	ld [wTempAI], a
	ld a, c
	ld [wCurCardCanAttack], a

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
	jr c, .no_carry
; none found

	ld a, [wTempAIPokemonCard]
	scf
	ret

.no_carry
	or a
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
	push bc
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
	pop bc
	pop de
	pop hl
	scf
	ret
.no_carry
	pop bc
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
	jr c, .no_carry

; if card ID 1 is not in deck, return no carry.
	ld a, [wTempAI]
	ld e, a
	ld a, CARD_LOCATION_DECK
	call LookForCardIDInLocation_Bank8
	jr nc, .no_carry

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
	jr z, .no_carry
	ld b, a
	call LoadCardDataToBuffer1_FromDeckIndex
	cp c
	jr z, .loop_hand
	ld a, [wLoadedCard1Type]
	cp TYPE_ENERGY
	jr nc, .loop_hand

; found, output deck index of card ID 1 in deck
; and deck index of card found in hand, and set carry
	ld e, b
	ld a, [wTempAI]
	scf
	ret

.no_carry
	or a
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
	call LoadCardDataToBuffer1_FromDeckIndex
	ld b, a
	ld a, [wTempCardIDToLook]
	cp b
	jr nz, .loop_hand
	ld a, c
	or a
	jr nz, .set_carry
	inc c
	jr nz, .loop_hand

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
	ld a, $ff
	ld [wTempAI], a
	call CreateHandCardList
	ld hl, wDuelTempList
	push hl

.loop_hand_outer
	pop hl
	ld a, [hli]
	cp $ff
	jr z, .done
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
; if they are Pokemon cards, store its deck index.
	call GetCardType
	cp TYPE_ENERGY
	jr nc, .loop_hand_outer
	ld a, c
	ld [wTempAI], a
	; for some reason loop still continues
	; even though if some other duplicate
	; cards are found, it overwrites the result.
	jr .loop_hand_outer

.done
	ld a, [wTempAI]
	cp $ff
	jr z, .no_carry

; found
	scf
	ret
.no_carry
	or a
	ret

; return carry flag if attack is not high recoil.
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
	call CheckLoadedAttackFlag
	ccf
	ret

; stores in wce06 the highest damaging attack
; for the card in play area location in e
; and stores this card's location in wce08
FindHighestDamagingAttack:
	push de
	ld a, e
	ldh [hTempPlayAreaLocation_ff9d], a

	xor a ; FIRST_ATTACK_OR_PKMN_POWER
	farcall EstimateDamage_VersusDefendingCard
	ld a, [wDamage]
	or a
	jr z, .skip_1
	ld e, a
	ld a, [wce06]
	cp e
	jr nc, .skip_1
	ld a, e
	ld [wce06], a ; store this damage value
	pop de
	ld a, e
	ld [wce08], a ; store this location
	jr .second_attack

.skip_1
	pop de

.second_attack
	push de
	ld a, e
	ldh [hTempPlayAreaLocation_ff9d], a

	ld a, SECOND_ATTACK
	farcall EstimateDamage_VersusDefendingCard
	ld a, [wDamage]
	or a
	jr z, .skip_2
	ld e, a
	ld a, [wce06]
	cp e
	jr nc, .skip_2
	ld a, e
	ld [wce06], a ; store this damage value
	pop de
	ld a, e
	ld [wce08], a ; store this location
	ret
.skip_2
	pop de
	ret
