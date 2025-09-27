; handles printing and player input in the card confirmation list that
; is shown when cards are missing for a deck configuration
; input:
;	hl = deck name
;	de = deck cards
HandleDeckMissingCardsList:
; read deck name from hl and cards from de
	push de
	ld de, wCurDeckName
	call CopyListFromHLToDEInSRAM
	pop de
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

.HandleList
	call SortCurDeckCardsByID
	call CreateCurDeckUniqueCardList
	xor a
	ld [wCardListVisibleOffset], a
.loop
	ld hl, .DeckConfirmationCardSelectionParams
	call InitCardSelectionParams
	ld a, [wNumUniqueCards]
	ld [wNumCardListEntries], a
	cp 5
	jr c, .got_num_positions
	ld a, 5 ; display the maximum number of visible entries
.got_num_positions
	ld [wCardListNumCursorPositions], a
	ld [wNumVisibleCardListEntries], a

; draw the screen
	call EmptyScreenAndLoadFontDuelAndDeckIcons
	call .PrintDeckIndexAndName
	call EnableLCD
	ld hl, wCardListCoords
	ld [hl], 3 ; initial y coordinate
	inc hl
	ld [hl], 3 ; initial x coordinate
	call PrintConfirmationCardList
	ld hl, wCardConfirmationText
	ld a, [hli]
	ld h, [hl]
	ld l, a
	call DrawWideTextBox_PrintText

; set the card update function
	ld hl, wCardListUpdateFunction
	ld a, LOW(.CardListUpdateFunction)
	ld [hli], a
	ld [hl], HIGH(.CardListUpdateFunction)
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
	; START button was pressed

.open_card_page
	ld a, SFX_CONFIRM
	call PlaySFX
	ld a, [wCardListCursorPos]
	ld [wced7], a
	ld de, wUniqueDeckCardList
	call OpenCardPageFromCardList
	jr .loop

.selection_made
	cp -1
	ret z ; exit if the B button was pressed
	jr .open_card_page

.DeckConfirmationCardSelectionParams
	db 0 ; x position
	db 3 ; y position
	db 2 ; y spacing
	db 0 ; x spacing
	db 5 ; number of entries
	db SYM_CURSOR_R ; visible cursor tile
	db SYM_SPACE ; invisible cursor tile
	dw NULL ; wCardListHandlerFunction

.CardListUpdateFunction
	ld hl, hffb0
	ld [hl], $01
	call .PrintDeckIndexAndName
	lb de, 1, 14
	ld hl, wCardConfirmationText
	ld a, [hli]
	ld h, [hl]
	ld l, a
	call InitTextPrinting_ProcessTextFromID
	ld hl, hffb0
	ld [hl], $00
	jp PrintConfirmationCardList

; prints text in the form "X.<DECK NAME> deck",
; where X is the deck index in the list
.PrintDeckIndexAndName
	ld a, [wCurDeckName]
	or a
	ret z ; not a valid deck
	ld a, [wCurDeck]
	inc a
	ld hl, wDefaultText
	call ConvertToNumericalDigits
	ldfw [hl], "." ; period punctuation mark
	inc hl
	ld [hl], TX_END
	ld hl, wDefaultText
	lb de, 0, 1
	call InitTextPrinting_ProcessText

	ld hl, wCurDeckName
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
	call CopyListFromHLToDE
	lb de, 3, 1
	ld hl, wDefaultText
	jp InitTextPrinting_ProcessText


HandleDeckSaveMachineMenu:
	xor a
	ld [wCardListVisibleOffset], a
	ld hl, wDeckMachineTitleText
	ld a, LOW(DeckSaveMachineText_)
	ld [hli], a
	ld [hl], HIGH(DeckSaveMachineText_)
	call ClearScreenAndDrawDeckMachineScreen
	ld a, NUM_DECK_SAVE_MACHINE_SLOTS
	ld [wNumDeckMachineEntries], a
	xor a
.start_selection
	ld hl, DeckMachineSelectionParams
	call InitCardSelectionParams
	call DrawListScrollArrows
	call PrintNumSavedDecks
	ldtx hl, PleaseSelectDeckText
	call DrawWideTextBox_PrintText
	ldtx de, PleaseSelectDeckText
	call InitDeckMachineDrawingParams
	call HandleDeckMachineSelection
	jr c, .start_selection
	cp -1
	ret z ; exit if the B button was pressed
	; get the index of the selected deck
	ld b, a
	ld a, [wCardListVisibleOffset]
	add b
	ld [wSelectedDeckMachineEntry], a

	ld a, 10
	ld [wCheckMenuCursorXPositionOffset], a
	call ResetCheckMenuCursorPositionAndBlink
	call DrawWideTextBox
	ld hl, .DeckMachineMenuData
	call PlaceTextItems
.wait_input_submenu
	call DoFrame
	call HandleCheckMenuInput
	jr nc, .wait_input_submenu
	cp -1
	jr z, .restart_selection ; close submenu if the B button was pressed

.submenu_option_selected
	ld a, [wCheckMenuCursorYPosition]
	add a
	ld hl, wCheckMenuCursorXPosition
	add [hl]
	; a = 2 * cursor y position + cursor x position
	or a
	jr nz, .check_second_submenu_option

; Build This Deck
	call CheckIfSelectedDeckMachineEntryIsEmpty
	jr c, .is_empty
	call TryBuildDeckMachineDeck
	jr nc, .restart_selection
.redraw_screen_and_restart_selection
	ld a, [wTempCardListVisibleOffset]
	ld [wCardListVisibleOffset], a
	call ClearScreenAndDrawDeckMachineScreen
	call DrawListScrollArrows
	call PrintNumSavedDecks
.restart_selection
	ld a, [wTempDeckMachineCursorPos]
	jr .start_selection

.check_second_submenu_option
	dec a
	jr nz, .check_third_submenu_option

; Save a New Deck
	call CheckIfSelectedDeckMachineEntryIsEmpty
	jr c, .save_deck
	; slot isn't empty, so ask if it's okay to replace the current entry
	ldtx hl, OKIfFileDeletedText
	call YesOrNoMenuWithText
	jr c, .restart_selection ; cancel save if the Player answered "No"
