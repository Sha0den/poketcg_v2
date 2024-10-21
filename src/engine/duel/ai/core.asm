INCLUDE "engine/duel/ai/damage_calculation.asm"
INCLUDE "engine/duel/ai/deck_ai.asm"
INCLUDE "engine/duel/ai/init.asm"
INCLUDE "engine/duel/ai/retreat.asm"
INCLUDE "engine/duel/ai/hand_pokemon.asm"
INCLUDE "engine/duel/ai/energy.asm"
INCLUDE "engine/duel/ai/attacks.asm"
INCLUDE "engine/duel/ai/special_attacks.asm"
INCLUDE "engine/duel/ai/boss_deck_set_up.asm"


; input:
;	[hTempPlayAreaLocation_ff9d] = Attacking Pokémon's play area location offset (PLAY_AREA_* constant)
; output:
;	carry = set:  if any of the given Pokémon's attacks can KO the Defending Pokémon
;	[wSelectedAttack] = index for the first attack that can KO (0 = first attack, 1 = second attack)
CheckIfAnyAttackKnocksOutDefendingCard:
	xor a ; FIRST_ATTACK_OR_PKMN_POWER
	call CheckIfAttackKnocksOutDefendingCard
	ret c
	ld a, SECOND_ATTACK
;	fallthrough

; input:
;	a = which attack to check (0 = first attack, 1 = second attack)
;	[hTempPlayAreaLocation_ff9d] = Attacking Pokémon's play area location offset (PLAY_AREA_* constant)
; output:
;	carry = set:  if the given attack for the Pokémon in the given location can KO the Defending Pokémon
CheckIfAttackKnocksOutDefendingCard:
	call EstimateDamage_VersusDefendingCard
	ld a, DUELVARS_ARENA_CARD_HP
	call GetNonTurnDuelistVariable
	dec a ; subtract 1 so carry will be set if final HP = 0
	ld hl, wDamage
	sub [hl]
	ret


; checks AI scores for all Benched Pokémon
; output:
;	a & [hTempPlayAreaLocation_ff9d] = play area location offset of the Benched Pokémon
;	                                   with the highest AI score (PLAY_AREA_* constant)
FindHighestBenchScore:
	ld a, DUELVARS_NUMBER_OF_POKEMON_IN_PLAY_AREA
	get_turn_duelist_var
	ld b, a
	ld c, PLAY_AREA_ARENA
	ld d, c
	ld e, c ; initial score for comparison = 0
	ld hl, wPlayAreaAIScore + 1
	jr .next

.loop
	ld a, [hli]
	cp e
	jr c, .next
	ld e, a
	ld d, c
.next
	inc c
	dec b
	jr nz, .loop

	ld a, d
	ldh [hTempPlayAreaLocation_ff9d], a
	or a
	ret


; adds a to wAIScore. if there's an overflow, it's capped at $ff.
; preserves all registers except af
; input:
;	a = number to add to [wAIScore]
; output:
;	a & [wAIScore] = sum of input a and [wAIScore] (capped at $ff)
AddToAIScore:
	push hl
	ld hl, wAIScore
	add [hl]
	jr nc, .no_cap
	ld a, $ff
.no_cap
	ld [hl], a
	pop hl
	ret


; subtracts a from wAIScore, unless wAIScore = $00.
; if there's an underflow, it's capped at $00.
; preserves all registers except af
; input:
;	a = number to subtract from [wAIScore]
; output:
;	[wAIScore] = difference between a and wAIScore ($00 if the result was negative)
SubFromAIScore:
	push hl
	push de
	ld e, a
	ld hl, wAIScore
	ld a, [hl]
	or a
	jr z, .done
	sub e
	ld [hl], a
	jr nc, .done
	ld [hl], $00
.done
	pop de
	pop hl
	ret


; loads the Defending Pokémon's Weakness/Resistance
; and the number of Prize cards in both sides.
; preserves bc and de
LoadDefendingPokemonColorWRAndPrizeCards:
	rst SwapTurn
	call GetArenaCardColor
	call TranslateColorToWR
	ld [wAIPlayerColor], a
	call GetArenaCardWeakness
	ld [wAIPlayerWeakness], a
	call GetArenaCardResistance
	ld [wAIPlayerResistance], a
	call CountPrizes
	ld [wAIPlayerPrizeCount], a
	rst SwapTurn
	call CountPrizes
	ld [wAIOpponentPrizeCount], a
	ret


; called when AI has chosen its attack. executes all effects and damage.
; also handles AI choosing parameters for certain attacks as well.
; input:
;	[wSelectedAttack] = attack index (0 = first attack, 1 = second attack)
AITryUseAttack:
	ld a, [wSelectedAttack]
	ldh [hTemp_ffa0], a
	ld e, a
	ld a, DUELVARS_ARENA_CARD
	get_turn_duelist_var
	ldh [hTempCardIndex_ff9f], a
	ld d, a
	call CopyAttackDataAndDamage_FromDeckIndex
	ld a, OPPACTION_BEGIN_ATTACK
	bank1call AIMakeDecision
	ret c ; return if the opponent's turn has ended

	call AISelectSpecialAttackParameters
	jr c, .use_attack
	ld a, EFFECTCMDTYPE_AI_SELECTION
	call TryExecuteEffectCommandFunction

.use_attack
	ld a, [wSelectedAttack]
	ld e, a
	ld a, DUELVARS_ARENA_CARD
	get_turn_duelist_var
	ld d, a
	call CopyAttackDataAndDamage_FromDeckIndex
	ld a, OPPACTION_USE_ATTACK
	bank1call AIMakeDecision
	ret c ; return if the opponent's turn has ended

	ld a, EFFECTCMDTYPE_AI_SWITCH_DEFENDING_PKMN
	call TryExecuteEffectCommandFunction
	ld a, OPPACTION_ATTACK_ANIM_AND_DAMAGE
	bank1call AIMakeDecision
	ret


; picks a random Pokémon on the Bench.
; preserves bc and de
; output:
;	a = play area location offset of the Benched Pokémon that was chosen (PLAY_AREA_* constant)
PickRandomBenchPokemon:
	ld a, DUELVARS_NUMBER_OF_POKEMON_IN_PLAY_AREA
	get_turn_duelist_var
	dec a
	call Random
	inc a
	ret


AIPickPrizeCards:
	ld a, [wNumberPrizeCardsToTake]
	ld b, a
.loop
	call .PickPrizeCard
	ld a, DUELVARS_PRIZES
	get_turn_duelist_var
	or a
	ret z
	dec b
	jr nz, .loop
	ret

; picks a Prize card at random
; and adds it to the hand.
.PickPrizeCard:
	ld a, DUELVARS_PRIZES
	get_turn_duelist_var
	push hl
	ld c, a

; choose a random Prize card until
; one is found that isn't taken already.
.loop_pick_prize
	ld a, 6
	call Random
	ld e, a
	ld d, $00
	ld hl, .prize_flags
	add hl, de
	ld a, [hl]
	and c
	jr z, .loop_pick_prize ; no Prize

; a Prize card was found
; remove this Prize from wOpponentPrizes
	ld a, [hl]
	pop hl
	cpl
	and [hl]
	ld [hl], a

; add this Prize card to the hand
	ld a, e
	add DUELVARS_PRIZE_CARDS
	get_turn_duelist_var
	jp AddCardToHand

.prize_flags
	db $1 << 0
	db $1 << 1
	db $1 << 2
	db $1 << 3
	db $1 << 4
	db $1 << 5
	db $1 << 6
	db $1 << 7


; AI plays all Basic Pokémon from its hand at the start of the duel
AIPlayInitialBasicCards:
	call CreateHandCardList
	ld hl, wDuelTempList
.check_next_card
	ld a, [hli]
	ldh [hTempCardIndex_ff98], a
	cp $ff
	ret z ; return when there are no more hand cards to check

	call CheckDeckIndexForBasicPokemon
	jr nc, .check_next_card ; skip this card if it isn't a Basic Pokémon

; put the Basic Pokémon from the hand into play
	push hl
	ldh a, [hTempCardIndex_ff98]
	call PutHandPokemonCardInPlayArea
	pop hl
	jr .check_next_card


; input:
;	[hTempPlayAreaLocation_ff9d] = Pokémon's play area location offset (PLAY_AREA_* constant)
;	[wSelectedAttack] = attack index (0 = first attack, 1 = second attack)
; output:
;	carry = set:  if the Pokémon in the given location can't use the given attack or
;	              if the attack has FLAG_2_BIT_5 set (Wildfire, Magnetic Storm, and Prophecy)
CheckIfSelectedAttackIsUnusable:
	ldh a, [hTempPlayAreaLocation_ff9d]
	or a ; cp PLAY_AREA_ARENA
	jr nz, .bench

	call HandleCantAttackSubstatus
	ret c
	bank1call CheckIfActiveCardParalyzedOrAsleep
	ret c

	ld a, DUELVARS_ARENA_CARD
	get_turn_duelist_var
	ld d, a
	ld a, [wSelectedAttack]
	ld e, a
	call CopyAttackDataAndDamage_FromDeckIndex
	call HandleAmnesiaSubstatus
	ret c
	ld a, EFFECTCMDTYPE_INITIAL_EFFECT_1
	call TryExecuteEffectCommandFunction
	ret c

.bench
	call CheckEnergyNeededForAttack
	ret c ; can't be used
	ld a, ATTACK_FLAG2_ADDRESS | FLAG_2_BIT_5_F
	jp CheckLoadedAttackFlag


