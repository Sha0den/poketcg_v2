; AI chooses an attack to use, but does not execute it.
; output:
;	carry = set:  if an attack was chosen
AIProcessButDontUseAttack:
	ld a, $01
	ld [wAIExecuteProcessedAttack], a

; backup wPlayAreaAIScore in wTempPlayAreaAIScore.
	ld hl, wPlayAreaAIScore
	ld de, wTempPlayAreaAIScore
	ld b, MAX_PLAY_AREA_POKEMON
	call CopyNBytesFromHLToDE

; copies wAIScore to wTempAIScore
	ld a, [wAIScore]
	ld [de], a
	jr AIProcessAttacks


; AI chooses an attack and then attempts to execute it.
; output:
;	carry = set:  if an attack was chosen
AIProcessAndTryToUseAttack:
	xor a
	ld [wAIExecuteProcessedAttack], a
;	fallthrough

; checks which of the Active Pokémon's attacks should be used by the AI.
; If any of the attacks has enough AI score to be used,
; AI will use it if wAIExecuteProcessedAttack is 0.
; in either case, return carry if an attack is chosen to be used.
; input:
;	[wAIExecuteProcessedAttack] == 0:  try to execute the chosen attack
;	[wAIExecuteProcessedAttack] != 0:  return after choosing an attack
AIProcessAttacks:
; if AI used Pluspower, load its attack index.
	ld a, [wPreviousAIFlags]
	and AI_FLAG_USED_PLUSPOWER
	jr z, .no_pluspower
	ld a, [wAIPluspowerAttack]
	ld [wSelectedAttack], a
	jr .attack_chosen

.no_pluspower
; if Player is running MewtwoLv53 mill deck,
; skip attack if Barrier counter is 0.
	ld a, [wAIBarrierFlagCounter]
	cp AI_MEWTWO_MILL + 0
	jr z, .dont_attack

; determine AI score of both attacks.
	xor a ; FIRST_ATTACK_OR_PKMN_POWER
	call GetAIScoreOfAttack
	ld a, [wAIScore]
	ld [wFirstAttackAIScore], a
	ld a, SECOND_ATTACK
	call GetAIScoreOfAttack

; compare both attack scores.
	ld c, SECOND_ATTACK
	ld a, [wFirstAttackAIScore]
	ld b, a
	ld a, [wAIScore]
	cp b
	jr nc, .check_score
	; first attack has the higher score
	dec c ; FIRST_ATTACK_OR_PKMN_POWER
	ld a, b

; c holds the attack index chosen by AI, and a holds its AI score.
; first, check if the chosen attack has at least the minimum score requirement.
; then, check if the first attack is better than the second attack
; in case the second one was chosen.
.check_score
	cp $50 ; minimum score to use attack
	jr c, .dont_attack
	; enough score, proceed

	ld a, c
	ld [wSelectedAttack], a
	or a
	call nz, CheckWhetherToSwitchToFirstAttack

.attack_chosen
; check whether to execute the attack chosen.
	ld a, [wAIExecuteProcessedAttack]
	or a
	scf
	jr nz, RetrievePlayAreaAIScoreFromBackup ; return carry after resetting AI scores if not executing the attack

; before executing the attack, consider playing any Trainer cards in the hand
; that could modify the attack's damage (e.g. Defender/PlusPower)
	ld a, AI_TRAINER_CARD_PHASE_14
	call AIProcessHandTrainerCards

; load this attack's damage output against the current Defending Pokémon.
	xor a ; PLAY_AREA_ARENA
	ldh [hTempPlayAreaLocation_ff9d], a
	ld a, [wSelectedAttack]
	call EstimateDamage_VersusDefendingCard
	ld a, [wDamage]

	or a
	jr z, .check_damage_bench
	; if damage is not 0, fallthrough

.can_damage
	xor a
	ld [wAIRetreatScore], a
	jr .use_attack

