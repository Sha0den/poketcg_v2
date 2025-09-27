; if carry flag is set, only delays
; if carry not set:
; - set rRP edge up, wait;
; - set rRP edge down, wait;
; - return
; preserves all registers except af
; input:
;	hl = rRP
TransmitIRBit:
	jr c, .delay_once
	ld [hl], RP_WRITE_HIGH | RP_ENABLE
	ld a, 5
	jr .loop_delay_1 ; jump to possibly to add more cycles?
.loop_delay_1
	dec a
	jr nz, .loop_delay_1
	ld [hl], RP_WRITE_LOW | RP_ENABLE
	ld a, 14
	jr .loop_delay_2 ; jump to possibly to add more cycles?
.loop_delay_2
	dec a
	jr nz, .loop_delay_2
	ret

.delay_once
	ld a, 21
	jr .loop_delay_3 ; jump to possibly to add more cycles?
.loop_delay_3
	dec a
	jr nz, .loop_delay_3
	nop
	ret


; preserves de
; output:
;	carry = set (& a = $ff):  if the B button was pressed
TransmitIRDataBuffer:
	call Func_19705
	jp c, ReturnZFlagUnsetAndCarryFlagSet
	ld a, $49
	call TransmitByteThroughIR
	ld a, $52
	call TransmitByteThroughIR
	ld hl, wIRDataBuffer
	ld c, 8
;	fallthrough

; preserves de
; input:
;	hl = start of data to transmit
;	c = number of bytes to transmit
; output:
;	carry = set:  if the B button was pressed
TransmitNBytesFromHLThroughIR:
	ld b, $0
.loop_data_bytes
	ld a, b
	add [hl]
	ld b, a
	ld a, [hli]
	call TransmitByteThroughIR
	ret c
	dec c
	jr nz, .loop_data_bytes
	ld a, b
	cpl
	inc a
;	fallthrough

; preserves all registers except af
; input:
;	a = byte to transmit through IR
; output:
;	carry = set (& a = $ff):  if the B button was pressed
TransmitByteThroughIR:
	push hl
	ld hl, rRP
	push de
	push bc
	ld b, a
	scf  ; carry set
	call TransmitIRBit
	or a ; carry not set
	call TransmitIRBit
	ld c, 8
	ld c, 8 ; number of input bits
.loop
	ld a, $00
	rr b
	call TransmitIRBit
	dec c
	jr nz, .loop
	pop bc
	pop de
	pop hl
	ldh a, [rJOYP]
	bit 1, a ; P11
	jp z, ReturnZFlagUnsetAndCarryFlagSet
	xor a ; return z set
	ret


; same as ReceiveByteThroughIR but returns $0 in a if there's an error in IR
; preserves all registers except af
; output:
;	a = sequence of bits related to how rRP sets/unsets bit 1 ($00 if carry is set)
;	carry = set:  if there was a time out error
ReceiveByteThroughIR_ZeroIfUnsuccessful:
	call ReceiveByteThroughIR
	ret nc
	xor a
	ret


; preserves all registers except af
; output:
;	a = sequence of bits related to how rRP sets/unsets bit 1 ($ff if carry is set)
;	carry = set:  if there was a time out error
ReceiveByteThroughIR:
	push de
	push bc
	push hl

; waits for bit 1 in rRP to be unset
; up to $100 loops
	ld b, 0
	ld hl, rRP
.wait_ir
	bit B_RP_DATA_IN, [hl]
	jr z, .ok
	dec b
	jr nz, .wait_ir
	; looped around $100 times
	; return $ff and carry set
	pop hl
	pop bc
	pop de
	scf
	ld a, $ff
	ret

.ok
; delay for some cycles
	ld a, 15
.loop_delay
	dec a
	jr nz, .loop_delay

; loop for each bit
	ld e, 8
.loop
	ld a, $01
	; possibly delay cycles?
	ld b, 9
	ld b, 9
	ld b, 9
	ld b, 9

; checks for bit 1 in rRP, and if it is unset in any of the checks,
; then a is set to 0. this is done a total of 9 times.
	bit B_RP_DATA_IN, [hl]
	jr nz, .asm_196ec
	xor a
.asm_196ec
	bit B_RP_DATA_IN, [hl]
	jr nz, .asm_196f1
	xor a
.asm_196f1
	dec b
	jr nz, .asm_196ec
	; one bit received
	rrca
	rr d
	dec e
	jr nz, .loop
	ld a, d ; has bits set for each "cycle" that bit 1 was not unset
	pop hl
	pop bc
	pop de
	or a
	ret


; called when expecting to transmit data
; preserves bc and de
; output:
;	carry = set (& a = $ff):  if the B button was pressed
Func_19705:
	ld hl, rRP
