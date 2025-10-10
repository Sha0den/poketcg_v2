; determines the AI's score for retreating
; output:
;	carry = set:  if the AI decided to retreat
AIDecideWhetherToRetreat:
	ld a, [wOncePerTurnFlags]
	and UNABLE_TO_RETREAT_THIS_TURN
	ret nz ; return no carry if flipped tails after trying to retreat while Confused
	ld [wAIPlayEnergyCardForRetreat], a ; FALSE
	call LoadDefendingPokemonColorWRAndPrizeCards
	ld a, $80 ; initial retreat score
	ld [wAIScore], a
	ld a, [wAIRetreatScore]
	or a
	jr z, .check_status
	; add wAIRetreatScore * 2 to score
	add a ; *2
	call AIEncourage

; increase the score by 2 if the AI's Active Pokémon is Poisoned and
; increase the score by 1 if the AI's Active Pokémon is Confused.
.check_status
	ld a, DUELVARS_ARENA_CARD_STATUS
	get_turn_duelist_var
	or a ; cp NO_STATUS
	jr z, .skip_status_check 
	and DOUBLE_POISONED
	ld a, 2
	call nz, AIEncourage ; add 2 if Poisoned/Double Poisoned
	ld a, [hl]
	and CNF_SLP_PRZ
	cp CONFUSED
	ld a, 1
	call z, AIEncourage ; add 1 if Confused

; decrease the score by 5 if the AI's Active Pokémon could KO the Defending Pokémon this turn.
; decrease the score by another 35 if the AI only has 1 remaining Prize card.
.skip_status_check 
	call CheckIfActiveWillNotBeAbleToKODefending
	jr c, .active_cant_ko_1
	; Active Pokémon can KO
	ld a, 5
	call AIDiscourage
	ld a, [wAIOpponentPrizeCount]
	dec a ; cp 1
	ld a, 35
	call z, AIDiscourage ; subtract 35 if on last prize

.active_cant_ko_1
; increase the score by 2 if the Defending Pokémon can KO the AI's Active Pokémon.
	call CheckIfDefendingPokemonCanKnockOut
	jr nc, .defending_cant_ko
	ld a, 2
	call AIEncourage

; if using a boss deck and the Player only has 1 remaining Prize card,
; then allow the AI to attach an Energy card from its hand
; to the Active Pokémon in order to pay its Retreat Cost.
	call CheckIfNotABossDeckID
	jr c, .check_resistance_1
	ld a, [wAIPlayerPrizeCount]
	cp 1
	jr nz, .check_prize_count
	ld [wAIPlayEnergyCardForRetreat], a ; TRUE

.defending_cant_ko
; increase the score by 2 if AI is using a boss deck
; and the Player only has 1 remaining Prize card.
	call CheckIfNotABossDeckID
	jr c, .check_resistance_1
	ld a, [wAIPlayerPrizeCount]
	dec a ; cp 1
	ld a, 2
	call z, AIEncourage ; add 2 if on last prize

.check_prize_count
; decrease the score by 2 if the AI only has 1 remaining Prize card.
	ld a, [wAIOpponentPrizeCount]
	dec a ; cp 1
	ld a, 2
	call z, AIDiscourage ; subtract 2 if on last prize

.check_resistance_1
; increase the score by 1 if the Defending Pokémon
; has a Resistance to the AI's Active Pokémon.
	call GetArenaCardColor
	call TranslateColorToWR
	ld b, a
	ld a, [wAIPlayerResistance]
	and b
	jr z, .check_weakness_1
	ld a, 1
	call AIEncourage

; look for a Pokémon on the AI's Bench with a type that
; the Defending Pokémon doesn't have a Resistance to.
; if none were found, decrease the AI score by 2.
	ld a, [wAIPlayerResistance]
	ld b, a
	ld a, DUELVARS_BENCH
	get_turn_duelist_var
.loop_resistance_1
	ld a, [hli]
	cp -1 ; empty play area slot?
	jr z, .exit_loop_resistance_1
	call LoadCardDataToBuffer1_FromDeckIndex
	ld a, [wLoadedCard1Type]
	call TranslateColorToWR
	and b
	jr nz, .loop_resistance_1
	jr .check_weakness_1
