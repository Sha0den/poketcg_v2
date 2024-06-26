; handles player input in the check menu
; works out which cursor coordinate to go to
; output:
;	a = $1:       if the A button was pressed
;	a = $ff:      if the B button was pressed
;	carry = set:  if either the A or the B button were pressed
HandleCheckMenuInput:
	xor a
	ld [wMenuInputSFX], a
	ld a, [wCheckMenuCursorXPosition]
	ld d, a
	ld a, [wCheckMenuCursorYPosition]
	ld e, a
	; d,e = x,y positions of the cursor sprite

	ldh a, [hDPadHeld]
	or a
	jr z, .no_pad
	bit D_LEFT_F, a
	jr nz, .horizontal
	bit D_RIGHT_F, a
	jr z, .check_vertical

; handles horizontal input
.horizontal
	ld a, d
	xor $1 ; flips x coordinate
	ld d, a
	jr .okay
.check_vertical
	bit D_UP_F, a
	jr nz, .vertical
	bit D_DOWN_F, a
	jr z, .no_pad

; handles vertical input
.vertical
	ld a, e
	xor $01 ; flips y coordinate
	ld e, a

.okay
	ld a, SFX_CURSOR
	ld [wMenuInputSFX], a
	push de
	call EraseCheckMenuCursor
	pop de

; updates x and y cursor positions
	ld a, d
	ld [wCheckMenuCursorXPosition], a
	ld a, e
	ld [wCheckMenuCursorYPosition], a

; resets cursor blink
	xor a
	ld [wCheckMenuCursorBlinkCounter], a
.no_pad
	ldh a, [hKeysPressed]
	and A_BUTTON | B_BUTTON
	jr z, .no_input
	and A_BUTTON
	jr nz, .a_press
	ld a, $ff ; cancel
	call PlaySFXConfirmOrCancel
	scf
	ret

.a_press
	call DisplayCheckMenuCursor
	ld a, $01
	call PlaySFXConfirmOrCancel
	scf
	ret

.no_input
	ld a, [wMenuInputSFX]
	or a
	jr z, .check_blink
	call PlaySFX

.check_blink
	ld hl, wCheckMenuCursorBlinkCounter
	ld a, [hl]
	inc [hl]
	and %00001111
	ret nz  ; only update cursor if blink's lower nibble is 0

	ld a, SYM_CURSOR_R ; cursor byte
	bit 4, [hl] ; only draw cursor if blink counter's fourth bit is not set
	jr z, DrawCheckMenuCursor
;	fallthrough

; draws in the cursor position
EraseCheckMenuCursor:
	ld a, SYM_SPACE ; empty cursor
;	fallthrough

; draws in the cursor position
; input:
;	a = tile byte to draw (SYM_* constant)
DrawCheckMenuCursor:
	ld e, a
	ld a, 10
	ld l, a
	ld a, [wCheckMenuCursorXPosition]
	ld h, a
	call HtimesL

	ld a, l
	add 1
	ld b, a
	ld a, [wCheckMenuCursorYPosition]
	sla a
	add 14
	ld c, a

	ld a, e
	call WriteByteToBGMap0
	or a
	ret

DisplayCheckMenuCursor:
	ld a, SYM_CURSOR_R
	jr DrawCheckMenuCursor


; plays sound depending on value in a
; preserves all registers
; input:
;	a  = $ff:  play cancel sound effect
;	a != $ff:  play confirm sound effect
PlaySFXConfirmOrCancel:
	push af
	inc a
	jr z, .cancel_sfx
	ld a, SFX_CONFIRM
	jr .play_sfx
.cancel_sfx
	ld a, SFX_CANCEL
.play_sfx
	call PlaySFX
	pop af
	ret
