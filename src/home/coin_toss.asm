; executes a single coin toss during a duel.
; text at de is printed in a text box during the coin toss.
; preserves hl
; input:
;	de = text ID for the relevant text to print
; output:
;	a & [wCoinTossNumHeads] = 0:  if the result was tails
;	                        = 1:  if the result was heads
;	carry = set:  if the result was heads
TossCoin::
	ld a, 1
;	fallthrough

; executes one or more consecutive coin tosses during a duel,
; displaying each result ([O] or [X]), starting from the top left corner of the screen.
; text at de is printed in a text box during the coin toss.
; preserves hl
; input:
;	a = number of coin tosses
;	de = text ID for the relevant text to print
; output:
;	a & [wCoinTossNumHeads] = number of heads that were flipped
;	carry = set:  if there was at least one heads
TossCoinATimes::
	push hl
	ld hl, wCoinTossScreenTextID
	ld [hl], e
	inc hl
	ld [hl], d
	farcall _TossCoin
	ld hl, wDuelDisplayedScreen
	ld [hl], 0
	pop hl
	ret
