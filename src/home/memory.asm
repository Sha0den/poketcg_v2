; gets far byte a:hl
; preserves all registers
; output:
;	a = byte that was retrieved
GetFarByte::
	push hl
	push af
	ldh a, [hBankROM]
	push af
	push hl
	ld hl, sp+$05
	ld a, [hl]
	rst BankswitchROM
	pop hl
	ld a, [hl]
	ld hl, sp+$03
	ld [hl], a
	pop af
	rst BankswitchROM
	pop af
	pop hl
	ret
