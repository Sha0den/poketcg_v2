INCLUDE "engine/duel/ai/damage_calculation.asm"
INCLUDE "engine/duel/ai/deck_ai.asm"
INCLUDE "engine/duel/ai/init.asm"
INCLUDE "engine/duel/ai/retreat.asm"
INCLUDE "engine/duel/ai/hand_pokemon.asm"
INCLUDE "engine/duel/ai/energy.asm"
INCLUDE "engine/duel/ai/attacks.asm"
INCLUDE "engine/duel/ai/special_attacks.asm"
INCLUDE "engine/duel/ai/boss_deck_set_up.asm"


; returns carry if damage dealt from any of
; a card's attacks KOs defending Pokémon
; outputs index of the attack that KOs
; input:
;	[hTempPlayAreaLocation_ff9d] = location of attacking card to consider
; output:
;	[wSelectedAttack] = attack index that KOs
CheckIfAnyAttackKnocksOutDefendingCard:
	xor a ; first attack
	call CheckIfAttackKnocksOutDefendingCard
	ret c
	ld a, SECOND_ATTACK
;	fallthrough

CheckIfAttackKnocksOutDefendingCard:
	call EstimateDamage_VersusDefendingCard
	ld a, DUELVARS_ARENA_CARD_HP
	call GetNonTurnDuelistVariable
	dec a ; subtract 1 so carry will be set if final HP = 0
	ld hl, wDamage
	sub [hl]
	ret

; checks AI scores for all benched Pokémon
; returns the location of the card with highest score
; in a and [hTempPlayAreaLocation_ff9d]
FindHighestBenchScore:
	ld a, DUELVARS_NUMBER_OF_POKEMON_IN_PLAY_AREA
	get_turn_duelist_var
	ld b, a
	ld c, 0
	ld e, c
	ld d, c
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

; adds a to wAIScore
; if there's overflow, it's capped at $ff
; output:
;	a = a + wAIScore (capped at $ff)
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

; subs a from wAIScore
; if there's underflow, it's capped at $00
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

; loads defending Pokémon's weakness/resistance
; and the number of prize cards in both sides
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

; called when AI has chosen its attack.
; executes all effects and damage.
; handles AI choosing parameters for certain attacks as well.
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
	ret c

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
	ret c

	ld a, EFFECTCMDTYPE_AI_SWITCH_DEFENDING_PKMN
	call TryExecuteEffectCommandFunction
	ld a, OPPACTION_ATTACK_ANIM_AND_DAMAGE
	bank1call AIMakeDecision
	ret

; return carry if any of the following is satisfied:
;	- deck index in a corresponds to a double colorless energy card;
;	- card type in wTempCardType is colorless;
;	- card ID in wTempCardID is a Pokémon card that has
;	  attacks that require energy other than its color and
;	  the deck index in a corresponds to that energy type;
;	- card ID is Eevee and a corresponds to an energy type
;	  of water, fire or lightning;
;	- type of card in register a is the same as wTempCardType.
; used for knowing if a given energy card can be discarded
; from a given Pokémon card
; input:
;	a = energy card attached to Pokémon to check
;	[wTempCardType] = TYPE_ENERGY_* of given Pokémon
;	[wTempCardID] = card index of Pokémon card to check
CheckIfEnergyIsUseful:
	push de
	call GetCardIDFromDeckIndex
	ld a, e
	cp DOUBLE_COLORLESS_ENERGY
	jr z, .set_carry
	ld a, [wTempCardType]
	cp TYPE_ENERGY_DOUBLE_COLORLESS
	jr z, .set_carry
	ld a, [wTempCardID]

	ld d, PSYCHIC_ENERGY
	cp EXEGGCUTE
	jr z, .check_energy
	cp EXEGGUTOR
	jr z, .check_energy
	cp PSYDUCK
	jr z, .check_energy
	cp GOLDUCK
	jr z, .check_energy

	ld d, WATER_ENERGY
	cp SURFING_PIKACHU_LV13
	jr z, .check_energy
	cp SURFING_PIKACHU_ALT_LV13
	jr z, .check_energy

	cp EEVEE
	jr nz, .check_type
	ld a, e
	cp WATER_ENERGY
	jr z, .set_carry
	cp FIRE_ENERGY
	jr z, .set_carry
	cp LIGHTNING_ENERGY
	jr z, .set_carry

