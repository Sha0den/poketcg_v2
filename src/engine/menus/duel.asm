_OpenDuelCheckMenu::
	ld a, 9
	ld [wCheckMenuCursorXPositionOffset], a
	call ResetCheckMenuCursorPositionAndBlink
	ld [wce5e], a ; 0
	call DrawWideTextBox
	ld hl, CheckMenuData
	call PlaceTextItems
.loop
	call DoFrame
	call HandleCheckMenuInput
	jr nc, .loop
	cp -1
	ret z ; exit if the B button was pressed
	; A button was pressed
	ld a, [wCheckMenuCursorYPosition]
	add a
	ld b, a
	ld a, [wCheckMenuCursorXPosition]
	add b
	ld hl, .jump_table
	call JumpToFunctionInTable
	jr _OpenDuelCheckMenu

.jump_table
	dw DuelCheckMenu_InPlayArea
	dw DuelCheckMenu_Glossary
	dw DuelCheckMenu_YourPlayArea
	dw DuelCheckMenu_OppPlayArea


; opens the In Play Area submenu
DuelCheckMenu_InPlayArea:
	xor a
	ld [wInPlayAreaFromSelectButton], a
	farcall OpenInPlayAreaScreen
	ret


; opens the Glossary submenu
DuelCheckMenu_Glossary:
	lb de, $38, $ff
	call SetupText
	farcall OpenGlossaryScreen
	ret


; opens the Your Play Area submenu
DuelCheckMenu_YourPlayArea:
	ld a, 10
	ld [wCheckMenuCursorXPositionOffset], a
	call ResetCheckMenuCursorPositionAndBlink
	ld [wce5e], a ; 0
	ldh a, [hWhoseTurn]
.draw
	ld h, a
	ld l, a
	call DrawYourOrOppPlayAreaScreen

; convert cursor position and store it in wYourOrOppPlayAreaLastCursorPosition
	ld a, [wCheckMenuCursorYPosition]
	add a
	ld b, a
	ld a, [wCheckMenuCursorXPosition]
	add b
	ld [wYourOrOppPlayAreaLastCursorPosition], a

; draw black arrows associated with the currently selected option (hand, discard pile, or Pokémon)
	ld b, $f8 ; black arrow tile
	call DrawYourOrOppPlayArea_DrawArrows

; reset cursor blink
	xor a
	ld [wCheckMenuCursorBlinkCounter], a

; draw text box and print text options
	call DrawWideTextBox
	ld hl, YourPlayAreaMenuData
	call PlaceTextItems

; handle input
.loop
	call DoFrame
	xor a
	call DrawYourOrOppPlayArea_RefreshArrows
	call HandleCheckMenuInput_YourOrOppPlayArea
	jr nc, .loop

	call DrawYourOrOppPlayArea_EraseArrows
	cp -1
	ret z ; exit if the B button was pressed

; A button was pressed
; jump to function corresponding to cursor position
	ld a, [wCheckMenuCursorYPosition]
	add a
	ld b, a
	ld a, [wCheckMenuCursorXPosition]
	add b
	ld hl, .jump_table
	call JumpToFunctionInTable
	jr .draw

.jump_table
	dw OpenYourOrOppPlayAreaScreen_TurnHolderPlayArea
	dw OpenYourOrOppPlayAreaScreen_TurnHolderHand
	dw OpenYourOrOppPlayAreaScreen_TurnHolderDiscardPile


OpenYourOrOppPlayAreaScreen_TurnHolderPlayArea:
	ldh a, [hWhoseTurn]
	push af
	bank1call OpenTurnHolderPlayAreaScreen
	pop af
	ldh [hWhoseTurn], a
	ret


OpenYourOrOppPlayAreaScreen_NonTurnHolderPlayArea:
	ldh a, [hWhoseTurn]
	push af
	bank1call OpenNonTurnHolderPlayAreaScreen
	pop af
	ldh [hWhoseTurn], a
	ret


OpenYourOrOppPlayAreaScreen_TurnHolderHand:
	ldh a, [hWhoseTurn]
	push af
	bank1call OpenTurnHolderHandScreen_Simple
	pop af
	ldh [hWhoseTurn], a
	ret


OpenYourOrOppPlayAreaScreen_NonTurnHolderHand:
	ldh a, [hWhoseTurn]
	push af
	bank1call OpenNonTurnHolderHandScreen_Simple
	pop af
	ldh [hWhoseTurn], a
	ret


OpenYourOrOppPlayAreaScreen_TurnHolderDiscardPile:
	ldh a, [hWhoseTurn]
	push af
	bank1call OpenTurnHolderDiscardPileScreen
	pop af
	ldh [hWhoseTurn], a
	ret


OpenYourOrOppPlayAreaScreen_NonTurnHolderDiscardPile:
	ldh a, [hWhoseTurn]
	push af
	bank1call OpenNonTurnHolderDiscardPileScreen
	pop af
	ldh [hWhoseTurn], a
	ret


; opens the Opponent's Play Area submenu.
; if the Clairvoyance Pokemon Power is active,
; then add the option to check the opponent's hand.
DuelCheckMenu_OppPlayArea:
	ld a, 13
	ld [wCheckMenuCursorXPositionOffset], a
	call ResetCheckMenuCursorPositionAndBlink
	call IsClairvoyanceActive
	ld a, %10000000
	jr nc, .begin
	; able to view the opponent's hand
	xor a
.begin
	ld [wce5e], a
	ldh a, [hWhoseTurn]
.draw
	ld l, a
	cp PLAYER_TURN
	ld a, OPPONENT_TURN ; if player is turn holder, wCheckMenuPlayAreaWhichDuelist = OPPONENT_TURN
	jr z, .got_variable
	ld a, PLAYER_TURN ; if opponent is turn holder, wCheckMenuPlayAreaWhichDuelist = PLAYER_TURN
.got_variable
	ld h, a
	call DrawYourOrOppPlayAreaScreen

; convert cursor position and store it in wYourOrOppPlayAreaLastCursorPosition
	ld a, [wCheckMenuCursorYPosition]
	add a
	ld b, a
	ld a, [wCheckMenuCursorXPosition]
	add b
	add 3
	ld [wYourOrOppPlayAreaLastCursorPosition], a

; draw black arrows associated with the currently selected option (hand, discard pile, or Pokémon)
	ld b, $f8 ; black arrow tile
	call DrawYourOrOppPlayArea_DrawArrows

; reset cursor blink
	xor a
	ld [wCheckMenuCursorBlinkCounter], a

; place text items depending on the Clairvoyance Power.
; when active, it allows you to look at the opponent's hand.
	call DrawWideTextBox
	call IsClairvoyanceActive
	ld hl, OppPlayAreaMenuData
	jr nc, .place_text
	; able to view the opponent's hand
	ld hl, OppPlayAreaMenuData_WithClairvoyance
.place_text
	call PlaceTextItems

; handle input
.loop
	call DoFrame
	ld a, 1
	call DrawYourOrOppPlayArea_RefreshArrows
	call HandleCheckMenuInput_YourOrOppPlayArea
	jr nc, .loop

	call DrawYourOrOppPlayArea_EraseArrows
	cp -1
	ret z ; exit if the B button was pressed

; A button was pressed
; jump to function corresponding to cursor position
	ld a, [wCheckMenuCursorYPosition]
	add a
	ld b, a
	ld a, [wCheckMenuCursorXPosition]
	add b
	ld hl, .jump_table
	call JumpToFunctionInTable
	jr .draw

.jump_table
	dw OpenYourOrOppPlayAreaScreen_NonTurnHolderPlayArea
	dw OpenYourOrOppPlayAreaScreen_NonTurnHolderHand
	dw OpenYourOrOppPlayAreaScreen_NonTurnHolderDiscardPile


