; decompresses data from a given bank
; uses values initialized by InitDataDecompression
; preserves de and hl
; input:
;	bc = buffer length
;	de = buffer to place decompressed data
DecompressDataFromBank::
	ldh a, [hBankROM]
	push af
	ld a, [wTempPointerBank]
	call BankswitchROM
	call DecompressData
	pop af
	jp BankswitchROM


; Copies bc bytes from [wTempPointer] to de
; preserves all registers except af
; input:
;	bc = number of bytes to copy
;	[wTempPointer] = address from which to start copying the data
;	de = where to copy the data
CopyBankedDataToDE::
	ldh a, [hBankROM]
	push af
	push hl
	ld a, [wTempPointerBank]
	call BankswitchROM
	ld a, [wTempPointer]
	ld l, a
	ld a, [wTempPointer + 1]
	ld h, a
	call CopyDataHLtoDE_SaveRegisters
	pop hl
	pop af
	jp BankswitchROM


; fills bc bytes of data at hl with a
; preserves all registers except af
; input:
;	a = data to copy
;	bc = how many times to copy the data
;	hl = where to copy the data
FillMemoryWithA::
	push hl
	push de
	push bc
	ld e, a
.loop
	ld [hl], e
	inc hl
	dec bc
	ld a, b
	or c
	jr nz, .loop
	pop bc
	pop de
	pop hl
	ret


; fills 2*bc bytes of data at hl with d,e
; preserves all registers except af
; input:
;	de = data to copy
;	bc = how many times to copy the data
;	hl = where to copy the data
FillMemoryWithDE::
	push hl
	push bc
.loop
	ld [hl], e
	inc hl
	ld [hl], d
	inc hl
	dec bc
	ld a, b
	or c
	jr nz, .loop
	pop bc
	pop hl
	ret


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
	call BankswitchROM
	pop hl
	ld a, [hl]
	ld hl, sp+$03
	ld [hl], a
	pop af
	call BankswitchROM
	pop af
	pop hl
	ret
