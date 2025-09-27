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
	inc a ; cp -1
	ld a, SFX_CONFIRM
	jr nz, .play_sfx
	ld a, SFX_CANCEL
.play_sfx
	call PlaySFX
	pop af
	ret


; [Deck1Data ~ Deck4Data]
; These are directed from InputCurDeckName,
; without any bank description.
; That is, the developers hard-coded it. -_-;;
Deck1Data:
	textitem  2,  1, Deck1Text ; "1."
	textitem 14,  1, DeckText  ; " Deck"
	db $ff

Deck2Data:
	textitem  2,  1, Deck2Text ; "2."
	textitem 14,  1, DeckText  ; " Deck"
	db $ff

Deck3Data:
	textitem  2,  1, Deck3Text ; "3."
	textitem 14,  1, DeckText  ; " Deck"
	db $ff

Deck4Data:
	textitem  2,  1, Deck4Text ; "4."
	textitem 14,  1, DeckText  ; " Deck"
	db $ff

WhatIsYourNameData:
	textitem 2, 1, WhatIsYourNameText
	db $ff


; gets the Player's name from user input and stores it in wNameBuffer.
InputPlayerName:
	ld hl, WhatIsYourNameData
	ld de, wNameBuffer
	lb bc, 12, 1
	ld a, MAX_PLAYER_NAME_LENGTH
;	fallthrough

; gets a deck name from user input and stores it in [de].
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

	xor a ; SYM_SPACE
	ld [wTileMapFill], a
	call EmptyScreen
	call ZeroObjectPositionsAndToggleOAMCopy
	call LoadSymbolsFont

	lb de, $38, $bf
	call SetupText
	call LoadHalfWidthTextCursorTile

	xor a
	ld [wWhichKeyboard], a
	ld [wd009], a
	ld d, a ; x = 0
	ld e, a ; y = 0
	lb bc, 20, 18 ; w, h
	call DrawRegularTextBox
	ld b, SCREEN_WIDTH
	lb de, 0, 2
	call DrawTextBoxSeparator
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
	and PAD_SELECT | PAD_START
	jr z, .else
	and PAD_START
	jr nz, .pressed_start

; pressed SELECT
; changes the keyboard (Uppercase -> Lowercase -> Accents -> Uppercase...)
	ld a, SFX_CONFIRM
	call PlaySFX
	ld a, [wWhichKeyboard]
	inc a
	cp ACCENTS_KEYBOARD + 1
	jr c, .swap_keyboard
	xor a ; UPPERCASE_KEYBOARD
.swap_keyboard
	ld [wWhichKeyboard], a
	call DrawDeckNamingScreenBG
	jr .loop

.pressed_start
; moves cursor to the Done button
	ld a, SFX_CONFIRM
	call PlaySFX
	call DeckNamingScreen_DrawInvisibleCursor
	ld a, 4
	ld [wNamingScreenCursorX], a
	ld a, 6
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

	; Player selected the "Done" button.
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
	call DrawDeckNamingScreenBG
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
	ld hl, wDefaultText
	ld a, TX_HALFWIDTH
	ld [hli], a
	ld a, [wNamingScreenBufferMaxLength]
	dec a
	ld d, a
	ld a, "_"
.loop
	ld [hli], a
	dec d
	jr nz, .loop
	ld [hl], TX_END

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


; draws the deck naming keyboard and prints the question, if it exists.
; this function is very similar to 'DrawPlayerNamingScreenBG'.
; input:
;	[wNamingScreenQuestionPointer] = pointer for text data (2 bytes)
DrawDeckNamingScreenBG:
	; print situational text item(s) if pointer isn't null
	ld hl, wNamingScreenQuestionPointer
	ld a, [hli]
	ld h, [hl]
	ld l, a
	or h
	call nz, PlaceTextItems
	; print the keyboard text
	ld a, [wWhichKeyboard]
	add a
	ld e, a
	ld d, $00
	ld hl, KeyboardTextIDTable
	add hl, de
	ld a, [hli]
	ld h, [hl]
	ld l, a
	lb de, 2, 4
	call InitTextPrinting_ProcessTextFromID
	; print the text for the currently selected name
	call PrintDeckNameFromInput
	jp EnableLCD

KeyboardTextIDTable:
	tx UppercaseKeyboardText  ; UPPERCASE_KEYBOARD
	tx LowercaseKeyboardText  ; LOWERCASE_KEYBOARD
	tx AccentsKeyboardText    ; ACCENTS_KEYBOARD


; output:
;	carry = set:  if "Done" was selected on the keyboard
DeckNamingScreen_ProcessInput:
	ld a, [wNamingScreenCursorX]
	ld h, a
	ld a, [wNamingScreenCursorY]
	ld l, a
	call DeckNamingScreen_GetCharInfoFromPos
	inc hl
	inc hl
	ld a, [hl]
	cp $05
	jr nc, .normal_key
	dec a ; cp $01 ("Done")
	scf
	ret z ; return carry if "Done" was selected
	dec a
	; a = UPPERCASE_KEYBOARD if initial value was $02
	; a = LOWERCASE_KEYBOARD if initial value was $03
	; a = ACCENTS_KEYBOARD if initial value was $04
	ld [wWhichKeyboard], a
	jr .done

