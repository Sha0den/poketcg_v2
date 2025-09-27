; sends serial data to printer.
; if there's an error in connection,
; show Printer Not Connected scene with error message.
PreparePrinterConnection::
	ld bc, 0
	lb de, PRINTERPKT_DATA, FALSE
	call SendPrinterPacket
	ret nc ; return if no error

	ld hl, wPrinterStatus
	ld a, [hl]
	or a
	jr nz, .asm_19e55
	ld [hl], $ff
.asm_19e55
	ld a, [hl]
	cp $ff
	jr z, ShowPrinterIsNotConnected
;	fallthrough

; shows message on screen depending on wPrinterStatus.
; also shows SCENE_GAMEBOY_PRINTER_NOT_CONNECTED.
; output:
;	carry = set
HandlePrinterError:
	ld a, [wPrinterStatus]
	cp $ff
	jr z, .cable_or_printer_switch
	or a
	jr z, .interrupted
	bit PRINTER_ERROR_BATTERIES_LOST_CHARGE, a
	jr nz, .batteries_lost_charge
	bit PRINTER_ERROR_CABLE_PRINTER_SWITCH, a
	jr nz, .cable_or_printer_switch
	bit PRINTER_ERROR_PAPER_JAMMED, a
	jr nz, .jammed_printer

	ldtx hl, PrinterPacketErrorText
;	ld a, $04 ; error code
	jr ShowPrinterConnectionErrorScene
.cable_or_printer_switch
	ldtx hl, CheckCableOrPrinterSwitchText
;	ld a, $02 ; error code
	jr ShowPrinterConnectionErrorScene
.jammed_printer
	ldtx hl, PrinterPaperIsJammedText
;	ld a, $03 ; error code
	jr ShowPrinterConnectionErrorScene
.batteries_lost_charge
	ldtx hl, BatteriesHaveLostTheirChargeText
;	ld a, $01 ; error code
	jr ShowPrinterConnectionErrorScene
.interrupted
	ldtx hl, PrintingWasInterruptedText
	call DrawWideTextBox_WaitForInput
	scf
	ret


ShowPrinterIsNotConnected:
	ldtx hl, PrinterIsNotConnectedText
;	ld a, $02 ; error code
;	fallthrough

; input:
;	hl = text ID for the notification text to print in the text box
; output:
;	carry = set
ShowPrinterConnectionErrorScene:
	push hl
	call SetSpriteAnimationsAsVBlankFunction
	ld a, SCENE_GAMEBOY_PRINTER_NOT_CONNECTED
	lb bc, 0, 0
	call LoadScene
	pop hl
	call DrawWideTextBox_WaitForInput
	call RestoreVBlankFunction
	scf
	ret


; main card printer function
; output:
;	carry = set:  if there was an error
RequestToPrintCard::
	ld e, a
	ld d, $0
	call LoadCardDataToBuffer1_FromCardID
	call SetSpriteAnimationsAsVBlankFunction
	ld a, SCENE_GAMEBOY_PRINTER_TRANSMITTING
	lb bc, 0, 0
	call LoadScene
	ld a, 20
	call CopyCardNameAndLevel
	xor a ; TX_END
	ld [hl], a ; terminate the text string at wDefaultText
	; zero wTxRam2 so that the name & level text just loaded to wDefaultText is printed
	ld hl, wTxRam2
	ld [hli], a
	ld [hl], a
	ldtx hl, NowPrintingText
	call DrawWideTextBox_PrintText
	call EnableLCD
	call PrepareForPrinterCommunications
	call .DrawTopCardInfoInSRAMGfxBuffer0
	call Func_19f87
	call .DrawCardPicInSRAMGfxBuffer2
	call Func_19f99
	jr c, .error
	call DrawBottomCardInfoInSRAMGfxBuffer0
	call Func_1a011
	jr c, .error
	call RestoreVBlankFunction
	call ResetPrinterCommunicationSettings
	or a
	ret
.error
	call RestoreVBlankFunction
	call ResetPrinterCommunicationSettings
	jp HandlePrinterError

; draw card's picture in sGfxBuffer2
.DrawCardPicInSRAMGfxBuffer2:
	ld hl, wLoadedCard1Gfx
	ld a, [hli]
	ld h, [hl]
	ld l, a
	ld de, sGfxBuffer2
	call Func_37a5
	ld a, $40
	lb hl, 12,  1
	lb de,  2, 68
	lb bc, 16, 12
	call FillRectangle
	ret

