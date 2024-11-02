; preserves de and hl
OverworldDoFrameFunction::
	ld a, [wOverworldNPCFlags]
	bit HIDE_ALL_NPC_SPRITES, a
	ret nz
	ldh a, [hBankROM]
	push af
	ld a, BANK(SetScreenScrollWram)
	rst BankswitchROM
	call SetScreenScrollWram
	call Func_c554 ; this function is also in Bank $03
	ld a, BANK(HandleAllNPCMovement)
	rst BankswitchROM
	call HandleAllNPCMovement
	call HandleAllSpriteAnimations
	ld a, BANK(DoLoadedFramesetSubgroupsFrame)
	rst BankswitchROM
	call DoLoadedFramesetSubgroupsFrame
	call UpdateRNGSources
	pop af
	jp BankswitchROM


; enables the play time counter and executes the game event at [wGameEvent].
; then returns to the overworld, or restarts the game (only after Credits).
ExecuteGameEvent::
	ld a, 1
	ld [wPlayTimeCounterEnable], a
	ldh a, [hBankROM]
	push af
.loop
	call _ExecuteGameEvent
	jr nc, .restart
	farcall LoadMap
	jr .loop
.restart
	pop af
	jp BankswitchROM

; executes a game event at [wGameEvent] from GameEventPointerTable
_ExecuteGameEvent::
	ld a, [wGameEvent]
	cp NUM_GAME_EVENTS
	jr c, .got_game_event
	ld a, GAME_EVENT_CHALLENGE_MACHINE
.got_game_event
	ld hl, GameEventPointerTable
	jp JumpToFunctionInTable

GameEventPointerTable::
	dw GameEvent_Overworld
	dw GameEvent_Duel
	dw GameEvent_BattleCenter
	dw GameEvent_GiftCenter
	dw GameEvent_Credits
	dw GameEvent_ContinueDuel
	dw GameEvent_ChallengeMachine
	dw GameEvent_Overworld


; output:
;	carry = set
GameEvent_Duel::
	ld a, GAME_EVENT_DUEL
	ld [wActiveGameEvent], a
	xor a
	ld [wSongOverride], a
	call EnableSRAM
	ld [sPlayerInChallengeMachine], a
	call DisableSRAM
	call SaveGeneralSaveData
	bank1call StartDuel_VSAIOpp
	scf
	ret


; output:
;	carry = set
GameEvent_BattleCenter::
	ld a, GAME_EVENT_BATTLE_CENTER
	ld [wActiveGameEvent], a
	xor a
	ld [wSongOverride], a
	dec a ; -1
	ld [wDuelResult], a
	ld a, MUSIC_DUEL_THEME_1
	ld [wDuelTheme], a
	ld a, MUSIC_CARD_POP
	call PlaySong
	farcall SetUpAndStartLinkDuel
	scf
	ret


; output:
;	carry = set
GameEvent_GiftCenter::
	ldh a, [hBankROM]
	push af
	call PauseSong
	ld a, MUSIC_CARD_POP
	call PlaySong
	ld a, BANK(HandleGiftCenter)
	rst BankswitchROM
	ld a, GAME_EVENT_GIFT_CENTER
	ld [wActiveGameEvent], a
	ld a, [wGiftCenterChoice]
	or $10
	ld [wGiftCenterChoice], a
	call HandleGiftCenter
	ld a, [wGiftCenterChoice]
	and $ef
	ld [wGiftCenterChoice], a
	call ResumeSong
	pop af
	rst BankswitchROM
	scf
	ret


GameEvent_Credits::
	farcall PlayCreditsSequence
	or a
	ret


; output:
;	carry = set
GameEvent_ContinueDuel::
	xor a
	ld [wSongOverride], a
	bank1call TryContinueDuel
	call EnableSRAM
	ld a, [sPlayerInChallengeMachine]
	call DisableSRAM
	cp $ff
	jr z, GameEvent_ChallengeMachine.asm_38ed
	scf
	ret


GameEvent_ChallengeMachine::
	ld a, MUSIC_PC_MAIN_MENU
	ld [wDefaultSong], a
	call PlayDefaultSong
	call EnableSRAM
	xor a
	ld [sPlayerInChallengeMachine], a
	call DisableSRAM
.asm_38ed
	farcall ChallengeMachine_Start
	ld a, MUSIC_OVERWORLD
	ld [wDefaultSong], a
	call PlayDefaultSong
;	fallthrough

; output:
;	carry = set
GameEvent_Overworld::
	scf
	ret


; preserves all registers except af
GetReceivedLegendaryCards::
	ld a, EVENT_RECEIVED_LEGENDARY_CARDS
	farcall GetEventValue
	call EnableSRAM
	ld [sReceivedLegendaryCards], a
	jp DisableSRAM


; preserves all registers except af
; input:
;	bc = x and y coordinates for the current map
; output:
;	a = permission byte corresponding to the coordinates from input
GetPermissionOfMapPosition::
	push hl
	call GetPermissionByteOfMapPosition
	ld a, [hl]
	pop hl
	ret


