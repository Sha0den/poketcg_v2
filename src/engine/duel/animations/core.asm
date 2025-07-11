; preserves all registers except af
_ResetAnimationQueue::
	push hl
	push bc
	call Set_OBJ_8x8
	ld hl, wDoFrameFunction
	ld a, LOW(UpdateQueuedAnimations)
	ld [hli], a
	ld [hl], HIGH(UpdateQueuedAnimations)
	ld a, $ff
	ld hl, wAnimationQueue
	ld c, ANIMATION_QUEUE_LENGTH
.fill_queue
	ld [hli], a
	dec c
	jr nz, .fill_queue
	ld [wActiveScreenAnim], a
	ld [wd4c0], a
	xor a
	ld [wDuelAnimBufferCurPos], a
	ld [wDuelAnimBufferSize], a
	ld [wDuelAnimSetScreen], a
	call DefaultScreenAnimationUpdate
	call EnableAndClearSpriteAnimations
	pop bc
	pop hl
	ret


PlayLoadedDuelAnimation::
	ld a, [wDoFrameFunction + 0]
	cp LOW(UpdateQueuedAnimations)
	ret nz
	ld a, [wDoFrameFunction + 1]
	cp HIGH(UpdateQueuedAnimations)
	ret nz

	ld a, [wTempAnimation]
	ld [wd4bf], a
	cp DUEL_SPECIAL_ANIMS
	jp nc, Func_1cb5e

	push hl
	push bc
	push de
	call GetAnimationData
; hl: pointer

	ld a, [wAnimationsDisabled]
	or a
	jr z, .check_to_play_sfx
	; animations are disabled
	push hl
	ld bc, ANIM_SPRITE_ANIM_FLAGS
	add hl, bc
	ld a, [hl]
	; if flag is set, play animation anyway
	and SPRITE_ANIM_FLAG_UNSKIPPABLE
	pop hl
	jr z, .return

.check_to_play_sfx
	push hl
	ld bc, ANIM_SOUND_FX_ID
	add hl, bc
	ld a, [hl]
	pop hl
	or a
	call nz, PlaySFX

; this data field is always $00,
; so this calculation is unnecessary
; seems like there was supposed to be
; more than 1 function to handle animation
	push hl
	ld bc, ANIM_HANDLER_FUNCTION
	add hl, bc
	ld a, [hl]
	rlca
	add LOW(.address) ; $48
	ld l, a ; LO
	ld a, HIGH(.address) ; $49
	adc 0
	ld h, a ; HI
; hl: pointer
	ld a, [hli]
	ld b, [hl]
	ld c, a
	pop hl

	call CallBC
.return
	pop de
	pop bc
	pop hl
	ret

.address
	dw .handler_func

.handler_func
; if any of ANIM_SPRITE_ID, ANIM_PALETTE_ID and ANIM_SPRITE_ANIM_ID
; are 0, then return
	ld e, l
	ld d, h
	ld c, ANIM_SPRITE_ANIM_ID + 1
.loop
	ld a, [de]
	or a
	jr z, .return_with_carry
	inc de
	dec c
	jr nz, .loop

	ld a, [hli] ; ANIM_SPRITE_ID
	farcall CreateSpriteAndAnimBufferEntry
	ld a, [wWhichSprite]
	ld [wAnimationQueue], a ; push an animation to the queue

	xor a
	ld [wVRAMTileOffset], a
	ld [wd4cb], a

	ld a, [hli] ; ANIM_PALETTE_ID
	farcall LoadPaletteData
	ld a, [hli] ; ANIM_SPRITE_ANIM_ID

	push af
	ld a, [hli] ; ANIM_SPRITE_ANIM_FLAGS
	ld [wAnimFlags], a
	call LoadAnimCoordsAndFlags
	pop af

	farcall StartNewSpriteAnimation
	or a
	ret

.return_with_carry
	scf
	ret


