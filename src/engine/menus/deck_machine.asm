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
	cp $05
	jr c, .got_num_positions
	ld a, $05
.got_num_positions
	ld [wCardListNumCursorPositions], a
	ld [wNumVisibleCardListEntries], a
	call .PrintTitleAndList
	ld hl, wCardConfirmationText
	ld a, [hli]
	ld h, [hl]
	ld l, a
	call DrawWideTextBox_PrintText

; set the card update function
	ld hl, .CardListUpdateFunction
	ld d, h
	ld a, l
	ld hl, wCardListUpdateFunction
	ld [hli], a
	ld [hl], d
	xor a
	ld [wced2], a

.loop_input
	call DoFrame
	call HandleDeckCardSelectionList
	jr c, .selection_made
	call HandleLeftRightInCardList
	jr c, .loop_input
	ldh a, [hDPadHeld]
	and START
	jr z, .loop_input

.open_card_pge
	ld a, $1
	call PlaySFXConfirmOrCancel_Bank2
	ld a, [wCardListCursorPos]
	ld [wced7], a

	; set wOwnedCardsCountList as the current card list
	; and then show the card page screen
	ld de, wOwnedCardsCountList
	ld hl, wCurCardListPtr
	ld [hl], e
	inc hl
	ld [hl], d
	call OpenCardPageFromCardList
	jr .loop

.selection_made
	ldh a, [hffb3]
	cp $ff
	ret z
	jr .open_card_pge

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

.PrintTitleAndList
	call .ClearScreenAndPrintDeckTitle
	lb de, 3, 3
	ld hl, wCardListCoords
	ld [hl], e
	inc hl
	ld [hl], d
	jp PrintConfirmationCardList

.ClearScreenAndPrintDeckTitle
	call EmptyScreenAndLoadFontDuelAndDeckIcons
	call .PrintDeckIndexAndName
	jp EnableLCD

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
	ld a, TX_FULLWIDTH3
	ld [hli], a
	ld [hl], $7b ; Period
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
	ldtx de, DeckSaveMachineText
	ld hl, wDeckMachineTitleText
	ld [hl], e
	inc hl
	ld [hl], d
	call ClearScreenAndDrawDeckMachineScreen
	ld a, NUM_DECK_SAVE_MACHINE_SLOTS
	ld [wNumDeckMachineEntries], a

	xor a
.wait_input
	ld hl, DeckMachineSelectionParams
	call InitCardSelectionParams
	call DrawListScrollArrows
	call PrintNumSavedDecks
	ldtx hl, PleaseSelectDeckText
	call DrawWideTextBox_PrintText
	ldtx de, PleaseSelectDeckText
	call InitDeckMachineDrawingParams
	call HandleDeckMachineSelection
	jr c, .wait_input
	cp $ff
	ret z ; operation cancelled
	; get the index of the selected deck
	ld b, a
	ld a, [wCardListVisibleOffset]
	add b
	ld [wSelectedDeckMachineEntry], a

	call ResetCheckMenuCursorPositionAndBlink
	call DrawWideTextBox
	ld hl, .DeckMachineMenuData
	call PlaceTextItems
.wait_input_submenu
	call DoFrame
	call HandleCheckMenuInput
	jr nc, .wait_input_submenu
	cp $ff
	jr nz, .submenu_option_selected
	; return from submenu
	ld a, [wTempDeckMachineCursorPos]
	jr .wait_input

.submenu_option_selected
	ld a, [wCheckMenuCursorYPosition]
	sla a
	ld hl, wCheckMenuCursorXPosition
	add [hl]
	or a
	jr nz, .ok_1

; Save a Deck
	call CheckIfSelectedDeckMachineEntryIsEmpty
	jr nc, .prompt_ok_if_deleted
	call SaveDeckInDeckSaveMachine
	ld a, [wTempDeckMachineCursorPos]
	jr c, .wait_input
	jr .return_to_list
.prompt_ok_if_deleted
	ldtx hl, OKIfFileDeletedText
	call YesOrNoMenuWithText
	ld a, [wTempDeckMachineCursorPos]
	jr c, .wait_input
	call SaveDeckInDeckSaveMachine
	ld a, [wTempDeckMachineCursorPos]
	jr c, .wait_input
	jr .return_to_list