; writes the tiles necessary to draw
; the card's information in sGfxBuffer0
; this includes card's type, lv, HP and attacks if Pokemon card
; or otherwise just the card's name and type symbol
.DrawTopCardInfoInSRAMGfxBuffer0:
	call Func_1a025
	call Func_212f

	; draw empty text box frame
	ld hl, sGfxBuffer0
	ld a, $34
	lb de, $30, $31
	ld b, 20
	call CopyLine
	ld c, 15
.loop_lines
	xor a ; SYM_SPACE
	lb de, $36, $37
	ld b, 20
	call CopyLine
	dec c
	jr nz, .loop_lines

	; draw card type symbol
	ld a, $38
	lb hl, 1,  2
	lb de, 1, 65
	lb bc, 2,  2
	call FillRectangle
	; print card's name
	lb de, 4, 65
	ld hl, wLoadedCard1Name
	call InitTextPrinting_ProcessTextFromPointerToID

; prints card's type, lv, and HP if it's a Pokemon card
	ld a, [wLoadedCard1Type]
	cp TYPE_ENERGY
	ret nc ; skip Pokemon data
	inc a ; symbol corresponding to card's type (color)
	lb bc, 18, 65
	call WriteByteToBGMap0
	ld a, [wLoadedCard1Level]
	lb bc, 12, 66
	call WriteTwoDigitNumberInTxSymbolFormat_TrimLeadingZero
	ld a, [wLoadedCard1HP]
	ld b, 16 ; c = 66
	call WriteOneByteNumberInTxSymbolFormat_TrimLeadingZeros
	lb de, 11, 66
	ldtx hl, LvSymbolText
	call InitTextPrinting_ProcessTextFromID
	ld d, 15 ; e = 66
	ldtx hl, HPSymbolText
	jp InitTextPrinting_ProcessTextFromID


; writes the tiles necessary to draw the card's information in sGfxBuffer0.
; if the card's a Pokemon, this includes its Retreat cost, Weakness, Resistance, and attack(s).
; if it's a Trainer or Energy card, just print the card's description.
DrawBottomCardInfoInSRAMGfxBuffer0:
	call Func_1a025
	xor a ; CARDPAGETYPE_NOT_PLAY_AREA
	ld [wCardPageType], a
	ld hl, sGfxBuffer0
	lb bc, 20, 9
.loop_lines
	xor a ; SYM_SPACE
	lb de, $36, $37
	call CopyLine
	dec c
	jr nz, .loop_lines
	ld a, $35
	lb de, $32, $33
	call CopyLine

	ld a, [wLoadedCard1Type]
	cp TYPE_ENERGY
	jr nc, .not_pkmn_card
	ld hl, RetreatWeakResistData
	call PlaceTextItems
	ld c, 66
	bank1call DisplayCardPage_PokemonOverview.attacks
	lb bc, 16, 72
	ld hl, wLoadedCard1PokedexNumber
	ld a, [hli]
	ld h, [hl]
	ld l, a
	jp WriteThreeDigitNumberInTxSymbolFormat

.not_pkmn_card
	ld a, SINGLE_SPACED
	ld [wLineSeparation], a
	lb de, 1, 66
	ld a, 19 ; line length
	call InitTextPrintingInTextbox
	ld hl, wLoadedCard1NonPokemonDescription
	call ProcessTextFromPointerToID
	xor a ; DOUBLE_SPACED
	ld [wLineSeparation], a
	ret

RetreatWeakResistData:
	textitem 1, 70, RetreatText
	textitem 1, 71, WeaknessText
	textitem 1, 72, ResistanceText
	textitem 15, 72, NumberSymbolText
	db $ff


; calls setup text and sets wTilePatternSelector
; preserves bc
Func_1a025:
	lb de, $40, $bf
	call SetupText
	ld a, $a4
	ld [wTilePatternSelector], a
	xor a
	ld [wTilePatternSelectorCorrection], a
	ret


; switches to CGB normal speed, resets serial
; enables SRAM and switches to SRAM1
; and clears sGfxBuffer0
; preserves de
PrepareForPrinterCommunications:
	call SwitchToCGBNormalSpeed
	call ResetSerial
	ld a, $10
	ld [wPrinterNumberLineFeeds], a
	call EnableSRAM
	ld a, [sPrinterContrastLevel]
	ld [wPrinterContrastLevel], a
	call DisableSRAM
	ldh a, [hBankSRAM]
	ld [wTempPrinterSRAM], a
	ld a, BANK("SRAM1")
	call BankswitchSRAM
	call EnableSRAM
