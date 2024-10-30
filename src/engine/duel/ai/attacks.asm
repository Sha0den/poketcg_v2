; AI chooses an attack to use, but does not execute it.
; output:
;	carry = set:  if an attack was chosen
AIProcessButDontUseAttack:
	ld a, $01
	ld [wAIExecuteProcessedAttack], a

; backup wPlayAreaAIScore in wTempPlayAreaAIScore.
	ld de, wTempPlayAreaAIScore
	ld hl, wPlayAreaAIScore
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
	jr z, .execute

; set carry and reset the play area AI score to the previous values.
	scf
	jr RetrievePlayAreaAIScoreFromBackup

.execute
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
	ld a, ATTACK_FLAG1_ADDRESS | DAMAGE_TO_OPPONENT_BENCH_F
	call CheckLoadedAttackFlag
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
	ld de, wPlayAreaAIScore
	ld hl, wTempPlayAreaAIScore
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
	call CheckIfSelectedAttackIsUnusable
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
; also render the attack unusable if it's a Pokémon Power.
	call HandleNoDamageOrEffectSubstatus
	rst SwapTurn
	jr nc, .check_if_can_ko

	; Defending Pokémon has a No Damage substatus
	ld a, TRUE
	ld [wAICannotDamage], a
	ld a, [wSelectedAttack]
	call EstimateDamage_VersusDefendingCard
	ld a, [wLoadedAttackCategory]
	cp POKEMON_POWER
	jr z, .unusable
	and RESIDUAL
	jr nz, .check_if_can_ko
	ld a, ATTACK_FLAG1_ADDRESS | DAMAGE_TO_OPPONENT_BENCH_F
	call CheckLoadedAttackFlag
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
	call AddToAIScore

; raise AI score by the number of damage counters that this attack deals.
; if no damage is dealt, decrease AI score by 1.
; if wDamage is zero but wMaxDamage is not, then encourage attack afterwards.
; otherwise, if wMaxDamage is also zero, check for damage done to
; the Player's Benched Pokémon, and encourage the attack if there is.
.check_damage
	xor a ; FALSE
	ld [wAIAttackIsNonDamaging], a
	ld a, [wDamage]
	ld [wTempAI], a
	or a
	jr z, .no_damage
	call ConvertHPToDamageCounters_Bank5
	call AddToAIScore
	jr .check_recoil
.no_damage
	ld a, $01
	ld [wAIAttackIsNonDamaging], a ; TRUE
	call SubFromAIScore
	ld a, [wAIMaxDamage]
	or a
	jr z, .no_max_damage
	ld a, 2
	call AddToAIScore
	xor a ; FALSE
	ld [wAIAttackIsNonDamaging], a
.no_max_damage
	ld a, ATTACK_FLAG1_ADDRESS | DAMAGE_TO_OPPONENT_BENCH_F
	call CheckLoadedAttackFlag
	jr nc, .check_recoil
	ld a, 2
	call AddToAIScore

; handle recoil attacks (low and high recoil).
.check_recoil
	ld a, ATTACK_FLAG1_ADDRESS | LOW_RECOIL_F
	call CheckLoadedAttackFlag
	jr c, .is_recoil
	ld a, ATTACK_FLAG1_ADDRESS | HIGH_RECOIL_F
	call CheckLoadedAttackFlag
	jp nc, .check_defending_can_ko
.is_recoil
	; subtract from the AI score the number of damage counters
	; that the attack would put on the Attacking Pokémon.
	ld a, [wLoadedAttackEffectParam]
	or a
	jp z, .check_defending_can_ko
	ld [wDamage], a
	call ApplyDamageModifiers_DamageToSelf
	ld a, e
	call ConvertHPToDamageCounters_Bank5
	call SubFromAIScore

	ld a, ATTACK_FLAG1_ADDRESS | HIGH_RECOIL_F
	call CheckLoadedAttackFlag
	jr c, .high_recoil

	; if LOW_RECOIL KOs self, decrease AI score
	ld a, DUELVARS_ARENA_CARD_HP
	get_turn_duelist_var
	dec a ; subtract 1 so carry will be set if final HP = 0
	cp e
	jp nc, .check_defending_can_ko
.kos_self
	ld a, 10
	call SubFromAIScore

.high_recoil
	; dismiss this attack if the AI has no Benched Pokémon
	ld a, DUELVARS_NUMBER_OF_POKEMON_IN_PLAY_AREA
	get_turn_duelist_var
	dec a
	jr z, .dismiss_high_recoil_atk
	; has Benched Pokémon

; here the AI handles high recoil attacks differently
; depending on what deck it's playing.
	ld a, [wOpponentDeckID]
	cp ROCK_CRUSHER_DECK_ID
	jr z, .rock_crusher_deck
	cp ZAPPING_SELFDESTRUCT_DECK_ID
	jr z, .zapping_selfdestruct_deck
	cp BOOM_BOOM_SELFDESTRUCT_DECK_ID
	jr z, .encourage_high_recoil_atk
	; Boom Boom Selfdestruct deck always encourages
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
	sla a
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
	call .check_if_kos_bench
	jr c, .dismiss_high_recoil_atk