.normal_key
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
.done
	call DrawDeckNamingScreenBG
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
	bit B_PAD_UP, b
	jr z, .check_d_down
	; up
	dec a
	bit 7, a ; check underflow
	jr z, .adjust_y_position
	ld a, c
	dec a
	jr .adjust_y_position
.check_d_down
	bit B_PAD_DOWN, b
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
	ld a, l
	bit B_PAD_LEFT, b
	jr z, .check_d_right
	cp $06 ; cursor y = final keyboard row
	ld a, h
	dec a
	jr c, .check_underflow
	; buttons in bottom row are the size of 3 regular keys
	dec a
	dec a
.check_underflow
	bit 7, a
	jr z, .adjust_x_position
	ld a, c
	dec a
	jr .adjust_x_position
.check_d_right
	bit B_PAD_RIGHT, b
	jr z, .check_A_or_B
	cp $06 ; cursor y = final keyboard row
	ld a, h
	inc a
	jr c, .check_overflow
	; buttons in bottom row are the size of 3 regular keys
	inc a
	inc a
.check_overflow
	cp c
	jr c, .adjust_x_position
	xor a
.adjust_x_position
	ld h, a
.update_keyboard_cursor
	push hl
	call DeckNamingScreen_DrawInvisibleCursor
	pop hl
	ld a, l
	ld [wNamingScreenCursorY], a
	ld a, h
	ld [wNamingScreenCursorX], a
	xor a
	ld [wCheckMenuCursorBlinkCounter], a
	ld a, SFX_CURSOR
	ld [wMenuInputSFX], a
.check_A_or_B
	ldh a, [hKeysPressed]
	and PAD_A | PAD_B
	jr z, .check_sfx_and_cursor_blink
	and PAD_A
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
	add a
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
	ld a, [wNamingScreenKeyboardHeight]
	ld l, a
	call HtimesL
	ld a, l
	add e
	ld e, a
	ld a, [wWhichKeyboard]
	ld hl, DeckNamingScreen_UppercaseKeyboardData
	or a
	jr z, .check_position
	ld hl, DeckNamingScreen_LowercaseKeyboardData
	dec a
	jr z, .check_position
	ld hl, DeckNamingScreen_AccentsKeyboardData
.check_position
	ld a, e
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
DeckNamingScreen_UppercaseKeyboardData:
	db  4,  2, "A"
	db  6,  2, "J"
	db  8,  2, "S"
	db 10,  2, "1"
	db 12,  2, "("
	db 14,  2, "'"
	db 16,  2, $03 ; "Lowercase"

	db  4,  4, "B"
	db  6,  4, "K"
	db  8,  4, "T"
	db 10,  4, "2"
	db 12,  4, ")"
	db 14,  4, "”"
	db 16,  2, $03 ; "Lowercase"

	db  4,  6, "C"
	db  6,  6, "L"
	db  8,  6, "U"
	db 10,  6, "3"
	db 12,  6, "‹"
	db 14,  6, ","
	db 16,  2, $03 ; "Lowercase"

	db  4,  8, "D"
	db  6,  8, "M"
	db  8,  8, "V"
	db 10,  8, "4"
	db 12,  8, ">"
	db 14,  8, "."
	db 16,  9, $01 ; "Done"

	db  4, 10, "E"
	db  6, 10, "N"
	db  8, 10, "W"
	db 10, 10, "5"
	db 12, 10, "="
	db 14, 10, " "
	db 16,  9, $01 ; "Done"

	db  4, 12, "F"
	db  6, 12, "O"
	db  8, 12, "X"
	db 10, 12, "6"
	db 12, 12, "+"
	db 14, 12, "!"
	db 16,  9, $01 ; "Done"

	db  4, 14, "G"
	db  6, 14, "P"
	db  8, 14, "Y"
	db 10, 14, "7"
	db 12, 14, "-"
	db 14, 14, "?"
	db 16, 14, $04 ; "Accents"

	db  4, 16, "H"
	db  6, 16, "Q"
	db  8, 16, "Z"
	db 10, 16, "8"
	db 12, 16, "•"
	db 14, 16, ":"
	db 16, 14, $04 ; "Accents"

	db  4, 18, "I"
	db  6, 18, "R"
	db  8, 18, "0"
	db 10, 18, "9"
	db 12, 18, "/"
	db 14, 18, "&"
	db 16, 14, $04 ; "Accents"