;	fallthrough

; preserves de
ClearPrinterGfxBuffer:
	ld hl, sGfxBuffer0
	ld bc, $400
	call ClearData
	ld [wce9f], a ; 0
	ret


; reverts settings changed by PrepareForPrinterCommunications
; preserves af
ResetPrinterCommunicationSettings:
	push af
	call SwitchToCGBDoubleSpeed
	ld a, [wTempPrinterSRAM]
	call BankswitchSRAM
	call DisableSRAM
	lb de, $30, $bf
	call SetupText
	pop af
	ret


; sends printer packet
; input:
;	bc = number of bytes in data
;	d = PRINTERPKT_* constant
;	e = in case of PRINTERPKT_DATA, whether it's compressed
; output:
;	carry = set:  if there was an error
SendPrinterPacket:
	push hl
	ld hl, wPrinterPacket
	; Preamble
	ld a, $88
	ld [hli], a          ; [wPrinterPacketPreamble + 0] ← $88
	ld a, $33
	ld [hli], a          ; [wPrinterPacketPreamble + 1] ← $33

	; Header
	ld [hl], d           ; [wPrinterPacketInstructions + 0] ← d
	inc hl
	ld [hl], e           ; [wPrinterPacketInstructions + 1] ← e
	inc hl
	ld [hl], c           ; [wPrinterPacketDataSize + 0] ← c
	inc hl
	ld [hl], b           ; [wPrinterPacketDataSize + 1] ← b
	inc hl

	; Data pointer
	pop de
	ld [hl], e           ; [wPrinterPacketDataPtr + 0] ← l
	inc hl
	ld [hl], d           ; [wPrinterPacketDataPtr + 1] ← h
	inc hl
	ld de, -$bb
	ld [hl], e           ; [wPrinterPacketChecksum + 0] ← $45
	inc hl
	ld [hl], d           ; [wPrinterPacketChecksum + 1] ← $ff

	ld hl, wSerialDataPtr
	ld [hl], LOW(wPrinterPacket)  ; [wSerialDataPtr] ← $64
	inc hl
	ld [hl], HIGH(wPrinterPacket) ; [wSerialDataPtr] ← $ce

	call Func_0e8e

	ld a, $1
	ld [wPrinterPacketSequence], a        ; [wPrinterPacketSequence] ← 1
	call SendNextPrinterPacketByte
.wait_printer_packet_transmission
	call DoFrame
	ld a, [wPrinterPacketSequence]
	or a
	jr nz, .wait_printer_packet_transmission
	call ResetSerial

	ld bc, 1500
.post_transmission_delay
	dec bc
	ld a, b
	or c
	jr nz, .post_transmission_delay

	; we expect printer to send $81
	; as the device number, any other value
	; means that a second device is connected
	ld a, [wSerialTransferData]
	cp $81
	jr nz, .unexpected_device_number
	ld a, [wPrinterStatus]
	ld l, a
	and $f1
	ld a, l
	ret z
	scf
	ret

.unexpected_device_number
	ld a, $ff
	ld [wPrinterStatus], a
	scf
	ret


; tries initiating the communications for sending data to printer
; output:
;	carry = set:  if the operation was cancelled by the Player (with B button) or
;	              if the serial transfer took too long
TryInitPrinterCommunications:
	xor a
	ld [wPrinterInitAttempts], a
.wait_input
	call DoFrame
	ldh a, [hKeysHeld]
	and PAD_B
	jr nz, .b_button
	ld bc, 0
	lb de, PRINTERPKT_NUL, FALSE
	call SendPrinterPacket
	jr c, .delay
	and (1 << PRINTER_STATUS_BUSY) | (1 << PRINTER_STATUS_PRINTING)
	jr nz, .wait_input

.init
	ld bc, 0
	lb de, PRINTERPKT_INIT, FALSE
	call SendPrinterPacket
	ret nc
	ld hl, wPrinterInitAttempts
	inc [hl]
	ld a, [hl]
	cp 3
	jr c, .wait_input
	; time out
	scf
	ret

.b_button
	xor a
	ld [wPrinterStatus], a
	scf
	ret

