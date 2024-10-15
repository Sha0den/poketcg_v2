INCLUDE "data/duel/ai_trainer_card_logic.asm"

_AIProcessHandTrainerCards:
	ld [wAITrainerCardPhase], a
; create hand list in wDuelTempList and wTempHandCardList.
	call CreateHandCardList
	ld hl, wDuelTempList
	ld de, wTempHandCardList
	call CopyListWithFFTerminatorFromHLToDE_Bank8
	ld hl, wTempHandCardList

.loop_hand
	ld a, [hli]
	ld [wAITrainerCardToPlay], a
	cp $ff
	ret z

	push hl
	ld a, [wAITrainerCardPhase]
	ld d, a
	ld hl, AITrainerCardLogic
.loop_data
	xor a
	ld [wCurrentAIFlags], a
	ld a, [hli]
	cp $ff
	jp z, .pop_hl

; compare input to first byte in data and continue if equal.
	cp d
	jp nz, .inc_hl_by_5

	ld a, [hli]
	ld [wAITrainerLogicCard], a
	ld a, [wAITrainerCardToPlay]
	call _GetCardIDFromDeckIndex
	cp SWITCH
	jr nz, .skip_switch_check

	ld b, a
	ld a, [wPreviousAIFlags]
	and AI_FLAG_USED_SWITCH
	jr nz, .inc_hl_by_4
	ld a, b

.skip_switch_check
; compare hand card to second byte in data and continue if equal.
	ld b, a
	ld a, [wAITrainerLogicCard]
	cp b
	jr nz, .inc_hl_by_4

; found Trainer card
	push hl
	push de
	ld a, [wAITrainerCardToPlay]
	ldh [hTempCardIndex_ff9f], a

; if Headache effects prevent playing card
; move on to the next item in list.
	call CheckCantUseTrainerDueToHeadache
	jr c, .next_in_data

	call LoadNonPokemonCardEffectCommands
	ld a, EFFECTCMDTYPE_INITIAL_EFFECT_1
	call TryExecuteEffectCommandFunction
	jr c, .next_in_data

; AI can randomly choose not to play card.
	call AIChooseRandomlyNotToDoAction
	jr c, .next_in_data

; call routine to decide whether to play Trainer card
	pop de
	pop hl
	push hl
	call CallIndirect
	pop hl
	jr nc, .inc_hl_by_4

; routine returned carry, which means
; this card should be played.
	inc hl
	inc hl
	ld [wAITrainerCardParameter], a

; show Play Trainer Card screen
	push de
	push hl
	ld a, [wAITrainerCardToPlay]
	ldh [hTempCardIndex_ff9f], a
	ld a, OPPACTION_PLAY_TRAINER
	bank1call AIMakeDecision
	pop hl
	pop de
	jr c, .inc_hl_by_2

; execute the effects of the Trainer card
	push hl
	call CallIndirect
	pop hl

	inc hl
	inc hl
	ld a, [wPreviousAIFlags]
	ld b, a
	ld a, [wCurrentAIFlags]
	or b
	ld [wPreviousAIFlags], a
	pop hl
	and AI_FLAG_MODIFIED_HAND
	jp z, .loop_hand

; the hand was modified during the Trainer effect
; so it needs to be re-listed again and
; looped from the top.
	call CreateHandCardList
	ld hl, wDuelTempList
	ld de, wTempHandCardList
	call CopyListWithFFTerminatorFromHLToDE_Bank8
	ld hl, wTempHandCardList
; clear the AI_FLAG_MODIFIED_HAND flag
	ld a, [wPreviousAIFlags]
	and ~AI_FLAG_MODIFIED_HAND
	ld [wPreviousAIFlags], a
	jp .loop_hand

.inc_hl_by_5
	inc hl
.inc_hl_by_4
	inc hl
	inc hl
.inc_hl_by_2
	inc hl
	inc hl
	jp .loop_data

.next_in_data
	pop de
	pop hl
	inc hl
	inc hl
	inc hl
	inc hl
	jp .loop_data

.pop_hl
	pop hl
	jp .loop_hand


; plays a Trainer card that doesn't require any input variables
AIPlay_TrainerCard_NoVars:
	ld a, [wAITrainerCardToPlay]
	ldh [hTempCardIndex_ff9f], a
	ld a, OPPACTION_EXECUTE_TRAINER_EFFECTS
	bank1call AIMakeDecision
	ret


; plays a Trainer card that requires 1 input variable
; input:
;	[wAITrainerCardParameter] = input for the Trainer card's effect commands (stored in hTemp_ffa0)
AIPlay_TrainerCard_OneVar:
	ld a, [wAITrainerCardToPlay]
	ldh [hTempCardIndex_ff9f], a
	ld a, [wAITrainerCardParameter]
	ldh [hTemp_ffa0], a
	ld a, OPPACTION_EXECUTE_TRAINER_EFFECTS
	bank1call AIMakeDecision
	ret


; plays a Trainer card that requires 2 input variables
; input:
;	[wAITrainerCardParameter] = input for the Trainer card's effect commands (stored in hTemp_ffa0)
;	[wce1a] = input for the Trainer card's effect commands (stored in hTempPlayAreaLocation_ffa1)
AIPlay_TrainerCard_TwoVars:
	ld a, [wAITrainerCardToPlay]
	ldh [hTempCardIndex_ff9f], a
	ld a, [wAITrainerCardParameter]
	ldh [hTemp_ffa0], a
	ld a, [wce1a]
	ldh [hTempPlayAreaLocation_ffa1], a
	ld a, OPPACTION_EXECUTE_TRAINER_EFFECTS
	bank1call AIMakeDecision
	ret




; makes AI use Potion card.
AIPlay_Potion:
	ld a, [wAITrainerCardToPlay]
	ldh [hTempCardIndex_ff9f], a
	ld a, [wAITrainerCardParameter]
	ldh [hTemp_ffa0], a
	ld e, a
	call GetCardDamageAndMaxHP
	cp 20
	jr c, .play_card
	ld a, 20
.play_card
	ldh [hTempPlayAreaLocation_ffa1], a
	ld a, OPPACTION_EXECUTE_TRAINER_EFFECTS
	bank1call AIMakeDecision
	ret


; if AI doesn't decide to retreat this card,
; check if defending Pokémon can KO active card
; next turn after using Potion.
; if it cannot, return carry.
; also take into account whether attack is high recoil.
AIDecide_Potion1:
	farcall AIDecideWhetherToRetreat
	ccf
	ret nc
	call AICheckIfAttackIsHighRecoil
	ccf
	ret nc
	xor a ; active card
	ldh [hTempPlayAreaLocation_ff9d], a
	farcall CheckIfDefendingPokemonCanKnockOut
	ret nc

.check_if_can_prevent_ko
	ld d, a
	ld a, DUELVARS_ARENA_CARD_HP
	get_turn_duelist_var
	ld h, a
	ld e, PLAY_AREA_ARENA
	call GetCardDamageAndMaxHP
	cp 20 + 1 ; if damage <= 20
	jr c, .calculate_hp
	ld a, 20 ; amount of Potion HP healing

; if damage done by defending Pokémon next turn will still
; KO this card after healing, return no carry.
.calculate_hp
	ld l, a
	ld a, h
	add l
	sub d
	ret z ; nc
	ld a, e ; PLAY_AREA_ARENA
	ccf
	ret


; finds a card in Play Area to use Potion on.
; output:
;	a = card to use Potion on;
;	carry set if Potion should be used.
AIDecide_Potion2:
	xor a
	ldh [hTempPlayAreaLocation_ff9d], a
	farcall CheckIfDefendingPokemonCanKnockOut
	jr nc, .start_from_active
; can KO
	call AIDecide_Potion1.check_if_can_prevent_ko
	ret c

; using Potion on active card does not prevent a KO.
; if player is at last prize, start loop with active card.
; otherwise start loop at first bench Pokémon.
.count_prizes
	rst SwapTurn
	call CountPrizes
	rst SwapTurn
	dec a
	jr z, .start_from_active
	ld e, PLAY_AREA_BENCH_1
	jr .loop

; find Play Area Pokémon with more than 10 damage.
; skip Pokémon if it has a BOOST_IF_TAKEN_DAMAGE attack.
.start_from_active
	ld e, PLAY_AREA_ARENA
.loop
	ld a, DUELVARS_ARENA_CARD
	add e
	get_turn_duelist_var
	cp $ff
	ret z
	push de
	call .check_boost_if_taken_damage
	pop de
	jr c, .has_boost_damage
	call GetCardDamageAndMaxHP
	cp 20 ; if damage >= 20
	jr nc, .found
.has_boost_damage
	inc e
	jr .loop

; a card was found, now to check if it's active or benched.
.found
	ld a, e
	or a
	jr z, .active_card

; bench card
	rst SwapTurn
	call CountPrizes
	rst SwapTurn
	dec a
	jr z, .skip_random
	ld a, 10
	call Random
	cp 3
	ccf
	ret nc
; 7/10 chance of returning carry.
.skip_random
	ld a, e
	scf
	ret

; return carry for active card if not High Recoil.
.active_card
	call AICheckIfAttackIsHighRecoil
	ld a, PLAY_AREA_ARENA
	ccf
	ret

; return carry if either of the attacks are usable
; and have the BOOST_IF_TAKEN_DAMAGE effect.
.check_boost_if_taken_damage
	xor a ; FIRST_ATTACK_OR_PKMN_POWER
	call .check_selected_attack_for_boost_if_taken_damage
	ret c
	ld a, SECOND_ATTACK
;	fallthrough

; return carry if the attack in a is usable
; and has the BOOST_IF_TAKEN_DAMAGE effect.
.check_selected_attack_for_boost_if_taken_damage
	ld [wSelectedAttack], a
	farcall CheckIfSelectedAttackIsUnusable
	ccf
	ret nc
	ld a, ATTACK_FLAG3_ADDRESS | BOOST_IF_TAKEN_DAMAGE_F
	jp CheckLoadedAttackFlag




; makes AI use Super Potion card.
AIPlay_SuperPotion:
	ld a, [wAITrainerCardToPlay]
	ldh [hTempCardIndex_ff9f], a
	ld a, [wAITrainerCardParameter]
	ldh [hTempPlayAreaLocation_ffa1], a
	call AIPickEnergyCardToDiscard
	ldh [hTemp_ffa0], a
	ld a, [wAITrainerCardParameter]
	ld e, a
	call GetCardDamageAndMaxHP
	cp 40
	jr c, .play_card
	ld a, 40
.play_card
	ldh [hTempRetreatCostCards], a
	ld a, OPPACTION_EXECUTE_TRAINER_EFFECTS
	bank1call AIMakeDecision
	ret


; if AI doesn't decide to retreat this card and card has
; any energy cards attached, check if defending Pokémon can KO
; active card next turn after using Super Potion.
; if it cannot, return carry.
; also take into account whether attack is high recoil.
AIDecide_SuperPotion1:
	farcall AIDecideWhetherToRetreat
	ccf
	ret nc
	call AICheckIfAttackIsHighRecoil
	ccf
	ret nc
	xor a
	ldh [hTempPlayAreaLocation_ff9d], a
	ld e, a
	call GetPlayAreaCardAttachedEnergies
;	ld a, [wTotalAttachedEnergies] ; already loaded
	or a
	ret z
	farcall CheckIfDefendingPokemonCanKnockOut
	ret nc

.check_if_can_prevent_ko
	ld d, a
	ld a, DUELVARS_ARENA_CARD_HP
	get_turn_duelist_var
	ld h, a
	ld e, PLAY_AREA_ARENA
	call GetCardDamageAndMaxHP
	cp 40 + 1 ; if damage < 40
	jr c, .calculate_hp
	ld a, 40
.calculate_hp
	ld l, a
	ld a, h
	add l
	sub d
	ret z ; nc

; play Super Potion on the Active Pokémon if it will prevent the KO.
	ld a, e
	ccf
	ret


; finds a card in Play Area to use Super Potion on.
; output:
;	a = card to use Super Potion on;
;	carry set if Super Potion should be used.
AIDecide_SuperPotion2:
	xor a
	ldh [hTempPlayAreaLocation_ff9d], a
	farcall CheckIfDefendingPokemonCanKnockOut
	jr nc, .start_from_active
; can KO
	call AIDecide_SuperPotion1.check_if_can_prevent_ko
	ret c

; using Super Potion on active card does not prevent a KO.
; if player is at last prize, start loop with active card.
; otherwise start loop at first bench Pokémon.
.count_prizes
	rst SwapTurn
	call CountPrizes
	rst SwapTurn
	dec a
	jr z, .start_from_active
	ld e, PLAY_AREA_BENCH_1
	jr .loop

; find Play Area Pokémon with more than 30 damage.
; skip Pokémon if it doesn't have any energy attached,
; has a BOOST_IF_TAKEN_DAMAGE attack,
; or if discarding makes any attack of its attacks unusable.
.start_from_active
	ld e, PLAY_AREA_ARENA
.loop
	ld a, DUELVARS_ARENA_CARD
	add e
	get_turn_duelist_var
	cp $ff
	ret z
	ld d, a
	call GetPlayAreaCardAttachedEnergies
;	ld a, [wTotalAttachedEnergies] ; already loaded
	or a
	jr z, .next
	push de
	call AIDecide_Potion2.check_boost_if_taken_damage
	pop de
	jr c, .next
	push de
	farcall CheckIfEnergyDiscardRendersAnyAttackUnusable
	pop de
	jr c, .next
	call GetCardDamageAndMaxHP
	cp 40 ; if damage >= 40
	jr nc, .found
.next
	inc e
	jr .loop

; a card was found, now to check if it's active or benched.
.found
	ld a, e
	or a
	jr z, .active_card

; bench card
	rst SwapTurn
	call CountPrizes
	rst SwapTurn
	dec a
	jr z, .skip_random
	ld a, 10
	call Random
	cp 3
	ccf
	ret nc
; 7/10 chance of returning carry.
.skip_random
	ld a, e
	scf
	ret

; return carry for active card if not Hgh Recoil.
.active_card
	call AICheckIfAttackIsHighRecoil
	ld a, PLAY_AREA_ARENA
	ccf
	ret




AIPlay_Defender:
	ld a, [wAITrainerCardToPlay]
	ldh [hTempCardIndex_ff9f], a
	xor a
	ldh [hTemp_ffa0], a
	ld a, OPPACTION_EXECUTE_TRAINER_EFFECTS
	bank1call AIMakeDecision
	ret


; returns carry if using Defender can prevent a KO
; by the defending Pokémon.
; this takes into account both attacks and whether they're useable.
AIDecide_Defender1:
; don't play Defender if the AI's Active Pokémon could KO the Defending Pokémon this turn.
	farcall CheckIfActiveWillNotBeAbleToKODefending
	ret nc

; don't play Defender if the Defending Pokémon is currently unable to KO the AI's Active Pokémon.
	farcall CheckIfDefendingPokemonCanKnockOut
	ret nc

; the greatest amount of damage that the Defending Pokémon
; can do to the AI's Active Pokémon is in the a register.
; AI will only decide to play Defender if the damage reduction can
; prevent its Active Pokémon from being KO'd in the following turn.
.check_if_defender_prevents_ko
	sub 20 - 1 ; Defender's damage reduction minus 1 (so carry will be set if final HP = 0)
	ld d, a
	ld a, DUELVARS_ARENA_CARD_HP
	get_turn_duelist_var
	sub d
	ccf
	ret


; return carry if using Defender prevents Pokémon
; from being knocked out by an attack with recoil.
AIDecide_Defender2:
	ld a, ATTACK_FLAG1_ADDRESS | HIGH_RECOIL_F
	call CheckLoadedAttackFlag
	jr c, .recoil
	ld a, ATTACK_FLAG1_ADDRESS | LOW_RECOIL_F
	call CheckLoadedAttackFlag
	ret nc

.recoil
	ld a, DUELVARS_ARENA_CARD
	get_turn_duelist_var
	call LoadCardDataToBuffer2_FromDeckIndex
	ld a, [wSelectedAttack]
	or a
	jr nz, .second_attack
; first attack
	ld a, [wLoadedCard2Atk1EffectParam]
	jr .check_weak
.second_attack
	ld a, [wLoadedCard2Atk2EffectParam]

; double recoil damage if card is weak to its own color.
.check_weak
	ld d, a
	call GetArenaCardColor
	call TranslateColorToWR
	ld b, a
	call GetArenaCardWeakness
	and b
	jr z, .check_resist
	sla d

; subtract 30 from recoil damage if card resists its own color.
; if this yields a negative number, return no carry.
.check_resist
	call GetArenaCardColor
	call TranslateColorToWR
	ld b, a
	call GetArenaCardResistance
	and b
	jr z, .subtract
	ld a, d
	sub 30
	ccf
	ret nc
	ld d, a

; subtract damage prevented by Defender.
; if damage still knocks out card, return no carry.
; if damage does not knock out, return carry.
.subtract
	ld a, d
	or a
	jr nz, AIDecide_Defender1.check_if_defender_prevents_ko
	ret




AIPlay_Pluspower:
	ld a, [wCurrentAIFlags]
	or AI_FLAG_USED_PLUSPOWER
	ld [wCurrentAIFlags], a
	ld a, [wAITrainerCardParameter]
	ld [wAIPluspowerAttack], a
	ld a, [wAITrainerCardToPlay]
	ldh [hTempCardIndex_ff9f], a
	ld a, OPPACTION_EXECUTE_TRAINER_EFFECTS
	bank1call AIMakeDecision
	ret


; returns carry if using a Pluspower can KO defending Pokémon
; if active card cannot KO without the boost.
; outputs in a the attack to use.
AIDecide_Pluspower1:
; continue if no attack can knock out.
; if there's an attack that can, only continue
; if it's unusable and there's no card in hand
; to fulfill its energy cost.
	farcall CheckIfActiveWillNotBeAbleToKODefending
	ret nc

; cannot use an attack that knocks out.
; get active Pokémon's info.
	ld a, DUELVARS_ARENA_CARD
	get_turn_duelist_var
	call _GetCardIDFromDeckIndex
	ld [wTempTurnDuelistCardID], a

; get defending Pokémon's info and check
; its No Damage or Effect substatus.
; if substatus is active, return.
	rst SwapTurn
	ld a, DUELVARS_ARENA_CARD
	get_turn_duelist_var
	call _GetCardIDFromDeckIndex
	ld [wTempNonTurnDuelistCardID], a
	call HandleNoDamageOrEffectSubstatus
	rst SwapTurn
	ccf
	ret nc

; check both attacks and decide which one
; can KO with Pluspower boost.
; if neither can KO, return no carry.
	xor a ; FIRST_ATTACK_OR_PKMN_POWER
	call .check_ko_with_pluspower
	jr c, .kos_with_pluspower
	ld a, SECOND_ATTACK
	call .check_ko_with_pluspower
	ret nc

; selected attack can KO with Pluspower.
.kos_with_pluspower
	call AIDecide_Pluspower2.check_mr_mime
	ret nc
	ld a, [wSelectedAttack]
	ret ; carry set