; loads the selected attack of the Pokémon in hTempPlayAreaLocation_ff9d
; and checks if there is enough Energy to execute the selected attack.
; input:
;	[hTempPlayAreaLocation_ff9d] = Pokémon's play area location offset (PLAY_AREA_* constant)
;	[wSelectedAttack] = attack index (0 = first attack, 1 = second attack)
; output:
;	b = amount of Basic/non-Colorless Energy needed before the given attack can be used, if any
;	c = amount of Colorless Energy needed before the given attack can be used, if any
;	carry = set:  if the attack slot is empty, contains a Pokémon Power, or has a cost
;	              that isn't met by the current amount of attached Energy
CheckEnergyNeededForAttack:
	ldh a, [hTempPlayAreaLocation_ff9d]
	add DUELVARS_ARENA_CARD
	get_turn_duelist_var
	ld d, a
	ld a, [wSelectedAttack]
	ld e, a
	call CopyAttackDataAndDamage_FromDeckIndex
	ld hl, wLoadedAttackName
	ld a, [hli]
	or [hl]
	jr z, .no_attack
	ld a, [wLoadedAttackCategory]
	cp POKEMON_POWER
	jr nz, .is_attack
.no_attack
	lb bc, 0, 0
	scf
	ret

.is_attack
	ldh a, [hTempPlayAreaLocation_ff9d]
	ld e, a
	call GetPlayAreaCardAttachedEnergies
;	fallthrough

; GetPlayAreaCardAttachedEnergies should be called before this to provide the attached Energy amounts.
; input:
;	[wLoadedAttack] = attack data for the Pokémon being checked (atk_data_struct)
;	[wAttachedEnergies] = specific Energy amounts that would be used to pay for the given attack (8 bytes)
;	[wTotalAttachedEnergies] = total amount of Energy that could be used to pay for the given attack
; output:
;	b = amount of Basic/non-Colorless Energy needed before the given attack can be used, if any
;	c = amount of Colorless Energy needed before the given attack can be used, if any
;	carry = set:  if the current amount of attached Energy isn't enough to pay the given attack's Energy cost
CalculateEnergyNeededForAttack:
	call HandleEnergyBurn

	; fill wTempLoadedAttackEnergyCost
	ld hl, wLoadedAttackEnergyCost
	ld de, wTempLoadedAttackEnergyCost
	ld b, NUM_TYPES / 2
	call CopyNBytesFromHLToDE

	; clear wTempLoadedAttackEnergyNeededAmount
	; and wTempLoadedAttackEnergyNeededTotal
	ld hl, wTempLoadedAttackEnergyNeededAmount
	ld c, NUM_TYPES / 2 + 1
	xor a
.loop_clear
	ld [hli], a
	dec c
	jr nz, .loop_clear

	ld hl, wAttachedEnergies
	ld de, wLoadedAttackEnergyCost
	ld c, FIRE
.loop
	; check all Basic Energy cards
	call CheckIfEnoughParticularAttachedEnergy
	call CheckIfEnoughParticularAttachedEnergy
	inc de
	ld a, c
	cp NUM_TYPES
	jr nz, .loop

	; count Basic Energy cards in use
	ld hl, wTempLoadedAttackEnergyCost
	ld de, wTempLoadedAttackEnergyNeededAmount
	ld c, 0
	ld a, (NUM_TYPES / 2) - 1
.loop_tally_energies_in_use
	push af
	ld a, [de] ; needed amount
	swap a
	and %1111
	ld b, a
	ld a, [wTempLoadedAttackEnergyNeededTotal]
	add b
	ld [wTempLoadedAttackEnergyNeededTotal], a
	ld a, [hl] ; Energy cost
	swap a
	and %1111
	sub b
	add c
	ld c, a
	ld a, [de] ; needed amount
	inc de
	and %1111
	ld b, a
	ld a, [wTempLoadedAttackEnergyNeededTotal]
	add b
	ld [wTempLoadedAttackEnergyNeededTotal], a
	ld a, [hli] ; Energy cost
	and %1111
	sub b
	add c
	ld c, a
	pop af
	dec a
	jr nz, .loop_tally_energies_in_use

	; colorless
	ld a, [hl]
	swap a
	and %00001111
	ld b, a ; Colorless Energy still needed
	ld a, [wTotalAttachedEnergies]
	sub c
	sub b
	jr c, .not_enough

	ld a, [wTempLoadedAttackEnergyNeededTotal]
	or a
	ret z

; being here means the Energy cost isn't satisfied,
; including with Colorless Energy
	xor a
.not_enough
	cpl
	inc a
	ld c, a ; Colorless Energy still needed
	ld a, [wTempLoadedAttackEnergyNeededTotal]
	ld b, a ; Basic Energy still needed
	scf
	ret


; preserves de
; input:
;	c    = TYPE_* constant
;	[de] = attack's Energy cost
;	[hl] = attached Energy
; output:
;	carry = set:  if not enough of this type/color of Energy is attached
CheckIfEnoughParticularAttachedEnergy:
	ld a, c
	rrca ; carry set if odd
	ld a, [de]
	jr c, .no_swap1
	swap a
.no_swap1
	and %00001111
	jr nz, .check
.has_enough
	inc hl
	inc c
	ret

.check
	sub [hl]
	jr z, .has_enough
	jr c, .has_enough

	; not enough Energy
	push hl
	push bc
	ld hl, wTempLoadedAttackEnergyNeededAmount
	ld b, $00
	rr c ; /2
	jr c, .no_swap2
	swap a
.no_swap2
	add hl, bc
	or [hl]
	ld [hl], a
	pop bc
	pop hl

	inc hl
	inc c
	ret


; finds the first needed Energy card from wTempLoadedAttackEnergyNeededAmount.
; preserves bc and de
; output:
;	a = Energy card ID
GetEnergyCardNeeded:
	push bc
	ld hl, wTempLoadedAttackEnergyNeededAmount
	ld c, FIRE
.loop_find_type
	ld a, c
	rrca ; carry set if odd
	ld a, [hli]
	jr c, .no_swap
	dec hl
	swap a
.no_swap
	and %1111
	jr nz, .found_type
	inc c
	jr .loop_find_type ; we assume this loop will terminate
.found_type
	ld a, c
	pop bc
; fallthrough

; preserves all registers except af
; input:
;	a = Energy type/color
; output:
;	a = Energy card ID
ConvertColorToEnergyCardID:
	push hl
	push de
	ld e, a
	ld d, 0
	ld hl, .card_id
	add hl, de
	ld a, [hl]
	pop de
	pop hl
	ret

.card_id
	db FIRE_ENERGY
	db GRASS_ENERGY
	db LIGHTNING_ENERGY
	db WATER_ENERGY
	db FIGHTING_ENERGY
	db PSYCHIC_ENERGY
	db DOUBLE_COLORLESS_ENERGY


; return carry depending on the deck index in a:
;	- if it's an Energy card, return carry if an Energy card has already been played that turn
;	- if it's a Basic Pokémon card, return carry if there's no space on the AI's Bench
;	- if it's an Evolution card, return carry if if it doesn't evolve from a Pokémon in the AI's play area
;	- if it's a Trainer card, return carry if it can't be used
; input:
;	a = deck index to check
; output:
;	carry = set:  if the given card can't be played
;	[wLoadedCard1] = all of the given card's data (card_data_struct)
CheckIfCardCanBePlayed:
	ldh [hTempCardIndex_ff9f], a
	call LoadCardDataToBuffer1_FromDeckIndex
	ld a, [wLoadedCard1Type]
	cp TYPE_ENERGY
	jr c, .pokemon_card
	cp TYPE_TRAINER
	jr z, .trainer_card

; energy card
	ld a, [wAlreadyPlayedEnergy]
	or a
	ret z
	scf
	ret

.pokemon_card
	ld a, [wLoadedCard1Stage]
	or a ; cp BASIC
	jr nz, .evolution_card
	ld a, DUELVARS_NUMBER_OF_POKEMON_IN_PLAY_AREA
	get_turn_duelist_var
	cp MAX_PLAY_AREA_POKEMON
	ccf
	ret

.evolution_card
	call IsPrehistoricPowerActive
	ret c
	ld a, DUELVARS_NUMBER_OF_POKEMON_IN_PLAY_AREA
	get_turn_duelist_var
	ld c, a
	ldh a, [hTempCardIndex_ff9f]
	ld d, a
	ld e, PLAY_AREA_ARENA
.loop
	call CheckIfCanEvolveInto
	ret nc
	inc e
	dec c
	jr nz, .loop
	scf
	ret

.trainer_card
	call CheckCantUseTrainerDueToEffect
	ret c
	call LoadNonPokemonCardEffectCommands
	ld a, EFFECTCMDTYPE_INITIAL_EFFECT_1
	jp TryExecuteEffectCommandFunction


; lists in wDuelTempList all the Energy cards in the turn holder's hand.
; preserves all registers except af
; output:
;	a = number of Energy cards in the turn holder's hand
;	carry = set:  if no Energy cards were found in the hand
;	wDuelTempList = $ff-terminated list with deck indices of
;	                all Energy cards in the turn holder's hand
CreateEnergyCardListFromHand:
	push hl
	push de
	push bc
	ld b, 0 ; counter
	ld de, wDuelTempList
	ld a, DUELVARS_NUMBER_OF_CARDS_IN_HAND
	get_turn_duelist_var
	or a
	jr z, .terminate_list
	ld c, a
	ld l, LOW(wOpponentHand)

