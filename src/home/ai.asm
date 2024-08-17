; All of these functions can only be used from the home bank.
; If moved to another bank, the game will crash.

AIDoAction_Turn::
	ld a, AIACTION_DO_TURN
	jr AIDoAction

AIDoAction_StartDuel::
	ld a, AIACTION_START_DUEL
	jr AIDoAction

AIDoAction_ForcedSwitch::
	ld a, AIACTION_FORCED_SWITCH
	call AIDoAction
	ldh [hTempPlayAreaLocation_ff9d], a
	ret

AIDoAction_KOSwitch::
	ld a, AIACTION_KO_SWITCH
	call AIDoAction
	ldh [hTemp_ffa0], a
	ret

AIDoAction_TakePrize::
	ld a, AIACTION_TAKE_PRIZE
;	fallthrough

; calls the appropriate AI routine to handle action,
; depending on the deck ID (see engine/duel/ai/deck_ai.asm)
; input:
;	- a = AIACTION_* constant
AIDoAction::
	ld c, a

; load bank for Opponent Deck pointer table
	ldh a, [hBankROM]
	push af
	ld a, BANK(DeckAIPointerTable)
	rst BankswitchROM

; load hl with the corresponding pointer
	ld a, [wOpponentDeckID]
	ld l, a
	ld h, $0
	add hl, hl ; two bytes per deck
	ld de, DeckAIPointerTable
	add hl, de
	ld a, [hli]
	ld h, [hl]
	ld l, a

	ld a, c
	or a
	jr nz, .not_zero

; if input was 0, copy deck data of turn player
	ld e, [hl]
	inc hl
	ld d, [hl]
	call CopyDeckData
	jr .done

; jump to corresponding AI routine related to input
.not_zero
	call JumpToFunctionInTable

.done
	ld c, a
	pop af
	rst BankswitchROM
	ld a, c
	ret