; return carry if attack is useable and KOs
; defending Pokémon with Pluspower boost.
.check_ko_with_pluspower
	ld [wSelectedAttack], a
	farcall CheckIfSelectedAttackIsUnusable
	ccf
	ret nc
	ld a, [wSelectedAttack]
	farcall EstimateDamage_VersusDefendingCard
	ld a, DUELVARS_ARENA_CARD_HP
	call GetNonTurnDuelistVariable
	ld b, a
	ld hl, wDamage
	sub [hl]
	ret z ; nc
	ccf
	ret nc
	ld a, [hl]
	or a
	ret z ; return no carry if the attack won't do any damage before using PlusPower
	add 10 + 1 ; add Pluspower boost plus 1 (so carry will be set if final HP = 0)
	ld c, a
	ld a, b
	sub c
	ret


; returns carry 7/10 of the time
; if selected attack is useable, can't KO without Pluspower boost
; can damage Mr. Mime even with Pluspower boost
; and has a minimum damage > 0.
; outputs in a the attack to use.
AIDecide_Pluspower2:
; don't play PlusPower if the selected attack isn't usable.
	xor a
	ldh [hTempPlayAreaLocation_ff9d], a
	farcall CheckIfSelectedAttackIsUnusable
	ccf
	ret nc
; don't play PlusPower if the selected attack can already KO the Defending Pokémon.
	ld a, [wSelectedAttack]
	farcall EstimateDamage_VersusDefendingCard
	ld a, DUELVARS_ARENA_CARD_HP
	call GetNonTurnDuelistVariable
	ld hl, wDamage
	sub [hl]
	ret z ; nc
	ccf
	ret nc
; don't play PlusPower if the selected attack might not do any damage.
	ld a, [wAIMinDamage]
	or a
	ret z ; nc
; randomly decide to not play PlusPower 30% of the time.
	ld a, 10
	call Random
	cp 3
	ret nc

; returns carry if Pluspower boost does
; not exceed 30 damage when facing Mr. Mime.
.check_mr_mime
	ld a, [wDamage]
	add 10 ; add Pluspower boost
	cp 30 ; no danger in preventing damage
	ret c
	rst SwapTurn
	ld a, DUELVARS_ARENA_CARD
	get_turn_duelist_var
	call _GetCardIDFromDeckIndex
	rst SwapTurn
	cp MR_MIME
	ret z
; damage is >= 30 but not Mr. Mime
	scf
	ret




AIPlay_Switch:
	ld a, [wCurrentAIFlags]
	or AI_FLAG_USED_SWITCH
	ld [wCurrentAIFlags], a
	ld a, [wAITrainerCardToPlay]
	ldh [hTempCardIndex_ff9f], a
	ld a, [wAITrainerCardParameter]
	ldh [hTemp_ffa0], a
	ld a, OPPACTION_EXECUTE_TRAINER_EFFECTS
	bank1call AIMakeDecision
	xor a
	ld [wAIRetreatScore], a
	ret


; returns carry if the active card has less energy cards
; than the retreat cost and if AI can't play an energy
; card from the hand to fulfill the cost
AIDecide_Switch:
; play Switch if the Active Pokémon is unable to retreat due to an effect.
	ld a, DUELVARS_ARENA_CARD_STATUS
	get_turn_duelist_var
	and CNF_SLP_PRZ
	cp ASLEEP
	jr z, .switch
	cp PARALYZED
	jr z, .switch
	call CheckCantRetreatDueToAttackEffect
	jr c, .switch

; check if AI can already play an energy card from hand to retreat
	ld a, [wAIPlayEnergyCardForRetreat]
	or a
	jr z, .check_cost_amount

; can't play energy card from hand to retreat
; compare number of energy cards attached to retreat cost
	xor a ; PLAY_AREA_ARENA
	ldh [hTempPlayAreaLocation_ff9d], a
	ld e, a
	call GetPlayAreaCardAttachedEnergies
	ld b, a
	call GetPlayAreaCardRetreatCost
	sub b
	; jump if cards attached > retreat cost
	jr c, .check_cost_amount
	cp 2
	; jump if retreat cost is 2 more energy cards
	; than the number of cards attached
	jr nc, .switch

.check_cost_amount
	xor a ; PLAY_AREA_ARENA
	ldh [hTempPlayAreaLocation_ff9d], a
	call GetPlayAreaCardRetreatCost
	cp 3
	; jump if retreat cost >= 3
	jr nc, .switch

	ld b, a
	ld e, PLAY_AREA_ARENA
	call GetPlayAreaCardAttachedEnergies
	cp b
	; jump if energy cards attached < retreat cost
	ret nc

.switch
	ld a, [wAIPlayAreaCardToSwitch]
	scf
	ret




AIPlay_GustOfWind:
	ld a, [wCurrentAIFlags]
	or AI_FLAG_USED_GUST_OF_WIND
	ld [wCurrentAIFlags], a
	ld a, [wAITrainerCardToPlay]
	ldh [hTempCardIndex_ff9f], a
	ld a, [wAITrainerCardParameter]
	ldh [hTemp_ffa0], a
	ld a, OPPACTION_EXECUTE_TRAINER_EFFECTS
	bank1call AIMakeDecision
	ret


AIDecide_GustOfWind:
	ld a, DUELVARS_NUMBER_OF_POKEMON_IN_PLAY_AREA
	call GetNonTurnDuelistVariable
	dec a
	or a
	ret z ; no bench cards

; if used Gust Of Wind already,
; do not use it again.
	ld a, [wPreviousAIFlags]
	and AI_FLAG_USED_GUST_OF_WIND
	ret nz

	farcall CheckIfActivePokemonCanUseAnyNonResidualAttack
	ret nc ; no non-residual attack can be used

; don't play Gust of Wind if the AI's Active Pokémon could KO the Defending Pokémon this turn.
	farcall CheckIfActiveWillNotBeAbleToKODefending
	ret nc

	; skip if current active card is MEW_LV23 or MEWTWO_LV53
	ld a, DUELVARS_ARENA_CARD
	get_turn_duelist_var
	call _GetCardIDFromDeckIndex
	cp MEW_LV23
	ret z ; return no carry if MewLv23 is the AI's Active Pokémon
	cp MEWTWO_LV53
	ret z ; return no carry if MewtwoLv53 is the AI's Active Pokémon

	call .FindBenchCardToKnockOut
	ret c

	xor a ; PLAY_AREA_ARENA
	farcall CheckIfCanDamageDefendingPokemon
	jr nc, .check_bench_energy

	; skip if current arena card's color is
	; the defending card's weakness
	call GetArenaCardColor
	call TranslateColorToWR
	ld b, a
	rst SwapTurn
	call GetArenaCardWeakness
	rst SwapTurn
	and b
	jr z, .FindBenchCardWithWeakness
	ret ; nc

; being here means AI's arena card cannot damage player's arena card
.check_bench_energy
	; return carry if there's a bench card with weakness
	call GetArenaCardColor
	call TranslateColorToWR
	ld b, a
	call .FindBenchCardWithWeakness
	ret c

	ld a, DUELVARS_NUMBER_OF_POKEMON_IN_PLAY_AREA
	call GetNonTurnDuelistVariable
	ld d, a
	ld e, PLAY_AREA_ARENA
; loop through bench and check attached energy cards
.loop_1
	inc e
	dec d
	jr z, .check_bench_hp
	rst SwapTurn
	call GetPlayAreaCardAttachedEnergies
	rst SwapTurn
;	ld a, [wTotalAttachedEnergies] ; already loaded
	or a
	jr nz, .loop_1 ; skip if has energy attached
	call .CheckIfCanDamageBenchedCard
	jr nc, .loop_1
	ld a, e
	scf
	ret

.check_bench_hp
	ld a, $ff
	ld [wce06], a
	xor a
	ld [wce08], a
	ld e, a
	ld a, DUELVARS_NUMBER_OF_POKEMON_IN_PLAY_AREA
	call GetNonTurnDuelistVariable
	ld d, a

; find bench card with least amount of available HP
.loop_2
	inc e
	dec d
	jr z, .check_found
	ld a, e
	add DUELVARS_ARENA_CARD_HP
	ld l, a
	ld b, [hl]
	ld a, [wce06]
	inc b
	cp b
	jr c, .loop_2
	call .CheckIfCanDamageBenchedCard
	jr nc, .loop_2
	dec b
	ld a, b
	ld [wce06], a
	ld a, e
	ld [wce08], a
	jr .loop_2

.check_found
	ld a, [wce08]
	or a
	ret z ; return no carry if no suitable Pokémon was found
; a card was found

.set_carry
	scf
	ret

; returns carry if any of the player's
; benched cards is weak to color in b
; and has a way to damage it
.FindBenchCardWithWeakness
	ld a, DUELVARS_BENCH
	call GetNonTurnDuelistVariable
	ld e, PLAY_AREA_ARENA
.loop_3
	inc e
	ld a, [hli]
	cp $ff
	ret z ; return no carry if there are no more Benched Pokémon to check
	rst SwapTurn
	call LoadCardDataToBuffer1_FromDeckIndex
	rst SwapTurn
	ld a, [wLoadedCard1Weakness]
	and b
	jr z, .loop_3

.check_can_damage
	call .CheckIfCanDamageBenchedCard
	jr nc, .loop_3
	ld a, e
	ret ; c

; returns carry if there is a player's bench card that
; the opponent's current active card can KO
.FindBenchCardToKnockOut
	ld a, DUELVARS_BENCH
	call GetNonTurnDuelistVariable
	ld e, PLAY_AREA_ARENA

.loop_4
	ld a, [hli]
	cp $ff
	ret z
	inc e
	push de
	push hl

; overwrite a variety of Defending Pokémon variables.
; this includes its deck index, HP, attached Defenders,
; Status, Substatus 1/2, and changed Weakness/Resistance.
; could also consider including card stage and changed type.
	; copy the the given Pokémon's deck index
	ld l, DUELVARS_ARENA_CARD
	ld b, [hl]
	ld [hl], a

	; copy the given Pokémon's HP
	ld a, e
	add DUELVARS_ARENA_CARD_HP
	ld l, a
	ld d, [hl]
	ld l, DUELVARS_ARENA_CARD_HP
	ld c, [hl]
	ld [hl], d
	push bc ; backup Defending Pokémon's card deck index and HP

	; copy the given Pokémon's attached Defenders
	ld a, e
	add DUELVARS_ARENA_CARD_ATTACHED_DEFENDER
	ld l, a
	ld d, [hl]
	ld l, DUELVARS_ARENA_CARD_ATTACHED_DEFENDER
	ld b, [hl]
	ld [hl], d

	; clear the Defending Pokémon's Special Conditions, Substatus1,
	; Substatus2, changed Weakness, and changed Resistance.
	xor a
	ld l, DUELVARS_ARENA_CARD_STATUS
	ld c, [hl]
	ld [hl], a
	push bc ; backup Defending Pokémon's attached Defenders and Special Conditions
	ld l, DUELVARS_ARENA_CARD_SUBSTATUS1
	ld b, [hl]
	ld [hl], a
	inc l ; DUELVARS_ARENA_CARD_SUBSTATUS2
	ld c, [hl]
	ld [hl], a
	push bc ; backup Defending Pokémon's Substatus1/2
	inc l ; DUELVARS_ARENA_CARD_CHANGED_WEAKNESS
	ld b, [hl]
	ld [hl], a
	inc l ; DUELVARS_ARENA_CARD_CHANGED_RESISTANCE
	ld c, [hl]
	ld [hl], a
	push bc ; backup Defending Pokémon's changed Weakness/Resistance
	push hl

; check if the Player's Pokémon can be KO'd by the AI's Active Pokémon.
	farcall CheckIfActiveWillNotBeAbleToKODefending

; restore all of the Defending Pokémon variables while preserving the status of the carry flag.
	pop hl ; DUELVARS_ARENA_CARD_CHANGED_RESISTANCE
	pop bc ; Defending Pokémon's changed Weakness/Resistance
	ld [hl], c
	dec l ; DUELVARS_ARENA_CARD_CHANGED_WEAKNESS
	ld [hl], b
	pop bc ; Defending Pokémon's Substatus1/2
	dec l ; DUELVARS_ARENA_CARD_SUBSTATUS2
	ld [hl], c
	dec l ; DUELVARS_ARENA_CARD_SUBSTATUS1
	ld [hl], b
	pop bc ; Defending Pokémon's attached Defenders and Special Conditions
	ld l, DUELVARS_ARENA_CARD_STATUS
	ld [hl], c
	ld l, DUELVARS_ARENA_CARD_ATTACHED_DEFENDER
	ld [hl], b
	pop bc ; Defending Pokémon's card deck index and HP
	ld l, DUELVARS_ARENA_CARD_HP
	ld [hl], c
	ld l, DUELVARS_ARENA_CARD
	ld [hl], b
	pop hl
	pop de
	jr c, .loop_4

; found a Benched Pokémon that can be KO'd, so return carry with its location in a.
	ld a, e
	scf
	ret

; returns carry if opponent's arena card can damage
; this benched card if it were switched with
; the player's arena card
.CheckIfCanDamageBenchedCard
	push bc
	push de
	push hl

	; overwrite arena card data
	ld a, e
	add DUELVARS_ARENA_CARD
	call GetNonTurnDuelistVariable
	ld d, a
	ld l, DUELVARS_ARENA_CARD
	ld b, [hl]
	ld [hl], d

	; overwrite arena card HP
	ld a, e
	add DUELVARS_ARENA_CARD_HP
	ld l, a
	ld d, [hl]
	ld l, DUELVARS_ARENA_CARD_HP
	ld c, [hl]
	ld [hl], d
	push bc ; backup Defending Pokémon's card deck index and HP

	; overwrite arena card Defenders
	ld a, e
	add DUELVARS_ARENA_CARD_ATTACHED_DEFENDER
	ld l, a
	ld d, [hl]
	ld l, DUELVARS_ARENA_CARD_ATTACHED_DEFENDER
	ld b, [hl]
	ld [hl], d

	; clear arena card status, substatus1/2, and changed Weakness/Resistance
	xor a
	ld l, DUELVARS_ARENA_CARD_STATUS
	ld c, [hl]
	ld [hl], a
	push bc ; backup Defending Pokémon's attached Defenders and Special Conditions
	ld l, DUELVARS_ARENA_CARD_SUBSTATUS1
	ld b, [hl]
	ld [hl], a
	inc l ; DUELVARS_ARENA_CARD_SUBSTATUS2
	ld c, [hl]
	ld [hl], a
	push bc ; backup Defending Pokémon's Substatus1/2
	inc l ; DUELVARS_ARENA_CARD_CHANGED_WEAKNESS
	ld b, [hl]
	ld [hl], a
	inc l ; DUELVARS_ARENA_CARD_CHANGED_RESISTANCE
	ld c, [hl]
	ld [hl], a
	push bc ; backup Defending Pokémon's changed Weakness/Resistance
	push hl

	xor a ; PLAY_AREA_ARENA
	farcall CheckIfCanDamageDefendingPokemon

; restore all of the Defending Pokémon variables while preserving the status of the carry flag.
	pop hl ; DUELVARS_ARENA_CARD_CHANGED_RESISTANCE
	pop bc ; Defending Pokémon's changed Weakness/Resistance
	ld [hl], c
	dec l ; DUELVARS_ARENA_CARD_CHANGED_WEAKNESS
	ld [hl], b
	pop bc ; Defending Pokémon's Substatus1/2
	dec l ; DUELVARS_ARENA_CARD_SUBSTATUS2
	ld [hl], c
	dec l ; DUELVARS_ARENA_CARD_SUBSTATUS1
	ld [hl], b
	pop bc ; Defending Pokémon's attached Defenders and Special Conditions
	ld l, DUELVARS_ARENA_CARD_STATUS
	ld [hl], c
	ld l, DUELVARS_ARENA_CARD_ATTACHED_DEFENDER
	ld [hl], b
	pop bc ; Defending Pokémon's card deck index and HP
	ld l, DUELVARS_ARENA_CARD_HP
	ld [hl], c
	ld l, DUELVARS_ARENA_CARD
	ld [hl], b
	pop hl
	pop de
	pop bc
	ret




; Bill uses 'AIPlay_TrainerCard_NoVars'


; return carry if cards in deck > 9
AIDecide_Bill:
	ld a, DUELVARS_NUMBER_OF_CARDS_NOT_IN_DECK
	get_turn_duelist_var
	cp DECK_SIZE - 9
	ret




; Energy Removal uses 'AIPlay_TrainerCard_TwoVars'


; picks an energy card in the player's Play Area to remove
AIDecide_EnergyRemoval:
; check if the current active card can KO player's card
; if it's possible to KO, then do not consider the player's
; active card to remove its attached energy
	farcall CheckIfActiveWillNotBeAbleToKODefending
	ld e, PLAY_AREA_ARENA
	jr c, .defending_pokemon_not_excluded
	; Active can KO, so start loop from the first Benched Pokémon.
	inc e

; loop each card and check if it has enough Energy to use any attack
; if it does, then proceed to pick an Energy card to remove
.defending_pokemon_not_excluded
	rst SwapTurn
	ld a, e
	ld [wce0f], a

.loop_1
	ld a, DUELVARS_ARENA_CARD
	add e
	get_turn_duelist_var
	cp $ff
	jr z, .default

;	ld d, a ; store deck index
	call GetPlayAreaCardAttachedEnergies
;	ld a, [wTotalAttachedEnergies] ; already loaded
	or a
	jr z, .next_1
	push de
	call .CheckIfNotEnoughEnergyToAttack
	pop de
	jr nc, .pick_energy ; jump if enough energy to attack
.next_1
	inc e
	jr .loop_1

; if no card in player's Play Area was found with enough energy
; to attack, just pick an energy card from player's active card
; (in case the AI cannot KO it this turn)
.default
	ld a, [wce0f]
	or a
	jr nz, .check_bench_damage ; not active card
	ld e, a
	call GetPlayAreaCardAttachedEnergies
;	ld a, [wTotalAttachedEnergies] ; already loaded
	or a
	jr nz, .pick_energy

; lastly, check what attack on player's Play Area is highest damaging
; and pick an energy card attached to that Pokemon to remove
.check_bench_damage
	ld e, PLAY_AREA_BENCH_1
	call FindEnergizedPokemonWithHighestDamagingAttack
	ld a, [wce08]
	or a
	jr z, .done ; skip if none found
	ld e, a

.pick_energy
; a play area card was picked to remove energy
; store the picked energy card to remove in wce1a
; and set carry
	ld a, e
	push af
	call PickAttachedEnergyCardToRemove
	ld [wce1a], a
	pop af
	scf
.done
	jp SwapTurn

; returns carry if this card does not
; have enough energy for either of its attacks
.CheckIfNotEnoughEnergyToAttack
	ld a, e
	ldh [hTempPlayAreaLocation_ff9d], a
	xor a ; FIRST_ATTACK_OR_PKMN_POWER
	ld [wSelectedAttack], a
	farcall CheckEnergyNeededForAttack
	ret nc ; return no carry if enough Energy

	ld a, SECOND_ATTACK
	ld [wSelectedAttack], a
	farcall CheckEnergyNeededForAttack
	ret c ; return carry if neither attack has enough energy

