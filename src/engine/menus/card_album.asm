; fills wFilteredCardList and wOwnedCardsCountList
; with card IDs and counts, respectively, from a given Card Set
; input:
;	a = CARD_SET_* constant
; output:
;	wFilteredCardList = null-terminated list with card IDs of every card in the given set
;	wOwnedCardsCountList = $ff-terminated list with card counts of every card in the given set
CreateCardSetList:
	push af
	ld a, DECK_SIZE ; number of bytes that will be cleared (max number of cards in a set = 60)
	ld hl, wFilteredCardList
	call ClearMemory_Bank2
	ld a, DECK_SIZE ; number of bytes that will be cleared (max number of cards in a set = 60)
	ld hl, wOwnedCardsCountList
	call ClearMemory_Bank2
	xor a
	ld [wOwnedPhantomCardFlags], a
	ld h, a
	ld l, a
	ld d, a
	ld e, a
	pop af
	ld b, a
.loop_all_cards
	inc e
	call LoadCardDataToBuffer1_FromCardID
	jr c, .check_energy_cards
	ld a, [wLoadedCard1Type]
	and TYPE_ENERGY
	jr nz, .loop_all_cards
	ld a, [wLoadedCard1Set]
	and $f0 ; set 1
	swap a
	cp b
	jr nz, .loop_all_cards
	; this card has the same set as input
	ld a, e
	cp VENUSAUR_LV64
	jp z, .SetVenusaurLv64OwnedFlag
	cp MEW_LV15
	jp z, .SetMewLv15OwnedFlag
	push bc
	push hl
	ld bc, wFilteredCardList
	add hl, bc
	ld [hl], e ; card ID
	ld hl, wTempCardCollection
	add hl, de
	ld a, [hl]
	pop hl
	push hl
	ld bc, wOwnedCardsCountList
	add hl, bc
	ld [hl], a ; card count in collection
	pop hl
	inc l
	pop bc
	jr .loop_all_cards

.check_energy_cards
; put any Special Energy cards at the end of their respective set lists.
	ld de, GRASS_ENERGY + NUM_COLORED_TYPES - 1
.loop_special_energy_cards
	inc e
	call LoadCardDataToBuffer1_FromCardID
	ld a, [wLoadedCard1Type]
	and TYPE_ENERGY
	jr z, .check_basic_energy
	ld a, [wLoadedCard1Set]
	and $f0 ; set 1
	swap a
	cp b
	jr nz, .loop_special_energy_cards
	push bc
	push hl
	ld bc, wFilteredCardList
	add hl, bc
	ld [hl], e
	ld hl, wTempCardCollection
	add hl, de
	ld a, [hl]
	pop hl
	push hl
	ld bc, wOwnedCardsCountList
	add hl, bc
	ld [hl], a
	pop hl
	inc l
	pop bc
	jr .loop_special_energy_cards

.check_basic_energy
; put all Basic Energy cards at the end of the Colosseum set.
	ld a, b
	or a ; cp CARD_SET_COLOSSEUM
	jr nz, .check_phantom_cards
	ld de, GRASS_ENERGY
	ld c, NUM_COLORED_TYPES
.loop_basic_energy_cards
	push bc
	push hl
	ld bc, wFilteredCardList
	add hl, bc
	ld [hl], e
	ld hl, wTempCardCollection
	add hl, de
	ld a, [hl]
	pop hl
	push hl
	ld bc, wOwnedCardsCountList
	add hl, bc
	ld [hl], a
	pop hl
	pop bc
	inc l
	inc e
	dec c
	jr nz, .loop_basic_energy_cards

.check_phantom_cards
	ld a, [wOwnedPhantomCardFlags]
	bit VENUSAUR_OWNED_PHANTOM_F, a
	call nz, .PlaceVenusaurLv64InList
.check_mew
	bit MEW_OWNED_PHANTOM_F, a
	call nz, .PlaceMewLv15InList

.find_first_owned
	dec l
	ld c, l
	ld b, h
.loop_owned_cards
	ld hl, wOwnedCardsCountList
	add hl, bc
	ld a, [hl]
	cp CARD_NOT_OWNED
	jr nz, .found_owned
	dec c
	jr .loop_owned_cards

.found_owned
	inc c
	ld a, c
	ld [wNumEntriesInCurFilter], a
	xor a ; terminator byte
	ld hl, wFilteredCardList
	add hl, bc
	ld [hl], a
	ld a, $ff ; terminator byte
	ld hl, wOwnedCardsCountList
	add hl, bc
	ld [hl], a
	ret

