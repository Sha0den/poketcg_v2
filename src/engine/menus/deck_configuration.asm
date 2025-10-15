; goes through whole deck in hl
; for each card ID, goes to its corresponding
; entry in sCardCollection and decrements its count
; assumes SRAM is enabled
; preserves hl
; input:
;	hl = list of cards in a deck (e.g. wCurDeckCards)
DecrementDeckCardsInCollection:
	push hl
	ld b, $0
	ld d, DECK_SIZE
.loop_deck
	ld a, [hli]
	or a
	jr z, .done
	ld c, a
	push hl
	ld hl, sCardCollection
	add hl, bc
	dec [hl]
	pop hl
	dec d
	jr nz, .loop_deck
.done
	pop hl
	ret


; like AddDeckToCollection, but takes care to check if increasing
; the collection count would go over MAX_AMOUNT_OF_CARD and caps it.
; this is because it's used within Gift Center, so we cannot assume that
; the deck configuration won't make it go over MAX_AMOUNT_OF_CARD.
; preserves hl
; input:
;	hl = deck configuration with cards to add
AddGiftCenterDeckCardsToCollection:
	push hl
	ld b, $0
	ld d, DECK_SIZE
.loop_deck
	ld a, [hli]
	or a
	jr z, .done
	ld c, a
	push hl
	push de
	push bc
	ld a, ALL_DECKS
	call CreateCardCollectionListWithDeckCards
	pop bc
	pop de
	ld hl, wTempCardCollection
	add hl, bc
	ld a, [hl]
	cp MAX_AMOUNT_OF_CARD
	jr z, .next_card ; capped
	call EnableSRAM
	ld hl, sCardCollection
	add hl, bc
	ld a, [hl]
	cp CARD_NOT_OWNED
	jr nz, .incr
	; not owned
	xor a
	ld [hl], a
.incr
	inc [hl]
.next_card
	pop hl
	dec d
	jr nz, .loop_deck
.done
	pop hl
	jp DisableSRAM


; adds all cards in the deck at hl to the player's collection
; assumes SRAM is enabled
; preserves hl
; input:
;	hl = pointer to the deck list
AddDeckToCollection:
	push hl
	ld b, $0
	ld d, DECK_SIZE
.loop_deck
	ld a, [hli]
	or a
	jr z, .done
	ld c, a
	push hl
	ld hl, sCardCollection
	add hl, bc
	inc [hl]
	pop hl
	dec d
	jr nz, .loop_deck
.done
	pop hl
	ret


; draws the screen which shows the player's current deck configurations
; input:
;	a = DECK_* flags to pick which deck names to show
DrawDecksScreen:
	ldh [hffb5], a
	call EmptyScreenAndLoadFontDuelAndDeckIcons
	lb de, 0,  0
	lb bc, 20, 13
	call DrawRegularTextBox
	ld b, SCREEN_WIDTH
	lb de, 0, 3
	call DrawTextBoxSeparator
	ld b, SCREEN_WIDTH
	lb de, 0, 6
	call DrawTextBoxSeparator
	ld b, SCREEN_WIDTH
	lb de, 0, 9
	call DrawTextBoxSeparator
	
	ld hl, DeckNameMenuData
	call PlaceTextItems

; for each deck, check if it has cards and if so,
; then mark it as valid in wValidDecks
	xor a
	ld [wValidDecks], a
; deck 1
	ldh a, [hffb5]
	bit 0, a
	jr z, .skip_name_1
	ld hl, sDeck1Name
	lb de, 6, 2
	call PrintDeckName
.skip_name_1
	ld hl, sDeck1Cards
	call CheckIfDeckHasCards
	jr c, .deck_2
	ld hl, wValidDecks
	set DECK_1_F, [hl]
	lb de, 1, 1
	call DrawDeckIcon

.deck_2
	ldh a, [hffb5]
	bit 1, a
	jr z, .skip_name_2
	ld hl, sDeck2Name
	lb de, 6, 5
	call PrintDeckName
.skip_name_2
	ld hl, sDeck2Cards
	call CheckIfDeckHasCards
	jr c, .deck_3
	ld hl, wValidDecks
	set DECK_2_F, [hl]
	lb de, 1, 4
	call DrawDeckIcon

.deck_3
	ldh a, [hffb5]
	bit 2, a
	jr z, .skip_name_3
	ld hl, sDeck3Name
	lb de, 6, 8
	call PrintDeckName
.skip_name_3
	ld hl, sDeck3Cards
	call CheckIfDeckHasCards
	jr c, .deck_4
	ld hl, wValidDecks
	set DECK_3_F, [hl]
	lb de, 1, 7
	call DrawDeckIcon

.deck_4
	ldh a, [hffb5]
	bit 3, a
	jr z, .skip_name_4
	ld hl, sDeck4Name
	lb de, 6, 11
	call PrintDeckName
.skip_name_4
	ld hl, sDeck4Cards
	call CheckIfDeckHasCards
	jr c, .place_cursor
	ld hl, wValidDecks
	set DECK_4_F, [hl]
	lb de, 1, 10
	call DrawDeckIcon

.place_cursor
; places cursor on sCurrentlySelectedDeck
; if it's an empty deck, then advance the cursor
; until it's selecting a valid deck
	call EnableSRAM
	ld a, [sCurrentlySelectedDeck]
	ld e, a
	ld d, 2
.check_valid_deck
	ld a, e
	call CheckIfDeckIsValid
	jr nc, .valid_selected_deck
	inc e
	ld a, NUM_DECKS
	cp e
	jr nz, .check_valid_deck
	ld e, 0 ; roll back to deck 1
	dec d
	jr nz, .check_valid_deck

.valid_selected_deck
	ld a, e
	ld [sCurrentlySelectedDeck], a
	call DisableSRAM
	call DrawDeckBoxTileOnCurDeck
	jp EnableLCD

DeckNameMenuData:
	textitem 4,  2, Deck1Text
	textitem 4,  5, Deck2Text
	textitem 4,  8, Deck3Text
	textitem 4, 11, Deck4Text
	db $ff


; copies text from hl to wDefaultText with " deck" appended to the end
; input:
;	hl = pointer to deck name
CopyDeckName:
	ld de, wDefaultText
	call CopyListFromHLToDE
	ld hl, wDefaultText
	call GetTextLengthInTiles
	ld b, $0
	ld hl, wDefaultText
	add hl, bc
	ld d, h
	ld e, l
	ld hl, DeckNameSuffix
;	fallthrough

; copies a $00-terminated list from hl to de
; preserves bc
; input:
;	hl = list to copy
;	de = where to copy
CopyListFromHLToDE:
	ld a, [hli]
	ld [de], a
	or a
	ret z
	inc de
	jr CopyListFromHLToDE


; appends text in hl to wDefaultText and adds " Deck" to the end before printing.
; if it's an empty deck, then print "No Deck" instead.
; preserves de
; input:
;	hl = deck name (sDeck1Name ~ sDeck4Name)
;	de = screen coordinates for printing the deck name
; output:
;	carry = set:  if the deck has no cards
PrintDeckName:
	push hl
	call CheckIfDeckHasCards
	pop hl
	jr c, .no_deck

; print "<deck name> Deck"
	push de
	ld de, wDefaultText
	call CopyListFromHLToDEInSRAM
	ld hl, wDefaultText
	call GetTextLengthInTiles
	ld b, $0
	ld hl, wDefaultText
	add hl, bc
	ld d, h
	ld e, l
	; append " Deck" starting from the given length
	ld hl, DeckNameSuffix
	call CopyListFromHLToDE
	pop de
	ld hl, wDefaultText
	call InitTextPrinting_ProcessText
	or a
	ret

; print "No Deck"
.no_deck
	ldtx hl, NoDeckText
	call InitTextPrinting_ProcessTextFromID
	scf
	ret

DeckNameSuffix:
	db " Deck"
	done

; appends text in hl to wDefaultText and adds " Deck" to the end before printing.
; uses spaces to overwrite previously written deck names.
; preserves de
; input:
;	hl = text to append
;	de = screen coordinates for printing the text
; output:
;	carry = set:  if the deck has no cards
PrintDeckNameForDeckMachine:
	push hl
	call CheckIfDeckHasCards
	pop hl
	ret c ; no cards

	push de
	; append the text from hl
	ld de, wDefaultText
	call CopyListFromHLToDEInSRAM

	; get string length (up to DECK_NAME_SIZE_WO_SUFFIX)
	ld hl, wDefaultText
	call GetTextLengthInTiles
	ld a, c
	cp DECK_NAME_SIZE_WO_SUFFIX
	jr c, .got_length
	ld c, DECK_NAME_SIZE_WO_SUFFIX
.got_length
	ld b, $0
	ld hl, wDefaultText
	add hl, bc
	ld d, h
	ld e, l
	; append " Deck" starting from the given length
	ld hl, .text_start
	ld b, .text_end - .text_start
	call CopyNBytesFromHLToDE
	xor a ; TX_END
	ld [wDefaultText + DECK_NAME_SIZE + 2], a
	pop de
	ld hl, wDefaultText
	call InitTextPrinting_ProcessText
	or a
	ret

.text_start
	db " Deck                       "
.text_end


; alternatively, the direct address of the cards can be used,
; since DECK_SIZE > DECK_NAME_SIZE
; preserves de
; input:
;	hl = deck name (sDeck*Name) or deck cards (sDeck*Cards)
; output:
;	carry = set:  if the deck in hl is not valid, i.e. it has no cards
CheckIfDeckHasCards:
	ld bc, DECK_NAME_SIZE
	add hl, bc
	call EnableSRAM
	ld a, [hl]
	call DisableSRAM
	or a
	ret nz ; return no carry if the first card slot isn't empty
	scf
	ret


; input:
;	de = screen coordinates for drawing the icon
DrawDeckIcon:
	ld a, $c8 ; location of first deck tile
	lb hl, 1, 2
	lb bc, 2, 2 ; rectangle size
	call FillRectangle
	ld a, [wConsole]
	cp CONSOLE_CGB
	ret nz
	ld a, $02 ; CGB Background Palette 2 (blue/green)
	lb bc, 2, 2
	lb hl, 0, 0
	call BankswitchVRAM1
	call FillRectangle
	jp BankswitchVRAM0


; calculates the y coordinate of the currently selected deck
; and draws a deck box icon at that position
DrawDeckBoxTileOnCurDeck:
	call EnableSRAM
	ld a, [sCurrentlySelectedDeck]
	call DisableSRAM
	ld h, 3
	ld l, a
	call HtimesL
	ld e, l
	inc e ; (sCurrentlySelectedDeck * 3) + 1
	ld d, 1
;	fallthrough

; input:
;	de = screen coordinates for drawing the icon
DrawDeckBoxTileAtDE:
	ld a, $cc ; location of first deck box tile
	lb hl, 1, 2
	lb bc, 2, 2 ; rectangle size
	call FillRectangle
	ld a, [wConsole]
	cp CONSOLE_CGB
	ret nz
	ld a, $04 ; CGB Background Palette 4 (orange/red)
	lb bc, 2, 2
	lb hl, 0, 0
	call BankswitchVRAM1
	call FillRectangle
	jp BankswitchVRAM0

; handles user input when selecting a card filter while building a deck.
; the handling of selecting cards from the list, to add to or remove cards
; from the deck, is done in HandleDeckCardSelectionList.
; this function is similar to HandlePlayersCardsScreen.
HandleDeckBuildScreen:
	call WriteCardListsTerminatorBytes
	call CountNumberOfCardsForEachCardType
.skip_count
	call DrawCardTypeIconsAndPrintCardCounts
	xor a
	ld [wCardListVisibleOffset], a
	ld [wCurCardTypeFilter], a ; FILTER_GRASS
.print_card_list
	call PrintFilteredCardList
.skip_draw
	ld hl, FiltersCardSelectionParams
	call InitCardSelectionParams
.wait_input
	call DoFrame
	xor a ; FALSE
	ld [wReturnToCardListFromDeckBuildMenu], a ; FALSE
	ldh a, [hDPadHeld]
	and PAD_START
	jp nz, OpenDeckConfigurationMenu

	ld a, [wCurCardTypeFilter]
	ld b, a
	ld a, [wTempCardTypeFilter]
	cp b
	jr z, .check_down_btn
	; need to refresh the filtered card list
	ld [wCurCardTypeFilter], a
	ld hl, wCardListVisibleOffset
	ld [hl], 0
	call PrintFilteredCardList
	ld a, NUM_FILTERS
	ld [wCardListNumCursorPositions], a
