; sets current dest VRAM bank to 0
; preserves all registers
BankswitchVRAM0::
	push af
	xor a
	ldh [hBankVRAM], a
	ldh [rVBK], a
	pop af
	ret


; sets current dest VRAM bank to 1
; preserves all registers
BankswitchVRAM1::
	push af
	ld a, $1
	ldh [hBankVRAM], a
	ldh [rVBK], a
	pop af
	ret