.check_damage_bench
; check if it can otherwise damage the Player's Bench
	call CheckIfCanDamageBench
	jr c, .can_damage

; cannot damage the Defending Pokémon or any of the Player's Benched Pokémon
	ld hl, wAIRetreatScore
	inc [hl]

; return carry after the AI tries to use the chosen attack.
.use_attack
	ld a, TRUE
	ld [wAITriedAttack], a
	call AITryUseAttack
	scf
	ret

; return no carry if there was no viable attack.
.failed_to_use
	ld hl, wAIRetreatScore
	inc [hl]
	or a
	ret

.dont_attack
	ld a, [wAIExecuteProcessedAttack]
	or a
	jr z, .failed_to_use
;	fallthrough to reset the play area AI score to the previous values

; copies wTempPlayAreaAIScore to wPlayAreaAIScore
; and loads wAIScore with value in wTempAIScore.
; preserves af
RetrievePlayAreaAIScoreFromBackup:
	push af
	ld hl, wTempPlayAreaAIScore
	ld de, wPlayAreaAIScore
	ld b, MAX_PLAY_AREA_POKEMON
	call CopyNBytesFromHLToDE
	ld a, [hl]
	ld [wAIScore], a
	pop af
	ret


; determines the AI score of the attack index in a.
; input:
;	a = which attack should be evaluated (0 = first attack, 1 = second attack)
; output:
;	[wAIScore] = score assigned to the given attack
GetAIScoreOfAttack:
; initialize AI score.
	ld [wSelectedAttack], a
	ld a, $50
	ld [wAIScore], a

	xor a ; PLAY_AREA_ARENA
	ldh [hTempPlayAreaLocation_ff9d], a
	call CheckIfSelectedAttackIsUnusable ; also sets up wLoadedAttack
	jr nc, .usable

; return zero AI score.
.unusable
	xor a
	ld [wAIScore], a
	ret

; store the card IDs of both Active Pokémon
.usable
	xor a ; FALSE
	ld [wAICannotDamage], a
	ld a, DUELVARS_ARENA_CARD
	get_turn_duelist_var
	call _GetCardIDFromDeckIndex
	ld [wTempTurnDuelistCardID], a
	rst SwapTurn
	ld a, DUELVARS_ARENA_CARD
	get_turn_duelist_var
	call _GetCardIDFromDeckIndex
	ld [wTempNonTurnDuelistCardID], a

; take into account whether the Defending Pokémon has a No Damage substatus.
; if it does, check if this attack has a residual effect or if it can damage the opposing Bench.
; If none of those are true, render the attack unusable.
	call HandleNoDamageOrEffectSubstatus
	rst SwapTurn
	jr nc, .check_if_can_ko

	; Defending Pokémon has a No Damage substatus
	ld a, TRUE
	ld [wAICannotDamage], a
	ld a, [wLoadedAttackCategory]
	and RESIDUAL
	jr nz, .check_if_can_ko
	call CheckIfCanDamageBench
	jr nc, .unusable

; calculate damage to check if the attack can KO the Defending Pokémon.
; encourage the attack by increasing the score if it's able to KO.
.check_if_can_ko
	ld a, [wSelectedAttack]
	call EstimateDamage_VersusDefendingCard
	ld a, DUELVARS_ARENA_CARD_HP
	call GetNonTurnDuelistVariable
	dec a ; subtract 1 so carry will be set if final HP = 0
	ld hl, wDamage
	sub [hl]
	jr nc, .check_damage
.can_ko
	ld a, 20
	call AIEncourage

; increase this attack's score by the number of damage counters that it will do.
; alternatively, if no damage is dealt, then decrease this attack's score by 1,
; but then increase the score by 2 if wAIMaxDamage > 0 or if it can damage the opposing Bench.
.check_damage
	xor a ; FALSE
	ld [wAIAttackIsNonDamaging], a
	ld a, [wDamage]
	ld [wTempAI], a
	or a
	jr z, .no_damage
	call ConvertHPToDamageCounters_Bank5
	call AIEncourage
	jr .check_recoil