.save_deck
	call SaveDeckInDeckSaveMachine
	jr nc, .redraw_screen_and_restart_selection
	jr .restart_selection

.check_third_submenu_option
	dec a
	ret nz ; must be fourth submenu option "Cancel"

; Delete This Deck
	call CheckIfSelectedDeckMachineEntryIsEmpty
	jr c, .is_empty
	call TryDeleteSavedDeck
	jr nc, .redraw_screen_and_restart_selection
	jr .restart_selection

; unused deck save slot
.is_empty
	call PlaySFX_InvalidChoice
	ldtx hl, NoDeckIsSavedText
	call DrawWideTextBox_WaitForInput
	jr .restart_selection

.DeckMachineMenuData
	textitem  2, 14, BuildThisDeckText
	textitem 12, 14, SaveNewDeckText
	textitem  2, 16, DeleteThisDeckText
	textitem 12, 16, CancelText
	db $ff


; sets the number of cursor positions for the deck machine menu, sets the ID
; for the text to print, and sets DrawDeckMachineScreen as the update function
; preserves bc and de
; input:
;	de = text ID
InitDeckMachineDrawingParams:
	ld a, NUM_DECK_MACHINE_SLOTS
	ld [wCardListNumCursorPositions], a
	ld hl, wDeckMachineText
	ld [hl], e
	inc hl
	ld [hl], d
	ld hl, wCardListUpdateFunction
	ld a, LOW(DrawDeckMachineScreen)
	ld [hli], a
	ld [hl], HIGH(DrawDeckMachineScreen)
	xor a
	ld [wced2], a
	ret


; handles the player's input inside the Deck Machine screen.
; the Start button opens up the deck confirmation menu and returns carry.
; otherwise, returns no carry with the player's selection in a.
; output:
;	a = player's selection
;	carry = set:  if the player used the START button to view a deck list
HandleDeckMachineSelection:
.start
	call DoFrame
	call HandleDeckCardSelectionList
	jr c, .selection_made

	call .HandleListJumps
	jr c, .start
	ldh a, [hDPadHeld]
	and PAD_START
	jr z, .start

; START button
	ld a, [wCardListVisibleOffset]
	ld [wTempCardListVisibleOffset], a
	ld b, a
	ld a, [wCardListCursorPos]
	ld [wTempDeckMachineCursorPos], a
	add b
	ld c, a
	inc a
	or $80
	ld [wCurDeck], a

	; get pointer to the cards from the selected deck,
	; and if it's an empty deck, jump back to the start
	sla c
	ld b, $0
	ld hl, wMachineDeckPtrs
	add hl, bc
	ld a, [hli]
	ld h, [hl]
	ld l, a
	push hl
	ld bc, DECK_NAME_SIZE
	add hl, bc
	ld d, h
	ld e, l
	call EnableSRAM
	ld a, [hl]
	call DisableSRAM
	pop hl
	or a
	jr z, .start

; show deck confirmation screen with deck cards
; and return with the carry flag set
	ld a, SFX_CONFIRM
	call PlaySFX
	call OpenDeckConfirmationMenu
	ld a, [wTempCardListVisibleOffset]
	ld [wCardListVisibleOffset], a
	call ClearScreenAndDrawDeckMachineScreen
	call DrawListScrollArrows
	call PrintNumSavedDecks
	ld a, [wTempDeckMachineCursorPos]
	ld [wCardListCursorPos], a
	scf
	ret

.selection_made
	call DrawListCursor_Visible
	ld a, [wCardListVisibleOffset]
	ld [wTempCardListVisibleOffset], a
	ld a, [wCardListCursorPos]
	ld [wTempDeckMachineCursorPos], a
	ldh a, [hffb3]
	or a
	ret

; handles right and left input for jumping several entries at once
; output:
;	carry = set:  if a jump was made
.HandleListJumps
	ld a, [wCardListVisibleOffset]
	ld c, a
	ldh a, [hDPadHeld]
	cp PAD_RIGHT
	jr z, .d_right
	cp PAD_LEFT
	jr z, .d_left
	or a
	ret

.d_right
	ld a, [wCardListVisibleOffset]
	add NUM_DECK_MACHINE_SLOTS
	ld b, a
	add NUM_DECK_MACHINE_SLOTS
	ld hl, wNumDeckMachineEntries
	cp [hl]
	jr c, .got_new_pos
	ld a, [wNumDeckMachineEntries]
	sub NUM_DECK_MACHINE_SLOTS
	ld b, a
	jr .got_new_pos

.d_left
	ld a, [wCardListVisibleOffset]
	sub NUM_DECK_MACHINE_SLOTS
	ld b, a
	jr nc, .got_new_pos
	ld b, 0 ; first entry

.got_new_pos
	ld a, b
	ld [wCardListVisibleOffset], a
	cp c
	jr z, .set_carry
	; play SFX if jump was made and update UI
	ld a, SFX_CURSOR
	call PlaySFX
	call DrawDeckMachineScreen
	call PrintNumSavedDecks
.set_carry
	scf
	ret


; preserves de
; output:
;	carry = set:  if the deck corresponding to the entry that was
;	              selected in the Deck Machine menu is empty
CheckIfSelectedDeckMachineEntryIsEmpty:
	ld a, [wSelectedDeckMachineEntry]
	add a
	ld l, a
	ld h, $0
	ld bc, wMachineDeckPtrs
	add hl, bc
	ld a, [hli]
	ld h, [hl]
	ld l, a
	ld bc, DECK_NAME_SIZE
	add hl, bc
	call EnableSRAM
	ld a, [hl]
	call DisableSRAM
	or a
	ret nz ; is valid
	scf
	ret ; is empty


ClearScreenAndDrawDeckMachineScreen:
	call Set_OBJ_8x8
	xor a ; SYM_SPACE
	ld [wTileMapFill], a
	call EmptyScreen
	call ZeroObjectPositionsAndToggleOAMCopy
	call LoadSymbolsFont
	call LoadDuelCardSymbolTiles
	call SetDefaultConsolePalettes
	lb de, $38, $ff
	call SetupText
	lb de, 0, 0
	lb bc, 20, 13
	call DrawRegularTextBox
	call SetDeckMachineTitleText
	call GetSavedDeckPointers
	call PrintVisibleDeckMachineEntries
	call GetSavedDeckCount
	jp EnableLCD


