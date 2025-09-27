; switches to CGB Normal Speed Mode if playing on CGB and current mode is Double Speed Mode
; preserves de
SwitchToCGBNormalSpeed::
	call CheckForCGB
	ret c
	ld hl, rSPD
	bit B_SPD_DOUBLE, [hl]
	ret z
	jr CGBSpeedSwitch

; switches to CGB Double Speed Mode if playing on CGB and current mode is Normal Speed Mode
; preserves de
SwitchToCGBDoubleSpeed::
	call CheckForCGB
	ret c
	ld hl, rSPD
	bit B_SPD_DOUBLE, [hl]
	ret nz
;	fallthrough

; switches between CGB Double Speed Mode and Normal Speed Mode
; preserves de and hl
CGBSpeedSwitch::
	ldh a, [rIE]
	push af
	xor a
	ldh [rIE], a
	set B_SPD_PREPARE, [hl]
	xor a
	ldh [rIF], a
	ldh [rIE], a
	ld a, JOYP_GET_NONE
	ldh [rJOYP], a
	stop
	call SetupTimer
	pop af
	ldh [rIE], a
	ret