.no_damage
	ld a, $01
	ld [wAIAttackIsNonDamaging], a ; TRUE
	call AIDiscourage
	ld a, [wAIMaxDamage]
	or a
	jr z, .no_max_damage
	ld a, 2
	call AIEncourage
	xor a ; FALSE
	ld [wAIAttackIsNonDamaging], a
	jr .check_recoil
.no_max_damage
	call CheckIfCanDamageBench
	ld a, 2
	call c, AIEncourage ; add 2 if this flag is set

; handle recoil attacks (low and high recoil).
.check_recoil
	ld a, ATTACK_FLAG1_ADDRESS | LOW_RECOIL_F
	call CheckLoadedAttackFlag
	jr c, .is_recoil
	ld a, ATTACK_FLAG1_ADDRESS | HIGH_RECOIL_F
	call CheckLoadedAttackFlag
	jp nc, .check_defending_can_ko ; skip to next section if not a recoil attack
.is_recoil
	ld a, [wLoadedAttackEffectParam]
	or a
	jp z, .check_defending_can_ko ; skip to next section if no recoil damage is recorded in card data

	ld a, ATTACK_FLAG1_ADDRESS | HIGH_RECOIL_F
	call CheckLoadedAttackFlag
	jp nc, .check_damage_to_self ; skip Bench damage checks if LOW_RECOIL

; dismiss all high recoil attacks if the AI doesn't have any Benched Pokémon.
	ld a, DUELVARS_NUMBER_OF_POKEMON_IN_PLAY_AREA
	get_turn_duelist_var
	dec a ; cp 1
	jr z, .dismiss_high_recoil_atk
	; has Benched Pokémon

; AI handles high recoil attacks differently depending on what deck it's playing.
	ld a, [wOpponentDeckID]
	cp ROCK_CRUSHER_DECK_ID
	jr z, .rock_crusher_deck
	cp ZAPPING_SELFDESTRUCT_DECK_ID
	jr z, .zapping_selfdestruct_deck
	cp BOOM_BOOM_SELFDESTRUCT_DECK_ID
	jr z, .encourage_high_recoil_atk ; Boom Boom Selfdestruct deck always encourages
	cp POWER_GENERATOR_DECK_ID
	jr nz, .high_recoil_generic_checks
	; Power Generator deck always dismisses

.dismiss_high_recoil_atk
	xor a
	ld [wAIScore], a
	ret

; Zapping Selfdestruct deck only uses this attack
; if number of cards in deck >= 30 and
; HP of Active Pokémon is < half max HP.
.zapping_selfdestruct_deck
	ld a, DUELVARS_NUMBER_OF_CARDS_NOT_IN_DECK
	get_turn_duelist_var
	cp 31
	jr nc, .high_recoil_generic_checks
	ld e, PLAY_AREA_ARENA
	call GetCardDamageAndMaxHP
	add a
	cp c
	jr c, .high_recoil_generic_checks
	ld b, 0
	ld a, DUELVARS_ARENA_CARD
	get_turn_duelist_var
	call _GetCardIDFromDeckIndex
	cp MAGNEMITE_LV13
	jr z, .magnemite1
	ld b, 10 ; Bench damage
.magnemite1
	ld a, 10
	add b
	ld b, a ; 20 damage to the Bench if not MagnemiteLv13

; if this attack would cause the Player to win the duel by
; KO'ing too many of the AI's Pokémon, then dismiss the attack.
	ld a, 1 ; count Active Pokémon as KO'd
	call CheckIfDamageToAllTurnHolderBenchedPokemonLosesDuel
	jr c, .dismiss_high_recoil_atk

.encourage_high_recoil_atk
	ld a, 20
	jp AIEncourage

