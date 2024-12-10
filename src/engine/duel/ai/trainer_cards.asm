INCLUDE "data/duel/ai_trainer_card_logic.asm"

_AIProcessHandTrainerCards:
	ld [wAITrainerCardPhase], a
	
; exit if an effect such as Headache is preventing Trainer cards from being played.
	call CheckCantUseTrainerDueToEffect
	ret c

; create hand list in wDuelTempList and wTempHandCardList.
	call CreateHandCardList
	ld hl, wDuelTempList
	ld de, wTempHandCardList
	call CopyListWithFFTerminatorFromHLToDE_Bank8
	ld hl, wTempHandCardList

.loop_hand
	ld a, [hli]
	ld [wAITrainerCardToPlay], a
	inc a ; cp $ff
	ret z

	push hl
	ld hl, AITrainerCardLogic
.loop_data
	ld a, [wAITrainerCardPhase]
	ld d, a
	xor a
	ld [wCurrentAIFlags], a
	ld a, [hli]
	cp $ff
	jr z, .next_hand_card

; compare input to first byte in data and continue if equal.
	cp d
	jr nz, .inc_hl_by_5

	ld a, [hli]
	ld [wAITrainerLogicCard], a
	ld a, [wAITrainerCardToPlay]
	call _GetCardIDFromDeckIndex
	ld b, a
	cp SWITCH
	jr nz, .skip_switch_check

	ld a, [wPreviousAIFlags]
	and AI_FLAG_USED_SWITCH
	jr nz, .next_hand_card

.skip_switch_check
; compare hand card to second byte in data and continue if equal.
	ld a, [wAITrainerLogicCard]
	cp b
	jr nz, .inc_hl_by_4

; found Trainer card
	push hl
	ld a, [wAITrainerCardToPlay]
	ldh [hTempCardIndex_ff9f], a
	call LoadNonPokemonCardEffectCommands
	ld a, EFFECTCMDTYPE_INITIAL_EFFECT_1
	call TryExecuteEffectCommandFunction
	pop hl
	jr c, .next_hand_card

; AI can randomly choose not to play any card.
	call AIChooseRandomlyNotToDoAction
	jr c, .next_hand_card

; call routine to decide whether to play the Trainer card
	push hl
	call CallIndirect
	pop hl
	jr nc, .next_hand_card

; routine returned carry, which means this card should be played.
	inc hl
	inc hl
	ld [wAITrainerCardParameter], a

; show Play Trainer Card screen
	push hl
	ld a, [wAITrainerCardToPlay]
	ldh [hTempCardIndex_ff9f], a
	ld a, OPPACTION_PLAY_TRAINER
	bank1call AIMakeDecision
	pop hl
	jr c, .inc_hl_by_2 ; is this actually possible?

; execute the effects of the Trainer card
	call CallIndirect
	ld hl, wPreviousAIFlags
	ld a, [wCurrentAIFlags]
	or [hl]
	ld [hl], a
	and AI_FLAG_MODIFIED_HAND
	jr nz, .relist_hand
.next_hand_card
	pop hl
	jr .loop_hand

.relist_hand
; the hand was modified during the Trainer effect,
; so it needs to be re-listed again and looped from the top.
	pop hl
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




; Potion uses 'AIPlay_TrainerCard_TwoVars'


; if there are no plans to retreat the Active Pokémon and the AI doesn't intend
; to use a high recoil attack, then it will use Potion on the Active Pokémon,
; but only if doing so will prevent that Pokémon from being KO'd in the following turn.
; output:
;	a = amount of damage to heal, if any (usually 20)
;	[wce1a] = PLAY_AREA_ARENA:  if the AI decided to play Potion
;	carry = set:  if the AI decided to play Potion
AIDecide_Potion_Phase07:
; don't play Potion if the AI is going to retreat the Active Pokémon.
	farcall AIDecideWhetherToRetreat
	ccf
	ret nc

; don't play Potion if the AI is going to select a high recoil attack.
	call AICheckIfAttackIsHighRecoil
	ccf
	ret nc

; don't play Potion if the Defending Pokémon is unable to KO the AI's Active Pokémon.
	xor a ; PLAY_AREA_ARENA
	ldh [hTempPlayAreaLocation_ff9d], a
	farcall CheckIfDefendingPokemonCanKnockOut
	ret nc

; determine whether the Defending Pokémon can still KO this Pokémon,
; next turn, even after having used a Potion on it, and if it can't,
; then decide to play Potion and target the Active Pokémon.
.check_if_can_prevent_ko
	ld d, a ; largest amount of damage that the Defending Pokémon might do
	ld a, DUELVARS_ARENA_CARD_HP
	get_turn_duelist_var
	ld h, a
	ld e, PLAY_AREA_ARENA
	call GetCardDamageAndMaxHP
	cp 20 + 1 ; if damage <= 20
	jr c, .calculate_hp
	; Active Pokémon has more than 20 damage
	ld a, 20 ; maximum amount of HP healed by Potion
.calculate_hp
	ld l, a ; amount of damage to heal
	ld a, h ; current HP
	add l
	sub d
	ret z ; return no carry if the damage will reduce the HP to exactly 0

; play Potion on the Active Pokémon if it will prevent the KO.
	ld a, e ; PLAY_AREA_ARENA
	ld [wce1a], a
	ld a, l
	ccf
	ret


; AI still prioritizes the Active Pokémon, especially if it can prevent a KO,
; but it's now willing to consider Benched Pokémon as possible targets.
; output:
;	a = amount of damage to heal, if any (usually 20)
;	[wce1a] = target Pokémon's play area location offset (PLAY_AREA_* constant)
;	carry = set:  if the AI decided to play Potion
AIDecide_Potion_Phase10:
	xor a ; PLAY_AREA_ARENA
	ldh [hTempPlayAreaLocation_ff9d], a
	farcall CheckIfDefendingPokemonCanKnockOut
	jr nc, .start_from_active

; determine whether the Defending Pokémon can still KO this Pokémon,
; next turn, even after having used a Potion on it, and if it can't,
; then decide to play Potion and target the Active Pokémon.
	call AIDecide_Potion_Phase07.check_if_can_prevent_ko
	ret c

; using Potion on the Active Pokémon does not prevent a KO.
; if the Player is on their last Prize, start loop with the Active Pokémon.
; otherwise, start loop at the first Benched Pokémon.
.count_prizes
	ld e, PLAY_AREA_BENCH_1
	rst SwapTurn
	call CountPrizes
	rst SwapTurn
	dec a ; cp 1
	jr nz, .loop ; don't consider the Active Pokémon if opponent has more than 1 Prize
.start_from_active
	ld e, PLAY_AREA_ARENA
; find a play area Pokémon with at least 20 damage.
; skip a Pokémon if it has a BOOST_IF_TAKEN_DAMAGE attack.
.loop
	ld a, DUELVARS_ARENA_CARD
	add e
	get_turn_duelist_var
	cp -1 ; empty play area slot?
	ret z ; return no carry if there are no more Pokémon to check
	push de
	call .check_boost_if_taken_damage
	pop de
	jr c, .next
	call GetCardDamageAndMaxHP
	cp 20 ; if damage >= 20
	jr nc, .found
.next
	inc e
	jr .loop

; a Pokémon was selected, now to check if it's Active or Benched.
.found
	ld a, e
	ld [wce1a], a
	or a ; cp PLAY_AREA_ARENA
	jr z, .active_card

; if the target is a Benched Pokémon, then only play Potion 70% of the time.
; the random check is skipped if the Player is on their last Prize card.
	rst SwapTurn
	call CountPrizes
	rst SwapTurn
	dec a ; cp 1
	jr z, .skip_random
	; randomly decide to not play Potion 30% of the time.
	ld a, 10
	call Random
	cp 3
	ccf
	ret nc
.skip_random
	ld a, 20
	scf
	ret

; only decide to use Potion on the Active Pokémon
; if the AI does not intend to use a High Recoil recoil.
.active_card
	call AICheckIfAttackIsHighRecoil
	ld a, 20
	ccf
	ret


; input:
;	[hTempPlayAreaLocation_ff9d] = Pokémon's play area location offset (PLAY_AREA_* constant)
; output:
;	carry = set:  if either of the attacks has the BOOST_IF_TAKEN_DAMAGE effect and can be used
.check_boost_if_taken_damage
	xor a ; FIRST_ATTACK_OR_PKMN_POWER
	call .check_selected_attack_for_boost_if_taken_damage
	ret c
	ld a, SECOND_ATTACK
;	fallthrough

; input:
;	a = which attack to check (0 = first attack, 1 = second attack)
;	[hTempPlayAreaLocation_ff9d] = Pokémon's play area location offset (PLAY_AREA_* constant)
; output:
;	carry = set:  if the given attack has the BOOST_IF_TAKEN_DAMAGE effect and can be used
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
	ldh [hPlayAreaEffectTarget], a
	ld a, OPPACTION_EXECUTE_TRAINER_EFFECTS
	bank1call AIMakeDecision
	ret


; if there are no plans to retreat the Active Pokémon and the AI doesn't intend
; to use a high recoil attack, then it will use Super Potion on the Active Pokémon,
; but only if doing so will prevent that Pokémon from being KO'd in the following turn.
; output:
;	a = PLAY_AREA_ARENA:  if the AI decided to play Super Potion
;	carry = set:  if the AI decided to play Super Potion
AIDecide_SuperPotion_Phase08:
; don't play Super Potion if the AI is going to retreat the Active Pokémon.
	farcall AIDecideWhetherToRetreat
	ccf
	ret nc

; don't play Super Potion if the AI is going to select a high recoil attack.
	call AICheckIfAttackIsHighRecoil
	ccf
	ret nc

; don't play Super Potion unless the Active Pokémon has an attached Energy card to discard.
	xor a ; PLAY_AREA_ARENA
	ldh [hTempPlayAreaLocation_ff9d], a
	ld e, a
	call GetPlayAreaCardAttachedEnergies
;	ld a, [wTotalAttachedEnergies] ; already loaded
	or a
	ret z

; don't play Super Potion if the Defending Pokémon is unable to KO the AI's Active Pokémon.
	farcall CheckIfDefendingPokemonCanKnockOut
	ret nc

; determine whether the Defending Pokémon can still KO this Pokémon,
; next turn, even after having used a Super Potion on it, and if it can't,
; then decide to play Super Potion and target the Active Pokémon.
.check_if_can_prevent_ko
	ld d, a ; largest amount of damage that the Defending Pokémon might do
	ld a, DUELVARS_ARENA_CARD_HP
	get_turn_duelist_var
	ld h, a
	ld e, PLAY_AREA_ARENA
	call GetCardDamageAndMaxHP
	cp 40 + 1 ; if damage <= 40
	jr c, .calculate_hp
	; Active Pokémon has more than 40 damage
	ld a, 40 ; maximum amount of HP healed by Super Potion
.calculate_hp
	ld l, a ; amount of damage to heal
	ld a, h ; current HP
	add l
	sub d
	ret z ; return no carry if the damage will reduce the HP to exactly 0

; play Super Potion on the Active Pokémon if it will prevent the KO.
	ld a, e ; PLAY_AREA_ARENA
	ccf
	ret


; AI still prioritizes the Active Pokémon, especially if it can prevent a KO,
; but it's now willing to consider Benched Pokémon as possible targets.
; output:
;	a = target Pokémon's play area location offset (PLAY_AREA_* constant)
;	carry = set:  if the AI decided to play Super Potion
AIDecide_SuperPotion_Phase11:
	xor a ; PLAY_AREA_ARENA
	ldh [hTempPlayAreaLocation_ff9d], a
	farcall CheckIfDefendingPokemonCanKnockOut
	jr nc, .start_from_active

; determine whether the Defending Pokémon can still KO this Pokémon,
; next turn, even after having used a Super Potion on it, and if it can't,
; then decide to play Super Potion and target the Active Pokémon.
	call AIDecide_SuperPotion_Phase08.check_if_can_prevent_ko
	ret c

; using Super Potion on the Active Pokémon does not prevent a KO.
; if the Player is on their last Prize, start loop with the Active Pokémon.
; otherwise, start loop at the first Benched Pokémon.
.count_prizes
	rst SwapTurn
	call CountPrizes
	rst SwapTurn
	dec a ; cp 1
	jr z, .start_from_active
	ld e, PLAY_AREA_BENCH_1
	jr .loop

; find a play area Pokémon with at least 40 damage.
; skip a Pokémon if it doesn't have any attached Energy,
; or if it has a valid BOOST_IF_TAKEN_DAMAGE attack,
; or if discarding would make any of its attacks unusable.
.start_from_active
	ld e, PLAY_AREA_ARENA
.loop
	ld a, DUELVARS_ARENA_CARD
	add e
	get_turn_duelist_var
	cp -1 ; empty play area slot?
	ret z ; return no carry if there are no more Pokémon to check
	ld d, a
	call GetPlayAreaCardAttachedEnergies
;	ld a, [wTotalAttachedEnergies] ; already loaded
	or a
	jr z, .next
	push de
	call AIDecide_Potion_Phase10.check_boost_if_taken_damage
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

; a Pokémon was selected, now to check if it's Active or Benched.
.found
	ld a, e
	or a ; cp PLAY_AREA_ARENA
	jr z, .active_card

; if the target is a Benched Pokémon, then only play Super Potion 70% of the time.
; the random check is skipped if the Player is on their last Prize card.
	rst SwapTurn
	call CountPrizes
	rst SwapTurn
	dec a ; cp 1
	jr z, .skip_random
	; randomly decide to not play Super Potion 30% of the time.
	ld a, 10
	call Random
	cp 3
	ccf
	ret nc
.skip_random
	ld a, e
	scf
	ret

; only decide to use Super Potion on the Active Pokémon
; if the AI does not intend to use a High Recoil recoil.
.active_card
	call AICheckIfAttackIsHighRecoil
	ld a, PLAY_AREA_ARENA
	ccf
	ret




; AI always attaches a Defender card to the Active Pokémon.
AIPlay_Defender:
	ld a, [wAITrainerCardToPlay]
	ldh [hTempCardIndex_ff9f], a
	xor a ; PLAY_AREA_ARENA
	ldh [hTemp_ffa0], a
	ld a, OPPACTION_EXECUTE_TRAINER_EFFECTS
	bank1call AIMakeDecision
	ret


; AI will only play Defender if it can be used to prevent the
; Defending Pokémon from KOing its Active Pokémon in the following turn.
; this takes into account both of its attacks and whether they're useable.
; output:
;	carry = set:  if the AI decided to play Defender
AIDecide_Defender_Phase13:
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


; AI will only play Defender if it would prevent its Active Pokémon
; from being Knocked Out after using an attack with recoil damage.
; input:
;	[wLoadedAttack] = attack data for the Active Pokémon's chosen attack (atk_data_struct)
; output:
;	carry = set:  if the AI decided to play Defender
AIDecide_Defender_Phase14:
; don't play Defender unless the selected attack has a recoil effect.
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
	or a ; cp FIRST_ATTACK_OR_PKMN_POWER
	jr nz, .second_attack
; first attack
	ld a, [wLoadedCard2Atk1EffectParam]
	jr .check_weak
.second_attack
	ld a, [wLoadedCard2Atk2EffectParam]

; double the recoil damage if the Active Pokémon has a Weakness to its own type/color.
.check_weak
	ld d, a ; store the amount of recoil damage
	call GetArenaCardColor
	call TranslateColorToWR
	ld b, a
	call GetArenaCardWeakness
	and b
	jr z, .check_resist
	sla d ; double the amount of recoil damage

; reduce the recoil damage by 30 if the Active Pokémon has a Resistance to its own type/color.
; don't play Defender if this causes an underflow (i.e. the recoil damage is now a negative number).
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

; don't play Defender if the current recoil damage is 0 or
; if the Active Pokémon will still be KO'd after playing the Defender,
; but if Defender prevents a KO, then return carry.
.subtract
	ld a, d
	or a
	jr nz, AIDecide_Defender_Phase13.check_if_defender_prevents_ko
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


; AI will only decide to play Pluspower if the additional damage
; will allow its Active Pokémon to KO the Defending Pokémon.
; output:
;	a = attack index for the attack that should be used with PlusPower (0 = first attack, 1 = second attack)
;	carry = set:  if the AI decided to play PlusPower
AIDecide_Pluspower_Phase13:
; don't play PlusPower if the AI's Active Pokémon can already KO the Defending Pokémon this turn.
	farcall CheckIfActiveWillNotBeAbleToKODefending
	ret nc