; prints wDeckMachineTitleText as the title text
; preserves bc
; input:
;	[wDeckMachineTitleText] = text ID (2 bytes)
SetDeckMachineTitleText:
	lb de, 1, 0
	ld hl, wDeckMachineTitleText
	ld a, [hli]
	ld h, [hl]
	ld l, a
	jp InitTextPrinting_ProcessTextFromID


; saves all sSavedDecks pointers in wMachineDeckPtrs
GetSavedDeckPointers:
	ld a, 2 * NUM_DECK_SAVE_MACHINE_SLOTS ; number of bytes that will be cleared
	ld hl, wMachineDeckPtrs
	call ClearMemory_Bank2
	ld de, wMachineDeckPtrs
	ld hl, sSavedDecks
	ld bc, DECK_STRUCT_SIZE
	ld a, NUM_DECK_SAVE_MACHINE_SLOTS
.loop_saved_decks
	push af
	ld a, l
	ld [de], a
	inc de
	ld a, h
	ld [de], a
	inc de
	add hl, bc
	pop af
	dec a
	jr nz, .loop_saved_decks
	ret


UpdateDeckMachineScrollArrowsAndEntries:
	call DrawListScrollArrows
	jr PrintVisibleDeckMachineEntries

; input:
;	[wDeckMachineTitleText] = text ID (2 bytes)
;	[wDeckMachineText] = text ID (2 bytes)
DrawDeckMachineScreen:
	call DrawListScrollArrows
	ld hl, hffb0
	ld [hl], $01
	call SetDeckMachineTitleText
	lb de, 1, 14
	ld hl, wDeckMachineText
	ld a, [hli]
	ld h, [hl]
	ld l, a
	call InitTextPrinting_ProcessTextFromID
	ld hl, hffb0
	ld [hl], $00
;	fallthrough

; given the cursor position in the deck machine menu,
; prints the deck names of all entries that are visible
PrintVisibleDeckMachineEntries:
	ld a, [wCardListVisibleOffset]
	lb de, 2, 2
	ld b, NUM_DECK_MACHINE_VISIBLE_DECKS
.loop
	push af
	push bc
	push de
	call PrintDeckMachineEntry
	pop de
	pop bc
	pop af
	ret c ; jump never made?
	dec b
	ret z ; no more entries
	inc a
	inc e
	inc e
	jr .loop


; prints the deck name of the deck corresponding to the wMachineDeckPtrs index in register a.
; also checks whether the deck can be built, either directly from the player's collection
; or by dismantling other decks, and places the corresponding symbol next to the name.
; input:
;	a = index for the entry that should be printed
;	de = screen coordinates for printing the text
; output:
;	carry = set:  if the deck from input is not valid, i.e. it has no cards
PrintDeckMachineEntry:
	ld b, a
	push bc
	ld hl, wDefaultText
	inc a ; entry indices start at 0, not 1
	call ConvertToNumericalDigits
	ldfw [hl], "." ; period punctuation mark
	inc hl
	ld [hl], TX_END
	ld hl, wDefaultText
	call InitTextPrinting_ProcessText
	pop af

; get the deck corresponding to the index from input
; and append its name to wDefaultText
	push af
	add a ; 2 * index (pointers are 2 bytes)
	ld l, a
	ld h, $0
	ld bc, wMachineDeckPtrs
	add hl, bc
	ld a, [hli]
	ld h, [hl]
	ld l, a
	inc d
	inc d
	inc d
	push de
	call PrintDeckNameForDeckMachine
	pop de
	pop bc
	jr nc, .valid_deck

; invalid deck, give it the default
; empty deck name ("--------------")
	ldtx hl, EmptyDeckNameText
	call InitTextPrinting_ProcessTextFromID
	ld d, 13
	inc e
	ld hl, .text
	call InitTextPrinting_ProcessText
	scf
	ret

.valid_deck
	push de
	push bc
	ld d, 18
	call InitTextPrinting

; print the symbol that represents whether the deck can be built,
; or if another deck has to be dismantled to build it
	xor a ; no decks dismantled
	call CheckIfCanBuildSavedDeck
	pop bc
	ld hl, wDefaultText
	jr c, .cannot_build
	ldfw de, "○" ; can build
	; fallthrough

.print_build_status_symbol
	call Func_22ca
	pop de
	ld d, 13
	inc e
	ld hl, .text
	call InitTextPrinting_ProcessText
	or a
	ret

.cannot_build
	push bc
	ld a, ALL_DECKS
	call CheckIfCanBuildSavedDeck
	jr c, .cannot_build_at_all
	pop bc
	ldfw de, "※" ; can build by dismantling
	jr .print_build_status_symbol

.cannot_build_at_all
	ldfw de, "×" ; cannot build even by dismantling
	call Func_22ca
	pop bc
	pop de

; place in wDefaultText the number of cards
; that are needed in order to build the deck
	ld d, 17
	inc e
	call InitTextPrinting
	call .GetNumCardsMissingToBuildDeck
	ld hl, wDefaultText
	call ConvertToNumericalDigits
	ld [hl], TX_END
	ld hl, wDefaultText
	call ProcessText
	or a
	ret

.text
	db "<SPACE><SPACE><SPACE><SPACE><SPACE><SPACE>"
	done

; input:
;	b = index for the current deck machine entry
; output:
;	a = how many cards the player still needs before being able to build the deck
.GetNumCardsMissingToBuildDeck
	push bc
	call SafelySwitchToSRAM0
	call CreateCardCollectionListWithDeckCards
	call SafelySwitchToTempSRAMBank
	pop bc

; get address to cards for the corresponding deck entry
	sla b
	ld c, b
	ld b, $00
	ld hl, wMachineDeckPtrs
	add hl, bc
	ld a, [hli]
	ld h, [hl]
	ld l, a
	ld bc, DECK_NAME_SIZE
	add hl, bc

	call EnableSRAM
	ld de, wTempCardCollection
	lb bc, DECK_SIZE, 0
.loop
	ld a, [hli]
	push hl
	ld l, a
	ld h, $00
	add hl, de
	ld a, [hl]
	and CARD_COUNT_MASK
	or a
	jr z, .none
	dec [hl]
