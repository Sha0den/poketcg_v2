; zeroes a bytes starting from hl.
; this function is identical to 'ClearMemory_Bank2',
; as well as 'ClearMemory_Bank5' and 'ClearMemory_Bank8'.
; preserves all registers
; input:
;	a = number of bytes to clear
;	hl = where to begin erasing
ClearMemory_Bank6:
	push af
	push bc
	push hl
	ld b, a
	xor a
.loop
	ld [hli], a
	dec b
	jr nz, .loop
	pop hl
	pop bc
	pop af
	ret


; plays a sound effect depending on the value in a.
; this function is identical to 'PlaySFXConfirmOrCancel_Bank2'.
; preserves all registers
; input:
;	a == -1:  play SFX_CANCEL  (usually following a B press)
;	a != -1:  play SFX_CONFIRM (usually following an A press)
PlaySFXConfirmOrCancel_Bank6:
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


WhatIsYourNameData:
	textitem 1, 1, WhatIsYourNameText
	db $ff

; gets the Player's name from user input and stores it in [hl].
; input:
;	hl = where to store the name (wNameBuffer)
InputPlayerName:
	ld e, l
	ld d, h
	ld a, MAX_PLAYER_NAME_LENGTH
	ld hl, WhatIsYourNameData
	lb bc, 12, 1
	call InitializeInputName
	call Set_OBJ_8x8
	xor a
	ld [wTileMapFill], a
	call EmptyScreen
	call ZeroObjectPositions
	ld a, $01
	ld [wVBlankOAMCopyToggle], a
	call LoadSymbolsFont
	lb de, $38, $bf
	call SetupText
	call LoadTextCursorTile
	ld a, $02
	ld [wd009], a
	call DrawPlayerNamingScreenBG
	xor a
	ld [wNamingScreenCursorX], a
	ld [wNamingScreenCursorY], a
	ld [wInvisibleCursorTile], a ; SYM_SPACE
	ld a, $09
	ld [wNamingScreenNumColumns], a
	ld a, $06
	ld [wNamingScreenKeyboardHeight], a
	ld a, SYM_CURSOR_R
	ld [wVisibleCursorTile], a
.loop
	ld a, $01
	ld [wVBlankOAMCopyToggle], a
	call DoFrame
	call UpdateRNGSources
	ldh a, [hDPadHeld]
	and START
	jr z, .else
	; the Start button was pressed.
	ld a, SFX_CONFIRM
	call PlaySFX
	call PlayerNamingScreen_DrawInvisibleCursor
	ld a, 6
	ld [wNamingScreenCursorX], a
	ld a, 5
	ld [wNamingScreenCursorY], a
	call PlayerNamingScreen_DrawVisibleCursor
	jr .loop

.else
	call PlayerNamingScreen_CheckButtonState
	jr nc, .loop ; if not pressed, go back to the loop.
	cp -1
	jr z, .on_b_button
	; on A button
	call PlayerNamingScreen_ProcessInput
	jr nc, .loop
	; player selected the "End" button.
	jr FinalizeInputName

.on_b_button
	ld a, [wNamingScreenBufferLength]
	or a
	jr z, .loop ; empty string?
	; erase one character.
	ld e, a
	ld d, $00
	ld hl, wNamingScreenBuffer
	add hl, de
	dec hl
	dec hl
	ld [hl], d ; add null terminator (TX_END)
	ld hl, wNamingScreenBufferLength ; note that its unit is byte, not word.
	dec [hl]
	dec [hl]
	call PrintPlayerNameFromInput
	jr .loop


; called when the Player is asked to name something (either the protagonist or a deck)
; input:
;	a = maximum length of a name
;	bc = coordinates at which to begin printing the name
;	de = where to store the name
;	hl = pointer for text items
InitializeInputName:
	ld [wNamingScreenBufferMaxLength], a
	push hl
	ld hl, wNamingScreenNamePosition
	ld [hl], b
	inc hl
	ld [hl], c
	; set the destination buffer.
	ld hl, wNamingScreenDestPointer
	ld [hl], e
	inc hl
	ld [hl], d
	; set the question string.
	inc hl ; wNamingScreenQuestionPointer
	pop bc ; initial input in hl
	ld [hl], c
	inc hl
	ld [hl], b
	; clear the name buffer.
	ld a, NAMING_SCREEN_BUFFER_LENGTH
	ld hl, wNamingScreenBuffer
	call ClearMemory_Bank6
	ld hl, wNamingScreenBuffer
.copy
	ld a, [wNamingScreenBufferMaxLength]
	ld c, a
	inc c
	call CopyNBytesFromDEToHL
	ld hl, wNamingScreenBuffer
	call GetTextLengthInTiles
	ld a, c
	ld [wNamingScreenBufferLength], a
	ret


FinalizeInputName:
	ld hl, wNamingScreenDestPointer
	ld a, [hli]
	ld h, [hl]
	ld l, a
	ld de, wNamingScreenBuffer
	jr InitializeInputName.copy


; draws the player naming keyboard and prints the question, if it exists.
; this function is very similar to 'DrawDeckNamingScreenBG'.
; input:
;	[wNamingScreenQuestionPointer] = pointer for text data (2 bytes)
DrawPlayerNamingScreenBG:
	lb de, 0, 3 ; x, y
	lb bc, 20, 15 ; w, h
	call DrawRegularTextBox
	call PrintPlayerNameFromInput
	; print the question string.
	; ex) "What is your name?"
	ld hl, wNamingScreenQuestionPointer
	ld a, [hli]
	ld h, [hl]
	ld l, a
	or h
	call nz, PlaceTextItems ; only print text item(s) if pointer isn't null
	; print the keyboard characters and "End".
	ld hl, .data
	call PlaceTextItems
	jp EnableLCD
