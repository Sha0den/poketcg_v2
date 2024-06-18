; initializes parameters for a card list (e.g. hand cards in a duel or cards from a booster pack)
; preserves bc and de
; input:
;	a = number of cards in the list
;	de = initial page scroll offset, initial item (in the visible page)
;	hl = 9 bytes with the rest of the parameters
InitializeCardListParameters::
	ld [wNumListItems], a
	ld a, d
	ld [wListScrollOffset], a
	ld a, e
	ld [wCurMenuItem], a
	add d
	ldh [hCurMenuItem], a
	ld a, [hli]
	ld [wMenuCursorXOffset], a
	ld a, [hli]
	ld [wMenuCursorYOffset], a
	ld a, [hli]
	ld [wListItemXPosition], a
	ld a, [hli]
	ld [wListItemNameMaxLength], a
	ld a, [hli]
	ld [wNumMenuItems], a
	ld a, [hli]
	ld [wMenuVisibleCursorTile], a
	ld a, [hli]
	ld [wMenuInvisibleCursorTile], a
	ld a, [hli]
	ld [wListFunctionPointer], a
	ld a, [hli]
	ld [wListFunctionPointer + 1], a
	xor a
	ld [wCursorBlinkCounter], a
	ld a, 1
	ld [wMenuYSeparation], a
	ret


; used for card list screens like the Hand or Discard Pile
; similar to HandleMenuInput, but conveniently returns parameters
; related to the state of the list in a, d, and e if A or B were pressed.
; output:
;	d = [wListScrollOffset]
;	e = [wCurMenuItem]
;	a = [hCurMenuItem] ($ff if the B button was pressed)
;	carry = set:  if either the A or the B button were pressed
HandleCardListInput::
	call HandleMenuInput
	ret nc
	ld a, [wListScrollOffset]
	ld d, a
;	ld a, [wCurMenuItem]
;	ld e, a ; already set by HandleMenuInput
	ldh a, [hCurMenuItem]
	ret


; initializes parameters for a menu, given the 8 bytes starting at hl,
; which are loaded to the following addresses:
;	wMenuCursorXOffset, wMenuCursorYOffset, wMenuYSeparation, wNumMenuItems,
;	wMenuVisibleCursorTile, wMenuInvisibleCursorTile, wMenuUpdateFunc.
; also sets the current menu item (wCurMenuItem) to the one specified in register a.
; input:
;	a = current menu item
;	hl = menu parameter data to use
InitializeMenuParameters::
	ld [wCurMenuItem], a
	ldh [hCurMenuItem], a
	ld de, wMenuCursorXOffset
	ld b, wMenuParamsEnd - wMenuParams
.loop
	ld a, [hli]
	ld [de], a
	inc de
	dec b
	jr nz, .loop
	xor a
	ld [wCursorBlinkCounter], a
	ret


; note: output values still subject to those of the function at [wMenuUpdateFunc], if any
; output:
;	a =  0:  if the A button was pressed
;	a = -1:  if the B button was pressed
;	carry = set:  if either the A or the B button were pressed
HandleMenuInput::
	xor a
	ld [wRefreshMenuCursorSFX], a
	ldh a, [hDPadHeld]
	or a
	jr z, .up_down_done
	ld b, a
	ld a, [wNumMenuItems]
	ld c, a
	ld a, [wCurMenuItem]
	bit D_UP_F, b
	jr z, .not_up
	dec a
	bit 7, a
	jr z, .handle_up_or_down
	ld a, [wNumMenuItems]
	dec a ; wrapping around, so load the bottommost item
	jr .handle_up_or_down
.not_up
	bit D_DOWN_F, b
	jr z, .up_down_done
	inc a
	cp c
	jr c, .handle_up_or_down
	xor a ; wrapping around, so load the topmost item
.handle_up_or_down
	push af
	ld a, $1
	ld [wRefreshMenuCursorSFX], a ; buffer sound for up/down
	call EraseCursor
	pop af
	ld [wCurMenuItem], a
	xor a
	ld [wCursorBlinkCounter], a