.next
	pop hl
	dec b
	jr nz, .loop
.done
	ld a, c
	jp DisableSRAM
.none
	inc c
	jr .next


; output:
;	[wNumSavedDecks] & a = number of decks in sSavedDecks that aren't empty
GetSavedDeckCount:
	call EnableSRAM
	ld hl, sSavedDecks
	ld bc, DECK_STRUCT_SIZE
	lb de, NUM_DECK_SAVE_MACHINE_SLOTS, 0
.loop
	ld a, [hl]
	or a
	jr z, .empty_slot
	inc e
.empty_slot
	add hl, bc
	dec d
	jr nz, .loop
; got count
	ld a, e
	ld [wNumSavedDecks], a
	jp DisableSRAM


; prints "[wNumSavedDecks]/60"
PrintNumSavedDecks:
	ld a, [wNumSavedDecks]
	ld hl, wDefaultText
	call ConvertToNumericalDigits
	ld a, TX_SYMBOL
	ld [hli], a
	ld a, SYM_SLASH
	ld [hli], a
	ld a, NUM_DECK_SAVE_MACHINE_SLOTS
	call ConvertToNumericalDigits
	ld [hl], TX_END
	lb de, 14, 1
	ld hl, wDefaultText
	jp InitTextPrinting_ProcessText


; handles player choice in what deck to save in the Deck Save Machine.
; assumes the slot to save was selected and is stored in wSelectedDeckMachineEntry.
; output:
;	carry = set:  if the deck was successfully saved
SaveDeckInDeckSaveMachine:
	ld a, ALL_DECKS
	call DrawDecksScreen
	xor a
.start_selection
	ld hl, DeckSelectionMenuParameters
	call InitializeMenuParameters
	ldtx hl, ChooseADeckToSaveText
	call DrawWideTextBox_PrintText
.wait_input
	call DoFrame
	call HandleStartButtonInDeckSelectionMenu
	jr c, .start_selection
	call HandleMenuInput
	jr nc, .wait_input
	cp -1
	ret z ; exit if the B button was pressed
	ld [wCurDeck], a
	call CheckIfCurDeckIsValid
	jr nc, .SaveDeckInSelectedEntry
	; is an empty deck
	call PrintThereIsNoDeckHereText
	jr .start_selection

; overwrites data in the selected deck in SRAM
; with the deck that was chosen, in wCurDeck
; output:
;	carry = set
.SaveDeckInSelectedEntry
	call GetPointerToDeckName
	call GetSelectedSavedDeckPtr
	ld b, DECK_STRUCT_SIZE
	call CopyNBytesFromHLToDEInSRAM

	call ClearScreenAndDrawDeckMachineScreen
	call DrawListScrollArrows
	call PrintNumSavedDecks
	ld a, [wTempDeckMachineCursorPos]
	ld hl, DeckMachineSelectionParams
	call InitCardSelectionParams
	call DrawListCursor_Visible
	call GetPointerToDeckName
	call EnableSRAM
	call CopyDeckName
	call DisableSRAM
	; zero wTxRam2 so that the deck name just loaded to wDefaultText is printed
	ld hl, wTxRam2
	xor a
	ld [hli], a
	ld [hl], a
	ldtx hl, SavedTheConfigurationForText
	call DrawWideTextBox_WaitForInput
	scf
	ret

DeckMachineSelectionParams:
	db 1 ; x position
	db 2 ; y position
	db 2 ; y spacing
	db 0 ; x spacing
	db 5 ; number of entries
	db SYM_CURSOR_R ; visible cursor tile
	db SYM_SPACE ; invisible cursor tile
	dw NULL ; wCardListHandlerFunction


; preserves af, bc, and hl
; output:
;	de = pointer for saved deck corresponding to index in wSelectedDeckMachineEntry
GetSelectedSavedDeckPtr:
	push af
	push hl
	ld a, [wSelectedDeckMachineEntry]
	add a
	ld e, a
	ld d, $00
	ld hl, wMachineDeckPtrs
	add hl, de
	ld e, [hl]
	inc hl
	ld d, [hl]
	pop hl
	pop af
	ret


; checks if it's possible to build saved deck with index b.
; includes cards from already built decks based on the flags in a.
; input:
;	a = DECK_* flags for which decks to include in the collection
;	b = saved deck index
; output:
;	carry = set:  if the deck cannot be built with the given criteria
CheckIfCanBuildSavedDeck:
	push bc
	call SafelySwitchToSRAM0
	call CreateCardCollectionListWithDeckCards
	call SafelySwitchToTempSRAMBank
	pop bc
	sla b
	ld c, b
	ld b, $0
	ld hl, wMachineDeckPtrs
	add hl, bc
	ld a, [hli]
	ld h, [hl]
	ld l, a
	ld bc, DECK_NAME_SIZE
	add hl, bc
;	fallthrough

; input:
;	hl = pointer to the deck list
; output:
;	carry = set:  if wTempCardCollection does not have enough cards
;	              to build the deck from input
CheckIfHasEnoughCardsToBuildDeck:
	call EnableSRAM
	ld de, wTempCardCollection
	ld b, DECK_SIZE
.loop
	ld a, [hli]
	push hl
	ld l, a
	ld h, $00
	add hl, de
	ld a, [hl]
	or a
	jr z, .set_carry
	cp CARD_NOT_OWNED
	jr z, .set_carry
	dec [hl]
	pop hl
	dec b
	jr nz, .loop
	or a
	jp DisableSRAM

.set_carry
	pop hl
	scf
	jp DisableSRAM



; switches to SRAM bank 0 and stores current SRAM bank in wTempBankSRAM.
; immediately returns if SRAM bank 0 is already the current SRAM bank.
; preserves all registers
SafelySwitchToSRAM0:
	push af
	ldh a, [hBankSRAM]
	or a
	jr z, .skip
	ld [wTempBankSRAM], a
	xor a
	call BankswitchSRAM
.skip
	pop af
	ret


; switches to SRAM bank 1 and stores current SRAM bank in wTempBankSRAM.
; immediately returns if SRAM bank 1 is already the current SRAM bank.
; preserves all registers
SafelySwitchToSRAM1:
	push af
	ldh a, [hBankSRAM]
	cp BANK("SRAM1")
	jr z, .skip
	ld [wTempBankSRAM], a
	ld a, BANK("SRAM1")
	call BankswitchSRAM