; first attack doesn't have enough energy (or is just a Pokemon Power)
; but second attack has enough energy to be used
; check if there's surplus energy for attack and, if so, return carry
	farcall CheckIfNoSurplusEnergyForAttack
	ccf
	ret




AIPlay_SuperEnergyRemoval:
	ld a, [wAITrainerCardToPlay]
	ldh [hTempCardIndex_ff9f], a
	ld hl, wAITrainerCardParameter
	ld a, [hli]
	ldh [hTempList], a
	ld a, [hli] ; wce1a
	ldh [hTempList + 1], a
	ld a, [hli] ; wce1b
	ldh [hTempList + 2], a
	ld a, [hli] ; wce1c
	ldh [hTempList + 3], a
	ld a, [hl]  ; wce1d
	ldh [hTempList + 4], a
	ld a, $ff
	ldh [hTempList + 5], a
	ld a, OPPACTION_EXECUTE_TRAINER_EFFECTS
	bank1call AIMakeDecision
	ret


; picks two energy cards in the player's Play Area to remove
AIDecide_SuperEnergyRemoval:
; first find an Arena card with a color energy card
; to discard for card effect
; return immediately if no Arena cards
	ld a, DUELVARS_NUMBER_OF_POKEMON_IN_PLAY_AREA
	get_turn_duelist_var
	ld c, a
.loop_1
	dec c ; go through play area Pokémon in reverse order
	ld a, c
	or a
	ret z ; return no carry if we reached the Active Pokémon
	ld a, CARD_LOCATION_ARENA
	add c
	call FindBasicEnergyCardsInLocation
	jr c, .loop_1

; card in Play Area location c was found with
; a basic energy card
	ld a, c
	ld [wce0f], a

; check if the current active card can KO player's card
; if it's possible to KO, then do not consider the player's
; active card to remove its attached energy
	farcall CheckIfActiveWillNotBeAbleToKODefending
	rst SwapTurn
	ld e, PLAY_AREA_ARENA
	jr c, .loop_3
	; Active can KO, so start loop from the first Benched Pokémon.
	inc e

; loop each card and check if it has enough energy to use any attack
; if it does, then proceed to pick energy cards to remove
.loop_3
	ld a, DUELVARS_ARENA_CARD
	add e
	get_turn_duelist_var
	cp $ff
	jr z, .done

;	ld d, a ; store deck index
	farcall CountNumberOfEnergyCardsAttached
	cp 2
	jr c, .next_1
	push de
	call .CheckIfNotEnoughEnergyToAttack
	pop de
	jr nc, .found_card ; jump if enough energy to attack
.next_1
	inc e
	jr .loop_3

.found_card
; a play area card was picked to remove energy
; if this is not the Arena Card, then check
; entire bench to pick the highest damage
	ld a, e
	or a
	jr nz, .check_bench_damage

; store the picked energy card to remove in wce1a
; and set carry
.pick_energy
	ld [wce1b], a
	call PickTwoAttachedEnergyCards
	ld [wce1c], a
	ld a, b
	ld [wce1d], a
	rst SwapTurn
	ld a, [wce0f]
	push af
	call AIPickEnergyCardToDiscard
	ld [wce1a], a
	pop af
	scf
	ret

; check what attack on player's Play Area is highest damaging
; and pick an energy card attached to that Pokemon to remove
.check_bench_damage
	xor a
	ld [wce06], a
	ld [wce08], a

	ld e, PLAY_AREA_BENCH_1
.loop_4
	ld a, DUELVARS_ARENA_CARD
	add e
	get_turn_duelist_var
	cp $ff
	jr z, .found_damage
	farcall CountNumberOfEnergyCardsAttached
	cp 2
	jr c, .next_2
	push de
	call .CheckIfNotEnoughEnergyToAttack
	pop de
	call nc, FindEnergizedPokemonWithHighestDamagingAttack.check_attacks_for_current_pokemon
.next_2
	inc e
	jr .loop_4

.found_damage
	ld a, [wce08]
	or a
	jr nz, .pick_energy
.done
	jp SwapTurn

; returns carry if this card does not
; have enough energy for either of its attacks
.CheckIfNotEnoughEnergyToAttack
	ld a, e
	ldh [hTempPlayAreaLocation_ff9d], a
	xor a ; FIRST_ATTACK_OR_PKMN_POWER
	ld [wSelectedAttack], a
	farcall CheckEnergyNeededForAttack
	ret nc ; return no carry if enough Energy

	ld a, SECOND_ATTACK
	ld [wSelectedAttack], a
	farcall CheckEnergyNeededForAttack
	ret c ; return carry if neither attack has enough energy

; first attack doesn't have enough energy (or is just a Pokemon Power)
; but second attack has enough energy to be used
; check if there's surplus energy for attack and, if so,
; return carry if this surplus energy is at least 2
	farcall CheckIfNoSurplusEnergyForAttack
	cp 2
	ccf
	ret




; Pokémon Breeder uses 'AIPlay_TrainerCard_TwoVars'.


AIDecide_PokemonBreeder:
	call IsPrehistoricPowerActive
	ccf
	ret nc

	ld a, 9
	ld hl, wce06
	call ClearMemory_Bank8

	call CreateHandCardList
	ld hl, wDuelTempList

.loop_hand_1
	ld a, [hli]
	cp $ff
	jr z, .not_found_in_hand

; check if card in hand is any of the following
; stage 2 Pokemon cards
	ld d, a
	call _GetCardIDFromDeckIndex
	cp VENUSAUR_LV64
	jr z, .found
	cp VENUSAUR_LV67
	jr z, .found
	cp BLASTOISE
	jr z, .found
	cp VILEPLUME
	jr z, .found
	cp ALAKAZAM
	jr z, .found
	cp GENGAR
	jr nz, .loop_hand_1

.found
	ld a, DUELVARS_NUMBER_OF_POKEMON_IN_PLAY_AREA
	push hl
	get_turn_duelist_var
	pop hl
	ld c, a
	ld e, PLAY_AREA_ARENA

; check Play Area for card that can evolve into
; the picked stage 2 Pokemon
.loop_play_area_1
	push hl
	push bc
	push de
	farcall CheckIfCanEvolveInto_BasicToStage2
	pop de
	call nc, .StoreEvolutionInformation
	pop bc
	pop hl
	inc e
	dec c
	jr nz, .loop_play_area_1
	jr .loop_hand_1

.not_found_in_hand
	ld a, [wce06]
	or a
	jr z, .check_evolution_and_dragonite

; an evolution has been found before
	xor a
	ld [wce06], a
	ld a, DUELVARS_NUMBER_OF_POKEMON_IN_PLAY_AREA
	get_turn_duelist_var
	ld c, a
	lb de, $00, $00

; find highest score in wce08
.loop_score_1
	ld hl, wce08
	add hl, de
	ld a, [wce06]
	cp [hl]
	jr nc, .not_higher

; store this score to wce06
	ld a, [hl]
	ld [wce06], a
; store this PLay Area location to wce07
	ld a, e
	ld [wce07], a

.not_higher
	inc e
	dec c
	jr nz, .loop_score_1

; store the deck index of the stage 2 card
; that has been decided in a,
; return the Play Area location of card
; to evolve in wce1a and return carry
	ld a, [wce07]
	ld [wce1a], a
	ld e, a
	ld hl, wce0f
	add hl, de
	ld a, [hl]
	scf
	ret

.check_evolution_and_dragonite
	ld a, 9
	ld hl, wce06
	call ClearMemory_Bank8

	call CreateHandCardList
	ld hl, wDuelTempList
	push hl

.loop_hand_2
	pop hl
	ld a, [hli]
	cp $ff
	jr z, .check_evolution_found

	push hl
	ld d, a
	ld a, DUELVARS_NUMBER_OF_POKEMON_IN_PLAY_AREA
	get_turn_duelist_var
	ld c, a
	ld e, PLAY_AREA_ARENA

.loop_play_area_2
; check if evolution is possible
	push bc
	push de
	farcall CheckIfCanEvolveInto_BasicToStage2
	pop de
	call nc, .HandleDragoniteLv41Evolution
	call nc, .StoreEvolutionInformation

; not possible to evolve or returned carry
; when handling DragoniteLv41 evolution
	pop bc
	inc e
	dec c
	jr nz, .loop_play_area_2
	jr .loop_hand_2

.check_evolution_found
	ld a, [wce06]
	or a
	ret z ; return no carry if no evolution was found

; at least one evolution was found.
	ld hl, wce06
	xor a
	ld [hli], a ; [wce06] = $00
	ld a, $ff
	ld [hl], a  ; [wce07] = $ff

	ld a, DUELVARS_NUMBER_OF_POKEMON_IN_PLAY_AREA
	get_turn_duelist_var
	ld c, a
	lb de, $00, $00

; find highest score in wce08 with at least
; 2 energy cards attached
.loop_score_2
	ld hl, wce08
	add hl, de
	ld a, [wce06]
	cp [hl]
	jr nc, .next_score

; take the lower 4 bits (total energy cards)
; and skip if less than 2
	ld a, [hl]
	ld b, a
	and %00001111
	cp 2
	jr c, .next_score

; has at least 2 energy cards
; store the score in wce06
	ld a, b
	ld [wce06], a
; store this PLay Area location to wce07
	ld a, e
	ld [wce07], a

.next_score
	inc e
	dec c
	jr nz, .loop_score_2

	ld a, [wce07]
	cp $ff
	ret z

; store the play area location offset of the Pokémon to evolve in wce1a and
; store the deck index of the chosen Stage 2 Evolution card in a. then, return carry.
	ld [wce1a], a
	ld e, a
	ld hl, wce0f
	add hl, de
	ld a, [hl]
	scf
	ret

.StoreEvolutionInformation
	ld a, DUELVARS_ARENA_CARD_HP
	add e
	get_turn_duelist_var
	call ConvertHPToDamageCounters_Bank8
	swap a
	ld b, a

; count number of energy cards attached and keep
; the lowest 4 bits (capped at $0f)
	call GetPlayAreaCardAttachedEnergies
;	ld a, [wTotalAttachedEnergies] ; already loaded
	cp $10
	jr c, .not_maxed_out
	ld a, %00001111
.not_maxed_out
	or b

; 4 high bits of a = HP counters Pokemon still has
; 4 low  bits of a = number of energy cards attached

; store this score in wce08 + PLAY_AREA*
	ld hl, wce08
	ld c, e
	ld b, $00
	add hl, bc
	ld [hl], a

; store the deck index of stage 2 Pokemon in wce0f + PLAY_AREA*
	ld hl, wce0f
	add hl, bc
	ld [hl], d

; increase wce06 by one
	ld hl, wce06
	inc [hl]
	ret

; return carry if card is evolving to DragoniteLv41 and if
; - the card that is evolving is not Arena card and Toxic Gas is active
;   or number of damage counters in Play Area is under 8;
; - the card that is evolving is Arena card and has under 5
;   damage counters or has less than 3 energy cards attached.
.HandleDragoniteLv41Evolution
	push bc
	push de
	push hl

; check card ID
	ld a, d
	call _GetCardIDFromDeckIndex
	cp DRAGONITE_LV41
	jr nz, .no_carry

; check card Play Area location
	ld a, e
	or a
	jr z, .active_card_dragonite

; the card that is evolving is not active card
; return carry if DragoniteLv41's Pokémon Power would be negated.
	ld a, MUK
	call CountPokemonIDInBothPlayAreas
	jr c, .done
	
	ld a, DUELVARS_NUMBER_OF_POKEMON_IN_PLAY_AREA
	get_turn_duelist_var
	ld b, a
	ld c, 0 ; damage counter counter
	ld e, c ; PLAY_AREA_ARENA

; count damage counters in Play Area
.loop_play_area_damage
	push bc
	call GetCardDamageAndMaxHP
	pop bc
	call ConvertHPToDamageCounters_Bank8
	add c
	ld c, a
	inc e
	dec b
	jr nz, .loop_play_area_damage

; compare number of total damage counters
; with 7, if less or equal to that, set carry
	ld a, 7
	cp c
	ccf
	jr .done

.active_card_dragonite
; the card that is evolving is active card
; compare number of this card's damage counters
; with 5, if less than that, set carry
	call GetCardDamageAndMaxHP
	cp 50
	jr c, .done

; compare number of this card's attached energy cards
; with 3, if less than that, set carry
	call GetPlayAreaCardAttachedEnergies
	cp 3
	jr c, .done
.no_carry
	or a
.done
	pop hl
	pop de
	pop bc
	ret




AIPlay_ProfessorOak:
	ld a, [wCurrentAIFlags]
	or AI_FLAG_USED_PROFESSOR_OAK | AI_FLAG_MODIFIED_HAND
	ld [wCurrentAIFlags], a
	ld a, [wAITrainerCardToPlay]
	ldh [hTempCardIndex_ff9f], a
	ld a, OPPACTION_EXECUTE_TRAINER_EFFECTS
	bank1call AIMakeDecision
	ret


; sets carry if AI determines a score of playing
; Professor Oak is over a certain threshold.
AIDecide_ProfessorOak:
; return if cards in deck <= 6
	ld a, DUELVARS_NUMBER_OF_CARDS_NOT_IN_DECK
	get_turn_duelist_var
	cp DECK_SIZE - 6
	ret nc

	ld a, [wOpponentDeckID]
	cp LEGENDARY_ARTICUNO_DECK_ID
	jp z, .HandleLegendaryArticunoDeck
	cp EXCAVATION_DECK_ID
	jp z, .HandleExcavationDeck
	cp WONDERS_OF_SCIENCE_DECK_ID
	jp z, .HandleWondersOfScienceDeck

; return if cards in deck <= 14
.check_cards_deck
	ld a, [hl]
	cp DECK_SIZE - 14
	ret nc

; initialize score
	ld a, $1e
	ld [wce06], a

; check number of cards in hand
.check_cards_hand
	ld a, DUELVARS_NUMBER_OF_CARDS_IN_HAND
	get_turn_duelist_var
	cp 4
	jr nc, .more_than_3_cards

; less than 4 cards in hand
	ld a, [wce06]
	add $32
	ld [wce06], a
	jr .check_energy_cards

.more_than_3_cards
	cp 9
	jr c, .check_energy_cards

; more than 8 cards
	ld a, [wce06]
	sub $1e
	ld [wce06], a

.check_energy_cards
	farcall CreateEnergyCardListFromHand
	jr nc, .handle_blastoise

; no energy cards in hand
	ld a, [wce06]
	add $28
	ld [wce06], a

.handle_blastoise
	ld a, MUK
	call CountPokemonIDInBothPlayAreas
	jr c, .check_hand

; no Muk in Play Area
	ld a, BLASTOISE
	call CountPokemonIDInPlayArea
	jr nc, .check_hand

; at least one Blastoise in AI Play Area
	ld a, WATER_ENERGY
	farcall LookForCardIDInHand
	jr nc, .check_hand

; no Water energy in hand
	ld a, [wce06]
	add $0a
	ld [wce06], a

.check_hand
	call CreateHandCardList
	ld hl, wDuelTempList
.loop_hand
	ld a, [hli]
	cp $ff
	jr z, .check_evolution

	call CheckDeckIndexForBasicPokemon
	jr nc, .loop_hand

	ld a, [wce06]
	add $0a
	ld [wce06], a

.check_evolution
	ld hl, wce0f
	xor a
	ld [hli], a
	ld [hl], a

	ld a, DUELVARS_NUMBER_OF_POKEMON_IN_PLAY_AREA
	get_turn_duelist_var
	ld d, a
	ld e, PLAY_AREA_ARENA

.loop_play_area
	push de
	call .LookForEvolution
	pop de
	jr nc, .not_in_hand

; there's a card in hand that can evolve
	ld a, $01
	ld [wce0f], a

.not_in_hand
; check if a card that can evolve was found at all
; if not, go to the next card in the Play Area
	ld a, [wce08]
	cp $01
	jr nz, .next_play_area

; if it was found, set wce0f + 1 to $01
	ld a, $01
	ld [wce0f + 1], a

.next_play_area
	inc e
	dec d
	jr nz, .loop_play_area

; if a card was found that evolves...
	ld a, [wce0f + 1]
	or a
	jr z, .check_score

; ...but that card is not in the hand...
	ld a, [wce0f]
	or a
	jr nz, .check_score

; ...add to the score
	ld a, [wce06]
	add $0a
	ld [wce06], a

; only return carry if score >  $3c
.check_score
	ld a, [wce06]
	ld b, $3c
	cp b
	ccf
	ret

; return carry if there's a card in the hand that
; can evolve the card in Play Area location in e.
; sets wce08 to $01 if any card is found that can
; evolve regardless of card location.
.LookForEvolution
	xor a
	ld [wce08], a
	ld d, DECK_SIZE

; loop through the whole deck to check if there's
; a card that can evolve this Pokemon.
.loop_deck_evolution
	dec d ; go through deck indices in reverse order
	call CheckIfCanEvolveInto
	jr nc, .can_evolve
.evolution_not_in_hand
	ld a, d
	or a
	jr nz, .loop_deck_evolution
	ret

; a card was found that can evolve, set wce08 to $01
; and if the card is in the hand, return carry.
; otherwise resume looping through deck.
.can_evolve
	ld a, $01
	ld [wce08], a
	ld a, d ; DUELVARS_CARD_LOCATIONS + current deck index
	get_turn_duelist_var
	cp CARD_LOCATION_HAND
	jr nz, .evolution_not_in_hand

	scf
	ret

; handles Legendary Articuno Deck AI logic.
.HandleLegendaryArticunoDeck
	ld a, DUELVARS_NUMBER_OF_POKEMON_IN_PLAY_AREA
	get_turn_duelist_var
	cp 3
	jr nc, .check_playable_cards

; has less than 3 Pokemon in Play Area.
	push af
	call CreateHandCardList
	pop af
	ld d, a
	ld e, PLAY_AREA_ARENA

; if no cards in hand evolve cards in Play Area,
; returns carry.
.loop_play_area_articuno
	ld a, DUELVARS_ARENA_CARD
	add e

	push de
	get_turn_duelist_var
	farcall CheckForEvolutionInList
	pop de
	jr c, .check_playable_cards

	inc e
	dec d
	jr nz, .loop_play_area_articuno

.set_carry
	scf
	ret

; if there are more than 3 energy cards in hand,
; return no carry, otherwise check for playable cards.
.check_playable_cards
	farcall CreateEnergyCardListFromHand
	cp 4
	ret nc

; remove both Professor Oak cards from list
; before checking for playable cards
	call CreateHandCardList
	ld hl, wDuelTempList
	ld c, PROFESSOR_OAK
	farcall RemoveCardIDInList
	farcall RemoveCardIDInList