.check_down_btn
	ldh a, [hDPadHeld]
	and PAD_DOWN
	jr z, .no_down_btn
	call ConfirmSelectionAndReturnCarry
	jr .jump_to_list

.no_down_btn
	call HandleCardSelectionInput
	jr nc, .wait_input
	cp -1
	jp z, .try_to_exit ; ask to exit the deck builder if the B button was pressed

; input was made to jump to the card list
.jump_to_list
	ld a, [wNumEntriesInCurFilter]
	or a
	jr z, .wait_input

	xor a
.start_list_selection
	ld hl, FilteredCardListSelectionParams
	call InitCardSelectionParams
	ld a, [wNumEntriesInCurFilter]
	ld [wNumCardListEntries], a
	ld hl, wNumVisibleCardListEntries
	cp [hl]
	jr nc, .enough_entries
	; total number of entries is less than the number of visible entries,
	; so set the number of cursor positions to the list size.
	ld [wCardListNumCursorPositions], a
.enough_entries
	ld hl, wCardListUpdateFunction
	ld a, LOW(PrintDeckBuildingCardList)
	ld [hli], a
	ld [hl], HIGH(PrintDeckBuildingCardList)
	ld a, $01
	ld [wced2], a

.loop_input
	call DoFrame
	ld a, [wCardListCursorPos]
	ld [wTempFilteredCardListNumCursorPositions], a
	ld a, TRUE
	ld [wReturnToCardListFromDeckBuildMenu], a
	ldh a, [hDPadHeld]
	and PAD_START
	jp nz, OpenDeckConfigurationMenu

	call HandleSelectUpAndDownInList
	jr c, .loop_input
	call HandleDeckCardSelectionList
	jr c, .selection_made
	jr .loop_input

.open_card_page
	ld a, SFX_CONFIRM
	call PlaySFX
	ld a, [wCardListNumCursorPositions]
	ld [wTempCardListNumCursorPositions], a
	ld a, [wCardListCursorPos]
	ld [wTempCardListCursorPos], a
	ld de, wFilteredCardList
	call OpenCardPageFromCardList
	; return to card list
	call DrawCardTypeIconsAndPrintCardCounts
	ld hl, FiltersCardSelectionParams
	call InitCardSelectionParams
	ld a, [wCurCardTypeFilter]
	ld [wTempCardTypeFilter], a
	call DrawHorizontalListCursor_Visible
	call PrintDeckBuildingCardList
	ld hl, FilteredCardListSelectionParams
	call InitCardSelectionParams
	ld a, [wTempCardListNumCursorPositions]
	ld [wCardListNumCursorPositions], a
	ld a, [wTempCardListCursorPos]
	ld [wCardListCursorPos], a
	jr .loop_input

.selection_made
	call DrawListCursor_Invisible
	ld a, [wCardListCursorPos]
	ld [wTempCardListCursorPos], a
	ldh a, [hffb3]
	cp -1
	jr nz, .open_card_page
	; B button was pressed
	ld hl, FiltersCardSelectionParams
	call InitCardSelectionParams
	ld a, [wCurCardTypeFilter]
	ld [wTempCardTypeFilter], a
	jp .wait_input

.try_to_exit
	ld hl, wDeckConfigurationMenuHandlerFunction
	ld a, [hli]
	cp LOW(HandleDeckConfigurationMenu)
	jr nz, .ask_to_cancel
	ld a, [hl]
	cp HIGH(HandleDeckConfigurationMenu)
	jr nz, .ask_to_cancel
	; currently building a deck, so decide whether deck should be saved
	ldtx hl, QuitModifyingTheDeckText
	call YesOrNoMenuWithText
	jr c, .return_to_selection ; erase text box and return if "No" was selected
	; Player chose to quit
	call CheckIfCurrentDeckWasChanged
	ret nc ; return no carry if the deck wasn't changed
	ld hl, wCurDeckCards
	call CheckCardListForBasicPokemonUsingCardID
	ret nc ; return no carry if the deck doesn't have any Basic Pokémon cards
	ld a, [wTotalCardCount]
	cp DECK_SIZE
	jr z, .ask_to_save_deck
	or a
	ret

.ask_to_save_deck
	ldtx hl, SaveThisDeckText
	call YesOrNoMenuWithText_SetCursorToYes
	ccf ; return if carry if "Yes" and no carry if "No"
	ret

.ask_to_cancel
	ldtx hl, WouldYouLikeToQuitText
	call YesOrNoMenuWithText
	ret nc ; exit if the Player selected "Yes"
	; "No" was selected
.return_to_selection
	call ClearWideTextBox
	ld a, [wCurCardTypeFilter]
	jp .print_card_list

FiltersCardSelectionParams:
	db 1 ; x position
	db 1 ; y position
	db 0 ; y spacing
	db 2 ; x spacing
	db NUM_FILTERS ; number of entries
	db SYM_CURSOR_D ; visible cursor tile
	db SYM_SPACE ; invisible cursor tile
	dw NULL ; wCardListHandlerFunction

FilteredCardListSelectionParams:
	db 0 ; x position
	db 7 ; y position
	db 2 ; y spacing
	db 0 ; x spacing
	db NUM_FILTERED_LIST_VISIBLE_CARDS ; number of entries
	db SYM_CURSOR_R ; visible cursor tile
	db SYM_SPACE ; invisible cursor tile
	dw NULL ; wCardListHandlerFunction


OpenDeckConfigurationMenu:
	ld a, SFX_CONFIRM
	call PlaySFX
	xor a
	ld [wYourOrOppPlayAreaCurPosition], a
	ld de, wDeckConfigurationMenuTransitionTable
	ld hl, wMenuInputTablePointer
	ld a, [de]
	ld [hli], a
	inc de
	ld a, [de]
	ld [hl], a
	ld a, $ff
	ld [wDuelInitialPrizesUpperBitsSet], a
.skip_init
	xor a
	ld [wCheckMenuCursorBlinkCounter], a
	ld hl, wDeckConfigurationMenuHandlerFunction
	ld a, [hli]
	ld h, [hl]
	ld l, a
	jp hl


; related to wMenuInputTablePointer
; with this table, the cursor moves into the proper location based on the input.
; x coordinate, y coordinate, , D-pad up, D-pad down, D-pad right, D-pad left
DeckConfigurationMenu_TransitionTable:
	cursor_transition $10, $18, $00, $04, $02, $01, $01 ; View Deck List
	cursor_transition $60, $18, $00, $05, $03, $00, $00 ; Change Name
	cursor_transition $10, $28, $00, $00, $04, $03, $03 ; Discard Changes
	cursor_transition $60, $28, $00, $01, $05, $02, $02 ; Empty Deck
	cursor_transition $10, $38, $00, $02, $00, $05, $05 ; Save and Quit
	cursor_transition $60, $38, $00, $03, $01, $04, $04 ; Delete Deck

DeckBuildMenuData:
	; x, y, text ID
	textitem  2, 1, DeckBuildingMenuOptions1Text
	textitem 12, 1, DeckBuildingMenuOptions2Text
	db $ff

StatisticsSuffix:
	db " Statistics"
	done

; this function is loaded to wDeckConfigurationMenuHandlerFunction during DeckSelectionMenu.
HandleDeckConfigurationMenu:
; draw the menu box
	lb de, 0, 0
	lb bc, 20, 7
	call DrawRegularTextBox
; print the menu options
	ld hl, DeckBuildMenuData
	call PlaceTextItems
; draw the deck info box
	lb de, 0, 7
	lb bc, 20, 11
	call DrawRegularTextBox
; get the name of the deck for the info box header
	ld hl, wCurDeckName
	ld a, [hl]
	or a
	jr z, .print_new_deck_title
	ld de, wDefaultText
	push de
	call CopyListFromHLToDE
	pop hl ; wDefaultText
	push hl
	call GetTextLengthInTiles
	ld b, $0
	add hl, bc
	ld d, h
	ld e, l
	ld hl, DeckNameSuffix
	call CopyListFromHLToDE
	ld hl, StatisticsSuffix
	call CopyListFromHLToDE
	pop hl ; wDefaultText (contains "<deck name> Deck Statistics")
	ld e, 8
	call InitTextPrinting_ProcessCenteredText
	ld hl, wDefaultText + 1 ; ignore control character (TX_HALFWIDTH)
	ld b, -1
.get_length
	inc b
	ld a, [hli]
	or a ; cp TX_END
	jr nz, .get_length
	jr .print_underline

.print_new_deck_title
	lb de, 5, 8
	ldtx hl, NewDeckStatisticsText
	call InitTextPrinting_ProcessTextFromID
	ld b, 19 ; number of characters in "New Deck Statistics"

; underline the newly printed text
.print_underline
	ld hl, wDefaultText
	ld a, TX_HALFWIDTH
	ld [hli], a
	ld a, b
	cp 35
	ld a, "￣"
	jr nc, .underline_loop ; skip underline extension if text uses all 18 tiles
	; extend underline one character to the left
	dec d
	ld a, " "
	ld [hli], a
	ld a, "￣"
	ld [hli], a
.underline_loop
	ld [hli], a
	dec b
	jr nz, .underline_loop
	ld [hl], b ; TX_END
	ld hl, wDefaultText
	inc e
	call InitTextPrinting_ProcessText

; find how many of each type of card is in the current deck and store counts in wram
	xor a
	ld hl, wCurDeckBasicPokemonCardCount
	ld [hli], a ; wCurDeckBasicPokemonCardCount = 0
	ld [hli], a ; wCurDeckEvolutionCardCount = 0
	ld [hli], a ; wCurDeckTrainerCardCount = 0
	ld [hl], a  ; wCurDeckEnergyCardCount = 0
	ld bc, wCurDeckCards
.card_type_quantities_loop
	ld a, [bc]
	or a
	jr z, .print_deck_statistics
	ld e, a
	call LoadCardDataToBuffer1_FromCardID
	inc bc
	ld a, [wLoadedCard1Type]
	cp TYPE_ENERGY
	jr c, .pokemon_card
	cp TYPE_TRAINER
	jr nc, .trainer_card
; Energy card
	ld hl, wCurDeckEnergyCardCount
	inc [hl]
	jr .card_type_quantities_loop
.pokemon_card
	ld a, [wLoadedCard1Stage]
	or a ; cp BASIC
	jr nz, .evolution
	ld hl, wCurDeckBasicPokemonCardCount
	inc [hl]
	jr .card_type_quantities_loop
.evolution
	ld hl, wCurDeckEvolutionCardCount
	inc [hl]
	jr .card_type_quantities_loop
.trainer_card
	ld hl, wCurDeckTrainerCardCount
	inc [hl]
	jr .card_type_quantities_loop

; print the relevant card types and their quantities in the info box
.print_deck_statistics
	lb de, 5, 10
; check Basic Pokémon count
	ld a, [wCurDeckBasicPokemonCardCount]
	or a
	jr z, .check_evolution_count
	call WriteOneByteNumberInHalfwidthTextFormat_TrimLeadingZeros
	ldtx hl, BasicPokemonText
	inc d
	inc d
	call InitTextPrinting_ProcessTextFromID
	dec d
	dec d
	inc e
	inc e
.check_evolution_count
	ld a, [wCurDeckEvolutionCardCount]
	or a
	jr z, .check_trainer_count
	ld b, a
	call WriteOneByteNumberInHalfwidthTextFormat_TrimLeadingZeros
	dec b ; cp 1
	ldtx hl, EvolutionCardsText
	jr nz, .print_evolution_text
	ldtx hl, EvolutionCardText
.print_evolution_text
	inc d
	inc d
	call InitTextPrinting_ProcessTextFromID
	dec d
	dec d
	inc e
	inc e
.check_trainer_count
	ld a, [wCurDeckTrainerCardCount]
	or a
	jr z, .check_energy_count
	ld b, a
	call WriteOneByteNumberInHalfwidthTextFormat_TrimLeadingZeros
	dec b ; cp 1
	ldtx hl, TrainerCardsText
	jr nz, .print_trainer_text
	ldtx hl, TrainerCardText
.print_trainer_text
	inc d
	inc d
	call InitTextPrinting_ProcessTextFromID
	dec d
	dec d
	inc e
	inc e
