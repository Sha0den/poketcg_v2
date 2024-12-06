; handles AI logic for using some Pokémon Powers that need to be activated.
; The Pokémon Powers which are handled here are:
;	- VenusaurLv64's Solar Power
;	- Vileplume's Heal
;	- Venomoth's Shift
;	- Tentacool's Cowardice
;	- Mankey's Peek
;	- Slowbro's Strange Behavior
;	- Gengar's Curse
;	- DragoniteLv45's Step In
; output:
;	carry = set:  if the turn ended
HandleAIPkmnPowers:
	call CheckIfPkmnPowersAreCurrentlyDisabled
	ccf
	ret nc ; return no carry if Pokémon Powers can't be used

	call AIChooseRandomlyNotToDoAction
	ccf
	ret nc ; return no carry if AI randomly decides to

	ld a, DUELVARS_NUMBER_OF_POKEMON_IN_PLAY_AREA
	get_turn_duelist_var
	ld b, a
	ld c, PLAY_AREA_ARENA
	ld a, DUELVARS_ARENA_CARD_STATUS
	get_turn_duelist_var
	and CNF_SLP_PRZ
	jr nz, .next_2

.loop_play_area
	ld a, DUELVARS_ARENA_CARD
	add c
	get_turn_duelist_var
	ld [wce08], a

	push af
	push bc
	ld d, a
	ld a, c
	ldh [hTempPlayAreaLocation_ff9d], a
	ld e, FIRST_ATTACK_OR_PKMN_POWER
	call CopyAttackDataAndDamage_FromDeckIndex
	ld a, [wLoadedAttackCategory]
	cp POKEMON_POWER
	jr z, .execute_effect
	pop bc

.next_3
	pop af
	jr .next_2

.execute_effect
	ld a, EFFECTCMDTYPE_INITIAL_EFFECT_2
	call TryExecuteEffectCommandFunction
	pop bc
	jr c, .next_3

; TryExecuteEffectCommandFunction was successful,
; so check what Pokémon Power this is through the card's ID.
	pop af
	call _GetCardIDFromDeckIndex
	push bc

; solar power
	cp VENUSAUR_LV64
	jr nz, .heal
	call HandleAISolarPower
	jr .next_1

.heal
	cp VILEPLUME
	jr nz, .shift
	call HandleAIHeal
	jr .next_1

.shift
	cp VENOMOTH
	jr nz, .cowardice
	call HandleAIShift
	jr .next_1

.cowardice
	cp TENTACOOL
	jr nz, .peek
	call HandleAICowardice
	jr .next_1

.peek
	cp MANKEY
	jr nz, .strange_behavior
	call HandleAIPeek
	jr .next_1

.strange_behavior
	cp SLOWBRO
	jr nz, .curse
	call HandleAIStrangeBehavior
	jr .next_1

.curse
	cp GENGAR
	jr nz, .step_in
	call HandleAICurse
	jr nc, .next_1
	; turn/duel has ended
	pop bc
	ret ; carry set

.step_in
	cp DRAGONITE_LV45
	call z, HandleAIStepIn
;	fallthrough

.next_1
	pop bc
.next_2
	inc c
	ld a, c
	cp b
	jr nz, .loop_play_area
	ret


; checks whether AI uses VenusaurLv64's Solar Power
; input:
;	c = user's play area location offset (PLAY_AREA_* constant)
HandleAISolarPower:
	ld a, c
	ldh [hTemp_ffa0], a
	ld a, DUELVARS_ARENA_CARD_STATUS
	get_turn_duelist_var
	or a ; cp NO_STATUS
	ret z ; return if the AI's Active Pokémon isn't affected by any Special Conditions
	ld a, [wce08]
	ldh [hTempCardIndex_ff9f], a
	ld a, OPPACTION_USE_PKMN_POWER
	bank1call AIMakeDecision
	ld a, OPPACTION_EXECUTE_PKMN_POWER_EFFECT
	bank1call AIMakeDecision
	ld a, OPPACTION_DUEL_MAIN_SCENE
	bank1call AIMakeDecision
	ret


; checks whether AI uses Vileplume's Heal on 1 of its Pokémon
; input:
;	c = user's play area location offset (PLAY_AREA_* constant)
HandleAIHeal:
	ld a, c
	ldh [hTemp_ffa0], a
	call .CheckHealTarget
	ret nc ; return if no target to heal
	push af
	ld a, [wce08]
	ldh [hTempCardIndex_ff9f], a
	ld a, OPPACTION_USE_PKMN_POWER
	bank1call AIMakeDecision
	pop af
	ldh [hPlayAreaEffectTarget], a
	ld a, OPPACTION_EXECUTE_PKMN_POWER_EFFECT
	bank1call AIMakeDecision
	ld a, OPPACTION_DUEL_MAIN_SCENE
	bank1call AIMakeDecision
	ret