.encourage_high_recoil_atk
	ld a, 20
	jp AddToAIScore

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
	call .check_if_kos_bench
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
	cp CHANSEY
	jr z, .chansey
	cp MAGNEMITE_LV13
	jr z, .magnemite1_or_weezing
	cp WEEZING
	jr z, .magnemite1_or_weezing
	ld b, 20 ; 20 damage to the Bench
	jr .check_bench_kos
.magnemite1_or_weezing
	ld b, 10 ; 10 damage to the Bench
	jr .check_bench_kos
.chansey
	ld b, 0 ; no damage to the Bench
	; fallthrough

.check_bench_kos
	rst SwapTurn
	xor a
	call .check_if_kos_bench
	rst SwapTurn
	jr c, .wins_the_duel
	push de
	ld a, 1
	call .check_if_kos_bench
	pop bc
	jr nc, .count_own_ko_bench

; attack would cause the Player to draw all of their remaining Prize cards
	xor a
	ld [wAIScore], a
	ret

; attack would cause the AI to draw all of its remaining Prize cards
.wins_the_duel
	ld a, 20
	jp AddToAIScore

; subtract from AI score number of own Benched Pokémon that would be KO'd
.count_own_ko_bench
	ld a, d
	or a
	jr z, .count_player_ko_bench
	dec a
	call SubFromAIScore

; add to AI score the number of Pokémon on the Player's Bench that would be KO'd
.count_player_ko_bench
	ld a, b
	call AddToAIScore

; if the Defending Pokémon can KO the AI's Active Pokémon,
; then encourage the attack, unless it's non-damaging.
.check_defending_can_ko
	ld a, [wSelectedAttack]
	push af
	call CheckIfDefendingPokemonCanKnockOut
	pop bc
	ld a, b
	ld [wSelectedAttack], a
	jr nc, .check_discard
	ld a, 5
	call AddToAIScore
	ld a, [wAIAttackIsNonDamaging]
	or a
	jr z, .check_discard
	ld a, 5
	call SubFromAIScore

; subtract from AI score if this attack requires discarding any Energy cards.
.check_discard
	ld a, [wSelectedAttack]
	ld e, a
	ld a, DUELVARS_ARENA_CARD
	get_turn_duelist_var
	ld d, a
	call CopyAttackDataAndDamage_FromDeckIndex
	ld a, ATTACK_FLAG2_ADDRESS | DISCARD_ENERGY_F
	call CheckLoadedAttackFlag
	jr nc, .check_encourage_flag
	ld a, 1
	call SubFromAIScore
	ld a, [wLoadedAttackEffectParam]
	call SubFromAIScore

.check_encourage_flag
	ld a, ATTACK_FLAG2_ADDRESS | ENCOURAGE_THIS_ATTACK_F
	call CheckLoadedAttackFlag
	jr nc, .check_discourage_flag
	ld a, [wLoadedAttackEffectParam]
	call AddToAIScore

.check_discourage_flag
	ld a, ATTACK_FLAG2_ADDRESS | DISCOURAGE_THIS_ATTACK_F
	call CheckLoadedAttackFlag
	jr nc, .check_nullify_flag
	ld a, [wLoadedAttackEffectParam]
	call SubFromAIScore

; encourage the attack if it has a nullify or weaken attack effect.
.check_nullify_flag
	ld a, ATTACK_FLAG2_ADDRESS | NULLIFY_OR_WEAKEN_ATTACK_F
	call CheckLoadedAttackFlag
	jr nc, .check_heal_flag
	ld a, 1
	call AddToAIScore

.check_heal_flag
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
	jr z, .add_heal_score ; add 1 to the AI score if attack parameter is HEAL_10_HP_IF_DAMAGE_IS_DEALT
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
	call AddToAIScore

.check_status_effect
; skip ahead if the Defending Pokémon can't be affected by any Special Conditions
	rst SwapTurn
	call CheckIfActiveCardCanBeAffectedByStatus
	rst SwapTurn
	jp nc, .subtract_and_handle_special_atks

	ld a, DUELVARS_ARENA_CARD_STATUS
	call GetNonTurnDuelistVariable
	ld [wTempAI], a

; encourage an attack that causes the Poisoned condition if the Defending Pokémon
; isn't already Poisoned. discourage the attack if the Defending Pokémon is
; already Double Poisoned and this attack has the ENCOURAGE_THIS_ATTACK flag,
; likely to avoid replacing toxic poison with regular poison or using a weaker second attack.
	ld a, ATTACK_FLAG1_ADDRESS | INFLICT_POISON_F
	call CheckLoadedAttackFlag
	jr nc, .check_sleep ; skip ahead if the attack doesn't Poison
	ld a, [wTempAI]
	and DOUBLE_POISONED
	jr z, .add_poison_score ; increase score if Defending Pokémon isn't already Poisoned
	and $40
	jr z, .check_sleep ; skip ahead if Defending Pokémon is only Poisoned (not Toxic)
	ld a, ATTACK_FLAG2_ADDRESS | ENCOURAGE_THIS_ATTACK_F
	call CheckLoadedAttackFlag
	jr nc, .check_sleep
	ld a, 2
	call SubFromAIScore
	jr .check_sleep