; loads the correct coordinates/flags for the sprite animation in wAnimationQueue
; preserves all registers except af
; input:
;	[wAnimationQueue] = sprite ID (SPRITE_* constant)
LoadAnimCoordsAndFlags:
	push hl
	push bc
	ld a, [wAnimationQueue]
	ld c, SPRITE_ANIM_ATTRIBUTES
	call GetSpriteAnimBufferProperty_SpriteInA
	call GetAnimCoordsAndFlags

	push af
	and SPRITE_ANIM_FLAG_Y_FLIP | SPRITE_ANIM_FLAG_X_FLIP
	or [hl]
	ld [hli], a
	ld a, b
	ld [hli], a ; SPRITE_ANIM_COORD_X
	ld [hl], c ; SPRITE_ANIM_COORD_Y
	pop af

	ld bc, SPRITE_ANIM_FLAGS - SPRITE_ANIM_COORD_Y
	add hl, bc
	and SPRITE_ANIM_FLAG_Y_INVERTED | SPRITE_ANIM_FLAG_X_INVERTED
	or [hl]
	ld [hl], a
	pop bc
	pop hl
	ret


; outputs x and y coordinates for the sprite animation,
; taking into account who the turn duelist is.
; also returns in a the allowed animation flags of
; the configuration that is selected.
; preserves de and hl
; output:
;	a = animation flags
;	b = x coordinate
;	c = y coordinate
GetAnimCoordsAndFlags:
	push hl
	ld c, 0
	ld a, [wAnimFlags]
	and SPRITE_ANIM_FLAG_CENTERED
	jr nz, .calc_addr

	ld a, [wDuelAnimationScreen]
	add a ; 2 * [wDuelAnimationScreen]
	ld c, a
	add a ; 4 * [wDuelAnimationScreen]
	add c ; 6 * [wDuelAnimationScreen]
	add a ; 12 * [wDuelAnimationScreen]
	ld c, a

	ld a, [wDuelAnimDuelistSide]
	cp PLAYER_TURN
	jr z, .player_side
; opponent side
	ld a, 6
	add c
	ld c, a
.player_side
	ld a, [wDuelAnimLocationParam]
	add c ; a = [wDuelAnimLocationParam] + c
	ld c, a
	ld b, 0
	ld hl, AnimationCoordinatesIndex
	add hl, bc
	ld c, [hl]

.calc_addr
	ld a, c
	add a ; a = c * 2
	add c ; a = c * 3
	ld c, a
	ld b, 0
	ld hl, AnimationCoordinates
	add hl, bc
	ld b, [hl] ; x coordinate
	inc hl
	ld c, [hl] ; y coordinate
	inc hl
	ld a, [wAnimFlags]
	and [hl] ; flags
	pop hl
	ret


AnimationCoordinatesIndex:
; animations in the Duel Main Scene
	db $01, $01, $01, $01, $01, $01 ; player
	db $02, $02, $02, $02, $02, $02 ; opponent

; animations in the Player's Play Area, for each Play Area Pokemon
	db $03, $04, $05, $06, $07, $08 ; player
	db $03, $04, $05, $06, $07, $08 ; opponent

; animations in the Opponent's Play Area, for each Play Area Pokemon
	db $09, $0a, $0b, $0c, $0d, $0e ; player
	db $09, $0a, $0b, $0c, $0d, $0e ; opponent


AnimationCoordinates:
; x coord, y coord, animation flags
	db  88, 88, SPRITE_ANIM_FLAG_3

; animations in the Duel Main Scene
	db  40, 80, NONE
	db 136, 48, SPRITE_ANIM_FLAG_Y_FLIP | SPRITE_ANIM_FLAG_X_FLIP | SPRITE_ANIM_FLAG_Y_INVERTED | SPRITE_ANIM_FLAG_X_INVERTED

; animations in the Player's Play Area, for each Play Area Pokemon
	db  88, 72, NONE
	db  24, 96, NONE
	db  56, 96, NONE
	db  88, 96, NONE
	db 120, 96, NONE
	db 152, 96, NONE

; animations in the Opponent's Play Area, for each Play Area Pokemon
	db  88, 80, NONE
	db 152, 40, NONE
	db 120, 40, NONE
	db  88, 40, NONE
	db  56, 40, NONE
	db  24, 40, NONE