; finds a target suitable for AI to use Heal on.
; only heals the Active Pokémon if the Defending Pokémon
; cannot KO it after Heal is used.
; output:
;	a = chosen Pokémon's play area location offset (PLAY_AREA_* constant)
;	carry = set:  if the AI found a suitable target for Heal
.CheckHealTarget
; check if the Active Pokémon has any damage counters,
; if not, check the Bench instead.
	ld e, PLAY_AREA_ARENA
	call GetCardDamageAndMaxHP
	or a
	jr z, .check_bench

	xor a ; PLAY_AREA_ARENA
	ldh [hTempPlayAreaLocation_ff9d], a
	farcall CheckIfDefendingPokemonCanKnockOut
	jr nc, .set_carry ; return carry if can't KO

; check if the Defending Pokémon can still KO
; this Pokémon after Heal is used on it.
; if Heal prevents KO, return carry.
	ld d, a
	ld a, DUELVARS_ARENA_CARD_HP
	get_turn_duelist_var
	add 10 - 1 ; amount of HP that would be healed minus 1 (so carry will be set if final HP = 0)
	sub d ; subtract damage of the opponent's strongest attack
	jr c, .check_bench

.set_carry
	xor a ; PLAY_AREA_ARENA
	scf
	ret

; find the Benched Pokémon with the most damage counters on it.
.check_bench
	ld a, DUELVARS_NUMBER_OF_POKEMON_IN_PLAY_AREA
	get_turn_duelist_var
	ld d, a
	lb bc, 0, PLAY_AREA_ARENA
	ld e, PLAY_AREA_ARENA
	jr .next_bench
.loop_bench
	push bc
	call GetCardDamageAndMaxHP
	pop bc
	cp b
	jr c, .next_bench
	jr z, .next_bench
	ld b, a ; store the amount of damage
	ld c, e ; store this play area location
.next_bench
	inc e
	dec d
	jr nz, .loop_bench

; check if a Pokémon with damage counters was found
; in the Bench and, if so, return carry.
.done
	ld a, c
	or a ; cp PLAY_AREA_ARENA
	ret z ; return no carry if it's still the default value
; found
	scf
	ret


; checks whether AI uses Venomoth's Shift. It must be the Active Pokémon
; and AI only tries to pick the Defending Pokémon's Weakness.
; input:
;	c = user's play area location offset (PLAY_AREA_* constant)
HandleAIShift:
	ld a, c
	or a ; cp PLAY_AREA_ARENA
	ret nz ; return if the user is not the Active Pokémon

	ldh [hTemp_ffa0], a
	call GetArenaCardColor
	call TranslateColorToWR
	ld b, a
	rst SwapTurn
	call GetArenaCardWeakness
	ld [wAIDefendingPokemonWeakness], a
	rst SwapTurn
	or a
	ret z ; return if Defending Pokémon has no Weakness
	and b
	ret nz ; return if the user's type already matches the Defending Pokémon's Weakness

; check whether there's a card in play with
; the same type/color as the Weakness of the Defending Pokémon
	call .CheckWhetherTurnDuelistHasColor
	jr c, .found
	rst SwapTurn
	call .CheckWhetherTurnDuelistHasColor
	rst SwapTurn
	ret nc ; return if no type/color was found

.found
	ld a, [wce08]
	ldh [hTempCardIndex_ff9f], a
	ld a, OPPACTION_USE_PKMN_POWER
	bank1call AIMakeDecision

; converts WR_* to appropriate type/color
	ld a, [wAIDefendingPokemonWeakness]
	ld b, 0
.loop_color
	bit 7, a
	jr nz, .done
	inc b
	rlca
	jr .loop_color

; use Pokémon Power effect
.done
	ld a, b
	ldh [hAIPkmnPowerEffectParam], a
	ld a, OPPACTION_EXECUTE_PKMN_POWER_EFFECT
	bank1call AIMakeDecision
	ld a, OPPACTION_DUEL_MAIN_SCENE
	bank1call AIMakeDecision
	ret

; preserves de
; input:
;	[wAIDefendingPokemonWeakness] = which type/color to look for (WR_* constant)
; output:
;	carry = set:  if the turn holder has a Pokémon with the same type/color as input
.CheckWhetherTurnDuelistHasColor
	ld a, [wAIDefendingPokemonWeakness]
	ld b, a
	ld a, DUELVARS_ARENA_CARD
	get_turn_duelist_var
	ld c, PLAY_AREA_ARENA
.loop_play_area
	ld a, [hli]
	cp -1 ; empty play area slot?
	ret z ; return no carry if there are no more Pokémon to check
	ld a, c
	call GetPlayAreaCardColor
	call TranslateColorToWR
	and b
	jr nz, .true
	inc c
	jr .loop_play_area