.next_card_loop
	ld a, [hli]
	call GetCardTypeFromDeckIndex_SaveDE
	and TYPE_ENERGY
	jr z, .skip_card
	dec hl
	ld a, [hli]
	ld [de], a
	inc de
	inc b
.skip_card
	dec c
	jr nz, .next_card_loop

.terminate_list
	ld a, $ff ; list is $ff-terminated
	ld [de], a ; add terminating byte to wDuelTempList
	ld a, b
	pop bc
	pop de
	pop hl
	or a
	ret nz ; return no carry if there were no Energy cards in the hand
	scf
	ret


; preserves bc and e
; input:
;	a = CARD_LOCATION_* constant
;	e = card ID to look for
; output:
;	a & l = deck index of a matching card, if any
;	carry = set:  if the given card was found in the given location
LookForCardIDInLocation_Bank5:
	ld d, a
	ldh a, [hWhoseTurn]
	ld h, a
	ld l, DUELVARS_CARD_LOCATIONS + DECK_SIZE
.loop
	dec l ; go through deck indices in reverse order
	ld a, [hl]
	cp d
	ld a, l
	jr nz, .next ; skip if wrong location
	call _GetCardIDFromDeckIndex
	cp e
	ld a, l
	scf
	ret z ; return carry with deck index in a if a match was found
.next
	or a
	jr nz, .loop
	; none found, so return no carry
	ret


; checks the AI's hand for a specific card.
; unlike 'LookForCardIDInHandList_Bank5', this function doesn't create a list,
; the conditions for carry are reversed, and it preserves bc, de, and hl.
; preserves all registers except af
; input:
;	a = card ID
; output:
;	a = deck index for a copy of the given card in the turn holder's hand ($ff if none)
;	carry = set:  if the given card was NOT found in the hand
LookForCardIDInHand:
	push hl
	push bc
	ld b, a
	ld a, DUELVARS_NUMBER_OF_CARDS_IN_HAND
	get_turn_duelist_var
	or a
	jr z, .set_carry
	ld c, a
	ld l, DUELVARS_HAND

.loop
	ld a, [hli]
	call _GetCardIDFromDeckIndex
	cp b
	jr z, .no_carry
.next
	dec c
	jr nz, .loop

.set_carry
	pop bc
	pop hl
	scf
	ret

.no_carry
	dec hl
	ld a, [hl]
	pop bc
	pop hl
	or a
	ret


; checks the AI's hand for a specific card.
; unlike 'LookForCardIDInHand', this function creates a list in wDuelTempList,
; the conditions for carry are reversed, and none of the registers are preserved.
; input:
;	a = card ID
; output:
;	a = deck index for a copy of the given card in the turn holder's hand ($ff if none)
;	carry = set:  if the given card ID was found in the turn holder's hand
LookForCardIDInHandList_Bank5:
	ld [wTempCardIDToLook], a
	call CreateHandCardList
	ld hl, wDuelTempList
.loop
	ld a, [hli]
	cp $ff
	ret z ; return no carry if there are no more cards in the hand to check
	ldh [hTempCardIndex_ff98], a
	call GetCardIDFromDeckIndex
	ld a, [wTempCardIDToLook]
	cp e
	jr nz, .loop

; found a match, so return carry with the deck index in a.
	ldh a, [hTempCardIndex_ff98]
	scf
	ret


; checks the AI's play area for a specific card.
; preserves de
; input:
;	a = card ID
;	b = play area location offset to start with (PLAY_AREA_* constant)
; output:
;	a = play area location offset of the found card (first copy, more might exist)
;	  = $ff:  if none of the Pokémon in the turn holder's play area have the given card ID
;	carry = set:  if the given card ID was found in the turn holder's play area
LookForCardIDInPlayArea_Bank5:
	ld c, a
.loop
	ld a, DUELVARS_ARENA_CARD
	add b
	get_turn_duelist_var
	cp $ff
	ret z ; return no carry if there are more Pokémon in the play area to check
	call _GetCardIDFromDeckIndex
	cp c
	jr z, .found
	inc b
	jr .loop

.found
	ld a, b
	scf
	ret


; checks if there is a copy of the given Energy card in the AI's hand, and if there is,
; it is attached to the first copy of the given Pokémon card in the AI's play area.
; input:
;	e = Energy card ID
;	d = Pokémon card ID
AIAttachEnergyInHandToCardInPlayArea:
	ld a, e
	push de
	call LookForCardIDInHandList_Bank5
	pop de
	ret nc ; return if the Energy card wasn't found in the hand
	ld b, PLAY_AREA_ARENA

.attach
	ld e, a
	ld a, d
	call LookForCardIDInPlayArea_Bank5
	ret nc ; return if the Pokémon wasn't found in the play area
	ldh [hTempPlayAreaLocation_ffa1], a
	ld a, e
	ldh [hTemp_ffa0], a
	ld a, OPPACTION_PLAY_ENERGY
	bank1call AIMakeDecision
	ret

; same as AIAttachEnergyInHandToCardInPlayArea but
; only look for a card ID on the Bench.
; input:
;	e = Energy card ID
;	d = Pokémon card ID
AIAttachEnergyInHandToCardInBench:
	ld a, e
	push de
	call LookForCardIDInHandList_Bank5
	pop de
	ret nc
	ld b, PLAY_AREA_BENCH_1
	jr AIAttachEnergyInHandToCardInPlayArea.attach



; input:
;	e = play area location offset of the Pokémon to check (PLAY_AREA_* constant)
; output:
;	carry = set:  if discarding an Energy card would render any attack unusable,
;	              given that the attack has enough Energy to be used before discarding
CheckIfEnergyDiscardRendersAnyAttackUnusable:
	ld a, e
	ldh [hTempPlayAreaLocation_ff9d], a
	xor a ; FIRST_ATTACK_OR_PKMN_POWER
	call CheckIfEnergyDiscardRendersAttackUnusable
	ret c
	ld a, SECOND_ATTACK
;	fallthrough

; input:
;	a = which attack to check (0 = first attack, 1 = second attack)
;	[hTempPlayAreaLocation_ff9d] = play area location offset of the Pokémon to check (PLAY_AREA_* constant)
; output:
;	carry = set:  if discarding an Energy card would render the given attack unusable,
;	              given that the attack has enough Energy to be used before discarding
CheckIfEnergyDiscardRendersAttackUnusable:
	ld [wSelectedAttack], a
	call CheckEnergyNeededForAttack
	ccf
	ret nc
;	fallthrough

; loads selected attack from Pokémon in hTempPlayAreaLocation_ff9d,
; gets an Energy card to discard and subsequently checks if there is enough Energy
; to execute the selected attack after removing that attached Energy card.
; this is called when deciding whether or not to use a Super Potion.
; input:
;	[hTempPlayAreaLocation_ff9d] = Pokémon's play area location offset (PLAY_AREA_* constant)
;	[wSelectedAttack] = which attack to examine (0 = first attack, 1 = second attack)
; output:
;	b = amount of Basic/non-Colorless Energy that would be needed after discarding, if any
;	c = amount of Colorless Energy that would be needed after discarding, if any
;	carry = set:  if the attack slot is empty, contains a Pokémon Power, or has a cost
;	              that isn't met by the current amount of attached Energy
CheckEnergyNeededForAttackAfterDiscard:
	ldh a, [hTempPlayAreaLocation_ff9d]
	add DUELVARS_ARENA_CARD
	get_turn_duelist_var
	ld d, a
	ld a, [wSelectedAttack]
	ld e, a
	call CopyAttackDataAndDamage_FromDeckIndex
	ld hl, wLoadedAttackName
	ld a, [hli]
	or [hl]
	jr z, .no_attack
	ld a, [wLoadedAttackCategory]
	cp POKEMON_POWER
	jr nz, .is_attack
.no_attack
	lb bc, 0, 0
	scf
	ret

.is_attack
	ldh a, [hTempPlayAreaLocation_ff9d]
	ld e, a
	call GetPlayAreaCardAttachedEnergies
	ld a, e
	farcall AIPickEnergyCardToDiscard
	call _GetCardIDFromDeckIndex
	cp DOUBLE_COLORLESS_ENERGY
	jr z, .colorless

; basic/colored energy
; decrease respective attached Energy by 1.
	ld hl, wAttachedEnergies
	dec a ; because Basic Energy card IDs start at 1, not 0
	ld c, a
	ld b, $00
	add hl, bc
	dec [hl]
	ld hl, wTotalAttachedEnergies
	dec [hl]
	jp CalculateEnergyNeededForAttack

; decrease attached Colorless Energy by 2.
.colorless
	ld hl, wAttachedEnergies + COLORLESS
	dec [hl]
	dec [hl]
	ld hl, wTotalAttachedEnergies
	dec [hl]
	dec [hl]
	jp CalculateEnergyNeededForAttack


; copies an $ff-terminated list from hl to de
; preserves bc
; input:
;	hl = address from which to start copying the data
;	de = where to copy the data
CopyListWithFFTerminatorFromHLToDE_Bank5:
	ld a, [hli]
	ld [de], a
	cp $ff
	ret z
	inc de
	jr CopyListWithFFTerminatorFromHLToDE_Bank5


