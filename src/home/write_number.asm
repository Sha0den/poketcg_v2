; given a number between 0-255 in a, converts it to halfwidth text characters,
; and writes it to wStringBuffer and to the BGMap0 address at bc.
; any leading zeros are replaced with an empty space.
; preserves bc and de
; input:
;	a = number that will be printed
;	de = screen coordinates at which to begin printing the number
WriteOneByteNumberInHalfwidthTextFormat_TrimLeadingZeros::
	push bc
	push de
	ld l, a
	ld h, $00
	call TwoByteNumberToHalfwidthText_TrimLeadingZeros
.print_number
	ld hl, wStringBuffer + 1
	ld [hl], TX_HALFWIDTH
	pop de
	call InitTextPrinting_ProcessText
	pop bc
	ret


; given a number between 0-255 in a, converts it to TX_SYMBOL format,
; and writes it to wStringBuffer + 2 and to the BGMap0 address at bc.
; any leading zeros are replaced with SYM_SPACE.
; preserves bc and de
; input:
;	a = number that will be printed
;	bc = screen coordinates at which to begin printing the number
WriteOneByteNumberInTxSymbolFormat_TrimLeadingZeros::
	push de
	push bc
	ld l, a
	ld h, $00
	call TwoByteNumberToTxSymbol_TrimLeadingZeros
.print_number
	ld hl, wStringBuffer + 2
	ld a, 3
	pop bc
	call CopyDataToBGMap0
	pop de
	ret


; given a number between 0-999 in hl, converts it to TX_SYMBOL format,
; and writes it to wStringBuffer + 2 and to the BGMap0 address at bc.
; also prints any leading zeros.
; preserves bc and de
; input:
;	hl = number that will be printed
;	bc = screen coordinates at which to begin printing the number
WriteThreeDigitNumberInTxSymbolFormat::
	push de
	push bc
	call TwoByteNumberToTxSymbol
	jr WriteOneByteNumberInTxSymbolFormat_TrimLeadingZeros.print_number


; converts the number at hl to halfwidth text (ascii) format and writes it to de
; input:
;	hl = number to covert to text
;	de = where to copy the text (usually wStringBuffer)
TwoByteNumberToHalfwidthText::
	ld bc, -10000
	call GetHalfwidthTextDigit
	ld bc, -1000
	call GetHalfwidthTextDigit
	ld bc, -100
	call GetHalfwidthTextDigit
	ld bc, -10
	call GetHalfwidthTextDigit
	ld bc, -1
	call GetHalfwidthTextDigit
	xor a ; TX_END
	ld [de], a
	ret


; input:
;	bc = digit offset
;	hl = number to convert to a halfwidth text font
GetHalfwidthTextDigit::
	ld a, "0" - 1
	jr GetTxSymbolDigit.subtract_loop

; input:
;	bc = digit offset
;	hl = number to convert to a fullwidth text font
GetFullwidthTextDigit::
	ld a, TX_SYMBOL
	ld [de], a
	inc de
;	fallthrough

; input:
;	bc = digit offset
;	hl = number to convert to a text symbol font
GetTxSymbolDigit::
	ld a, SYM_0 - 1
.subtract_loop::
	inc a
	add hl, bc
	jr c, .subtract_loop
	ld [de], a
	inc de
	ld a, l
	sub c
	ld l, a
	ld a, h
	sbc b
	ld h, a
	ret


; converts the number at hl to TX_SYMBOL text format and writes it to wStringBuffer
; input:
;	hl = number to covert to text
; ouput:
;	[wStringBuffer] = number in text symbol format with leading zeros (6 bytes, but the last one is empty)
TwoByteNumberToTxSymbol::
	ld de, wStringBuffer
;	fallthrough

; converts the number at hl to TX_SYMBOL text format and writes it to de
; input:
;	hl = number to covert to text
;	de = where to store the text symbol string
TwoByteNumberToTxSymbolInDE::
	ld bc, -10000
	call GetTxSymbolDigit
	ld bc, -1000
	call GetTxSymbolDigit
	ld bc, -100
	call GetTxSymbolDigit
	ld bc, -10
	call GetTxSymbolDigit
	ld bc, -1
	call GetTxSymbolDigit
	xor a ; TX_END
	ld [de], a
	ret


