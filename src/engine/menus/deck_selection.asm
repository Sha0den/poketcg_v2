INCLUDE "data/glossary_menu_transitions.asm"


; copies b bytes of SRAM data from hl to de
; input:
;	b = number of bytes to copy
;	hl = address from which to start copying the data
;	de = where to copy the data
CopyNBytesFromHLToDEInSRAM:
	call EnableSRAM
	call CopyNBytesFromHLToDE
	jp DisableSRAM


; copies DECK_SIZE number of cards (60 cards) from de to hl in SRAM
; preserves bc
; input:
;	hl = address from which to start copying the data
;	de = where to copy the data
CopyDeckFromSRAM:
	push bc
	call EnableSRAM
	ld c, DECK_SIZE
	call CopyNBytesFromDEToHL
	xor a ; terminating byte
	ld [hl], a
	pop bc
	jp DisableSRAM


; clears some WRAM addresses to act as terminator bytes
; to wFilteredCardList and wCurDeckCards
; preserves de
WriteCardListsTerminatorBytes:
	xor a ; both lists are null-terminated
	ld hl, wFilteredCardList
	ld bc, DECK_SIZE
	add hl, bc
	ld [hl], a ; add terminating byte to wFilteredCardList
	ld hl, wCurDeckCards
	ld bc, DECK_CONFIG_BUFFER_SIZE
	add hl, bc
	ld [hl], a ; add terminating byte to wCurDeckCards
	ret


; loads the Deck icon to v0Tiles2
LoadDeckIcon:
	ld hl, DuelOtherGraphics + $29 tiles
	ld de, v0Tiles1 + $48 tiles
	ld b, $04
	jp CopyFontsOrDuelGraphicsTiles


; loads the Deck Box icon gfx to v0Tiles2
LoadDeckBoxIcon:
	ld hl, DeckBoxGfx
	ld de, v0Tiles1 + $4c tiles
	ld b, 64 ; 16 pixels * 16 pixels = 256 pixels, 256 pixels / 4 (2 bits per pixel) = 64 bytes
	jp SafeCopyDataHLtoDE

DeckBoxGfx:
	INCBIN "gfx/deck_box.2bpp"


; empties screen, zeroes object positions, loads cursor sprite,
; loads tiles for font symbols, card type symbols, and deck/deck box icons,
; sets default palettes, and designates tiles for text
EmptyScreenAndLoadFontDuelAndDeckIcons:
	xor a ; SYM_SPACE
	ld [wTileMapFill], a
	call EmptyScreen
	call ZeroObjectPositionsAndToggleOAMCopy
	call LoadCursorTile
	call LoadSymbolsFont
	call LoadDeckIcon
	call LoadDeckBoxIcon
	call LoadDuelCardSymbolTiles
	call SetDefaultConsolePalettes
	lb de, $38, $bf
	jp SetupText


; initializes the following deck building parameters from hl:
;	wMaxNumCardsAllowed
;	wSameNameCardsLimit
;	wIncludeCardsInDeck
;	wDeckConfigurationMenuHandlerFunction
;	wDeckConfigurationMenuTransitionTable
; input:
;	hl = parameters to use (e.g. DeckBuildingParams)
InitDeckBuildingParams:
	ld de, wMaxNumCardsAllowed
	ld b, $7
	jp CopyNBytesFromHLToDE


DeckBuildingParams:
	db DECK_CONFIG_BUFFER_SIZE ; max number of cards
	db MAX_NUM_SAME_NAME_CARDS ; max number of same name cards
	db TRUE ; whether to include deck cards
	dw HandleDeckConfigurationMenu
	dw DeckConfigurationMenu_TransitionTable

DeckSelectionMenuParameters:
	db 3, 2 ; cursor x, cursor y
	db 3 ; y displacement between items
	db 4 ; number of items
	db SYM_CURSOR_R ; cursor tile number
	db SYM_SPACE ; tile behind cursor
	dw NULL ; function pointer if non-0

DeckSelectionMenu:
	ld hl, DeckBuildingParams
	call InitDeckBuildingParams
	ld a, ALL_DECKS
	call DrawDecksScreen
	xor a