.up_down_done
	ld a, [wCurMenuItem]
	ldh [hCurMenuItem], a
	ld hl, wMenuUpdateFunc ; call the function if non-0 (periodically)
	ld a, [hli]
	or [hl]
	jr z, .check_A_or_B
	ld a, [hld]
	ld l, [hl]
	ld h, a
	ldh a, [hCurMenuItem]
	call CallHL
	jr nc, RefreshMenuCursor_CheckPlaySFX
.A_pressed_draw_cursor
	call DrawCursor2
.A_pressed
	call PlayOpenOrExitScreenSFX
	ld a, [wCurMenuItem]
	ld e, a
	ldh a, [hCurMenuItem]
	scf
	ret
.check_A_or_B
	ldh a, [hKeysPressed]
	and A_BUTTON | B_BUTTON
	jr z, RefreshMenuCursor_CheckPlaySFX
	and A_BUTTON
	jr nz, .A_pressed_draw_cursor
	; B button pressed
	ld a, [wCurMenuItem]
	ld e, a
	ld a, $ff
	ldh [hCurMenuItem], a
	call PlayOpenOrExitScreenSFX
	scf
	ret


; plays an "open screen" sound (SFX_CONFIRM) if [hCurMenuItem] != 0xff
; plays an "exit screen" sound (SFX_CANCEL) if [hCurMenuItem] == 0xff
; preserves all registers
PlayOpenOrExitScreenSFX::
	push af
	ldh a, [hCurMenuItem]
	inc a
	jr z, .play_exit_sfx
	ld a, SFX_CONFIRM
	jr .play_sfx
.play_exit_sfx
	ld a, SFX_CANCEL
.play_sfx
	call PlaySFX
	pop af
	ret


; called once per frame when a menu is open
; plays the sound effect at wRefreshMenuCursorSFX (if non-0)
; and blinks the cursor when wCursorBlinkCounter hits 16 (i.e. every 16 frames)
RefreshMenuCursor_CheckPlaySFX::
	ld a, [wRefreshMenuCursorSFX]
	or a
	jr z, RefreshMenuCursor
	call PlaySFX
;	fallthrough

RefreshMenuCursor::
	ld hl, wCursorBlinkCounter
	ld a, [hl]
	inc [hl]
; blink the cursor every 16 frames
	and $f
	ret nz
	ld a, [wMenuVisibleCursorTile]
	bit 4, [hl]
	jr z, DrawCursor
;	fallthrough

; sets the tile at [wMenuCursorXOffset],[wMenuCursorYOffset] to [wMenuInvisibleCursorTile]
EraseCursor::
	ld a, [wMenuInvisibleCursorTile]
;	fallthrough

; sets the tile at [wMenuCursorXOffset],[wMenuCursorYOffset] to a
; input:
;	a = which sprite to draw
DrawCursor::
	ld c, a
	ld a, [wMenuYSeparation]
	ld l, a
	ld a, [wCurMenuItem]
	ld h, a
	call HtimesL
	ld a, l
	ld hl, wMenuCursorXOffset
	ld d, [hl]
	inc hl
	add [hl]
	ld e, a
	call AdjustCoordinatesForBGScroll
	ld a, c
	ld c, e
	ld b, d
	call WriteByteToBGMap0
	or a
	ret

; sets the tile at [wMenuCursorXOffset],[wMenuCursorYOffset] to [wMenuVisibleCursorTile]
DrawCursor2::
	ld a, [wMenuVisibleCursorTile]
	jr DrawCursor


; sets wCurMenuItem and hCurMenuItem to a and clears wCursorBlinkCounter
; preserves all registers except af
; input:
;	a = new menu item
SetMenuItem::
	ld [wCurMenuItem], a
	ldh [hCurMenuItem], a
	xor a
	ld [wCursorBlinkCounter], a
	ret


; handles input for the 2-row 3-column duel menu.
; only handles input not involving the B, START, or SELECT buttons, that is,
; navigating through the menu or selecting an item with the A button.
; other input is handled by PrintDuelMenuAndHandleInput.handle_input
HandleDuelMenuInput::
	ldh a, [hDPadHeld]
	or a
	jr z, .blink_cursor
	ld b, a
	ld hl, wCurMenuItem
	and D_UP | D_DOWN
	jr z, .check_left
	ld a, [hl]
	xor 1 ; move to the other menu item in the same column
	jr .dpad_pressed
