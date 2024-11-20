; preserves all registers except af
; input:
;	[wTempNPC] = ID of the NPC to set (NPC_* constant)
SetNextNPCAndScript:
	push bc
	call FindLoadedNPC
;	ld a, [wLoadedNPCTempIndex] ; unnecessary?
	ld [wScriptNPC], a
	farcall SetNewScriptNPC
	pop bc
;	fallthrough

; preserves all registers except af
SetNextScript:
	push hl
	ld hl, wNextScript
	ld [hl], c
	inc hl
	ld [hl], b
	ld a, OWMODE_SCRIPT
	ld [wOverworldMode], a
	pop hl
	ret


; preserves all registers except af
Func_c943:
	push hl
	push bc
	push de
	ld l, MAP_SCRIPT_NPCS
	call GetMapScriptPointer
	jr nc, .quit
.load_npc_loop
	ld a, l
	ld [wTempPointer], a
	ld a, h
	ld [wTempPointer + 1], a
	ld a, BANK(MapScripts)
	ld [wTempPointerBank], a
	ld de, wTempNPC
	ld bc, NPC_MAP_SIZE
	call CopyBankedDataToDE
	ld a, [wTempNPC]
	or a
	jr z, .quit
	push hl
	ld hl, wLoadNPCFunction
	ld a, [hli]
	ld h, [hl]
	ld l, a
	or h
	jr z, .no_script
	call CallHL
	jr nc, .next_npc
.no_script
	ld a, [wTempNPC]
	farcall LoadNPCSpriteData
	call Func_c998
	farcall LoadNPC
.next_npc
	pop hl
	ld bc, NPC_MAP_SIZE
	add hl, bc
	jr .load_npc_loop
.quit
	ld l, MAP_SCRIPT_POST_NPC
	call CallMapScriptPointerIfExists
	pop de
	pop bc
	pop hl
	ret


; preserves de and hl
; input:
;	[wTempNPC] = ID of the NPC to animate (NPC_* constant)
Func_c998:
	ld a, [wTempNPC]
	cp NPC_AMY
	ret nz
	ld a, [wd3d0]
	or a
	ret z
	ld b, $4
	ld a, [wConsole]
	cp CONSOLE_CGB
	jr nz, .not_cgb
	ld b, $e
.not_cgb
	ld a, b
	ld [wNPCAnim], a
	ld a, $0
	ld [wNPCAnimFlags], a
	ret


Func_c9b8:
	ld l, MAP_SCRIPT_LOAD_MAP
	jr CallMapScriptPointerIfExists

Func_c9bc:
	ld l, MAP_SCRIPT_AFTER_DUEL
	jr CallMapScriptPointerIfExists

Func_c9c0:
	ld l, MAP_SCRIPT_MOVED_PLAYER
;	fallthrough

CallMapScriptPointerIfExists::
	call GetMapScriptPointer
	ret nc
	jp hl

Func_c9c7:
	ld l, MAP_SCRIPT_CLOSE_TEXTBOX
	jr CallMapScriptPointerIfExists


; preserves all registers except af
ClearEvents:
	push hl
	push bc
	ld hl, wEventVars
	ld b, EVENT_VAR_BYTES
	xor a
.loop
	ld [hli], a
	dec b
	jr nz, .loop
	pop bc
	pop hl
	ret


; clears temporary event variables before determining which room Imakuni is in
; preserves de
DetermineImakuniAndChallengeHall:
	xor a
	ld [wEventVars + EVENT_VAR_BYTES - 1], a
	call DetermineImakuniRoom
;	fallthrough

; preserves de and hl
DetermineChallengeHallEvent:
	ld a, [wOverworldMapSelection]
	cp OWMAP_CHALLENGE_HALL
	ret z
	get_event_value EVENT_RECEIVED_LEGENDARY_CARDS
	or a
	jr nz, .challenge_cup_three
; challenge cup two
	get_event_value EVENT_CHALLENGE_CUP_2_STATE
	cp CHALLENGE_CUP_OVER
	ret z
	or a ; cp CHALLENGE_CUP_NOT_STARTED
	jr z, .challenge_cup_one
	cp CHALLENGE_CUP_WON
	jr z, .close_challenge_cup_one
	ld c, CHALLENGE_CUP_READY_TO_START
	set_event_value EVENT_CHALLENGE_CUP_2_STATE
	jr .close_challenge_cup_one
.challenge_cup_one
	get_event_value EVENT_CHALLENGE_CUP_1_STATE
	cp CHALLENGE_CUP_OVER
	ret z
	or a ; cp CHALLENGE_CUP_NOT_STARTED
	ret z
	cp CHALLENGE_CUP_WON
	ret z
	ld c, CHALLENGE_CUP_READY_TO_START
	set_event_value EVENT_CHALLENGE_CUP_1_STATE
	ret
.challenge_cup_three
	call UpdateRNGSources
	ld c, CHALLENGE_CUP_READY_TO_START
	and %11
	or a
	jr z, .start_challenge_cup_three
	ld c, CHALLENGE_CUP_NOT_STARTED
.start_challenge_cup_three
	set_event_value EVENT_CHALLENGE_CUP_3_STATE
; close challenge cup two
	ld c, CHALLENGE_CUP_OVER
	set_event_value EVENT_CHALLENGE_CUP_2_STATE
.close_challenge_cup_one
	ld c, CHALLENGE_CUP_OVER
	set_event_value EVENT_CHALLENGE_CUP_1_STATE
	ret


; determines what room Imakuni is in when you reset.
; skips current room and does not occur if you haven't talked to Imakuni.
; preserves de
DetermineImakuniRoom:
	ld c, IMAKUNI_FIGHTING_CLUB
	get_event_value EVENT_IMAKUNI_STATE
	cp IMAKUNI_TALKED
	jr c, .skip
.loop
	call UpdateRNGSources
	and %11
	ld c, a
	ld b, 0
	ld hl, ImakuniPossibleRooms
	add hl, bc
	ld a, [wTempMap]
	cp [hl]
	jr z, .loop
.skip
	ld a, c
	set_event_value EVENT_IMAKUNI_ROOM
	ret

ImakuniPossibleRooms:
	db FIGHTING_CLUB_LOBBY
	db SCIENCE_CLUB_LOBBY
	db LIGHTNING_CLUB_LOBBY
	db WATER_CLUB_LOBBY


; preserves all registers except af
GetStackEventValue:
	call GetByteAfterCall
;	fallthrough

; preserves all registers except af
; input:
;	a = event ID
; output:
;	a = value for the event variable
GetEventValue::
	push hl
	push bc
	call GetEventVar
	ld c, [hl]
	ld a, [wLoadedEventBits]
.loop
	bit 0, a
	jr nz, .done
	srl a
	srl c
	jr .loop
.done
	and c
	pop bc
	pop hl
	or a
	ret

; Gets event value at c (Script defaults)
; c takes on the value of b as a side effect
; preserves de and hl
; input:
;	b = value for an event variable
;	c = event ID
; output:
;	c = input from register b
GetEventValueBC:
	ld a, c
	ld c, b
	jr GetEventValue


; preserves all registers except af
SetStackEventZero:
	call GetByteAfterCall
	push bc
	ld c, 0
	call SetEventValue
	pop bc
	ret


; Uses macro set_event_value. The byte db'd after this function is called
; is used as the event value argument for SetEventValue.
; preserves all registers except af
SetStackEventValue:
	call GetByteAfterCall
;	fallthrough