.start_selection
	ld hl, DeckSelectionMenuParameters
	call InitializeMenuParameters
	ldtx hl, PleaseSelectDeckText
	call DrawWideTextBox_PrintText
.loop_input
	call DoFrame
	jr c, .start_selection ; reinitialize menu parameters
; first check if either the START or the SELECT button was pressed
	ldh a, [hDPadHeld]
	and PAD_SELECT | PAD_START
	jr z, .else
	ld a, [wCurMenuItem]
	ld [wCurDeck], a
	call CheckIfCurDeckIsValid
	jr nc, .valid_deck
	; no deck is saved in the current slot
	call PrintThereIsNoDeckHereText
	jr .start_selection
.valid_deck
	ld a, SFX_CONFIRM
	call PlaySFX
	ldh a, [hDPadHeld]
	and PAD_SELECT
	jp nz, DeckSelectionSubMenu_SelectOrCancel.SelectDeck ; make this the active deck if SELECT was pressed
	; START button must have been pressed, so open the deck list/confirmation screen instead
	call HandleStartButtonInDeckSelectionMenu.skip_sfx
	jr .start_selection
.else
	call HandleMenuInput
	jr nc, .loop_input
	cp -1
	ret z ; exit if the B button was pressed
	; A button was pressed on a deck
	ld [wCurDeck], a
;	fallthrough

; handles the submenu when selecting a deck
; (Modify Deck, Use This Deck, Rename Deck and Dismantle Deck)
DeckSelectionSubMenu:
	call DrawWideTextBox
	ld hl, DeckSelectionData
	call PlaceTextItems
	ld a, 9
	ld [wCheckMenuCursorXPositionOffset], a
	call ResetCheckMenuCursorPositionAndBlink
.loop_input
	call DoFrame
	call HandleCheckMenuInput
	jr nc, .loop_input
	cp -1
	jr nz, .option_selected
	; the B button was pressed, so erase the cursor
	; and go back to the deck selection handling
	call EraseCheckMenuCursor
	ld a, [wCurDeck]
	jr DeckSelectionMenu.start_selection

.option_selected
	ld a, [wCheckMenuCursorXPosition]
	or a
	jp nz, DeckSelectionSubMenu_SelectOrCancel
	ld a, [wCheckMenuCursorYPosition]
	or a
	jr nz, .ChangeName

; Modify Deck
; read deck from SRAM
; TODO
	call GetPointerToDeckCards
	ld e, l
	ld d, h
	ld hl, wCurDeckCards
	call CopyDeckFromSRAM
	ld a, MAX_DECK_NAME_LENGTH ; number of bytes that will be cleared (20)
	ld hl, wCurDeckName
	call ClearMemory_Bank2
	ld de, wCurDeckName
	call GetPointerToDeckName
	call CopyListFromHLToDEInSRAM

	call HandleDeckBuildScreen
	jr nc, .return_to_deck_selection
	; save the current deck configuration
	call EnableSRAM
	ld hl, wCurDeckCards
	call DecrementDeckCardsInCollection
	call GetPointerToDeckCards
	call AddDeckToCollection
	ld e, l
	ld d, h
	ld hl, wCurDeckCards
	ld b, DECK_SIZE
	call CopyNBytesFromHLToDE
	call GetPointerToDeckName
	ld d, h
	ld e, l
	ld hl, wCurDeckName
	call CopyListFromHLToDE
	call GetPointerToDeckName
	ld a, [hl]
	call DisableSRAM
	or a
	jr z, .get_input_deck_name
.return_to_deck_selection
	ld a, ALL_DECKS
	call DrawDecksScreen
	ld a, [wCurDeck]
	jp DeckSelectionMenu.start_selection

.ChangeName
	call CheckIfCurDeckIsValid
	jr nc, .get_input_deck_name
	call PrintThereIsNoDeckHereText
	jp DeckSelectionMenu.start_selection
.get_input_deck_name
	ld a, MAX_DECK_NAME_LENGTH ; number of bytes that will be cleared (20)
	ld hl, wCurDeckName
	call ClearMemory_Bank2
	ld de, wCurDeckName
	call GetPointerToDeckName
	call CopyListFromHLToDEInSRAM
	call InputCurDeckName
	call GetPointerToDeckName
	ld d, h
	ld e, l
	ld hl, wCurDeckName
	call CopyListFromHLToDEInSRAM
	jr .return_to_deck_selection

