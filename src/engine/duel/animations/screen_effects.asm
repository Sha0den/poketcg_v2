; initializes a screen animation from wTempAnimation
; loads a function pointer for updating a frame
; and initializes the duration of the animation.
InitScreenAnimation:
	ld a, [wAnimationsDisabled]
	or a
	ret nz
	ld a, [wTempAnimation]
	ld [wActiveScreenAnim], a
	sub DUEL_SCREEN_ANIMS
	add a
	add a
	ld c, a
	ld b, $00
	ld hl, ScreenAnimationFunctions
	add hl, bc
	ld a, [hli]
	ld [wScreenAnimUpdatePtr], a
	ld c, a
	ld a, [hli]
	ld [wScreenAnimUpdatePtr + 1], a
	ld b, a
	ld a, [hl]
	ld [wScreenAnimDuration], a
	call CallBC
	ret


; for the following animations, these functions are run with the corresponding duration.
; this duration decides different effects, depending on which function runs
; and is decreased by one each time. when it is down to 0, the animation is done.

MACRO screen_effect
	dw \1 ; function pointer
	db \2 ; duration
	db $00 ; padding
ENDM


ScreenAnimationFunctions:
; function pointer, duration
	screen_effect ShakeScreenX_Small, 24 ; DUEL_ANIM_SMALL_SHAKE_X
	screen_effect ShakeScreenX_Big,   32 ; DUEL_ANIM_BIG_SHAKE_X
	screen_effect ShakeScreenY_Small, 24 ; DUEL_ANIM_SMALL_SHAKE_Y
	screen_effect ShakeScreenY_Big,   32 ; DUEL_ANIM_BIG_SHAKE_Y
	screen_effect WhiteFlashScreen,    8 ; DUEL_ANIM_FLASH
	screen_effect DistortScreen,      63 ; DUEL_ANIM_DISTORT


; checks if screen animation duration is over
; and if so, loads the default update function
; preserves bc and de
LoadDefaultScreenAnimationUpdateWhenFinished:
	ld a, [wScreenAnimDuration]
	or a
	ret nz
;	fallthrough

; function called for the screen animation update when it is over
; preserves bc and de
DefaultScreenAnimationUpdate:
	ld a, $ff
	ld [wActiveScreenAnim], a
	call DisableInt_LYCoincidence
	xor a
	ldh [hSCX], a
	ldh [rSCX], a
	ldh [hSCY], a
	ld hl, wScreenAnimUpdatePtr
	ld [hl], LOW(DefaultScreenAnimationUpdate)
	inc hl
	ld [hl], HIGH(DefaultScreenAnimationUpdate)
	ret


; runs the screen update function set in wScreenAnimUpdatePtr
DoScreenAnimationUpdate:
	ld a, 1
	ld [wScreenAnimDuration], a
	ld hl, wScreenAnimUpdatePtr
	ld a, [hli]
	ld h, [hl]
	ld l, a
	call CallHL
	jr DefaultScreenAnimationUpdate


; preserves bc and de
ShakeScreenX_Small:
	ld hl, SmallShakeOffsets
	jr ShakeScreenX

; preserves bc and de
ShakeScreenX_Big:
	ld hl, BigShakeOffsets
;	fallthrough

; input:
;	hl = timer and offset data
ShakeScreenX:
	ld a, l
	ld [wScreenShakeOffsetsPtr], a
	ld a, h
	ld [wScreenShakeOffsetsPtr + 1], a
	ld hl, wScreenAnimUpdatePtr
	ld [hl], LOW(.UpdateFunc)
	inc hl
	ld [hl], HIGH(.UpdateFunc)
	ret

.UpdateFunc
	ld hl, wScreenAnimDuration
	dec [hl]
	call UpdateShakeOffset
	jr nc, LoadDefaultScreenAnimationUpdateWhenFinished
	ldh a, [hSCX]
	add [hl]
	ldh [hSCX], a
	jr LoadDefaultScreenAnimationUpdateWhenFinished


; preserves bc and de
ShakeScreenY_Small:
	ld hl, SmallShakeOffsets
	jr ShakeScreenY

; preserves bc and de
ShakeScreenY_Big:
	ld hl, BigShakeOffsets
