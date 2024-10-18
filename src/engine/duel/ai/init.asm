; preserves bc and de
InitAIDuelVars:
	ld a, wAIDuelVarsEnd - wAIDuelVars
	ld hl, wAIDuelVars
	call ClearMemory_Bank5
	ld a, 5
	ld [wAIPokedexCounter], a
	ld a, $ff
	ld [wAIPeekedPrizes], a
	ret


; initializes some variables and sets value of wAIBarrierFlagCounter.
; if Player uses Barrier 3 times in a row, AI checks if Player's deck
; has only MewtwoLv53 Pokémon cards (running a MewtwoLv53 mill deck).
; preserves bc
InitAITurnVars:
; increase Pokedex counter by 1
	ld a, [wAIPokedexCounter]
	inc a
	ld [wAIPokedexCounter], a

	xor a
	ld [wPreviousAIFlags], a
	ld [wAITriedAttack], a
	ld [wcddc], a
	ld [wAIRetreatedThisTurn], a

; checks if the Player used an attack last turn
; and if it was the second attack of their card.
	ld a, [wPlayerAttackingAttackIndex]
	cp $ff
	jr z, .check_flag
	or a
	jr z, .check_flag
	ld a, [wPlayerAttackingCardIndex]
	cp $ff
	jr z, .check_flag

; if the card is MewtwoLv53, it means the Player
; used its second attack, Barrier.
	rst SwapTurn
	call _GetCardIDFromDeckIndex
	rst SwapTurn
	cp MEWTWO_LV53
	jr nz, .check_flag
	; Player used Barrier last turn

; check if flag was already set, if so,
; reset wAIBarrierFlagCounter to $80.
	ld a, [wAIBarrierFlagCounter]
	bit AI_MEWTWO_MILL_F, a
	jr nz, .set_flag

; if not, increase it by 1 and check if it exceeds 2.
	inc a
	ld [wAIBarrierFlagCounter], a
	cp 3
	ret c

; this means that the Player used Barrier at least 3 turns in a row.
; check if the opponent is using a deck with no Pokémon other than MewtwoLv53,
; and if so, set the wAIBarrierFlagCounter flag.
	rst SwapTurn
	ld a, DUELVARS_ARENA_CARD
	get_turn_duelist_var
	call _GetCardIDFromDeckIndex
	rst SwapTurn
	cp MEWTWO_LV53
	jr nz, .reset
	farcall CheckIfPlayerHasPokemonOtherThanMewtwoLv53
	jr nc, .set_flag
.reset
; reset wAIBarrierFlagCounter
	xor a
	ld [wAIBarrierFlagCounter], a
	ret

.set_flag
	ld a, AI_MEWTWO_MILL
	ld [wAIBarrierFlagCounter], a
	ret

.check_flag
; increase counter by 1 if flag is set
	ld a, [wAIBarrierFlagCounter]
	bit AI_MEWTWO_MILL_F, a
	jr z, .reset
	inc a
	ld [wAIBarrierFlagCounter], a
	ret