; Rock Crusher Deck only uses this attack if the Prize count is below 4
; and the attack wins (or potentially draws) the duel,
; (i.e. number of KOs >= number of remaining Prize cards).
.rock_crusher_deck
	call CountPrizes
	cp 4
	jr nc, .dismiss_high_recoil_atk
	; Prize count < 4
	ld b, 20 ; damage dealt to bench
	rst SwapTurn
	xor a
	call CheckIfDamageToAllTurnHolderBenchedPokemonLosesDuel
	rst SwapTurn
	jr c, .encourage_high_recoil_atk

; generic checks for all other deck IDs.
; encourage attack if it wins (or potentially draws) the duel,
; (i.e. number of KOs >= number of remaining Prize cards).
; dismiss it if it causes the Player to win.
.high_recoil_generic_checks
	ld a, DUELVARS_ARENA_CARD
	get_turn_duelist_var
	call _GetCardIDFromDeckIndex

	ld b, 20 ; 20 damage to the Bench
	cp MAGNETON_LV28
	jr z, .check_bench_kos
	cp MAGNETON_LV35
	jr z, .check_bench_kos
	cp GOLEM
	jr z, .check_bench_kos

	ld b, 10 ; 10 damage to the Bench
	cp MAGNEMITE_LV13
	jr z, .check_bench_kos
	cp WEEZING
	jr nz, .check_damage_to_self

.check_bench_kos
	rst SwapTurn
	xor a
	call CheckIfDamageToAllTurnHolderBenchedPokemonLosesDuel
	rst SwapTurn
	jr c, .wins_the_duel
	push bc
	ld a, 1 ; count Active Pokémon as KO'd
	call CheckIfDamageToAllTurnHolderBenchedPokemonLosesDuel
	pop de
	jr nc, .account_for_kos_on_bench

; this attack would cause the Player to draw all of their remaining Prize cards.
.loses_the_duel
	xor a
	ld [wAIScore], a
	ret

; this attack would cause the AI to draw all of its remaining Prize cards.
.wins_the_duel
	ld a, 20
	jp AIEncourage

; decrease this attack's score by 10 for each Pokémon on the AI's Bench that would be KO'd
; and increase it by 10 for each Pokémon on the Player's Bench that would be KO'd.
.account_for_kos_on_bench
	dec c ; ignore the Attacking Pokémon
	ld a, c
	add a ; *2
	add a ; *4
	add c ; *5
	add a ; *10
	call AIDiscourage
	ld a, e
	add a ; *2
	add a ; *4
	add c ; *5
	add a ; *10
	call AIEncourage

; decrease this attack's score by the number of damage counters that
; would be put on the Attacking Pokémon because of the recoil effect.
; if this would KO the user, then decrease the score by 10 instead.
; dismiss the attack entirely if it would cause the Player to win the duel.
.check_damage_to_self
	ld a, [wLoadedAttackEffectParam]
	ld [wDamage], a
	call ApplyDamageModifiers_DamageToSelf
	ld a, DUELVARS_ARENA_CARD_HP
	get_turn_duelist_var
	dec a ; subtract 1 so carry will be set if damage would reduce HP to exactly 0
	cp e
	jr c, .recoil_will_ko_user
	ld a, e
	call ConvertHPToDamageCounters_Bank5
	call AIDiscourage
	jr .check_defending_can_ko

.recoil_will_ko_user
	ld a, DUELVARS_NUMBER_OF_POKEMON_IN_PLAY_AREA
	get_turn_duelist_var
	dec a ; cp 1
	jr z, .loses_the_duel ; dismiss the attack if it would KO the AI's last Pokémon
	rst SwapTurn
	call CountPrizes
	rst SwapTurn
	dec a ; cp 1
	jr z, .loses_the_duel ; dismiss the attack if it would cause the Player to draw their last Prize
	ld a, 10
	call AIDiscourage

