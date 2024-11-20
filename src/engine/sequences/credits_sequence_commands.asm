; preserves all registers except af
SetCreditsSequenceCmdPtr:
	ld a, LOW(CreditsSequence)
	ld [wSequenceCmdPtr + 0], a
	ld a, HIGH(CreditsSequence)
	ld [wSequenceCmdPtr + 1], a
	xor a
	ld [wSequenceDelay], a
	ret


ExecuteCreditsSequenceCmd:
	ld a, [wSequenceDelay]
	or a
	jr z, .call_func
	cp $ff
	ret z ; sequence ended

	dec a ; still waiting
	ld [wSequenceDelay], a
	ret

.call_func
	ld hl, wSequenceCmdPtr
	ld a, [hli]
	ld h, [hl]
	ld l, a
	ld a, [hli]
	ld e, a
	ld a, [hli]
	ld d, a
	push de
	ld a, [hli]
	ld c, a
	ld a, [hli]
	ld b, a
	ld a, [hli]
	ld e, a
	ld a, [hli]
	ld d, a
	pop hl
	call CallHL
	jr ExecuteCreditsSequenceCmd


; preserves all registers except af
AdvanceCreditsSequenceCmdPtrBy2:
	ld a, 2
	jr AdvanceCreditsSequenceCmdPtr

; preserves all registers except af
AdvanceCreditsSequenceCmdPtrBy3:
	ld a, 3
	jr AdvanceCreditsSequenceCmdPtr

; preserves all registers except af
AdvanceCreditsSequenceCmdPtrBy5:
	ld a, 5
	jr AdvanceCreditsSequenceCmdPtr

; preserves all registers except af
AdvanceCreditsSequenceCmdPtrBy6:
	ld a, 6
	jr AdvanceCreditsSequenceCmdPtr

; preserves all registers except af
AdvanceCreditsSequenceCmdPtrBy4:
	ld a, 4
;	fallthrough

; input:
;	a = how much to add to wSequenceCmdPtr
AdvanceCreditsSequenceCmdPtr:
	push hl
	ld hl, wSequenceCmdPtr
	add [hl]
	ld [hli], a
	ld a, [hl]
	adc 0
	ld [hl], a
	pop hl
	ret


; preserves all registers except af
; input:
;	c = new sequence delay
CreditsSequenceCmd_Wait:
	ld a, c
	ld [wSequenceDelay], a
	jr AdvanceCreditsSequenceCmdPtrBy3


; preserves de
; input:
;	e = scene ID (SCENE_* constant)
;	c = base X position of scene in tiles
;	b = base Y position of scene in tiles
CreditsSequenceCmd_LoadScene:
	push bc
	push de
	call EmptyScreen
	xor a
	ld [wNumLoadedFramesetSubgroups], a
	ldh [hSCX], a
	ldh [hSCY], a
	call SetDefaultPalettes
	pop de
	pop bc
	ld a, c
	ld c, b
	ld b, a
	ld a, e
	call LoadScene
	jr AdvanceCreditsSequenceCmdPtrBy5


; preserves de
; input:
;	e = scene ID (SCENE_* constant)
;	c = base X position of scene in tiles
;	b = base Y position of scene in tiles
CreditsSequenceCmd_LoadBooster:
	push bc
	push de
	call EmptyScreen
	xor a
	ld [wNumLoadedFramesetSubgroups], a
	ldh [hSCX], a
	ldh [hSCY], a
	call SetDefaultPalettes
	pop de
	pop bc
	ld a, c
	ld c, b
	ld b, a
	ld a, e
	farcall LoadBoosterGfx
	jr AdvanceCreditsSequenceCmdPtrBy5


; input:
;	c = offset for wMastersBeatenList
CreditsSequenceCmd_LoadClubMap:
	ld b, $00
	ld hl, wMastersBeatenList
	add hl, bc
	ld a, [hl]
	or a
	jr nz, .at_least_1
	inc a