; look in hand for cards that can be played.
; if a card that cannot be played is found, return no carry.
; otherwise return carry.
.loop_hand_articuno
	ld a, [hli]
	cp $ff
	jr z, .set_carry
	push hl
	farcall CheckIfCardCanBePlayed
	pop hl
	jr c, .loop_hand_articuno
	ret

; handles Excavation deck AI logic.
; sets score depending on whether there's no
; Mysterious Fossil in play and in hand.
.HandleExcavationDeck
; return no carry if cards in deck < 15
	ld a, [hl]
	cp 46
	ret nc

; look for Mysterious Fossil
	ld a, MYSTERIOUS_FOSSIL
	call LookForCardIDInHandAndPlayArea
	jr c, .found_mysterious_fossil
	ld a, $50
	ld [wce06], a
	jp .check_cards_hand
.found_mysterious_fossil
	ld a, $1e
	ld [wce06], a
	jp .check_cards_hand

; handles Wonders of Science AI logic.
; if there's either Grimer or Muk in hand,
; do not play Professor Oak.
.HandleWondersOfScienceDeck
	ld a, GRIMER
	call LookForCardIDInHandList_Bank8
	ccf
	ret nc
	ld a, MUK
	call LookForCardIDInHandList_Bank8
	ccf
	ret nc

	ld a, DUELVARS_NUMBER_OF_CARDS_NOT_IN_DECK
	get_turn_duelist_var
	jp .check_cards_deck




AIPlay_EnergyRetrieval:
	ld a, [wCurrentAIFlags]
	or AI_FLAG_MODIFIED_HAND
	ld [wCurrentAIFlags], a
	ld a, [wAITrainerCardToPlay]
	ldh [hTempCardIndex_ff9f], a
	ld hl, wAITrainerCardParameter
	ld a, [hli]
	ldh [hTempList], a
	ld a, [hli] ; wce1a
	ldh [hTempList + 1], a
	ld a, [hl]  ; wce1b
	ldh [hTempList + 2], a
	ld a, $ff
	ldh [hTempList + 3], a
	ld a, OPPACTION_EXECUTE_TRAINER_EFFECTS
	bank1call AIMakeDecision
	ret


; checks whether AI can play Energy Retrieval and
; picks the energy cards from the discard pile,
; and duplicate cards in hand to discard.
AIDecide_EnergyRetrieval:
; return no carry if no cards in hand
	farcall CreateEnergyCardListFromHand
	ret nc

; handle Go Go Rain Dance deck
; return no carry if there's no Muk card in play and
; if there's no Blastoise card in Play Area
; if there's a Muk in play, continue as normal
	ld a, [wOpponentDeckID]
	cp GO_GO_RAIN_DANCE_DECK_ID
	jr nz, .start
	ld a, MUK
	call CountPokemonIDInBothPlayAreas
	jr c, .start
	ld a, BLASTOISE
	call CountPokemonIDInPlayArea
	ret nc

.start
; find duplicate cards in hand
	call CreateHandCardList
	ld hl, wDuelTempList
	call FindDuplicateCards
	ret nc

	ld [wce06], a
	ld a, CARD_LOCATION_DISCARD_PILE
	call FindBasicEnergyCardsInLocation
	ccf
	ret nc

; some basic energy cards were found in Discard Pile
	ld hl, wce1a
	ld a, $ff
	ld [hli], a ; [wce1a] = $ff
	ld [hli], a ; [wce1b] = $ff
	ld [hl], a  ; [wce1c] = $ff

	ld a, DUELVARS_NUMBER_OF_POKEMON_IN_PLAY_AREA
	get_turn_duelist_var
	ld d, a
	ld e, PLAY_AREA_ARENA

; first check if there are useful energy cards in the list
; and choose them for retrieval first
.loop_play_area
	ld a, DUELVARS_ARENA_CARD
	add e

; load this card's ID in wTempCardID
; and this card's Type in wTempCardType
	get_turn_duelist_var
	call LoadCardDataToBuffer1_FromDeckIndex
	ld [wTempCardID], a
	ld a, [wLoadedCard1Type]
	or TYPE_ENERGY
	ld [wTempCardType], a

; loop the energy cards in the Discard Pile
; and check if they are useful for this Pokemon
	ld hl, wDuelTempList
.loop_energy_cards_1
	ld a, [hli]
	cp $ff
	jr z, .next_play_area

	ld b, a
	farcall CheckIfEnergyIsUseful
	jr nc, .loop_energy_cards_1

	ld a, [wce1a]
	cp $ff
	jr nz, .second_energy

; check if there were already chosen cards,
; if this is the second chosen card, return carry

; first energy card found
	ld a, b
	ld [wce1a], a
	call RemoveCardFromList

.next_play_area
	inc e
	dec d
	jr nz, .loop_play_area

; next, if there are still energy cards left to choose,
; loop through the energy cards again and select
; them in order.
	ld hl, wDuelTempList
.loop_energy_cards_2
	ld a, [hli]
	cp $ff
	jr z, .check_chosen
	ld b, a
	ld a, [wce1a]
	cp $ff
	jr nz, .second_energy
	ld a, b
	ld [wce1a], a
	call RemoveCardFromList
	jr .loop_energy_cards_2

.second_energy
	ld a, b
	ld [wce1b], a
.set_carry
	ld a, [wce06]
	scf
	ret

; will set carry if at least one has been chosen
.check_chosen
	ld a, [wce1a]
	cp $ff
	jr nz, .set_carry
	ret ; nc




AIPlay_SuperEnergyRetrieval:
	ld a, [wCurrentAIFlags]
	or AI_FLAG_MODIFIED_HAND
	ld [wCurrentAIFlags], a
	ld a, [wAITrainerCardToPlay]
	ldh [hTempCardIndex_ff9f], a
	ld hl, wAITrainerCardParameter
	ld a, [hli]
	ldh [hTempList], a
	ld a, [hli] ; wce1a
	ldh [hTempList + 1], a
	ld a, [hli] ; wce1b
	ldh [hTempList + 2], a
	ld a, [hli] ; wce1c
	ldh [hTempList + 3], a
	cp $ff
	jr z, .play_card
	ld a, [hli] ; wce1d
	ldh [hTempList + 4], a
	cp $ff
	jr z, .play_card
	ld a, [hl]  ; wce1e
	ldh [hTempList + 5], a
	ld a, $ff
	ldh [hTempList + 6], a
.play_card
	ld a, OPPACTION_EXECUTE_TRAINER_EFFECTS
	bank1call AIMakeDecision
	ret


AIDecide_SuperEnergyRetrieval:
; return no carry if no cards in hand
	farcall CreateEnergyCardListFromHand
	ret nc

; handle Go Go Rain Dance deck
; return no carry if there's no Muk card in play and
; if there's no Blastoise card in Play Area
; if there's a Muk in play, continue as normal
	ld a, [wOpponentDeckID]
	cp GO_GO_RAIN_DANCE_DECK_ID
	jr nz, .start
	ld a, MUK
	call CountPokemonIDInBothPlayAreas
	jr c, .start
	ld a, BLASTOISE
	call CountPokemonIDInPlayArea
	ret nc

.start
; find duplicate cards in hand
	call CreateHandCardList
	ld hl, wDuelTempList
	call FindDuplicateCards
	ret nc

; remove the duplicate card in hand
; and run the hand check again
	ld [wce06], a
	ld hl, wDuelTempList
	call FindAndRemoveCardFromList
	call FindDuplicateCards
	ret nc
	ld b, a

	ld a, CARD_LOCATION_DISCARD_PILE
	call FindBasicEnergyCardsInLocation
	ccf
	ret nc

; some basic energy cards were found in Discard Pile
	ld a, b
	ld hl, wce1a
	ld [hli], a
	ld a, $ff
	ld [hli], a ; [wce1b] = $ff
	ld [hli], a ; [wce1c] = $ff
	ld [hli], a ; [wce1d] = $ff
	ld [hli], a ; [wce1e] = $ff
	ld [hl], a  ; [wce1f] = $ff

	ld a, DUELVARS_NUMBER_OF_POKEMON_IN_PLAY_AREA
	get_turn_duelist_var
	ld d, a
	ld e, PLAY_AREA_ARENA

; first check if there are useful energy cards in the list
; and choose them for retrieval first
.loop_play_area
	ld a, DUELVARS_ARENA_CARD
	add e

; load this card's ID in wTempCardID
; and this card's Type in wTempCardType
	get_turn_duelist_var
	call LoadCardDataToBuffer1_FromDeckIndex
	ld [wTempCardID], a
	ld a, [wLoadedCard1Type]
	or TYPE_ENERGY
	ld [wTempCardType], a

; loop the energy cards in the Discard Pile
; and check if they are useful for this Pokemon
	ld hl, wDuelTempList
.loop_energy_cards_1
	ld a, [hli]
	cp $ff
	jr z, .next_play_area

	ld b, a
	farcall CheckIfEnergyIsUseful
	jr nc, .loop_energy_cards_1

; first energy
	ld a, [wce1b]
	cp $ff
	jr nz, .second_energy_1
	ld a, b
	ld [wce1b], a
	call RemoveCardFromList
	jr .next_play_area

.second_energy_1
	ld a, [wce1c]
	cp $ff
	jr nz, .third_energy_1
	ld a, b
	ld [wce1c], a
	call RemoveCardFromList
	jr .next_play_area

.third_energy_1
	ld a, [wce1d]
	cp $ff
	jr nz, .fourth_energy
	ld a, b
	ld [wce1d], a
	call RemoveCardFromList
	; fallthrough

.next_play_area
	inc e
	dec d
	jr nz, .loop_play_area

; next, if there are still energy cards left to choose,
; loop through the energy cards again and select
; them in order.
	ld hl, wDuelTempList
.loop_energy_cards_2
	ld a, [hli]
	cp $ff
	jr z, .check_chosen
	ld b, a
	ld a, [wce1b]
	cp $ff
	jr nz, .second_energy_2
	ld a, b

; first energy
	ld [wce1b], a
	call RemoveCardFromList
	jr .loop_energy_cards_2

.second_energy_2
	ld a, [wce1c]
	cp $ff
	jr nz, .third_energy_2
	ld a, b
	ld [wce1c], a
	call RemoveCardFromList
	jr .loop_energy_cards_2

.third_energy_2
	ld a, [wce1d]
	cp $ff
	jr nz, .fourth_energy
	ld a, b
	ld [wce1d], a
	call RemoveCardFromList
	jr .loop_energy_cards_2

.fourth_energy
	ld a, b
	ld [wce1e], a

.set_carry
	ld a, [wce06]
	scf
	ret

; will set carry if at least one has been chosen
.check_chosen
	ld a, [wce1b]
	cp $ff
	jr nz, .set_carry
	ret ; nc




; Pokemon Center uses 'AIPlay_TrainerCard_NoVars'


AIDecide_PokemonCenter:
; return if active Pokemon can KO player's card.
	farcall CheckIfActiveWillNotBeAbleToKODefending
	ret nc

.start
	xor a
	ld [wce06], a
	ld [wce08], a
	ld [wce0f], a

	ld a, DUELVARS_NUMBER_OF_POKEMON_IN_PLAY_AREA
	get_turn_duelist_var
	ld d, a
	ld e, PLAY_AREA_ARENA

.loop_play_area
	ld a, DUELVARS_ARENA_CARD
	add e
	get_turn_duelist_var
	call LoadCardDataToBuffer1_FromDeckIndex

; get this Pokemon's current HP in number of counters
; and add it to the total.
	ld a, [wLoadedCard1HP]
	call ConvertHPToDamageCounters_Bank8
	ld b, a
	ld a, [wce06]
	add b
	ld [wce06], a

; get this Pokemon's current damage counters
; and add it to the total.
	call GetCardDamageAndMaxHP
	call ConvertHPToDamageCounters_Bank8
	ld b, a
	ld a, [wce08]
	add b
	ld [wce08], a

; get this Pokemon's number of attached energy cards
; and add it to the total.
; if there's overflow, return no carry.
	call GetPlayAreaCardAttachedEnergies
;	ld a, [wTotalAttachedEnergies] ; already loaded
	ld b, a
	ld a, [wce0f]
	add b
	ccf
	ret nc
	ld [wce0f], a

	inc e
	dec d
	jr nz, .loop_play_area

; if (number of damage counters / 2) < (total energy cards attached)
; return no carry.
	ld a, [wce08]
	srl a
	ld hl, wce0f
	cp [hl]
	ccf
	ret nc

; if (number of HP counters * 6 / 10) >= (number of damage counters)
; return no carry. otherwise, return carry.
	ld a, [wce06]
	ld l, a
	ld h, 6
	call HtimesL
	call CalculateWordTensDigit
	ld a, l
	ld hl, wce08
	cp [hl]
	ret




; Imposter Professor Oak uses 'AIPlay_TrainerCard_NoVars'


; sets carry depending on player's number of cards
; in deck in in hand.
AIDecide_ImposterProfessorOak:
	ld a, DUELVARS_NUMBER_OF_CARDS_NOT_IN_DECK
	call GetNonTurnDuelistVariable
	cp DECK_SIZE - 14
	jr c, .more_than_14_cards

; if player has less than 14 cards in deck, only
; set carry if number of cards in their hands < 6
	ld l, DUELVARS_NUMBER_OF_CARDS_IN_HAND
	ld a, [hl]
	cp 6
	ret

; if player has more than 14 cards in deck, only
; set carry if number of cards in their hands >= 9
.more_than_14_cards
	ld l, DUELVARS_NUMBER_OF_CARDS_IN_HAND
	ld a, [hl]
	cp 9
	ccf
	ret




; Energy Search uses 'AIPlay_TrainerCard_OneVar'


; AI checks for playing Energy Search
AIDecide_EnergySearch:
; don't play Energy Search if there is at least one Energy card
; in the AI's hand that is useful to a Pokémon in the play area.
	farcall CreateEnergyCardListFromHand
	jr c, .start
	call LookForUsefulEnergyCardInList
	ret nc

.start
; if no energy cards in deck, return no carry
	ld a, CARD_LOCATION_DECK
	call FindBasicEnergyCardsInLocation
	ccf
	ret nc

; handle some decks differently
	ld a, [wOpponentDeckID]
	cp HEATED_BATTLE_DECK_ID
	jr z, LookForUsefulEnergyCardInList_OnlyCheckFireAndLightningPokemon
	cp WONDERS_OF_SCIENCE_DECK_ID
	jr z, LookForUsefulEnergyCardInList_OnlyCheckGrassPokemon

; if any of the energy cards in deck is useful
; return carry right away...
	call LookForUsefulEnergyCardInList
	ret c

; ...otherwise save the list in a before return carry.
	ld a, [wDuelTempList]
	scf
	ret

; checks whether there are useful energies
; only for Fire and Lightning type Pokemon cards
; in Play Area. If any are found, return carry.
LookForUsefulEnergyCardInList_OnlyCheckFireAndLightningPokemon:
	ld a, DUELVARS_NUMBER_OF_POKEMON_IN_PLAY_AREA
	get_turn_duelist_var
	ld d, a
	ld e, PLAY_AREA_ARENA

.loop_play_area
	ld a, DUELVARS_ARENA_CARD
	add e
	get_turn_duelist_var

; get card's ID and Type
	call LoadCardDataToBuffer1_FromDeckIndex
	ld [wTempCardID], a
	ld a, [wLoadedCard1Type]

; only do check if the Pokemon's type
; is either Fire or Lightning
	cp TYPE_PKMN_FIRE
	jr z, .fire_or_lightning
	cp TYPE_PKMN_LIGHTNING
	jr nz, .next_play_area

; loop each energy card in list
.fire_or_lightning
	or TYPE_ENERGY
	ld [wTempCardType], a
	ld hl, wDuelTempList
.loop_energy
	ld a, [hli]
	cp $ff
	jr z, .next_play_area

; if this energy card is useful, return carry.
	ld b, a
	farcall CheckIfEnergyIsUseful
	jr nc, .loop_energy

	ld a, b
	ret ; c

.next_play_area
	inc e
	ld a, e
	cp d
	jr nz, .loop_play_area
; no card was found to be useful for Fire/Lightning type Pokemon.
	ret ; nc

; checks whether there are useful energies
; only for Grass type Pokemon cards
; in Play Area. If any are found, return carry.
LookForUsefulEnergyCardInList_OnlyCheckGrassPokemon:
	ld c, TYPE_PKMN_GRASS
;	fallthrough

LookForUsefulEnergyCardInList_OnlyCheckPokemonOfGivenType:
	ld a, DUELVARS_NUMBER_OF_POKEMON_IN_PLAY_AREA
	get_turn_duelist_var
	ld d, a
	ld e, PLAY_AREA_ARENA

.loop_play_area
	ld a, DUELVARS_ARENA_CARD
	add e
	get_turn_duelist_var

; get card's ID and Type
	call LoadCardDataToBuffer1_FromDeckIndex
	ld [wTempCardID], a
	ld a, [wLoadedCard1Type]
	cp c
	jr nz, .next_play_area ; skip this Pokémon if it's type doesn't match c input

; loop each energy card in list
	or TYPE_ENERGY
	ld [wTempCardType], a
	ld hl, wDuelTempList
.loop_energy
	ld a, [hli]
	cp $ff
	jr z, .next_play_area

; if this energy card is useful, return carry.
	ld b, a
	farcall CheckIfEnergyIsUseful
	jr nc, .loop_energy

	ld a, b
	ret ; c

.next_play_area
	inc e
	ld a, e
	cp d
	jr nz, .loop_play_area
; no card was found to be useful for Pokemon of given type.
	ret ; nc

; return carry if cards in wDuelTempList are
; useful to any of the Play Area Pokemon
LookForUsefulEnergyCardInList:
	ld a, DUELVARS_NUMBER_OF_POKEMON_IN_PLAY_AREA
	get_turn_duelist_var
	ld d, a
	ld e, PLAY_AREA_ARENA

.loop_play_area
	ld a, DUELVARS_ARENA_CARD
	add e
	get_turn_duelist_var

; store ID and type of card
	call LoadCardDataToBuffer1_FromDeckIndex
	ld [wTempCardID], a
	ld a, [wLoadedCard1Type]
	or TYPE_ENERGY
	ld [wTempCardType], a

; look in list for a useful energy,
; is any is found return no carry.
	ld hl, wDuelTempList
.loop_energy
	ld a, [hli]
	cp $ff
	jr z, .next_play_area
	ld b, a
	farcall CheckIfEnergyIsUseful
	jr nc, .loop_energy

	ld a, b
	ret ; c

.next_play_area
	inc e
	dec d
	jr nz, .loop_play_area
	ret ; nc




AIPlay_Pokedex:
	ld a, [wAITrainerCardToPlay]
	ldh [hTempCardIndex_ff9f], a
	ld hl, wce1a
	ld a, [hli]
	ldh [hTempList], a
	ld a, [hli] ; wce1b
	ldh [hTempList + 1], a
	ld a, [hli] ; wce1c
	ldh [hTempList + 2], a
	ld a, [hli] ; wce1d
	ldh [hTempList + 3], a
	ld a, [hl]  ; wce1e
	ldh [hTempList + 4], a
	ld a, $ff
	ldh [hTempList + 5], a
	ld a, OPPACTION_EXECUTE_TRAINER_EFFECTS
	bank1call AIMakeDecision
	ret