.delay
	ld a, 10
	call DoAFrames
	jr .init


; loads tiles given by map in hl to sGfxBuffer5.
; copies first 20 tiles, then offsets by 2 tiles and copies another 20.
; compresses this data and sends it to the printer.
; preserves bc
; input:
;	hl = pointing to a location in sGfxBuffer*
; output:
;	carry = set:  if there was an error
SendTilesToPrinter:
	push bc
	ld de, sGfxBuffer5
	call .Copy20Tiles
	call .Copy20Tiles
	push hl
	call CompressDataForPrinterSerialTransfer
	call SendPrinterPacket
	pop hl
	pop bc
	ret

; copies 20 tiles given by hl to de
; then adds 2 tiles to hl
.Copy20Tiles
	push hl
	ld c, 20
.loop_tiles
	ld a, [hli]
	call .CopyTile
	dec c
	jr nz, .loop_tiles
	pop hl
	ld bc, 2 tiles
	add hl, bc
	ret

; copies a tile to de
; preserves bc and hl
; input:
;	a = tile to get from sGfxBuffer1
.CopyTile
	push hl
	push bc
	ld l, a
	ld h, $00
	add hl, hl
	add hl, hl
	add hl, hl
	add hl, hl ; *TILE_SIZE
	ld bc, sGfxBuffer1
	add hl, bc
	ld b, TILE_SIZE
	call CopyNBytesFromHLToDE
	pop bc
	pop hl
	ret


; output:
;	carry = set:  if there was an error
Func_1a011:
	call TryInitPrinterCommunications
	ret c
	ld hl, sGfxBuffer0
	ld c, $05
.asm_1a01a
	call SendTilesToPrinter
	ret c
	dec c
	jr nz, .asm_1a01a
	jr SendPrinterInstructionPacket_1Sheet_3LineFeeds


; output:
;	carry = set:  if there was an error
SendCardListToPrinter:
	ld a, [wPrinterHorizontalOffset]
	cp 1
	jr z, .skip_load_gfx
	call LoadGfxBufferForPrinter
	ret c
.skip_load_gfx
	call TryInitPrinterCommunications
	ret c
;	fallthrough

; output:
;	carry = set:  if there was an error
SendPrinterInstructionPacket_1Sheet_3LineFeeds:
	call GetPrinterContrastSerialData
	push hl
	lb hl, 3, 1
	jr SendPrinterInstructionPacket


; output:
;	carry = set:  if there was an error
Func_19f87:
	call TryInitPrinterCommunications
	ret c ; aborted
	ld hl, sGfxBuffer0
	call SendTilesToPrinter
	ret c
	call SendTilesToPrinter
	jr SendPrinterInstructionPacket_1Sheet


; output:
;	carry = set:  if there was an error
Func_19f99:
	call TryInitPrinterCommunications
	ret c
	ld hl, sGfxBuffer0 + $8 tiles
	ld c, $06
.asm_19fa2
	call SendTilesToPrinter
	ret c
	dec c
	jr nz, .asm_19fa2
;	fallthrough

; uses wPrinterNumberLineFeeds to get number of line feeds to insert before print
; output:
;	carry = set:  if there was an error
SendPrinterInstructionPacket_1Sheet:
	call GetPrinterContrastSerialData
	push hl
	ld hl, wPrinterNumberLineFeeds
	ld a, [hl]
	ld [hl], $00
	ld h, a
	ld l, 1
;	fallthrough

; expects printer contrast information to be on stack
; input:
;	h = number of line feeds where:
;		high nybble is number of line feeds before printing
;		low nybble is number of line feeds after printing
;	l = number of sheets
; output:
;	carry = set:  if there was an error
SendPrinterInstructionPacket:
	push hl
	ld bc, 0
	lb de, PRINTERPKT_DATA, FALSE
	call SendPrinterPacket
	jr c, .aborted
	ld hl, sp+$00 ; contrast level bytes
	ld bc, 4 ; instruction packets are 4 bytes in size
	lb de, PRINTERPKT_PRINT_INSTRUCTION, FALSE
	call SendPrinterPacket
.aborted
	pop hl
	pop hl
	ret


; preserves bc
; output:
;	hl = bytes to be sent through serial to the printer for the set contrast level
GetPrinterContrastSerialData:
	ld a, [wPrinterContrastLevel]
	ld e, a
	ld d, $00
	ld hl, .contrast_level_data
	add hl, de
	ld h, [hl]
	ld l, %11100100 ; palette format
	ret

