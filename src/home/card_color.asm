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
	call GetTurnDuelistVariable
	bit HAS_CHANGED_COLOR_F, a
	jr nz, .has_changed_color
.regular_color
	ld a, e
	add DUELVARS_ARENA_CARD
	call GetTurnDuelistVariable
	call GetCardIDFromDeckIndex
	call GetCardType
	cp TYPE_TRAINER
	jr nz, .got_type
	ld a, COLORLESS
.got_type
	pop de
	pop hl
	ret
.has_changed_color
	ld a, e
	call CheckCannotUseDueToStatus_OnlyToxicGasIfANon0
	jr c, .regular_color ; jump if can't use Shift
	ld a, e
	add DUELVARS_ARENA_CARD_CHANGED_TYPE
	call GetTurnDuelistVariable
	pop de
	pop hl
	and $f
	ret


; finds the Weakness of one of the turn holder's in-play Pokemon
; preserves bc and hl
; input:
;	a = play area location offset (PLAY_AREA_* constant)
; output:
;	a = Weakness of the Pokemon from input
GetPlayAreaCardWeakness::
	or a
	jr z, GetArenaCardWeakness
	add DUELVARS_ARENA_CARD
	jr GetCardWeakness

; finds the Weakness of the turn holder's Active Pokemon's, either what's
; printed on the card or whatever it might have become via a card effect
; preserves bc and hl
; output:
;	a = Weakness of the turn holder's Active Pokemon
GetArenaCardWeakness::
	ld a, DUELVARS_ARENA_CARD_CHANGED_WEAKNESS
	call GetTurnDuelistVariable
	or a
	ret nz
	ld a, DUELVARS_ARENA_CARD
;	fallthrough

GetCardWeakness::
	call GetTurnDuelistVariable
	call LoadCardDataToBuffer2_FromDeckIndex
	ld a, [wLoadedCard2Weakness]
	ret


; finds the Resistance of one of the turn holder's in-play Pokemon
; preserves bc and hl
; input:
;	a = play area location offset (PLAY_AREA_* constant)
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
; preserves bc and hl
; output:
;	a = Resistance of the turn holder's Active Pokemon
GetArenaCardResistance::
	ld a, DUELVARS_ARENA_CARD_CHANGED_RESISTANCE
	call GetTurnDuelistVariable
	or a
	ret nz
	ld a, DUELVARS_ARENA_CARD
;	fallthrough

GetCardResistance::
	call GetTurnDuelistVariable
	call LoadCardDataToBuffer2_FromDeckIndex
	ld a, [wLoadedCard2Resistance]
	ret


; checks if the turn holder's CHARIZARD's Energy Burn is active,
; and if so, it turns all Energy (except for Double Colorless Energy)
; at wAttachedEnergies into Fire Energy
HandleEnergyBurn::
	ld a, DUELVARS_ARENA_CARD
	call GetTurnDuelistVariable
	call GetCardIDFromDeckIndex
	ld a, e
	cp CHARIZARD
	ret nz
	call CheckCannotUseDueToStatus
	ret c
	ld hl, wAttachedEnergies
	ld c, NUM_COLORED_TYPES
	xor a
.zero_next_energy
	ld [hli], a
	dec c
	jr nz, .zero_next_energy
	ld a, [wTotalAttachedEnergies]
	ld [wAttachedEnergies], a
	ret