.true
	scf
	ret


; checks whether AI uses Tentacool's Cowardice. user must have 1 or more damage counters.
; also, if the user has any attached Energy, then the AI will only use Cowardice
; if it's the Active Pokémon and the Defending Pokémon can KO it during the next turn.
; input:
;	c = user's play area location offset (PLAY_AREA_* constant)
HandleAICowardice:
	ld e, c
	call GetCardDamageAndMaxHP
	or a
	ret z ; return if this Pokémon doesn't have any damage counters
	ld a, e
	ldh [hTemp_ffa0], a
	or a ; cp PLAY_AREA_ARENA
	jr z, .is_active
	; user is on the Bench
	call GetPlayAreaCardAttachedEnergies
	or a
	ret nz ; return if this Pokémon has any attached Energy
	ld a, -1 ; no need to switch so no Benched Pokémon was selected
.use_cowardice
	push af
	ld a, [wce08]
	ldh [hTempCardIndex_ff9f], a
	ld a, OPPACTION_USE_PKMN_POWER
	bank1call AIMakeDecision
	pop af
	ldh [hTempPlayAreaLocation_ffa1], a
	ld a, OPPACTION_EXECUTE_PKMN_POWER_EFFECT
	bank1call AIMakeDecision
	ld a, OPPACTION_DUEL_MAIN_SCENE
	bank1call AIMakeDecision
	ret

.is_active
	call GetPlayAreaCardAttachedEnergies
	or a
	jr z, .decide_switch_target ; use power if this Pokémon has no attached Energy
	farcall CheckIfActiveCardCanKnockOut
	ret c ; return if this Pokémon can KO the Defending Pokémon
	farcall CheckIfDefendingPokemonCanKnockOut
	ret nc ; return if Defending Pokémon can't KO this Pokémon
.decide_switch_target
	farcall AIDecideBenchPokemonToSwitchTo
	jr .use_cowardice


; checks whether AI uses Mankey's Peek. only used 6% of the time and
; AI randomly picks between its Prizes, the Player's hand, and the Player's deck.
; input:
;	c = user's play area location offset (PLAY_AREA_* constant)
HandleAIPeek:
	ld a, c
	ldh [hTemp_ffa0], a
	ld a, 50
	call Random
	cp 3
	ret nc ; return 47 out of 50 times

; choose what to use Peek on at random
	ld a, 3
	call Random
	or a
	jr z, .check_ai_prizes
	cp 2
	jr c, .check_player_hand

; check the Player's deck
	ld a, DUELVARS_NUMBER_OF_CARDS_NOT_IN_DECK
	call GetNonTurnDuelistVariable
	cp DECK_SIZE - 1
	ret nc ; return if the Player has fewer than 2 cards in their deck
	ld a, AI_PEEK_TARGET_DECK
	jr .use_peek

.check_ai_prizes
	ld a, DUELVARS_PRIZES
	get_turn_duelist_var
	ld hl, wAIPeekedPrizes
	and [hl]
	ld [hl], a
	or a
	ret z ; return if no Prizes

	ld c, a
	ld b, $1
	ld d, 0
.loop_prizes
	ld a, c
	and b
	jr nz, .found_prize
	sla b
	inc d
	jr .loop_prizes
.found_prize
; remove this Prize's flag from the prize list
; and use Peek on first one in list (lowest bit set)
	ld a, c
	sub b
	ld [hl], a
	ld a, AI_PEEK_TARGET_PRIZE
	add d
	jr .use_peek

.check_player_hand
	rst SwapTurn
	call CreateHandCardList
	rst SwapTurn
	or a
	ret z ; return if no cards in hand
; shuffle list and pick the first entry to Peek
	ld hl, wDuelTempList
	call ShuffleCards
	ld a, [wDuelTempList]
	or AI_PEEK_TARGET_HAND

.use_peek
	push af
	ld a, [wce08]
	ldh [hTempCardIndex_ff9f], a
	ld a, OPPACTION_USE_PKMN_POWER
	bank1call AIMakeDecision
	pop af
	ldh [hAIPkmnPowerEffectParam], a
	ld a, OPPACTION_EXECUTE_PKMN_POWER_EFFECT
	bank1call AIMakeDecision
	ld a, OPPACTION_DUEL_MAIN_SCENE
	bank1call AIMakeDecision
	ret


; checks whether AI uses Slowbro's Strange Behavior. It's only used from the Bench
; and AI only transfers damage counters from the Active Pokémon.
; input:
;	c = user's play area location offset (PLAY_AREA_* constant)
HandleAIStrangeBehavior:
	ld a, c
	or a ; cp PLAY_AREA_ARENA
	ret z ; return if the user is the Active Pokémon

	ldh [hTemp_ffa0], a
	ld e, PLAY_AREA_ARENA
	call GetCardDamageAndMaxHP
	or a
	ret z ; return if the Active Pokémon has no damage counters

	ld [wce06], a ; store the Active Pokémon's damage
	ldh a, [hTemp_ffa0]
	add DUELVARS_ARENA_CARD_HP
	get_turn_duelist_var
	sub 10
	ret z ; return if the user only has 10 HP remaining

