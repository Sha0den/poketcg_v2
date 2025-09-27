OpenBoosterPack::
	ld a, PLAYER_TURN
	ldh [hWhoseTurn], a
; clears DECK_SIZE bytes starting from wPlayerDuelVariables
	ld h, a
	ld l, $00
.loop_clear
	xor a
	ld [hli], a
	ld a, l
	cp DECK_SIZE
	jr c, .loop_clear

; fills wDuelTempList with 0, 1, 2, 3, ...
; up to the number of cards received in the booster pack
	ld hl, wBoosterCardsDrawn
	ld de, wDuelTempList
	ld c, $00
.loop_index_sequence
	ld a, [hli]
	or a
	jr z, .done_index_sequence
	ld a, c
	ld [de], a
	inc de
	inc c
	jr .loop_index_sequence
.done_index_sequence
	ld a, $ff ; terminator byte
	ld [de], a

	lb de, $38, $9e
	call SetupText
	call LoadNewCardSymbolGraphics
	bank1call InitAndDrawCardListScreenLayout
	ldtx hl, ChooseTheCardYouWishToExamineText
	ldtx de, BoosterPackText
	call SetCardListHeaderText
	ld a, USE_BOOSTER_PACK_DISPLAY
	ld [wCardListDisplayFormat], a
	ld a, PAD_A | PAD_START
	ld [wNoItemSelectionMenuKeys], a
	bank1call DisplayCardList
	xor a ; DEFAULT_CARD_LIST_DISPLAY
	ld [wCardListDisplayFormat], a
;	fallthrough

; adds the final cards drawn from the booster pack to the player's collection (sCardCollection)
; preserves bc and de
; input:
;	wBoosterCardsDrawn = null-terminated list of card IDs
AddBoosterCardsToCollection:
	ld hl, wBoosterCardsDrawn
.add_cards_loop
	ld a, [hli]
	or a
	ret z ; return if there are no more cards to add
	call AddCardToCollection
	jr .add_cards_loop


; loads the Deck Box icon gfx to v0Tiles2
LoadNewCardSymbolGraphics:
	ld hl, NewCardSymbolGfx
	ld de, v0Tiles1 + $1f tiles
	ld b, 16 ; 1 tile = 8*8 = 64 pixels, 64 pixels / 4 (2 bits per pixel) = 16 bytes
	jp SafeCopyDataHLtoDE

NewCardSymbolGfx:
	INCBIN "gfx/new_card_symbol.2bpp"