.exit_loop_resistance_1
	ld a, 2
	call AIDiscourage

.check_weakness_1
; increase the score by 2 if the AI's Active Pokémon
; has a Weakness to the Defending Pokémon's type.
	ld a, [wAIPlayerColor]
	ld b, a
	call GetArenaCardWeakness
	and b
	jr z, .check_resistance_2
	ld a, 2
	call AIEncourage

; look for a Pokémon on the AI's Bench that doesn't
; have a Weakness to the Defending Pokémon's type.
; if none were found, decrease the AI score by 3.
;	ld a, [wAIPlayerColor]
;	ld b, a ; Defending Pokémon's type is already in b
	ld a, DUELVARS_BENCH
	get_turn_duelist_var
.loop_weakness_1
	ld a, [hli]
	cp -1 ; empty play area slot?
	jr z, .exit_loop_weakness_1
	call LoadCardDataToBuffer1_FromDeckIndex
	ld a, [wLoadedCard1Weakness]
	and b
	jr nz, .loop_weakness_1
	; found a Benched Pokémon that isn't weak to the Defending Pokémon
	jr .check_resistance_2
.exit_loop_weakness_1
	ld a, 3
	call AIDiscourage

.check_resistance_2
; decrease the score by 3 if the AI's Active Pokémon
; has a Resistance to the Defending Pokémon's type.
;	ld a, [wAIPlayerColor]
;	ld b, a ; Defending Pokémon's type is already in b
	call GetArenaCardResistance
	and b
	ld a, 3
	call nz, AIDiscourage ; subtract 3 if it has a useful Resistance

; look for a Pokémon on the AI's Bench with a type
; that matches the Defending Pokémon's Weakness.
; if any were found, increase the AI score by 3.
	ld a, [wAIPlayerWeakness]
	ld b, a
	ld a, DUELVARS_BENCH
	get_turn_duelist_var
	ld e, PLAY_AREA_BENCH_1 - 1
.loop_weakness_2
	ld a, [hli]
	cp -1 ; empty play area slot?
	jr z, .check_resistance_3
	inc e
	call LoadCardDataToBuffer1_FromDeckIndex
	ld a, [wLoadedCard1Type]
	call TranslateColorToWR
	and b
	jr z, .loop_weakness_2
	ld a, 2
	call AIEncourage

	ld a, DUELVARS_ARENA_CARD
	get_turn_duelist_var
	call _GetCardIDFromDeckIndex
	cp PORYGON
	jr nz, .check_weakness_3

; if the AI's Active Pokémon is Porygon and
; the Benched Pokémon with the matching type
; can damage the Defending Pokémon,
; then increase the score by 10.
	ld a, e
	call CheckIfCanDamageDefendingPokemon
	jr nc, .check_weakness_3
	ld a, 10
	call AIEncourage
	jr .check_resistance_3

.check_weakness_3
; decrease the score by 3 if the Defending Pokémon has
; a Weakness to the type of the AI's Active Pokémon.
	call GetArenaCardColor
	call TranslateColorToWR
	ld b, a
	ld a, [wAIPlayerWeakness]
	and b
	ld a, 3
	call nz, AIDiscourage ; subtract 3 if able to target Weakness

; look for a Pokémon on the AI's Bench with
; a Resistance to the Defending Pokémon's type.
; if any were found, increase the AI score by 1.
.check_resistance_3
	ld a, [wAIPlayerColor]
	ld b, a
	ld a, DUELVARS_BENCH
	get_turn_duelist_var
.loop_resistance_2
	ld a, [hli]
	cp -1 ; empty play area slot?
	jr z, .check_ko_2
	call LoadCardDataToBuffer1_FromDeckIndex
	ld a, [wLoadedCard1Resistance]
	and b
	jr z, .loop_resistance_2
	ld a, 1
	call AIEncourage

; look for a Pokémon on the AI's Bench that can KO the Defending Pokémon.
; if any were found, increase the AI score by 2.
.check_ko_2
	ld a, DUELVARS_NUMBER_OF_POKEMON_IN_PLAY_AREA
	get_turn_duelist_var
	ld b, a
	ld c, PLAY_AREA_BENCH_1 - 1