.SetMewLv15OwnedFlag
	ld a, (1 << MEW_OWNED_PHANTOM_F)
	; fallthrough

; input:
;	a = *_OWNED_PHANTOM_F constant
.SetPhantomOwnedFlag
	push hl
	push bc
	ld b, a
	ld hl, wTempCardCollection
	add hl, de
	ld a, [hl]
	cp CARD_NOT_OWNED
	jr z, .skip_set_flag
	ld a, [wOwnedPhantomCardFlags]
	or b
	ld [wOwnedPhantomCardFlags], a
.skip_set_flag
	pop bc
	pop hl
	jp .loop_all_cards

.SetVenusaurLv64OwnedFlag
	ld a, (1 << VENUSAUR_OWNED_PHANTOM_F)
	jr .SetPhantomOwnedFlag

.PlaceVenusaurLv64InList
	push af
	push hl
	ld e, VENUSAUR_LV64
	; fallthrough

; places card in register e directly in the list
; input:
;	e = card ID
.PlaceCardInList
	ld bc, wFilteredCardList
	add hl, bc
	ld [hl], e
	pop hl
	push hl
	ld bc, wOwnedCardsCountList
	add hl, bc
	ld [hl], $01
	pop hl
	inc l
	pop af
	ret

.PlaceMewLv15InList
	push af
	push hl
	ld e, MEW_LV15
	jr .PlaceCardInList


; preserves af
; input:
;	a = CARD_SET_* constant
CreateCardSetListAndInitListCoords:
	push af
	ld hl, sCardCollection
	ld de, wTempCardCollection
	ld b, CARD_COLLECTION_SIZE - 1
	call CopyNBytesFromHLToDEInSRAM
	pop af

	push af
	call .GetEntryPrefix
	call CreateCardSetList
	ld a, NUM_CARD_ALBUM_VISIBLE_CARDS
	ld [wNumVisibleCardListEntries], a
	ld hl, wCardListCoords
	ld [hl], 4 ; y-coordinate
	inc hl
	ld [hl], 2 ; x-coordinate
	pop af
	ret

; places in entry name the prefix associated with the selected Card Set
; preserves af and bc
; input:
;	a = CARD_SET_* constant
.GetEntryPrefix
	push af
	cp CARD_SET_PROMOTIONAL
	jr nz, .laboratory
	ldfw a, "P"
	jr .got_prefix
.laboratory
	cp CARD_SET_LABORATORY
	jr nz, .mystery
	ldfw a, "L"
	jr .got_prefix
.mystery
	cp CARD_SET_MYSTERY
	jr nz, .evolution
	ldfw a, "M"
	jr .got_prefix
.evolution
	cp CARD_SET_EVOLUTION
	jr nz, .colosseum
	ldfw a, "E"
	jr .got_prefix
.colosseum
	ldfw a, "C"
	; fallthrough

.got_prefix
	ld [wCurDeckName], a
	pop af
	ret


BoosterNamesTextIDTable:
	tx ColosseumText        ; CARD_SET_COLOSSEUM
	tx EvolutionText        ; CARD_SET_EVOLUTION
	tx MysteryText          ; CARD_SET_MYSTERY
	tx LaboratoryText       ; CARD_SET_LABORATORY
	tx PromotionalText      ; CARD_SET_PROMOTIONAL

; prints the cards being shown in the Card Album screen
; for the corresponding Card Set
; preserves bc
; input:
;	wFilteredCardList = null-terminated list with card IDs of every card in the given set
;	wOwnedCardsCountList = $ff-terminated list with card counts of every card in the given set
PrintCardSetListEntries:
	push bc
	ld a, [wSelectedCardSet]
	add a
	ld e, a
	ld d, $0
	ld hl, BoosterNamesTextIDTable
	add hl, de
	ld a, [hli]
	ld h, [hl]
	ld l, a
	lb de, 2, 1
	call InitTextPrinting_ProcessTextFromID
	ld hl, wCardListCoords
	ld e, [hl]
	inc hl
	ld d, [hl]
	ld b, 18
	ld c, e
	dec c

; draw up cursor on top right
	ld a, [wCardListVisibleOffset]
	or a
	jr z, .got_cursor_tile ; use SYM_SPACE (blank tile)
	ld a, SYM_CURSOR_U