CheckMenuData:
	textitem  2, 14, InPlayAreaText
	textitem  2, 16, YourPlayAreaText
	textitem 11, 14, GlossaryText
	textitem 11, 16, OppPlayAreaText
	db $ff


YourPlayAreaMenuData:
	textitem  2, 14, YourPokemonText
	textitem 12, 14, YourHandText
	textitem  2, 16, YourDiscardPileText
	db $ff


OppPlayAreaMenuData:
	textitem  2, 14, OpponentsPokemonText
	textitem  2, 16, OpponentsDiscardPileText
	db $ff


; HandText is used in place of OpponentsHandText because of the limited space
OppPlayAreaMenuData_WithClairvoyance:
	textitem  2, 14, OpponentsPokemonText
	textitem 15, 14, HandText
	textitem  2, 16, OpponentsDiscardPileText
	db $ff


; checks if arrows need to be erased in Your Play Area or Opp. Play Area
; and draws new arrows upon cursor position change.
; preserves af
; input:
;	a = an initial offset applied to the cursor position (used to adjust for
;	    the different layouts of the Your Play Area and Opp. Play Area screens)
DrawYourOrOppPlayArea_RefreshArrows:
	push af
	ld b, a
	add b
	add b
	ld c, a
	ld a, [wCheckMenuCursorYPosition]
	add a
	ld b, a
	ld a, [wCheckMenuCursorXPosition]
	add b
	add c
	; a = 2 * cursor y coordinate + cursor x coordinate + 3*a

; if cursor position is different from previous position, then update the arrows
	ld hl, wYourOrOppPlayAreaLastCursorPosition
	cp [hl]
	jr z, .unchanged

; erase and draw arrows
	call DrawYourOrOppPlayArea_EraseArrows
	ld [wYourOrOppPlayAreaLastCursorPosition], a
	ld b, $f8 ; black arrow tile byte
	call DrawYourOrOppPlayArea_DrawArrows

.unchanged
	pop af
	ret


; writes SYM_SPACE to positions tabulated in YourOrOppPlayAreaArrowPositions,
; with offset calculated from the cursor x/y positions in [wYourOrOppPlayAreaLastCursorPosition].
; preserves af
; input:
;	[wYourOrOppPlayAreaLastCursorPosition] = cursor position (2*y + x)
DrawYourOrOppPlayArea_EraseArrows:
	push af
	ld a, [wYourOrOppPlayAreaLastCursorPosition]
	ld b, SYM_SPACE ; blank tile
	call DrawYourOrOppPlayArea_DrawArrows
	pop af
	ret


; writes tile in b to positions tabulated in YourOrOppPlayAreaArrowPositions,
; with offset calculated from the cursor x and y positions in a.
; input:
;	a = cursor position (2*y + x)
;	b = byte to draw
DrawYourOrOppPlayArea_DrawArrows:
	push bc
	ld hl, YourOrOppPlayAreaArrowPositions
	add a
	ld c, a
	ld b, $00
	add hl, bc
; hl points to YourOrOppPlayAreaArrowPositions
; plus offset corresponding to a input

; load hl with draw position pointer
	ld a, [hli]
	ld h, [hl]
	ld l, a
	pop de

.loop
	ld a, [hli]
	cp $ff
	ret z
	ld b, a
	ld a, [hli]
	ld c, a
	ld a, d
	call WriteByteToBGMap0
	jr .loop


YourOrOppPlayAreaArrowPositions:
	dw YourOrOppPlayAreaArrowPositions_PlayerPokemon
	dw YourOrOppPlayAreaArrowPositions_PlayerHand
	dw YourOrOppPlayAreaArrowPositions_PlayerDiscardPile
	dw YourOrOppPlayAreaArrowPositions_OpponentPokemon
	dw YourOrOppPlayAreaArrowPositions_OpponentHand
	dw YourOrOppPlayAreaArrowPositions_OpponentDiscardPile

YourOrOppPlayAreaArrowPositions_PlayerPokemon:
; x and y coordinates to draw byte
	db  5,  5
	db  0, 10
	db  4, 10
	db  8, 10
	db 12, 10
	db 16, 10
	db $ff

YourOrOppPlayAreaArrowPositions_PlayerHand:
	db 14, 7
	db $ff

YourOrOppPlayAreaArrowPositions_PlayerDiscardPile:
	db 14, 5
	db $ff

YourOrOppPlayAreaArrowPositions_OpponentPokemon:
	db  5, 7
	db  0, 3
	db  4, 3
	db  8, 3
	db 12, 3
	db 16, 3
	db $ff

YourOrOppPlayAreaArrowPositions_OpponentHand:
	db 0, 5
	db $ff

YourOrOppPlayAreaArrowPositions_OpponentDiscardPile:
	db 0, 8
	db $ff


; loads tiles and icons to display Your Play Area / Opp. Play Area screen,
; and draws the screen according to the turn player.
; input:
;	h -> [wCheckMenuPlayAreaWhichDuelist] 
;	l -> [wCheckMenuPlayAreaWhichLayout]
DrawYourOrOppPlayAreaScreen:
; loads the turn holders
	ld a, h
	ld [wCheckMenuPlayAreaWhichDuelist], a
	ld a, l
	ld [wCheckMenuPlayAreaWhichLayout], a
;	fallthrough

; loads tiles and icons to display Your Play Area / Opp. Play Area screen,
; and draws the screen according to the turn player.
; input:
;	[wCheckMenuPlayAreaWhichDuelist] = PLAYER_TURN or OPPONENT_TURN
;	[wCheckMenuPlayAreaWhichLayout] = PLAYER_TURN or OPPONENT_TURN
_DrawYourOrOppPlayAreaScreen::
	xor a
	ld [wTileMapFill], a
	call ZeroObjectPositionsAndToggleOAMCopy
	call DoFrame
	call EmptyScreen
	call Set_OBJ_8x8
	call LoadCursorTile
	call LoadSymbolsFont
	call LoadDeckAndDiscardPileIcons
	lb de, $38, $9f
	call SetupText

; print <RAMNAME>'s Play Area
	ld de, wDefaultText
	ld a, [wCheckMenuPlayAreaWhichDuelist]
	cp PLAYER_TURN
	jr nz, .opp_turn1
	call CopyPlayerName
	jr .get_text_length
.opp_turn1
	call CopyOpponentName
.get_text_length
	ld hl, wDefaultText

	; center the text label
	call GetTextLengthInTiles
	ld a, MAX_PLAYER_NAME_LENGTH / 2
	sub b
	srl a
	add 4
	; a = (max name length in tiles - actual name length in tiles) / 2 + 4
	ld d, a ; text horizontal alignment

	ld e, 0
	call InitTextPrinting
	ldtx hl, DuelistsPlayAreaText
	ldh a, [hWhoseTurn]
	cp PLAYER_TURN
	jr nz, .opp_turn2
	ld a, [wCheckMenuPlayAreaWhichDuelist]
	cp PLAYER_TURN
	jr nz, .swap
.opp_turn2
	call PrintTextNoDelay
	jr .draw
.swap
	rst SwapTurn
	call PrintTextNoDelay
	rst SwapTurn

.draw
	ld a, [wCheckMenuPlayAreaWhichDuelist]
	ld b, a
	ld a, [wCheckMenuPlayAreaWhichLayout]
	cp b
	jr nz, .not_equal

	ld hl, PrizeCardsCoordinateData_YourOrOppPlayArea.player
	call DrawPlayArea_PrizeCards
	lb de, 6, 2 ; starting coordinates for drawing the player's Active Pokemon
	call DrawYourOrOppPlayArea_ActiveCardGfx
	lb de, 1, 9 ; starting coordinates for drawing the player's Benched Pokemon
	ld c, 4 ; spacing
	call DrawPlayArea_BenchCards
	xor a
	call DrawYourOrOppPlayArea_Icons
	jp EnableLCD