.check_left
	bit D_LEFT_F, b
	jr z, .check_right
	ld a, [hl]
	sub 2
	jr nc, .dpad_pressed
	; wrap to the rightmost item in the same row
	and 1
	add 4
	jr .dpad_pressed
.check_right
	bit D_RIGHT_F, b
	jr z, .dpad_not_pressed
	ld a, [hl]
	add 2
	cp 6
	jr c, .dpad_pressed
	; wrap to the leftmost item in the same row
	and 1
.dpad_pressed
	push af
	ld a, SFX_CURSOR
	call PlaySFX
	call .erase_cursor
	pop af
	ld [wCurMenuItem], a
	ldh [hCurMenuItem], a
	xor a
	ld [wCursorBlinkCounter], a
	jr .blink_cursor
.dpad_not_pressed
	ldh a, [hDPadHeld]
	and A_BUTTON
	jp nz, HandleMenuInput.A_pressed
.blink_cursor
	; blink cursor every 16 frames
	ld hl, wCursorBlinkCounter
	ld a, [hl]
	inc [hl]
	and $f
	ret nz
	ld a, SYM_CURSOR_R
	bit 4, [hl]
	jr z, .draw_cursor
.erase_cursor
	ld a, SYM_SPACE
.draw_cursor
	ld e, a
	ld a, [wCurMenuItem]
	add a
	ld c, a
	ld b, $0
	ld hl, DuelMenuCursorCoords
	add hl, bc
	ld b, [hl]
	inc hl
	ld c, [hl]
	ld a, e
	call WriteByteToBGMap0
	ld a, [wCurMenuItem]
	ld e, a
	or a
	ret


DuelMenuCursorCoords::
	db  2, 14 ; Hand
	db  2, 16 ; Attack
	db  8, 14 ; Check
	db  8, 16 ; Pkmn Power
	db 14, 14 ; Retreat
	db 14, 16 ; Done


; prints the items of a list of cards (e.g. hand cards in a duel or cards from a booster pack)
; and initializes the parameters of the list given
; input:
;	wDuelTempList = card list source
;	a = number of cards in the list
;	de = initial page scroll offset, initial item (in the visible page)
;	hl = 9 bytes with the rest of the parameters
PrintCardListItems::
	call InitializeCardListParameters
	ld hl, wMenuUpdateFunc
	ld a, LOW(CardListMenuFunction)
	ld [hli], a
	ld a, HIGH(CardListMenuFunction)
	ld [hli], a
	ld a, 2
	ld [wMenuYSeparation], a
	ld a, 1
	ld [wCardListIndicatorYPosition], a
;	fallthrough

; like PrintCardListItems, except more parameters are already initialized
; called instead of PrintCardListItems to reload the list after moving up or down
ReloadCardListItems::
	ld e, SYM_SPACE
	ld a, [wListScrollOffset]
	or a
	jr z, .cant_go_up
	ld e, SYM_CURSOR_U
.cant_go_up
	ld a, [wMenuCursorYOffset]
	dec a
	ld c, a
	ld b, 18
	ld a, e
	call WriteByteToBGMap0
	ld e, SYM_SPACE
	ld a, [wListScrollOffset]
	ld hl, wNumMenuItems
	add [hl]
	ld hl, wNumListItems
	cp [hl]
	jr nc, .cant_go_down
	ld e, SYM_CURSOR_D
.cant_go_down
	ld a, [wNumMenuItems]
	add a
	add c
	dec a
	ld c, a
	ld a, e
	call WriteByteToBGMap0
	ld a, [wListScrollOffset]
	ld e, a
	ld d, $00
	ld hl, wDuelTempList
	add hl, de
	ld a, [wNumMenuItems]
	ld b, a
	ld a, [wListItemXPosition]
	ld d, a
	ld a, [wMenuCursorYOffset]
	ld e, a
	ld c, $00
