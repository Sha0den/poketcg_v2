; switches SRAM bank to a
; preserves all registers
; input:
;	a = SRAM bank to use
BankswitchSRAM::
	push af
	ldh [hBankSRAM], a
	ld [rRAMB], a
	ld a, RAMG_SRAM_ENABLE
	ld [rRAMG], a
	pop af
	ret


; enables external RAM (SRAM)
; preserves all registers
EnableSRAM::
	push af
	ld a, RAMG_SRAM_ENABLE
	ld [rRAMG], a
	pop af
	ret


; disables external RAM (SRAM)
; preserves all registers
DisableSRAM::
	push af
	xor a ; RAMG_SRAM_DISABLE
	ld [rRAMG], a
	pop af
	ret
