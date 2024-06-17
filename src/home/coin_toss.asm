; executes one or more consecutive coin tosses during a duel,
; displaying each result ([O] or [X]), starting from the top left corner of the screen.
; text at de is printed in a text box during the coin toss.
; preserves hl
; input:
;	a = number of coin tosses
;	de = text ID for the relevant text to print
; output:
;	carry = set:  if there was at least one heads
;	[wCoinTossNumHeads] & a = number of heads
TossCoinATimes::
	push hl
	ld hl, wCoinTossScreenTextID
	ld [hl], e
	inc hl
	ld [hl], d
	bank1call _TossCoin
	pop hl
	ret


; executes a single coin toss during a duel.
; text at de is printed in a text box during the coin toss.
; preserves hl
; input:
;	de = text ID for the relevant text to print
; output:
;	carry = set: result was heads
;	[wCoinTossNumHeads] & a = 1: result was heads
;	[wCoinTossNumHeads] & a = 0: result was tails
TossCoin::
	push hl
	ld hl, wCoinTossScreenTextID
	ld [hl], e
	inc hl
	ld [hl], d
	ld a, 1
	bank1call _TossCoin
	ld hl, wDuelDisplayedScreen
	ld [hl], 0
	pop hl
	ret


; cp de, bc
; preserves all registers except af
CompareDEtoBC::
	ld a, d
	cp b
	ret nz
	ld a, e
	cp c
	ret