; get Active Pokémon's info.
	ld a, DUELVARS_ARENA_CARD
	get_turn_duelist_var
	call _GetCardIDFromDeckIndex
	ld [wTempTurnDuelistCardID], a

; get the Defending Pokémon's info and check its No Damage or Effect substatus.
; don't play PlusPower if the Defending Pokémon is temporarily protected from all damage.
	rst SwapTurn
	ld a, DUELVARS_ARENA_CARD
	get_turn_duelist_var
	call _GetCardIDFromDeckIndex
	ld [wTempNonTurnDuelistCardID], a
	call HandleNoDamageOrEffectSubstatus
	rst SwapTurn
	ccf
	ret nc

; check both of the Active Pokémon's attacks and decide which
; would be able to KO the Defending Pokémon after using PlusPower.
; if neither can, then return no carry.
	xor a ; FIRST_ATTACK_OR_PKMN_POWER
	call .check_ko_with_pluspower
	jr c, .kos_with_pluspower
	ld a, SECOND_ATTACK
	call .check_ko_with_pluspower
	ret nc

; selected attack can KO with Pluspower.
.kos_with_pluspower
	call AIDecide_Pluspower_Phase14.check_if_can_damage_mr_mime_after_pluspower
	ret nc
	ld a, [wSelectedAttack]
	ret ; carry set


; input:
;	a = which attack to check (0 = first attack, 1 = second attack)
;	[hTempPlayAreaLocation_ff9d] = play area location offset of the Attacking Pokémon
;	                               (it should be PLAY_AREA_ARENA, or 0)
; output:
;	carry = set: if the given attack can be used and it is only able to KO
;	             the Defending Pokémon after applying the PlusPower bonus.
.check_ko_with_pluspower
	ld [wSelectedAttack], a
	farcall CheckIfSelectedAttackIsUnusable
	ccf
	ret nc ; return no carry if the given attack can't be used

; return no carry if the attack can KO the Defending Pokémon without using PlusPower.
	ld a, [wSelectedAttack]
	farcall EstimateDamage_VersusDefendingCard
	ld a, DUELVARS_ARENA_CARD_HP
	call GetNonTurnDuelistVariable
	ld b, a
	ld hl, wDamage
	sub [hl]
	ret z ; return no carry if the damage reduces the Pokémon's HP to exactly 0
	ccf
	ret nc ; return no carry if the damage exceeds the Pokémon's HP

; check if the attack can KO the Defending Pokémon after applying the PlusPower bonus.
	ld a, [hl]
	or a
	ret z ; return no carry if the attack won't do any damage before using PlusPower
	add 10 + 1 ; add PlusPower boost plus 1 (so carry will be set if final HP = 0)
	ld c, a
	ld a, b
	sub c
	ret


; AI will randomly decide to play PlusPower 70% of the time as long as
; it's Active Pokémon is going to damage (but not KO) the Defending Pokémon.
; input:
;	[wSelectedAttack] = attack index for the attack being used (0 = first attack, 1 = second attack)
; output:
;	carry = set:  if the AI decided to play PlusPower
AIDecide_Pluspower_Phase14:
; don't play PlusPower if the selected attack isn't usable.
	xor a ; PLAY_AREA_ARENA
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
	ret z ; return no carry if the damage reduces the Pokémon's HP to exactly 0
	ccf
	ret nc ; return no carry if the damage exceeds the Pokémon's HP

; don't play PlusPower if the selected attack might not do any damage.
	ld a, [wAIMinDamage]
	or a
	ret z ; nc

; randomly decide to not play PlusPower 70% of the time.
	ld a, 10
	call Random
	cp 3
	ret nc

; play PlusPower as long as it doesn't trigger Mr. Mime's Invisible Wall.
; preserve bc and de
; input:
;	[wDamage] = damage that would be dealt to the Defending Pokémon
; output:
;	carry = set:  if the damage is still less than 30 after using PlusPower
;	              or if the Defending Pokémon isn't a Mr. Mime
.check_if_can_damage_mr_mime_after_pluspower
	ld a, [wDamage]
	add 10 ; add PlusPower boost
	cp 30 ; minimum damage prevented by Invisible Wall
	ret c
	rst SwapTurn
	ld a, DUELVARS_ARENA_CARD
	get_turn_duelist_var
	call _GetCardIDFromDeckIndex
	rst SwapTurn
	cp MR_MIME
	ret z
; damage is >= 30 but Defending Pokémon isn't Mr. Mime
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


; this function is only called after the AI has already decided to retreat.
; AI will play Switch if its Active Pokémon can't retreat due to an effect/status
; or if the Active Pokémon's Retreat Cost is 3 or more
; or if its Active Pokémon won't have enough Energy to pay its Retreat Cost.
; input:
;	[wAIPlayAreaCardToSwitch] = play area location offset of the Benched Pokémon to switch with the Active
; output:
;	a = [wAIPlayAreaCardToSwitch]
;	carry = set:  if the AI decided to play Switch
AIDecide_Switch:
; play Switch if the Active Pokémon is unable to retreat due to an effect.
	call CheckUnableToRetreatDueToEffect
	jr c, .switch

; check whether the AI can play an Energy card from its hand to retreat.
	ld a, [wAIPlayEnergyCardForRetreat]
	or a
	jr z, .check_cost_amount

; AI can play an Energy card from its hand to help pay the Active Pokémon's Retreat Cost.
; compare the amount of attached Energy with the Active Pokémon's Retreat Cost, and
; play Switch if the Retreat Cost is at least 2 more than the amount of attached Energy.
	xor a ; PLAY_AREA_ARENA
	ldh [hTempPlayAreaLocation_ff9d], a
	ld e, a
	call GetPlayAreaCardAttachedEnergies
	ld b, a ; wTotalAttachedEnergies
	call GetPlayAreaCardRetreatCost
	sub b
	jr c, .check_cost_amount ; skip ahead if amount of attached Energy > Retreat Cost
	cp 2
	jr nc, .switch

.check_cost_amount
; play Switch if the Active Pokémon's Retreat Cost is 3 or more.
	xor a ; PLAY_AREA_ARENA
	ldh [hTempPlayAreaLocation_ff9d], a
	call GetPlayAreaCardRetreatCost
	cp 3
	jr nc, .switch

; play Switch if the Active Pokémon doesn't have enough Energy to pay its Retreat Cost.
	ld b, a
	ld e, PLAY_AREA_ARENA
	call GetPlayAreaCardAttachedEnergies
	cp b
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


; AI won't play Gust of Wind if another copy was already played this turn,
; or if its Active Pokémon can only use a residual attack, or if it might
; KO the Defending Pokémon this turn, or if its Active Pokémon has Psywave/Psychic.
; if none of these are true, then it tries to target a Benched Pokémon that can be KO'd,
; then a Benched Pokémon that has a relevant Weakness, then a Benched Pokémon that
; has no attached Energy, and finally whichever Benched Pokémon has the least amount of HP.
; Benched Pokémon that the AI's Active Pokémon wouldn't be able to damage are ignored,
; and the logic stops after the Weakness checks if the AI can damage the Defending Pokémon.
; output:
;	a = play area location offset of the chosen Pokemon on the Player's Bench
;	carry = set:  if the AI decided to play Gust of Wind
AIDecide_GustOfWind:
; can't play Gust of Wind if there are no Pokémon on the Player's Bench.
	ld a, DUELVARS_NUMBER_OF_POKEMON_IN_PLAY_AREA
	call GetNonTurnDuelistVariable
	dec a
	or a
	ret z ; return no carry if the Player doesn't have any Benched Pokémon

; don't play Gust of Wind if it was already played previously in the turn.
	ld a, [wPreviousAIFlags]
	and AI_FLAG_USED_GUST_OF_WIND
	ret nz ; nc

; don't play Gust of Wind unless the AI's Active Pokémon can use a
; non-residual attack. (i.e. an attack that affects the Defending Pokémon)
	farcall CheckIfActivePokemonCanUseAnyNonResidualAttack
	ret nc

; don't play Gust of Wind if the AI's Active Pokémon could KO the Defending Pokémon this turn.
	farcall CheckIfActiveWillNotBeAbleToKODefending
	ret nc

; don't play Gust of Wind if the AI's Active Pokémon is MEW_LV23 or MEWTWO_LV53.
; this is likely because the damage boost from Psywave/Psychic
; isn't applied properly in the upcoming damage calculations.
	ld a, DUELVARS_ARENA_CARD
	get_turn_duelist_var
	call _GetCardIDFromDeckIndex
	cp MEW_LV23
	ret z ; return no carry if MewLv23 is the AI's Active Pokémon
	cp MEWTWO_LV53
	ret z ; return no carry if MewtwoLv53 is the AI's Active Pokémon

; if there's any Pokémon on the Player's Bench that can be KO'd by the
; AI's Active Pokémon, then play Gust of Wind targeting that Pokémon.
	call FindBenchCardToKnockOut
	ret c

	xor a ; PLAY_AREA_ARENA
	farcall CheckIfCanDamageDefendingPokemon
	jr nc, .check_bench_energy ; skip ahead if Active can't damage Defending

; decide to play Gust of Wind if there's a Pokémon on the Player's Bench that
; has Weakness to the AI's Active Pokémon and that the Active Pokémon can damage,
; but only if the Defending Pokémon doesn't already meet those requirements.
	call GetArenaCardColor
	call TranslateColorToWR
	ld b, a
	rst SwapTurn
	call GetArenaCardWeakness
	rst SwapTurn
	and b
	jr z, FindBenchCardWithWeakness
	; Defending Pokémon has a relevant Weakness and can be damaged, so return no carry
	ret

; being here means the AI's Active Pokémon cannot damage the Player's Active Pokémon.
.check_bench_energy
; check if there is a Pokémon on the Player's Bench that has Weakness
; to the AI's Active Pokémon and that the Active Pokémon can damage.
; if there is, then play Gust of Wind targeting that Pokémon.
	call GetArenaCardColor
	call TranslateColorToWR
	ld b, a
	call FindBenchCardWithWeakness
	ret c

; next, check if there is a Pokémon on the Player's Bench that
; has no attached Energy cards and that the Active Pokémon can damage.
; if there is, then play Gust of Wind targeting that Pokémon.
	ld a, DUELVARS_NUMBER_OF_POKEMON_IN_PLAY_AREA
	call GetNonTurnDuelistVariable
	ld d, a
	ld e, PLAY_AREA_BENCH_1 - 1
; loop through the Bench and check attached Energy cards
.loop_1
	inc e
	dec d
	jr z, .check_bench_hp
	rst SwapTurn
	call GetPlayAreaCardAttachedEnergies
	rst SwapTurn
;	ld a, [wTotalAttachedEnergies] ; already loaded
	or a
	jr nz, .loop_1 ; skip if it has attached Energy
	call CheckIfCanDamageBenchedCard
	jr nc, .loop_1
	ld a, e
	scf
	ret

; finally, check if the AI's Active Pokémon can damage any of the Player's Benched Pokémon.
; if any are found, play Gust of Wind targeting whichever of those Pokémon has the least HP.
.check_bench_hp
	ld a, $ff
	ld [wce06], a
	xor a
	ld [wce08], a
	ld e, a ; PLAY_AREA_ARENA
	ld a, DUELVARS_NUMBER_OF_POKEMON_IN_PLAY_AREA
	call GetNonTurnDuelistVariable
	ld d, a

; find the Benched Pokémon with the least amount of available HP
.loop_2
	inc e
	dec d
	jr z, .check_found
	ld a, e
	add DUELVARS_ARENA_CARD_HP
	ld l, a
	ld b, [hl]
	ld a, [wce06]
	inc b ; add 1 so carry will be set if this HP value is equal to the stored one
	cp b
	jr c, .loop_2
	call CheckIfCanDamageBenchedCard
	jr nc, .loop_2
	dec b ; subtract the 1 that was added earlier
	ld a, b
	ld [wce06], a
	ld a, e
	ld [wce08], a
	jr .loop_2

.check_found
	ld a, [wce08]
	or a
	ret z ; return no carry if no suitable Pokémon was found
	; a Pokémon was found, so return carry with its play area location in a
	scf
	ret


; preserves bc and d
; input:
;	b = Weakness to look for (WR_* constant)
; output:
;	a = play area location offset of a Pokémon on the Player's Bench that has
;	    the given Weakness and can be damaged by the AI's Active Pokémon, if any
;	carry = set:  if any of the Player's Benched Pokémon have the given Weakness
;	              and if the AI's Active Pokémon could damage that Pokémon
;	              after using Gust of Wind to switch it with Defending Pokémon
FindBenchCardWithWeakness:
	ld a, DUELVARS_BENCH
	call GetNonTurnDuelistVariable
	ld e, PLAY_AREA_BENCH_1 - 1
.loop_bench
	ld a, [hli]
	cp -1 ; empty play area slot?
	ret z ; return no carry if there are no more Benched Pokémon to check
	inc e
	rst SwapTurn
	call LoadCardDataToBuffer1_FromDeckIndex
	rst SwapTurn
	ld a, [wLoadedCard1Weakness]
	and b
	jr z, .loop_bench

.check_can_damage
	call CheckIfCanDamageBenchedCard
	jr nc, .loop_bench
	ld a, e
	ret ; carry set


; preserves d
; output:
;	a = play area location offset of a Pokémon on the Player's Bench
;	    that the AI's Active Pokémon can KO, if any (PLAY_AREA_* constant)
;	carry = set:  if the AI's Active Pokémon could KO one of the Player's Benched Pokémon
FindBenchCardToKnockOut:
	ld a, DUELVARS_BENCH
	call GetNonTurnDuelistVariable
	ld e, PLAY_AREA_BENCH_1 - 1

.loop_bench
	ld a, [hli]
	cp -1 ; empty play area slot?
	ret z ; return no carry if there are no more Benched Pokémon to check
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
	jr c, .loop_bench

; found a Benched Pokémon that can be KO'd, so return carry with its location in a.
	ld a, e
	scf
	ret


; preserves all registers except af
; input:
;	e = play area location offset of a Pokémon on the Player's Bench (PLAY_AREA_* constant)
; output:
;	carry = set:  if the AI's Active Pokémon could damage the given Pokémon
;	              after using Gust of Wind to switch it with Defending Pokémon
CheckIfCanDamageBenchedCard:
	push bc
	push de
	push hl

; overwrite a variety of Defending Pokémon variables.
; this includes its deck index, HP, attached Defenders,
; Status, Substatus 1/2, and changed Weakness/Resistance.
; could also consider including card stage and changed type.
	; copy the the given Pokémon's deck index
	ld a, e
	add DUELVARS_ARENA_CARD
	call GetNonTurnDuelistVariable
	ld d, a
	ld l, DUELVARS_ARENA_CARD
	ld b, [hl]
	ld [hl], d

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

; return carry if the AI's Active Pokémon can damage the new Pokémon. otherwise, no carry.
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


; AI will play Bill if it has at least 10 cards in its deck.
; preserves bc and de
; output:
;	carry = set:  if the AI decided to play Bill
AIDecide_Bill:
	ld a, DUELVARS_NUMBER_OF_CARDS_NOT_IN_DECK
	get_turn_duelist_var
	cp DECK_SIZE - 9
	ret




; Energy Removal uses 'AIPlay_TrainerCard_TwoVars'


; AI will play Energy Removal as long as there is a valid target in the Player's play area.
; The Defending Pokémon is only considered if it isn't going to be KO'd this turn.
; output:
;	a = play area location offset of the chosen Pokémon (PLAY_AREA_* constant)
;	[wce1a] = deck index of the Energy card to discard from the chosen Pokémon (0-59)
;	carry = set:  if the AI decided to play Energy Removal
AIDecide_EnergyRemoval:
; check if the current Active Pokémon can KO the Defending Pokémon.
; if it's possible to KO, then skip the Player's Active Pokémon
; and look for a target on the Player's Bench.
	farcall CheckIfActiveWillNotBeAbleToKODefending
	ld e, PLAY_AREA_ARENA
	jr c, .defending_pokemon_not_excluded
	; Active can KO, so start loop from the first Benched Pokémon.
	inc e

; loop each card and check if it has enough Energy to use any attack.
; if it does, then proceed to pick an Energy card to remove.
.defending_pokemon_not_excluded
	rst SwapTurn
	ld a, e
	ld [wce0f], a ; store default location (Defending Pokémon will also need to be skipped later)