; appends the current duel animation to the end of wDuelAnimBuffer
; preserves all registers except af
LoadDuelAnimationToBuffer::
	push hl
	push bc
	ld a, [wDuelAnimBufferCurPos]
	ld b, a
	ld hl, wDuelAnimBufferSize
	ld a, [hl]
	ld c, a
	add DUEL_ANIM_STRUCT_SIZE
	and %01111111
	cp b
	jr z, .skip
	ld [hl], a

	ld b, $00
	ld hl, wDuelAnimBuffer
	add hl, bc
	ld a, [wTempAnimation]
	ld [hli], a
	ld a, [wDuelAnimationScreen]
	ld [hli], a
	ld a, [wDuelAnimDuelistSide]
	ld [hli], a
	ld a, [wDuelAnimLocationParam]
	ld [hli], a
	ld a, [wDuelAnimDamage]
	ld [hli], a
	ld a, [wDuelAnimDamage + 1]
	ld [hli], a
	ld a, [wDuelAnimSetScreen]
	ld [hli], a
	ld a, [wDuelAnimReturnBank]
	ld [hl], a

.skip
	pop bc
	pop hl
	ret


; loads the animations from wDuelAnimBuffer in ascending order,
; starting at wDuelAnimBufferCurPos
; preserves bc and hl
PlayBufferedDuelAnimations:
	push hl
	push bc
.next_duel_anim
	ld a, [wDuelAnimBufferSize]
	ld b, a
	ld a, [wDuelAnimBufferCurPos]
	cp b
	jr z, .skip

	ld c, a
	add DUEL_ANIM_STRUCT_SIZE
	and %01111111
	ld [wDuelAnimBufferCurPos], a

	ld b, $00
	ld hl, wDuelAnimBuffer
	add hl, bc
	ld a, [hli]
	ld [wTempAnimation], a
	ld a, [hli]
	ld [wDuelAnimationScreen], a
	ld a, [hli]
	ld [wDuelAnimDuelistSide], a
	ld a, [hli]
	ld [wDuelAnimLocationParam], a
	ld a, [hli]
	ld [wDuelAnimDamage], a
	ld a, [hli]
	ld [wDuelAnimDamage + 1], a
	ld a, [hli]
	ld [wDuelAnimSetScreen], a
	ld a, [hl]
	ld [wDuelAnimReturnBank], a

	call PlayLoadedDuelAnimation
	call CheckAnyAnimationPlaying
	jr nc, .next_duel_anim

.skip
	pop bc
	pop hl
	ret


; gets data from Animations table for the anim ID in a
; preserves bc and de
; input:
;	[wTempAnimation] = animation ID (DUEL_ANIM_* constant)
; output:
;	hl = pointer to the animation data
GetAnimationData:
	push bc
	ld a, [wTempAnimation]
	ld l, a
	ld h, 0
	add hl, hl ; hl = anim * 2
	ld b, h
	ld c, l
	add hl, hl ; hl = anim * 4
	add hl, bc ; hl = anim * 6
	ld bc, Animations
	add hl, bc
	pop bc
	ret


_UpdateQueuedAnimations::
	ld a, [wActiveScreenAnim]
	cp $ff
	jr nz, .screen_anim
	ld a, [wd4c0]
	or a
	jr z, .asm_1cafb
	cp $80
	jr z, .asm_1cb11

; iterate through all animations, and
; if there is a sprite animation that has finished,
; then disable it and clear its slot in the queue.
	ld hl, wAnimationQueue
	ld c, ANIMATION_QUEUE_LENGTH
.loop_queue
	push af
	push bc
	ld a, [hl]
	cp $ff
	jr z, .next
	ld [wWhichSprite], a
	farcall GetSpriteAnimCounter
	cp $ff
	jr nz, .next
	farcall DisableCurSpriteAnim
	ld a, $ff
	ld [hl], a
.next
	pop bc
	pop af
	and [hl]
	inc hl
	dec c
	jr nz, .loop_queue
	; a is $ff if queue is empty