.add_poison_score
	ld a, 2
	call AddToAIScore

; encourage an attack that causes the Asleep condition
; if the Defending Pokémon isn't already Asleep.
.check_sleep
	ld a, ATTACK_FLAG1_ADDRESS | INFLICT_SLEEP_F
	call CheckLoadedAttackFlag
	jr nc, .check_paralysis
	ld a, [wTempAI]
	and CNF_SLP_PRZ
	cp ASLEEP
	jr z, .check_paralysis
	ld a, 1
	call AddToAIScore

; encourage an attack that causes the Paralyzed condition if the Defending Pokémon isn't Asleep.
; discourage the attack if the Defending Pokémon is currently Asleep.
.check_paralysis
	ld a, ATTACK_FLAG1_ADDRESS | INFLICT_PARALYSIS_F
	call CheckLoadedAttackFlag
	jr nc, .check_confusion
	ld a, [wTempAI]
	and CNF_SLP_PRZ
	cp ASLEEP
	jr z, .sub_prz_score
	ld a, 1
	call AddToAIScore
	jr .check_confusion
.sub_prz_score
	ld a, 1
	call SubFromAIScore

; encourage an attack that causes the Confused condition if the Defending Pokémon
; isn't already Asleep or Confused. otherwise, discourage the attack.
.check_confusion
	ld a, ATTACK_FLAG1_ADDRESS | INFLICT_CONFUSION_F
	call CheckLoadedAttackFlag
	jr nc, .check_if_confused
	ld a, [wTempAI]
	and CNF_SLP_PRZ
	cp ASLEEP
	jr z, .sub_cnf_score
	ld a, [wTempAI]
	and CNF_SLP_PRZ
	cp CONFUSED
	jr z, .check_if_confused
	ld a, 1
	call AddToAIScore
	jr .check_if_confused
.sub_cnf_score
	ld a, 1
	call SubFromAIScore

; if this Pokémon is Confused, subtract from score.
.check_if_confused
	ld a, DUELVARS_ARENA_CARD_STATUS
	get_turn_duelist_var
	and CNF_SLP_PRZ
	cp CONFUSED
	jr nz, .handle_special_atks
.subtract_and_handle_special_atks
	ld a, 1
	call SubFromAIScore

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
	jp AddToAIScore
.negative_score
	ld b, a
	ld a, $80
	sub b
	jp SubFromAIScore

; local function that gets called to determine damage to
; Benched Pokémon caused by a HIGH_RECOIL attack.
; this function is independent on duelist turn, so whatever
; turn it is when this is called, it's that duelist's
; Bench/Prize cards that get checked.
; preserves bc
; input:
;	a = initial number of KO's, other than Benched Pokémon,
;	    so that if the Active Pokémon is KO'd by the attack,
;	    this counts towards the number of Prize cards that will be drawn
;	b = damage dealt to Benched Pokémon
; output:
;	carry = set:  if the attack would KO enough of the turn holder's Pokémon
;	              for the opponent to draw all of their remaining Prize cards
.check_if_kos_bench
	ld d, a
	ld a, DUELVARS_BENCH
	get_turn_duelist_var
	ld e, PLAY_AREA_ARENA
.loop_bench
	inc e
	ld a, [hli]
	cp $ff
	jr z, .count_prizes
	ld a, e
	add DUELVARS_ARENA_CARD_HP
	push hl
	get_turn_duelist_var
	pop hl
	dec a ; subtract 1 so carry will be set if final HP = 0
	cp b
	jr nc, .loop_bench
	; damage in b will KO this Pokémon, so increment the counter for KO'd Pokémon
	inc d
	jr .loop_bench

.count_prizes
	rst SwapTurn
	call CountPrizes
	rst SwapTurn
	dec a ; subtract 1 so carry will be set if number of KO'd Pokémon = number of Prizes
	cp d
	ret


; called when second attack is determined by AI to have
; more AI score than the first attack, so that it checks
; whether the first attack is a better alternative.
CheckWhetherToSwitchToFirstAttack:
; this checks whether the first attack is also viable
; (has more than minimum score to be used)
	ld a, [wFirstAttackAIScore]
	cp $50
	jr c, .keep_second_attack

; first attack has more than minimum score to be used.
; check if second attack can KO.
; in case it can't, the AI keeps it as the attack to be used.
; (possibly due to the assumption that if the
; second attack cannot KO, the first attack can't KO as well.)
	xor a ; PLAY_AREA_ARENA
	ldh [hTempPlayAreaLocation_ff9d], a
	call EstimateDamage_VersusDefendingCard
	ld a, DUELVARS_ARENA_CARD_HP
	call GetNonTurnDuelistVariable
	dec a ; subtract 1 so carry will be set if final HP = 0
	ld hl, wDamage
	sub [hl]
	jr nc, .keep_second_attack

; second attack can ko, check its flag.
; in case its effect is to heal user or nullify/weaken damage
; next turn, keep second attack as the option.
; otherwise switch to the first attack.
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