; if the Defending Pokémon can KO the AI's Active Pokémon,
; then encourage the attack, unless it's non-damaging.
.check_defending_can_ko
	ld a, [wAIAttackIsNonDamaging]
	or a
	jr z, .check_discard
	ld a, [wSelectedAttack]
	push af
	call CheckIfDefendingPokemonCanKnockOut
	ld a, 5
	call c, AIEncourage ; add 5 if user might be KO'd next turn
	pop af
	ld [wSelectedAttack], a
	ld e, a
	ld a, DUELVARS_ARENA_CARD
	get_turn_duelist_var
	ld d, a
	call CopyAttackDataAndDamage_FromDeckIndex

; discourage this attack if it requires discarding any Energy cards.
.check_discard
	ld a, ATTACK_FLAG2_ADDRESS | DISCARD_ENERGY_F
	call CheckLoadedAttackFlag
	ld a, [wLoadedAttackEffectParam]
	inc a
	call c, AIDiscourage ; subtract 1 plus the value from AttackEffectParam byte if this flag is set

; check encourage attack flag
	ld a, ATTACK_FLAG2_ADDRESS | ENCOURAGE_THIS_ATTACK_F
	call CheckLoadedAttackFlag
	ld a, [wLoadedAttackEffectParam]
	call c, AIEncourage ; add the value from AttackEffectParam byte if this flag is set

; check discourage attack flag
	ld a, ATTACK_FLAG2_ADDRESS | DISCOURAGE_THIS_ATTACK_F
	call CheckLoadedAttackFlag
	ld a, [wLoadedAttackEffectParam]
	call c, AIDiscourage ; subtract the value from AttackEffectParam byte if this flag is set

; encourage the attack if it has a nullify or weaken attack effect.
	ld a, ATTACK_FLAG2_ADDRESS | NULLIFY_OR_WEAKEN_ATTACK_F
	call CheckLoadedAttackFlag
	ld a, 1
	call c, AIEncourage ; add 1 if this flag is set

; check heal flag
	ld a, ATTACK_FLAG2_ADDRESS | HEAL_USER_F
	call CheckLoadedAttackFlag
	jr nc, .check_status_effect
	ld a, [wLoadedAttackEffectParam]
	ld b, a
	cp HEALING_EQUALS_DAMAGE_DEALT
	jr c, .tally_heal_score
	; must be a special healing effect
	ld c, a
	ld a, [wTempAI] ; damage that would be dealt by this attack
	or a
	jr z, .check_status_effect ; skip to next section if attack won't do any damage
	call ConvertHPToDamageCounters_Bank5
	ld b, a
	ld a, c ; wLoadedAttackEffectParam
	sub HEALING_EQUALS_DAMAGE_DEALT
	jr z, .tally_heal_score
	cp 1
	jr z, .add_heal_score ; increase this attack's score by 1 if attack parameter is HEAL_10_HP_IF_DAMAGE_IS_DEALT
	cp 2
	jr nz, .check_status_effect ; skip to next section if attack parameter isn't HEALING_EQUALS_HALF_DAMAGE_DEALT
	srl b ; divide damage by 2
	jr nc, .tally_heal_score
	inc b ; round up to the nearest 10 damage
.tally_heal_score
	ld e, PLAY_AREA_ARENA
	call GetCardDamageAndMaxHP
	call ConvertHPToDamageCounters_Bank5
	cp b ; healing amount (in damage counters)
	jr c, .add_heal_score ; use number of damage counters on Active Pokémon if healing > damage
	ld a, b ; heal the full amount
.add_heal_score
	call AIEncourage

.check_status_effect
; skip ahead if the Defending Pokémon can't be affected by any Special Conditions
	rst SwapTurn
	call CheckIfActiveCardCanBeAffectedByStatus
	rst SwapTurn
	jr nc, .check_if_user_is_confused

	ld a, DUELVARS_ARENA_CARD_STATUS
	call GetNonTurnDuelistVariable
	ld [wTempAI], a

