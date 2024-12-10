; stores in wDamage, wAIMinDamage and wAIMaxDamage the calculated damage
; done to the Defending Pokémon by the Pokémon at hTempPlayAreaLocation_ff9d,
; using the attack index given in a.
; input:
;	a = which attack should be used (0 = first attack, 1 = second attack)
;	[hTempPlayAreaLocation_ff9d] = play area location offset of the Pokémon that
;	                               would be attacking (PLAY_AREA_* constant)
; output:
;	[wDamage] = final damage from the attack (with all modifiers and 1 turn of poison damage)
EstimateDamage_VersusDefendingCard:
	ld [wSelectedAttack], a
	ld e, a
	ldh a, [hTempPlayAreaLocation_ff9d]
	add DUELVARS_ARENA_CARD
	get_turn_duelist_var
	ld d, a
	call CopyAttackDataAndDamage_FromDeckIndex
	ld a, [wLoadedAttackCategory]
	cp POKEMON_POWER
	jr nz, .is_attack

.not_attack
; set wDamage, wAIMinDamage and wAIMaxDamage to zero
	ld hl, wDamage
	xor a
	ld [hli], a
	ld [hl], a
	ld [wAIMinDamage], a
	ld [wAIMaxDamage], a
	ld e, a
	ld d, a
	ret

.is_attack
; set wAIMinDamage and wAIMaxDamage to damage of attack.
; these values take into account the range of damage
; that the attack can span (e.g. min and max number of hits)
	ld a, [wDamage]
	ld [wAIMinDamage], a
	ld [wAIMaxDamage], a
	ld a, EFFECTCMDTYPE_AI
	call TryExecuteEffectCommandFunction
	ld a, [wAIMinDamage]
	ld hl, wAIMaxDamage
	or [hl]
	jr nz, .calculation
	ld a, [wDamage]
	ld [wAIMinDamage], a
	ld [wAIMaxDamage], a

.calculation
; if temp. location is Active, damage calculation can be done directly...
	ldh a, [hTempPlayAreaLocation_ff9d]
	or a ; cp PLAY_AREA_ARENA
	jr z, CalculateDamage_VersusDefendingPokemon

; ...otherwise substatuses need to be temporarily reset to account
; for the switching, to obtain the right damage calculation...
	; copy evolutionary stage
	ldh a, [hTempPlayAreaLocation_ff9d]
	add DUELVARS_ARENA_CARD_STAGE
	get_turn_duelist_var
	ld d, a
	ld l, DUELVARS_ARENA_CARD_STAGE
	ld b, [hl]
	ld [hl], d
	; copy changed type/color
	ldh a, [hTempPlayAreaLocation_ff9d]
	add DUELVARS_ARENA_CARD_CHANGED_TYPE
	ld l, a
	ld d, [hl]
	ld l, DUELVARS_ARENA_CARD_CHANGED_TYPE
	ld c, [hl]
	ld [hl], d
	push bc ; backup Active Pokémon's stage and changed type
	; reset substatus1 and substatus2
	xor a
	ld l, DUELVARS_ARENA_CARD_SUBSTATUS1
	ld b, [hl]
	ld [hl], a
	inc l ; DUELVARS_ARENA_CARD_SUBSTATUS2
	ld c, [hl]
	ld [hl], a
	push bc ; backup Active Pokémon's Substatus 1/2
	push hl
	call CalculateDamage_VersusDefendingPokemon
; ...and subsequently recovered to continue the duel normally
	pop hl ; DUELVARS_ARENA_CARD_SUBSTATUS2
	pop bc ; Active Pokémon's Substatus 1/2
	ld [hl], c
	dec l ; DUELVARS_ARENA_CARD_SUBSTATUS1
	ld [hl], b
	pop bc ; Active Pokémon's stage and changed type
	ld l, DUELVARS_ARENA_CARD_CHANGED_TYPE
	ld [hl], c
	ld l, DUELVARS_ARENA_CARD_STAGE
	ld [hl], b
	ret


; calculates the damage that will be dealt to the opponent's Active Pokémon
; using the the turn holder's Pokémon at location in hTempPlayAreaLocation_ff9d,
; taking into account Weakness/Resistance/Pluspowers/Defenders/etc.
; input:
;	[wAIMinDamage] = base damage
;	[wAIMaxDamage] = base damage
;	[wDamage]      = base damage
;	[hTempPlayAreaLocation_ff9d] = Attacking Pokémon's play area location offset (PLAY_AREA_* constant)
; output:
;	a & [wDamage] = adjusted damage (capped at $ff)
;	hl = wDamage
CalculateDamage_VersusDefendingPokemon:
	ld hl, wAIMinDamage
	call .CalculateDamage
	ld hl, wAIMaxDamage
	call .CalculateDamage
	ld hl, wDamage
;	fallthrough