.loop_1
	ld a, DUELVARS_ARENA_CARD
	add e
	get_turn_duelist_var
	cp -1 ; empty play area slot?
	jr z, .default

;	ld d, a ; store deck index
	call GetPlayAreaCardAttachedEnergies
;	ld a, [wTotalAttachedEnergies] ; already loaded
	or a
	jr z, .next_1
	push de
	call .CheckIfNotEnoughEnergyToAttack
	pop de
	jr nc, .pick_energy ; jump if enough Energy to attack
.next_1
	inc e
	jr .loop_1

; if none of the Player's Pokémon have enough Energy to attack,
; just pick an Energy card attached to the Defending Pokémon,
; but only if it has attached Energy and the AI won't KO it this turn.
.default
	ld a, [wce0f]
	or a
	jr nz, .check_bench_damage ; skip checking the Defending Pokémon if it's about to be KO'd
	ld e, a
	call GetPlayAreaCardAttachedEnergies
;	ld a, [wTotalAttachedEnergies] ; already loaded
	or a
	jr nz, .pick_energy

; the Player's Active Pokémon isn't a viable target, so find the
; Benched Pokémon that can do the most damage to the AI's Active Pokémon,
; but skip any Pokémon that doesn't have any attached Energy.
.check_bench_damage
	ld e, PLAY_AREA_BENCH_1
	call FindEnergizedPokemonWithHighestDamagingAttack
	ld a, [wce08]
	or a
	jr z, .done ; return no carry if no Pokémon was found
	ld e, a

; output the deck index and location of the chosen Energy card and then set carry.
.pick_energy
	ld a, e
	push af
	call PickAttachedEnergyCardToRemove
	ld [wce1a], a
	pop af
	scf
.done
	jp SwapTurn


; input:
;	e = play area location offset to check (PLAY_AREA_* constant)
; output:
;	carry = set:  if the Pokémon in the given location doesn't have enough Energy to use any attack
;	           OR if there's more than enough Energy to use the Pokémon's second attack
.CheckIfNotEnoughEnergyToAttack
	ld a, e
	ldh [hTempPlayAreaLocation_ff9d], a
	xor a ; FIRST_ATTACK_OR_PKMN_POWER
	ld [wSelectedAttack], a
	farcall CheckEnergyNeededForAttack
	ret nc ; return no carry if there's enough attached Energy to satisfy the first attack's cost

	ld a, SECOND_ATTACK
	ld [wSelectedAttack], a
	farcall CheckEnergyNeededForAttack
	ret c ; return carry if neither of the Pokémon's attacks can be used

; the first attack doesn't have enough Energy (or is just a Pokémon Power),
; but the second attack has enough Energy to be used. now, check if the amount
; of attached Energy is greater than the attack's cost, and if so, return carry.
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


; AI only plays Super Energy Removal if it is able to discard an Energy card
; from one of its Benched Pokémon and also prevent one of the Player's Pokémon
; from being able to attack.
; output:
;	      a = chosen AI Pokémon's play area location offset (PLAY_AREA_* constant)
;	[wce1a] = deck index of an Energy card attached to the chosen AI Pokémon (0-59)
;	[wce1b] = chosen Player Pokémon's play area location offset (PLAY_AREA_* constant)
;	[wce1c] = deck index of an Energy card attached to the chosen Player Pokémon (0-59)
;	[wce1d] = deck index of another Energy card attached to the chosen Player Pokémon (0-59)
;	carry = set:  if the AI decided to play Super Energy Removal
AIDecide_SuperEnergyRemoval:
; first, find a Benched Pokémon with an attached
; Basic Energy card for the first discard effect.
; don't play Super Energy Removal if none are found.
	ld a, DUELVARS_NUMBER_OF_POKEMON_IN_PLAY_AREA
	get_turn_duelist_var
	ld c, a
.loop_bench
	dec c ; go through play area Pokémon in reverse order
	ld a, c
	or a ; cp PLAY_AREA_ARENA
	ret z ; return no carry if we reached the Active Pokémon
	ld a, CARD_LOCATION_ARENA
	add c
	call FindBasicEnergyCardsInLocation
	jr c, .loop_bench

; the Pokémon in c location has a Basic Energy card attached to it
	ld a, c
	ld [wce0f], a

; check if the current Active Pokémon can KO the Defending Pokémon.
; if it's possible to KO, then skip the Defending Pokémon
; and look for a target on the Player's Bench.
	farcall CheckIfActiveWillNotBeAbleToKODefending
	rst SwapTurn
	ld e, PLAY_AREA_ARENA
	jr c, .loop_opposing_play_area
	; Active can KO, so start loop from the first Benched Pokémon.
	inc e

; loop each card and check if it has enough Energy to use any attack.
; if it does, then proceed to pick Energy cards to remove.
.loop_opposing_play_area
	ld a, DUELVARS_ARENA_CARD
	add e
	get_turn_duelist_var
	cp -1 ; empty play area slot?
	jr z, .done

;	ld d, a ; store deck index
	farcall CountNumberOfEnergyCardsAttached
	cp 2
	jr c, .next_1
	push de
	call .CheckIfNotEnoughEnergyToAttack
	pop de
	jr nc, .found_card ; jump if enough Energy to attack
.next_1
	inc e
	jr .loop_opposing_play_area

.found_card
; one of the Player's Pokémon was selected as the target.
; if this is not the Active Pokémon, then check the
; entire Bench to pick the highest damaging Pokémon.
	ld a, e
	or a ; cp PLAY_AREA_ARENA
	jr nz, .check_bench_damage

; store the Energy cards that should be discarded and their locations and then set carry.
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

; find the Pokémon in the Player's play area that can do the most damage
; to the AI's Active Pokémon, but only if it has at least 2 Energy cards
; attached to it and also enough Energy to attack (but not extra).
.check_bench_damage
	xor a
	ld [wce06], a
	ld [wce08], a

	ld e, PLAY_AREA_BENCH_1
.loop_4
	ld a, DUELVARS_ARENA_CARD
	add e
	get_turn_duelist_var
	inc a ; cp -1 (empty play area slot?)
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


; input:
;	e = play area location offset to check (PLAY_AREA_* constant)
; output:
;	carry = set:  if the Pokémon in the given location doesn't have enough Energy to use any attack or
;	              if the amount of attached Energy is at least 2 more than the cost of the Pokémon's second attack
.CheckIfNotEnoughEnergyToAttack
	ld a, e
	ldh [hTempPlayAreaLocation_ff9d], a
	xor a ; FIRST_ATTACK_OR_PKMN_POWER
	ld [wSelectedAttack], a
	farcall CheckEnergyNeededForAttack
	ret nc ; return no carry if there's enough attached Energy to satisfy the first attack's cost

	ld a, SECOND_ATTACK
	ld [wSelectedAttack], a
	farcall CheckEnergyNeededForAttack
	ret c ; return carry if neither of the Pokémon's attacks can be used

; the first attack doesn't have enough Energy (or is just a Pokémon Power),
; but the second attack has enough Energy to be used. now, check if the amount of
; attached Energy is at least 2 greater than the attack's cost, and if so, return carry.
	farcall CheckIfNoSurplusEnergyForAttack
	cp 2
	ccf
	ret




; Pokémon Breeder uses 'AIPlay_TrainerCard_TwoVars'.


; output:
;	a = deck index of the Stage 2 Evolution card in the AI's hand (0-59)
;	[wce1a] = play area location offset of the Pokémon being evolved (PLAY_AREA_* constant)
;	carry = set:  if the AI decided to play Pokémon Breeder
AIDecide_PokemonBreeder:
; can't play Pokémon Breeder if there's an active Prehistoric Power.
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

; check if the Evolution card in the hand is any of the following Stage 2 Pokémon.
; having a Stage 2 Evolution card listed here means that its Basic Pokémon doesn't
; need to have at least 2 Energy attached to it before it's considered a valid target.
; these Stage 2 cards either have a useful Pokémon Power or can attack with only 1 Energy.
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

; check the play area for a Pokémon that can evolve into the chosen Stage 2 Pokémon.
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

; a valid Evolution card was found during the initial hand check.
	xor a
	ld [wce06], a
	ld a, DUELVARS_NUMBER_OF_POKEMON_IN_PLAY_AREA
	get_turn_duelist_var
	ld c, a
	lb de, $00, $00

; find the highest score from what was stored in wce08-wce0d.
.loop_score_1
	ld hl, wce08
	add hl, de
	ld a, [wce06]
	cp [hl]
	jr nc, .not_higher

; store this score at wce06.
	ld a, [hl]
	ld [wce06], a
; store this play area location at wce07.
	ld a, e
	ld [wce07], a

.not_higher
	inc e
	dec c
	jr nz, .loop_score_1

; store the play area location offset of the Pokémon to evolve in wce1a and
; store the deck index of the chosen Stage 2 Evolution card in a. then, return carry.
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

; evolution isn't possible or the HandleDragoniteLv41Evolution returned carry.
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
	dec a ; $ff
	ld [hl], a  ; [wce07] = $ff

	ld a, DUELVARS_NUMBER_OF_POKEMON_IN_PLAY_AREA
	get_turn_duelist_var
	ld c, a
	lb de, $00, $00

; find the highest score in wce08 with at least 2 Energy attached to the evolving Pokémon.
.loop_score_2
	ld hl, wce08
	add hl, de
	ld a, [wce06]
	cp [hl]
	jr nc, .next_score

; take the lower 4 bits (total Energy) and skip if the amount is less than 2.
	ld a, [hl]
	ld b, a
	and %00001111
	cp 2
	jr c, .next_score

; has at least 2 Energy, so store this score at wce06.
	ld a, b
	ld [wce06], a
; store this play area location at wce07.
	ld a, e
	ld [wce07], a

.next_score
	inc e
	dec c
	jr nz, .loop_score_2

	ld a, [wce07]
	cp $ff
	ret z ; return no carry if none of the evolving Pokémon had at least 2 Energy.

; store the play area location offset of the Pokémon to evolve in wce1a and
; store the deck index of the chosen Stage 2 Evolution card in a. then, return carry.
	ld [wce1a], a
	ld e, a
	ld hl, wce0f
	add hl, de
	ld a, [hl]
	scf
	ret


; preserves de
; input:
;	d = deck index of the Stage 2 Evolution card being considered (0-59)
;	e = play area location offset of the Pokémon being evolved (PLAY_AREA_* constant)
; output:
;	[wce06] += 1
;	[wce08 + e] = some information about the Pokémon in the location from e input (lower 4 bits store
;	              its attached Energy amount and upper 4 bits store its remaining HP divided by 10)
;	[wce0f + e] = deck index from d input (0-59)
.StoreEvolutionInformation
	ld a, DUELVARS_ARENA_CARD_HP
	add e
	get_turn_duelist_var
	call ConvertHPToDamageCounters_Bank8
	swap a
	ld b, a

; count the amount of attached Energy and keep the lowest 4 bits (capped at $0f).
	call GetPlayAreaCardAttachedEnergies
;	ld a, [wTotalAttachedEnergies] ; already loaded
	cp $10
	jr c, .not_maxed_out
	ld a, %00001111
.not_maxed_out
	or b

; 4 high bits of a = this Pokémon's remaining HP (in damage counters)
; 4 low  bits of a = amount of Energy attached to this Pokémon

; store this score in wce08 + PLAY_AREA_* in e.
	ld hl, wce08
	ld c, e
	ld b, $00
	add hl, bc
	ld [hl], a

; store the deck index of the Stage 2 Evolution card in wce0f + PLAY_AREA_* in e.
	ld hl, wce0f
	add hl, bc
	ld [hl], d

; increase wce06 by one.
	ld hl, wce06
	inc [hl]
	ret


; if evolving the Active Pokémon, checks whether DragoniteLv41 would be able to attack.
; if that check fails or if it's evolving a Benched Pokémon, then only play DragoniteLv41
; if its Healing Wind power would remove at least 6 damage counters from the play area.
; preserves all registers except af
; input:
;	d = deck index of the Stage 2 Evolution card being considered (0-59)
;	e = play area location offset of the Pokémon being evolved (PLAY_AREA_* constant)
; output:
;	carry = set:  if DragoniteLv41 is evolving the Active Pokémon and it wouldn't have enough Energy to attack
;	           OR if fewer than 6 damage counters would be removed by DragoniteLv41's Healing Wind power
.HandleDragoniteLv41Evolution
	push bc
	push de
	push hl
	ld a, d
	call _GetCardIDFromDeckIndex
	cp DRAGONITE_LV41
	jr nz, .no_carry ; return no carry if the Evolution card being considered isn't DragoniteLv41
	farcall AIDecidePlayLegendaryDragonite
	jr .done
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


; AI won't play Professor Oak if it's deck count is too low.
; otherwise, it will tally a score and play Professor Oak if the result is high enough.
; there are also several subroutines for specific decks.
; output:
;	carry = set:  if the AI decided to play Professor Oak
AIDecide_ProfessorOak:
; don't play Professor Oak if there are fewer than 7 cards left in the AI's deck.
	ld a, DUELVARS_NUMBER_OF_CARDS_NOT_IN_DECK
	get_turn_duelist_var
	cp DECK_SIZE - 6
	ret nc

; handle some decks differently.
	ld a, [wOpponentDeckID]
	cp LEGENDARY_ARTICUNO_DECK_ID
	jp z, .HandleLegendaryArticunoDeck
	cp EXCAVATION_DECK_ID
	jp z, .HandleExcavationDeck
	cp WONDERS_OF_SCIENCE_DECK_ID
	jp z, .HandleWondersOfScienceDeck

; don't play Professor Oak if there are fewer than 15 cards left in the AI's deck.
.check_cards_deck
	ld a, [hl]
	cp DECK_SIZE - 14
	ret nc

; initialize the score for playing Professor Oak.
	ld a, 30
	ld [wce06], a

; check the number of cards in the AI's hand.
.check_cards_hand
	ld a, DUELVARS_NUMBER_OF_CARDS_IN_HAND
	get_turn_duelist_var
	cp 4
	jr nc, .more_than_3_cards

; increase the score by 50 because there are less than 4 cards in the AI's hand.
	ld a, [wce06]
	add 50
	ld [wce06], a
	jr .check_energy_cards

.more_than_3_cards
	cp 9
	jr c, .check_energy_cards

; decrease the score by 30 because there are more than 8 cards in the AI's hand.
	ld a, [wce06]
	sub 30
	ld [wce06], a

.check_energy_cards
	farcall CreateEnergyCardListFromHand
	jr nc, .handle_blastoise

; increase the score by 40 because there are no Energy cards in the AI's hand.
	ld a, [wce06]
	add 40
	ld [wce06], a

.handle_blastoise
	call CheckIfPkmnPowersAreCurrentlyDisabled
	jr c, .check_hand

; Toxic Gas isn't in effect.
	ld a, BLASTOISE
	call CountTurnDuelistPokemonWithActivePkmnPower
	jr nc, .check_hand

; at least one Blastoise is in the AI's play area.
	ld a, WATER_ENERGY
	farcall LookForCardIDInHand
	jr nc, .check_hand

; increase the score by 10 because Rain Dance is active,
; and none of the Energy in the AI's hand are Water Energy.
	ld a, [wce06]
	add 10
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

; increase the score by 10 because there is at least one Basic Pokémon in the AI's hand.
	ld a, [wce06]
	add 10
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
; if not, go to the next card in the play area
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

; ...increase the score by 10.
	ld a, [wce06]
	add 10
	ld [wce06], a

; only play Professor Oak if the final score is at least twice that of the inital score.
.check_score
	ld a, [wce06]
	ld b, 60
	cp b
	ccf
	ret


; preserves bc and e
; input:
;	e = play area location offset of the Pokémon to check (PLAY_AREA_* constant)
; output:
;	carry = if an Evolution card in the AI's hand can evolve the Pokémon in the given location
;	[wce08] = $01:  if an Evolution card in any card location can evolve the Pokémon in the given location
.LookForEvolution
	xor a
	ld [wce08], a
	ld d, DECK_SIZE

; loop through the whole deck to check if there's
; a card that can evolve this Pokémon.
.loop_deck_evolution
	dec d ; go through deck indices in reverse order
	call CheckIfCanEvolveInto
	jr nc, .can_evolve
.evolution_not_in_hand
	ld a, d
	or a
	jr nz, .loop_deck_evolution
	ret ; nc

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