.next_card
	ld a, [hl]
	cp $ff
	ret z ; done
	push hl
	push bc
	push de
	call LoadCardDataToBuffer1_FromDeckIndex
	call DrawCardSymbol
	call InitTextPrinting
	ld a, [wListItemNameMaxLength]
	call CopyCardNameAndLevel
	ld hl, wDefaultText
	call ProcessText
	pop de
	pop bc
	pop hl
	inc hl
	ld a, [wNumListItems]
	dec a
	inc c
	cp c
	ret c ; done
	inc e
	inc e
	dec b
	jr nz, .next_card
	ret


; this function is always loaded to wMenuUpdateFunc by PrintCardListItems
; takes care of things like handling page scrolling and calling the function at wListFunctionPointer
CardListMenuFunction::
	ldh a, [hDPadHeld]
	ld b, a
	ld a, [wNumMenuItems]
	dec a
	ld c, a
	ld a, [wCurMenuItem]
	bit D_UP_F, b
	jr z, .not_up
	cp c
	jp nz, .continue
	; we're at the top of the page
	xor a
	ld [wCurMenuItem], a ; set to first item
	ld hl, wListScrollOffset
	ld a, [hl]
	or a ; can we scroll up?
	jr z, .no_more_items
	dec [hl] ; scroll page up
	call ReloadCardListItems
	jp .continue
.not_up
	bit D_DOWN_F, b
	jr z, .not_down
	or a
	jr nz, .not_last_visible_item
	; we're at the bottom of the page
	ld a, c
	ld [wCurMenuItem], a ; set to last item
	ld a, [wListScrollOffset]
	add c
	inc a
	ld hl, wNumListItems
	cp [hl] ; can we scroll down?
	jr z, .no_more_items
	ld hl, wListScrollOffset
	inc [hl] ; scroll page down
	call ReloadCardListItems
	jp .continue
.not_last_visible_item
	; this appears to be a redundant check
	ld hl, wListScrollOffset
	add [hl]
	ld hl, wNumListItems
	cp [hl]
	jp c, .continue ; should always jump
	ld hl, wCurMenuItem
	dec [hl]
.no_more_items
	xor a
	ld [wRefreshMenuCursorSFX], a
	jp .continue
.not_down
	bit D_LEFT_F, b
	jr z, .not_left
	ld a, [wListScrollOffset]
	or a
	jr z, .continue
	ld hl, wNumMenuItems
	sub [hl]
	jr c, .top_of_page_reached
	ld [wListScrollOffset], a
	call ReloadCardListItems
	jr .continue
.top_of_page_reached
	call EraseCursor
	ld a, [wListScrollOffset]
	ld hl, wCurMenuItem
	add [hl]
	ld c, a
	ld hl, wNumMenuItems
	sub [hl]
	jr nc, .asm_28c4
	add [hl]
.asm_28c4
	ld [wCurMenuItem], a
	xor a
	ld [wListScrollOffset], a
	ld [wRefreshMenuCursorSFX], a
	call ReloadCardListItems
	jr .continue
.not_left
	bit D_RIGHT_F, b
	jr z, .continue
	ld a, [wNumMenuItems]
	ld hl, wNumListItems
	cp [hl]
	jr nc, .continue
	ld a, [wListScrollOffset]
	ld hl, wNumMenuItems
	add [hl]
	ld c, a
	add [hl]
	dec a
	ld hl, wNumListItems
	cp [hl]
	jr nc, .asm_28f9
	ld a, c
	ld [wListScrollOffset], a
	call ReloadCardListItems
	jr .continue
.asm_28f9
	call EraseCursor
	ld a, [wListScrollOffset]
	ld hl, wCurMenuItem
	add [hl]
	ld c, a
	ld a, [wNumListItems]
	ld hl, wNumMenuItems
	sub [hl]
	ld [wListScrollOffset], a
	ld b, a
	ld a, c
	sub b
	jr nc, .asm_2914
	add [hl]
.asm_2914
	ld [wCurMenuItem], a
	call ReloadCardListItems
