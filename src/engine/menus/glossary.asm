OpenGlossaryScreen:
	xor a
	ld [wGlossaryPageNo], a
	call .display_menu

	xor a
	ld [wInPlayAreaCurPosition], a
	ld de, OpenGlossaryScreen_TransitionTable ; this data is stored in bank $02.
	ld hl, wMenuInputTablePointer
	ld [hl], e
	inc hl
	ld [hl], d
	ld a, $ff
	ld [wDuelInitialPrizesUpperBitsSet], a
	xor a
	ld [wCheckMenuCursorBlinkCounter], a
.next
	ld a, $01
	ld [wVBlankOAMCopyToggle], a
	call DoFrame
	ldh a, [hKeysPressed]
	and SELECT
	jr nz, .on_select

	farcall YourOrOppPlayAreaScreen_HandleInput
	jr nc, .next

	cp -1 ; B button
	jr nz, .check_button
	jp ZeroObjectPositionsAndToggleOAMCopy

.check_button
	push af
	call ZeroObjectPositionsAndToggleOAMCopy
	pop af

	cp $09 ; $09: next page or prev page
	jr z, .change_page

	call .print_description
	call .display_menu
	xor a
	ld [wCheckMenuCursorBlinkCounter], a
	jr .next

.on_select
	ld a, $01
	farcall PlaySFXConfirmOrCancel
.change_page
	ld a, [wGlossaryPageNo]
	xor $01 ; swap page
	ld [wGlossaryPageNo], a
	call .print_menu
	jr .next

; displays the Glossary menu
.display_menu
	xor a
	ld [wTileMapFill], a
	call ZeroObjectPositionsAndToggleOAMCopy
	call DoFrame
	call EmptyScreen
	call Set_OBJ_8x8
	farcall LoadCursorTile
	call .print_menu
	ldtx hl, ChooseWordAndPressAButtonText
	jp DrawWideTextBox_PrintText

; prints texts in the Glossary menu
.print_menu
; print Glossary at the top of the page and then draw the page borders
	ld hl, GlossaryTextData
	call PlaceTextItems

; alternate header separator that uses a text box tile (it's also colored)
;	lb bc, 0, 1
;	ld a, SYM_BOX_BOTTOM
;	call FillBGMapLineWithA

; print the current page number in the bottom right corner
	ld hl, wDefaultText

	ld a, TX_SYMBOL
	ld [hli], a

	ld a, [wGlossaryPageNo]
	add SYM_1
	ld [hli], a

	ld a, TX_SYMBOL
	ld [hli], a

	ld a, SYM_SLASH
	ld [hli], a

	ld a, TX_SYMBOL
	ld [hli], a

	ld a, SYM_2
	ld [hli], a

	ld [hl], TX_END

	lb de, 17, 10
	call InitTextPrinting
	ld hl, wDefaultText
	call ProcessText

; print the page-specific text
	lb de, 1, 2
	ld a, [wGlossaryPageNo]
	or a
	jr nz, .page_two
; page one
	ldtx hl, GlossaryMenuPage1LeftText
	call InitTextPrinting_ProcessTextFromID
	ld d, 12
	ldtx hl, GlossaryMenuPage1RightText
	jp InitTextPrinting_ProcessTextFromID
.page_two
	ldtx hl, GlossaryMenuPage2LeftText
	call InitTextPrinting_ProcessTextFromID
	ld d, 12
	ldtx hl, GlossaryMenuPage2RightText
	jp InitTextPrinting_ProcessTextFromID

; draws the Glossary description screen and prints the description
.print_description
	push af
	xor a
	ld [wTileMapFill], a
	call EmptyScreen
	lb de, 0, 0
	lb bc, 20, 18
	call DrawRegularTextBox
	lb de, 0, 2
	call DrawTextBoxSeparator

	ld a, [wGlossaryPageNo]
	or a
	jr nz, .back_page

	ld hl, GlossaryData1
	jr .front_page

.back_page
	ld hl, GlossaryData2
.front_page
	pop af
	; hl += (a + (a << 2)).
	; that is,
	; hl += (5 * a).
	ld c, a
	ld b, 0
	add hl, bc
	sla a
	sla a
	ld c, a
	add hl, bc
	ld a, [hli]
	push hl
	ld d, a
	ld e, 1
	call InitTextPrinting
	ld a, [hli]
	ld h, [hl]
	ld l, a
	call ProcessTextFromID
	pop hl
	lb de, 1, 4
	call InitTextPrinting
	inc hl
	inc hl
	ld a, [hli]
	ld h, [hl]
	ld l, a
	ld a, $01 ; text isn't double-spaced
	ld [wLineSeparation], a
	call ProcessTextFromID
	xor a ; text is double-spaced
	ld [wLineSeparation], a
	call EnableLCD
.loop
	call DoFrame
	ldh a, [hKeysPressed]
	and B_BUTTON
	jr z, .loop

	ld a, -1
	farcall PlaySFXConfirmOrCancel
	ret

GlossaryTextData:
	textitem 6, 0, GlossaryFWText
	textitem 0, 1, HorizontalLineSeparatorText
	textitem 10, 1, IntersectingLines1Text
	textitem 10, 2, VerticalLinesX5Text
	textitem 10, 3, VerticalLinesX4Text
	textitem 0, 11, HorizontalLineSeparatorText
	textitem 10, 11, IntersectingLines2Text
	db $ff

; unit: 5 bytes.
; [structure]
; horizontal align (1) / title text id (2) / desc. text id (2)
MACRO glossary_entry
	db \1
	tx \2
	tx \3
ENDM

GlossaryData1:
	glossary_entry 3, AboutActivePokemonAndBenchText, ActivePokemonAndBenchDescriptionText
	glossary_entry 7, AboutPrizesText, PrizesDescriptionText
	glossary_entry 6, AboutTheDeckText, TheDeckDescriptionText
	glossary_entry 2, AboutTheDiscardPileText, TheDiscardPileDescriptionText
	glossary_entry 6, AboutTheHandText, TheHandDescriptionText
	glossary_entry 3, AboutBasicPokemonText, BasicPokemonDescriptionText
	glossary_entry 3, AboutEvolutionCardsText, EvolutionCardsDescriptionText
	glossary_entry 3, AboutTrainerCardsText, TrainerCardsDescriptionText
	glossary_entry 4, AboutEnergyCardsText, EnergyCardsDescriptionText

GlossaryData2:
	glossary_entry 5, AboutAttackingText, AttackingDescriptionText
	glossary_entry 2, AboutDamageCountersText, DamageCountersDescriptionText
	glossary_entry 6, AboutEvolvingText, EvolvingDescriptionText
	glossary_entry 3, AboutPokemonPowersText, PokemonPowersDescriptionText
	glossary_entry 5, AboutRetreatingText, RetreatingDescriptionText
	glossary_entry 6, AboutWeaknessText, WeaknessDescriptionText
	glossary_entry 5, AboutResistanceText, ResistanceDescriptionText
	glossary_entry 1, AboutSpecialConditions1Text, SpecialConditions1DescriptionText
	glossary_entry 1, AboutSpecialConditions2Text, SpecialConditions2DescriptionText
