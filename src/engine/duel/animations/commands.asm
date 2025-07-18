; reads the animation commands from PointerTable_AttackAnimation
; of attack in wLoadedAttackAnimation and plays them
; input:
;	[wLoadedAttackAnimation] = which attack animation to play (ATK_ANIM_* constant)
PlayAttackAnimationCommands::
	ld a, [wLoadedAttackAnimation]
	or a
	ret z

	ld l, a
	ld h, 0
	add hl, hl
	ld de, PointerTable_AttackAnimation
	add hl, de
	ld e, [hl]
	inc hl
	ld d, [hl]

	push de
	ld hl, wAttackAnimationIsPlaying
	ld a, [hl]
	or a
	jr nz, .read_command
	ld [hl], TRUE ; wAttackAnimationIsPlaying
	call ResetAnimationQueue
	pop de
	push de
	ld a, DUEL_ANIM_SCREEN_MAIN_SCENE
	ld [wDuelAnimationScreen], a
	ld a, SET_ANIM_SCREEN_MAIN
	ld [wDuelAnimSetScreen], a
	xor a
	ld [wDuelAnimLocationParam], a
	ld a, [de]
	cp ANIMCMD_SET_SCREEN
	jr z, .read_command
	ld a, DUEL_ANIM_SET_SCREEN
	call PlayDuelAnimation
.read_command
	pop de
;	fallthrough

; input:
;	de = AttackAnimation_* (from PointerTable_AttackAnimation)
PlayAttackAnimationCommands_NextCommand:
	ld a, [de]
	inc de
	ld hl, AnimationCommandPointerTable
	jp JumpToFunctionInTable

AnimationCommandPointerTable:
	table_width 2, AnimationCommandPointerTable
	dw AnimationCommand_AnimEnd      ; ANIMCMD_END
	dw AnimationCommand_AnimNormal   ; ANIMCMD_NORMAL
	dw AnimationCommand_AnimPlayer   ; ANIMCMD_PLAYER_SIDE
	dw AnimationCommand_AnimOpponent ; ANIMCMD_OPP_SIDE
	dw AnimationCommand_AnimScreen   ; ANIMCMD_SET_SCREEN
	dw AnimationCommand_AnimPlayArea ; ANIMCMD_PLAY_AREA
	dw AnimationCommand_AnimEnd2     ; ANIMCMD_END_UNUSED
	assert_table_length NUM_ANIM_COMMANDS


AnimationCommand_AnimEnd:
	ret


; input:
;	de = AttackAnimation_* (from PointerTable_AttackAnimation)
AnimationCommand_AnimPlayer:
	ldh a, [hWhoseTurn]
	ld [wDuelAnimDuelistSide], a
	ld a, [wDuelType]
	cp $00
	jr nz, AnimationCommand_AnimNormal
	ld a, PLAYER_TURN
	ld [wDuelAnimDuelistSide], a
	jr AnimationCommand_AnimNormal


; input:
;	de = AttackAnimation_* (from PointerTable_AttackAnimation)
AnimationCommand_AnimOpponent:
	rst SwapTurn
	ldh a, [hWhoseTurn]
	ld [wDuelAnimDuelistSide], a
	rst SwapTurn
	ld a, [wDuelType]
	cp $00
	jr nz, AnimationCommand_AnimNormal
	ld a, OPPONENT_TURN
	ld [wDuelAnimDuelistSide], a
	jr AnimationCommand_AnimNormal


; input:
;	de = AttackAnimation_* (from PointerTable_AttackAnimation)
AnimationCommand_AnimPlayArea:
	ld a, [wDamageAnimPlayAreaLocation]
	and $7f
	ld [wDuelAnimLocationParam], a
;	fallthrough

; input:
;	de = AttackAnimation_* (from PointerTable_AttackAnimation)
AnimationCommand_AnimNormal:
	ld a, [de]
	inc de
	cp DUEL_ANIM_SHOW_DAMAGE
	jr z, .show_damage
	cp DUEL_ANIM_SHAKE1
	jr z, .shake_1
	cp DUEL_ANIM_SHAKE2
	jr z, .shake_2
	cp DUEL_ANIM_SHAKE3
	jr z, .shake_3

.play_anim
	call PlayDuelAnimation
	jr PlayAttackAnimationCommands_NextCommand

