;----------------------------------------
;  THIS FILE WAS REMOVED FROM THE BUILD
;----------------------------------------

; prints player's coordinates by pressing B
; and draws palettes by pressing A
Func_1c003:
	ld a, [wCurMap]
	or a
	jr z, SetWindowOff
	ld a, [wOverworldMode]
	cp OWMODE_START_SCRIPT
	jr nc, SetWindowOff

	ldh a, [hKeysHeld]
	ld b, a
	and A_BUTTON | B_BUTTON
	cp b
	jr nz, SetWindowOff
	and B_BUTTON
	jr z, SetWindowOff

	ld bc, $20
	ld a, [wPlayerXCoord]
	bank1call WriteTwoByteNumberInTxSymbolFormat
	ld bc, $320
	ld a, [wPlayerYCoord]
	bank1call WriteTwoByteNumberInTxSymbolFormat
	ld a, $77
	ldh [hWX], a
	ld a, $88
	ldh [hWY], a

	ldh a, [hKeysPressed]
	and A_BUTTON
	jr z, .skip_load_scene
	ld a, SCENE_COLOR_PALETTE
	lb bc, 0, 33
	call LoadScene
.skip_load_scene
	ldh a, [hKeysHeld]
	and A_BUTTON
	jp z, SetWindowOn
	ld a, $67
	ldh [hWX], a
	ld a, $68
	ldh [hWY], a
	jp SetWindowOn
