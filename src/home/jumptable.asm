; input:
;	a = index of the entry in the table to jump to
;	hl = pointer table to use
JumpToFunctionInTable::
	add a
	add l
	ld l, a
	ld a, $0
	adc h
	ld h, a
	ld a, [hli]
	ld h, [hl]
	ld l, a
	jp hl


; calls the function at [hl], if non-NULL
CallIndirect::
	push af
	ld a, [hli]
	ld h, [hl]
	ld l, a
	or h
	jr nz, .call_hl
	pop af
	ret
.call_hl
	pop af
;	fallthrough

; jumps to the address pointed to by the hl register
CallHL::
	jp hl