.asm_1cafb
	; if a is $ff, then play buffered animations
	cp $ff
	ret nz
	jp PlayBufferedDuelAnimations

.screen_anim
	ld hl, wScreenAnimUpdatePtr
	ld a, [hli]
	ld h, [hl]
	ld l, a
	call CallHL
	ld a, [wActiveScreenAnim]
	jr .asm_1cafb

.asm_1cb11
	ld a, $ff
	ld [wd4c0], a
	jr .asm_1cafb ; will play buffered animations


; preserves all registers except af
; output:
;	carry = set:  if wDoFrameFunction != UpdateQueuedAnimations
ClearAndDisableQueuedAnimations::
	push hl
	push bc
	push de

	; if UpdateQueuedAnimations is not set as
	; wDoFrameFunction, quit and set carry
	ld a, [wDoFrameFunction]
	cp LOW(UpdateQueuedAnimations)
	jr nz, .carry
	ld a, [wDoFrameFunction + 1]
	cp HIGH(UpdateQueuedAnimations)
	jr nz, .carry

	ld a, $ff
	ld [wd4c0], a
	ld a, [wActiveScreenAnim]
	cp $ff
	call nz, DoScreenAnimationUpdate

; clear all queued animations
; and disable their sprite anims
	ld hl, wAnimationQueue
	ld c, ANIMATION_QUEUE_LENGTH
.loop_queue
	push bc
	ld a, [hl]
	cp $ff
	jr z, .next_queued
	ld [wWhichSprite], a
	farcall DisableCurSpriteAnim
	ld a, $ff
	ld [hl], a
.next_queued
	pop bc
	inc hl
	dec c
	jr nz, .loop_queue

	xor a
	ld [wDuelAnimBufferCurPos], a
	ld [wDuelAnimBufferSize], a
.done
	pop de
	pop bc
	pop hl
	ret
.carry
	scf
	jr .done


; input:
;	a = DUEL_ANIM_* constant
Func_1ce03:
	cp DUEL_ANIM_158_UNUSED
	jr z, .asm_1ce17
	sub $96
	add a
	ld c, a
	ld b, $00
	ld hl, .pointer_table
	add hl, bc
	ld a, [hli]
	ld h, [hl]
	ld l, a
	jp Func_3bb5

.asm_1ce17
	ld hl, wDuelAnimDamage
	ld a, [hli]
	ld h, [hl]
	ld l, a
	jp Func_3bb5

.pointer_table
	dw SetScreenForDuelAnimation ; DUEL_ANIM_SET_SCREEN
	dw PrintDamageText           ; DUEL_ANIM_PRINT_DAMAGE
	dw UpdateMainSceneHUD        ; DUEL_ANIM_UPDATE_HUD
	dw DuelAnim153               ; DUEL_ANIM_153_UNUSED
	dw DuelAnim154               ; DUEL_ANIM_154_UNUSED
	dw DuelAnim155               ; DUEL_ANIM_155_UNUSED
	dw DuelAnim156               ; DUEL_ANIM_156_UNUSED
	dw DuelAnim157               ; DUEL_ANIM_157_UNUSED


; input:
;	a = DUEL_ANIM_* constant
Func_1cb5e:
	cp $96
	jr nc, Func_1ce03
	cp DUEL_ANIM_DAMAGE_HUD
	jp nz, InitScreenAnimation
.damage
	ld a, [wDuelAnimDamage + 1]
	cp HIGH(1000)
	jr nz, .return_on_overflow
	ld a, [wDuelAnimDamage]
	cp LOW(1000)
.return_on_overflow
	ret nc

	xor a
	ld [wDamageCharAnimDelay], a
	ld [wVRAMTileOffset], a
	ld [wd4cb], a

	ld a, PALETTE_37
	farcall LoadPaletteData

	call DrawDamageAnimationNumbers
	ld hl, wDuelAnimEffectiveness
	bit 0, [hl] ; weak
	call nz, DrawDamageAnimationWeak
	ld a, 18
	ld [wDamageCharAnimDelay], a
	bit 1, [hl] ; resistant
	call nz, DrawDamageAnimationResist
	bit 2, [hl]
	call nz, DrawDamageAnimationArrow

	xor a
	ld [wDuelAnimEffectiveness], a
	ret