; preserves all registers except af
; input:
;	a = event ID
;	c = value (truncated to fit only the event variable's bounds)
SetEventValue:
	push hl
	push bc
	call GetEventVar
	ld a, [wLoadedEventBits]
.loop
	bit 0, a
	jr nz, .done
	srl a
	sla c
	jr .loop
.done
	ld a, [wLoadedEventBits]
	and c
	ld c, a
	ld a, [wLoadedEventBits]
	cpl
	and [hl]
	or c
	ld [hl], a
	pop bc
	pop hl
	ret


; preserves all registers except af
; output:
;	a = the byte db'd after the call to a function that calls this
GetByteAfterCall:
	push hl
	ld hl, sp+4
	push bc
	ld c, [hl]
	inc hl
	ld b, [hl]
	ld a, [bc]
	inc bc
	ld [hl], b
	dec hl
	ld [hl], c
	pop bc
	pop hl
	ret


; preserves all registers except af
MaxStackEventValue:
	call GetByteAfterCall
;	fallthrough

; preserves all registers except af
; input:
;	a = event ID
MaxOutEventValue:
	push bc
	ld c, $ff
	call SetEventValue
	pop bc
	ret


; preserves all registers except af
SetStackEventFalse:
	call GetByteAfterCall
;	fallthrough

; preserves all registers except af
; input:
;	a = event ID
ZeroOutEventValue:
	push bc
	ld c, 0
	call SetEventValue
	pop bc
	ret


; preserves all registers except af
TryGiveMedalPCPacks:
	push hl
	push bc
	ld hl, MedalEvents
	lb bc, 0, 8
.loop
	ld a, [hli]
	call GetEventValue
	jr z, .no_medal
	inc b
.no_medal
	dec c
	jr nz, .loop

	ld c, b
	set_event_value EVENT_MEDAL_COUNT
	ld a, c
	push af
	cp 8
	jr nc, .give_packs_for_eight_medals
	cp 7
	jr nc, .give_packs_for_seven_medals
	cp 3
	jr nc, .give_packs_for_three_medals
	jr .done

.give_packs_for_eight_medals
	ld a, $c
	farcall TryGivePCPack

.give_packs_for_seven_medals
	ld a, $b
	farcall TryGivePCPack

.give_packs_for_three_medals
	ld a, $a
	farcall TryGivePCPack

.done
	pop af
	pop bc
	pop hl
	ret

MedalEvents:
	db EVENT_BEAT_NIKKI
	db EVENT_BEAT_RICK
	db EVENT_BEAT_KEN
	db EVENT_BEAT_AMY
	db EVENT_BEAT_ISAAC
	db EVENT_BEAT_MURRAY
	db EVENT_BEAT_GENE
	db EVENT_BEAT_MITCH


; preserves bc and de
; input:
;	a = event ID
; output:
;	hl = wEventVars byte
;	[wLoadedEventBits] = related bits
GetEventVar:
	push bc
	ld c, a
	ld b, 0
	sla c
	rl b
	ld hl, EventVarMasks
	add hl, bc
	ld a, [hli]
	ld c, a
	ld a, [hl]
	ld [wLoadedEventBits], a
	ld b, 0
	ld hl, wEventVars
	add hl, bc
	pop bc
	ret

; location in wEventVars of each event var:
; offset - which byte holds the event value
; mask - which bits in the byte hold the value
; events 0-7 are reset when game resets
EventVarMasks:
	table_width 2, EventVarMasks
	event_def $3f, %10000000 ; EVENT_TEMP_TRADED_WITH_ISHIHARA
	event_def $3f, %01000000 ; EVENT_TEMP_GIFTED_TO_MAN1
	event_def $3f, %00100000 ; EVENT_TEMP_TALKED_TO_IMAKUNI
	event_def $3f, %00010000 ; EVENT_TEMP_DUELED_IMAKUNI
	event_def $3f, %00001000 ; EVENT_TEMP_TRADED_WITH_LASS2
	event_def $3f, %00000100 ; EVENT_TEMP_05 unused?
	event_def $3f, %00000010 ; EVENT_TEMP_06 unused?
	event_def $3f, %00000001 ; EVENT_TEMP_07 unused?
	event_def $00, %10000000 ; EVENT_BEAT_NIKKI
	event_def $00, %01000000 ; EVENT_BEAT_RICK
	event_def $00, %00100000 ; EVENT_BEAT_KEN
	event_def $00, %00010000 ; EVENT_BEAT_AMY
	event_def $00, %00001000 ; EVENT_BEAT_ISAAC
	event_def $00, %00000100 ; EVENT_BEAT_MURRAY
	event_def $00, %00000010 ; EVENT_BEAT_GENE
	event_def $00, %00000001 ; EVENT_BEAT_MITCH
	event_def $00, %11111111 ; EVENT_MEDAL_FLAGS
	event_def $01, %11110000 ; EVENT_PUPIL_MICHAEL_STATE
	event_def $01, %00001111 ; EVENT_GAL1_TRADE_STATE
	event_def $02, %11000000 ; EVENT_IMAKUNI_STATE
	event_def $02, %00110000 ; EVENT_LASS1_MENTIONED_IMAKUNI
	event_def $02, %00001000 ; EVENT_BEAT_SARA
	event_def $02, %00000100 ; EVENT_BEAT_AMANDA
	event_def $03, %11110000 ; EVENT_PUPIL_CHRIS_STATE
	event_def $03, %00001111 ; EVENT_MATTHEW_STATE
	event_def $04, %11110000 ; EVENT_CHAP2_TRADE_STATE
	event_def $04, %00001111 ; EVENT_DAVID_STATE
	event_def $05, %10000000 ; EVENT_BEAT_JOSEPH
	event_def $05, %01000000 ; EVENT_ISHIHARA_MENTIONED
	event_def $05, %00100000 ; EVENT_ISHIHARA_MET
	event_def $05, %00010000 ; EVENT_ISHIHARAS_HOUSE_MENTIONED
	event_def $05, %00001111 ; EVENT_ISHIHARA_TRADE_STATE
	event_def $06, %11110000 ; EVENT_PUPIL_JESSICA_STATE
	event_def $06, %00001100 ; EVENT_LAD2_STATE
	event_def $06, %00000010 ; EVENT_RECEIVED_LEGENDARY_CARDS
	event_def $06, %00000001 ; EVENT_KEN_HAD_ENOUGH_CARDS
	event_def $07, %11000000 ; EVENT_KEN_TALKED
	event_def $07, %00100000 ; EVENT_BEAT_JENNIFER
	event_def $07, %00010000 ; EVENT_BEAT_NICHOLAS
	event_def $07, %00001000 ; EVENT_BEAT_BRANDON
	event_def $07, %00000100 ; EVENT_ISAAC_TALKED
	event_def $07, %00000010 ; EVENT_MAN1_TALKED
	event_def $07, %00000001 ; EVENT_MAN1_WAITING_FOR_CARD
	event_def $08, %11111111 ; EVENT_MAN1_REQUESTED_CARD_ID
	event_def $09, %11100000 ; EVENT_MAN1_GIFT_SEQUENCE_STATE
	event_def $09, %00011111 ; EVENT_MAN1_GIFTED_CARD_FLAGS
	event_def $0a, %11110000 ; EVENT_MEDAL_COUNT
	event_def $0a, %00001000 ; EVENT_DANIEL_TALKED
	event_def $0a, %00000100 ; EVENT_MURRAY_TALKED
	event_def $0a, %00000011 ; EVENT_PAPPY1_STATE
	event_def $0b, %10000000 ; EVENT_RONALD_PSYCHIC_CLUB_LOBBY_ENCOUNTER
	event_def $0b, %01110000 ; EVENT_JOSHUA_STATE
	event_def $0b, %00001100 ; EVENT_IMAKUNI_ROOM
	event_def $0b, %00000011 ; EVENT_NIKKI_STATE
	event_def $0c, %11100000 ; EVENT_IMAKUNI_WIN_COUNT
	event_def $0c, %00011100 ; EVENT_LASS2_TRADE_STATE
	event_def $0c, %00000010 ; EVENT_ISHIHARA_WANTS_TO_TRADE
	event_def $0c, %00000001 ; EVENT_ISHIHARA_CONGRATULATED_PLAYER
	event_def $0d, %10000000 ; EVENT_BEAT_KRISTIN
	event_def $0d, %01000000 ; EVENT_BEAT_HEATHER
	event_def $0d, %00100000 ; EVENT_BEAT_BRITTANY
	event_def $0d, %00010000 ; EVENT_DRMASON_CONGRATULATED_PLAYER
	event_def $0d, %00001110 ; EVENT_MASON_LAB_STATE
	event_def $0e, %11100000 ; EVENT_CHALLENGE_CUP_1_STATE
	event_def $0e, %00011100 ; EVENT_CHALLENGE_CUP_2_STATE
	event_def $0f, %11100000 ; EVENT_CHALLENGE_CUP_3_STATE
	event_def $10, %10000000 ; EVENT_CHALLENGE_CUP_STARTING
	event_def $10, %01000000 ; EVENT_CHALLENGE_CUP_STAGE_VISITED
	event_def $10, %00110000 ; EVENT_CHALLENGE_CUP_NUMBER
	event_def $10, %00001100 ; EVENT_CHALLENGE_CUP_OPPONENT_NUMBER
	event_def $10, %00000010 ; EVENT_CHALLENGE_CUP_OPPONENT_CHOSEN
	event_def $10, %00000001 ; EVENT_CHALLENGE_CUP_IN_MENU
	event_def $11, %11100000 ; EVENT_CHALLENGE_CUP_1_RESULT
	event_def $11, %00011100 ; EVENT_CHALLENGE_CUP_2_RESULT
	event_def $12, %11100000 ; EVENT_CHALLENGE_CUP_3_RESULT
	event_def $13, %10000000 ; EVENT_RONALD_FIRST_CLUB_ENTRANCE_ENCOUNTER
	event_def $13, %01100000 ; EVENT_RONALD_FIRST_DUEL_STATE
	event_def $13, %00011000 ; EVENT_RONALD_SECOND_DUEL_STATE
	event_def $13, %00000100 ; EVENT_RONALD_TALKED
	event_def $13, %00000010 ; EVENT_RONALD_POKEMON_DOME_ENTRANCE_ENCOUNTER
	event_def $14, %10000000 ; EVENT_RONALD_CHALLENGE_HALL_LOBBY_CONVO_1
	event_def $14, %01000000 ; EVENT_RONALD_CHALLENGE_HALL_LOBBY_CONVO_2
	event_def $14, %00100000 ; EVENT_RONALD_CHALLENGE_HALL_LOBBY_CONVO_3
	event_def $14, %00010000 ; EVENT_RONALD_CHALLENGE_HALL_LOBBY_CONVO_4
	event_def $14, %00001000 ; EVENT_RONALD_CHALLENGE_HALL_LOBBY_CONVO_5
	event_def $14, %00000100 ; EVENT_RONALD_CHALLENGE_HALL_LOBBY_CONVO_6
	event_def $14, %00000010 ; EVENT_RONALD_CHALLENGE_HALL_LOBBY_CONVO_7
	event_def $14, %00000001 ; EVENT_RONALD_CHALLENGE_HALL_LOBBY_CONVO_8
	event_def $15, %11110000 ; EVENT_RONALD_CHALLENGE_HALL_LOBBY_STATE
	event_def $15, %00001000 ; EVENT_PLAYER_ENTERED_CHALLENGE_CUP
	event_def $16, %10000000 ; EVENT_FIGHTING_DECK_MACHINE_ACTIVE
	event_def $16, %01000000 ; EVENT_ROCK_DECK_MACHINE_ACTIVE
	event_def $16, %00100000 ; EVENT_WATER_DECK_MACHINE_ACTIVE
	event_def $16, %00010000 ; EVENT_LIGHTNING_DECK_MACHINE_ACTIVE
	event_def $16, %00001000 ; EVENT_GRASS_DECK_MACHINE_ACTIVE
	event_def $16, %00000100 ; EVENT_PSYCHIC_DECK_MACHINE_ACTIVE
	event_def $16, %00000010 ; EVENT_SCIENCE_DECK_MACHINE_ACTIVE
	event_def $16, %00000001 ; EVENT_FIRE_DECK_MACHINE_ACTIVE
	event_def $16, %11111111 ; EVENT_ALL_DECK_MACHINE_FLAGS
	event_def $17, %10000000 ; EVENT_HALL_OF_HONOR_DOORS_OPEN
	event_def $17, %01000000 ; EVENT_CHALLENGED_GRAND_MASTERS
	event_def $17, %00110000 ; EVENT_POKEMON_DOME_STATE
	event_def $17, %00001000 ; EVENT_POKEMON_DOME_IN_MENU
	event_def $17, %00000100 ; EVENT_CHALLENGED_RONALD
	event_def $18, %11000000 ; EVENT_COURTNEY_STATE
	event_def $18, %00110000 ; EVENT_STEVE_STATE
	event_def $18, %00001100 ; EVENT_JACK_STATE
	event_def $18, %00000011 ; EVENT_ROD_STATE
	event_def $19, %11000000 ; EVENT_RONALD_POKEMON_DOME_STATE
	event_def $19, %00100000 ; EVENT_RECEIVED_ZAPDOS
	event_def $19, %00010000 ; EVENT_RECEIVED_MOLTRES
	event_def $19, %00001000 ; EVENT_RECEIVED_ARTICUNO
	event_def $19, %00000100 ; EVENT_RECEIVED_DRAGONITE
	event_def $19, %00111100 ; EVENT_LEGENDARY_CARDS_RECEIVED_FLAGS
	event_def $1a, %11111100 ; EVENT_GIFT_CENTER_MENU_CHOICE
	event_def $1a, %00000011 ; EVENT_AARON_BOOSTER_REWARD
	event_def $1b, %11111111 ; EVENT_CONSOLE
	event_def $1c, %11110000 ; EVENT_SAM_MENU_CHOICE
	event_def $1c, %00001111 ; EVENT_AARON_DECK_MENU_CHOICE
	event_def $1d, %00000001 ; EVENT_PLAYER_GENDER
	assert_table_length NUM_EVENT_FLAGS


; Used for basic level objects that just print text and quit
PrintInteractableObjectText:
	ld hl, wDefaultObjectText
	ld a, [hli]
	ld h, [hl]
	ld l, a
	call Func_cc32
;	fallthrough

; closes dialogue window. seems to be for other things as well.
; preserves hl
CloseAdvancedDialogueBox:
	ld a, [wOverworldNPCFlags]
	bit AUTO_CLOSE_TEXTBOX, a
	call nz, CloseTextBox
	ld a, [wOverworldNPCFlags]
	bit RESTORE_FACING_DIRECTION, a
	jr z, .skip
	ld a, [wScriptNPC]
	ld [wLoadedNPCTempIndex], a
	farcall Func_1c5e9
.skip
	xor a
	ld [wOverworldNPCFlags], a
	ld a, [wOverworldModeBackup]
	ld [wOverworldMode], a
	ret


; input:
;	hl = ID of the text to print
Func_cc32:
	push hl
	ld hl, wCurrentNPCNameTx
	ld e, [hl]
	inc hl
	ld d, [hl]
	pop hl
;	fallthrough

Func_c8ba:
	ld a, e
	or d
	jp z, Func_c891
	push hl
	ld a, [wOverworldNPCFlags]
	bit AUTO_CLOSE_TEXTBOX, a
	jr z, .asm_c8d4
	ld hl, wd3b9
	ld a, [hli]
	cp e
	jr nz, .asm_c8d1
	ld a, [hl]
	cp d
	jr z, .asm_c8d4

.asm_c8d1
	call CloseTextBox

.asm_c8d4
	ld hl, wd3b9
	ld [hl], e
	inc hl
	ld [hl], d
	pop hl
	ld a, 1 << AUTO_CLOSE_TEXTBOX
	call SetOverworldNPCFlags
	call Func_c241
	call Func_c915
	call DoFrameIfLCDEnabled
	jp PrintScrollableText_WithTextBoxLabel


; Used for things that are represented as NPCs but don't have a Script
; EX: Clerks and legendary cards that interact through Level Objects
; preserves hl
Script_Clerk10:
Script_GiftCenterClerk:
Script_Woman2:
Script_Torch:
Script_LegendaryCardTopLeft:
Script_LegendaryCardTopRight:
Script_LegendaryCardLeftSpark:
Script_LegendaryCardBottomLeft:
Script_LegendaryCardBottomRight:
Script_LegendaryCardRightSpark:
	jr CloseAdvancedDialogueBox


; Enters into the script loop, continuing until wBreakScriptLoop > 0
; When the loop is broken, it resumes normal code execution where script ended
; Note: Some scripts "double return" and skip this.
RST20::
	pop hl
	ld a, l
	ld [wScriptPointer], a
	ld a, h
	ld [wScriptPointer + 1], a
	xor a
	ld [wBreakScriptLoop], a
.loop
	call RunOverworldScript
	ld a, [wBreakScriptLoop] ; if you break out, it jumps
	or a
	jr z, .loop
	ld hl, wScriptPointer
	ld a, [hli]
	ld c, a
	ld b, [hl]
	retbc


; preserves de and hl (also true for the following 6 functions)
IncreaseScriptPointerBy1:
	ld a, 1
	jr IncreaseScriptPointer

IncreaseScriptPointerBy2:
	ld a, 2
	jr IncreaseScriptPointer

IncreaseScriptPointerBy4:
	ld a, 4
	jr IncreaseScriptPointer

IncreaseScriptPointerBy5:
	ld a, 5
	jr IncreaseScriptPointer

IncreaseScriptPointerBy6:
	ld a, 6
	jr IncreaseScriptPointer

IncreaseScriptPointerBy7:
	ld a, 7
	jr IncreaseScriptPointer

IncreaseScriptPointerBy3:
	ld a, 3
;	fallthrough

; preserves de and hl
; input:
;	a = how much to increase the script pointer
IncreaseScriptPointer:
	ld c, a
	ld a, [wScriptPointer]
	add c
	ld [wScriptPointer], a
	ld a, [wScriptPointer + 1]
	adc 0
	ld [wScriptPointer + 1], a
	ret


; preserves bc and de
; input:
;	bc = new script pointer
SetScriptPointer:
	ld hl, wScriptPointer
	ld [hl], c
	inc hl
	ld [hl], b
	ret


; preserves de and hl (also true for the following 2 functions)
GetScriptArgs1AfterPointer:
	ld a, 1
	jr GetScriptArgsAfterPointer

GetScriptArgs2AfterPointer:
	ld a, 2
	jr GetScriptArgsAfterPointer

GetScriptArgs3AfterPointer:
	ld a, 3
;	fallthrough

; preserves de and hl
; input:
;	a = used to adjust the script pointer
; output:
;	bc = new arguments
GetScriptArgsAfterPointer:
	push hl
	ld l, a
	ld a, [wScriptPointer]
	add l
	ld l, a
	ld a, [wScriptPointer + 1]
	adc 0
	ld h, a
	ld a, [hli]
	ld c, a
	ld b, [hl]
	pop hl
	or b
	ret


; Exits Script mode and runs the next instruction like normal
; preserves de and hl
ScriptCommand_EndScript:
	ld a, TRUE
	ld [wBreakScriptLoop], a
	jr IncreaseScriptPointerBy1


; preserves hl
ScriptCommand_CloseAdvancedTextBox:
	call CloseAdvancedDialogueBox
	jr IncreaseScriptPointerBy1


ScriptCommand_QuitScriptFully:
	call ScriptCommand_CloseAdvancedTextBox
	call ScriptCommand_EndScript
	pop hl
	ret


; input:
;	bc = ID of the text to print
ScriptCommand_PrintNPCText:
	ld l, c
	ld h, b
	call Func_cc32
	jr IncreaseScriptPointerBy3


; input:
;	bc = ID of the text to print
ScriptCommand_PrintText:
	ld l, c
	ld h, b
	call Func_c891
	jr IncreaseScriptPointerBy3


ScriptCommand_AskQuestionJumpDefaultYes:
	ld a, TRUE
	ld [wDefaultYesOrNo], a
;	fallthrough

; Asks the player a question then jumps if they answer yes. Seem to be able to
; take a text of 0000 (NULL) to overwrite last with (yes no) prompt at the bottom
; preserves de
; input:
;	bc = ID of the text to print before yes/no
ScriptCommand_AskQuestionJump:
	ld l, c
	ld h, b
	call Func_c8ed
	ldh a, [hCurMenuItem]
	ld [wScriptControlByte], a
	jr c, IncreaseScriptPointerBy5 ; no jump
	call GetScriptArgs3AfterPointer
	jr z, IncreaseScriptPointerBy5 ; no jump
	jr SetScriptPointer


; arguments: Prize cards, deck ID, duel theme index
; sets a duel up, doesn't start until we break out of the script system.
; preserves de
; input:
;	c = number of Prizes to use
;	b = opponent's deck ID (*_DECK constant)
ScriptCommand_StartDuel:
	call SetNPCDuelParams
	ld a, [wScriptNPC]
	ld l, LOADED_NPC_ID
	call GetItemInLoadedNPCIndex
	ld a, [hl]
	farcall SetNPCMatchStartTheme
	ld a, [wNPCDuelDeckID]
	cp $ff
	jr nz, .not_aaron_duel
	ld a, [wMultichoiceTextboxResult_ChooseDeckToDuelAgainst]
	ld c, a
	ld b, 0
	ld hl, AaronDeckIDs
	add hl, bc
	ld a, [hl]
	ld [wNPCDuelDeckID], a
.not_aaron_duel
	ld a, [wScriptNPC]
	ld l, LOADED_NPC_ID
	call GetItemInLoadedNPCIndex
	ld a, [hl]
.start_duel
	ld [wNPCDuelist], a
	ld [wNPCDuelistCopy], a
	push af
	farcall Func_1c557
	ld [wNPCDuelistDirection], a
	pop af
	farcall SetNPCOpponentNameAndPortrait
	ld a, GAME_EVENT_DUEL
	ld [wGameEvent], a
	ld hl, wOverworldTransition
	set 6, [hl]
	jp IncreaseScriptPointerBy4

; preserves de
; input:
;	c = number of Prizes to use
;	b = opponent's deck ID (*_DECK constant)
ScriptCommand_StartChallengeHallDuel:
	call SetNPCDuelParams
	ld a, [wChallengeHallNPC]
	farcall SetNPCDeckIDAndDuelTheme
	ld a, MUSIC_MATCH_START_2
	ld [wMatchStartTheme], a
	ld a, [wChallengeHallNPC]
	jr ScriptCommand_StartDuel.start_duel

AaronDeckIDs:
	db LIGHTNING_AND_FIRE_DECK_ID
	db WATER_AND_FIGHTING_DECK_ID
	db GRASS_AND_PSYCHIC_DECK_ID


; preserves de and hl
; input:
;	c = number of Prizes to use
;	b = NPC's deck ID (*_DECK constant)
SetNPCDuelParams:
	ld a, c
	ld [wNPCDuelPrizes], a
	ld a, b
	ld [wNPCDuelDeckID], a
	call GetScriptArgs3AfterPointer
	ld a, c
	ld [wDuelTheme], a
	ret


; preserves de
ScriptCommand_BattleCenter:
	ld a, GAME_EVENT_BATTLE_CENTER
	ld [wGameEvent], a
	ld hl, wOverworldTransition
	set 6, [hl]
	jp IncreaseScriptPointerBy1


; prints text, 1 of 2 arguments depending on wScriptControlByte.
; input:
;	bc = ID of the text to print (if [wScriptControlByte] != 0)
ScriptCommand_PrintVariableNPCText:
	ld a, [wScriptControlByte]
	or a
	call z, GetScriptArgs3AfterPointer
	ld l, c
	ld h, b
	call Func_cc32
	jp IncreaseScriptPointerBy5


ScriptCommand_PrintTextForChallengeCup:
	get_event_value EVENT_CHALLENGE_CUP_NUMBER
	dec a
	and %11
	add a
	inc a
	call GetScriptArgsAfterPointer
	ld l, c
	ld h, b
	call Func_cc32
	jp IncreaseScriptPointerBy7


ScriptCommand_PrintVariableText:
	ld a, [wScriptControlByte]
	or a
	call z, GetScriptArgs3AfterPointer
	ld l, c
	ld h, b
	call Func_c891
	jp IncreaseScriptPointerBy5


; Does not return to RST20 - pops an extra time to skip that.
; input:
;	bc = ID of the text to print
ScriptCommand_PrintTextQuitFully:
	ld l, c
	ld h, b
	call Func_cc32
	call CloseAdvancedDialogueBox
	ld a, TRUE
	ld [wBreakScriptLoop], a
	call IncreaseScriptPointerBy3
	pop hl
	ret


; preserves de and hl
ScriptCommand_UnloadActiveNPC:
	ld a, [wScriptNPC]
	ld [wLoadedNPCTempIndex], a
Func_cdd1:
	farcall UnloadNPC
	jp IncreaseScriptPointerBy1


; preserves de and hl
ScriptCommand_UnloadChallengeHallNPC:
	ld a, [wLoadedNPCTempIndex]
	push af
	ld a, [wTempNPC]
	push af
	ld a, [wChallengeHallNPC]
	ld [wTempNPC], a
	call FindLoadedNPC
	call Func_cdd1
	pop af
	ld [wTempNPC], a
	pop af
	ld [wLoadedNPCTempIndex], a
	ret


; preserves de and hl
; input:
;	c = NPC's x coordinate
;	b = NPC's y coordinate
ScriptCommand_SetChallengeHallNPCCoords:
	ld a, [wLoadedNPCTempIndex]
	push af
	ld a, [wTempNPC]
	push af
	ld a, [wChallengeHallNPC]
	ld [wTempNPC], a
	ld a, c
	ld [wLoadNPCXPos], a
	ld a, b
	ld [wLoadNPCYPos], a
	ld a, SOUTH
	ld [wLoadNPCDirection], a
	ld a, [wTempNPC]
	farcall LoadNPCSpriteData
	farcall LoadNPC
	pop af
	ld [wTempNPC], a
	pop af
	ld [wLoadedNPCTempIndex], a
	jp IncreaseScriptPointerBy3


; Finds and executes an NPCMovement script in the table provided in bc
; based on the active NPC's current direction
; preserves de
; input:
;	 bc = used to figure out NPC's movement
ScriptCommand_MoveActiveNPCByDirection:
	ld a, [wScriptNPC]
	ld [wLoadedNPCTempIndex], a
	farcall GetNPCDirection
	rlca
	add c
	ld l, a
	ld a, b
	adc 0
	ld h, a
	ld c, [hl]
	inc hl
	ld b, [hl]
;	fallthrough

; Moves an NPC given the list of directions pointed to by bc
; set bit 7 to only rotate the NPC
; preserves de and hl
; input:
;	bc = address of next NPC movement byte
ExecuteNPCMovement::
	farcall StartNPCMovement
.loop
	call DoFrameIfLCDEnabled
	ld a, [wIsAnNPCMoving]
	and NPC_FLAG_MOVING
	jr nz, .loop ; is moving
	jp IncreaseScriptPointerBy3

; Begin a series of NPC movements on the currently talking NPC
; based on the series of directions pointed to by bc
; preserves de and hl
; input:
;	bc = address of next NPC movement byte
ScriptCommand_MoveActiveNPC:
	ld a, [wScriptNPC]
	ld [wLoadedNPCTempIndex], a
	jr ExecuteNPCMovement


; Begins a series of NPC movements on the Challenge Hall opponent NPC
; based on the series of directions pointed to by bc
; preserves de
; input:
;	bc = address of next NPC movement byte
ScriptCommand_MoveChallengeHallNPC:
	ld a, [wLoadedNPCTempIndex]
	push af
	ld a, [wTempNPC]
	push af
	ld a, [wChallengeHallNPC]
;	fallthrough

; Executes movement on an arbitrary NPC using values in a and on the stack
; Changes and fixes Temp NPC using stack values
ExecuteArbitraryNPCMovementFromStack:
	ld [wTempNPC], a
	call FindLoadedNPC
	call ExecuteNPCMovement
	pop af
	ld [wTempNPC], a
	pop af
	ld [wLoadedNPCTempIndex], a
	ret

; preserves de and hl
; input:
;	c = ID of the arbitrary NPC (NPC_* constant)
ScriptCommand_MoveArbitraryNPC:
	ld a, [wLoadedNPCTempIndex]
	push af
	ld a, [wTempNPC]
	push af
	ld a, c
	push af
	call GetScriptArgs2AfterPointer
	push bc
	call IncreaseScriptPointerBy1
	pop bc
	pop af
	jr ExecuteArbitraryNPCMovementFromStack


; preserves hl
ScriptCommand_CloseTextBox:
	call CloseTextBox
	jp IncreaseScriptPointerBy1


; arguments: booster pack index, booster pack index, booster pack index
; input:
;	c = ID for 1st booster pack (e.g. BOOSTER_COLOSSEUM_NEUTRAL)
;	b = ID for 2nd booster pack
ScriptCommand_GiveBoosterPacks:
	xor a
	ld [wAnotherBoosterPack], a
	call Func_c2a3
	push bc
	ld a, c
	farcall GiveBoosterPack
	ld a, TRUE
	ld [wAnotherBoosterPack], a
	pop bc
	ld a, b
	cp NO_BOOSTER
	jr z, .done
	farcall GiveBoosterPack
	call GetScriptArgs3AfterPointer
	ld a, c
	cp NO_BOOSTER
	jr z, .done
	farcall GiveBoosterPack
.done
	call ReturnToOverworldNoCallback
	jp IncreaseScriptPointerBy4


; used after the player defeats Imakuni
ScriptCommand_GiveOneOfEachTrainerBooster:
	xor a
	ld [wAnotherBoosterPack], a
	call Func_c2a3
	ld hl, .booster_type_table
.loop
	ld a, [hl]
	cp NO_BOOSTER
	jr z, .done
	push hl
	farcall GiveBoosterPack
	ld a, TRUE
	ld [wAnotherBoosterPack], a
	pop hl
	inc hl
	jr .loop
.done
	call ReturnToOverworldNoCallback
	jp IncreaseScriptPointerBy1

.booster_type_table
	db BOOSTER_COLOSSEUM_TRAINER
	db BOOSTER_EVOLUTION_TRAINER
	db BOOSTER_MYSTERY_TRAINER_COLORLESS
	db BOOSTER_LABORATORY_TRAINER
	db NO_BOOSTER ; $ff


; Shows the card received screen for a given promotional card
; input:
;	c = ID of the received card (unless c is $00 or $ff)
;	c = $00:  use card ID in [wCardReceived]
;	c = $ff:  use one of the 4 Legendary cards
ScriptCommand_ShowCardReceivedScreen:
	call Func_c2a3
	ld a, c
	cp $ff
	jr z, .legendary_card
	or a
	jr nz, .show_card
	ld a, [wCardReceived]

.show_card
	push af
	farcall InitMenuScreen
	farcall FlashWhiteScreen
	pop af
	farcall ShowPromotionalCardScreen
	call WhiteOutDMGPals
	call DoFrameIfLCDEnabled
	call ReturnToOverworldNoCallback
	jp IncreaseScriptPointerBy2

.legendary_card
	xor a
	jr .show_card


; preserves de
; input:
;	c = card ID to check
ScriptCommand_JumpIfCardOwned:
	ld a, c
	call GetCardCountInCollectionAndDecks
	jr ScriptCommand_JumpIfCardInCollection.count_check

; preserves de
; input:
;	c = card ID to check
ScriptCommand_JumpIfCardInCollection:
	ld a, c
	call GetCardCountInCollection

.count_check
	or a
	jr nz, .pass_try_jump

.fail
	xor a ; fail
	ld [wScriptControlByte], a
	jp IncreaseScriptPointerBy4

.pass_try_jump
	ld a, $ff ; pass
	ld [wScriptControlByte], a
	call GetScriptArgs2AfterPointer
	jp z, IncreaseScriptPointerBy4 ; no jump
	jp SetScriptPointer


; preserves de
; input:
;	bc = number of cards needed
ScriptCommand_JumpIfEnoughCardsOwned:
	push bc
	call IncreaseScriptPointerBy1
	pop bc
	call GetAmountOfCardsOwned
	ld a, h
	cp b
	jr nz, .high_byte_not_equal
	ld a, l
	cp c

.high_byte_not_equal
	jr nc, ScriptCommand_JumpIfCardInCollection.pass_try_jump
	jr ScriptCommand_JumpIfCardInCollection.fail


; preserves de and hl
; input:
;	c = ID of the received card (unless c = $00)
;	c = $00:  use card ID in [wCardReceived]
ScriptCommand_GiveCard:
	ld a, c
	or a
	jr nz, .give_card
	ld a, [wCardReceived]

.give_card
	call AddCardToCollection
	jp IncreaseScriptPointerBy2


; preserves de and hl
; input:
;	c = ID of the card being lost
ScriptCommand_TakeCard:
	ld a, c
	call RemoveCardFromCollection
	jp IncreaseScriptPointerBy2


; preserves de
ScriptCommand_JumpIfAnyEnergyCardsInCollection:
	lb bc, 0, GRASS_ENERGY
.loop
	ld a, c
	call GetCardCountInCollection
	add b
	ld b, a
	inc c
	ld a, c
	cp DOUBLE_COLORLESS_ENERGY + 1
	jr c, .loop
	ld a, b
	or a
	jr nz, .pass_try_jump

.fail
	xor a ; fail
	ld [wScriptControlByte], a
	jp IncreaseScriptPointerBy3

.pass_try_jump
	ld a, $ff ; pass
	ld [wScriptControlByte], a
	call GetScriptArgs1AfterPointer
	jp z, IncreaseScriptPointerBy3 ; no jump
	jp SetScriptPointer


; preserves de and hl
ScriptCommand_RemoveAllEnergyCardsFromCollection:
	ld c, GRASS_ENERGY
.next_energy
	push bc
	ld a, c
	call GetCardCountInCollection
	jr c, .no_energy
	ld b, a
.remove_loop
	ld a, c
	call RemoveCardFromCollection
	dec b
	jr nz, .remove_loop

.no_energy
	pop bc
	inc c
	ld a, c
	cp DOUBLE_COLORLESS_ENERGY + 1
	jr c, .next_energy
	jp IncreaseScriptPointerBy1


; preserves de
ScriptCommand_JumpBasedOnFightingClubPupilStatus:
	ld c, 0
	get_event_value EVENT_PUPIL_MICHAEL_STATE
	or a ; cp PUPIL_INACTIVE
	jr z, .first_interaction
	cp PUPIL_DEFEATED
	jr c, .pupil1_not_defeated
	inc c
.pupil1_not_defeated
	get_event_value EVENT_PUPIL_CHRIS_STATE
	cp PUPIL_DEFEATED
	jr c, .pupil2_not_defeated
	inc c
.pupil2_not_defeated
	get_event_value EVENT_PUPIL_JESSICA_STATE
	cp PUPIL_DEFEATED
	jr c, .pupil3_not_defeated
	inc c
.pupil3_not_defeated
	ld a, c
	rlca
	add 3
	call GetScriptArgsAfterPointer
	jp SetScriptPointer

.first_interaction
	call GetScriptArgs1AfterPointer
	jp SetScriptPointer


; preserves de and hl
; input:
;	c = new direction for LOADED_NPC_DIRECTION_BACKUP
ScriptCommand_SetActiveNPCDirection:
	ld a, [wScriptNPC]
	ld [wLoadedNPCTempIndex], a
	ld a, c
	farcall Func_1c52e
	jp IncreaseScriptPointerBy2


ScriptCommand_PickNextMan1RequestedCard:
	get_event_value EVENT_MAN1_GIFTED_CARD_FLAGS
	ld b, a
.choose_again
	ld a, Man1RequestedCardsList.end - Man1RequestedCardsList
	call Random
	ld e, 1
	ld c, a
	push bc
	or a
	jr z, .skip_shift
.shift_loop
	sla e
	dec c
	jr nz, .shift_loop
.skip_shift
	ld a, e
	and b ; has this card already been chosen before?
	pop bc
	jr nz, .choose_again
	ld a, e
	or b
	push bc
	ld c, a
	set_event_value EVENT_MAN1_GIFTED_CARD_FLAGS
	pop bc
	ld b, 0
	ld hl, Man1RequestedCardsList
	add hl, bc
	ld c, [hl]
	set_event_value EVENT_MAN1_REQUESTED_CARD_ID
	jp IncreaseScriptPointerBy1

Man1RequestedCardsList:
	db GRAVELER
	db OMASTAR
	db PARASECT
	db RAPIDASH
	db WEEZING
.end


; input:
;	c = offset for wTxRam2
ScriptCommand_LoadMan1RequestedCardIntoTxRamSlot:
	sla c
	ld b, 0
	ld hl, wTxRam2
	add hl, bc
	push hl
	get_event_value EVENT_MAN1_REQUESTED_CARD_ID
	ld e, a ; e = ID of the requested card
	ld d, 0
	call GetCardName
	pop hl
	ld [hl], e
	inc hl
	ld [hl], d
	jp IncreaseScriptPointerBy2


; preserves de
ScriptCommand_JumpIfMan1RequestedCardOwned:
	get_event_value EVENT_MAN1_REQUESTED_CARD_ID
	call GetCardCountInCollectionAndDecks
	jp c, ScriptCommand_JumpIfAnyEnergyCardsInCollection.fail
	jp ScriptCommand_JumpIfAnyEnergyCardsInCollection.pass_try_jump


; preserves de
ScriptCommand_JumpIfMan1RequestedCardInCollection:
	get_event_value EVENT_MAN1_REQUESTED_CARD_ID
	call GetCardCountInCollection
	jp c, ScriptCommand_JumpIfAnyEnergyCardsInCollection.fail
	jp ScriptCommand_JumpIfAnyEnergyCardsInCollection.pass_try_jump


; preserves de and hl
ScriptCommand_RemoveMan1RequestedCardFromCollection:
	get_event_value EVENT_MAN1_REQUESTED_CARD_ID
	call RemoveCardFromCollection
	jp IncreaseScriptPointerBy1


; preserves de
ScriptCommand_Jump:
	call GetScriptArgs1AfterPointer
	jp SetScriptPointer


; preserves de and hl
ScriptCommand_TryGiveMedalPCPacks:
	call TryGiveMedalPCPacks
	jp IncreaseScriptPointerBy1


; preserves de and hl
; input:
;	c = direction to set
ScriptCommand_SetPlayerDirection:
	ld a, c
	call UpdatePlayerDirection
	jp IncreaseScriptPointerBy2


; preserves hl
; input:
;	c = player's direction (index in PlayerMovementOffsetTable_Tiles)
;	b = Tiles Moves (Speed)
ScriptCommand_MovePlayer:
	ld a, c
	ld [wd339], a
	ld a, b
	ld [wd33a], a
	call StartScriptedMovement
.wait
	call DoFrameIfLCDEnabled
	call SetScreenScroll
	call Func_c53d
	ld a, [wPlayerCurrentlyMoving]
	and $03
	jr nz, .wait
	call DoFrameIfLCDEnabled
	call SetScreenScroll
	jp IncreaseScriptPointerBy3


; preserves de and hl
; input:
;	c = ID of the NPC that's talking (NPC_* constant)
ScriptCommand_SetDialogNPC:
	ld a, c
	farcall SetNPCDialogName
	jp IncreaseScriptPointerBy2


; preserves de and hl
; input:
;	c = ID of the NPC to set (NPC_* constant)
ScriptCommand_SetNextNPCAndScript:
	ld a, c
	ld [wTempNPC], a
	call GetScriptArgs2AfterPointer
	call SetNextNPCAndScript
	jp IncreaseScriptPointerBy4


; input:
;	b = NPC animation for CGB
;	c = NPC animation for DMG/SGB
ScriptCommand_SetSpriteAttributes:
	ld a, [wScriptNPC]
	ld [wLoadedNPCTempIndex], a
	push bc
	call GetScriptArgs3AfterPointer
	ld a, [wScriptNPC]
	ld l, LOADED_NPC_FLAGS
	call GetItemInLoadedNPCIndex
	res NPC_FLAG_DIRECTIONLESS_F, [hl]
	ld a, [hl]
	or c
	ld [hl], a
	pop bc
	ld e, c
	ld a, [wConsole]
	cp CONSOLE_CGB
	jr nz, .not_cgb
	ld e, b
.not_cgb
	ld a, e
	farcall SetNPCAnimation
	jp IncreaseScriptPointerBy4


; preserves de and hl
; input:
;	c = NPC's new x coordinate
;	b = NPC's new y coordinate
ScriptCommand_SetActiveNPCCoords:
	ld a, [wScriptNPC]
	ld [wLoadedNPCTempIndex], a
	ld a, c
	ld c, b
	ld b, a
	farcall SetNPCPosition
	jp IncreaseScriptPointerBy3


; preserves de and hl
; input:
;	c = number of times to call DoFrameIfLCDEnabled
ScriptCommand_DoFrames:
	call DoFrameIfLCDEnabled
	dec c
	jr nz, ScriptCommand_DoFrames
	jp IncreaseScriptPointerBy2


; input:
;	c = x coordinate to check
;	b = y coordinate to check
ScriptCommand_JumpIfActiveNPCCoordsMatch:
	ld a, [wScriptNPC]
	ld [wLoadedNPCTempIndex], a
	ld d, c
	ld e, b
	farcall GetNPCPosition
	ld a, e
	cp c
	jp nz, ScriptCommand_JumpIfEventEqual.fail
	ld a, d
	cp b
	jp nz, ScriptCommand_JumpIfEventEqual.fail
	jp ScriptCommand_JumpIfEventEqual.pass_try_jump


; preserves de
; input:
;	c = x coordinate to check
;	b = y coordinate to check
ScriptCommand_JumpIfPlayerCoordsMatch:
	ld a, [wPlayerXCoord]
	cp c
	jp nz, ScriptCommand_JumpIfEventEqual.fail
	ld a, [wPlayerYCoord]
	cp b
	jp nz, ScriptCommand_JumpIfEventEqual.fail
	jp ScriptCommand_JumpIfEventEqual.pass_try_jump


; preserves de
; input:
;	c = ID of the NPC to check (NPC_* constant)
ScriptCommand_JumpIfNPCLoaded:
	ld a, [wLoadedNPCTempIndex]
	push af
	ld a, [wTempNPC]
	push af
	ld a, c
	ld [wTempNPC], a
	call FindLoadedNPC
	jr c, .not_loaded
	call ScriptCommand_JumpIfEventTrue.pass_try_jump
	jr .done

.not_loaded
	call ScriptCommand_JumpIfEventFalse.fail

.done
	pop af
	ld [wTempNPC], a
	pop af
	ld [wLoadedNPCTempIndex], a
	ret


; input:
;	c = which medal to show
ScriptCommand_ShowMedalReceivedScreen:
	call Func_c2a3
	ld a, c
	farcall ShowMedalReceivedScreen
	call ReturnToOverworldNoCallback
	jp IncreaseScriptPointerBy2


; input:
;	c = used to create the offset for wTxRam2
ScriptCommand_LoadCurrentMapNameIntoTxRamSlot:
	sla c
	ld b, 0
	ld hl, wTxRam2
	add hl, bc
	push hl
	ld a, [wOverworldMapSelection]
	rlca
	ld c, a
	ld b, 0
	ld hl, MapNames - 2
	add hl, bc
	ld e, [hl]
	inc hl
	ld d, [hl]
	pop hl
	ld [hl], e
	inc hl
	ld [hl], d
	jp IncreaseScriptPointerBy2

MapNames:
	tx MasonLaboratoryMapName
	tx MrIshiharasHouseMapName
	tx FightingClubMapName
	tx RockClubMapName
	tx WaterClubMapName
	tx LightningClubMapName
	tx GrassClubMapName
	tx PsychicClubMapName
	tx ScienceClubMapName
	tx FireClubMapName
	tx ChallengeHallMapName
	tx PokemonDomeMapName


; input:
;	c = used to create the offset for wTxRam2
ScriptCommand_LoadChallengeHallNPCIntoTxRamSlot:
	ld hl, wCurrentNPCNameTx
	ld e, [hl]
	inc hl
	ld d, [hl]
	push de
	sla c
	ld b, 0
	ld hl, wTxRam2
	add hl, bc
	push hl
	ld a, [wChallengeHallNPC]
	farcall SetNPCDialogName
	pop hl
	ld a, [wCurrentNPCNameTx]
	ld [hli], a
	ld a, [wCurrentNPCNameTx + 1]
	ld [hl], a
	pop de
	ld hl, wCurrentNPCNameTx
	ld [hl], e
	inc hl
	ld [hl], d
	jp IncreaseScriptPointerBy2


ScriptCommand_PickChallengeHallOpponent:
	ld a, [wTempNPC]
	push af
	get_event_value EVENT_CHALLENGE_CUP_OPPONENT_NUMBER
	inc a
	ld c, a
	set_event_value EVENT_CHALLENGE_CUP_OPPONENT_NUMBER
	call Func_f580
	pop af
	ld [wTempNPC], a
	jp IncreaseScriptPointerBy1


ScriptCommand_OpenMenu:
	call PauseMenu
	jp IncreaseScriptPointerBy1


ScriptCommand_PickChallengeCupPrizeCard:
	get_event_value EVENT_CHALLENGE_CUP_NUMBER
	dec a
	cp 2
	jr c, .first_or_second_cup
	ld a, (ChallengeCupPrizeCards.end - ChallengeCupPrizeCards) / 3 - 2
	call Random
	add 2
.first_or_second_cup
	ld hl, ChallengeCupPrizeCards
.get_card_from_list
	ld e, a
	add a
	add e
	ld e, a
	ld d, 0
	add hl, de
	ld a, [hli]
	ld [wCardReceived], a
	ld a, [hli]
	ld [wTxRam2], a
	ld a, [hl]
	ld [wTxRam2 + 1], a
	jp IncreaseScriptPointerBy1

ChallengeCupPrizeCards:
	db MEWTWO_LV60
	tx MewtwoTradeCardName

	db MEW_LV8
	tx MewTradeCardName

	db ARCANINE_LV34
	tx ArcanineTradeCardName

	db PIKACHU_LV16
	tx PikachuTradeCardName

	db PIKACHU_ALT_LV16
	tx PikachuTradeCardName

	db SURFING_PIKACHU_LV13
	tx SurfingPikachuTradeCardName

	db SURFING_PIKACHU_ALT_LV13
	tx SurfingPikachuTradeCardName

	db ELECTABUZZ_LV20
	tx ElectabuzzTradeCardName

	db SLOWPOKE_LV9
	tx SlowpokeTradeCardName

	db MEWTWO_ALT_LV60
	tx MewtwoTradeCardName

	db MEWTWO_LV60
	tx MewtwoTradeCardName

	db MEW_LV8
	tx MewTradeCardName

	db JIGGLYPUFF_LV12
	tx JigglypuffTradeCardName

	db SUPER_ENERGY_RETRIEVAL
	tx SuperEnergyRetrievalTradeCardName

	db FLYING_PIKACHU
	tx FlyingPikachuTradeCardName

	db VENUSAUR_LV64
	tx VenusaurLv64TradeCardName

	db MEW_LV15
	tx MewLv15TradeCardName
.end


ScriptCommand_PickLegendaryCard:
	get_event_value EVENT_LEGENDARY_CARDS_RECEIVED_FLAGS
	ld e, a
.new_random
	call UpdateRNGSources
	ld d, %00001000
	and %11
	ld c, a
	ld b, a
.loop
	jr z, .done
	srl d
	dec b
	jr .loop
.done
	ld a, d
	and e ; has this legendary been given already?
	jr nz, .new_random
	push bc
	ld b, 0
	ld hl, LegendaryCardEvents
	add hl, bc
	ld a, [hl]
	call MaxOutEventValue ; also modifies EVENT_LEGENDARY_CARDS_RECEIVED_FLAGS
	pop bc
	ld hl, LegendaryCards
	ld a, c
	jr ScriptCommand_PickChallengeCupPrizeCard.get_card_from_list

LegendaryCards:
	db ZAPDOS_LV68
	tx ZapdosLegendaryCardName

	db MOLTRES_LV37
	tx MoltresLegendaryCardName

	db ARTICUNO_LV37
	tx ArticunoLegendaryCardName

	db DRAGONITE_LV41
	tx DragoniteLegendaryCardName

LegendaryCardEvents:
	db EVENT_RECEIVED_ZAPDOS
	db EVENT_RECEIVED_MOLTRES
	db EVENT_RECEIVED_ARTICUNO
	db EVENT_RECEIVED_DRAGONITE


; preserves de and hl
; input:
;	c = offset for wOWMapEvents
ScriptCommand_ReplaceMapBlocks:
	ld a, c
	farcall Func_80ba4
	jp IncreaseScriptPointerBy2


ScriptCommand_ChooseDeckToDuelAgainstMultichoice:
	ld hl, .multichoice_menu_args
	xor a
	call ShowMultichoiceTextbox
	ld a, [wMultichoiceTextboxResult_ChooseDeckToDuelAgainst]
	ld c, a
	set_event_value EVENT_AARON_DECK_MENU_CHOICE
	jp IncreaseScriptPointerBy1

.multichoice_menu_args
	dw NULL ; NPC title for textbox under menu
	tx SelectDeckToDuelText ; text for textbox under menu
	dw MultichoiceTextbox_ConfigTable_ChooseDeckToDuelAgainst ; location of table configuration in bank 4
	db AARON_DECK_MENU_CANCEL ; the value to return when b is pressed
	dw wMultichoiceTextboxResult_ChooseDeckToDuelAgainst ; ram location to return result into
	dw .text_entries ; location of table containing text entries

.text_entries
	tx LightningAndFireDeckChoiceText
	tx WaterAndFightingDeckChoiceText
	tx GrassAndPsychicDeckChoiceText

	dw NULL


ScriptCommand_ChooseStarterDeckMultichoice:
	ld hl, .multichoice_menu_args
	xor a
	call ShowMultichoiceTextbox
	jp IncreaseScriptPointerBy1

.multichoice_menu_args
	dw NULL ; NPC title for textbox under menu
	tx SelectDeckToTakeText ; text for textbox under menu
	dw MultichoiceTextbox_ConfigTable_ChooseDeckStarterDeck ; location of table configuration in bank 4
	db $00 ; the value to return when b is pressed
	dw wStarterDeckChoice ; ram location to return result into
	dw .text_entries ; location of table containing text entries

.text_entries
	tx CharmanderAndFriendsDeckChoiceText
	tx SquirtleAndFriendsDeckChoiceText
	tx BulbasaurAndFriendsDeckChoiceText


; displays a textbox with multiple choices and a cursor.
; takes as an argument in h1 a pointer to a table
;	dw text ID for the NPC's title (for header of textbox below menu)
;	dw text ID for the textbox below the menu
;	dw location of the table configuration in bank $04
;	db the value to return when the B button is pressed
;	dw ram location to output the result
;	dw location of the table containing the text entries (optional)
; input:
;	a = current menu item
;	hl = multichoice menu parameters
ShowMultichoiceTextbox:
	ld [wd416], a
;	push hl ; unnecessary?
	call Func_c241
	call Func_c915
	call DoFrameIfLCDEnabled
;	pop hl ; unnecessary?
	ld a, [hli]
	ld e, a
	ld a, [hli]
	ld d, a
	ld a, [hli]
	push hl
	ld h, [hl]
	ld l, a
	or h
	call nz, Func_c8ba
	ld a, 1 << AUTO_CLOSE_TEXTBOX
	call SetOverworldNPCFlags
	pop hl
	inc hl
	ld a, [hli]
	push hl
	ld h, [hl]
	ld l, a
	ld a, [wd416]
	farcall InitAndPrintMenu
	pop hl
	inc hl
	ld a, [hli]
	ld [wd417], a
	push hl

.wait_input
	call DoFrameIfLCDEnabled
	call HandleMenuInput
	jr nc, .wait_input
	cp e ; compare hCurMenuItem with wCurMenuItem
	jr z, .got_result
	ld a, [wd417]
	or a
	jr z, .wait_input
	ld e, a
	ldh [hCurMenuItem], a

.got_result
	pop hl
	ld a, [hli]
	push hl
	ld h, [hl]
	ld l, a
	ld a, e
	ld [hl], a ; store result
	add a
	ld c, a
	ld b, $0
	pop hl
	inc hl
	ld a, [hli]
	ld h, [hl]
	ld l, a
	or h
	ret z ; no text
	add hl, bc
	ld a, [hli]
	ld [wTxRam2], a
	ld a, [hl]
	ld [wTxRam2 + 1], a
	ret


ScriptCommand_ShowSamNormalMultichoice:
	ld hl, .multichoice_menu_args
	xor a
	call ShowMultichoiceTextbox
	ld a, [wMultichoiceTextboxResult_Sam]
	ld c, a
	set_event_value EVENT_SAM_MENU_CHOICE
	xor a
	ld [wMultichoiceTextboxResult_Sam], a
	jp IncreaseScriptPointerBy1

.multichoice_menu_args
	tx SamNPCName ; NPC title for textbox under menu
	tx HowCanIHelpText ; text for textbox under menu
	dw SamNormalMultichoice_ConfigurationTable ; location of table configuration in bank 4
	db SAM_MENU_NOTHING ; the value to return when b is pressed
	dw wMultichoiceTextboxResult_Sam ; ram location to return result into
	dw NULL ; location of table containing text entries


ScriptCommand_ShowSamRulesMultichoice:
	ld hl, .multichoice_menu_args
	ld a, [wMultichoiceTextboxResult_Sam]
	call ShowMultichoiceTextbox
	ld a, [wMultichoiceTextboxResult_Sam]
	ld c, a
	set_event_value EVENT_SAM_MENU_CHOICE
	jp IncreaseScriptPointerBy1

.multichoice_menu_args
	dw NULL ; NPC title for textbox under menu
	dw NULL ; text for textbox under menu
	dw SamRulesMultichoice_ConfigurationTable ; location of table configuration in bank 4
	db SAM_MENU_NOTHING_TO_ASK ; the value to return when b is pressed
	dw wMultichoiceTextboxResult_Sam ; ram location to return result into
	dw NULL ; location of table containing text entries


ScriptCommand_OpenDeckMachine:
	push bc
	call Func_c2a3
	call PauseSong
	ld a, MUSIC_DECK_MACHINE
	call PlaySong
	call EmptyScreen
	xor a
	ldh [hSCX], a
	ldh [hSCY], a
	call SetDefaultPalettes
	call EnableLCD
	pop bc
	ld a, c
	or a
	jr z, .asm_d360
	dec a
	ld [wCurAutoDeckMachine], a
	farcall HandleAutoDeckMenu
	jr .asm_d364
.asm_d360
	farcall HandleDeckSaveMachineMenu
.asm_d364
	call ResumeSong
	call ReturnToOverworldNoCallback
	jp IncreaseScriptPointerBy2


; arguments: unused, room, new player x, new player y, new player direction
; preserves de
ScriptCommand_EnterMap:
	ld hl, wScriptPointer
	ld a, [hli]
	ld h, [hl]
	ld l, a
	inc hl
	ld a, [hli]
	ld a, [hli]
	ld [wTempMap], a
	ld a, [hli]
	ld [wTempPlayerXCoord], a
	ld a, [hli]
	ld [wTempPlayerYCoord], a
	ld a, [hli]
	ld [wTempPlayerDirection], a
	ld hl, wOverworldTransition
	set 4, [hl]
	jp IncreaseScriptPointerBy6


ScriptCommand_FlashScreen:
	farcall FlashScreenToWhite
	jp IncreaseScriptPointerBy2


; preserves de
; input:
;	c = 0: save the player at their current position
;	c > 0: save the player in Mason's lab
ScriptCommand_SaveGame:
	farcall _SaveGame
	jp IncreaseScriptPointerBy2


; input:
;	c = Gift Center selection (might be stored in [wGiftCenterChoice])
ScriptCommand_GiftCenter:
	ld a, c
	or a
	jr nz, .load_gift_center
	; show menu
	farcall GiftCenterMenu
	ld c, a
	set_event_value EVENT_GIFT_CENTER_MENU_CHOICE
	jp IncreaseScriptPointerBy2

.load_gift_center
	ld a, GAME_EVENT_GIFT_CENTER
	ld [wGameEvent], a
	ld hl, wOverworldTransition
	set 6, [hl]
	jp IncreaseScriptPointerBy2


; preserves de
ScriptCommand_PlayCredits:
	call GetReceivedLegendaryCards
	ld a, GAME_EVENT_CREDITS
	ld [wGameEvent], a
	ld hl, wOverworldTransition
	set 6, [hl]
	jp IncreaseScriptPointerBy1


; input:
;	c = booster type (e.g. BOOSTER_COLOSSEUM_NEUTRAL)
ScriptCommand_TryGivePCPack:
	ld a, c
	farcall TryGivePCPack
	jp IncreaseScriptPointerBy2


; preserves de and hl
ScriptCommand_nop:
	jp IncreaseScriptPointerBy1


ScriptCommand_GiveStarterDeck:
	ld a, [wStarterDeckChoice]
	farcall AddStarterDeck
	jp IncreaseScriptPointerBy1


ScriptCommand_WalkPlayerToMasonLaboratory:
	ld a, OWMAP_MASON_LABORATORY
	ld [wOverworldMapSelection], a
	farcall OverworldMap_BeginPlayerMovement
.asm_d3e9
	call DoFrameIfLCDEnabled
	farcall OverworldMap_UpdatePlayerWalkingAnimation
	ld a, [wOverworldMapPlayerAnimationState]
	cp $2
	jr nz, .asm_d3e9
	farcall OverworldMap_PrintMapName
	jp IncreaseScriptPointerBy1


; preserves de and hl
; input:
;	c = ID of the song to play (MUSIC_* constant)
ScriptCommand_OverrideSong:
	ld a, c
	ld [wSongOverride], a
	call PlaySong
	jp IncreaseScriptPointerBy2


; preserves de and hl
; input:
;	c = ID of the song to set as the default (MUSIC_* constant)
ScriptCommand_SetDefaultSong:
	ld a, c
	ld [wDefaultSong], a
	jp IncreaseScriptPointerBy2


; preserves de and hl
; input:
;	c = ID of the song to play (MUSIC_* constant)
ScriptCommand_PlaySong:
	ld a, c
	call PlaySong
	jp IncreaseScriptPointerBy2


; preserves de and hl
; input:
;	c = ID of the sound effect to play (SFX_* constant)
ScriptCommand_PlaySFX:
	ld a, c
	call PlaySFX
	jp IncreaseScriptPointerBy2


; preserves de and hl
ScriptCommand_PlayDefaultSong:
	call PlayDefaultSong
	jp IncreaseScriptPointerBy1


ScriptCommand_PauseSong:
	call PauseSong
	jp IncreaseScriptPointerBy1


ScriptCommand_ResumeSong:
	call ResumeSong
	jp IncreaseScriptPointerBy1


; preserves de and hl
ScriptCommand_WaitForSongToFinish:
	call WaitForSongToFinish
	jp IncreaseScriptPointerBy1


; preserves de and hl
; input:
;	c = master to add to wMastersBeatenList
ScriptCommand_RecordMasterWin:
	ld a, c
	farcall AddMasterBeatenToList
	jp IncreaseScriptPointerBy2


; preserves de
ScriptCommand_ChallengeMachine:
	ld a, GAME_EVENT_CHALLENGE_MACHINE
	ld [wGameEvent], a
	ld hl, wOverworldTransition
	set 6, [hl]
	jp IncreaseScriptPointerBy1


; sets the event variable in argument 1 to the value in argument 2
; preserves de and hl
; input:
;	c = event ID
;	b = value (truncated to fit only the event variable's bounds)
ScriptCommand_SetEventValue:
	ld a, c
	ld c, b
	call SetEventValue
	jp IncreaseScriptPointerBy3


; preserves de and hl
; input:
;	c = event ID
ScriptCommand_IncrementEventValue:
	ld a, c
	push af
	call GetEventValue
	inc a
	ld c, a
	pop af
	call SetEventValue
	jp IncreaseScriptPointerBy2


; preserves de
; input:
;	c = event ID
ScriptCommand_JumpIfEventZero:
	ld a, c
	call GetEventValue
	or a
	jr z, .pass_try_jump

.fail
	xor a ; fail
	ld [wScriptControlByte], a
	jp IncreaseScriptPointerBy4

.pass_try_jump
	ld a, $ff ; pass
	ld [wScriptControlByte], a
	call GetScriptArgs2AfterPointer
	jp z, IncreaseScriptPointerBy4 ; no jump
	jp SetScriptPointer


; preserves de
; input:
;	c = event ID
ScriptCommand_JumpIfEventNonzero:
	ld a, c
	call GetEventValue
	or a
	jr nz, ScriptCommand_JumpIfEventZero.pass_try_jump
	jr ScriptCommand_JumpIfEventZero.fail


; arguments: event variable, value, jump address
; preserves de
; input:
;	c = event ID
;	b = event variable value to compare
ScriptCommand_JumpIfEventEqual:
	call GetEventValueBC
	cp c ; input from register b
	jr z, .pass_try_jump

.fail
	xor a ; fail
	ld [wScriptControlByte], a
	jp IncreaseScriptPointerBy5

.pass_try_jump
	ld a, $ff ; pass
	ld [wScriptControlByte], a
	call GetScriptArgs3AfterPointer
	jp z, IncreaseScriptPointerBy5 ; no jump
	jp SetScriptPointer


; preserves de
; input:
;	c = event ID
;	b = event variable value to compare
ScriptCommand_JumpIfEventNotEqual:
	call GetEventValueBC
	cp c ; input from register b
	jr nz, ScriptCommand_JumpIfEventEqual.pass_try_jump
	jr ScriptCommand_JumpIfEventEqual.fail


; preserves de
; input:
;	c = event ID
;	b = event variable value to compare
ScriptCommand_JumpIfEventGreaterOrEqual:
	call GetEventValueBC
	cp c ; input from register b
	jr nc, ScriptCommand_JumpIfEventEqual.pass_try_jump
	jr ScriptCommand_JumpIfEventEqual.fail


; preserves de
; input:
;	c = event ID
;	b = event variable value to compare
ScriptCommand_JumpIfEventLessThan:
	call GetEventValueBC
	cp c ; input from register b
	jr c, ScriptCommand_JumpIfEventEqual.pass_try_jump
	jr ScriptCommand_JumpIfEventEqual.fail


; preserves de and hl
; input:
;	c = event ID
ScriptCommand_MaxOutEventValue:
	ld a, c
	call MaxOutEventValue
	jp IncreaseScriptPointerBy2


; preserves de and hl
; input:
;	c = event ID
ScriptCommand_ZeroOutEventValue:
	ld a, c
	call ZeroOutEventValue
	jp IncreaseScriptPointerBy2


; preserves de
; input:
;	c = event ID
ScriptCommand_JumpIfEventTrue:
	ld a, c
	call GetEventValue
	or a
	jr z, ScriptCommand_JumpIfEventFalse.fail

.pass_try_jump
	ld a, $ff ; pass
	ld [wScriptControlByte], a
	call GetScriptArgs2AfterPointer
	jp z, IncreaseScriptPointerBy4 ; no jump
	jp SetScriptPointer


; preserves de
; input:
;	c = event ID
ScriptCommand_JumpIfEventFalse:
	ld a, c
	call GetEventValue
	or a
	jr z, ScriptCommand_JumpIfEventTrue.pass_try_jump

.fail
	xor a ; fail
	ld [wScriptControlByte], a
	jp IncreaseScriptPointerBy4


; preserves de and hl
LoadOverworld:
	call Func_d4fb
	get_event_value EVENT_MASON_LAB_STATE
	or a
	ret nz
	ld bc, Script_BeginGame
	jp SetNextScript


; preserves all registers except af
Func_d4fb:
	set_event_false EVENT_PLAYER_ENTERED_CHALLENGE_CUP
	call Func_f602
	get_event_value EVENT_CHALLENGE_CUP_1_STATE
	cp CHALLENGE_CUP_WON
	jr z, .close_challenge_cup_one
	get_event_value EVENT_CHALLENGE_CUP_2_STATE
	cp CHALLENGE_CUP_WON
	jr z, .close_challenge_cup_two
	get_event_value EVENT_CHALLENGE_CUP_3_STATE
	cp CHALLENGE_CUP_WON
	jr z, .close_challenge_cup_three
	ret

.close_challenge_cup_three
	ld c, CHALLENGE_CUP_OVER
	set_event_value EVENT_CHALLENGE_CUP_3_STATE
.close_challenge_cup_two
	ld c, CHALLENGE_CUP_OVER
	set_event_value EVENT_CHALLENGE_CUP_2_STATE
.close_challenge_cup_one
	ld c, CHALLENGE_CUP_OVER
	set_event_value EVENT_CHALLENGE_CUP_1_STATE
	ret


INCLUDE "scripts/mason_laboratory.asm"
INCLUDE "scripts/deck_machine_room.asm"

INCLUDE "scripts/ishiharas_house.asm"

INCLUDE "scripts/fighting_club_entrance.asm"
INCLUDE "scripts/fighting_club_lobby.asm"
INCLUDE "scripts/fighting_club.asm"

INCLUDE "scripts/rock_club_entrance.asm"
INCLUDE "scripts/rock_club_lobby.asm"
INCLUDE "scripts/rock_club.asm"

INCLUDE "scripts/water_club_entrance.asm"
INCLUDE "scripts/water_club_lobby.asm"
INCLUDE "scripts/water_club.asm"

INCLUDE "scripts/lightning_club_entrance.asm"
INCLUDE "scripts/lightning_club_lobby.asm"
INCLUDE "scripts/lightning_club.asm"

INCLUDE "scripts/grass_club_entrance.asm"
INCLUDE "scripts/grass_club_lobby.asm"
INCLUDE "scripts/grass_club.asm"

INCLUDE "scripts/psychic_club_entrance.asm"
INCLUDE "scripts/psychic_club_lobby.asm"
INCLUDE "scripts/psychic_club.asm"

INCLUDE "scripts/science_club_entrance.asm"
INCLUDE "scripts/science_club_lobby.asm"
INCLUDE "scripts/science_club.asm"

INCLUDE "scripts/fire_club_entrance.asm"
INCLUDE "scripts/fire_club_lobby.asm"
INCLUDE "scripts/fire_club.asm"

INCLUDE "scripts/challenge_hall_entrance.asm"
INCLUDE "scripts/challenge_hall_lobby.asm"
INCLUDE "scripts/challenge_hall.asm"

INCLUDE "scripts/pokemon_dome_entrance.asm"
INCLUDE "scripts/pokemon_dome.asm"
INCLUDE "scripts/hall_of_honor.asm"

INCLUDE "scripts/battle_center.asm"
INCLUDE "scripts/gift_center.asm"