.check_type
	call GetCardType
	ld d, a
	ld a, [wTempCardType]
	cp d
	jr z, .set_carry
	pop de
	or a
	ret

.check_energy
	ld a, d
	cp e
	jr nz, .check_type
.set_carry
	pop de
	scf
	ret

; pick a random Pokemon in the bench.
; output:
;	- a = PLAY_AREA_* of Bench Pokemon picked.
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

; picks a prize card at random
; and adds it to the hand.
.PickPrizeCard:
	ld a, DUELVARS_PRIZES
	get_turn_duelist_var
	push hl
	ld c, a

; choose a random prize card until
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
	jr z, .loop_pick_prize ; no prize

; prize card was found
; remove this prize from wOpponentPrizes
	ld a, [hl]
	pop hl
	cpl
	and [hl]
	ld [hl], a

; add this prize card to the hand
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

; routine for AI to play all Basic cards from its hand
; in the beginning of the Duel.
AIPlayInitialBasicCards:
	call CreateHandCardList
	ld hl, wDuelTempList
.check_for_next_card
	ld a, [hli]
	ldh [hTempCardIndex_ff98], a
	cp $ff
	ret z ; return when done

	call CheckDeckIndexForBasicPokemon
	jr nc, .check_for_next_card ; skip this card if it isn't a Basic Pokémon

; play Basic card from hand
	push hl
	ldh a, [hTempCardIndex_ff98]
	call PutHandPokemonCardInPlayArea
	pop hl
	jr .check_for_next_card

; returns carry if Pokémon at hTempPlayAreaLocation_ff9d
; can't use an attack or if that selected attack doesn't have enough energy
; input:
;	[hTempPlayAreaLocation_ff9d] = location of Pokémon card
;	[wSelectedAttack]         = selected attack to examine
CheckIfSelectedAttackIsUnusable:
	ldh a, [hTempPlayAreaLocation_ff9d]
	or a
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

; load selected attack from Pokémon in hTempPlayAreaLocation_ff9d
; and checks if there is enough energy to execute the selected attack
; input:
;	[hTempPlayAreaLocation_ff9d] = location of Pokémon card
;	[wSelectedAttack]         = selected attack to examine
; output:
;	b = basic energy still needed
;	c = colorless energy still needed
;	carry set if no attack
;	       OR if it's a Pokémon Power
;	       OR if not enough energy for attack
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
	ld b, a ; colorless energy still needed
	ld a, [wTotalAttachedEnergies]
	sub c
	sub b
	jr c, .not_enough

	ld a, [wTempLoadedAttackEnergyNeededTotal]
	or a
	ret z

; being here means the energy cost isn't satisfied,
; including with colorless energy
	xor a
.not_enough
	cpl
	inc a
	ld c, a ; colorless energy still needed
	ld a, [wTempLoadedAttackEnergyNeededTotal]
	ld b, a ; basic energy still needed
	scf
	ret

; takes as input the energy cost of an attack for a
; particular energy, stored in the lower nibble of a
; if the attack costs some amount of this energy, the lower nibble of a != 0,
; and this amount is stored in wTempLoadedAttackEnergyCost
; sets carry flag if not enough energy of this type attached
; input:
;	c    = TYPE_* constant
;	[de] = attack's Energy cost
;	[hl] = attached energy
; output:
;	carry set if not enough of this energy type attached
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

	; not enough energy
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


; finds the first needed Energy card
; from wTempLoadedAttackEnergyNeededAmount
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

; input:
;	a = energy type
; output:
;	a = energy card ID
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

; return carry depending on card index in a:
;	- if energy card, return carry if no energy card has been played yet
;	- if basic Pokémon card, return carry if there's space in bench
;	- if evolution card, return carry if there's a Pokémon
;	  in Play Area it can evolve
;	- if trainer card, return carry if it can be used
; input:
;	a = card index to check
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
	or a
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
	ld e, 0
.loop
	call CheckIfCanEvolveInto
	ret nc
	inc e
	dec c
	jr nz, .loop
	scf
	ret