.data
	textitem  2,  4, PlayerNameKeyboardText
	textitem 15, 16, EndText ; "End"
	db $ff


; this is called when naming the player character.
; it's similar to 'PrintDeckNameFromInput'.
; preserves bc
; input:
;	[wNamingScreenNamePosition] = screen coordinates for printing (2 bytes)
;	[wNamingScreenBufferMaxLength] = MAX_PLAYER_NAME_LENGTH
;	[wNamingScreenBuffer] = name generated from keyboard input (up to 24 bytes)
PrintPlayerNameFromInput:
	ld hl, wNamingScreenNamePosition
	ld d, [hl]
	inc hl
	ld e, [hl]
	call InitTextPrinting
	ld hl, .underbar_data
	ld de, wDefaultText
.loop
; copy the underbar string to wDefaultText
	ld a, [hli]
	ld [de], a
	inc de
	or a
	jr nz, .loop

	ld hl, wNamingScreenBuffer
	ld de, wDefaultText
.loop2
; copy the input from the user to wDefaultText
	ld a, [hli]
	or a
	jr z, .print_name
	ld [de], a
	inc de
	jr .loop2

.print_name
	ld hl, wDefaultText
	jp ProcessText

.underbar_data
REPT MAX_PLAYER_NAME_LENGTH / 2
	db TX_FULLWIDTH3, "FW3__"
ENDR
	db TX_END


; checks if any buttons were pressed and handles the input.
; this function is similar to 'DeckNamingScreen_CheckButtonState'.
; output:
;	carry = set:  if either the A button or the B button were pressed
PlayerNamingScreen_CheckButtonState:
	xor a
	ld [wMenuInputSFX], a
	ldh a, [hDPadHeld]
	or a
	jp z, .check_A_or_B
	; detected any button press.
	ld b, a
	ld a, [wNamingScreenKeyboardHeight]
	ld c, a
	ld a, [wNamingScreenCursorX]
	ld h, a
	ld a, [wNamingScreenCursorY]
	ld l, a
	bit D_UP_F, b
	jr z, .check_d_down
	; up
	dec a
	bit 7, a ; check underflow
	jr z, .adjust_y_position
	ld a, c
	dec a
	jr .adjust_y_position
.check_d_down
	bit D_DOWN_F, b
	jr z, .check_d_left
	; down
	inc a
	cp c
	jr c, .adjust_y_position
	xor a
.adjust_y_position
	ld l, a
	jr .update_keyboard_cursor