.at_least_1
	dec a
	ld c, a
	add a
	add a
	add c ; *5
	ld c, a
	ld hl, .CreditsOWClubMaps
	add hl, bc
	ld a, [hli] ; map x coordinate
	ld c, a
	ld a, [hli] ; map y coordinate
	ld b, a
	ld a, [hli] ; map ID
	ld e, a
	push hl
	call LoadOWMapForCreditsSequence
	pop hl
	ld a, [hli]
	ld h, [hl]
	ld l, a
	or h
	jp z, AdvanceCreditsSequenceCmdPtrBy3 ; done


.loop_npcs
	ld a, [hli] ; NPC ID
	or a
	jp z, AdvanceCreditsSequenceCmdPtrBy3 ; done
	ld d, a
	ld a, [hli] ; NPC x coordinate
	ld c, a
	ld a, [hli] ; NPC y coordinate
	ld b, a
	ld a, [hli] ; NPC direction
	ld e, a
	push hl
	call LoadNPCForCreditsSequence
	pop hl
	jr .loop_npcs


MACRO credits_club_map
	db \1 ; x
	db \2 ; y
	db \3 ; OW map
	dw \4 ; list of NPCs to load
ENDM

.CreditsOWClubMaps
	credits_club_map 16,  0, FIGHTING_CLUB,  .CreditsNPCs_FightingClub
	credits_club_map 32,  0, ROCK_CLUB,      .CreditsNPCs_RockClub
	credits_club_map 64,  0, WATER_CLUB,     .CreditsNPCs_WaterClub
	credits_club_map 32,  0, LIGHTNING_CLUB, .CreditsNPCs_LightningClub
	credits_club_map 32,  0, GRASS_CLUB,     .CreditsNPCs_GrassClub
	credits_club_map 32, 16, PSYCHIC_CLUB,   .CreditsNPCs_PsychicClub
	credits_club_map  0,  0, SCIENCE_CLUB,   .CreditsNPCs_ScienceClub
	credits_club_map 32,  0, FIRE_CLUB,      .CreditsNPCs_FireClub
	credits_club_map 32,  0, CHALLENGE_HALL, .CreditsNPCs_ChallengeHall
	credits_club_map 48,  0, POKEMON_DOME,   .CreditsNPCs_PokemonDome

.CreditsNPCs_FightingClub
	; NPC ID, x, y, direction
	db NPC_CHRIS,           4,  8, SOUTH
	db NPC_MICHAEL,        14, 10, SOUTH
	db NPC_JESSICA,        18,  6, EAST
	db NPC_MITCH,          10,  4, SOUTH
	db NPC_PLAYER_CREDITS, 10,  6, NORTH
	db $00

.CreditsNPCs_RockClub
	; NPC ID, x, y, direction
	db NPC_RYAN,           20, 14, EAST
	db NPC_GENE,           12,  6, SOUTH
	db NPC_PLAYER_CREDITS, 12,  8, NORTH
	db $00

.CreditsNPCs_WaterClub
	; NPC ID, x, y, direction
	db NPC_JOSHUA,         22,  8, SOUTH
	db NPC_AMY,            22,  4, NORTH
	db NPC_PLAYER_CREDITS, 18, 10, NORTH
	db $00

.CreditsNPCs_LightningClub
	; NPC ID, x, y, direction
	db NPC_NICHOLAS,        6, 10, SOUTH
	db NPC_BRANDON,        22, 12, NORTH
	db NPC_ISAAC,          12,  4, NORTH
	db NPC_PLAYER_CREDITS, 12, 10, NORTH
	db $00

.CreditsNPCs_GrassClub
	; NPC ID, x, y, direction
	db NPC_KRISTIN,         4, 10, EAST
	db NPC_HEATHER,        14, 16, SOUTH
	db NPC_NIKKI,          12,  4, SOUTH
	db NPC_PLAYER_CREDITS, 12,  6, NORTH
	db $00