.continue
	ld a, [wListScrollOffset]
	ld hl, wCurMenuItem
	add [hl]
	ldh [hCurMenuItem], a
	ld a, [wCardListIndicatorYPosition]
	cp $ff
	jr z, .skip_printing_indicator
	; print <sel_item>/<num_items>
	; adjusts printing to account for single digit numbers
	ld c, a
	ld b, 16
	ld a, [wNumListItems]
	call TwoDigitNumberToTxSymbol
	ld a, [hl]
	cp SYM_0
	jr nz, .two_digits
	ld [hl], SYM_SLASH
	ld a, 2
	call CopyDataToBGMap0
	jr .current_item_number
.two_digits
	ld a, 2
	call CopyDataToBGMap0
	dec b
	ld a, SYM_SLASH
	call WriteByteToBGMap0
.current_item_number
	dec b
	dec b
	ldh a, [hCurMenuItem]
	inc a
	call TwoDigitNumberToTxSymbol_TrimLeadingZero
	ld a, 2
	call CopyDataToBGMap0
.skip_printing_indicator
	ld hl, wListFunctionPointer
	ld a, [hli]
	or [hl]
	jr z, .no_list_function
	ld a, [hld]
	ld l, [hl]
	ld h, a
	ldh a, [hCurMenuItem]
	jp hl ; execute the function at wListFunctionPointer
.no_list_function
	ldh a, [hKeysPressed]
	and A_BUTTON | B_BUTTON
	ret z
	and B_BUTTON
	jr nz, .pressed_b
	scf
	ret
.pressed_b
	ld a, $ff
	ldh [hCurMenuItem], a
	scf
	ret


; translates the TYPE_* constant in wLoadedCard1Type to an index for CardSymbolTable
; preserves all registers except af
CardTypeToSymbolID::
	ld a, [wLoadedCard1Type]
	cp TYPE_TRAINER
	jr nc, .trainer_card
	cp TYPE_ENERGY
	jr c, .pokemon_card
	; Energy card
	and 7 ; match TYPE_ENERGY_* with the appropriate Energy icon
	ret
.trainer_card
	ld a, 11 ; use the T icon
	ret
.pokemon_card
	ld a, [wLoadedCard1Stage] ; different symbol for each stage of evolution
	add 8
	ret


; uses the TYPE_* constant in wLoadedCard1Type to find the relevant entry in CardSymbolTable
; preserves de
; output:
;	hl = pointing to an entry from CardSymbolTable
;	a = starting tile number of the symbol being drawn (ICON_TILE_* constant)
GetCardSymbolData::
	call CardTypeToSymbolID
	add a ; double number to account for palette data
	ld c, a
	ld b, 0
	ld hl, CardSymbolTable
	add hl, bc
	ld a, [hl]
	ret


; draws, at de, the 2x2 tile card symbol associated to the TYPE_* constant in wLoadedCard1Type
; preserves all registers except af
; input:
;	de = coordinates at which to begin drawing the symbol
;	hl = pointing to an entry from CardSymbolTable
DrawCardSymbol::
	push hl
	push de
	push bc
	call GetCardSymbolData
	dec d
	dec d
	dec e
	ld a, [wConsole]
	cp CONSOLE_CGB
	jr nz, .tiles
	; CGB-only attrs (palette)
	push hl
	inc hl
	ld a, [hl]
	lb bc, 2, 2
	lb hl, 0, 0
	call BankswitchVRAM1
	call FillRectangle
	call BankswitchVRAM0
	pop hl
.tiles
	ld a, [hl]
	lb hl, 1, 2
	lb bc, 2, 2
	call FillRectangle
	pop bc
	pop de
	pop hl
	ret