; if the user can't receive all of the damage counters,
; only transfer remaining HP - 10 damage
	ld hl, wce06
	cp [hl]
	jr c, .use_strange_behavior
	ld a, [hl] ; can receive all damage counters

.use_strange_behavior
	push af
	ld a, [wce08]
	ldh [hTempCardIndex_ff9f], a
	ld a, OPPACTION_USE_PKMN_POWER
	bank1call AIMakeDecision
	xor a ; PLAY_AREA_ARENA
	ldh [hTempPlayAreaLocation_ffa1], a
	ld a, OPPACTION_EXECUTE_PKMN_POWER_EFFECT
	bank1call AIMakeDecision
	pop af

; loop counters chosen to transfer and use Pkmn Power
	call ConvertHPToDamageCounters_Bank8
	ld e, a
.loop_counters
	; 30 frame delay
	ld a, 30
	call DoAFrames

	push de
	ld a, OPPACTION_6B15
	bank1call AIMakeDecision
	pop de
	dec e
	jr nz, .loop_counters

; return to main scene after a 60 frame delay
	ld a, 60
	call DoAFrames
	ld a, OPPACTION_DUEL_MAIN_SCENE
	bank1call AIMakeDecision
	ret


; checks whether AI uses Gengar's Curse.
; input:
;	c = user's play area location offset (PLAY_AREA_* constant)
; output:
;	carry = set:  if the turn/duel has ended
HandleAICurse:
	ld a, c
	ldh [hTemp_ffa0], a

; loop through the Player's play area, checking for damage.
; finds the card with lowest remaining HP and
; stores its HP and its play area location offset
	ld a, DUELVARS_NUMBER_OF_POKEMON_IN_PLAY_AREA
	call GetNonTurnDuelistVariable
	ld d, a
	ld e, PLAY_AREA_ARENA
	lb bc, 0, $ff
	ld h, PLAY_AREA_ARENA
	rst SwapTurn
.loop_play_area_1
	push bc
	call GetCardDamageAndMaxHP
	pop bc
	or a
	jr z, .next_1

	inc b
	ld a, e
	add DUELVARS_ARENA_CARD_HP
	push hl
	get_turn_duelist_var
	pop hl
	cp c
	jr nc, .next_1
	; lower HP than one stored
	ld c, a ; store this HP
	ld h, e ; store this play area location

.next_1
	inc e
	dec d
	jr nz, .loop_play_area_1

	ld a, 1
	cp b
	jr nc, .failed ; return if less than 2 cards with damage

; the Pokémon with the lowest remaining HP was found.
; look for another Pokémon to take a damage counter from.
	ld a, h
	ldh [hPlayAreaEffectTarget], a
	ld b, a
	ld a, 10
	cp c
	jr z, .hp_10_remaining
	; if it has more than 10 HP remaining,
	; skip the Active Pokémon when choosing which
	; card to take a damage counter from.
	ld e, PLAY_AREA_BENCH_1
	jr .second_card

.hp_10_remaining
	; if Curse can KO, then include the Player's Active Pokémon
	; when selecting a damage counter to transfer.
	ld e, PLAY_AREA_ARENA

.second_card
	ld a, DUELVARS_NUMBER_OF_POKEMON_IN_PLAY_AREA
	get_turn_duelist_var
	ld d, a
.loop_play_area_2
	ld a, e
	cp b
	jr z, .next_2 ; skip same Pokémon card
	push bc
	call GetCardDamageAndMaxHP
	pop bc
	or a
	jr nz, .use_curse ; has damage counters, choose this card
.next_2
	inc e
	ld a, e
	cp d
	jr nz, .loop_play_area_2

.failed
	or a
	jp SwapTurn

.use_curse
	ld a, e
	ldh [hTempPlayAreaLocation_ffa1], a
	rst SwapTurn
	ld a, [wce08]
	ldh [hTempCardIndex_ff9f], a
	ld a, OPPACTION_USE_PKMN_POWER
	bank1call AIMakeDecision
	ld a, OPPACTION_EXECUTE_PKMN_POWER_EFFECT
	bank1call AIMakeDecision
	ld a, OPPACTION_DUEL_MAIN_SCENE
	bank1call AIMakeDecision
	ret