.trainer_card
	call CheckCantUseTrainerDueToHeadache
	ret c
	call LoadNonPokemonCardEffectCommands
	ld a, EFFECTCMDTYPE_INITIAL_EFFECT_1
	jp TryExecuteEffectCommandFunction

; loads all the energy cards
; in hand in wDuelTempList
; outputs the number of energy cards found in a
; return carry if no energy cards found
CreateEnergyCardListFromHand:
	push hl
	push de
	push bc
	ld b, 0
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
	ld a, $ff ; terminator byte
	ld [de], a
	ld a, b
	pop bc
	pop de
	pop hl
	or a
	ret nz ; return no carry if there were no Energy cards in the hand
	scf
	ret


; input:
;   a = CARD_LOCATION_* constant
;   e = card ID to look for
; output:
;	a & e = deck index of a matching card, if any
;	carry = set:  if the given card was found in the given location
LookForCardIDInLocation_Bank5:
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
	ret z
	ldh [hTempCardIndex_ff98], a
	call GetCardIDFromDeckIndex
	ld a, [wTempCardIDToLook]
	cp e
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
;	  = $ff:  if none of the Pokémon in the turn holder's play area have the given card ID
;	carry = set:  if the given card ID was found in the turn holder's play area
LookForCardIDInPlayArea_Bank5:
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

; check if energy card ID in e is in AI hand and,
; if so, attaches it to card ID in d in Play Area.
; input:
;	e = Energy card ID
;	d = Pokemon card ID
AIAttachEnergyInHandToCardInPlayArea:
	ld a, e
	push de
	call LookForCardIDInHandList_Bank5
	pop de
	ret nc ; not in hand
	ld b, PLAY_AREA_ARENA

.attach
	ld e, a
	ld a, d
	call LookForCardIDInPlayArea_Bank5
	ret nc ; not in play area
	ldh [hTempPlayAreaLocation_ffa1], a
	ld a, e
	ldh [hTemp_ffa0], a
	ld a, OPPACTION_PLAY_ENERGY
	bank1call AIMakeDecision
	ret

; same as AIAttachEnergyInHandToCardInPlayArea but
; only look for card ID in the Bench.
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

; load selected attack from Pokémon in hTempPlayAreaLocation_ff9d,
; gets an energy card to discard and subsequently
; check if there is enough energy to execute the selected attack
; after removing that attached energy card.
; input:
;	[hTempPlayAreaLocation_ff9d] = location of Pokémon card
;	[wSelectedAttack]         = selected attack to examine
; output:
;	b = basic energy still needed
;	c = colorless energy still needed
;	carry set if no attack
;	       OR if it's a Pokémon Power
;	       OR if not enough energy for attack
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

; color energy
; decrease respective attached energy by 1.
	ld hl, wAttachedEnergies
	dec a
	ld c, a
	ld b, $00
	add hl, bc
	dec [hl]
	ld hl, wTotalAttachedEnergies
	dec [hl]
	jp CalculateEnergyNeededForAttack
; decrease attached colorless by 2.
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
; this function is identical to 'ClearNBytesFromHL' in Bank $2,
; as well as ClearMemory_Bank6' and 'ClearMemory_Bank8'.
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
;	a = number to convert to damage counters
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


; returns in a the number of Energy cards attached to Pokémon
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


; counts total number of energy cards in opponent's hand
; plus all the cards attached in Turn Duelist's Play Area.
; output:
;	a = total number of energy cards.
CountOppEnergyCardsInHandAndAttached:
	call CreateEnergyCardListFromHand
	ld b, a

; counts number of energy cards
; that are attached in Play Area
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

; returns carry if any card with ID in e is found
; in the list that is pointed by hl.
; if one is found, it is removed from the list.
; input:
;   c  = card ID to look for.
;   hl = list to look in
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

; play Pokemon cards from the hand to set the starting
; Play Area of Boss decks.
; each Boss deck has two ID lists in order of preference.
; one list is for the Arena card is the other is for the Bench cards.
; if Arena card could not be set (due to hand not having any card in its list)
; or if list is null, return carry and do not play any cards.
TrySetUpBossStartingPlayArea:
	ld de, wAICardListArenaPriority
	ld a, d
	or a
	scf
	ret z ; return carry if pointer is null