CardSymbolTable::
; starting tile number, cgb palette (grey, yellow/red, green/blue, pink/orange)
	db ICON_TILE_FIRE,            $01 ; TYPE_ENERGY_FIRE
	db ICON_TILE_GRASS,           $02 ; TYPE_ENERGY_GRASS
	db ICON_TILE_LIGHTNING,       $01 ; TYPE_ENERGY_LIGHTNING
	db ICON_TILE_WATER,           $02 ; TYPE_ENERGY_WATER
	db ICON_TILE_FIGHTING,        $03 ; TYPE_ENERGY_PSYCHIC
	db ICON_TILE_PSYCHIC,         $03 ; TYPE_ENERGY_FIGHTING
	db ICON_TILE_COLORLESS,       $00 ; TYPE_ENERGY_DOUBLE_COLORLESS
	db ICON_TILE_ENERGY,          $02 ; TYPE_ENERGY_UNUSED
	db ICON_TILE_BASIC_POKEMON,   $02 ; TYPE_PKMN_*, Basic
	db ICON_TILE_STAGE_1_POKEMON, $02 ; TYPE_PKMN_*, Stage 1
	db ICON_TILE_STAGE_2_POKEMON, $01 ; TYPE_PKMN_*, Stage 2
	db ICON_TILE_TRAINER,         $02 ; TYPE_TRAINER


; copies the name and level of the card at wLoadedCard1 to wDefaultText
; preserves bc and de
; input:
;	a = length in number of tiles (the resulting string will be padded with spaces to match it)
CopyCardNameAndLevel::
	farcall _CopyCardNameAndLevel
	ret


; sets cursor parameters for navigating in a text box, but using
; default values for the cursor tile (SYM_CURSOR_R) and the tile behind it (SYM_SPACE).
; input:
;	de = coordinates of the cursor
SetCursorParametersForTextBox_Default::
	lb bc, SYM_CURSOR_R, SYM_SPACE ; cursor tile, tile behind cursor
	call SetCursorParametersForTextBox
;	fallthrough

; waits for the player to press either the A or the B button
; output:
;	carry = set:      if the A button was pressed
;	carry = not set:  if the B button was pressed
WaitForButtonAorB::
	call DoFrame
	call RefreshMenuCursor
	ldh a, [hKeysPressed]
	bit A_BUTTON_F, a
	jr nz, .a_pressed
	bit B_BUTTON_F, a
	jr z, WaitForButtonAorB
	call EraseCursor
	scf
	ret
.a_pressed
	call EraseCursor
	or a
	ret


; sets cursor parameters for navigating in a text box
; preserves bc and de
; input:
;	bc = tile numbers of the cursor and of the tile behind it
;	de = coordinates of the cursor
SetCursorParametersForTextBox::
	xor a
	ld hl, wCurMenuItem
	ld [hli], a
	ld [hl], d ; wMenuCursorXOffset
	inc hl
	ld [hl], e ; wMenuCursorYOffset
	inc hl
	ld [hl], 0 ; wMenuYSeparation
	inc hl
	ld [hl], 1 ; wNumMenuItems
	inc hl
	ld [hl], b ; wMenuVisibleCursorTile
	inc hl
	ld [hl], c ; wMenuInvisibleCursorTile
	ld [wCursorBlinkCounter], a
	ret


; draws a 20x6 text box aligned to the bottom of the screen,
; prints the text at hl without letter delay, and waits for A or B to be pressed
; input:
;	hl = text to print
DrawWideTextBox_PrintTextNoDelay_Wait::
	call DrawWideTextBox_PrintTextNoDelay
	jr WaitForWideTextBoxInput


; draws a 20x6 text box aligned to the bottom of the screen
; and prints the text at hl without letter delay
; input:
;	hl = text to print
DrawWideTextBox_PrintTextNoDelay::
	push hl
	call DrawWideTextBox
	ld a, 19
	jr DrawTextBox_PrintTextNoDelay


; draws a 12x6 text box aligned to the bottom left of the screen
; and prints the text at hl without letter delay
; input:
;	hl = text to print
DrawNarrowTextBox_PrintTextNoDelay::
	push hl
	call DrawNarrowTextBox
	ld a, 11
;	fallthrough

DrawTextBox_PrintTextNoDelay::
	lb de, 1, 14
	call AdjustCoordinatesForBGScroll
	call InitTextPrintingInTextbox
	pop hl
	ld a, l
	or h
	jp nz, PrintTextNoDelay
	ld hl, wDefaultText
	jp ProcessText