.ok_1
	cp $1
	jr nz, .ok_2

; Delete a Deck
	call CheckIfSelectedDeckMachineEntryIsEmpty
	jr c, .is_empty
	call TryDeleteSavedDeck
	ld a, [wTempDeckMachineCursorPos]
	jp c, .wait_input
	jr .return_to_list

; Empty Deck
.is_empty
	ldtx hl, NoDeckIsSavedText
	call DrawWideTextBox_WaitForInput
	ld a, [wTempDeckMachineCursorPos]
	jp .wait_input

.ok_2
	cp $2
	ret nz ; cancel

; Build a Deck
	call CheckIfSelectedDeckMachineEntryIsEmpty
	jr c, .is_empty
	call TryBuildDeckMachineDeck
	ld a, [wTempDeckMachineCursorPos]
	jp nc, .wait_input

.return_to_list
	ld a, [wTempCardListVisibleOffset]
	ld [wCardListVisibleOffset], a
	call ClearScreenAndDrawDeckMachineScreen
	call DrawListScrollArrows
	call PrintNumSavedDecks
	ld a, [wTempDeckMachineCursorPos]
	jp .wait_input

.DeckMachineMenuData
	textitem  2, 14, SaveADeckText
	textitem 12, 14, DeleteADeckText
	textitem  2, 16, BuildADeckText
	textitem 12, 16, CancelText
	db $ff


; sets the number of cursor positions for the deck machine menu, sets the ID
; for the text to print, and sets DrawDeckMachineScreen as the update function
; preserves bc
; input:
;	de = text ID
InitDeckMachineDrawingParams:
	ld a, NUM_DECK_MACHINE_SLOTS
	ld [wCardListNumCursorPositions], a
	ld hl, wDeckMachineText
	ld [hl], e
	inc hl
	ld [hl], d
	ld hl, DrawDeckMachineScreen
	ld d, h
	ld a, l
	ld hl, wCardListUpdateFunction
	ld [hli], a
	ld [hl], d
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
	and START
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
	ld a, $1
	call PlaySFXConfirmOrCancel_Bank2
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
	cp D_RIGHT
	jr z, .d_right
	cp D_LEFT
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
	sla a
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
	xor a
	ld [wTileMapFill], a
	call ZeroObjectPositions
	call EmptyScreen
	ld a, $01
	ld [wVBlankOAMCopyToggle], a
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
;	a = wMachineDeckPtrs index
;	de = screen coordinates for printing the text
; output:
;	carry = set:  if the deck from input is not valid, i.e. it has no cards
PrintDeckMachineEntry:
	ld b, a
	push bc
	ld hl, wDefaultText
	inc a
	call ConvertToNumericalDigits
	ld a, TX_FULLWIDTH3
	ld [hli], a
	ld [hl], $7b ; Period
	inc hl
	ld [hl], TX_END
	ld hl, wDefaultText
	call InitTextPrinting_ProcessText
	pop af

; get the deck corresponding to the index from input
; and append its name to wDefaultText
	push af
	sla a
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
	ld a, $0 ; no decks dismantled
	call CheckIfCanBuildSavedDeck
	pop bc
	ld hl, wDefaultText
	jr c, .cannot_build
	lb de, TX_FULLWIDTH3, "FW3_○" ; can build
	; fallthrough

.asm_b4c2
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
	lb de, TX_FULLWIDTH3, "FW3_※" ; can build by dismantling
	jr .asm_b4c2

.cannot_build_at_all
	lb de, TX_FULLWIDTH0, "FW0_×" ; cannot build even by dismantling
	call Func_22ca
	pop bc
	pop de

; place in wDefaultText the number of cards
; that are needed in order to build the deck
	push bc
	ld d, 17
	inc e
	call InitTextPrinting
	pop bc
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
;	b = index for wMachineDeckPtrs
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
	lb bc, 0, 0
.loop
	inc b
	ld a, DECK_SIZE
	cp b
	jr c, .done
	ld a, [hli]
	push hl
	ld l, a
	ld h, $00
	add hl, de
	ld a, [hl]
	and CARD_COUNT_MASK
	or a
	jr z, .none
	dec a
	ld [hl], a
	pop hl
	jr .loop
.none
	inc c
	pop hl
	jr .loop
