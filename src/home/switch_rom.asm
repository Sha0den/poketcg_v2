; switches to rombank (a + top2 of h shifted down),
; set top2 of h to 01 (switchable ROM bank area),
; returns old rombank ID on top-of-stack
; preserves all registers
; input:
;	a/h/l = used to figure out which ROM bank to switch to
BankpushROM::
	push hl
	push bc
	push af
	push de
	ld e, l
	ld d, h
	ld hl, sp+$9
	ld b, [hl]
	dec hl
	ld c, [hl]
	dec hl
	ld [hl], b
	dec hl
	ld [hl], c
	ld hl, sp+$9
	ldh a, [hBankROM]
	ld [hld], a
	ld [hl], $0
	ld a, d
	rlca
	rlca
	and $3
	ld b, a
	res 7, d
	set 6, d ; $4000 ≤ de ≤ $7fff
	ld l, e
	ld h, d
	pop de
	pop af
	add b
	rst BankswitchROM
	pop bc
	ret


; switches to rombank a,
; returns old rombank ID on top-of-stack
; preserves all registers
; input:
;	a = ROM bank to switch to
BankpushROM2::
	push hl
	push bc
	push af
	push de
	ld e, l
	ld d, h
	ld hl, sp+$9
	ld b, [hl]
	dec hl
	ld c, [hl]
	dec hl
	ld [hl], b
	dec hl
	ld [hl], c
	ld hl, sp+$9
	ldh a, [hBankROM]
	ld [hld], a
	ld [hl], $0
	ld l, e
	ld h, d
	pop de
	pop af
	rst BankswitchROM
	pop bc
	ret


; restores rombank from top-of-stack
; preserves all registers except af
BankpopROM::
	push hl
	push de
	ld hl, sp+$7
	ld a, [hld]
	rst BankswitchROM
	dec hl
	ld d, [hl]
	dec hl
	ld e, [hl]
	inc hl
	inc hl
	ld [hl], e
	inc hl
	ld [hl], d
	pop de
	pop hl
	pop af
	ret
