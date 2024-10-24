; preserves all registers except af
; input:
;	a = number to divide by 2
; output:
;	a /= 2 (rounded up)
HalfARoundedUp::
	srl a
	bit 0, a
	ret z  ; no need for rounding
	add 5  ; round up to nearest 10
	ret


; divides BC by DE. Stores result in BC and remainder in HL
; input:
;	bc = dividend
;	de = divisor
; output:
;	bc = quotient
;	hl = remainder from the division
DivideBCbyDE::
	ld hl, $0000
	rl c
	rl b
	ld a, $10
.asm_3c63
	ldh [hffb6], a
	rl l
	rl h
	push hl
	ld a, l
	sub e
	ld l, a
	ld a, h
	sbc d
	ccf
	jr nc, .asm_3c78
	ld h, a
	add sp, $2
	scf
	jr .asm_3c79
.asm_3c78
	pop hl
.asm_3c79
	rl c
	rl b
	ldh a, [hffb6]
	dec a
	jr nz, .asm_3c63
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


; preserves bc and de
; input:
;	h & l = factors
; output:
;	hl = h * l
HtimesL::
	push de
	ld a, h
	ld e, l
	ld d, $0
	ld l, d
	ld h, d
	jr .asm_887
.asm_882
	add hl, de
.asm_883
	sla e
	rl d
.asm_887
	srl a
	jr c, .asm_882
	jr nz, .asm_883
	pop de
	ret


;----------------------------------------
;        UNREFERENCED FUNCTIONS
;----------------------------------------
;
; unreferenced counterpart of ATimes10 that would be used if
; the product could exceed 255, thus requiring 2 bytes/registers
; preserves bc and de
; input:
;	a = number to multiply by 10
; output:
;	hl = a*10
;HLTimes10::
;	push de
;	ld l, a
;	ld e, a
;	ld h, $00
;	ld d, h
;	add hl, hl
;	add hl, hl
;	add hl, de
;	add hl, hl
;	pop de
;	ret
;
;
; preserves all registers except af
; input:
;	a = number to divide by 10
; output:
;	a /= 10
;	carry = set:  if a % 10 >= 5
;ADividedBy10::
;	push de
;	ld e, -1
;.loop
;	inc e
;	sub 10
;	jr nc, .loop
;	add 5
;	ld a, e
;	pop de
;	ret
;
;
; unreferenced counterpart of HalfARoundedUp
; preserves all registers except af
; output:
;	a /= 2 (rounded down)
;HalfARoundedDown::
;	srl a
;	bit 0, a
;	ret z  ; no need for rounding
;	sub 5  ; round down to nearest 10
;	ret