; encourage an attack that causes the Poisoned condition if the Defending Pokémon
; isn't already Poisoned. discourage the attack if the Defending Pokémon is
; already Double Poisoned and this attack has the ENCOURAGE_THIS_ATTACK flag,
; likely to avoid replacing toxic poison with regular poison or using a weaker second attack.
	ld a, ATTACK_FLAG1_ADDRESS | INFLICT_POISON_F
	call CheckLoadedAttackFlag
	jr nc, .check_other_status_effects ; skip ahead if the attack doesn't Poison
	ld a, [wTempAI]
	and DOUBLE_POISONED
	jr z, .add_poison_score ; increase score if Defending Pokémon isn't already Poisoned
	and $40
	jr z, .check_other_status_effects ; skip ahead if Defending Pokémon is only Poisoned (not Toxic)
	ld a, ATTACK_FLAG2_ADDRESS | ENCOURAGE_THIS_ATTACK_F
	call CheckLoadedAttackFlag
	ld a, 2
	call c, AIDiscourage ; subtract 2 if flag is set
	jr .check_other_status_effects
.add_poison_score
	ld a, 2
	call AIEncourage

; encourage an attack that makes the Defending Pokémon Asleep, Confused, or Paralyzed
; if it isn't already affected by one of those conditions. otherwise, discourage the attack.
.check_other_status_effects
	ld a, ATTACK_FLAG1_ADDRESS | INFLICT_SLEEP_F
	call CheckLoadedAttackFlag
	jr c, .update_score_based_on_current_status
	ld a, ATTACK_FLAG1_ADDRESS | INFLICT_PARALYSIS_F
	call CheckLoadedAttackFlag
	jr c, .update_score_based_on_current_status
	ld a, ATTACK_FLAG1_ADDRESS | INFLICT_CONFUSION_F
	call CheckLoadedAttackFlag
	jr nc, .check_if_user_is_confused

.update_score_based_on_current_status
	ld a, [wTempAI]
	and CNF_SLP_PRZ
	jr nz, .already_affected
	ld a, 1
	call AIEncourage
	jr .check_if_user_is_confused
.already_affected
	ld a, 1
	call AIDiscourage

; if this Pokémon is Confused, subtract from score.
.check_if_user_is_confused
	ld a, DUELVARS_ARENA_CARD_STATUS
	get_turn_duelist_var
	and CNF_SLP_PRZ
	cp CONFUSED
	jr nz, .handle_special_atks
	ld a, 1
	call AIDiscourage

; SPECIAL_AI_HANDLING marks attacks that the AI handles individually.
; each attack has its own checks and modifies AI score accordingly.
.handle_special_atks
	ld a, ATTACK_FLAG3_ADDRESS | SPECIAL_AI_HANDLING_F
	call CheckLoadedAttackFlag
	ret nc
	call HandleSpecialAIAttacks
	cp $80
	jr c, .negative_score
	sub $80
	jp AIEncourage
.negative_score
	ld b, a
	ld a, $80
	sub b
	jp AIDiscourage


; checks if the currently loaded attack has the DAMAGE_TO_OPPONENT_BENCH flag
; and if there are any Pokémon on the opposing Bench to damage.
; preserves bc and de
; input:
;	[wLoadedAttack] = data for a Pokémon's attack (atk_data_struct)
; output:
;	carry = set:  if the given attack will be able to damage an opposing Benched Pokémon
CheckIfCanDamageBench:
	ld a, ATTACK_FLAG1_ADDRESS | DAMAGE_TO_OPPONENT_BENCH_F
	call CheckLoadedAttackFlag
	ret nc ; return no carry if the flag isn't set
	ld a, DUELVARS_NUMBER_OF_POKEMON_IN_PLAY_AREA
	call GetNonTurnDuelistVariable
	cp 1
	ret z ; return no carry if the Bench is empty
	scf
	ret