DeckSelectionData:
	textitem  2, 14, ModifyDeckText
	textitem 11, 14, UseThisDeckText
	textitem  2, 16, RenameDeckText
	textitem 11, 16, DismantleDeckText
	db $ff


; handles the START button being pressed when in the deck selection menu.
; does nothing if the START button wasn't pressed.
; prints "There is no deck here!" if the selected deck is empty.
; output:
;	carry = set:  if button press was handled
HandleStartButtonInDeckSelectionMenu:
	ldh a, [hDPadHeld]
	and PAD_START
	ret z ; skip

; set menu item as current deck
	ld a, [wCurMenuItem]
	ld [wCurDeck], a
	call CheckIfCurDeckIsValid
	jr nc, .valid_deck

; not a valid deck, cancel
	call PrintThereIsNoDeckHereText
	scf
	ret

.valid_deck
	ld a, SFX_CONFIRM
	call PlaySFX
.skip_sfx
	call GetPointerToDeckCards
	push hl
	call GetPointerToDeckName
	pop de
	call OpenDeckConfirmationMenu
	ld a, ALL_DECKS
	call DrawDecksScreen
	ld a, [wCurDeck]
	scf
	ret


; gets current deck's name from user input
InputCurDeckName:
	ld a, [wCurDeck]
	or a
	jr nz, .deck_2
	ld hl, Deck1Data
	jr .got_deck_ptr
.deck_2
	dec a
	jr nz, .deck_3
	ld hl, Deck2Data
	jr .got_deck_ptr
.deck_3
	dec a
	jr nz, .deck_4
	ld hl, Deck3Data
	jr .got_deck_ptr
.deck_4
	ld hl, Deck4Data
	; fallthrough
.got_deck_ptr
	ld a, MAX_DECK_NAME_LENGTH
	lb bc, 4, 1
	ld de, wCurDeckName
	farcall InputDeckName
	ld a, [wCurDeckName]
	or a
	ret nz
	; fallthrough if deck wasn't given a name by the player

; handles the naming of unnamed decks
; inputs as the deck name "DECK XXX"
; where XXX is the current unnamed deck counter
.UnnamedDeck
; read the current unnamed deck number and convert it to text
	ld hl, sUnnamedDeckCounter
	call EnableSRAM
	ld a, [hli]
	ld h, [hl]
	call DisableSRAM
	ld l, a
	ld de, wDefaultText
	call TwoByteNumberToHalfwidthText

	ld hl, wCurDeckName
	ld [hl], TX_HALFWIDTH
	inc hl
	ld [hl], "D"
	inc hl
	ld [hl], "e"
	inc hl
	ld [hl], "c"
	inc hl
	ld [hl], "k"
	inc hl
	ld [hl], " "
	inc hl
	ld de, wDefaultText + 2
	ld a, [de]
	inc de
	ld [hli], a
	ld a, [de]
	inc de
	ld [hli], a
	ld a, [de]
	ld [hli], a
	xor a ; TX_END
	ld [hl], a

; increment the unnamed deck counter
	ld hl, sUnnamedDeckCounter
	call EnableSRAM
	ld e, [hl]
	inc hl
	ld d, [hl]
; capped at 999
	ld a, HIGH(MAX_UNNAMED_DECK_NUM)
	cp d
	jr nz, .incr_counter
	ld a, LOW(MAX_UNNAMED_DECK_NUM)
	cp e
	jr nz, .incr_counter
	; reset counter
	ld de, 0
.incr_counter
	inc de
	ld [hl], d
	dec hl
	ld [hl], e
	jp DisableSRAM


; handles the options on the right side of the deck selection sub-menu.
; the choices are either "Use This Deck" or "Dismantle This Deck",
; depending on the cursor's Y position.
DeckSelectionSubMenu_SelectOrCancel:
	call CheckIfCurDeckIsValid
	jr nc, .check_which_was_selected
	; invalid deck
	call PrintThereIsNoDeckHereText
	jp DeckSelectionMenu.start_selection