.loop_ko_1
	inc c
	dec b
	jr z, .check_defending_id
	push bc
	ld a, c
	ldh [hTempPlayAreaLocation_ff9d], a
	call CheckIfAnyAttackKnocksOutDefendingCard
	jr nc, .no_ko
	call CheckIfSelectedAttackIsUnusable
	jr nc, .success
	call LookForEnergyNeededForAttackInHand
	jr c, .success
.no_ko
	pop bc
	jr .loop_ko_1
.success
	pop bc
	ld a, 2
	call AIEncourage

; a Benched Pokémon was found that can KO.
; if this is a boss deck and it has only 1 Prize card left,
; then increase the score by 40 if the Active Pokémon can't KO,
; and allow the AI to attach an Energy card from its hand
; to the Active Pokémon in order to pay its Retreat Cost.

	ld a, [wAIOpponentPrizeCount]
	dec a ; cp 1
	jr nz, .check_defending_id
	call CheckIfNotABossDeckID
	jr c, .check_defending_id
	call CheckIfActiveCardCanKnockOut
	jr c, .check_defending_id
	; Active Pokémon can't KO
	ld a, 40
	call AIEncourage
	ld a, TRUE
	ld [wAIPlayEnergyCardForRetreat], a

.check_defending_id
	rst SwapTurn
	ld a, DUELVARS_ARENA_CARD
	get_turn_duelist_var
	call _GetCardIDFromDeckIndex
	rst SwapTurn
	cp MR_MIME
	jr nz, .check_retreat_cost

; if the Active Pokémon can't damage the opponent's Mr. Mime,
; then look for a Pokémon on the AI's Bench that can damage it.
; if one is found, then increase the score by 5 and
; allow the AI to attach an Energy card from its hand
; to the Active Pokémon in order to pay its Retreat Cost.
	xor a ; PLAY_AREA_ARENA
	call CheckIfCanDamageDefendingPokemon
	jr c, .check_retreat_cost

	ld a, DUELVARS_NUMBER_OF_POKEMON_IN_PLAY_AREA
	get_turn_duelist_var
	ld b, a
	ld c, PLAY_AREA_BENCH_1 - 1
.loop_damage
	inc c
	dec b
	jr z, .check_retreat_cost
	ld a, c
	push bc
	call CheckIfCanDamageDefendingPokemon
	pop bc
	jr nc, .loop_damage

	ld a, 5
	call AIEncourage
	ld a, TRUE
	ld [wAIPlayEnergyCardForRetreat], a

; decrease the score if Active Pokémon's Retreat Cost > 1.
.check_retreat_cost
	xor a ; PLAY_AREA_ARENA
	ldh [hTempPlayAreaLocation_ff9d], a
	call GetPlayAreaCardRetreatCost
	ld b, 1
	cp 2
	jr c, .one_or_none
	jr z, .exactly_two
	; -1 to score if Retreat Cost = 2
	; -2 to score if Retreat Cost > 2
	inc b
.exactly_two
	ld a, b
	call AIDiscourage

.one_or_none
; if the AI's Active Pokémon isn't set up, then look for Benched Pokémon
; that are set up, and increase the score by 1 for each one that qualifies.
; A Pokémon is set up if it isn't able to evolve, has at least half
; of its HP left, and has enough Energy to use each of its attacks.
	call CheckIfArenaCardIsFullyPowered
	jr c, .check_defending_can_ko
	call CountNumberOfSetUpBenchPokemon
	cp 2
	call nc, AIEncourage ; add number of set up Pokémon on Bench (if more than 1)

; look for a non-Trainer Pokémon on the AI's Bench that the Defending Pokémon
; isn't able to KO, and if none are found, then decrease the score by 20.
.check_defending_can_ko
	ld a, DUELVARS_BENCH
	get_turn_duelist_var
	ld e, PLAY_AREA_BENCH_1 - 1