.check_energy_count
	ld a, [wCurDeckEnergyCardCount]
	or a
	jr z, .wait_input
	ld b, a
	call WriteOneByteNumberInHalfwidthTextFormat_TrimLeadingZeros
	dec b ; cp 1
	ldtx hl, EnergyCardsText
	jr nz, .print_energy_text
	ldtx hl, EnergyCardText
.print_energy_text
	inc d
	inc d
	call InitTextPrinting_ProcessTextFromID

.wait_input
	ld a, $1
	ld [wVBlankOAMCopyToggle], a
	call DoFrame
	ldh a, [hDPadHeld]
	and PAD_START
	ld a, -1
	call nz, PlaySFXConfirmOrCancel_Bank2
	jr nz, .close_menu
	call YourOrOppPlayAreaScreen_HandleInput
	jr nc, .wait_input
	ld [wced6], a
	cp -1
	jr nz, .selection_made
	; B button was pressed
.close_menu
	call DrawCardTypeIconsAndPrintCardCounts
	ld a, [wTempCardListCursorPos]
	ld [wCardListCursorPos], a
	ld a, [wCurCardTypeFilter]
	call PrintFilteredCardList
	ld a, [wReturnToCardListFromDeckBuildMenu]
	or a
	ld a, [wCurCardTypeFilter]
	jp z, HandleDeckBuildScreen.skip_draw
	ld hl, FiltersCardSelectionParams
	call InitCardSelectionParams
	ld a, [wCurCardTypeFilter]
	ld [wTempCardTypeFilter], a
	call DrawHorizontalListCursor_Visible
	ld a, [wTempFilteredCardListNumCursorPositions]
	jp HandleDeckBuildScreen.start_list_selection

.selection_made
	push af
	call YourOrOppPlayAreaScreen_HandleInput.draw_cursor
	ld a, $01
	ld [wVBlankOAMCopyToggle], a
	pop af
	ld hl, .func_table
	call JumpToFunctionInTable
	jp OpenDeckConfigurationMenu.skip_init

.func_table
	dw ViewDeckList            ; View Deck List
	dw ChangeDeckName          ; Change Name
	dw ResetDeckFromSaveData   ; Discard Changes
	dw RemoveAllCardsFromDeck  ; Empty Deck
	dw SaveDeckConfiguration   ; Save and Quit
	dw DismantleDeck           ; Delete Deck


ViewDeckList:
	ld hl, wCardListVisibleOffset
	ld a, [hl]
	ld hl, wCardListVisibleOffsetBackup
	ld [hl], a
	call HandleDeckConfirmationMenu
	call Set_OBJ_8x8
	ld hl, wCardListVisibleOffsetBackup
	ld a, [hl]
	ld hl, wCardListVisibleOffset
	ld [hl], a
	ret


ChangeDeckName:
	call InputCurDeckName
	call ZeroObjectPositionsAndToggleOAMCopy
	jp LoadCursorTile


ResetDeckFromSaveData:
	ldtx hl, ReturnToOriginalConfigurationText
	call YesOrNoMenuWithText
	ret c ; return if "No" was selected
	call GetPointerToDeckCards
	ld e, l
	ld d, h
	ld hl, wCurDeckCards
	call CopyDeckFromSRAM
	; reset filter counts for the deck building screen header
	call CountNumberOfCardsForEachCardType
;	fallthrough

; adds up all of the card type totals in wCardFilterCounts
; and stores the sum in wTotalCardCount.
; preserves de
; output:
;	a & b & [wTotalCardCount] = sum of all card filter counts
GetTotalCardCount:
	lb bc, 0, NUM_FILTERS
	ld hl, wCardFilterCounts
.loop
	ld a, [hli]
	add b
	ld b, a
	dec c
	jr nz, .loop
	ld a, b
	ld [wTotalCardCount], a
	ret


RemoveAllCardsFromDeck:
	ldtx hl, RemoveEveryCardFromTheDeckText
	call YesOrNoMenuWithText
	ret c ; return if "No" was selected
; remove all of the card IDs in wCurDeckCards 
	ld hl, wCurDeckCards
	xor a
	ld b, DECK_SIZE
.loop_deck
	ld [hli], a
	dec b
	jr nz, .loop_deck
; reset all of the filter counts
	ld hl, wCardFilterCounts
	ld b, NUM_FILTERS
.loop_filter_counts
	ld [hli], a
	dec b
	jr nz, .loop_filter_counts
	ld [wTotalCardCount], a
	ret


; output:
;	carry = set:  if the Player decided to save the current deck configuration
;	              (only relevant if using "add sp, $2" before the final return)
SaveDeckConfiguration:
; handle deck configuration size
	ld a, [wTotalCardCount]
	cp DECK_SIZE
	jr z, .ask_to_save_deck
	ldtx hl, ThisIsntA60CardDeckText
	call DrawWideTextBox_WaitForInput
	ldtx hl, ReturnToOriginalConfigurationText
	call YesOrNoMenuWithText
	ldtx hl, TheDeckMustInclude60CardsText
	jr c, .print_warning ; print notification text and return if "No" was selected
; cancel deck building and return to the deck selection screen
	add sp, $2
	or a
	ret

.ask_to_save_deck
	ldtx hl, SaveThisDeckText
	call YesOrNoMenuWithText
	ret c ; return if "No" was selected
	ld hl, wCurDeckCards
	call CheckCardListForBasicPokemonUsingCardID
	jr c, .set_carry
	ldtx hl, ThereAreNoBasicPokemonInThisDeckText
	call DrawWideTextBox_WaitForInput
	ldtx hl, YouMustIncludeABasicPokemonInTheDeckText
.print_warning
	jp DrawWideTextBox_WaitForInput

.set_carry
; cancel deck building and return to the deck selection screen (after saving the deck)
	add sp, $2
	scf
	ret


;CancelDeckModifications:
;; if the deck wasn't changed, then allow immediate cancel
;	call CheckIfCurrentDeckWasChanged
;	jr nc, .cancel_modification
;; else prompt the player to confirm
;	ldtx hl, QuitModifyingTheDeckText
;	call YesOrNoMenuWithText
;	ret c
;.cancel_modification
;; cancel deck building and return to the deck selection screen
;	add sp, $2
;	or a
;	ret


DismantleDeck:
	ldtx hl, DismantleThisDeckText
	call YesOrNoMenuWithText
	ret c ; return if "No" was selected
	call CheckIfHasOtherValidDecks
	ldtx hl, ThereIsOnly1DeckSoCannotBeDismantledText
	jp c, DrawWideTextBox_WaitForInput
	call EnableSRAM
	call GetPointerToDeckName
	ld a, [hl]
	or a
	jr z, .done_dismantle ; no need to clear save data for this deck if none exists
	ld a, NAME_BUFFER_LENGTH ; number of bytes that will be cleared (16)
	call ClearMemory_Bank2
	call GetPointerToDeckCards
	call AddDeckToCollection
	ld a, DECK_SIZE ; number of bytes that will be cleared (60)
	call ClearMemory_Bank2
.done_dismantle
; cancel deck building and return to the deck selection screen (after deleting the deck)
	add sp, $2
	jp DisableSRAM


; output:
;	carry = set:  if the current deck was changed (name or configuration)
CheckIfCurrentDeckWasChanged:
	ld a, [wTotalCardCount]
	or a
	jr z, .skip_size_check
	cp DECK_SIZE
	jr nz, .set_carry

.skip_size_check
; copy the selected deck to wCurDeckCardChanges
	call GetPointerToDeckCards
	ld de, wCurDeckCardChanges
	ld b, DECK_SIZE
	call CopyNBytesFromHLToDEInSRAM
	ld a, $ff ; terminator byte
	ld [de], a

; check if this deck was originally empty
	ld de, wCurDeckCards
	ld hl, wCurDeckCardChanges
	ld a, [hl]
	or a
	jr nz, .loop_outer
	; this is a new deck
	ld a, [de]
	or a
	scf
	ret nz ; return carry if at least one card was added

; loops through cards in wCurDeckCards
; then if that card is found in wCurDeckCardChanges
; overwrite it with $00
.loop_outer
	ld a, [de]
	or a
	jr z, .check_empty ; exit loop if there are no more cards to check
	ld b, a
	inc de
	ld hl, wCurDeckCardChanges
.loop_inner
	ld a, [hli]
	cp $ff
	jr z, .loop_outer
	cp b
	jr nz, .loop_inner
	; found
	dec hl
	ld [hl], $00 ; remove this card from wCurDeckCardChanges
	jr .loop_outer

.check_empty
	ld hl, wCurDeckCardChanges
.loop_check_empty
	ld a, [hli]
	cp $ff
	jr z, .is_empty
	or a
	jr z, .loop_check_empty
	; there's still a valid card ID in the list, so return carry
.set_carry
	scf
.done
	jp DisableSRAM

.is_empty
; wCurDeckCardChanges is empty (all $0)
; check if name was changed
	call GetPointerToDeckName
	ld de, wCurDeckName
	call EnableSRAM
.loop_name
	ld a, [de]
	cp [hl]
	jr nz, .set_carry
	or a ; cp TX_END
	jr z, .done ; return no carry if the deck names were also identical
	inc de
	inc hl
	jr .loop_name


; preserves bc and de
; output:
;	carry = set:  if the only valid deck is the current deck
CheckIfHasOtherValidDecks:
	xor a
	ld hl, wValidDecks
	bit DECK_1_F, [hl]
	jr z, .check_deck_2
	inc a
.check_deck_2
	bit DECK_2_F, [hl]
	jr z, .check_deck_3
	inc a
.check_deck_3
	bit DECK_3_F, [hl]
	jr z, .check_deck_4
	inc a
.check_deck_4
	bit DECK_4_F, [hl]
	jr z, .check_count
	inc a
.check_count
	cp 2
	ret nc ; return no carry if there are at least 2 valid decks
	; less than 2 valid decks
	call GetPointerToDeckCards
	call EnableSRAM
	ld a, [hl]
	call DisableSRAM
	or a
	ret z ; return no carry if the currently selected deck is empty
	; current deck is the only valid deck, so return carry
	scf
	ret


; preserves bc
; input:
;	hl = null-terminated list with card IDs
; output:
;	e = card ID of the first Basic Pokémon in the list
;	carry = set:  if there's a Basic Pokémon in the list of cards
CheckCardListForBasicPokemonUsingCardID:
	ld a, [hli]
	ld e, a
	or a
	ret z
	call LoadCardDataToBuffer1_FromCardID
	ld a, [wLoadedCard1Type]
	cp TYPE_ENERGY
	jr nc, CheckCardListForBasicPokemonUsingCardID ; skip if not a Pokémon
	ld a, [wLoadedCard1Stage]
	or a
	jr nz, CheckCardListForBasicPokemonUsingCardID ; skip if stage isn't Basic
	; found a Basic Pokémon
	scf
	ret


; draws each card type icon in a line
; the respective card counts underneath each icon
; and prints"X/60" in the upper-right corner,
; where X is the total card count
DrawCardTypeIconsAndPrintCardCounts:
	call Set_OBJ_8x8
	call EmptyScreenAndLoadFontDuelAndDeckIcons
	lb bc, 0, 5
	ld a, SYM_BOX_TOP
	call FillBGMapLineWithA
	call DrawCardTypeIcons
	call PrintCardTypeCounts
	lb de, 15, 0
	call PrintTotalCardCount
	lb bc, 17, 0
	call PrintSlashSixty
	jp EnableLCD


; draws the same tile across an entire line in BG Map
; if CGB, also fills the line with background palette 4 in VRAM1
; input:
;	a = TX_SYMBOL (SYM_* constant)
;	bc = coordinates to print line
FillBGMapLineWithA::
	call BCCoordToBGMap0Address
	ld b, SCREEN_WIDTH
	call FillDEWithA
	ld a, [wConsole]
	cp CONSOLE_CGB
	ret nz ; return if not CGB
	ld a, $04 ; CGB Background Palette 4 (orange/red)
	ld b, SCREEN_WIDTH
	call BankswitchVRAM1
	call FillDEWithA
	jp BankswitchVRAM0


; fills de with b bytes of the value in register a
; preserves a and de
; input:
;	a = byte to copy
;	b = number of bytes to copy
;	de = where to copy the data
FillDEWithA:
	ld l, e
	ld h, d
.loop
	ld [hli], a
	dec b
	jr nz, .loop
	ret


