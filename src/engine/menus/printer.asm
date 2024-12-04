HandlePrinterMenu:
	farcall PreparePrinterConnection
	ret c
	xor a
.loop
	ld hl, PrinterMenuParameters
	call InitializeMenuParameters
	call EmptyScreenAndLoadFontDuelAndDeckIcons
	lb de, 4, 0
	lb bc, 12, 12
	call DrawRegularTextBox
	lb de, 6, 2
	ldtx hl, PrintMenuItemsText
	call InitTextPrinting_ProcessTextFromID
	ldtx hl, WhatWouldYouLikeToPrintText
	call DrawWideTextBox_PrintText
	call EnableLCD
.loop_input
	call DoFrame
	call HandleMenuInput
	jr nc, .loop_input
	cp -1
	call z, PrinterMenu_QuitPrint ; exit if the B button was pressed
	ld [wSelectedPrinterMenuItem], a
	ld hl, PrinterMenuFunctionTable
	call JumpToFunctionInTable
	ld a, [wSelectedPrinterMenuItem]
	jr .loop

PrinterMenuParameters:
	db 5, 2 ; cursor x, cursor y
	db 2 ; y displacement between items
	db 5 ; number of items
	db SYM_CURSOR_R ; cursor tile number
	db SYM_SPACE ; tile behind cursor
	dw NULL ; function pointer if non-0

PrinterMenuFunctionTable:
	dw PrinterMenu_PokemonCards
	dw PrinterMenu_DeckConfiguration
	dw PrinterMenu_CardList
	dw PrinterMenu_PrintQuality
	dw PrinterMenu_QuitPrint


PrinterMenu_PokemonCards:
	ld hl, wHandlePlayersCardsScreenPointer
	ld a, LOW(PrintThisCardMenu)
	ld [hli], a
	ld [hl], HIGH(PrintThisCardMenu)
	jp HandlePlayersCardsScreen


PrintThisCardMenu:
	call DrawListCursor_Visible
	call EraseHeader
	lb de, 1, 1
	ldtx hl, PrintThisCardYesNoText
	call InitTextPrinting_ProcessTextFromID
	ld a, $01 ; default option is "No"
	ld hl, YesNoInHeaderSelectionParams
	call InitCardSelectionParams
.loop_input
	call DoFrame
	call HandleCardSelectionInput
	jr nc, .loop_input
	or a
	jr nz, .quickly_return_to_card_list ; return immediately if "No" was selected
	ld hl, wFilteredCardList
	ld b, $00
	ld a, [wTempCardListCursorPos]
	ld c, a
	add hl, bc
	ld a, [wCardListVisibleOffset]
	ld c, a
	add hl, bc
	ld a, [hl]
	farcall RequestToPrintCard
	jp HandlePlayersCardsScreen.return_to_card_list

.quickly_return_to_card_list
	call EraseHeader
	call PrintPlayersCardsHeaderInfo.skip_empty_screen
	jp HandlePlayersCardsScreen.skip_header


; fills the first 4 rows of the screen with blank tiles
EraseHeader:
	xor a ; SYM_SPACE
	ld h, a
	ld l, a
	ld d, a ; starting x coordinate
	ld e, a ; starting y coordinate
	lb bc, 20, 4
	call FillRectangle
	ld a, [wConsole]
	cp CONSOLE_CGB
	ret nz ; exit if not CGB

	xor a ; CGB Background Palette 0 (monochrome)
	ld h, a
	ld l, a
	lb bc, 20, 4
	call BankswitchVRAM1
	call FillRectangle
	jp BankswitchVRAM0


YesNoInHeaderSelectionParams:
	db 3 ; x position
	db 3 ; y position
	db 0 ; y spacing
	db 4 ; x spacing
	db 2 ; number of entries
	db SYM_CURSOR_R ; visible cursor tile
	db SYM_SPACE ; invisible cursor tile
	dw NULL ; wCardListHandlerFunction