; zeroes a bytes starting from hl.
; this function is identical to 'ClearMemory_Bank2',
; as well as 'ClearMemory_Bank6' and 'ClearMemory_Bank8'.
; preserves all registers
; input:
;	a = number of bytes to clear
;	hl = where to begin erasing
ClearMemory_Bank5:
	push af
	push bc
	push hl
	ld b, a
	xor a
.clear_loop
	ld [hli], a
	dec b
	jr nz, .clear_loop
	pop hl
	pop bc
	pop af
	ret


; converts an HP value or amount of damage to the number of equivalent damage counters
; preserves all registers except af
; input:
;	a = HP value to convert
; output:
;	a = number of damage counters
ConvertHPToDamageCounters_Bank5:
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


; returns in a the division of b by a, rounded down
; preserves all registers except af
; input:
;	b = dividend
;	a = divisor
; output:
;	a = quotient (without remainder)
CalculateBDividedByA_Bank5:
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


; returns in a the number of Energy cards attached to the Pokémon
; at the play area location in e. assumes that Colorless are paired,
; meaning that every Colorless Energy card provides 2 Colorless Energy.
; preserves all registers except af
; input:
;	e = play area location offset to check (PLAY_AREA_* constant)
; output:
;	a = number of Energy cards attached to the Pokémon in the given location
CountNumberOfEnergyCardsAttached:
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


; counts the total number of Energy cards in the turn holder's hand
; plus all the attached Energy cards in the turn holder's play area.
; output:
;	a & b = total number of Energy cards.
CountOppEnergyCardsInHandAndAttached:
	call CreateEnergyCardListFromHand
	ld b, a

; counts number of attached Energy cards in the play area
	ld a, DUELVARS_NUMBER_OF_POKEMON_IN_PLAY_AREA
	get_turn_duelist_var
	ld d, a
	ld e, PLAY_AREA_ARENA
.loop_play_area
	call CountNumberOfEnergyCardsAttached
	add b
	ld b, a
	inc e
	dec d
	jr nz, .loop_play_area
	ret


; uses a card ID to try to remove a deck index from a list of cards
; preserves all registers except af
; input:
;	c  = card ID to look for
;	hl = $ff-terminated list of deck indices to search
; output:
;	a & [hTempCardIndex_ff98] = deck index that was removed from the list, if any
;	carry = set:  if a card with the given ID was found in the given list
RemoveCardIDInList:
	push hl
	push de
	push bc

.loop_1
	ld a, [hli]
	cp $ff
	jr z, .done ; return no carry if there are no more cards to check

	ldh [hTempCardIndex_ff98], a
	call _GetCardIDFromDeckIndex
	cp c
	jr nz, .loop_1

; found
	ld d, h
	ld e, l
	dec hl

; remove this index from the list
; and reposition the rest of the list ahead.
.loop_2
	ld a, [de]
	inc de
	ld [hli], a
	cp $ff
	jr nz, .loop_2

	ldh a, [hTempCardIndex_ff98]
	scf
.done
	pop bc
	pop de
	pop hl
	ret


; plays Pokémon cards from the hand to set up the starting play area for Boss decks.
; each Boss deck has two ID lists in order of preference.
; one list is for the Active Pokémon and the other is for Benched Pokémon.
; if the Active Pokémon could not be set (due to hand not having any card in its list)
; or if the list is null, return carry and do not play any cards.
; output:
;	carry = set:  if the play area could not be set up
TrySetUpBossStartingPlayArea:
	ld de, wAICardListArenaPriority
	ld a, d
	or a
	scf
	ret z ; return carry if pointer is null

; pick the Active Pokémon
	call CreateHandCardList
	ld hl, wDuelTempList
	ld de, wAICardListArenaPriority
	call .PlayPokemonCardInOrder
	ret c ; return carry if there are no cards in the hand that match a card ID from the priority list

; put Basic Pokémon cards onto the Bench until there are
; a maximum of 3 cards in the play area.
.loop
	ld de, wAICardListBenchPriority
	call .PlayPokemonCardInOrder
	ccf
	ret nc ; return no carry if no more cards in the hand match a card ID from the priority list
	cp 3
	jr c, .loop
	; there are now 3 Pokémon in play, so return no carry.
	ret

; uses the pointer at de to find a priority list and then uses that list to
; decide which Basic Pokémon to put into play from the list of hand cards at hl.
; preserves hl and b
; input:
;	de = pointer for a null-terminated list with card IDs (of Basic Pokémon to play)
;	hl = $ff-terminated list with deck indices (of hand cards)
; output:
;	a = number of Pokémon in the AI's play area
;	carry = set:  if none of the cards in the list from de were found in the list at hl
;	           OR if there wasn't room on the Bench for the Pokémon that was found
.PlayPokemonCardInOrder
	ld a, [de]
	ld c, a
	inc de
	ld a, [de]
	ld d, a
	ld e, c

; read the list at de and play the first card from the list at hl with a matching card ID.
; returns carry if hand doesn't have any card in list.
.loop_id_list
	ld a, [de]
	inc de
	or a
	scf
	ret z ; return carry if there are no more card IDs to check
	ld c, a
	call RemoveCardIDInList
	jr nc, .loop_id_list

	; put this card into play and return
	push hl
	call PutHandPokemonCardInPlayArea
	pop hl
	ret


; checks if the Player's Active Pokémon is a Mr. Mime, and if it is,
; checks if the Pokémon at the given location can damage it.
; input:
;	a = AI Pokémon's play area location offset (PLAY_AREA_* constant)
; output:
;	carry = set:  if the Player's Active Pokémon isn't a Mr. Mime or
;	              if the Pokémon in the given location can damage it anyway
CheckDamageToMrMime:
	ld b, a
	rst SwapTurn
	ld a, DUELVARS_ARENA_CARD
	get_turn_duelist_var
	call _GetCardIDFromDeckIndex
	rst SwapTurn
	cp MR_MIME
	scf
	ret nz ; return carry if the Defending Pokémon isn't a Mr. Mime
	ld a, b
	jp CheckIfCanDamageDefendingPokemon


; output:
;	carry = set:  if the Active Pokémon would not be able to KO the Defending Pokémon,
;	              even after attaching another Energy card from the hand
CheckIfActiveWillNotBeAbleToKODefending:
	xor a ; PLAY_AREA_ARENA
	ldh [hTempPlayAreaLocation_ff9d], a
	call CheckIfAnyAttackKnocksOutDefendingCard
	ccf
	ret c ; return carry if none of the Active Pokémon's attacks can KO
	call CheckIfSelectedAttackIsUnusable
	ret nc ; return no carry if Active Pokémon can use the attack that would KO
	call LookForEnergyNeededForAttackInHand
	ccf
	ret


; output:
;	carry = set:  if the Active Pokémon can KO the Defending Pokémon
CheckIfActiveCardCanKnockOut:
	xor a ; PLAY_AREA_ARENA
	ldh [hTempPlayAreaLocation_ff9d], a
	call CheckIfAnyAttackKnocksOutDefendingCard
	ret nc
	call CheckIfSelectedAttackIsUnusable
	ccf
	ret


; checks that the AI's Active Pokémon will be able to use an attack that
; is damaging or will otherwise be able to affect the Defending Pokémon.
; output:
;	carry = set:  if any of the Active Pokémon's attacks can be used and are not residual
CheckIfActivePokemonCanUseAnyNonResidualAttack:
	xor a ; PLAY_AREA_ARENA
	ldh [hTempPlayAreaLocation_ff9d], a
	; a = FIRST_ATTACK_OR_PKMN_POWER
	call CheckIfAttackIsUsableAndNotResidual
	ret c
	ld a, SECOND_ATTACK
;	fallthrough

; input:
;	a = which attack to check (0 = first attack, 1 = second attack)
;	[hTempPlayAreaLocation_ff9d] = play area location offset of the Pokémon to check (PLAY_AREA_* constant)
; output:
;	carry = set:  if the given attack can be used and isn't Residual
CheckIfAttackIsUsableAndNotResidual:
	ld [wSelectedAttack], a
	call CheckIfSelectedAttackIsUnusable
	ccf
	ret nc ; return no carry if the attack isn't usable
	ld a, [wLoadedAttackCategory]
	and RESIDUAL
	ret nz ; return no carry if it's a residual attack
	scf
	ret


; looks for Energy card(s) in hand depending on what is needed
; by the attacks of the Pokémon in the given location.
;	- if one Basic Energy is required, look for that Energy
;	- if one Colorless Energy is required, create a list at wDuelTempList of all Energy cards
;	- if two Colorless Energy are required, look for a Double Colorless Energy
; input:
;	[hTempPlayAreaLocation_ff9d] = Pokémon's play area location offset (PLAY_AREA_* constant)
; output:
;	carry = set:  if a required Energy card was found in the hand
LookForEnergyNeededInHand:
	xor a ; FIRST_ATTACK_OR_PKMN_POWER
	ld [wSelectedAttack], a
	call LookForEnergyNeededForAttackInHand
	ret c
	ld a, SECOND_ATTACK
	ld [wSelectedAttack], a
;	fallthrough

; looks for Energy card(s) in hand depending on what is needed for the selected Pokémon and attack
;	- if one Basic Energy is required, look for that Energy
;	- if one Colorless Energy is required, create a list at wDuelTempList of all Energy cards
;	- if two Colorless Energy are required, look for a Double Colorless Energy
; input:
;	[hTempPlayAreaLocation_ff9d] = play area location offset of the Pokémon to check (PLAY_AREA_* constant)
;	[wSelectedAttack] = which attack to check (0 = first attack, 1 = second attack)
; output:
;	carry = set:  if the required Energy card was found in the hand
LookForEnergyNeededForAttackInHand:
	call CheckEnergyNeededForAttack
	ld a, b
	add c
	cp 1
	jr z, .one_energy
	cp 2
	jr nz, .no_carry
	ld a, c
	cp 2
	jr z, .two_colorless
