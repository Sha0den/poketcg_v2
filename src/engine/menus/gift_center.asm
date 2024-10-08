; output:
;	[wGiftCenterChoice] & a = GIFT_CENTER_MENU_* constant
GiftCenterMenu:
	ld a, 1 << AUTO_CLOSE_TEXTBOX
	farcall SetOverworldNPCFlags
	ld a, [wSelectedGiftCenterMenuItem]
	ld hl, .GiftCenterMenuParams
	call InitAndPrintMenu
.loop_input
	call DoFrameIfLCDEnabled
	call HandleMenuInput
	jr nc, .loop_input
	ld a, e
	ld [wSelectedGiftCenterMenuItem], a
	ldh a, [hCurMenuItem]
	cp e
	jr z, .got_choice
	ld a, GIFT_CENTER_MENU_EXIT
.got_choice
	ld [wGiftCenterChoice], a
	push af
	ld hl, .LoadTextPointerFunctionTable
	call JumpToFunctionInTable
	farcall CloseTextBox
	call DoFrameIfLCDEnabled
	pop af
	ret

.LoadTextPointerFunctionTable:
	dw .LoadChoiceTextPointer ; GIFT_CENTER_MENU_SEND_CARD
	dw .LoadChoiceTextPointer ; GIFT_CENTER_MENU_RECEIVE_CARD
	dw .LoadChoiceTextPointer ; GIFT_CENTER_MENU_SEND_DECK
	dw .LoadChoiceTextPointer ; GIFT_CENTER_MENU_RECEIVE_DECK
	dw .stub                  ; GIFT_CENTER_MENU_EXIT

.LoadChoiceTextPointer:
	ld a, [wGiftCenterChoice]
	add a
	ld c, a
	ld b, $00
	ld hl, .GiftCenterTextPointers
	add hl, bc
	ld a, [hli]
	ld [wTxRam2], a
	ld a, [hl]
	ld [wTxRam2 + 1], a
.stub
	ret

.GiftCenterTextPointers:
	tx SendCardText                 ; GIFT_CENTER_MENU_SEND_CARD
	tx ReceiveCardText              ; GIFT_CENTER_MENU_RECEIVE_CARD
	tx SendDeckConfigurationText    ; GIFT_CENTER_MENU_SEND_DECK
	tx ReceiveDeckConfigurationText ; GIFT_CENTER_MENU_RECEIVE_DECK

.GiftCenterMenuParams:
	db  4,  0 ; start menu coordinates
	db 16, 12 ; start menu text box dimensions

	db  6, 2 ; text alignment for InitTextPrinting
	tx GiftCenterMenuText
	db $ff

	db 5, 2 ; cursor x, cursor y
	db 2 ; y displacement between items
	db 5 ; number of items
	db SYM_CURSOR_R ; cursor tile number
	db SYM_SPACE ; tile behind cursor
	dw NULL ; function pointer if non-0
