; sets up to start a link duel
; decides which device will pick the number of prizes
; then exchanges names and duels between the players
; and starts the main duel routine
SetUpAndStartLinkDuel::
	ld hl, sp+$00
	ld a, l
	ld [wDuelReturnAddress + 0], a
	ld a, h
	ld [wDuelReturnAddress + 1], a
	call SetSpriteAnimationsAsVBlankFunction

	ld a, SCENE_GAMEBOY_LINK_TRANSMITTING
	lb bc, 0, 0
	call LoadScene

	bank1call LoadPlayerDeck
	call SwitchToCGBNormalSpeed
	call DecideLinkDuelVariables
	push af
	call RestoreVBlankFunction
	pop af
	jp c, .error

	ld a, DUELIST_TYPE_PLAYER
	ld [wPlayerDuelistType], a
	ld a, DUELIST_TYPE_LINK_OPP
	ld [wOpponentDuelistType], a
	ld a, DUELTYPE_LINK
	ld [wDuelType], a

	call EmptyScreen
	ld a, [wSerialOp]
	cp $29
	jr nz, .asm_1a540

	ld a, PLAYER_TURN
	ldh [hWhoseTurn], a
	call .ExchangeNamesAndDecks
	jr c, .error
	lb de, 6, 2
	lb bc, 8, 6
	call DrawRegularTextBox
	lb de, 7, 4
	ldtx hl, PrizesCardsText
	call InitTextPrinting_ProcessTextFromID
	ldtx hl, ChooseTheNumberOfPrizesText
	call DrawWideTextBox_PrintText
	call EnableLCD
	call .PickNumberOfPrizeCards
	ld a, [wNPCDuelPrizes]
	call SerialSend8Bytes
	jr .prizes_decided

.asm_1a540
	ld a, OPPONENT_TURN
	ldh [hWhoseTurn], a
	call .ExchangeNamesAndDecks
	jr c, .error
	ldtx hl, PleaseWaitDecidingNumberOfPrizesText
	call DrawWideTextBox_PrintText
	call EnableLCD
	call SerialRecv8Bytes
	ld [wNPCDuelPrizes], a

.prizes_decided
	call ExchangeRNG
	ld a, LINK_OPP_PIC
	ld [wOpponentPortrait], a
	ldh a, [hWhoseTurn]
	push af
	call EmptyScreen
	call SetDefaultConsolePalettes
	ld a, SHUFFLE_DECK
	ld [wDuelDisplayedScreen], a
	bank1call DrawDuelistPortraitsAndNames
	ld a, OPPONENT_TURN
	ldh [hWhoseTurn], a
	ld a, [wNPCDuelPrizes]
	ld hl, wTxRam3
	ld [hli], a
	xor a
	ld [hl], a
	ldtx hl, BeginAPrizeDuelWithText
	call DrawWideTextBox_WaitForInput
	pop af
	ldh [hWhoseTurn], a
	call ExchangeRNG
	bank1call StartDuel_VSLinkOpp
	jp SwitchToCGBDoubleSpeed

.error
	ld a, -1
	ld [wDuelResult], a
	call SetSpriteAnimationsAsVBlankFunction

	ld a, SCENE_GAMEBOY_LINK_NOT_CONNECTED
	lb bc, 0, 0
	call LoadScene

	ldtx hl, TransmissionErrorText
	call DrawWideTextBox_WaitForInput
	call RestoreVBlankFunction
	call ResetSerial
	ret

.ExchangeNamesAndDecks
	ld de, wDefaultText
	call CopyPlayerName
	ld hl, wDefaultText
	ld de, wNameBuffer
	ld c, NAME_BUFFER_LENGTH
	call SerialExchangeBytes
	ret c
	xor a
	ld hl, wOpponentName
	ld [hli], a
	ld [hl], a
	ld hl, wPlayerDeck
	ld de, wOpponentDeck
	ld c, DECK_SIZE
	call SerialExchangeBytes
	ret

; handles player choice of number of prize cards
; pressing left/right makes it decrease/increase respectively
; selection is confirmed by pressing A button
.PickNumberOfPrizeCards
	ld a, PRIZES_4
	ld [wNPCDuelPrizes], a
	xor a
	ld [wPrizeCardSelectionFrameCounter], a
