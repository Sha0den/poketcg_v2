; writes n items of text, each given in the following format in hl:
;		x coord, y coord, text ID
;		...
;		db $ff
; preserves bc
; input:
;	hl = $ff-terminated list of text items to print
PlaceTextItems::
	ld d, [hl] ; x coordinate
	inc hl
	bit 7, d
	ret nz ; return if no more items of text
	ld e, [hl] ; y coordinate
	inc hl ; hl = text ID
	push hl
	call InitTextPrinting_ProcessTextFromPointerToID
	pop hl
	inc hl
	inc hl
	jr PlaceTextItems ; do next item


; like ProcessTextFromID, except it calls InitTextPrinting first
; preserves bc and de
; input:
;	de = screen coordinates at which to begin printing the text
;	hl = text ID
InitTextPrinting_ProcessTextFromID::
	call InitTextPrinting
	jr ProcessTextFromID

; like ProcessTextFromPointerToID, except it calls InitTextPrinting first
; preserves bc and de
; input:
;	de = screen coordinates at which to begin printing the text
;	[hl] = text ID
InitTextPrinting_ProcessTextFromPointerToID::
	call InitTextPrinting
;	fallthrough

; like ProcessTextFromID below, except a memory address containing a text ID is
; provided in hl rather than the text ID directly.
; preserves bc and de
; input:
;	[hl] = text ID
ProcessTextFromPointerToID::
	ld a, [hli]
	ld h, [hl]
	ld l, a
	or h
	ret z ; return if the pointer is null
;	fallthrough

; given the ID of a text in hl, reads the characters from it
; and processes them, looping until TX_END is found.
; ignores TX_RAM1, TX_RAM2, and TX_RAM3 characters.
; restores original ROM bank before returning.
; preserves bc and de
; input:
;	hl = text ID
ProcessTextFromID::
	ldh a, [hBankROM]
	push af
	call GetTextOffsetFromTextID
	call ProcessText
	pop af
	jp BankswitchROM


; finds the number of lines contained in a given text (by counting '\n' characters)
; preserves all registers except af
; input:
;	hl = text ID
; output:
;	a = number of lines in the text from input
CountLinesOfTextFromID::
	push hl
	push de
	push bc
	ldh a, [hBankROM]
	push af
	call GetTextOffsetFromTextID
	ld c, $00
.char_loop
	ld a, [hli]
	or a ; TX_END
	jr z, .end
	cp TX_CTRL_END
	jr nc, .char_loop
	cp TX_HALFWIDTH
	jr c, .skip
	cp "\n"
	jr nz, .char_loop
	inc c
	jr .char_loop
.skip
	inc hl
	jr .char_loop
.end
	pop af
	rst BankswitchROM
	ld a, c
	inc a
	pop bc
	pop de
	pop hl
	ret


; calls PrintScrollableText with no text box label, then waits for the
; player to press A or B to advance the printed text
; input:
;	hl = text ID for the scrollable text
; output:
;	carry = set:  if the B button was pressed
PrintScrollableText_NoTextBoxLabel::
	xor a
	call PrintScrollableText
;	fallthrough

; when a text box is full or the text is over, this prompts the player to
; press A or B in order to clear the text and print the next lines.
WaitForPlayerToAdvanceText::
	lb bc, SYM_CURSOR_D, SYM_BOX_BOTTOM ; cursor tile, tile behind cursor
	lb de, 18, 17 ; x, y
	call SetCursorParametersForTextBox
	jp WaitForButtonAorB

; calls PrintScrollableText with text box label, then waits for the
; player to press A or B to advance the printed text
; input:
;	de = text ID for the text box label
;	hl = text ID for the scrollable text
; output:
;	carry = set:  if the B button was pressed
PrintScrollableText_WithTextBoxLabel::
	call PrintScrollableText_WithTextBoxLabel_NoWait
	jr WaitForPlayerToAdvanceText


; input:
;	de = text ID for the text box label
;	hl = text ID for the scrollable text
PrintScrollableText_WithTextBoxLabel_NoWait::
	push hl
	ld hl, wTextBoxLabel
	ld [hl], e
	inc hl
	ld [hl], d
	pop hl
	ld a, $01
;	fallthrough

; draws a text box, and prints the text with ID at hl, with letter delay.
; unlike PrintText, PrintScrollableText also supports scrollable text and
; prompts the user to press either A or B to advance the page or close the text.
; register a determines whether the textbox is labeled or not.
; if labeled, the text ID of the label is provided in wTextBoxLabel.
; PrintScrollableText is used mostly for overworld NPC text.
; input:
;	hl = text ID for the scrollable text
;	a == 0:  don't use a label for the text box
;	a != 0:  use a label for the text
;	[wTextBoxLabel] = text ID for the label:  if a != 0
PrintScrollableText::
	ld [wIsTextBoxLabeled], a
	ldh a, [hBankROM]
	push af
	call GetTextOffsetFromTextID
	call DrawTextReadyLabeledOrRegularTextBox
	call ResetTxRam_WriteToTextHeader