; set to a the permission byte corresponding to the current map's x,y coordinates at bc
; preserves all registers
; input:
;	a = new permission byte value
;	bc = x and y coordinates for the current map
SetPermissionOfMapPosition::
	push hl
	push af
	call GetPermissionByteOfMapPosition
	pop af
	ld [hl], a
	pop hl
	ret


; set the permission byte corresponding to the current map's x,y coordinates at bc
; to the value of register a anded by its current value
; preserves all registers except af
; input:
;	a = value used to modify the permission byte
;	bc = x and y coordinates for the current map
UpdatePermissionOfMapPosition::
	push hl
	push de
	cpl
	ld e, a
	call GetPermissionByteOfMapPosition
	ld a, [hl]
	and e
	ld [hl], a
	pop de
	pop hl
	ret


; preserves bc and de
; input:
;	bc = x and y coordinates for the current map
; output:
;	hl = address within wPermissionMap corresponding to the coordinates from input
GetPermissionByteOfMapPosition::
	push bc
	srl b
	srl c
	swap c
	ld a, c
	and $f0
	or b
	ld c, a
	ld b, $0
	ld hl, wPermissionMap
	add hl, bc
	pop bc
	ret


; copy c bytes of data from hl in bank wTempPointerBank to de, b times.
; input:
;	b = number of times to copy
;	c = number of bytes to copy
;	hl = address from which to start copying the data
;	de = where to copy the data
CopyGfxDataFromTempBank::
	ldh a, [hBankROM]
	push af
	ld a, [wTempPointerBank]
	rst BankswitchROM
	call CopyGfxData
	pop af
	jp BankswitchROM


; Movement offsets for player movements
PlayerMovementOffsetTable::
	db  0, -1 ; NORTH
	db  1,  0 ; EAST
	db  0,  1 ; SOUTH
	db -1,  0 ; WEST


; Movement offsets for player movements, in tiles
PlayerMovementOffsetTable_Tiles::
	db  0, -2 ; NORTH
	db  2,  0 ; EAST
	db  0,  2 ; SOUTH
	db -2,  0 ; WEST


OverworldMapNames::
	table_width 2, OverworldMapNames
	tx OverworldMapMasonLaboratoryText
	tx OverworldMapMasonLaboratoryText
	tx OverworldMapIshiharasHouseText
	tx OverworldMapFightingClubText
	tx OverworldMapRockClubText
	tx OverworldMapWaterClubText
	tx OverworldMapLightningClubText
	tx OverworldMapGrassClubText
	tx OverworldMapPsychicClubText
	tx OverworldMapScienceClubText
	tx OverworldMapFireClubText
	tx OverworldMapChallengeHallText
	tx OverworldMapPokemonDomeText
	tx OverworldMapMysteryHouseText
	assert_table_length NUM_OWMAP_NAMES


; preserves all registers except af
HandleMapWarp::
	ldh a, [hBankROM]
	push af
	ld a, BANK(_HandleMapWarp)
	rst BankswitchROM
	call _HandleMapWarp
	pop af
	jp BankswitchROM


; preserves bc and de
; input:
;	a = NPC's index (0-7) for wLoadedNPCs table
; output:
;	hl = pointer to the location of NPC's ID in wLoadedNPCs
GetLoadedNPCID::
	ld l, LOADED_NPC_ID
;	fallthrough

; preserves bc and de
; input:
;	a = NPC's index (0-7) for wLoadedNPCs table
;	l = NPC parameter to find (LOADED_NPC_* constant)
; output:
;	hl = pointer to the location of NPC's parameter l in wLoadedNPCs
GetItemInLoadedNPCIndex::
	push bc
	cp LOADED_NPC_MAX
	jr c, .asm_39b4
	xor a
.asm_39b4
	add a
	add a
	ld h, a
	add a
	add h
	add l
	ld l, a
	ld h, $0
	ld bc, wLoadedNPCs
	add hl, bc
	pop bc
	ret


; Finds the index on the wLoadedNPCs table of the NPC in wTempNPC
; preserves all registers except af
; input:
;	[wTempNPC] = NPC to find
; output:
;	carry = set:  if the NPC wasn't found
;	[wLoadedNPCTempIndex] & a = NPC's index (0-7) for wLoadedNPCs table
FindLoadedNPC::
	push hl
	push bc
	push de
	xor a
	ld [wLoadedNPCTempIndex], a
	ld b, a
	ld c, LOADED_NPC_MAX
	ld de, LOADED_NPC_LENGTH
	ld hl, wLoadedNPCs
	ld a, [wTempNPC]
.findNPCLoop
	cp [hl]
	jr z, .foundNPCMatch
	add hl, de
	inc b
	dec c
	jr nz, .findNPCLoop
	scf
	jr z, .exit
.foundNPCMatch
	ld a, b
	ld [wLoadedNPCTempIndex], a
	or a
.exit
	pop de
	pop bc
	pop hl
	ret


; preserves all registers except af
;input:
;	bc = address of next NPC movement byte
; output:
;	a = next NPC movement byte
GetNextNPCMovementByte::
	push bc
	ldh a, [hBankROM]
	push af
	ld a, BANK(ExecuteNPCMovement)
	rst BankswitchROM
	ld a, [bc]
	ld c, a
	pop af
	rst BankswitchROM
	ld a, c
	pop bc
	ret
