HandleGiftCenter::
	ld a, [wGiftCenterChoice]
	and $3
	ld hl, .GiftCenterFunctionTable
	call JumpToFunctionInTable
	jr c, .exit
	or a
	jr nz, .exit
	; a = $00
	ld [wTxRam2 + 0], a
	ld [wTxRam2 + 1], a
	ret
.exit
	ld a, -1
	ld [wGiftCenterChoice], a
	ret

.GiftCenterFunctionTable
	dw GiftCenter_SendCard    ; GIFT_CENTER_MENU_SEND_CARD
	dw GiftCenter_ReceiveCard ; GIFT_CENTER_MENU_RECEIVE_CARD
	dw GiftCenter_SendDeck    ; GIFT_CENTER_MENU_SEND_DECK
	dw GiftCenter_ReceiveDeck ; GIFT_CENTER_MENU_RECEIVE_DECK


; output:
;	carry = set:  if a connection error occurred and the Player chose to quit
GiftCenter_SendCard:
	xor a ; SYM_SPACE
	ld [wTileMapFill], a
	call EmptyScreen
	call ZeroObjectPositionsAndToggleOAMCopy
	call LoadSymbolsFont
	call SetDefaultConsolePalettes

	lb de, $38, $bf
	call SetupText
	lb de, 3, 1
	ldtx hl, ProceduresForSendingCardsText
	call InitTextPrinting_ProcessTextFromID
	lb de, 1, 3
	ldtx hl, CardSendingProceduresText
	ld a, SINGLE_SPACED
	ld [wLineSeparation], a
	call InitTextPrinting_ProcessTextFromID
	xor a ; DOUBLE_SPACED
	ld [wLineSeparation], a
	ldtx hl, PleaseReadTheProceduresForSendingCardsText
	call DrawWideTextBox_WaitForInput

	call EnableLCD
	call PrepareToBuildDeckConfigurationToSend
	jr c, .send
	ld a, $01
	or a
	ret

.send
	ld hl, wCurDeckCards
	ld de, wDuelTempList
	call CopyListFromHLToDE
	xor a
	ld [wNameBuffer], a
	farcall SendCard
	ret c
	call EnableSRAM
	ld hl, wCurDeckCards
	call DecrementDeckCardsInCollection
	call DisableSRAM
	call SaveGame
	ld hl, wNameBuffer
	ld de, wDefaultText
	call CopyListFromHLToDE
	xor a
	ret


; output:
;	carry = set:  if a connection error occurred and the Player chose to quit
GiftCenter_ReceiveCard:
	xor a
	ld [wDuelTempList], a
	ld [wNameBuffer], a
	farcall ReceiveCard
	ret c

	call EnableSRAM
	ld hl, wDuelTempList
	call AddGiftCenterDeckCardsToCollection
	call DisableSRAM
	call SaveGame
	xor a
	ld [wCardListVisibleOffset], a
	ld hl, GiftCenterCardSelectionParams
	call InitCardSelectionParams
	call PrintReceivedTheseCardsText
	call PrintFilteredCardList_UseDuelTempList
	call EnableLCD
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
	ld a, LOW(ShowReceivedCardsList)
	ld [hli], a
	ld [hl], HIGH(ShowReceivedCardsList)
	xor a
	ld [wced2], a

.wait_input
	call DoFrame
	call HandleDeckCardSelectionList
	jr c, .selection_made
	call HandleLeftRightInCardList
	jr c, .wait_input
	ldh a, [hDPadHeld]
	and PAD_START
	jr z, .wait_input
	; START button was pressed