; a set of keyboard datum
; unit: 3 bytes
; structure: y position, x position, character code
DeckNamingScreen_LowercaseKeyboardData:
	db  4,  2, "a"
	db  6,  2, "j"
	db  8,  2, "s"
	db 10,  2, "1"
	db 12,  2, "("
	db 14,  2, "'"
	db 16,  2, $02 ; "Uppercase"

	db  4,  4, "b"
	db  6,  4, "k"
	db  8,  4, "t"
	db 10,  4, "2"
	db 12,  4, ")"
	db 14,  4, "”"
	db 16,  2, $02 ; "Uppercase"

	db  4,  6, "c"
	db  6,  6, "l"
	db  8,  6, "u"
	db 10,  6, "3"
	db 12,  6, "‹"
	db 14,  6, ","
	db 16,  2, $02 ; "Uppercase"

	db  4,  8, "d"
	db  6,  8, "m"
	db  8,  8, "v"
	db 10,  8, "4"
	db 12,  8, ">"
	db 14,  8, "."
	db 16,  9, $01 ; "Done"

	db  4, 10, "e"
	db  6, 10, "n"
	db  8, 10, "w"
	db 10, 10, "5"
	db 12, 10, "="
	db 14, 10, " "
	db 16,  9, $01 ; "Done"

	db  4, 12, "f"
	db  6, 12, "o"
	db  8, 12, "x"
	db 10, 12, "6"
	db 12, 12, "+"
	db 14, 12, "!"
	db 16,  9, $01 ; "Done"

	db  4, 14, "g"
	db  6, 14, "p"
	db  8, 14, "y"
	db 10, 14, "7"
	db 12, 14, "-"
	db 14, 14, "?"
	db 16, 14, $04 ; "Accents"

	db  4, 16, "h"
	db  6, 16, "q"
	db  8, 16, "z"
	db 10, 16, "8"
	db 12, 16, "•"
	db 14, 16, ":"
	db 16, 14, $04 ; "Accents"

	db  4, 18, "i"
	db  6, 18, "r"
	db  8, 18, "0"
	db 10, 18, "9"
	db 12, 18, "/"
	db 14, 18, "&"
	db 16, 14, $04 ; "Accents"


; a set of keyboard datum
; unit: 3 bytes
; structure: y position, x position, character code
DeckNamingScreen_AccentsKeyboardData:
	db  4,  2, "À"
	db  6,  2, "Ê"
	db  8,  2, "Ô"
	db 10,  2, "à"
	db 12,  2, "ê"
	db 14,  2, "ô"
	db 16,  2, $02 ; "Uppercase"

	db  4,  4, "Á"
	db  6,  4, "Ë"
	db  8,  4, "Õ"
	db 10,  4, "á"
	db 12,  4, "ë"
	db 14,  4, "õ"
	db 16,  2, $02 ; "Uppercase"

	db  4,  6, "Â"
	db  6,  6, "Ì"
	db  8,  6, "Ö"
	db 10,  6, "â"
	db 12,  6, "ì"
	db 14,  6, "ö"
	db 16,  2, $02 ; "Uppercase"

	db  4,  8, "Ã"
	db  6,  8, "Í"
	db  8,  8, "Ù"
	db 10,  8, "ã"
	db 12,  8, "í"
	db 14,  8, "ù"
	db 16,  9, $01 ; "Done"

	db  4, 10, "Ä"
	db  6, 10, "Î"
	db  8, 10, "Ú"
	db 10, 10, "ä"
	db 12, 10, "î"
	db 14, 10, "ú"
	db 16,  9, $01 ; "Done"

	db  4, 12, "Å"
	db  6, 12, "Ï"
	db  8, 12, "Û"
	db 10, 12, "å"
	db 12, 12, "ï"
	db 14, 12, "û"
	db 16,  9, $01 ; "Done"

	db  4, 14, "Ç"
	db  6, 14, "Ñ"
	db  8, 14, "Ü"
	db 10, 14, "ç"
	db 12, 14, "ñ"
	db 14, 14, "ü"
	db 16, 14, $03 ; "Lowercase"

	db  4, 16, "È"
	db  6, 16, "Ò"
	db  8, 16, "Ý"
	db 10, 16, "è"
	db 12, 16, "ò"
	db 14, 16, "ý"
	db 16, 14, $03 ; "Lowercase"

	db  4, 18, "É"
	db  6, 18, "Ó"
	db  8, 18, "Ÿ"
	db 10, 18, "é"
	db 12, 18, "ó"
	db 14, 18, "ÿ"
	db 16, 14, $03 ; "Lowercase"