; input:
;	[hl] = base damage to modify
.CalculateDamage
	push hl
	ld e, [hl]
	inc hl
	ld d, [hl]

	; load the Attacking Pokémon's card data
	ldh a, [hTempPlayAreaLocation_ff9d]
	add DUELVARS_ARENA_CARD
	get_turn_duelist_var
	call _GetCardIDFromDeckIndex
	ld [wTempTurnDuelistCardID], a

	; load the Defending Pokémon's card data
	rst SwapTurn
	ld a, DUELVARS_ARENA_CARD
	get_turn_duelist_var
	call _GetCardIDFromDeckIndex
	ld [wTempNonTurnDuelistCardID], a
	rst SwapTurn

	push de
	call HandleNoDamageOrEffectSubstatus
	pop de
	jr nc, .vulnerable
	; invulnerable to damage
	ld de, 0
	jr .done

.vulnerable
	ldh a, [hTempPlayAreaLocation_ff9d]
	or a ; cp PLAY_AREA_ARENA
	call z, HandleDoubleDamageSubstatus
	; skips the weak/res checks if unaffected.
	bit UNAFFECTED_BY_WEAKNESS_RESISTANCE_F, d
	res UNAFFECTED_BY_WEAKNESS_RESISTANCE_F, d
	jr nz, .not_resistant

; handle weakness
	ldh a, [hTempPlayAreaLocation_ff9d]
	call GetPlayAreaCardColor
	call TranslateColorToWR
	ld b, a
	rst SwapTurn
	call GetArenaCardWeakness
	rst SwapTurn
	and b
	jr z, .not_weak
	; double de
	sla e
	rl d

.not_weak
; handle resistance
	rst SwapTurn
	call GetArenaCardResistance
	rst SwapTurn
	and b
	jr z, .not_resistant
	ld hl, -30
	add hl, de
	ld e, l
	ld d, h

.not_resistant
; account for any attached PlusPower or Defender cards.
	ldh a, [hTempPlayAreaLocation_ff9d]
	add CARD_LOCATION_ARENA
	ld b, a
	call ApplyAttachedPluspower
	rst SwapTurn
	ld b, CARD_LOCATION_ARENA
	call ApplyAttachedDefender
; apply any remaining damage modifiers.
	call HandleDamageReduction
	; test if de underflowed
	bit 7, d
	jr z, .no_underflow
	ld de, 0

.no_underflow
; account for 1 turn of poison damage since it's the Active Pokémon.
; add 10 daamge if Poisoned or 20 damage if Double Poisoned.
	ld a, DUELVARS_ARENA_CARD_STATUS
	get_turn_duelist_var
	and DOUBLE_POISONED
	jr z, .not_poisoned
	ld c, 20
	and DOUBLE_POISONED & (POISONED ^ $ff)
	jr nz, .add_poison
	ld c, 10
.add_poison
	ld a, c
	add e
	ld e, a
	ld a, $00
	adc d
	ld d, a
.not_poisoned
	rst SwapTurn

.done
	pop hl ; address from input
	ld [hl], e
	ld a, d
	or a
	ret z
	; cap damage at 255 (1 byte)
	ld a, 255
	ld [hl], a
	ret


; stores in wDamage, wAIMinDamage and wAIMaxDamage the calculated damage
; done to the Pokémon at hTempPlayAreaLocation_ff9d by the Defending Pokémon,
; using the attack index given in a.
; input:
;	a = which attack should be used (0 = first attack, 1 = second attack)
;	[hTempPlayAreaLocation_ff9d] = play area location offset of the Pokémon that
;	                               would receive the attack (PLAY_AREA_* constant)
; output:
;	[wDamage] = final damage from the attack (with all modifiers and 2 turns of poison damage)
EstimateDamage_FromDefendingPokemon:
	rst SwapTurn
	ld [wSelectedAttack], a
	ld e, a
	ld a, DUELVARS_ARENA_CARD
	get_turn_duelist_var
	ld d, a
	call CopyAttackDataAndDamage_FromDeckIndex
	rst SwapTurn
	ld a, [wLoadedAttackCategory]
	cp POKEMON_POWER
	jp z, EstimateDamage_VersusDefendingCard.not_attack

; set wAIMinDamage and wAIMaxDamage to the damage from the attack.
; these values take into account the range of damage
; that the attack can span (e.g. min and max number of hits)
	ld a, [wDamage]
	ld [wAIMinDamage], a
	ld [wAIMaxDamage], a
	rst SwapTurn
	ldh a, [hTempPlayAreaLocation_ff9d]
	push af
	xor a ; PLAY_AREA_ARENA
	ldh [hTempPlayAreaLocation_ff9d], a
	ld a, EFFECTCMDTYPE_AI
	call TryExecuteEffectCommandFunction
	pop af
	ldh [hTempPlayAreaLocation_ff9d], a
	rst SwapTurn
	ld a, [wAIMinDamage]
	ld hl, wAIMaxDamage
	or [hl]
	jr nz, .calculation
	ld a, [wDamage]
	ld [wAIMinDamage], a
	ld [wAIMaxDamage], a

.calculation
; if temp. location is Active, damage calculation can be done directly...
	ldh a, [hTempPlayAreaLocation_ff9d]
	or a ; cp PLAY_AREA_ARENA
	jr z, CalculateDamage_FromDefendingPokemon