; converts the number at hl to TX_SYMBOL text format and writes it to wStringBuffer,
; replacing any leading zeros with SYM_SPACE
; input:
;	hl = number to convert to text symbols
; output:
;	hl = pointer for first non-zero digit in wStringBuffer
;	[wStringBuffer] = number in text symbol format (6 bytes, but the last one is empty)
TwoByteNumberToTxSymbol_TrimLeadingZeros::
	ld de, wStringBuffer
;	fallthrough

; converts the number at hl to TX_SYMBOL text format and writes it to de,
; replacing any leading zeros with SYM_SPACE
; input:
;	hl = number to convert to text symbols
;	de = where to store the text symbol string
; output:
;	hl = pointer for first non-zero digit in location from de input
TwoByteNumberToTxSymbolInDE_TrimLeadingZeros::
	push de
	call TwoByteNumberToTxSymbolInDE
	pop hl 
	ld b, 4
.digit_loop
	ld a, [hl]
	cp SYM_0
	ret nz ; return if reached a non-zero digit
	ld [hl], SYM_SPACE ; trim leading zero
	inc hl
	dec b
	jr nz, .digit_loop
	ret


; if [wFontWidth] == HALF_WIDTH:
;	converts the number at hl to halfwidth text (ascii) format and writes it to wStringBuffer
; if [wFontWidth] == FULL_WIDTH:
;	converts the number at hl to fullwidth text format and writes it to wStringBuffer,
;	replacing any leading zeros with spaces
; input:
;	hl = number to covert to text
; output:
;	hl = pointer for first non-zero digit in wStringBuffer
;	[wStringBuffer] = number in current text format (includes leading zeros if halfwidth)
TwoByteNumberToText_TrimLeadingZeros::
	ld a, [wFontWidth]
	or a ; FULL_WIDTH
	jr z, TwoByteNumberToFullwidthText_TrimLeadingZeros
;	fallthrough

TwoByteNumberToHalfwidthText_TrimLeadingZeros::
	ld de, wStringBuffer
	push de
	call TwoByteNumberToHalfwidthText
	pop hl ; wStringBuffer
	ld c, 4
.digit_loop
	ld a, [hl]
	cp "0"
	ret nz
	ld a, " "
	ld [hli], a
	dec c
	jr nz, .digit_loop
	ret


; converts the number at hl to fullwidth (symbol font) text and writes it to wStringBuffer,
; replacing any leading zeros with spaces. If 'InitTextPrinting' was already called,
; then 'ProcessText' can be called after this function to print the number on the screen.
; input:
;	hl = number to convert to a fullwidth font
; output:
;	e = number of digits in number from input (excluding any leading zeros)
;	hl = pointer for first non-zero digit in wStringBuffer
;	[wStringBuffer] = number in fullwidth text format (11 bytes, but the last one is empty)
TwoByteNumberToFullwidthText_TrimLeadingZeros::
	ld de, wStringBuffer
;	fallthrough

; converts the number at hl to fullwidth text and writes it to de,
; replacing any leading zeros with spaces. If 'InitTextPrinting' was already called,
; then 'ProcessText' can be called after this function to print the number on the screen.
; input:
;	hl = number to convert to a fullwidth font
; output:
;	e = number of digits in number from input (excluding any leading zeros)
;	hl = pointer for first non-zero digit in location from de input
TwoByteNumberToFullwidthTextInDE_TrimLeadingZeros::
	push de
	ld bc, -10000
	call GetFullwidthTextDigit
	ld bc, -1000
	call GetFullwidthTextDigit
	ld bc, -100
	call GetFullwidthTextDigit
	ld bc, -10
	call GetFullwidthTextDigit
	ld bc, -1
	call GetFullwidthTextDigit
	xor a ; TX_END
	ld [de], a
	pop hl
	ld e, 5
.digit_loop
	inc hl
	ld a, [hl]
	cp SYM_0
	jr nz, .done ; jump if not zero
	ld [hl], SYM_SPACE ; trim leading zero
	inc hl
	dec e
	jr nz, .digit_loop
	dec hl
	ld [hl], SYM_0
.done
	dec hl
	ret


; converts a number between 0 and 99 to the TX_SYMBOL text format and writes it to wDecimalChars
; preserves bc
; input:
;	a = two-digit number to convert to symbol font
; output:
;	hl = wDecimalChars
;	[wDecimalChars] = number in text symbol format (3 bytes, but the last one is empty)
TwoDigitNumberToTxSymbol::
	ld hl, wDecimalChars