; saves the count of each type of card that is in wCurDeckCards
; stores these values in wCardFilterCounts
CountNumberOfCardsForEachCardType:
	ld hl, wCardFilterCounts
	ld de, CardTypeFilters
.loop
	ld a, [de]
	cp $ff
	ret z
	inc de
	call CountNumberOfCardsOfType
	ld [hli], a
	jr .loop


; prints "/60" at the coordinates given in bc
; preserves bc
; input:
;	bc = screen coordinates for printing the text
PrintSlashSixty:
	ld hl, wDefaultText
	ld a, SYM_SLASH
	ld [hli], a
	ld a, SYM_6
	ld [hli], a
	ld a, SYM_0
	ld [hld], a
	dec hl ; wDefaultText
	ld a, 3
	jp CopyDataToBGMap0


; creates two separate lists given the card type in register a
; if a card matches the card type given, then it's added to wFilteredCardList.
; if a card has been owned by the player, and its card count is at least 1,
; then its temporary collection count is also added to wOwnedCardsCountList.
; if input a is $ff, then all card types are included, but any owned card
; that has a count of 0 in wTempCardCollection is ignored.
; preserves all registers
; input:
;	a = FILTER_* constant (include all cards in wTempCardCollection if $ff)
;	[wTempCardCollection] = list with every card that contains the quantities to use
CreateFilteredCardList:
	push af
	push bc
	push de
	push hl

; clear wOwnedCardsCountList and wFilteredCardList
	push af
	ld a, DECK_SIZE ; number of bytes that will be cleared (60)
	ld hl, wOwnedCardsCountList
	call ClearMemory_Bank2
;	ld a, DECK_SIZE ; number of bytes that will be cleared (60)
	ld hl, wFilteredCardList
	call ClearMemory_Bank2
	pop af

; loops all cards in collection
	ld hl, $0 ; starting list index = 0
	ld d, h
	ld e, l ; starting card ID = 0
	ld b, a ; input card type
.loop_card_ids
	inc e
	call GetCardType
	jr c, .store_count
	ld c, a
	ld a, b
	cp $ff
	jr z, .add_card
	and FILTER_ENERGY
	cp FILTER_ENERGY
	jr z, .check_energy
	ld a, c
	cp b
	jr nz, .loop_card_ids
	jr .add_card
.check_energy
	ld a, c
	and TYPE_ENERGY
	jr z, .loop_card_ids
.add_card
	push bc
	push hl
	ld bc, wFilteredCardList
	add hl, bc
	ld [hl], e
	ld hl, wTempCardCollection
	add hl, de
	ld b, [hl]
	pop hl
	pop af ; from push bc
	push af
	inc a ; cp $ff (initial input from a register)
	ld a, b
	jr nz, .show_all_owned_cards
	; include any card with at least 1 copy in wTempCardCollection
	and CARD_COUNT_MASK
	or a
	jr z, .next_card
	jr .ok
.show_all_owned_cards
	cp CARD_NOT_OWNED
	jr z, .next_card ; skip this card if it has never been owned
	or a
	jr nz, .ok ; add this card if there's at least 1 copy outside of decks
	call IsCardInAnyDeck
	jr c, .next_card ; skip this card if there are no copies in any built decks
.ok
	push hl
	ld bc, wOwnedCardsCountList
	add hl, bc
	ld [hl], a
	pop hl
	inc l
.next_card
	pop bc
	jr .loop_card_ids

.store_count
	ld a, l
	ld [wNumEntriesInCurFilter], a
; add terminator bytes in both lists
	xor a ; $00
	ld c, l
	ld b, h
	ld hl, wFilteredCardList
	add hl, bc
	ld [hl], a
	dec a ; $ff
	ld hl, wOwnedCardsCountList
	add hl, bc
	ld [hl], a
	pop hl
	pop de
	pop bc
	pop af
	ret


; preserves all registers except b and f
; input:
;	e = card ID
; output:
;	carry = set:  if the given card was not found in any of the saved decks
IsCardInAnyDeck:
	push af
	push hl
	ld hl, sDeck1Cards
	call .FindCardInDeck
	jr nc, .found_card
	ld hl, sDeck2Cards
	call .FindCardInDeck
	jr nc, .found_card
	ld hl, sDeck3Cards
	call .FindCardInDeck
	jr nc, .found_card
	ld hl, sDeck4Cards
	call .FindCardInDeck
	jr nc, .found_card
	pop hl
	pop af
	scf
	ret
.found_card
	pop hl
	pop af
	or a
	ret

; preserves all registers except af and b
; input:
;	e = card ID
;	hl = deck to look through (sDeck*Cards)
; output:
;	carry = set:  if the given card was not found in the given deck
.FindCardInDeck
	call EnableSRAM
	ld b, DECK_SIZE
.loop
	ld a, [hli]
	cp e
	jr z, .done ; return no carry if the given card ID was found in the deck
	dec b
	jr nz, .loop
; not found
	scf
.done
	jp DisableSRAM


; zeroes a bytes starting from hl.
; this function is identical to 'ClearMemory_Bank5',
; 'ClearMemory_Bank6' and 'ClearMemory_Bank8'.
; preserves all registers
; input:
;	a = number of bytes to clear
;	hl = where to begin erasing
ClearMemory_Bank2:
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


; preserves all registers except af and d
; input:
;	e = card ID
; output:
;	a & d = number of cards in wCurDeckCards with the ID from input
GetCountOfCardInCurDeck:
	push hl
	ld hl, wCurDeckCards
	ld d, 0
.loop
	ld a, [hli]
	or a
	jr z, .done
	cp e
	jr nz, .loop
	inc d
	jr .loop
.done
	ld a, d
	pop hl
	ret


; finds out how many copies the player owns of a given card.
; looks it up in wFilteredCardList, then uses the index
; to retrieve the total value from wOwnedCardsCountList.
; preserves bc and hl
; input:
;	e = card ID
; output:
;	a = number of cards owned by the player matching the card ID from input
GetOwnedCardCount:
	push hl
	ld hl, wFilteredCardList
	ld d, -1
.loop
	inc d
	ld a, [hli]
	or a
	jr z, .done ; return with a = 0 if the card wasn't found in the list
	cp e
	jr nz, .loop
	ld hl, wOwnedCardsCountList
	push de
	ld e, d
	ld d, $00
	add hl, de
	pop de
	ld a, [hl]
.done
	pop hl
	ret


; appends text "X/Y", where X is the number of included cards
; and Y is the total number of cards in storage of a given card ID
; preserves all registers
; input:
;	e = card ID
;	hl = text string (e.g. wDefaultText)
AppendOwnedCardCountAndStorageCountNumbers:
	push af
	push bc
	push de
	push hl
; find the end of the text string ($00 byte)
	dec hl
.loop
	inc hl
	ld a, [hl]
	or a ; cp TX_END
	jr nz, .loop
; add current and total collection amounts to text string
	push de
	call GetCountOfCardInCurDeck
	call ConvertToNumericalDigits
	ld [hl], TX_SYMBOL
	inc hl
	ld [hl], SYM_SLASH
	inc hl
	pop de
	call GetOwnedCardCount
	call ConvertToNumericalDigits
	ld [hl], TX_END
	pop hl
	pop de
	pop bc
	pop af
	ret


; determines the ones and tens digits in a for printing.
; the ones place is added to SYM_0 so that it maps to a numerical character.
; if the tens place is 0, it maps to an empty character (SYM_SPACE).
; preserves all registers
; input:
;	a = two-digit number to convert to symbol font
; output:
;	[wDecimalDigitsSymbols] = number in text symbol format with digits reversed
CalculateOnesAndTensDigits:
	push af
	push bc
	push de
	push hl
	ld c, -1
.loop
	inc c
	sub 10
	jr nc, .loop
	add 10
; a = ones digit
	add SYM_0
	ld hl, wDecimalDigitsSymbols
	ld [hli], a
; c = tens digit
	ld a, c
	or a
	jr z, .store_tens_digit ; use SYM_SPACE if tens digit = 0
	add SYM_0
.store_tens_digit
	ld [hl], a
	pop hl
	pop de
	pop bc
	pop af
	ret

; converts a two-digit number in register a to numerical symbols for ProcessText
; places the symbols in hl
; preserves de and c
; input:
;	a = two-digit number to convert to symbol font
;	hl = where to store the numerical text string
ConvertToNumericalDigits:
	call CalculateOnesAndTensDigits
	push hl
	ld hl, wDecimalDigitsSymbols
	ld a, [hli]
	ld b, a
	ld a, [hl]
	pop hl
	ld [hl], TX_SYMBOL
	inc hl
	ld [hli], a
	ld [hl], TX_SYMBOL
	inc hl
	ld a, b
	ld [hli], a
	ret


; counts the number of cards in wCurDeckCards
; that are the same type as the input in register a.
; if input is $20, counts all Energy cards instead.
; preserves de and hl
; input:
;	a = card type (FILTER_* constant)
; output:
;	a = number of cards with the same type
CountNumberOfCardsOfType:
	push de
	push hl
	ld hl, $0
	ld b, a
	ld c, l ; 0
.loop_cards
	push hl
	push bc
	ld bc, wCurDeckCards
	add hl, bc
	ld a, [hl]
	pop bc
	pop hl
	inc l
	or a
	jr z, .done ; end of card list

; gets card type and compares it with the type from input.
; if it's the same type, then increase the count.
; if the input was FILTER_ENERGY, then run a separate comparison.
	ld e, a
	call GetCardType
	jr c, .done
	ld d, a
	ld a, b
	and FILTER_ENERGY
	cp FILTER_ENERGY
	ld a, d
	jr z, .check_energy
	cp b
	jr nz, .loop_cards
	inc c
	jr .loop_cards

; counts all Energy cards as the same filter
.check_energy
	and TYPE_ENERGY
	jr z, .loop_cards
	inc c
	jr .loop_cards

.done
	ld a, c
	pop hl
	pop de
	ret


; prints the card count of each individual card type.
; assumes CountNumberOfCardsForEachCardType was already called.
; this is done by processing text in a single line and concatenating all digits.
PrintCardTypeCounts:
	ld c, NUM_FILTERS
	ld de, wCardFilterCounts
	ld hl, wDefaultText
.loop
	ld a, [de]
	inc de
	call ConvertToNumericalDigits
	dec c
	jr nz, .loop
	ld [hl], c ; $00 (TX_END)
	lb de, 1, 4
	ld hl, wDefaultText
	jp InitTextPrinting_ProcessText


; prints the list of cards, applying the filter from register a.
; the counts of each card displayed is taken from wCurDeck.
; preserves af
; input:
;	a = index for CardTypeFilters
PrintFilteredCardList:
	push af
	ld hl, CardTypeFilters
	ld b, $00
	ld c, a
	add hl, bc
	ld a, [hl]
	push af

; copy sCardCollection to wTempCardCollection
	ld hl, sCardCollection
	ld de, wTempCardCollection
	ld b, CARD_COLLECTION_SIZE - 1
	call CopyNBytesFromHLToDEInSRAM

	ld a, [wIncludeCardsInDeck]
	or a
	jr z, .ok
	call GetPointerToDeckCards
	ld d, h
	ld e, l
	call IncrementDeckCardsInTempCollection
.ok
	pop af
	call CreateFilteredCardList
	ld a, NUM_FILTERED_LIST_VISIBLE_CARDS
	ld [wNumVisibleCardListEntries], a
	ld hl, wCardListCoords
	ld [hl], 7 ; initial y coordinate
	inc hl
	ld [hl], 1 ; initial x coordinate
	call PrintDeckBuildingCardList
	pop af
	ret

; used to filter the cards in the deck building/card selection screen
CardTypeFilters:
	db FILTER_GRASS
	db FILTER_FIRE
	db FILTER_WATER
	db FILTER_LIGHTNING
	db FILTER_FIGHTING
	db FILTER_PSYCHIC
	db FILTER_COLORLESS
	db FILTER_TRAINER
	db FILTER_ENERGY
	db $ff ; end of list


; counts all of the cards from each card type (stored in wCardFilterCounts)
; and stores it in wTotalCardCount, then prints the number at de.
; preserves de
; input:
;	de = screen coordinates for printing the count
PrintTotalCardCount:
	call GetTotalCardCount
	ld hl, wDefaultText
	call ConvertToNumericalDigits
	ld [hl], TX_END
	ld hl, wDefaultText
	jp InitTextPrinting_ProcessText