.skip
	pop af
	ret


; preserves all registers
SafelySwitchToTempSRAMBank:
	push af
	push bc
	ldh a, [hBankSRAM]
	ld b, a
	ld a, [wTempBankSRAM]
	cp b
	call nz, BankswitchSRAM
	pop bc
	pop af
	ret


; preserves bc and de
; output:
;	a = first empty deck slot (0-3)
;	carry = set:  if no empty slot was found
FindFirstEmptyDeckSlot:
	ld hl, sDeck1Cards
	ld a, [hl]
	or a
	ret z ; return with a = 0 if the first deck is empty

.check_deck_2
	ld hl, sDeck2Cards
	ld a, [hl]
	or a
	jr nz, .check_deck_3
	inc a ; 1
	ret

.check_deck_3
	ld hl, sDeck3Cards
	ld a, [hl]
	or a
	jr nz, .check_deck_4
	ld a, 2
	ret

.check_deck_4
	ld hl, sDeck4Cards
	ld a, [hl]
	or a
	jr nz, .set_carry
	ld a, 3
	ret

.set_carry
	scf
	ret


; prompts the player whether to delete the selected saved deck.
; if the player selects "Yes", then clear the memory in SRAM
; corresponding to that saved deck slot.
; output:
;	carry = set:  if the player selected "No"
TryDeleteSavedDeck:
	ldtx hl, DoYouReallyWishToDeleteText
	call YesOrNoMenuWithText
	ret c ; return if "No" was selected
	call GetSelectedSavedDeckPtr
	ld l, e
	ld h, d
	push hl
	call EnableSRAM
	call CopyDeckName
	pop hl
	ld a, DECK_STRUCT_SIZE ; number of bytes that will be cleared
	call ClearMemory_Bank2
	call DisableSRAM
	; zero wTxRam2 so that the deck name just loaded to wDefaultText is printed
	ld hl, wTxRam2
	xor a
	ld [hli], a
	ld [hl], a
	ldtx hl, DeletedTheConfigurationForText
	jp DrawWideTextBox_WaitForInput


; preserves de and hl
DrawListScrollArrows:
	ld a, [wCardListVisibleOffset]
	or a
	ld a, SYM_BOX_RIGHT
	jr z, .got_tile_1
	ld a, SYM_CURSOR_U
.got_tile_1
	lb bc, 19, 1
	call WriteByteToBGMap0

	ld a, [wCardListVisibleOffset]
	add NUM_DECK_MACHINE_VISIBLE_DECKS + 1
	ld b, a
	ld a, [wNumDeckMachineEntries]
	cp b
	jr c, .no_down_cursor
	xor a ; FALSE
	ld [wUnableToScrollDown], a
	ld a, SYM_CURSOR_D
	jr .got_tile_2
.no_down_cursor
	ld a, TRUE
	ld [wUnableToScrollDown], a
	ld a, SYM_BOX_RIGHT
.got_tile_2
	lb bc, 19, 11
	jp WriteByteToBGMap0


; handles the deck menu for when the player
; needs to make space for new deck to build
; output:
;	carry = set:  if the operation was cancelled by the Player (with B button)
HandleDismantleDeckToMakeSpace:
	ldtx hl, YouMayOnlyCarry4DecksText
	call DrawWideTextBox_WaitForInput
	call SafelySwitchToSRAM0
	ld a, ALL_DECKS
	call DrawDecksScreen
	xor a
.start_selection
	ld hl, DeckSelectionMenuParameters
	call InitializeMenuParameters
	ldtx hl, ChooseADeckToDismantleText
	call DrawWideTextBox_PrintText
.loop_input
	call DoFrame
	call HandleStartButtonInDeckSelectionMenu
	jr c, .start_selection
	call HandleMenuInput
	jr nc, .loop_input
	cp -1
	jr nz, .selected_deck
	; operation was cancelled
	call SafelySwitchToTempSRAMBank
	scf
	ret

.selected_deck
	ld [wCurDeck], a
	ldtx hl, DismantleThisDeckText
	call YesOrNoMenuWithText
	ld a, [wCurDeck]
	jr c, .start_selection ; loop back to the start if "No" was selected
	; player chose to dismantle the deck
	call GetPointerToDeckName
	push hl
	ld de, wDismantledDeckName
	call EnableSRAM
	call CopyListFromHLToDE
	pop hl
	push hl
	ld bc, DECK_NAME_SIZE
	add hl, bc
	call AddDeckToCollection
	pop hl
	ld a, DECK_STRUCT_SIZE ; number of bytes that will be cleared
	call ClearMemory_Bank2
	call DisableSRAM

	; redraw deck screen
	ld a, ALL_DECKS
	call DrawDecksScreen
	ld a, [wCurDeck]
	ld hl, DeckSelectionMenuParameters
	call InitializeMenuParameters
	call DrawCursor2
	call SafelySwitchToTempSRAMBank
	ld hl, wDismantledDeckName
	call CopyDeckName
	; zero wTxRam2 so that the deck name just loaded to wDefaultText is printed
	ld hl, wTxRam2
	xor a
	ld [hli], a
	ld [hl], a
	ldtx hl, DismantledDeckText
	call DrawWideTextBox_WaitForInput
	ld a, [wCurDeck]
	ret


; tries to build the deck in wSelectedDeckMachineEntry.
; will check if can be built with or without dismantling.
; prompts the player in case a deck has to be dismantled,
; or, if it's impossible to build the deck, then show the list of missing cards.
; output:
;	carry = set (always?)
TryBuildDeckMachineDeck:
	ld a, [wSelectedDeckMachineEntry]
	ld b, a
	push bc
	xor a ; no decks dismantled
	call CheckIfCanBuildSavedDeck
	pop bc
	jr nc, .build_deck
	ld a, ALL_DECKS
	call CheckIfCanBuildSavedDeck
	jp c, .ShowMissingCardList
	; can only be built by dismantling some deck
	ldtx hl, ThisDeckCanOnlyBeBuiltIfYouDismantleText
	call DrawWideTextBox_WaitForInput
	call .DismantleDecksNeededToBuild
	jp c, .set_carry ; return carry if the player chose not to dismantle the deck(s)