; pick Arena card
	call CreateHandCardList
	ld hl, wDuelTempList
	ld de, wAICardListArenaPriority
	call .PlayPokemonCardInOrder
	ret c

; play Pokemon cards to Bench until there are
; a maximum of 3 cards in Play Area.
.loop
	ld de, wAICardListBenchPriority
	call .PlayPokemonCardInOrder
	ccf
	ret nc
	cp 3
	jr c, .loop
	ret

; runs through input card ID list in de.
; plays to Play Area first card that is found in hand.
; returns carry if none of the cards in the list are found.
; returns number of Pokemon in Play Area in a.
.PlayPokemonCardInOrder
	ld a, [de]
	ld c, a
	inc de
	ld a, [de]
	ld d, a
	ld e, c

; go in order of the list in de and
; add first card that matches ID.
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

	; play this card to Play Area and return
	push hl
	call PutHandPokemonCardInPlayArea
	pop hl
	ret


; check if player's active Pokémon is Mr Mime
; if it isn't, set carry
; if it is, check if Pokémon at a
; can damage it, and if it can, set carry
; input:
;	a = location of Pokémon card
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


; returns carry if arena card
; can knock out defending Pokémon
CheckIfActiveCardCanKnockOut:
	xor a
	ldh [hTempPlayAreaLocation_ff9d], a
	call CheckIfAnyAttackKnocksOutDefendingCard
	ret nc
	call CheckIfSelectedAttackIsUnusable
	ccf
	ret

; outputs carry if any of the active Pokémon attacks
; can be used and are not residual
CheckIfActivePokemonCanUseAnyNonResidualAttack:
	xor a ; active card
	ldh [hTempPlayAreaLocation_ff9d], a
; first atk
	call CheckIfAttackIsUsableAndNotResidual
	ret c
; second atk
	ld a, $01
;	fallthrough

; outputs carry if the attack in a can be used and is not residual
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

; looks for energy card(s) in hand depending on
; what is needed for selected card, for both attacks
;	- if one basic energy is required, look for that energy;
;	- if one colorless is required, create a list at wDuelTempList
;	  of all energy cards;
;	- if two colorless are required, look for double colorless;
; return carry if successful in finding card
; input:
;	[hTempPlayAreaLocation_ff9d] = location of Pokémon card
LookForEnergyNeededInHand:
	xor a ; first attack
	ld [wSelectedAttack], a
	call LookForEnergyNeededForAttackInHand
	ret c
	ld a, SECOND_ATTACK
	ld [wSelectedAttack], a
;	fallthrough

; looks for energy card(s) in hand depending on
; what is needed for selected card and attack
;	- if one basic energy is required, look for that energy;
;	- if one colorless is required, create a list at wDuelTempList
;	  of all energy cards;
;	- if two colorless are required, look for double colorless;
; return carry if successful in finding card
; input:
;	[hTempPlayAreaLocation_ff9d] = location of Pokémon card
;	[wSelectedAttack]         = selected attack to examine
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

; goes through $00 terminated list pointed
; by wAICardListPlayFromHandPriority and compares it to each card in hand.
; Sorts the hand in wDuelTempList so that the found card IDs
; are in the same order as the list pointed by de.
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
	ret z ; return when list is over
	inc de
	ld hl, wDuelTempList
	ld b, 0
	add hl, bc
	ld b, a

; search in the hand card list
.next_hand_card
	ld a, [hl]
	ldh [hTempCardIndex_ff98], a
	cp -1
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

; looks for energy card(s) in list at wDuelTempList
; depending on energy flags set in a
; return carry if successful in finding card
; input:
;	a = energy flags needed
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

; if energy card matches required energy, return carry
.check_energy
	and e
	jr z, .next_card
	scf
	ret

; returns in a the energy cost of both attacks from card index in a
; represented by energy flags
; i.e. each bit represents a different energy type cost
; if any colorless energy is required, all bits are set
; input:
;	a = card index
; output:
;	a = bits of each energy requirement
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