.loop_ko_2
	ld a, [hli]
	cp -1 ; empty play area slot?
	jr z, .exit_loop_ko
	inc e
	call _GetCardIDFromDeckIndex
	cp MYSTERIOUS_FOSSIL
	jr z, .loop_ko_2
	cp CLEFAIRY_DOLL
	jr z, .loop_ko_2
	ld a, e
	ldh [hTempPlayAreaLocation_ff9d], a
	push de
	push hl
	call CheckIfDefendingPokemonCanKnockOut
	pop hl
	pop de
	jr c, .loop_ko_2
	; found a Benched Pokémon that won't be KO'd by the Defending Pokémon
	jr .check_active_id
.exit_loop_ko
	ld a, 20
	call AIDiscourage

.check_active_id
	ld a, DUELVARS_ARENA_CARD
	get_turn_duelist_var
	call _GetCardIDFromDeckIndex
	cp MYSTERIOUS_FOSSIL
	jr z, .mysterious_fossil_or_clefairy_doll
	cp CLEFAIRY_DOLL
	jr z, .mysterious_fossil_or_clefairy_doll

; if wAIScore is at least 131, set carry
	ld a, [wAIScore]
	cp 131
	ccf
	ret

; set carry regardless if the Active Pokémon is
; either Mysterious Fossil or Clefairy Doll
; and there's a Benched Pokémon who is not KO'd
; by the Defending Pokémon and can damage it.
.mysterious_fossil_or_clefairy_doll
	ld e, PLAY_AREA_BENCH_1 - 1
.loop_ko_3
	inc e
	ld a, e
	add DUELVARS_ARENA_CARD
	get_turn_duelist_var
	cp -1 ; empty play area slot?
	ret z ; return no carry if there are no more Benched Pokémon to check
	ld a, e
	ldh [hTempPlayAreaLocation_ff9d], a
	push de
	call CheckIfDefendingPokemonCanKnockOut
	pop de
	jr c, .loop_ko_3
	ld a, e
	push de
	call CheckIfCanDamageDefendingPokemon
	pop de
	jr nc, .loop_ko_3
	ret ; carry set


; if it's the Player's turn and the loaded attack is not a Pokémon Power
; OR if it's the AI's turn and wAITriedAttack == 0,
; then set wAIRetreatFlags's bit 7 flag.
; preserves all registers except af
; input:
;	[wLoadedAttack] = attack data for the Pokémon being checked (atk_data_struct)
SetAIRetreatFlags:
	xor a
	ld [wAIRetreatFlags], a
	ld a, [wWhoseTurn]
	cp OPPONENT_TURN
	jr z, .opponent

; player
	ld a, [wLoadedAttackCategory]
	cp POKEMON_POWER
	ret z
	jr .set_flag

.opponent
	ld a, [wAITriedAttack]
	or a
	ret nz

.set_flag
	ld a, %10000000
	ld [wAIRetreatFlags], a
	ret


; calculates the AI score for Benched Pokémon.
; output:
;	a & [hTempPlayAreaLocation_ff9d] = chosen Pokémon's play area location offset (PLAY_AREA_* constant)
;	carry = set:  if there are no Pokémon on the AI's Bench
AIDecideBenchPokemonToSwitchTo:
	xor a ; PLAY_AREA_ARENA
	ldh [hTempPlayAreaLocation_ff9d], a
	ld a, DUELVARS_NUMBER_OF_POKEMON_IN_PLAY_AREA
	get_turn_duelist_var
	cp 2
	ret c

; has at least 2 Pokémon in the play area
	call SetAIRetreatFlags
	call LoadDefendingPokemonColorWRAndPrizeCards
	ld a, 50
	ld [wAIScore], a
	ld a, DUELVARS_NUMBER_OF_POKEMON_IN_PLAY_AREA
	get_turn_duelist_var
	ld b, a
	ld c, PLAY_AREA_ARENA
	push bc
	jp .store_score

.loop_play_area
	push bc
	ld a, c
	ldh [hTempPlayAreaLocation_ff9d], a
	ld a, 50 ; this Pokémon's initial score
	ld [wAIScore], a