.no_carry
	or a
	ret

.one_energy
	ld a, b
	or a
	jr z, .one_colorless
	call GetEnergyCardNeeded
	jp LookForCardIDInHandList_Bank5

.one_colorless
	call CreateEnergyCardListFromHand
	ccf
	ret

.two_colorless
	ld a, DOUBLE_COLORLESS_ENERGY
	jp LookForCardIDInHandList_Bank5


; goes through a priority list and compares the card IDs
; in the list with each card in wDuelTempList.
; Sorts wDuelTempList so that the cards are in the same order as the priority list.
; input:
;	[wAICardListPlayFromHandPriority] = pointer for a null-terminated list of card IDs
;	[wDuelTempList] = $ff-terminated list with deck indices (of hand cards)
SortTempHandByIDList:
	ld a, [wAICardListPlayFromHandPriority+1]
	or a
	ret z ; return if list is empty

; start going down the ID list
	ld d, a
	ld a, [wAICardListPlayFromHandPriority]
	ld e, a
	ld c, 0
.loop_list_id
; get this item's ID
; if $00, list has ended
	ld a, [de]
	or a
	ret z ; return if there are no more card IDs to check
	inc de
	ld hl, wDuelTempList
	ld b, 0
	add hl, bc
	ld b, a

; search in the hand card list
.next_hand_card
	ld a, [hl]
	ldh [hTempCardIndex_ff98], a
	cp $ff
	jr z, .loop_list_id
	call _GetCardIDFromDeckIndex
	cp b
	jr nz, .not_same

; found
; swap this hand card with the spot
; in hand corresponding to c
	push bc
	push hl
	ld b, 0
	ld hl, wDuelTempList
	add hl, bc
	ld b, [hl]
	ldh a, [hTempCardIndex_ff98]
	ld [hl], a
	pop hl
	ld [hl], b
	pop bc
	inc c
.not_same
	inc hl
	jr .next_hand_card


; looks for Energy card(s) in the list at wDuelTempList
; depending on the energy flags that are set in a.
; preserves bc
; input:
;	a = energy flags needed
;	[wDuelTempList] = $ff-terminated list with deck indices of cards
; output:
;	carry = set:  if an Energy card was found that matches the given flags
CheckEnergyFlagsNeededInList:
	ld e, a
	ld hl, wDuelTempList
.next_card
	ld a, [hli]
	cp $ff
	ret z ; nc
	call _GetCardIDFromDeckIndex

; fire
	cp FIRE_ENERGY
	jr nz, .grass
	ld a, FIRE_F
	jr .check_energy
.grass
	cp GRASS_ENERGY
	jr nz, .lightning
	ld a, GRASS_F
	jr .check_energy
.lightning
	cp LIGHTNING_ENERGY
	jr nz, .water
	ld a, LIGHTNING_F
	jr .check_energy
.water
	cp WATER_ENERGY
	jr nz, .fighting
	ld a, WATER_F
	jr .check_energy
.fighting
	cp FIGHTING_ENERGY
	jr nz, .psychic
	ld a, FIGHTING_F
	jr .check_energy
.psychic
	cp PSYCHIC_ENERGY
	jr nz, .colorless
	ld a, PSYCHIC_F
	jr .check_energy
.colorless
	cp DOUBLE_COLORLESS_ENERGY
	jr nz, .next_card
	ld a, COLORLESS_F
	; fallthrough

; return carry if the Energy card matches the required Energy.
.check_energy
	and e
	jr z, .next_card
	scf
	ret


; returns in a the Energy cost of both attacks from the Pokémon
; with deck index in a, represented by energy bit flags,
; i.e. each bit represents a different Energy type/color cost.
; if any Colorless Energy is required, all bits are set.
; preserves de
; input:
;	a = Pokémon card's deck index
; output:
;	a = bits of each Energy requirement
;	[wLoadedCard2] = all of the given card's data (card_data_struct)
GetAttacksEnergyCostBits:
	call LoadCardDataToBuffer2_FromDeckIndex
	ld hl, wLoadedCard2Atk1EnergyCost
	call GetEnergyCostBits
	push bc
	ld hl, wLoadedCard2Atk2EnergyCost
	call GetEnergyCostBits
	pop bc
	or c
	ret


; returns in a the Energy cost of an attack in [hl], represented by energy bit flags,
; i.e. each bit represents a different Energy type/color cost.
; if any Colorless Energy is required, all bits are set.
; preserves de
; input:
;	[hl] = Energy cost for a loaded Pokémon card's attack (e.g. wLoadedCard1Atk1EnergyCost)
; output:
;	a & c = bits of each Energy requirement
GetEnergyCostBits:
	ld c, $00
	ld a, [hli]
	ld b, a

; fire
	and $f0
	jr z, .grass
	ld c, FIRE_F
.grass
	ld a, b
	and $0f
	jr z, .lightning
	ld a, GRASS_F
	or c
	ld c, a
.lightning
	ld a, [hli]
	ld b, a
	and $f0
	jr z, .water
	ld a, LIGHTNING_F
	or c
	ld c, a
.water
	ld a, b
	and $0f
	jr z, .fighting
	ld a, WATER_F
	or c
	ld c, a
.fighting
	ld a, [hli]
	ld b, a
	and $f0
	jr z, .psychic
	ld a, FIGHTING_F
	or c
	ld c, a
.psychic
	ld a, b
	and $0f
	jr z, .colorless
	ld a, PSYCHIC_F
	or c
	ld c, a
.colorless
	ld a, [hli]
	ld b, a
	and $f0
	jr z, .done
	ld c, %11111111
.done
	ld a, c
	ret


; preserves bc
; input:
;	a = deck index to check for evolution
;	wDuelTempList = $ff-terminated list of card deck indices
; output:
;	a = deck index of a card in wDuelTempList that evolves from the given card, if any
;	carry = set:  if any card in wDuelTempList can evolve from the given card
CheckForEvolutionInList:
	ld d, a
	ld a, DUELVARS_ARENA_CARD
	get_turn_duelist_var
	push af
	ld [hl], d
	ld e, PLAY_AREA_ARENA
	ld hl, wDuelTempList
.loop
	ld a, [hli]
	cp $ff
	jr z, CheckForEvolutionInDeck.no_carry
	ld d, a
	push hl
	call CheckIfCanEvolveInto
	pop hl
	jr c, .loop

.set_carry
	ld a, DUELVARS_ARENA_CARD
	get_turn_duelist_var
	pop af
	ld [hl], a
	ld a, d
	scf
	ret


; preserves bc
; input:
;	a = deck index to check for evolution
; output:
;	a = deck index of a card in the AI's deck that evolves from the given card, if any
;	carry = set:  if any card in the AI's deck can evolve from the given card
CheckForEvolutionInDeck:
	ld d, a
	ld a, DUELVARS_ARENA_CARD
	get_turn_duelist_var
	push af
	ld [hl], d
	lb de, DECK_SIZE, PLAY_AREA_ARENA
.loop
	dec d ; go through deck indices in reverse order
	ld a, d ; DUELVARS_CARD_LOCATIONS + current deck index
	get_turn_duelist_var
	cp CARD_LOCATION_DECK
	jr nz, .not_in_deck
	call CheckIfCanEvolveInto
	jr nc, CheckForEvolutionInList.set_carry

; exit when it gets to the Prize cards
.not_in_deck
	ld a, d
	or a
	jr nz, .loop

.no_carry
	ld a, DUELVARS_ARENA_CARD
	get_turn_duelist_var
	pop af
	ld [hl], a
	or a
	ret


; preserves bc
; input:
;	a = deck index to check for evolution
; output:
;	a = deck index of a card in the AI's hand or deck that evolves from the given card, if any
;	carry = set:  if any card in the AI's hand or deck can evolve from the given card
CheckCardEvolutionInHandOrDeck:
	ld d, a
	ld a, DUELVARS_ARENA_CARD
	get_turn_duelist_var
	push af
	ld [hl], d
	lb de, DECK_SIZE, PLAY_AREA_ARENA

.loop
	dec d ; go through deck indices in reverse order
	ld a, d ; DUELVARS_CARD_LOCATIONS + current deck index
	get_turn_duelist_var
	cp CARD_LOCATION_DECK
	jr z, .deck_or_hand
	cp CARD_LOCATION_HAND
	jr nz, .next
.deck_or_hand
	call CheckIfCanEvolveInto
	jr nc, CheckForEvolutionInList.set_carry
.next
	ld a, d
	or a
	jr nz, .loop

.no_carry
	ld a, DUELVARS_ARENA_CARD
	get_turn_duelist_var
	pop af
	ld [hl], a
	or a
	ret


; checks in the other play area for non-Basic Pokémon.
; afterwards, that card is checked for damage,
; and if the damage counters it has is greater than or equal
; to the max HP of the card stage below it,
; return carry with that card's play area location offset in a.
; output:
;	a = play area location offset of a Pokémon that would be KO'd after devolution, if any
;	carry = set:  if any Pokémon in the Player's play area would be KO'd after devolution
LookForCardThatIsKnockedOutOnDevolution:
	ldh a, [hTempPlayAreaLocation_ff9d]
	push af
	rst SwapTurn
	ld a, DUELVARS_NUMBER_OF_POKEMON_IN_PLAY_AREA
	get_turn_duelist_var
	ld b, a
	ld c, PLAY_AREA_ARENA