.got_cursor_tile
	call WriteByteToBGMap0

	ld a, [wCardListVisibleOffset]
	ld l, a
	ld h, $00
	ld a, [wNumVisibleCardListEntries]
.loop_visible_cards
	push de
	or a
	jr z, .handle_down_cursor
	ld b, a
	ld de, wFilteredCardList
	push hl
	add hl, de
	ld a, [hl]
	pop hl
	inc l
	or a
	jr z, .no_down_cursor
	ld e, a
	call AddCardIDToVisibleList
	call LoadCardDataToBuffer1_FromCardID
	push bc
	push hl
	ld de, wOwnedCardsCountList
	add hl, de
	dec hl
	ld a, [hl]
	cp CARD_NOT_OWNED
	jr nz, .owned
	ld hl, .EmptySlotText
	ld de, wDefaultText
	call CopyListFromHLToDE
	jr .print_text
.owned
	ld a, 13
	call CopyCardNameAndLevel
.print_text
	pop hl
	pop bc
	pop de
	push hl
	call .AppendCardListIndex
	call InitTextPrinting_ProcessText
	ld hl, wDefaultText
	call ProcessText
	pop hl
	ld a, b
	dec a
	inc e
	inc e
	jr .loop_visible_cards

.handle_down_cursor
	ld de, wFilteredCardList
	add hl, de
	ld a, [hl]
	or a
	jr z, .no_down_cursor
	pop de
	xor a ; FALSE
	ld [wUnableToScrollDown], a
	ld a, SYM_CURSOR_D
	jr .got_down_cursor_tile
.no_down_cursor
	pop de
	ld a, TRUE
	ld [wUnableToScrollDown], a
	xor a ; SYM_SPACE
.got_down_cursor_tile
	lb bc, 18, 16
	call WriteByteToBGMap0
	pop bc
	ret

.EmptySlotText
	textfw "-------------"
	done

; gets the index in the card list and adds it to wCurDeckName
; preserves bc and de
; input:
;	b  = [wNumVisibleCardListEntries] - number of entries that have already been printed
;	hl = [wCardListVisibleOffset] + 1
.AppendCardListIndex
	push bc
	push de
	ld de, wFilteredCardList
	add hl, de
	dec hl
	ld a, [hl]
	cp VENUSAUR_LV64
	jr z, .phantom_card
	cp MEW_LV15
	jr z, .phantom_card

	ld a, [wNumVisibleCardListEntries]
	sub b
	ld hl, wCardListVisibleOffset
	add [hl]
	inc a
	call CalculateOnesAndTensDigits
	ld hl, wDecimalDigitsSymbols
	ld a, [hli]
	ld b, a
	ld a, [hl]
	or a
	jr nz, .got_index
	ld a, SYM_0
.got_index
	ld hl, wCurDeckName + 1 ; skip prefix
	ld [hl], TX_SYMBOL
	inc hl
	ld [hli], a ; tens place
	ld [hl], TX_SYMBOL
	inc hl
	ld a, b
	ld [hli], a ; ones place
	ld [hl], TX_SYMBOL
	inc hl
	xor a ; SYM_SPACE
	ld [hli], a
	ld [hl], a ; TX_END
	ld hl, wCurDeckName
	pop de
	pop bc
	ret

.phantom_card
; phantom cards get only "??" in their index number
	ld hl, wCurDeckName + 1 ; skip prefix
	ldfw a, "?"
	ld [hli], a
	ld [hli], a
	ld a, TX_SYMBOL
	ld [hli], a
	xor a ; SYM_SPACE
	ld [hli], a
	ld [hl], a ; TX_END
	ld hl, wCurDeckName
	pop de
	pop bc
	ret


; handles opening card page, and inputs when inside Card Album.
; this function is very similar to OpenCardPageFromCardList.
; input:
;	[wCardListCursorPos] = which list position is currently selected
;	[wCardListVisibleOffset] = position in list of the first card that's currently shown on screen
;	[wCardListNumCursorPositions] = NUM_CARD_ALBUM_VISIBLE_CARDS (7)
;	wOwnedCardsCountList = $ff-terminated list with card counts of every card in the given set
;	wCurCardListPtr = pointer for a list of card IDs for the current set (wFilteredCardList)
HandleCardAlbumCardPage:
	ld a, [wCardListCursorPos]
	ld b, a
	ld a, [wCardListVisibleOffset]
	add b
	ld c, a
	ld b, $00
	ld hl, wOwnedCardsCountList
	add hl, bc
	ld a, [hl]
	cp CARD_NOT_OWNED
	jr z, .handle_input

	ld hl, wCurCardListPtr
	ld a, [hli]
	ld h, [hl]
	ld l, a
	add hl, bc
	ld e, [hl]
	ld d, $00
	push de
	call LoadCardDataToBuffer1_FromCardID
	lb de, $38, $9f
	call SetupText
	bank1call OpenCardPage_FromCheckHandOrDiscardPile
	pop de

