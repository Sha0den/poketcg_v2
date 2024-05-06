; returns a *= 10
ATimes10::
	push de
	ld e, a
	add a
	add a
	add e
	add a
	pop de
	ret

; returns hl *= 10
HLTimes10::
	push de
	ld l, a
	ld e, a
	ld h, $00
	ld d, h
	add hl, hl
	add hl, hl
	add hl, de
	add hl, hl
	pop de
	ret

; returns a /= 10
; returns carry if a % 10 >= 5
ADividedBy10::
	push de
	ld e, -1
.asm_c62
	inc e
	sub 10
	jr nc, .asm_c62
	add 5
	ld a, e
	pop de
	ret

; returns a /= 2 rounded up
HalfARoundedUp::
	srl a
	bit 0, a
	ret z  ; rounded
	add 5  ; round up to nearest 10
	ret

; unreferenced counterpart of HalfARoundedUp
; returns a /= 2 rounded down
;HalfARoundedDown::
;	srl a
;	bit 0, a
;	ret z  ; rounded
;	sub 5  ; round down to nearest 10
;	ret
