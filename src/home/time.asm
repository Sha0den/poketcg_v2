; timer interrupt handler
; preserves all registers
TimerHandler::
	push af
	push hl
	push de
	push bc
	ei
	call SerialTimerHandler
	; only trigger every fourth interrupt ≈ 60.24 Hz
	ld hl, wTimerCounter
	ld a, [hl]
	inc [hl]
	and $3
	jr nz, .done
	; increment the 60-60-60-255-255 counter
	call IncrementPlayTimeCounter
	; check in-timer flag
	ld hl, wReentrancyFlag
	bit IN_TIMER, [hl]
	jr nz, .done
	set IN_TIMER, [hl]
	ldh a, [hBankROM]
	push af
	ld a, BANK(SoundTimerHandler)
	rst BankswitchROM
	call SoundTimerHandler
	pop af
	rst BankswitchROM
	; clear in-timer flag
	ld hl, wReentrancyFlag
	res IN_TIMER, [hl]
.done
	pop bc
	pop de
	pop hl
	pop af
	reti


; increments play time counter by a tick
; preserves bc and de
IncrementPlayTimeCounter::
	ld a, [wPlayTimeCounterEnable]
	or a
	ret z
	ld hl, wPlayTimeCounter
	inc [hl]
	ld a, [hl]
	cp 60
	ret c
	ld [hl], $0
	inc hl
	inc [hl]
	ld a, [hl]
	cp 60
	ret c
	ld [hl], $0
	inc hl
	inc [hl]
	ld a, [hl]
	cp 60
	ret c
	ld [hl], $0
	inc hl
	inc [hl]
	ret nz
	inc hl
	inc [hl]
	ret


; setup timer to 16384/68 ≈ 240.94 Hz
; preserves de and hl
SetupTimer::
	ld b, -68 ; Value for Normal Speed
	call CheckForCGB
	jr c, .set_timer
	ldh a, [rSPD]
	and SPD_DOUBLE
	jr z, .set_timer
	ld b, -68 * 2 ; Value for CGB Double Speed
.set_timer
	ld a, b
	ldh [rTMA], a
	ld a, TAC_16KHZ
	ldh [rTAC], a
	ld a, TAC_START | TAC_16KHZ
	ldh [rTAC], a
	ret


; preserves all registers except af
; output:
;	carry = set:  if the console isn't a Game Boy Color
CheckForCGB::
	ld a, [wConsole]
	cp CONSOLE_CGB
	ret z
	scf
	ret