.not_equal
	ld hl, PrizeCardsCoordinateData_YourOrOppPlayArea.opponent
	call DrawPlayArea_PrizeCards
	lb de, 6, 5 ; starting coordinates for drawing the opponent's Active Pokemon
	call DrawYourOrOppPlayArea_ActiveCardGfx
	lb de, 1, 2 ; starting coordinates for drawing the opponent's Benched Pokemon
	ld c, 4 ; spacing
	call DrawPlayArea_BenchCards
	ld a, $01
	call DrawYourOrOppPlayArea_Icons
	jp EnableLCD


; loads tiles and icons to display the In Play Area screen and then draws the screen
DrawInPlayAreaScreen:
	xor a
	ld [wTileMapFill], a
	call ZeroObjectPositionsAndToggleOAMCopy
	call DoFrame
	call EmptyScreen

	ld a, CHECK_PLAY_AREA
	ld [wDuelDisplayedScreen], a
	call Set_OBJ_8x8
	call LoadCursorTile
	call LoadSymbolsFont
	call LoadDeckAndDiscardPileIcons

	lb de, $80, $9f
	call SetupText

; reset turn holders
	ldh a, [hWhoseTurn]
	ld [wCheckMenuPlayAreaWhichDuelist], a
	ld [wCheckMenuPlayAreaWhichLayout], a

; player's Prize cards
	ld hl, PrizeCardsCoordinateData_InPlayArea.player
	call DrawPlayArea_PrizeCards

; player's Benched Pokemon
	lb de, 3, 15
	ld c, 3
	call DrawPlayArea_BenchCards

	ld hl, PlayAreaIconCoordinates.player2
	call DrawInPlayArea_Icons

	rst SwapTurn
	ldh a, [hWhoseTurn]
	ld [wCheckMenuPlayAreaWhichDuelist], a
	rst SwapTurn

; opponent's Prize cards
	ld hl, PrizeCardsCoordinateData_InPlayArea.opponent
	call DrawPlayArea_PrizeCards

; opponent's Benched Pokemon
	lb de, 3, 0
	ld c, 3
	call DrawPlayArea_BenchCards

	rst SwapTurn
	ld hl, PlayAreaIconCoordinates.opponent2
	call DrawInPlayArea_Icons
	rst SwapTurn
;	fallthrough

; draws the card graphics for both player's
; Active Pokemon in the "In Play Area" screen.
DrawInPlayArea_ActiveCardGfx:
	xor a
	ld [wArenaCardsInPlayArea], a

	ld a, DUELVARS_ARENA_CARD
	get_turn_duelist_var
	cp -1 ; empty play area slot?
	jr z, .opponent1

	push af
	ld a, [wArenaCardsInPlayArea]
	or %00000001 ; set the player's Active Pokemon bit
	ld [wArenaCardsInPlayArea], a
	pop af

; load card gfx
	call LoadCardDataToBuffer1_FromDeckIndex
	lb de, $8a, $00
	ld hl, wLoadedCard1Gfx
	ld a, [hli]
	ld h, [hl]
	ld l, a
	lb bc, $30, TILE_SIZE
	call LoadCardGfx
	bank1call SetBGP6OrSGB3ToCardPalette

.opponent1
	ld a, DUELVARS_ARENA_CARD
	call GetNonTurnDuelistVariable
	cp -1 ; empty play area slot?
	jr z, .draw

	push af
	ld a, [wArenaCardsInPlayArea]
	or %00000010 ; set the opponent's Active Pokemon bit
	ld [wArenaCardsInPlayArea], a
	pop af

; load card gfx
	rst SwapTurn
	call LoadCardDataToBuffer1_FromDeckIndex
	lb de, $95, $00
	ld hl, wLoadedCard1Gfx
	ld a, [hli]
	ld h, [hl]
	ld l, a
	lb bc, $30, TILE_SIZE
	call LoadCardGfx
	bank1call SetBGP7OrSGB2ToCardPalette
	rst SwapTurn

.draw
	ld a, [wArenaCardsInPlayArea]
	or a
	ret z ; no cards in the Arena

	bank1call FlushAllPalettesOrSendPal23Packet
	ld a, [wArenaCardsInPlayArea]
	and %00000001 ; test the player's Active Pokemon bit
	jr z, .opponent2

; draw the player's Active Pokemon
	ld a, $a0 ; starting tile number (v0Tiles1 + $20 tiles)
	lb de, 6, 9 ; screen coordinates for top left tile
	lb hl, 6, 1
	lb bc, 8, 6 ; width and height of image (in tiles)
	call FillRectangle
	bank1call ApplyBGP6OrSGB3ToCardImage

.opponent2
	ld a, [wArenaCardsInPlayArea]
	and %00000010 ; test the opponent's Active Pokemon bit
	ret z

; draws the opponent's Active Pokemon
	rst SwapTurn
	ld a, $50 ; starting tile number (v0Tiles2 + $50 tiles)
	lb de, 6, 2 ; screen coordinates for top left tile
	lb hl, 6, 1
	lb bc, 8, 6 ; width and height of image (in tiles)
	call FillRectangle
	bank1call ApplyBGP7OrSGB2ToCardImage
	jp SwapTurn


; draws the player's or opponent's Active Pokemon gfx at coordinates de,
; depending on wCheckMenuPlayAreaWhichDuelist.
; input:
;	de = screen coordinates for drawing the card image
DrawYourOrOppPlayArea_ActiveCardGfx:
	push de
	ld a, [wCheckMenuPlayAreaWhichDuelist]
	ld h, a
	ld l, DUELVARS_ARENA_CARD
	ld a, [hl]
	cp -1 ; empty play area slot?
	jr z, .no_pokemon

	ld d, a
	ld a, [wCheckMenuPlayAreaWhichDuelist]
	ld b, a
	ldh a, [hWhoseTurn]
	cp b
	ld a, d
	jr nz, .swap
	call LoadCardDataToBuffer1_FromDeckIndex
	jr .draw
.swap
	rst SwapTurn
	call LoadCardDataToBuffer1_FromDeckIndex
	rst SwapTurn

.draw
	ld de, v0Tiles1 + $20 tiles ; destination offset of loaded gfx
	ld hl, wLoadedCard1Gfx
	ld a, [hli]
	ld h, [hl]
	ld l, a
	lb bc, $30, TILE_SIZE
	call LoadCardGfx
	bank1call SetBGP6OrSGB3ToCardPalette
	bank1call FlushAllPalettesOrSendPal23Packet
	pop de

; draw card gfx
	ld a, $a0 ; starting tile number (v0Tiles1 + $20 tiles)
	lb hl, 6, 1
	lb bc, 8, 6 ; width and height of image (in tiles)
	call FillRectangle
	bank1call ApplyBGP6OrSGB3ToCardImage
	ret

.no_pokemon
	pop de
	ret


Func_82b6:
	ld a, [wCheckMenuPlayAreaWhichDuelist]
	ld b, a
	ld a, [wCheckMenuPlayAreaWhichLayout]
	cp b
	ld hl, PrizeCardsCoordinateData_YourOrOppPlayArea.player
	jr z, DrawPlayArea_PrizeCards
	ld hl, PrizeCardsCoordinateData_YourOrOppPlayArea.opponent
;	fallthrough

; draws Prize cards depending on the data stored in wCheckMenuPlayAreaWhichDuelist.
; input:
;	hl = pointer to coordinate data
DrawPlayArea_PrizeCards:
	push hl
	call GetDuelInitialPrizesUpperBitsSet
	ld a, [wCheckMenuPlayAreaWhichDuelist]
	ld h, a
	ld l, DUELVARS_PRIZES
	ld a, [hl]

	pop hl
	ld b, 0
	push af