.check_which_was_selected
	ld a, [wCheckMenuCursorYPosition]
	or a
	jr nz, .DismantleDeck

.SelectDeck
	call EnableSRAM
	ld a, [sCurrentlySelectedDeck]
	call DisableSRAM

; replace the previously selected deck's deck box icon with a deck icon
	ld h, $3
	ld l, a
	call HtimesL
	ld e, l
	inc e
	ld d, 1
	call DrawDeckIcon
	; draw an empty rectangle
;	xor a ; SYM_SPACE
;	lb hl, 0, 0
;	lb bc, 2, 2
;	call FillRectangle

; set the current deck as the selected deck and draw the deck box icon
	ld a, [wCurDeck]
	call EnableSRAM
	ld [sCurrentlySelectedDeck], a
	call DisableSRAM
	call DrawDeckBoxTileOnCurDeck

; print "<DECK> was chosen as the dueling deck!"
	call GetPointerToDeckName
	call EnableSRAM
	call CopyDeckName
	call DisableSRAM
	; zero wTxRam2 so that the deck name just loaded to wDefaultText is printed
	ld hl, wTxRam2
	xor a
	ld [hli], a
	ld [hl], a
	ldtx hl, ChosenAsDuelingDeckText
.print_message_and_restart_selection
	call DrawWideTextBox_WaitForInput
.restart_selection
	ld a, [wCurDeck]
	jp DeckSelectionMenu.start_selection

.DismantleDeck
	ldtx hl, DismantleThisDeckText
	call YesOrNoMenuWithText
	jr c, .restart_selection ; close sub-menu if "No" was selected
	call CheckIfHasOtherValidDecks
	ldtx hl, ThereIsOnly1DeckSoCannotBeDismantledText
	jr c, .print_message_and_restart_selection
	call EnableSRAM
	call GetPointerToDeckName
	ld a, NAME_BUFFER_LENGTH ; number of bytes that will be cleared (16)
	call ClearMemory_Bank2
	call GetPointerToDeckCards
	call AddDeckToCollection
	ld a, DECK_SIZE ; number of bytes that will be cleared (60)
	call ClearMemory_Bank2
	call DisableSRAM
	jp DeckSelectionSubMenu.return_to_deck_selection


PrintThereIsNoDeckHereText:
	call PlaySFX_InvalidChoice
	ldtx hl, ThereIsNoDeckHereText
	call DrawWideTextBox_WaitForInput
	ld a, [wCurDeck]
	ret


; preserves de
; input:
;	[wCurDeck] = which deck to check (0-3)
; output:
;	carry = set:  if the deck in wCurDeck is not a valid deck
CheckIfCurDeckIsValid:
	ld a, [wCurDeck]
;	fallthrough

; preserves de
; input:
;	a = which deck to check (0-3)
; output:
;	carry = set:  if the given deck is not a valid deck
CheckIfDeckIsValid:
	ld c, a
	ld b, $00
	ld hl, PowersOf2
	add hl, bc
	ld a, [hl]
	ld hl, wValidDecks
	and [hl]
	ret nz ; return no carry if the given deck is valid
	; not valid, so return carry
	scf
	ret


; preserves bc and de
; output:
;	hl = pointer for sDeckXName, where X is [wCurDeck] + 1
GetPointerToDeckName:
	ld a, [wCurDeck]
	ld h, a
	ld l, DECK_STRUCT_SIZE
	call HtimesL
	push de
	ld de, sDeck1Name
	add hl, de
	pop de
	ret


; preserves af, bc, and de
; output:
;	hl = pointer for sDeckXCards, where X is [wCurDeck] + 1
GetPointerToDeckCards:
	push af
	ld a, [wCurDeck]
	ld h, a
	ld l, sDeck2Cards - sDeck1Cards
	call HtimesL
	push de
	ld de, sDeck1Cards
	add hl, de
	pop de
	pop af
	ret


; preserves all registers except af
ResetCheckMenuCursorPositionAndBlink:
	xor a
	ld [wCheckMenuCursorXPosition], a
	ld [wCheckMenuCursorYPosition], a
	ld [wCheckMenuCursorBlinkCounter], a
	ret