; increase this Pokémon's score by 10 if it can KO the Defending Pokémon.
; add another 10 to the score if the AI has only 1 Prize card remaining.
	call CheckIfAnyAttackKnocksOutDefendingCard
	jr nc, .check_can_use_atks
	call CheckIfSelectedAttackIsUnusable
	jr c, .check_can_use_atks
	ld a, 10
	call AIEncourage
	ld a, [wAIRetreatFlags]
	or %00000001
	ld [wAIRetreatFlags], a
	call CountPrizes
	dec a ; cp 1
	jr nz, .check_defending_weak
	ld a, 10
	call AIEncourage

; calculates damage of both attacks
; and increases this Pokémon's score accordingly
.check_can_use_atks
	xor a ; FIRST_ATTACK_OR_PKMN_POWER
	ld [wSelectedAttack], a
	call CheckIfSelectedAttackIsUnusable
	call nc, .HandleAttackDamageScore
	ld a, SECOND_ATTACK
	ld [wSelectedAttack], a
	call CheckIfSelectedAttackIsUnusable
	call nc, .HandleAttackDamageScore

; if an Energy card that is needed is found in the hand, then
; calculate the damage of the attack and increase this Pokémon's score.
; AI score += floor(Damage / 20)
	call LookForEnergyNeededInHand
	jr nc, .check_attached_energy
	ld a, [wSelectedAttack] ; SECOND_ATTACK
	call EstimateDamage_VersusDefendingCard
	ld a, [wDamage]
	call ConvertHPToDamageCounters_Bank5
	srl a ; divide number of damage counters by 2
	call AIEncourage

; decrease this Pokémon's score by 1 if no Energy is attached to the Pokémon.
.check_attached_energy
	ldh a, [hTempPlayAreaLocation_ff9d]
	ld e, a
	call GetPlayAreaCardAttachedEnergies
;	ld a, [wTotalAttachedEnergies] ; already loaded
	or a
	ld a, 1
	call z, AIDiscourage ; subtract 1 if no Energy is attached

; increase this Pokémon's score by 5 if it can damage the opponent's Mr. Mime.
	rst SwapTurn
	ld a, DUELVARS_ARENA_CARD
	get_turn_duelist_var
	call _GetCardIDFromDeckIndex
	rst SwapTurn
	cp MR_MIME
	jr nz, .check_defending_weak
	xor a ; FIRST_ATTACK_OR_PKMN_POWER
	call EstimateDamage_VersusDefendingCard
	ld a, [wDamage]
	or a
	jr nz, .can_damage
	ld a, SECOND_ATTACK
	call EstimateDamage_VersusDefendingCard
	ld a, [wDamage]
	or a
	jr z, .check_defending_weak
.can_damage
	ld a, 5
	call AIEncourage

; increase this Pokémon's score by 3 if the Defending Pokémon
; has a Weakness to this Pokémon's type.
.check_defending_weak
	ldh a, [hTempPlayAreaLocation_ff9d]
	add DUELVARS_ARENA_CARD
	get_turn_duelist_var
	call LoadCardDataToBuffer1_FromDeckIndex
	ld a, [wLoadedCard1Type]
	call TranslateColorToWR
	ld c, a
	ld a, [wAIPlayerWeakness]
	and c
	ld a, 3
	call nz, AIEncourage ; add 3 if it will do extra damage due to Weakness

; decrease this Pokémon's score by 2 if the Defending Pokémon
; has a Resistance to this Pokémon's type.
	ld a, [wAIPlayerResistance]
	and c
	ld a, 2
	call nz, AIDiscourage ; subtract 2 if it will be affected by Resistance

; increase this Pokémon's score by 2 if it has a Resistance to the Defending Pokémon's type.
	ld a, [wAIPlayerColor]
	ld c, a
	ld a, [wLoadedCard1Resistance]
	and c
	ld a, 2
	call nz, AIEncourage ; add 2 if it has a useful Resistance

; decrease this Pokémon's score by 3 if it has a Weakness to the Defending Pokémon's type.
	ld a, [wLoadedCard1Weakness]
	and c
	ld a, 3
	call nz, AIDiscourage ; subtract 3 if it has a problematic Weakness

