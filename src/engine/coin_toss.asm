; input:
;	a = number of coin tosses to perform
;	[wCoinTossScreenTextID] = text ID for the relevant text to print (2 bytes)
; output:
;	carry = set:  if there was at least one heads
;	[wCoinTossNumHeads] & a = number of heads
_TossCoin::
	ld [wCoinTossTotalNum], a
	ld a, [wDuelDisplayedScreen]
	cp COIN_TOSS
	jr z, .print_text
	xor a
	ld [wCoinTossNumTossed], a
	call EmptyScreen
	call LoadDuelCoinTossResultTiles

.print_text
; no need to print text if this is not the first coin toss
	ld a, [wCoinTossNumTossed]
	or a
	jr nz, .clear_text_pointer
	ld a, COIN_TOSS
	ld [wDuelDisplayedScreen], a
	lb de, 0, 12
	lb bc, 20, 6
	ld hl, $0000
	call DrawLabeledTextBox
	call EnableLCD
	lb de, 1, 14
	ld a, 19
	call InitTextPrintingInTextbox
	ld hl, wCoinTossScreenTextID
	ld a, [hli]
	ld h, [hl]
	ld l, a
	call PrintText

.clear_text_pointer
	ld hl, wCoinTossScreenTextID
	xor a
	ld [hli], a
	ld [hl], a

; store duelist type and reset number of heads
	call EnableLCD
	ld a, DUELVARS_DUELIST_TYPE
	get_turn_duelist_var
	ld [wCoinTossDuelistType], a
	call ExchangeRNG
	xor a
	ld [wCoinTossNumHeads], a

.print_coin_tally
; skip printing text if it's only one coin toss
	ld a, [wCoinTossTotalNum]
	cp 2
	jr c, .skip_printing_indicator

; write "#coin/#total coins"
	ld a, [wCoinTossTotalNum]
	lb bc, 18, 11
	call TwoDigitNumberToTxSymbol
	ld a, [hl]
	cp SYM_0
	jr nz, .two_digits
	ld [hl], SYM_SLASH
	ld a, 2
	call CopyDataToBGMap0
	jr .current_item_number
.two_digits
	ld a, 2
	call CopyDataToBGMap0
	dec b
	ld a, SYM_SLASH
	call WriteByteToBGMap0
.current_item_number
	dec b
	dec b
	ld a, [wCoinTossNumTossed]
	inc a ; current coin number is wCoinTossNumTossed + 1
	call TwoDigitNumberToTxSymbol_TrimLeadingZero
	ld a, 2
	call CopyDataToBGMap0
.skip_printing_indicator
	call ResetAnimationQueue
	ld a, DUEL_ANIM_COIN_SPIN
	call PlayDuelAnimation

	ld a, [wCoinTossDuelistType]
	or a
	jr z, .asm_7236
	call Func_7324
	jr .asm_723c

.asm_7236
	call WaitForWideTextBoxInput
	call Func_72ff

.asm_723c
	call ResetAnimationQueue
	ld d, DUEL_ANIM_COIN_TOSS2
	ld e, $0 ; tails
	call UpdateRNGSources
	rra
	jr c, .got_result
	ld d, DUEL_ANIM_COIN_TOSS1
	ld e, $1 ; heads

.got_result
; already decided on coin toss result,
; load the correct tossing animation
; and wait for it to finish
	ld a, d
	call PlayDuelAnimation
	ld a, [wCoinTossDuelistType]
	or a
	jr z, .wait_anim
	ld a, e
	call Func_7310
	ld e, a
	jr .done_toss_anim
.wait_anim
	call WaitForAnimationToFinish_AllowSkipDelay
	ld a, e
	call Func_72ff

.done_toss_anim
	ld b, DUEL_ANIM_COIN_HEADS
	ld c, $34 ; tile for cross
	ld a, e
	or a
	jr z, .show_result
	ld b, DUEL_ANIM_COIN_TAILS
	ld c, $30 ; tile for circle
	ld hl, wCoinTossNumHeads
	inc [hl]

.show_result
	ld a, b
	call PlayDuelAnimation

; load correct sound effect
; the sound of the coin toss result
; is dependant on whether it was the Player
; or the Opponent to get heads/tails
	ld a, [wCoinTossDuelistType]
	or a
	jr z, .check_sfx
	ld a, $1
	xor e ; invert result in case it's not Player
	ld e, a
.check_sfx
	ld d, SFX_COIN_TOSS_HEADS
	ld a, e
	or a
	jr nz, .got_sfx
	ld d, SFX_COIN_TOSS_TAILS
.got_sfx
	ld a, d
	call PlaySFX

; in case it's a multiple coin toss scenario,
; then the result needs to be registered on screen
; with a circle (o) or a cross (x)
	ld a, [wCoinTossTotalNum]
	dec a
	jr z, .incr_num_coin_tossed ; skip if not more than 1 coin toss
	ld a, c
	push af
	ld e, 0
	ld a, [wCoinTossNumTossed]
; calculate the offset to draw the circle/cross
.asm_72a3
	; if < 10, then the offset is simply calculated
	; from wCoinTossNumTossed * 2...
	cp 10
	jr c, .got_offset
	; ...else the y-offset is added for each multiple of 10
	inc e
	inc e
	sub 10
	jr .asm_72a3

.got_offset
	add a
	ld d, a
	lb bc, 2, 2
	lb hl, 1, 2
	pop af
	call FillRectangle

.incr_num_coin_tossed
	ld hl, wCoinTossNumTossed
	inc [hl]

	ld a, [wCoinTossDuelistType]
	or a
	jr z, .asm_72dc
	ld a, [hl]
	ld hl, wCoinTossTotalNum
	cp [hl]
	call z, WaitForWideTextBoxInput
	call Func_7324
	ld a, [wCoinTossTotalNum]
	ld hl, wCoinTossNumHeads
	or [hl]
	call z, WaitForWideTextBoxInput
	jr .asm_72e2

.asm_72dc
	call WaitForWideTextBoxInput
	call Func_72ff

.asm_72e2
	call FinishQueuedAnimations
	ld a, [wCoinTossNumTossed]
	ld hl, wCoinTossTotalNum
	cp [hl]
	jp c, .print_coin_tally ; proceed with next coin toss
	call ExchangeRNG
	call FinishQueuedAnimations
	call ResetAnimationQueue

; return carry if at least 1 heads
	ld a, [wCoinTossNumHeads]
	or a
	ret z
	scf
	ret


Func_72ff:
	ldh [hff96], a
	ld a, [wDuelType]
	cp DUELTYPE_LINK
	ret nz
	ldh a, [hff96]
	call SerialSendByte
	jr Func_7344


Func_7310:
	ldh [hff96], a
	ld a, [wDuelType]
	cp DUELTYPE_LINK
	jr z, Func_7338
	call WaitForAnimationToFinish_AllowSkipDelay
	ldh a, [hff96]
	ret


Func_7324:
	ldh [hff96], a
	ld a, [wDuelType]
	cp DUELTYPE_LINK
	jr z, Func_7338

; delay coin flip for AI opponent
	ld a, 30 ; frames to delay
	call WaitAFrames_AllowSkipDelay
	ldh a, [hff96]
	ret


Func_7338:
	call DoFrame
	call SerialRecvByte
	jr c, Func_7338
;	fallthrough

; preserves af
Func_7344:
	push af
	ld a, [wSerialFlags]
	or a
	jr nz, .asm_734d
	pop af
	ret

.asm_734d
	call FinishQueuedAnimations
	jp DuelTransmissionError