.show_damage
	ld a, DUEL_ANIM_PRINT_DAMAGE
	call PlayDuelAnimation
	ld a, [wDamageAnimEffectiveness]
	ld [wDuelAnimEffectiveness], a

	push de
	ld hl, wDamageAnimAmount
	ld de, wDuelAnimDamage
	ld a, [hli]
	ld [de], a
	inc de
	ld a, [hli]
	ld [de], a
	pop de

	ld a, DUEL_ANIM_DAMAGE_HUD
	call PlayDuelAnimation
	ld a, [wDuelDisplayedScreen]
	cp DUEL_MAIN_SCENE
	jr nz, .skip_update_hud
	ld a, DUEL_ANIM_UPDATE_HUD
	call PlayDuelAnimation
.skip_update_hud
	jp PlayAttackAnimationCommands_NextCommand

; screen shake happens differently
; depending on whose turn it is
.shake_1
	lb bc, DUEL_ANIM_SMALL_SHAKE_Y, DUEL_ANIM_SMALL_SHAKE_X
	jr .check_duelist

.shake_2
	lb bc, DUEL_ANIM_BIG_SHAKE_Y, DUEL_ANIM_BIG_SHAKE_X
	jr .check_duelist

.shake_3
	lb bc, DUEL_ANIM_SMALL_SHAKE_X, DUEL_ANIM_SMALL_SHAKE_Y
;	fallthrough

.check_duelist
	ldh a, [hWhoseTurn]
	cp PLAYER_TURN
	ld a, c
	jr z, .play_anim
	ld a, [wDuelType]
	cp $00
	ld a, c
	jr z, .play_anim
	ld a, b
	jr .play_anim


; input:
;	de = AttackAnimation_* (from PointerTable_AttackAnimation)
AnimationCommand_AnimScreen:
	ld a, [de]
	inc de
	ld [wDuelAnimSetScreen], a
	ld a, [wDamageAnimPlayAreaLocation]
	ld [wDuelAnimLocationParam], a
	call UpdateDuelAnimationScreen
	ld a, DUEL_ANIM_SET_SCREEN
	call PlayDuelAnimation
	jp PlayAttackAnimationCommands_NextCommand


AnimationCommand_AnimEnd2:
	ret


; sets wDuelAnimationScreen according to wDuelAnimSetScreen
; preserves bc and de
; input:
;	[wDuelAnimSetScreen] = SET_ANIM_SCREEN_MAIN:      use DUEL_ANIM_SCREEN_MAIN_SCENE
;	[wDuelAnimSetScreen] = SET_ANIM_SCREEN_PLAY_AREA: use DUEL_ANIM_SCREEN_PLAYER_PLAY_AREA
;	                                                   or DUEL_ANIM_SCREEN_OPP_PLAY_AREA
UpdateDuelAnimationScreen:
	ld a, [wDuelAnimSetScreen]
	cp SET_ANIM_SCREEN_PLAY_AREA
	jr z, .set_play_area_screen
	cp SET_ANIM_SCREEN_MAIN
	ret nz
	ld a, DUEL_ANIM_SCREEN_MAIN_SCENE
	ld [wDuelAnimationScreen], a
	ret

.set_play_area_screen
	ld a, [wDuelAnimLocationParam]
	ld l, a
	ld a, [wWhoseTurn]
	ld h, a
	cp PLAYER_TURN
	jr z, .players_turn

; opponent's turn
	ld a, [wDuelType]
	cp $00
	jr z, .asm_50c6
; link duel or vs. AI
	bit 7, l
	jr z, .asm_50e2
	jr .asm_50d2
.asm_50c6
	bit 7, l
	jr z, .asm_50da
	jr .asm_50ea

.players_turn
	bit 7, l
	jr z, .asm_50d2
	jr .asm_50e2

.asm_50d2
	lb hl, PLAYER_TURN, UNKNOWN_SCREEN_4
	ld a, DUEL_ANIM_SCREEN_PLAYER_PLAY_AREA
	jr .ok
.asm_50da
	lb hl, OPPONENT_TURN, UNKNOWN_SCREEN_4
	ld a, DUEL_ANIM_SCREEN_PLAYER_PLAY_AREA
	jr .ok