.check_d_left
	ld a, [wNamingScreenNumColumns]
	ld c, a
	ld a, h
	bit D_LEFT_F, b
	jr z, .check_d_right
	; left
	ld d, a
	ld a, $06 ; cursor y = final keyboard row
	cp l
	ld a, d
	jr nz, .check_if_can_move_left
	; cursor's in the bottom row
	push hl
	push af
	call PlayerNamingScreen_GetCharInfoFromPos
	inc hl
	inc hl
	inc hl
	inc hl
	inc hl
	ld a, [hl]
	dec a
	ld d, a
	pop af
	pop hl
	sub d ; cursor x position - (selected key's character code - 1)
	cp -1
	jr nz, .asm_6962
	ld a, c
	sub $02 ; number of columns in keyboard - 2
	; a = 7
	jr .adjust_x_position
.asm_6962
	cp -2
	jr nz, .check_if_can_move_left
	ld a, c
	sub $03 ; number of columns in keyboard - 3
	; a = 6
	jr .adjust_x_position
.check_if_can_move_left
	dec a
	bit 7, a ; check underflow
	jr z, .adjust_x_position
	ld a, c
	dec a
	jr .adjust_x_position
.check_d_right
	bit D_RIGHT_F, b
	jr z, .check_A_or_B
	ld d, a
	ld a, $06 ; cursor y = final keyboard row
	cp l
	ld a, d
	jr nz, .check_if_can_move_right
	; cursor's in the bottom row
	push hl
	push af
	call PlayerNamingScreen_GetCharInfoFromPos
	inc hl
	inc hl
	inc hl
	inc hl
	ld a, [hl]
	dec a
	ld d, a
	pop af
	pop hl
	add d ; cursor x position + (selected key's font type code - 1)
.check_if_can_move_right
	inc a
	cp c
	jr c, .adjust_x_position
	inc c
	cp c
	jr c, .reset_x_position
	inc c
	cp c
	ld a, $02
	jr nc, .adjust_x_position
	dec a ; $01
	jr .adjust_x_position
.reset_x_position
	xor a
.adjust_x_position
	ld h, a
.update_keyboard_cursor
	push hl
	call PlayerNamingScreen_GetCharInfoFromPos
	inc hl
	inc hl
	inc hl
	ld a, [wd009]
	cp $02
	jr nz, .asm_69bb
	inc hl
	inc hl
.asm_69bb
	ld d, [hl]
	push de
	call PlayerNamingScreen_DrawInvisibleCursor
	pop de
	pop hl
	ld a, l
	ld [wNamingScreenCursorY], a
	ld a, h
	ld [wNamingScreenCursorX], a
	xor a
	ld [wCheckMenuCursorBlinkCounter], a
	ld a, $06
	cp d
	jp z, PlayerNamingScreen_CheckButtonState
	ld a, SFX_CURSOR
	ld [wMenuInputSFX], a
.check_A_or_B
	ldh a, [hKeysPressed]
	and A_BUTTON | B_BUTTON
	jr z, .check_sfx_and_cursor_blink
	and A_BUTTON
	jr nz, .pressed_a
	; pressed B
	ld a, -1
.pressed_a
	call PlaySFXConfirmOrCancel_Bank6
	push af
	call PlayerNamingScreen_DrawVisibleCursor
	pop af
	scf
	ret

.check_sfx_and_cursor_blink
	ld a, [wMenuInputSFX]
	or a
	call nz, PlaySFX
	ld hl, wCheckMenuCursorBlinkCounter
	ld a, [hl]
	inc [hl]
	and $0f
	ret nz
	ld a, [wVisibleCursorTile]
	bit 4, [hl]
	jr z, PlayerNamingScreen_DrawCursor
;	fallthrough

PlayerNamingScreen_DrawInvisibleCursor:
	ld a, [wInvisibleCursorTile]
;	fallthrough

; this function is very similar to 'DeckNamingScreen_DrawCursor'.
; input:
;	a = which tile to draw
;	[wNamingScreenCursorX] = cursor's x position on the keyboard screen
;	[wNamingScreenCursorY] = cursor's y position on the keyboard screen
PlayerNamingScreen_DrawCursor:
	ld e, a
	ld a, [wNamingScreenCursorX]
	ld h, a
	ld a, [wNamingScreenCursorY]
	ld l, a
	call PlayerNamingScreen_GetCharInfoFromPos
	ld a, [hli]
	ld c, a
	ld b, [hl]
	dec b
	ld a, e
	call PlayerNamingScreen_AdjustCursorPosition
	call WriteByteToBGMap0
	or a
	ret

PlayerNamingScreen_DrawVisibleCursor:
	ld a, [wVisibleCursorTile]
	jr PlayerNamingScreen_DrawCursor


; returns after calling ZeroObjectPositions if a = [wInvisibleCursorTile].
; otherwise, uses [wNamingScreenBufferLength], [wNamingScreenBufferMaxLength], and
; [wNamingScreenNamePosition] to determine x/y positions and calls SetOneObjectAttributes.
; this function is similar to 'DeckNamingScreen_AdjustCursorPosition'.
; preserves all registers
; input:
;	a = cursor tile
PlayerNamingScreen_AdjustCursorPosition:
	push af
	push bc
	push de
	push hl
	push af
	call ZeroObjectPositions
	pop af
	ld b, a
	ld a, [wInvisibleCursorTile]
	cp b
	jr z, .done
	ld a, [wNamingScreenBufferLength]
	srl a
	ld d, a
	ld a, [wNamingScreenBufferMaxLength]
	srl a
	ld e, a
	ld a, d
	cp e
	jr nz, .buffer_not_full
	dec a
.buffer_not_full
	ld hl, wNamingScreenNamePosition
	add [hl]
	ld d, a
	ld h, $08
	ld l, d
	call HtimesL
	ld a, l
	add $08
	ld d, a
	ld e, $18
	ld bc, $0000
	call SetOneObjectAttributes
.done
	pop hl
	pop de
	pop bc
	pop af
	ret


; loads, to the first tile of v0Tiles0, the graphics for the blinking black square
; used in name input screens for inputting full width text.
; this function is very similar to 'LoadHalfWidthTextCursorTile'.
; preserves de and c
LoadTextCursorTile:
	ld hl, v0Tiles0 + $00 tiles
	ld b, TILE_SIZE
	ld a, $ff
.loop
	ld [hli], a
	dec b
	jr nz, .loop
	ret


; output:
;	carry = set:  if "End" was selected on the keyboard
PlayerNamingScreen_ProcessInput:
	ld a, [wNamingScreenCursorX]
	ld h, a
	ld a, [wNamingScreenCursorY]
	ld l, a
	call PlayerNamingScreen_GetCharInfoFromPos
	inc hl
	inc hl
	; load types into de.
	ld e, [hl]
	inc hl
	ld a, [hli]
	ld d, a
	cp $09 ; "End"
	scf
	ret z ; return carry if "End" was selected

; everything from this point up until .read_char doesn't seem like it's ever used.
; it's probably left over from the original Japanese input data.
	cp $07
	jr nz, .next_1
	ld a, [wd009]
	or a
	jr z, .store_one
	dec a
	jr z, .store_two
	xor a
	jr .set_var
.next_1
	cp $08
	jr nz, .next_2
	ld a, [wd009]
	or a
	jr z, .store_two
	dec a
	jr z, .set_var
.store_one
	ld a, $01
	; fallthrough
.set_var
	ld [wd009], a
	call DrawPlayerNamingScreenBG
	or a
	ret
.store_two
	ld a, $02
	jr .set_var

.next_2
	ld a, [wd009]
	cp $02
	jr z, .read_char
; check dakuten
	lb bc, TX_FULLWIDTH3, "FW3_゛"
	ld a, d
	cp b
	jr nz, .check_handakuten
	ld a, e
	cp c
	jr nz, .check_handakuten
	push hl
	ld hl, TransitionTable1 ; from 55th.
	call TransformCharacter
	pop hl
	jr nc, .return_to_previous_char
.cannot_transform
	or a
	ret

.check_handakuten
	lb bc, TX_FULLWIDTH3, "FW3_゜"
	ld a, d
	cp b
	jr nz, .check_font_type
	ld a, e
	cp c
	jr nz, .check_font_type
	push hl
	ld hl, TransitionTable2 ; from 72th.
	call TransformCharacter
	pop hl
	jr c, .cannot_transform
.return_to_previous_char
	ld a, [wNamingScreenBufferLength]
	dec a
	dec a
	ld [wNamingScreenBufferLength], a
	ld hl, wNamingScreenBuffer
	push de
	ld d, $00
	ld e, a
	add hl, de
	pop de
	ld a, [hl]
	jr .check_name_buffer

.check_font_type
	ld a, d
	or a
	jr nz, .check_name_buffer
	ld a, [wd009]
	or a
	jr z, .use_hiragana
	ld a, TX_KATAKANA
	jr .check_name_buffer

; read character code from info. to register.
; input:
;	hl = pointer
.read_char
	ld e, [hl]
	inc hl
	ld a, [hl] ; a = first byte of the code.
	or a
	; if 2 bytes code, jump.
	jr nz, .check_name_buffer
.use_hiragana
	ld a, TX_HIRAGANA
.check_name_buffer
	ld d, a ; de = character code
	ld hl, wNamingScreenBufferLength
	ld a, [hl]
	ld c, a
	push hl
	ld hl, wNamingScreenBufferMaxLength
	cp [hl]
	pop hl
	jr nz, .buffer_not_full
	; buffer is full, so just change the last character.
	ld hl, wNamingScreenBuffer
	dec hl
	dec hl
	jr .add_character_to_buffer

; increase name length before adding the character.
.buffer_not_full
	inc [hl]
	inc [hl]
	ld hl, wNamingScreenBuffer

; write 2 byte character codes to the name buffer.
; input:
;	c  = wNamingScreenBufferLength
;	de = 2 byte character code
;	hl = copy destination
.add_character_to_buffer
	ld b, $00
	add hl, bc
	ld [hl], d
	inc hl
	ld [hl], e
	inc hl
	ld [hl], b ; add null terminator (TX_END)
	call PrintPlayerNameFromInput
	or a
	ret


; this transforms the last japanese character
; in the name buffer into its dakuon shape or something.
; it seems to have been deprecated as the game was translated into english,
; but it can still be applied to english, such as upper-lower case transition.
; preserves bc
; input:
;	hl = character conversion data (e.g. TransitionTable1)
; output:
;	de = updated 2 byte character code
;	carry = set:  if there was no conversion
TransformCharacter:
	ld a, [wNamingScreenBufferLength]
	or a
	jr z, .return_carry ; if the length is zero, just return.
	dec a
	dec a
	push hl
	ld hl, wNamingScreenBuffer
	ld d, $00
	ld e, a
	add hl, de
	ld e, [hl]
	inc hl
	ld d, [hl]
	; de = last character in the buffer,
	; but byte-wise swapped.
	ld a, TX_KATAKANA
	cp e
	jr nz, .hiragana
	; if it's katakana,
	; make it hiragana by decreasing its high byte.
	dec e
.hiragana
	pop hl
.loop
	ld a, [hli]
	or a
	jr z, .return_carry ; reached the end of the table
	cp d
	jr nz, .next
	ld a, [hl]
	cp e
	jr nz, .next
	inc hl
	ld e, [hl]
	inc hl
	ld d, [hl]
	or a
	ret
.next
	inc hl
	inc hl
	inc hl
	jr .loop
.return_carry
	scf
	ret


; given the cursor position, returns the pointer to the character information.
; this function is very similar to 'DeckNamingScreen_GetCharInfoFromPos',
; except that the data structure has a different unit size (6 bytes instead of 3).
; preserves bc and de
; input:
;	h = x position
;	l = y position
; output:
;	hl = PlayerNamingScreen_KeyboardData pointer
PlayerNamingScreen_GetCharInfoFromPos:
	push de
	; (information index) = (x) * (height) + (y)
	; (height) = 0x05(Deck) or 0x06(Player)
	ld e, l
	ld d, h
	ld a, [wNamingScreenKeyboardHeight]
	ld l, a
	call HtimesL
	ld a, l
	add e
	ld hl, PlayerNamingScreen_KeyboardData
	pop de
	or a
	ret z
.loop
	inc hl
	inc hl
	inc hl
	inc hl
	inc hl
	inc hl
	dec a
	jr nz, .loop
	ret


; a set of keyboard datum.
; unit: 6 bytes.
; structure:
; abs. y pos. (1) / abs. x pos. (1) / type 1 (1) / type 2 (1) / char. code (2)
; unused data contains its character code as zero.
MACRO kbitem
	db \1, \2, \3, \4
	IF (_NARG == 5)
		dw \5
	ELIF (\5 == TX_FULLWIDTH0)
		dw (\5 << 8) | STRCAT("FW0_", \6)
	ELIF (\5 == TX_FULLWIDTH3)
		dw (\5 << 8) | STRCAT("FW3_", \6)
	ELSE
		dw (\5 << 8) | \6
	ENDC
ENDM

PlayerNamingScreen_KeyboardData:
	kbitem  4,  2, $11, $00, TX_FULLWIDTH3,   "A"
	kbitem  6,  2, $12, $00, TX_FULLWIDTH3,   "J"
	kbitem  8,  2, $13, $00, TX_FULLWIDTH3,   "S"
	kbitem 10,  2, $14, $00, TX_FULLWIDTH0,   "?"
	kbitem 12,  2, $15, $00, TX_FULLWIDTH0,   "4"
	kbitem 16, 15, $01, $09, $0000          ; "End"

	kbitem  4,  4, $16, $00, TX_FULLWIDTH3,   "B"
	kbitem  6,  4, $17, $00, TX_FULLWIDTH3,   "K"
	kbitem  8,  4, $18, $00, TX_FULLWIDTH3,   "T"
	kbitem 10,  4, $19, $00, TX_FULLWIDTH3,   "&"
	kbitem 12,  4, $1a, $00, TX_FULLWIDTH0,   "5"
	kbitem 16, 15, $01, $09, $0000          ; "End"

	kbitem  4,  6, $1b, $00, TX_FULLWIDTH3,   "C"
	kbitem  6,  6, $1c, $00, TX_FULLWIDTH3,   "L"
	kbitem  8,  6, $1d, $00, TX_FULLWIDTH3,   "U"
	kbitem 10,  6, $1e, $00, TX_FULLWIDTH0,   "+"
	kbitem 12,  6, $1f, $00, TX_FULLWIDTH0,   "6"
	kbitem 16, 15, $01, $09, $0000          ; "End"

	kbitem  4,  8, $20, $00, TX_FULLWIDTH3,   "D"
	kbitem  6,  8, $21, $00, TX_FULLWIDTH3,   "M"
	kbitem  8,  8, $22, $00, TX_FULLWIDTH3,   "V"
	kbitem 10,  8, $23, $00, TX_FULLWIDTH0,   "-"
	kbitem 12,  8, $24, $00, TX_FULLWIDTH0,   "7"
	kbitem 16, 15, $01, $09, $0000          ; "End"

	kbitem  4, 10, $25, $00, TX_FULLWIDTH3,   "E"
	kbitem  6, 10, $26, $00, TX_FULLWIDTH3,   "N"
	kbitem  8, 10, $27, $00, TX_FULLWIDTH3,   "W"
	kbitem 10, 10, $28, $00, TX_FULLWIDTH0,   "・"
	kbitem 12, 10, $29, $00, TX_FULLWIDTH0,   "8"
	kbitem 16, 15, $01, $09, $0000          ; "End"

	kbitem  4, 12, $2a, $00, TX_FULLWIDTH3,   "F"
	kbitem  6, 12, $2b, $00, TX_FULLWIDTH3,   "O"
	kbitem  8, 12, $2c, $00, TX_FULLWIDTH3,   "X"
	kbitem 10, 12, $2d, $00, TX_FULLWIDTH0,   "0"
	kbitem 12, 12, $2e, $00, TX_FULLWIDTH0,   "9"
	kbitem 16, 15, $01, $09, $0000          ; "End"

	kbitem  4, 14, $2f, $00, TX_FULLWIDTH3,   "G"
	kbitem  6, 14, $30, $00, TX_FULLWIDTH3,   "P"
	kbitem  8, 14, $31, $00, TX_FULLWIDTH3,   "Y"
	kbitem 10, 14, $32, $00, TX_FULLWIDTH0,   "1"
	kbitem 12, 14, $33, $00, TX_FULLWIDTH3,   "#"
	kbitem 16, 15, $01, $09, $0000          ; "End"

	kbitem  4, 16, $34, $00, TX_FULLWIDTH3,   "H"
	kbitem  6, 16, $35, $00, TX_FULLWIDTH3,   "Q"
	kbitem  8, 16, $36, $00, TX_FULLWIDTH3,   "Z"
	kbitem 10, 16, $3c, $00, TX_FULLWIDTH0,   "2"
	kbitem 12, 16, $3d, $00, TX_SYMBOL,       SYM_Lv
	kbitem 16, 15, $01, $09, $0000          ; "End"

	kbitem  4, 18, $37, $00, TX_FULLWIDTH3,   "I"
	kbitem  6, 18, $38, $00, TX_FULLWIDTH3,   "R"
	kbitem  8, 18, $39, $00, TX_FULLWIDTH0,   "!"
	kbitem 10, 18, $3a, $00, TX_FULLWIDTH0,   "3"
	kbitem 12, 18, $3b, $00, TX_FULLWIDTH0,   " "
	kbitem 16, 15, $01, $09, $0000          ; "End"
	kbitem $00, $00, $00, $00, $0000


; a set of transition datum use to apply dakuten to katakana characters.
; unit: 4 bytes.
; structure:
; previous char. code (2) / translated char. code (2)
; - the former char. code contains 0x0e in high byte.
; - the latter char. code contains only low byte.
TransitionTable1:
	dw $0e16, $003e ; ka -> ga
	dw $0e17, $003f ; ki -> gi
	dw $0e18, $0040 ; ku -> gu
	dw $0e19, $0041 ; ke -> ge
	dw $0e1a, $0042 ; ko -> go
	dw $0e1b, $0043 ; sa -> za
	dw $0e1c, $0044 ; shi -> ji
	dw $0e1d, $0045 ; su -> zu
	dw $0e1e, $0046 ; se -> ze
	dw $0e1f, $0047 ; so -> zo
	dw $0e20, $0048 ; ta -> da
	dw $0e21, $0049 ; chi -> dji
	dw $0e22, $004a ; tsu -> dzu
	dw $0e23, $004b ; te -> de
	dw $0e24, $004c ; to -> do
	dw $0e2a, $004d ; ha -> ba
	dw $0e2b, $004e ; hi -> bi
	dw $0e2c, $004f ; fu -> bu
	dw $0e2d, $0050 ; he -> be
	dw $0e2e, $0051 ; ho -> bo
	dw $0e52, $004d ; pa -> ba
	dw $0e53, $004e ; pi -> bi
	dw $0e54, $004f ; pu -> bu
	dw $0e55, $0050 ; pe -> be
	dw $0e56, $0051 ; po -> bo
	dw $0000


; a set of transition datum use to apply handakuten to katakana characters.
; it has the same unit size and structure as TransitionTable1.
TransitionTable2:
	dw $0e2a, $0052 ; ha -> pa
	dw $0e2b, $0053 ; hi -> pi
	dw $0e2c, $0054 ; fu -> pu
	dw $0e2d, $0055 ; he -> pe
	dw $0e2e, $0056 ; ho -> po
	dw $0e4d, $0052 ; ba -> pa
	dw $0e4e, $0053 ; bi -> pi
	dw $0e4f, $0054 ; bu -> pu
	dw $0e50, $0055 ; be -> pe
	dw $0e51, $0056 ; bo -> po
	dw $0000


; [Deck1Data ~ Deck4Data]
; These are directed from InputCurDeckName,
; without any bank description.
; That is, the developers hard-coded it. -_-;;
Deck1Data:
	textitem 2, 1, Deck1Text
	db $ff

Deck2Data:
	textitem 2, 1, Deck2Text
	db $ff

Deck3Data:
	textitem 2, 1, Deck3Text
	db $ff

Deck4Data:
	textitem 2, 1, Deck4Text
	db $ff

; gets a deck name from user input and stores it in [de].
; this function is similar to 'InputPlayerName'.
; input:
;	a = maximum length of a name (MAX_DECK_NAME_LENGTH)
;	bc = coordinates at which to begin printing the name
;	de = where to store the name (wCurDeckName)
;	hl = pointer for text items (Deck*Data)
InputDeckName:
	push af
	; check if the buffer is empty.
	ld a, [de]
	or a
	jr nz, .not_empty
	; this buffer will contain half-width characters.
	ld a, TX_HALFWIDTH
	ld [de], a
.not_empty
	pop af
	inc a
	call InitializeInputName
	call Set_OBJ_8x8

	xor a
	ld [wTileMapFill], a
	call EmptyScreen
	call ZeroObjectPositions

	ld a, $01
	ld [wVBlankOAMCopyToggle], a
	call LoadSymbolsFont

	lb de, $38, $bf
	call SetupText
	call LoadHalfWidthTextCursorTile

	xor a
	ld [wd009], a
	call DrawDeckNamingScreenBG

	xor a
	ld [wNamingScreenCursorX], a
	ld [wNamingScreenCursorY], a
	ld [wInvisibleCursorTile], a ; SYM_SPACE

	ld a, $09
	ld [wNamingScreenNumColumns], a
	ld a, $07
	ld [wNamingScreenKeyboardHeight], a
	ld a, SYM_CURSOR_R
	ld [wVisibleCursorTile], a
.loop
	ld a, $01
	ld [wVBlankOAMCopyToggle], a
	call DoFrame

	call UpdateRNGSources

	ldh a, [hDPadHeld]
	and START
	jr z, .else

	; the Start button was pressed.
	ld a, SFX_CONFIRM
	call PlaySFX
	call DeckNamingScreen_DrawInvisibleCursor

	ld a, 6
	ld [wNamingScreenCursorX], a
	ld [wNamingScreenCursorY], a
	call DeckNamingScreen_DrawVisibleCursor
	jr .loop

.else
	call DeckNamingScreen_CheckButtonState
	jr nc, .loop ; if not pressed, go back to the loop.

	cp -1
	jr z, .on_b_button

	; on A button
	call DeckNamingScreen_ProcessInput
	jr nc, .loop

	; Player selected the "End" button.
	call FinalizeInputName

	ld hl, wNamingScreenDestPointer
	ld a, [hli]
	ld h, [hl]
	ld l, a
	inc hl

	ld a, [hl]
	or a
	ret nz

	dec hl
	ld [hl], TX_END
	ret

.on_b_button
	ld a, [wNamingScreenBufferLength]
	cp $02
	jr c, .loop

	; erase one character.
	ld e, a
	ld d, $00
	ld hl, wNamingScreenBuffer
	add hl, de
	dec hl
	ld [hl], d ; add null terminator (TX_END)

	ld hl, wNamingScreenBufferLength
	dec [hl]
	call PrintDeckNameFromInput

	jr .loop


; loads, to the first tile of v0Tiles0, the graphics for the
; blinking black square used in name input screens for inputting half width text.
; this function is very similar to 'LoadTextCursorTile'.
; preserves de and c
LoadHalfWidthTextCursorTile:
	ld hl, v0Tiles0 + $00 tiles
	ld b, TILE_SIZE
	ld a, $f0
.loop
	ld [hli], a
	dec b
	jr nz, .loop
	ret


; this is called when naming a deck.
; it's similar to 'PrintPlayerNameFromInput'.
; preserves bc
; input:
;	[wNamingScreenNamePosition] = screen coordinates for printing (2 bytes)
;	[wNamingScreenBuffer] = name generated from keyboard input (up to 24 bytes)
PrintDeckNameFromInput:
	ld hl, wNamingScreenNamePosition
	ld d, [hl]
	inc hl
	ld e, [hl]
	call InitTextPrinting
	ld hl, .underbar_data
	ld de, wDefaultText
.loop
; copy the underbar string to wDefaultText
	ld a, [hli]
	ld [de], a
	inc de
	or a
	jr nz, .loop

	ld hl, wNamingScreenBuffer
	ld de, wDefaultText
.loop2
; copy the input from the user to wDefaultText
	ld a, [hli]
	or a
	jr z, .print_name
	ld [de], a
	inc de
	jr .loop2

.print_name
	ld hl, wDefaultText
	jp ProcessText

.underbar_data
	db TX_HALFWIDTH
REPT MAX_DECK_NAME_LENGTH
	db "_"
ENDR
	db TX_END


; draws the deck naming keyboard and prints the question, if it exists.
; this function is very similar to 'DrawPlayerNamingScreenBG'.
; input:
;	[wNamingScreenQuestionPointer] = pointer for text data (2 bytes)
DrawDeckNamingScreenBG:
	lb de, 0, 3 ; x, y
	lb bc, 20, 15 ; w, h
	call DrawRegularTextBox
	call PrintDeckNameFromInput
	; print situational text item(s) if pointer isn't null
	ld hl, wNamingScreenQuestionPointer
	ld a, [hli]
	ld h, [hl]
	ld l, a
	or h
	call nz, PlaceTextItems
	; print the keyboard characters and "End".
	ld hl, .data
	call PlaceTextItems
	jp EnableLCD
.data
	textitem 14,  1, DeckText ; " Deck"
	textitem  2,  4, DeckNameKeyboardText
	textitem 15, 16, EndText ; "End"
	db $ff


; output:
;	carry = set:  if "End" was selected on the keyboard
DeckNamingScreen_ProcessInput:
	ld a, [wNamingScreenCursorX]
	ld h, a
	ld a, [wNamingScreenCursorY]
	ld l, a
	call DeckNamingScreen_GetCharInfoFromPos
	inc hl
	inc hl
	ld a, [hl]
	cp $01 ; "End"
	scf
	ret z ; return carry if "End" was selected
	ld d, a
	ld hl, wNamingScreenBufferLength
	ld a, [hl]
	ld c, a
	push hl
	ld hl, wNamingScreenBufferMaxLength
	cp [hl]
	pop hl
	jr nz, .buffer_not_full
	; buffer is full, so just change the last character.
	ld hl, wNamingScreenBuffer
	dec hl
	jr .add_character_to_buffer

.buffer_not_full
; increase name length before adding the character.
	inc [hl]
	ld hl, wNamingScreenBuffer
.add_character_to_buffer
	ld b, $00
	add hl, bc
	ld [hl], d
	inc hl
	ld [hl], b ; add null terminator (TX_END)
	call PrintDeckNameFromInput
	or a
	ret


; checks if any buttons were pressed and handles the input.
; this function is similar to 'PlayerNamingScreen_CheckButtonState'.
; output:
;	carry = set:  if either the A button or the B button were pressed
DeckNamingScreen_CheckButtonState:
	xor a
	ld [wMenuInputSFX], a
	ldh a, [hDPadHeld]
	or a
	jr z, .check_A_or_B
	; detected any button press
	ld b, a
	ld a, [wNamingScreenKeyboardHeight]
	ld c, a
	ld a, [wNamingScreenCursorX]
	ld h, a
	ld a, [wNamingScreenCursorY]
	ld l, a
	bit D_UP_F, b
	jr z, .check_d_down
	; up
	dec a
	bit 7, a ; check underflow
	jr z, .adjust_y_position
	ld a, c
	dec a
	jr .adjust_y_position
.check_d_down
	bit D_DOWN_F, b
	jr z, .check_d_left
	; down
	inc a
	cp c
	jr c, .adjust_y_position
	xor a
.adjust_y_position
	ld l, a
	jr .update_keyboard_cursor
.check_d_left
	cp $06 ; cursor y = final keyboard row
	jr z, .check_A_or_B
	ld a, [wNamingScreenNumColumns]
	ld c, a
	ld a, h
	bit D_LEFT_F, b
	jr z, .check_d_right
	dec a
	bit 7, a ; check underflow
	jr z, .adjust_x_position
	ld a, c
	dec a
	jr .adjust_x_position
.check_d_right
	bit D_RIGHT_F, b
	jr z, .check_A_or_B
	inc a
	cp c
	jr c, .adjust_x_position
	xor a
.adjust_x_position
	ld h, a
.update_keyboard_cursor
	push hl
	call DeckNamingScreen_GetCharInfoFromPos
	inc hl
	inc hl
	ld d, [hl]
	push de
	call DeckNamingScreen_DrawInvisibleCursor
	pop de
	pop hl
	ld a, l
	ld [wNamingScreenCursorY], a
	ld a, h
	ld [wNamingScreenCursorX], a
	xor a
	ld [wCheckMenuCursorBlinkCounter], a
	ld a, $02 ; empty keyboard row
	cp d
	jr z, DeckNamingScreen_CheckButtonState
	ld a, SFX_CURSOR
	ld [wMenuInputSFX], a
.check_A_or_B
	ldh a, [hKeysPressed]
	and A_BUTTON | B_BUTTON
	jr z, .check_sfx_and_cursor_blink
	and A_BUTTON
	jr nz, .pressed_a
	; pressed B
	ld a, -1
.pressed_a
	call PlaySFXConfirmOrCancel_Bank6
	push af
	call DeckNamingScreen_DrawVisibleCursor
	pop af
	scf
	ret

.check_sfx_and_cursor_blink
	ld a, [wMenuInputSFX]
	or a
	call nz, PlaySFX
	ld hl, wCheckMenuCursorBlinkCounter
	ld a, [hl]
	inc [hl]
	and $0f
	ret nz
	ld a, [wVisibleCursorTile]
	bit 4, [hl]
	jr z, DeckNamingScreen_DrawCursor
;	fallthrough

DeckNamingScreen_DrawInvisibleCursor:
	ld a, [wInvisibleCursorTile]
;	fallthrough

; this function is very similar to 'PlayerNamingScreen_DrawCursor'.
; input:
;	a = which tile to draw
;	[wNamingScreenCursorX] = cursor's x position on the keyboard screen
;	[wNamingScreenCursorY] = cursor's y position on the keyboard screen
DeckNamingScreen_DrawCursor:
	ld e, a
	ld a, [wNamingScreenCursorX]
	ld h, a
	ld a, [wNamingScreenCursorY]
	ld l, a
	call DeckNamingScreen_GetCharInfoFromPos
	ld a, [hli]
	ld c, a
	ld b, [hl]
	dec b
	ld a, e
	call DeckNamingScreen_AdjustCursorPosition
	call WriteByteToBGMap0
	or a
	ret

DeckNamingScreen_DrawVisibleCursor:
	ld a, [wVisibleCursorTile]
	jr DeckNamingScreen_DrawCursor


; returns after calling ZeroObjectPositions if a = [wInvisibleCursorTile].
; otherwise, uses [wNamingScreenBufferLength], [wNamingScreenBufferMaxLength], and
; [wNamingScreenNamePosition] to determine x/y positions and calls SetOneObjectAttributes.
; this function is similar to 'PlayerNamingScreen_AdjustCursorPosition'.
; preserves all registers
; input:
;	a = cursor tile
DeckNamingScreen_AdjustCursorPosition:
	push af
	push bc
	push de
	push hl
	push af
	call ZeroObjectPositions
	pop af
	ld b, a
	ld a, [wInvisibleCursorTile]
	cp b
	jr z, .done
	ld a, [wNamingScreenBufferLength]
	ld d, a
	ld a, [wNamingScreenBufferMaxLength]
	ld e, a
	ld a, d
	cp e
	jr nz, .buffer_not_full
	dec a
.buffer_not_full
	dec a
	ld d, a
	ld hl, wNamingScreenNamePosition
	ld a, [hl]
	sla a
	add d
	ld d, a
	ld h, $04
	ld l, d
	call HtimesL
	ld a, l
	add $08
	ld d, a
	ld e, $18
	ld bc, $0000
	call SetOneObjectAttributes
.done
	pop hl
	pop de
	pop bc
	pop af
	ret


; given the cursor position, returns the pointer to the character information.
; this function is very similar to 'PlayerNamingScreen_GetCharInfoFromPos',
; except that the data structure has a different unit size (3 bytes instead of 6).
; preserves bc and de
; input:
;	h = x position
;	l = y position
; output:
;	hl = DeckNamingScreen_KeyboardData pointer
DeckNamingScreen_GetCharInfoFromPos:
	push de
	; (information index) = (x) * (height) + (y)
	; (height) = 0x05(Deck) or 0x06(Player)
	ld e, l
	ld d, h
	ld a, [wNamingScreenKeyboardHeight]
	ld l, a
	call HtimesL
	ld a, l
	add e
	ld hl, DeckNamingScreen_KeyboardData
	pop de
	or a
	ret z
.loop
	inc hl
	inc hl
	inc hl
	dec a
	jr nz, .loop
	ret

; a set of keyboard datum
; unit: 3 bytes
; structure: y position, x position, character code
DeckNamingScreen_KeyboardData:
	db  4,  2, "A"
	db  6,  2, "J"
	db  8,  2, "S"
	db 10,  2, "?"
	db 12,  2, "4"
	db 14,  2, $02
	db 16, 15, $01 ; "End"

	db  4,  4, "B"
	db  6,  4, "K"
	db  8,  4, "T"
	db 10,  4, "&"
	db 12,  4, "5"
	db 14,  4, $02
	db 16, 15, $01 ; "End"

	db  4,  6, "C"
	db  6,  6, "L"
	db  8,  6, "U"
	db 10,  6, "+"
	db 12,  6, "6"
	db 14,  6, $02
	db 16, 15, $01 ; "End"

	db  4,  8, "D"
	db  6,  8, "M"
	db  8,  8, "V"
	db 10,  8, "-"
	db 12,  8, "7"
	db 14,  8, $02
	db 16, 15, $01 ; "End"

	db  4, 10, "E"
	db  6, 10, "N"
	db  8, 10, "W"
	db 10, 10, "'"
	db 12, 10, "8"
	db 14, 10, $02
	db 16, 15, $01 ; "End"

	db  4, 12, "F"
	db  6, 12, "O"
	db  8, 12, "X"
	db 10, 12, "0"
	db 12, 12, "9"
	db 14, 12, $02
	db 16, 15, $01 ; "End"

	db  4, 14, "G"
	db  6, 14, "P"
	db  8, 14, "Y"
	db 10, 14, "1"
	db 12, 14, " "
	db 14, 14, $02
	db 16, 15, $01 ; "End"

	db  4, 16, "H"
	db  6, 16, "Q"
	db  8, 16, "Z"
	db 10, 16, "2"
	db 12, 16, " "
	db 14, 16, $02
	db 16, 15, $01 ; "End"

	db  4, 18, "I"
	db  6, 18, "R"
	db  8, 18, "!"
	db 10, 18, "3"
	db 12, 18, " "
	db 14, 18, $02
	db 16, 15, $01 ; "End"

	ds 4 ; empty