.loop
	ldh a, [rJOYP]
	bit 1, a ; P11
	jr z, ReturnZFlagUnsetAndCarryFlagSet
	ld a, $aa ; request
	call TransmitByteThroughIR
	push hl
	pop hl
	call ReceiveByteThroughIR_ZeroIfUnsuccessful
	cp $33 ; acknowledge
	jr nz, .loop
	xor a
	ret


; called when expecting to receive data
; preserves bc and de
; output:
;	carry = set (& a = $ff):  if the B button was pressed
Func_1971e:
	ld hl, rRP
.asm_19721
	ldh a, [rJOYP]
	bit 1, a ; P11
	jr z, ReturnZFlagUnsetAndCarryFlagSet
	call ReceiveByteThroughIR_ZeroIfUnsuccessful
	cp $aa ; request
	jr nz, .asm_19721
	ld a, $33 ; acknowledge
	call TransmitByteThroughIR
	xor a
	ret


; preserves de
; output:
;	carry = set (& a = $ff):  if the B button was pressed or
;	                          if there was an error
ReceiveIRDataBuffer:
	call Func_1971e
	jr c, ReturnZFlagUnsetAndCarryFlagSet
	call ReceiveByteThroughIR
	cp $49
	jr nz, ReceiveIRDataBuffer
	call ReceiveByteThroughIR
	cp $52
	jr nz, ReceiveIRDataBuffer
	ld hl, wIRDataBuffer
	ld c, 8
;	fallthrough

; preserves de
; input:
;	hl = address to write received data
;	c = number of bytes to be received
; output:
;	carry = set (& a = $ff):  if there was an error
ReceiveNBytesToHLThroughIR:
	ld b, 0
.loop_data_bytes
	call ReceiveByteThroughIR
	jr c, ReturnZFlagUnsetAndCarryFlagSet
	ld [hli], a
	add b
	ld b, a
	dec c
	jr nz, .loop_data_bytes
	call ReceiveByteThroughIR
	add b
	or a
	ret z
;	fallthrough

ReturnZFlagUnsetAndCarryFlagSet:
	ld a, $ff
	or a ; z not set
	scf  ; carry set
	ret


; disables interrupts, sets joypad and IR communication port,
; and switches to CGB normal speed
; preserves de
StartIRCommunications:
	di
	call SwitchToCGBNormalSpeed
	ld a, P14
	ldh [rJOYP], a
	ld a, RP_ENABLE
	ldh [rRP], a
	ret


; reenables interrupts, and switches CGB back to double speed
; preserves de
CloseIRCommunications:
	ld a, JOYP_GET_NONE
	ldh [rJOYP], a
.wait_vblank_on
	ldh a, [rSTAT]
	and STAT_MODE
	cp STAT_VBLANK
	jr z, .wait_vblank_on
.wait_vblank_off
	ldh a, [rSTAT]
	and STAT_MODE
	cp STAT_VBLANK
	jr nz, .wait_vblank_off
	call SwitchToCGBDoubleSpeed
	reti


; expects to receive a command (IRCMD_* constant) in wIRDataBuffer + 1,
; then calls the subroutine corresponding to that command
ExecuteReceivedIRCommands:
	call StartIRCommunications
.loop_commands
	call ReceiveIRDataBuffer
	jr c, .error
	jr nz, .loop_commands
	ld hl, wIRDataBuffer + 1
	ld a, [hl]
	ld hl, .CmdPointerTable
	cp NUM_IR_COMMANDS
	jr nc, .loop_commands ; invalid command
	call .JumpToCmdPointer ; execute command
	jr .loop_commands
.error
	call CloseIRCommunications
	xor a
	scf
	ret

.JumpToCmdPointer
	add a ; *2
	add l
	ld l, a
	ld a, 0
	adc h
	ld h, a
	ld a, [hli]
	ld h, [hl]
	ld l, a
.jp_hl
	jp hl

.CmdPointerTable
	dw .Close                ; IRCMD_CLOSE
	dw .ReturnWithoutClosing ; IRCMD_RETURN_WO_CLOSING
	dw .TransmitData         ; IRCMD_TRANSMIT_DATA
	dw .ReceiveData          ; IRCMD_RECEIVE_DATA
	dw .CallFunction         ; IRCMD_CALL_FUNCTION

; closes the IR communications
; pops hl so that the sp points
; to the return address of ExecuteReceivedIRCommands
.Close
	pop hl
	call CloseIRCommunications
	; fallthrough

; returns without closing the IR communications
; will continue the command loop
.ReturnWithoutClosing
	or a
	ret

; receives an address and number of bytes
; and transmits starting at that address
.TransmitData
	call Func_19705
	ret c
	call LoadRegistersFromIRDataBuffer
	jp TransmitNBytesFromHLThroughIR