.print_char_loop
	ld a, [wTextSpeed]
	ld c, a
	inc c
	jr .go
.nonzero_text_speed
	ld a, [wTextSpeed]
	cp TEXT_SPEED_1
	jr nc, .apply_delay
	; unless TEXT_SPEED_1 is selected, then pressing the B button will skip the delay
	ldh a, [hKeysHeld]
	and PAD_B
	jr nz, .skip_delay
.apply_delay
	call DoFrame
.go
	dec c
	jr nz, .nonzero_text_speed
.skip_delay
	call ProcessTextHeader
	jr c, .asm_2cc3
	ld a, [wCurTextLine]
	cp 3
	jr c, .print_char_loop
	; two lines of text already printed, so need to advance text
	call WaitForPlayerToAdvanceText
	call DrawTextReadyLabeledOrRegularTextBox
	jr .print_char_loop
.asm_2cc3
	pop af
	jp BankswitchROM


; fills wTextHeader1 with TX_KATAKANA, wFontWidth, hBankROM,
; and uses register bc to fill in the text's pointer.
; input:
;	hl = text ID for the header
; output:
;	[wWhichTextHeader] = 0
;	[wWhichTxRam2] = 0
;	[wWhichTxRam3] = 0
;	[hJapaneseSyllabary] = TX_KATAKANA
ResetTxRam_WriteToTextHeader::
	xor a
	ld [wWhichTextHeader], a
	ld [wWhichTxRam2], a
	ld [wWhichTxRam3], a
	ld a, TX_KATAKANA
	ldh [hJapaneseSyllabary], a
;	fallthrough

; fills the wTextHeader specified in wWhichTextHeader (0-3) with
; hJapaneseSyllabary, wFontWidth, hBankROM, and uses bc to fill in the text's pointer.
; input:
;	hl = text ID for the header
WriteToTextHeader::
	push hl
	call GetPointerToTextHeader
	pop bc
	ldh a, [hJapaneseSyllabary]
	ld [hli], a
	ld a, [wFontWidth]
	ld [hli], a
	ldh a, [hBankROM]
	ld [hli], a
	ld [hl], c
	inc hl
	ld [hl], b
	ret


; same as WriteToTextHeader, except it then increases wWhichTextHeader to
; set the next text header to the current one (usually, because
; it will soon be written to due to a TX_RAM command).
;	hl = text ID for the header
WriteToTextHeader_MoveToNext::
	call WriteToTextHeader
	ld hl, wWhichTextHeader
	inc [hl]
	ret


; reads the wTextHeader specified in wWhichTextHeader (0-3)
; and uses the data to populate the corresponding memory addresses.
; also switches to the text's rombank
; preserves bc
; output:
;	hl = address of the next character
ReadTextHeader::
	call GetPointerToTextHeader
	ld a, [hli]
	ldh [hJapaneseSyllabary], a
	ld a, [hli]
	ld [wFontWidth], a
	ld a, [hli]
	rst BankswitchROM
	ld a, [hli]
	ld h, [hl]
	ld l, a
	ret


; preserves bc
; output:
;	hl = address of the wTextHeader specified in wWhichTextHeader (0-3)
GetPointerToTextHeader::
	ld a, [wWhichTextHeader]
	ld e, a
	add a ; *2
	add a ; *4
	add e ; *5
	ld e, a
	ld d, $0
	ld hl, wTextHeader1
	add hl, de
	ret


; draws a wide (20x6) text box with or without label depending on wIsTextBoxLabeled
; if labeled, the label's text ID is provided in wTextBoxLabel
; calls InitTextPrintingInTextbox after drawing the text box
; preserves hl
; input:
;	[wTextBoxLabel] = text ID (2 bytes):  if [wIsTextBoxLabeled] != 0
DrawTextReadyLabeledOrRegularTextBox::
	push hl
	lb de, 0, 12
	lb bc, 20, 6
	call AdjustCoordinatesForBGScroll
	ld a, [wIsTextBoxLabeled]
	or a
	jr nz, .labeled
	call DrawRegularTextBox
	call EnableLCD
	jr .init_text
.labeled
	ld hl, wTextBoxLabel
	ld a, [hli]
	ld h, [hl]
	ld l, a
	call DrawLabeledTextBox
.init_text
	lb de, 1, 14
	call AdjustCoordinatesForBGScroll
	ld a, 19
	call InitTextPrintingInTextbox
	pop hl
	ret