.build_deck
	call EnableSRAM
	call SafelySwitchToSRAM0
	call FindFirstEmptyDeckSlot
	call SafelySwitchToTempSRAMBank
	call DisableSRAM
	jr nc, .got_deck_slot
	call HandleDismantleDeckToMakeSpace
	ret c
	; fallthrough

.got_deck_slot
	ld [wDeckSlotForNewDeck], a
	ld a, [wSelectedDeckMachineEntry]
	add a
	ld c, a
	ld b, $00
	ld hl, wMachineDeckPtrs
	add hl, bc
	ld a, [hli]
	ld h, [hl]
	ld l, a

	; copy deck to buffer
	ld de, wDeckToBuild
	ld b, DECK_STRUCT_SIZE
	call EnableSRAM
	call CopyNBytesFromHLToDE

	; remove the needed cards from collection
	ld hl, wDeckToBuild + DECK_NAME_SIZE
	call SafelySwitchToSRAM0
	call DecrementDeckCardsInCollection

	; copy the deck cards from the buffer
	; to the deck slot that was chosen
	ld a, [wDeckSlotForNewDeck]
	ld l, a
	ld h, DECK_STRUCT_SIZE
	call HtimesL
	ld bc, sBuiltDecks
	add hl, bc
	ld d, h
	ld e, l
	ld hl, wDeckToBuild
	ld b, DECK_STRUCT_SIZE
	call CopyNBytesFromHLToDE
	call DisableSRAM

	; draw Decks screen
	ld a, ALL_DECKS
	call DrawDecksScreen
	ld a, [wDeckSlotForNewDeck]
	ld [wCurDeck], a
	ld hl, DeckSelectionMenuParameters
	call InitializeMenuParameters
	call DrawCursor2
	call GetPointerToDeckName
	call EnableSRAM
	call CopyDeckName
	call DisableSRAM
	call SafelySwitchToTempSRAMBank
	; zero wTxRam2 so that the deck name just loaded to wDefaultText is printed
	ld hl, wTxRam2
	xor a
	ld [hli], a
	ld [hl], a
	ldtx hl, BuiltDeckText
	call DrawWideTextBox_WaitForInput
	scf
	ret


; asks the player for confirmation to dismantle decks
; needed to build the selected deck from the Deck Save Machine.
; if the player selected "Yes", then dismantle the decks.
; output:
;	carry = set:  if player selected "No"
.DismantleDecksNeededToBuild
; shows Decks screen with the names of the decks to be dismantled
	call CheckWhichDecksToDismantleToBuildSavedDeck
	call SafelySwitchToSRAM0
	call DrawDecksScreen
	ldtx hl, DismantleTheseDecksText
	call YesOrNoMenuWithText
	jp c, SafelySwitchToTempSRAMBank ; reset SRAM bank and return carry if "No" was selected
	; player chose to dismantle the required deck(s)
	call EnableSRAM
; deck 1
	ld a, [wDecksToBeDismantled]
	bit DECK_1_F, a
	ld a, DECK_1_F
	call nz, .DismantleDeck
; deck 2
	ld a, [wDecksToBeDismantled]
	bit DECK_2_F, a
	ld a, DECK_2_F
	call nz, .DismantleDeck
; deck 3
	ld a, [wDecksToBeDismantled]
	bit DECK_3_F, a
	ld a, DECK_3_F
	call nz, .DismantleDeck
; deck 4
	ld a, [wDecksToBeDismantled]
	bit DECK_4_F, a
	ld a, DECK_4_F
	call nz, .DismantleDeck
; done dismantling
	call DisableSRAM
	ld a, [wDecksToBeDismantled]
	call DrawDecksScreen
	call SafelySwitchToTempSRAMBank
	ldtx hl, DismantledTheDeckText
	jp DrawWideTextBox_WaitForInput


; dismantles built deck given by a
; and adds its cards to the collection
; input:
;	a = DECK_*_F to dismantle
.DismantleDeck
	ld l, a
	ld h, DECK_STRUCT_SIZE
	call HtimesL
	ld bc, sBuiltDecks
	add hl, bc
	push hl
	ld bc, DECK_NAME_SIZE
	add hl, bc
	call AddDeckToCollection
	pop hl
	ld a, DECK_STRUCT_SIZE ; number of bytes that will be cleared
	jp ClearMemory_Bank2


; collects cards missing from the player's collection and shows its confirmation list
; output:
;	carry = set
.ShowMissingCardList
	ldtx hl, YouDoNotOwnAllCardsNeededToBuildThisDeckText
	call DrawWideTextBox_WaitForInput
; copy saved deck cards from SRAM to wCurDeckCards
; and make unique card list sorted by ID
	ld a, [wSelectedDeckMachineEntry]
	ld [wCurDeck], a
	call GetSelectedSavedDeckPtr
	ld hl, DECK_NAME_SIZE
	add hl, de
	ld de, wCurDeckCards
	ld b, DECK_SIZE
	call CopyNBytesFromHLToDEInSRAM
	xor a ; terminator byte for deck
	ld [de], a
	call SortCurDeckCardsByID
	call CreateCurDeckUniqueCardList

; create collection card list, including the cards from all built decks
	ld a, ALL_DECKS
	call SafelySwitchToSRAM0
	call CreateCardCollectionListWithDeckCards
	call SafelySwitchToTempSRAMBank

; creates list in wFilteredCardList with
; cards that are missing to build this deck
	ld hl, wUniqueDeckCardList
	ld de, wFilteredCardList
.loop_deck_configuration
	ld a, [hli]
	or a
	jr z, .finish_missing_card_list
	ld b, a
	push de
	push hl
	ld hl, wCurDeckCards
	call .CheckIfCardIsMissing
	pop hl
	pop de
	jr nc, .loop_deck_configuration
	; this card is missing, so store in wFilteredCardList this card ID
	; a number of times equal to the amount still needed
	ld c, a
	ld a, b
.loop_number_missing
	ld [de], a
	inc de
	dec c
	jr nz, .loop_number_missing
	jr .loop_deck_configuration