.handle_input
	ldh a, [hDPadHeld]
	ld b, a
	and PAD_BUTTONS
	jr nz, .exit
	xor a ; FALSE
	ld [wMenuInputSFX], a
	ld a, [wCardListNumCursorPositions]
	ld c, a
	ld a, [wCardListCursorPos]
	bit B_PAD_UP, b
	jr z, .check_d_down

	push af
	ld a, SFX_CURSOR
	ld [wMenuInputSFX], a
	ld a, [wCardListCursorPos]
	ld hl, wCardListVisibleOffset
	add [hl]
	ld hl, wFirstOwnedCardIndex
	cp [hl]
	jr z, .open_card_page_pop_af
	pop af

	dec a
	bit 7, a
	jr z, .got_new_pos
	ld a, [wCardListVisibleOffset]
	or a
	jr z, .open_card_page
	dec a
	ld [wCardListVisibleOffset], a
	xor a
	jr .got_new_pos

.check_d_down
	bit B_PAD_DOWN, b
	jr z, .open_card_page
	ld hl, wMenuInputSFX
	ld [hl], SFX_CURSOR
	inc a
	cp c
	jr c, .got_new_pos
	push af
	ld hl, wCurCardListPtr
	ld a, [hli]
	ld h, [hl]
	ld l, a
	ld b, $00
	ld a, [wCardListCursorPos]
	ld c, a
	add hl, bc
	ld a, [wCardListVisibleOffset]
	inc a
	ld c, a
	add hl, bc
	ld a, [hl]
	or a
	jr z, .open_card_page_pop_af
	ld a, [wCardListVisibleOffset]
	inc a
	ld [wCardListVisibleOffset], a
	pop af
	dec a
.got_new_pos
	; loop back to the start
	ld [wCardListCursorPos], a
	ld a, [wMenuInputSFX]
	or a
	call nz, PlaySFX
	jp HandleCardAlbumCardPage

.open_card_page_pop_af
	pop af
.open_card_page
	push de
	bank1call OpenCardPage.input_loop
	pop de
	jr .handle_input

.exit
	ld a, $01
	ld [wVBlankOAMCopyToggle], a
	ld a, [wCardListCursorPos]
	ld [wTempCardListCursorPos], a
	ret


; preserves de
; input:
;	wOwnedCardsCountList = $ff-terminated list with card counts of every card in the given set
; output:
;	[wFirstOwnedCardIndex] = position in the given list of the first card that's owned
GetFirstOwnedCardIndex:
	ld hl, wOwnedCardsCountList
	ld b, 0
.loop_cards
	ld a, [hli]
	cp CARD_NOT_OWNED
	jr nz, .owned
	inc b
	jr .loop_cards
.owned
	ld a, b
	ld [wFirstOwnedCardIndex], a
	ret


; primary function which handles all of the card album menu screens
CardAlbum:
	ld a, $01
	ldh [hffb4], a
	xor a
.booster_pack_menu
	ld hl, .SetSelectionMenuParams
	call InitializeMenuParameters
	call .ShowSetSelectionMenu
.loop_input_1
	call DoFrame
	call HandleMenuInput ; CreateCardSetListAndInitListCoords is called by wMenuUpdateFunc
	jr nc, .loop_input_1
	cp -1
	ret z ; exit if the B button was pressed

	call .PrintCardCount
	xor a
	ld [wCardListVisibleOffset], a
	call PrintCardSetListEntries
	call EnableLCD
	ld a, [wNumEntriesInCurFilter]
	or a
	jr nz, .get_num_card_entries

.loop_input_2
	call DoFrame
	ldh a, [hKeysPressed]
	and PAD_B
	jr z, .loop_input_2
	ld a, SFX_CANCEL
	call PlaySFX
	ldh a, [hCurMenuItem]
	jr .booster_pack_menu

.get_num_card_entries
	ld hl, wFilteredCardList
	ld b, -1