; checks whether AI uses Dragonite's Step In.
; Step In is only activated if the AI's Active Pokémon is about to be KO'd.
; the user must also have 4 Energy so that it can attack.
; input:
;	c = user's play area location offset (PLAY_AREA_* constant)
HandleAIStepIn:
	ld a, c
	ldh [hTemp_ffa0], a
	xor a ; PLAY_AREA_ARENA
	ldh [hTempPlayAreaLocation_ff9d], a
	farcall CheckIfDefendingPokemonCanKnockOut
	ret nc ; Defending Pokémon cannot KO
	ldh a, [hTemp_ffa0]
	ld e, a
	call GetPlayAreaCardAttachedEnergies
;	ld a, [wTotalAttachedEnergies] ; already loaded
	cp 4
	ccf
	ret nc ; user doesn't have enough Energy to attack
	ld a, [wce08]
	ldh [hTempCardIndex_ff9f], a
	ld a, OPPACTION_USE_PKMN_POWER
	bank1call AIMakeDecision
	ld a, OPPACTION_EXECUTE_PKMN_POWER_EFFECT
	bank1call AIMakeDecision
	ld a, OPPACTION_DUEL_MAIN_SCENE
	bank1call AIMakeDecision
	ret




; handles AI routines for Energy Trans.
; uses AI_ENERGY_TRANS_* constants as input:
;	- AI_ENERGY_TRANS_RETREAT: transfers enough Grass Energy cards to
;	  the Active Pokémon for it to be able to pay its Retreat Cost.
;	- AI_ENERGY_TRANS_ATTACK: transfers enough Grass Energy cards to
;	  the Active Pokémon for it to be able to use its second attack.
;	- AI_ENERGY_TRANS_TO_BENCH: transfers all Grass Energy cards from the
;	  Active Pokémon to the Bench in case the Active Pokémon will be KO'd.
HandleAIEnergyTrans:
	ld [wce06], a

; choose to randomly return
	call AIChooseRandomlyNotToDoAction
	ret c

	ld a, DUELVARS_NUMBER_OF_POKEMON_IN_PLAY_AREA
	get_turn_duelist_var
	dec a
	ret z ; return if there are no Benched Pokémon

	ld a, VENUSAUR_LV67
	call CountTurnDuelistPokemonWithActivePkmnPower
	ret nc ; return if no VenusaurLv67 was found in the AI's play area

	call CheckIfPkmnPowersAreCurrentlyDisabled
	ret c ; return if Pokémon Powers can't be used

	ld a, [wce06]
	cp AI_ENERGY_TRANS_RETREAT
	jr z, .check_retreat

	cp AI_ENERGY_TRANS_TO_BENCH
	jp z, AIEnergyTransTransferEnergyToBench

	; AI_ENERGY_TRANS_ATTACK
	call .CheckEnoughGrassEnergyCardsForAttack
	ret nc
	jr .TransferEnergyToArena

.check_retreat
	call .CheckEnoughGrassEnergyCardsForRetreatCost
	ret nc

; use Energy Trans to move Grass Energy cards from the Bench to the Active Pokémon.
; input:
;	a = number of Grass Energy cards that should be transferred to the Active Pokémon
.TransferEnergyToArena
	ld [wAINumberOfEnergyTransCards], a

; look for a VenusaurLv67 in the play area
; so that its Pokémon Power can be used.
	ld a, DUELVARS_NUMBER_OF_POKEMON_IN_PLAY_AREA
	get_turn_duelist_var
	dec a ; convert into the last play area location offset
	ld b, a
.loop_play_area
	ld a, DUELVARS_ARENA_CARD
	add b
	get_turn_duelist_var
	ldh [hTempCardIndex_ff9f], a
	call _GetCardIDFromDeckIndex
	cp VENUSAUR_LV67
	jr z, .use_pkmn_power

	ld a, b
	or a ; cp PLAY_AREA_ARENA
	ret z ; return if there are no more Pokémon to check in the play area

	dec b
	jr .loop_play_area

; use Energy Trans Pkmn Power
.use_pkmn_power
	ld a, b
	ldh [hTemp_ffa0], a
	ld a, OPPACTION_USE_PKMN_POWER
	bank1call AIMakeDecision
	ld a, OPPACTION_EXECUTE_PKMN_POWER_EFFECT
	bank1call AIMakeDecision

	xor a ; PLAY_AREA_ARENA
	ldh [hAIEnergyTransPlayAreaLocation], a
	ld a, [wAINumberOfEnergyTransCards]
	ld d, a

; look for Grass Energy cards that
; are currently attached to a Benched Pokémon.
	ld e, 0 ; initial deck index