; loop each prize card
.loop
	inc b
	ld a, [wDuelInitialPrizes]
	inc a
	cp b
	jr z, .done

	pop af
	srl a ; right shift prize cards left
	push af
	ld a, $dc ; tile byte for card
	jr c, .draw
	ld a, $e0 ; tile byte for empty slot
.draw
	ld e, [hl]
	inc hl
	ld d, [hl]
	inc hl

	push hl
	push bc
	lb hl, $01, $02 ; card tile gfx
	lb bc, 2, 2 ; rectangle size
	call FillRectangle

	ld a, [wConsole]
	cp CONSOLE_CGB
	jr nz, .not_cgb
	ld a, $02 ; CGB Background Palette 2 (blue/green)
	lb bc, 2, 2
	lb hl, 0, 0
	call BankswitchVRAM1
	call FillRectangle
	call BankswitchVRAM0
.not_cgb
	pop bc
	pop hl
	jr .loop
.done
	pop af
	ret


PrizeCardsCoordinateData_YourOrOppPlayArea:
; x and y coordinates for the player's prize cards
.player
	db 2, 1
	db 2, 3
	db 4, 1
	db 4, 3
	db 6, 1
	db 6, 3
; x and y coordinates for the opponent's prize cards
.opponent
	db 9, 17
	db 9, 15
	db 7, 17
	db 7, 15
	db 5, 17
	db 5, 15


; used by Func_833c
PrizeCardsCoordinateData_2:
; x and y coordinates for the player's prize cards
.player
	db  6, 0
	db  6, 2
	db  8, 0
	db  8, 2
	db 10, 0
	db 10, 2
; x and y coordinates for the opponent's prize cards
.opponent
	db 4, 18
	db 4, 16
	db 2, 18
	db 2, 16
	db 0, 18
	db 0, 16


PrizeCardsCoordinateData_InPlayArea:
; x and y coordinates for the player's prize cards
.player
	db  9, 1
	db  9, 3
	db 11, 1
	db 11, 3
	db 13, 1
	db 13, 3
; x and y coordinates for the opponent's prize cards
.opponent
	db 6, 17
	db 6, 15
	db 4, 17
	db 4, 15
	db 2, 17
	db 2, 15


; calculates bits set up to the number of initial prizes, with upper 2 bits set, i.e:
; 6 prizes:  a = %11111111
; 4 prizes:  a = %11001111
; 3 prizes:  a = %11000111
; 2 prizes:  a = %11000011
; preserves de and hl
GetDuelInitialPrizesUpperBitsSet:
	ld a, [wDuelInitialPrizes]
	call MakeBitmask
	dec b
	ld a, b
	or %11000000
	ld [wDuelInitialPrizesUpperBitsSet], a
	ret


; currently an unreferenced function
; draws the player's Benched Pokemon and Prizes
DrawPlayersPrizeAndBenchCards::
	xor a
	ld [wTileMapFill], a
	call ZeroObjectPositionsAndToggleOAMCopy
	call DoFrame
	call EmptyScreen
	call LoadSymbolsFont
	call LoadDeckAndDiscardPileIcons

; player cards
	ld a, PLAYER_TURN
	ld [wCheckMenuPlayAreaWhichDuelist], a
	ld [wCheckMenuPlayAreaWhichLayout], a
	ld hl, PrizeCardsCoordinateData_2.player
	call DrawPlayArea_PrizeCards
	lb de, 5, 10 ; coordinates
	ld c, 3 ; spacing
	call DrawPlayArea_BenchCards

; opponent cards
	ld a, OPPONENT_TURN
	ld [wCheckMenuPlayAreaWhichDuelist], a
	ld hl, PrizeCardsCoordinateData_2.opponent
	call DrawPlayArea_PrizeCards
	lb de, 1, 0 ; coordinates
	ld c, 3 ; spacing
;	fallthrough

; draws filled and empty Bench slots depending on the turn loaded in wCheckMenuPlayAreaWhichDuelist.
; if wCheckMenuPlayAreaWhichDuelist is different from wCheckMenuPlayAreaWhichLayout,
; then it adjusts the coordinates of the bench slots.
; input:
;	de = screen coordinates for drawing the Bench icons
;	c  = spacing between slots
DrawPlayArea_BenchCards:
	ld a, [wCheckMenuPlayAreaWhichLayout]
	ld b, a
	ld a, [wCheckMenuPlayAreaWhichDuelist]
	cp b
	jr z, .skip

; adjust the starting Bench position for the opponent
	ld a, d
	add c
	add c
	add c
	add c
	ld d, a
	; d = d + 4 * c

; have the spacing go to the left instead of right
	xor a
	sub c
	ld c, a
	; c = $ff - c + 1

	ld a, [wCheckMenuPlayAreaWhichDuelist]
.skip
	ld h, a
	ld l, DUELVARS_NUMBER_OF_POKEMON_IN_PLAY_AREA
	ld b, [hl]
	ld l, DUELVARS_BENCH1_CARD_STAGE
.loop_1
	dec b ; number of remaining Benched Pokemon
	jr z, .done

	ld a, [hli]
	push hl
	push bc
	add a ; *2
	add a ; *4
	add $e4
	; a holds the correct stage gfx tile
	ld b, a
	push bc

	lb hl, 1, 2
	lb bc, 2, 2
	call FillRectangle

	ld a, [wConsole]
	cp CONSOLE_CGB
	pop bc
	jr nz, .next

	ld a, b
	cp $ec ; tile offset for the Stage 2 icon (v0Tiles1 + $6c tiles)
	jr z, .two_stage
	cp $f0 ; tile offset for the Stage 2 without Stage 1 icon (v0Tiles1 + $70 tiles)
	jr z, .two_stage

	ld a, $02 ; CGB Background Palette 2 (blue/green)
	jr .palette
.two_stage
	ld a, $01 ; CGB Background Palette 1 (red/yellow)
.palette
	lb bc, 2, 2
	lb hl, 0, 0
	call BankswitchVRAM1
	call FillRectangle
	call BankswitchVRAM0

.next ; adjust coordinates for next card
	pop bc
	pop hl
	ld a, d
	add c
	ld d, a
	; d = d + c
	jr .loop_1

.done
	ld a, [wCheckMenuPlayAreaWhichDuelist]
	ld h, a
	ld l, DUELVARS_NUMBER_OF_POKEMON_IN_PLAY_AREA
	ld b, [hl]
	ld a, MAX_PLAY_AREA_POKEMON
	sub b
	ret z ; return if already full

	ld b, a
.loop_2
	push bc
	ld a, $f4 ; empty bench slot tile
	lb hl, 1, 2
	lb bc, 2, 2
	call FillRectangle

	ld a, [wConsole]
	cp CONSOLE_CGB
	jr nz, .not_cgb

	ld a, $02 ; colour
	lb bc, 2, 2
	lb hl, 0, 0
	call BankswitchVRAM1
	call FillRectangle
	call BankswitchVRAM0

.not_cgb
	pop bc
	ld a, d
	add c
	ld d, a
	dec b
	jr nz, .loop_2
	ret


PlayAreaIconCoordinates:
; used for "Your/Opp. Play Area" screen
.player1
	db 15,  6 ; hand
	db 15,  2 ; deck
	db 15,  4 ; discard pile
.opponent1
	db  1,  5 ; hand
	db  1,  9 ; deck
	db  1,  7 ; discard pile

; used for "In Play Area" screen
.player2
	db 15, 13 ; player's hand
	db 15,  9 ; player's deck
	db 15, 11 ; player's discard pile
.opponent2
	db  0,  2 ; opponent's hand
	db  0,  6 ; opponent's deck
	db  0,  4 ; opponent's discard pile