.contrast_level_data
	db $00, $20, $40, $60, $7f


; input:
;	a = saved deck index to print
PrintDeckConfiguration::
; copies selected deck from SRAM to wDuelTempList
	call EnableSRAM
	ld l, a
	ld h, DECK_STRUCT_SIZE
	call HtimesL
	ld de, sSavedDeck1
	add hl, de
	ld de, wDuelTempList
	ld b, DECK_STRUCT_SIZE
	call CopyNBytesFromHLToDE
	call DisableSRAM

	call ShowPrinterTransmitting
	call PrepareForPrinterCommunications
	call Func_1a025
	call Func_212f
	lb de, 0, 64
	lb bc, 20, 4
	call DrawRegularTextBoxDMG
	lb de, 4, 66
	ld hl, wDuelTempList ; print deck name
	call InitTextPrinting_ProcessText
	ldtx hl, DeckPrinterText
	call ProcessTextFromID

	ld a, 5
	ld [wPrinterHorizontalOffset], a
	ld hl, wPrinterTotalCardCount
	xor a
	ld [hli], a
	ld [hl], a
	ld [wPrintOnlyStarRarity], a

	ld hl, wCurDeckCards
.loop_cards
	ld a, [hl]
	or a
	jr z, .asm_1a1d6
	ld e, a
	ld d, $00
	call LoadCardDataToBuffer1_FromCardID

	; find out this card's count
	ld a, [hli]
	ld b, a
	ld c, 1
.loop_card_count
	cp [hl]
	jr nz, .got_card_count
	inc hl
	inc c
	jr .loop_card_count

.got_card_count
	ld a, c
	ld [wPrinterCardCount], a
	call LoadCardInfoForPrinter
	call AddToPrinterGfxBuffer
	jr c, .printer_error
	jr .loop_cards

.asm_1a1d6
	call SendCardListToPrinter
	jr c, .printer_error
	call ResetPrinterCommunicationSettings
	call RestoreVBlankFunction
	or a
	ret

.printer_error
	call ResetPrinterCommunicationSettings
	call RestoreVBlankFunction
	jp HandlePrinterError


PrintCardList::
; if Select button is held when printing card list
; only print cards with Star rarity (excluding Promotional cards)
; even if it's not marked as seen in the collection
	ld e, FALSE
	ldh a, [hKeysHeld]
	and PAD_SELECT
	jr z, .no_select
	inc e ; TRUE
.no_select
	ld a, e
	ld [wPrintOnlyStarRarity], a

	call ShowPrinterTransmitting
	call CreateTempCardCollection
	ld de, wDefaultText
	call CopyPlayerName
	call PrepareForPrinterCommunications
	call Func_1a025
	call Func_212f

	lb de, 0, 64
	lb bc, 20, 4
	call DrawRegularTextBoxDMG
	ld a, PLAYER_TURN
	ldh [hWhoseTurn], a
	lb de, 2, 66
	ld hl, wDefaultText
	call InitTextPrinting_ProcessText
	ldtx hl, AllCardsOwnedText
	call ProcessTextFromID
	ld a, [wPrintOnlyStarRarity]
	or a
	jr z, .asm_1a2c2
	ld a, TX_HALF2FULL
	call ProcessSpecialTextCharacter
	ldfw de, "★"
	call Func_22ca
.asm_1a2c2
	ld a, $ff
	ld [wCurPrinterCardType], a
	xor a
	ld hl, wPrinterTotalCardCount
	ld [hli], a
	ld [hl], a
	ld [wPrinterNumCardTypes], a
	ld a, 5
	ld [wPrinterHorizontalOffset], a

	ld e, GRASS_ENERGY
.loop_cards
	push de
	ld d, $00
	call LoadCardDataToBuffer1_FromCardID
	jr c, .done_card_loop
	ld d, HIGH(wTempCardCollection)
	ld a, [de] ; card ID count in collection
	ld [wPrinterCardCount], a
	call .LoadCardTypeEntry
	jr c, .printer_error_pop_de

	ld a, [wPrintOnlyStarRarity]
	or a
	jr z, .all_owned_cards_mode
	ld a, [wLoadedCard1Set]
	and %11110000
	cp PROMOTIONAL
	jr z, .next_card
	ld a, [wLoadedCard1Rarity]
	cp STAR
	jr nz, .next_card
	; not Promotional, and Star rarity
	ld hl, wPrinterCardCount
	res CARD_NOT_OWNED_F, [hl]
	jr .got_card_count