PrinterMenu_DeckConfiguration:
	xor a
	ld [wCardListVisibleOffset], a
	call ClearScreenAndDrawDeckMachineScreen
	ld a, NUM_DECK_SAVE_MACHINE_SLOTS
	ld [wNumDeckMachineEntries], a
	xor a
.start_selection
	ld hl, DeckMachineSelectionParams
	call InitCardSelectionParams
	call DrawListScrollArrows
	call PrintNumSavedDecks
	ldtx hl, PleaseChooseDeckConfigurationToPrintText
	call DrawWideTextBox_PrintText
	ldtx de, PleaseChooseDeckConfigurationToPrintText
	call InitDeckMachineDrawingParams
.loop_input
	call HandleDeckMachineSelection
	jr c, .start_selection
	cp -1
	ret z ; exit if the B button was pressed
	ld b, a
	ld a, [wCardListVisibleOffset]
	add b
	ld [wSelectedDeckMachineEntry], a
	call CheckIfSelectedDeckMachineEntryIsEmpty
	jr c, .loop_input
	call DrawWideTextBox
	ldtx hl, PrintThisDeckText
	call YesOrNoMenuWithText
	jr c, .no
	call GetSelectedSavedDeckPtr
	ld hl, DECK_NAME_SIZE
	add hl, de
	ld de, wCurDeckCards
	ld b, DECK_SIZE
	call CopyNBytesFromHLToDEInSRAM
	xor a ; terminator byte for deck
	ld [de], a
	call SortCurDeckCardsByID
	ld a, [wSelectedDeckMachineEntry]
	farcall PrintDeckConfiguration
	call ClearScreenAndDrawDeckMachineScreen
.no
	ld a, [wTempDeckMachineCursorPos]
	ld [wCardListCursorPos], a
	jr .start_selection


PrinterMenu_CardList:
	call WriteCardListsTerminatorBytes
	call Set_OBJ_8x8
	call EmptyScreenAndLoadFontDuelAndDeckIcons
	lb bc, 0, 4
	ld a, SYM_BOX_TOP
	call FillBGMapLineWithA
	xor a
	ld [wCardListVisibleOffset], a
	ld [wCurCardTypeFilter], a
	call PrintFilteredCardSelectionList
	call EnableLCD
	lb de, 1, 1
	ldtx hl, PrintTheCardListText
	call InitTextPrinting_ProcessTextFromID
	ld a, $01
	ld hl, YesNoInHeaderSelectionParams
	call InitCardSelectionParams
.loop_frame
	call DoFrame
	call HandleCardSelectionInput
	jr nc, .loop_frame
	or a
	ret nz
	farcall PrintCardList
	ret


PrinterMenu_PrintQuality:
	ldtx hl, PleaseSetTheContrastText
	call DrawWideTextBox_PrintText
	call EnableSRAM
	ld a, [sPrinterContrastLevel]
	call DisableSRAM
	ld hl, .SelectionParams
	call InitCardSelectionParams
.loop_frame
	call DoFrame
	call HandleCardSelectionInput
	jr nc, .loop_frame
	cp -1
	jr z, .skip_contrast ; don't adjust the contrast if the B button was pressed
	call EnableSRAM
	ld [sPrinterContrastLevel], a
	call DisableSRAM
.skip_contrast
	add sp, $2 ; exit menu
	ld a, [wSelectedPrinterMenuItem]
	ld hl, PrinterMenuParameters
	call InitializeMenuParameters
	ldtx hl, WhatWouldYouLikeToPrintText
	call DrawWideTextBox_PrintText
	jp HandlePrinterMenu.loop_input

.SelectionParams
	db 5  ; x position
	db 16 ; y position
	db 0  ; y spacing
	db 2  ; x spacing
	db 5  ; number of entries
	db SYM_CURSOR_R ; visible cursor tile
	db SYM_SPACE ; invisible cursor tile
	dw NULL ; wCardListHandlerFunction


PrinterMenu_QuitPrint:
	add sp, $2 ; exit menu
	ldtx hl, PleaseMakeSureToTurnGameBoyPrinterOffText
	jp DrawWideTextBox_WaitForInput
