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
	ld b, wMenuParamsEnd - wMenuParams ; 8 bytes
	call CopyNBytesFromHLToDE
	xor a
	ld [wCursorBlinkCounter], a
	ret


; note: output values still subject to those of the function at [wMenuUpdateFunc], if any
; output:
;	a & [hCurMenuItem] = index for the currently selected item:  if the A button was pressed
;	                   = -1:  if the B button was pressed
;	e & [wCurMenuItem] = index for the currently selected item (on the screen)
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
	bit B_PAD_UP, b
	jr z, .not_up
	dec a
	bit 7, a
	jr z, .handle_up_or_down
	ld a, [wNumMenuItems]
	dec a ; wrapping around, so load the bottommost item
	jr .handle_up_or_down
.not_up
	bit B_PAD_DOWN, b
	jr z, .up_down_done
	inc a
	cp c
	jr c, .handle_up_or_down
	xor a ; wrapping around, so load the topmost item
.handle_up_or_down
	push af
	ld a, SFX_CURSOR
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
	ld h, [hl]
	ld l, a
	or h
	jr z, .check_A_or_B
	ldh a, [hCurMenuItem]
	call CallHL
	jr nc, RefreshMenuCursor_CheckPlaySFX
.A_pressed_draw_cursor
	call DrawCursor2
.A_pressed::
	call PlayOpenOrExitScreenSFX
	ld a, [wCurMenuItem]
	ld e, a
	ldh a, [hCurMenuItem]
	scf
	ret
.check_A_or_B
	ldh a, [hKeysPressed]
	and PAD_A | PAD_B
	jr z, RefreshMenuCursor_CheckPlaySFX
	and PAD_A
	jr nz, .A_pressed_draw_cursor
	; B button pressed
	ld a, [wCurMenuItem]
	ld e, a
	ld a, -1
	ldh [hCurMenuItem], a
	call PlayOpenOrExitScreenSFX
	scf
	ret


; plays an "open screen" sound (SFX_CONFIRM) if [hCurMenuItem] != -1
; plays an "exit screen" sound (SFX_CANCEL)  if [hCurMenuItem] == -1
; preserves all registers
PlayOpenOrExitScreenSFX::
	push af
	ldh a, [hCurMenuItem]
	inc a ; cp -1
	ld a, SFX_CONFIRM
	jr nz, .play_sfx
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
	call nz, PlaySFX
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


; translates the TYPE_* constant in wLoadedCard1Type to an index
; and then uses that index to find the relevant entry in CardSymbolTable.
; preserves de
; output:
;	hl = pointing to an entry from CardSymbolTable
;	a = starting tile number of the symbol being drawn (ICON_TILE_* constant)
GetCardSymbolData::
	ld a, [wLoadedCard1Type]
	cp TYPE_TRAINER
	jr nc, .trainer_card
	cp TYPE_ENERGY
	jr c, .pokemon_card
	; Energy card
	and 7 ; match TYPE_ENERGY_* with the appropriate Energy icon
	jr .got_index
.trainer_card
	ld a, 11 ; use the T icon
	jr .got_index
.pokemon_card
	ld a, [wLoadedCard1Stage] ; different symbol for each stage of evolution
	add 8
.got_index
	add a ; double index to account for palette data
	ld c, a
	ld b, 0
	ld hl, CardSymbolTable
	add hl, bc
	ld a, [hl]
	ret


; draws, at de, the 2x2 tile card symbol associated to the TYPE_* constant in wLoadedCard1Type.
; the actual icon is drawn 2 tiles to the left and 1 tile up from the coordinates given in de.
; Energy cards are given an icon that represents the type of Energy provided. (e.g. Grass, Fire, etc.)
; Pokémon cards are given an icon that represents their stage. (e.g. Basic, Stage 1, etc.)
; Trainer cards are simply given an icon that consists of a capital letter T.
; preserves all registers except af
; input:
;	de = screen coordinates for drawing the symbol
;	[wLoadedCard1] = all of the card's data (card_data_struct)
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
	db $00


