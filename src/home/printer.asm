; input:
;	a = which sequence to execute
ExecutePrinterPacketSequence::
	ld hl, .SequencePointers
	dec a
	jp JumpToFunctionInTable

.SequencePointers:
	; each entry corresponds to value in wPrinterPacketSequence
	dw .SendPreambleOrHeaderByte   ; 1: send wPrinterPacketPreamble + 1
	dw .SendPreambleOrHeaderByte   ; 2: send wPrinterPacketInstructions + 0
	dw .SendPreambleOrHeaderByte   ; 3: send wPrinterPacketInstructions + 1
	dw .SendPreambleOrHeaderByte   ; 4: send wPrinterPacketDataSize + 0
	dw .SendPreambleOrHeaderByte   ; 5: send wPrinterPacketDataSize + 1
	dw .StartDataSection           ; 6
	dw .SendRestOfDataSection      ; 7
	dw .SendChecksumByte1          ; 8
	dw .SendChecksumByte2          ; 9
	dw .SendDummyByte              ; 10
	dw .GetDeviceNumber            ; 11
	dw .GetStatusAndFinishSequence ; 12

; sends next byte and increments sequence
.SendPreambleOrHeaderByte:
	call SendNextPrinterPacketByte
.increment_sequence
	ld hl, wPrinterPacketSequence
	inc [hl]
	ret

; checks if there is data to send
; if so, then updates the serial data pointer
; otherwise, skip sending data section
.StartDataSection:
	call .increment_sequence
	ld hl, wPrinterPacketDataSize
	ld a, [hli]
	or [hl]
	jr nz, .set_data_ptr
	; no data to send
	call .increment_sequence
	jr .SendChecksumByte1

.set_data_ptr
	ld hl, wPrinterPacketDataPtr
	ld de, wSerialDataPtr
	ld a, [hli]
	ld [de], a
	inc de
	ld a, [hl]
	ld [de], a
;	fallthrough

; sends next byte in data section
; only increments sequence when
; there are no more bytes to send
.SendRestOfDataSection:
	call SendNextPrinterPacketByte
	ld hl, wPrinterPacketDataSize
	ld a, [hl]
	dec [hl]
	or a
	jr nz, .finish_data_section
	inc hl
	dec [hl]
	dec hl
.finish_data_section
	ld a, [hli]
	or [hl]
	jr z, .increment_sequence
	ret

; sends first byte of checksum
.SendChecksumByte1:
	ld a, [wPrinterPacketChecksum + 0]
.send_byte_and_increment_sequence
	call SendByteThroughSerialData
	jr .increment_sequence

; sends second byte of checksum
.SendChecksumByte2:
	ld a, [wPrinterPacketChecksum + 1]
	jr .send_byte_and_increment_sequence

; gets number of device, and sends a dummy byte
.GetDeviceNumber:
	ldh a, [rSB]
	ld [wSerialTransferData], a
;	fallthrough

; sends a dummy byte
.SendDummyByte:
	xor a
	jr .send_byte_and_increment_sequence

; gets the printer status, then finishes sequence
.GetStatusAndFinishSequence:
	ldh a, [rSB]
	ld [wPrinterStatus], a
	xor a
	ld [wPrinterPacketSequence], a
	ret


; sends byte pointed to by wSerialDataPtr to printer
; then increments this pointer to point to the next byte
; for the next iteration, and adds the byte value to the checksum
; preserves bc
SendNextPrinterPacketByte::
	ld hl, wSerialDataPtr
	ld e, [hl]
	inc hl
	ld d, [hl]
	ld a, [de]
	inc de
	ld [hl], d
	dec hl
	ld [hl], e
	ld e, a

	ld hl, wPrinterPacketChecksum
	add [hl]
	ld [hli], a
	ld a, $0
	adc [hl]
	ld [hl], a
	ld a, e
;	fallthrough

; preserves all registers except af
; input:
;	a = byte to send through serial data transfer
SendByteThroughSerialData:
	ldh [rSB], a
	ld a, SC_INTERNAL
	ldh [rSC], a
	ld a, SC_START | SC_INTERNAL
	ldh [rSC], a
	ret
