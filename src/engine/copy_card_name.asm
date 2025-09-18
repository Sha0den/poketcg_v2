; copies the name and level of the card at wLoadedCard1 to wDefaultText
; preserves bc and de
; input:
;	a = length in number of tiles (the resulting string will be padded with spaces to match it)
;	[wLoadedCard1] = all of the card's data (card_data_struct)
; output:
;	hl = first empty space at the end of the text string that was stored in wDefaultText
_CopyCardNameAndLevel::
	push bc
	push de
	ld [wCardNameLength], a
	ld hl, wLoadedCard1Name
	ld a, [hli]
	ld h, [hl]
	ld l, a
	ld de, wDefaultText
	push de
	call CopyText ; copy card name to wDefaultText
	pop hl ; hl = wDefaultText
	ld a, [hl]
	cp TX_HALFWIDTH
	jr z, _CopyCardNameAndLevel_HalfwidthText

; the name doesn't start with TX_HALFWIDTH
; this doesn't appear to ever be the case (unless caller manipulates wLoadedCard1Name)
	call GetTextLengthInTiles
	ld a, [wCardNameLength]
	sub b ; number of tiles used by the card's name
	ld b, a
	ld h, d
	ld l, e
	; hl = byte immediately after the end of the last character from the card's name in wDefaultText
	ld a, [wLoadedCard1Type]
	cp TYPE_ENERGY
	jr nc, .level_done ; skip level if Energy or Trainer card
	ld a, [wLoadedCard1Level]
	or a
	jr z, .level_done
	ldfw a, " "
	ld [hli], a
	dec b
	ldfw a, "[Lv.]"
	ld [hli], a
	dec b
	ld a, [wLoadedCard1Level]
	cp 10
	jr c, .copy_ones_digit
	ld [hl], TX_SYMBOL
	inc hl
	push bc
	ld b, SYM_0 - 1
.tens_digit_loop
	inc b
	sub 10
	jr nc, .tens_digit_loop
	add 10
	ld [hl], b ; tens digit
	inc hl
	pop bc
	dec b
.copy_ones_digit
	ld [hl], TX_SYMBOL
	inc hl
	add SYM_0
	ld [hli], a ; ones digit
	dec b
.level_done
	push hl
	ldfw a, " "
.fill_spaces_loop
	ld [hli], a
	dec b
	jr nz, .fill_spaces_loop
	ld [hl], TX_END
	pop hl
	pop de
	pop bc
	ret

; the name starts with TX_HALFWIDTH
; input:
;	hl = wDefaultText (with card name already stored)
_CopyCardNameAndLevel_HalfwidthText:
	ld a, [wCardNameLength]
	inc a ; +1 (because of the control characters)
	add a ; *2 (because each tile holds 2 characters)
	ld b, a
.find_end_text_loop
	dec b
	ld a, [hli]
	or a ; TX_END
	jr nz, .find_end_text_loop
	dec hl
	ld a, [wLoadedCard1Type]
	cp TYPE_ENERGY
	jr nc, .level_done
	ld a, [wLoadedCard1Level]
	or a
	jr z, .level_done
	ld a, " "
	ld [hli], a
	dec b
	ld a, CHARVAL("[Lv.]", 0)
	ld [hli], a
	dec b
	ld a, CHARVAL("[Lv.]", 1)
	ld [hli], a
	dec b
	ld a, [wLoadedCard1Level]
	cp 10
	jr c, .copy_ones_digit
	push bc
	ld b, "0" - 1
.tens_digit_loop
	inc b
	sub 10
	jr nc, .tens_digit_loop
	add 10
	ld [hl], b ; first digit
	inc hl
	pop bc
	dec b
.copy_ones_digit
	add "0"
	ld [hli], a ; last (or only) digit
	dec b
.level_done
	push hl
	ld a, " "
.fill_spaces_loop
	ld [hli], a
	dec b
	jr nz, .fill_spaces_loop
	ld [hl], TX_END
	pop hl
	pop de
	pop bc
	ret