; returns in a the energy cost of an attack in [hl]
; represented by energy flags
; i.e. each bit represents a different energy type cost
; if any colorless energy is required, all bits are set
; input:
;	[hl] = Loaded card attack energy cost
; output:
;	a & c = bits of each energy requirement
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

; set carry flag if any card in
; wDuelTempList evolves card index in a
; if found, the evolution card index is returned in a
; input:
;	a = card index to check evolution
; output:
;	a = card index of evolution found
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

; set carry if it finds an evolution for
; the card index in a in the deck
; if found, return that evolution card index in a
; input:
;	a = card index to check evolution
; output:
;	a = card index of evolution found
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

; exit when it gets to the prize cards
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

; return carry if there is a card that
; can evolve a Pokémon in hand or deck.
; input:
;	a = deck index of card to check;
; output:
;	a = deck index of evolution in hand, if found;
;	carry set if there's a card in hand that can evolve.
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

; checks in other Play Area for non-basic cards.
; afterwards, that card is checked for damage,
; and if the damage counters it has is greater than or equal
; to the max HP of the card stage below it,
; return carry and that card's Play Area location in a.
; output:
;	a = card location of Pokémon card, if found;
;	carry set if such a card is found.
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
	; is not a basic card
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

; returns carry if the following conditions are met:
;	- arena card HP >= half max HP
;	- arena card Unknown2's 4 bit is not set or
;	  is set but there's no evolution of card in hand/deck
;	- arena card can use second attack
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
	xor a ; active card
	ldh [hTempPlayAreaLocation_ff9d], a
	inc a ; SECOND_ATTACK
	ld [wSelectedAttack], a
	call CheckIfSelectedAttackIsUnusable
	ccf
	ret

; count Pokemon in the Bench that
; meet the following conditions:
;	- card HP > half max HP
;	- card Unknown2's 4 bit is not set or
;	  is set but there's no evolution of card in hand/deck
;	- card can use second attack
; Outputs the number of Pokémon in bench
; that meet these requirements in a
; and returns carry if at least one is found
CountNumberOfSetUpBenchPokemon:
	ldh a, [hTempPlayAreaLocation_ff9d]
	ld d, a
	ld a, [wSelectedAttack]
	ld e, a
	push de
	ld a, DUELVARS_BENCH
	get_turn_duelist_var
	lb bc, 0, 0
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

; handles AI logic to determine some selections regarding certain attacks,
; if any of these attacks were chosen to be used.
; returns carry if selection was successful,
; and no carry if unable to make one.
; outputs in hTempPlayAreaLocation_ffa1 the chosen parameter.
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

.DevolutionBeam
; in case selected attack is Devolution Beam
; store in hTempPlayAreaLocation_ffa1
; the location of card to select to devolve
	ld a, [wSelectedAttack]
	or a
	ret z ; return no carry if the Active Pokémon is using its first attack

	ld a, $01
	ldh [hTemp_ffa0], a
	call LookForCardThatIsKnockedOutOnDevolution
	ldh [hTempPlayAreaLocation_ffa1], a
	ret

.EnergyAbsorption
; in case selected attack is Energy Absorption
; make list from energy cards in Discard Pile
	ld a, [wSelectedAttack]
	or a
	ret nz ; return no carry if the Active Pokémon isn't using its first attack

	ld a, $ff
	ldh [hTempPlayAreaLocation_ffa1], a
	ldh [hTempRetreatCostCards], a

; search for Psychic energy cards in Discard Pile
	ld e, PSYCHIC_ENERGY
	ld a, CARD_LOCATION_DISCARD_PILE
	call LookForCardIDInLocation_Bank5
	ret nc
	ldh [hTemp_ffa0], a
	farcall CreateEnergyCardListFromDiscardPile_AllEnergy

; find any energy card different from
; the one found by LookForCardIDInLocation_Bank5.
; since using this attack requires a Psychic energy card,
; and another one is in hTemp_ffa0,
; then any other energy card would account
; for the Energy Cost of Psyburn.
	ld hl, wDuelTempList
.loop_energy_cards
	ld a, [hli]
	cp $ff
	jr z, .set_carry
	ld b, a
	ldh a, [hTemp_ffa0]
	cp b
	jr z, .loop_energy_cards ; same card, keep looking