; increase this Pokémon's score if its Retreat Cost < 2.
; decrease this Pokémon's score if its Retreat Cost > 2.
	call GetPlayAreaCardRetreatCost
	cp 2
	jr c, .one_or_none
	ld a, 1
	call nz, AIDiscourage ; subtract 1 if Retreat Cost is more than 2
	jr .check_player_prize_count
.one_or_none
	ld a, 1
	call AIEncourage

; if wAIRetreatFlags != $81 and the Defending Pokémon can KO this Pokémon,
; then decrease this Pokémon's score by 3 if the Player
; isn't on their last Prize card or by 10 if they are.
.check_player_prize_count
	ld a, [wAIRetreatFlags]
	cp %10000000 | %00000001
	jr z, .check_hp
	call CheckIfDefendingPokemonCanKnockOut
	jr nc, .check_hp
	ld e, 3
	ld a, [wAIPlayerPrizeCount]
	dec a ; cp 1
	jr nz, .lower_score_1
	ld e, 10
.lower_score_1
	ld a, e
	call AIDiscourage

; if this Pokémon's HP is 0, set the AI score to 0
.check_hp
	ldh a, [hTempPlayAreaLocation_ff9d]
	add DUELVARS_ARENA_CARD_HP
	get_turn_duelist_var
	or a
	jr nz, .add_hp_score
	ld [wAIScore], a

.store_score
	ldh a, [hTempPlayAreaLocation_ff9d]
	ld c, a
	ld b, $00
	ld hl, wPlayAreaAIScore
	add hl, bc
	ld a, [wAIScore]
	ld [hl], a
	pop bc
	inc c
	dec b
	jp nz, .loop_play_area

; done
	xor a
	ld [wAIRetreatScore], a
	jp FindHighestBenchScore

; AI score += floor(HP/40)
.add_hp_score
	ld b, a
	ld a, 4
	call CalculateBDividedByA_Bank5
	call ConvertHPToDamageCounters_Bank5
	call AIEncourage

; increase this Pokémon's score by 5 if it's a Mr Mime or
; if it's a MewLv8 and the Defending Pokémon's stage isn't Basic.
	ldh a, [hTempPlayAreaLocation_ff9d]
	add DUELVARS_ARENA_CARD
	get_turn_duelist_var
	call LoadCardDataToBuffer1_FromDeckIndex
	cp MR_MIME
	jr z, .raise_score
	cp MEW_LV8
	jr nz, .check_if_has_bench_utility
	rst SwapTurn
	ld a, DUELVARS_ARENA_CARD
	get_turn_duelist_var
	call LoadCardDataToBuffer2_FromDeckIndex
	rst SwapTurn
	ld a, [wLoadedCard2Stage]
	or a ; cp BASIC
	jr z, .check_if_has_bench_utility
.raise_score
	ld a, 5
	call AIEncourage

; decrease this Pokémon's score by 2 if it's probably more useful on the Bench.
; (e.g. Muk, Aerodactyl, Slowbro, Dodrio, etc.)
.check_if_has_bench_utility
	ld a, [wLoadedCard1PokemonFlags]
	and AI_TRY_TO_KEEP_ON_BENCH
	ld a, 2
	call nz, AIDiscourage ; subtract 2 if it has this flag

; decrease this Pokémon's score by 10 if it's a Mysterious Fossil or Clefairy Doll.
	ld a, [wLoadedCard1ID]
	ld b, a
	cp MYSTERIOUS_FOSSIL
	jr z, .lower_score_2
	cp CLEFAIRY_DOLL
	jr nz, .ai_score_bonus
.lower_score_2
	ld a, 10
	call AIDiscourage

; apply any assigned score bonuses that are specific to this deck.
.ai_score_bonus
	ld hl, wAICardListRetreatBonus
	ld a, [hli]
	ld h, [hl]
	ld l, a
	or h
	jr z, .store_score ; skip if pointer is null

.loop_ids
	ld a, [hli]
	or a
	jr z, .store_score ; list is over
	cp b
	jr nz, .next_id
	ld a, [hl]
	cp $80
	jr c, .subtract_score
	sub $80
	call AIEncourage
	jr .next_id
.subtract_score
	ld c, a
	ld a, $80
	sub c
	call AIDiscourage