; copies the name and level of the card at wLoadedCard1 to wDefaultText
; preserves bc and de
; input:
;	a = length in number of tiles (the resulting string will be padded with spaces to match it)
;	[wLoadedCard1] = all of the card's data (card_data_struct)
; output:
;	hl = first empty space at the end of the text string that was stored in wDefaultText
CopyCardNameAndLevel::
	ld h, a
	ldh a, [hBankROM]
	push af
	ld a, BANK(_CopyCardNameAndLevel)
	rst BankswitchROM
	ld a, h
	call _CopyCardNameAndLevel
	pop af
	jp BankswitchROM


; sets cursor parameters for navigating in a text box, but using
; default values for the cursor tile (SYM_CURSOR_R) and the tile behind it (SYM_SPACE).
; input:
;	de = screen coordinates for the cursor
SetCursorParametersForTextBox_Default::
	lb bc, SYM_CURSOR_R, SYM_SPACE ; cursor tile, tile behind cursor
	call SetCursorParametersForTextBox
;	fallthrough

; waits for the player to press either the A or the B button
; output:
;	carry = set:  if the B button was pressed
WaitForButtonAorB::
	call DoFrame
	call RefreshMenuCursor
	ldh a, [hKeysPressed]
	bit B_PAD_A, a
	jp nz, EraseCursor ; erase cursor and return if A button was pressed
	bit B_PAD_B, a
	jr z, WaitForButtonAorB
	call EraseCursor
	scf
	ret


; sets cursor parameters for navigating in a text box
; preserves bc and de
; input:
;	b = tile number for the cursor sprite
;	c = tile number for the background tile behind the cursor
;	de = screen coordinates for the cursor
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


; draws a 12x6 text box aligned to the bottom left of the screen
; and prints the text at hl without letter delay. if [hl] = 0 (TX_END),
; then print the text at wDefaultText instead of using a text ID.
; input:
;	hl = text ID (or terminating byte of text string at wDefaultText)
DrawNarrowTextBox_PrintTextNoDelay::
	push hl
	call DrawNarrowTextBox
	ld a, 11
	jr DrawWideTextBox_PrintTextNoDelay.print_text


; draws a 20x6 text box aligned to the bottom of the screen
; and prints the text at hl without letter delay. if [hl] = 0 (TX_END),
; then print the text at wDefaultText instead of using a text ID.
; input:
;	hl = text ID (or terminating byte of text string at wDefaultText)
DrawWideTextBox_PrintTextNoDelay::
	push hl
	call DrawWideTextBox
	ld a, 19
.print_text
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
;	hl = text ID for the text to print
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


; currently an unreferenced function
; draws a 12x6 text box aligned to the bottom left of the screen,
; prints the text at hl without letter delay, and waits for A or B to be pressed
; input:
;	hl = text ID for the text to print
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
	and PAD_A | PAD_B
	jr z, .wait_A_or_B_loop
	ret

NarrowTextBoxMenuParameters::
	db 10, 17 ; cursor x, cursor y
	db 1 ; y displacement between items
	db 1 ; number of items
	db SYM_CURSOR_D ; cursor tile number
	db SYM_BOX_BOTTOM ; tile behind cursor
	dw NULL ; function pointer if non-0


; currently an unreferenced function
; draws a 20x6 text box aligned to the bottom of the screen,
; prints the text at hl without letter delay, and waits for A or B to be pressed
; input:
;	hl = text ID for the text to print
DrawWideTextBox_PrintTextNoDelay_Wait::
	call DrawWideTextBox_PrintTextNoDelay
	jr WaitForWideTextBoxInput

; draws a 20x6 text box aligned to the bottom of the screen,
; prints the text at hl with letter delay, and waits for A or B to be pressed
; input:
;	hl = text ID for the text to print
DrawWideTextBox_WaitForInput::
	call DrawWideTextBox_PrintText
;	fallthrough

; waits for A or B to be pressed on a wide (20x6) text box
WaitForWideTextBoxInput::
	xor a
	ld hl, WideTextBoxMenuParameters
	call InitializeMenuParameters
	call EnableLCD
	call DrawNarrowTextBox_WaitForInput.wait_A_or_B_loop
	jp EraseCursor