; AI has less than 3 Pokémon in the play area, so play Professor Oak
; if none of the Evolution cards in hand can be used to evolve those Pokémon.
	push af
	call CreateHandCardList
	pop af
	ld d, a
	ld e, PLAY_AREA_ARENA

.loop_play_area_articuno
	ld a, DUELVARS_ARENA_CARD
	add e
	push de
	get_turn_duelist_var
	farcall CheckForEvolutionInList
	pop de
	jr c, .check_playable_cards

; can't evolve, so move on to the next Pokémon.
	inc e
	dec d
	jr nz, .loop_play_area_articuno

.set_carry
	scf
	ret

.check_playable_cards
; don't play Professor Oak if there are more than 3 Energy cards in hand.
	farcall CreateEnergyCardListFromHand
	cp 4
	ret nc

; remove both Professor Oak cards from the list before checking for playable cards.
	call CreateHandCardList
	ld hl, wDuelTempList
	ld c, PROFESSOR_OAK
	farcall RemoveCardIDInList
	farcall RemoveCardIDInList

; don't play Professor Oak if any other card in the AI's hand can be played,
; but if they're all unplayable, then return carry.
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
; uses a significantly boosted initial score if it doesn't have any Mysterious Fossil in play or in hand.
.HandleExcavationDeck
; don't play Professor Oak if there are fewer than 15 cards left in the AI's deck.
	ld a, [hl]
	cp DECK_SIZE - 14
	ret nc

; search the AI's hand and play area for Mysterious Fossil.
; if none are found, then massively increase the initial score
; before returning to the default logic.
	ld a, MYSTERIOUS_FOSSIL
	call LookForCardIDInHandAndPlayArea
	jr c, .found_mysterious_fossil
	ld a, 80
	ld [wce06], a
	jp .check_cards_hand
.found_mysterious_fossil
	ld a, 30 ; default initial score
	ld [wce06], a
	jp .check_cards_hand


; handles Wonders of Science AI logic.
; do not play Professor Oak if there's either a Grimer or a Muk in the AI's hand.
; if neither are in the hand, then return to the default logic.
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


; AI will only play Energy Retrieval if there are no Energy cards in its hand and
; only if there are multiple copies of the same card in the hand for the discard.
; output:
;	a       = deck index of the card that will be discarded from the AI's hand (0-59)
;	[wce1a] = deck index of a Basic Energy card in the AI's discard pile (0-59)
;	[wce1b] = deck index of another Basic Energy card in the AI's discard pile, if any (0-59)
;	carry = set:  if the AI decided to play Energy Retrieval
AIDecide_EnergyRetrieval:
; don't play Energy Retrieval if there are any Energy cards in the AI's hand.
	farcall CreateEnergyCardListFromHand
	ret nc

; the Go Go Rain Dance deck has some additional logic.
; don't play Energy Retrieval unless Rain Dance is active.
	ld a, [wOpponentDeckID]
	cp GO_GO_RAIN_DANCE_DECK_ID
	jr nz, .start
	call CheckIfPkmnPowersAreCurrentlyDisabled
	jr c, .start
	ld a, BLASTOISE
	call CountTurnDuelistPokemonWithActivePkmnPower
	ret nc

.start
; don't play Energy Retrieval unless there is a duplicate card in the hand to discard.
	call CreateHandCardList
	ld hl, wDuelTempList
	call FindDuplicateCards
	ret nc
	ld [wce06], a ; store the deck index of the duplicate card that will be discarded

; can't play Energy Retrieval if there aren't any Basic Energy card in the AI's discard pile.
	ld a, CARD_LOCATION_DISCARD_PILE
	call FindBasicEnergyCardsInLocation
	ccf
	ret nc

; at least one Basic Energy card was found in the discard pile, so initialize some variables.
	ld hl, wce1a
	ld a, $ff
	ld [hli], a ; [wce1a] = $ff
	ld [hli], a ; [wce1b] = $ff
	ld [hl], a  ; [wce1c] = $ff

; go through the AI's play area Pokémon and check
; if any of the Energy cards in the list are useful.
	ld a, DUELVARS_NUMBER_OF_POKEMON_IN_PLAY_AREA
	get_turn_duelist_var
	ld d, a
	ld e, PLAY_AREA_ARENA
.loop_play_area
	ld a, DUELVARS_ARENA_CARD
	add e

; store this card's ID in wTempCardID and this card's Type in wTempCardType.
	get_turn_duelist_var
	call LoadCardDataToBuffer1_FromDeckIndex
	ld [wTempCardID], a
	ld a, [wLoadedCard1Type]
	or TYPE_ENERGY
	ld [wTempCardType], a

; loop the Energy cards in the discard pile and check if they are useful for this Pokémon.
	ld hl, wDuelTempList
.loop_energy_cards_1
	ld a, [hli]
	cp $ff
	jr z, .next_play_area

	ld b, a
	call CheckIfEnergyIsUseful
	jr nc, .loop_energy_cards_1

; if another card was already chosen, then return carry after storing the second deck index.
	ld a, [wce1a]
	cp $ff
	jr nz, .second_energy

; the first Energy card was found. store its deck index
; and remove it from the discard pile list.
	ld a, b
	ld [wce1a], a
	call RemoveCardFromList

.next_play_area
	inc e
	dec d
	jr nz, .loop_play_area

; next, if there are still Energy cards left to choose,
; loop through the Energy cards again and select them in order.
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

; decide to play Energy Retrieval if at least one Basic Energy card was chosen.
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
	inc a ; cp $ff
	jr z, .play_card
	ld a, [hli] ; wce1d
	ldh [hTempList + 4], a
	inc a ; cp $ff
	jr z, .play_card
	ld a, [hl]  ; wce1e
	ldh [hTempList + 5], a
	ld a, $ff ; list is $ff-terminated
	ldh [hTempList + 6], a ; add terminating byte to hTempList
.play_card
	ld a, OPPACTION_EXECUTE_TRAINER_EFFECTS
	bank1call AIMakeDecision
	ret


; AI will only play Super Energy Retrieval if there are no Energy cards in its hand
; and only if there are at least 2 duplicate cards in the hand to discard.
; output:
;	a       = deck index of the 1st card that will be discarded from the AI's hand (0-59)
;	[wce1a] = deck index of the 2nd card that will be discarded from the AI's hand (0-59)
;	[wce1b] = deck index of a Basic Energy card in the AI's discard pile (0-59)
;	[wce1c] = deck index of a 2nd Basic Energy card in the AI's discard pile, if any (0-59)
;	[wce1d] = deck index of a 3rd Basic Energy card in the AI's discard pile, if any (0-59)
;	[wce1e] = deck index of a 4th Basic Energy card in the AI's discard pile, if any (0-59)
;	carry = set:  if the AI decided to play Super Energy Retrieval
AIDecide_SuperEnergyRetrieval:
; don't play Super Energy Retrieval if there are any Energy cards in the AI's hand.
	farcall CreateEnergyCardListFromHand
	ret nc

; the Go Go Rain Dance deck has some additional logic.
; don't play Super Energy Retrieval unless Rain Dance is active.
	ld a, [wOpponentDeckID]
	cp GO_GO_RAIN_DANCE_DECK_ID
	jr nz, .start
	call CheckIfPkmnPowersAreCurrentlyDisabled
	jr c, .start
	ld a, BLASTOISE
	call CountTurnDuelistPokemonWithActivePkmnPower
	ret nc

.start
; don't play Super Energy Retrieval unless there are duplicate cards in the AI's hand.
	call CreateHandCardList
	ld hl, wDuelTempList
	call FindDuplicateCards
	ret nc

; store the found deck index. remove it from the list, and look for another duplicate.
; don't play Super Energy Retrieval unless another duplicate is found.
	ld [wce06], a
	ld hl, wDuelTempList
	call FindAndRemoveCardFromList
	call FindDuplicateCards
	ret nc
	ld b, a ; store the deck index of the second duplicate card

; can't play Super Energy Retrieval if there aren't any Basic Energy card in the AI's discard pile.
	ld a, CARD_LOCATION_DISCARD_PILE
	call FindBasicEnergyCardsInLocation
	ccf
	ret nc

; at least one Basic Energy card was found in the discard pile, so initialize some variables.
	ld a, b
	ld hl, wce1a
	ld [hli], a
	ld a, $ff
	ld [hli], a ; [wce1b] = $ff
	ld [hli], a ; [wce1c] = $ff
	ld [hli], a ; [wce1d] = $ff
	ld [hli], a ; [wce1e] = $ff
	ld [hl], a  ; [wce1f] = $ff

; go through the AI's play area Pokémon and check
; if any of the Energy cards in the list are useful.
	ld a, DUELVARS_NUMBER_OF_POKEMON_IN_PLAY_AREA
	get_turn_duelist_var
	ld d, a
	ld e, PLAY_AREA_ARENA
.loop_play_area
	ld a, DUELVARS_ARENA_CARD
	add e

; store this card's ID in wTempCardID and this card's Type in wTempCardType.
	get_turn_duelist_var
	call LoadCardDataToBuffer1_FromDeckIndex
	ld [wTempCardID], a
	ld a, [wLoadedCard1Type]
	or TYPE_ENERGY
	ld [wTempCardType], a

; loop the Energy cards in the discard pile and check if they are useful for this Pokémon.
	ld hl, wDuelTempList
.loop_energy_cards_1
	ld a, [hli]
	cp $ff
	jr z, .next_play_area

	ld b, a
	call CheckIfEnergyIsUseful
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

; next, if there are still Energy cards left to choose,
; loop through the Energy cards again and select them in order.
	ld hl, wDuelTempList
.loop_energy_cards_2
	ld a, [hli]
	cp $ff
	jr z, .check_chosen
	ld b, a

; first energy
	ld a, [wce1b]
	cp $ff
	jr nz, .second_energy_2
	ld a, b
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

; decide to play Super Energy Retrieval if at least one Basic Energy card was chosen.
.check_chosen
	ld a, [wce1b]
	cp $ff
	jr nz, .set_carry
	ret ; nc




; Pokémon Center uses 'AIPlay_TrainerCard_NoVars'


; AI gathers max HP, damage, and attached Energy data for each of its Pokémon,
; and then uses that data to decide whether or not to play Pokémon Center.
; output:
;	carry = set:  if the AI decided to play Pokémon Center
AIDecide_PokemonCenter:
; don't play Pokémon Center if the AI's Active Pokémon could KO the Defending Pokémon this turn.
	farcall CheckIfActiveWillNotBeAbleToKODefending
	ret nc

.start
	xor a
	ld [wce06], a ; used for max HP total
	ld [wce08], a ; used for damage total
	ld [wce0f], a ; used for attached Energy total

	ld a, DUELVARS_NUMBER_OF_POKEMON_IN_PLAY_AREA
	get_turn_duelist_var
	ld d, a
	ld e, PLAY_AREA_ARENA

.loop_play_area
	ld a, DUELVARS_ARENA_CARD
	add e
	get_turn_duelist_var
	call LoadCardDataToBuffer1_FromDeckIndex

; get this Pokémon's current HP in number of counters and add it to the total.
	ld a, [wLoadedCard1HP]
	call ConvertHPToDamageCounters_Bank8
	ld b, a
	ld a, [wce06]
	add b
	ld [wce06], a

; get this Pokémon's current damage counters and add it to the total.
	call GetCardDamageAndMaxHP
	call ConvertHPToDamageCounters_Bank8
	ld b, a
	ld a, [wce08]
	add b
	ld [wce08], a

; get the amount of Energy attached to this Pokémon and add it to the total.
; don't play Pokémon Center if there's an overflow (i.e. more than 255 attached Energy).
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

; don't play Pokémon Center if (total number of damage counters / 2) < (total number of attached Energy cards).
	ld a, [wce08]
	srl a
	ld hl, wce0f
	cp [hl]
	ccf
	ret nc

; don't play Pokémon Center if (number of HP counters * 6 / 10) >= (number of damage counters).
; essentially, only play Pokémon Center if combined HP of all play area Pokémon is less than 60% of max.
	ld a, [wce06]
	ld l, a
	ld h, 6
	call HtimesL
	call HLDividedBy10
	ld a, l
	ld hl, wce08
	cp [hl]
	ret




; Imposter Professor Oak uses 'AIPlay_TrainerCard_NoVars'


; AI checks the number of cards in the Player's deck and hand
; and only decides to play Imposter Professor Oak if:
;	- Player's deck > 14 cards and Player's hand > 8 cards
;	- Player's deck < 15 cards and Player's hand < 6 cards
; basically, the early game goal is to limit the Player's resources,
; and the late game goal is to encourage the Player to lose via deck out.
; preserves bc and de
; output:
;	carry = set:  if the AI decided to play Imposter Professor Oak
AIDecide_ImposterProfessorOak:
	ld a, DUELVARS_NUMBER_OF_CARDS_NOT_IN_DECK
	call GetNonTurnDuelistVariable
	cp DECK_SIZE - 14
	jr c, .more_than_14_cards

; if the Player has fewer than 15 cards left in their deck, then only
; play Imposter Professor Oak if there are fewer than 6 cards in the Player's hand.
	ld l, DUELVARS_NUMBER_OF_CARDS_IN_HAND
	ld a, [hl]
	cp 6
	ret

; if the Player has more than 14 cards left in their deck, then only
; play Imposter Professor Oak if there are at least 9 cards in the Player's hand.
.more_than_14_cards
	ld l, DUELVARS_NUMBER_OF_CARDS_IN_HAND
	ld a, [hl]
	cp 9
	ccf
	ret




; Energy Search uses 'AIPlay_TrainerCard_OneVar'


; AI checks for playing Energy Search
; output:
;	carry = set:  if the AI decided to play Energy Search
AIDecide_EnergySearch:
; don't play Energy Search if there is at least one Energy card
; in the AI's hand that is useful to a Pokémon in the play area.
	farcall CreateEnergyCardListFromHand
	jr c, .start
	; there is already at least one Energy card in the AI's hand
	call LookForUsefulEnergyCardInList
	ret nc ; return if at least one of those Energy cards is useful.

.start
; can't play Energy Search if there are no Basic Energy cards left in the AI's deck.
	ld a, CARD_LOCATION_DECK
	call FindBasicEnergyCardsInLocation
	ccf
	ret nc

; handle some decks differently.
	ld a, [wOpponentDeckID]
	cp HEATED_BATTLE_DECK_ID
	jr z, LookForUsefulEnergyCardInList_OnlyCheckFireAndLightningPokemon
	cp WONDERS_OF_SCIENCE_DECK_ID
	jr z, LookForUsefulEnergyCardInList_OnlyCheckGrassPokemon

; if any of the Basic Energy cards in the deck is useful
; for a play area Pokémon, then pick one of them and return carry.
	call LookForUsefulEnergyCardInList
	ret c

; otherwise, just pick the first Basic Energy card that was found.
	ld a, [wDuelTempList]
	scf
	ret


; preserves c
; input:
;	wDuelTempList = $ff-terminated list with deck indices of Energy cards
; output:
;	a & b = deck index of an Energy card in wDuelTempList that can be used
;	        by a Fire or Lightning Pokémon in the AI's play area, if any (0-59)
;	carry = set:  if a useful Energy card was found in wDuelTempList
LookForUsefulEnergyCardInList_OnlyCheckFireAndLightningPokemon:
	ld a, DUELVARS_NUMBER_OF_POKEMON_IN_PLAY_AREA
	get_turn_duelist_var
	ld d, a
	ld e, PLAY_AREA_ARENA

.loop_play_area
	ld a, DUELVARS_ARENA_CARD
	add e
	get_turn_duelist_var

; store the Pokémon's card ID and equivalent Energy type.
	call LoadCardDataToBuffer1_FromDeckIndex
	ld [wTempCardID], a
	ld a, [wLoadedCard1Type]
	cp TYPE_PKMN_FIRE
	jr z, .fire_or_lightning
	cp TYPE_PKMN_LIGHTNING
	jr nz, .next_play_area ; skip if not a Fire or Lightning Pokémon
.fire_or_lightning
	or TYPE_ENERGY
	ld [wTempCardType], a

; try to find a useful Energy in wDuelTempList.
	ld hl, wDuelTempList
.loop_energy
	ld a, [hli]
	cp $ff
	jr z, .next_play_area
	ld b, a
	call CheckIfEnergyIsUseful
	jr nc, .loop_energy