.finish_missing_card_list
	xor a ; terminator byte
	ld [de], a

	ld hl, wCardConfirmationText
	ld a, LOW(TheseCardsAreNeededToBuildThisDeckText_)
	ld [hli], a
	ld [hl], HIGH(TheseCardsAreNeededToBuildThisDeckText_)

	call GetSelectedSavedDeckPtr
	ld h, d
	ld l, e
	ld de, wFilteredCardList
	call HandleDeckMissingCardsList
.set_carry
	ld a, [wCardListCursorPos]
	scf
	ret


; checks if player has enough cards with ID given in register a
; in the collection to build the deck, and if not,
; sets the carry flag and outputs in a the difference.
; preserves bc
; input:
;	a = card ID
;	hl = list of deck cards (e.g. wCurDeckCards)
; output:
;	a = number of cards needed to build the deck (only if cannot build)
;	carry = set:  if the player doesn't have enough cards to build the deck
.CheckIfCardIsMissing
; get card count from deck
	ld e, a
	ld d, 0
.loop_deck_cards
	ld a, [hli]
	or a
	jr z, .get_card_count_from_collection
	cp e
	jr nz, .loop_deck_cards
	inc d
	jr .loop_deck_cards

.get_card_count_from_collection
	push de
	ld hl, wTempCardCollection
	ld d, $00
	add hl, de
	pop de
	ld a, [hl]
	and CARD_COUNT_MASK
	; d = card count in deck
	; a = card count in collection
	cp d
	ret nc ; return no carry if there are enough of this card in the collection

; needs more cards than the player has in their in collection
; return with carry set and the number of cards needed in a
	ld e, a
	ld a, d
	sub e
	scf
	ret


; tries out all combinations of dismantling the player's decks
; in order to build the deck in wSelectedDeckMachineEntry
; output:
;	a = which deck(s) would need to be dismantled
;	carry = set:  if none of the combinations work
CheckWhichDecksToDismantleToBuildSavedDeck:
	xor a
	ld [wDecksToBeDismantled], a

; first check if it can be built by only dismantling a single deck
	ld a, DECK_1
.loop_single_built_decks
	call .CheckIfCanBuild
	ret nc
	add a ; move on to the next deck (each bit is twice the previous bit: 1, 2, 4, 8)
	cp (1 << NUM_DECKS)
	jr nz, .loop_single_built_decks

; next check all two deck combinations
	ld a, DECK_1 | DECK_2
	call .CheckIfCanBuild
	ret nc
	ld a, DECK_1 | DECK_3
	call .CheckIfCanBuild
	ret nc
	ld a, DECK_1 | DECK_4
	call .CheckIfCanBuild
	ret nc
	ld a, DECK_2 | DECK_3
	call .CheckIfCanBuild
	ret nc
	ld a, DECK_2 | DECK_4
	call .CheckIfCanBuild
	ret nc
	ld a, DECK_3 | DECK_4
	call .CheckIfCanBuild
	ret nc

; next check all three deck combinations
	ld a, $ff ^ DECK_4
.loop_three_deck_combinations
	call .CheckIfCanBuild
	ret nc
	sra a
	cp $ff
	jr nz, .loop_three_deck_combinations

; finally check if can be built by dismantling all decks (a = $ff)
;	fallthrough

; preserves af
; input:
;	a = DECK_* flags
; output:
;	carry = set:  if wSelectedDeckMachineEntry cannot be built by
;	              dismantling the decks from input
.CheckIfCanBuild
	push af
	ld hl, wSelectedDeckMachineEntry
	ld b, [hl]
	call CheckIfCanBuildSavedDeck
	jr c, .cannot_build
	pop af
	ld [wDecksToBeDismantled], a
	or a
	ret
.cannot_build
	pop af
	scf
	ret


HandleAutoDeckMenu:
	ld a, [wCurAutoDeckMachine]
	ld hl, .DeckMachineTitleTextList
	add a
	ld c, a
	ld b, $0
	add hl, bc
	ld de, wDeckMachineTitleText
	ld a, [hli]
	ld [de], a
	inc de
	ld a, [hl]
	ld [de], a
	xor a
	ld [wCardListVisibleOffset], a
	call .InitAutoDeckMenu
	ld a, NUM_DECK_MACHINE_SLOTS
	ld [wNumDeckMachineEntries], a
	xor a

.start_deck_selection
	ld hl, .MenuParameters
	call InitializeMenuParameters
	ldtx hl, PleaseSelectDeckText
	call DrawWideTextBox_PrintText
	ld a, NUM_DECK_MACHINE_SLOTS
	ld [wCardListNumCursorPositions], a
	ld hl, wCardListUpdateFunction
	ld a, LOW(UpdateDeckMachineScrollArrowsAndEntries)
	ld [hli], a
	ld [hl], HIGH(UpdateDeckMachineScrollArrowsAndEntries)
.wait_input
	call DoFrame
	call HandleMenuInput
	jr c, .deck_selection_made

; check whether to show deck confirmation list
	ldh a, [hDPadHeld]
	and PAD_START
	jr z, .wait_input

	ld a, [wCardListVisibleOffset]
	ld [wTempCardListVisibleOffset], a
	ld b, a
	ld a, [wCurMenuItem]
	ld [wTempDeckMachineCursorPos], a
	add b
	ld c, a
	inc a
	or $80
	ld [wCurDeck], a
	sla c
	ld b, $0
	ld hl, wMachineDeckPtrs
	add hl, bc
	call SafelySwitchToSRAM1
	ld a, [hli]
	ld h, [hl]
	ld l, a
	push hl
	ld bc, DECK_NAME_SIZE
	add hl, bc
	ld d, h
	ld e, l
	ld a, [hl]
	pop hl
	call SafelySwitchToSRAM0
	or a
	jr z, .wait_input ; invalid deck

	; show confirmation list
	ld a, SFX_CONFIRM
	call PlaySFX
	call SafelySwitchToSRAM1
	call OpenDeckConfirmationMenu
	call SafelySwitchToSRAM0
.redraw_screen_and_restart_deck_selection
	ld a, [wTempCardListVisibleOffset]
	ld [wCardListVisibleOffset], a
	call .InitAutoDeckMenu
.restart_deck_selection
	ld a, [wTempDeckMachineCursorPos]
	jr .start_deck_selection