;	fallthrough

; input:
;	hl = timer and offset data
ShakeScreenY:
	ld a, l
	ld [wScreenShakeOffsetsPtr], a
	ld a, h
	ld [wScreenShakeOffsetsPtr + 1], a
	ld hl, wScreenAnimUpdatePtr
	ld [hl], LOW(.UpdateFunc)
	inc hl
	ld [hl], HIGH(.UpdateFunc)
	ret

.UpdateFunc
	ld hl, wScreenAnimDuration
	dec [hl]
	call UpdateShakeOffset
	jr nc, LoadDefaultScreenAnimationUpdateWhenFinished
	ldh a, [hSCY]
	add [hl]
	ldh [hSCY], a
	jr LoadDefaultScreenAnimationUpdateWhenFinished


; gets the displacement of the current frame depending on the value of wScreenAnimDuration
; preserves bc and de
; output:
;	carry = set:  if the displacement was updated
UpdateShakeOffset:
	ld hl, wScreenShakeOffsetsPtr
	ld a, [hli]
	ld h, [hl]
	ld l, a
	ld a, [wScreenAnimDuration]
	cp [hl]
	ret nc
	inc hl
	push hl
	inc hl
	ld a, l
	ld [wScreenShakeOffsetsPtr], a
	ld a, h
	ld [wScreenShakeOffsetsPtr + 1], a
	pop hl
	scf
	ret


SmallShakeOffsets:
; timer, offset
	db 21,  2
	db 17, -2
	db 13,  2
	db  9, -2
	db  5,  1
	db  1, -1


BigShakeOffsets:
; timer, offset
	db 29,  4
	db 25, -4
	db 21,  4
	db 17, -4
	db 13,  3
	db  9, -3
	db  5,  2
	db  1, -2


WhiteFlashScreen:
	ld hl, wScreenAnimUpdatePtr
	ld [hl], LOW(.UpdateFunc)
	inc hl
	ld [hl], HIGH(.UpdateFunc)
	ld a, [wBGP]
	ld [wTempWhiteFlashBGP], a
	; backup the current background palettes
	ld hl, wBackgroundPalettesCGB
	ld de, wTempBackgroundPalettesCGB
	ld b, 8 palettes
	call CopyNBytesFromHLToDE
	ld de, PALRGB_WHITE
	ld hl, wBackgroundPalettesCGB
	ld bc, (8 palettes) / 2
	call FillMemoryWithDE
	xor a ; all white
	call SetBGP
	call FlushAllPalettes

.UpdateFunc
	ld hl, wScreenAnimDuration
	dec [hl]
	ld a, [wScreenAnimDuration]
	or a
	ret nz
	; retrieve the previous background palettes
	ld hl, wTempBackgroundPalettesCGB
	ld de, wBackgroundPalettesCGB
	ld bc, 8 palettes
	call CopyDataHLtoDE_SaveRegisters
	ld a, [wTempWhiteFlashBGP]
	call SetBGP
	call FlushAllPalettes
	jp DefaultScreenAnimationUpdate


; preserves de
DistortScreen:
	ld hl, wScreenAnimUpdatePtr
	ld [hl], LOW(.UpdateFunc)
	inc hl
	ld [hl], HIGH(.UpdateFunc)
	xor a
	ld [wApplyBGScroll], a
	ld hl, wLCDCFunctionTrampoline + 1
	ld [hl], LOW(ApplyBackgroundScroll)
	inc hl
	ld [hl], HIGH(ApplyBackgroundScroll)
	ld a, 1
	ld [wBGScrollMod], a
	call EnableInt_LYCoincidence

.UpdateFunc
	ld a, [wScreenAnimDuration]
	srl a
	srl a
	srl a
	and %00000111
	ld c, a
	ld b, $00
	ld hl, .BGScrollModData
	add hl, bc
	ld a, [hl]
	ld [wBGScrollMod], a
	ld hl, wScreenAnimDuration
	dec [hl]
	jp LoadDefaultScreenAnimationUpdateWhenFinished

; each value is applied for 8 "ticks" of wScreenAnimDuration
; starting from the last and running backwards
.BGScrollModData:
	db 4, 3, 2, 1, 1, 1, 1, 2