;----------------------------------------
;        UNREFERENCED FUNCTIONS
;----------------------------------------
;
;; gets the Player's name from user input and stores it in [hl].
;; input:
;;	hl = where to store the name (wNameBuffer)
;InputPlayerName:
;	ld e, l
;	ld d, h
;	ld a, MAX_PLAYER_NAME_LENGTH
;	ld hl, WhatIsYourNameData
;	lb bc, 12, 1
;	call InitializeInputName
;	call Set_OBJ_8x8
;	xor a ; SYM_SPACE
;	ld [wTileMapFill], a
;	call EmptyScreen
;	call ZeroObjectPositionsAndToggleOAMCopy
;	call LoadSymbolsFont
;	lb de, $38, $bf
;	call SetupText
;	call LoadTextCursorTile
;	ld a, $02
;	ld [wd009], a
;	call DrawPlayerNamingScreenBG
;	xor a
;	ld [wNamingScreenCursorX], a
;	ld [wNamingScreenCursorY], a
;	ld [wInvisibleCursorTile], a ; SYM_SPACE
;	ld a, $09
;	ld [wNamingScreenNumColumns], a
;	ld a, $06
;	ld [wNamingScreenKeyboardHeight], a
;	ld a, SYM_CURSOR_R
;	ld [wVisibleCursorTile], a
;.loop
;	ld a, $01
;	ld [wVBlankOAMCopyToggle], a
;	call DoFrame
;	call UpdateRNGSources
;	ldh a, [hDPadHeld]
;	and PAD_START
;	jr z, .else
;	; the Start button was pressed.
;	ld a, SFX_CONFIRM
;	call PlaySFX
;	call PlayerNamingScreen_DrawInvisibleCursor
;	ld a, 6
;	ld [wNamingScreenCursorX], a
;	ld a, 5
;	ld [wNamingScreenCursorY], a
;	call PlayerNamingScreen_DrawVisibleCursor
;	jr .loop
;
;.else
;	call PlayerNamingScreen_CheckButtonState
;	jr nc, .loop ; if not pressed, go back to the loop.
;	cp -1
;	jr z, .on_b_button
;	; on A button
;	call PlayerNamingScreen_ProcessInput
;	jr nc, .loop
;	; player selected the "End" button.
;	jr FinalizeInputName
;
;.on_b_button
;	ld a, [wNamingScreenBufferLength]
;	or a
;	jr z, .loop ; empty string?
;	; erase one character.
;	ld e, a
;	ld d, $00
;	ld hl, wNamingScreenBuffer
;	add hl, de
;	dec hl
;	dec hl
;	ld [hl], d ; add null terminator (TX_END)
;	ld hl, wNamingScreenBufferLength ; note that its unit is byte, not word.
;	dec [hl]
;	dec [hl]
;	call PrintPlayerNameFromInput
;	jr .loop
;
;
;; draws the player naming keyboard and prints the question, if it exists.
;; this function is very similar to 'DrawDeckNamingScreenBG'.
;; input:
;;	[wNamingScreenQuestionPointer] = pointer for text data (2 bytes)
;DrawPlayerNamingScreenBG:
;	lb de, 0, 3 ; x, y
;	lb bc, 20, 15 ; w, h
;	call DrawRegularTextBox
;	call PrintPlayerNameFromInput
;	; print the question string.
;	; ex) "What is your name?"
;	ld hl, wNamingScreenQuestionPointer
;	ld a, [hli]
;	ld h, [hl]
;	ld l, a
;	or h
;	call nz, PlaceTextItems ; only print text item(s) if pointer isn't null
;	; print the keyboard characters and "End".
;	ld hl, .data
;	call PlaceTextItems
;	jp EnableLCD
;.data
;	textitem  2,  4, PlayerNameKeyboardText
;	textitem 15, 16, EndText ; "End"
;	db $ff
;
;
;; this is called when naming the player character.
;; it's similar to 'PrintDeckNameFromInput'.
;; preserves bc
;; input:
;;	[wNamingScreenNamePosition] = screen coordinates for printing (2 bytes)
;;	[wNamingScreenBufferMaxLength] = MAX_PLAYER_NAME_LENGTH
;;	[wNamingScreenBuffer] = name generated from keyboard input (up to 24 bytes)
;PrintPlayerNameFromInput:
;	ld hl, wNamingScreenNamePosition
;	ld d, [hl]
;	inc hl
;	ld e, [hl]
;	call InitTextPrinting
;	ld hl, .underbar_data
;	ld de, wDefaultText
;.loop
;; copy the underbar string to wDefaultText
;	ld a, [hli]
;	ld [de], a
;	inc de
;	or a
;	jr nz, .loop
;
;	ld hl, wNamingScreenBuffer
;	ld de, wDefaultText
;.loop2
;; copy the input from the user to wDefaultText
;	ld a, [hli]
;	or a
;	jr z, .print_name
;	ld [de], a
;	inc de
;	jr .loop2
;
;.print_name
;	ld hl, wDefaultText
;	jp ProcessText
;
;.underbar_data
;	textfw "______"
;	done
;
;
;; checks if any buttons were pressed and handles the input.
;; this function is similar to 'DeckNamingScreen_CheckButtonState'.
;; output:
;;	carry = set:  if either the A button or the B button were pressed
;PlayerNamingScreen_CheckButtonState:
;	xor a
;	ld [wMenuInputSFX], a
;	ldh a, [hDPadHeld]
;	or a
;	jp z, .check_A_or_B
;	; detected any button press.
;	ld b, a
;	ld a, [wNamingScreenKeyboardHeight]
;	ld c, a
;	ld a, [wNamingScreenCursorX]
;	ld h, a
;	ld a, [wNamingScreenCursorY]
;	ld l, a
;	bit B_PAD_UP, b
;	jr z, .check_d_down
;	; up
;	dec a
;	bit 7, a ; check underflow
;	jr z, .adjust_y_position
;	ld a, c
;	dec a
;	jr .adjust_y_position
;.check_d_down
;	bit B_PAD_DOWN, b
;	jr z, .check_d_left
;	; down
;	inc a
;	cp c
;	jr c, .adjust_y_position
;	xor a
;.adjust_y_position
;	ld l, a
;	jr .update_keyboard_cursor
;.check_d_left
;	ld a, [wNamingScreenNumColumns]
;	ld c, a
;	ld a, h
;	bit B_PAD_LEFT, b
;	jr z, .check_d_right
;	; left
;	ld d, a
;	ld a, $06 ; cursor y = final keyboard row
;	cp l
;	ld a, d
;	jr nz, .check_if_can_move_left
;	; cursor's in the bottom row
;	push hl
;	push af
;	call PlayerNamingScreen_GetCharInfoFromPos
;	inc hl
;	inc hl
;	inc hl
;	inc hl
;	inc hl
;	ld a, [hl]
;	dec a
;	ld d, a
;	pop af
;	pop hl
;	sub d ; cursor x position - (selected key's character code - 1)
;	cp -1
;	jr nz, .asm_6962
;	ld a, c
;	sub $02 ; number of columns in keyboard - 2
;	; a = 7
;	jr .adjust_x_position
;.asm_6962
;	cp -2
;	jr nz, .check_if_can_move_left
;	ld a, c
;	sub $03 ; number of columns in keyboard - 3
;	; a = 6
;	jr .adjust_x_position
;.check_if_can_move_left
;	dec a
;	bit 7, a ; check underflow
;	jr z, .adjust_x_position
;	ld a, c
;	dec a
;	jr .adjust_x_position
;.check_d_right
;	bit B_PAD_RIGHT, b
;	jr z, .check_A_or_B
;	ld d, a
;	ld a, $06 ; cursor y = final keyboard row
;	cp l
;	ld a, d
;	jr nz, .check_if_can_move_right
;	; cursor's in the bottom row
;	push hl
;	push af
;	call PlayerNamingScreen_GetCharInfoFromPos
;	inc hl
;	inc hl
;	inc hl
;	inc hl
;	ld a, [hl]
;	dec a
;	ld d, a
;	pop af
;	pop hl
;	add d ; cursor x position + (selected key's font type code - 1)
;.check_if_can_move_right
;	inc a
;	cp c
;	jr c, .adjust_x_position
;	inc c
;	cp c
;	jr c, .reset_x_position
;	inc c
;	cp c
;	ld a, $02
;	jr nc, .adjust_x_position
;	dec a ; $01
;	jr .adjust_x_position
;.reset_x_position
;	xor a
;.adjust_x_position
;	ld h, a
;.update_keyboard_cursor
;	push hl
;	call PlayerNamingScreen_GetCharInfoFromPos
;	inc hl
;	inc hl
;	inc hl
;	ld a, [wd009]
;	cp $02
;	jr nz, .asm_69bb
;	inc hl
;	inc hl
;.asm_69bb
;	ld d, [hl]
;	push de
;	call PlayerNamingScreen_DrawInvisibleCursor
;	pop de
;	pop hl
;	ld a, l
;	ld [wNamingScreenCursorY], a
;	ld a, h
;	ld [wNamingScreenCursorX], a
;	xor a
;	ld [wCheckMenuCursorBlinkCounter], a
;	ld a, $06
;	cp d
;	jp z, PlayerNamingScreen_CheckButtonState
;	ld a, SFX_CURSOR
;	ld [wMenuInputSFX], a
;.check_A_or_B
;	ldh a, [hKeysPressed]
;	and PAD_A | PAD_B
;	jr z, .check_sfx_and_cursor_blink
;	and PAD_A
;	jr nz, .pressed_a
;	; pressed B
;	ld a, -1
;.pressed_a
;	call PlaySFXConfirmOrCancel_Bank6
;	push af
;	call PlayerNamingScreen_DrawVisibleCursor
;	pop af
;	scf
;	ret
;
;.check_sfx_and_cursor_blink
;	ld a, [wMenuInputSFX]
;	or a
;	call nz, PlaySFX
;	ld hl, wCheckMenuCursorBlinkCounter
;	ld a, [hl]
;	inc [hl]
;	and $0f
;	ret nz
;	ld a, [wVisibleCursorTile]
;	bit 4, [hl]
;	jr z, PlayerNamingScreen_DrawCursor
;;	fallthrough
;
;PlayerNamingScreen_DrawInvisibleCursor:
;	ld a, [wInvisibleCursorTile]
;;	fallthrough
;
;; this function is very similar to 'DeckNamingScreen_DrawCursor'.
;; input:
;;	a = which tile to draw
;;	[wNamingScreenCursorX] = cursor's x position on the keyboard screen
;;	[wNamingScreenCursorY] = cursor's y position on the keyboard screen
;PlayerNamingScreen_DrawCursor:
;	ld e, a
;	ld a, [wNamingScreenCursorX]
;	ld h, a
;	ld a, [wNamingScreenCursorY]
;	ld l, a
;	call PlayerNamingScreen_GetCharInfoFromPos
;	ld a, [hli]
;	ld c, a
;	ld b, [hl]
;	dec b
;	ld a, e
;	call PlayerNamingScreen_AdjustCursorPosition
;	call WriteByteToBGMap0
;	or a
;	ret
;
;PlayerNamingScreen_DrawVisibleCursor:
;	ld a, [wVisibleCursorTile]
;	jr PlayerNamingScreen_DrawCursor
;
;
;; returns after calling ZeroObjectPositions if a = [wInvisibleCursorTile].
;; otherwise, uses [wNamingScreenBufferLength], [wNamingScreenBufferMaxLength], and
;; [wNamingScreenNamePosition] to determine x/y positions and calls SetOneObjectAttributes.
;; this function is similar to 'DeckNamingScreen_AdjustCursorPosition'.
;; preserves all registers
;; input:
;;	a = cursor tile
;PlayerNamingScreen_AdjustCursorPosition:
;	push af
;	push bc
;	push de
;	push hl
;	push af
;	call ZeroObjectPositions
;	pop af
;	ld b, a
;	ld a, [wInvisibleCursorTile]
;	cp b
;	jr z, .done
;	ld a, [wNamingScreenBufferLength]
;	srl a
;	ld d, a
;	ld a, [wNamingScreenBufferMaxLength]
;	srl a
;	ld e, a
;	ld a, d
;	cp e
;	jr nz, .buffer_not_full
;	dec a
;.buffer_not_full
;	ld hl, wNamingScreenNamePosition
;	add [hl]
;	ld d, a
;	ld h, $08
;	ld l, d
;	call HtimesL
;	ld a, l
;	add $08
;	ld d, a
;	ld e, $18
;	ld bc, $0000
;	call SetOneObjectAttributes
;.done
;	pop hl
;	pop de
;	pop bc
;	pop af
;	ret
;
;
;; loads, to the first tile of v0Tiles0, the graphics for the blinking black square
;; used in name input screens for inputting full width text.
;; this function is very similar to 'LoadHalfWidthTextCursorTile'.
;; preserves de and c
;LoadTextCursorTile:
;	ld hl, v0Tiles0 + $00 tiles
;	ld b, TILE_SIZE
;	ld a, $ff
;.loop
;	ld [hli], a
;	dec b
;	jr nz, .loop
;	ret
;
;
;; output:
;;	carry = set:  if "End" was selected on the keyboard
;PlayerNamingScreen_ProcessInput:
;	ld a, [wNamingScreenCursorX]
;	ld h, a
;	ld a, [wNamingScreenCursorY]
;	ld l, a
;	call PlayerNamingScreen_GetCharInfoFromPos
;	inc hl
;	inc hl
;	; load types into de.
;	ld e, [hl]
;	inc hl
;	ld a, [hli]
;	ld d, a
;	cp $09 ; "End"
;	scf
;	ret z ; return carry if "End" was selected
;
;; everything from this point up until .read_char doesn't seem like it's ever used.
;; it's probably left over from the original Japanese input data.
;	cp $07
;	jr nz, .next_1
;	ld a, [wd009]
;	or a
;	jr z, .store_one
;	dec a
;	jr z, .store_two
;	xor a
;	jr .set_var
;.next_1
;	cp $08
;	jr nz, .next_2
;	ld a, [wd009]
;	or a
;	jr z, .store_two
;	dec a
;	jr z, .set_var
;.store_one
;	ld a, $01
;	; fallthrough
;.set_var
;	ld [wd009], a
;	call DrawPlayerNamingScreenBG
;	or a
;	ret
;.store_two
;	ld a, $02
;	jr .set_var
;
;.next_2
;	ld a, [wd009]
;	cp $02
;	jr z, .read_char
;; check dakuten
;	ldfw bc, "゛"
;	ld a, d
;	cp b
;	jr nz, .check_handakuten
;	ld a, e
;	cp c
;	jr nz, .check_handakuten
;	push hl
;	ld hl, TransitionTable1 ; from 55th.
;	call TransformCharacter
;	pop hl
;	jr nc, .return_to_previous_char
;.cannot_transform
;	or a
;	ret
;
;.check_handakuten
;	ldfw bc, "゜"
;	ld a, d
;	cp b
;	jr nz, .check_font_type
;	ld a, e
;	cp c
;	jr nz, .check_font_type
;	push hl
;	ld hl, TransitionTable2 ; from 72th.
;	call TransformCharacter
;	pop hl
;	jr c, .cannot_transform
;.return_to_previous_char
;	ld a, [wNamingScreenBufferLength]
;	dec a
;	dec a
;	ld [wNamingScreenBufferLength], a
;	ld hl, wNamingScreenBuffer
;	push de
;	ld d, $00
;	ld e, a
;	add hl, de
;	pop de
;	ld a, [hl]
;	jr .check_name_buffer
;
;.check_font_type
;	ld a, d
;	or a
;	jr nz, .check_name_buffer
;	ld a, [wd009]
;	or a
;	jr z, .use_hiragana
;	ld a, TX_KATAKANA
;	jr .check_name_buffer
;
;; read character code from info. to register.
;; input:
;;	hl = pointer
;.read_char
;	ld e, [hl]
;	inc hl
;	ld a, [hl] ; a = first byte of the code.
;	or a
;	; if 2 bytes code, jump.
;	jr nz, .check_name_buffer
;.use_hiragana
;	ld a, TX_HIRAGANA
;.check_name_buffer
;	ld d, a ; de = character code
;	ld hl, wNamingScreenBufferLength
;	ld a, [hl]
;	ld c, a
;	push hl
;	ld hl, wNamingScreenBufferMaxLength
;	cp [hl]
;	pop hl
;	jr nz, .buffer_not_full
;	; buffer is full, so just change the last character.
;	ld hl, wNamingScreenBuffer
;	dec hl
;	dec hl
;	jr .add_character_to_buffer
;
;; increase name length before adding the character.
;.buffer_not_full
;	inc [hl]
;	inc [hl]
;	ld hl, wNamingScreenBuffer
;
;; write 2 byte character codes to the name buffer.
;; input:
;;	c  = wNamingScreenBufferLength
;;	de = 2 byte character code
;;	hl = copy destination
;.add_character_to_buffer
;	ld b, $00
;	add hl, bc
;	ld [hl], d
;	inc hl
;	ld [hl], e
;	inc hl
;	ld [hl], b ; add null terminator (TX_END)
;	call PrintPlayerNameFromInput
;	or a
;	ret
;
;
;; this transforms the last japanese character
;; in the name buffer into its dakuon shape or something.
;; it seems to have been deprecated as the game was translated into english,
;; but it can still be applied to english, such as upper-lower case transition.
;; preserves bc
;; input:
;;	hl = character conversion data (e.g. TransitionTable1)
;; output:
;;	de = updated 2 byte character code
;;	carry = set:  if there was no conversion
;TransformCharacter:
;	ld a, [wNamingScreenBufferLength]
;	or a
;	jr z, .return_carry ; if the length is zero, just return.
;	dec a
;	dec a
;	push hl
;	ld hl, wNamingScreenBuffer
;	ld d, $00
;	ld e, a
;	add hl, de
;	ld e, [hl]
;	inc hl
;	ld d, [hl]
;	; de = last character in the buffer,
;	; but byte-wise swapped.
;	ld a, TX_KATAKANA
;	cp e
;	jr nz, .hiragana
;	; if it's katakana,
;	; make it hiragana by decreasing its high byte.
;	dec e
;.hiragana
;	pop hl
;.loop
;	ld a, [hli]
;	or a
;	jr z, .return_carry ; reached the end of the table
;	cp d
;	jr nz, .next
;	ld a, [hl]
;	cp e
;	jr nz, .next
;	inc hl
;	ld e, [hl]
;	inc hl
;	ld d, [hl]
;	or a
;	ret
;.next
;	inc hl
;	inc hl
;	inc hl
;	jr .loop
;.return_carry
;	scf
;	ret
;
;
;; given the cursor position, returns the pointer to the character information.
;; this function is very similar to 'DeckNamingScreen_GetCharInfoFromPos',
;; except that the data structure has a different unit size (6 bytes instead of 3).
;; preserves bc and de
;; input:
;;	h = x position
;;	l = y position
;; output:
;;	hl = PlayerNamingScreen_KeyboardData pointer
;PlayerNamingScreen_GetCharInfoFromPos:
;	push de
;	; (information index) = (x) * (height) + (y)
;	; (height) = 0x05(Deck) or 0x06(Player)
;	ld e, l
;	ld d, h
;	ld a, [wNamingScreenKeyboardHeight]
;	ld l, a
;	call HtimesL
;	ld a, l
;	add e
;	ld hl, PlayerNamingScreen_KeyboardData
;	pop de
;	or a
;	ret z
;.loop
;	inc hl
;	inc hl
;	inc hl
;	inc hl
;	inc hl
;	inc hl
;	dec a
;	jr nz, .loop
;	ret
;
;
;; a set of keyboard datum.
;; unit: 6 bytes.
;; structure:
;; abs. y pos. (1) / abs. x pos. (1) / type 1 (1) / type 2 (1) / char. code (2)
;; unused data contains its character code as zero.
;MACRO kbitem
;	db \1, \2, \3, \4
;	PUSHC fullwidth
;	IF (_NARG > 4)
;		dwfw \5
;	ELSE
;		dw 0
;	ENDC
;	POPC
;ENDM
;
;PlayerNamingScreen_KeyboardData:
;	kbitem $04, $02, $11, $00, "A"
;	kbitem $06, $02, $12, $00, "J"
;	kbitem $08, $02, $13, $00, "S"
;	kbitem $0a, $02, $14, $00, "?"
;	kbitem $0c, $02, $15, $00, "4"
;	kbitem $10, $0f, $01, $09
;
;	kbitem $04, $04, $16, $00, "B"
;	kbitem $06, $04, $17, $00, "K"
;	kbitem $08, $04, $18, $00, "T"
;	kbitem $0a, $04, $19, $00, "&"
;	kbitem $0c, $04, $1a, $00, "5"
;	kbitem $10, $0f, $01, $09
;
;	kbitem $04, $06, $1b, $00, "C"
;	kbitem $06, $06, $1c, $00, "L"
;	kbitem $08, $06, $1d, $00, "U"
;	kbitem $0a, $06, $1e, $00, "+"
;	kbitem $0c, $06, $1f, $00, "6"
;	kbitem $10, $0f, $01, $09
;
;	kbitem $04, $08, $20, $00, "D"
;	kbitem $06, $08, $21, $00, "M"
;	kbitem $08, $08, $22, $00, "V"
;	kbitem $0a, $08, $23, $00, "-"
;	kbitem $0c, $08, $24, $00, "7"
;	kbitem $10, $0f, $01, $09
;
;	kbitem $04, $0a, $25, $00, "E"
;	kbitem $06, $0a, $26, $00, "N"
;	kbitem $08, $0a, $27, $00, "W"
;	kbitem $0a, $0a, $28, $00, "・"
;	kbitem $0c, $0a, $29, $00, "8"
;	kbitem $10, $0f, $01, $09
;
;	kbitem $04, $0c, $2a, $00, "F"
;	kbitem $06, $0c, $2b, $00, "O"
;	kbitem $08, $0c, $2c, $00, "X"
;	kbitem $0a, $0c, $2d, $00, "0"
;	kbitem $0c, $0c, $2e, $00, "9"
;	kbitem $10, $0f, $01, $09
;
;	kbitem $04, $0e, $2f, $00, "G"
;	kbitem $06, $0e, $30, $00, "P"
;	kbitem $08, $0e, $31, $00, "Y"
;	kbitem $0a, $0e, $32, $00, "1"
;	kbitem $0c, $0e, $33, $00, "#"
;	kbitem $10, $0f, $01, $09
;
;	kbitem $04, $10, $34, $00, "H"
;	kbitem $06, $10, $35, $00, "Q"
;	kbitem $08, $10, $36, $00, "Z"
;	kbitem $0a, $10, $3c, $00, "2"
;	kbitem $0c, $10, $3d, $00, "[Lv.]"
;	kbitem $10, $0f, $01, $09
;
;	kbitem $04, $12, $37, $00, "I"
;	kbitem $06, $12, $38, $00, "R"
;	kbitem $08, $12, $39, $00, "!"
;	kbitem $0a, $12, $3a, $00, "3"
;	kbitem $0c, $12, $3b, $00, " "
;	kbitem $10, $0f, $01, $09
;	kbitem $00, $00, $00, $00
;
;MACRO diacritic
;	PUSHC hiragana
;	db \1, TX_HIRAGANA
;	db \2, 0
;	POPC
;ENDM
;
;
;; a set of transition datum use to apply dakuten to katakana characters.
;; unit: 4 bytes.
;; structure:
;; previous char. code (2) / translated char. code (2)
;; - the former char. code contains 0x0e in high byte.
;; - the latter char. code contains only low byte.
;TransitionTable1:
;	diacritic "か", "が" ; katakana カ, ガ
;	diacritic "き", "ぎ" ; katakana キ, ギ
;	diacritic "く", "ぐ" ; katakana ク, グ
;	diacritic "け", "げ" ; katakana ケ, ゲ
;	diacritic "こ", "ご" ; katakana コ, ゴ
;	diacritic "さ", "ざ" ; katakana サ, ザ
;	diacritic "し", "じ" ; katakana シ, ジ
;	diacritic "す", "ず" ; katakana ス, ズ
;	diacritic "せ", "ぜ" ; katakana セ, ゼ
;	diacritic "そ", "ぞ" ; katakana ソ, ゾ
;	diacritic "た", "だ" ; katakana タ, ダ
;	diacritic "ち", "ぢ" ; katakana チ, ヂ
;	diacritic "つ", "づ" ; katakana ツ, ヅ
;	diacritic "て", "で" ; katakana テ, デ
;	diacritic "と", "ど" ; katakana ト, ド
;	diacritic "は", "ば" ; katakana ハ, バ
;	diacritic "ひ", "び" ; katakana ヒ, ビ
;	diacritic "ふ", "ぶ" ; katakana フ, ブ
;	diacritic "へ", "べ" ; katakana ヘ, ベ
;	diacritic "ほ", "ぼ" ; katakana ホ, ボ
;	diacritic "ぱ", "ば" ; katakana パ, バ
;	diacritic "ぴ", "び" ; katakana ピ, ビ
;	diacritic "ぷ", "ぶ" ; katakana プ, ブ
;	diacritic "ぺ", "べ" ; katakana ペ, ベ
;	diacritic "ぽ", "ぼ" ; katakana ポ, ボ
;	dw 0 ; end
;
;
;; a set of transition datum use to apply handakuten to katakana characters.
;; it has the same unit size and structure as TransitionTable1.
;TransitionTable2:
;	diacritic "は", "ぱ" ; katakana ハ, パ
;	diacritic "ひ", "ぴ" ; katakana ヒ, ピ
;	diacritic "ふ", "ぷ" ; katakana フ, プ
;	diacritic "へ", "ぺ" ; katakana ヘ, ペ
;	diacritic "ほ", "ぽ" ; katakana ホ, ポ
;	diacritic "ば", "ぱ" ; katakana バ, パ
;	diacritic "び", "ぴ" ; katakana ビ, ピ
;	diacritic "ぶ", "ぷ" ; katakana ブ, プ
;	diacritic "べ", "ぺ" ; katakana ベ, ペ
;	diacritic "ぼ", "ぽ" ; katakana ボ, ポ
;	dw 0 ; end