;	fallthrough

; converts a number between 0 and 99 to the TX_SYMBOL text format and writes it to hl
; preserves bc and hl
; input:
;	a = two-digit number to convert to symbol font
;	hl = where to store the text symbols (e.g. wDecimalDigitsSymbols)
; output:
;	[hl] = number in text symbol format (3 bytes, but the last one is empty)
TwoDigitNumberToTxSymbolInHL::
	push hl
	ld e, SYM_0 - 1
.first_digit_loop
	inc e
	sub 10
	jr nc, .first_digit_loop
	ld [hl], e ; first digit
	inc hl
	add SYM_0 + 10
	ld [hli], a ; second digit
	ld [hl], TX_END
	pop hl
	ret


; converts a number between 0 and 99 to the TX_SYMBOL text format and writes it to wDecimalChars
; replacing a zero in the tens digit with SYM_SPACE.
; preserves bc
; input:
;	a = two-digit number to convert to symbol font
; output:
;	hl = wDecimalChars
;	[wDecimalChars] = number in text symbol format (3 bytes, but the last one is empty)
TwoDigitNumberToTxSymbol_TrimLeadingZero::
	ld hl, wDecimalChars
;	fallthrough

; converts a number between 0 and 99 to the TX_SYMBOL text format and writes it to hl,
; replacing a zero in the tens digit with SYM_SPACE.
; preserves bc and hl
; input:
;	a = two-digit number to convert to symbol font
;	hl = where to store the text symbols
; output:
;	[hl] = number in text symbol format (3 bytes, but the last one is empty)
TwoDigitNumberToTxSymbolInHL_TrimLeadingZero::
	call TwoDigitNumberToTxSymbolInHL
	ld a, [hl]
	cp SYM_0
	ret nz
	ld [hl], SYM_SPACE
	ret


; given a number between 0-99 in a, converts it to TX_SYMBOL format,
; and writes it to wDecimalChars and to the BGMap0 address at bc.
; if the number is between 0-9, the first digit is replaced with SYM_SPACE.
; preserves all registers except af
; input:
;	a = number that will be printed
;	bc = screen coordinates at which to begin printing the number
WriteTwoDigitNumberInTxSymbolFormat_TrimLeadingZero::
	push hl
	push de
	call TwoDigitNumberToTxSymbol_TrimLeadingZero
	ld a, 2
	call CopyDataToBGMap0
	pop de
	pop hl
	ret