; store the deck index of energy card found
	ld a, b
	ldh [hTempPlayAreaLocation_ffa1], a
	; fallthrough

.set_carry
	scf
	ret

.Teleport
; in case selected attack is Teleport
; decide Bench card to switch to.
	ld a, [wSelectedAttack]
	or a
	ret nz ; return no carry if the Active Pokémon isn't using its first attack
	call AIDecideBenchPokemonToSwitchTo
	ldh [hTemp_ffa0], a
	ccf
	ret

.EnergySpike
; in case selected attack is Energy Spike
; decide basic energy card to fetch from Deck.
	ld a, [wSelectedAttack]
	or a
	ret z; return no carry if the Active Pokémon is using its first attack

	ld a, CARD_LOCATION_DECK
	ld e, LIGHTNING_ENERGY

; if none were found in Deck, return carry...
	call LookForCardIDInLocation_Bank5
	ret nc
	ldh [hTemp_ffa0], a

; ...else find a suitable Play Area Pokemon to
; attach the energy card to.
	call AIProcessButDontPlayEnergy_SkipEvolution
	ret nc
	ldh a, [hTempPlayAreaLocation_ff9d]
	ldh [hTempPlayAreaLocation_ffa1], a
	ret ; carry set

; return carry if Pokémon at play area location
; in hTempPlayAreaLocation_ff9d does not have
; energy required for the attack index in wSelectedAttack
; or has exactly the same amount of energy needed
; input:
;	[hTempPlayAreaLocation_ff9d] = play area location
;	[wSelectedAttack]         = attack index to check
; output:
;	a = number of extra energy cards attached
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
	jr z, .set_carry ; not attack
	ld a, [wLoadedAttackCategory]
	cp POKEMON_POWER
	jr z, .set_carry ; not attack
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

	; colorless
	ld a, [de]
	swap a
	and %1111
	ld b, a ; Colorless Energy still needed
	ld a, [wTotalAttachedEnergies]
	sub c
	sub b
	ret c ; return if not enough energy

	or a
	ret nz ; return if surplus energy

; exactly the amount of energy needed
.set_carry
	scf
	ret

; returns carry if Pokemon at PLAY_AREA* in a
; can damage defending Pokémon with any of its attacks
; input:
;	a = location of card to check
CheckIfCanDamageDefendingPokemon:
	ldh [hTempPlayAreaLocation_ff9d], a
	xor a ; first attack
	call CheckIfAttackCanDamageDefendingPokemon
	ret c
	ld a, SECOND_ATTACK
;	fallthrough

; returns carry if Pokemon at PLAY_AREA* in hTempPlayAreaLocation_ff9d
; can damage defending Pokémon with the attack in a
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

; checks if defending Pokémon can knock out
; card at hTempPlayAreaLocation_ff9d with any of its attacks
; and if so, stores the damage to wAIFirstAttackDamage and wAISecondAttackDamage
; sets carry if any on the attacks knocks out
; also outputs the largest damage dealt in a
; input:
;	[hTempPlayAreaLocation_ff9d] = location of card to check
; output:
;	a = largest damage of both attacks
;	carry set if can knock out
CheckIfDefendingPokemonCanKnockOut:
	xor a
	ld [wAIFirstAttackDamage], a
	ld [wAISecondAttackDamage], a

	; first attack
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

; return carry if defending Pokémon can knock out
; card at hTempPlayAreaLocation_ff9d
; input:
;	a = attack index
;	[hTempPlayAreaLocation_ff9d] = location of card to check
CheckIfDefendingPokemonCanKnockOutWithAttack:
	ld [wSelectedAttack], a
	ldh a, [hTempPlayAreaLocation_ff9d]
	push af
	xor a
	ldh [hTempPlayAreaLocation_ff9d], a
	rst SwapTurn
	call CheckIfSelectedAttackIsUnusable
	rst SwapTurn
	pop bc
	ld a, b
	ldh [hTempPlayAreaLocation_ff9d], a
	ccf
	ret nc ; return if the given attack can't be used