; reads the incoming character from the current wTextHeader and processes it
; then updates the current wTextHeader to point to the next character.
; a TX_RAM command causes a switch to a wTextHeader in the level below, and
; a TX_END command terminates the text unless there is a pending wTextHeader in the above level.
; output:
;	carry = set:  if TX_END command terminated the text
ProcessTextHeader::
	call ReadTextHeader
	ld a, [hli]
	or a ; TX_END
	jr z, .tx_end
	cp TX_CTRL_START
	jr c, .character_pair
	cp TX_CTRL_END
	jr nc, .character_pair
	call ProcessSpecialTextCharacter
	jr nc, .processed_char
	cp TX_RAM1
	jr z, .tx_ram1
	cp TX_RAM2
	jr z, .tx_ram2
	cp TX_RAM3
	jr z, .tx_ram3
	jr .processed_char
.character_pair
	ld e, a ; first character
	ld d, [hl] ; second character
	call ClassifyTextCharacterPair
	jr nc, .not_tx_fullwidth
	inc hl
.not_tx_fullwidth
	call Func_22ca
	xor a ; TX_END
	call ProcessSpecialTextCharacter
.processed_char
	call WriteToTextHeader
	or a
	ret
.tx_end
	ld a, [wWhichTextHeader]
	or a
	jr z, .no_more_text
	; handle text header in the above level
	dec a
	ld [wWhichTextHeader], a
	jr ProcessTextHeader
.no_more_text
	call TerminateHalfWidthText
	scf
	ret
.tx_ram2
	call WriteToTextHeader_MoveToNext
	ld a, TX_KATAKANA
	ldh [hJapaneseSyllabary], a
	xor a ; FULL_WIDTH
	ld [wFontWidth], a
	ld de, wTxRam2
	ld hl, wWhichTxRam2
	call HandleTxRam2Or3
	ld a, l
	or h
	jr z, .empty
	call GetTextOffsetFromTextID
	call WriteToTextHeader
	jr ProcessTextHeader
.empty
	ld hl, wDefaultText
	call WriteToTextHeader
	jr ProcessTextHeader
.tx_ram3
	call WriteToTextHeader_MoveToNext
	ld de, wTxRam3
	ld hl, wWhichTxRam3
	call HandleTxRam2Or3
	call TwoByteNumberToText_TrimLeadingZeros
	call WriteToTextHeader
	jp ProcessTextHeader
.tx_ram1
	call WriteToTextHeader_MoveToNext
	call CopyPlayerNameOrTurnDuelistName
	ld a, [wStringBuffer]
	cp TX_HALFWIDTH
	jr z, .tx_halfwidth
	ld a, TX_HALF2FULL
	call ProcessSpecialTextCharacter
.tx_halfwidth
	call WriteToTextHeader
	jp ProcessTextHeader


; preserves bc
; input:
;	de = wTxRam2 or wTxRam3
;	hl = wWhichTxRam2 or wWhichTxRam3
; output:
;	hl = wTxRam* buffer's current entry (also increments wWhichTxRam*)
HandleTxRam2Or3::
	push de
	ld a, [hl]
	inc [hl]
	add a
	ld e, a
	ld d, $0
	pop hl
	add hl, de
	ld a, [hli]
	ld h, [hl]
	ld l, a
	ret


; uses the two byte text ID in hl to read the three byte text offset
; loads the correct bank for the specific text and returns the pointer in hl
; preserves bc and de
; input:
;	hl = text ID
; output:
;	hl = address of the text
GetTextOffsetFromTextID::
	push de
	ld e, l
	ld d, h
	add hl, hl
	add hl, de
	set 6, h ; hl = (hl * 3) + $4000
	ld a, BANK(TextOffsets)
	rst BankswitchROM
	ld e, [hl]
	inc hl
	ld d, [hl]
	inc hl
	ld a, [hl]
	ld h, d
	rl h
	rla
	rl h
	rla
	add BANK("Text 1")
	rst BankswitchROM
	res 7, d
	set 6, d ; $4000 ≤ de ≤ $7fff
	ld l, e
	ld h, d
	pop de
	ret


; if in the overworld, this copies the player's name to wStringBuffer
; if in a duel, this copies the name of the duelist whose turn it is to wStringBuffer
; preserves bc
; output:
;	hl = wStringBuffer
CopyPlayerNameOrTurnDuelistName::
	ld de, wStringBuffer
	push de
	ldh a, [hWhoseTurn]
	cp OPPONENT_TURN
	jr z, .opponent_turn
	call CopyPlayerName
	pop hl
	ret
.opponent_turn
	call CopyOpponentName
	pop hl
	ret