; determines how many Pokémon on the turn holder's Bench will be KO'd
; if b damage is dealt to each Benched Pokémon (by a HIGH_RECOIL attack)
; and whether this would cause the other player to draw all of their Prize cards.
; preserves b
; input:
;	a = initial number of KO's, other than Benched Pokémon,
;	    so that if the Active Pokémon is KO'd by the attack,
;	    this counts towards the number of Prize cards that will be drawn
;	b = damage dealt to each Benched Pokémon
; output:
;	c = total number of Pokémon in the turn holder's play area that would be KO'd
;	carry = set:  if the attack would KO enough of the turn holder's Pokémon
;	              for the opponent to draw all of their remaining Prize cards
CheckIfDamageToAllTurnHolderBenchedPokemonLosesDuel:
	ld c, a
	ld a, DUELVARS_NUMBER_OF_POKEMON_IN_PLAY_AREA
	get_turn_duelist_var
	ld d, a
	ld e, PLAY_AREA_BENCH_1 - 1
.loop_bench
	inc e
	dec d
	jr z, .count_prizes
	ld a, e
	add DUELVARS_ARENA_CARD_HP
	get_turn_duelist_var
	dec a ; subtract 1 so carry will be set if damage would reduce HP to exactly 0
	cp b
	jr nc, .loop_bench
	; damage in b will KO this Pokémon, so increment the counter for KO'd Pokémon
	inc c
	jr .loop_bench

.count_prizes
	rst SwapTurn
	call CountPrizes
	rst SwapTurn
	dec a ; subtract 1 so carry will be set if number of KO'd Pokémon = number of Prizes
	cp c
	ret


; called when second attack is determined by AI to have more value than the first attack,
; so that it checks whether the first attack is a better alternative.
; this is likely due to the fact that cheaper attacks more frequently
; have beneficial secondary effects and rarely have harmful secondary effects,
; such as doing damage to the turn holder's Pokémon or needing to discard Energy beforehand.
CheckWhetherToSwitchToFirstAttack:
; this checks whether the first attack is also viable
; (has more than minimum score to be used)
	ld a, [wFirstAttackAIScore]
	cp $50
	jr c, .keep_second_attack

; first attack has more than minimum score to be used,
; check if it can KO, in case it can't
; then the AI keeps second attack as selection.
	xor a ; PLAY_AREA_ARENA
	ldh [hTempPlayAreaLocation_ff9d], a
	; a = FIRST_ATTACK_OR_PKMN_POWER
	call EstimateDamage_VersusDefendingCard
	ld a, DUELVARS_ARENA_CARD_HP
	call GetNonTurnDuelistVariable
	dec a ; subtract 1 so carry will be set if final HP = 0
	ld hl, wDamage
	sub [hl] ; HP - damage
	jr nc, .keep_second_attack ; cannot KO

; first attack can ko, check its flags from second attack.
; in case its effect is to heal user or nullify/weaken damage
; next turn, keep second attack as the option.
.check_flag
	ld a, DUELVARS_ARENA_CARD
	get_turn_duelist_var
	ld d, a
	ld e, SECOND_ATTACK
	call CopyAttackDataAndDamage_FromDeckIndex
	ld a, ATTACK_FLAG2_ADDRESS | HEAL_USER_F
	call CheckLoadedAttackFlag
	jr c, .keep_second_attack
	ld a, ATTACK_FLAG2_ADDRESS | NULLIFY_OR_WEAKEN_ATTACK_F
	call CheckLoadedAttackFlag
	jr c, .keep_second_attack
; switch to first attack
	xor a ; FIRST_ATTACK_OR_PKMN_POWER
	ld [wSelectedAttack], a
	ret
.keep_second_attack
	ld a, SECOND_ATTACK
	ld [wSelectedAttack], a
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
