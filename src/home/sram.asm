; switches SRAM bank to a
; preserves all registers
; input:
;	a = SRAM bank to use
BankswitchSRAM::
	push af
	ldh [hBankSRAM], a
	ld [MBC3SRamBank], a
	ld a, SRAM_ENABLE
	ld [MBC3SRamEnable], a
	pop af
	ret


; enables external RAM (SRAM)
; preserves all registers
EnableSRAM::
	push af
	ld a, SRAM_ENABLE
	ld [MBC3SRamEnable], a
	pop af
	ret


; disables external RAM (SRAM)
; preserves all registers
DisableSRAM::
	push af
	xor a ; SRAM_DISABLE
	ld [MBC3SRamEnable], a
	pop af
	ret