WideTextBoxMenuParameters::
	db 18, 17 ; cursor x, cursor y
	db 1 ; y displacement between items
	db 1 ; number of items
	db SYM_CURSOR_D ; cursor tile number
	db SYM_BOX_BOTTOM ; tile behind cursor
	dw NULL ; function pointer if non-0


; draws a text box that covers the whole screen and
; prints the text with ID in hl, then waits for Player input.
; input:
;	hl = text ID
DrawWholeScreenTextBox::
	push hl
	call EmptyScreen
	lb de, 0, 0
	lb bc, 20, 18
	call DrawRegularTextBox
	ld a, 19
	lb de, 1, 1
	call InitTextPrintingInTextbox
	ld a, SINGLE_SPACED
	ld [wLineSeparation], a
	pop hl
	call ProcessTextFromID
	call EnableLCD
	xor a ; DOUBLE_SPACED
	ld [wLineSeparation], a
	jr WaitForWideTextBoxInput


; same as function below except the default selection is set to "Yes"
YesOrNoMenuWithText_SetCursorToYes::
	ld a, $01
	ld [wDefaultYesOrNo], a
;	fallthrough

; displays a YES / NO menu in a 20x6 textbox with custom text and handles input
; input:
;	hl = text ID for the question
;	[wDefaultYesOrNo] = 0:  the default selection will be "No"
;	                  = 1:  the default selection will be "Yes"
; output:
;	carry = set:  if "No" was selected
YesOrNoMenuWithText::
	call DrawWideTextBox_PrintText
;	fallthrough

; prints the YES / NO menu items at coordinates x,y = 7,16 and handles input.
; wDefaultYesOrNo determines whether the cursor initially points to YES or to NO.
; output:
;	carry = set:  if "No" was selected
YesOrNoMenu::
	lb de, 7, 16 ; x, y
	call PrintYesOrNoItems
	lb de, 6, 16 ; x, y
;	fallthrough

; input:
;	de = screen coordinates for the cursor
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
	bit B_PAD_A, a
	jr nz, .a_pressed
	ldh a, [hDPadHeld]
	and PAD_RIGHT | PAD_LEFT
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
	ld a, SFX_CONFIRM
	call PlaySFX
	ld a, [wCurMenuItem]
	ldh [hCurMenuItem], a
	ld hl, wDefaultYesOrNo
	ld [hl], a
	or a
	ret z ; return no carry if "Yes" was selected
	; "No" was selected, so return carry
	ld [hl], $00 ; default set to "No"
	scf
	ret


; prints the YES / NO menu items at coordinates x,y = 3,16 and handles input
; wDefaultYesOrNo determines whether the cursor initially points to YES or to NO
; input:
;	hl = text ID for the question
;	[wDefaultYesOrNo] = 0:  the default selection will be "No"
;	                  = 1:  the default selection will be "Yes"
; output:
;	carry = set:  if "No" was selected
YesOrNoMenuWithText_LeftAligned::
	call DrawNarrowTextBox_PrintTextNoDelay
	lb de, 3, 16 ; x, y
	call PrintYesOrNoItems
	lb de, 2, 16 ; x, y
	jr HandleYesOrNoMenu


; displays a two-item horizontal menu with custom text provided in hl and handles input
; input:
;	hl = text ID for the horizontal menu
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
;	de = screen coordinates at which to begin printing the text
PrintYesOrNoItems::
	call AdjustCoordinatesForBGScroll
	ldtx hl, YesOrNoText
	jp InitTextPrinting_ProcessTextFromID


; preserves all registers except af
; input:
;	de = text ID for the text box header
;	hl = text ID for the text box contents
SetCardListHeaderText::
	ld a, e
	ld [wCardListHeaderText], a
	ld a, d
	ld [wCardListHeaderText + 1], a
;	fallthrough

; preserves all registers except af
; input:
;	hl = text ID for the text box contents
SetCardListInfoBoxText::
	ld a, l
	ld [wCardListInfoBoxText], a
	ld a, h
	ld [wCardListInfoBoxText + 1], a
	ret


;----------------------------------------
;        UNREFERENCED FUNCTIONS
;----------------------------------------
;
;ContinueDuel::
;	ld a, BANK(_ContinueDuel)
;	rst BankswitchROM
;	jp _ContinueDuel