; input:
;	[wDuelAnimDamage] = amount of damage to display
DrawDamageAnimationNumbers:
	call GetDamageNumberChars
	xor a
	ld [wDamageCharIndex], a
	ld hl, wDecimalChars
	ld de, wAnimationQueue + 1
.loop_num_chars
	push hl
	push de
	ld a, [hl]
	or a
	call nz, CreateDamageCharSprite
	pop de
	pop hl
	inc hl
	inc de
	ld a, [wDamageCharIndex]
	inc a
	ld [wDamageCharIndex], a
	cp 3
	jr c, .loop_num_chars
	ret


; creates a character sprite
; given index in wDamageCharIndex
; the relative x-positions for each index are:
;	index:  0   1   2   3   4   5
;	rel x: -16 -8   0   8  -8  -16
; indices 0, 1 and 2 are for number chars
; input:
;	a = sprite animation ID (SPRITE_ANIM_* constant)
CreateDamageCharSprite:
	push af
	ld a, SPRITE_DUEL_DAMAGE
	farcall CreateSpriteAndAnimBufferEntry
	ld a, [wWhichSprite]
	ld [de], a
	ld a, SPRITE_ANIM_FLAG_UNSKIPPABLE
	ld [wAnimFlags], a
	ld c, SPRITE_ANIM_COORD_X
	call GetSpriteAnimBufferProperty
	call GetAnimCoordsAndFlags

	ld a, [wDamageCharIndex]
	add LOW(.RelativeXPos)
	ld e, a
	ld a, HIGH(.RelativeXPos)
	adc 0
	ld d, a
	ld a, [de]
	add b
	ld [hli], a ; SPRITE_ANIM_COORD_X
	ld [hl], c ; SPRITE_ANIM_COORD_Y
	ld a, [wDamageCharAnimDelay]
	ld c, a
	pop af
	farcall Func_12ac9
	ret

.RelativeXPos:
	db -16, -8, 0, 8, -8, -16


; input:
;	[wDuelAnimDamage] = number to convert to graphic tiles
GetDamageNumberChars:
	ld hl, wDuelAnimDamage
	ld a, [hli]
	ld h, [hl]
	ld l, a

	ld de, wDecimalChars
	ld bc, -100
	call .ConvertDigitToCharTile
	ld bc, -10
	call .ConvertDigitToCharTile
	ld a, l
	add SPRITE_ANIM_79
	ld [de], a

	; remove left padding zeroes
	ld hl, wDecimalChars
	ld c, 2
.loop_check_zeroes
	ld a, [hl]
	cp SPRITE_ANIM_79 ; 0 char
	ret nz
	ld [hl], $00
	inc hl
	dec c
	jr nz, .loop_check_zeroes
	ret

.ConvertDigitToCharTile
	ld a, SPRITE_ANIM_79 - 1
	jp GetTxSymbolDigit.subtract_loop


; preserves hl
DrawDamageAnimationWeak:
	push hl
	ld a, 3
	ld [wDamageCharIndex], a
	ld de, wAnimationQueue + 4
	ld a, SPRITE_ANIM_91
	call CreateDamageCharSprite
	pop hl
	ret


; preserves hl
DrawDamageAnimationResist:
	push hl
	ld a, 4
	ld [wDamageCharIndex], a
	ld de, wAnimationQueue + 5
	ld a, SPRITE_ANIM_90
	call CreateDamageCharSprite
	ld a, [wDamageCharAnimDelay]
	add 18
	ld [wDamageCharAnimDelay], a
	pop hl
	ret


; preserves hl
DrawDamageAnimationArrow:
	push hl
	ld a, 5
	ld [wDamageCharIndex], a
	ld de, wAnimationQueue + 6
	ld a, SPRITE_ANIM_89
	call CreateDamageCharSprite
	pop hl
	ret