; draws Your/Opp Play Area icons depending on value in a.
; the icons correspond to Deck, Discard Pile, and Hand.
; the corresponding number of cards is printed alongside each icon.
; input:
;	a = $00:  draws player icons
;	a = $01:  draws opponent icons
DrawYourOrOppPlayArea_Icons:
	or a
	ld hl, PlayAreaIconCoordinates.player1
	jr z, .draw
	ld hl, PlayAreaIconCoordinates.opponent1
.draw
	ld a, [wCheckMenuPlayAreaWhichDuelist]
	ld d, a
	jr DrawInPlayArea_Icons.draw

; draws In Play Area icons depending on value in a.
; the icons correspond to Deck, Discard Pile, and Hand.
; the corresponding number of cards is printed alongside each icon.
; input:
;	hl = starting address for coordinate data (either player's or opponent's)
DrawInPlayArea_Icons:
	ldh a, [hWhoseTurn]
	ld d, a
.draw
; hand icon and value
	ld e, DUELVARS_NUMBER_OF_CARDS_IN_HAND
	ld a, [de]
	ld b, a
	ld a, $d0 ; tile offset for hand icon (v0Tiles1 + $50 tiles)
	call DrawPlayArea_IconWithValue

; deck icon and value
	ld e, DUELVARS_NUMBER_OF_CARDS_NOT_IN_DECK
	ld a, [de]
	ld b, a
	ld a, DECK_SIZE
	sub b
	ld b, a
	ld a, $d4 ; tile offset for deck icon (v0Tiles1 + $54 tiles)
	call DrawPlayArea_IconWithValue

; discard pile icon and value
	ld e, DUELVARS_NUMBER_OF_CARDS_IN_DISCARD_PILE
	ld a, [de]
	ld b, a
	ld a, $d8 ; tile offset for discard pile icon (v0Tiles1 + $58 tiles)
;	fallthrough

; draws the interface icon corresponding to the gfx tile in a.
; also prints the number in symbol font corresponding to the value in b.
; the screen coordinates for printing are given by [hl].
; preserves de
; input:
;	a  = tile for the icon
;	b  = number to print alongside the icon
;	hl = pointer to screen coordinates
; output:
;	hl = pointer for next icon's coordinates (input hl + 2)
DrawPlayArea_IconWithValue:
	push de
; drawing the icon
	ld d, [hl]
	inc hl
	ld e, [hl]
	inc hl
	push hl
	push bc
	lb hl, 1, 2
	lb bc, 2, 2
	call FillRectangle

	ld a, [wConsole]
	cp CONSOLE_CGB
	jr nz, .skip

	ld a, $02 ; CGB Background Palette 2 (blue/green)
	lb bc, 2, 2
	lb hl, 0, 0
	call BankswitchVRAM1
	call FillRectangle
	call BankswitchVRAM0

.skip
; adjust coordinate to the lower right
	inc d
	inc d
	inc e
	call InitTextPrinting
	pop bc
	ld a, b
	call CalculateOnesAndTensDigits

	ld hl, wDecimalDigitsSymbols
	ld a, [hli]
	ld b, a
	ld a, [hl]

; loading numerical and cross symbols
	ld hl, wDefaultText
	ld [hl], TX_SYMBOL
	inc hl
	ld [hl], SYM_CROSS
	inc hl
	ld [hl], TX_SYMBOL
	inc hl
	ld [hli], a ; tens place
	ld [hl], TX_SYMBOL
	inc hl
	ld a, b
	ld [hli], a ; ones place
	ld [hl], TX_END

; printing the decimal value
	ld hl, wDefaultText
	call ProcessText
	pop hl
	pop de
	ret


; handles the player's menu input in the Your or Opp. Play Area screens
; and works out which cursor coordinate to go to.
; output:
;	a =  1:  if the A button was pressed
;	a = -1:  if the B button was pressed
;	carry = set:  if either the A or the B button were pressed
HandleCheckMenuInput_YourOrOppPlayArea:
	xor a
	ld [wMenuInputSFX], a
	ld a, [wCheckMenuCursorXPosition]
	ld d, a
	ld a, [wCheckMenuCursorYPosition]
	ld e, a

; d = cursor x position
; e = cursor y position

	ldh a, [hDPadHeld]
	or a
	jr z, .skip

; pad is pressed
	ld a, [wce5e]
	and %10000000
	ldh a, [hDPadHeld]
	jr nz, .check_vertical
	bit B_PAD_LEFT, a ; test left button
	jr nz, .horizontal
	bit B_PAD_RIGHT, a ; test right button
	jr z, .check_vertical

; handle horizontal input
.horizontal
	ld a, [wce5e]
	and %01111111
	or a
	jr nz, .asm_86dd ; jump if wce5e's lower 7 bits aren't set
	ld a, e
	or a
	jr z, .flip_x ; jump if y is 0

	; wce5e = %10000000
	; e = 1
	dec e ; change y position
	jr .flip_x

.asm_86dd
	ld a, e
	or a
	jr nz, .flip_x ; jump if y is not 0
	inc e ; change y position
.flip_x
	ld a, d
	xor $01 ; flip x position
	ld d, a
	jr .erase

.check_vertical
	bit B_PAD_UP, a
	jr nz, .vertical
	bit B_PAD_DOWN, a
	jr z, .skip

; handle vertical input
.vertical
	ld a, d
	or a
	jr z, .flip_y ; jump if x is 0
	dec d
.flip_y
	ld a, e
	xor $01 ; flip y position
	ld e, a

.erase
	ld a, SFX_CURSOR
	ld [wMenuInputSFX], a
	call EraseCheckMenuCursor

; update x and y cursor positions
	ld a, d
	ld [wCheckMenuCursorXPosition], a
	ld a, e
	ld [wCheckMenuCursorYPosition], a

; reset cursor blink
	xor a
	ld [wCheckMenuCursorBlinkCounter], a

.skip
	ldh a, [hKeysPressed]
	and PAD_A | PAD_B
	jr z, .sfx
	and PAD_A
	jr nz, .a_pressed
	; B button pressed
	ld a, -1 ; cancel
	call PlaySFXConfirmOrCancel_Bank2
	scf
	ret

.a_pressed
	call DisplayCheckMenuCursor
	ld a, $1
	call PlaySFXConfirmOrCancel_Bank2
	scf
	ret

.sfx
	ld a, [wMenuInputSFX]
	or a
	call nz, PlaySFX

	ld hl, wCheckMenuCursorBlinkCounter
	ld a, [hl]
	inc [hl]
	and %00001111
	ret nz ; only update cursor if blink's lower nibble is 0

	bit 4, [hl] ; only draw cursor if blink counter's fourth bit is not set
	jp z, DisplayCheckMenuCursor
	jp EraseCheckMenuCursor


; handles the selection menus for the Peek Pokemon Power
HandlePeekSelection::
	call Set_OBJ_8x8
	call LoadCursorTile
; reset wce5c and wIsSwapTurnPending
	xor a
	ld [wce5c], a
	ld [wIsSwapTurnPending], a

; draw play area screen for the turn player
	ldh a, [hWhoseTurn]
	ld h, a
	ld l, a
	call DrawYourOrOppPlayAreaScreen

.check_swap
	ld a, [wIsSwapTurnPending]
	or a
	jr z, .draw_menu_1
; if wIsSwapTurnPending is TRUE, swap turn
	rst SwapTurn
	xor a
	ld [wIsSwapTurnPending], a

; prompt player to choose either own Play Area or opponent's
.draw_menu_1
	ld hl, .PlayAreaMenuParameters
	call InitializeMenuParameters
	call DrawWideTextBox
	ld hl, .YourOrOppPlayAreaData
	call PlaceTextItems