;----------------------------------------
;        UNREFERENCED FUNCTIONS
;----------------------------------------
;
; given a number in hl, converts it to TX_SYMBOL format,
; and writes it to wStringBuffer and to the BGMap0 address at bc.
; any leading zeros are replaced with SYM_SPACE.
; preserves bc and de
; input:
;	hl = number that will be printed
;	bc = screen coordinates at which to begin printing the number
;WriteTwoByteNumberInTxSymbolFormat_TrimLeadingZeros::
;	push de
;	push bc
;	call TwoByteNumberToTxSymbol_TrimLeadingZeros
;	ld hl, wStringBuffer
;	ld a, 5
;	pop bc
;	call CopyDataToBGMap0
;	pop de
;	ret
;
;
; converts the one-byte number at a to halfwidth text (ascii) format,
; and writes it to [wStringBuffer] and the BGMap0 address at bc
; preserves bc and hl
; input:
;	a = number to covert to text
;	bc = coordinates at which to begin printing the number
;WriteOneByteNumber::
;	push bc
;	push hl
;	ld l, a
;	ld h, $00
;	ld de, wStringBuffer
;	push de
;	push bc
;	ld bc, -100
;	call GetHalfwidthTextDigit
;	ld bc, -10
;	call GetHalfwidthTextDigit
;	ld bc, -1
;	call GetHalfwidthTextDigit
;	pop bc
;	call BCCoordToBGMap0Address
;	pop hl
;	ld b, 3
;	call HblankCopyDataHLtoDE
;	pop hl
;	pop bc
;	ret
;
;
; converts the two-byte number at hl to halfwidth text (ascii) format,
; and writes it to [wStringBuffer] and the BGMap0 address at bc
; preserves bc
; input:
;	hl = number to covert to text
;	bc = coordinates at which to begin printing the number
;WriteTwoByteNumber::
;	push bc
;	ld de, wStringBuffer
;	push de
;	call TwoByteNumberToHalfwidthText
;	pop bc
;	push bc
;	call BCCoordToBGMap0Address
;	pop hl ; wStringBuffer
;	ld b, 5
;	call HblankCopyDataHLtoDE
;	pop bc
;	ret
;
;
; converts the one-digit BCD number provided in the lower nybble of a to text
; (ascii) format, and writes it to [wStringBuffer] and to the BGMap0 address at bc
; preserves all registers except af
; input:
;	a = binary-coded decimal number to covert to text
;	bc = coordinates at which to begin printing the number
;WriteOneDigitBCDNumber::
;	push hl
;	push bc
;	push de
;	ld hl, wStringBuffer
;	push hl
;	push bc
;	call WriteBCDDigitInTextFormat
;	pop bc
;	call BCCoordToBGMap0Address
;	pop hl
;	ld b, 1
;	call HblankCopyDataHLtoDE
;	pop de
;	pop bc
;	pop hl
;	ret
;
;
; converts the two-digit BCD number provided in a to text (ascii) format,
; writes them to [wStringBuffer] and [wStringBuffer + 1], and to the BGMap0 address at bc
; preserves all registers except af
; input:
;	a = binary-coded decimal number to covert to text
;	bc = coordinates at which to begin printing the number
;WriteTwoDigitBCDNumber::
;	push hl
;	push bc
;	push de
;	ld hl, wStringBuffer
;	push hl
;	push bc
;	call WriteBCDNumberInTextFormat
;	pop bc
;	call BCCoordToBGMap0Address
;	pop hl
;	ld b, 2
;	call HblankCopyDataHLtoDE
;	pop de
;	pop bc
;	pop hl
;	ret
;
;
; converts the four-digit BCD number provided in h and l to text (ascii) format,
; writes them to [wStringBuffer] through [wStringBuffer + 3], and to the BGMap0 address at bc
; preserves all registers except af
; input:
;	hl = binary-coded decimal number to covert to text
;	bc = coordinates at which to begin printing the number
;WriteFourDigitBCDNumber::
;	push hl
;	push bc
;	push de
;	ld e, l
;	ld d, h
;	ld hl, wStringBuffer
;	push hl
;	push bc
;	ld a, d
;	call WriteBCDNumberInTextFormat
;	ld a, e
;	call WriteBCDNumberInTextFormat
;	pop bc
;	call BCCoordToBGMap0Address
;	pop hl
;	ld b, 4
;	call HblankCopyDataHLtoDE
;	pop de
;	pop bc
;	pop hl
;	ret
;
;
; given two BCD digits in the two nybbles of register a,
; writes them in text (ascii) format to hl (most significant nybble first).
; numbers above 9 end up converted to half-width font tiles.
; preserves bc and de
; input:
;	a = double-digit binary-coded decimal number to covert to text
;WriteBCDNumberInTextFormat::
;	push af
;	swap a
;	call WriteBCDDigitInTextFormat
;	pop af
;	; fallthrough
;
; given a BCD digit in the (lower nybble) of register a, write it in text (ascii) format to hl.
; numbers above 9 end up converted to half-width font tiles.
; preserves bc and de
; input:
;	a = single-digit binary-coded decimal number to covert to text
;WriteBCDDigitInTextFormat::
;	and $0f
;	add "0"
;	cp "9" + 1
;	jr c, .write_num
;	add $07
;.write_num
;	ld [hli], a
;	ret
;
;
; converts a number between 0 and 99 to the TX_SYMBOL text format
; and writes it to wDefaultText. if the first digit is 0, then replace it
; with the next digit and then replace that digit with SYM_SPACE.
; preserves bc and hl
; input:
;	a = two-digit number to convert to symbol font
;	hl = where to store the text symbols (e.g. wDecimalChars)
; output:
;	[hl] = number in text symbol format (3 bytes, but the last 1-2 are empty)
;TwoDigitNumberToTxSymbolInHL_TrimLeadingZeroAndAlign::
;	call TwoDigitNumberToTxSymbolInHL
;	ld a, [hli]
;	cp SYM_0
;	jr nz, .done
;	; shift number one tile to the left
;	ld a, [hld]
;	ld [hli], a
;	ld [hl], SYM_SPACE
;.done
;	dec hl
;	ret