; a useful Energy card was found, so output the deck index in a and return carry.
	ld a, b
	ret

.next_play_area
	inc e
	ld a, e
	cp d
	jr nz, .loop_play_area
	; no useful Energy cards were found, so return no carry.
	ret


; input:
;	wDuelTempList = $ff-terminated list with deck indices of Energy cards
; output:
;	a & b = deck index of an Energy card in wDuelTempList that can be used
;	        by a Grass Pokémon in the AI's play area, if any (0-59)
;	carry = set:  if a useful Energy card was found in wDuelTempList
LookForUsefulEnergyCardInList_OnlyCheckGrassPokemon:
	ld c, TYPE_PKMN_GRASS
;	fallthrough

; input:
;	c = TYPE_PKMN_* constant
;	wDuelTempList = $ff-terminated list with deck indices of Energy cards
; output:
;	a & b = deck index of an Energy card in wDuelTempList that can be used
;	        by a Pokémon of the given type in the AI's play area, if any (0-59)
;	carry = set:  if a useful Energy card was found in wDuelTempList
LookForUsefulEnergyCardInList_OnlyCheckPokemonOfGivenType:
	ld a, DUELVARS_NUMBER_OF_POKEMON_IN_PLAY_AREA
	get_turn_duelist_var
	ld d, a
	ld e, PLAY_AREA_ARENA

.loop_play_area
	ld a, DUELVARS_ARENA_CARD
	add e
	get_turn_duelist_var

; store the Pokémon's card ID and equivalent Energy type.
	call LoadCardDataToBuffer1_FromDeckIndex
	ld [wTempCardID], a
	ld a, [wLoadedCard1Type]
	cp c
	jr nz, .next_play_area ; skip this Pokémon if it's type doesn't match c input
	or TYPE_ENERGY
	ld [wTempCardType], a

; try to find a useful Energy in wDuelTempList.
	ld hl, wDuelTempList
.loop_energy
	ld a, [hli]
	cp $ff
	jr z, .next_play_area
	ld b, a
	call CheckIfEnergyIsUseful
	jr nc, .loop_energy

; a useful Energy card was found, so output the deck index in a and return carry.
	ld a, b
	ret

.next_play_area
	inc e
	ld a, e
	cp d
	jr nz, .loop_play_area
	; no useful Energy cards were found, so return no carry.
	ret


; preserves c
; input:
;	wDuelTempList = $ff-terminated list with deck indices of Energy cards
; output:
;	a & b = deck index of an Energy card in wDuelTempList that can be used
;	        by one of the Pokémon in the AI's play area, if any (0-59)
;	carry = set:  if a useful Energy card was found in wDuelTempList
LookForUsefulEnergyCardInList:
	ld a, DUELVARS_NUMBER_OF_POKEMON_IN_PLAY_AREA
	get_turn_duelist_var
	ld d, a
	ld e, PLAY_AREA_ARENA

.loop_play_area
	ld a, DUELVARS_ARENA_CARD
	add e
	get_turn_duelist_var

; store the Pokémon's card ID and equivalent Energy type.
	call LoadCardDataToBuffer1_FromDeckIndex
	ld [wTempCardID], a
	ld a, [wLoadedCard1Type]
	or TYPE_ENERGY
	ld [wTempCardType], a

; try to find a useful Energy in wDuelTempList.
	ld hl, wDuelTempList
.loop_energy
	ld a, [hli]
	cp $ff
	jr z, .next_play_area
	ld b, a
	call CheckIfEnergyIsUseful
	jr nc, .loop_energy

; a useful Energy card was found, so output the deck index in a and return carry.
	ld a, b
	ret

.next_play_area
	inc e
	dec d
	jr nz, .loop_play_area
	; no useful Energy cards were found, so return no carry.
	ret




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


; AI will only play Pokédex if it's been at least 5 turns since
; a Pokédex was last played and there's at least 5 cards in the deck.
; if both are true, then there's a 30% chance that the card will be played.
; most decks will prioritize Energy, then Pokémon, then Trainers,
; but Rick's Wonders of Science deck will pick Pokémon, Trainers, and then Energy.
; input:
;	[wce1a] = deck index of the card that should be placed on top of the deck (0-59)
;	[wce1b] = deck index of the card that should be placed below the previous card (0-59)
;	[wce1c] = deck index of the card that should be placed below the previous card (0-59)
;	[wce1d] = deck index of the card that should be placed below the previous card (0-59)
;	[wce1e] = deck index of the card that should be placed below the previous card (0-59)
;	carry = set:  if the AI decided to play Pokédex
AIDecide_Pokedex:
; don't play Pokédex if it hasn't been at least 5 turns since the last Pokédex was played.
	ld a, [wAIPokedexCounter]
	cp 5
	ccf
	ret nc

; don't play Pokédex if there aren't at least 5 cards in the AI's deck.
	ld a, DUELVARS_NUMBER_OF_CARDS_NOT_IN_DECK
	get_turn_duelist_var
	cp DECK_SIZE - 4
	ret nc

; randomly decide to not play Pokédex 70% of the time.
	ld a, 10
	call Random
	cp 3
	ret nc

; switch to a custom subroutine if the NPC opponent is using the Wonders of Science deck.
.pick_cards
	ld a, [wOpponentDeckID]
	cp WONDERS_OF_SCIENCE_DECK_ID
	jp nz, PickPokedexCards_EnergyPokemonTrainer
	; fallthrough for the Wonders of Science deck

; picks the new order for the top 5 cards of the AI's deck.
; prioritizes Pokémon cards, then Trainer cards, then Energy cards.
; stores the resulting order in wce1a, wce1b, wce1c, wce1d, and wce1e.
; output:
;	carry = set
PickPokedexCards_PokemonTrainerEnergy:
	xor a
	ld [wAIPokedexCounter], a ; reset counter

	ld a, DUELVARS_NUMBER_OF_CARDS_NOT_IN_DECK
	get_turn_duelist_var
	add DUELVARS_DECK_CARDS
	ld l, a
	ld de, 0 ; offset for storing the cards in wram
	ld b, 5  ; number of cards that should be reordered

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

; find Pokémon
	ld hl, wce08
	lb bc, 0, -1

; run through the stored cards and look for any Pokémon cards.
.loop_pokemon
	inc c
	ld a, [hli]
	cp $ff
	jr z, .find_trainers
	cp TYPE_ENERGY
	jr nc, .loop_pokemon
; found a Pokémon, so store it in wce1a list
	push hl
	ld hl, wce0f
	add hl, bc
	ld a, [hl]
	pop hl
	ld [de], a
	inc de
	jr .loop_pokemon

; run through the stored cards and look for any Trainer cards.
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

; run through the stored cards and look for any Energy cards.
.loop_energy
	inc c
	ld a, [hli]
	cp $ff
	jr z, .done
	and TYPE_ENERGY
	jr z, .loop_energy
; found an Energy card
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


; picks the new order for the top 5 cards of the AI's deck.
; prioritizes Energy cards, then Pokémon cards, then Trainer cards.
; stores the resulting order in wce1a, wce1b, wce1c, wce1d, and wce1e.
; output:
;	carry = set
PickPokedexCards_EnergyPokemonTrainer:
	xor a
	ld [wAIPokedexCounter], a ; reset counter

	ld a, DUELVARS_NUMBER_OF_CARDS_NOT_IN_DECK
	get_turn_duelist_var
	add DUELVARS_DECK_CARDS
	ld l, a
	ld de, 0 ; offset for storing the cards in wram
	ld b, 5  ; number of cards that should be reordered

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

; run through the stored cards and look for any Energy cards.
.loop_energy
	inc c
	ld a, [hli]
	cp $ff
	jr z, .find_pokemon
	and TYPE_ENERGY
	jr z, .loop_energy
; found an Energy card
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

; run through the stored cards and look for any Pokémon cards.
.loop_pokemon
	inc c
	ld a, [hli]
	cp $ff
	jr z, .find_trainers
	cp TYPE_ENERGY
	jr nc, .loop_pokemon
; found a Pokémon, so store it in wce1a list
	push hl
	ld hl, wce0f
	add hl, bc
	ld a, [hl]
	pop hl
	ld [de], a
	inc de
	jr .loop_pokemon

; run through the stored cards and look for any Trainer cards.
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


; AI will always play Full Heal if its Active Pokémon is Poisoned,
; but it will run through various checks before deciding whether or not to
; play the card if its Active Pokémon is Asleep, Confused, or Paralyzed.
; output:
;	carry = set:  if the AI decided to play Full Heal
AIDecide_FullHeal:
; can't play Full Heal unless the AI's Active Pokémon is affected by a Special Condition.
	ld a, DUELVARS_ARENA_CARD_STATUS
	get_turn_duelist_var
	or a ; cp NO_STATUS
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

; preserves de
; input:
;	a = card ID to look for
; output:
;	carry = set:  if the Player's Active Pokémon is a copy of the given card
.CheckPlayerArenaCard:
	rst SwapTurn
	ld b, PLAY_AREA_ARENA
	call LookForCardIDInPlayArea_Bank8
	jp SwapTurn

.asleep
; set carry if there's a HaunterLv22 or any Gastly in the
; Player's play area (due to Haunter's Dream Eater attack).
	ld a, GASTLY_LV8
	call .CheckPlayerArenaCard
	ret c
	ld a, GASTLY_LV17
	call .CheckPlayerArenaCard
	ret c
	ld a, HAUNTER_LV22
	call .CheckPlayerArenaCard
	ret c
;	fallthrough

.paralyzed
; don't play Full Heal if the AI will decide to play Scoop Up later in the turn.
	ld a, SCOOP_UP
	call LookForCardIDInHandList_Bank8
	jr nc, .no_scoop_up_prz
	call AIDecide_ScoopUp
	ccf
	ret nc

; return carry if the Active Pokémon can damage the Defending Pokémon.
.no_scoop_up_prz
; temporarily remove status effect to check the damage.
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

; if it can play an Energy card to retreat, set carry.
	ld a, [wAIPlayEnergyCardForRetreat]
	or a
	jr nz, .set_carry

; if not, check whether it's a card it would rather retreat,
; and if it isn't, set carry.
	farcall AIDecideWhetherToRetreat
	ccf
	ret

.confused
; don't play Full Heal if the AI will decide to play Scoop Up later in the turn.
	ld a, SCOOP_UP
	call LookForCardIDInHandList_Bank8
	jr nc, .no_scoop_up_cnf
	call AIDecide_ScoopUp
	ccf
	ret nc

.no_scoop_up_cnf
; if this Pokémon can damage the Defending Pokémon...
	xor a ; PLAY_AREA_ARENA
	farcall CheckIfCanDamageDefendingPokemon
	ret nc
; ...and can play an Energy card to retreat, set carry.
	ld a, [wAIPlayEnergyCardForRetreat]
	or a
	jr nz, .set_carry
; if not, return no carry.
	ret




; Mr. Fuji uses 'AIPlay_TrainerCard_OneVar'


; AI will only play Mr. Fuji if it has a Benched Pokémon
; with remaining HP that's less than 1/3 its maximum HP.
; output:
;	a & [wce06] = chosen Pokémon's play area location offset (PLAY_AREA_* constant)
;	carry = set:  if the AI decided to play Mr. Fuji
AIDecide_MrFuji:
	ld a, $ff
	ld [wce06], a
	ld [wce08], a

; can't play Mr. Fuji if the AI doesn't have any Benched Pokémon.
	ld a, DUELVARS_NUMBER_OF_POKEMON_IN_PLAY_AREA
	get_turn_duelist_var
	dec a
	or a
	ret z ; return no carry if there are no Benched Pokémon

	ld d, a
	ld e, PLAY_AREA_BENCH_1

; find a Benched Pokémon that has damage counters.
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

; a = number of damage counters on the Pokémon
; b = the Pokémon's remaining HP
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


; most AI opponents will only play Scoop Up on their Active Pokémon and
; only if it can't KO or retreat and has less than 30% of its max HP.
; The Legendary Articuno and Legendary Ronald decks have their own logic.
; output:
;	a = play area location offset of the Pokemon to scoop up (PLAY_AREA_* constant)
;	[wce1a] = play area location offset of the Benched Pokemon to switch in:  if a = PLAY_AREA_ARENA
;	carry = set:  if the AI decided to play Scoop Up
AIDecide_ScoopUp:
; can't play Scoop Up unless the AI has at least 2 Pokémon in play.
	ld a, DUELVARS_NUMBER_OF_POKEMON_IN_PLAY_AREA
	get_turn_duelist_var
	cp 1
	ret z ; return no carry if there are no Benched Pokémon

; handle some decks differently.
	ld a, [wOpponentDeckID]
	cp LEGENDARY_ARTICUNO_DECK_ID
	jr z, .HandleLegendaryArticuno
	cp LEGENDARY_RONALD_DECK_ID
	jp z, .HandleLegendaryRonald

; don't play Scoop Up if the AI's Active Pokémon could KO the Defending Pokémon this turn.
	farcall CheckIfActiveWillNotBeAbleToKODefending
	ret nc

; Active Pokémon won't be able to KO, so check if it can retreat.
	call CheckUnableToRetreatDueToEffect
	jr c, .cannot_retreat

; nothing is preventing the Active Pokémon from retreating, so check if
; it has enough Energy to retreat, and if it does, then don't play Scoop Up.
	xor a ; PLAY_AREA_ARENA
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

; don't play Scoop Up if (total damage / total HP counters) < 7.
; (this corresponds to damage counters being under 70% of the max HP)
	ld b, a
	ld a, d
	call CalculateBDividedByA_Bank8
	cp 7
	ccf
	ret nc

; store Pokémon to switch to in wce1a and set carry.
.decide_switch
	farcall AIDecideBenchPokemonToSwitchTo
	ccf
	ret nc ; can't play Scoop Up if there are no Benched Pokémon to switch with.
	ld [wce1a], a
	xor a ; PLAY_AREA_ARENA
	scf
	ret

; this deck will use Scoop Up on a Benched ARTICUNO_LV37
; or on an Active ArticunoLv37/Chansey under specific circumstances.
.HandleLegendaryArticuno
; don't play Scoop Up unless the AI has at least 3 Pokémon in play.
	ld a, DUELVARS_NUMBER_OF_POKEMON_IN_PLAY_AREA
	get_turn_duelist_var
	cp 3
	ccf
	ret nc

; look for ArticunoLv37 on the Bench
	ld a, ARTICUNO_LV37
	ld b, PLAY_AREA_BENCH_1
	call LookForCardIDInPlayArea_Bank8
	jr c, .articuno_bench

; check the Active Pokémon
	ld a, DUELVARS_ARENA_CARD
	get_turn_duelist_var
	call _GetCardIDFromDeckIndex
	cp ARTICUNO_LV37
	jr z, .articuno_or_chansey
	cp CHANSEY
	jr z, .articuno_or_chansey
	or a
	ret

; either ArticunoLv37 or Chansey is the Active Pokémon. if it can't KO the
; Defending Pokémon but the Defending Pokémon can KO it, then set carry.
; return no carry in all other scenarios.
.articuno_or_chansey
; don't play Scoop Up if the AI's Active Pokémon could KO the Defending Pokémon this turn.
	farcall CheckIfActiveWillNotBeAbleToKODefending
	ret nc

; next, check if the Defending Pokémon can KO the AI's Active Pokémon next turn,
; and only decide to play Scoop Up if it can.
	farcall CheckIfDefendingPokemonCanKnockOut
	ret nc
	jr .decide_switch

.articuno_bench
	ld e, a
	rst SwapTurn
	call CheckIfActiveCardCanBeAffectedByStatus
	rst SwapTurn
	ret nc ; return no carry if the Defending Pokémon can't be Paralyzed

; check attached Energy cards.
; if it has any, return no carry.
	ld a, e
.check_attached_energy
	ld e, a
	call GetPlayAreaCardAttachedEnergies
	or a
	ret nz ; return no carry if this Pokémon has any attached Energy cards

; don't play Scoop Up unless Pokémon Powers can be used.
	call CheckIfPkmnPowersAreCurrentlyDisabled
	ccf
	ret nc

; has decided to Scoop Up a Benched Pokémon,
; store -1 as the Pokémon card to switch to
; because there's no need to switch.
	ld a, -1
	ld [wce1a], a
	ld a, e
	ret

