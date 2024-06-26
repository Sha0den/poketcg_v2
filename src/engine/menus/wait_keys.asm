; preserves all registers except af
; input:
;	a = keys to escape
WaitUntilKeysArePressed:
	push bc
	ld b, a
.loop_input
	call DoFrameIfLCDEnabled
	ldh a, [hKeysPressed]
	and b
	jr z, .loop_input
	pop bc
	ret