.loop_deck_locations
	ld a, e ; DUELVARS_CARD_LOCATIONS + current deck index
	get_turn_duelist_var
	and %00011111
	cp CARD_LOCATION_BENCH_1
	jr c, .next_card

	and %00001111
	ldh [hTempPlayAreaLocation_ffa1], a

	ld a, e
	call _GetCardIDFromDeckIndex
	cp GRASS_ENERGY
	jr nz, .next_card

	; store the deck index of the Energy card
	ld a, e
	ldh [hAIEnergyTransEnergyCard], a

	; 30 frame delay
	ld a, 30
	call DoAFrames

	push de
	ld a, OPPACTION_6B15
	bank1call AIMakeDecision
	pop de
	dec d
	jr z, .done_transfer

.next_card
	inc e
	ld a, DECK_SIZE
	cp e
	jr nz, .loop_deck_locations

; transfer is done, perform delay
; and return to main scene.
.done_transfer
	ld a, 60
	call DoAFrames
	ld a, OPPACTION_DUEL_MAIN_SCENE
	bank1call AIMakeDecision
	ret

; assumes that there are no attacks that have both Grass Energy
; and another non-Colorless Energy in their attack cost.
; output:
;	a = amount of Energy that should be transferred to the Active Pokémon
;	    so that it can use its second attack:  if the below condition is true
;	carry = set:  if transferring Grass Energy from Benched Pokémon would
;	              allow the Active Pokémon to use its second attack
.CheckEnoughGrassEnergyCardsForAttack
	ld a, DUELVARS_ARENA_CARD
	get_turn_duelist_var
	call _GetCardIDFromDeckIndex
	cp EXEGGUTOR
	jr z, .is_exeggutor

	xor a ; PLAY_AREA_ARENA
	ldh [hTempPlayAreaLocation_ff9d], a
	ld a, SECOND_ATTACK
	ld [wSelectedAttack], a
	farcall CheckEnergyNeededForAttack
	ret nc ; return if no Energy needed

; check if only Colorless Energy is needed...
	ld a, b
	or a
	jr nz, .need_colored_energy
	ld a, c
	or a
	jr nz, .count_if_enough
	ret

; ...otherwise check if the needed Basic Energy is Grass.
.need_colored_energy
	farcall GetEnergyCardNeeded
	cp GRASS_ENERGY
	jr nz, .no_carry
	ld a, b
	add c
	ld c, a ; c = total number of Energy needed for the attack

.count_if_enough
; if there's enough Grass Energy cards in the Bench
; to satisfy the attack's Energy cost, return carry.
	call .CountGrassEnergyInBench
	cp c
	ccf
	ld a, c
	ret

.is_exeggutor
; in case Exeggutor is the Active Pokémon, return carry
; if there are any Grass Energy cards attached to Benched Pokémon.
	call .CountGrassEnergyInBench
	or a
	ret z ; return no carry if there are no Grass Energy to transfer
	scf
	ret

.no_carry
	or a
	ret

; preserves bc and e
; output:
;	a & d = number of Grass Energy cards attached to all of the AI's Benched Pokémon
.CountGrassEnergyInBench
	xor a
	ld d, a ; initial Grass Energy counter = 0
	; a = DUELVARS_CARD_LOCATIONS
	get_turn_duelist_var
	; hl = starting address for AI's card location data
.count_loop
	ld a, [hl]
	and %00011111
	cp CARD_LOCATION_BENCH_1
	jr c, .count_next ; skip if not in Bench

; card is in the Bench
	ld a, l
	call _GetCardIDFromDeckIndex
	cp GRASS_ENERGY
	jr nz, .count_next ; skip if not a Basic Grass Energy card
	inc d
.count_next
	inc l
	ld a, l
	cp DECK_SIZE
	jr c, .count_loop
	ld a, d
	ret

; output:
;	a & c = number of Energy cards that need to be transferred before the Active
;	        Pokémon can pay its Retreat Cost:  if the below condition is true
;	carry = set:  if the Active Pokémon can't pay its Retreat Cost without more Energy 
;	              and if Energy Trans can be used to make up the difference
.CheckEnoughGrassEnergyCardsForRetreatCost
	xor a ; PLAY_AREA_ARENA
	ld e, a
	ldh [hTempPlayAreaLocation_ff9d], a
	call GetPlayAreaCardRetreatCost
	ld b, a
	call GetPlayAreaCardAttachedEnergies
	cp b
	ret nc ; return if the Active Pokémon already has enough Energy to retreat

; see if there's enough Grass Energy cards
; in the Bench to satisfy the Retreat Cost
	ld c, a
	ld a, b
	sub c
	ld c, a
	call .CountGrassEnergyInBench
	cp c
	jr c, .no_carry ; return if there aren't enough Grass Energy to pay for the Retreat Cost

; output number of cards needed to retreat
	ld a, c
	scf
	ret

; AI logic to determine whether to use the Energy Trans Pokémon Power
; to transfer Energy cards from the Active Pokémon to some Pokémon on the Bench.
AIEnergyTransTransferEnergyToBench:
; return if the Active Pokémon has no Grass Energy cards attached to it.
	ld e, PLAY_AREA_ARENA
	call GetPlayAreaCardAttachedEnergies
	ld a, [wAttachedEnergies + GRASS]
	or a
	ret z

