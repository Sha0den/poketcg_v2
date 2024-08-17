; doubles the damage at de if Swords Dance or Focus Energy was used
; in the last turn by the turn holder's Active Pokemon
; preserves bc
; input:
;	de = damage to double
HandleDoubleDamageSubstatus::
	ld a, DUELVARS_ARENA_CARD_SUBSTATUS3
	get_turn_duelist_var
	bit SUBSTATUS3_THIS_TURN_DOUBLE_DAMAGE_F, [hl]
	ret z
;	fallthrough

; output:
;	de *= 2
DoubleDamage::
	ld a, e
	or d
	ret z
	sla e
	rl d
	ret


; checks if the Defending Pokemon (turn holder's Active Pokemon) has anything
; that reduces the damage dealt to it this turn (SUBSTATUS1 or Pokemon Powers).
; also checks if the Attacking Pokemon (non-turn holder's Active Pokemon)
; has any substatus that reduces the damage dealt this turn (SUBSTATUS2).
; input:
;	de = damage being dealt
; output:
;	de = updated damage
HandleDamageReduction::
	call HandleDamageReductionExceptSubstatus2
	ld a, DUELVARS_ARENA_CARD_SUBSTATUS2
	call GetNonTurnDuelistVariable
	or a
	ret z
	cp SUBSTATUS2_REDUCE_BY_20
	jr z, ReduceDamageBy20
	cp SUBSTATUS2_REDUCE_BY_10
	ret nz
;	fallthrough

; output:
;	de -= 10
ReduceDamageBy10::
	ld hl, -10
	add hl, de
	ld e, l
	ld d, h
	ret

; output:
;	de -= 20
ReduceDamageBy20::
	ld hl, -20
	add hl, de
	ld e, l
	ld d, h
	ret


; output:
;	de = 0:  if input de < 40
PreventAllDamage_IfLessThan40::
	ld bc, 40
	call CompareDEtoBC
	ret nc ; return if damage is at least 40
	ld de, 0
	ret


; output:
;	de = 0:  if input de ≥ 30
PreventAllDamage_IfMoreThan20::
	ld bc, 30
	call CompareDEtoBC
	ret c ; return if damage is less than 30
;	fallthrough

; output:
;	de = 0
PreventAllDamage::
	ld de, 0
	ret


; checks if the Defending Pokemon (turn holder's Active Pokemon) has anything
; that reduces the damage dealt to it this turn. (SUBSTATUS1 or Pokemon Powers)
; input:
;	de = damage being dealt
; output:
;	de = updated damage
HandleDamageReductionExceptSubstatus2::
	ld a, [wNoDamageOrEffect]
	or a
	jr nz, PreventAllDamage
	ld a, DUELVARS_ARENA_CARD_SUBSTATUS1
	get_turn_duelist_var
	or a
	jr z, .not_affected_by_substatus1
	cp SUBSTATUS1_NO_DAMAGE
	jr z, PreventAllDamage
	cp SUBSTATUS1_REDUCE_BY_10
	jr z, ReduceDamageBy10
	cp SUBSTATUS1_REDUCE_BY_20
	jr z, ReduceDamageBy20
	cp SUBSTATUS1_HARDEN
	jr z, PreventAllDamage_IfLessThan40
	cp SUBSTATUS1_HALVE_DAMAGE
	jr z, HalveDamage_RoundedDown
.not_affected_by_substatus1
	call CheckCannotUseDueToStatus
	ret c ; return if Pokemon Powers can't be used because of status or Toxic Gas
.pkmn_power
	ld a, [wLoadedAttackCategory]
	cp POKEMON_POWER
	ret z
	ld a, [wTempNonTurnDuelistCardID]
	cp MR_MIME
	jr z, PreventAllDamage_IfMoreThan20 ; Invisible Wall
	cp KABUTO
	ret nz
;	fallthrough

; output:
;	de /= 2 (rounded down to the nearest 10)
HalveDamage_RoundedDown::
	sla d
	rr e
	bit 0, e
	ret z
	ld hl, -5
	add hl, de
	ld e, l
	ld d, h
	ret


; checks for Invisible Wall, Kabuto Armor, Neutralizing Shield, or Transparency.
; if found, then reduce or nullify the damage at de accordingly.
; input:
;	de = damage being dealt
; output:
;	de = updated damage
HandleDamageReductionOrNoDamageFromPkmnPowerEffects::
	ld a, [wLoadedAttackCategory]
	cp POKEMON_POWER
	ret z
	ld a, MUK
	call CountPokemonIDInBothPlayAreas
	ret c ; return if there's a Muk in play
	ld a, [wTempPlayAreaLocation_cceb]
	or a
	call nz, HandleDamageReductionExceptSubstatus2.pkmn_power
	push de ; push damage from call above, which handles Invisible Wall and Kabuto Armor
	call HandleNoDamageOrEffectSubstatus.pkmn_power
	call nc, HandleTransparency
	pop de ; restore damage
	ret nc
	; if carry was set due to Neutralizing Shield or Transparency, damage is 0
	ld de, 0
	ret


; preserves bc
; input:
;	a = wNoDamageOrEffect ID (NO_DAMAGE_OR_EFFECT_* constant)
; output:
;	hl = text ID from NoDamageOrEffectTextIDTable (only if check succeeds)
;	carry = set:  if the target has anything affecting it that would prevent
;	              any damage or effect done to it during this turn
CheckNoDamageOrEffect::
	ld a, [wNoDamageOrEffect]
	or a
	ret z
	bit 7, a
	jr nz, .dont_print_text ; already been here so don't repeat the text
	ld hl, wNoDamageOrEffect
	set 7, [hl]
	dec a
	add a
	ld e, a
	ld d, $0
	ld hl, NoDamageOrEffectTextIDTable
	add hl, de
	ld a, [hli]
	ld h, [hl]
	ld l, a
	scf
	ret

.dont_print_text
	ld hl, $0000
	scf
	ret

NoDamageOrEffectTextIDTable::
	tx NoDamageOrEffectDueToAttackText       ; NO_DAMAGE_OR_EFFECT_ATTACK
	tx NoDamageOrEffectDueToTransparencyText ; NO_DAMAGE_OR_EFFECT_TRANSPARENCY
	tx NoDamageOrEffectDueToNShieldText      ; NO_DAMAGE_OR_EFFECT_NSHIELD


; preserves bc
; output:
;	hl = ID for notification text
;	carry = set:  if the Defending Pokemon (turn holder's Active Pokemon) is affected by
;	              a substatus that prevents any damage or effect dealt to it for the turn.
;	wNoDamageOrEffect = correct index (NO_DAMAGE_OR_EFFECT_* constant)
HandleNoDamageOrEffectSubstatus::
	xor a
	ld [wNoDamageOrEffect], a
	ld a, [wLoadedAttackCategory]
	cp POKEMON_POWER
	ret z
	ld a, DUELVARS_ARENA_CARD_SUBSTATUS1
	get_turn_duelist_var
	ld e, NO_DAMAGE_OR_EFFECT_ATTACK
	ldtx hl, NoDamageOrEffectDueToAttackText
	cp SUBSTATUS1_IMMUNITY
	jr z, .no_damage_or_effect
	call CheckCannotUseDueToStatus
	ccf
	ret nc ; return if Pokemon Power can't be used because of status or Toxic Gas
.pkmn_power
	ld a, [wTempNonTurnDuelistCardID]
	cp MEW_LV8
	jr z, .neutralizing_shield
	or a
	ret
.no_damage_or_effect
	ld a, e
	ld [wNoDamageOrEffect], a
	scf
	ret
.neutralizing_shield
	ld a, [wIsDamageToSelf]
	or a
	ret nz
	; prevent damage if attacked by a non-Basic Pokemon
	ld a, [wTempTurnDuelistCardID]
	ld e, a
	ld d, $0
	call LoadCardDataToBuffer2_FromCardID
	ld a, [wLoadedCard2Stage]
	or a
	ret z
	ld e, NO_DAMAGE_OR_EFFECT_NSHIELD
	ldtx hl, NoDamageOrEffectDueToNShieldText
	jr .no_damage_or_effect


; if the Pokemon being attacked is HAUNTER_LV17 and its Transparency is active,
; there is a 50% chance that any damage or effect is prevented.
; output:
;	hl = ID for notification text:  if the below condition is true
;	carry = set:  if Transparency successfully protected Haunter from the attack
HandleTransparency::
	ld a, [wTempNonTurnDuelistCardID]
	cp HAUNTER_LV17
	jr z, .transparency
.done
	or a
	ret
.transparency
	ld a, [wLoadedAttackCategory]
	cp POKEMON_POWER
	jr z, .done ; Transparency has no effect against Pokemon Powers
	ld a, [wTempPlayAreaLocation_cceb]
	call CheckCannotUseDueToStatus_OnlyToxicGasIfANon0
	jr c, .done
	xor a
	ld [wDuelDisplayedScreen], a
	ldtx de, TransparencyCheckText
	call TossCoin
	ret nc ; return if tails
	ld a, NO_DAMAGE_OR_EFFECT_TRANSPARENCY
	ld [wNoDamageOrEffect], a
	ldtx hl, NoDamageOrEffectDueToTransparencyText
	scf
	ret


; this is called to potentially negate a non-damaging attack, like Lure
; output:
;	carry = set:  if MEW_LV8 or HAUNTER_LV17 is the turn holder's Active Pokemon
HandleNShieldAndTransparency::
	push de
	ld a, DUELVARS_ARENA_CARD
	add e
	get_turn_duelist_var
	call GetCardIDFromDeckIndex
	ld a, e
	cp MEW_LV8
	jr z, .nshield
	cp HAUNTER_LV17
	jr z, .transparency
.done
	pop de
	or a
	ret
.nshield
	ld a, DUELVARS_ARENA_CARD_STAGE
	call GetNonTurnDuelistVariable
	or a
	jr z, .done
	ld a, NO_DAMAGE_OR_EFFECT_NSHIELD
	ld [wNoDamageOrEffect], a
	ldtx hl, NoDamageOrEffectDueToNShieldText
.print_text
	call DrawWideTextBox_WaitForInput
	pop de
	scf
	ret
.transparency
	xor a
	ld [wDuelDisplayedScreen], a
	ldtx de, TransparencyCheckText
	call TossCoin
	jr nc, .done
	ld a, NO_DAMAGE_OR_EFFECT_TRANSPARENCY
	ld [wNoDamageOrEffect], a
	ldtx hl, NoDamageOrEffectDueToTransparencyText
	jr .print_text


; preserves bc and de
; output:
;	hl = ID for notification text:  if the Active Pokemon is affected by a Substatus2
;	carry = set:  if the turn holder's Active Pokemon is affected by
;	              an attack effect that makes it unable to attack
HandleCantAttackSubstatus::
	ld a, DUELVARS_ARENA_CARD_SUBSTATUS2
	get_turn_duelist_var
	or a
	ret z
	ldtx hl, UnableToAttackThatPokemonText
	cp SUBSTATUS2_CANNOT_ATTACK_THIS
	jr z, .return_with_cant_attack
	ldtx hl, UnableToAttackText
	cp SUBSTATUS2_CANNOT_ATTACK
	jr z, .return_with_cant_attack
	or a
	ret
.return_with_cant_attack
	scf
	ret


; preserves bc and de
; ouput:
;	hl = ID for notification text:  if the below condition is true
;	carry = set:  if the turn holder's Active Pokemon cannot use the attack
;	              at wSelectedAttack because it's affected by Amnesia
HandleAmnesiaSubstatus::
	ld a, DUELVARS_ARENA_CARD_SUBSTATUS2
	get_turn_duelist_var
	or a
	ret z
; check amnesia
	cp SUBSTATUS2_AMNESIA
	jr z, .affected_by_amnesia
.not_the_disabled_atk
	or a
	ret
.affected_by_amnesia
	ld a, DUELVARS_ARENA_CARD_DISABLED_ATTACK_INDEX
	get_turn_duelist_var
	ld a, [wSelectedAttack]
	cp [hl]
	jr nz, .not_the_disabled_atk
	ldtx hl, UnableToUseAttackDueToAmnesiaText
	scf
	ret


; output:
;	carry = set:  if the turn holder's attack was unsuccessful due to Smokescreen
HandleSmokescreenSubstatus::
	call CheckSmokescreenSubstatus
	ret nc ; return if the Active Pokemon isn't affected by Smokescreen
	call TossCoin
	ld [wGotHeadsFromSmokescreenCheck], a
	ccf
	ret nc ; return if heads
	ldtx hl, AttackUnsuccessfulText
	call DrawWideTextBox_WaitForInput
	scf
	ret


; preserves bc
; output:
;	de = ID for TossCoin notification text
;	carry = set:  if the turn holder's Active Pokemon is affected by Smokescreen
CheckSmokescreenSubstatus::
	ld a, DUELVARS_ARENA_CARD_SUBSTATUS2
	get_turn_duelist_var
	or a
	ret z
	ldtx de, SmokescreenCheckText
	cp SUBSTATUS2_SMOKESCREEN
	jr z, .card_is_affected
	or a
	ret
.card_is_affected
	ld a, [wGotHeadsFromSmokescreenCheck]
	or a
	ret nz
	scf
	ret


; preserves bc and de
; output:
;	hl = ID for notification text:  if the below condition is true
;	carry = set:  if the turn holder's Active Pokemon cannot retreat because of a substatus
CheckCantRetreatDueToAttackEffect::
	ld a, DUELVARS_ARENA_CARD_SUBSTATUS2
	get_turn_duelist_var
	or a
	ret z
	cp SUBSTATUS2_UNABLE_RETREAT
	jr z, .cant_retreat
	or a
	ret
.cant_retreat
	ldtx hl, UnableToRetreatDueToAcidText
	scf
	ret


; preserves bc and de
; output:
;	hl = ID for notification text:  if the below condition is true
;	carry = set:  if the turn holder can't play any Trainer cards because of Headache
CheckCantUseTrainerDueToHeadache::
	ld a, DUELVARS_ARENA_CARD_SUBSTATUS3
	get_turn_duelist_var
	or a
	bit SUBSTATUS3_HEADACHE_F, [hl]
	ret z
	ldtx hl, UnableToUseTrainerDueToHeadacheText
	scf
	ret


; preserves bc and de
; output:
;	hl = ID for notification text:  if the below condition is true
;	carry = set:  if there's an Aerodactyl in play with an active Prehistoric Power
IsPrehistoricPowerActive::
	ld a, AERODACTYL
	call CountPokemonIDInBothPlayAreas
	ret nc ; return if there isn't an Aerodactyl in play
	ld a, MUK
	call CountPokemonIDInBothPlayAreas
	ldtx hl, UnableToEvolveDueToPrehistoricPowerText
	ccf
	ret


; preserves all registers except af
; output:
;	carry = set:  if the turn holder has an Omanyte with an active Clairvoyance Pokemon Power
IsClairvoyanceActive::
	ld a, MUK
	call CountPokemonIDInBothPlayAreas
	ccf
	ret nc ; return if there's a Muk in play
	ld a, OMANYTE
;	fallthrough

; checks the turn holder's play area for a specific Pokemon, but the Active Pokemon
; is ignored if it's Asleep, Confused, or Paralyzed (i.e. Pokemon Power-incapable).
; preserves all registers except af
; input:
;	a = card ID of Pokemon to look for
; output:
;	a = number of Pokemon with the ID from input that are in the turn holder's play area
;	carry = set:  if there's at least 1 of that Pokemon in the turn holder's play area
CountPokemonIDInPlayArea::
	push hl
	push de
	push bc
	ld [wTempPokemonID_ce7c], a
	ld c, $0
	ld a, DUELVARS_ARENA_CARD
	get_turn_duelist_var
	cp -1
	jr z, .check_bench
	call GetCardIDFromDeckIndex
	ld a, [wTempPokemonID_ce7c]
	cp e
	jr nz, .check_bench
	ld a, DUELVARS_ARENA_CARD_STATUS
	get_turn_duelist_var
	and CNF_SLP_PRZ
	jr nz, .check_bench
	inc c
.check_bench
	ld a, DUELVARS_BENCH
	get_turn_duelist_var
.next_bench_slot
	ld a, [hli]
	cp -1
	jr z, .done
	call GetCardIDFromDeckIndex
	ld a, [wTempPokemonID_ce7c]
	cp e
	jr nz, .skip
	inc c
.skip
	inc b
	jr .next_bench_slot
.done
	ld a, c
	or a
	scf
	jr nz, .found
	or a
.found
	pop bc
	pop de
	pop hl
	ret


; checks both play areas for a specific Pokemon, but the Active Pokemon is
; ignored if it's Asleep, Confused, or Paralyzed (i.e. Pokemon Power-incapable)
; preserves all registers except af
; input:
;	a = card ID of Pokemon to look for
; output:
;	a = number of Pokemon with the ID from input that are in either play area
;	carry = set:  if there's at least 1 of that Pokemon in either play area
CountPokemonIDInBothPlayAreas::
	push bc
	ld [wTempPokemonID_ce7c], a
	call CountPokemonIDInPlayArea
	ld c, a
	call SwapTurn
	ld a, [wTempPokemonID_ce7c]
	call CountPokemonIDInPlayArea
	call SwapTurn
	add c
	or a
	scf
	jr nz, .found
	or a
.found
	pop bc
	ret


; preserves bc and de
; output:
;	hl = ID for notification text
;	carry = set:  if the turn holder's Active Pokemon is Asleep, Confused, Paralyzed,
;	              and/or Toxic Gas is active (i.e. its Pokemon Power cannot be used)
CheckCannotUseDueToStatus::
	xor a

; same as above, but if a is non-0, only toxic gas is checked
CheckCannotUseDueToStatus_OnlyToxicGasIfANon0::
	or a
	jr nz, .check_toxic_gas
	ld a, DUELVARS_ARENA_CARD_STATUS
	get_turn_duelist_var
	and CNF_SLP_PRZ
	ldtx hl, CannotUseDueToStatusText
	scf
	ret nz ; return carry
.check_toxic_gas
	ld a, MUK
	call CountPokemonIDInBothPlayAreas
	ldtx hl, UnableDueToToxicGasText
	ret


; if the ID of the card provided in register a as a deck index is MUK,
; then clear the changed type of all Active and Benched Pokemon.
; input:
;	a = deck index (0-59) to check
ClearChangedTypesIfMuk::
	call GetCardIDFromDeckIndex
	ld a, e
	cp MUK
	ret nz ; return if the Pokemon isn't a Muk
	call SwapTurn
	call .zero_changed_types
	call SwapTurn
.zero_changed_types
	ld a, DUELVARS_ARENA_CARD_CHANGED_TYPE
	get_turn_duelist_var
	ld c, MAX_PLAY_AREA_POKEMON
.zero_changed_types_loop
	xor a
	ld [hli], a
	dec c
	jr nz, .zero_changed_types_loop
	ret


; clears some SUBSTATUS2 conditions from the turn holder's Active Pokemon.
; more specifically, those conditions that reduce the damage from an attack
; or prevent the opposing Pokemon from attacking the substatus condition inducer.
; preserves bc and de
ClearDamageReductionSubstatus2::
	ld a, DUELVARS_ARENA_CARD_SUBSTATUS2
	get_turn_duelist_var
	or a
	ret z
	cp SUBSTATUS2_REDUCE_BY_20
	jr z, .zero
	cp SUBSTATUS2_REDUCE_BY_10
	jr z, .zero
	cp SUBSTATUS2_CANNOT_ATTACK_THIS
	ret nz
.zero
	ld [hl], 0
	ret


; clears the SUBSTATUS1 and updates the double damage condition
; of the player whose turn is about to start
; preserves bc and de
UpdateSubstatusConditions_StartOfTurn::
	ld a, DUELVARS_ARENA_CARD_SUBSTATUS1
	get_turn_duelist_var
	ld [hl], $0
	or a
	ret z
	cp SUBSTATUS1_NEXT_TURN_DOUBLE_DAMAGE
	ret nz
	ld a, DUELVARS_ARENA_CARD_SUBSTATUS3
	get_turn_duelist_var
	set SUBSTATUS3_THIS_TURN_DOUBLE_DAMAGE_F, [hl]
	ret


; clears the SUBSTATUS2/Headache, and updates the double damage condition
; of the player whose turn has ended
; preserves bc and de
UpdateSubstatusConditions_EndOfTurn::
	ld a, DUELVARS_ARENA_CARD_SUBSTATUS3
	get_turn_duelist_var
	res SUBSTATUS3_HEADACHE_F, [hl]
	push hl
	ld a, DUELVARS_ARENA_CARD_SUBSTATUS2
	get_turn_duelist_var
	xor a
	ld [hl], a
	ld a, DUELVARS_ARENA_CARD_SUBSTATUS1
	get_turn_duelist_var
	pop hl
	cp SUBSTATUS1_NEXT_TURN_DOUBLE_DAMAGE
	ret z
	res SUBSTATUS3_THIS_TURN_DOUBLE_DAMAGE_F, [hl]
	ret


; if the Defending Pokemon's HP is 0 and the Attacking Pokemon's HP is not,
; then the Attacking Pokemon is Knocked Out if it was affected by Destiny Bond.
HandleDestinyBondSubstatus::
	ld a, DUELVARS_ARENA_CARD_SUBSTATUS1
	call GetNonTurnDuelistVariable
	cp SUBSTATUS1_DESTINY_BOND
	ret nz
; check hp
	ld a, DUELVARS_ARENA_CARD
	call GetNonTurnDuelistVariable
	cp -1
	ret z
	ld a, DUELVARS_ARENA_CARD_HP
	call GetNonTurnDuelistVariable
	or a
	ret nz
	ld a, DUELVARS_ARENA_CARD_HP
	get_turn_duelist_var
	or a
	ret z
	ld [hl], 0
	push hl
	bank1call DrawDuelMainScene
	bank1call DrawDuelHUDs
	pop hl
	ld l, DUELVARS_ARENA_CARD
	ld a, [hl]
	call LoadCardDataToBuffer2_FromDeckIndex
	ld hl, wLoadedCard2Name
	ld a, [hli]
	ld h, [hl]
	ld l, a
	call LoadTxRam2
	ldtx hl, KnockedOutDueToDestinyBondText
	jp DrawWideTextBox_WaitForInput


; used to bounce back a damaging attack.
; when MACHAMP is damaged, if its Strikes Back is active, then
; the Attacking Pokemon (turn holder's Active Pokemon) takes 10 damage.
; ignore if damage taken at de is 0.
; preserves de and hl
; output:
;	de = amount of damage being dealt
;	carry = set:  if Machamp is unable to use its Pokemon Power
HandleStrikesBack_AgainstDamagingAttack::
	ld a, e
	or d
	ret z
	ld a, [wIsDamageToSelf]
	or a
	ret nz
	ld a, [wTempNonTurnDuelistCardID] ; ID of Defending Pokemon
	cp MACHAMP
	ret nz ; return if the Defending Pokemon isn't a Machamp
	ld a, MUK
	call CountPokemonIDInBothPlayAreas
	ret c ; return if there's a Muk in play
	ld a, [wLoadedAttackCategory] ; category of attack used
	cp POKEMON_POWER
	ret z
	ld a, [wTempPlayAreaLocation_cceb] ; Defending Pokemon's PLAY_AREA_*
	or a ; cp PLAY_AREA_ARENA
	jr nz, .in_bench
	call CheckCannotUseDueToStatus
	ret c ; return if Pokemon Power can't be used because of status or Toxic Gas
.in_bench
	push hl
	push de
	; subtract 10 HP from Attacking Pokemon (turn holder's Active Pokemon)
	call SwapTurn
	ld a, DUELVARS_ARENA_CARD
	get_turn_duelist_var
	call LoadCardDataToBuffer2_FromDeckIndex
	ld a, DUELVARS_ARENA_CARD_HP
	get_turn_duelist_var
	push af
	push hl
	ld de, 10
	call SubtractHP
	ld a, [wLoadedCard2ID]
	ld [wTempNonTurnDuelistCardID], a
	ld hl, 10
	call LoadTxRam3
	ld hl, wLoadedCard2Name
	ld a, [hli]
	ld h, [hl]
	ld l, a
	call LoadTxRam2
	ldtx hl, ReceivesDamageDueToStrikesBackText
	call DrawWideTextBox_WaitForInput
	pop hl
	pop af
	or a
	jr z, .not_knocked_out
	xor a
	call PrintPlayAreaCardKnockedOutIfNoHP
.not_knocked_out
	pop de
	pop hl
	jp SwapTurn


; used to bounce back an attack of the RESIDUAL category.
; when MACHAMP is damaged, if its Strikes Back is active, the
; attacking Pokemon (turn holder's Active Pokemon) takes 10 damage.
; output:
;	carry = set:  if Machamp is unable to use its Pokemon Power
HandleStrikesBack_AgainstResidualAttack::
	ld a, [wTempNonTurnDuelistCardID]
	cp MACHAMP
	ret nz ; return if the Defending Pokemon isn't a Machamp
	ld a, [wLoadedAttackCategory]
	and RESIDUAL
	ret nz
	ld a, [wDealtDamage]
	or a
	ret z
	call SwapTurn
	call CheckCannotUseDueToStatus
	call SwapTurn
	ret c  ; return if Pokemon Power can't be used because of status or Toxic Gas
	ld hl, 10 ; amount of damage to give the Attacking Pokemon
	call ApplyStrikesBack_AgainstResidualAttack
	jp nc, WaitForWideTextBoxInput
	ret

; output:
;	carry = set:  if the Attacking Pokemon was Knocked Out
ApplyStrikesBack_AgainstResidualAttack::
	push hl
	call LoadTxRam3
	ld a, [wTempTurnDuelistCardID]
	ld e, a
	ld d, $0
	call LoadCardDataToBuffer2_FromCardID
	ld hl, wLoadedCard2Name
	ld a, [hli]
	ld h, [hl]
	ld l, a
	call LoadTxRam2
	ld a, DUELVARS_ARENA_CARD_HP
	get_turn_duelist_var
	pop de
	push af
	push hl
	call SubtractHP
	ldtx hl, ReceivesDamageDueToStrikesBackText
	call DrawWideTextBox_PrintText
	pop hl
	pop af
	or a
	ret z
	call WaitForWideTextBoxInput
	xor a ; PLAY_AREA_ARENA
	call PrintPlayAreaCardKnockedOutIfNoHP
	bank1call DrawDuelHUDs
	scf
	ret
