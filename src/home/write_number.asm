; currently an unreferenced function
; converts the one-byte number at a to halfwidth text (ascii) format,
; and writes it to [wStringBuffer] and the BGMap0 address at bc
; preserves bc and hl
; input:
;	a = number to covert to text
;	bc = coordinates at which to begin printing the number
WriteOneByteNumber::
	push bc
	push hl
	ld l, a
	ld h, $00
	ld de, wStringBuffer
	push de
	push bc
	ld bc, -100
	call TwoByteNumberToText.get_digit
	ld bc, -10
	call TwoByteNumberToText.get_digit
	ld bc, -1
	call TwoByteNumberToText.get_digit
	pop bc
	call BCCoordToBGMap0Address
	pop hl
	ld b, 3
	call HblankCopyDataHLtoDE
	pop hl
	pop bc
	ret


; currently an unreferenced function
; converts the two-byte number at hl to halfwidth text (ascii) format,
; and writes it to [wStringBuffer] and the BGMap0 address at bc
; preserves bc
; input:
;	hl = number to covert to text
;	bc = coordinates at which to begin printing the number
WriteTwoByteNumber::
	push bc
	ld de, wStringBuffer
	push de
	call TwoByteNumberToText
	call BCCoordToBGMap0Address
	pop hl
	ld b, 5
	call HblankCopyDataHLtoDE
	pop bc
	ret


; converts the number at hl to halfwidth text (ascii) format and write it to de
; preserves bc
; input:
;	hl = number to covert to text
;	de = where to copy the text (usually wStringBuffer)
TwoByteNumberToText::
	push bc
	ld bc, -10000
	call .get_digit
	ld bc, -1000
	call .get_digit
	ld bc, -100
	call .get_digit
	ld bc, -10
	call .get_digit
	ld bc, -1
	call .get_digit
	xor a ; TX_END
	ld [de], a
	pop bc
	ret
.get_digit
	ld a, "0" - 1
.subtract_loop
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

; if [wFontWidth] == HALF_WIDTH:
;	converts the number at hl to halfwidth text (ascii) format and writes it to wStringBuffer,
;	adjusting the hl pointer to skip over any leading zeros
; if [wFontWidth] == FULL_WIDTH:
;	converts the number at hl to TX_SYMBOL text format and writes it to wStringBuffer,
;	replacing leading zeros with SYM_SPACE
; input:
;	hl = number to covert to text/symbol font
; output:
;	hl = wStringBuffer (if halfwidth: its wStringBuffer + the number of leading zeros)
;	[wStringBuffer] = numerical text string (includes leading zeros if halfwidth)
TwoByteNumberToText_TrimLeadingZeros::
	ld a, [wFontWidth]
	or a ; FULL_WIDTH
	jr z, .fullwidth
	ld de, wStringBuffer
	call TwoByteNumberToText
	ld hl, wStringBuffer
	ld c, 4
.digit_loop
	ld a, [hl]
	cp "0"
	ret nz
	inc hl
	dec c
	jr nz, .digit_loop
	ret
.fullwidth
	farcall TwoByteNumberToTxSymbol_TrimLeadingZeros_Bank6
	ret


; converts a number between 0 and 99 to the TX_SYMBOL text format
; and writes it to wDefaultText
; preserves bc
; input:
;	a = number to convert to symbol font
; output:
;	hl = wDefaultText
;	[wDefaultText] = numerical text string
TwoDigitNumberToTxSymbol::
	ld hl, wDefaultText
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
	ld [hl], SYM_SPACE
	pop hl
	ret


; same as TwoDigitNumberToTxSymbol above, except it
; replaces the first leading zero with SYM_SPACE
TwoDigitNumberToTxSymbol_TrimLeadingZero::
	call TwoDigitNumberToTxSymbol
	ld a, [hl]
	cp SYM_0
	ret nz
	ld [hl], SYM_SPACE
	ret


; currently an unreferenced function
; converts a number between 0 and 99 to the TX_SYMBOL text format
; and writes it to wDefaultText. if the first digit is 0, then replace it
; with the next digit and then replace that digit with SYM_SPACE.
; preserves bc
; input:
;	a = number (0-99) to convert to symbol font
; output:
;	hl = wDefaultText
;	[wDefaultText] = numerical text string
TwoDigitNumberToTxSymbol_TrimLeadingZeroAndAlign::
	call TwoDigitNumberToTxSymbol
	ld a, [hli]
	cp SYM_0
	ret nz
	; shift number one tile to the left
	ld a, [hld]
	ld [hli], a
	ld [hl], SYM_SPACE
	ret


;----------------------------------------
;        UNREFERENCED FUNCTIONS
;----------------------------------------
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
