; disables all sprite animations and clears memory related to sprites
; preserves all registers except af
EnableAndClearSpriteAnimations::
	xor a
	ld [wAllSpriteAnimationsDisabled], a
;	fallthrough

; tries to disable all sprite animations and clear memory related to sprites
; preserves all registers except af
; input:
;	[wAllSpriteAnimationsDisabled] = 0:  clear all sprite animations
;	[wAllSpriteAnimationsDisabled] > 0:  return before clearing any sprite animations
ClearSpriteAnimations::
	ldh a, [hBankROM]
	push af
	ld a, BANK(_ClearSpriteAnimations)
	rst BankswitchROM
	call _ClearSpriteAnimations
	pop af
	jp BankswitchROM


; preserves all registers except af
HandleAllSpriteAnimations::
	ldh a, [hBankROM]
	push af
	ld a, BANK(_HandleAllSpriteAnimations)
	rst BankswitchROM
	call _HandleAllSpriteAnimations
	pop af
	jp BankswitchROM


; input:
;	hl = pointer to animation frame
;	[wCurrSpriteFrameBank] = bank of animation frame
DrawSpriteAnimationFrame::
	ldh a, [hBankROM]
	push af
	ld a, [wCurrSpriteFrameBank]
	rst BankswitchROM
	ld a, [wCurrSpriteXPos]
	cp $f0
	ld a, 0
	jr c, .notNearRight
	dec a
.notNearRight
	ld [wCurrSpriteRightEdgeCheck], a
	ld a, [wCurrSpriteYPos]
	cp $f0
	ld a, 0
	jr c, .setBottomEdgeCheck
	dec a
.setBottomEdgeCheck
	ld [wCurrSpriteBottomEdgeCheck], a
	ld a, [hli]
	or a
	jp z, .done
	ld c, a
.loop
	push bc
	push hl
	ld b, 0
	bit 7, [hl]
	jr z, .beginY
	dec b
.beginY
	ld a, [wCurrSpriteAttributes]
	bit B_OAM_YFLIP, a
	jr z, .unflippedY
	ld a, [hl]
	add 8 ; size of a tile
	ld c, a
	ld a, 0
	adc b
	ld b, a
	ld a, [wCurrSpriteYPos]
	sub c
	ld e, a
	ld a, [wCurrSpriteBottomEdgeCheck]
	sbc b
	jr .finishYPosition
.unflippedY
	ld a, [wCurrSpriteYPos]
	add [hl]
	ld e, a
	ld a, [wCurrSpriteBottomEdgeCheck]
	adc b
.finishYPosition
	or a
	jr nz, .endCurrentIteration
	inc hl
	ld b, 0
	bit 7, [hl]
	jr z, .beginX
	dec b
.beginX
	ld a, [wCurrSpriteAttributes]
	bit B_OAM_XFLIP, a
	jr z, .unflippedX
	ld a, [hl]
	add 8 ; size of a tile
	ld c, a
	ld a, 0
	adc b
	ld b, a
	ld a, [wCurrSpriteXPos]
	sub c
	ld d, a
	ld a, [wCurrSpriteRightEdgeCheck]
	sbc b
	jr .finishXPosition
.unflippedX
	ld a, [wCurrSpriteXPos]
	add [hl]
	ld d, a
	ld a, [wCurrSpriteRightEdgeCheck]
	adc b
.finishXPosition
	or a
	jr nz, .endCurrentIteration
	inc hl
	ld a, [wCurrSpriteTileID]
	add [hl]
	ld c, a
	inc hl
	ld a, [wCurrSpriteAttributes]
	add [hl]
	and OAM_PALETTE | OAM_PAL1
	ld b, a
	ld a, [wCurrSpriteAttributes]
	xor [hl]
	and OAM_XFLIP | OAM_YFLIP | OAM_PRIO
	or b
	ld b, a
	call SetOneObjectAttributes
.endCurrentIteration
	pop hl
	ld bc, 4 ; size of info for one sub tile
	add hl, bc
	pop bc
	dec c
	jr nz, .loop
.done
	pop af
	jp BankswitchROM


; Loads a pointer to the current animation frame into
; SPRITE_ANIM_FRAME_DATA_POINTER using the current frame's offset
; preserves hl
; input:
;	[wd4ca] = current frame offset
;	[wTempPointer] = pointer to current animation
GetAnimationFramePointer::
	ldh a, [hBankROM]
	push af
	push hl
	push hl
	ld a, [wd4ca]
	inc a
	jr nz, .useLoadedOffset
	ld de, SpriteNullAnimationPointer
	jr .loadPointer
.useLoadedOffset
	ld hl, wTempPointer
	ld a, [hli]
	ld h, [hl]
	ld l, a
	ld a, [wTempPointerBank]
	rst BankswitchROM
	ld a, [hli]

	push af
	ld a, [wd4ca]
	rlca
	ld e, [hl]
	add e
	ld e, a
	inc hl
	ld a, [hl]
	adc 0
	ld d, a
	pop af

