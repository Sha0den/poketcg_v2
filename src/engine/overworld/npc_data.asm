; preserves bc and de
; input:
;	a = NPC ID (NPC_* constant)
; output:
;	hl = pointer for NPCHeaderPointers
GetNPCHeaderPointer:
	rlca
	add LOW(NPCHeaderPointers)
	ld l, a
	ld a, HIGH(NPCHeaderPointers)
	adc 0
	ld h, a
	ld a, [hli]
	ld h, [hl]
	ld l, a
	ret


; preserves all registers except af
; input:
;	a = NPC ID (NPC_* constant)
LoadNPCSpriteData:
	push hl
	push bc
	call GetNPCHeaderPointer
	ld a, [hli]
	ld [wTempNPC], a
	ld a, [hli]
	ld [wNPCSpriteID], a
	ld a, [hli]
	ld [wNPCAnim], a
	ld a, [hli]
	push af
	ld a, [hli]
	ld [wNPCAnimFlags], a
	pop bc
	ld a, [wConsole]
	cp CONSOLE_CGB
	jr nz, .not_cgb
	ld a, b
	ld [wNPCAnim], a
.not_cgb
	pop bc
	pop hl
	ret


; preserves de and hl
; input:
;	a = NPC ID (NPC_* constant)
; output:
;	bc = pointer for the script
;	[wCurrentNPCNameTx] = name of the NPC from input
GetNPCNameAndScript:
	push hl
	call GetNPCHeaderPointer
	ld bc, NPC_DATA_SCRIPT_PTR
	add hl, bc
	ld c, [hl]
	inc hl
	ld b, [hl]
	inc hl
	ld a, [hli]
	ld [wCurrentNPCNameTx], a
	ld a, [hli]
	ld [wCurrentNPCNameTx + 1], a
	pop hl
	ret


; sets the text box header to the name of the NPC with ID in register a
; preserves all registers except af
; input:
;	a = NPC ID (NPC_* constant)
SetNPCDialogName:
	push hl
	push bc
	call GetNPCHeaderPointer
	ld bc, NPC_DATA_NAME_TEXT
	add hl, bc
	ld a, [hli]
	ld [wCurrentNPCNameTx], a
	ld a, [hli]
	ld [wCurrentNPCNameTx + 1], a
	pop bc
	pop hl
	ret


; sets the opponent's name and portrait for the NPC with ID in register a
; preserves all registers except af
; input:
;	a = NPC ID (NPC_* constant)
SetNPCOpponentNameAndPortrait:
	push hl
	push bc
	call GetNPCHeaderPointer
	ld bc, NPC_DATA_NAME_TEXT
	add hl, bc
	ld a, [hli]
	ld [wOpponentName], a
	ld a, [hli]
	ld [wOpponentName + 1], a
	ld a, [hli]
	ld [wOpponentPortrait], a
	pop bc
	pop hl
	ret


; sets the deck ID and duel theme for the NPC with ID in register a
; preserves all registers except af
; input:
;	a = NPC ID (NPC_* constant)
SetNPCDeckIDAndDuelTheme:
	push hl
	push bc
	call GetNPCHeaderPointer
	ld bc, NPC_DATA_DECK_ID
	add hl, bc
	ld a, [hli]
	ld [wNPCDuelDeckID], a
	ld a, [hli]
	ld [wDuelTheme], a
	pop bc
	pop hl
	ret


; sets the start theme for the NPC with ID in register a
; preserves all registers except af
; input:
;	a = NPC ID (NPC_* constant)
SetNPCMatchStartTheme:
	push hl
	push bc
	push af
	call GetNPCHeaderPointer
	ld bc, NPC_DATA_MATCH_START_ID
	add hl, bc
	ld a, [hli]
	ld [wMatchStartTheme], a
	pop af
	cp NPC_RONALD1
	jr nz, .not_ronald_final_duel
	ld a, [wCurMap]
	cp POKEMON_DOME
	jr nz, .not_ronald_final_duel
	ld a, MUSIC_MATCH_START_3
	ld [wMatchStartTheme], a

.not_ronald_final_duel
	pop bc
	pop hl
	ret


INCLUDE "data/npcs.asm"


; preserves bc and de
; input:
;	[wNPCDuelDeckID] = deck ID (*_DECK constant)
_GetChallengeMachineDuelConfigurations:
	push bc
	push de
	ld a, [wNPCDuelDeckID]
	ld e, a
	ld bc, 9 ; size of struct - 1
	ld hl, DeckIDDuelConfigurations
.loop_deck_ids
	ld a, [hli]
	cp -1 ; end of list?
	jr z, .done
	cp e
	jr nz, .next_deck_id
	push hl
	ld a, [hli]
	ld [wOpponentPortrait], a
	ld a, [hli]
	ld [wOpponentName], a
	ld a, [hli]
	ld [wOpponentName + 1], a
	inc hl
	ld a, [hli]
	ld [wDuelTheme], a
	pop hl
	dec hl
	scf
.done
	pop de
	pop bc
	ret
.next_deck_id
	add hl, bc
	jr .loop_deck_ids


;----------------------------------------
;        UNREFERENCED FUNCTIONS
;----------------------------------------
;
; loads some configurations for the duel against
; the NPC whose deck ID is stored in wNPCDuelDeckID.
; this includes NPC portrait, his/her name text ID, and the number of prize cards.
; this was used in testing since these configurations
; are stored in the script-related NPC data for normal gameplay.
; preserves all registers except af
; input:
;	[wNPCDuelDeckID] = NPC's deck ID (*_DECK constant)
; output:
;	carry = set:  if a duel configuration was found for the given NPC deck ID
;_GetNPCDuelConfigurations::
;	push hl
;	push bc
;	push de
;	ld a, [wNPCDuelDeckID]
;	ld e, a
;	ld bc, 9 ; size of struct - 1
;	ld hl, DeckIDDuelConfigurations
;.loop_deck_ids
;	ld a, [hli]
;	cp -1 ; end of list?
;	jr z, .done
;	cp e
;	jr nz, .next_deck_id
;	ld a, [hli]
;	ld [wOpponentPortrait], a
;	ld a, [hli]
;	ld [wOpponentName], a
;	ld a, [hli]
;	ld [wOpponentName + 1], a
;	ld a, [hl]
;	ld [wNPCDuelPrizes], a
;	scf
;.done
;	pop de
;	pop bc
;	pop hl
;	ret
;.next_deck_id
;	add hl, bc
;	jr .loop_deck_ids
