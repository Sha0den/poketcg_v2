; preserves all registers except af
; output:
;	carry = not set:  if wActiveScreenAnim, wd4c0, and wAnimationQueue are all $ff,
;	                  meaning that no animation is playing (or any animations have ended)
;	carry = set:  if an animation is playing
CheckAnyAnimationPlaying::
	push hl
	push bc
	ld a, [wActiveScreenAnim]
	ld hl, wd4c0
	and [hl]
	ld hl, wAnimationQueue
	ld c, ANIMATION_QUEUE_LENGTH
.loop
	and [hl]
	inc hl
	dec c
	jr nz, .loop
	cp $ff
	pop bc
	pop hl
	ret


; plays a duel animation
; the animations are loaded to a buffer
; and played in order, so they can be stacked
; preserves all registers except af
; input:
;	a = animation ID (DUEL_ANIM_* constant)
PlayDuelAnimation::
	ld [wTempAnimation], a ; hold an animation temporarily
	ldh a, [hBankROM]
	push af
	ld [wDuelAnimReturnBank], a

	push hl
	push bc
	push de
	ld a, BANK(LoadDuelAnimationToBuffer)
	rst BankswitchROM
	ld a, [wTempAnimation]
	cp DUEL_SPECIAL_ANIMS
	jr nc, .load_buffer

	ld hl, wDuelAnimBufferSize
	ld a, [wDuelAnimBufferCurPos]
	cp [hl]
	jr nz, .load_buffer
	call CheckAnyAnimationPlaying
	jr nc, .play_anim

.load_buffer
	call LoadDuelAnimationToBuffer
	jr .done

.play_anim
	call PlayLoadedDuelAnimation ; this function is also in Bank $07

.done
	pop de
	pop bc
	pop hl
	pop af
	jp BankswitchROM


UpdateQueuedAnimations::
	ldh a, [hBankROM]
	push af
	ld a, BANK(_UpdateQueuedAnimations)
	rst BankswitchROM
	call _UpdateQueuedAnimations
	call HandleAllSpriteAnimations
	pop af
	jp BankswitchROM


Func_3bb5::
	xor a
	ld [wd4c0], a
	ldh a, [hBankROM]
	push af
	ld a, [wDuelAnimReturnBank]
	rst BankswitchROM
	call HandleAllSpriteAnimations
	call CallHL
	pop af
	rst BankswitchROM
	ld a, $80
	ld [wd4c0], a
	ret