.next_id
	inc hl
	jr .loop_ids

; increases the AI score depending on the amount of damage
; it can inflict to the Defending Pokémon.
; AI score += floor(Damage / 10) + 1
.HandleAttackDamageScore
	ld a, [wSelectedAttack]
	call EstimateDamage_VersusDefendingCard
	ld a, [wDamage]
	call ConvertHPToDamageCounters_Bank5
	inc a
	jp AIEncourage


; handles the AI retreating its Active Pokémon and chooses which Energy cards to discard.
; if the Active Pokémon is a Clefairy Doll or Mysterious Fossil,
; it uses its effect to discard itself instead of retreating.
; input:
;	a = play area location offset of the Benched Pokémon to switch with (PLAY_AREA_* constant)
; output:
;	carry = set:  if the Active Pokémon isn't able to retreat
AITryToRetreat:
	ld b, a
	call CheckUnableToRetreatDueToEffect
	ret c

; check if the AI is allowed to play an Energy card from its hand
; in order to help pay for its Active Pokémon's Retreat Cost.
	push bc
	ld a, [wAIPlayEnergyCardForRetreat]
	or a
	jr z, .check_id ; skip ahead if it can't play an Energy card to retreat

; first, check if the AI has yet to play an Energy card this turn.
; then, check if the Active Pokémon needs just one more Energy to retreat.
; finally, check if there are any Energy cards in the AI's hand.
; if all of the checks are successful, then attach an Energy card
; to the Active Pokémon before moving on to the next section.
	ld a, [wOncePerTurnFlags]
	and PLAYED_ENERGY_THIS_TURN
	jr nz, .check_id
	xor a ; PLAY_AREA_ARENA
	ldh [hTempPlayAreaLocation_ff9d], a
	ld e, a
	call GetPlayAreaCardAttachedEnergies
	push af
	call GetPlayAreaCardRetreatCost
	pop bc
	sub b ; Retreat Cost - total amount of attached Energy
;	jr c, .check_id ; skip if attached Energy > Retreat Cost
;	jr z, .check_id ; skip if attached Energy = Retreat Cost
	cp 1
	jr nz, .check_id ; skip if the Active Pokémon doesn't need just 1 more Energy to retreat
	call CreateEnergyCardListFromHand
	jr c, .check_id
	ld a, [wDuelTempList]
	ldh [hTemp_ffa0], a ; use the first Energy card that was found in the hand
	xor a ; PLAY_AREA_ARENA
	ldh [hTempPlayAreaLocation_ffa1], a
	ld a, OPPACTION_PLAY_ENERGY
	bank1call AIMakeDecision

.check_id
	ld a, DUELVARS_ARENA_CARD
	get_turn_duelist_var
	call _GetCardIDFromDeckIndex
	cp MYSTERIOUS_FOSSIL
	jp z, .mysterious_fossil_or_clefairy_doll
	cp CLEFAIRY_DOLL
	jp z, .mysterious_fossil_or_clefairy_doll

; store some variables for later.
	pop af
	ldh [hTempPlayAreaLocation_ffa1], a
	ld a, DUELVARS_ARENA_CARD_STATUS
	get_turn_duelist_var
	ldh [hTemp_ffa0], a ; used during OPPACTION_ATTEMPT_RETREAT
	ld a, $ff
	ldh [hTempRetreatCostCards], a

; check Energy required to retreat.
; if the cost is 0, retreat right away.
	xor a ; PLAY_AREA_ARENA
	ldh [hTempPlayAreaLocation_ff9d], a
	call GetPlayAreaCardRetreatCost
	ld [wTempCardRetreatCost], a
	or a
	jp z, .retreat

; if Retreat Cost > 0 and number of attached Energy cards == cost,
; then discard all of the Energy cards attached to the Active Pokémon.
	xor a ; PLAY_AREA_ARENA
	call CreateArenaOrBenchEnergyCardList
	ld a, [wTempCardRetreatCost]
	ld c, a
	ld e, PLAY_AREA_ARENA
	call GetPlayAreaCardAttachedEnergies
	ld de, hTempRetreatCostCards
	ld hl, wDuelTempList