.loop_input
	call DoFrame
	ld a, [wNPCDuelPrizes]
	add SYM_0
	ld e, a
	; check frame counter so that it
	; either blinks or shows number
	ld hl, wPrizeCardSelectionFrameCounter
	ld a, [hl]
	inc [hl]
	and $10
	jr z, .no_blink
	ld e, SYM_SPACE
.no_blink
	ld a, e
	lb bc, 9, 6
	call WriteByteToBGMap0

	ldh a, [hDPadHeld]
	ld b, a
	ld a, [wNPCDuelPrizes]
	bit B_PAD_LEFT, b
	jr z, .check_d_right
	dec a
	cp PRIZES_2
	jr nc, .got_prize_count
	ld a, PRIZES_6 ; wrap around to 6
	jr .got_prize_count

.check_d_right
	bit B_PAD_RIGHT, b
	jr z, .check_a_btn
	inc a
	cp PRIZES_6 + 1
	jr c, .got_prize_count
	ld a, PRIZES_2
.got_prize_count
	ld [wNPCDuelPrizes], a
	xor a
	ld [wPrizeCardSelectionFrameCounter], a

.check_a_btn
	bit B_PAD_A, b
	jr z, .loop_input
	ret


; seems to communicate with another device for starting a duel
; output:
;	hl = wPlayerDuelVariables:   if [wSerialOp] = $29
;	hl = wOpponentDuelVariables: if [wSerialOp] = $12
;	carry = set:  if the link transfer was cancelled
DecideLinkDuelVariables:
	call Func_0e8e
	ldtx hl, PressStartWhenReadyText
	call DrawWideTextBox_PrintText
	call EnableLCD
.input_loop
	call DoFrame
	ldh a, [hKeysPressed]
	bit B_PAD_B, a
	jr nz, .link_cancel
	and PAD_START
	call Func_0cc5
	jr nc, .input_loop
	ld hl, wPlayerDuelVariables
	ld a, [wSerialOp]
	cp $29
	jr z, .link_continue
	ld hl, wOpponentDuelVariables
	cp $12
	jr z, .link_continue
.link_cancel
	call ResetSerial
	scf
	ret
.link_continue
	or a
	ret


; output:
;	carry = set:  if ???
Func_0cc5:
	ld hl, wSerialRecvCounter
	or a
	jr nz, .asm_cdc
	ld a, [hl]
	or a
	ret z
	ld [hl], $00
	ld a, [wSerialRecvBuf]
	ld e, $12
	cp $29
	jr z, .asm_cfa
	xor a
	scf
	ret

.asm_cdc
	ld a, $29
	ldh [rSB], a
	ld a, SC_INTERNAL
	ldh [rSC], a
	ld a, SC_START | SC_INTERNAL
	ldh [rSC], a
.asm_ce8
	ld a, [hl]
	or a
	jr z, .asm_ce8
	ld [hl], $00
	ld a, [wSerialRecvBuf]
	ld e, $29
	cp $12
	jr z, .asm_cfa
	xor a
	scf
	ret

.asm_cfa
	xor a
	ld [wSerialSendBufIndex], a
	ld [wcb80], a
	ld [wSerialSendBufToggle], a
	ld [wSerialSendSave], a
	ld [wcba3], a
	ld [wSerialRecvIndex], a
	ld [wSerialRecvCounter], a
	ld [wSerialLastReadCA], a
	ld a, e
	cp $29
	jr nz, .asm_d21
	ld bc, $800
.asm_d1b
	dec bc
	ld a, c
	or b
	jr nz, .asm_d1b
	ld a, e
.asm_d21
	ld [wSerialOp], a
	scf
	ret


; enters slave mode (external clock) for serial transfer?
; preserves de
Func_0e8e::
	call ClearSerialData
	ld a, $12
	ldh [rSB], a         ; send $12
	ld a, SC_START | SC_EXTERNAL
	ldh [rSC], a         ; use external clock, set transfer start flag
	ldh a, [rIF]
	and ~IE_SERIAL
	ldh [rIF], a         ; clear serial interrupt flag
	ldh a, [rIE]
	or IE_SERIAL         ; enable serial interrupt
	ldh [rIE], a
	ret