.loadPointer
	add BANK(SpriteNullAnimationPointer)
	pop hl
	ld bc, SPRITE_ANIM_FRAME_BANK
	add hl, bc
	ld [hli], a
	rst BankswitchROM
	ld a, [de]
	ld [hli], a
	inc de
	ld a, [de]
	ld [hl], a
	pop hl
	pop af
	jp BankswitchROM


; preserves bc and de
; input:
;	[wWhichSprite] = sprite ID (SPRITE_* constant)
; output:
;	hl = pointing to the start of the sprite from input in wSpriteAnimBuffer
GetFirstSpriteAnimBufferProperty::
	push bc
	ld c, SPRITE_ANIM_ENABLED
	call GetSpriteAnimBufferProperty
	pop bc
	ret


; preserves bc and de
; input:
;	[wWhichSprite] = sprite ID (SPRITE_* constant)
;	c = property to apply (SPRITE_ANIM_* constant)
; output:
;	hl = pointing to the start of the sprite from input in wSpriteAnimBuffer
GetSpriteAnimBufferProperty::
	ld a, [wWhichSprite]
;	fallthrough

; preserves bc and de
; input:
;	a = sprite ID (SPRITE_* constant)
;	c = property to apply (SPRITE_ANIM_* constant)
; output:
;	hl = pointing to the start of the sprite from input in wSpriteAnimBuffer
GetSpriteAnimBufferProperty_SpriteInA::
	cp SPRITE_ANIM_BUFFER_CAPACITY
	jr c, .got_sprite
	ld a, SPRITE_ANIM_BUFFER_CAPACITY - 1 ; default to last sprite
.got_sprite
	push bc
	swap a ; a *= SPRITE_ANIM_LENGTH
	push af
	and $f
	ld b, a
	pop af
	and $f0
	or c ; add the property offset
	ld c, a
	ld hl, wSpriteAnimBuffer
	add hl, bc
	pop bc
	ret


; preserves all registers except af
; input:
;	a = scene ID (SCENE_* constant)
;	b = base X position of scene in tiles (usually 0)
;	c = base Y position of scene in tiles (usually 0)
LoadScene::
	push af
	ldh a, [hBankROM]
	push af
	push hl
	ld a, BANK(_LoadScene)
	rst BankswitchROM
	ld hl, sp+$5
	ld a, [hl]
	call _LoadScene
	call FlushAllPalettes
	pop hl
	pop af
	rst BankswitchROM
	pop af
	ld a, [wSceneSpriteIndex]
	ret


; draws the player's portrait at b,c
; preserves bc and de
; input:
;	bc = coordinates at which to begin drawing the portrait
DrawPlayerPortrait::
	ld a, EVENT_PLAYER_GENDER
	farcall GetEventValue
	or a
	ld a, PLAYER_PIC
	jr z, .got_pic
	ld a, MINT_PIC
.got_pic
	ld [wCurPortrait], a
	ld a, TILEMAP_PLAYER
;	fallthrough

; input:
;	a = tilemap ID (TILEMAP_* constant)
;	[wCurPortrait] = portrait ID to draw (*_PIC constant)
DrawPortrait::
	ld [wCurTilemap], a
	ldh a, [hBankROM]
	push af
	ld a, BANK(_DrawPortrait)
	rst BankswitchROM
	call _DrawPortrait
	pop af
	jp BankswitchROM

; draws the opponent's portrait given in a at b,c
; preserves bc and de
; input:
;	a = portrait ID to draw (*_PIC constant), usually stored in wOpponentPortrait
;	bc = coordinates at which to begin drawing the portrait
DrawOpponentPortrait::
	ld [wCurPortrait], a
	ld a, TILEMAP_OPPONENT
	jr DrawPortrait


; preserves de and hl
Func_3e31::
	ldh a, [hBankROM]
	push af
	call HandleAllSpriteAnimations
	ld a, BANK(DoLoadedFramesetSubgroupsFrame)
	rst BankswitchROM
	call DoLoadedFramesetSubgroupsFrame
	pop af
	jp BankswitchROM


;----------------------------------------
;        UNREFERENCED FUNCTIONS
;----------------------------------------
;
;Func_3ddb::
;	push hl
;	push bc
;	ld c, SPRITE_ANIM_FLAGS
;	call GetSpriteAnimBufferProperty_SpriteInA
;	res SPRITE_ANIM_FLAG_CENTERED_F, [hl]
;	pop bc
;	pop hl
;	ret
;
;
;Func_3de7::
;	push hl
;	push bc
;	ld c, SPRITE_ANIM_FLAGS
;	call GetSpriteAnimBufferProperty_SpriteInA
;	set SPRITE_ANIM_FLAG_CENTERED_F, [hl]
;	pop bc
;	pop hl
;	ret