.CreditsNPCs_PsychicClub
	; NPC ID, x, y, direction
	db NPC_DANIEL,          8,  8, NORTH
	db NPC_STEPHANIE,      22, 12, EAST
	db NPC_MURRAY1,        12,  6, SOUTH
	db NPC_PLAYER_CREDITS, 12,  8, NORTH
	db $00

.CreditsNPCs_ScienceClub
	; NPC ID, x, y, direction
	db NPC_JOSEPH,         10, 10, WEST
	db NPC_RICK,            4,  4, SOUTH
	db NPC_PLAYER_CREDITS,  4,  6, NORTH
	db $00

.CreditsNPCs_FireClub
	; NPC ID, x, y, direction
	db NPC_ADAM,            8, 14, SOUTH
	db NPC_JONATHAN,       18, 10, SOUTH
	db NPC_KEN,            14,  4, SOUTH
	db NPC_PLAYER_CREDITS, 14,  6, NORTH
	db $00

.CreditsNPCs_ChallengeHall
	; NPC ID, x, y, direction
	db NPC_HOST,           14,  4, SOUTH
	db NPC_RONALD1,        18,  8, WEST
	db NPC_PLAYER_CREDITS, 12,  8, EAST
	db $00

.CreditsNPCs_PokemonDome
	; NPC ID, x, y, direction
	db NPC_COURTNEY,       18,  4, SOUTH
	db NPC_STEVE,          22,  4, SOUTH
	db NPC_JACK,            8,  4, SOUTH
	db NPC_ROD,            14,  6, SOUTH
	db NPC_PLAYER_CREDITS, 14, 10, NORTH
	db $00


; input:
;	bc = coordinates
;	e = OW map
LoadOWMapForCreditsSequence:
	push bc
	push de
	call EmptyScreen
	pop de
	pop bc

	; set input coordinates and map
	ld a, c
	ldh [hSCX], a
	ld a, b
	ldh [hSCY], a
	ld a, e
	ld [wCurMap], a

	farcall LoadMapTilesAndPals
	farcall Func_c9c7
	farcall SafelyCopyBGMapFromSRAMToVRAM
	farcall DoMapOWFrame
	xor a
	ld [wd4ca], a
	ld [wd4cb], a
	ld a, PALETTE_29
	farcall LoadPaletteData
	ret


; input:
;	bc = coordinates
;	e = OW map
CreditsSequenceCmd_LoadOWMap:
	call LoadOWMapForCreditsSequence
	jp AdvanceCreditsSequenceCmdPtrBy5


; preserves all registers except af
CreditsSequenceCmd_DisableLCD:
	call DisableLCD
	jp AdvanceCreditsSequenceCmdPtrBy2


CreditsSequenceCmd_FadeIn:
	call DisableLCD
	call SetWindowOn
	farcall FadeScreenFromWhite
	jp AdvanceCreditsSequenceCmdPtrBy2


CreditsSequenceCmd_FadeOut:
	farcall FadeScreenToWhite
	call ClearSpriteAnimations
	call EnableLCD
	call DoFrameIfLCDEnabled
	call DisableLCD
	call SetWindowOff
	jp AdvanceCreditsSequenceCmdPtrBy2


; input:
;	b = height of the image being drawn by FillRectangle
;	c = used to find the y coordinate for FillRectangle
CreditsSequenceCmd_DrawRectangle:
	ld a, c
	or $20
	ld e, a   ; y coordinate
	ld d, $00 ; x coordinate
	ld c, b   ; height of image
	ld b, 20  ; width of image
	xor a     ; starting tile number
	lb hl, 0, 0
	call FillRectangle
	jp AdvanceCreditsSequenceCmdPtrBy4


; input:
;	de = ID of text to print
;	c = x coordinate at which to begin printing the text
;	b = used to find the y coordinate for printing the text
CreditsSequenceCmd_PrintText:
	ld a, SINGLE_SPACED
	ld [wLineSeparation], a
	push de
	ld d, c ; x coordinate for the text
	ld a, b
	or $20
	ld e, a ; y coordinate for the text
	pop hl
	call InitTextPrinting_PrintTextNoDelay
	jp AdvanceCreditsSequenceCmdPtrBy6


