; empties screen and replaces wVBlankFunctionTrampoline with HandleAllSpriteAnimations
SetSpriteAnimationsAsVBlankFunction:
	call EmptyScreen
	call Set_OBJ_8x8
	call ClearSpriteAnimations
	lb de, $38, $7f
	call SetupText
	ld hl, wVBlankFunctionTrampoline + 1
	ld de, wVBlankFunctionTrampolineBackup
	call BackupVBlankFunctionTrampoline
	di
	ld [hl], LOW(HandleAllSpriteAnimations)
	inc hl
	ld [hl], HIGH(HandleAllSpriteAnimations)
	reti


; sets backup VBlank function as wVBlankFunctionTrampoline
RestoreVBlankFunction:
	ld hl, wVBlankFunctionTrampolineBackup
	ld de, wVBlankFunctionTrampoline + 1
	call BackupVBlankFunctionTrampoline
	call ClearSpriteAnimations
	jp ZeroObjectPositionsAndToggleOAMCopy


; copies 2 bytes from hl to de while interrupts are disabled
; used to load or store wVBlankFunctionTrampoline to wVBlankFunctionTrampolineBackup
; preserves bc
; input:
;	hl = address from which to start copying the data
;	de = where to copy the data
BackupVBlankFunctionTrampoline:
	di
	ld a, [hli]
	ld [de], a
	inc de
	ld a, [hld]
	ld [de], a
	reti
