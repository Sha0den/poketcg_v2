; waits for VBlankHandler to finish, unless lcd is off
; preserves all registers except af
WaitForVBlank::
	push hl
	ld a, [wLCDC]
	bit LCDC_ENABLE_F, a
	jr z, .lcd_off
	ld hl, wVBlankCounter
	ld a, [hl]
.wait_vblank
	halt
	nop
	cp [hl]
	jr z, .wait_vblank
.lcd_off
	pop hl
	ret


; turns on LCD
; preserves all registers except af
EnableLCD::
	ld a, [wLCDC]        ;
	bit LCDC_ENABLE_F, a ;
	ret nz               ; assert that LCD is off
	or LCDC_ON           ;
	ld [wLCDC], a        ;
	ldh [rLCDC], a       ; turn LCD on
	ld a, FLUSH_ALL_PALS
	ld [wFlushPaletteFlags], a
	ret


; waits for vblank, then turns off LCD
; preserves all registers except af
DisableLCD::
	ldh a, [rLCDC]       ;
	bit LCDC_ENABLE_F, a ;
	ret z                ; assert that LCD is on
	ldh a, [rIE]
	ld [wIE], a
	res INT_VBLANK, a    ;
	ldh [rIE], a         ; disable vblank interrupt
.wait_vblank
	ldh a, [rLY]         ;
	cp LY_VBLANK         ;
	jr nz, .wait_vblank  ; wait for vblank
	ldh a, [rLCDC]       ;
	and LCDC_OFF         ;
	ldh [rLCDC], a       ;
	ld a, [wLCDC]        ;
	and LCDC_OFF         ;
	ld [wLCDC], a        ; turn LCD off
	xor a
	ldh [rBGP], a
	ldh [rOBP0], a
	ldh [rOBP1], a
	ld a, [wIE]
	ldh [rIE], a
	ret


; sets OBJ size: 8x8
; preserves all registers except af
Set_OBJ_8x8::
	ld a, [wLCDC]
	and LCDC_OBJ8
	ld [wLCDC], a
	ret


; sets OBJ size: 8x16
; preserves all registers except af
Set_OBJ_8x16::
	ld a, [wLCDC]
	or LCDC_OBJ16
	ld [wLCDC], a
	ret


; sets Window Display to on
; preserves all registers except af
SetWindowOn::
	ld a, [wLCDC]
	or LCDC_WINON
	ld [wLCDC], a
	ret


; sets Window Display to off
; preserves all registers except af
SetWindowOff::
	ld a, [wLCDC]
	and LCDC_WINOFF
	ld [wLCDC], a
	ret
