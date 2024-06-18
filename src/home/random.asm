; preserves all registers except af
; input:
;	a = highest possible number to consider
; output:
;	a = random number between 0 and a (exclusive)
Random::
	push hl
	ld h, a
	call UpdateRNGSources
	ld l, a
	call HtimesL
	ld a, h
	pop hl
	ret


; gets the next random numbers of the wRNG1 and wRNG2 sequences
; preserves all registers except af
UpdateRNGSources::
	push hl
	push de
	ld hl, wRNG1
	ld a, [hli]
	ld d, [hl] ; wRNG2
	inc hl
	ld e, a
	ld a, d
	rlca
	rlca
	xor e
	rra
	push af
	ld a, d
	xor e
	ld d, a
	ld a, [hl] ; wRNGCounter
	xor e
	ld e, a
	pop af
	rl e
	rl d
	ld a, d
	xor e
	inc [hl] ; wRNGCounter
	dec hl
	ld [hl], d ; wRNG2
	dec hl
	ld [hl], e ; wRNG1
	pop de
	pop hl
	ret