; prints the name, level and storage count of the cards
; that are visible in the list window in the form: CARD NAME/LEVEL X/Y,
; where X is the current count of that card and Y is its storage count
; preserves bc
PrintDeckBuildingCardList:
	push bc
	lb de, 1, 0
	ldtx hl, PressSTARTToViewMenuText
	call InitTextPrinting_ProcessTextFromID
	ld hl, wCardListCoords
	ld e, [hl]
	inc hl
	ld d, [hl]
	ld b, 19 ; x coordinate
	ld c, e
	dec c
	ld a, [wCardListVisibleOffset]
	or a
	jr z, .got_cursor_tile ; use SYM_SPACE (blank tile) if can't scroll up
	ld a, SYM_CURSOR_U
.got_cursor_tile
	call WriteByteToBGMap0

; iterates by decreasing value in wNumVisibleCardListEntries
; by 1 until it reaches 0
	ld a, [wCardListVisibleOffset]
	ld c, a
	ld b, $0
	ld hl, wFilteredCardList
	add hl, bc
	ld a, [wNumVisibleCardListEntries]
.loop_filtered_cards
	or a
	jr z, .exit_loop
	ld b, a
	ld a, [hli]
	push hl
	or a
	jr z, .invalid_card ; print empty row if list value = 0
	push de
	ld e, a
	call AddCardIDToVisibleList
	call LoadCardDataToBuffer1_FromCardID
	ld a, 13
	call CopyCardNameAndLevel
	call AppendOwnedCardCountAndStorageCountNumbers
	pop de
	ld hl, wDefaultText
	jr .process_text

.invalid_card
	ld hl, Text_9a30 ; print an empty row
.process_text
	call InitTextPrinting_ProcessText
	pop hl
	ld a, b
	dec a
	inc e
	inc e
	jr .loop_filtered_cards

.exit_loop
	ld a, [hl]
	or a
	jr z, .cannot_scroll
	; draw the down cursor to show that there are more cards to view
	xor a ; FALSE
	ld [wUnableToScrollDown], a
	ld a, SYM_CURSOR_D
	jr .draw_cursor
.cannot_scroll
	ld a, TRUE
	ld [wUnableToScrollDown], a
	xor a ; SYM_SPACE
.draw_cursor
	ld b, 19 ; x coordinate
	ld c, e
	dec c
	dec c
	call WriteByteToBGMap0
	pop bc
	ret

Text_9a30:
	db "<SPACE>"
	db "<SPACE>"
	db "<SPACE>"
Text_9a36:
	db "<SPACE>"
	db "<SPACE>"
	db "<SPACE>"
	db "<SPACE>"
	db "<SPACE>"
	db "<SPACE>"
	db "<SPACE>"
	db "<SPACE>"
	db "<SPACE>"
	db "<SPACE>"
	db "<SPACE>"
	db "<SPACE>"
	db "<SPACE>"
	db "<SPACE>"
	db "<SPACE>"
	db "<SPACE>"
	db "<SPACE>"
	done


; writes the card ID in register e to wVisibleListCardIDs,
; given its position in the list in register b.
; preserves all registers
; input:
;	b = list position (starts from bottom)
;	e = card ID
AddCardIDToVisibleList:
	push af
	push bc
	push hl
	ld hl, wVisibleListCardIDs
	ld a, [wNumVisibleCardListEntries]
	sub b
	ld c, a ; wNumVisibleCardListEntries - b
	ld b, $0
	add hl, bc
	ld [hl], e
	pop hl
	pop bc
	pop af
	ret


; copies data from hl to:
;	wCardListCursorXPos
;	wCardListCursorYPos
;	wCardListYSpacing
;	wCardListXSpacing
;	wCardListNumCursorPositions
;	wVisibleCursorTile
;	wInvisibleCursorTile
;	wCardListHandlerFunction
; input:
;	a = starting item (usually 0)
;	hl = parameters to use
InitCardSelectionParams:
	ld [wCardListCursorPos], a
	ldh [hffb3], a
	ld de, wCardListCursorXPos
	ld b, $9
	call CopyNBytesFromHLToDE
	xor a
	ld [wCheckMenuCursorBlinkCounter], a
	ret


; output:
;	a & [hffb3] = list index for the currently selected card:  if the A button was pressed
;	            = -1:  if the B button was pressed
;	carry = set:  if either the A or the B button were pressed
HandleCardSelectionInput:
	xor a ; FALSE
	ld [wMenuInputSFX], a
	ldh a, [hDPadHeld]
	or a
	jr z, .handle_ab_btns

; handle d-pad
	ld b, a
	ld a, [wCardListNumCursorPositions]
	ld c, a
	ld a, [wCardListCursorPos]
	bit B_PAD_LEFT, b
	jr z, .check_d_right
	dec a
	bit 7, a
	jr z, .got_cursor_pos
	; if underflow, set to max cursor position
	ld a, [wCardListNumCursorPositions]
	dec a
	jr .got_cursor_pos
.check_d_right
	bit B_PAD_RIGHT, b
	jr z, .handle_ab_btns
	inc a
	cp c
	jr c, .got_cursor_pos
	; if over the max position, set to position 0
	xor a
.got_cursor_pos
	push af
	ld a, SFX_CURSOR
	ld [wMenuInputSFX], a
	call DrawHorizontalListCursor_Invisible
	pop af
	ld [wCardListCursorPos], a
	xor a
	ld [wCheckMenuCursorBlinkCounter], a

.handle_ab_btns
	ld a, [wCardListCursorPos]
	ldh [hffb3], a
	ldh a, [hKeysPressed]
	and PAD_A | PAD_B
	jr z, HandleCardSelectionCursorBlink
	and PAD_A
	jr nz, ConfirmSelectionAndReturnCarry
	; B button was pressed
	ld a, -1
	ldh [hffb3], a
	call PlaySFXConfirmOrCancel_Bank2
	scf
	ret

; output:
;	a = selection
;	e = cursor position
;	carry = set
ConfirmSelectionAndReturnCarry:
	call DrawHorizontalListCursor_Visible
	ld a, [wCardListCursorPos]
	ld e, a
	ldh a, [hffb3]
	call PlaySFXConfirmOrCancel_Bank2
	scf
	ret


HandleCardSelectionCursorBlink:
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
	jr z, DrawHorizontalListCursor
;	fallthrough

DrawHorizontalListCursor_Invisible:
	ld a, [wInvisibleCursorTile]
;	fallthrough

; like DrawListCursor but only for lists with one line,
; and each entry being laid horizontally
; input:
;	a = which tile to draw
DrawHorizontalListCursor:
	ld e, a
	ld a, [wCardListXSpacing]
	ld l, a
	ld a, [wCardListCursorPos]
	ld h, a
	call HtimesL
	ld a, l
	ld hl, wCardListCursorXPos
	add [hl]
	ld b, a ; x coordinate
	ld hl, wCardListCursorYPos
	ld a, [hl]
	ld c, a ; y coordinate
	ld a, e
	call WriteByteToBGMap0
	or a
	ret

DrawHorizontalListCursor_Visible:
	ld a, [wVisibleCursorTile]
	jr DrawHorizontalListCursor


; handles user input when selecting cards to add to a deck configuration
; output:
;	a & [hffb3] = list index of selection (-1 if operation was cancelled)
;	carry = set:  if a selection was made (either selected card or cancelled)
HandleDeckCardSelectionList:
	ld hl, wMenuInputSFX
	ld [hl], $00 ; FALSE

	ldh a, [hDPadHeld]
	or a
	jp z, .check_handler_function

	ld b, a
	ld a, [wCardListNumCursorPositions]
	ld c, a
	ld a, [wCardListCursorPos]
; check d up
	bit B_PAD_UP, b
	jr z, .check_d_down
	ld [hl], SFX_CURSOR ; update wMenuInputSFX
	dec a
	bit 7, a
	jr z, .update_cursor
	ld a, [wCardListVisibleOffset]
	or a
	jr z, .cannot_scroll_up
	dec a
	ld [wCardListVisibleOffset], a
	ld hl, wCardListUpdateFunction
	call CallIndirect
	xor a
	jr .update_cursor
.cannot_scroll_up
	xor a
	ld [hl], a ; reset wMenuInputSFX
	jr .update_cursor

.check_d_down
	bit B_PAD_DOWN, b
	jr z, .handle_d_left_and_d_right
	ld [hl], SFX_CURSOR ; update wMenuInputSFX
	inc a
	cp c
	jr c, .update_cursor
	push af
	ld a, [wUnableToScrollDown]
	or a
	jr z, .able_to_scroll_down
	ld [hl], $00 ; reset wMenuInputSFX
	jr .undo_cursor_change
.able_to_scroll_down
	ld hl, wCardListVisibleOffset
	inc [hl]
	ld hl, wCardListUpdateFunction
	call CallIndirect
.undo_cursor_change
	pop af
	dec a

.update_cursor
	push af
	call DrawListCursor_Invisible
	pop af
	ld [wCardListCursorPos], a
	xor a
	ld [wCheckMenuCursorBlinkCounter], a
	jr .check_handler_function

.handle_d_left_and_d_right
	ld a, [wced2]
	or a
	jr z, .check_handler_function
	; also handle left and right d-pad when building a deck
	bit B_PAD_LEFT, b
	jr z, .check_d_right
	call GetSelectedVisibleCardID
	call RemoveCardFromDeckAndUpdateCount
	jr .check_handler_function
.check_d_right
	bit B_PAD_RIGHT, b
	jr z, .check_handler_function
	call GetSelectedVisibleCardID
	call AddCardToDeckAndUpdateCount

.check_handler_function
	ld a, [wCardListCursorPos]
	ldh [hffb3], a
	ld hl, wCardListHandlerFunction
	ld a, [hli]
	ld h, [hl]
	ld l, a
	or h
	jr z, .handle_ab_btns

	; this code seemingly never runs
	; because wCardListHandlerFunction is always NULL
	ldh a, [hffb3]
	call CallHL
	jr nc, .handle_blink

.select_card
	call DrawListCursor_Visible
	ld a, [wCardListCursorPos]
	ld e, a
	ldh a, [hffb3]
	call PlaySFXConfirmOrCancel_Bank2
	scf
	ret

.handle_ab_btns
	ldh a, [hKeysPressed]
	and PAD_A | PAD_B
	jr z, .check_sfx
	and PAD_A
	jr nz, .select_card
	ld a, -1
	ldh [hffb3], a
	call PlaySFXConfirmOrCancel_Bank2
	scf
	ret

.check_sfx
	ld a, [wMenuInputSFX]
	or a
	call nz, PlaySFX
.handle_blink
	ld hl, wCheckMenuCursorBlinkCounter
	ld a, [hl]
	inc [hl]
	and $0f
	ret nz
	ld a, [wVisibleCursorTile]
	bit 4, [hl]
	jr z, DrawListCursor
;	fallthrough

DrawListCursor_Invisible:
	ld a, [wInvisibleCursorTile]
;	fallthrough

; draws cursor considering wCardListCursorPos spaces each entry
; horizontally by wCardListXSpacing and vertically by wCardListYSpacing
; input:
;	a = tile to write
DrawListCursor:
	ld e, a
	ld a, [wCardListXSpacing]
	ld l, a
	ld a, [wCardListCursorPos]
	ld h, a
	call HtimesL
	ld a, l
	ld hl, wCardListCursorXPos
	add [hl]
	ld b, a ; x coordinate
	ld a, [wCardListYSpacing]
	ld l, a
	ld a, [wCardListCursorPos]
	ld h, a
	call HtimesL
	ld a, l
	ld hl, wCardListCursorYPos
	add [hl]
	ld c, a ; y coordinate
	ld a, e
	call WriteByteToBGMap0
	or a
	ret

DrawListCursor_Visible:
	ld a, [wVisibleCursorTile]
	jr DrawListCursor


; input:
;	de = starting address for the card list that should be used (e.g. wFilteredCardList)
OpenCardPageFromCardList:
; set list from de as the current card list
	ld hl, wCurCardListPtr
	ld [hl], e
	inc hl
	ld [hl], d
; get the card index that is selected and open its card page
	ld h, d
	ld l, e