; draws a 20x6 text box aligned to the bottom of the screen
; and prints the text at hl with letter delay
; input:
;	hl = text to print
DrawWideTextBox_PrintText::
	push hl
	call DrawWideTextBox
	ld a, 19
	lb de, 1, 14
	call AdjustCoordinatesForBGScroll
	call InitTextPrintingInTextbox
	call EnableLCD
	pop hl
	jp PrintText


; draws a 12x6 text box aligned to the bottom left of the screen
DrawNarrowTextBox::
	lb de, 0, 12
	lb bc, 12, 6
	call AdjustCoordinatesForBGScroll
	jp DrawRegularTextBox


; draws a 12x6 text box aligned to the bottom left of the screen,
; prints the text at hl without letter delay, and waits for A or B to be pressed
; input:
;	hl = text to print
DrawNarrowTextBox_WaitForInput::
	call DrawNarrowTextBox_PrintTextNoDelay
	xor a
	ld hl, NarrowTextBoxMenuParameters
	call InitializeMenuParameters
	call EnableLCD
.wait_A_or_B_loop
	call DoFrame
	call RefreshMenuCursor
	ldh a, [hKeysPressed]
	and A_BUTTON | B_BUTTON
	jr z, .wait_A_or_B_loop
	ret


NarrowTextBoxMenuParameters::
	db 10, 17 ; cursor x, cursor y
	db 1 ; y displacement between items
	db 1 ; number of items
	db SYM_CURSOR_D ; cursor tile number
	db SYM_BOX_BOTTOM ; tile behind cursor
	dw NULL ; function pointer if non-0


; draws a 20x6 text box aligned to the bottom of the screen
DrawWideTextBox::
	lb de, 0, 12
	lb bc, 20, 6
	call AdjustCoordinatesForBGScroll
	jp DrawRegularTextBox


; draws a 20x6 text box aligned to the bottom of the screen,
; prints the text at hl with letter delay, and waits for A or B to be pressed
; input:
;	hl = text to print
DrawWideTextBox_WaitForInput::
	call DrawWideTextBox_PrintText
;	fallthrough

; waits for A or B to be pressed on a wide (20x6) text box
WaitForWideTextBoxInput::
	xor a
	ld hl, WideTextBoxMenuParameters
	call InitializeMenuParameters
	call EnableLCD
.wait_A_or_B_loop
	call DoFrame
	call RefreshMenuCursor
	ldh a, [hKeysPressed]
	and A_BUTTON | B_BUTTON
	jr z, .wait_A_or_B_loop
	jp EraseCursor


WideTextBoxMenuParameters::
	db 18, 17 ; cursor x, cursor y
	db 1 ; y displacement between items
	db 1 ; number of items
	db SYM_CURSOR_D ; cursor tile number
	db SYM_BOX_BOTTOM ; tile behind cursor
	dw NULL ; function pointer if non-0


; same as function below except the default selection is set to "Yes"
YesOrNoMenuWithText_SetCursorToYes::
	ld a, $01
	ld [wDefaultYesOrNo], a
;	fallthrough

; displays a YES / NO menu in a 20x6 textbox with custom text and handles input
; input:
;	hl = text to print
;	wDefaultYesOrNo = 1:  the default selection will be "Yes"
;	wDefaultYesOrNo = 0:  the default selection will be "No"
; output:
;	carry = set:  if "No" was selected
YesOrNoMenuWithText::
	call DrawWideTextBox_PrintText
;	fallthrough

; prints the YES / NO menu items at coordinates x,y = 7,16 and handles input
; wDefaultYesOrNo determines whether the cursor initially points to YES or to NO
; output:
;	carry = set:  if "No" was selected
YesOrNoMenu::
	lb de, 7, 16 ; x, y
	call PrintYesOrNoItems
	lb de, 6, 16 ; x, y
	jr HandleYesOrNoMenu