;	ld a, [wTotalAttachedEnergies] ; already loaded
	cp c
	jr nz, .find_energy_to_discard

.choose_all_energy_loop
	ld a, [hli]
	ld [de], a
	inc de
	inc a ; cp $ff (list terminator)
	jr nz, .choose_all_energy_loop
	jr .retreat

; if Retreat Cost > 0 and number of attached Energy cards > cost,
; choose Energy cards to discard according to their type/color.
.find_energy_to_discard
; retrieve some data that was stored during GetPlayAreaCardRetreatCost.
	ld a, [wLoadedCard1ID]
	ld [wTempCardID], a
	ld a, [wLoadedCard1Type]
	or TYPE_ENERGY
	ld [wTempCardType], a

; first, look for a Double Colorless Energy to discard if Retreat Cost is at least 2
.choose_double_colorless_loop
	ld a, c
	cp 2
	jr c, .find_least_useful_energy
	ld a, [hli]
	cp $ff
	jr z, .find_least_useful_energy
	ld [de], a
	call _GetCardIDFromDeckIndex
	cp DOUBLE_COLORLESS_ENERGY
	jr nz, .choose_double_colorless_loop
	ld a, [de]
	call RemoveCardFromDuelTempList
	dec hl
	inc de
	dec c
	dec c
	jr nz, .choose_double_colorless_loop
	jr .end_retreat_list

; second, shuffle attached cards and discard Energy cards
; that are not of the same type as the Pokémon
; the exception for this are cards that are needed for
; some attacks but are not of the same type/color as the Pokémon
; (i.e. Psyduck's Headache attack)
; and Energy cards attached to Eevee corresponding to the
; type/color of any of its evolutions (Water, Fire, or Lightning)
.find_least_useful_energy
	ld hl, wDuelTempList
	call CountCardsInDuelTempList
	call ShuffleCards
.choose_unimportant_energy_loop
	ld a, [hli]
	cp $ff
	jr z, .find_random_energy
	ld [de], a
	farcall CheckIfEnergyIsUseful
	jr c, .choose_unimportant_energy_loop
	ld a, [de]
	call RemoveCardFromDuelTempList
	dec hl
	inc de
	dec c
	jr nz, .choose_unimportant_energy_loop
	jr .end_retreat_list

; third, discard random Energy cards until the Retreat Cost is met.
.find_random_energy
	ld hl, wDuelTempList
.choose_any_energy_loop
	ld a, [hli]
	cp $ff
	jr z, .set_carry
	ld [de], a
	inc de
	call _GetCardIDFromDeckIndex
	cp DOUBLE_COLORLESS_ENERGY
	jr nz, .not_double_colorless
	dec c
	jr z, .end_retreat_list
.not_double_colorless
	dec c
	jr nz, .choose_any_energy_loop

.end_retreat_list
	ld a, $ff ; list terminator
	ld [de], a

.retreat
	ld a, OPPACTION_ATTEMPT_RETREAT
	bank1call AIMakeDecision
	or a
	ret

; handle Mysterious Fossil and Clefairy Doll.
; if there are Benched Pokémon, use the effect to discard the card.
; this is equivalent to using its Pokémon Power.
.mysterious_fossil_or_clefairy_doll
	ld a, DUELVARS_NUMBER_OF_POKEMON_IN_PLAY_AREA
	get_turn_duelist_var
	dec a ; cp 1
	jr nz, .has_bench
	; return carry if there are no Benched Pokémon
	pop af
.set_carry
	scf
	ret

.has_bench
	ld a, DUELVARS_ARENA_CARD
	get_turn_duelist_var
	ldh [hTempCardIndex_ff9f], a
	xor a ; PLAY_AREA_ARENA
	ldh [hTemp_ffa0], a
	ld a, OPPACTION_USE_PKMN_POWER
	bank1call AIMakeDecision
	pop af
	ldh [hAIPkmnPowerEffectParam], a
	ld a, OPPACTION_EXECUTE_PKMN_POWER_EFFECT
	bank1call AIMakeDecision
	ld a, OPPACTION_DUEL_MAIN_SCENE
	bank1call AIMakeDecision
	or a
	ret
