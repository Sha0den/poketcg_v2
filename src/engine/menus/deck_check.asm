; handles player input in the check menu
; works out which cursor coordinate to go to
; output:
;	a =  1:      if the A button was pressed
;	a = -1:      if the B button was pressed
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
	bit B_PAD_LEFT, a
	jr nz, .horizontal
	bit B_PAD_RIGHT, a
	jr z, .check_vertical

; handles horizontal input
.horizontal
	ld a, d
	xor $1 ; flips x coordinate
	ld d, a
	jr .okay
.check_vertical
	bit B_PAD_UP, a
	jr nz, .vertical
	bit B_PAD_DOWN, a
	jr z, .no_pad

; handles vertical input
.vertical
	ld a, e
	xor $01 ; flips y coordinate
	ld e, a

.okay
	ld a, SFX_CURSOR
	ld [wMenuInputSFX], a
	call EraseCheckMenuCursor

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
	and PAD_A | PAD_B
	jr z, .no_input
	and PAD_A
	jr nz, .a_press
	ld a, -1 ; cancel
	call PlaySFXConfirmOrCancel_Bank2
	scf
	ret

.a_press
	call DisplayCheckMenuCursor
	ld a, $1
	call PlaySFXConfirmOrCancel_Bank2
	scf
	ret

.no_input
	ld a, [wMenuInputSFX]
	or a
	call nz, PlaySFX
	ld hl, wCheckMenuCursorBlinkCounter
	ld a, [hl]
	inc [hl]
	and %00001111
	ret nz  ; only update cursor if blink's lower nibble is 0

	ld a, SYM_CURSOR_R ; cursor byte
	bit 4, [hl] ; only draw cursor if blink counter's fourth bit is not set
	jr z, DrawCheckMenuCursor
;	fallthrough

; draws a blank tile over the menu cursor.
; preserves de
EraseCheckMenuCursor:
	xor a ; SYM_SPACE (blank tile)
;	fallthrough

; transforms the cursor position into coordinates
; in order to draw the tile in a over the menu cursor.
; preserves de
; input:
;	a = tile byte to draw (SYM_* constant)
DrawCheckMenuCursor:
	push af
	ld a, [wCheckMenuCursorXPosition]
	ld h, a
	ld a, [wCheckMenuCursorXPositionOffset]
	ld l, a
	call HtimesL
	ld b, l
	inc b
	; b = 10 * cursor x position + 1
	ld a, [wCheckMenuCursorYPosition]
	add a
	add 14
	ld c, a
	; c = 2 * cursor y position + 14
	pop af
	call WriteByteToBGMap0
	or a
	ret

; draws a right-facing arrow icon where the cursor should go.
; preserves de
DisplayCheckMenuCursor:
	ld a, SYM_CURSOR_R
	jr DrawCheckMenuCursor


; plays a sound effect depending on the value in a
; preserves all registers
; input:
;	a  = -1:  play SFX_CANCEL  (usually following a B press)
;	a != -1:  play SFX_CONFIRM (usually following an A press)
PlaySFXConfirmOrCancel_Bank2:
	push af
	inc a ; cp -1
	ld a, SFX_CONFIRM
	jr nz, .play_sfx
	ld a, SFX_CANCEL
.play_sfx
	call PlaySFX
	pop af
	ret