.loop_input_1
	call DoFrame
	call HandleMenuInput
	jr nc, .loop_input_1
	cp -1
	jr z, .loop_input_1 ; can't use the B button to cancel

	call EraseCursor
	ldh a, [hCurMenuItem]
	or a
	jp nz, .PrepareYourPlayAreaSelection ; jump if Opp Play Area

; own Play Area was chosen
	ld a, [wCheckMenuPlayAreaWhichDuelist]
	ld b, a
	ldh a, [hWhoseTurn]
	cp b
	jr z, .text_1

; switch the play area to draw
	ld h, a
	ld l, a
	call DrawYourOrOppPlayAreaScreen
	xor a
	ld [wIsSwapTurnPending], a

.text_1
	call DrawWideTextBox
	lb de, 1, 14
	ldtx hl, WhichCardWouldYouLikeToSeeText
	call InitTextPrinting_ProcessTextFromID

	xor a
	ld [wYourOrOppPlayAreaCurPosition], a
	ld hl, wTransitionTablePtr
	ld a, LOW(PeekYourPlayAreaTransitionTable)
	ld [hli], a
	ld [hl], HIGH(PeekYourPlayAreaTransitionTable)

.loop_input_2
	ld a, $01
	ld [wVBlankOAMCopyToggle], a
	call DoFrame
	call YourOrOppPlayAreaScreen_HandleInput
	jr nc, .loop_input_2
	cp -1
	jr nz, .selection_made
	; B button was pressed
	call ZeroObjectPositionsAndToggleOAMCopy
	jr .check_swap
.selection_made
	ld hl, .SelectionFunctionTable
	call JumpToFunctionInTable
	jr .loop_input_2

.SelectionFunctionTable
REPT 6
	dw .SelectedPrize
ENDR
	dw .SelectedOppsHand
	dw .SelectedDeck

.YourOrOppPlayAreaData
	textitem 2, 14, YourPlayAreaText
	textitem 2, 16, OppPlayAreaText
	db $ff

.PlayAreaMenuParameters
	db 1, 14 ; cursor x, cursor y
	db 2 ; y displacement between items
	db 2 ; number of items
	db SYM_CURSOR_R ; cursor tile number
	db SYM_SPACE ; tile behind cursor
	dw NULL ; function pointer if non-0

.SelectedPrize
	ld a, [wYourOrOppPlayAreaCurPosition]
	ld c, a
	call MakeBitmask
	ld a, DUELVARS_PRIZES
	get_turn_duelist_var
	and b
	ret z ; return if the prize card was already taken

	ld a, c
	add $40
	ld [wce5c], a
	ld a, c
	add DUELVARS_PRIZE_CARDS
	get_turn_duelist_var
	jr .ShowSelectedCard

.SelectedOppsHand
	call CreateHandCardList
	ret c
	ld hl, wDuelTempList
	call ShuffleCards
	ld a, [hl]
	jr .ShowSelectedCard

.SelectedDeck
	call CreateDeckCardList
	ret c
	ld a, %01111111
	ld [wce5c], a
	ld a, [wDuelTempList]
	; fallthrough

; input:
;	a = deck index of the card to load (0-59)
; output:
;	a = wce5c, with upper bit set if turn was swapped
.ShowSelectedCard
	ld b, a
	ld a, [wce5c]
	or a
	jr nz, .display
	; if wce5c is not set, set it as input deck index
	ld a, b
	ld [wce5c], a
.display
	ld a, b
	call LoadCardDataToBuffer1_FromDeckIndex
	call Set_OBJ_8x16
	bank1call OpenCardPage_FromHand
	ld a, $01
	ld [wVBlankOAMCopyToggle], a
	pop af

; if wIsSwapTurnPending is TRUE, swap turn
	ld a, [wIsSwapTurnPending]
	or a
	jr z, .dont_swap
	ld a, [wce5c]
	or %10000000
	jp SwapTurn
.dont_swap
	ld a, [wce5c]
	ret

; prepares menu parameters to handle selection of the opponent's play area
.PrepareYourPlayAreaSelection
	ld a, [wCheckMenuPlayAreaWhichDuelist]
	ld b, a
	ldh a, [hWhoseTurn]
	cp b
	jr nz, .text_2

	ld l, a
	cp PLAYER_TURN
	ld a, OPPONENT_TURN ; if player is turn holder, wCheckMenuPlayAreaWhichDuelist = OPPONENT_TURN
	jr z, .draw_menu_2
	ld a, PLAYER_TURN ; if opponent is turn holder, wCheckMenuPlayAreaWhichDuelist = PLAYER_TURN

.draw_menu_2
	ld h, a
	call DrawYourOrOppPlayAreaScreen

.text_2
	call DrawWideTextBox
	lb de, 1, 14
	ldtx hl, WhichCardWouldYouLikeToSeeText
	call InitTextPrinting_ProcessTextFromID

	xor a
	ld [wYourOrOppPlayAreaCurPosition], a
	ld hl, wTransitionTablePtr
	ld a, LOW(PeekOppPlayAreaTransitionTable)
	ld [hli], a
	ld [hl], HIGH(PeekOppPlayAreaTransitionTable)

	rst SwapTurn
	ld a, TRUE
	ld [wIsSwapTurnPending], a ; mark pending to swap turn
	jp .loop_input_2


; it's related to wMenuInputTablePointer.
; with this table, the cursor moves into the proper location by the input.
; x, y, cursor type (left/right), D-pad up, D-pad down, D-pad right, D-pad left
PeekYourPlayAreaTransitionTable:
	cursor_transition $08, $28, $00, $04, $02, $01, $07 ; top left prize
	cursor_transition $30, $28, $20, $05, $03, $07, $00 ; top right prize
	cursor_transition $08, $38, $00, $00, $04, $03, $07 ; middle left prize
	cursor_transition $30, $38, $20, $01, $05, $07, $02 ; middle right prize
	cursor_transition $08, $48, $00, $02, $00, $05, $07 ; bottom left prize
	cursor_transition $30, $48, $20, $03, $01, $07, $04 ; bottom right prize
	cursor_transition $78, $50, $00, $07, $07, $00, $01 ; your hand (never used)
	cursor_transition $78, $28, $00, $07, $07, $00, $01 ; your deck


PeekOppPlayAreaTransitionTable:
	cursor_transition $a0, $60, $20, $02, $04, $07, $01 ; bottom right prize
	cursor_transition $78, $60, $00, $03, $05, $00, $07 ; bottom left prize
	cursor_transition $a0, $50, $20, $04, $00, $06, $03 ; middle right prize
	cursor_transition $78, $50, $00, $05, $01, $02, $06 ; middle left prize
	cursor_transition $a0, $40, $20, $00, $02, $06, $05 ; top right prize
	cursor_transition $78, $40, $00, $01, $03, $04, $06 ; top left prize
	cursor_transition $08, $38, $00, $07, $07, $05, $04 ; opponent's hand
	cursor_transition $08, $60, $00, $06, $06, $01, $00 ; opponent's deck


; input:
;	a = AI_PEEK_TARGET_* constant
DrawAIPeekScreen::
	ld b, a
	push bc
	call Set_OBJ_8x8
	call LoadCursorTile
	xor a
	ld [wIsSwapTurnPending], a
	ldh a, [hWhoseTurn]
	ld l, a
	ld de, PeekYourPlayAreaTransitionTable
	pop bc
	bit AI_PEEK_TARGET_HAND_F, b
	jr z, .draw_play_area

; AI chose the hand (or the deck)
	rst SwapTurn
	ld a, TRUE
	ld [wIsSwapTurnPending], a ; mark pending to swap turn
	ldh a, [hWhoseTurn]
	ld de, PeekOppPlayAreaTransitionTable
.draw_play_area
	ld h, a
	push bc
	push de
	call DrawYourOrOppPlayAreaScreen
	pop de
	pop bc