AIDecide_Pokedex:
	ld a, [wAIPokedexCounter]
	cp 5
	ccf
	ret nc ; return if counter hasn't reached 5 yet

; return no carry if number of cards in deck <= 4
	ld a, DUELVARS_NUMBER_OF_CARDS_NOT_IN_DECK
	get_turn_duelist_var
	cp DECK_SIZE - 4
	ret nc

; has a 3 in 10 chance of actually playing card
	ld a, 10
	call Random
	cp 3
	ret nc

.pick_cards
	ld a, [wOpponentDeckID]
	cp WONDERS_OF_SCIENCE_DECK_ID
	jp nz, PickPokedexCards
	; fallthrough

; picks order of the cards in deck from the effects of Pokedex.
; prioritizes Pokemon cards, then Trainer cards, then energy cards.
; stores the resulting order in wce1a.
	xor a
	ld [wAIPokedexCounter], a ; reset counter

	ld a, DUELVARS_NUMBER_OF_CARDS_NOT_IN_DECK
	get_turn_duelist_var
	add DUELVARS_DECK_CARDS
	ld l, a
	lb de, $00, $00
	ld b, 5

; run through 5 of the remaining cards in deck
.next_card
	ld a, [hli]
	ld c, a
	call GetCardTypeFromDeckIndex_SaveDE

; load this card's deck index and type in memory
; wce08 = card types
; wce0f = card deck indices
	push hl
	ld hl, wce08
	add hl, de
	ld [hl], a
	ld hl, wce0f
	add hl, de
	ld [hl], c
	pop hl

	inc e
	dec b
	jr nz, .next_card

; terminate the wce08 list
	ld a, $ff
	ld [wce08 + 5], a

	ld de, wce1a

; find Pokemon
	ld hl, wce08
	lb bc, 0, -1

; run through the stored cards
; and look for any Pokemon cards.
.loop_pokemon
	inc c
	ld a, [hli]
	cp $ff
	jr z, .find_trainers
	cp TYPE_ENERGY
	jr nc, .loop_pokemon
; found a Pokemon card
; store it in wce1a list
	push hl
	ld hl, wce0f
	add hl, bc
	ld a, [hl]
	pop hl
	ld [de], a
	inc de
	jr .loop_pokemon

; run through the stored cards
; and look for any Trainer cards.
.find_trainers
	ld hl, wce08
	lb bc, 0, -1

.loop_trainers
	inc c
	ld a, [hli]
	cp $ff
	jr z, .find_energy
	cp TYPE_TRAINER
	jr nz, .loop_trainers
; found a Trainer card
; store it in wce1a list
	push hl
	ld hl, wce0f
	add hl, bc
	ld a, [hl]
	pop hl
	ld [de], a
	inc de
	jr .loop_trainers

.find_energy
	ld hl, wce08
	lb bc, 0, -1

; run through the stored cards
; and look for any energy cards.
.loop_energy
	inc c
	ld a, [hli]
	cp $ff
	jr z, .done
	and TYPE_ENERGY
	jr z, .loop_energy
; found an energy card
; store it in wce1a list
	push hl
	ld hl, wce0f
	add hl, bc
	ld a, [hl]
	pop hl
	ld [de], a
	inc de
	jr .loop_energy

.done
	scf
	ret


; picks order of the cards in deck from the effects of Pokedex.
; prioritizes energy cards, then Pokemon cards, then Trainer cards.
; stores the resulting order in wce1a.
PickPokedexCards:
	xor a
	ld [wAIPokedexCounter], a ; reset counter ; reset counter

	ld a, DUELVARS_NUMBER_OF_CARDS_NOT_IN_DECK
	get_turn_duelist_var
	add DUELVARS_DECK_CARDS
	ld l, a
	lb de, $00, $00
	ld b, 5

; run through 5 of the remaining cards in deck
.next_card
	ld a, [hli]
	ld c, a
	call GetCardTypeFromDeckIndex_SaveDE

; load this card's deck index and type in memory
; wce08 = card types
; wce0f = card deck indices
	push hl
	ld hl, wce08
	add hl, de
	ld [hl], a
	ld hl, wce0f
	add hl, de
	ld [hl], c
	pop hl

	inc e
	dec b
	jr nz, .next_card

; terminate the wce08 list
	ld a, $ff
	ld [wce08 + 5], a

	ld de, wce1a

; find energy
	ld hl, wce08
	lb bc, 0, -1

; run through the stored cards
; and look for any energy cards.
.loop_energy
	inc c
	ld a, [hli]
	cp $ff
	jr z, .find_pokemon
	and TYPE_ENERGY
	jr z, .loop_energy
; found an energy card
; store it in wce1a list
	push hl
	ld hl, wce0f
	add hl, bc
	ld a, [hl]
	pop hl
	ld [de], a
	inc de
	jr .loop_energy

.find_pokemon
	ld hl, wce08
	lb bc, 0, -1

; run through the stored cards
; and look for any Pokemon cards.
.loop_pokemon
	inc c
	ld a, [hli]
	cp $ff
	jr z, .find_trainers
	cp TYPE_ENERGY
	jr nc, .loop_pokemon
; found a Pokemon card
; store it in wce1a list
	push hl
	ld hl, wce0f
	add hl, bc
	ld a, [hl]
	pop hl
	ld [de], a
	inc de
	jr .loop_pokemon

; run through the stored cards
; and look for any Trainer cards.
.find_trainers
	ld hl, wce08
	lb bc, 0, -1

.loop_trainers
	inc c
	ld a, [hli]
	cp $ff
	jr z, .done
	cp TYPE_TRAINER
	jr nz, .loop_trainers
; found a Trainer card
; store it in wce1a list
	push hl
	ld hl, wce0f
	add hl, bc
	ld a, [hl]
	pop hl
	ld [de], a
	inc de
	jr .loop_trainers

.done
	scf
	ret




; Full Heal uses 'AIPlay_TrainerCard_NoVars'


AIDecide_FullHeal:
	ld a, DUELVARS_ARENA_CARD_STATUS
	get_turn_duelist_var

; skip if no status on arena card
	or a ; NO_STATUS
	ret z ; return no carry if there are no Special Conditions to remove

	and CNF_SLP_PRZ
	cp PARALYZED
	jr z, .paralyzed
	cp ASLEEP
	jr z, .asleep
	cp CONFUSED
	jr z, .confused
	; if either PSN or DBLPSN, fallthrough

.set_carry
	scf
	ret

; returns carry if player's Arena card
; is card in register a
.CheckPlayerArenaCard:
	rst SwapTurn
	ld b, PLAY_AREA_ARENA
	call LookForCardIDInPlayArea_Bank8
	jp SwapTurn

.asleep
; set carry if any of the following
; cards are in the Play Area.
	ld a, GASTLY_LV8
	call .CheckPlayerArenaCard
	ret c
	ld a, GASTLY_LV17
	call .CheckPlayerArenaCard
	ret c
	ld a, HAUNTER_LV22
	call .CheckPlayerArenaCard
	ret c

.paralyzed
; if Scoop Up is in hand and decided to be played, skip.
	ld a, SCOOP_UP
	call LookForCardIDInHandList_Bank8
	jr nc, .no_scoop_up_prz
	call AIDecide_ScoopUp
	ccf
	ret nc

.no_scoop_up_prz
; return carry if Arena card
; can damage the defending Pokémon

; temporarily remove status effect for damage checking
	ld a, DUELVARS_ARENA_CARD_STATUS
	get_turn_duelist_var
	ld b, [hl]
	ld [hl], NO_STATUS
	push hl
	push bc
	xor a ; PLAY_AREA_ARENA
	farcall CheckIfCanDamageDefendingPokemon
	pop bc
	pop hl
	ld [hl], b
	ret c

; if it can play an energy card to retreat, set carry.
	ld a, [wAIPlayEnergyCardForRetreat]
	or a
	jr nz, .set_carry

; if not, check whether it's a card it would rather retreat,
; and if it isn't, set carry.
	farcall AIDecideWhetherToRetreat
	ccf
	ret

.confused
; if Scoop Up is in hand and decided to be played, skip.
	ld a, SCOOP_UP
	call LookForCardIDInHandList_Bank8
	jr nc, .no_scoop_up_cnf
	call AIDecide_ScoopUp
	ccf
	ret nc

.no_scoop_up_cnf
; if card can damage defending Pokemon...
	xor a ; PLAY_AREA_ARENA
	farcall CheckIfCanDamageDefendingPokemon
	ret nc
; ...and can play an energy card to retreat, set carry.
	ld a, [wAIPlayEnergyCardForRetreat]
	or a
	jr nz, .set_carry
; if not, return no carry.
	ret




; Mr. Fuji uses 'AIPlay_TrainerCard_OneVar'


; AI logic for playing Mr Fuji
AIDecide_MrFuji:
	ld a, $ff
	ld [wce06], a
	ld [wce08], a

; if just one Pokemon in Play Area, skip.
	ld a, DUELVARS_NUMBER_OF_POKEMON_IN_PLAY_AREA
	get_turn_duelist_var
	dec a
	or a
	ret z

	ld d, a
	ld e, PLAY_AREA_BENCH_1

; find a Pokemon in the bench that has damage counters.
.loop_bench
	ld a, DUELVARS_ARENA_CARD
	add e
	get_turn_duelist_var
	call LoadCardDataToBuffer1_FromDeckIndex

	ld a, [wLoadedCard1HP]
	ld b, a

	; skip if zero damage counters
	call GetCardDamageAndMaxHP
	call ConvertHPToDamageCounters_Bank8
	or a
	jr z, .next

; a = damage counters
; b = hp left
	call CalculateBDividedByA_Bank8
	cp 20
	jr nc, .next

; here, HP left in counters is less than twice
; the number of damage counters, that is:
; HP < 1/3 max HP

; if value is less than the one found before, store this one.
	ld hl, wce08
	cp [hl]
	jr nc, .next
	ld [hl], a
	ld a, e
	ld [wce06], a
.next
	inc e
	dec d
	jr nz, .loop_bench

	ld a, [wce06]
	cp $ff
	ret z

	scf
	ret




; Scoop Up uses 'AIPlay_TrainerCard_TwoVars'


AIDecide_ScoopUp:
; if only one Pokemon in Play Area, skip.
	ld a, DUELVARS_NUMBER_OF_POKEMON_IN_PLAY_AREA
	get_turn_duelist_var
	cp 1
	ret z ; return no carry if there are no Benched Pokémon

; handle some decks differently
	ld a, [wOpponentDeckID]
	cp LEGENDARY_ARTICUNO_DECK_ID
	jr z, .HandleLegendaryArticuno
	cp LEGENDARY_RONALD_DECK_ID
	jp z, .HandleLegendaryRonald

; if can't KO defending Pokemon, check if defending Pokemon
; can KO this card. If so, then continue.
; If not, return no carry.

; if it can KO the defending Pokemon this turn,
; return no carry.
	farcall CheckIfActiveWillNotBeAbleToKODefending
	ret nc

	ld a, DUELVARS_ARENA_CARD_STATUS
	get_turn_duelist_var
	and CNF_SLP_PRZ
	cp PARALYZED
	jr z, .cannot_retreat
	cp ASLEEP
	jr z, .cannot_retreat
	call CheckCantRetreatDueToAttackEffect
	jr c, .cannot_retreat

; doesn't have a status that prevents retreat.
; so check if it has enough energy to retreat.
; if not, return no carry.
	xor a
	ld e, a
	ldh [hTempPlayAreaLocation_ff9d], a
	call GetPlayAreaCardRetreatCost
	ld b, a
	call GetPlayAreaCardAttachedEnergies
	cp b
	ret nc

.cannot_retreat
; store damage and total HP left
	ld a, DUELVARS_ARENA_CARD
	get_turn_duelist_var
	call LoadCardDataToBuffer1_FromDeckIndex
	ld a, [wLoadedCard1HP]
	call ConvertHPToDamageCounters_Bank8
	ld d, a

; skip if card has no damage counters.
	ld e, PLAY_AREA_ARENA
	call GetCardDamageAndMaxHP
	or a
	ret z ; return no carry if the Active Pokémon isn't damaged

; if (total damage / total HP counters) < 7
; return carry.
; (this corresponds to damage counters
; being under 70% of the max HP)
	ld b, a
	ld a, d
	call CalculateBDividedByA_Bank8
	cp 7
	ccf
	ret nc

; store Pokemon to switch to in wce1a and set carry.
.decide_switch
	farcall AIDecideBenchPokemonToSwitchTo
	ccf
	ret nc
	ld [wce1a], a
	xor a
	scf
	ret

; this deck will use Scoop Up on a Benched ARTICUNO_LV37
; or on an Active ArticunoLv37/Chansey.
.HandleLegendaryArticuno
; if less than 3 Play Area Pokemon cards, skip.
	ld a, DUELVARS_NUMBER_OF_POKEMON_IN_PLAY_AREA
	get_turn_duelist_var
	cp 3
	ccf
	ret nc

; look for ArticunoLv37 in bench
	ld a, ARTICUNO_LV37
	ld b, PLAY_AREA_BENCH_1
	call LookForCardIDInPlayArea_Bank8
	jr c, .articuno_bench

; check Arena card
	ld a, DUELVARS_ARENA_CARD
	get_turn_duelist_var
	call _GetCardIDFromDeckIndex
	cp ARTICUNO_LV37
	jr z, .articuno_or_chansey
	cp CHANSEY
	jr z, .articuno_or_chansey
	or a
	ret

; here either ArticunoLv37 or Chansey
; is the Arena Card.
.articuno_or_chansey
; if can't KO defending Pokemon, check if defending Pokemon
; can KO this card. If so, then continue.
; If not, return no carry.

; if it can KO the defending Pokemon this turn,
; return no carry.
	farcall CheckIfActiveWillNotBeAbleToKODefending
	ret nc

	farcall CheckIfDefendingPokemonCanKnockOut
	ret nc
	jr .decide_switch

.articuno_bench
; skip if the defending card is Snorlax
	ld e, a
	rst SwapTurn
	ld a, DUELVARS_ARENA_CARD
	get_turn_duelist_var
	call _GetCardIDFromDeckIndex
	rst SwapTurn
	cp SNORLAX
	ret z ; return no carry if the Defending Pokémon is a Snorlax

; check attached energy cards.
; if it has any, return no carry.
	ld a, e
.check_attached_energy
	ld e, a
	call GetPlayAreaCardAttachedEnergies
	or a
	ret nz ; return no carry if this Pokémon has any attached Energy cards

; return no carry if there's a Muk in either play area
	ld a, MUK
	call CountPokemonIDInBothPlayAreas
	ccf
	ret nc

; has decided to Scoop Up benched card,
; store $ff as the Pokemon card to switch to
; because there's no need to switch.
	ld a, $ff
	ld [wce1a], a
	ld a, e
	ret

; this deck will use Scoop Up on a benched ArticunoLv37, ZapdosLv68 or MoltresLv37.
.HandleLegendaryRonald
; if less than 3 Play Area Pokemon cards, skip.
	ld a, DUELVARS_NUMBER_OF_POKEMON_IN_PLAY_AREA
	get_turn_duelist_var
	cp 3
	ccf
	ret nc

	ld a, ARTICUNO_LV37
	ld b, PLAY_AREA_BENCH_1
	call LookForCardIDInPlayArea_Bank8
	call c, .articuno_bench
	ret c
	ld a, ZAPDOS_LV68
	ld b, PLAY_AREA_BENCH_1
	call LookForCardIDInPlayArea_Bank8
	call c, .check_attached_energy
	ret c
	ld a, MOLTRES_LV37
	ld b, PLAY_AREA_BENCH_1
	call LookForCardIDInPlayArea_Bank8
	jr c, .check_attached_energy
	ret




AIPlay_Maintenance:
	ld a, [wCurrentAIFlags]
	or AI_FLAG_MODIFIED_HAND
	ld [wCurrentAIFlags], a
	ld a, [wAITrainerCardToPlay]
	ldh [hTempCardIndex_ff9f], a
	ld a, [wce1a]
	ldh [hTempList], a
	ld a, [wce1b]
	ldh [hTempList + 1], a
	ld a, OPPACTION_EXECUTE_TRAINER_EFFECTS
	bank1call AIMakeDecision
	ret


; AI logic for playing Maintenance
AIDecide_Maintenance:
; Imakuni? has his own thing
	ld a, [wOpponentDeckID]
	cp IMAKUNI_DECK_ID
	jr z, .imakuni

; skip if number of cars in hand < 4.
	ld a, DUELVARS_NUMBER_OF_CARDS_IN_HAND
	get_turn_duelist_var
	cp 4
	ccf
	ret nc

; list out all the hand cards and remove
; wAITrainerCardToPlay from list.Then find any duplicate cards.
	call CreateHandCardList
	ld hl, wDuelTempList
	ld a, [wAITrainerCardToPlay]
	call FindAndRemoveCardFromList
; if duplicates are not found, return no carry.
	call FindDuplicateCards
	ret nc

; store the first duplicate card and remove it from the list.
; run duplicate check again.
	ld [wce1a], a
	ld hl, wDuelTempList
	call FindAndRemoveCardFromList
; if duplicates are not found, return no carry.
	call FindDuplicateCards
	ret nc

; store the second duplicate card and return carry.
	ld [wce1b], a
	ret

.imakuni
; has a 2 in 10 chance of not skipping.
	ld a, 10
	call Random
	cp 2
	ret nc

; skip if number of cards in hand < 3.
	ld a, DUELVARS_NUMBER_OF_CARDS_IN_HAND
	get_turn_duelist_var
	cp 3
	ccf
	ret nc

; shuffle hand cards
	call CreateHandCardList
	ld hl, wDuelTempList
	call ShuffleCards

; go through each card and find
; cards that are different from wAITrainerCardToPlay.
; if found, add those cards to wce1a and wce1a+1.
	ld a, [wAITrainerCardToPlay]
	ld b, a
	ld c, 2
	ld de, wce1a

.loop
	ld a, [hli]
	cp $ff
	ret z ; return no carry if there are no more cards in the list (previous hand check makes that impossible)
	cp b
	jr z, .loop
	ld [de], a
	inc de
	dec c
	jr nz, .loop

; two cards were found, return carry.
	scf
	ret




; this function is identical to AIPlay_Pokeball.
AIPlay_Recycle:
	ld a, [wAITrainerCardToPlay]
	ldh [hTempCardIndex_ff9f], a
	ldtx de, TrainerCardSuccessCheckText
	call TossCoin
	jr nc, .tails
	ld a, [wAITrainerCardParameter]
	ldh [hTemp_ffa0], a
	jr .play_card
.tails
	ld a, $ff
	ldh [hTemp_ffa0], a
.play_card
	ld a, OPPACTION_EXECUTE_TRAINER_EFFECTS
	bank1call AIMakeDecision
	ret