; input:
;	de = ID of text to print
;	c = x coordinate at which to begin printing the text
;	b = y coordinate at which to begin printing the text
CreditsSequenceCmd_PrintTextBox:
	ld a, SINGLE_SPACED
	ld [wLineSeparation], a
	push de
	ld d, c
	ld e, b
	pop hl
	call InitTextPrinting_PrintTextNoDelay
	jp AdvanceCreditsSequenceCmdPtrBy6


; preserves all registers except af
; input:
;	c = stored in wd647 to be used by future functions
;	b = stored in wd648 to be used by future functions
;	e = stored in wd649 to be used by future functions
;	d = stored in wd64a to be used by future functions
CreditsSequenceCmd_InitOverlay:
	ld a, c
	ld [wd647], a
	ld a, b
	ld [wd648], a
	ld a, e
	ld [wd649], a
	ld a, d
	ld [wd64a], a
	call Func_1d765
	jp AdvanceCreditsSequenceCmdPtrBy6


; preserves de
; input:
;	bc = coordinates at which to draw the NPC
;	e = direction for the NPC to face
;	d = NPC ID (NPC_* constant)
CreditsSequenceCmd_LoadNPC:
	call LoadNPCForCreditsSequence
	jp AdvanceCreditsSequenceCmdPtrBy6


; preserves de
; input:
;	bc = coordinates at which to draw the NPC
;	e = direction for the NPC to face
;	d = NPC ID (NPC_* constant)
LoadNPCForCreditsSequence:
	ld a, c
	ld [wLoadNPCXPos], a
	ld a, b
	ld [wLoadNPCYPos], a
	ld a, e
	ld [wLoadNPCDirection], a
	ld a, d
	farcall LoadNPCSpriteData
	ld a, [wNPCSpriteID]
	farcall CreateSpriteAndAnimBufferEntry

	ld c, SPRITE_ANIM_COORD_X
	call GetSpriteAnimBufferProperty
	ldh a, [hSCX]
	ld c, a
	ld a, [wLoadNPCXPos]
	add a
	add a
	add a ; *8
	add 8
	sub c
	ld [hli], a ; x
	ldh a, [hSCY]
	ld c, a
	ld a, [wLoadNPCYPos]
	add a
	add a
	add a ; *8
	add 16
	sub c
	ld [hli], a ; y

	ld a, [wNPCAnim]
	ld c, a
	ld a, [wLoadNPCDirection]
	add c
	farcall StartNewSpriteAnimation
	ret


; preserves de
CreditsSequenceCmd_InitVolcanoSprite:
	farcall OverworldMap_InitVolcanoSprite
	jp AdvanceCreditsSequenceCmdPtrBy2


; preserves de
CreditsSequenceCmd_TransformOverlay:
; either stretches or shrinks overlay to the input configurations
	ld l, 0
	ld a, [wd647]
	call .Func_1dade
	ld [wd647], a
	ld a, [wd648]
	ld c, b
	call .Func_1dade
	ld [wd648], a
	ld a, [wd649]
	ld c, e
	call .Func_1dade
	ld [wd649], a
	ld a, [wd64a]
	ld c, d
	call .Func_1dade
	ld [wd64a], a
	ld a, l
	or a
	jr z, .advance_sequence
	ld a, 1
	ld [wSequenceDelay], a
	ret

.advance_sequence
	call Func_1d765
	jp AdvanceCreditsSequenceCmdPtrBy6

; compares a with c
; if it's smaller: increase by 2 and increment l
; if it's larger:  decrease by 2 and increment l
; if it's equal or $ff: do nothing
.Func_1dade
	cp $ff
	ret z
	cp c
	ret z
	inc l
	jr c, .incr_a
; decr a
	dec a
	dec a
	ret
.incr_a
	inc a
	inc a
	ret
