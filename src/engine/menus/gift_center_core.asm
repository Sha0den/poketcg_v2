HandleGiftCenter::
	ld a, [wGiftCenterChoice]
	and $3
	ld hl, .GiftCenterFunctionTable
	call JumpToFunctionInTable
	jr c, .asm_b18f
	or a
	jr nz, .asm_b18f
	; a = $00
	ld [wTxRam2 + 0], a
	ld [wTxRam2 + 1], a
	ret
.asm_b18f
	ld a, -1
	ld [wGiftCenterChoice], a
	ret

.GiftCenterFunctionTable
	dw GiftCenter_SendCard    ; GIFT_CENTER_MENU_SEND_CARD
	dw GiftCenter_ReceiveCard ; GIFT_CENTER_MENU_RECEIVE_CARD
	dw GiftCenter_SendDeck    ; GIFT_CENTER_MENU_SEND_DECK
	dw GiftCenter_ReceiveDeck ; GIFT_CENTER_MENU_RECEIVE_DECK


GiftCenter_SendCard:
	xor a
	ld [wTileMapFill], a
	call ZeroObjectPositions
	call EmptyScreen
	ld a, $1
	ld [wVBlankOAMCopyToggle], a
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
	jr c, .asm_af6b
	ld a, $01
	or a
	ret

.asm_af6b
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
	ld hl, Data_b04a
	call InitCardSelectionParams
	call PrintReceivedTheseCardsText
	call Func_b088
	call EnableLCD
	ld a, [wNumEntriesInCurFilter]
	ld [wNumCardListEntries], a
	ld hl, wNumVisibleCardListEntries
	cp [hl]
	jr nc, .asm_afd4
	ld [wCardListNumCursorPositions], a
.asm_afd4
	ld hl, wCardListUpdateFunction
	ld a, LOW(ShowReceivedCardsList)
	ld [hli], a
	ld a, HIGH(ShowReceivedCardsList)
	ld [hl], a

	xor a
	ld [wced2], a
.asm_afe2
	call DoFrame
	call HandleDeckCardSelectionList
	jr c, .asm_b02f
	call HandleLeftRightInCardList
	jr c, .asm_afe2
	ldh a, [hDPadHeld]
	and START
	jr z, .asm_afe2
.asm_aff5
	ld a, $1
	call PlaySFXConfirmOrCancel_Bank2
	ld a, [wCardListCursorPos]
	ld [wTempCardListCursorPos], a

	; set wFilteredCardList as the current card list
	; and then show the card page screen
	ld de, wFilteredCardList
	ld hl, wCurCardListPtr
	ld [hl], e
	inc hl
	ld [hl], d
	call OpenCardPageFromCardList
	call PrintReceivedTheseCardsText

	call PrintCardSelectionList
	call EnableLCD
	ld hl, Data_b04a
	call InitCardSelectionParams
	ld a, [wNumEntriesInCurFilter]
	ld hl, wNumVisibleCardListEntries
	cp [hl]
	jr nc, .asm_b027
	ld [wCardListNumCursorPositions], a
.asm_b027
	ld a, [wTempCardListCursorPos]
	ld [wCardListCursorPos], a
	jr .asm_afe2
.asm_b02f
	call DrawListCursor_Invisible
	ld a, [wCardListCursorPos]
	ld [wTempCardListCursorPos], a
	ldh a, [hffb3]
	cp -1
	jr nz, .asm_aff5
	ld hl, wNameBuffer
	ld de, wDefaultText
	call CopyListFromHLToDE
	or a
	ret

Data_b04a:
	db 1 ; x position
	db 3 ; y position
	db 2 ; y spacing
	db 0 ; x spacing
	db 5 ; number of entries
	db SYM_CURSOR_R ; visible cursor tile
	db SYM_SPACE ; invisible cursor tile
	dw NULL ; wCardListHandlerFunction


GiftCenter_SendDeck:
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
.asm_bc1a
	ld hl, DeckMachineSelectionParams
	call InitCardSelectionParams
	call DrawListScrollArrows
	call PrintNumSavedDecks
	ldtx hl, PleaseChooseADeckConfigurationToSendText
	call DrawWideTextBox_PrintText
	ldtx de, PleaseChooseADeckConfigurationToSendText
	call InitDeckMachineDrawingParams
.asm_bc32
	call HandleDeckMachineSelection
	jr c, .asm_bc1a
	cp -1
	jr nz, .asm_bc3f
	ld a, $01
	or a
	ret
.asm_bc3f
	ld b, a
	ld a, [wCardListVisibleOffset]
	add b
	ld [wSelectedDeckMachineEntry], a
	call CheckIfSelectedDeckMachineEntryIsEmpty
	jr c, .asm_bc32

	call GetSelectedSavedDeckPtr
	ld l, e
	ld h, d
	ld de, wDuelTempList
	ld b, DECK_STRUCT_SIZE
	call EnableSRAM
	call CopyNBytesFromHLToDE
	call DisableSRAM

	xor a
	ld [wNameBuffer], a
	farcall SendDeckConfiguration
	ret c

	call GetSelectedSavedDeckPtr
	ld l, e
	ld h, d
	ld de, wDefaultText
	call EnableSRAM
	call CopyListFromHLToDE
	or a
	jp DisableSRAM


GiftCenter_ReceiveDeck:
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
.asm_bc90
	ld hl, DeckMachineSelectionParams
	call InitCardSelectionParams
	call DrawListScrollArrows
	call PrintNumSavedDecks
	ldtx hl, PleaseChooseASaveSlotText
	call DrawWideTextBox_PrintText
	ldtx de, PleaseChooseASaveSlotText
	call InitDeckMachineDrawingParams
	call HandleDeckMachineSelection
	jr c, .asm_bc90
	cp -1
	jr nz, .asm_bcb5
	ld a, $01
	or a
	ret