.all_owned_cards_mode
	ld a, [wPrinterCardCount]
	or a
	jr z, .next_card
	cp CARD_NOT_OWNED
	jr z, .next_card ; ignore not owned cards

.got_card_count
	ld a, [wPrinterCardCount]
	and CARD_COUNT_MASK
	ld c, a

	; add to total card count
	ld hl, wPrinterTotalCardCount
	add [hl]
	ld [hli], a
	ld a, 0
	adc [hl]
	ld [hl], a

	; add to current card type count
	ld hl, wPrinterCurCardTypeCount
	ld a, c
	add [hl]
	ld [hli], a
	ld a, 0
	adc [hl]
	ld [hl], a

	ld hl, wPrinterNumCardTypes
	inc [hl]
	ld hl, wce98
	inc [hl]
	call LoadCardInfoForPrinter
	call AddToPrinterGfxBuffer
	jr c, .printer_error_pop_de
.next_card
	pop de
	inc e
	jr .loop_cards

.printer_error_pop_de
	pop de
.printer_error
	call ResetPrinterCommunicationSettings
	call RestoreVBlankFunction
	jp HandlePrinterError

.done_card_loop
	pop de
	; add separator line
	ld a, [wPrinterHorizontalOffset]
	dec a
	or $40
	ld c, a
	ld b, 0
	call BCCoordToBGMap0Address
	ld a, $35
	lb de, $35, $35
	ld b, 20
	call CopyLine
	call AddToPrinterGfxBuffer
	jr c, .printer_error

	ld hl, wPrinterTotalCardCount
	ld c, [hl]
	inc hl
	ld b, [hl]
	ldtx hl, TotalNumberOfCardsText
	call .PrintTextWithNumber
	jr c, .printer_error
	ld a, [wPrintOnlyStarRarity]
	or a
	jr nz, .done
	ld a, [wPrinterNumCardTypes]
	ld c, a
	ld b, 0
	ldtx hl, TypesOfCardsText
	call .PrintTextWithNumber
	jr c, .printer_error

.done
	call SendCardListToPrinter
	jr c, .printer_error
	call ResetPrinterCommunicationSettings
	call RestoreVBlankFunction
	or a
	ret

; loads this card's type icon and text
; if it's a new card type that hasn't been printed yet
.LoadCardTypeEntry
	ld a, [wLoadedCard1Type]
	ld c, a
	cp TYPE_ENERGY
	jr c, .got_type ; jump if Pokemon card
	ld c, $08
	cp TYPE_TRAINER
	jr nc, .got_type ; jump if Trainer card
	ld c, $07
.got_type
	ld hl, wCurPrinterCardType
	ld a, [hl]
	cp c
	ret z ; already handled this card type

	; show corresponding icon and text for this new card type
	ld a, c
	ld [hl], a ; set it as current card type
	add a
	add c ; *3
	ld c, a
	ld b, $00
	ld hl, .IconTextList
	add hl, bc
	ld a, [wPrinterHorizontalOffset]
	dec a
	or %1000000
	ld e, a
	ld d, 1
	ld a, [hli]
	push hl
	lb bc, 2, 2
	lb hl, 1, 2
	call FillRectangle
	pop hl
	ld d, 3
	inc e
	ld a, [hli]
	ld h, [hl]
	ld l, a
	call InitTextPrinting_ProcessTextFromID

	call AddToPrinterGfxBuffer
	ld hl, wPrinterCurCardTypeCount
	xor a
	ld [hli], a
	ld [hl], a
	ld [wce98], a
	ret

.IconTextList
	; Fire
	db ICON_TILE_FIRE
	tx FirePokemonText

	; Grass
	db ICON_TILE_GRASS
	tx GrassPokemonText

	; Lightning
	db ICON_TILE_LIGHTNING
	tx LightningPokemonText

	; Water
	db ICON_TILE_WATER
	tx WaterPokemonText

	; Fighting
	db ICON_TILE_FIGHTING
	tx FightingPokemonText

	; Psychic
	db ICON_TILE_PSYCHIC
	tx PsychicPokemonText

	; Colorless
	db ICON_TILE_COLORLESS
	tx ColorlessPokemonText

	; Energy
	db ICON_TILE_ENERGY
	tx EnergyCardsText

	; Trainer
	db ICON_TILE_TRAINER
	tx TrainerCardsText