.loop
	ld a, c
	ldh [hTempPlayAreaLocation_ff9d], a
	push bc
	farcall GetCardOneStageBelow
	pop bc
	jr c, .next
	; is not a Basic Pokémon
	; compare its HP with current damage
	ld e, c
	push bc
	call GetCardDamageAndMaxHP
	pop bc
	ld e, a
	ld a, d ; deck index of previous stage
	call LoadCardDataToBuffer2_FromDeckIndex
	ld a, [wLoadedCard2HP]
	dec a ; subtract 1 so carry will be set if final HP = 0
	cp e
	jr c, .set_carry
.next
	inc c
	dec b
	jr nz, .loop

	pop af
	ldh [hTempPlayAreaLocation_ff9d], a
	or a
	jp SwapTurn

.set_carry
	pop af
	ldh [hTempPlayAreaLocation_ff9d], a
	ld a, c
	scf
	jp SwapTurn


; output:
;	carry = set:  if the following conditions are met:
;		- Active Pokémon's HP >= half max HP
;		- Active Pokémon's Unknown2's 4 bit is not set or
;		  it is set but there's no matching Evolution card in hand/deck
;		- Active Pokémon can use its second attack
CheckIfArenaCardIsAtHalfHPCanEvolveAndUseSecondAttack:
	ld a, DUELVARS_ARENA_CARD
	get_turn_duelist_var
	ld d, a
	call LoadCardDataToBuffer1_FromDeckIndex
	ld a, DUELVARS_ARENA_CARD_HP
	get_turn_duelist_var
	ld e, a
	ld a, [wLoadedCard1HP]
	rrca
	cp e
	ret nc

	ld a, [wLoadedCard1Unknown2]
	and %00010000
	jr z, .check_second_attack
	ld a, d
	call CheckCardEvolutionInHandOrDeck
	ccf
	ret nc

.check_second_attack
	xor a ; PLAY_AREA_ARENA
	ldh [hTempPlayAreaLocation_ff9d], a
	inc a ; SECOND_ATTACK
	ld [wSelectedAttack], a
	call CheckIfSelectedAttackIsUnusable
	ccf
	ret


; counts Pokémon in the turn holder's Bench that meet the following conditions:
;	- card HP >= half max HP
;	- card Unknown2's 4 bit is not set or
;	  it is set but there's no matching Evolution card in hand/deck
;	- card can use its second attack
; output:
;	a = number of Benched Pokémon that meet all of the above requirements
;	carry = set:  if one or more suitable Pokémon were found
CountNumberOfSetUpBenchPokemon:
	ldh a, [hTempPlayAreaLocation_ff9d]
	ld d, a
	ld a, [wSelectedAttack]
	ld e, a
	push de
	ld a, DUELVARS_BENCH
	get_turn_duelist_var
	lb bc, 0, PLAY_AREA_ARENA
	push hl

.next
	inc c
	pop hl
	ld a, [hli]
	push hl
	cp $ff
	jr z, .done

	ld d, a
	call LoadCardDataToBuffer1_FromDeckIndex

; compares card's current HP with max HP
	ld a, c
	add DUELVARS_ARENA_CARD_HP
	get_turn_duelist_var
	ld e, a
	ld a, [wLoadedCard1HP]
	rrca

; a = max HP / 2
; e = current HP
; jumps if (current HP) <= (max HP / 2)
	cp e
	jr nc, .next

	ld a, [wLoadedCard1Unknown2]
	and $10
	jr z, .check_second_attack

	ld a, d
	call CheckCardEvolutionInHandOrDeck
	jr c, .next

.check_second_attack
	ld a, c
	ldh [hTempPlayAreaLocation_ff9d], a
	ld a, SECOND_ATTACK
	ld [wSelectedAttack], a
	push bc
	call CheckIfSelectedAttackIsUnusable
	pop bc
	jr c, .next
	inc b
	jr .next

.done
	pop hl
	pop de
	ld a, e
	ld [wSelectedAttack], a
	ld a, d
	ldh [hTempPlayAreaLocation_ff9d], a
	ld a, b
	or a
	ret z
	scf
	ret


; handles AI logic to determine some selections for certain attacks,
; if any of these attacks were chosen to be used.
; also outputs the chosen parameters in hram (e.g. $ffa0, $ffa1, etc.).
; output:
;	carry = set:  if the parameter selection was successful
AISelectSpecialAttackParameters:
	ld a, [wSelectedAttack]
	push af
	call .SelectAttackParameters
	pop bc
	ld a, b
	ld [wSelectedAttack], a
	ret

.SelectAttackParameters:
	ld a, DUELVARS_ARENA_CARD
	get_turn_duelist_var
	call _GetCardIDFromDeckIndex
	cp MEW_LV23
	jr z, .DevolutionBeam
	cp MEWTWO_ALT_LV60
	jr z, .EnergyAbsorption
	cp MEWTWO_LV60
	jr z, .EnergyAbsorption
	cp EXEGGUTOR
	jr z, .Teleport
	cp ELECTRODE_LV35
	jr z, .EnergySpike
	or a
	ret


; if the selected attack is Devolution Beam, store $01 in hTemp_ffa0 and
; the location of the Pokémon to devolve in hTempPlayAreaLocation_ffa1.
; carry is only set if the devolution will KO one of the Player's Pokémon.
.DevolutionBeam
	ld a, [wSelectedAttack]
	or a ; cp FIRST_ATTACK_OR_PKMN_POWER
	ret z ; return no carry if the Active Pokémon is using its first attack

	ld a, $01 ; always target the Player's play area
	ldh [hTemp_ffa0], a
	call LookForCardThatIsKnockedOutOnDevolution
	ldh [hTempPlayAreaLocation_ffa1], a
	ret


; if the selected attack is Energy Absorption, select up to two Energy cards in the discard pile.
; carry is only set if there's a Psychic Energy in the discard pile to use for the first selection. 
.EnergyAbsorption
	ld a, [wSelectedAttack]
	or a ; cp FIRST_ATTACK_OR_PKMN_POWER
	ret nz ; return no carry if the Active Pokémon isn't using its first attack

; add terminating bytes to the list.
	ld a, $ff
	ldh [hTempList + 1], a
	ldh [hTempList + 2], a

; search for Psychic Energy cards in the discard pile.
	ld e, PSYCHIC_ENERGY
	ld a, CARD_LOCATION_DISCARD_PILE
	call LookForCardIDInLocation_Bank5
	ret nc ; return no carry if there weren't any Psychic Energy cards in the discard pile
	ldh [hTempList], a
	farcall CreateEnergyCardListFromDiscardPile_AllEnergy

; find any Energy card different from the one found by LookForCardIDInLocation_Bank5.
; since using this attack requires a Psychic Energy card, and another one is in hTempList,
; then any other Energy card would account for the Energy Cost of Psyburn.
	ld hl, wDuelTempList
.loop_energy_cards
	ld a, [hli]
	cp $ff
	jr z, .set_carry
	ld b, a
	ldh a, [hTempList]
	cp b
	jr z, .loop_energy_cards ; same card, keep looking

; store the deck index of the found Energy card.
	ld a, b
	ldh [hTempList + 1], a
	; fallthrough

.set_carry
	scf
	ret


; if the selected attack is Teleport, decide the Benched Pokémon to switch to.
; carry is only set if there's at least one Benched Pokémon.
.Teleport
	ld a, [wSelectedAttack]
	or a ; cp FIRST_ATTACK_OR_PKMN_POWER
	ret nz ; return no carry if the Active Pokémon isn't using its first attack
	call AIDecideBenchPokemonToSwitchTo
	ldh [hTemp_ffa0], a
	ccf
	ret


; if the selected attack is Energy Spike, choose a Basic Energy card
; to fetch from the deck and the Pokémon to attach it to.
; carry is only set if there's a Lightning Energy card to target in the deck
; and a Pokémon in the AI's play area that would benefit from more Energy.
.EnergySpike
	ld a, [wSelectedAttack]
	or a ; cp FIRST_ATTACK_OR_PKMN_POWER
	ret z ; return no carry if the Active Pokémon is using its first attack

; try to target a Lightning Energy in the deck.
	ld a, CARD_LOCATION_DECK
	ld e, LIGHTNING_ENERGY
	call LookForCardIDInLocation_Bank5
	ret nc ; return no carry if there are no Lightning Energy in the deck
	ldh [hTemp_ffa0], a

; find a suitable play area Pokémon to attach the Energy card to.
	call AIProcessButDontPlayEnergy_SkipEvolution
	ret nc ; return no carry if none of the AI's Pokémon need more Energy
	ldh a, [hTempPlayAreaLocation_ff9d]
	ldh [hTempPlayAreaLocation_ffa1], a
	ret ; carry set