; return if the Defending Pokémon can't KO the AI's Active Pokémon.
	xor a ; PLAY_AREA_ARENA
	ldh [hTempPlayAreaLocation_ff9d], a
	farcall CheckIfDefendingPokemonCanKnockOut
	ret nc

; return if any of the Active Pokémon's attacks would be used by AI.
	farcall AIProcessButDontUseAttack
	ret c

; return if the AI decided that none of its Benched Pokémon need more Energy.
	farcall AIProcessButDontPlayEnergy_SkipEvolutionAndArena
	ret nc

; AI decided that an Energy card is needed, so find
; VenusaurLv67 in the play area and use its Pokémon Power.
	ld a, DUELVARS_NUMBER_OF_POKEMON_IN_PLAY_AREA
	get_turn_duelist_var
	dec a ; convert into the last play area location offset
	ld b, a
.loop_play_area
	ld a, DUELVARS_ARENA_CARD
	add b
	get_turn_duelist_var
	ldh [hTempCardIndex_ff9f], a
	ld [wAIVenusaurLv67DeckIndex], a
	call _GetCardIDFromDeckIndex
	cp VENUSAUR_LV67
	jr z, .use_pkmn_power

	ld a, b
	or a ; cp PLAY_AREA_ARENA
	ret z ; return if there are no more Pokémon to check in the play area

	dec b
	jr .loop_play_area

; use the Energy Trans Pokémon Power
.use_pkmn_power
	ld a, b
	ldh [hTemp_ffa0], a
	ld [wAIVenusaurLv67PlayAreaLocation], a
	ld a, OPPACTION_USE_PKMN_POWER
	bank1call AIMakeDecision
	ld a, OPPACTION_EXECUTE_PKMN_POWER_EFFECT
	bank1call AIMakeDecision

; loop for transferring the Grass Energy cards.
.loop_energy
	xor a
	ldh [hTempPlayAreaLocation_ffa1], a
	ld a, [wAIVenusaurLv67PlayAreaLocation]
	ldh [hTemp_ffa0], a

	; returns when the Active Pokémon has no Grass Energy cards attached to it.
	ld e, PLAY_AREA_ARENA
	call GetPlayAreaCardAttachedEnergies
	ld a, [wAttachedEnergies + GRASS]
	or a
	jr z, .done_transfer

; look for Grass Energy cards that
; are currently attached to the Active Pokémon.
	ld e, 0 ; initial deck index
.loop_deck_locations
	ld a, e ; DUELVARS_CARD_LOCATIONS + current deck index
	get_turn_duelist_var
	cp CARD_LOCATION_ARENA
	jr nz, .next_card

	ld a, e
	call _GetCardIDFromDeckIndex
	cp GRASS_ENERGY
	jr nz, .next_card

	; store the deck index of the Energy card
	ld a, e
	ldh [hAIEnergyTransEnergyCard], a

.transfer
; get the Benched Pokémon's location to transfer the Grass Energy card to.
	farcall AIProcessButDontPlayEnergy_SkipEvolutionAndArena
	jr nc, .done_transfer
	ldh a, [hTempPlayAreaLocation_ff9d]
	ldh [hAIEnergyTransPlayAreaLocation], a

	; 30 frame delay
	ld a, 30
	call DoAFrames

	ld a, [wAIVenusaurLv67DeckIndex]
	ldh [hTempCardIndex_ff9f], a
	ld d, a
	ld e, FIRST_ATTACK_OR_PKMN_POWER
	call CopyAttackDataAndDamage_FromDeckIndex
	ld a, OPPACTION_6B15
	bank1call AIMakeDecision
	jr .loop_energy

.next_card
	inc e
	ld a, DECK_SIZE
	cp e
	jr nz, .loop_deck_locations

; transfer is done, perform delay
; and return to main scene.
.done_transfer
	ld a, 60
	call DoAFrames
	ld a, OPPACTION_DUEL_MAIN_SCENE
	bank1call AIMakeDecision
	ret




