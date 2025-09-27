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
	and PAD_A | PAD_B
	cp b
	jr nz, SetWindowOff
	and PAD_B
	jr z, SetWindowOff

	ld bc, $20
	ld a, [wPlayerXCoord]
	call WriteOneByteNumberInTxSymbolFormat_TrimLeadingZeros
	ld bc, $320
	ld a, [wPlayerYCoord]
	call WriteOneByteNumberInTxSymbolFormat_TrimLeadingZeros
	ld a, 112 + WX_OFS
	ldh [hWX], a
	ld a, 136
	ldh [hWY], a

	ldh a, [hKeysPressed]
	and PAD_A
	jr z, .skip_load_scene
	ld a, SCENE_COLOR_PALETTE
	lb bc, 0, 33
	call LoadScene
.skip_load_scene
	ldh a, [hKeysHeld]
	and PAD_A
	jp z, SetWindowOn
	ld a, 96 + WX_OFS
	ldh [hWX], a
	ld a, 104
	ldh [hWY], a
	jp SetWindowOn
