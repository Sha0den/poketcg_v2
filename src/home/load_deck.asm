; loads the deck ID in a from DeckPointers and copies it to wPlayerDeck
; or to wOpponentDeck, depending on whose turn it is.
; preserves hl
; input:
;	a = deck ID (*_DECK constant)
; output:
;	carry = set:  if an invalid deck ID is used
LoadDeck::
	push hl
	ld l, a
	ld h, $0
	ldh a, [hBankROM]
	push af
	ld a, BANK(DeckPointers)
	rst BankswitchROM
	add hl, hl
	ld de, DeckPointers
	add hl, de
	ld e, [hl]
	inc hl
	ld d, [hl]
	ld a, d
	or e
	jr z, .null_pointer
	call CopyDeckData
	pop af
	rst BankswitchROM
	pop hl
	or a
	ret
.null_pointer
	pop af
	rst BankswitchROM
	pop hl
	scf
	ret