; player's active Pokémon can use attack
	ld a, [wSelectedAttack]
	call EstimateDamage_FromDefendingPokemon
	ldh a, [hTempPlayAreaLocation_ff9d]
	add DUELVARS_ARENA_CARD_HP
	get_turn_duelist_var
	dec a ; subtract 1 so carry will be set if final HP = 0
	ld hl, wDamage
	sub [hl]
	ret

; sets carry if Opponent's deck ID
; is between LEGENDARY_MOLTRES_DECK_ID (inclusive)
; and MUSCLES_FOR_BRAINS_DECK_ID (exclusive)
; these are the decks for Grandmaster/Club Master/Ronald
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

; sets carry if not a boss fight
; and if hasn't received legendary cards yet
CheckIfNotABossDeckID:
	call EnableSRAM
	ld a, [sReceivedLegendaryCards]
	call DisableSRAM
	or a
	ret nz ; nc
	call CheckIfOpponentHasBossDeckID
	ccf
	ret

; checks if any bench Pokémon has same ID
; as input, and sets carry if it has more than
; half health and can use its second attack
; input:
;	a = card ID to check for
; output:
;	carry set if the above requirements are met
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

; add 5 to wPlayAreaEnergyAIScore AI score corresponding to all cards
; in bench that have same ID as register a
; input:
;	a = card ID to look for
RaiseAIScoreToAllMatchingIDsInBench:
	ld d, a
	ld a, DUELVARS_BENCH
	get_turn_duelist_var
	ld e, 0
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
	ld e, 0

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

; loads wcdf9 with card ID
; and call Func_17583
	ld a, [wcdf9]
	call _GetCardIDFromDeckIndex
	ld [wcdf9], a
	push hl
	push de
	call Func_17583

; check play area Pokémon ahead
; if there is a card with the same ID,
; call Func_17583 for it as well
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

; if there are more than 1 of the same ID
; in play area, iterate bench backwards
; and determines which card has highest
; score in wcdea
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

; c = play area location of highest score
; decrease wPlayAreaEnergyAIScore score for all cards with same ID
; except for the one with highest score
; increase wPlayAreaEnergyAIScore score for card with highest ID
.asm_17560
	ld hl, wPlayAreaEnergyAIScore
	ld de, wcdea
	ld b, PLAY_AREA_ARENA
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
; with energy  * 2 + $80 - floor(dam / 10)
; loads wcdfa + play area location in e
; with $01
Func_17583:
	push hl
	push de
	call GetCardDamageAndMaxHP
	call ConvertHPToDamageCounters_Bank5
	ld b, a
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

; counts how many play area locations in wcdea
; are != 0, and outputs result in a
; also returns carry if result is < 2
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
HandleAIAntiMewtwoDeckStrategy:
; return carry if Player is not playing MewtwoLv53 mill deck
	ld a, [wAIBarrierFlagCounter]
	bit AI_MEWTWO_MILL_F, a
	jr z, .set_carry

; else, check if there's been less than 2 turns
; without the Player using Barrier.
	cp AI_MEWTWO_MILL + 2
	jr c, .count_bench

; if there has been, reset wAIBarrierFlagCounter
; and return carry.
	xor a
	ld [wAIBarrierFlagCounter], a
	; fallthrough
	
.set_carry
	scf
	ret

; else, check number of Pokemon that are set up in Bench
; if less than 4, return carry.
.count_bench
	call CountNumberOfSetUpBenchPokemon
	cp 4
	ret c

; if there's at least 4 Pokemon in the Bench set up,
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
; returns carry if loaded attack effect has
; an "initial effect 2" or "require selection" command type
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
; expects a $00-terminated list of 3-byte data with the following:
; - non-zero value (anything but $1 is ignored)
; - card ID to look for in Play Area
; - number of energy cards
; returns carry if a card ID is found in bench with at least the
; listed number of energy cards
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
; expects a $00-terminated list of 3-byte data with the following:
; - non-zero value
; - card ID
; - number of energy cards
; goes through the given list and if a card with a listed ID is found
; with less than the number of energy cards corresponding to its entry
; then have AI try to play an energy card from the hand to it
;Func_15886:
;	call CreateEnergyCardListFromHand
;	ret c ; quit if no energy cards in hand
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
;	jr nc, .next ; skip if not found in Play Area
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