; prints text ID given in hl, with decimal representation of the number given in bc
; input:
;	hl = text ID
;	bc = number
.PrintTextWithNumber
	push bc
	ld a, [wPrinterHorizontalOffset]
	dec a
	or $40
	ld e, a
	ld d, 2
	call InitTextPrinting_ProcessTextFromID
	pop hl
	push de
	call TwoByteNumberToTxSymbol_TrimLeadingZeros
	pop bc
	ld b, 14
	call BCCoordToBGMap0Address
	ld hl, wStringBuffer
	ld b, 5
	call SafeCopyDataHLtoDE
;	fallthrough

; increases printer horizontal offset by 2
; preserves hl
; output:
;	carry = set:  if LoadGfxBufferForPrinter transfer was unsuccessful
AddToPrinterGfxBuffer:
	push hl
	ld hl, wPrinterHorizontalOffset
	inc [hl]
	inc [hl]
	ld a, [hl]
	pop hl
	; return no carry if below 18
	cp 18
	ccf
	ret nc
	; >= 18
;	fallthrough

; copies Gfx to Gfx buffer and sends some serial data
; preserves hl
; output:
;	carry = set:  if the transfer was unsuccessful
LoadGfxBufferForPrinter:
	push hl
	call TryInitPrinterCommunications
	jr c, .set_carry
	ld a, [wPrinterHorizontalOffset]
	srl a
	ld c, a
	ld hl, sGfxBuffer0
.loop_gfx_buffer
	call SendTilesToPrinter
	jr c, .set_carry
	dec c
	jr nz, .loop_gfx_buffer
	call SendPrinterInstructionPacket_1Sheet
	jr c, .set_carry

	call ClearPrinterGfxBuffer
	ld a, 1
	ld [wPrinterHorizontalOffset], a
	pop hl
	or a
	ret

.set_carry
	pop hl
	scf
	ret


; loads symbol, name, level and card count to buffer
; preserves hl
LoadCardInfoForPrinter:
	push hl
	ld a, [wPrinterHorizontalOffset]
	or %1000000
	ld e, a
	ld d, 3
	ld a, [wPrintOnlyStarRarity]
	or a
	jr nz, .skip_card_symbol
	ld hl, wPrinterTotalCardCount
	ld a, [hli]
	or [hl]
	call z, DrawCardSymbol
.skip_card_symbol
	ld a, 14
	call CopyCardNameAndLevel
	ld hl, wDefaultText
	call InitTextPrinting_ProcessText
	ld a, [wPrinterHorizontalOffset]
	or %1000000
	ld c, a
	ld b, 16
	ld a, SYM_CROSS
	call WriteByteToBGMap0
	inc b
	ld a, [wPrinterCardCount]
	call WriteTwoDigitNumberInTxSymbolFormat_TrimLeadingZero
	pop hl
	ret


ShowPrinterTransmitting:
	call SetSpriteAnimationsAsVBlankFunction
	ld a, SCENE_GAMEBOY_PRINTER_TRANSMITTING
	lb bc, 0, 0
	call LoadScene
	ldtx hl, NowPrintingPleaseWaitText
	call DrawWideTextBox_PrintText
	jp EnableLCD


; compresses $28 tiles in sGfxBuffer5 and writes it in sGfxBuffer5 + $28 tiles.
; compressed data has 2 commands to instruct on how to decompress it.
;	- a command byte with bit 7 not set: copy that many + 1 bytes
;	  that are following it literally
;	- a command byte with bit 7 set: copy the following byte that many times + 2
;	 (after masking the top bit of command byte)
; output:
;	bc = size of the compressed data
;	de = PRINTERPKT_DATA, TRUE
;	hl = sGfxBuffer5 + $28 tiles
CompressDataForPrinterSerialTransfer:
	ld hl, sGfxBuffer5
	ld de, sGfxBuffer5 + $28 tiles
	ld bc, $28 tiles
.loop_remaining_data
	ld a, $ff
	inc b
	dec b
	jr nz, .check_compression
	ld a, c
