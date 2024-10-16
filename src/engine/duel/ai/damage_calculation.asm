; stores in wDamage, wAIMinDamage and wAIMaxDamage the calculated damage
; done to the defending Pokémon by a given card and attack
; input:
;	a = attack index to take into account
;	[hTempPlayAreaLocation_ff9d] = location of attacking card to consider
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
; set wAIMinDamage and wAIMaxDamage to damage of attack
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
; if temp. location is active, damage calculation can be done directly...
	ldh a, [hTempPlayAreaLocation_ff9d]
	or a
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

; calculates the damage that will be dealt to the player's active card
; using the card that is located in hTempPlayAreaLocation_ff9d
; taking into account weakness/resistance/pluspowers/defenders/etc
; and outputs the result capped at a max of $ff
; input:
;	[wAIMinDamage] = base damage
;	[wAIMaxDamage] = base damage
;	[wDamage]      = base damage
;	[hTempPlayAreaLocation_ff9d] = turn holder's card location as the attacker
CalculateDamage_VersusDefendingPokemon:
	ld hl, wAIMinDamage
	call _CalculateDamage_VersusDefendingPokemon
	ld hl, wAIMaxDamage
	call _CalculateDamage_VersusDefendingPokemon
	ld hl, wDamage
;	fallthrough

_CalculateDamage_VersusDefendingPokemon:
	ld e, [hl]
	ld d, $00
	push hl

	; load this card's data
	ldh a, [hTempPlayAreaLocation_ff9d]
	add DUELVARS_ARENA_CARD
	get_turn_duelist_var
	call _GetCardIDFromDeckIndex
	ld [wTempTurnDuelistCardID], a

	; load player's arena card data
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
	ld de, $0
	jr .done
.vulnerable
	ldh a, [hTempPlayAreaLocation_ff9d]
	or a
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
	; apply pluspower and defender boosts
	ldh a, [hTempPlayAreaLocation_ff9d]
	add CARD_LOCATION_ARENA
	ld b, a
	call ApplyAttachedPluspower
	rst SwapTurn
	ld b, CARD_LOCATION_ARENA
	call ApplyAttachedDefender
	call HandleDamageReduction
	; test if de underflowed
	bit 7, d
	jr z, .no_underflow
	ld de, $0

.no_underflow
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
	pop hl
	ld [hl], e
	ld a, d
	or a
	ret z
	; cap damage
	ld a, $ff
	ld [hl], a
	ret

; stores in wDamage, wAIMinDamage and wAIMaxDamage the calculated damage
; done to the Pokémon at hTempPlayAreaLocation_ff9d
; by the defending Pokémon, using the attack index at a
; input:
;	a = attack index
;	[hTempPlayAreaLocation_ff9d] = location of card to calculate
;	                               damage as the receiver
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

; set wAIMinDamage and wAIMaxDamage to damage of attack
; these values take into account the range of damage
; that the attack can span (e.g. min and max number of hits)
	ld a, [wDamage]
	ld [wAIMinDamage], a
	ld [wAIMaxDamage], a
	rst SwapTurn
	ldh a, [hTempPlayAreaLocation_ff9d]
	push af
	xor a
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
; if temp. location is active, damage calculation can be done directly...
	ldh a, [hTempPlayAreaLocation_ff9d]
	or a
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
	; reset changed weakness
	inc l ; DUELVARS_ARENA_CARD_CHANGED_WEAKNESS
	ld b, [hl]
	ld [hl], a
	; reset changed resistance
	inc l ; DUELVARS_ARENA_CARD_CHANGED_RESISTANCE
	ld c, [hl]
	ld [hl], a
	push bc ; backup Defending Pokémon's changed Weakness/Resistance
	push hl
	call CalculateDamage_FromDefendingPokemon
; ...and subsequently recovered to continue the duel normally
	pop hl ; DUELVARS_ARENA_CARD_CHANGED_RESISTANCE
	pop bc ; Defending Pokémon's changed Weakness/Resistance
	ld [hl], c
	dec l ; DUELVARS_ARENA_CARD_CHANGED_WEAKNESS
	ld [hl], b
	pop bc ; Defending Pokémon's Substatus 1/2
	dec l ; DUELVARS_ARENA_CARD_SUBSTATUS2
	ld [hl], c
	dec l ; DUELVARS_ARENA_CARD_SUBSTATUS1
	ld [hl], b
	ret