; get the right cursor position depending on
; what the AI chose (prize, hand, or deck)
	ld hl, wMenuInputTablePointer
	ld [hl], e
	inc hl
	ld [hl], d
	ld a, b
	and $7f
	cp $7f
	jr nz, .prize_card
	; cursor on the deck
	ld a, $7
	ld [wYourOrOppPlayAreaCurPosition], a
	jr .got_cursor_position
.prize_card
	bit AI_PEEK_TARGET_PRIZE_F, a
	jr z, .hand
	and $3f
	ld [wYourOrOppPlayAreaCurPosition], a
	jr .got_cursor_position
.hand
	ld a, $6
	ld [wYourOrOppPlayAreaCurPosition], a
.got_cursor_position
	call YourOrOppPlayAreaScreen_HandleInput.draw_cursor

	ld a, $1
	ld [wVBlankOAMCopyToggle], a
	ld a, [wIsSwapTurnPending]
	or a
	ret z
	jp SwapTurn


LoadCursorTile:
	ld de, v0Tiles0
	ld hl, .tile_data
	ld b, 16 ; 8 pixels * 8 pixels = 64 pixels, 64 pixels / 4 (2 bits per pixel) = 16 bytes
	jp SafeCopyDataHLtoDE

.tile_data:
	db $e0, $c0, $98, $b0, $84, $8c, $83, $82
	db $86, $8f, $9d, $be, $f4, $f8, $50, $60


; handles input inside the "Your Play Area" or "Opp Play Area" screens
; output:
;	a = -1:  if the B button was pressed
;	carry = set:   if either the A or the B button were pressed
YourOrOppPlayAreaScreen_HandleInput:
	xor a
	ld [wMenuInputSFX], a

; get the transition data for the prize card next to the cursor
	ld hl, wTransitionTablePtr
	ld e, [hl]
	inc hl
	ld d, [hl]
	ld a, [wYourOrOppPlayAreaCurPosition]
	ld [wPrizeCardCursorTemporaryPosition], a
	ld l, a
	ld h, 7 ; length of each transition table item
	call HtimesL
	add hl, de

; get the transition index related to the directional input
	ldh a, [hDPadHeld]
	or a
	jr z, .check_button
	inc hl
	inc hl
	inc hl

	bit B_PAD_UP, a
	jr nz, .process_dpad ; use location in hl if Up button was pressed
	inc hl
	bit B_PAD_DOWN, a
	jr nz, .process_dpad ; use location in hl if Down button was pressed
	inc hl
	bit B_PAD_RIGHT, a
	jr nz, .process_dpad ; use location in hl if Right button was pressed
	inc hl
	bit B_PAD_LEFT, a
	jr z, .check_button ; move on to A/B button if last D-pad direction wasn't pressed
	; use location in hl if Left button was pressed
.process_dpad
	ld a, [hl] ; location from the transition table
	ld [wYourOrOppPlayAreaCurPosition], a
	cp $8 ; if a >= 8
	jr nc, .next

; check if the moved cursor refers to an existing item.
; it's always true when this function was called from the glossary procedure.
.make_bitmask
	call MakeBitmask
	ld a, [wDuelInitialPrizesUpperBitsSet]
	and b
	jr nz, .next

; when no cards exist at the cursor,
	ld a, [wPrizeCardCursorTemporaryPosition]
	cp $06
	jr nz, YourOrOppPlayAreaScreen_HandleInput
	; move once more in the direction (recursively) until it reaches an existing item.

; check if either the left or right dpad is pressed.
; if not, just go back to the start.
	ldh a, [hDPadHeld]
	bit B_PAD_RIGHT, a
	jr nz, .left_or_right
	bit B_PAD_LEFT, a
	jr z, YourOrOppPlayAreaScreen_HandleInput

.left_or_right
	; if started with 5 or 6 prize cards,
	; can switch sides normally
	ld a, [wDuelInitialPrizes]
	cp PRIZES_5
	jr nc, .next
	; else if it's last card, place it at position 3
	ld a, [wYourOrOppPlayAreaCurPosition]
	cp 5
	ld a, 3
	jr z, .ok
	; otherwise, place at position 2
	dec a ; 2
.ok
	ld [wYourOrOppPlayAreaCurPosition], a
	ld a, [wDuelInitialPrizes]
	cp PRIZES_3
	jr nc, .handled_cursor_pos
	; in this case, we can just subtract 2 from the position
	ld a, [wYourOrOppPlayAreaCurPosition]
	sub 2
	ld [wYourOrOppPlayAreaCurPosition], a

.handled_cursor_pos
	ld a, [wYourOrOppPlayAreaCurPosition]
	ld [wPrizeCardCursorTemporaryPosition], a
	jr .make_bitmask

.next
	ld a, SFX_CURSOR
	ld [wMenuInputSFX], a

; reset cursor blink
	xor a
	ld [wCheckMenuCursorBlinkCounter], a
.check_button
	ldh a, [hKeysPressed]
	and PAD_A | PAD_B
	jr z, .return

	and PAD_A
	jr nz, .a_button

	ld a, -1 ; cancel
	call PlaySFXConfirmOrCancel_Bank2
	scf
	ret

.a_button
	call .draw_cursor
	ld a, [wYourOrOppPlayAreaCurPosition]
	call PlaySFXConfirmOrCancel_Bank2
	scf
	ret

.return
	ld a, [wMenuInputSFX]
	or a
	call nz, PlaySFX
	ld hl, wCheckMenuCursorBlinkCounter
	ld a, [hl]
	inc [hl]
	and (1 << 4) - 1
	ret nz
	bit 4, [hl]
	jp nz, ZeroObjectPositionsAndToggleOAMCopy

.draw_cursor
	call ZeroObjectPositions
	ld hl, wTransitionTablePtr
	ld e, [hl]
	inc hl
	ld d, [hl]
	ld a, [wYourOrOppPlayAreaCurPosition]
	ld l, a
	ld h, 7
	call HtimesL
	add hl, de
	; hl = [wTransitionTablePtr] + 7 * wce52
	ld d, [hl]
	inc hl
	ld e, [hl]
	inc hl
	ld b, [hl]
	ld c, $00
	call SetOneObjectAttributes
	or a
	ret


; handles the screen for the Player to select prize card(s)
_SelectPrizeCards::
	xor a
	call GetFirstSetPrizeCard
	ld [wYourOrOppPlayAreaCurPosition], a
	ld hl, wSelectedPrizeCardListPtr
	ld a, LOW(hTempPlayAreaLocation_ffa1)
	ld [hli], a
	ld [hl], HIGH(hTempPlayAreaLocation_ffa1)

.check_prize_cards_to_select
	ld a, [wNumberOfPrizeCardsToSelect]
	or a
	jr z, .done_selection
	ld a, DUELVARS_PRIZES
	get_turn_duelist_var
	or a
	jr nz, .got_prizes

.done_selection
	ld a, DUELVARS_PRIZES
	get_turn_duelist_var
	ldh [hTemp_ffa0], a
	ld hl, wSelectedPrizeCardListPtr
	ld a, [hli]
	ld h, [hl]
	ld l, a
	ld [hl], $ff
	ret

.got_prizes
	ldh a, [hWhoseTurn]
	ld h, a
	ld l, a
	call DrawYourOrOppPlayAreaScreen
	call DrawWideTextBox
	lb de, 1, 14
	ldtx hl, PleaseChooseAPrizeText
	call InitTextPrinting_ProcessTextFromID
	ld hl, wMenuInputTablePointer
	ld a, LOW(.cursor_transition_table)
	ld [hli], a
	ld [hl], HIGH(.cursor_transition_table)
