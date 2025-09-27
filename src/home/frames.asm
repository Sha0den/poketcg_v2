; writes from hl the pointer to the function to be called by DoFrame
; preserves all registers except af
; input:
;	hl = function to be called by DoFrame
; output:
;	[wDoFrameFunction] = hl
SetDoFrameFunction::
	ld a, l
	ld [wDoFrameFunction], a
	ld a, h
	ld [wDoFrameFunction + 1], a
	ret


; calls DoFrame a times
; preserves all registers except af
; input:
;	a = number of times to run the DoFrame function
DoAFrames::
.loop
	call DoFrame
	dec a
	jr nz, .loop
	ret


; preserves all registers
DoFrameIfLCDEnabled::
	push af
	ldh a, [rLCDC]
	bit B_LCDC_ENABLE, a
	call nz, DoFrame
	pop af
	ret


; updates background, sprites and other game variables, halts until vblank, and reads user input
; if wDebugPauseAllowed is not 0, the game can be paused (and resumed) by pressing the SELECT button
; preserves all registers
DoFrame::
	push af
	push hl
	push de
	push bc
	ld hl, wDoFrameFunction ; context-specific function
	call CallIndirect
	call WaitForVBlank
	call ReadJoypad
	call HandleDPadRepeat
	ld a, [wDebugPauseAllowed]
	or a
	jr z, .done
	ldh a, [hKeysPressed]
	and PAD_SELECT
	jr z, .done
.game_paused_loop
	call WaitForVBlank
	call ReadJoypad
	call HandleDPadRepeat
	ldh a, [hKeysPressed]
	and PAD_SELECT
	jr z, .game_paused_loop
.done
	pop bc
	pop de
	pop hl
	pop af
	ret


; handles D-pad repeat counter
; used to quickly scroll through menus when a relevant D-pad key is held
; preserves bc and de
HandleDPadRepeat::
	ldh a, [hKeysHeld]
	ldh [hDPadHeld], a
	and PAD_CTRL_PAD
	jr z, .done
	ld hl, hDPadRepeat
	ldh a, [hKeysPressed]
	and PAD_CTRL_PAD
	jr z, .dpad_key_held
	ld [hl], 24
	ret
.dpad_key_held
	dec [hl]
	jr nz, .done
	ld [hl], 6
	ret
.done
	ldh a, [hKeysPressed]
	and PAD_BUTTONS
	ldh [hDPadHeld], a
	ret