.start
	ld b, $00
	ld a, [wCardListCursorPos]
	ld c, a
	add hl, bc
	ld a, [wCardListVisibleOffset]
	ld c, a
	add hl, bc
	ld e, [hl]
	ld d, $0
	push de
	call LoadCardDataToBuffer1_FromCardID
	lb de, $38, $9f
	call SetupText
	bank1call OpenCardPage_FromCheckHandOrDiscardPile
	pop de

.handle_input
	ldh a, [hDPadHeld]
	ld b, a
	and PAD_A | PAD_B | PAD_SELECT | PAD_START
	jr nz, .exit

; check d-pad and if UP or DOWN is pressed, then change the card
; that's shown, given the order in the current card list
	xor a ; FALSE
	ld [wMenuInputSFX], a
	ld a, [wCardListNumCursorPositions]
	ld c, a
	ld a, [wCardListCursorPos]
	bit B_PAD_UP, b
	jr z, .check_d_down
	ld hl, wMenuInputSFX
	ld [hl], SFX_CURSOR
	dec a
	bit 7, a
	jr z, .reopen_card_page
	ld a, [wCardListVisibleOffset]
	or a
	jr z, .handle_regular_card_page_input
	dec a
	ld [wCardListVisibleOffset], a
	xor a
	jr .reopen_card_page

.check_d_down
	bit B_PAD_DOWN, b
	jr z, .handle_regular_card_page_input
	ld hl, wMenuInputSFX
	ld [hl], SFX_CURSOR
	inc a
	cp c
	jr c, .reopen_card_page
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
	jr z, .skip_change_card
	ld a, [wCardListVisibleOffset]
	inc a
	ld [wCardListVisibleOffset], a
	pop af
	dec a
.reopen_card_page
	ld [wCardListCursorPos], a
	ld a, [wMenuInputSFX]
	or a
	call nz, PlaySFX
	ld hl, wCurCardListPtr
	ld a, [hli]
	ld h, [hl]
	ld l, a
	jp .start

.skip_change_card
	pop af
.handle_regular_card_page_input
	push de
	bank1call OpenCardPage.input_loop
	pop de
	jr .handle_input

.exit
	ld a, $1
	ld [wVBlankOAMCopyToggle], a
	ld a, [wCardListCursorPos]
	ld [wTempCardListCursorPos], a
	ret


; tries to add the card with ID in register e to wCurDeckCards
; fails to add the card if one of the following conditions are met:
;	- total cards are equal to wMaxNumCardsAllowed
;	- cards with the same name as it reached the allowed limit
;	- player doesn't own more copies in the collection
; otherwise, writes card ID to the first empty slot in wCurDeckCards
; preserves e
; input:
;	e = card ID
; output:
;	carry = set:  if the card was not added to the deck
TryAddCardToDeck:
	ld a, [wMaxNumCardsAllowed]
	ld d, a
	ld a, [wTotalCardCount]
	cp d
	scf
	ret z ; return carry if wMaxNumCardsAllowed == wTotalCardCount

	call .CheckIfCanAddCardWithSameName
	ret c ; cannot add more cards with this name

	call GetCountOfCardInCurDeck
	ld d, a
	ld hl, wOwnedCardsCountList
	ld b, $00
	ld a, [wCardListVisibleOffset]
	ld c, a
	add hl, bc
	ld a, [wCardListCursorPos]
	ld c, a
	add hl, bc
	ld a, [hl]
	cp d
	scf
	ret z ; return carry if there are no more copies of this card in the player's collection

	ld a, SFX_CURSOR
	call PlaySFX
	ld hl, wCurDeckCards
	dec hl
.loop
	inc hl
	ld a, [hl]
	or a
	jr nz, .loop
	; found an empty slot
	ld [hl], e ; store card ID
	inc hl
	xor a
	ld [hl], a ; store new terminating byte

	ld a, [wCurCardTypeFilter]
	ld c, a
	ld b, $0
	ld hl, wCardFilterCounts
	add hl, bc
	inc [hl]
	or a
	ret


; preserves e
; input:
;	e = card ID
; output:
;	carry = set:  if the card with ID from input could not be added to the current deck
;	              because the max number of cards with that name have already been added
.CheckIfCanAddCardWithSameName
	call LoadCardDataToBuffer1_FromCardID
	ld a, [wLoadedCard1Type]
	cp TYPE_ENERGY_DOUBLE_COLORLESS
	jr z, .check_for_other_copies ; Double Colorless Energy is limited
	and TYPE_ENERGY
	ret nz ; return if it's any other Energy card (Basic Energy aren't limited)

; compare this card's name to the names of cards in list wCurDeckCards
.check_for_other_copies
	ld a, [wLoadedCard1Name + 0]
	ld c, a
	ld a, [wLoadedCard1Name + 1]
	ld b, a
	ld hl, wCurDeckCards
	ld d, 0
	push de
.loop_cards
	ld a, [hli]
	or a
	jr z, .exit_pop_de ; return no carry if there are no more cards to check
	ld e, a
	ld d, $0
	call GetCardName
	ld a, e
	cp c
	jr nz, .loop_cards
	ld a, d
	cp b
	jr nz, .loop_cards
	; has same name
	pop de
	inc d ; increment counter of cards with this name
	ld a, [wSameNameCardsLimit]
	cp d
	push de
	jr nz, .loop_cards
	; reached the maximum number of allowed cards with that name
	scf
.exit_pop_de
	pop de
	ret


; gets the element in wVisibleListCardIDs
; corresponding to the index in wCardListCursorPos
; preserves bc
; output:
;	e = card ID
GetSelectedVisibleCardID:
	ld hl, wVisibleListCardIDs
	ld a, [wCardListCursorPos]
	ld e, a
	ld d, $00
	add hl, de
	ld e, [hl]
	ret


; adds the card in register e to the deck configuration
; and updates the values shown for its count in the card selection list
; input:
;	e = card ID
AddCardToDeckAndUpdateCount:
	call TryAddCardToDeck
	ret c ; failed to add the card
	push de
	call PrintCardTypeCounts
	lb de, 15, 0
	call PrintTotalCardCount
	pop de
	call GetCountOfCardInCurDeck
;	fallthrough

; appends the digits of the value in register a to wDefaultText
; then prints it in the cursor's Y position
; input:
;	a = value to convert to numerical digits
PrintNumberValueInCursorYPos:
	ld hl, wDefaultText
	call ConvertToNumericalDigits
	ld [hl], TX_END
	ld a, [wCardListYSpacing]
	ld l, a
	ld a, [wCardListCursorPos]
	ld h, a
	call HtimesL
	ld a, l
	ld hl, wCardListCursorYPos
	add [hl]
	ld e, a
	ld d, 14
	ld hl, wDefaultText
	jp InitTextPrinting_ProcessText

; removes the card in register e from the deck configuration
; and updates the values shown for its count in the card selection list
; input:
;	e = card ID
RemoveCardFromDeckAndUpdateCount:
	call RemoveCardFromCurDeckCards
	ret nc
	push de
	call PrintCardTypeCounts
	lb de, 15, 0
	call PrintTotalCardCount
	pop de
	call GetCountOfCardInCurDeck
	jr PrintNumberValueInCursorYPos


; removes the selected card from wCurDeckCards
; preserves e
; input:
;	e = ID of the card to remove from the deck
;	carry = set:  if the card was removed from the deck
RemoveCardFromCurDeckCards:
	call GetCountOfCardInCurDeck
	or a
	ret z ; card is not in the deck
	ld a, SFX_CURSOR
	call PlaySFX

; remove the first card matching the ID in e and shifts all elements up by one
	ld hl, wCurDeckCards
.loop_1
	ld a, [hli]
	cp e
	jr nz, .loop_1
	ld c, l
	ld b, h
	dec bc
.loop_2
	ld a, [hli]
	ld [bc], a
	inc bc
	or a
	jr nz, .loop_2

	ld a, [wCurCardTypeFilter]
	ld c, a
	ld b, $0
	ld hl, wCardFilterCounts
	add hl, bc
	dec [hl]
	scf
	ret


UpdateConfirmationCardScreen:
	ld hl, hffb0
	ld [hl], $01
	call PrintCurDeckNumberAndName
	ld hl, hffb0
	ld [hl], $00
	jp PrintConfirmationCardList


; input:
;	de = pointer for sDeckXCards, where X is [wCurDeck] + 1
;	hl = pointer for sDeckXName, where X is [wCurDeck] + 1
OpenDeckConfirmationMenu:
; copy deck name
	push de
	ld de, wCurDeckName
	call CopyListFromHLToDEInSRAM
	pop de

; copy deck cards
	ld hl, wCurDeckCards
	call CopyDeckFromSRAM

	ld a, NUM_FILTERS ; number of bytes that will be cleared
	ld hl, wCardFilterCounts
	call ClearMemory_Bank2
	ld a, DECK_SIZE
	ld [wTotalCardCount], a
	ld hl, wCardFilterCounts
	ld [hl], a
;	fallthrough

HandleDeckConfirmationMenu:
; if deck is empty, just show deck info header with empty card list
	ld a, [wTotalCardCount]
	or a
	jp z, ShowDeckInfoHeaderAndWaitForBButton

; create a list of all unique cards
	call SortCurDeckCardsByID
	call CreateCurDeckUniqueCardList

	xor a
	ld [wCardListVisibleOffset], a
.start_selection
	ld hl, .CardSelectionParams
	call InitCardSelectionParams
	ld a, [wNumUniqueCards]
	ld [wNumCardListEntries], a
	cp NUM_DECK_CONFIRMATION_VISIBLE_CARDS
	jr c, .no_cap
	ld a, NUM_DECK_CONFIRMATION_VISIBLE_CARDS
.no_cap
	ld [wCardListNumCursorPositions], a
	ld [wNumVisibleCardListEntries], a
	call ShowConfirmationCardScreen

; set the card update function
	ld hl, wCardListUpdateFunction
	ld a, LOW(UpdateConfirmationCardScreen)
	ld [hli], a
	ld [hl], HIGH(UpdateConfirmationCardScreen)

	xor a
	ld [wced2], a
.loop_input
	call DoFrame
	call HandleDeckCardSelectionList
	jr c, .selection_made
	call HandleLeftRightInCardList
	jr c, .loop_input
	ldh a, [hDPadHeld]
	and PAD_START
	jr z, .loop_input

.open_card_page
	ld a, SFX_CONFIRM
	call PlaySFX
	ld a, [wCardListCursorPos]
	ld [wced7], a
	ld de, wUniqueDeckCardList
	call OpenCardPageFromCardList
	jr .start_selection

.selection_made
	cp -1
	ret z ; exit if the B button was pressed
	jr .open_card_page

.CardSelectionParams
	db 0 ; x position
	db 5 ; y position
	db 2 ; y spacing
	db 0 ; x spacing
	db 7 ; number of entries
	db SYM_CURSOR_R ; visible cursor tile
	db SYM_SPACE ; invisible cursor tile
	dw NULL ; wCardListHandlerFunction


; handles pressing left/right in card lists, which
; scrolls up/down a number of wCardListNumCursorPositions entries.
; preserves hl
; output:
;	carry = set:  if scrolling occurred
HandleLeftRightInCardList:
	ld a, [wCardListNumCursorPositions]
	ld d, a
	ld a, [wCardListVisibleOffset]
	ld c, a
	ldh a, [hDPadHeld]
	cp PAD_RIGHT
	jr z, .right
	cp PAD_LEFT
	jr z, .left
	or a
	ret

.right
	ld a, c
	add d
	ld b, a ; wCardListVisibleOffset + wCardListNumCursorPositions
	add d
	ld hl, wNumCardListEntries
	cp [hl]
	jr c, .got_new_pos
	ld a, [wNumCardListEntries]
	sub d
	ld b, a ; wNumCardListEntries - wCardListNumCursorPositions
	jr .got_new_pos

.left
	ld a, c
	sub d
	ld b, a ; wCardListVisibleOffset - wCardListNumCursorPositions
	jr nc, .got_new_pos
	ld b, 0 ; go to first position
.got_new_pos
	ld a, b
	ld [wCardListVisibleOffset], a
	cp c
	jr z, .set_carry
	ld a, SFX_CURSOR
	call PlaySFX
	ld hl, wCardListUpdateFunction
	call CallIndirect
.set_carry
	scf
	ret