; this deck will use Scoop Up on a Benched ArticunoLv37, ZapdosLv68 or MoltresLv37
; if it doesn't have any attached Energy cards and there's no Muk in the play area.
.HandleLegendaryRonald
; don't play Scoop Up unless the AI has at least 3 Pokémon in play.
	ld a, DUELVARS_NUMBER_OF_POKEMON_IN_PLAY_AREA
	get_turn_duelist_var
	cp 3
	ccf
	ret nc

; look for specific Pokémon on the AI's Bench.
	ld a, ARTICUNO_LV37
	ld b, PLAY_AREA_BENCH_1
	call LookForCardIDInPlayArea_Bank8
	call c, .articuno_bench
	ret c ; return if AI decided to use Scoop Up on a Benched ArticunoLv37
	ld a, ZAPDOS_LV68
	ld b, PLAY_AREA_BENCH_1
	call LookForCardIDInPlayArea_Bank8
	call c, .check_attached_energy
	ret c ; return if AI decided to use Scoop up on a Benched ZapdosLv68
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


; all AI opponents other than Imakuni? will only play Maintenance
; if there are duplicate card in the hand to shuffle back into the deck.
; Imakuni? will randomly decide to play Maintenance 20% of the time.
; output:
;	[wce1a] = deck index of the first card that was selected from the AI's hand (0-59)
;	[wce1b] = deck index of the second card that was selected from the AI's hand (0-59)
;	carry = set:  if the AI decided to play Maintenance
AIDecide_Maintenance:
; switch to a custom subroutine if the NPC opponent is Imakuni?.
	ld a, [wOpponentDeckID]
	cp IMAKUNI_DECK_ID
	jr z, .imakuni

; don't play Maintenance if there are fewer than 4 cards in the AI's hand.
	ld a, DUELVARS_NUMBER_OF_CARDS_IN_HAND
	get_turn_duelist_var
	cp 4
	ccf
	ret nc

; create a list of the cards in the AI's hand and remove wAITrainerCardToPlay
; from the list. then, try to find duplicate cards to discard.
	call CreateHandCardList
	ld hl, wDuelTempList
	ld a, [wAITrainerCardToPlay]
	call FindAndRemoveCardFromList
; if duplicates are not found, return no carry.
	call FindDuplicateCards
	ret nc

; store the first duplicate card and remove it from the list.
; then, search for another duplicate.
	ld [wce1a], a
	ld hl, wDuelTempList
	call FindAndRemoveCardFromList
; if duplicates are not found, return no carry.
	call FindDuplicateCards
	ret nc

; store the second duplicate card and return carry.
	ld [wce1b], a
	ret ; carry set

.imakuni
; Imakuni? randomly decides to not play Maintenance 80% of the time.
	ld a, 10
	call Random
	cp 2
	ret nc

; can't play Maintenance if there are fewer than 3 cards (including Maintenance) in hand.
	ld a, DUELVARS_NUMBER_OF_CARDS_IN_HAND
	get_turn_duelist_var
	cp 3
	ccf
	ret nc

; create a randomized list of every card in the AI's hand.
	call CreateHandCardList
	ld hl, wDuelTempList
	call ShuffleCards

; find the first 2 cards that are different from wAITrainerCardToPlay
; and store those deck indices in wce1a and wce1b.
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
	ld a, -1
	ldh [hTemp_ffa0], a
.play_card
	ld a, OPPACTION_EXECUTE_TRAINER_EFFECTS
	bank1call AIMakeDecision
	ret


; AI uses Recycle on a discarded Trainer when not using a deck with a given
; priority list, which includes Ken's Fire Charge deck and Robert's Ghost Deck.
; output:
;	a = deck index of the card that was chosen from the discard pile (0-59)
;	carry = set:  if the AI decided to play Recycle
AIDecide_Recycle:
; can't play Recycle if there are no cards in the AI's discard pile.
	call CreateDiscardPileCardList
	ccf
	ret nc

; initialize a priority list.
	ld hl, wce08
	ld a, $ff
	ld [hli], a
	ld [hli], a
	ld [hli], a
	ld [hli], a
	ld [hl], a

; try to jump to a customized priority list with up to 5 card IDs to look for.
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

; priority list for Ken's Fire Charge deck
.fire_charge_search_loop
	ld a, [hli]
	cp $ff
	jr z, .done

	ld b, a
	call _GetCardIDFromDeckIndex

; double colorless energy
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

; loop through wce08 and set carry after outputting
; the deck index of the first card that was found.
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

; priority list for Robert's Ghost deck
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


; AI will only play Lass if there are no other Trainer cards in its hand.
; the Player must also have at least 7 cards in their hand.
; output:
;	carry = set:  if the AI decided to play Lass
AIDecide_Lass:
; skip if the Player has less than 7 cards in hand.
	ld a, DUELVARS_NUMBER_OF_CARDS_IN_HAND
	call GetNonTurnDuelistVariable
	cp 7
	ccf
	ret nc

; look for Trainer cards in the AI's hand (except for Lass).
; if any are found, return no carry.
; otherwise, return carry.
	call CreateHandCardList
	ld hl, wDuelTempList
.loop
	ld a, [hli]
	cp $ff
	scf
	ret z ; return carry if there are no more cards to check
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
; output:
;	a = deck index of a Trainer card in the AI's discard pile (to add to the hand) (0-59)
;	[wce1a] = deck index of a duplicate card in the AI's hand (to discard) (0-59)
;	[wce1b] = deck index of another duplicate card in the AI's hand (to discard) (0-59)
;	carry = set:  if the AI decided to play Item Finder
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

; choose 2 cards to discard from the hand.
	call CreateHandCardList
.choose_discard
	ld hl, wDuelTempList

; do not discard wAITrainerCardToPlay.
	ld a, [wAITrainerCardToPlay]
	call FindAndRemoveCardFromList
; look for a duplicate and return no carry if none were found.
	call FindDuplicateCards
	ret nc

; store the duplicate's deck index in wce1a and remove it from the hand list.
	ld [wce1a], a
	ld hl, wDuelTempList
	call FindAndRemoveCardFromList
; look for another duplicate and return no carry if none were found.
	call FindDuplicateCards
	ret nc

; store the duplicate's deck index in wce1b and
; output the card to be recovered from the discard pile.
	ld [wce1b], a
	ld a, [wce06]
	ret ; carry set


; look for Energy Removal in the discard pile
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

; before looking for cards to discard from the hand,
; remove any Mr. Mime and Pokémon Trader cards.
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


; AI will decide to play Imakuni? if it's Active Pokémon isn't already Confused.
; preserves bc and de
; output:
;	carry = set:  if the AI decided to play Imakuni?
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


; all AI opponents other than Imakuni? will only play Gambler
; if the Player is using a MewtwoLv53 stall deck and only once
; they have less than 5 cards left in their deck.
; Imakuni? will randomly decide to play Gambler 20% of the time.
; preserves bc and de
; output:
;	carry = set:  if the AI decided to play Gambler
AIDecide_Gambler:
; switch to a custom subroutine if the NPC opponent is Imakuni?.
	ld a, [wOpponentDeckID]
	cp IMAKUNI_DECK_ID
	jr z, .imakuni

; check if the Player is using a deck with only MewtwoLv53.
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
; Imakuni? randomly decides to play Gambler exactly 20% of the time.
	ld a, 10
	call Random
	cp 2
	ret




; Revive uses 'AIPlay_TrainerCard_OneVar'


; all AI opponents other than Chris will use Revive on the Basic Pokémon
; with the highest HP in their discard pile, but only if it has
; at least 50 HP and only if there are fewer than 3 Benched Pokémon.
; Chris's Muscles for Brains deck will try to target specific Pokémon in the discard pile.
; output:
;	a = deck index of the Basic Pokémon card that was chosen (0-59)
;	carry = set:  if the AI decided to play Revive
AIDecide_Revive:
; can't play Revive if there are no cards in the AI's discard pile.
	call CreateDiscardPileCardList
	ccf
	ret nc

; don't play Revive if there's already 3 or more Benched Pokémon.
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
	dec a ; $ff
	ld [wce08], a

; find the Basic Pokémon with the highest HP in the discard pile.
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

; look in the discard pile for specific Pokémon.
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




; Pokémon Flute uses 'AIPlay_TrainerCard_OneVar'


; all AI opponents other than Imakuni? will only play Pokémon Flute
; if there's a Basic Pokémon with less than 50 HP in the Player's discard pile.
; Imakuni? will randomly decide to play Pokémon Flute 20% of the time,
; and he'll target the first Basic Pokémon in the Player's discard pile.
; output:
;	a = deck index of the Basic Pokémon card that was chosen (0-59)
;	carry = set:  if the AI decided to play Pokémon Flute
AIDecide_PokemonFlute:
; can't play Pokémon Flute if the Player has no cards in their discard pile.
	rst SwapTurn
	call CreateDiscardPileCardList
	ccf
	jr nc, .done

; can't play Pokémon Flute if there's no room on the Player's Bench.
	ld a, DUELVARS_NUMBER_OF_POKEMON_IN_PLAY_AREA
	get_turn_duelist_var
	cp MAX_PLAY_AREA_POKEMON
	jr nc, .done

; switch to a custom subroutine if the NPC opponent is Imakuni?.
	ld a, [wOpponentDeckID]
	cp IMAKUNI_DECK_ID
	jr z, .imakuni

	ld a, $ff
	ld [wce06], a
	ld [wce08], a

; find the Basic Pokémon with the lowest HP in the discard pile.
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
; if lower, store this card's HP and deck index
	ld [wce06], a
	ld a, b
	ld [wce08], a
	jr .loop_1

.check_lowest_hp
; only play Pokémon Flute if the lowest HP value was less than 50.
	ld a, [wce06]
	cp 50
	ld a, [wce08]
.done
	jp SwapTurn

.imakuni
; Imakuni? randomly decides to not play Pokémon Flute 80% of the time.
	ld a, 10
	call Random
	cp 2
	jr nc, .done

; look for any Basic Pokémon card.
	ld hl, wDuelTempList
.loop_2
	ld a, [hli]
	cp $ff
	jr z, .done
	ld b, a
	call CheckDeckIndexForBasicPokemon
	jr nc, .loop_2

; return carry with the Basic Pokémon's deck index in a.
	rst SwapTurn
	ld a, b
	ret ; carry set




; Clefairy Doll and Mysterious Fossil use 'AIPlay_TrainerCard_NoVars'


; AI will only play Clefairy Doll or Mysterious Fossil if it has
; fewer than 3 Benched Pokémon or if its Active Pokémon is Wigglytuff.
; preserves de and c
; output:
;	carry = set:  if the AI decided to play this card
AIDecide_ClefairyDollOrMysteriousFossil:
; can't play this card if the Bench is already full.
	ld a, DUELVARS_NUMBER_OF_POKEMON_IN_PLAY_AREA
	get_turn_duelist_var
	ld b, a
	cp MAX_PLAY_AREA_POKEMON
	ret nc

; always play this card if the Active Pokémon is Wigglytuff.
	ld a, DUELVARS_ARENA_CARD
	get_turn_duelist_var
	call _GetCardIDFromDeckIndex
	cp WIGGLYTUFF
	scf
	ret z

; don't play this card if there's already 3 or more Benched Pokémon.
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
	ld a, -1
	ldh [hTemp_ffa0], a
.play_card
	ld a, OPPACTION_EXECUTE_TRAINER_EFFECTS
	bank1call AIMakeDecision
	ret


; every deck that currently contains Poké Ball has its own priority list.
; if Poké Ball is in a deck that isn't listed, then the AI will
; look for a Basic Pokémon if it has fewer than 3 Pokémon in play,
; then a card that evolves from a play area Pokémon, then any Pokémon.
; output:
;	a = deck index of the Pokémon card that was chosen from the deck (0-59)
;	carry = set:  if the AI decided to play Poké Ball
AIDecide_Pokeball:
; use the opponent's Deck ID to switch to the correct subroutine.
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
; given a specific Energy card in the hand.
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


; this deck looks for Evolution cards if a pre-evolution is in either the hand or the play area.
; if none of these are found, it looks for pre-evolutions of cards it has in hand.
; it does this for both the NidoranM (first) and NidoranF (second) families.
.lovely_nidoran
; pick Nidorino if it was found in the deck but not the hand/play area and Nidoran M was also found in the hand/play area.
	ld b, NIDORANM
	ld a, NIDORINO
	call LookForCardIDInDeck_GivenCardIDInHandAndPlayArea
	ret c
; pick Nidoking if it was found in the deck but not the hand/play area and Nidorino was also found in the hand/play area.
	ld b, NIDORINO
	ld a, NIDOKING
	call LookForCardIDInDeck_GivenCardIDInHandAndPlayArea
	ret c
; pick Nidoran M if it was found in the deck but not the hand/play area and Nidorino was also found in the hand.
	ld a, NIDORANM
	ld b, NIDORINO
	call LookForCardIDInDeck_GivenCardIDInHand
	ret c
; pick Nidorino if it was found in the deck but not the hand/play area and Nidoking was also found in the hand.
	ld a, NIDORINO
	ld b, NIDOKING
	call LookForCardIDInDeck_GivenCardIDInHand
	ret c
; pick Nidorina if it was found in the deck but not the hand/play area and Nidoran F was also found in the hand/play area.
	ld b, NIDORANF
	ld a, NIDORINA
	call LookForCardIDInDeck_GivenCardIDInHandAndPlayArea
	ret c
; pick Nidoqueen if it was found in the deck but not the hand/play area and Nidorina was also found in the hand/play area.
	ld b, NIDORINA
	ld a, NIDOQUEEN
	call LookForCardIDInDeck_GivenCardIDInHandAndPlayArea
	ret c
; pick Nidoran F if it was found in the deck but not the hand/play area and Nidorina was also found in the hand.
	ld a, NIDORANF
	ld b, NIDORINA
	call LookForCardIDInDeck_GivenCardIDInHand
	ret c
; pick Nidorina if it was found in the deck but not the hand/play area and Nidoqueen was also found in the hand.
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


; every deck that contains Computer Search has its own subroutine.
; output:
;	a = deck index of the card to move from the deck to the hand (0-59)
;	[wce1a] = deck index of the first card to discard from the hand (0-59)
;	[wce1b] = deck index of the second card to discard from the hand (0-59)
;	carry = set:  if the AI decided to play Computer Search
AIDecide_ComputerSearch:
; can't play Computer Serach if there aren't at least 2 other cards in the AI's hand.
	ld a, DUELVARS_NUMBER_OF_CARDS_IN_HAND
	get_turn_duelist_var
	cp 3
	jr c, .no_carry

; use the opponent's Deck ID to switch to the correct subroutine.
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


; the Rock Crusher deck tries to search for either a Professor Oak card or
; a specific Evolution card, depending on the other cards in its hand.
AIDecide_ComputerSearch_RockCrusher:
; if there are exactly 3 cards in the AI's hand,
; then only search for a Professor Oak card.
	ld a, DUELVARS_NUMBER_OF_CARDS_IN_HAND
	get_turn_duelist_var
	cp 3
	jr nz, .graveler

; don't play Computer Search unless there's a Professor Oak card in the AI's deck.
	ld e, PROFESSOR_OAK
	ld a, CARD_LOCATION_DECK
	call LookForCardIDInLocation_Bank8
	ret nc

	ld [wce06], a ; store the deck index of the Professor Oak card that was found for later
	call CreateHandCardList
	ld hl, wDuelTempList
	ld de, wce1a
	ld b, 2 ; number of cards that need to be discarded
	ld a, [wAITrainerCardToPlay]
	ld c, a
.loop_hand_1
	ld a, [hli]
	cp $ff
	ret z ; return no carry if there are no more cards in the hand to check
	cp c
	jr z, .loop_hand_1 ; skip this card if it's the Trainer card that's being decided

; don't play Computer Search if any of the following cards are in the AI's hand.
	call _GetCardIDFromDeckIndex
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
	ret z ; return no carry if it's an Onix
	cp RHYHORN
	ret z ; return no carry if it's a Rhyhorn

; store this card index in memory
	ld [de], a
	inc de
	dec b
	jr nz, .loop_hand_1

; two cards were found, so output in a the deck index of
; the Professor Oak card that was found in the deck and set carry.
	ld a, [wce06]
	scf
	ret

; there are more than 3 cards in the AI's hand, so look for specific Evolution cards.
; first, check if there is a Graveler card in the deck to target.
; if so, check if there's a Geodude in the hand or the play area,
; and if there's no Graveler card in the hand, proceed.
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