.asm_bcc4
	ldtx hl, OKIfFileDeletedText
	call YesOrNoMenuWithText
	jr nc, .asm_bcd1
	ld a, [wCardListCursorPos]
	jr .asm_bc90
.asm_bcb5
	ld b, a
	ld a, [wCardListVisibleOffset]
	add b
	ld [wSelectedDeckMachineEntry], a
	call CheckIfSelectedDeckMachineEntryIsEmpty
	jr nc, .asm_bcc4
.asm_bcd1
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
	call EnableSRAM
	call CopyListFromHLToDE
	xor a
	jp DisableSRAM


; initializes WRAM variables to start creating a deck configuration to send
PrepareToBuildDeckConfigurationToSend:
	ld hl, wCurDeckCards
	ld a, wCurDeckCardsEnd - wCurDeckCards ; number of bytes that will be cleared
	call ClearMemory_Bank2
	ld a, $ff
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

HandleSendDeckConfigurationMenu:
	ld de, $0
	lb bc, 20, 6
	call DrawRegularTextBox
	ld hl, SendDeckConfigurationMenuData
	call PlaceTextItems
	ld a, $ff
	ld [wDuelInitialPrizesUpperBitsSet], a
.loop_input
	ld a, $01
	ld [wVBlankOAMCopyToggle], a
	call DoFrame
	call YourOrOppPlayAreaScreen_HandleInput
	jr nc, .loop_input
	ld [wced6], a
	cp $ff
	jr nz, .asm_a23b
	call DrawCardTypeIconsAndPrintCardCounts
	ld a, [wTempCardListCursorPos]
	ld [wCardListCursorPos], a
	ld a, [wCurCardTypeFilter]
	call PrintFilteredCardList
	jp HandleDeckBuildScreen.skip_draw
.asm_a23b
	ld hl, .func_table
	call JumpToFunctionInTable
	jp OpenDeckConfigurationMenu.skip_init

.func_table
	dw ConfirmDeckConfiguration     ; Confirm
	dw .SendDeckConfiguration       ; Send
	dw .CancelSendDeckConfiguration ; Cancel

.SendDeckConfiguration
	ld a, [wCurDeckCards]
	or a
	jr z, .CancelSendDeckConfiguration
	xor a
	ld [wCardListVisibleOffset], a
	ld hl, Data_b04a
	call InitCardSelectionParams
	ld hl, wCurDeckCards
	ld de, wDuelTempList
	call CopyListFromHLToDE
	call PrintCardToSendText
	call Func_b088
	call EnableLCD
	ldtx hl, SendTheseCardsText
	call YesOrNoMenuWithText
	jr nc, .asm_a279
	add sp, $2
	jp HandleDeckBuildScreen.skip_count
.asm_a279
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


Func_b088:
	ld a, CARD_COLLECTION_SIZE - 1 ; number of bytes that will be cleared
	ld hl, wTempCardCollection
	call ClearMemory_Bank2
	ld de, wDuelTempList
	call .Func_b0b2
	ld a, $ff
	call .Func_b0c0
	ld a, $05
	ld [wNumVisibleCardListEntries], a
	lb de, 2, 3
	ld hl, wCardListCoords
	ld [hl], e
	inc hl
	ld [hl], d
	ld a, SYM_BOX_RIGHT
	ld [wCursorAlternateTile], a
	jp PrintCardSelectionList

.Func_b0b2
	ld bc, wTempCardCollection
.loop
	ld a, [de]
	inc de
	or a
	ret z
	ld h, $00
	ld l, a
	add hl, bc
	inc [hl]
	jr .loop

; preserves all registers
.Func_b0c0
	push af
	push bc
	push de
	push hl
	push af
	ld a, DECK_SIZE ; number of bytes that will be cleared (60)
	ld hl, wOwnedCardsCountList
	call ClearMemory_Bank2
;	ld a, DECK_SIZE ; number of bytes that will be cleared (60)
	ld hl, wFilteredCardList
	call ClearMemory_Bank2
	pop af
	ld hl, $0
	ld de, $0
	ld b, a
.asm_b0dd
	inc e
	call GetCardType
	jr c, .asm_b119
	ld c, a
	ld a, b
	cp $ff
	jr z, .asm_b0fc
	and FILTER_ENERGY
	cp FILTER_ENERGY
	jr z, .asm_b0f5
	ld a, c
	cp b
	jr nz, .asm_b0dd
	jr .asm_b0fc
.asm_b0f5
	ld a, c
	and TYPE_ENERGY
	cp TYPE_ENERGY
	jr nz, .asm_b0dd
.asm_b0fc
	push bc
	push hl
	ld bc, wFilteredCardList
	add hl, bc
	ld [hl], e
	ld hl, wTempCardCollection
	add hl, de
	ld a, [hl]
	and $7f
	pop hl
	or a
	jr z, .asm_b116
	push hl
	ld bc, wOwnedCardsCountList
	add hl, bc
	ld [hl], a
	pop hl
	inc l
.asm_b116
	pop bc
	jr .asm_b0dd

.asm_b119
	ld a, l
	ld [wNumEntriesInCurFilter], a
	xor a
	ld c, l
	ld b, h
	ld hl, wFilteredCardList
	add hl, bc
	ld [hl], a
	ld a, $ff ; terminating byte
	ld hl, wOwnedCardsCountList
	add hl, bc
	ld [hl], a
	pop hl
	pop de
	pop bc
	pop af
	ret


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