; handles scrolling up and down with the SELECT button.
; in this case, the cursor position goes up/down
; by wCardListNumCursorPositions entries respectively.
; output:
;	carry = set:  if scrolling occurred
HandleSelectUpAndDownInList:
	ld a, [wCardListNumCursorPositions]
	ld d, a
	ld a, [wCardListVisibleOffset]
	ld c, a
	ldh a, [hDPadHeld]
	cp PAD_SELECT | PAD_DOWN
	jr z, HandleLeftRightInCardList.right
	cp PAD_SELECT | PAD_UP
	jr z, HandleLeftRightInCardList.left
	or a
	ret


; simply draws the deck info header
; then awaits a B button press to exit
ShowDeckInfoHeaderAndWaitForBButton:
	call ShowDeckInfoHeader
.wait_input
	call DoFrame
	ldh a, [hKeysPressed]
	and PAD_B
	jr z, .wait_input
	ld a, -1
	jp PlaySFXConfirmOrCancel_Bank2


; draws a box at the top of the screen with wCurDeck's name and card count
; also draws a deck/deck box icon beside the name
ShowDeckInfoHeader:
	call EmptyScreenAndLoadFontDuelAndDeckIcons
	lb de, 0, 0
	lb bc, 20, 4
	call DrawRegularTextBox
; print card count
	lb de, 14, 1
	call PrintTotalCardCount
	ld b, 16
	ld c, e
	call PrintSlashSixty
;	call TallyCardsInCardFilterLists ; replaces 0/60 with No cards chosen.
	call EnableLCD
; draw an icon before the deck name
	lb de, 1, 1
	ld a, [wCurDeck]
	ld b, a
	call EnableSRAM
	ld a, [sCurrentlySelectedDeck]
	call DisableSRAM
	cp b
	jr nz, .deck_icon ; this isn't the player's active deck
	call DrawDeckBoxTileAtDE
	jr PrintCurDeckNumberAndName
.deck_icon
	ld a, [wTotalCardCount]
	or a
	call nz, DrawDeckIcon ; draw the default deck icon if the deck isn't empty
;	fallthrough

; prints the name of the deck after drawing a deck/deck box icon
; prints "New Deck" if the deck hasn't been named yet
; no longer prints a number before the deck name
PrintCurDeckNumberAndName:
	ld a, [wCurDeck]
	inc a ; cp -1
	jr z, .blank_deck_name
	; print the deck number in the menu in the form "#."
;	ld hl, wDefaultText
;	call ConvertToNumericalDigits
;	ldfw [hl], "." ; period punctuation mark
;	inc hl
;	ld [hl], TX_END
;	lb de, 3, 2
;	ld hl, wDefaultText
;	call InitTextPrinting_ProcessText

	ld a, [wCurDeckName]
	or a
	jr z, .new_deck
	ld hl, wCurDeckName
	ld de, wDefaultText
	call CopyListFromHLToDE

; print "<deck name> deck"
	ld hl, wDefaultText
	call GetTextLengthInTiles
	ld b, $0
	ld hl, wDefaultText
	add hl, bc
	ld d, h
	ld e, l
	ld hl, DeckNameSuffix
	call CopyListFromHLToDE
;	lb de, 6, 2 ; coordinates if printing after a number
	lb de, 3, 2 ; coordinates without a deck number
	ld hl, wDefaultText
	jp InitTextPrinting_ProcessText

.new_deck
;	lb de, 6, 2 ; coordinates if printing after a number
	lb de, 3, 2 ; coordinates without a deck number
	ldtx hl, NewDeckText
	jp InitTextPrinting_ProcessTextFromID

.blank_deck_name
	ld hl, wCurDeckName
	ld de, wDefaultText
	call CopyListFromHLToDE
	lb de, 3, 2
	ld hl, wDefaultText
	jp InitTextPrinting_ProcessText


; sorts wCurDeckCards by ID
SortCurDeckCardsByID:
; wOpponentDeck is used to temporarily store deck's cards
; so that it can be later sorted by ID
	ld hl, wCurDeckCards
	ld de, wOpponentDeck
	ld bc, wDuelTempList
	ld a, -1
.loop_copy
	inc a ; increment deck index
	push af
	ld a, [hli]
	ld [de], a
	inc de
	or a
	jr z, .sort_cards
	pop af
	ld [bc], a ; store deck index
	inc bc
	jr .loop_copy

.sort_cards
	pop af
	ld a, $ff ; terminator byte for wDuelTempList
	ld [bc], a

; force Opp Turn so that SortCardsInDuelTempListByID can be used
	ldh a, [hWhoseTurn]
	push af
	ld a, OPPONENT_TURN
	ldh [hWhoseTurn], a
	call SortCardsInDuelTempListByID
	pop af
	ldh [hWhoseTurn], a

; given the ordered cards in wOpponentDeck, with each entry corresponding to
; its deck index (first ordered card is deck index 0, second is deck index 1, etc.),
; copy these entries in this order in wCurDeckCards
	ld hl, wCurDeckCards
	ld de, wDuelTempList
.loop_order_by_deck_index
	ld a, [de]
	cp $ff
	jr z, .done
	ld c, a
	ld b, $0
	push hl
	ld hl, wOpponentDeck
	add hl, bc
	ld a, [hl]
	pop hl
	ld [hli], a
	inc de
	jr .loop_order_by_deck_index

.done
	xor a ; terminator byte for wCurDeckCards
	ld [hl], a
	ret


; goes through the list in wCurDeckCards, and for each card in it,
; create a list in wUniqueDeckCardList of all unique cards that are found
; (assuming wCurDeckCards is sorted by ID)
; also counts the total number of the different cards
CreateCurDeckUniqueCardList:
	lb bc, 0, $0
	ld hl, wCurDeckCards
	ld de, wUniqueDeckCardList
.loop
	ld a, [hli]
	cp c
	jr z, .loop
	ld c, a
	ld [de], a
	inc de
	or a
	jr z, .done
	inc b
	jr .loop
.done
	ld a, b
	ld [wNumUniqueCards], a
	ret


ShowConfirmationCardScreen:
	call ShowDeckInfoHeader
	ld hl, wCardListCoords
	ld [hl], 5 ; initial y coordinate
	inc hl
	ld [hl], 3 ; initial x coordinate
;	fallthrough

; prints the list of cards visible in the window of the confirmation screen
; card info is presented with name, level and its count preceded by "x"
; preserves bc
PrintConfirmationCardList:
	push bc
	ld hl, wCardListCoords
	ld e, [hl]
	inc hl
	ld d, [hl]
	ld b, 19 ; x coordinate
	ld c, e
	dec c
	ld a, [wCardListVisibleOffset]
	or a
	jr z, .got_cursor_tile ; use SYM_SPACE (blank tile) if can't scroll up
	ld a, SYM_CURSOR_U
.got_cursor_tile
	call WriteByteToBGMap0

; iterates by decreasing value in wNumVisibleCardListEntries
; by 1 until it reaches 0
	ld a, [wCardListVisibleOffset]
	ld c, a
	ld b, $0
	ld hl, wOwnedCardsCountList
	add hl, bc
	ld a, [wNumVisibleCardListEntries]
.loop_cards
	or a
	jp z, PrintDeckBuildingCardList.exit_loop
	ld b, a
	ld a, [hli]
	or a
	jp z, PrintDeckBuildingCardList.cannot_scroll
	push bc
	push hl
	push de
	ld e, a
	call AddCardIDToVisibleList
	call LoadCardDataToBuffer1_FromCardID
	; places in wDefaultText the card's name and level
	; then appends at the end "x" with the count of that card
	; draws the card's type icon as well
	ld a, 13
	call CopyCardNameAndLevel
	dec hl
.loop_search
	inc hl
	ld a, [hl]
	or a ; cp TX_END
	jr nz, .loop_search
	call GetCountOfCardInCurDeck
	ld [hl], TX_SYMBOL
	inc hl
	ld [hl], SYM_CROSS
	inc hl
	call ConvertToNumericalDigits
	ld [hl], TX_END
	pop de
	call DrawCardSymbol
	ld hl, wDefaultText
	call InitTextPrinting_ProcessText
	pop hl
	pop bc
	ld a, b
	dec a
	inc e
	inc e
	jr .loop_cards


; handles the screen showing all the player's cards.
; this function is similar to HandleDeckBuildScreen.
HandlePlayersCardsScreen:
	call WriteCardListsTerminatorBytes
	call PrintPlayersCardsHeaderInfo
	xor a
	ld [wCardListVisibleOffset], a
	ld [wCurCardTypeFilter], a
	call PrintFilteredCardSelectionList
	call EnableLCD
	xor a
	ld hl, FiltersCardSelectionParams
	call InitCardSelectionParams
.wait_input
	call DoFrame
	ld a, [wCurCardTypeFilter]
	ld b, a
	ld a, [wTempCardTypeFilter]
	cp b
	jr z, .check_d_down
	; need to refresh the filtered card list
	ld [wCurCardTypeFilter], a
	ld hl, wCardListVisibleOffset
	ld [hl], $00
	call PrintFilteredCardSelectionList

	ld hl, hffb0
	ld [hl], $01
	call PrintPlayersCardsText
	ld hl, hffb0
	ld [hl], $00

	ld a, NUM_FILTERS
	ld [wCardListNumCursorPositions], a
.check_d_down
	ldh a, [hDPadHeld]
	and PAD_DOWN
	jr z, .no_d_down
	; pressing down starts selection from the current filter's card list
	call ConfirmSelectionAndReturnCarry
	jr .jump_to_list

.no_d_down
	call HandleCardSelectionInput
	jr nc, .wait_input
	cp -1
	ret z ; exit if the B button was pressed

; input was made to jump to the card list
.jump_to_list
	ld a, [wNumEntriesInCurFilter]
	or a
	jr z, .wait_input

	xor a
	ld hl, CardsScreenSelectionParams
	call InitCardSelectionParams
	ld a, [wNumEntriesInCurFilter]
	ld [wNumCardListEntries], a
	ld hl, wNumVisibleCardListEntries
	cp [hl]
	jr nc, .enough_entries
	; total number of entries is less than the number of visible entries,
	; so set the number of cursor positions to the list size.
	ld [wCardListNumCursorPositions], a
.enough_entries
	ld hl, wCardListUpdateFunction
	ld a, LOW(PrintCardSelectionList)
	ld [hli], a
	ld [hl], HIGH(PrintCardSelectionList)
	xor a
	ld [wced2], a

.loop_input
	call DoFrame
	call HandleSelectUpAndDownInList
	jr c, .loop_input
	call HandleDeckCardSelectionList
	jr c, .selection_made
	ldh a, [hDPadHeld]
	and PAD_START
	jr z, .loop_input
	; START button was pressed

.open_card_page
	ld a, SFX_CONFIRM
	call PlaySFX
	ld a, [wCardListNumCursorPositions]
	ld [wTempCardListNumCursorPositions], a
	ld a, [wCardListCursorPos]
	ld [wTempCardListCursorPos], a
	ld de, wFilteredCardList
	call OpenCardPageFromCardList
.return_to_card_list
	call PrintPlayersCardsHeaderInfo
.skip_header
	ld hl, FiltersCardSelectionParams
	call InitCardSelectionParams
	ld a, [wCurCardTypeFilter]
	ld [wTempCardTypeFilter], a
	call DrawHorizontalListCursor_Visible
	call PrintCardSelectionList
	call EnableLCD
	ld hl, CardsScreenSelectionParams
	call InitCardSelectionParams
	ld a, [wTempCardListNumCursorPositions]
	ld [wCardListNumCursorPositions], a
	ld a, [wTempCardListCursorPos]
	ld [wCardListCursorPos], a
	jr .loop_input

.selection_made
	call DrawListCursor_Invisible
	ld a, [wCardListNumCursorPositions]
	ld [wTempCardListNumCursorPositions], a
	ld a, [wCardListCursorPos]
	ld [wTempCardListCursorPos], a
	ldh a, [hffb3]
	cp -1
	jr z, .pressed_b
	; pressed A
	ld hl, wHandlePlayersCardsScreenPointer
	ld a, [hli]
	ld h, [hl]
	ld l, a
	or h
	jr z, .open_card_page ; if pointer is null, pressing A will open card page
	jp hl

.pressed_b
	ld hl, FiltersCardSelectionParams
	call InitCardSelectionParams
	ld a, [wCurCardTypeFilter]
	ld [wTempCardTypeFilter], a
	ld hl, hffb0
	ld [hl], $01
	call PrintPlayersCardsText
	ld hl, hffb0
	ld [hl], $00
	jp .wait_input