; prints the YES / NO menu items at coordinates x,y = 3,16 and handles input
; wDefaultYesOrNo determines whether the cursor initially points to YES or to NO
; output:
;	carry = set:  if "No" was selected
YesOrNoMenuWithText_LeftAligned::
	call DrawNarrowTextBox_PrintTextNoDelay
	lb de, 3, 16 ; x, y
	call PrintYesOrNoItems
	lb de, 2, 16 ; x, y
;	fallthrough

HandleYesOrNoMenu::
	ld a, d
	ld [wLeftmostItemCursorX], a
	lb bc, SYM_CURSOR_R, SYM_SPACE ; cursor tile, tile behind cursor
	call SetCursorParametersForTextBox
	ld a, [wDefaultYesOrNo]
	ld [wCurMenuItem], a
	call EnableLCD
	jr .refresh_menu
.wait_button_loop
	call DoFrame
	call RefreshMenuCursor
	ldh a, [hKeysPressed]
	bit A_BUTTON_F, a
	jr nz, .a_pressed
	ldh a, [hDPadHeld]
	and D_RIGHT | D_LEFT
	jr z, .wait_button_loop
	; left or right pressed, so switch to the other menu item
	ld a, SFX_CURSOR
	call PlaySFX
	call EraseCursor
.refresh_menu
	ld a, [wLeftmostItemCursorX]
	ld c, a
	; default to the second option (NO)
	ld hl, wCurMenuItem
	ld a, [hl]
	xor $1
	ld [hl], a
	; x separation between left and right items is 4 tiles
	add a
	add a
	add c
	ld [wMenuCursorXOffset], a
	xor a
	ld [wCursorBlinkCounter], a
	jr .wait_button_loop
.a_pressed
	ld a, [wCurMenuItem]
	ldh [hCurMenuItem], a
	or a
	jr nz, .no
;.yes
	ld [wDefaultYesOrNo], a ; 0
	ret
.no
	xor a
	ld [wDefaultYesOrNo], a ; 0
	ld a, 1
	ldh [hCurMenuItem], a
	scf
	ret


; displays a two-item horizontal menu with custom text provided in hl and handles input
; input:
;	hl = text to print
TwoItemHorizontalMenu::
	call DrawWideTextBox_PrintText
	lb de, 6, 16 ; x, y
	ld a, d
	ld [wLeftmostItemCursorX], a
	lb bc, SYM_CURSOR_R, SYM_SPACE ; cursor tile, tile behind cursor
	call SetCursorParametersForTextBox
	ld a, 1
	ld [wCurMenuItem], a
	call EnableLCD
	jr HandleYesOrNoMenu.refresh_menu


; prints "YES NO" at de
; preserves bc
; input:
;	de = coordinates at which to begin printing the text
PrintYesOrNoItems::
	call AdjustCoordinatesForBGScroll
	ldtx hl, YesOrNoText
	jp InitTextPrinting_ProcessTextFromID


ContinueDuel::
	ld a, BANK(_ContinueDuel)
	call BankswitchROM
	jp _ContinueDuel


; draws the same tile across an entire line in BG Map
; if CGB, also fills the line with background palette 4 in VRAM1
; input:
;	a = TX_SYMBOL (SYM_?)
;	bc = coordinates to print line
FillBGMapLineWithA::
	call BCCoordToBGMap0Address
	ld b, SCREEN_WIDTH
	call FillDEWithA
	ld a, [wConsole]
	cp CONSOLE_CGB
	ret nz ; return if not CGB
	ld a, $04
	ld b, SCREEN_WIDTH
	call BankswitchVRAM1
	call FillDEWithA
	jp BankswitchVRAM0


; fills de with b bytes of the value in register a
; preserves af and hl
; input:
;	a = byte to copy
;	b = number of bytes to copy
;	de = where to copy the data
FillDEWithA:
	push hl
	ld l, e
	ld h, d
.loop
	ld [hli], a
	dec b
	jr nz, .loop
	pop hl
	ret


;----------------------------------------
;        UNREFERENCED FUNCTIONS
;----------------------------------------
;
; reloads a list of cards, except don't print their names
;Func_2827::
;	ld a, $01
;	ldh [hffb0], a
;	call ReloadCardListItems
;	xor a
;	ldh [hffb0], a
;	ret