.loop_handle_input
	ld a, $1
	ld [wVBlankOAMCopyToggle], a
	call DoFrame
	call YourOrOppPlayAreaScreen_HandleInput
	jr nc, .loop_handle_input
	cp -1
	jr z, .loop_handle_input ; must choose, B button can't be used to exit

	call ZeroObjectPositionsAndToggleOAMCopy

; get prize bit mask that corresponds to the one pointed at by the cursor
	ld a, [wYourOrOppPlayAreaCurPosition]
	ld c, a
	call MakeBitmask
	ld a, DUELVARS_PRIZES
	get_turn_duelist_var
	and b
	jr z, .loop_handle_input ; return to input loop if cursor prize is not set

	; remove prize
	ld a, DUELVARS_PRIZES
	get_turn_duelist_var
	sub b
	ld [hl], a

	; get its deck index
	ld a, c
	add DUELVARS_PRIZE_CARDS
	get_turn_duelist_var

	ld hl, wSelectedPrizeCardListPtr
	ld e, [hl]
	inc hl
	ld d, [hl]
	ld [de], a ; store deck index
	inc de
	ld [hl], d
	dec hl
	ld [hl], e

	; add prize card to hand
	call AddCardToHand
	call LoadCardDataToBuffer1_FromDeckIndex
	call Set_OBJ_8x16
	bank1call OpenCardPage_FromHand
	ld a, [wNumberOfPrizeCardsToSelect]
	dec a
	ld [wNumberOfPrizeCardsToSelect], a
	ld a, [wYourOrOppPlayAreaCurPosition]
	call GetFirstSetPrizeCard
	ld [wYourOrOppPlayAreaCurPosition], a
	jp .check_prize_cards_to_select

.cursor_transition_table
	cursor_transition $08, $28, $00, $04, $02, $01, $01
	cursor_transition $30, $28, $20, $05, $03, $00, $00
	cursor_transition $08, $38, $00, $00, $04, $03, $03
	cursor_transition $30, $38, $20, $01, $05, $02, $02
	cursor_transition $08, $48, $00, $02, $00, $05, $05
	cursor_transition $30, $48, $20, $03, $01, $04, $04


_DrawPlayAreaToPlacePrizeCards::
	xor a
	ld [wTileMapFill], a
	call ZeroObjectPositions
	call EmptyScreen
	call LoadSymbolsFont
	call LoadPlacingThePrizesScreenTiles

	ldh a, [hWhoseTurn]
	ld [wCheckMenuPlayAreaWhichLayout], a
	ld [wCheckMenuPlayAreaWhichDuelist], a

	lb de, 0, 10
	ld c, 3
	call DrawPlayArea_BenchCards
	ld hl, .player_icon_coordinates
	call DrawYourOrOppPlayArea_Icons.draw
	; draw the facedown card image for the player's Active Pokemon
	lb de, 8, 6 ; screen coordinates for top left tile
	ld a, $a0 ; starting tile number (v0Tiles1 + $20 tiles)
	lb hl, 1, 4
	lb bc, 4, 3 ; width and height of image (in tiles)
	call FillRectangle

	rst SwapTurn
	ldh a, [hWhoseTurn]
	ld [wCheckMenuPlayAreaWhichDuelist], a
	lb de, 6, 0
	ld c, 3
	call DrawPlayArea_BenchCards
	ld hl, .opp_icon_coordinates
	call DrawYourOrOppPlayArea_Icons.draw
	; draw the facedown card image for the opponent's Active Pokemon
	lb de, 8, 3 ; screen coordinates for top left tile
	ld a, $a0 ; starting tile number (v0Tiles1 + $20 tiles)
	lb hl, 1, 4
	lb bc, 4, 3 ; width and height of image (in tiles)
	call FillRectangle
	jp SwapTurn

.player_icon_coordinates
	db 15, 10
	db 15,  6
	db 15,  8

.opp_icon_coordinates
	db  0,  0
	db  0,  4
	db  0,  2


; gets the first prize card index that is set,
; starting with the index in register a.
; preserves all registers except af
; input:
;	a = prize card index
GetFirstSetPrizeCard:
	push bc
	push de
	push hl
	ld e, PRIZES_6
	ld c, a
	ldh a, [hWhoseTurn]
	ld h, a
	ld l, DUELVARS_PRIZES
	ld d, [hl]
.loop_prizes
	push bc
	ld a, c
	call MakeBitmask
	ld a, b
	pop bc
	and d
	jr nz, .done ; prize is set
	dec e
	jr nz, .next_prize
	ld c, 0
.done
	ld a, c ; first prize index that is set
	pop hl
	pop de
	pop bc
	ret

.next_prize
	inc c
	ld a, PRIZES_6
	cp c
	jr nz, .loop_prizes
	ld c, 0
	jr .loop_prizes


; left-shift b a number of times corresponding to input in a.
; preserves all registers except af and b
; input:
;	a = number of times to loop
; output:
;	b = (1 << a)
MakeBitmask:
	ld b, $1
.loop
	or a
	ret z
	sla b
	dec a
	jr .loop


;----------------------------------------
;        UNREFERENCED FUNCTIONS
;----------------------------------------
;
; prints "Hand x_" to represent the amount of cards in a player's hand
; input:
;	b = number to print alongside text
;	hl = pointer to screen coordinates
;DrawPlayArea_HandText:
;	ld d, [hl]
;	inc hl
;	ld e, [hl]
;	inc hl
;
;	; text
;	push hl
;	ldtx hl, HandText
;	call InitTextPrinting_ProcessTextFromID
;
;	; decimal value
;	ld a, b
;	call CalculateOnesAndTensDigits
;	ld hl, wDecimalDigitsSymbols
;	ld a, [hli]
;	ld b, a
;	ld a, [hl]
;
;	ld hl, wDefaultText
;	ld [hl], TX_SYMBOL
;	inc hl
;	ld [hl], SYM_CROSS
;	inc hl
;	ld [hl], TX_SYMBOL
;	inc hl
;	ld [hli], a
;	ld [hl], TX_SYMBOL
;	inc hl
;
;	; draw to screen
;	ld a, b
;	ld [hli], a
;	ld [hl], TX_END
;	ld hl, wDefaultText
;	call ProcessText
;	pop hl
;	ret
;
;
; seems like a function to draw prize cards
; input:
;	hl = pointer to a list of coordinates
;Func_8bf2:
;	push hl
;	ld a, [wCheckMenuPlayAreaWhichDuelist]
;	ld h, a
;	ld l, DUELVARS_PRIZES
;	ld a, [hl]
;	pop hl
;
;	ld b, 0
;	push af
;.loop_prize_cards
;	inc b
;	ld a, [wDuelInitialPrizes]
;	inc a
;	cp b
;	jr z, .done
;	pop af
;	srl a
;	push af
;	jr c, .not_taken
;	; same tile whether the prize card is taken or not
;	ld a, $ac
;	jr .got_tile
;.not_taken
;	ld a, $ac
;.got_tile
;	ld e, [hl]
;	inc hl
;	ld d, [hl]
;	inc hl
;	push hl
;	push bc
;	lb hl, 0, 0
;	lb bc, 1, 1
;	call FillRectangle
;	ld a, [wConsole]
;	cp CONSOLE_CGB
;	jr nz, .skip_pal
;	ld a, $02
;	lb bc, 1, 1
;	lb hl, 0, 0
;	call BankswitchVRAM1
;	call FillRectangle
;	call BankswitchVRAM0
;.skip_pal
;	pop bc
;	pop hl
;	jr .loop_prize_cards
;.done
;	pop af
;	ret
;
;
; unknown data
;Data_8c3f:
;	db $06, $05, $06, $06, $07, $05, $07, $06
;	db $08, $05, $08, $06, $05, $0e, $05, $0d
;	db $04, $0e, $04, $0d, $03, $0e, $03, $0d