CardsScreenSelectionParams:
	db 1 ; x position
	db 5 ; y position
	db 2 ; y spacing
	db 0 ; x spacing
	db 7 ; number of entries
	db SYM_CURSOR_R ; visible cursor tile
	db SYM_SPACE ; invisible cursor tile
	dw NULL ; wCardListHandlerFunction


; preserves af
; input:
;	a = index for CardTypeFilters
PrintFilteredCardSelectionList:
	push af
	ld hl, CardTypeFilters
	ld b, $00
	ld c, a
	add hl, bc
	ld a, [hl]
	push af
	ld a, ALL_DECKS
	call CreateCardCollectionListWithDeckCards
	pop af
	call CreateFilteredCardList

	ld a, NUM_DECK_CONFIRMATION_VISIBLE_CARDS
	ld [wNumVisibleCardListEntries], a
	ld hl, wCardListCoords
	ld a, 5 ; y coordinate
	ld [hli], a
	ld [hl], 2 ; x coordinate
	xor a ; SYM_SPACE
	ld [wCursorAlternateTile], a
	call PrintCardSelectionList
	pop af
	ret


; outputs in wTempCardCollection all the cards in sCardCollection
; plus the cards that are being used in built decks
; input:
;	a = DECK_* flags for which decks to include in the collection
CreateCardCollectionListWithDeckCards:
	ldh [hffb5], a
; copies sCardCollection to wTempCardCollection
	ld hl, sCardCollection
	ld de, wTempCardCollection
	ld b, CARD_COLLECTION_SIZE - 1
	call CopyNBytesFromHLToDEInSRAM

; deck_1
	ldh a, [hffb5]
	bit DECK_1_F, a
	jr z, .deck_2
	ld de, sDeck1Cards
	call IncrementDeckCardsInTempCollection
.deck_2
	ldh a, [hffb5]
	bit DECK_2_F, a
	jr z, .deck_3
	ld de, sDeck2Cards
	call IncrementDeckCardsInTempCollection
.deck_3
	ldh a, [hffb5]
	bit DECK_3_F, a
	jr z, .deck_4
	ld de, sDeck3Cards
	call IncrementDeckCardsInTempCollection
.deck_4
	ldh a, [hffb5]
	bit DECK_4_F, a
	ret z
	ld de, sDeck4Cards
;	fallthrough

; goes through the cards of the deck in de and for each card ID,
; increments its corresponding entry in wTempCardCollection
; input:
;	de = sDeck*Cards
IncrementDeckCardsInTempCollection:
	call EnableSRAM
	ld bc, wTempCardCollection
	ld h, DECK_SIZE
.loop
	ld a, [de]
	inc de
	or a
	jr z, .done
	push hl
	ld h, $0
	ld l, a
	add hl, bc
	inc [hl]
	pop hl
	dec h
	jr nz, .loop
.done
	jp DisableSRAM


; prints the name, level and storage count of the cards
; that are visible in the list window in the form: CARD NAME/LEVEL X
; where X is the current count of that card
; preserves bc
PrintCardSelectionList:
	push bc
	call PrintPlayersCardsText
	ld hl, wCardListCoords
	ld e, [hl]
	inc hl
	ld d, [hl]
	ld b, 19 ; x coordinate
	ld c, e
	ld a, [wCardListVisibleOffset]
	or a
	ld a, [wCursorAlternateTile]
	jr z, .got_cursor_tile_1
	ld a, SYM_CURSOR_U
.got_cursor_tile_1
	call WriteByteToBGMap0

; iterates by decreasing value in wNumVisibleCardListEntries
; by 1 until it reaches 0
	ld a, [wCardListVisibleOffset]
	ld c, a
	ld b, $0
	ld hl, wFilteredCardList
	add hl, bc
	ld a, [wNumVisibleCardListEntries]
.loop_filtered_cards
	or a
	jr z, .exit_loop
	ld b, a
	ld a, [hli]
	push hl
	or a
	jr z, .invalid_card ; card ID of 0
	push de
	ld e, a
	call AddCardIDToVisibleList
	call LoadCardDataToBuffer1_FromCardID
	; places in wDefaultText the card's name and level
	; then appends at the end the count of that card in the card storage
	ld a, 14
	call CopyCardNameAndLevel
	call AppendOwnedCardCountNumber
	pop de
	ld hl, wDefaultText
	jr .process_text

.invalid_card
	ld hl, Text_9a36 ; print an empty row (only 17/20 tiles)
.process_text
	call InitTextPrinting_ProcessText
	pop hl
	ld a, b
	dec a
	inc e
	inc e
	jr .loop_filtered_cards

.exit_loop
	ld a, [hl]
	or a
	jr z, .cannot_scroll
	; draw the down cursor to show that there are more cards to view
	xor a ; FALSE
	ld [wUnableToScrollDown], a
	ld a, SYM_CURSOR_D
	jr .got_cursor_tile_2
.cannot_scroll
	inc a ; TRUE
	ld [wUnableToScrollDown], a
	ld a, [wCursorAlternateTile]
.got_cursor_tile_2
	ld b, 19 ; x coordinate
	ld c, e
	dec c
	dec c
	call WriteByteToBGMap0
	pop bc
	ret


; appends the card count (in symbol font)
; for the card in register e to the text in hl.
; preserves all registers
; input:
;	hl = text data
;	e = card ID
AppendOwnedCardCountNumber:
	push af
	push bc
	push de
	push hl
; find the end of the text string ($00 byte)
	dec hl
.loop
	inc hl
	ld a, [hl]
	or a ; cp TX_END
	jr nz, .loop
; add total collection amount to the text string
	call GetOwnedCardCount
	call ConvertToNumericalDigits
	ld [hl], TX_END ; insert byte terminator
	pop hl
	pop de
	pop bc
	pop af
	ret


; prints header info (card count and player name)
PrintPlayersCardsHeaderInfo:
	call Set_OBJ_8x8
	call EmptyScreenAndLoadFontDuelAndDeckIcons
.skip_empty_screen
	lb bc, 0, 4
	ld a, SYM_BOX_TOP
	call FillBGMapLineWithA
	call PrintTotalNumberOfCardsInCollection
	call PrintPlayersCardsText
;	fallthrough

; draws all the card type icons in a line specified by .CardTypeIcons
DrawCardTypeIcons:
	ld hl, .CardTypeIcons
.loop
	ld a, [hli]
	or a
	ret z ; done
	ld d, [hl] ; x coordinate
	inc hl
	ld e, [hl] ; y coordinate
	inc hl
	push hl
	push af
	lb hl, 1, 2
	lb bc, 2, 2
	call FillRectangle
	pop af
	call GetCardTypeIconPalette
	ld b, a
	ld a, [wConsole]
	cp CONSOLE_CGB
	jr nz, .not_cgb
	ld a, b
	lb bc, 2, 2
	lb hl, 0, 0
	call BankswitchVRAM1
	call FillRectangle
	call BankswitchVRAM0
.not_cgb
	pop hl
	jr .loop

.CardTypeIcons
; icon tile, x coordinate, y coordinate
	db ICON_TILE_GRASS,      1, 2
	db ICON_TILE_FIRE,       3, 2
	db ICON_TILE_WATER,      5, 2
	db ICON_TILE_LIGHTNING,  7, 2
	db ICON_TILE_FIGHTING,   9, 2
	db ICON_TILE_PSYCHIC,   11, 2
	db ICON_TILE_COLORLESS, 13, 2
	db ICON_TILE_TRAINER,   15, 2
	db ICON_TILE_ENERGY,    17, 2
	db $00


; preserves all registers except af
; input:
;	a = ICON_TILE_* constant
; output:
;	a = background palette corresponding to the card type icon from input a
;	a = 0:  if the palette wasn't found
GetCardTypeIconPalette:
	push bc
	push hl
	ld b, a
	ld hl, CardSymbolTable - 1
.loop
	inc hl
	ld a, [hli]
	or a
	jr z, .done
	cp b
	jr nz, .loop
	ld a, [hl]
.done
	pop hl
	pop bc
	ret


; prints "<PLAYER>'s cards"
PrintPlayersCardsText:
	lb de, 1, 0
	call InitTextPrinting
	ld de, wDefaultText
	call CopyPlayerName
	ld hl, wDefaultText
	call ProcessText
	ld hl, wDefaultText
	call GetTextLengthInTiles
	inc b
	ld d, b
	ld e, 0
	ldtx hl, SCardsText
	jp InitTextPrinting_ProcessTextFromID


PrintTotalNumberOfCardsInCollection:
	ld a, ALL_DECKS
	call CreateCardCollectionListWithDeckCards

; count all the cards in collection
	ld de, wTempCardCollection + 1
	ld hl, 0
	ld b, NUM_CARDS
.loop_all_cards
	ld a, [de]
	inc de
	and CARD_COUNT_MASK
	push bc
	ld b, $00
	ld c, a
	add hl, bc
	pop bc
	dec b
	jr nz, .loop_all_cards

; hl = total number of cards in collection
	ld de, wTempCardCollection
	call TwoByteNumberToFullwidthTextInDE_TrimLeadingZeros
	lb de, 14, 0
	ld hl, wTempCardCollection
	jp InitTextPrinting_ProcessText


;----------------------------------------
;        UNREFERENCED FUNCTIONS
;----------------------------------------
;
;; draws the icon corresponding to the loaded card's type:
;; Grass/Fire/Water/Lightning/Fighting/Psychic/Colorless Symbol for Energy cards,
;; Stage Symbol for Pokemon cards, and a T Symbol for Trainer cards.
;; draws it 2 tiles to the left and 1 up to the current coordinate in de.
;; this function is more or less identical to "DrawCardSymbol" in home/menus.asm
;; preserves de
;; input:
;;	de = screen coordinates for drawing the symbol
;;	[wLoadedCard1] = all of the card's data (card_data_struct)
;DrawCardTypeIcon
;	push de
;	ld a, [wLoadedCard1Type]
;	cp TYPE_ENERGY
;	jr nc, .not_pkmn_card
;
;; Pokemon card
;	ld a, [wLoadedCard1Stage]
;	add a ; *2
;	add a ; *4 (number of tiles in a type icon)
;	add ICON_TILE_BASIC_POKEMON
;	jr .got_tile
;
;.not_pkmn_card
;	cp TYPE_TRAINER
;	jr nc, .trainer_card
;
;; Energy card
;	sub TYPE_ENERGY
;	add a ; *2
;	add a ; *4 (number of tiles in a type icon)
;	add ICON_TILE_FIRE
;	jr .got_tile
;
;.trainer_card
;	ld a, ICON_TILE_TRAINER
;.got_tile
;	dec d
;	dec d
;	dec e
;	push af
;	lb hl, 1, 2
;	lb bc, 2, 2
;	call FillRectangle
;	pop af
;	call GetCardTypeIconPalette
;	ld b, a
;	ld a, [wConsole]
;	cp CONSOLE_CGB
;	jr nz, .skip_pal
;	ld a, b
;	lb bc, 2, 2
;	lb hl, 0, 0
;	call BankswitchVRAM1
;	call FillRectangle
;	call BankswitchVRAM0
;.skip_pal
;	pop de
;	ret
;
;
;; counts all values stored in wCardFilterCounts
;; if the total count is 0, then prints "No cards chosen."
;; output:
;;	c = sum of all card filter counts
;TallyCardsInCardFilterLists:
;	lb bc, NUM_FILTERS, 0
;	ld hl, wCardFilterCounts
;.loop
;	ld a, [hli]
;	add c
;	ld c, a
;	dec b
;	jr nz, .loop
;	ld a, c
;	or a
;	ret nz
;	lb de, 11, 1
;	ldtx hl, NoCardsChosenText
;	jp InitTextPrinting_ProcessTextFromID
;
;
;; opens card page from the card list
;Func_9ced:
;	ld hl, wVisibleListCardIDs
;	ld a, [wCardListCursorPos]
;	ld c, a
;	ld b, $00
;	add hl, bc
;	ld e, [hl]
;	inc hl
;	ld d, [hl]
;	call LoadCardDataToBuffer1_FromCardID
;	lb de, $38, $9f
;	call SetupText
;	bank1call OpenCardPage_FromHand
;	ld a, $01
;	ld [wVBlankOAMCopyToggle], a
;	ret