.done
	ld a, c
	jp DisableSRAM


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
	dec d
	jr z, .got_count
	add hl, bc
	jr .loop
.got_count
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
.wait_input
	ld hl, DeckSelectionMenuParameters
	call InitializeMenuParameters
	ldtx hl, ChooseADeckToSaveText
	call DrawWideTextBox_PrintText
.wait_submenu_input
	call DoFrame
	call HandleStartButtonInDeckSelectionMenu
	jr c, .wait_input
	call HandleMenuInput
	jr nc, .wait_submenu_input
	ldh a, [hCurMenuItem]
	cp $ff
	ret z ; operation cancelled
	ld [wCurDeck], a
	call CheckIfCurDeckIsValid
	jr nc, .SaveDeckInSelectedEntry
	; is an empty deck
	call PrintThereIsNoDeckHereText
	ld a, [wCurDeck]
	jr .wait_input

; overwrites data in the selected deck in SRAM
; with the deck that was chosen, in wCurDeck
; output:
;	carry = set
.SaveDeckInSelectedEntry
	call GetPointerToDeckName
	call GetSelectedSavedDeckPtr
	ld b, DECK_STRUCT_SIZE
	call EnableSRAM
	call CopyNBytesFromHLToDE
	call DisableSRAM

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
	sla a
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


; checks if it's possible to build saved deck with index b
; includes cards from already built decks from flags in a
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
	ld b, 0
.loop
	inc b
	ld a, DECK_SIZE
	cp b
	jr c, .no_carry
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
	dec a
	ld [hl], a
	pop hl
	jr .loop

.set_carry
	pop hl
	scf
	jp DisableSRAM

.no_carry
	or a
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
	jr nz, .check_deck_2
	xor a
	ret

.check_deck_2
	ld hl, sDeck2Cards
	ld a, [hl]
	or a
	jr nz, .check_deck_3
	ld a, 1
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
	jr c, .no
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
	call DrawWideTextBox_WaitForInput
	or a
	ret

.no
	ld a, [wCardListCursorPos]
	scf
	ret


; preserves de and hl
DrawListScrollArrows:
	ld a, [wCardListVisibleOffset]
	or a
	jr z, .no_up_cursor
	ld a, SYM_CURSOR_U
	jr .got_tile_1
.no_up_cursor
	ld a, SYM_BOX_RIGHT
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
.init_menu_params
	ld hl, DeckSelectionMenuParameters
	call InitializeMenuParameters
	ldtx hl, ChooseADeckToDismantleText
	call DrawWideTextBox_PrintText
.loop_input
	call DoFrame
	call HandleStartButtonInDeckSelectionMenu
	jr c, .init_menu_params
	call HandleMenuInput
	jr nc, .loop_input
	ldh a, [hCurMenuItem]
	cp $ff
	jr nz, .selected_deck
	; operation was cancelled
	call SafelySwitchToTempSRAMBank
	scf
	ret

.selected_deck
	ld [wCurDeck], a
	ldtx hl, DismantleThisDeckText
	call YesOrNoMenuWithText
	jr nc, .dismantle
	ld a, [wCurDeck]
	jr .init_menu_params

.dismantle
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
	ld a, $0
	call CheckIfCanBuildSavedDeck
	pop bc
	jr nc, .build_deck
	ld a, ALL_DECKS
	call CheckIfCanBuildSavedDeck
	jr c, .do_not_own_all_cards_needed
	; can only be built by dismantling some deck
	ldtx hl, ThisDeckCanOnlyBeBuiltIfYouDismantleText
	call DrawWideTextBox_WaitForInput
	call .DismantleDecksNeededToBuild
	jr nc, .build_deck
	; player chose not to dismantle

.set_carry_and_return
	ld a, [wCardListCursorPos]
	scf
	ret

.do_not_own_all_cards_needed
	ldtx hl, YouDoNotOwnAllCardsNeededToBuildThisDeckText
	call DrawWideTextBox_WaitForInput
	jp .ShowMissingCardList

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
	ld c, a
	ld b, $0
	sla c
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
; shows Decks screen with the names
; of the decks to be dismantled
	call CheckWhichDecksToDismantleToBuildSavedDeck
	call SafelySwitchToSRAM0
	call DrawDecksScreen
	ldtx hl, DismantleTheseDecksText
	call YesOrNoMenuWithText
	jr nc, .yes