; AI uses Recycle on a discarded Trainer when not using one of decks with a given
; priority list, which includes Ken's Fire Charge deck and Robert's Ghost Deck.
AIDecide_Recycle:
; no use checking if no cards in Discard Pile
	call CreateDiscardPileCardList
	ccf
	ret nc

	ld hl, wce08
	ld a, $ff
	ld [hli], a
	ld [hli], a
	ld [hli], a
	ld [hli], a
	ld [hl], a

; handle Ghost deck differently
	ld hl, wDuelTempList
	ld a, [wOpponentDeckID]
	cp FIRE_CHARGE_DECK_ID
	jr z, .fire_charge_search_loop
	cp GHOST_DECK_ID
	jr z, .ghost_search_loop

.trainer_search_loop
	ld a, [hli]
	cp $ff
	ret z ; return no carry if there are no Trainer cards in the discard pile.
	ld b, a
	call GetCardTypeFromDeckIndex_SaveDE
	cp TYPE_TRAINER
	jr nz, .trainer_search_loop
	; found a Trainer card
	ld a, b
.set_carry
	scf
	ret

; priority list for Fire Charge deck
.fire_charge_search_loop
	ld a, [hli]
	cp $ff
	jr z, .done

	ld b, a
	call _GetCardIDFromDeckIndex

; double colorless
	cp DOUBLE_COLORLESS_ENERGY
	jr nz, .chansey
	ld a, b
	ld [wce08], a
	jr .fire_charge_search_loop

.chansey
	cp CHANSEY
	jr nz, .tauros
	ld a, b
	ld [wce08 + 1], a
	jr .fire_charge_search_loop

.tauros
	cp TAUROS
	jr nz, .jigglypuff
	ld a, b
	ld [wce08 + 2], a
	jr .fire_charge_search_loop

.jigglypuff
	cp JIGGLYPUFF_LV12
	jr nz, .fire_charge_search_loop
	ld a, b
	ld [wce08 + 3], a
	jr .fire_charge_search_loop

; loop through wce08 and set carry
; on the first that was found in Discard Pile.
; if none were found, return no carry.
.done
	ld hl, wce08
	ld b, 5
.loop_found
	ld a, [hli]
	cp $ff
	jr nz, .set_carry
	dec b
	jr nz, .loop_found
	ret

; priority list for Ghost deck
.ghost_search_loop
	ld a, [hli]
	cp $ff
	jr z, .done

	ld b, a
	call _GetCardIDFromDeckIndex

; gastly2
	cp GASTLY_LV17
	jr nz, .gastly1
	ld a, b
	ld [wce08], a
	jr .ghost_search_loop

.gastly1
	cp GASTLY_LV8
	jr nz, .zubat
	ld a, b
	ld [wce08 + 1], a
	jr .ghost_search_loop

.zubat
	cp ZUBAT
	jr nz, .ditto
	ld a, b
	ld [wce08 + 2], a
	jr .ghost_search_loop

.ditto
	cp DITTO
	jr nz, .meowth
	ld a, b
	ld [wce08 + 3], a
	jr .ghost_search_loop

.meowth
	cp MEOWTH_LV15
	jr nz, .ghost_search_loop
	ld a, b
	ld [wce08 + 4], a
	jr .ghost_search_loop




AIPlay_Lass:
	ld a, [wCurrentAIFlags]
	or AI_FLAG_MODIFIED_HAND
	ld [wCurrentAIFlags], a
	ld a, [wAITrainerCardToPlay]
	ldh [hTempCardIndex_ff9f], a
	ld a, OPPACTION_EXECUTE_TRAINER_EFFECTS
	bank1call AIMakeDecision
	ret


AIDecide_Lass:
; skip if player has less than 7 cards in hand
	ld a, DUELVARS_NUMBER_OF_CARDS_IN_HAND
	call GetNonTurnDuelistVariable
	cp 7
	ccf
	ret nc

; look for Trainer cards in hand (except for Lass)
; if any is found, return no carry.
; otherwise, return carry.
	call CreateHandCardList
	ld hl, wDuelTempList
.loop
	ld a, [hli]
	cp $ff
	scf
	ret z
	ld b, a
	call LoadCardDataToBuffer1_FromDeckIndex
	cp LASS
	jr z, .loop
	ld a, [wLoadedCard1Type]
	cp TYPE_TRAINER
	jr nz, .loop
	ret ; nc




; this function is identical to AIPlay_ComputerSearch.
AIPlay_ItemFinder:
	ld a, [wCurrentAIFlags]
	or AI_FLAG_MODIFIED_HAND
	ld [wCurrentAIFlags], a
	ld a, [wAITrainerCardToPlay]
	ldh [hTempCardIndex_ff9f], a
	ld hl, wAITrainerCardParameter
	ld a, [hli]
	ldh [hTempList + 2], a ; deck search target
	ld a, [hli] ; wce1a
	ldh [hTempList], a     ; hand discard 1
	ld a, [hl]  ; wce1b
	ldh [hTempList + 1], a ; hand discard 2
	ld a, OPPACTION_EXECUTE_TRAINER_EFFECTS
	bank1call AIMakeDecision
	ret


; all AI opponents other than Stephanie will use Item Finder on the first Trainer card
; in their discard pile that isn't another Item Finder but will refuse to play the card
; unless they have 2 duplicate cards in their hand to discard for the cost.
; Stephanie's Strange Power deck will only use Item Finder on a discarded Energy Removal
; and also refuses to discard a duplicate Mr. Mime or Pokémon Trader card from her hand.
AIDecide_ItemFinder:
; can't play Item Finder if there are no Trainer cards in the AI's discard pile.
	farcall CreateTrainerCardListFromDiscardPile
	ccf
	ret nc

	ld hl, wDuelTempList
; switch to a custom subroutine if the NPC opponent is using the Strange Power deck.
	ld a, [wOpponentDeckID]
	cp STRANGE_POWER_DECK_ID
	jr z, .loop_discard_pile_strange_power

; choose the first Trainer card in the discard pile, other than Item Finder.
.loop_discard_pile
	ld a, [hli]
	cp $ff
	ret z ; return no carry if there are no more cards in the list
	ld b, a
	call _GetCardIDFromDeckIndex
	cp ITEM_FINDER
	jr z, .loop_discard_pile
; found, store this deck index
	ld a, b
	ld [wce06], a

; choose cards to discard from hand.
	call CreateHandCardList
.choose_discard
	ld hl, wDuelTempList

; do not discard wAITrainerCardToPlay
	ld a, [wAITrainerCardToPlay]
	call FindAndRemoveCardFromList
; find any duplicates, if not found, return no carry.
	call FindDuplicateCards
	ret nc

; store the duplicate found in wce1a and
; remove it from the hand list.
	ld [wce1a], a
	ld hl, wDuelTempList
	call FindAndRemoveCardFromList
; find duplicates again, if not found, return no carry.
	call FindDuplicateCards
	ret nc

; store the duplicate found in wce1b.
; output the card to be recovered from the Discard Pile.
	ld [wce1b], a
	ld a, [wce06]
	ret ; carry set

; look for Energy Removal in Discard Pile
.loop_discard_pile_strange_power
	ld a, [hli]
	cp $ff
	ret z ; return no carry if there are no more cards in the list
	ld b, a
	call _GetCardIDFromDeckIndex
	cp ENERGY_REMOVAL
	jr nz, .loop_discard_pile_strange_power
; found, store this deck index
	ld a, b
	ld [wce06], a

; before looking for cards to discard in hand,
; remove any Mr Mime and Pokemon Trader cards.
; this way these are guaranteed to not be discarded.
	call CreateHandCardList
	ld hl, wDuelTempList
.loop_hand_strange_power
	ld a, [hli]
	cp $ff
	jr z, .choose_discard
	call _GetCardIDFromDeckIndex
	cp MR_MIME
	jr nz, .pkmn_trader
	call RemoveCardFromList
	jr .loop_hand_strange_power
.pkmn_trader
	cp POKEMON_TRADER
	jr nz, .loop_hand_strange_power
	call RemoveCardFromList
	jr .loop_hand_strange_power




; Imakuni? uses 'AIPlay_TrainerCard_NoVars'


; only sets carry if Active card is not confused.
AIDecide_Imakuni:
	ld a, DUELVARS_ARENA_CARD_STATUS
	get_turn_duelist_var
	and CNF_SLP_PRZ
	cp CONFUSED
	ret z ; return no carry if the Active Pokémon is already Confused
	scf
	ret




AIPlay_Gambler:
	ld a, [wCurrentAIFlags]
	or AI_FLAG_MODIFIED_HAND
	ld [wCurrentAIFlags], a
	ld a, [wOpponentDeckID]
	cp IMAKUNI_DECK_ID
	jr z, .asm_2186a
	ld hl, wRNG1
	ld a, [hli]
	ld [wce06], a
	ld a, [hli]
	ld [wce08], a
	ld a, [hl]
	ld [wce0f], a
	ld a, $50
	ld [hld], a
	ld [hld], a
	ld [hl], a
	ld a, [wAITrainerCardToPlay]
	ldh [hTempCardIndex_ff9f], a
	ld a, OPPACTION_EXECUTE_TRAINER_EFFECTS
	bank1call AIMakeDecision
	ld hl, wRNG1
	ld a, [wce06]
	ld [hli], a
	ld a, [wce08]
	ld [hli], a
	ld a, [wce0f]
	ld [hl], a
	ret
.asm_2186a
	ld a, [wAITrainerCardToPlay]
	ldh [hTempCardIndex_ff9f], a
	ld a, OPPACTION_EXECUTE_TRAINER_EFFECTS
	bank1call AIMakeDecision
	ret


; checks whether to play Gambler.
; aside from Imakuni?, all other opponents only
; play this card if Player is running MewtwoLv53-only deck.
AIDecide_Gambler:
; Imakuni? has his own routine
	ld a, [wOpponentDeckID]
	cp IMAKUNI_DECK_ID
	jr z, .imakuni

; check if flag is set for Player using MewtwoLv53 only deck
	ld a, [wAIBarrierFlagCounter]
	and AI_MEWTWO_MILL
	ret z ; return no carry if the Player isn't using a Mewtwo Barrier deck

; set carry if number of cards in deck <= 4.
; this is done to counteract the deck out strategy
; of MewtwoLv53 deck, by replenishing the deck with hand cards.
	ld a, DUELVARS_NUMBER_OF_CARDS_NOT_IN_DECK
	get_turn_duelist_var
	cp DECK_SIZE - 4
	ccf
	ret

.imakuni
; has a 2 in 10 chance of returning carry
	ld a, 10
	call Random
	cp 2
	ret




; Revive uses 'AIPlay_TrainerCard_OneVar'


; all AI opponents other than Chris will use Revive on the Basic Pokémon
; with the highest HP in their discard pile, but only if it has
; at least 50 HP and only if there are fewer than 3 Benched Pokémon.
; Chris's Muscles for Brains deck will try to use this card on specific Pokémon.
AIDecide_Revive:
; skip if no cards in Discard Pile
	call CreateDiscardPileCardList
	ccf
	ret nc

; skip if number of Pokemon cards in Play Area >= 4
	ld a, DUELVARS_NUMBER_OF_POKEMON_IN_PLAY_AREA
	get_turn_duelist_var
	cp 4
	ret nc ; return if the number of play area Pokémon >= 4

	ld hl, wDuelTempList
; switch to a custom subroutine if the NPC opponent is using the Muscles for Brains deck.
	ld a, [wOpponentDeckID]
	cp MUSCLES_FOR_BRAINS_DECK_ID
	jr z, .muscles_for_brains_loop

; reset wram variables
	xor a
	ld [wce06], a
	ld a, $ff
	ld [wce08], a

; find the Basic Pokémon with the highest HP in the discard pile
.loop_discard_pile
	ld a, [hli]
	cp $ff
	jr z, .done ; end loop if there are no more discard pile cards to check

	ld b, a
	call CheckDeckIndexForBasicPokemon
	jr nc, .loop_discard_pile ; skip this card if it's not a Basic Pokémon

; compare this HP with one stored
	ld a, [wLoadedCard2HP]
	push hl
	ld hl, wce06
	cp [hl]
	pop hl
	jr c, .loop_discard_pile
; if higher, store this card's HP and deck index
	ld [wce06], a
	ld a, b
	ld [wce08], a
	jr .loop_discard_pile

.done
; if highest HP found < 50, return no carry.
; otherwise, return carry.
	ld a, [wce06]
	cp 50
	ld a, [wce08]
	ccf
	ret

; look in Discard Pile for specific cards.
.muscles_for_brains_loop
	ld a, [hli]
	cp $ff
	ret z ; return no carry if there are no more discard pile cards to check
	ld b, a
	call _GetCardIDFromDeckIndex
	cp HITMONCHAN
	jr z, .set_carry
	cp HITMONLEE
	jr z, .set_carry
	cp TAUROS
	jr z, .set_carry
	cp KANGASKHAN
	jr nz, .muscles_for_brains_loop

.set_carry
	ld a, b
	scf
	ret




; Pokemon Flute uses 'AIPlay_TrainerCard_OneVar'


AIDecide_PokemonFlute:
; if player has no Discard Pile, skip.
	rst SwapTurn
	call CreateDiscardPileCardList
	ccf
	jr nc, .done

; if player's Play Area is already full, skip.
	ld a, DUELVARS_NUMBER_OF_POKEMON_IN_PLAY_AREA
	get_turn_duelist_var
	cp MAX_PLAY_AREA_POKEMON
	jr nc, .done

	ld a, [wOpponentDeckID]
	cp IMAKUNI_DECK_ID
	jr z, .imakuni

	ld a, $ff
	ld [wce06], a
	ld [wce08], a

; find Basic stage Pokemon with lowest HP in Discard Pile
	ld hl, wDuelTempList
.loop_1
	ld a, [hli]
	cp $ff
	jr z, .check_lowest_hp

	ld b, a
	call CheckDeckIndexForBasicPokemon
	jr nc, .loop_1 ; skip this card if it's not a Basic Pokémon

; compare this HP with one stored
	ld a, [wLoadedCard2HP]
	push hl
	ld hl, wce06
	cp [hl]
	pop hl
	jr nc, .loop_1
; if lower, store this one
	ld [wce06], a
	ld a, b
	ld [wce08], a
	jr .loop_1

.check_lowest_hp
; if lowest HP found < 50, return carry
	ld a, [wce06]
	cp 50
	ld a, [wce08]
.done
	jp SwapTurn

.imakuni
; has 2 in 10 chance of not skipping
	ld a, 10
	call Random
	cp 2
	jr nc, .done

; look for any Basic Pokemon card
	ld hl, wDuelTempList
.loop_2
	ld a, [hli]
	cp $ff
	jr z, .done
	ld b, a
	call CheckDeckIndexForBasicPokemon
	jr nc, .loop_2

; a Basic stage Pokemon was found, return carry
	rst SwapTurn
	ld a, b
	ret ; carry set




; Clefairy Doll and Mysterious Fossil use 'AIPlay_TrainerCard_NoVars'


; AI logic for playing Clefairy Doll
AIDecide_ClefairyDollOrMysteriousFossil:
; if has max number of Play Area Pokemon, skip
	ld a, DUELVARS_NUMBER_OF_POKEMON_IN_PLAY_AREA
	get_turn_duelist_var
	ld b, a
	cp MAX_PLAY_AREA_POKEMON
	ret nc

; if the Arena card is Wigglytuff, return carry
	ld a, DUELVARS_ARENA_CARD
	get_turn_duelist_var
	call _GetCardIDFromDeckIndex
	cp WIGGLYTUFF
	scf
	ret z

; if number of Play Area Pokemon >= 4, return no carry
	ld a, b
	cp 4
	ret




; this function is identical to AIPlay_Recycle.
AIPlay_Pokeball:
	ld a, [wAITrainerCardToPlay]
	ldh [hTempCardIndex_ff9f], a
	ldtx de, TrainerCardSuccessCheckText
	call TossCoin
	jr nc, .tails
	ld a, [wAITrainerCardParameter]
	ldh [hTemp_ffa0], a
	jr .play_card
.tails
	ld a, $ff
	ldh [hTemp_ffa0], a
.play_card
	ld a, OPPACTION_EXECUTE_TRAINER_EFFECTS
	bank1call AIMakeDecision
	ret


; every deck that currently contains Poké Ball has its own priority list.
; if Poké Ball is in a deck that isn't listed, then the AI will
; look for a Basic Pokémon if it has fewer than 3 Pokémon in play,
; then a card that evolves from a play area Pokémon, then any Pokémon.
AIDecide_Pokeball:
; go to the routines associated with deck ID
	ld a, [wOpponentDeckID]
	cp FIRE_CHARGE_DECK_ID
	jr z, .fire_charge
	cp HARD_POKEMON_DECK_ID
	jr z, .hard_pokemon
	cp PIKACHU_DECK_ID
	jr z, .pikachu
	cp ETCETERA_DECK_ID
	jp z, .etcetera
	cp LOVELY_NIDORAN_DECK_ID
	jp z, .lovely_nidoran

; can't play Poké Ball if there are no cards left in the AI's deck.
	call CreateDeckCardList
	ccf
	ret nc

; skip looking for a Basic Pokémon if the AI already has at least 3 Pokémon in play.
	ld a, DUELVARS_NUMBER_OF_POKEMON_IN_PLAY_AREA
	get_turn_duelist_var
	ld c, a
	ld e, PLAY_AREA_ARENA
	cp 3
	jr nc, .find_useful_evolution

; if the AI has fewer than 3 Pokémon in the play area, then search for a Basic Pokémon.
.find_first_basic_pkmn
	ld hl, wDuelTempList
.basic_pkmn_search_loop
	ld a, [hli]
	cp $ff
	jr z, .find_useful_evolution ; if no Basic Pokémon, then look for an Evolution card
	ld b, a
	call CheckDeckIndexForBasicPokemon
	jr nc, .basic_pkmn_search_loop
	ld a, b
	ret ; carry set

; otherwise, search for a card that evolves from one of the AI's play area Pokémon.
.find_useful_evolution
	ld hl, wDuelTempList
.evolution_search_loop
	ld a, [hli]
	cp $ff
	jr z, .check_next_pkmn
	ld d, a
	push hl
	call CheckIfCanEvolveInto
	pop hl
	jr c, .evolution_search_loop
	ld a, d
	scf
	ret
.check_next_pkmn
	inc e
	dec c
	jr nz, .find_useful_evolution
;	fallthrough

; if no useful Evolution card was found, then search for any Pokémon in the deck.
.find_first_pkmn
	ld hl, wDuelTempList
.pkmn_search_loop
	ld a, [hli]
	cp $ff
	ret z ; return no carry if there aren't any Pokémon in the deck
	ld b, a
	call GetCardTypeFromDeckIndex_SaveDE
	cp TYPE_ENERGY
	jr nc, .pkmn_search_loop
	ld a, b
	ret ; carry set