; next, check if there is a Golem card in the deck to target.
; if so, check if there's a Graveler in the play area,
; and if there's no Golem card in the hand, proceed.
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

; finally, check if there's a Diglett in the play area
; and a Dugtrio in the deck but not the hand.
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
	ld d, $00 ; start by trying to discard only Trainer cards

; stores wAITrainerCardToPlay in e so that
; all routines ignore it for the discard effects.
	ld a, [wAITrainerCardToPlay]
	ld e, a

; this loop will store in wce1a the cards that should be discarded from the hand.
; at the start, it will only consider Trainer cards, but if it can't find enough
; Trainer cards, then it will move on to Pokémon cards and finally, to Energy cards.
.loop_hand_2
	call RemoveFromListDifferentCardOfGivenType
	jr c, .found
	inc d ; move on to next type (Pokemon, then Energy)
	ld a, $03
	cp d
	ret z ; return no carry if there are no more card types to consider
	jr .loop_hand_2

.found
; store this card in memory, and if there's still one more card
; to search for,then jump back into the loop.
	ld [bc], a
	inc bc
	ld a, [wce1b]
	cp $ff
	jr z, .loop_hand_2

; output in a the Computer Search target and set carry.
	ld a, [wce06]
	scf
	ret


; the Wonders of Science deck tries to search for either a Professor Oak card
; or a Grimer/Muk, depending on the other cards in its hand.
AIDecide_ComputerSearch_WondersOfScience:
; if there are fewer than 5 cards in the AI's hand,
; then try to search for a Professor Oak card.
	ld a, DUELVARS_NUMBER_OF_CARDS_IN_HAND
	get_turn_duelist_var
	cp 5
	jr nc, .look_in_hand

; if there's a Professor Oak in the deck, then store its deck index
; and move on to choosing cards in the hand to discard.
	ld e, PROFESSOR_OAK
	ld a, CARD_LOCATION_DECK
	call LookForCardIDInLocation_Bank8
	jr nc, .look_in_hand
	jr CheckHandForTwoTrainerCards

; Professor Oak wasn't found in the deck, so try to
; search for either a Grimer or a Muk if there
; isn't already one in the AI's hand or play area.
.look_in_hand
	ld a, GRIMER
	call LookForCardIDInHandAndPlayArea
	jr nc, .target_grimer
	ld a, MUK
	call LookForCardIDInHandAndPlayArea
	jr nc, .target_muk
	or a
	ret

; if there's a Grimer in the deck, then store its deck index
; and move on to choosing cards in the hand to discard.
.target_grimer
	ld e, GRIMER
	ld a, CARD_LOCATION_DECK
	call LookForCardIDInLocation_Bank8
	ret nc
	jr CheckHandForTwoTrainerCards

; if there's a Muk in the deck, then store its deck index
; and move on to choosing cards in the hand to discard.
.target_muk
	ld e, MUK
	ld a, CARD_LOCATION_DECK
	call LookForCardIDInLocation_Bank8
	ret nc
	jr CheckHandForTwoTrainerCards


; the Fire Charge deck tries to search for specific Pokémon that aren't already in the hand.
AIDecide_ComputerSearch_FireCharge:
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

; don't play Computer Search if the given card isn't in the deck,
; but if a copy was found, then check the hand for Trainer cards to discard.
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

; preserves a (only if carry is set)
; output:
;	carry = set:  if at least 2 Trainer cards were found in the AI's hand
;	[wce1a] = deck index of a Trainer card in the AI's hand, if any (0-59)
;	[wce1b] = deck index of another Trainer card in the AI's hand, if any (0-59)
CheckHandForTwoTrainerCards:
	ld [wce06], a
	call CreateHandCardList
	ld hl, wDuelTempList
	ld d, $00 ; only look for Trainer cards
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


; the Anger deck uses a priority list to search for specific Pokémon,
; depending on the cards in its hand and play area.
AIDecide_ComputerSearch_Anger:
; pick Raticate if it was found in the deck but not the hand/play area and Rattata was also found in the hand/play area.
	ld b, RATTATA
	ld a, RATICATE
	call LookForCardIDInDeck_GivenCardIDInHandAndPlayArea
	jr c, CheckHandForTwoTrainerCards
; pick Rattata if it was found in the deck but not the hand/play area and Raticate was also found in the hand.
	ld a, RATTATA
	ld b, RATICATE
	call LookForCardIDInDeck_GivenCardIDInHand
	jr c, CheckHandForTwoTrainerCards
; pick ArcanineLv34 if it was found in the deck but not the hand/play area and Growlithe was also found in the hand/play area.
	ld b, GROWLITHE
	ld a, ARCANINE_LV34
	call LookForCardIDInDeck_GivenCardIDInHandAndPlayArea
	jr c, CheckHandForTwoTrainerCards
; pick Growlithe if it was found in the deck but not the hand/play area and ArcanineLv34 was also found in the hand.
	ld a, GROWLITHE
	ld b, ARCANINE_LV34
	call LookForCardIDInDeck_GivenCardIDInHand
	jr c, CheckHandForTwoTrainerCards
; pick Dodrio if it was found in the deck but not the hand/play area and Doduo was also found in the hand/play area.
	ld b, DODUO
	ld a, DODRIO
	call LookForCardIDInDeck_GivenCardIDInHandAndPlayArea
	jr c, CheckHandForTwoTrainerCards
; pick Doduo if it was found in the deck but not the hand/play area and Dodrio was also found in the hand.
	ld a, DODUO
	ld b, DODRIO
	call LookForCardIDInDeck_GivenCardIDInHand
	jr c, CheckHandForTwoTrainerCards
	ret




; Pokémon Trader uses 'AIPlay_TrainerCard_TwoVars'


; every deck that contains Pokémon Trader has its own subroutine.
; output:
;	a = deck index of the card to move from the hand to the deck (0-59)
;	[wce1a] = deck index of the card to move from the deck to the hand (0-59)
;	carry = set:  if the AI decided to play Pokémon Trader
AIDecide_PokemonTrader:
; use the opponent's Deck ID to switch to the correct subroutine.
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


; AI only plays Pokémon Trader if it can target a MoltresLv37 in its deck and
; trade it with a Pokémon in its hand other than MoltresLv35.
AIDecide_PokemonTrader_LegendaryMoltres:
	ld a, MOLTRES_LV37
	ld e, MOLTRES_LV35
	call LookForCardIDToTradeWithDifferentHandCard
	ret nc
; success
	ld [wce1a], a
	ld a, e
	ret ; carry set


; AI only plays Pokémon Trader if it can target a needed Seel or Dewgong in its deck
; and trade it with a duplicate Chansey, Ditto, or ArticunoLv37 in its hand.
AIDecide_PokemonTrader_LegendaryArticuno:
; don't play Pokémon Trader if there's a Lapras or ArticunoLv35 in the AI's hand or play area.
	ld a, ARTICUNO_LV35
	call LookForCardIDInHandAndPlayArea
	ccf
	ret nc
	ld a, LAPRAS
	call LookForCardIDInHandAndPlayArea
	ccf
	ret nc

; if AI doesn't have a Seel in its hand or play area, then look for it in the deck.
; otherwise, look for a Dewgong instead.
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

; a Seel or Dewgong was found in the deck, so look for a
; duplicate Chansey, Ditto, or ArticunoLv37 in the hand to trade.
.check_hand
	ld [wce1a], a
	ld a, CHANSEY
	call CheckIfHasDuplicateCardIDInHand
	ret c ; found Chansey
	ld a, DITTO
	call CheckIfHasDuplicateCardIDInHand
	ret c ; found Ditto
	ld a, ARTICUNO_LV37
	jp CheckIfHasDuplicateCardIDInHand


; unless the AI has at least 5 total Pokémon and 5 total Energy cards in its hand and play area,
; then only search the deck for a Kangaskhan. otherwise, uses a priority list to decide the deck target.
; The card to trade from the hand is also chosen from a priority list (and it must be a duplicate).
AIDecide_PokemonTrader_LegendaryDragonite:
; If the AI's hand/play area doesn't have at least 5 Energy cards and 5 Pokémon,
; then target a Kangaskhan in the deck.
	farcall CountOppEnergyCardsInHandAndAttached
	cp 5
	jr c, .kangaskhan
	call CountPokemonCardsInHandAndInPlayArea
	cp 5
	jr c, .kangaskhan
	; total number of Energy cards >= 5
	; total number of Pokémon cards >= 5

; pick Gyarados if it was found in the deck but not the hand/play area and Magikarp was also found in the hand/play area.
	ld b, MAGIKARP
	ld a, GYARADOS
	call LookForCardIDInDeck_GivenCardIDInHandAndPlayArea
	jr c, .choose_hand
; pick Magikarp if it was found in the deck but not the hand/play area and Gyarados was also found in the hand.
	ld a, MAGIKARP
	ld b, GYARADOS
	call LookForCardIDInDeck_GivenCardIDInHand
	jr c, .choose_hand
; pick Dragonair if it was found in the deck but not the hand/play area and Dratini was also found in the hand/play area.
	ld b, DRATINI
	ld a, DRAGONAIR
	call LookForCardIDInDeck_GivenCardIDInHandAndPlayArea
	jr c, .choose_hand
; pick DragoniteLv41 if it was found in the deck but not the hand/play area and Dragonair was also found in the hand/play area.
	ld b, DRAGONAIR
	ld a, DRAGONITE_LV41
	call LookForCardIDInDeck_GivenCardIDInHandAndPlayArea
	jr c, .choose_hand
; pick Dratini if it was found in the deck but not the hand/play area and Dragonair was also found in the hand.
	ld a, DRATINI
	ld b, DRAGONAIR
	call LookForCardIDInDeck_GivenCardIDInHand
	jr c, .choose_hand
; pick Dragonair if it was found in the deck but not the hand/play area and DragoniteLv41 was also found in the hand.
	ld a, DRAGONAIR
	ld b, DRAGONITE_LV41
	call LookForCardIDInDeck_GivenCardIDInHand
	jr c, .choose_hand
; pick Charmeleon if it was found in the deck but not the hand/play area and Charmander was also found in the hand/play area.
	ld b, CHARMANDER
	ld a, CHARMELEON
	call LookForCardIDInDeck_GivenCardIDInHandAndPlayArea
	jr c, .choose_hand
; pick Charizard if it was found in the deck but not the hand/play area and Charmeleon was also found in the hand/play area.
	ld b, CHARMELEON
	ld a, CHARIZARD
	call LookForCardIDInDeck_GivenCardIDInHandAndPlayArea
	jr c, .choose_hand
; pick Charmander if it was found in the deck but not the hand/play area and Charmeleon was also found in the hand.
	ld a, CHARMANDER
	ld b, CHARMELEON
	call LookForCardIDInDeck_GivenCardIDInHand
	jr c, .choose_hand
; pick Charmeleon if it was found in the deck but not the hand/play area and Charizard was also found in the hand.
	ld a, CHARMELEON
	ld b, CHARIZARD
	call LookForCardIDInDeck_GivenCardIDInHand
	jr c, .choose_hand
	ret

; don't play Pokémon Trader if Kangaskhan isn't in the deck.
.kangaskhan
	ld e, KANGASKHAN
	ld a, CARD_LOCATION_DECK
	call LookForCardIDInLocation_Bank8
	ret nc

; a target was found in the deck, so look for a duplicate Pokémon in the hand to trade.
.choose_hand
	ld [wce1a], a
	ld a, DRAGONAIR
	call CheckIfHasDuplicateCardIDInHand
	ret c ; found Dragonair
	ld a, CHARMELEON
	call CheckIfHasDuplicateCardIDInHand
	ret c ; found Charmeleon
	ld a, GYARADOS
	call CheckIfHasDuplicateCardIDInHand
	ret c ; found Gyarados
	ld a, MAGIKARP
	call CheckIfHasDuplicateCardIDInHand
	ret c ; found Magikarp
	ld a, CHARMANDER
	call CheckIfHasDuplicateCardIDInHand
	ret c ; found Charmander
	ld a, DRATINI
	jp CheckIfHasDuplicateCardIDInHand


; uses a priority list to decide which card should be targeted in the deck.
; if a target is found, then pick a Legendary Articuno, Zapdos, or Moltres in the hand for the trade.
AIDecide_PokemonTrader_LegendaryRonald:
; pick FlareonLv22 if it was found in the deck but not the hand/play area and Eevee was also found in the hand/play area.
	ld b, EEVEE
	ld a, FLAREON_LV22
	call LookForCardIDInDeck_GivenCardIDInHandAndPlayArea
	jr c, .choose_hand
; pick VaporeonLv29 if it was found in the deck but not the hand/play area and Eevee was also found in the hand/play area.
	ld b, EEVEE
	ld a, VAPOREON_LV29
	call LookForCardIDInDeck_GivenCardIDInHandAndPlayArea
	jr c, .choose_hand
; pick JolteonLv24 if it was found in the deck but not the hand/play area and Eevee was also found in the hand/play area.
	ld b, EEVEE
	ld a, JOLTEON_LV24
	call LookForCardIDInDeck_GivenCardIDInHandAndPlayArea
	jr c, .choose_hand
; pick Eevee if it was found in the deck but not the hand/play area and FlareonLv22 was also found in the hand.
	ld a, EEVEE
	ld b, FLAREON_LV22
	call LookForCardIDInDeck_GivenCardIDInHand
	jr c, .choose_hand
; pick Eevee if it was found in the deck but not the hand/play area and VaporeonLv29 was also found in the hand.
	ld a, EEVEE
	ld b, VAPOREON_LV29
	call LookForCardIDInDeck_GivenCardIDInHand
	jr c, .choose_hand
; pick Eevee if it was found in the deck but not the hand/play area and JolteonLv24 was also found in the hand.
	ld a, EEVEE
	ld b, JOLTEON_LV24
	call LookForCardIDInDeck_GivenCardIDInHand
	jr c, .choose_hand
; pick Dragonair if it was found in the deck but not the hand/play area and Dratini was also found in the hand/play area.
	ld b, DRATINI
	ld a, DRAGONAIR
	call LookForCardIDInDeck_GivenCardIDInHandAndPlayArea
	jr c, .choose_hand
; pick DragoniteLv41 if it was found in the deck but not the hand/play area and Dragonair was also found in the hand/play area.
	ld b, DRAGONAIR
	ld a, DRAGONITE_LV41
	call LookForCardIDInDeck_GivenCardIDInHandAndPlayArea
	jr c, .choose_hand
; pick Dratini if it was found in the deck but not the hand/play area and Dragonair was also found in the hand.
	ld a, DRATINI
	ld b, DRAGONAIR
	call LookForCardIDInDeck_GivenCardIDInHand
	jr c, .choose_hand
; pick Dragonair if it was found in the deck but not the hand/play area and DragoniteLv41 was also found in the hand.
	ld a, DRAGONAIR
	ld b, DRAGONITE_LV41
	call LookForCardIDInDeck_GivenCardIDInHand
	ret nc
	; fallthrough

; found the search target, so check if there's a legendary bird in the hand to trade.
; if a duplicate is found, then return carry with its deck index in a.
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


; uses a priority list to decide which card should be targeted in the deck.
; if a target is found, then pick any duplicate Pokémon in the hand for the trade.
AIDecide_PokemonTrader_BlisteringPokemon:
; pick Rhydon if it was found in the deck but not the hand/play area and Rhyhorn was also found in the hand/play area.
	ld b, RHYHORN
	ld a, RHYDON
	call LookForCardIDInDeck_GivenCardIDInHandAndPlayArea
	jr c, .find_duplicates
; pick Rhyhorn if it was found in the deck but not the hand/play area and Rhydon was also found in the hand.
	ld a, RHYHORN
	ld b, RHYDON
	call LookForCardIDInDeck_GivenCardIDInHand
	jr c, .find_duplicates
; pick MarowakLv26 if it was found in the deck but not the hand/play area and Cubone was also found in the hand/play area.
	ld b, CUBONE
	ld a, MAROWAK_LV26
	call LookForCardIDInDeck_GivenCardIDInHandAndPlayArea
	jr c, .find_duplicates
; pick Cubone if it was found in the deck but not the hand/play area and MarowakLv26 was also found in the hand.
	ld a, CUBONE
	ld b, MAROWAK_LV26
	call LookForCardIDInDeck_GivenCardIDInHand
	jr c, .find_duplicates