; similar to CalculateDamage_VersusDefendingPokemon but reversed,
; calculating damage of the defending Pokémon versus
; the card located in hTempPlayAreaLocation_ff9d
; taking into account weakness/resistance/pluspowers/defenders/etc
; and poison damage for two turns
; and outputs the result capped at a max of $ff
; input:
;	[wAIMinDamage] = base damage
;	[wAIMaxDamage] = base damage
;	[wDamage]      = base damage
;	[hTempPlayAreaLocation_ff9d] = location of card to calculate
;								 damage as the receiver
CalculateDamage_FromDefendingPokemon:
	ld hl, wAIMinDamage
	call .CalculateDamage
	ld hl, wAIMaxDamage
	call .CalculateDamage
	ld hl, wDamage
	; fallthrough

.CalculateDamage
	ld e, [hl]
	ld d, $00
	push hl

	; load player active card's data
	rst SwapTurn
	ld a, DUELVARS_ARENA_CARD
	get_turn_duelist_var
	call _GetCardIDFromDeckIndex
	ld [wTempTurnDuelistCardID], a
	rst SwapTurn

	; load opponent's card data
	ldh a, [hTempPlayAreaLocation_ff9d]
	add DUELVARS_ARENA_CARD
	get_turn_duelist_var
	call _GetCardIDFromDeckIndex
	ld [wTempNonTurnDuelistCardID], a

	rst SwapTurn
	call HandleDoubleDamageSubstatus
	bit UNAFFECTED_BY_WEAKNESS_RESISTANCE_F, d
	res UNAFFECTED_BY_WEAKNESS_RESISTANCE_F, d
	jr nz, .not_resistant

; handle weakness
	call GetArenaCardColor
	call TranslateColorToWR
	ld b, a
	rst SwapTurn
	ldh a, [hTempPlayAreaLocation_ff9d]
	or a
	jr nz, .bench_weak
	ld a, DUELVARS_ARENA_CARD_CHANGED_WEAKNESS
	get_turn_duelist_var
	or a
	jr nz, .unchanged_weak

.bench_weak
	ldh a, [hTempPlayAreaLocation_ff9d]
	add DUELVARS_ARENA_CARD
	get_turn_duelist_var
	call LoadCardDataToBuffer2_FromDeckIndex
	ld a, [wLoadedCard2Weakness]
.unchanged_weak
	and b
	jr z, .not_weak
	; double de
	sla e
	rl d

.not_weak
; handle resistance
	ldh a, [hTempPlayAreaLocation_ff9d]
	or a
	jr nz, .bench_res
	ld a, DUELVARS_ARENA_CARD_CHANGED_RESISTANCE
	get_turn_duelist_var
	or a
	jr nz, .unchanged_res

.bench_res
	ldh a, [hTempPlayAreaLocation_ff9d]
	add DUELVARS_ARENA_CARD
	get_turn_duelist_var
	call LoadCardDataToBuffer2_FromDeckIndex
	ld a, [wLoadedCard2Resistance]
.unchanged_res
	and b
	jr z, .not_resistant
	ld hl, -30
	add hl, de
	ld e, l
	ld d, h

.not_resistant
	; apply pluspower and defender boosts
	rst SwapTurn
	ld b, CARD_LOCATION_ARENA
	call ApplyAttachedPluspower
	rst SwapTurn
	ldh a, [hTempPlayAreaLocation_ff9d]
	add CARD_LOCATION_ARENA
	ld b, a
	call ApplyAttachedDefender
	ldh a, [hTempPlayAreaLocation_ff9d]
	or a
	call z, HandleDamageReduction
	bit 7, d
	jr z, .no_underflow
	ld de, $0

.no_underflow
	ldh a, [hTempPlayAreaLocation_ff9d]
	or a
	jr nz, .done
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
	pop hl
	ld [hl], e
	ld a, d
	or a
	ret z
	ld a, $ff
	ld [hl], a
	ret