; this deck runs a deck check for specific
; card IDs in order of decreasing priority
.fire_charge
	ld e, CHANSEY
	ld a, CARD_LOCATION_DECK
	call LookForCardIDInLocation_Bank8
	ret c
	ld e, TAUROS
	ld a, CARD_LOCATION_DECK
	call LookForCardIDInLocation_Bank8
	ret c
	ld e, JIGGLYPUFF_LV12
	ld a, CARD_LOCATION_DECK
	jp LookForCardIDInLocation_Bank8

; this deck runs a deck check for specific
; card IDs in order of decreasing priority
.hard_pokemon
	ld e, RHYHORN
	ld a, CARD_LOCATION_DECK
	call LookForCardIDInLocation_Bank8
	ret c
	ld e, RHYDON
	ld a, CARD_LOCATION_DECK
	call LookForCardIDInLocation_Bank8
	ret c
	ld e, ONIX
	ld a, CARD_LOCATION_DECK
	jp LookForCardIDInLocation_Bank8

; this deck runs a deck check for specific
; card IDs in order of decreasing priority
.pikachu
	ld e, PIKACHU_LV14
	ld a, CARD_LOCATION_DECK
	call LookForCardIDInLocation_Bank8
	ret c
	ld e, PIKACHU_LV16
	ld a, CARD_LOCATION_DECK
	call LookForCardIDInLocation_Bank8
	ret c
	ld e, PIKACHU_ALT_LV16
	ld a, CARD_LOCATION_DECK
	call LookForCardIDInLocation_Bank8
	ret c
	ld e, PIKACHU_LV12
	ld a, CARD_LOCATION_DECK
	call LookForCardIDInLocation_Bank8
	ret c
	ld e, FLYING_PIKACHU
	ld a, CARD_LOCATION_DECK
	jp LookForCardIDInLocation_Bank8

; this deck runs a deck check for specific
; card IDs in order of decreasing priority
; given a specific energy card in hand.
; also it avoids redundancy, so if it already
; has that card ID in the hand, it is skipped.
.etcetera
; fire
	ld a, FIRE_ENERGY
	call LookForCardIDInHandList_Bank8
	jr nc, .lightning
	ld a, CHARMANDER
	call LookForCardIDInHandList_Bank8
	jr c, .lightning
	ld a, MAGMAR_LV31
	call LookForCardIDInHandList_Bank8
	jr c, .lightning
	ld e, CHARMANDER
	ld a, CARD_LOCATION_DECK
	call LookForCardIDInLocation_Bank8
	ret c
	ld e, MAGMAR_LV31
	ld a, CARD_LOCATION_DECK
	call LookForCardIDInLocation_Bank8
	ret c

.lightning
	ld a, LIGHTNING_ENERGY
	call LookForCardIDInHandList_Bank8
	jr nc, .fighting
	ld a, PIKACHU_LV12
	call LookForCardIDInHandList_Bank8
	jr c, .fighting
	ld a, MAGNEMITE_LV13
	call LookForCardIDInHandList_Bank8
	jr c, .fighting
	ld e, PIKACHU_LV12
	ld a, CARD_LOCATION_DECK
	call LookForCardIDInLocation_Bank8
	ret c
	ld e, MAGNEMITE_LV13
	ld a, CARD_LOCATION_DECK
	call LookForCardIDInLocation_Bank8
	ret c

.fighting
	ld a, FIGHTING_ENERGY
	call LookForCardIDInHandList_Bank8
	jr nc, .psychic
	ld a, DIGLETT
	call LookForCardIDInHandList_Bank8
	jr c, .psychic
	ld a, MACHOP
	call LookForCardIDInHandList_Bank8
	jr c, .psychic
	ld e, DIGLETT
	ld a, CARD_LOCATION_DECK
	call LookForCardIDInLocation_Bank8
	ret c
	ld e, MACHOP
	ld a, CARD_LOCATION_DECK
	call LookForCardIDInLocation_Bank8
	ret c

.psychic
	ld a, PSYCHIC_ENERGY
	call LookForCardIDInHandList_Bank8
	ret nc
	ld a, GASTLY_LV8
	call LookForCardIDInHandList_Bank8
	jr c, .done_etcetera
	ld a, JYNX
	call LookForCardIDInHandList_Bank8
	jr c, .done_etcetera
	ld e, GASTLY_LV8
	ld a, CARD_LOCATION_DECK
	call LookForCardIDInLocation_Bank8
	ret c
	ld e, JYNX
	ld a, CARD_LOCATION_DECK
	call LookForCardIDInLocation_Bank8
	ret c
.done_etcetera
	or a
	ret

; this deck looks for card evolutions if
; its pre-evolution is in hand or in Play Area.
; if none of these are found, it looks for pre-evolutions
; of cards it has in hand.
; it does this for both the NidoranM (first)
; and NidoranF (second) families.
.lovely_nidoran
	ld b, NIDORANM
	ld a, NIDORINO
	call LookForCardIDInDeck_GivenCardIDInHandAndPlayArea
	ret c
	ld b, NIDORINO
	ld a, NIDOKING
	call LookForCardIDInDeck_GivenCardIDInHandAndPlayArea
	ret c
	ld a, NIDORANM
	ld b, NIDORINO
	call LookForCardIDInDeck_GivenCardIDInHand
	ret c
	ld a, NIDORINO
	ld b, NIDOKING
	call LookForCardIDInDeck_GivenCardIDInHand
	ret c
	ld b, NIDORANF
	ld a, NIDORINA
	call LookForCardIDInDeck_GivenCardIDInHandAndPlayArea
	ret c
	ld b, NIDORINA
	ld a, NIDOQUEEN
	call LookForCardIDInDeck_GivenCardIDInHandAndPlayArea
	ret c
	ld a, NIDORANF
	ld b, NIDORINA
	call LookForCardIDInDeck_GivenCardIDInHand
	ret c
	ld a, NIDORINA
	ld b, NIDOQUEEN
	jp LookForCardIDInDeck_GivenCardIDInHand




; this function is identical to AIPlay_ItemFinder.
AIPlay_ComputerSearch:
	ld a, [wCurrentAIFlags]
	or AI_FLAG_MODIFIED_HAND
	ld [wCurrentAIFlags], a
	ld a, [wAITrainerCardToPlay]
	ldh [hTempCardIndex_ff9f], a
	ld hl, wAITrainerCardParameter
	ld a, [hli]
	ldh [hTempList + 2], a ; deck search target
	ld a, [hli] ; wce1a
	ldh [hTempList], a     ; hand discard 1
	ld a, [hl]  ; wce1b
	ldh [hTempList + 1], a ; hand discard 2
	ld a, OPPACTION_EXECUTE_TRAINER_EFFECTS
	bank1call AIMakeDecision
	ret


; checks what Deck ID AI is playing and handle
; them in their own routine.
AIDecide_ComputerSearch:
; skip if number of cards in hand < 3
	ld a, DUELVARS_NUMBER_OF_CARDS_IN_HAND
	get_turn_duelist_var
	cp 3
	jr c, .no_carry

	ld a, [wOpponentDeckID]
	cp ROCK_CRUSHER_DECK_ID
	jr z, AIDecide_ComputerSearch_RockCrusher
	cp WONDERS_OF_SCIENCE_DECK_ID
	jp z, AIDecide_ComputerSearch_WondersOfScience
	cp FIRE_CHARGE_DECK_ID
	jp z, AIDecide_ComputerSearch_FireCharge
	cp ANGER_DECK_ID
	jp z, AIDecide_ComputerSearch_Anger

.no_carry
	or a
	ret


AIDecide_ComputerSearch_RockCrusher:
; if number of cards in hand is equal to 3,
; target Professor Oak in deck
	ld a, DUELVARS_NUMBER_OF_CARDS_IN_HAND
	get_turn_duelist_var
	cp 3
	jr nz, .graveler

	ld e, PROFESSOR_OAK
	ld a, CARD_LOCATION_DECK
	call LookForCardIDInLocation_Bank8
	ret nc

	ld [wce06], a
	ld hl, wce1a
	ld a, $ff
	ld [hli], a ; [wce1a] = $ff
	ld [hl], a  ; [wce1b] = $ff

	call CreateHandCardList
	ld hl, wDuelTempList
	ld de, wce1a
.loop_hand_1
	ld a, [hli]
	cp $ff
	jr z, .check_discard_cards

	ld c, a
	call _GetCardIDFromDeckIndex

; if any of the following cards are in the hand,
; return no carry.
	cp PROFESSOR_OAK
	ret z ; return no carry if it's a Professor Oak
	cp FIGHTING_ENERGY
	ret z ; return no carry if it's a Fighting Energy
	cp DOUBLE_COLORLESS_ENERGY
	ret z ; return no carry if it's a Double Colorless Energy
	cp DIGLETT
	ret z ; return no carry if it's a Diglett
	cp GEODUDE
	ret z ; return no carry if it's a Geodude
	cp ONIX
	ret z ; return no carry if it's a Onix
	cp RHYHORN
	ret z ; return no carry if it's a Rhyhorn

; if it's same as wAITrainerCardToPlay, skip this card.
	ld a, [wAITrainerCardToPlay]
	cp c
	jr z, .loop_hand_1

; store this card index in memory
	ld [de], a
	inc de
	jr .loop_hand_1

.check_discard_cards
; check if two cards were found
; if so, output in a the deck index
; of Professor Oak card found in deck and set carry.
	ld a, [wce1b]
	cp $ff
	ret z ; return no carry if a deck index wasn't stored
	ld a, [wce06]
	scf
	ret

; more than 3 cards in hand, so look for
; specific evolution cards.

; checks if there is a Graveler card in the deck to target.
; if so, check if there's Geodude in hand or Play Area,
; and if there's no Graveler card in hand, proceed.
; also removes Geodude from hand list so that it is not discarded.
.graveler
	ld e, GRAVELER
	ld a, CARD_LOCATION_DECK
	call LookForCardIDInLocation_Bank8
	jr nc, .golem
	ld [wce06], a
	ld a, GEODUDE
	call LookForCardIDInHandAndPlayArea
	jr nc, .golem
	ld a, GRAVELER
	call LookForCardIDInHandList_Bank8
	jr c, .golem
	call CreateHandCardList
	ld hl, wDuelTempList
	ld c, GEODUDE
	farcall RemoveCardIDInList
	jr .find_discard_cards_2

; checks if there is a Golem card in the deck to target.
; if so, check if there's Graveler in Play Area,
; and if there's no Golem card in hand, proceed.
.golem
	ld e, GOLEM
	ld a, CARD_LOCATION_DECK
	call LookForCardIDInLocation_Bank8
	jr nc, .dugtrio
	ld [wce06], a
	ld a, GRAVELER
	call LookForCardIDInPlayArea_Bank8
	jr nc, .dugtrio
	ld a, GOLEM
	call LookForCardIDInHandList_Bank8
	jr c, .dugtrio
	call CreateHandCardList
	ld hl, wDuelTempList
	jr .find_discard_cards_2

; checks if there is a Dugtrio card in the deck to target.
; if so, check if there's Diglett in Play Area,
; and if there's no Dugtrio card in hand, proceed.
.dugtrio
	ld e, DUGTRIO
	ld a, CARD_LOCATION_DECK
	call LookForCardIDInLocation_Bank8
	ret nc
	ld [wce06], a
	ld a, DIGLETT
	call LookForCardIDInPlayArea_Bank8
	ret nc
	ld a, DUGTRIO
	call LookForCardIDInHandList_Bank8
	ccf
	ret nc
	call CreateHandCardList
	ld hl, wDuelTempList
	; fallthrough

.find_discard_cards_2
	ld a, $ff
	ld bc, wce1b
	ld [bc], a
	dec bc
	ld [bc], a
	ld d, $00 ; start considering Trainer cards only

; stores wAITrainerCardToPlay in e so that
; all routines ignore it for the discard effects.
	ld a, [wAITrainerCardToPlay]
	ld e, a

; this loop will store in wce1a cards to discard from hand.
; at the start it will only consider Trainer cards,
; then if there are still needed to discard,
; move on to Pokemon cards, and finally to Energy cards.
.loop_hand_2
	call RemoveFromListDifferentCardOfGivenType
	jr c, .found
	inc d ; move on to next type (Pokemon, then Energy)
	ld a, $03
	cp d
	ret z ; return no carry if there are no more card types to consider
	jr .loop_hand_2
.found
; store this card in memory,
; and if there's still one more card to search for,
; jump back into the loop.
	ld [bc], a
	inc bc
	ld a, [wce1b]
	cp $ff
	jr z, .loop_hand_2

; output in a Computer Search target and set carry.
	ld a, [wce06]
	scf
	ret


AIDecide_ComputerSearch_WondersOfScience:
; if number of cards in hand < 5, target Professor Oak in deck
	ld a, DUELVARS_NUMBER_OF_CARDS_IN_HAND
	get_turn_duelist_var
	cp 5
	jr nc, .look_in_hand

; target Professor Oak for Computer Search
	ld e, PROFESSOR_OAK
	ld a, CARD_LOCATION_DECK
	call LookForCardIDInLocation_Bank8
	jr nc, .look_in_hand
	jr CheckHandForTwoTrainerCards

; Professor Oak not in deck, move on to
; look for other cards instead.
; if Grimer or Muk are not in hand,
; check whether to use Computer Search on them.
.look_in_hand
	ld a, GRIMER
	call LookForCardIDInHandAndPlayArea
	jr nc, .target_grimer
	ld a, MUK
	call LookForCardIDInHandAndPlayArea
	jr nc, .target_muk
	or a
	ret

; first check Grimer
; if in deck, check cards to discard.
.target_grimer
	ld e, GRIMER
	ld a, CARD_LOCATION_DECK
	call LookForCardIDInLocation_Bank8
	ret nc
	jr CheckHandForTwoTrainerCards

; first check Muk
; if in deck, check cards to discard.
.target_muk
	ld e, MUK
	ld a, CARD_LOCATION_DECK
	call LookForCardIDInLocation_Bank8
	ret nc
	jr CheckHandForTwoTrainerCards


AIDecide_ComputerSearch_FireCharge:
; pick target card in deck from highest to lowest priority.
; if not found in hand, go to corresponding branch.
	ld a, CHANSEY
	call LookForCardIDInHandList_Bank8
	jr nc, .chansey
	ld a, TAUROS
	call LookForCardIDInHandList_Bank8
	jr nc, .tauros
	ld a, JIGGLYPUFF_LV12
	call LookForCardIDInHandList_Bank8
	jr nc, .jigglypuff
	or a
	ret

; for each card targeted, check if it's in deck and,
; if not, then return no carry.
; else, look for cards to discard.
.chansey
	ld e, CHANSEY
	ld a, CARD_LOCATION_DECK
	call LookForCardIDInLocation_Bank8
	ret nc
	jr CheckHandForTwoTrainerCards
.tauros
	ld e, TAUROS
	ld a, CARD_LOCATION_DECK
	call LookForCardIDInLocation_Bank8
	ret nc
	jr CheckHandForTwoTrainerCards
.jigglypuff
	ld e, JIGGLYPUFF_LV12
	ld a, CARD_LOCATION_DECK
	call LookForCardIDInLocation_Bank8
	ret nc
;	fallthrough

; only discard Trainer cards from hand.
; if there are less than 2 Trainer cards to discard,
; then return with no carry.
; else, store the cards to discard and the
; target card deck index, and return carry.
CheckHandForTwoTrainerCards:
	ld [wce06], a
	call CreateHandCardList
	ld hl, wDuelTempList
	ld d, $00 ; first consider Trainer cards

; ignore wAITrainerCardToPlay for the discard effects.
	ld a, [wAITrainerCardToPlay]
	ld e, a
	call RemoveFromListDifferentCardOfGivenType
	ret nc
	ld [wce1a], a
	call RemoveFromListDifferentCardOfGivenType
	ret nc
	ld [wce1b], a
	ld a, [wce06]
	scf
	ret


AIDecide_ComputerSearch_Anger:
; for each of the following cards,
; first run a check if there's a pre-evolution in
; Play Area or in the hand. If there is, choose it as target.
; otherwise, check if the evolution card is in
; hand and if so, choose it as target instead.
	ld b, RATTATA
	ld a, RATICATE
	call LookForCardIDInDeck_GivenCardIDInHandAndPlayArea
	jr c, CheckHandForTwoTrainerCards
	ld a, RATTATA
	ld b, RATICATE
	call LookForCardIDInDeck_GivenCardIDInHand
	jr c, CheckHandForTwoTrainerCards
	ld b, GROWLITHE
	ld a, ARCANINE_LV34
	call LookForCardIDInDeck_GivenCardIDInHandAndPlayArea
	jr c, CheckHandForTwoTrainerCards
	ld a, GROWLITHE
	ld b, ARCANINE_LV34
	call LookForCardIDInDeck_GivenCardIDInHand
	jr c, CheckHandForTwoTrainerCards
	ld b, DODUO
	ld a, DODRIO
	call LookForCardIDInDeck_GivenCardIDInHandAndPlayArea
	jr c, CheckHandForTwoTrainerCards
	ld a, DODUO
	ld b, DODRIO
	call LookForCardIDInDeck_GivenCardIDInHand
	jr c, CheckHandForTwoTrainerCards
	ret




; Pokemon Trader uses 'AIPlay_TrainerCard_TwoVars'


AIDecide_PokemonTrader:
; each deck has their own routine for picking
; what Pokemon to look for.
	ld a, [wOpponentDeckID]
	cp LEGENDARY_MOLTRES_DECK_ID
	jr z, AIDecide_PokemonTrader_LegendaryMoltres
	cp LEGENDARY_ARTICUNO_DECK_ID
	jr z, AIDecide_PokemonTrader_LegendaryArticuno
	cp LEGENDARY_DRAGONITE_DECK_ID
	jp z, AIDecide_PokemonTrader_LegendaryDragonite
	cp LEGENDARY_RONALD_DECK_ID
	jp z, AIDecide_PokemonTrader_LegendaryRonald
	cp BLISTERING_POKEMON_DECK_ID
	jp z, AIDecide_PokemonTrader_BlisteringPokemon
	cp SOUND_OF_THE_WAVES_DECK_ID
	jp z, AIDecide_PokemonTrader_SoundOfTheWaves
	cp POWER_GENERATOR_DECK_ID
	jp z, AIDecide_PokemonTrader_PowerGenerator
	cp FLOWER_GARDEN_DECK_ID
	jp z, AIDecide_PokemonTrader_FlowerGarden
	cp STRANGE_POWER_DECK_ID
	jp z, AIDecide_PokemonTrader_StrangePower
	cp FLAMETHROWER_DECK_ID
	jp z, AIDecide_PokemonTrader_Flamethrower
	or a
	ret


AIDecide_PokemonTrader_LegendaryMoltres:
; look for MoltresLv37 card in deck to trade with a
; card in hand different from MoltresLv35.
	ld a, MOLTRES_LV37
	ld e, MOLTRES_LV35
	call LookForCardIDToTradeWithDifferentHandCard
	ret nc
; success
	ld [wce1a], a
	ld a, e
	ret ; carry set