.asm_50e2
	lb hl, OPPONENT_TURN, UNKNOWN_SCREEN_5
	ld a, DUEL_ANIM_SCREEN_OPP_PLAY_AREA
	jr .ok
.asm_50ea
	lb hl, PLAYER_TURN, UNKNOWN_SCREEN_5
	ld a, DUEL_ANIM_SCREEN_OPP_PLAY_AREA
;	fallthrough

.ok
	ld [wDuelAnimationScreen], a
	ret


SetScreenForDuelAnimation:
	ld a, [wDuelAnimSetScreen]
	cp SET_ANIM_SCREEN_PLAY_AREA
	jr z, .set_play_area_screen
	cp SET_ANIM_SCREEN_MAIN
	ret nz
; set duel main screen
	ld a, DUEL_ANIM_SCREEN_MAIN_SCENE
	ld [wDuelAnimationScreen], a
	ld a, [wDuelDisplayedScreen]
	cp DUEL_MAIN_SCENE
	ret z
	bank1call DrawDuelMainScene
	ret

.set_play_area_screen
	call UpdateDuelAnimationScreen
	ld a, [wDuelDisplayedScreen]
	cp l
	jp z, DrawWideTextBox ; skip change screen
	ld a, l
	push af
	ld l, PLAYER_TURN
	ld a, [wDuelType]
	cp $00
	jr nz, .asm_5127
	ld a, [wWhoseTurn]
	ld l, a
.asm_5127
	call DrawYourOrOppPlayAreaScreen_Bank0
	pop af
	ld [wDuelDisplayedScreen], a
	jp DrawWideTextBox


; prints text related to the damage received by Pokemon with card ID in wTempNonTurnDuelistCardID.
; takes into account type effectiveness
; preserves all registers except af
; input:
;	[wTempNonTurnDuelistCardID] = card ID of the Pokemon causing the damage
PrintDamageText:
	push hl
	push bc
	push de
	ld a, [wLoadedAttackAnimation]
	cp ATK_ANIM_HEAL
	jr z, .skip
	cp ATK_ANIM_HEALING_WIND_PLAY_AREA
	jr z, .skip

	ld a, [wTempNonTurnDuelistCardID]
	ld e, a
	ld d, $00
	call LoadCardDataToBuffer1_FromCardID
	ld a, 18
	call CopyCardNameAndLevel
	xor a ; TX_END
	ld [hl], a ; terminate the text string at wDefaultText
	; zero wTxRam2 so that the name & level text just loaded to wDefaultText is printed
	ld hl, wTxRam2
	ld [hli], a
	ld [hl], a
	ld hl, wDamageAnimAmount
	ld a, [hli]
	ld h, [hl]
	ld l, a
	call GetDamageText
	ld a, l
	or h
	call nz, DrawWideTextBox_PrintText
.skip
	pop de
	pop bc
	pop hl
	ret


; preserves bc
; input:
;	hl = amount of damage
; output:
;	hl = text id associated with the damage in hl and its effectiveness
GetDamageText:
	ld a, l
	or h
	jr z, .no_damage
	call LoadTxRam3
	ld a, [wDamageAnimEffectiveness]
	ldtx hl, AttackDamageText
	and (1 << RESISTANCE) | (1 << WEAKNESS)
	ret z ; not weak or resistant
	ldtx hl, WeaknessMoreDamageText
	cp (1 << RESISTANCE) | (1 << WEAKNESS)
	ret z ; weak and resistant
	and (1 << WEAKNESS)
	ldtx hl, WeaknessMoreDamageText
	ret nz ; weak
	ldtx hl, ResistanceLessDamageText
	ret ; resistant

.no_damage
	call CheckNoDamageOrEffect
	ret c
	ldtx hl, NoDamageText
	ld a, [wDamageAnimEffectiveness]
	and (1 << RESISTANCE)
	ret z ; not resistant
	ldtx hl, ResistanceNoDamageText
	ret ; resistant


UpdateMainSceneHUD:
	ld a, [wDuelDisplayedScreen]
	cp DUEL_MAIN_SCENE
	ret nz
	bank1call DrawDuelHUDs
DuelAnim153:
DuelAnim154:
DuelAnim155:
DuelAnim156:
DuelAnim157:
	ret


INCLUDE "data/duel/animations/attack_animations.asm"