.loop_card_ids
	inc b
	ld a, [hli]
	or a
	jr nz, .loop_card_ids
	ld a, b
	ld [wNumCardListEntries], a

	xor a
	ld hl, .CardListMenuParams
	call InitCardSelectionParams
	ld a, [wNumEntriesInCurFilter]
	ld hl, wNumVisibleCardListEntries
	cp [hl]
	jr nc, .enough_entries
	; total number of entries is less than the number of visible entries,
	; so set the number of cursor positions to the list size.
	ld [wCardListNumCursorPositions], a
.enough_entries
	ld hl, wCardListUpdateFunction
	ld a, LOW(PrintCardSetListEntries)
	ld [hli], a
	ld [hl], HIGH(PrintCardSetListEntries)
	xor a
	ld [wced2], a
.loop_input_3
	call DoFrame
	call HandleDeckCardSelectionList
	jr c, .selection_made
	call HandleLeftRightInCardList
	jr c, .loop_input_3
	ldh a, [hDPadHeld]
	and PAD_START
	jr z, .loop_input_3
	; START button was pressed
.open_card_page
	ld a, SFX_CONFIRM
	call PlaySFX
	ld a, [wCardListNumCursorPositions]
	ld [wTempCardListNumCursorPositions], a
	ld a, [wCardListCursorPos]
	ld [wTempCardListCursorPos], a
	ld c, a
	ld a, [wCardListVisibleOffset]
	add c
	ld hl, wOwnedCardsCountList
	ld c, a
	ld b, $00
	add hl, bc
	ld a, [hl]
	cp CARD_NOT_OWNED
	jr z, .loop_input_3

	; set wFilteredCardList as current card list
	ld hl, wCurCardListPtr
	ld a, LOW(wFilteredCardList)
	ld [hli], a
	ld [hl], HIGH(wFilteredCardList)

	call GetFirstOwnedCardIndex
	call HandleCardAlbumCardPage
	call .PrintCardCount
	call PrintCardSetListEntries
	call EnableLCD
	ld hl, .CardListMenuParams
	call InitCardSelectionParams
	ld a, [wTempCardListNumCursorPositions]
	ld [wCardListNumCursorPositions], a
	ld a, [wTempCardListCursorPos]
	ld [wCardListCursorPos], a
	jr .loop_input_3

.selection_made
	call DrawListCursor_Invisible
	ld a, [wCardListCursorPos]
	ld [wTempCardListCursorPos], a
	ldh a, [hffb3]
	inc a ; cp -1
	jr nz, .open_card_page ; jump if B button wasn't pressed (i.e. pressed A button)
	; B button was pressed
	ldh a, [hCurMenuItem]
	jp .booster_pack_menu

.SetSelectionMenuParams:
	db 3, 6 ; cursor x, cursor y
	db 2 ; y displacement between items
	db 5 ; number of items
	db SYM_CURSOR_R ; cursor tile number
	db SYM_SPACE ; tile behind cursor
	dw .OnlySelectSetIfListIsNotEmpty ; function pointer if non-0

.CardListMenuParams:
	db 1 ; x position
	db 4 ; y position
	db 2 ; y spacing
	db 0 ; x spacing
	db NUM_CARD_ALBUM_VISIBLE_CARDS ; num entries
	db SYM_CURSOR_R ; visible cursor tile
	db SYM_SPACE ; invisible cursor tile
	dw NULL ; wCardListHandlerFunction

; prints "X/Y" where X is number of cards owned in the set
; and Y is the total card count of the Card Set
.PrintCardCount
	call Set_OBJ_8x8
	xor a ; SYM_SPACE
	ld [wTileMapFill], a
	call EmptyScreen
	call ZeroObjectPositionsAndToggleOAMCopy
	call LoadCursorTile
	call LoadSymbolsFont
	call LoadDuelCardSymbolTiles
	call SetDefaultConsolePalettes
	lb de, $3c, $ff
	call SetupText
	lb de, 0, 0
	lb bc, 20, 18
	call DrawRegularTextBox
	ld b, SCREEN_WIDTH
	lb de, 0, 2
	call DrawTextBoxSeparator
	call .CountOwnedCardsInSet
	ld a, [wSelectedCardSet]

	ld c, a
	ld b, $00
	ld hl, .CardSetTotals
	add hl, bc
	ld e, [hl]

	cp CARD_SET_PROMOTIONAL
	jr nz, .has_card_set_count
	ld a, [wOwnedPhantomCardFlags]
	bit VENUSAUR_OWNED_PHANTOM_F, a
	jr nz, .check_owns_mew
	dec e