; no
	call SafelySwitchToTempSRAMBank
	scf
	ret

.yes
	call EnableSRAM
	ld a, [wDecksToBeDismantled]
	bit DECK_1_F, a
	jr z, .deck_2
	ld a, DECK_1_F
	call .DismantleDeck
.deck_2
	ld a, [wDecksToBeDismantled]
	bit DECK_2_F, a
	jr z, .deck_3
	ld a, DECK_2_F
	call .DismantleDeck
.deck_3
	ld a, [wDecksToBeDismantled]
	bit DECK_3_F, a
	jr z, .deck_4
	ld a, DECK_3_F
	call .DismantleDeck
.deck_4
	ld a, [wDecksToBeDismantled]
	bit DECK_4_F, a
	jr z, .done_dismantling
	ld a, DECK_4_F
	call .DismantleDeck

.done_dismantling
	call DisableSRAM
	ld a, [wDecksToBeDismantled]
	call DrawDecksScreen
	call SafelySwitchToTempSRAMBank
	ldtx hl, DismantledTheDeckText
	call DrawWideTextBox_WaitForInput
	or a
	ret

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

; collects cards missing from the player's collection
; and shows its confirmation list
; output:
;	carry = set
.ShowMissingCardList
; copy saved deck card from SRAM to wCurDeckCards
; and make unique card list sorted by ID
	ld a, [wSelectedDeckMachineEntry]
	ld [wCurDeck], a
	call GetSelectedSavedDeckPtr
	ld hl, DECK_NAME_SIZE
	add hl, de
	ld de, wCurDeckCards
	ld b, DECK_SIZE
	call EnableSRAM
	call CopyNBytesFromHLToDE
	call DisableSRAM
	xor a ; terminator byte for deck
	ld [wCurDeckCards + DECK_SIZE], a
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
;	push bc
	push de
	push hl
	ld hl, wCurDeckCards
	call .CheckIfCardIsMissing
	pop hl
	pop de
;	pop bc
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

	ldtx bc, TheseCardsAreNeededToBuildThisDeckText
	ld hl, wCardConfirmationText
	ld a, c
	ld [hli], a
	ld a, b
	ld [hl], a

	call GetSelectedSavedDeckPtr
	ld h, d
	ld l, e
	ld de, wFilteredCardList
	call HandleDeckMissingCardsList
	jp .set_carry_and_return


; checks if player has enough cards with ID given in register a
; in the collection to build the deck, and if not,
; sets the carry flag and outputs in a the difference
; preserves bc
; input:
;	a = card ID
;	hl = list of deck cards (e.g. wCurDeckCards)
; output:
;	a = number of cards needed to build the deck (only if cannot build)
;	carry = set:  if the player doesn't have enough cards to build the deck
.CheckIfCardIsMissing
	call .GetCardCountFromDeck
	ld hl, wTempCardCollection
	push de
	call .GetCardCountFromCollection
	ld a, e
	pop de

	; d = card count in deck
	; a = card count in collection
	cp d
	jr c, .not_enough
	or a
	ret

; needs more cards than the player has in their in collection
; return with carry set and the number of cards needed in a
.not_enough
	ld e, a
	ld a, d
	sub e
	scf
	ret

; preserves af and bc
; input:
;	a = card ID
;	hl = list of deck cards (e.g. wCurDeckCards)
; output:
;	d = how many cards with ID from input are in the deck from input
.GetCardCountFromDeck
	push af
	ld e, a
	ld d, 0
.loop_deck_cards
	ld a, [hli]
	or a
	jr z, .done_deck_cards
	cp e
	jr nz, .loop_deck_cards
	inc d
	jr .loop_deck_cards
.done_deck_cards
	pop af
	ret

; preserves af and bc
; input:
;	a = card ID
;	hl = card collection
; output:
;	e = how many cards with ID from input are in the player's collection
.GetCardCountFromCollection
	push af
	ld e, a
	ld d, $0
	add hl, de
	ld a, [hl]
	and CARD_COUNT_MASK
	ld e, a
	pop af
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
	sla a ; next deck
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

; finally check if can be built by dismantling all decks
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
	sla a
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