; ...otherwise substatuses need to be temporarily reset to account
; for the switching, to obtain the right damage calculation...
	; reset substatus1
	ld a, DUELVARS_ARENA_CARD_SUBSTATUS1
	get_turn_duelist_var
	ld b, a
	xor a
	ld [hl], a
	; reset substatus2
	inc l ; DUELVARS_ARENA_CARD_SUBSTATUS2
	ld c, [hl]
	ld [hl], a
	push bc ; backup Defending Pokémon's Substatus 1/2
	push hl
	call CalculateDamage_FromDefendingPokemon
; ...and subsequently recovered to continue the duel normally
	pop hl ; DUELVARS_ARENA_CARD_SUBSTATUS2
	pop bc ; Defending Pokémon's Substatus 1/2
	ld [hl], c
	dec l ; DUELVARS_ARENA_CARD_SUBSTATUS1
	ld [hl], b
	ret


; similar to CalculateDamage_VersusDefendingPokemon but reversed,
; calculating damage of the Defending Pokémon versus
; the AI's Pokémon located in hTempPlayAreaLocation_ff9d,
; taking into account Weakness/Resistance/Pluspowers/Defenders/etc
; as well as poison damage for two turns.
; input:
;	[wAIMinDamage] = base damage
;	[wAIMaxDamage] = base damage
;	[wDamage]      = base damage
;	[hTempPlayAreaLocation_ff9d] = play area location offset of the Pokémon that would
;	                               be receiving the damage (PLAY_AREA_* constant)
; output:
;	a & [wDamage] = adjusted damage (capped at $ff)
;	hl = wDamage
CalculateDamage_FromDefendingPokemon:
	ld hl, wAIMinDamage
	call .CalculateDamage
	ld hl, wAIMaxDamage
	call .CalculateDamage
	ld hl, wDamage
	; fallthrough

; input:
;	[hl] = base damage to modify
.CalculateDamage
	push hl
	ld e, [hl]
	inc hl
	ld d, [hl]

	; load the card data for the Player's Active Pokémon
	rst SwapTurn
	ld a, DUELVARS_ARENA_CARD
	get_turn_duelist_var
	call _GetCardIDFromDeckIndex
	ld [wTempTurnDuelistCardID], a
	rst SwapTurn

	; load the card data for the Pokémon receiving the attack 
	ldh a, [hTempPlayAreaLocation_ff9d]
	add DUELVARS_ARENA_CARD
	get_turn_duelist_var
	call _GetCardIDFromDeckIndex
	ld [wTempNonTurnDuelistCardID], a

; handle double damage substatus
	ld a, DUELVARS_ARENA_CARD_SUBSTATUS1
	call GetNonTurnDuelistVariable
	cp SUBSTATUS1_NEXT_TURN_DOUBLE_DAMAGE
	call z, DoubleDamage

	bit UNAFFECTED_BY_WEAKNESS_RESISTANCE_F, d
	res UNAFFECTED_BY_WEAKNESS_RESISTANCE_F, d
	jr nz, .not_resistant

; handle weakness
	rst SwapTurn
	call GetArenaCardColor
	rst SwapTurn
	call TranslateColorToWR
	ld b, a
	ldh a, [hTempPlayAreaLocation_ff9d]
	call GetPlayAreaCardWeakness
	and b
	jr z, .not_weak
	; double de
	sla e
	rl d

.not_weak
; handle resistance
	ldh a, [hTempPlayAreaLocation_ff9d]
	call GetPlayAreaCardResistance
	and b
	jr z, .not_resistant
	ld hl, -30
	add hl, de
	ld e, l
	ld d, h

.not_resistant
; account for any attached Pluspower and Defender cards.
	rst SwapTurn
	ld b, CARD_LOCATION_ARENA
	call ApplyAttachedPluspower
	rst SwapTurn
	ldh a, [hTempPlayAreaLocation_ff9d]
	add CARD_LOCATION_ARENA
	ld b, a
	call ApplyAttachedDefender
	call HandleDamageReduction
	; test if de underflowed
	bit 7, d
	jr z, .no_underflow
	ld de, 0

.no_underflow
	ldh a, [hTempPlayAreaLocation_ff9d]
	or a ; cp PLAY_AREA_ARENA
	jr nz, .done
; it's the AI's Active Pokémon, so account for 2 turns of poison damage.
; add 20 damage if Poisoned or 40 damage if Double Poisoned.
	ld a, DUELVARS_ARENA_CARD_STATUS
	get_turn_duelist_var
	and DOUBLE_POISONED
	jr z, .done
	ld c, 40
	and DOUBLE_POISONED & (POISONED ^ $ff)
	jr nz, .add_poison
	ld c, 20
.add_poison
	ld a, c
	add e
	ld e, a
	ld a, $00
	adc d
	ld d, a

.done
	pop hl ; address from input
	ld [hl], e
	ld a, d
	or a
	ret z
	; cap damage at 255 (1 byte)
	ld a, 255
	ld [hl], a
	ret