.check_owns_mew
	bit MEW_OWNED_PHANTOM_F, a
	jr nz, .has_card_set_count
	dec e
.has_card_set_count
	ld a, [wNumOwnedCardsInSet]
	ld hl, wDefaultText
	call ConvertToNumericalDigits
	call CalculateOnesAndTensDigits
	ld [hl], TX_SYMBOL
	inc hl
	ld [hl], SYM_SLASH
	inc hl
	ld a, e
	call ConvertToNumericalDigits
	ld [hl], TX_END
	ld hl, wDefaultText
	lb de, 14, 1
	call InitTextPrinting_ProcessText
	jp EnableLCD

; counts number of cards in wOwnedCardsCountList
; that are not set as CARD_NOT_OWNED
; preserves de and c
; input:
;	wOwnedCardsCountList = $ff-terminated list with card counts of every card in the given set
; output:
;	a & b & [wNumOwnedCardsInSet] = number of cards in the given list
.CountOwnedCardsInSet
	ld hl, wOwnedCardsCountList
	ld b, 0
.loop_card_count
	ld a, [hli]
	cp $ff
	jr z, .got_num_owned_cards
	cp CARD_NOT_OWNED
	jr z, .loop_card_count
	inc b
	jr .loop_card_count
.got_num_owned_cards
	ld a, b
	ld [wNumOwnedCardsInSet], a
	ret

.CardSetTotals
	db 56 ; CARD_SET_COLOSSEUM
	db 50 ; CARD_SET_EVOLUTION
	db 51 ; CARD_SET_MYSTERY
	db 51 ; CARD_SET_LABORATORY
	db 20 ; CARD_SET_PROMOTIONAL

.OnlySelectSetIfListIsNotEmpty
	ldh a, [hKeysPressed]
	and PAD_A | PAD_B
	ret z
	and PAD_A
	jr nz, .a_pressed
	; B button pressed
	ld a, -1
	ldh [hCurMenuItem], a
.set_carry
	scf
	ret

.a_pressed
	ldh a, [hCurMenuItem]
	ld [wSelectedCardSet], a
	call CreateCardSetListAndInitListCoords
	ld a, [wFilteredCardList]
	or a
	jr nz, .set_carry

; there are no cards in the set list, so play a sound effect
; and display a message explaining why this set can't be selected.
; then, reload the selection screen after a short period of time.
	call PlaySFX_InvalidChoice
	ld a, [wSelectedCardSet]
	add a
	ld c, a
	ld b, $00
	ld hl, .SetNames
	add hl, bc
	ld a, [hli]
	ld h, [hl]
	ld l, a
	call LoadTxRam2
	ldtx hl, NoCardsCollectedInThatSetText
	call DrawWideTextBox_PrintText
	; wait about 60 frames before closing the text box
	ld a, 60
	call DoAFrames
	jr .draw_box

.SetNames
	tx ColosseumName   ; CARD_SET_COLOSSEUM
	tx EvolutionName   ; CARD_SET_EVOLUTION
	tx MysteryName     ; CARD_SET_MYSTERY
	tx LaboratoryName  ; CARD_SET_LABORATORY
	tx PromotionalName ; CARD_SET_PROMOTIONAL

.ShowSetSelectionMenu:
	xor a ; SYM_SPACE
	ld [wTileMapFill], a
	call EmptyScreen
	ldh a, [hffb4]
	dec a
	jr nz, .draw_box
	ldh [hffb4], a
	call Set_OBJ_8x8
	call ZeroObjectPositionsAndToggleOAMCopy

	call LoadCursorTile
	call LoadSymbolsFont
	call LoadDuelCardSymbolTiles
	call SetDefaultConsolePalettes
	lb de, $3c, $ff
	call SetupText

.draw_box
	lb de, 0, 0
	lb bc, 20, 18
	call DrawRegularTextBox
	ld b, SCREEN_WIDTH
	lb de, 0, 2
	call DrawTextBoxSeparator
	ld hl, .BoosterPacksMenuData
	call PlaceTextItems
	jp EnableLCD

.BoosterPacksMenuData
	textitem 2,  1, PokemonTCGSetsText
	textitem 2,  4, ViewWhichCardFileText
	textitem 4,  6, Item1ColosseumText
	textitem 4,  8, Item2EvolutionText
	textitem 4, 10, Item3MysteryText
	textitem 4, 12, Item4LaboratoryText
	textitem 4, 14, Item5PromotionalCardText
	db $ff