.please_select_deck
	ld hl, .MenuParameters
	call InitializeMenuParameters
	ldtx hl, PleaseSelectDeckText
	call DrawWideTextBox_PrintText
	ld a, NUM_DECK_MACHINE_SLOTS
	ld [wCardListNumCursorPositions], a
	ld hl, UpdateDeckMachineScrollArrowsAndEntries
	ld d, h
	ld a, l
	ld hl, wCardListUpdateFunction
	ld [hli], a
	ld [hl], d
.wait_input
	call DoFrame
	call HandleMenuInput
	jr c, .deck_selection_made

	; the following lines do nothing
;	ldh a, [hDPadHeld]
;	and D_UP | D_DOWN
;	jr z, .asm_ba4e
;.asm_ba4e

; check whether to show deck confirmation list
	ldh a, [hDPadHeld]
	and START
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
	ld a, $1
	call PlaySFXConfirmOrCancel_Bank2
	call SafelySwitchToSRAM1
	call OpenDeckConfirmationMenu
	call SafelySwitchToSRAM0
	ld a, [wTempCardListVisibleOffset]
	ld [wCardListVisibleOffset], a
	call .InitAutoDeckMenu
	ld a, [wTempDeckMachineCursorPos]
	jr .please_select_deck

.deck_selection_made
	call DrawCursor2
	ld a, [wCardListVisibleOffset]
	ld [wTempCardListVisibleOffset], a
	ld a, [wCurMenuItem]
	ld [wTempDeckMachineCursorPos], a
	ldh a, [hCurMenuItem]
	cp $ff
	jr z, .exit ; operation cancelled
	ld [wSelectedDeckMachineEntry], a
	call ResetCheckMenuCursorPositionAndBlink
	ld [wce5e], a ; 0
	call DrawWideTextBox
	ld hl, .DeckMachineMenuData
	call PlaceTextItems
.wait_submenu_input
	call DoFrame
	call HandleCheckMenuInput_YourOrOppPlayArea
	jr nc, .wait_submenu_input
	cp $ff
	jr nz, .submenu_option_selected
	ld a, [wTempDeckMachineCursorPos]
	jp .please_select_deck

.submenu_option_selected
	ld a, [wCheckMenuCursorYPosition]
	sla a
	ld hl, wCheckMenuCursorXPosition
	add [hl]
	or a
	jr nz, .asm_bb09

; Build a Deck
	call SafelySwitchToSRAM1
	call TryBuildDeckMachineDeck
	call SafelySwitchToSRAM0
	ld a, [wTempDeckMachineCursorPos]
	jp nc, .please_select_deck
	ld a, [wTempCardListVisibleOffset]
	ld [wCardListVisibleOffset], a
	call .InitAutoDeckMenu
	ld a, [wTempDeckMachineCursorPos]
	jp .please_select_deck

.asm_bb09
	cp $1
	jr nz, .read_the_instructions
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
	ld c, a
	ld [wCurDeck], a
	sla c
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
	ld a, $1
	call PlaySFXConfirmOrCancel_Bank2
	call SafelySwitchToSRAM1
	xor a
	call HandleDeckMissingCardsList
	call SafelySwitchToSRAM0
	ld a, [wTempCardListVisibleOffset]
	ld [wCardListVisibleOffset], a
	call .InitAutoDeckMenu
	ld a, [wTempDeckMachineCursorPos]
	jp .please_select_deck

.MenuParameters
	db 1, 2 ; cursor x, cursor y
	db 2 ; y displacement between items
	db 5 ; number of items
	db SYM_CURSOR_R ; cursor tile number
	db SYM_SPACE ; tile behind cursor
	dw NULL ; function pointer if non-0

.DeckMachineMenuData
	textitem  2, 14, BuildADeckText
	textitem 12, 14, CancelText
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
	xor a
	ld [wTileMapFill], a
	call ZeroObjectPositions
	call EmptyScreen
	ld a, $01
	ld [wVBlankOAMCopyToggle], a
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
	call .CreateAutoDeckPointerList
	call PrintVisibleDeckMachineEntries
	call SafelySwitchToSRAM0
	jp EnableLCD

; writes to wMachineDeckPtrs the pointers
; to the Auto Decks in sAutoDecks
.CreateAutoDeckPointerList
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
	ret


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