; AI logic for Damage Swap to transfer damage from the Active Pokémon
; to a Benched Pokémon with more than 10 HP remaining
; and with no Energy cards attached to it.
; only removes damage counters from the Active Pokémon and will only select
; specific Pokémon (from Murray's Strange Psyshock deck) for the transfer.
HandleAIDamageSwap:
	ld a, DUELVARS_NUMBER_OF_POKEMON_IN_PLAY_AREA
	get_turn_duelist_var
	dec a
	ret z ; return if there are no Benched Pokémon

	call AIChooseRandomlyNotToDoAction
	ret c

	ld a, ALAKAZAM
	call CountTurnDuelistPokemonWithActivePkmnPower
	ret nc ; return if no Alakazam
	call CheckIfPkmnPowersAreCurrentlyDisabled
	ret c ; return if Pokémon Powers can't be used

; only take damage off certain Active Pokémon
	ld a, DUELVARS_ARENA_CARD
	get_turn_duelist_var
	call _GetCardIDFromDeckIndex
	cp ALAKAZAM
	jr z, .ok
	cp KADABRA
	jr z, .ok
	cp ABRA
	jr z, .ok
	cp MR_MIME
	ret nz

.ok
	ld e, PLAY_AREA_ARENA
	call GetCardDamageAndMaxHP
	or a
	ret z ; return if no damage

	call ConvertHPToDamageCounters_Bank8
	ld [wce06], a
	ld a, ALAKAZAM
	ld b, PLAY_AREA_BENCH_1
	call LookForCardIDInPlayArea_Bank8
	jr c, .is_in_bench

; the only Alakazam is the Active Pokémon
	xor a ; PLAY_AREA_ARENA
.is_in_bench
	ld [wce08], a
	call .CheckForDamageSwapTargetInBench
	ret c ; return if not found

; use Damage Swap
	ld a, [wce08]
	add DUELVARS_ARENA_CARD
	get_turn_duelist_var
	ldh [hTempCardIndex_ff9f], a
	ld a, [wce08]
	ldh [hTemp_ffa0], a
	ld a, OPPACTION_USE_PKMN_POWER
	bank1call AIMakeDecision
	ld a, OPPACTION_EXECUTE_PKMN_POWER_EFFECT
	bank1call AIMakeDecision

	ld a, [wce06]
	ld e, a
.loop_damage
	; 30 frame delay
	ld a, 30
	call DoAFrames

	push de
	call .CheckForDamageSwapTargetInBench
	jr c, .no_more_target

	ldh [hPlayAreaEffectTarget], a
	xor a ; PLAY_AREA_ARENA
	ldh [hTempPlayAreaLocation_ffa1], a
	ld a, OPPACTION_6B15
	bank1call AIMakeDecision
	pop de
	dec e
	jr nz, .loop_damage

.done
; return to main scene after a 60 frame delay
	ld a, 60
	call DoAFrames
	ld a, OPPACTION_DUEL_MAIN_SCENE
	bank1call AIMakeDecision
	ret

.no_more_target
	pop de
	jr .done

; looks for a Benched Pokémon to receive the damage counters.
; output:
;	a = chosen Pokémon's play area location offset (PLAY_AREA_* constant)
;	carry = set:  if the AI didn't choose a Benched Pokémon
.CheckForDamageSwapTargetInBench
	ld a, DUELVARS_NUMBER_OF_POKEMON_IN_PLAY_AREA
	get_turn_duelist_var
	ld b, a
	ld c, PLAY_AREA_BENCH_1
	lb de, $ff, $ff

; look for candidates on the Bench to get the damage counters
; only target specific card IDs.
.loop_bench
	ld a, c
	add DUELVARS_ARENA_CARD
	get_turn_duelist_var
	call _GetCardIDFromDeckIndex
	cp CHANSEY
	jr z, .found_candidate
	cp KANGASKHAN
	jr z, .found_candidate
	cp SNORLAX
	jr z, .found_candidate
	cp MR_MIME
	jr z, .found_candidate

.next_play_area
	inc c
	dec b
	jr nz, .loop_bench

; done
	ld a, e
	cp $ff
	jr nz, .no_carry
	ld a, d
	cp $ff
	jr z, .set_carry
.no_carry
	or a
	ret

.found_candidate
; found a potential candidate to receive damage counters
	ld a, DUELVARS_ARENA_CARD_HP
	add c
	get_turn_duelist_var
	cp 20
	jr c, .next_play_area ; ignore cards with only 10 HP left

	ld d, c ; store location
	push de
	ld e, c
	call GetPlayAreaCardAttachedEnergies
	pop de
	or a
	jr nz, .next_play_area ; ignore cards with attached Energy
	ld e, c ; store location again
	jr .next_play_area

.set_carry
	scf
	ret




; handles AI logic for attaching Energy cards in the Go Go Rain Dance deck.
HandleAIGoGoRainDanceEnergy:
	ld a, [wOpponentDeckID]
	cp GO_GO_RAIN_DANCE_DECK_ID
	ret nz ; return if not Go Go Rain Dance deck

	ld a, BLASTOISE
	call CountTurnDuelistPokemonWithActivePkmnPower
	ret nc ; return if no Blastoise
	call CheckIfPkmnPowersAreCurrentlyDisabled
	ret c ; return if Pokémon Powers can't be used

; play all the Energy cards that are needed.
.loop
	farcall AIProcessAndTryToPlayEnergy
	jr c, .loop
	ret