.open_card_page
	ld a, SFX_CONFIRM
	call PlaySFX
	ld a, [wCardListCursorPos]
	ld [wTempCardListCursorPos], a
	ld de, wFilteredCardList
	call OpenCardPageFromCardList
	; return to card list
	call PrintReceivedTheseCardsText
	call PrintCardSelectionList
	call EnableLCD
	ld hl, GiftCenterCardSelectionParams
	call InitCardSelectionParams
	ld a, [wNumEntriesInCurFilter]
	ld hl, wNumVisibleCardListEntries
	cp [hl]
	jr nc, .enough_entries_2
	; total number of entries is less than the number of visible entries,
	; so set the number of cursor positions to the list size.
	ld [wCardListNumCursorPositions], a
.enough_entries_2
	ld a, [wTempCardListCursorPos]
	ld [wCardListCursorPos], a
	jr .wait_input

.selection_made
	call DrawListCursor_Invisible
	ld a, [wCardListCursorPos]
	ld [wTempCardListCursorPos], a
	ldh a, [hffb3]
	inc a ; cp -1
	jr nz, .open_card_page ; jump if B button wasn't pressed (i.e. pressed A button)
	; B button was pressed
	ld hl, wNameBuffer
	ld de, wDefaultText
	call CopyListFromHLToDE
	or a
	ret

GiftCenterCardSelectionParams:
	db 1 ; x position
	db 3 ; y position
	db 2 ; y spacing
	db 0 ; x spacing
	db 5 ; number of entries
	db SYM_CURSOR_R ; visible cursor tile
	db SYM_SPACE ; invisible cursor tile
	dw NULL ; wCardListHandlerFunction


; output:
;	carry = set:  if a connection error occurred and the Player chose to quit
GiftCenter_SendDeck:
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
	ldtx hl, PleaseChooseADeckConfigurationToSendText
	call DrawWideTextBox_PrintText
	ldtx de, PleaseChooseADeckConfigurationToSendText
	call InitDeckMachineDrawingParams
.wait_input
	call HandleDeckMachineSelection
	jr c, .start_selection
	cp -1
	jr nz, .selection_made
	; B button was pressed
	ld a, $01
	or a
	ret
.selection_made
	ld b, a
	ld a, [wCardListVisibleOffset]
	add b
	ld [wSelectedDeckMachineEntry], a
	call CheckIfSelectedDeckMachineEntryIsEmpty
	jr c, .wait_input

	call GetSelectedSavedDeckPtr
	ld l, e
	ld h, d
	ld de, wDuelTempList
	ld b, DECK_STRUCT_SIZE
	call CopyNBytesFromHLToDEInSRAM

	xor a
	ld [wNameBuffer], a
	farcall SendDeckConfiguration
	ret c

	call GetSelectedSavedDeckPtr
	ld l, e
	ld h, d
	ld de, wDefaultText
;	fallthrough

; copies a $00-terminated list from hl to de
; preserves bc
; input:
;	hl = list to copy
;	de = where to copy
CopyListFromHLToDEInSRAM:
	call EnableSRAM
	call CopyListFromHLToDE
	jp DisableSRAM


; output:
;	carry = set:  if a connection error occurred and the Player chose to quit
GiftCenter_ReceiveDeck:
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
	ldtx hl, PleaseChooseASaveSlotText
	call DrawWideTextBox_PrintText
	ldtx de, PleaseChooseASaveSlotText
	call InitDeckMachineDrawingParams
	call HandleDeckMachineSelection
	jr c, .start_selection
	cp -1
	jr nz, .selection_made
	ld a, $01
	or a
	ret
.ask_to_delete
	ldtx hl, OKIfFileDeletedText
	call YesOrNoMenuWithText
	jr nc, .save_new_configuration ; proceed if the Player chose to delete the selected entry
	; otherwise, return to the selection process
	ld a, [wCardListCursorPos]
	jr .start_selection
.selection_made
	ld b, a
	ld a, [wCardListVisibleOffset]
	add b
	ld [wSelectedDeckMachineEntry], a
	call CheckIfSelectedDeckMachineEntryIsEmpty
	jr nc, .ask_to_delete
