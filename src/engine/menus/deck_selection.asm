INCLUDE "data/glossary_menu_transitions.asm"


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
	xor a
	ld [hl], a
	pop bc
	jp DisableSRAM


; clears some WRAM addresses to act as terminator bytes
; to wFilteredCardList and wCurDeckCards
; preserves de
WriteCardListsTerminatorBytes:
	xor a
	ld hl, wFilteredCardList
	ld bc, DECK_SIZE
	add hl, bc
	ld [hl], a ; terminator byte
	ld hl, wCurDeckCards
	ld bc, DECK_CONFIG_BUFFER_SIZE
	add hl, bc
	ld [hl], a ; terminator byte
	ret


; initializes some SRAM addresses
; preserves bc and de
InitPromotionalCardAndDeckCounterSaveData:
	call EnableSRAM
	xor a
	ld hl, sHasPromotionalCards
	ld [hli], a
	inc a ; $1
	ld [hli], a ; sb704
	ld [hli], a
	ld [hl], a
	ld [sUnnamedDeckCounter], a
	jp DisableSRAM


; loads the Deck icon to v0Tiles2
LoadDeckIcon:
	ld hl, DuelOtherGraphics + $29 tiles
	ld de, v0Tiles1 + $48 tiles
	ld b, $04
	jp CopyFontsOrDuelGraphicsTiles


; loads the Deck Box icon gfx to v0Tiles2
LoadDeckBoxIcon:
	ld hl, DeckBoxGfx
	ld bc, 64
	ld de, v0Tiles1 + $4c tiles
	jp CopyDataHLtoDE

DeckBoxGfx:
	INCBIN "gfx/deck_box.2bpp"


; empties screen, zeroes object positions, loads cursor sprite,
; loads tiles for font symbols, card type symbols, and deck/deck box icons,
; sets default palettes, and designates tiles for text
EmptyScreenAndLoadFontDuelAndDeckIcons:
	xor a
	ld [wTileMapFill], a
	call ZeroObjectPositions
	call EmptyScreen
	ld a, $1
	ld [wVBlankOAMCopyToggle], a
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

.init_menu_params
	ld hl, DeckSelectionMenuParameters
	call InitializeMenuParameters
	ldtx hl, PleaseSelectDeckText
	call DrawWideTextBox_PrintText
.loop_input
	call DoFrame
	jr c, .init_menu_params ; reinitialize menu parameters
	call HandleStartButtonInDeckSelectionMenu
	jr c, .init_menu_params
	call HandleMenuInput
	jr nc, .loop_input
	ldh a, [hCurMenuItem]
	cp $ff
	ret z ; B button was pressed
	; A button was pressed on a deck
	ld [wCurDeck], a
;	fallthrough

; handles the submenu when selecting a deck
; (Modify Deck, Select Deck, Change Name and Cancel)
DeckSelectionSubMenu:
	call DrawWideTextBox
	ld hl, DeckSelectionData
	call PlaceTextItems
	call ResetCheckMenuCursorPositionAndBlink
.loop_input
	call DoFrame
	call HandleCheckMenuInput
	jr nc, .loop_input
	cp $ff
	jr nz, .option_selected
	; the B button was pressed, so erase the cursor
	; and go back to the deck selection handling
	call EraseCheckMenuCursor
	ld a, [wCurDeck]
	jr DeckSelectionMenu.init_menu_params

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
	jr nc, .asm_8ec4
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
.asm_8ec4
	ld a, ALL_DECKS
	call DrawDecksScreen
	ld a, [wCurDeck]
	jp DeckSelectionMenu.init_menu_params

.ChangeName
	call CheckIfCurDeckIsValid
	jr nc, .get_input_deck_name
	call PrintThereIsNoDeckHereText
	jp DeckSelectionMenu.init_menu_params
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
	ld a, ALL_DECKS
	call DrawDecksScreen
	ld a, [wCurDeck]
	jp DeckSelectionMenu.init_menu_params

DeckSelectionData:
	textitem  2, 14, ModifyDeckText
	textitem 12, 14, SelectDeckText
	textitem  2, 16, ChangeNameText
	textitem 12, 16, CancelText
	db $ff


; handles the START button being pressed when in the deck selection menu.
; does nothing if the START button wasn't pressed.
; prints "There is no deck here!" if the selected deck is empty.
; output:
;	carry = set:  if button press was handled
HandleStartButtonInDeckSelectionMenu:
	ldh a, [hDPadHeld]
	and START
	ret z ; skip

; set menu item as current deck
	ld a, [wCurMenuItem]
	ld [wCurDeck], a
	call CheckIfCurDeckIsValid
	jr nc, .valid_deck

; not a valid deck, cancel
	ld a, -1 ; cancel
	call PlaySFXConfirmOrCancel_Bank2
	call PrintThereIsNoDeckHereText
	scf
	ret

.valid_deck
	ld a, $1
	call PlaySFXConfirmOrCancel_Bank2
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
	ld [hl], $6
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
	xor a
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


; handles the deck selection sub-menu
; the choices are either "Select Deck" or "Cancel",
; depending on the cursor's Y position
DeckSelectionSubMenu_SelectOrCancel:
	ld a, [wCheckMenuCursorYPosition]
	or a
	ret nz

; select deck
	call CheckIfCurDeckIsValid
	jr nc, .SelectDeck
	; invalid deck
	call PrintThereIsNoDeckHereText
	jp DeckSelectionMenu.init_menu_params

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
;	xor a
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
	call DrawWideTextBox_WaitForInput
	ld a, [wCurDeck]
	jp DeckSelectionMenu.init_menu_params


PrintThereIsNoDeckHereText:
	ldtx hl, ThereIsNoDeckHereText
	call DrawWideTextBox_WaitForInput
	ld a, [wCurDeck]
	ret


; preserves de
; output:
;	carry = set:  if the deck in wCurDeck is not a valid deck
CheckIfCurDeckIsValid:
	ld a, [wCurDeck]
	ld hl, wDecksValid
	ld b, $0
	ld c, a
	add hl, bc
	ld a, [hl]
	or a
	ret nz ; is valid
	scf
	ret ; is not valid


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