; receives an address and number of bytes
; and writes the data received to that address
.ReceiveData
	call LoadRegistersFromIRDataBuffer
	ld l, e
	ld h, d
	call ReceiveNBytesToHLThroughIR
	ret c
	sub b
	jp TransmitByteThroughIR

; receives an address to call, then stores
; the registers in the IR data buffer
.CallFunction
	call LoadRegistersFromIRDataBuffer
	call .jp_hl
;	fallthrough

; stores af, hl, de and bc in wIRDataBuffer
; preserves af and bc
StoreRegistersInIRDataBuffer:
	push de
	push hl
	push af
	ld hl, wIRDataBuffer
	pop de
	ld [hl], e ; <- f
	inc hl
	ld [hl], d ; <- a
	inc hl
	pop de
	ld [hl], e ; <- l
	inc hl
	ld [hl], d ; <- h
	inc hl
	pop de
	ld [hl], e ; <- e
	inc hl
	ld [hl], d ; <- d
	inc hl
	ld [hl], c ; <- c
	inc hl
	ld [hl], b ; <- b
	ret


; loads all the registers that were stored
; from StoreRegistersInIRDataBuffer
LoadRegistersFromIRDataBuffer:
	ld hl, wIRDataBuffer
	ld e, [hl]
	inc hl
	ld d, [hl]
	inc hl
	push de
	ld e, [hl]
	inc hl
	ld d, [hl]
	inc hl
	push de
	ld e, [hl]
	inc hl
	ld d, [hl]
	inc hl
	ld c, [hl]
	inc hl
	ld b, [hl]
	pop hl
	pop af
	ret


; preserves de
; output:
;	carry = set:  if the sent request was not acknowledged
TrySendIRRequest:
	call StartIRCommunications
	ld hl, rRP
	ld c, 4
.send_request
	ld a, $aa ; request
	push bc
	call TransmitByteThroughIR
	push bc
	pop bc
	call ReceiveByteThroughIR_ZeroIfUnsuccessful
	pop bc
	cp $33 ; acknowledgement
	jr z, .received_ack
	dec c
	jr nz, .send_request
	scf
	jr SafelyCloseIRCommunications

.received_ack
	xor a
	jr SafelyCloseIRCommunications


; preserves de
; output:
;	carry = set:  if the request was not received
TryReceiveIRRequest:
	call StartIRCommunications
	ld hl, rRP
.wait_request
	call ReceiveByteThroughIR_ZeroIfUnsuccessful
	cp $aa ; request
	jr z, .send_ack
	ldh a, [rJOYP]
	cpl
	and P10 | P11
	jr z, .wait_request
	scf
	jr SafelyCloseIRCommunications

.send_ack
	ld a, $33 ; acknowledgement
	call TransmitByteThroughIR
	xor a
	jr SafelyCloseIRCommunications


; preserves de
; sends request for other device to close current communication
RequestCloseIRCommunication:
	call StartIRCommunications
	ld a, IRCMD_CLOSE
	ld [wIRDataBuffer + 1], a
	call TransmitIRDataBuffer
;	fallthrough

; preserves af and de
SafelyCloseIRCommunications:
	push af
	call CloseIRCommunications
	pop af
	ret


; sends a request for data to be transmitted from the other device
; preserves de
; input:
;	hl = start of data to request to transmit
;	de = address to write data received
;	c = length of data
RequestDataTransmissionThroughIR:
	ld a, IRCMD_TRANSMIT_DATA
	call TransmitRegistersThroughIR
	push de
	call Func_1971e
	pop hl
	jr c, SafelyCloseIRCommunications
	call ReceiveNBytesToHLThroughIR
	jr SafelyCloseIRCommunications


; transmits data to be written in the other device
; preserves de
; input:
;	hl = start of data to transmit
;	de = address for other device to write data
;	c = length of data
; output:
;	carry = set (& a = $ff):  if there was an error
RequestDataReceivalThroughIR:
	ld a, IRCMD_RECEIVE_DATA
	call TransmitRegistersThroughIR
	call TransmitNBytesFromHLThroughIR
	jr c, SafelyCloseIRCommunications
	call ReceiveByteThroughIR
	jr c, SafelyCloseIRCommunications
	add b
	jr nz, .asm_1989e
	xor a
	jr SafelyCloseIRCommunications
.asm_1989e
	call ReturnZFlagUnsetAndCarryFlagSet
	jr SafelyCloseIRCommunications


; first stores all the current registers in wIRDataBuffer
; then transmits it through IR
; preserves all registers except af
TransmitRegistersThroughIR:
	push hl
	push de
	push bc
	call StoreRegistersInIRDataBuffer
	call StartIRCommunications
	call TransmitIRDataBuffer
	pop bc
	pop de
	pop hl
	ret nc
	inc sp
	inc sp
	jr SafelyCloseIRCommunications