.save_new_configuration
	xor a
	ld [wDuelTempList], a
	ld [wNameBuffer], a
	farcall ReceiveDeckConfiguration
	ret c
	call EnableSRAM
	ld hl, wDuelTempList
	call GetSelectedSavedDeckPtr
	ld b, DECK_STRUCT_SIZE
	call CopyNBytesFromHLToDE
	call DisableSRAM
	call SaveGame
	call ClearScreenAndDrawDeckMachineScreen
	ld a, [wCardListCursorPos]
	ld hl, DeckMachineSelectionParams
	call InitCardSelectionParams
	call DrawListScrollArrows
	call PrintNumSavedDecks
	call DrawListCursor_Visible
	ld hl, wNameBuffer
	ld de, wDefaultText
	call CopyListFromHLToDE
	; zero wTxRam2 so that the name just loaded to wDefaultText is printed
	ld hl, wTxRam2
	xor a
	ld [hli], a
	ld [hl], a
	ldtx hl, ReceivedADeckConfigurationFromText
	call DrawWideTextBox_WaitForInput
	call GetSelectedSavedDeckPtr
	ld l, e
	ld h, d
	ld de, wDefaultText
	call CopyListFromHLToDEInSRAM
	xor a
	ret


; initializes WRAM variables to start creating a deck configuration to send
; output:
;	carry = set:  if the Player decided to send a deck configuration
PrepareToBuildDeckConfigurationToSend:
	ld hl, wCurDeckCards
	ld a, wCurDeckCardsEnd - wCurDeckCards ; number of bytes that will be cleared
	call ClearMemory_Bank2
	ld a, -1
	ld [wCurDeck], a
	ld hl, .text
	ld de, wCurDeckName
	call CopyListFromHLToDE
	ld hl, .DeckConfigurationParams
	call InitDeckBuildingParams
	jp HandleDeckBuildScreen

.text
	text "Cards chosen to send"
	done

.DeckConfigurationParams
	db DECK_SIZE ; max number of cards
	db 60 ; max number of same name cards
	db FALSE ; whether to include deck cards
	dw HandleSendDeckConfigurationMenu
	dw SendDeckConfigurationMenu_TransitionTable

; related to wMenuInputTablePointer
; with this table, the cursor moves into the proper location based on the input.
; x coordinate, y coordinate, , D-pad up, D-pad down, D-pad right, D-pad left
SendDeckConfigurationMenu_TransitionTable:
	cursor_transition $10, $20, $00, $00, $00, $01, $02 ; Confirm
	cursor_transition $48, $20, $00, $01, $01, $02, $00 ; Send
	cursor_transition $80, $20, $00, $02, $02, $00, $01 ; Cancel

SendDeckConfigurationMenuData:
	textitem  2, 2, ConfirmText
	textitem  9, 2, SendText
	textitem 16, 2, CancelText
	db $ff

; this function is loaded to wDeckConfigurationMenuHandlerFunction
; during PrepareToBuildDeckConfigurationToSend.
HandleSendDeckConfigurationMenu:
	lb de, 0, 0
	lb bc, 20, 6
	call DrawRegularTextBox
	ld hl, SendDeckConfigurationMenuData
	call PlaceTextItems
	ld a, $ff
	ld [wDuelInitialPrizesUpperBitsSet], a
.wait_input
	ld a, $01
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
	ld a, [wTempFilteredCardListNumCursorPositions]
	jp HandleDeckBuildScreen.start_list_selection

.selection_made
	ld hl, .func_table
	call JumpToFunctionInTable
	jp OpenDeckConfigurationMenu.skip_init

.func_table
	dw .ConfirmDeckConfiguration    ; Confirm
	dw .SendDeckConfiguration       ; Send
	dw .CancelSendDeckConfiguration ; Cancel