.deck_selection_made
	call DrawCursor2
	ld a, [wCardListVisibleOffset]
	ld [wTempCardListVisibleOffset], a
	ld a, [wCurMenuItem]
	ld [wTempDeckMachineCursorPos], a
	ldh a, [hCurMenuItem]
	cp -1
	jr z, .exit ; exit if the B button was pressed
	ld [wSelectedDeckMachineEntry], a
	ld a, 11
	ld [wCheckMenuCursorXPositionOffset], a
	call ResetCheckMenuCursorPositionAndBlink
	ld [wce5e], a ; 0
	call DrawWideTextBox
	ld hl, .DeckMachineMenuData
	call PlaceTextItems
.wait_submenu_input
	call DoFrame
	call HandleCheckMenuInput_YourOrOppPlayArea
	jr nc, .wait_submenu_input
	cp -1
	jr z, .restart_deck_selection ; loop back if the B button was pressed

	ld a, [wCheckMenuCursorYPosition]
	add a
	ld hl, wCheckMenuCursorXPosition
	add [hl]
	; a = 2 * cursor y position + cursor x position
	or a
	jr nz, .check_other_submenu_options

; Build a Deck
	call SafelySwitchToSRAM1
	call TryBuildDeckMachineDeck
	call SafelySwitchToSRAM0
	jr c, .redraw_screen_and_restart_deck_selection
	jr nc, .restart_deck_selection

.check_other_submenu_options
	dec a ; cp $1
	jr nz, .read_the_instructions
	; "Cancel" was selected
.exit
	xor a
	ld [wTempBankSRAM], a
	ret

.read_the_instructions
; show card confirmation list
	ld a, [wCardListVisibleOffset]
	ld [wTempCardListVisibleOffset], a
	ld b, a
	ld a, [wCurMenuItem]
	ld [wTempDeckMachineCursorPos], a
	add b
	ld [wCurDeck], a
	add a
	ld c, a
	ld b, $0
	ld hl, wMachineDeckPtrs
	add hl, bc

	; set the description text in text box
	push hl
	ld hl, wAutoDeckMachineTextDescriptions
	add hl, bc
	ld bc, wCardConfirmationText
	ld a, [hli]
	ld [bc], a
	inc bc
	ld a, [hl]
	ld [bc], a
	pop hl

	call SafelySwitchToSRAM1
	ld a, [hli]
	ld h, [hl]
	ld l, a
	push hl
	ld bc, DECK_NAME_SIZE
	add hl, bc
	ld d, h
	ld e, l
	ld a, [hl]
	pop hl
	call SafelySwitchToSRAM0
	or a
	jp z, .wait_input ; invalid deck

	; show confirmation list
	ld a, SFX_CONFIRM
	call PlaySFX
	call SafelySwitchToSRAM1
	call HandleDeckMissingCardsList
	call SafelySwitchToSRAM0
	jp .redraw_screen_and_restart_deck_selection

.MenuParameters
	db 1, 2 ; cursor x, cursor y
	db 2 ; y displacement between items
	db 5 ; number of items
	db SYM_CURSOR_R ; cursor tile number
	db SYM_SPACE ; tile behind cursor
	dw NULL ; function pointer if non-0

.DeckMachineMenuData
	textitem  2, 14, BuildThisDeckText
	textitem 13, 14, CancelText
	textitem  2, 16, ReadTheInstructionsText
	db $ff

.DeckMachineTitleTextList
	tx FightingMachineText
	tx RockMachineText
	tx WaterMachineText
	tx LightningMachineText
	tx GrassMachineText
	tx PsychicMachineText
	tx ScienceMachineText
	tx FireMachineText
	tx AutoMachineText
	tx LegendaryMachineText

; clears the screen, loads the proper tiles,
; prints the Auto Deck title and deck entries,
; and creates the auto deck configurations
; input:
;	[wDeckMachineTitleText] = text ID (2 bytes)
.InitAutoDeckMenu
	call Set_OBJ_8x8
	xor a ; SYM_SPACE
	ld [wTileMapFill], a
	call EmptyScreen
	call ZeroObjectPositionsAndToggleOAMCopy
	call LoadSymbolsFont
	call LoadDuelCardSymbolTiles
	call SetDefaultConsolePalettes
	lb de, $38, $ff
	call SetupText
	lb de, 0, 0
	lb bc, 20, 13
	call DrawRegularTextBox
	lb de, 1, 0
	ld hl, wDeckMachineTitleText
	ld a, [hli]
	ld h, [hl]
	ld l, a
	call InitTextPrinting_ProcessTextFromID
	call SafelySwitchToSRAM1
	farcall ReadAutoDeckConfiguration

; write to wMachineDeckPtrs the Auto Deck pointers in sAutoDecks
	ld a, 2 * NUM_DECK_MACHINE_SLOTS ; number of bytes that will be cleared
	ld hl, wMachineDeckPtrs
	call ClearMemory_Bank2
	ld de, wMachineDeckPtrs
	ld hl, sAutoDecks
	ld bc, DECK_STRUCT_SIZE
	ld a, NUM_DECK_MACHINE_SLOTS
.loop
	push af
	ld a, l
	ld [de], a
	inc de
	ld a, h
	ld [de], a
	inc de
	add hl, bc
	pop af
	dec a
	jr nz, .loop

	call PrintVisibleDeckMachineEntries
	call SafelySwitchToSRAM0
	jp EnableLCD


;----------------------------------------
;        UNREFERENCED FUNCTIONS
;----------------------------------------
;
; prints "X/Y", where X is the current list index
; and Y is the total number of saved decks
;Func_b568:
;	ld a, [wCardListCursorPos]
;	ld b, a
;	ld a, [wCardListVisibleOffset]
;	add b
;	inc a
;	ld hl, wDefaultText
;	call ConvertToNumericalDigits
;	ld a, TX_SYMBOL
;	ld [hli], a
;	ld a, SYM_SLASH
;	ld [hli], a
;	ld a, [wNumSavedDecks]
;	call ConvertToNumericalDigits
;	ld [hl], TX_END
;	lb de, 14, 1
;	ld hl, wDefaultText
;	jp InitTextPrinting_ProcessText
