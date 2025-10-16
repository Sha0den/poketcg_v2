; output:
;	a = Active Pokemon's type/color (accounting for Venomoth's Shift Pokemon Power if active)
GetArenaCardColor::
	xor a ; PLAY_AREA_ARENA
;	fallthrough

; preserves all registers except af
; input:
;	a = play area location offset of the desired card (PLAY_AREA_* constant)
; output:
;	a = type/color of the turn holder's Pokemon from input
;	    (accounting for Venomoth's Shift Pokemon Power if active)
GetPlayAreaCardColor::
	push hl
	push de
	ld e, a
	add DUELVARS_ARENA_CARD_CHANGED_TYPE
	get_turn_duelist_var
	bit HAS_CHANGED_COLOR_F, a
	jr nz, .has_changed_color
.regular_color
	ld a, e
	add DUELVARS_ARENA_CARD
	get_turn_duelist_var
	call GetCardTypeFromDeckIndex_SaveDE
	cp TYPE_TRAINER
	jr nz, .got_type
	ld a, COLORLESS
.got_type
	pop de
	pop hl
	ret
.has_changed_color
	ld a, e
	call CheckIsIncapableOfUsingPkmnPower
	jr c, .regular_color ; jump if can't use Shift
	ld a, e
	add DUELVARS_ARENA_CARD_CHANGED_TYPE
	get_turn_duelist_var
	pop de
	pop hl
	and $f
	ret


; finds the Weakness of one of the turn holder's in-play Pokemon
; preserves bc and de
; input:
;	a = Pokémon's play area location offset (PLAY_AREA_* constant)
; output:
;	a = Weakness of the Pokemon from input
GetPlayAreaCardWeakness::
	or a
	jr z, GetArenaCardWeakness
	add DUELVARS_ARENA_CARD
	jr GetCardWeakness

; finds the Weakness of the turn holder's Active Pokemon's, either what's
; printed on the card or whatever it might have become via a card effect
; preserves bc and de
; output:
;	a = Weakness of the turn holder's Active Pokemon
GetArenaCardWeakness::
	ld a, DUELVARS_ARENA_CARD_CHANGED_WEAKNESS
	get_turn_duelist_var
	or a
	ret nz
	ld a, DUELVARS_ARENA_CARD
;	fallthrough

GetCardWeakness::
	get_turn_duelist_var
	call LoadCardDataToBuffer2_FromDeckIndex
	ld a, [wLoadedCard2Weakness]
	ret


; finds the Resistance of one of the turn holder's in-play Pokemon
; preserves bc and de
; input:
;	a = Pokémon's play area location offset (PLAY_AREA_* constant)
; output:
;	a = Resistance of the Pokemon from input
GetPlayAreaCardResistance::
	or a
	jr z, GetArenaCardResistance ; it's the Active Pokemon
	; it's a Benched Pokemon
	add DUELVARS_ARENA_CARD
	jr GetCardResistance

; finds the Resistance of the turn holder's Active Pokemon's, either what's
; printed on the card or whatever it might have become via a card effect
; preserves bc and de
; output:
;	a = Resistance of the turn holder's Active Pokemon
GetArenaCardResistance::
	ld a, DUELVARS_ARENA_CARD_CHANGED_RESISTANCE
	get_turn_duelist_var
	or a
	ret nz
	ld a, DUELVARS_ARENA_CARD
;	fallthrough

GetCardResistance::
	get_turn_duelist_var
	call LoadCardDataToBuffer2_FromDeckIndex
	ld a, [wLoadedCard2Resistance]
	ret


; converts a color to its equivalent WR_* (weakness/resistance) value
; preserves all registers except af
; input:
; 	a = type/color constant (e.g. FIRE, GRASS, etc.)
TranslateColorToWR::
	push hl
	add LOW(InvertedPowersOf2)
	ld l, a
	ld a, HIGH(InvertedPowersOf2)
	adc $0
	ld h, a
	ld a, [hl]
	pop hl
	ret

InvertedPowersOf2::
	db $80, $40, $20, $10, $08, $04, $02, $01


; checks if the turn holder's CHARIZARD's Energy Burn is active,
; and if so, it turns all Energy (except for Double Colorless Energy)
; at wAttachedEnergies into Fire Energy
; preserves de
; input:
;	e = Pokémon's play area location offset (PLAY_AREA_* constant)
;	[wAttachedEnergies] (8 bytes) = how many Energy of each type is attached to the Active Pokémon
;	[wTotalAttachedEnergies] = total amount of Energy attached to the Active Pokémon
HandleEnergyBurn::
	ld a, DUELVARS_ARENA_CARD
	add e
	get_turn_duelist_var
	call _GetCardIDFromDeckIndex
	cp CHARIZARD
	ret nz
	ld a, e
	call CheckIsIncapableOfUsingPkmnPower
	ret c
	ld hl, wAttachedEnergies
	ld c, NUM_COLORED_TYPES
	xor a
.zero_next_energy
	ld [hli], a
	dec c
	jr nz, .zero_next_energy
	ld a, [wTotalAttachedEnergies]
	ld [wAttachedEnergies + FIRE], a
	ret