; prints text with ID at hl, with letter delay, in a textbox area.
; the text must fit in the textbox; PrintScrollableText should be used instead.
; input:
;	hl = text ID
PrintText::
	ld a, l
	or h
	jr z, .from_ram
	ldh a, [hBankROM]
	push af
	call GetTextOffsetFromTextID
	call .print_text
	pop af
	jp BankswitchROM
.from_ram
	ld hl, wDefaultText
.print_text
	call ResetTxRam_WriteToTextHeader
.next_tile_loop
	ldh a, [hKeysHeld]
	ld b, a
	ld a, [wTextSpeed]
	inc a
	cp TEXT_SPEED_1 + 1
	jr nc, .apply_delay
	; unless TEXT_SPEED_1 is selected, then pressing the B button will skip the delay
	bit B_PAD_B, b
	jr nz, .skip_delay
	jr .apply_delay
.text_delay_loop
	; wait a number of frames equal to [wTextSpeed] between printing each text tile
	call DoFrame
.apply_delay
	dec a
	jr nz, .text_delay_loop
.skip_delay
	call ProcessTextHeader
	jr nc, .next_tile_loop
	ret


; like PrintTextNoDelay, except it calls InitTextPrinting first
; input:
;	de = screen coordinates at which to begin printing the text
;	hl = text ID
InitTextPrinting_PrintTextNoDelay::
	call InitTextPrinting
;	fallthrough

; prints text with ID at hl, without letter delay, in a textbox area.
; the text must fit in the textbox; PrintScrollableText should be used instead.
; input:
;	hl = text ID
PrintTextNoDelay::
	ldh a, [hBankROM]
	push af
	call GetTextOffsetFromTextID
	call ResetTxRam_WriteToTextHeader
.next_tile_loop
	call ProcessTextHeader
	jr nc, .next_tile_loop
	pop af
	jp BankswitchROM


; copies the opponent's name to de
; if text ID at wOpponentName is non-0, copy it from there
; else, if text at wc500 is non-0, copy if from there
; else, copy Player2Text
; preserves bc
; input:
;	de = where to copy the data (usually wDefaultText)
; output:
;	de = end of the text string that was stored at de
CopyOpponentName::
	ld hl, wOpponentName
	ld a, [hli]
	ld h, [hl]
	ld l, a
	or h
	jr nz, CopyText
	; use wNameBuffer if pointer is null
	ld hl, wNameBuffer
	ld a, [hl]
	or a
	jr nz, CopyPlayerName.loop
	; use "Player 2" if wNameBuffer is empty
	ldtx hl, Player2Text
;	fallthrough

; preserves bc
; input:
;	hl = ID of text to copy (if 0, then use turn duelist's name)
;	de = where to copy the data (usually wDefaultText)
; output:
;	de = end of the text string that was stored at de
CopyText::
	ld a, l
	or h
	jr z, .special
	ldh a, [hBankROM]
	push af
	call GetTextOffsetFromTextID
.next_tile_loop
	ld a, [hli]
	ld [de], a
	inc de
	or a ; cp TX_END
	jr nz, .next_tile_loop
	pop af
	rst BankswitchROM
	dec de
	ret
.special
	ldh a, [hWhoseTurn]
	cp OPPONENT_TURN
	jr z, CopyOpponentName
;	fallthrough

; copies the TX_END-terminated player's name from sPlayerName to de
; preserves bc
; input:
;	de = where to copy the data (usually wDefaultText)
; output:
;	de = end of the text string that was stored at de
CopyPlayerName::
	call EnableSRAM
	ld hl, sPlayerName
.loop
	ld a, [hli]
	ld [de], a
	inc de
	or a ; TX_END
	jr nz, .loop
	dec de
	jp DisableSRAM


; copies text of maximum length a (in tiles) from its ID at hl to de,
; then terminates the text with TX_END if it doesn't contain it already.
; fill any remaining bytes with spaces plus TX_END to match the length specified in a.
; preserves bc
; input:
;	a = maximum number of text tiles to copy
;	hl = ID of text to copy
;	de = where to copy the data (usually wDefaultText)
; output:
;	e = how many text characters were copied
CopyTextData_FromTextID::
	ldh [hff96], a
	ldh a, [hBankROM]
	push af
	call GetTextOffsetFromTextID
	ldh a, [hff96]
	call CopyTextData
	pop af
	jp BankswitchROM


; text ID (usually of a card name) for TX_RAM2
; preserves all registers except af
; input:
;	hl = text ID
LoadTxRam2::
	ld a, l
	ld [wTxRam2], a
	ld a, h
	ld [wTxRam2 + 1], a
	ret


; a number between 0 and 65535 for TX_RAM3
; preserves all registers except af
;	hl = number
LoadTxRam3::
	ld a, l
	ld [wTxRam3], a
	ld a, h
	ld [wTxRam3 + 1], a
	ret