AIDecide_PokemonTrader_LegendaryArticuno:
; if has none of these cards in Hand or Play Area, proceed
	ld a, ARTICUNO_LV35
	call LookForCardIDInHandAndPlayArea
	ccf
	ret nc
	ld a, LAPRAS
	call LookForCardIDInHandAndPlayArea
	ccf
	ret nc

; if doesn't have Seel in Hand or Play Area,
; look for it in the deck.
; otherwise, look for Dewgong instead.
	ld a, SEEL
	call LookForCardIDInHandAndPlayArea
	jr c, .dewgong

	ld e, SEEL
	ld a, CARD_LOCATION_DECK
	call LookForCardIDInLocation_Bank8
	jr c, .check_hand

.dewgong
	ld a, DEWGONG
	call LookForCardIDInHandAndPlayArea
	ccf
	ret nc
	ld e, DEWGONG
	ld a, CARD_LOCATION_DECK
	call LookForCardIDInLocation_Bank8
	ret nc

; a Seel or Dewgong was found in deck,
; check hand for card to trade for
.check_hand
	ld [wce1a], a
	ld a, CHANSEY
	call CheckIfHasCardIDInHand
	ret c ; found Chansey
	ld a, DITTO
	call CheckIfHasCardIDInHand
	ret c ; found Ditto
	ld a, ARTICUNO_LV37
	jp CheckIfHasCardIDInHand


AIDecide_PokemonTrader_LegendaryDragonite:
; if has less than 5 cards of energy
; and of Pokemon in hand/Play Area,
; target a Kangaskhan in deck.
	farcall CountOppEnergyCardsInHandAndAttached
	cp 5
	jr c, .kangaskhan
	call CountPokemonCardsInHandAndInPlayArea
	cp 5
	jr c, .kangaskhan
	; total number of energy cards >= 5
	; total number of Pokemon cards >= 5

; for each of the following cards,
; first run a check if there's a pre-evolution in
; Play Area or in the hand. If there is, choose it as target.
; otherwise, check if the evolution card is in
; hand and if so, choose it as target instead.
	ld b, MAGIKARP
	ld a, GYARADOS
	call LookForCardIDInDeck_GivenCardIDInHandAndPlayArea
	jr c, .choose_hand
	ld a, MAGIKARP
	ld b, GYARADOS
	call LookForCardIDInDeck_GivenCardIDInHand
	jr c, .choose_hand
	ld b, DRATINI
	ld a, DRAGONAIR
	call LookForCardIDInDeck_GivenCardIDInHandAndPlayArea
	jr c, .choose_hand
	ld b, DRAGONAIR
	ld a, DRAGONITE_LV41
	call LookForCardIDInDeck_GivenCardIDInHandAndPlayArea
	jr c, .choose_hand
	ld a, DRATINI
	ld b, DRAGONAIR
	call LookForCardIDInDeck_GivenCardIDInHand
	jr c, .choose_hand
	ld a, DRAGONAIR
	ld b, DRAGONITE_LV41
	call LookForCardIDInDeck_GivenCardIDInHand
	jr c, .choose_hand
	ld b, CHARMANDER
	ld a, CHARMELEON
	call LookForCardIDInDeck_GivenCardIDInHandAndPlayArea
	jr c, .choose_hand
	ld b, CHARMELEON
	ld a, CHARIZARD
	call LookForCardIDInDeck_GivenCardIDInHandAndPlayArea
	jr c, .choose_hand
	ld a, CHARMANDER
	ld b, CHARMELEON
	call LookForCardIDInDeck_GivenCardIDInHand
	jr c, .choose_hand
	ld a, CHARMELEON
	ld b, CHARIZARD
	call LookForCardIDInDeck_GivenCardIDInHand
	jr c, .choose_hand
	ret

.kangaskhan
	ld e, KANGASKHAN
	ld a, CARD_LOCATION_DECK
	call LookForCardIDInLocation_Bank8
	ret nc

; card was found as target in deck,
; look for card in hand to trade with
.choose_hand
	ld [wce1a], a
	ld a, DRAGONAIR
	call CheckIfHasCardIDInHand
	ret c ; found Dragonair
	ld a, CHARMELEON
	call CheckIfHasCardIDInHand
	ret c ; found Charmeleon
	ld a, GYARADOS
	call CheckIfHasCardIDInHand
	ret c ; found Gyarados
	ld a, MAGIKARP
	call CheckIfHasCardIDInHand
	ret c ; found Magikarp
	ld a, CHARMANDER
	call CheckIfHasCardIDInHand
	ret c ; found Charmander
	ld a, DRATINI
	jp CheckIfHasCardIDInHand


AIDecide_PokemonTrader_LegendaryRonald:
; for each of the following cards,
; first run a check if there's a pre-evolution in
; Play Area or in the hand. If there is, choose it as target.
; otherwise, check if the evolution card is in
; hand and if so, choose it as target instead.
	ld b, EEVEE
	ld a, FLAREON_LV22
	call LookForCardIDInDeck_GivenCardIDInHandAndPlayArea
	jr c, .choose_hand
	ld b, EEVEE
	ld a, VAPOREON_LV29
	call LookForCardIDInDeck_GivenCardIDInHandAndPlayArea
	jr c, .choose_hand
	ld b, EEVEE
	ld a, JOLTEON_LV24
	call LookForCardIDInDeck_GivenCardIDInHandAndPlayArea
	jr c, .choose_hand
	ld a, EEVEE
	ld b, FLAREON_LV22
	call LookForCardIDInDeck_GivenCardIDInHand
	jr c, .choose_hand
	ld a, EEVEE
	ld b, VAPOREON_LV29
	call LookForCardIDInDeck_GivenCardIDInHand
	jr c, .choose_hand
	ld a, EEVEE
	ld b, JOLTEON_LV24
	call LookForCardIDInDeck_GivenCardIDInHand
	jr c, .choose_hand
	ld b, DRATINI
	ld a, DRAGONAIR
	call LookForCardIDInDeck_GivenCardIDInHandAndPlayArea
	jr c, .choose_hand
	ld b, DRAGONAIR
	ld a, DRAGONITE_LV41
	call LookForCardIDInDeck_GivenCardIDInHandAndPlayArea
	jr c, .choose_hand
	ld a, DRATINI
	ld b, DRAGONAIR
	call LookForCardIDInDeck_GivenCardIDInHand
	jr c, .choose_hand
	ld a, DRAGONAIR
	ld b, DRAGONITE_LV41
	call LookForCardIDInDeck_GivenCardIDInHand
	ret nc
	; fallthrough

; card was found as target in deck,
; look for card in hand to trade with
.choose_hand
	ld [wce1a], a
	ld a, ZAPDOS_LV68
	call LookForCardIDInHandList_Bank8
	ret c ; found Zapdos
	ld a, ARTICUNO_LV37
	call LookForCardIDInHandList_Bank8
	ret c ; found Articuno
	ld a, MOLTRES_LV37
	jp LookForCardIDInHandList_Bank8


AIDecide_PokemonTrader_BlisteringPokemon:
; for each of the following cards,
; first run a check if there's a pre-evolution in
; Play Area or in the hand. If there is, choose it as target.
; otherwise, check if the evolution card is in
; hand and if so, choose it as target instead.
	ld b, RHYHORN
	ld a, RHYDON
	call LookForCardIDInDeck_GivenCardIDInHandAndPlayArea
	jr c, .find_duplicates
	ld a, RHYHORN
	ld b, RHYDON
	call LookForCardIDInDeck_GivenCardIDInHand
	jr c, .find_duplicates
	ld b, CUBONE
	ld a, MAROWAK_LV26
	call LookForCardIDInDeck_GivenCardIDInHandAndPlayArea
	jr c, .find_duplicates
	ld a, CUBONE
	ld b, MAROWAK_LV26
	call LookForCardIDInDeck_GivenCardIDInHand
	jr c, .find_duplicates
	ld b, PONYTA
	ld a, RAPIDASH
	call LookForCardIDInDeck_GivenCardIDInHandAndPlayArea
	jr c, .find_duplicates
	ld a, PONYTA
	ld b, RAPIDASH
	call LookForCardIDInDeck_GivenCardIDInHand
	ret nc
	; fallthrough

; a card in deck was found to look for,
; check if there are duplicates in hand to trade with.
; return carry if duplicates were found.
.find_duplicates
	ld [wce1a], a
	jp FindDuplicatePokemonCards


AIDecide_PokemonTrader_SoundOfTheWaves:
; for each of the following cards,
; first run a check if there's a pre-evolution in
; Play Area or in the hand. If there is, choose it as target.
; otherwise, check if the evolution card is in
; hand and if so, choose it as target instead.
	ld b, SEEL
	ld a, DEWGONG
	call LookForCardIDInDeck_GivenCardIDInHandAndPlayArea
	jr c, .choose_hand
	ld a, SEEL
	ld b, DEWGONG
	call LookForCardIDInDeck_GivenCardIDInHand
	jr c, .choose_hand
	ld b, KRABBY
	ld a, KINGLER
	call LookForCardIDInDeck_GivenCardIDInHandAndPlayArea
	jr c, .choose_hand
	ld a, KRABBY
	ld b, KINGLER
	call LookForCardIDInDeck_GivenCardIDInHand
	jr c, .choose_hand
	ld b, SHELLDER
	ld a, CLOYSTER
	call LookForCardIDInDeck_GivenCardIDInHandAndPlayArea
	jr c, .choose_hand
	ld a, SHELLDER
	ld b, CLOYSTER
	call LookForCardIDInDeck_GivenCardIDInHand
	jr c, .choose_hand
	ld b, HORSEA
	ld a, SEADRA
	call LookForCardIDInDeck_GivenCardIDInHandAndPlayArea
	jr c, .choose_hand
	ld a, HORSEA
	ld b, SEADRA
	call LookForCardIDInDeck_GivenCardIDInHand
	jr c, .choose_hand
	ld b, TENTACOOL
	ld a, TENTACRUEL
	call LookForCardIDInDeck_GivenCardIDInHandAndPlayArea
	jr c, .choose_hand
	ld a, TENTACOOL
	ld b, TENTACRUEL
	call LookForCardIDInDeck_GivenCardIDInHand
	ret nc
	; fallthrough

; card was found as target in deck,
; look for card in hand to trade with
.choose_hand
	ld [wce1a], a
	ld a, SEEL
	call CheckIfHasCardIDInHand
	ret c ; Seel found
	ld a, KRABBY
	call CheckIfHasCardIDInHand
	ret c ; Krabby found
	ld a, HORSEA
	call CheckIfHasCardIDInHand
	ret c ; Horsea found
	ld a, SHELLDER
	call CheckIfHasCardIDInHand
	ret c ; Shellder found
	ld a, TENTACOOL
	jp CheckIfHasCardIDInHand


AIDecide_PokemonTrader_PowerGenerator:
; for each of the following cards,
; first run a check if there's a pre-evolution in
; Play Area or in the hand. If there is, choose it as target.
; otherwise, check if the evolution card is in
; hand and if so, choose it as target instead.
	ld b, PIKACHU_LV14
	ld a, RAICHU_LV40
	call LookForCardIDInDeck_GivenCardIDInHandAndPlayArea
	jp c, .find_duplicates
	ld b, PIKACHU_LV12
	ld a, RAICHU_LV40
	call LookForCardIDInDeck_GivenCardIDInHandAndPlayArea
	jr c, .find_duplicates
	ld a, PIKACHU_LV14
	ld b, RAICHU_LV40
	call LookForCardIDInDeck_GivenCardIDInHand
	jr c, .find_duplicates
	ld a, PIKACHU_LV12
	ld b, RAICHU_LV40
	call LookForCardIDInDeck_GivenCardIDInHand
	jr c, .find_duplicates
	ld b, VOLTORB
	ld a, ELECTRODE_LV42
	call LookForCardIDInDeck_GivenCardIDInHandAndPlayArea
	jr c, .find_duplicates
	ld b, VOLTORB
	ld a, ELECTRODE_LV35
	call LookForCardIDInDeck_GivenCardIDInHandAndPlayArea
	jr c, .find_duplicates
	ld a, VOLTORB
	ld b, ELECTRODE_LV42
	call LookForCardIDInDeck_GivenCardIDInHand
	jr c, .find_duplicates
	ld a, VOLTORB
	ld b, ELECTRODE_LV35
	call LookForCardIDInDeck_GivenCardIDInHand
	jr c, .find_duplicates
	ld b, MAGNEMITE_LV13
	ld a, MAGNETON_LV35
	call LookForCardIDInDeck_GivenCardIDInHandAndPlayArea
	jr c, .find_duplicates
	ld b, MAGNEMITE_LV15
	ld a, MAGNETON_LV35
	call LookForCardIDInDeck_GivenCardIDInHandAndPlayArea
	jr c, .find_duplicates
	ld b, MAGNEMITE_LV13
	ld a, MAGNETON_LV28
	call LookForCardIDInDeck_GivenCardIDInHandAndPlayArea
	jr c, .find_duplicates
	ld b, MAGNEMITE_LV15
	ld a, MAGNETON_LV28
	call LookForCardIDInDeck_GivenCardIDInHandAndPlayArea
	jr c, .find_duplicates
	ld a, MAGNEMITE_LV15
	ld b, MAGNETON_LV35
	call LookForCardIDInDeck_GivenCardIDInHand
	jr c, .find_duplicates
	ld a, MAGNEMITE_LV13
	ld b, MAGNETON_LV35
	call LookForCardIDInDeck_GivenCardIDInHand
	jr c, .find_duplicates
	ld a, MAGNEMITE_LV15
	ld b, MAGNETON_LV28
	call LookForCardIDInDeck_GivenCardIDInHand
	jr c, .find_duplicates
	ld a, MAGNEMITE_LV13
	ld b, MAGNETON_LV28
	call LookForCardIDInDeck_GivenCardIDInHand
	ret nc
	; fallthrough

; a card in deck was found to look for,
; check if there are duplicates in hand to trade with.
; return carry if duplicates were found.
.find_duplicates
	ld [wce1a], a
	jp FindDuplicatePokemonCards


AIDecide_PokemonTrader_FlowerGarden:
; for each of the following cards,
; first run a check if there's a pre-evolution in
; Play Area or in the hand. If there is, choose it as target.
; otherwise, check if the evolution card is in
; hand and if so, choose it as target instead.
	ld b, BULBASAUR
	ld a, IVYSAUR
	call LookForCardIDInDeck_GivenCardIDInHandAndPlayArea
	jr c, .find_duplicates
	ld b, IVYSAUR
	ld a, VENUSAUR_LV67
	call LookForCardIDInDeck_GivenCardIDInHandAndPlayArea
	jr c, .find_duplicates
	ld a, BULBASAUR
	ld b, IVYSAUR
	call LookForCardIDInDeck_GivenCardIDInHand
	jr c, .find_duplicates
	ld a, IVYSAUR
	ld b, VENUSAUR_LV67
	call LookForCardIDInDeck_GivenCardIDInHand
	jr c, .find_duplicates
	ld b, BELLSPROUT
	ld a, WEEPINBELL
	call LookForCardIDInDeck_GivenCardIDInHandAndPlayArea
	jr c, .find_duplicates
	ld b, WEEPINBELL
	ld a, VICTREEBEL
	call LookForCardIDInDeck_GivenCardIDInHandAndPlayArea
	jr c, .find_duplicates
	ld a, BELLSPROUT
	ld b, WEEPINBELL
	call LookForCardIDInDeck_GivenCardIDInHand
	jr c, .find_duplicates
	ld a, WEEPINBELL
	ld b, VICTREEBEL
	call LookForCardIDInDeck_GivenCardIDInHand
	jr c, .find_duplicates
	ld b, ODDISH
	ld a, GLOOM
	call LookForCardIDInDeck_GivenCardIDInHandAndPlayArea
	jr c, .find_duplicates
	ld b, GLOOM
	ld a, VILEPLUME
	call LookForCardIDInDeck_GivenCardIDInHandAndPlayArea
	jr c, .find_duplicates
	ld a, ODDISH
	ld b, GLOOM
	call LookForCardIDInDeck_GivenCardIDInHand
	jr c, .find_duplicates
	ld a, GLOOM
	ld b, VILEPLUME
	call LookForCardIDInDeck_GivenCardIDInHand
	ret nc
	; fallthrough

; a card in deck was found to look for,
; check if there are duplicates in hand to trade with.
; return carry if duplicates were found.
.find_duplicates
	ld [wce1a], a
	jp FindDuplicatePokemonCards


AIDecide_PokemonTrader_StrangePower:
; looks for a Pokemon in hand to trade with Mr Mime in deck.
; inputting Mr Mime in register e for the function is redundant
; since it already checks whether a Mr Mime exists in the hand.
	ld a, MR_MIME
	ld e, a
	call LookForCardIDToTradeWithDifferentHandCard
	ret nc
; found
	ld [wce1a], a
	ld a, e
	scf
	ret


AIDecide_PokemonTrader_Flamethrower:
; for each of the following cards,
; first run a check if there's a pre-evolution in
; Play Area or in the hand. If there is, choose it as target.
; otherwise, check if the evolution card is in
; hand and if so, choose it as target instead.
	ld b, CHARMANDER
	ld a, CHARMELEON
	call LookForCardIDInDeck_GivenCardIDInHandAndPlayArea
	jr c, .find_duplicates
	ld b, CHARMELEON
	ld a, CHARIZARD
	call LookForCardIDInDeck_GivenCardIDInHandAndPlayArea
	jr c, .find_duplicates
	ld a, CHARMANDER
	ld b, CHARMELEON
	call LookForCardIDInDeck_GivenCardIDInHand
	jr c, .find_duplicates
	ld a, CHARMELEON
	ld b, CHARIZARD
	call LookForCardIDInDeck_GivenCardIDInHand
	jr c, .find_duplicates
	ld b, VULPIX
	ld a, NINETALES_LV32
	call LookForCardIDInDeck_GivenCardIDInHandAndPlayArea
	jr c, .find_duplicates
	ld a, VULPIX
	ld b, NINETALES_LV32
	call LookForCardIDInDeck_GivenCardIDInHand
	jr c, .find_duplicates
	ld b, GROWLITHE
	ld a, ARCANINE_LV45
	call LookForCardIDInDeck_GivenCardIDInHandAndPlayArea
	jr c, .find_duplicates
	ld a, GROWLITHE
	ld b, ARCANINE_LV45
	call LookForCardIDInDeck_GivenCardIDInHand
	jr c, .find_duplicates
	ld b, EEVEE
	ld a, FLAREON_LV28
	call LookForCardIDInDeck_GivenCardIDInHandAndPlayArea
	jr c, .find_duplicates
	ld a, EEVEE
	ld b, FLAREON_LV28
	call LookForCardIDInDeck_GivenCardIDInHand
	ret nc
	; fallthrough

; a card in deck was found to look for,
; check if there are duplicates in hand to trade with.
; return carry if duplicates were found.
.find_duplicates
	ld [wce1a], a
	jp FindDuplicatePokemonCards