; pick Rapidash if it was found in the deck but not the hand/play area and Ponyta was also found in the hand/play area.
	ld b, PONYTA
	ld a, RAPIDASH
	call LookForCardIDInDeck_GivenCardIDInHandAndPlayArea
	jr c, .find_duplicates
; pick Ponyta if it was found in the deck but not the hand/play area and Rapidash was also found in the hand.
	ld a, PONYTA
	ld b, RAPIDASH
	call LookForCardIDInDeck_GivenCardIDInHand
	ret nc
	; fallthrough

; found the search target, so check if there's a duplicate Pokémon in the hand to trade.
; if a duplicate is found, then return carry with its deck index in a.
.find_duplicates
	ld [wce1a], a
	jp FindDuplicatePokemonCards


; uses a priority list to decide which card should be targeted in the deck.
; The card to trade from the hand is also chosen from a priority list (and it must be a duplicate).
AIDecide_PokemonTrader_SoundOfTheWaves:
; pick Dewgong if it was found in the deck but not the hand/play area and Seel was also found in the hand/play area.
	ld b, SEEL
	ld a, DEWGONG
	call LookForCardIDInDeck_GivenCardIDInHandAndPlayArea
	jr c, .choose_hand
; pick Seel if it was found in the deck but not the hand/play area and Dewgong was also found in the hand.
	ld a, SEEL
	ld b, DEWGONG
	call LookForCardIDInDeck_GivenCardIDInHand
	jr c, .choose_hand
; pick Kingler if it was found in the deck but not the hand/play area and Krabby was also found in the hand/play area.
	ld b, KRABBY
	ld a, KINGLER
	call LookForCardIDInDeck_GivenCardIDInHandAndPlayArea
	jr c, .choose_hand
; pick Krabby if it was found in the deck but not the hand/play area and Kingler was also found in the hand.
	ld a, KRABBY
	ld b, KINGLER
	call LookForCardIDInDeck_GivenCardIDInHand
	jr c, .choose_hand
; pick Cloyster if it was found in the deck but not the hand/play area and Shellder was also found in the hand/play area.
	ld b, SHELLDER
	ld a, CLOYSTER
	call LookForCardIDInDeck_GivenCardIDInHandAndPlayArea
	jr c, .choose_hand
; pick Shellder if it was found in the deck but not the hand/play area and Cloyster was also found in the hand.
	ld a, SHELLDER
	ld b, CLOYSTER
	call LookForCardIDInDeck_GivenCardIDInHand
	jr c, .choose_hand
; pick Seadra if it was found in the deck but not the hand/play area and Horsea was also found in the hand/play area.
	ld b, HORSEA
	ld a, SEADRA
	call LookForCardIDInDeck_GivenCardIDInHandAndPlayArea
	jr c, .choose_hand
; pick Horsea if it was found in the deck but not the hand/play area and Seadra was also found in the hand.
	ld a, HORSEA
	ld b, SEADRA
	call LookForCardIDInDeck_GivenCardIDInHand
	jr c, .choose_hand
; pick Tentacruel if it was found in the deck but not the hand/play area and Tentacool was also found in the hand/play area.
	ld b, TENTACOOL
	ld a, TENTACRUEL
	call LookForCardIDInDeck_GivenCardIDInHandAndPlayArea
	jr c, .choose_hand
; pick Tentacool if it was found in the deck but not the hand/play area and Tentacruel was also found in the hand.
	ld a, TENTACOOL
	ld b, TENTACRUEL
	call LookForCardIDInDeck_GivenCardIDInHand
	ret nc
	; fallthrough

; a target was found in the deck, so look for a duplicate Pokémon in the hand to trade.
.choose_hand
	ld [wce1a], a
	ld a, SEEL
	call CheckIfHasDuplicateCardIDInHand
	ret c ; Seel found
	ld a, KRABBY
	call CheckIfHasDuplicateCardIDInHand
	ret c ; Krabby found
	ld a, HORSEA
	call CheckIfHasDuplicateCardIDInHand
	ret c ; Horsea found
	ld a, SHELLDER
	call CheckIfHasDuplicateCardIDInHand
	ret c ; Shellder found
	ld a, TENTACOOL
	jp CheckIfHasDuplicateCardIDInHand


; uses a priority list to decide which card should be targeted in the deck.
; if a target is found, then pick any duplicate Pokémon in the hand for the trade.
AIDecide_PokemonTrader_PowerGenerator:
; pick RaichuLv40 if it was found in the deck but not the hand/play area and PikachuLv14 was also found in the hand/play area.
	ld b, PIKACHU_LV14
	ld a, RAICHU_LV40
	call LookForCardIDInDeck_GivenCardIDInHandAndPlayArea
	jp c, .find_duplicates
; pick RaichuLv40 if it was found in the deck but not the hand/play area and PikachuLv12 was also found in the hand/play area.
	ld b, PIKACHU_LV12
	ld a, RAICHU_LV40
	call LookForCardIDInDeck_GivenCardIDInHandAndPlayArea
	jr c, .find_duplicates
; pick PikachuLv14 if it was found in the deck but not the hand/play area and RaichuLv40 was also found in the hand.
	ld a, PIKACHU_LV14
	ld b, RAICHU_LV40
	call LookForCardIDInDeck_GivenCardIDInHand
	jr c, .find_duplicates
; pick PikachuLv12 if it was found in the deck but not the hand/play area and RaichuLv40 was also found in the hand.
	ld a, PIKACHU_LV12
	ld b, RAICHU_LV40
	call LookForCardIDInDeck_GivenCardIDInHand
	jr c, .find_duplicates
; pick ElectrodeLv42 if it was found in the deck but not the hand/play area and Voltorb was also found in the hand/play area.
	ld b, VOLTORB
	ld a, ELECTRODE_LV42
	call LookForCardIDInDeck_GivenCardIDInHandAndPlayArea
	jr c, .find_duplicates
; pick ElectrodeLv35 if it was found in the deck but not the hand/play area and Voltorb was also found in the hand/play area.
	ld b, VOLTORB
	ld a, ELECTRODE_LV35
	call LookForCardIDInDeck_GivenCardIDInHandAndPlayArea
	jr c, .find_duplicates
; pick Voltorb if it was found in the deck but not the hand/play area and ElectrodeLv42 was also found in the hand.
	ld a, VOLTORB
	ld b, ELECTRODE_LV42
	call LookForCardIDInDeck_GivenCardIDInHand
	jr c, .find_duplicates
; pick Voltorb if it was found in the deck but not the hand/play area and ElectrodeLv35 was also found in the hand.
	ld a, VOLTORB
	ld b, ELECTRODE_LV35
	call LookForCardIDInDeck_GivenCardIDInHand
	jr c, .find_duplicates
; pick MagnetonLv35 if it was found in the deck but not the hand/play area and MagnemiteLv13 was also found in the hand/play area.
	ld b, MAGNEMITE_LV13
	ld a, MAGNETON_LV35
	call LookForCardIDInDeck_GivenCardIDInHandAndPlayArea
	jr c, .find_duplicates
; pick MagnetonLv35 if it was found in the deck but not the hand/play area and MagnemiteLv15 was also found in the hand/play area.
	ld b, MAGNEMITE_LV15
	ld a, MAGNETON_LV35
	call LookForCardIDInDeck_GivenCardIDInHandAndPlayArea
	jr c, .find_duplicates
; pick MagnetonLv28 if it was found in the deck but not the hand/play area and MagnemiteLv13 was also found in the hand/play area.
	ld b, MAGNEMITE_LV13
	ld a, MAGNETON_LV28
	call LookForCardIDInDeck_GivenCardIDInHandAndPlayArea
	jr c, .find_duplicates
; pick MagnetonLv28 if it was found in the deck but not the hand/play area and MagnemiteLv15 was also found in the hand/play area.
	ld b, MAGNEMITE_LV15
	ld a, MAGNETON_LV28
	call LookForCardIDInDeck_GivenCardIDInHandAndPlayArea
	jr c, .find_duplicates
; pick MagnemiteLv15 if it was found in the deck but not the hand/play area and MagnetonLv35 was also found in the hand.
	ld a, MAGNEMITE_LV15
	ld b, MAGNETON_LV35
	call LookForCardIDInDeck_GivenCardIDInHand
	jr c, .find_duplicates
; pick MagnemiteLv13 if it was found in the deck but not the hand/play area and MagnetonLv35 was also found in the hand.
	ld a, MAGNEMITE_LV13
	ld b, MAGNETON_LV35
	call LookForCardIDInDeck_GivenCardIDInHand
	jr c, .find_duplicates
; pick MagnemiteLv15 if it was found in the deck but not the hand/play area and MagnetonLv28 was also found in the hand.
	ld a, MAGNEMITE_LV15
	ld b, MAGNETON_LV28
	call LookForCardIDInDeck_GivenCardIDInHand
	jr c, .find_duplicates
; pick MagnemiteLv13 if it was found in the deck but not the hand/play area and MagnetonLv28 was also found in the hand.
	ld a, MAGNEMITE_LV13
	ld b, MAGNETON_LV28
	call LookForCardIDInDeck_GivenCardIDInHand
	ret nc
	; fallthrough

; found the search target, so check if there's a duplicate Pokémon in the hand to trade.
; if a duplicate is found, then return carry with its deck index in a.
.find_duplicates
	ld [wce1a], a
	jp FindDuplicatePokemonCards


; uses a priority list to decide which card should be targeted in the deck.
; if a target is found, then pick any duplicate Pokémon in the hand for the trade.
AIDecide_PokemonTrader_FlowerGarden:
; pick Ivysaur if it was found in the deck but not the hand/play area and Bulbasaur was also found in the hand/play area.
	ld b, BULBASAUR
	ld a, IVYSAUR
	call LookForCardIDInDeck_GivenCardIDInHandAndPlayArea
	jr c, .find_duplicates
; pick VenusaurLv67 if it was found in the deck but not the hand/play area and Ivysaur was also found in the hand/play area.
	ld b, IVYSAUR
	ld a, VENUSAUR_LV67
	call LookForCardIDInDeck_GivenCardIDInHandAndPlayArea
	jr c, .find_duplicates
; pick Bulbasaur if it was found in the deck but not the hand/play area and Ivysaur was also found in the hand.
	ld a, BULBASAUR
	ld b, IVYSAUR
	call LookForCardIDInDeck_GivenCardIDInHand
	jr c, .find_duplicates
; pick Ivysaur if it was found in the deck but not the hand/play area and VenusaurLv67 was also found in the hand/play area.
	ld a, IVYSAUR
	ld b, VENUSAUR_LV67
	call LookForCardIDInDeck_GivenCardIDInHand
	jr c, .find_duplicates
; pick Weepinbell if it was found in the deck but not the hand/play area and Bellsprout was also found in the hand/play area.
	ld b, BELLSPROUT
	ld a, WEEPINBELL
	call LookForCardIDInDeck_GivenCardIDInHandAndPlayArea
	jr c, .find_duplicates
; pick Victreebel if it was found in the deck but not the hand/play area and Weepinbell was also found in the hand/play area.
	ld b, WEEPINBELL
	ld a, VICTREEBEL
	call LookForCardIDInDeck_GivenCardIDInHandAndPlayArea
	jr c, .find_duplicates
; pick Bellsprout if it was found in the deck but not the hand/play area and Weepinbell was also found in the hand.
	ld a, BELLSPROUT
	ld b, WEEPINBELL
	call LookForCardIDInDeck_GivenCardIDInHand
	jr c, .find_duplicates
; pick Weepinbell if it was found in the deck but not the hand/play area and Victreebel was also found in the hand.
	ld a, WEEPINBELL
	ld b, VICTREEBEL
	call LookForCardIDInDeck_GivenCardIDInHand
	jr c, .find_duplicates
; pick Gloom if it was found in the deck but not the hand/play area and Oddish was also found in the hand/play area.
	ld b, ODDISH
	ld a, GLOOM
	call LookForCardIDInDeck_GivenCardIDInHandAndPlayArea
	jr c, .find_duplicates
; pick Vileplume if it was found in the deck but not the hand/play area and Gloom was also found in the hand/play area.
	ld b, GLOOM
	ld a, VILEPLUME
	call LookForCardIDInDeck_GivenCardIDInHandAndPlayArea
	jr c, .find_duplicates
; pick Oddish if it was found in the deck but not the hand/play area and Gloom was also found in the hand.
	ld a, ODDISH
	ld b, GLOOM
	call LookForCardIDInDeck_GivenCardIDInHand
	jr c, .find_duplicates
; pick Gloom if it was found in the deck but not the hand/play area and Vileplume was also found in the hand.
	ld a, GLOOM
	ld b, VILEPLUME
	call LookForCardIDInDeck_GivenCardIDInHand
	ret nc
	; fallthrough

; found the search target, so check if there's a duplicate Pokémon in the hand to trade.
; if a duplicate is found, then return carry with its deck index in a.
.find_duplicates
	ld [wce1a], a
	jp FindDuplicatePokemonCards


; trades any Pokémon in the hand for a Mr. Mime from the deck.
AIDecide_PokemonTrader_StrangePower:
; inputting Mr Mime's card ID in register e for the function is redundant
; since it already checks that there was no Mr Mime in the hand.
	ld a, MR_MIME
	ld e, a
	call LookForCardIDToTradeWithDifferentHandCard
	ret nc
; found
	ld [wce1a], a
	ld a, e
	scf
	ret


; uses a priority list to decide which card should be targeted in the deck.
; if a target is found, then pick any duplicate Pokémon in the hand for the trade.
AIDecide_PokemonTrader_Flamethrower:
; pick Charmeleon if it was found in the deck but not the hand/play area and Charmander was also found in the hand/play area.
	ld b, CHARMANDER
	ld a, CHARMELEON
	call LookForCardIDInDeck_GivenCardIDInHandAndPlayArea
	jr c, .find_duplicates
; pick Charizard if it was found in the deck but not the hand/play area and Charmeleon was also found in the hand/play area.
	ld b, CHARMELEON
	ld a, CHARIZARD
	call LookForCardIDInDeck_GivenCardIDInHandAndPlayArea
	jr c, .find_duplicates
; pick Charmander if it was found in the deck but not the hand/play area and Charmeleon was also found in the hand.
	ld a, CHARMANDER
	ld b, CHARMELEON
	call LookForCardIDInDeck_GivenCardIDInHand
	jr c, .find_duplicates
; pick Charmeleon if it was found in the deck but not the hand/play area and Charizard was also found in the hand.
	ld a, CHARMELEON
	ld b, CHARIZARD
	call LookForCardIDInDeck_GivenCardIDInHand
	jr c, .find_duplicates
; pick NinetalesLv32 if it was found in the deck but not the hand/play area and Vulpix was also found in the hand/play area.
	ld b, VULPIX
	ld a, NINETALES_LV32
	call LookForCardIDInDeck_GivenCardIDInHandAndPlayArea
	jr c, .find_duplicates
; pick Vulpix if it was found in the deck but not the hand/play area and NinetalesLv32 was also found in the hand.
	ld a, VULPIX
	ld b, NINETALES_LV32
	call LookForCardIDInDeck_GivenCardIDInHand
	jr c, .find_duplicates
; pick ArcanineLv45 if it was found in the deck but not the hand/play area and Growlithe was also found in the hand/play area.
	ld b, GROWLITHE
	ld a, ARCANINE_LV45
	call LookForCardIDInDeck_GivenCardIDInHandAndPlayArea
	jr c, .find_duplicates
; pick Growlithe if it was found in the deck but not the hand/play area and ArcanineLv45 was also found in the hand.
	ld a, GROWLITHE
	ld b, ARCANINE_LV45
	call LookForCardIDInDeck_GivenCardIDInHand
	jr c, .find_duplicates
; pick FlareonLv28 if it was found in the deck but not the hand/play area and Eevee was also found in the hand/play area.
	ld b, EEVEE
	ld a, FLAREON_LV28
	call LookForCardIDInDeck_GivenCardIDInHandAndPlayArea
	jr c, .find_duplicates
; pick Eevee if it was found in the deck but not the hand/play area and FlareonLv28 was also found in the hand.
	ld a, EEVEE
	ld b, FLAREON_LV28
	call LookForCardIDInDeck_GivenCardIDInHand
	ret nc
	; fallthrough

; found the search target, so check if there's a duplicate Pokémon in the hand to trade.
; if a duplicate is found, then return carry with its deck index in a.
.find_duplicates
	ld [wce1a], a
	jp FindDuplicatePokemonCards