.ConfirmDeckConfiguration:
	ld hl, wCardListVisibleOffset
	ld a, [hl]
	ld hl, wCardListVisibleOffsetBackup
	ld [hl], a
	call HandleDeckConfirmationMenu
	call ClearBackground
	call Set_OBJ_8x8
	ld hl, wCardListVisibleOffsetBackup
	ld a, [hl]
	ld hl, wCardListVisibleOffset
	ld [hl], a
	ld a, [wCurCardTypeFilter]
	call PrintFilteredCardList
	ld a, [wced6]
	ld [wCardListCursorPos], a
	ret

.SendDeckConfiguration
	ld a, [wCurDeckCards]
	or a
	jr z, .CancelSendDeckConfiguration
	xor a
	ld [wCardListVisibleOffset], a
	ld hl, GiftCenterCardSelectionParams
	call InitCardSelectionParams
	ld hl, wCurDeckCards
	ld de, wDuelTempList
	call CopyListFromHLToDE
	call PrintCardToSendText
	call PrintFilteredCardList_UseDuelTempList
	call EnableLCD
	ldtx hl, SendTheseCardsText
	call YesOrNoMenuWithText
	jr nc, .send ; jump if the Player selected "Yes"
	; Player selected "No"
	add sp, $2
	jp HandleDeckBuildScreen.skip_count
.send
	add sp, $2
	scf
	ret

.CancelSendDeckConfiguration
	add sp, $2
	or a
	ret


ShowReceivedCardsList:
	ld hl, hffb0
	ld [hl], $01
	lb de, 1, 1
	ldtx hl, CardReceivedText
	call InitTextPrinting_ProcessTextFromID
	ld hl, wNameBuffer
	ld de, wDefaultText
	call CopyListFromHLToDE
	; zero wTxRam2 so that the name just loaded to wDefaultText is printed
	ld hl, wTxRam2
	xor a
	ld [hli], a
	ld [hl], a
	lb de, 1, 14
	ldtx hl, ReceivedTheseCardsFromText
	call InitTextPrinting_PrintTextNoDelay
	ld hl, hffb0
	ld [hl], $00
	jp PrintCardSelectionList


PrintFilteredCardList_UseDuelTempList:
	ld a, CARD_COLLECTION_SIZE - 1 ; number of bytes that will be cleared
	ld hl, wTempCardCollection
	call ClearMemory_Bank2
	; add cards in wDuelTempList to wTempCardCollection
	ld de, wDuelTempList
	ld bc, wTempCardCollection
.loop
	ld a, [de]
	inc de
	or a
	jr z, .create_list
	ld h, $00
	ld l, a
	add hl, bc
	inc [hl]
	jr .loop
.create_list
	ld a, $ff
	call CreateFilteredCardList
	ld a, $05
	ld [wNumVisibleCardListEntries], a
	ld hl, wCardListCoords
	ld a, 3 ; initial y coordinate
	ld [hli], a
	ld [hl], 2 ; initial x coordinate
	ld a, SYM_BOX_RIGHT
	ld [wCursorAlternateTile], a
	jp PrintCardSelectionList


PrintCardToSendText:
	call EmptyScreenAndDrawTextBox
	lb de, 1, 1
	ldtx hl, CardToSendText
	jp InitTextPrinting_ProcessTextFromID


PrintReceivedTheseCardsText:
	call EmptyScreenAndDrawTextBox
	lb de, 1, 1
	ldtx hl, CardReceivedText
	call InitTextPrinting_ProcessTextFromID
	ld hl, wNameBuffer
	ld de, wDefaultText
	call CopyListFromHLToDE
	; zero wTxRam2 so that the name just loaded to wDefaultText is printed
	ld hl, wTxRam2
	xor a
	ld [hli], a
	ld [hl], a
	ldtx hl, ReceivedTheseCardsFromText
	jp DrawWideTextBox_PrintText


EmptyScreenAndDrawTextBox:
	call Set_OBJ_8x8
	call EmptyScreenAndLoadFontDuelAndDeckIcons
	lb de, 0, 0
	lb bc, 20, 13
	jp DrawRegularTextBox