.check_compression
	push bc
	push de
	ld c, a
	call CheckDataCompression
	ld a, e
	ld c, e
	pop de
	jr c, .copy_byte
	ld a, c
	ld b, c
	dec a
	ld [de], a ; number of bytes to copy literally - 1
	inc de
.copy_literal_sequence
	ld a, [hli]
	ld [de], a
	inc de
	dec c
	jr nz, .copy_literal_sequence
	ld c, b
	jr .sub_added_bytes

.copy_byte
	ld a, c
	dec a
	dec a
	or %10000000 ; set high bit
	ld [de], a ; = (n times to copy - 2) | %10000000
	inc de
	ld a, [hl] ; byte to copy n times
	ld [de], a
	inc de
	ld b, $0
	add hl, bc

.sub_added_bytes
	ld a, c
	cpl
	inc a
	pop bc
	add c
	ld c, a
	ld a, $ff
	adc b
	ld b, a
	or c
	jr nz, .loop_remaining_data

	ld hl, $10000 - (sGfxBuffer5 + $28 tiles)
	add hl, de ; gets the size of the compressed data
	ld c, l
	ld b, h
	ld hl, sGfxBuffer5 + $28 tiles
	lb de, PRINTERPKT_DATA, TRUE
	ret


; checks whether the next byte sequence in hl, up to c bytes, can be compressed
; returns carry if the next sequence of bytes can be compressed,
; i.e. it has at least 3 consecutive bytes with the same value.
; in that case, returns in e the number of consecutive same value bytes that were found.
; if there are no bytes with same value, then count as many bytes left
; as possible until either there are no more remaining data bytes,
; or until a sequence of 3 bytes with the same value are found.
; in that case, the number of bytes in this sequence is returned in e.
; preserves hl
; input:
;	c = number of bytes to check
;	hl = pointing to the start of the data to check
; output:
;	e = number of consecutive bytes with the same value that can be compressed
;	carry = set:  if there's data that can be compressed
CheckDataCompression:
	push hl
	ld e, c
	ld a, c
; if number of remaining bytes is less than 4, then no point in compressing
	cp 4
	jr c, .no_carry

; check first if there are at least 3 consecutive bytes with the same value
	ld b, c
	ld a, [hli]
	cp [hl]
	inc hl
	jr nz, .literal_copy ; not same
	cp [hl]
	inc hl
	jr nz, .literal_copy ; not same

; 3 consecutive bytes were found with same value
; keep track of how many consecutive bytes
; with the same value there are in e
	dec c
	dec c
	dec c
	ld e, 3
.loop_same_value
	cp [hl]
	jr nz, .set_carry ; exit when a different byte is found
	inc hl
	inc e
	dec c
	jr z, .set_carry ; exit when there is no more remaining data
	bit 5, e
	; exit if number of consecutive bytes >= $20
	jr z, .loop_same_value
.set_carry
	pop hl
	scf
	ret

.literal_copy
; consecutive bytes are not the same value
; count the number of bytes there are left
; until a sequence of 3 bytes with the same value is found
	pop hl
	push hl
	ld c, b ; number of remaining bytes
	ld e, 1
	ld a, [hli]
	dec c
	jr z, .no_carry ; exit if no more data
.reset_same_value_count
	ld d, 2 ; number of consecutive same value bytes to exit
.next_byte
	inc e
	dec c
	jr z, .no_carry
	bit 7, e
	jr nz, .no_carry ; exit if >= $80
	cp [hl]
	jr z, .same_consecutive_value
	ld a, [hli]
	jr .reset_same_value_count

.same_consecutive_value
	inc hl
	dec d
	jr nz, .next_byte
	; 3 consecutive bytes with same value found
	; discard the last 3 bytes in the sequence
	dec e
	dec e
	dec e
.no_carry
	pop hl
	or a
	ret


;----------------------------------------
;        UNREFERENCED FUNCTIONS
;----------------------------------------
;
; send some bytes through serial
;Func_1a080:
;	ld bc, 0
;	lb de, PRINTERPKT_NUL, FALSE
;	jp SendPrinterPacket
;
;
;Func_1a14b:
;	ld a, $01
;	jr .asm_1a15d
;	ld a, $02
;	jr .asm_1a15d
;	ld a, $03
;	jr .asm_1a15d
;	ld a, $04
;	jr .asm_1a15d
;	ld a, $05
;	; fallthrough
;.asm_1a15d
;	ld [wce9d], a
;	scf
;	ret
