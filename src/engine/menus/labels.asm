; prints $ff-terminated list of text to text box
; given 2 bytes for text alignment and 2 bytes for text ID
; input:
;	hl = list of labels to print
PrintLabels:
	ldh a, [hffb0]
	push af
	ld a, $02
	ldh [hffb0], a

	push hl
.loop_text_print_1
	ld d, [hl]
	inc hl
	bit 7, d
	jr nz, .next
	inc hl
	ld a, [hli]
	push hl
	ld h, [hl]
	ld l, a
	call PrintTextNoDelay
	pop hl
	inc hl
	jr .loop_text_print_1

.next
	pop hl
	pop af
	ldh [hffb0], a
.loop_text_print_2
	ld d, [hl]
	inc hl
	bit 7, d
	ret nz
	ld e, [hl]
	inc hl
	call AdjustCoordinatesForBGScroll
	ld a, [hli]
	push hl
	ld h, [hl]
	ld l, a
	call InitTextPrinting_PrintTextNoDelay
	pop hl
	inc hl
	jr .loop_text_print_2


; preserves all registers except af
; input:
;	hl = menu parameters
;	a = current menu item
InitAndPrintMenu:
	push hl
	push bc
	push de
	push af
	ld d, [hl]
	inc hl
	ld e, [hl]
	inc hl
	ld b, [hl]
	inc hl
	ld c, [hl]
	inc hl
	push hl
	call AdjustCoordinatesForBGScroll
	farcall Func_c3ca
	call DrawRegularTextBox
	call DoFrameIfLCDEnabled
	pop hl
	call PrintLabels
	pop af
	call InitializeMenuParameters
	pop de
	pop bc
	pop hl
	ret


PauseMenuParams:
	db 12,  0 ; start menu coordinates
	db  8, 14 ; start menu text box dimensions

	db 14, 2 ; text alignment for InitTextPrinting
	tx PauseMenuOptionsText
	db $ff

	db 13, 2 ; cursor x, cursor y
	db 2 ; y displacement between items
	db 6 ; number of items
	db SYM_CURSOR_R ; cursor tile number
	db SYM_SPACE ; tile behind cursor
	dw NULL ; function pointer if non-0


PCMenuParams:
	db 10,  0 ; start menu coordinates
	db 10, 12 ; start menu text box dimensions

	db 12, 2 ; text alignment for InitTextPrinting
	tx PCMenuOptionsText
	db $ff

	db 11, 2 ; cursor x, cursor y
	db 2 ; y displacement between items
	db 5 ; number of items
	db SYM_CURSOR_R ; cursor tile number
	db SYM_SPACE ; tile behind cursor
	dw NULL ; function pointer if non-0