; input:
;	[hTempPlayAreaLocation_ff9d] = Pokémon's play area location offset (PLAY_AREA_* contant)
;	[wSelectedAttack] = which attack to check (0 = first attack, 1 = second attack)
; output:
;	a = number of extra Energy cards that are attached
;	carry = set:  if the given Pokémon doesn't have enough Energy to use the given attack
;	           OR if it has the exact amount of Energy needed for that attack
;	           OR if the given attack isn't an attack (either empty or a Pokémon Power)
CheckIfNoSurplusEnergyForAttack:
	ldh a, [hTempPlayAreaLocation_ff9d]
	add DUELVARS_ARENA_CARD
	get_turn_duelist_var
	ld d, a
	ld a, [wSelectedAttack]
	ld e, a
	call CopyAttackDataAndDamage_FromDeckIndex
	ld hl, wLoadedAttackName
	ld a, [hli]
	or [hl]
	jr z, .set_carry ; attack slot is empty
	ld a, [wLoadedAttackCategory]
	cp POKEMON_POWER
	jr z, .set_carry ; it's a Pokémon Power
; is attack
	ldh a, [hTempPlayAreaLocation_ff9d]
	ld e, a
	call GetPlayAreaCardAttachedEnergies
	call HandleEnergyBurn

	; fill wTempLoadedAttackEnergyCost
	ld hl, wLoadedAttackEnergyCost
	ld de, wTempLoadedAttackEnergyCost
	ld b, NUM_TYPES / 2
	call CopyNBytesFromHLToDE

	; clear wTempLoadedAttackEnergyNeededAmount
	ld hl, wTempLoadedAttackEnergyNeededAmount
	ld c, NUM_TYPES / 2
	xor a
.loop_clear
	ld [hli], a
	dec c
	jr nz, .loop_clear
	ld hl, wAttachedEnergies
	ld de, wLoadedAttackEnergyCost
	ld c, FIRE
.loop
	; check all Basic Energy cards
	call CheckIfEnoughParticularAttachedEnergy
	call CheckIfEnoughParticularAttachedEnergy
	inc de
	ld a, c
	cp NUM_TYPES
	jr z, .loop

	; count Basic Energy cards in use
	ld hl, wTempLoadedAttackEnergyCost
	ld de, wTempLoadedAttackEnergyNeededAmount
	ld c, 0
	ld a, (NUM_TYPES / 2) - 1
.loop_tally_energies_in_use
	push af
	ld a, [de] ; needed amount
	swap a
	and %1111
	ld b, a
	ld a, [hl] ; Energy cost
	swap a
	and %1111
	sub b
	add c
	ld c, a
	ld a, [de] ; needed amount
	inc de
	and %1111
	ld b, a
	ld a, [hli] ; Energy cost
	and %1111
	sub b
	add c
	ld c, a
	pop af
	dec a
	jr nz, .loop_tally_energies_in_use

	; Colorless
	ld a, [de]
	swap a
	and %1111
	ld b, a ; Colorless Energy still needed
	ld a, [wTotalAttachedEnergies]
	sub c
	sub b
	ret c ; return if not enough Energy

	or a
	ret nz ; return no carry if there's surplus Energy

; exactly the amount of Energy needed
.set_carry
	scf
	ret


; input:
;	a = play area location offset of the Pokémon to check (PLAY_AREA_* constant)
; output:
;	carry = set:  if the given Pokémon can use one of its attacks to damage the Defending Pokémon
CheckIfCanDamageDefendingPokemon:
	ldh [hTempPlayAreaLocation_ff9d], a
	xor a ; FIRST_ATTACK_OR_PKMN_POWER
	call CheckIfAttackCanDamageDefendingPokemon
	ret c
	ld a, SECOND_ATTACK
;	fallthrough

; input:
;	a = which attack to check (0 = first attack, 1 = second attack)
;	[hTempPlayAreaLocation_ff9d] = play area location offset of the Pokémon to check (PLAY_AREA_* constant)
; output:
;	carry = set:  if the given attack can be used to damage the Defending Pokémon
CheckIfAttackCanDamageDefendingPokemon:
	ld [wSelectedAttack], a
	call CheckIfSelectedAttackIsUnusable
	ccf
	ret nc
	ld a, [wSelectedAttack]
	call EstimateDamage_VersusDefendingCard
	ld a, [wDamage]
	or a
	ret z ; nc
	scf
	ret


; checks if the Defending Pokémon can KO a given Pokémon with any of its attacks,
; and if so, stores the damage to wAIFirstAttackDamage and wAISecondAttackDamage
; input:
;	[hTempPlayAreaLocation_ff9d] = AI Pokémon's play area location offset (PLAY_AREA_* constant)
; output:
;	a = largest amount of damage that can be dealt (either attack)
;	carry = set:  if any of the Defending Pokémon's attacks are able to KO the given Pokémon
CheckIfDefendingPokemonCanKnockOut:
	xor a
	ld [wAIFirstAttackDamage], a
	ld [wAISecondAttackDamage], a

; first attack
	; a = FIRST_ATTACK_OR_PKMN_POWER
	call CheckIfDefendingPokemonCanKnockOutWithAttack
	jr nc, .second_attack
	ld a, [wDamage]
	ld [wAIFirstAttackDamage], a
.second_attack
	ld a, SECOND_ATTACK
	call CheckIfDefendingPokemonCanKnockOutWithAttack
	jr nc, .return_if_neither_kos
	ld a, [wDamage]
	ld [wAISecondAttackDamage], a
	jr .compare

.return_if_neither_kos
	ld a, [wAIFirstAttackDamage]
	or a
	ret z

.compare
	ld a, [wAIFirstAttackDamage]
	ld b, a
	ld a, [wAISecondAttackDamage]
	cp b
	jr nc, .set_carry ; wAIFirstAttackDamage < wAISecondAttackDamage
	ld a, b
.set_carry
	scf
	ret


; checks if the Defending Pokémon can KO a given Pokémon using a specified attack
; input:
;	a = attack index (0 = first attack, 1 = second attack)
;	[hTempPlayAreaLocation_ff9d] = AI Pokémon's play area location offset (PLAY_AREA_* constant)
; output:
;	carry = set:  if the Defending Pokémon's given attack is able to KO the given Pokémon
;	[wDamage] = amount of damage that the given attack will do to the given Pokémon
CheckIfDefendingPokemonCanKnockOutWithAttack:
	ld [wSelectedAttack], a
	ldh a, [hTempPlayAreaLocation_ff9d]
	push af
	xor a ; PLAY_AREA_ARENA
	ldh [hTempPlayAreaLocation_ff9d], a
	rst SwapTurn
	call CheckIfSelectedAttackIsUnusable
	rst SwapTurn
	pop bc
	ld a, b
	ldh [hTempPlayAreaLocation_ff9d], a
	ccf
	ret nc ; return if the given attack can't be used

; the Defending Pokémon is able to use the given attack.
	ld a, [wSelectedAttack]
	call EstimateDamage_FromDefendingPokemon
	ldh a, [hTempPlayAreaLocation_ff9d]
	add DUELVARS_ARENA_CARD_HP
	get_turn_duelist_var
	dec a ; subtract 1 so carry will be set if final HP = 0
	ld hl, wDamage
	sub [hl]
	ret


; preserves all registers except f (flags)
; output:
;	carry = set:  if AI's deck ID is between LEGENDARY_MOLTRES_DECK_ID (inclusive)
;	              and MUSCLES_FOR_BRAINS_DECK_ID (exclusive). this range includes
;	              the decks for each of the Grandmasters, Club Masters, and Ronald.
CheckIfOpponentHasBossDeckID:
	push af
	ld a, [wOpponentDeckID]
	cp LEGENDARY_MOLTRES_DECK_ID
	jr c, .no_carry
	cp MUSCLES_FOR_BRAINS_DECK_ID
	jr nc, .no_carry
	pop af
	scf
	ret

.no_carry
	pop af
	or a
	ret


; preserves all registers except af
; output:
;	carry = set:  if the AI isn't using a boss deck and the Player
;	              has not yet received the Legendary Cards
CheckIfNotABossDeckID:
	call EnableSRAM
	ld a, [sReceivedLegendaryCards]
	call DisableSRAM
	or a
	ret nz ; nc
	call CheckIfOpponentHasBossDeckID
	ccf
	ret


; input:
;	a = card ID to check for
; output:
;	carry = set:  if any Benched Pokémon matching the given card ID still has
;	              more than half its max HP and is capable of using its 2nd attack
CheckForBenchIDAtHalfHPAndCanUseSecondAttack:
	ld [wcdf9], a
	ldh a, [hTempPlayAreaLocation_ff9d]
	ld d, a
	ld a, [wSelectedAttack]
	ld e, a
	push de
	ld a, DUELVARS_BENCH
	get_turn_duelist_var
	lb bc, 0, PLAY_AREA_ARENA
	push hl

.loop
	inc c
	pop hl
	ld a, [hli]
	push hl
	cp $ff
	jr z, .done
	ld d, a
	call LoadCardDataToBuffer1_FromDeckIndex
	ld a, c
	add DUELVARS_ARENA_CARD_HP
	get_turn_duelist_var
	ld e, a
	ld a, [wLoadedCard1HP]
	rrca
	cp e
	jr nc, .loop
	; half max HP < current HP
	ld a, [wLoadedCard1ID]
	ld hl, wcdf9
	cp [hl]
	jr nz, .loop

	ld a, c
	ldh [hTempPlayAreaLocation_ff9d], a
	ld a, SECOND_ATTACK
	ld [wSelectedAttack], a
	push bc
	call CheckIfSelectedAttackIsUnusable
	pop bc
	jr c, .loop
	inc b
.done
	pop hl
	pop de
	ld a, e
	ld [wSelectedAttack], a
	ld a, d
	ldh [hTempPlayAreaLocation_ff9d], a
	ld a, b
	or a
	ret z
	scf
	ret


; adds 5 to the wPlayAreaEnergyAIScore score corresponding to all
; Benched Pokémon that have the same ID as register a
; input:
;	a = card ID to look for
RaiseAIScoreToAllMatchingIDsInBench:
	ld d, a
	ld a, DUELVARS_BENCH
	get_turn_duelist_var
	ld e, PLAY_AREA_ARENA
.loop
	inc e
	ld a, [hli]
	cp $ff
	ret z
	call _GetCardIDFromDeckIndex
	cp d
	jr nz, .loop
	ld c, e
	ld b, $00
	push hl
	ld hl, wPlayAreaEnergyAIScore
	add hl, bc
	ld a, 5
	add [hl]
	ld [hl], a
	pop hl
	jr .loop


; goes through each play area Pokémon, and
; for all cards of the same ID, determine which
; card has highest value calculated from Func_17583
; the card with highest value gets increased wPlayAreaEnergyAIScore
; while all others get decreased wPlayAreaEnergyAIScore
Func_174f2:
	ld a, MAX_PLAY_AREA_POKEMON
	ld hl, wcdfa
	call ClearMemory_Bank5
	ld a, DUELVARS_BENCH
	get_turn_duelist_var
	ld e, PLAY_AREA_ARENA

.loop_play_area
	push hl
	ld a, MAX_PLAY_AREA_POKEMON
	ld hl, wcdea
	call ClearMemory_Bank5
	pop hl
	inc e
	ld a, [hli]
	cp $ff
	ret z

	ld [wcdf9], a
	push de
	push hl

; checks wcdfa + play area location in e
; if != 0, go to next in play area
	ld d, $00
	ld hl, wcdfa
	add hl, de
	ld a, [hl]
	or a
	pop hl
	pop de
	jr nz, .loop_play_area

; loads wcdf9 with card ID and calls Func_17583
	ld a, [wcdf9]
	call _GetCardIDFromDeckIndex
	ld [wcdf9], a
	push hl
	push de
	call Func_17583

; check play area Pokémon ahead.
; if there is a card with the same ID,
; call Func_17583 for it as well.
.loop_1
	inc e
	ld a, [hli]
	cp $ff
	jr z, .check_if_repeated_id
	push de
	call GetCardIDFromDeckIndex
	ld a, [wcdf9]
	cp e
	pop de
	jr nz, .loop_1
	call Func_17583
	jr .loop_1

; if there's more than 1 of the same ID in the play area,
; iterate the Bench backwards and determine which card
; has the highest score in wcdea.
.check_if_repeated_id
	call Func_175a8
	jr c, .next
	lb bc, 0, 0
	ld hl, wcdea + MAX_BENCH_POKEMON
	ld d, MAX_PLAY_AREA_POKEMON
.loop_2
	dec d
	jr z, .asm_17560
	ld a, [hld]
	cp b
	jr c, .loop_2
	ld b, a
	ld c, d
	jr .loop_2

; decrease wPlayAreaEnergyAIScore score for all cards with same ID,
; except for the one with highest score.
; increase wPlayAreaEnergyAIScore score for card with highest ID.
.asm_17560
	ld hl, wPlayAreaEnergyAIScore
	ld de, wcdea
	ld b, PLAY_AREA_ARENA
	; c = play area location offset with the highest score
.loop_3
	ld a, c
	cp b
	jr z, .card_with_highest
	ld a, [de]
	or a
	jr z, .check_next
; decrease score
	dec [hl]
	jr .check_next
.card_with_highest
; increase score
	inc [hl]
.check_next
	inc b
	ld a, MAX_PLAY_AREA_POKEMON
	cp b
	jr z, .next
	inc de
	inc hl
	jr .loop_3

.next
	pop de
	pop hl
	jr .loop_play_area


; loads wcdea + play area location in e
; with Energy  * 2 + $80 - floor(dam / 10).
; loads wcdfa + play area location in e with $01.
; preserves de and hl
; input:
;	e = play area location offset (PLAY_AREA_* constant)
Func_17583:
	push hl
	push de
	call GetCardDamageAndMaxHP
	call ConvertHPToDamageCounters_Bank5
	ld b, a ; b = number of damage counters
	call CountNumberOfEnergyCardsAttached
	sla a
	add $80
	sub b
	pop de
	push de
	ld d, $00
	ld hl, wcdea
	add hl, de
	ld [hl], a
	ld hl, wcdfa
	add hl, de
	ld [hl], $01
	pop de
	pop hl
	ret


; counts how many play area locations in wcdea are not 0, and outputs result in a.
; preserves bc
; output:
;	a & d = number of wcdea values that aren't 0 (0-6)
;	carry = set:  if the count is < 2
Func_175a8:
	ld hl, wcdea
	lb de, $00, MAX_PLAY_AREA_POKEMON + 1
.loop
	dec e
	jr z, .done
	ld a, [hli]
	or a
	jr z, .loop
	inc d
	jr .loop
.done
	ld a, d
	cp 2
	ret


; returns no carry if, given the Player is using a MewtwoLv53 mill deck,
; the AI already has a Bench fully set up, in which case it
; will process some Trainer cards in hand (namely Energy Removals).
; this is used to check whether to skip some normal AI routines
; this turn and jump right to the attacking phase.
; output:
;	carry = set: if [wAIBarrierFlagCounter] = 0 or
;	             if [wAIBarrierFlagCounter] > 2 or 
;	             if the AI has less than 4 Benched Pokémon
HandleAIAntiMewtwoDeckStrategy:
; return carry if the Player is not playing a MewtwoLv53 mill deck
	ld a, [wAIBarrierFlagCounter]
	bit AI_MEWTWO_MILL_F, a
	jr z, .set_carry

; else, check if there's been less than 2 turns
; without the Player using Barrier.
	cp AI_MEWTWO_MILL + 2
	jr c, .count_bench

; if there has been, reset wAIBarrierFlagCounter and return carry.
	xor a
	ld [wAIBarrierFlagCounter], a
.set_carry
	scf
	ret

; else, check number of Pokémon that are set up on the Bench.
; if less than 4, return carry.
.count_bench
	call CountNumberOfSetUpBenchPokemon
	cp 4
	ret c

; if there's at least 4 Pokémon on the Bench set up,
; process Trainer hand cards of AI_TRAINER_CARD_PHASE_05
	ld a, AI_TRAINER_CARD_PHASE_05
	call AIProcessHandTrainerCards
	or a
	ret


AIProcessHandTrainerCards:
	farcall _AIProcessHandTrainerCards
	ret


;----------------------------------------
;        UNREFERENCED FUNCTIONS
;----------------------------------------
;INCLUDE "engine/duel/ai/decks/unreferenced.asm"
;
;
; preserves de
; input:
;	[wLoadedAttack] = attack data for the Pokémon being checked (atk_data_struct)
; output:
;	carry = set:  if the loaded attack effect has an "initial effect 2"
;	              or a "require selection" effect command
;Func_14323:
;	ld hl, wLoadedAttackEffectCommands
;	ld a, [hli]
;	ld h, [hl]
;	ld l, a
;	ld a, EFFECTCMDTYPE_INITIAL_EFFECT_2
;	push hl
;	call CheckMatchingCommand
;	pop hl
;	ccf
;	ret c
;	ld a, EFFECTCMDTYPE_REQUIRE_SELECTION
;	call CheckMatchingCommand
;	ccf
;	ret
;
;
; input:
;	hl = $00-terminated list with 3 bytes of data using the following structure:
;			- non-zero value (anything but $1 is ignored)
;			- card ID to look for in the play area
;			- number of Energy cards
; output:
;	a = play area location offset of a Benched Pokémon that met all requirements
;	carry = set:  if a Benched Pokémon with the given card ID was found
;	              with at least the given number of attached Energy cards
;Func_1585b:
;	ld a, [hli]
;	or a
;	ret z ; nc
;	dec a
;	jr nz, .next_1
;	ld a, [hli]
;	ld b, PLAY_AREA_BENCH_1
;	push hl
;	call LookForCardIDInPlayArea_Bank5
;	pop hl
;	jr nc, .next_2
;	ld e, a
;	call CountNumberOfEnergyCardsAttached
;	cp [hl]
;	inc hl
;	jr c, Func_1585b
;	ld a, e
;	scf
;	ret
;
;.next_1
;	inc hl
;.next_2
;	inc hl
;	jr Func_1585b
;
;
; goes through the given list, and if a card with a listed ID is found
; with less than the number of Energy cards corresponding to its entry,
; then have the AI try to attach an Energy card from their hand to that Pokémon
; input:
;	hl = $00-terminated list with 3 bytes of data using the following structure:
;		- non-zero value
;		- card ID to look for in the play area
;		- number of Energy cards
;Func_15886:
;	call CreateEnergyCardListFromHand
;	ret c ; quit if no Energy cards in hand
;
;.loop_energy_cards
;	ld a, [hli]
;	or a
;	ret z ; done
;	ld a, [hli]
;	ld b, PLAY_AREA_ARENA
;	push hl
;	call LookForCardIDInPlayArea_Bank5
;	pop hl
;	jr nc, .next ; skip if not found in the play area
;	ld e, a
;	call CountNumberOfEnergyCardsAttached
;	cp [hl]
;	jr nc, .next
;	ld a, e
;	ldh [hTempPlayAreaLocation_ff9d], a
;	push hl
;	call AITryToPlayEnergyCard
;	pop hl
;	ret c
;.next
;	inc hl
;	jr .loop_energy_cards
