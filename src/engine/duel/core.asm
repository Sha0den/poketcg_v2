; try to resume a saved duel from the main menu
TryContinueDuel::
	call SetupDuel
	call LoadAndValidateDuelSaveData
	ldtx hl, BackUpIsBrokenText
	jr c, HandleFailedToContinueDuel
;	fallthrough

_ContinueDuel::
	ld hl, sp+$00
	ld a, l
	ld [wDuelReturnAddress], a
	ld a, h
	ld [wDuelReturnAddress + 1], a
	call ClearJoypad
	ld a, [wDuelTheme]
	call PlaySong
	xor a
	ld [wDuelFinished], a
	call DuelMainInterface
	jr MainDuelLoop.between_turns

HandleFailedToContinueDuel:
	call DrawWideTextBox_WaitForInput
	call ResetSerial
	scf
	ret


; begins the duel after the opponent's graphics, name and deck have been introduced.
; loads both players' decks and sets up the variables and resources required to begin a duel.
StartDuel_VSAIOpp::
	ld a, PLAYER_TURN
	ldh [hWhoseTurn], a
	ld a, DUELIST_TYPE_PLAYER
	ld [wPlayerDuelistType], a
	ld a, [wNPCDuelDeckID]
	ld [wOpponentDeckID], a
	call LoadPlayerDeck
	rst SwapTurn
	call LoadOpponentDeck
	rst SwapTurn
	jr StartDuel


StartDuel_VSLinkOpp:
	ld a, MUSIC_DUEL_THEME_1
	ld [wDuelTheme], a
	ld hl, wOpponentName
	xor a
	ld [hli], a
	ld [hl], a
	ld [wIsPracticeDuel], a
;	fallthrough

StartDuel:
	ld hl, sp+$0
	ld a, l
	ld [wDuelReturnAddress], a
	ld a, h
	ld [wDuelReturnAddress + 1], a
	xor a
	ld [wCurrentDuelMenuItem], a
	call SetupDuel
	ld a, [wNPCDuelPrizes]
	ld [wDuelInitialPrizes], a
	call InitVariablesToBeginDuel
	ld a, [wDuelTheme]
	call PlaySong
	call HandleDuelSetup
	ret c
;	fallthrough

; the loop returns here after every turn switch
MainDuelLoop:
	xor a
	ld [wCurrentDuelMenuItem], a
	call UpdateSubstatusConditions_StartOfTurn
	call DisplayDuelistTurnScreen
	call HandleTurn

.between_turns
	call ExchangeRNG
	ld a, [wDuelFinished]
	or a
	jr nz, .duel_finished
	call UpdateSubstatusConditions_EndOfTurn
	call HandleBetweenTurnsEvents
	call FinishQueuedAnimations
	call ExchangeRNG
	ld a, [wDuelFinished]
	or a
	jr nz, .duel_finished
	ld hl, wDuelTurns
	inc [hl]
	ld a, [wDuelType]
	cp DUELTYPE_PRACTICE
	jr z, .practice_duel

.next_turn
	rst SwapTurn
	jr MainDuelLoop

.practice_duel
	ld a, [wIsPracticeDuel]
	or a
	jr z, .next_turn
	ld a, [hl]
	cp 15 ; the practice duel lasts 15 turns (8 player turns and 7 opponent turns)
	jr c, .next_turn
	xor a ; DUEL_WIN
	ld [wDuelResult], a
	ret

.duel_finished
	call ZeroObjectPositionsAndToggleOAMCopy
	call EmptyScreen
	ld a, BOXMSG_DECISION
	call DrawDuelBoxMessage
	ldtx hl, DecisionText
	call DrawWideTextBox_WaitForInput
	call EmptyScreen
	ldh a, [hWhoseTurn]
	push af
	ld a, PLAYER_TURN
	ldh [hWhoseTurn], a
	call DrawDuelistPortraitsAndNames
	call PrintDuelResultStats
	pop af
	ldh [hWhoseTurn], a

; animate the duel result screen
; load the correct music and animation depending on result
	call ResetAnimationQueue
	ld a, [wDuelFinished]
	cp TURN_PLAYER_WON
	jr z, .active_duelist_won_duel
	cp TURN_PLAYER_LOST
	jr z, .active_duelist_lost_duel
	ld a, DUEL_ANIM_DUEL_DRAW
	ld c, MUSIC_MATCH_DRAW
	ldtx hl, DuelWasADrawText
	jr .handle_duel_finished

.active_duelist_won_duel
	ldh a, [hWhoseTurn]
	cp PLAYER_TURN
	jr nz, .opponent_won_duel

.player_won_duel
	xor a ; DUEL_WIN
	ld [wDuelResult], a
	ld a, DUEL_ANIM_DUEL_WIN
	ld c, MUSIC_MATCH_VICTORY
	ldtx hl, WonDuelText
	jr .handle_duel_finished

.active_duelist_lost_duel
	ldh a, [hWhoseTurn]
	cp PLAYER_TURN
	jr nz, .player_won_duel

.opponent_won_duel
	ld a, DUEL_LOSS
	ld [wDuelResult], a
	ld a, DUEL_ANIM_DUEL_LOSS
	ld c, MUSIC_MATCH_LOSS
	ldtx hl, LostDuelText

.handle_duel_finished
	call PlayDuelAnimation
	ld a, c
	call PlaySong
	ld a, OPPONENT_TURN
	ldh [hWhoseTurn], a
	call DrawWideTextBox_PrintText
	call EnableLCD
	call WaitForSongToFinish
	ld a, [wDuelFinished]
	cp TURN_PLAYER_TIED
	jr z, .tied_duel
	call PlayDefaultSong
	call WaitForWideTextBoxInput
	call FinishQueuedAnimations
	call ResetSerial
	ld a, PLAYER_TURN
	ldh [hWhoseTurn], a
	ret

.tied_duel
	call WaitForWideTextBoxInput
	call FinishQueuedAnimations
	ld a, [wDuelTheme]
	call PlaySong
	ldtx hl, StartSuddenDeathMatchText
	call DrawWideTextBox_WaitForInput
	ld a, 1
	ld [wDuelInitialPrizes], a
	call InitVariablesToBeginDuel
	ld a, [wDuelType]
	cp DUELTYPE_LINK
	jr z, .link_duel
	ld a, PLAYER_TURN
	ldh [hWhoseTurn], a
	call HandleDuelSetup
	jp MainDuelLoop

.link_duel
	call ExchangeRNG
	ld h, PLAYER_TURN
	ld a, [wSerialOp]
	cp $29
	jr z, .got_turn
	ld h, OPPONENT_TURN
.got_turn
	ld a, h
	ldh [hWhoseTurn], a
	call HandleDuelSetup
	jp nc, MainDuelLoop
	ret


; empties the screen, and sets up text and graphics for a duel
SetupDuel:
	xor a ; SYM_SPACE
	ld [wTileMapFill], a
	call ZeroObjectPositionsAndToggleOAMCopy
	call EmptyScreen
	call LoadSymbolsFont
	call SetDefaultConsolePalettes
	lb de, $38, $9f
	call SetupText
	jp EnableLCD


; handles the turn of the duelist identified by hWhoseTurn.
; if it's the player's turn, displays the animation of the player
; drawing the card at hTempCardIndex_ff98 and saves the duel state to SRAM.
HandleTurn:
	ld a, DUELVARS_DUELIST_TYPE
	get_turn_duelist_var
	ld [wDuelistType], a
	ld a, [wDuelTurns]
	cp 2
	jr c, .skip_let_evolve ; jump if it's the turn holder's first turn
	call SetAllPlayAreaPokemonCanEvolve
.skip_let_evolve
	call InitVariablesToBeginTurn
	call DisplayDrawOneCardScreen
	call DrawCardFromDeck
	jr nc, .deck_not_empty
	ld a, TURN_PLAYER_LOST
	ld [wDuelFinished], a
	ret

.deck_not_empty
	ldh [hTempCardIndex_ff98], a
	call AddCardToHand
	ld a, [wDuelistType]
	cp DUELIST_TYPE_PLAYER
	jr z, .player_turn

; opponent's turn
	rst SwapTurn
	call IsClairvoyanceActive
	rst SwapTurn
	call c, DisplayPlayerDrawCardScreen
	jr DuelMainInterface

; player's turn
.player_turn
	call DisplayPlayerDrawCardScreen
	call SaveDuelStateToSRAM
;	fallthrough

; when a practice duel turn needs to be restarted because the player did not
; follow the instructions correctly, the game loops back here
RestartPracticeDuelTurn:
	ld a, PRACTICEDUEL_PRINT_TURN_INSTRUCTIONS
	call DoPracticeDuelAction
;	fallthrough

; prints the main interface during a duel, including background, Pokemon, HUDs and a text box.
; the bottom text box changes depending on whether the turn belongs to the player (show the duel menu),
; an AI opponent (print "Waiting..." and a reduced menu) or a link opponent (print "<Duelist> is thinking").
DuelMainInterface:
	call DrawDuelMainScene
	ld a, [wDuelistType]
	cp DUELIST_TYPE_PLAYER
	jr z, PrintDuelMenuAndHandleInput
	cp DUELIST_TYPE_LINK_OPP
	jp z, DoLinkOpponentTurn
	; DUELIST_TYPE_AI_OPP
	xor a
	ld [wVBlankCounter], a
	ldtx hl, DuelistIsThinkingText
	call DrawWideTextBox_PrintTextNoDelay
	call AIDoAction_Turn
	ld a, $ff
	ld [wPlayerAttackingCardIndex], a
	ld [wPlayerAttackingAttackIndex], a
	ret


; triggered by pressing B + UP in the duel menu
DuelMenuShortcut_OpponentPlayArea:
	call OpenNonTurnHolderPlayAreaScreen
	jr DuelMainInterface


; triggered by pressing B + DOWN in the duel menu
DuelMenuShortcut_PlayerPlayArea:
	call OpenTurnHolderPlayAreaScreen
	jr DuelMainInterface


; triggered by pressing B + RIGHT in the duel menu
DuelMenuShortcut_OpponentDiscardPile:
	call OpenNonTurnHolderDiscardPileScreen
	jr c, PrintDuelMenuAndHandleInput
	jr DuelMainInterface


; triggered by pressing B + LEFT in the duel menu
DuelMenuShortcut_PlayerDiscardPile:
	call OpenTurnHolderDiscardPileScreen
	jr c, PrintDuelMenuAndHandleInput
	jr DuelMainInterface


; triggered by pressing B + START in the duel menu
DuelMenuShortcut_OpponentActivePokemon:
	rst SwapTurn
	call OpenActivePokemonScreen
	rst SwapTurn
	jr DuelMainInterface


; triggered by pressing START in the duel menu
DuelMenuShortcut_PlayerActivePokemon:
	call OpenActivePokemonScreen
	jr DuelMainInterface


; triggered by pressing SELECT in the duel menu
DuelMenuShortcut_BothActivePokemon:
	call FinishQueuedAnimations
	call OpenVariousPlayAreaScreens_FromSelectPresses
	jr DuelMainInterface


; triggered by selecting the "Hand" item in the duel menu
DuelMenu_Hand:
	ld a, DUELVARS_NUMBER_OF_CARDS_IN_HAND
	get_turn_duelist_var
	or a
	jp nz, OpenPlayerHandScreen
	ldtx hl, NoCardsInHandText
	call DrawWideTextBox_WaitForInput
;	fallthrough

PrintDuelMenuAndHandleInput:
	call DrawWideTextBox
	ld hl, DuelMenuData
	call PlaceTextItems
.menu_items_printed
	call SaveDuelData
	ld a, [wDuelFinished]
	or a
	ret nz
	ld [wCursorBlinkCounter], a ; 0
	ld a, [wCurrentDuelMenuItem]
	ld [wCurMenuItem], a
	ldh [hCurMenuItem], a

.handle_input
	call DoFrame
	ldh a, [hKeysHeld]
	and PAD_B
	jr z, .b_not_held
	ldh a, [hKeysPressed]
	bit B_PAD_UP, a
	jr nz, DuelMenuShortcut_OpponentPlayArea
	bit B_PAD_DOWN, a
	jr nz, DuelMenuShortcut_PlayerPlayArea
	bit B_PAD_LEFT, a
	jr nz, DuelMenuShortcut_PlayerDiscardPile
	bit B_PAD_RIGHT, a
	jr nz, DuelMenuShortcut_OpponentDiscardPile
	bit B_PAD_START, a
	jr nz, DuelMenuShortcut_OpponentActivePokemon

.b_not_held
	ldh a, [hKeysPressed]
	and PAD_START
	jr nz, DuelMenuShortcut_PlayerActivePokemon
	ldh a, [hKeysPressed]
	bit B_PAD_SELECT, a
	jp nz, DuelMenuShortcut_BothActivePokemon
	ld a, [wDebugSkipDuelMenuInput]
	or a
	jr nz, .handle_input
	call HandleDuelMenuInput
	ld a, e
	ld [wCurrentDuelMenuItem], a
	jr nc, .handle_input
	ldh a, [hCurMenuItem]
	ld hl, DuelMenuFunctionTable
	jp JumpToFunctionInTable

DuelMenuFunctionTable:
	dw DuelMenu_Hand
	dw DuelMenu_Attack
	dw DuelMenu_Check
	dw DuelMenu_PkmnPower
	dw DuelMenu_Retreat
	dw DuelMenu_Done


; triggered by selecting the "Attack" item in the duel menu
DuelMenu_Attack:
	call CheckUnableToAttackDueToEffect
	jr nc, .can_attack
	; unable to attack
.print_text_and_return
	call DrawWideTextBox_WaitForInput
.return
	jr PrintDuelMenuAndHandleInput

.can_attack
	xor a
	ld [wSelectedDuelSubMenuItem], a
.try_open_attack_menu
	call PrintAndLoadAttacksToDuelTempList
	or a
	jr nz, .open_attack_menu
	ldtx hl, NoSelectableAttackText
	jr .print_text_and_return

.open_attack_menu
	push af
	ld a, [wSelectedDuelSubMenuItem]
	ld hl, AttackMenuParameters
	call InitializeMenuParameters
	pop af
	ld [wNumMenuItems], a
	ld a, DUELVARS_ARENA_CARD
	get_turn_duelist_var
	call LoadCardDataToBuffer1_FromDeckIndex

.wait_for_input
	call DoFrame
	ldh a, [hKeysPressed]
	and PAD_START
	jr nz, .display_selected_attack_info
	call HandleMenuInput
	jr nc, .wait_for_input
	cp -1 ; was B pressed?
	jr z, .return
	; A button was pressed
	ld [wSelectedDuelSubMenuItem], a
	call CheckIfEnoughEnergiesToAttack
	jr nc, .enough_energy
	ldtx hl, NotEnoughEnergyCardsText
.cannot_use_this_attack
	call DrawWideTextBox_WaitForInput
	jr .try_open_attack_menu

.enough_energy
	ldh a, [hCurMenuItem]
	add a
	ld e, a
	ld d, $00
	ld hl, wDuelTempList
	add hl, de
	ld d, [hl] ; card's deck index (0-59)
	inc hl
	ld e, [hl] ; attack index (0 or 1)
	call CopyAttackDataAndDamage_FromDeckIndex
	call HandleAmnesiaSubstatus
	jr c, .cannot_use_this_attack
	ld a, PRACTICEDUEL_VERIFY_PLAYER_TURN_ACTIONS
	call DoPracticeDuelAction
	; if player did something wrong in the practice duel, jump in order to restart turn
	jp c, RestartPracticeDuelTurn
	call UseAttackOrPokemonPower
	jp c, DuelMainInterface
	ret

.display_selected_attack_info
	call OpenAttackPage
	call DrawDuelMainScene
	jr .try_open_attack_menu

AttackMenuParameters:
	db 1, 13 ; cursor x, cursor y
	db 2 ; y displacement between items
	db 2 ; number of items
	db SYM_CURSOR_R ; cursor tile number
	db SYM_SPACE ; tile behind cursor
	dw NULL ; function pointer if non-0


; triggered by selecting the "Check" item in the duel menu
DuelMenu_Check:
	call FinishQueuedAnimations
	call OpenDuelCheckMenu
	jp DuelMainInterface


; triggered by selecting the "Pkmn Power" item in the duel menu
DuelMenu_PkmnPower:
	call DisplayPlayAreaScreenToUsePkmnPower
	call nc, UseAttackOrPokemonPower
	jp DuelMainInterface


; triggered by selecting the "Retreat" item in the duel menu
DuelMenu_Retreat:
	call CheckAbleToRetreat
	jr c, .print_text_and_return
	ld a, DUELVARS_ARENA_CARD_STATUS
	get_turn_duelist_var
	and CNF_SLP_PRZ
	cp CONFUSED
	ldh [hTemp_ffa0], a
	jr nz, .not_confused
	ld a, [wOncePerTurnFlags]
	and UNABLE_TO_RETREAT_THIS_TURN
	jr nz, .unable_to_retreat
	call DisplayRetreatScreen
	jr c, .exit
	ldtx hl, SelectNewActivePokemonText
	call DrawWideTextBox_WaitForInput
	call InitVarsAndOpenPlayAreaScreenForSelection_OnlyBench
	jr c, .exit ; exit if the B button was pressed
	ld [wBenchSelectedPokemon], a
	ldh [hTempPlayAreaLocation_ffa1], a
	ld a, OPPACTION_ATTEMPT_RETREAT
	call SetOppAction_SerialSendDuelData
	call AttemptRetreat
	jr nc, .exit
	; retreat unsuccessful due to confusion
	call DrawDuelMainScene

.unable_to_retreat
	ldtx hl, UnableToRetreatText
.print_text_and_return
	call DrawWideTextBox_WaitForInput
	jp PrintDuelMenuAndHandleInput

.not_confused
	; note that the Energy cards are discarded (DiscardRetreatCostCards), then returned
	; (ReturnRetreatCostCardsToArena), then discarded again for good (AttemptRetreat).
	; It's done this way so that the retreating Pokemon is listed with its Energies updated
	; when the Play Area screen is shown to select the Pokemon to switch to. The reason why
	; AttemptRetreat is responsible for discarding the Energy cards is because, if the
	; Pokemon is Confused, it may not be able to retreat, so they cannot be discarded earlier.
	call DisplayRetreatScreen
	jr c, .exit
	call DiscardRetreatCostCards
	ldtx hl, SelectNewActivePokemonText
	call DrawWideTextBox_WaitForInput
	call InitVarsAndOpenPlayAreaScreenForSelection_OnlyBench
	ld [wBenchSelectedPokemon], a
	ldh [hTempPlayAreaLocation_ffa1], a
	push af
	call ReturnRetreatCostCardsToArena
	pop af
	jr c, .exit ; exit if the B button was pressed
	ld a, OPPACTION_ATTEMPT_RETREAT
	call SetOppAction_SerialSendDuelData
	call AttemptRetreat
.exit
	jp DuelMainInterface


; triggered by selecting the "Done" item in the duel menu
DuelMenu_Done:
	ld a, PRACTICEDUEL_REPEAT_INSTRUCTIONS
	call DoPracticeDuelAction
	; always jumps on practice duel (no action requires player to select Done)
	jp c, RestartPracticeDuelTurn
	ld a, OPPACTION_FINISH_NO_ATTACK
	call SetOppAction_SerialSendDuelData
	jp ClearNonTurnTemporaryDuelvars


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
	and PAD_UP | PAD_DOWN
	jr z, .check_left
	ld a, [hl]
	xor 1 ; move to the other menu item in the same column
	jr .dpad_pressed
.check_left
	bit B_PAD_LEFT, b
	jr z, .check_right
	ld a, [hl]
	sub 2
	jr nc, .dpad_pressed
	; wrap to the rightmost item in the same row
	and 1
	add 4
	jr .dpad_pressed
.check_right
	bit B_PAD_RIGHT, b
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
	and PAD_A
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
	xor a ; SYM_SPACE
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

DuelMenuData:
	; x, y, text ID
	textitem  3, 14, HandText
	textitem  9, 14, CheckText
	textitem 15, 14, RetreatText
	textitem  3, 16, AttackText
	textitem  9, 16, PKMNPowerText
	textitem 15, 16, DoneText
	db $ff


; draws the card page screen for the turn holder's Active Pokemon, if it exists
OpenActivePokemonScreen:
	ld a, DUELVARS_ARENA_CARD
	get_turn_duelist_var
	cp -1
	ret z ; return if there's no Active Pokémon
	call GetCardIDFromDeckIndex
	call LoadCardDataToBuffer1_FromCardID
	ld hl, wCurPlayAreaSlot
	xor a
	ld [hli], a
	ld [hl], a ; wCurPlayAreaY
	jp OpenCardPage_FromCheckPlayArea


; called when the Player presses SELECT while inside the main duel interface
; - 1st SELECT press displays the full play area screen
; - 2nd SELECT press displays the screen that lists the Player's play area Pokemon
; - 3rd SELECT press displays the screen that lists the opponent's play area Pokemon
OpenVariousPlayAreaScreens_FromSelectPresses:
	call OpenInPlayAreaScreen_FromSelectButton
	ret c
	call .Func_45a9
	ret c
	rst SwapTurn
	call .Func_45a9
	jp SwapTurn

; draws the screen that lists the turn holder's play area Pokemon
; and handles input to determine where to go next
; output:
;	carry = set:  if the Player pressed the B button
.Func_45a9
	call InitPlayAreaScreenVars
	ld a, CYCLE_PLAY_AREA_SCREENS
	ld [hl], a ; wPlayAreaSelectAction = CYCLE_PLAY_AREA_SCREENS
	call OpenPlayAreaScreenForViewing
	ldh a, [hKeysPressed]
	and PAD_B
	ret z ; return no carry if the B button wasn't pressed
	scf
	ret


; draws the screen that lists the opponent's play area Pokemon
OpenNonTurnHolderPlayAreaScreen:
	rst SwapTurn
	call OpenTurnHolderPlayAreaScreen
	jp SwapTurn


; draws the screen that lists the turn holder's play area Pokemon
OpenTurnHolderPlayAreaScreen:
	call InitPlayAreaScreenVars
	jp OpenPlayAreaScreenForViewing


; draws the non-turn holder's discard pile screen
OpenNonTurnHolderDiscardPileScreen:
	rst SwapTurn
	call OpenTurnHolderDiscardPileScreen
	jp SwapTurn


; draws the non-turn holder's hand screen. simpler version of OpenPlayerHandScreen
; used only for checking the cards rather than for playing them.
OpenNonTurnHolderHandScreen_Simple:
	rst SwapTurn
	call OpenTurnHolderHandScreen_Simple
	jp SwapTurn


; draws the turn holder's hand screen. simpler version of OpenPlayerHandScreen
; used only for checking the cards rather than for playing them.
; used for example in the "Your Play Area" screen of the Check menu.
OpenTurnHolderHandScreen_Simple:
	call CreateHandCardList
	jr c, .no_cards_in_hand
	call InitAndDrawCardListScreenLayout
	ld a, PAD_START + PAD_A
	ld [wNoItemSelectionMenuKeys], a
	jp DisplayCardList
.no_cards_in_hand
	ldtx hl, NoCardsInHandText
	jp DrawWideTextBox_WaitForInput


; sorts the turn holder's hand cards by ID (highest to lowest ID).
; makes use of wDuelTempList (what de is initially pointing to).
SortHandCardsByID:
	call FindLastCardInHand
.loop
	ld a, [hld]
	ld [de], a
	inc de
	dec b
	jr nz, .loop
	ld a, $ff ; terminating byte
	ld [de], a
	call SortCardsInDuelTempListByID
	call FindLastCardInHand
.loop2
	ld a, [de]
	inc de
	ld [hld], a
	dec b
	jr nz, .loop2
	ret


; draws the screen for the player's hand and handles user input to
; check or attempt to play a card from the hand
OpenPlayerHandScreen:
	call CreateHandCardList
	call InitAndDrawCardListScreenLayout
	ldtx hl, PleaseSelectHandText
	call SetCardListInfoBoxText
	ld a, PLAY_CHECK
	ld [wCardListItemSelectionMenuType], a
.handle_input
	call DisplayCardList
	push af
	ld a, [wSortCardListByID]
	or a
	call nz, SortHandCardsByID
	pop af
	jr c, .exit ; exit if the B button was pressed
	call LoadCardDataToBuffer1_FromDeckIndex
	ld a, [wLoadedCard1Type]
	ld c, a
	bit TYPE_TRAINER_F, c
	jr nz, .trainer_card
	bit TYPE_ENERGY_F, c
	jr nz, PlayEnergyCard
	call PlayPokemonCard
	jr c, ReloadCardListScreen ; jump if card not played
.exit
	jp DuelMainInterface
.trainer_card
	call PlayTrainerCard
	jr nc, .exit
;	fallthrough if card not played

; reloads the card list screen (because the selected card could not be played)
ReloadCardListScreen:
	call CreateHandCardList
	; skip doing the things that have already been done when initially opened
	call DrawCardListScreenLayout
	jr OpenPlayerHandScreen.handle_input


; input:
;	c = type of Energy card being played (TYPE_ENERGY_* constant)
;	[hTempCardIndex_ff98] = Energy card's deck index (0-59)
PlayEnergyCard:
	ld a, c
	cp TYPE_ENERGY_WATER
	jr nz, .rain_dance_not_active
	ld a, BLASTOISE
	call CountTurnDuelistPokemonWithActivePkmnPower
	jr nc, .rain_dance_not_active
	call CheckIfPkmnPowersAreCurrentlyDisabled
	jr nc, .rain_dance_active

.rain_dance_not_active
	ld a, [wOncePerTurnFlags]
	and PLAYED_ENERGY_THIS_TURN
	jr nz, .already_played_energy
	call InitVarsAndOpenPlayAreaScreenForSelection ; choose Pokemon to attach Energy card to
	jr c, .exit ; exit if the B button was pressed
.play_energy_set_played
	ld hl, wOncePerTurnFlags
	set PLAYED_ENERGY_THIS_TURN_F, [hl]
.play_energy
	ldh a, [hTempPlayAreaLocation_ff9d]
	ldh [hTempPlayAreaLocation_ffa1], a
	ld e, a
	ldh a, [hTempCardIndex_ff98]
	ldh [hTemp_ffa0], a
	call PutHandCardInPlayArea
	call PrintPlayAreaCardList_EnableLCD
	ld a, OPPACTION_PLAY_ENERGY
	call SetOppAction_SerialSendDuelData
	call PrintAttachedEnergyToPokemon
.exit
	jp DuelMainInterface

.rain_dance_active
	call InitVarsAndOpenPlayAreaScreenForSelection ; choose Pokemon to attach Energy card to
	jr c, .exit ; exit if the B button was pressed
	call GetPlayAreaCardColor
	cp TYPE_PKMN_WATER
	jr nz, .no_rain_dance ; attach normally if the target isn't a Water Pokémon
	ldh a, [hTempCardIndex_ff98]
	call GetCardTypeFromDeckIndex_SaveDE
	cp TYPE_ENERGY_WATER
	jr z, .play_energy ; ignore once per turn restriction if a Water Energy is being attached to a Water Pokémon
.no_rain_dance
	ld a, [wOncePerTurnFlags]
	and PLAYED_ENERGY_THIS_TURN
	jr z, .play_energy_set_played
	ldtx hl, MayOnlyAttachOneEnergyCardText
	call DrawWideTextBox_WaitForInput
	jp OpenPlayerHandScreen

.already_played_energy
	ldtx hl, MayOnlyAttachOneEnergyCardText
	call DrawWideTextBox_WaitForInput
	jr ReloadCardListScreen


; puts a Basic Pokemon into play, either in the Arena or on the Bench, or puts a
; Stage 1/2 Evolution card on top of a Pokemon that's already in play to evolve it.
; input:
;	[wLoadedCard1] = all of the Pokémon's data (card_data_struct)
;	[hTempCardIndex_ff98] = deck index of the Pokemon being played (0-59)
; output:
;	carry = set:  if the Pokemon card wasn't put into play
PlayPokemonCard:
	ld a, [wLoadedCard1Stage]
	or a ; BASIC
	jr nz, .try_evolve ; jump if the card being played isn't a Basic Pokemon
	ld a, DUELVARS_NUMBER_OF_POKEMON_IN_PLAY_AREA
	get_turn_duelist_var
	cp MAX_PLAY_AREA_POKEMON
	ldtx hl, NoSpaceOnTheBenchText
	jr nc, .print_text_and_return_carry
	ldh a, [hTempCardIndex_ff98]
	ldh [hTemp_ffa0], a
	call PutHandPokemonCardInPlayArea
	ldh [hTempPlayAreaLocation_ff9d], a
	add DUELVARS_ARENA_CARD_STAGE
	get_turn_duelist_var
	ld [hl], BASIC
	ld a, OPPACTION_PLAY_BASIC_PKMN
	call SetOppAction_SerialSendDuelData
	ldh a, [hTempCardIndex_ff98]
	call LoadCardDataToBuffer1_FromDeckIndex
	ld a, 20
	call CopyCardNameAndLevel
	xor a ; TX_END
	ld [hl], a ; terminate the text string at wDefaultText
	; zero wTxRam2 so that the name & level text just loaded to wDefaultText is printed
	ld hl, wTxRam2
	ld [hli], a
	ld [hl], a
	ldtx hl, PlacedOnTheBenchText
	call DrawWideTextBox_WaitForInput
	call ProcessPlayedPokemonCard
	or a
	ret

.try_evolve
	ld a, DUELVARS_NUMBER_OF_POKEMON_IN_PLAY_AREA
	get_turn_duelist_var
	ld c, a
	ldh a, [hTempCardIndex_ff98]
	ld d, a
	ld e, PLAY_AREA_ARENA
	push de
	push bc
.next_play_area_pkmn
	call CheckIfCanEvolveInto
	jr nc, .can_evolve
	inc e
	dec c
	jr nz, .next_play_area_pkmn
	pop bc
	pop de
.find_cant_evolve_reason_loop
; don't bother opening the selection screen if there are no Pokemon capable of evolving
	call CheckIfCanEvolveInto
	ldtx hl, CantEvolvePokemonInSameTurnItsPlacedText
	jr nz, .print_text_and_return_carry
	inc e
	dec c
	jr nz, .find_cant_evolve_reason_loop
	ldtx hl, NoPokemonCapableOfEvolvingText
.print_text_and_return_carry
	jp DrawWideTextBox_WaitForInput_ReturnCarry

.can_evolve
	pop bc
	pop de
	call IsPrehistoricPowerActive
	jr c, .print_text_and_return_carry
	call InitPlayAreaScreenVars
.try_evolve_loop
	call OpenPlayAreaScreenForSelection
	jr c, .done ; exit if the B button was pressed
	ldh a, [hTempCardIndex_ff98]
	ldh [hTemp_ffa0], a
	ldh a, [hTempPlayAreaLocation_ff9d]
	ldh [hTempPlayAreaLocation_ffa1], a
	call EvolvePokemonCardIfPossible
	jr c, .try_evolve_loop ; jump if evolution wasn't successful somehow
	ld a, OPPACTION_EVOLVE_PKMN
	call SetOppAction_SerialSendDuelData
	call PrintPlayAreaCardList_EnableLCD
	call PrintPokemonEvolvedIntoPokemon
	call ProcessPlayedPokemonCard
.done
	or a
	ret


; plays the Trainer card with deck index at hTempCardIndex_ff98.
; a Trainer card is like an attack effect, with its own effect commands.
; input:
;	[hTempCardIndex_ff98] = deck index of the Trainer card being played (0-59)
; output:
;	carry = set:  if the Trainer card wasn't played
PlayTrainerCard:
	call CheckCantUseTrainerDueToEffect
	jr c, PlayPokemonCard.print_text_and_return_carry
	ldh a, [hTempCardIndex_ff98]
	ldh [hTempCardIndex_ff9f], a
	call LoadNonPokemonCardEffectCommands
	ld a, EFFECTCMDTYPE_INITIAL_EFFECT_1
	call TryExecuteEffectCommandFunction
	jr c, PlayPokemonCard.print_text_and_return_carry
	ld a, EFFECTCMDTYPE_INITIAL_EFFECT_2
	call TryExecuteEffectCommandFunction
	jr c, .done
	ld a, OPPACTION_PLAY_TRAINER
	call SetOppAction_SerialSendDuelData
	call DisplayUsedTrainerCardDetailScreen
	call ExchangeRNG
	ld a, EFFECTCMDTYPE_DISCARD_ENERGY
	call TryExecuteEffectCommandFunction
	ld a, EFFECTCMDTYPE_REQUIRE_SELECTION
	call TryExecuteEffectCommandFunction
	ld a, OPPACTION_EXECUTE_TRAINER_EFFECTS
	call SetOppAction_SerialSendDuelData
	ld a, EFFECTCMDTYPE_BEFORE_DAMAGE
	call TryExecuteEffectCommandFunction
	ldh a, [hTempCardIndex_ff9f]
	call TryToDiscardCardFromHand
	call ExchangeRNG
.done
	or a
	ret


; checks if the turn holder's Active Pokemon is unable to retreat due to some status condition
; or because there are no Benched Pokemon with greater than 0 HP.
; output:
;	hl = ID for notification text:  if the below condition is true
;	carry = set:  if the Active Pokemon is unable to retreat
CheckAbleToRetreat:
	ld a, DUELVARS_NUMBER_OF_POKEMON_IN_PLAY_AREA
	get_turn_duelist_var
	dec a
	jr z, .unable_to_retreat ; can't retreat if there are no Benched Pokémon
	call CheckUnableToRetreatDueToEffect
	ret c
	ld a, DUELVARS_ARENA_CARD
	get_turn_duelist_var
	call GetCardTypeFromDeckIndex_SaveDE
	cp TYPE_TRAINER
	jr z, .unable_to_retreat
	call CheckIfEnoughEnergiesToRetreat
	ret nc
	; not enough Energy
	ld a, [wEnergyCardsRequiredToRetreat]
	ld hl, wTxRam3
	ld [hli], a
	ld [hl], $00
	ldtx hl, EnergyCardsRequiredToRetreatText
	ret ; carry set
.unable_to_retreat
	ldtx hl, UnableToRetreatText
	scf
	ret


; checks if the turn holder's Active Pokemon has enough Energy to retreat.
; output:
;	carry = set:  if the Pokemon doesn't have enough Energy to retreat
;	[wEnergyCardsRequiredToRetreat] = the Pokemon's Retreat Cost
CheckIfEnoughEnergiesToRetreat:
	xor a ; PLAY_AREA_ARENA
	ldh [hTempPlayAreaLocation_ff9d], a
	ld e, a
	call GetPlayAreaCardRetreatCost
	ld [wEnergyCardsRequiredToRetreat], a
	ld c, a
	call GetPlayAreaCardAttachedEnergies
	cp c
	ret


; displays the screen that prompts the player to select Energy cards to discard
; before retreating an Active Pokemon. also handles input in order to
; display the number of Energy cards that have already been selected.
; returns when enough Energy have been selected or if the player declines to retreat.
; output:
;	carry = set:  if the operation was cancelled by the Player (with B button)
;	hTempRetreatCostCards = $ff terminated list with deck indices of Energy cards that
;	                        will be discarded from the Active Pokemon upon retreat
DisplayRetreatScreen:
	ld a, $ff
	ldh [hTempRetreatCostCards], a
	ld a, [wEnergyCardsRequiredToRetreat]
	or a
	ret z ; return if no Energy cards are required to retreat (i.e. Retreat Cost = 0)
	xor a
	ld [wNumRetreatEnergiesSelected], a
	call CreateArenaOrBenchEnergyCardList
	call SortCardsInDuelTempListByID
	ld a, LOW(hTempRetreatCostCards)
	ld [wTempRetreatCostCardsPos], a
	xor a ; PLAY_AREA_ARENA
	call DisplayEnergyDiscardScreen
	ld a, [wEnergyCardsRequiredToRetreat]
	ld [wEnergyDiscardMenuDenominator], a
.select_energies_loop
	ld a, [wNumRetreatEnergiesSelected]
	ld [wEnergyDiscardMenuNumerator], a
	call HandleEnergyDiscardMenuInput
	ret c ; exit if the B button was pressed
	call LoadCardDataToBuffer2_FromDeckIndex
	; append selected Energy card to hTempRetreatCostCards
	ld hl, wTempRetreatCostCardsPos
	ld c, [hl]
	inc [hl]
	ldh a, [hTempCardIndex_ff98]
	ld [$ff00+c], a
	; accumulate selected Energy card
	ld c, 1
	ld a, [wLoadedCard2ID]
	cp DOUBLE_COLORLESS_ENERGY
	jr nz, .not_double
	inc c
.not_double
	ld hl, wNumRetreatEnergiesSelected
	ld a, [hl]
	add c
	ld [hl], a
	ld hl, wEnergyCardsRequiredToRetreat
	cp [hl]
	jr nc, .enough
	; more Energy is needed to retreat
	ldh a, [hTempCardIndex_ff98]
	call RemoveCardFromDuelTempList
	call DisplayEnergyDiscardMenu
	jr .select_energies_loop
.enough
	; terminate hTempRetreatCostCards array with $ff
	ld a, [wTempRetreatCostCardsPos]
	ld c, a
	ld a, $ff
	ld [$ff00+c], a
	or a
	ret


; discards Retreat Cost Energy cards and attempts retreat of the Active Pokemon.
; if successful, the retreating Pokemon is replaced with a Benched Pokemon card.
; if unsuccessful, sets UNABLE_TO_RETREAT_THIS_TURN_F in wOncePerTurnFlags and returns carry.
; input:
;	[hTemp_ffa0] = Active Pokémon's Special Conditions status (from DUELVARS_ARENA_CARD_STATUS)
;	[hTempPlayAreaLocation_ffa1] = play area location offset of the Benched Pokémon to switch with
;	hTempRetreatCostCards = $ff terminated list with deck indices of cards to discard
; output:
;	carry = set:  if unable to retreat this turn due to a failed confusion check
AttemptRetreat:
	call DiscardRetreatCostCards
	ldh a, [hTemp_ffa0]
	and CNF_SLP_PRZ
	cp CONFUSED
	jr nz, .success
	ldtx de, ConfusionCheckRetreatText
	call TossCoin
	jr c, .success
	ld hl, wOncePerTurnFlags
	set UNABLE_TO_RETREAT_THIS_TURN_F, [hl]
	scf
	ret
.success
	ldh a, [hTempPlayAreaLocation_ffa1]
	ld e, a
	call SwapArenaWithBenchPokemon ; resets carry flag
	ld hl, wOncePerTurnFlags
	res UNABLE_TO_RETREAT_THIS_TURN_F, [hl]
	ret


; moves the cards loaded by deck index at hTempRetreatCostCards to the discard pile
; preserves bc and de
; input:
;	hTempRetreatCostCards = $ff terminated list with deck indices of cards to discard
DiscardRetreatCostCards:
	ld hl, hTempRetreatCostCards
.discard_loop
	ld a, [hli]
	cp $ff
	ret z
	call PutCardInDiscardPile
	jr .discard_loop


; moves the discard pile cards that were loaded to hTempRetreatCostCards back to the Active Pokemon.
; this exists because they will be discarded again during the call to AttemptRetreat, so
; it prevents the Energy cards from being discarded twice.
; preserves bc and d
; input:
;	hTempRetreatCostCards = $ff-terminated list with deck indices of cards to discard
ReturnRetreatCostCardsToArena:
	ld hl, hTempRetreatCostCards
.loop
	ld a, [hli]
	cp $ff
	ret z
	push hl
	call MoveCardFromDiscardPileToHand
	ld e, PLAY_AREA_ARENA
	call PutHandCardInPlayArea
	pop hl
	jr .loop


; displays the screen that prompts the player to select Energy cards to discard
; in order to retreat a Pokemon or use an attack like Flamethrower. includes the
; card's information and a menu to select the attached Energy cards to discard.
; input:
;	a = play area location offset of the Pokemon to discard Energy from (PLAY_AREA_* constant)
DisplayEnergyDiscardScreen:
	ld [wEnergyDiscardPlayAreaLocation], a
	call EmptyScreen
	call LoadDuelCardSymbolTiles
	call LoadDuelFaceDownCardTiles
	ld a, [wEnergyDiscardPlayAreaLocation]
	ld hl, wCurPlayAreaSlot
	ld [hli], a
	xor a
	ld [hl], a ; wCurPlayAreaY = 0
	ld [wEnergyDiscardMenuNumerator], a
	inc a ; 1
	ld [wEnergyDiscardMenuDenominator], a
	call PrintPlayAreaCardInformation
;	fallthrough

; displays the menu that belongs to the Energy discard screen, which has the
; Player select Energy cards attached to a Pokemon in the play area in order
; to retreat it to the Bench or use an attack like Flamethrower, Recover, etc.
; input:
;	wDuelTempList = $ff terminated list of the relevant Energy cards
DisplayEnergyDiscardMenu:
	lb de, 0, 3
	lb bc, 20, 10
	call DrawRegularTextBox
	ldtx hl, ChooseEnergyCardToDiscardText
	call DrawWideTextBox_PrintTextNoDelay
	call EnableLCD
	call CountCardsInDuelTempList
	ld hl, EnergyDiscardCardListParameters
	lb de, 0, 0 ; initial page scroll offset, initial item (in the visible page)
	call PrintCardListItems
	ld a, 4
	ld [wCardListIndicatorYPosition], a
	ret

EnergyDiscardCardListParameters:
	db 1, 5 ; cursor x, cursor y
	db 4 ; item x
	db 14 ; maximum length, in tiles, occupied by the name and level string of each card in the list
	db 4 ; number of items selectable without scrolling
	db SYM_CURSOR_R ; cursor tile number
	db SYM_SPACE ; tile behind cursor
	dw NULL ; function pointer if non-0


; if [wEnergyDiscardMenuDenominator] != 0:
;	prints "[wEnergyDiscardMenuNumerator]/[wEnergyDiscardMenuDenominator]" at coordinates 16,16,
;	where [wEnergyDiscardMenuNumerator] is the amount of Energy already selected to be discarded
;	and [wEnergyDiscardMenuDenominator] is the total amount of Energy that needs to be discarded.
; if [wEnergyDiscardMenuDenominator] == 0:
;	prints only "[wEnergyDiscardMenuNumerator]"
; input:
;	[wEnergyDiscardMenuNumerator] = amount of Energy already selected to be discarded
;	[wEnergyDiscardMenuDenominator] = total amount of Energy that needs to be discarded
;	wDuelTempList = $ff terminated list with deck indices of attached Energy cards
; output:
;	a & [hTempCardIndex_ff98] = selected card's deck index (0-59)
;	carry = set:  if the B button was pressed to exit the Energy Discard menu
HandleEnergyDiscardMenuInput:
	lb bc, 16, 16
	ld a, [wEnergyDiscardMenuDenominator]
	or a
	jr z, .print_single_number
	ld a, [wEnergyDiscardMenuNumerator]
	add SYM_0
	call WriteByteToBGMap0
	inc b
	ld a, SYM_SLASH
	call WriteByteToBGMap0
	inc b
	ld a, [wEnergyDiscardMenuDenominator]
	add SYM_0
	call WriteByteToBGMap0
	jr .wait_input
.print_single_number
	ld a, [wEnergyDiscardMenuNumerator]
	inc b
	call WriteTwoDigitNumberInTxSymbolFormat_TrimLeadingZero
.wait_input
	call DoFrame
	call HandleMenuInput
	jr nc, .wait_input
	cp -1
	scf
	ret z ; return carry if the B button was pressed
	call GetCardInDuelTempList_OnlyDeckIndex
	or a
	ret


; draws the attack page of the card at wLoadedCard1 and of the attack selected in the Attack
; menu by hCurMenuItem, and listen for input in order to switch the page or to exit.
; input:
;	wDuelTempList = start of an $ff-terminated list with info for a Pokémon's attacks,
;	                list format: <deck index of Pokémon card (0-59)>, <attack index (0-1)>
;	[wLoadedCard1] = all of the Pokémon's data (card_data_struct)
OpenAttackPage:
	ld a, CARDPAGE_POKEMON_OVERVIEW
	ld [wCardPageNumber], a
	xor a
	ld [wCurPlayAreaSlot], a
	call EmptyScreen
	call FinishQueuedAnimations
	ld de, v0Tiles1 + $20 tiles
	call LoadLoaded1CardGfx
	call SetOBP1OrSGB3ToCardPalette
	call SetBGP6OrSGB3ToCardPalette
	call FlushAllPalettesOrSendPal23Packet
	lb de, $38, $30 ; X Position and Y Position of top-left corner
	call PlaceCardImageOAM
	lb de, 6, 4
	call ApplyBGP6OrSGB3ToCardImage
	ldh a, [hCurMenuItem]
	ld [wSelectedDuelSubMenuItem], a
	add a
	ld e, a
	ld d, $00
	ld hl, wDuelTempList + 1
	add hl, de
	ld a, [hl] ; load the relevant attack index
	or a ; cp FIRST_ATTACK_OR_PKMN_POWER
	jr z, .store_page_number ; use ATTACKPAGE_ATTACK1_1
	ld a, ATTACKPAGE_ATTACK2_1
.store_page_number
	ld [wAttackPageNumber], a
.open_page
	call DisplayAttackPage
	call EnableLCD
.loop
	call DoFrame
	; switch page (see SwitchAttackPage) if Right or Left D-Pad pressed
	ldh a, [hDPadHeld]
	and PAD_RIGHT | PAD_LEFT
	jr nz, .open_page
	; return to Attack menu if A or B pressed
	ldh a, [hKeysPressed]
	and PAD_A | PAD_B
	jr z, .loop
	ret


; displays the card page with ID at wAttackPageNumber for card in wLoadedCard1
; input:
;	[wAttackPageNumber] = which card page to load (ATTACKPAGE_ATTACK* constant)
;	[wLoadedCard1] = all of the Pokémon's data (card_data_struct)
DisplayAttackPage:
	ld a, [wAttackPageNumber]
	ld hl, AttackPageDisplayPointerTable
	jp JumpToFunctionInTable

AttackPageDisplayPointerTable:
	dw DisplayAttackPage_Attack1Page1 ; ATTACKPAGE_ATTACK1_1
	dw DisplayAttackPage_Attack1Page2 ; ATTACKPAGE_ATTACK1_2
	dw DisplayAttackPage_Attack2Page1 ; ATTACKPAGE_ATTACK2_1
	dw DisplayAttackPage_Attack2Page2 ; ATTACKPAGE_ATTACK2_2


; displays ATTACKPAGE_ATTACK1_1
DisplayAttackPage_Attack1Page1:
	call DisplayCardPage_PokemonAttack1Page1
	ld hl, wLoadedCard1Atk1Description + 2
.print_down_arrow_and_switch_attack_page
	call PrintDownArrowIfSecondDescriptionPage
;	fallthrough

; switches to ATTACKPAGE_ATTACK*_2 if in ATTACKPAGE_ATTACK*_1 and vice versa.
; sets the next attack page to switch to if Right or Left D-Pad are pressed.
; preserves bc and de
SwitchAttackPage:
	ld hl, wAttackPageNumber
	ld a, $01
	xor [hl]
	ld [hl], a
	ret


; displays ATTACKPAGE_ATTACK1_2 if it exists. otherwise return in order
; to switch back to ATTACKPAGE_ATTACK1_1 and display it instead.
DisplayAttackPage_Attack1Page2:
	ld hl, wLoadedCard1Atk1Description + 2
	ld a, [hli]
	or [hl]
	ret z ; return if the pointer is null (i.e. this attack doesn't have a second page)
	call DisplayCardPage_PokemonAttack1Page2
	call PrintUpArrowOnSecondDescriptionPage
	jr SwitchAttackPage


; displays ATTACKPAGE_ATTACK2_1
DisplayAttackPage_Attack2Page1:
	call DisplayCardPage_PokemonAttack2Page1
	ld hl, wLoadedCard1Atk2Description + 2
	jr DisplayAttackPage_Attack1Page1.print_down_arrow_and_switch_attack_page


; displays ATTACKPAGE_ATTACK2_2 if it exists. otherwise, return in order
; to switch back to ATTACKPAGE_ATTACK2_1 and display it instead.
DisplayAttackPage_Attack2Page2:
	ld hl, wLoadedCard1Atk2Description + 2
	ld a, [hli]
	or [hl]
	ret z ; return if the pointer is null (i.e. this attack doesn't have a second page)
	call DisplayCardPage_PokemonAttack2Page2
	call PrintUpArrowOnSecondDescriptionPage
	jr SwitchAttackPage


; given the card at hTempCardIndex_ff98, for each non-empty, non-Pokemon Power attack slot,
; prints its information at lines 13 (first attack, if any), and 15 (second attack, if any)
; output:
;	a = number of non-empty, non-Pokemon Power attacks
;	wDuelTempList = start of an $ff-terminated list with info for the Active Pokémon's attacks,
;	                list format: <deck index of Pokémon card (0-59)>, <attack index (0-1)>
PrintAndLoadAttacksToDuelTempList:
	call DrawWideTextBox
	ld a, DUELVARS_ARENA_CARD
	get_turn_duelist_var
	ldh [hTempCardIndex_ff98], a
	call LoadCardDataToBuffer1_FromDeckIndex
	lb bc, 13, 0
	; b = y-coordinate, c = counter for number of actual attacks
	xor a
	ld [wCardPageNumber], a
	ld hl, wLoadedCard1Atk1Name
	call .CheckAttackSlotEmptyOrPokemonPower
	ld hl, wDuelTempList
	jr c, .check_second_atk_slot
	ldh a, [hTempCardIndex_ff98]
	ld [hli], a
	xor a ; FIRST_ATTACK_OR_PKMN_POWER
	ld [hli], a
	inc c
	push hl
	ld e, b
	ld hl, wLoadedCard1Atk1Name
	call PrintAttackOrPkmnPowerInformation
	pop hl
	inc b
	inc b ; 15
.check_second_atk_slot
	push hl
	ld hl, wLoadedCard1Atk2Name
	call .CheckAttackSlotEmptyOrPokemonPower
	pop hl
	jr c, .done
	ldh a, [hTempCardIndex_ff98]
	ld [hli], a
	ld a, SECOND_ATTACK
	ld [hli], a
	inc c
	ld e, b
	ld hl, wLoadedCard1Atk2Name
	call PrintAttackOrPkmnPowerInformation
.done
	ld a, c
	ret

; preserves bc
; input:
;	hl = wLoadedCard*Atk*Name
; output:
;	carry = set:  if the attack is a Pokemon Power or if the attack slot is empty
.CheckAttackSlotEmptyOrPokemonPower:
	ld a, [hli]
	or [hl]
	scf
	ret z ; return carry if this attack slot is blank
	ld de, CARD_DATA_ATTACK1_CATEGORY - (CARD_DATA_ATTACK1_NAME + 1)
	add hl, de
	ld a, [hl]
	and $ff ^ RESIDUAL
	cp POKEMON_POWER
	scf
	ret z ; return carry if this attack slot contains a Pokémon Power
	or a
	ret


; checks if the Active Pokemon card has enough Energy attached to it to use the selected attack.
; preserves bc and hl
; input:
;	wDuelTempList = start of an $ff-terminated list with info for a Pokémon's attacks,
;	                list format: <deck index of Pokémon card (0-59)>, <attack index (0-1)>
; output:
;	carry = set:  if the Pokemon doesn't have enough Energy to use the attack
;	           OR if the given attack slot contains a Pokemon Power or is blank
CheckIfEnoughEnergiesToAttack:
	push hl
	push bc
	ld e, PLAY_AREA_ARENA
	call GetPlayAreaCardAttachedEnergies
	call HandleEnergyBurn
	ldh a, [hCurMenuItem]
	add a
	ld e, a
	ld d, $0
	ld hl, wDuelTempList
	add hl, de
	ld d, [hl] ; card's deck index (0-59)
	inc hl
	ld e, [hl] ; attack index (0 or 1)
	call _CheckIfEnoughEnergiesToAttack
	pop bc
	pop hl
	ret


; checks if a Pokemon has enough Energy attached to it in order to use an attack
; preserves de
; input:
;	d = Pokemon's deck index (0-59)
;	e = attack index (0 = first attack, 1 = second attack)
;	[wAttachedEnergies] (8 bytes) = how many Energy of each type is attached to the Pokemon
;	[wTotalAttachedEnergies] = total amount of Energy attached to the Pokemon
; output:
;	carry = set:  if the Pokemon doesn't have enough Energy to use the attack
;	           OR if the given attack slot contains a Pokemon Power or is blank
_CheckIfEnoughEnergiesToAttack:
	push de
	ld a, d
	call LoadCardDataToBuffer1_FromDeckIndex
	ld a, e
	ld de, wLoadedCard1Atk1EnergyCost
	or a ; cp FIRST_ATTACK_OR_PKMN_POWER
	jr z, .got_atk
	ld de, wLoadedCard1Atk2EnergyCost

.got_atk
	ld hl, CARD_DATA_ATTACK1_NAME - CARD_DATA_ATTACK1_ENERGY_COST
	add hl, de
	ld a, [hli]
	or [hl]
	jr z, .not_usable_or_not_enough_energies
	ld hl, CARD_DATA_ATTACK1_CATEGORY - CARD_DATA_ATTACK1_ENERGY_COST
	add hl, de
	ld a, [hl]
	cp POKEMON_POWER
	jr z, .not_usable_or_not_enough_energies
	xor a
	ld [wAttachedEnergiesAccum], a
	ld hl, wAttachedEnergies
	ld c, (NUM_COLORED_TYPES) / 2

.next_energy_type_pair
	ld a, [de]
	swap a
	call CheckIfEnoughEnergiesOfType
	jr c, .not_usable_or_not_enough_energies
	ld a, [de]
	call CheckIfEnoughEnergiesOfType
	jr c, .not_usable_or_not_enough_energies
	inc de
	dec c
	jr nz, .next_energy_type_pair
	ld a, [de] ; Colorless energy
	swap a
	and $f
	ld b, a
	ld a, [wAttachedEnergiesAccum]
	ld c, a
	ld a, [wTotalAttachedEnergies]
	sub c
	cp b
	pop de
	ret

.not_usable_or_not_enough_energies
	scf
	pop de
	ret


; given the amount of a specific type of Energy required for an attack
; in the lower nybble of register a, checks whether the Pokemon
; has enough attached Energy of that type to use the attack.
; preserves bc and de
; input:
;	a = amount of a specific type of Energy in the attack cost
;	[hl] = amount of a specific type of Energy attached to this Pokemon
; output:
;	carry = set:  if the Pokemon doesn't have enough of that type of Energy to use the attack
CheckIfEnoughEnergiesOfType:
	and $f
	push af
	push hl
	ld hl, wAttachedEnergiesAccum
	add [hl]
	ld [hl], a ; accumulate the amount of Energy required for the attack
	pop hl
	pop af
	jr z, .done ; return no carry if no Energy of this type are required
	dec a ; subtract 1 so carry will be set if difference = 0
	cp [hl]
	; carry is now set if the Energy requirement in the attack cost
	; is less than or equal to the amount of attached Energy
	ccf ; reverse carry
.done
	inc hl
	ret


; displays the animation for the turn holder drawing one card at the beginning of the turn.
; if there aren't any cards left in the deck, lets the player know with a text message.
; preserves all registers except af
DisplayDrawOneCardScreen:
	ld a, 1
;	fallthrough

; displays the animation for the turn holder drawing a given number of cards.
; if there aren't any cards left in the deck, lets the player know with a text message.
; preserves all registers except af
; input:
;	a = number of cards to draw
DisplayDrawNCardsScreen:
	push hl
	push de
	push bc
	ld [wNumCardsTryingToDraw], a
	xor a
	ld [wNumCardsBeingDrawn], a
	ld a, DUELVARS_NUMBER_OF_CARDS_NOT_IN_DECK
	get_turn_duelist_var
	ld a, DECK_SIZE
	sub [hl]
	ld hl, wNumCardsTryingToDraw
	cp [hl]
	jr nc, .has_cards_left
	; trying to draw more cards than there are left in the deck
	ld [hl], a ; draw the same number of cards that are still in the deck
.has_cards_left
	ld a, [wDuelDisplayedScreen]
	cp DRAW_CARDS
	jr z, .portraits_drawn
	cp SHUFFLE_DECK
	jr z, .portraits_drawn
	call EmptyScreen
	call DrawDuelistPortraitsAndNames
.portraits_drawn
	ld a, DRAW_CARDS
	ld [wDuelDisplayedScreen], a
	call PrintDeckAndHandIconsAndNumberOfCards
	ld a, [wNumCardsTryingToDraw]
	or a
	jr nz, .can_draw
	; if wNumCardsTryingToDraw set to 0 before, it's because not enough cards in deck
	ldtx hl, CannotDrawCardBecauseNoCardsInDeckText
	call DrawWideTextBox_WaitForInput
	jr .done
.can_draw
	ld hl, wTxRam3
	ld [hli], a
	xor a
	ld [hl], a
	ldtx hl, DrawCardsFromTheDeckText
	call DrawWideTextBox_PrintText
	call EnableLCD
.anim_drawing_cards_loop
	call PlayTurnDuelistDrawAnimation
	ld hl, wNumCardsBeingDrawn
	inc [hl]
	call PrintNumberOfHandAndDeckCards
	ld a, [wNumCardsBeingDrawn]
	ld hl, wNumCardsTryingToDraw
	cp [hl]
	jr c, .anim_drawing_cards_loop
	; wait up to 30 frames before finishing
	ld a, 30 ; frames to delay
	call WaitAFrames_AllowSkipDelay
.done
	pop bc
	pop de
	pop hl
	ret


; animates the screen when the turn holder draws a card
PlayTurnDuelistDrawAnimation:
	call ResetAnimationQueue
	ld e, DUEL_ANIM_PLAYER_DRAW
	ldh a, [hWhoseTurn]
	cp PLAYER_TURN
	jr z, .got_duelist
	ld e, DUEL_ANIM_OPP_DRAW
.got_duelist
	ld a, e
	call PlayDuelAnimation
	call WaitForAnimationToFinish_AllowSkipDelay
	jp FinishQueuedAnimations


; prints, for each duelist, the number of cards in the hand along with the
; hand icon, and the number of cards in the deck, along with the deck icon,
; according to each element's placement in the draw card(s) screen.
PrintDeckAndHandIconsAndNumberOfCards:
	call LoadDuelDrawCardsScreenTiles
	ld hl, DeckAndHandIconsTileData
	call WriteDataBlocksToBGMap0
	ld a, [wConsole]
	cp CONSOLE_CGB
	jr nz, .not_cgb
	call BankswitchVRAM1
	ld hl, DeckAndHandIconsCGBPalData
	call WriteDataBlocksToBGMap0
	call BankswitchVRAM0
.not_cgb
	call PrintPlayerNumberOfHandAndDeckCards
;	fallthrough

PrintOpponentNumberOfHandAndDeckCards:
	ld a, [wOpponentNumberOfCardsInHand]
	ld hl, wNumCardsBeingDrawn
	add [hl]
	ld d, a
	ld a, DECK_SIZE
	ld hl, wOpponentNumberOfCardsNotInDeck
	sub [hl]
	ld hl, wNumCardsBeingDrawn
	sub [hl]
	ld e, a
	ld a, d
	lb bc, 5, 3
	call WriteTwoDigitNumberInTxSymbolFormat_TrimLeadingZero
	ld a, e
	lb bc, 11, 3
	jp WriteTwoDigitNumberInTxSymbolFormat_TrimLeadingZero


; prints, for each duelist, the number of cards in the hand, and the number
; of cards in the deck, according to their placement in the draw card(s) screen.
; input:
;	[wNumCardsBeingDrawn] = number of cards being drawn (in order to add them to
;	                        the hand cards and subtract them from the deck cards)
PrintNumberOfHandAndDeckCards:
	ldh a, [hWhoseTurn]
	cp PLAYER_TURN
	jr nz, PrintOpponentNumberOfHandAndDeckCards
;	fallthrough

PrintPlayerNumberOfHandAndDeckCards:
	ld a, [wPlayerNumberOfCardsInHand]
	ld hl, wNumCardsBeingDrawn
	add [hl]
	ld d, a
	ld a, DECK_SIZE
	ld hl, wPlayerNumberOfCardsNotInDeck
	sub [hl]
	ld hl, wNumCardsBeingDrawn
	sub [hl]
	ld e, a
	ld a, d
	lb bc, 16, 10
	call WriteTwoDigitNumberInTxSymbolFormat_TrimLeadingZero
	ld a, e
	lb bc, 10, 10
	jp WriteTwoDigitNumberInTxSymbolFormat_TrimLeadingZero


DeckAndHandIconsTileData:
; x, y, tiles[], 0
	db  4,  3, SYM_CROSS, 0 ; x for opponent's hand
	db 10,  3, SYM_CROSS, 0 ; x for opponent's deck
	db  8,  2, $f4, $f5,  0 ; opponent's deck icon
	db  8,  3, $f6, $f7,  0 ; opponent's deck icon
	db  2,  2, $f8, $f9,  0 ; opponent's hand icon
	db  2,  3, $fa, $fb,  0 ; opponent's hand icon
	db  9, 10, SYM_CROSS, 0 ; x for player's deck
	db 15, 10, SYM_CROSS, 0 ; x for player's hand
	db  7,  9, $f4, $f5,  0 ; player's deck icon
	db  7, 10, $f6, $f7,  0 ; player's deck icon
	db 13,  9, $f8, $f9,  0 ; player's hand icon
	db 13, 10, $fa, $fb,  0 ; player's hand icon
	db $ff


DeckAndHandIconsCGBPalData:
; x, y, pals[], 0
	db  8,  2, $02, $02, 0
	db  8,  3, $02, $02, 0
	db  2,  2, $02, $02, 0
	db  2,  3, $02, $02, 0
	db  7,  9, $02, $02, 0
	db  7, 10, $02, $02, 0
	db 13,  9, $02, $02, 0
	db 13, 10, $02, $02, 0
	db $ff


; draws the portraits of the two duelists and prints their names.
; also draws a horizontal line to separate the two sides of the Arena.
DrawDuelistPortraitsAndNames:
	call LoadSymbolsFont
	; player's name
	ld de, wDefaultText
	push de
	call CopyPlayerName
	lb de, 0, 11
	pop hl
	call InitTextPrinting_ProcessText
	; player's portrait
	lb bc, 0, 5
	call DrawPlayerPortrait
	; opponent's name (aligned to the right)
	ld de, wDefaultText
	push de
	call CopyOpponentName
	pop hl
	call GetTextLengthInTiles
	push hl
	add SCREEN_WIDTH
	ld d, a
	ld e, 0
	pop hl
	call InitTextPrinting_ProcessText
	; opponent's portrait
	ld a, [wOpponentPortrait]
	lb bc, 13, 1
	call DrawOpponentPortrait
	; middle line
;	fallthrough

; draws a horizontal line to separate the two sides of the Arena
; and then colorizes it if playing on a Game Boy Color
DrawDuelHorizontalSeparator:
	ld hl, DuelHorizontalSeparatorTileData
	call WriteDataBlocksToBGMap0
	ld a, [wConsole]
	cp CONSOLE_CGB
	ret nz
	call BankswitchVRAM1
	ld hl, DuelHorizontalSeparatorCGBPalData
	call WriteDataBlocksToBGMap0
	jp BankswitchVRAM0

DuelHorizontalSeparatorTileData:
; x, y, tiles[], 0
	db 0, 4, $37, $37, $37, $37, $37, $37, $37, $37, $37, $31, $32, 0
	db 9, 5, $33, $34, 0
	db 9, 6, $33, $34, 0
	db 9, 7, $35, $36, $37, $37, $37, $37, $37, $37, $37, $37, $37, 0
	db $ff

DuelHorizontalSeparatorCGBPalData:
; x, y, pals[], 0
	db 0, 4, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, 0
	db 9, 5, $02, $02, 0
	db 9, 6, $02, $02, 0
	db 9, 7, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, 0
	db $ff


; prints the number of remaining Prizes for each player,
; whether or not there's an Active Pokemon in either play area,
; and the number of cards left in each player's deck.
; this is called when drawing the results screen at the end of a duel.
PrintDuelResultStats:
	rst SwapTurn
	lb de, 1, 1
	call .PrintDuelistResultStats
	rst SwapTurn
	lb de, 8, 8
;	fallthrough

; prints, at d,e, how many Prizes the turn holder hasn't drawn,
; whether the turn holder still has an Active Pokemon,
; and the number of cards left in the turn holder's deck.
; b,c are used throughout as input coordinates for
; WriteTwoDigitNumberInTxSymbolFormat_TrimLeadingZero,
; and d,e is used for InitTextPrinting_ProcessTextFromID.
; input:
;	de = screen coordinates at which to begin printing the stats
.PrintDuelistResultStats:
	ld a, SINGLE_SPACED
	ld [wLineSeparation], a
	ldtx hl, PrizesLeftActivePokemonCardsInDeckText
	call InitTextPrinting_ProcessTextFromID
	xor a ; DOUBLE_SPACED
	ld [wLineSeparation], a
	ld c, e
	ld a, d
	add 7
	ld b, a
	inc a
	inc a
	ld d, a
	call CountPrizes
	call .print_x_cards
	inc e
	inc c
	ld a, DUELVARS_NUMBER_OF_POKEMON_IN_PLAY_AREA
	get_turn_duelist_var
	ldtx hl, YesText
	or a
	jr nz, .pkmn_in_play_area
	ldtx hl, NoneText
.pkmn_in_play_area
	dec d
	call InitTextPrinting_ProcessTextFromID
	inc e
	inc d
	inc c
	ld a, DUELVARS_NUMBER_OF_CARDS_NOT_IN_DECK
	get_turn_duelist_var
	ld a, DECK_SIZE
	sub [hl]
.print_x_cards
	call WriteTwoDigitNumberInTxSymbolFormat_TrimLeadingZero
	ldtx hl, CardsText
	jp InitTextPrinting_ProcessTextFromID


; after a Trainer card is played, draws its graphic in a card frame and prints "Used xxx"
; input:
;	[hTempCardIndex_ff9f] = Trainer card's deck index (0-59)
DisplayUsedTrainerCardDetailScreen::
	ldh a, [hTempCardIndex_ff9f]
	ldtx hl, UsedText
	jr DisplayCardDetailScreen

; displays the card detail screen after the Player draws a card from their deck
; input:
;	[hTempCardIndex_ff98] = deck index of the card to display (0-59)
DisplayPlayerDrawCardScreen:
	ldh a, [hTempCardIndex_ff98]
	ldtx hl, YouDrewText
;	fallthrough

; draws an oversized card oncreen revealing its type and graphic and prints the text at hl
; in a textbox at the bottom of the screen after adding the card's name to the text
; input:
;	a = deck index of the card to display (0-59)
;	hl = text ID for the text to print at the bottom of the screen
DisplayCardDetailScreen:
	call LoadCardDataToBuffer1_FromDeckIndex
;	fallthrough

; input:
;	hl = text ID for the text to print at the bottom of the screen
;	[wLoadedCard1] = all of the card's data (card_data_struct)
_DisplayCardDetailScreen:
	push hl
	call DrawLargePictureOfCard
	ld a, 18
	call CopyCardNameAndLevel
	xor a ; TX_END
	ld [hl], a ; terminate the text string at wDefaultText
	; zero wTxRam2 so that the name & level text just loaded to wDefaultText is printed
	ld hl, wTxRam2
	ld [hli], a
	ld [hl], a
	pop hl
	jp DrawWideTextBox_WaitForInput


; input:
;	wDuelTempList = $ff terminated list with deck indices of cards
DisplayCardListDetails:
	ld a, [wDuelTempList]
	cp $ff
	ret z ; return if the list is empty
	call InitAndDrawCardListScreenLayout
	call CountCardsInDuelTempList ; list length
	ld hl, CardListParameters ; other list params
	lb de, 0, 0 ; initial page scroll offset, initial item (in the visible page)
	call PrintCardListItems
	ldtx hl, TheCardYouReceivedText
	lb de, 1, 1
	call InitTextPrinting_PrintTextNoDelay
	ldtx hl, YouReceivedTheseCardsText
	jp DrawWideTextBox_WaitForInput


; handles the initial duel actions:
; - drawing starting hand and placing the Basic Pokemon cards
; - placing the appropriate number of Prize cards
; - tossing a coin to determine which player player goes first
HandleDuelSetup:
; init variables and shuffle cards
	call InitDuelVariables_BothDuelists
	call PlayShuffleAndDrawCardsAnimation_BothDuelists
	call ShuffleDeckAndDrawSevenCards
	ldh [hTemp_ffa0], a
	rst SwapTurn
	call ShuffleDeckAndDrawSevenCards
	rst SwapTurn
	ld c, a

; check if any Basic Pokémon cards were drawn
	ldh a, [hTemp_ffa0]
	ld b, a
	and c
	jr nz, .hand_cards_ok
	ld a, b
	or c
	jr z, .neither_drew_basic_pkmn
	ld a, b
	or a
	jr nz, .opp_drew_no_basic_pkmn

;.player_drew_no_basic_pkmn
.ensure_player_basic_pkmn_loop
	call DisplayNoBasicPokemonInHandScreenAndText
	call InitDuelVariables_TurnDuelist
	call PlayShuffleAndDrawCardsAnimation_TurnDuelist
	call ShuffleDeckAndDrawSevenCards
	jr c, .ensure_player_basic_pkmn_loop
	jr .hand_cards_ok

.neither_drew_basic_pkmn
	ldtx hl, NeitherPlayerHasBasicPkmnText
	call DrawWideTextBox_WaitForInput
	call DisplayNoBasicPokemonInHandScreen
	rst SwapTurn
	call DisplayNoBasicPokemonInHandScreen
	rst SwapTurn
	call PrintReturnCardsToDeckDrawAgain
	jr HandleDuelSetup

.opp_drew_no_basic_pkmn
	rst SwapTurn
.ensure_opp_basic_pkmn_loop
	call DisplayNoBasicPokemonInHandScreenAndText
	call InitDuelVariables_TurnDuelist
	call PlayShuffleAndDrawCardsAnimation_TurnDuelist
	call ShuffleDeckAndDrawSevenCards
	jr c, .ensure_opp_basic_pkmn_loop
	rst SwapTurn

.hand_cards_ok
	ldh a, [hWhoseTurn]
	push af
	ld a, PLAYER_TURN
	ldh [hWhoseTurn], a
	call ChooseInitialArenaAndBenchPokemon
	rst SwapTurn
	call ChooseInitialArenaAndBenchPokemon
	rst SwapTurn
	jr nc, .continue
	; error
	pop af
	ldh [hWhoseTurn], a
	scf
	ret
.continue
	call DrawPlayAreaToPlacePrizeCards
	ldtx hl, PlacingThePrizesText
	call DrawWideTextBox_WaitForInput
	call ExchangeRNG

	ld a, [wDuelInitialPrizes]
	ld hl, wTxRam3
	ld [hli], a
	xor a
	ld [hl], a
	ldtx hl, PleasePlacePrizesText
	call DrawWideTextBox_PrintText
	call EnableLCD
	call .PlacePrizes
	call WaitForWideTextBoxInput
	pop af

	ldh [hWhoseTurn], a
	call InitPrizes_BothDuelists
	call EmptyScreen
	ld a, BOXMSG_COIN_TOSS
	call DrawDuelBoxMessage
	ldtx hl, CoinTossToDecideWhoPlaysFirstText
	call DrawWideTextBox_WaitForInput
	ldh a, [hWhoseTurn]
	cp PLAYER_TURN
	jr nz, .opponent_turn

; player flips coin
	ld de, wDefaultText
	call CopyPlayerName
	; zero wTxRam2 so that the name that was just loaded to wDefaultText is printed
	ld hl, wTxRam2
	xor a
	ld [hli], a
	ld [hl], a
	ldtx hl, YouPlayFirstText
	ldtx de, IfHeadsDuelistPlaysFirstText
	call TossCoin
	jr c, .play_first ; jump if heads
	rst SwapTurn
	ldtx hl, YouPlaySecondText
.play_first
	call DrawWideTextBox_WaitForInput
	call ExchangeRNG
	or a
	ret

.opponent_turn
; opp flips coin
	ld de, wDefaultText
	call CopyOpponentName
	; zero wTxRam2 so that the name that was just loaded to wDefaultText is printed
	ld hl, wTxRam2
	xor a
	ld [hli], a
	ld [hl], a
	ldtx hl, YouPlaySecondText
	ldtx de, IfHeadsDuelistPlaysFirstText
	call TossCoin
	jr c, .play_second ; jump if heads
	rst SwapTurn
	ldtx hl, YouPlayFirstText
.play_second
	call DrawWideTextBox_WaitForInput
	call ExchangeRNG
	or a
	ret


; places the Prize cards on both sides of the play area (Player's and opponent's)
.PlacePrizes
	ld hl, .PrizeCardCoordinates
	ld e, DECK_SIZE - 7 - 1 ; deck size - cards drawn - 1
	ld a, [wDuelInitialPrizes]
	ld d, a

.place_prize
	; wait up to 20 frames before placing each Prize card
	ld a, 20 ; frames to delay
	call WaitAFrames_AllowSkipDelay

	call .DrawPrizeTile
	call .DrawPrizeTile

	ld a, SFX_PLACE_PRIZE
	call PlaySFX
	; print new deck card number
	lb bc, 3, 5
	ld a, e
	call WriteTwoDigitNumberInTxSymbolFormat_TrimLeadingZero
	lb bc, 18, 7
	ld a, e
	call WriteTwoDigitNumberInTxSymbolFormat_TrimLeadingZero
	dec e ; decrease number of cards in deck
	dec d ; decrease number of prize cards left
	jr nz, .place_prize
	ret

.DrawPrizeTile
	ld b, [hl]
	inc hl
	ld c, [hl]
	inc hl
	ld a, $ac ; prize card tile
	jp WriteByteToBGMap0

.PrizeCardCoordinates
; player x, player y, opp x, opp y
	db 5, 6, 14, 5 ; Prize 1
	db 6, 6, 13, 5 ; Prize 2
	db 5, 7, 14, 4 ; Prize 3
	db 6, 7, 13, 4 ; Prize 4
	db 5, 8, 14, 3 ; Prize 5
	db 6, 8, 13, 3 ; Prize 6


; handles the turn holder putting Basic Pokemon into play at the start of the duel.
; also transmits the turn holder's duelvars to the other duelist in a link duel.
; called twice, once for each duelist.
ChooseInitialArenaAndBenchPokemon:
	ld a, DUELVARS_DUELIST_TYPE
	get_turn_duelist_var
	cp DUELIST_TYPE_PLAYER
	jr z, .choose_arena
	cp DUELIST_TYPE_LINK_OPP
	jr z, .exchange_duelvars

; AI opponent's turn
	push af
	push hl
	call AIDoAction_StartDuel
	pop hl
	pop af
	ld [hl], a
	or a
	ret

; link opponent's turn
.exchange_duelvars
	ldtx hl, TransmittingDataText
	call DrawWideTextBox_PrintText
	call ExchangeRNG
	ld hl, wPlayerDuelVariables
	ld de, wOpponentDuelVariables
	ld c, (wOpponentDuelVariables - wPlayerDuelVariables) / 2
	call SerialExchangeBytes
	jp c, DuelTransmissionError
	ld c, (wOpponentDuelVariables - wPlayerDuelVariables) / 2
	call SerialExchangeBytes
	jp c, DuelTransmissionError
	ld a, DUELVARS_DUELIST_TYPE
	get_turn_duelist_var
	ld [hl], DUELIST_TYPE_LINK_OPP
	or a
	ret

; player's turn (either AI or link duel)
; prompt (force) the player to choose a Basic Pokemon card to place in the Arena
.choose_arena
	call EmptyScreen
	ld a, BOXMSG_ARENA_POKEMON
	call DrawDuelBoxMessage
	ldtx hl, ChooseBasicPkmnToPlaceInArenaText
	call DrawWideTextBox_WaitForInput
	ld a, PRACTICEDUEL_DRAW_SEVEN_CARDS
	call DoPracticeDuelAction
.choose_arena_loop
	xor a
	ldtx hl, PleaseChooseAnActivePokemonText
	call DisplayPlaceInitialPokemonCardsScreen
	jr c, .choose_arena_loop
	ld a, PRACTICEDUEL_PLAY_GOLDEEN
	call DoPracticeDuelAction
	jr c, .choose_arena_loop
	ldh a, [hTempCardIndex_ff98]
	call PutHandPokemonCardInPlayArea
	ldh a, [hTempCardIndex_ff98]
	ldtx hl, PlacedInTheArenaText
	call DisplayCardDetailScreen

; after choosing the Active Pokemon, let the player put 0 or more Basic Pokemon
; cards onto their Bench. loop until the player decides to stop placing Pokemon.
	call EmptyScreen
	ld a, BOXMSG_BENCH_POKEMON
	call DrawDuelBoxMessage
	ldtx hl, ChooseUpTo5BasicPkmnToPlaceOnBenchText
	call PrintScrollableText_NoTextBoxLabel
	ld a, PRACTICEDUEL_PUT_STARYU_IN_BENCH
	call DoPracticeDuelAction
.bench_loop
	ld a, TRUE
	ldtx hl, ChooseYourBenchPokemonText
	call DisplayPlaceInitialPokemonCardsScreen
	jr c, .bench_done
	ld a, DUELVARS_NUMBER_OF_POKEMON_IN_PLAY_AREA
	get_turn_duelist_var
	cp MAX_PLAY_AREA_POKEMON
	jr nc, .no_space
	ldh a, [hTempCardIndex_ff98]
	call PutHandPokemonCardInPlayArea
	ldh a, [hTempCardIndex_ff98]
	ldtx hl, PlacedOnTheBenchText
	call DisplayCardDetailScreen
	ld a, PRACTICEDUEL_DONE_PUTTING_ON_BENCH
	call DoPracticeDuelAction
	jr .bench_loop

.no_space
	ldtx hl, NoSpaceOnTheBenchText
	call DrawWideTextBox_WaitForInput
	jr .bench_loop

.bench_done
	ld a, PRACTICEDUEL_VERIFY_INITIAL_PLAY
	call DoPracticeDuelAction
	jr c, .bench_loop
	ret


; the turn holder shuffles the deck unless it's a practice duel, then draws 7 cards
; preserves de
; output:
;	a = $01:  if 1 or more Basic Pokemon were drawn
;	a = $00:  if no Basic Pokemon were drawn
;	carry = set:  if no Basic Pokemon were drawn
ShuffleDeckAndDrawSevenCards:
	ld a, [wDuelType]
	cp DUELTYPE_PRACTICE
	jr z, .deck_ready
	call ShuffleDeck
	call ShuffleDeck
.deck_ready
	ld b, 7
.draw_loop
	call DrawCardFromDeck
	call AddCardToHand
	dec b
	jr nz, .draw_loop
	ld a, DUELVARS_HAND
	get_turn_duelist_var
	ld b, 7
.cards_loop
	ld a, [hli]
	call CheckDeckIndexForBasicPokemon
	jr c, .found_basic_pkmn
	dec b
	jr nz, .cards_loop
; no Basic Pokémon
	xor a
	scf
	ret
.found_basic_pkmn
	ld a, $01
	or a
	ret


DisplayNoBasicPokemonInHandScreenAndText:
	ldtx hl, ThereAreNoBasicPokemonInHand
	call DrawWideTextBox_WaitForInput
	call DisplayNoBasicPokemonInHandScreen
;	fallthrough

; prints ReturnCardsToDeckAndDrawAgainText in a textbox and calls ExchangeRNG
PrintReturnCardsToDeckDrawAgain:
	ldtx hl, ReturnCardsToDeckAndDrawAgainText
	call DrawWideTextBox_WaitForInput
	jp ExchangeRNG


; displays a bare list of seven hand cards for the turn holder,
; with the duelist's name printed at the top.
; used to let the player know that there are no Basic Pokemon in their opening hand
DisplayNoBasicPokemonInHandScreen:
	call EmptyScreen
	call LoadDuelCardSymbolTiles
	lb de, 0, 0
	lb bc, 20, 18
	call DrawRegularTextBox
	call CreateHandCardList
	ld hl, NoBasicPokemonCardListParameters
	lb de, 0, 0
	call PrintCardListItems
	ldtx hl, DuelistHandText
	lb de, 1, 1
	call InitTextPrinting_PrintTextNoDelay
	call EnableLCD
	jp WaitForWideTextBoxInput

NoBasicPokemonCardListParameters:
	db 1, 3 ; cursor x, cursor y
	db 4 ; item x
	db 14 ; maximum length, in tiles, occupied by the name and level string of each card in the list
	db 7 ; number of items selectable without scrolling
	db SYM_CURSOR_R ; cursor tile number
	db SYM_SPACE ; tile behind cursor
	dw NULL ; function pointer if non-0


; used only during the practice duel with Sam.
; displays the list with the player's cards in hand, and the player's name above the list.
DisplayPracticeDuelPlayerHandScreen:
	call CreateHandCardList
	call EmptyScreen
	call LoadDuelCardSymbolTiles
	lb de, 0, 0
	lb bc, 20, 13
	call DrawRegularTextBox
	call CountCardsInDuelTempList ; list length
	ld hl, CardListParameters ; other list params
	lb de, 0, 0 ; initial page scroll offset, initial item (in the visible page)
	call PrintCardListItems
	ldtx hl, DuelistHandText
	lb de, 1, 1
	call InitTextPrinting_PrintTextNoDelay
	jp EnableLCD


PlayShuffleAndDrawCardsAnimation_TurnDuelist:
	lb bc, DUEL_ANIM_PLAYER_SHUFFLE, DUEL_ANIM_PLAYER_DRAW
	ldh a, [hWhoseTurn]
	cp PLAYER_TURN
	jr z, .play_anim
	lb bc, DUEL_ANIM_OPP_SHUFFLE, DUEL_ANIM_OPP_DRAW
.play_anim
	ldtx hl, ShufflesTheDeckText
	ldtx de, Drew7CardsText
	jr PlayShuffleAndDrawCardsAnimation


PlayShuffleAndDrawCardsAnimation_BothDuelists:
	lb bc, DUEL_ANIM_BOTH_SHUFFLE, DUEL_ANIM_BOTH_DRAW
	ldtx hl, EachPlayerShuffleOpponentsDeckText
	ldtx de, EachPlayerDraw7CardsText
	ld a, [wDuelType]
	cp DUELTYPE_PRACTICE
	jr nz, PlayShuffleAndDrawCardsAnimation
	ldtx hl, ThisIsJustPracticeDoNotShuffleText
;	fallthrough

; animates the shuffle and drawing screen
; preserves bc
; input:
;	b = shuffling animation index (DUEL_ANIM_* constant)
;	c = drawing animation index (DUEL_ANIM_* constant)
;	hl = text ID for the text to print while shuffling
;	de = text ID for the text to print while drawing
PlayShuffleAndDrawCardsAnimation:
	push bc
	push de
	push hl
	call ZeroObjectPositionsAndToggleOAMCopy
	call EmptyScreen
	call DrawDuelistPortraitsAndNames
	call LoadDuelDrawCardsScreenTiles
	ld a, SHUFFLE_DECK
	ld [wDuelDisplayedScreen], a
	pop hl
	call DrawWideTextBox_PrintText
	call EnableLCD
	ld a, [wDuelType]
	cp DUELTYPE_PRACTICE
	jr nz, .not_practice
	call WaitForWideTextBoxInput
	jr .print_deck_info

.not_practice
; get the shuffling animation from input value of b
	call ResetAnimationQueue
	ld hl, sp+$03
	; play animation 3 times
	ld a, [hl]
	call PlayDuelAnimation
	ld a, [hl]
	call PlayDuelAnimation
	ld a, [hl]
	call PlayDuelAnimation
	call WaitForAnimationToFinish_AllowSkipDelay
	call FinishQueuedAnimations

.print_deck_info
	xor a
	ld [wNumCardsBeingDrawn], a
	call PrintDeckAndHandIconsAndNumberOfCards
	call ResetAnimationQueue
	pop hl
	call DrawWideTextBox_PrintText
.draw_card
; get the draw animation from input value of c
	ld hl, sp+$00
	ld a, [hl]
	call PlayDuelAnimation
	call WaitForAnimationToFinish_AllowSkipDelay
	jr c, .done ; skip ahead if delay was skipped
	ld hl, wNumCardsBeingDrawn
	inc [hl]
	ld hl, sp+$00
	ld a, [hl]
	cp DUEL_ANIM_BOTH_DRAW
	jr nz, .one_duelist_shuffled
	; if both duelists shuffled
	call PrintDeckAndHandIconsAndNumberOfCards.not_cgb
	jr .check_num_cards
.one_duelist_shuffled
	call PrintNumberOfHandAndDeckCards
.check_num_cards
	ld a, [wNumCardsBeingDrawn]
	cp 7
	jr c, .draw_card
	; wait up to 10 frames before finishing
	ld a, 10 ; frames to delay
	call WaitAFrames_AllowSkipDelay
.done
	call FinishQueuedAnimations
	pop bc
	ret


PlayDeckShuffleAnimation:
	ld a, [wDuelDisplayedScreen]
	cp SHUFFLE_DECK
	jr z, .skip_draw_scene
	call ZeroObjectPositionsAndToggleOAMCopy
	call EmptyScreen
	call DrawDuelistPortraitsAndNames
.skip_draw_scene
	ld a, SHUFFLE_DECK
	ld [wDuelDisplayedScreen], a

; if there's only one card in the deck, skip the shuffling animation
	ld a, DUELVARS_NUMBER_OF_CARDS_NOT_IN_DECK
	get_turn_duelist_var
	ld a, DECK_SIZE
	sub [hl]
	cp 2
	jr c, .one_card_in_deck

	ldtx hl, ShufflesTheDeckText
	call DrawWideTextBox_PrintText
	call EnableLCD
	call ResetAnimationQueue

; load correct animation depending on whose turn it is
	ld e, DUEL_ANIM_PLAYER_SHUFFLE
	ldh a, [hWhoseTurn]
	cp PLAYER_TURN
	jr z, .load_anim
	ld e, DUEL_ANIM_OPP_SHUFFLE
.load_anim
; play animation 3 times
	ld a, e
	call PlayDuelAnimation
	ld a, e
	call PlayDuelAnimation
	ld a, e
	call PlayDuelAnimation
	call WaitForAnimationToFinish_AllowSkipDelay
	call FinishQueuedAnimations
	ld a, $01
	ret

.one_card_in_deck
; no animation, just print text and delay
	ld hl, wTxRam3
	ld [hli], a
	xor a
	ld [hl], a
	ldtx hl, DeckHasXCardsText
	call DrawWideTextBox_PrintText
	call EnableLCD
	ld a, 60 ; frames to delay
	call WaitAFrames_AllowSkipDelay
	ld a, $01
	ret


; draws the main scene during a duel, except the contents of the bottom text box,
; which depend on the type of duelist holding the turn.
; includes the background, both Active Pokemon, and both HUDs.
DrawDuelMainScene::
	ld a, DUELVARS_DUELIST_TYPE
	get_turn_duelist_var
	cp DUELIST_TYPE_PLAYER
	jr z, .draw
	ldh a, [hWhoseTurn]
	push af
	ld a, PLAYER_TURN
	ldh [hWhoseTurn], a
	call .draw
	pop af
	ldh [hWhoseTurn], a
	ret
.draw
; first, load the graphics and draw the background scene
	ld a, [wDuelDisplayedScreen]
	cp DUEL_MAIN_SCENE
	ret z
	call ZeroObjectPositionsAndToggleOAMCopy
	call EmptyScreen
	call LoadSymbolsFont
	lb de, $38, $9f
	call SetupText
	ld a, DUEL_MAIN_SCENE
	ld [wDuelDisplayedScreen], a
	ld a, DUELVARS_ARENA_CARD
	get_turn_duelist_var
	ld de, v0Tiles1 + $50 tiles
	call LoadPlayAreaCardGfx
	call SetBGP7OrSGB2ToCardPalette
	rst SwapTurn
	ld a, DUELVARS_ARENA_CARD
	get_turn_duelist_var
	ld de, v0Tiles1 + $20 tiles
	call LoadPlayAreaCardGfx
	call SetBGP6OrSGB3ToCardPalette
	call FlushAllPalettesOrSendPal23Packet
	rst SwapTurn
; next, draw the Pokemon in the Arena
;.place_player_arena_pkmn
	ld a, DUELVARS_ARENA_CARD
	get_turn_duelist_var
	inc a ; cp -1 (empty play area slot?)
	jr z, .place_opponent_arena_pkmn
	ld a, $d0 ; v0Tiles1 + $50 tiles
	lb hl, 6, 1
	lb de, 0, 5
	lb bc, 8, 6
	call FillRectangle
	call ApplyBGP7OrSGB2ToCardImage
.place_opponent_arena_pkmn
	ld a, DUELVARS_ARENA_CARD
	call GetNonTurnDuelistVariable
	inc a ; cp -1 (empty play area slot?)
	jr z, .place_other_elements
	ld a, $a0 ; v0Tiles1 + $20 tiles
	lb hl, 6, 1
	lb de, 12, 1
	lb bc, 8, 6
	call FillRectangle
	call ApplyBGP6OrSGB3ToCardImage
.place_other_elements
	ld hl, DuelEAndHPSymbolsTextData
	call PlaceTextItems
	call DrawDuelHorizontalSeparator
	call DrawDuelHUDs
	call DrawWideTextBox
	jp EnableLCD


; draws the main elements of the main duel interface, including HUDs, HPs, card names
; and color symbols, attached cards, and other information, for both duelists.
DrawDuelHUDs::
	ld a, DUELVARS_DUELIST_TYPE
	get_turn_duelist_var
	cp DUELIST_TYPE_PLAYER
	jr z, .draw_hud
	ldh a, [hWhoseTurn]
	push af
	ld a, PLAYER_TURN
	ldh [hWhoseTurn], a
	call .draw_hud
	pop af
	ldh [hWhoseTurn], a
	ret
.draw_hud
	lb de, 1, 11 ; coordinates for printing the Player's Active Pokemon's name and info icons
	lb bc, 11, 8 ; coordinates for drawing the Player's attached Energy symbols and HP display
	call DrawDuelHUD
	lb bc, 8, 5
	ld a, DUELVARS_ARENA_CARD_STATUS
	get_turn_duelist_var
	call CheckPrintCnfSlpPrz
	inc c
	call CheckPrintPoisoned
	inc c
	call CheckPrintDoublePoisoned ; if double poisoned, print a second poison icon
	rst SwapTurn
	lb de, 7, 0 ; coordinates for printing the opponent's Active Pokemon's name and info icons
	lb bc, 3, 1 ; coordinates for drawing the opponent's attached Energy symbols and HP display
	call DrawDuelHUD
	lb bc, 11, 6
	ld a, DUELVARS_ARENA_CARD_STATUS
	get_turn_duelist_var
	call CheckPrintCnfSlpPrz
	dec c
	call CheckPrintPoisoned
	dec c
	call CheckPrintDoublePoisoned ; if double poisoned, print a second poison icon
	jp SwapTurn


DrawDuelHUD:
	ld hl, wHUDEnergyAndHPBarsX
	ld [hl], b
	inc hl
	ld [hl], c ; wHUDEnergyAndHPBarsY
	push de ; push coordinates for the Active Pokemon's name
	ld d, 1 ; opponent's info icons start in the second tile to the right
	ld a, e
	or a
	jr z, .go
	ld d, 15 ; player's info icons start in the 15th tile to the right
.go
	ld b, d
	ld c, e

	; print the Pokemon icon along with the number of Pokemon in this play area
	ld a, SYM_POKEMON
	call WriteByteToBGMap0
	inc b
	ld a, DUELVARS_NUMBER_OF_POKEMON_IN_PLAY_AREA
	get_turn_duelist_var
	add SYM_0 - 1
	call WriteByteToBGMap0
	inc b

	; print the Prize icon along with the number of remaining Prizes in this play area
	ld a, SYM_PRIZE
	call WriteByteToBGMap0
	inc b
	call CountPrizes
	add SYM_0
	call WriteByteToBGMap0

	; print the Active Pokemon's card name and level text
	pop de
	ld a, DUELVARS_ARENA_CARD
	get_turn_duelist_var
	cp -1
	ret z ; return if there's no Active Pokémon
	call LoadCardDataToBuffer1_FromDeckIndex
	ld a, 32
	call CopyCardNameAndLevel
	ld [hl], TX_END

	; print the Active Pokemon's type/color symbol just before the name
	ld a, e
	or a
	jr nz, .print_color_icon
	ld hl, wDefaultText
	call GetTextLengthInTiles
	add SCREEN_WIDTH
	ld d, a
.print_color_icon
	ld hl, wDefaultText
	call InitTextPrinting_ProcessText
	ld b, d
	ld c, e
	call GetArenaCardColor
	inc a ; TX_SYMBOL color tiles start at 1
	dec b ; place the symbol one tile to the left of the start of the card's name
	call WriteByteToBGMap0

	; print symbols for each attached Energy card
	ld hl, wHUDEnergyAndHPBarsX
	ld b, [hl]
	inc hl
	ld c, [hl] ; wHUDEnergyAndHPBarsY
	push bc
	ld e, PLAY_AREA_ARENA
	ld a, 8 ; maximum number of symbols to print
	call PrintPlayAreaCardAttachedEnergies
	pop bc
	inc c ; [wHUDEnergyAndHPBarsY] + 1
	; print HP as #/# (current HP/max HP)
	ld a, PLAY_AREA_ARENA
	call PrintCurrentAndMaxHP

; print number of attached Pluspower and Defender with respective icon, if any
; check pluspower
	ld a, [wHUDEnergyAndHPBarsX]
	ld b, a
	inc c ; [wHUDEnergyAndHPBarsY] + 2
	ld a, DUELVARS_ARENA_CARD_ATTACHED_PLUSPOWER
	get_turn_duelist_var
	or a
	jr z, .check_defender
	ld a, SYM_PLUSPOWER
	call WriteByteToBGMap0
	inc b
	ld a, [hl] ; number of attached Pluspower
	add SYM_0
	call WriteByteToBGMap0
	inc b
	inc b
	inc b
.check_defender
	ld a, DUELVARS_ARENA_CARD_ATTACHED_DEFENDER
	get_turn_duelist_var
	or a
	ret z
	ld a, SYM_DEFENDER
	call WriteByteToBGMap0
	inc b
	ld a, [hl] ; number of attached Defender
	add SYM_0
	jp WriteByteToBGMap0


DuelEAndHPSymbolsTextData:
	textitem 1, 1, ESymbolText
	textitem 1, 2, HPSymbolText
	textitem 9, 8, ESymbolText
	textitem 9, 9, HPSymbolText
	db $ff


; if this is a practice duel, execute the practice duel action at wPracticeDuelAction
; if not a practice duel, immediately return nc
; the practice duel functions below return carry when something's wrong
DoPracticeDuelAction:
	ld [wPracticeDuelAction], a
	ld a, [wIsPracticeDuel]
	or a
	ret z
	ld a, [wPracticeDuelAction]
	ld hl, PracticeDuelActionTable
	jp JumpToFunctionInTable

PracticeDuelActionTable:
	dw NULL
	dw PracticeDuel_DrawSevenCards           ; PRACTICEDUEL_DRAW_SEVEN_CARDS
	dw PracticeDuel_PlayGoldeen              ; PRACTICEDUEL_PLAY_GOLDEEN
	dw PracticeDuel_PutStaryuInBench         ; PRACTICEDUEL_PUT_STARYU_IN_BENCH
	dw PracticeDuel_VerifyInitialPlay        ; PRACTICEDUEL_VERIFY_INITIAL_PLAY
	dw PracticeDuel_DonePuttingOnBench       ; PRACTICEDUEL_DONE_PUTTING_ON_BENCH
	dw PracticeDuel_PrintTurnInstructions    ; PRACTICEDUEL_PRINT_TURN_INSTRUCTIONS
	dw PracticeDuel_VerifyPlayerTurnActions  ; PRACTICEDUEL_VERIFY_PLAYER_TURN_ACTIONS
	dw PracticeDuel_RepeatInstructions       ; PRACTICEDUEL_REPEAT_INSTRUCTIONS
	dw PracticeDuel_PlayStaryuFromBench      ; PRACTICEDUEL_PLAY_STARYU_FROM_BENCH
	dw PracticeDuel_ReplaceKnockedOutPokemon ; PRACTICEDUEL_REPLACE_KNOCKED_OUT_POKEMON


PracticeDuel_DrawSevenCards:
	call DisplayPracticeDuelPlayerHandScreen
	call EnableLCD
	ldtx hl, DrawSevenCardsPracticeDuelText
	jr PrintPracticeDuelDrMasonInstructions


; input:
;	[wLoadedCard2] = all of the data of the Pokémon being played (card_data_struct)
; output:
;	carry = set:  if the Player didn't choose Goldeen as their starting Pokemon
PracticeDuel_PlayGoldeen:
	ld a, [wLoadedCard2ID]
	cp GOLDEEN
	ret z
	ldtx hl, ChooseGoldeenPracticeDuelText
	scf
	jr PrintPracticeDuelDrMasonInstructions


PracticeDuel_PutStaryuInBench:
	call DisplayPracticeDuelPlayerHandScreen
	call EnableLCD
	ldtx hl, PutPokemonOnBenchPracticeDuelText
	jr PrintPracticeDuelDrMasonInstructions


; output:
;	carry = set:  if the Player didn't put Staryu on the Bench
PracticeDuel_VerifyInitialPlay:
	ld a, DUELVARS_NUMBER_OF_POKEMON_IN_PLAY_AREA
	get_turn_duelist_var
	cp 2
	ret z
	ldtx hl, ChooseStaryuPracticeDuelText
	scf
	jr PrintPracticeDuelDrMasonInstructions


PracticeDuel_DonePuttingOnBench:
	call DisplayPracticeDuelPlayerHandScreen
	call EnableLCD
	ld a, $ff
	ld [wPracticeDuelTurn], a
	ldtx hl, PressBToFinishPracticeDuelText
;	fallthrough

; prints a text box with instructions, labeled as 'Dr. Mason'
; preserves af
; input:
;	hl = text ID for the instructions
PrintPracticeDuelDrMasonInstructions:
	push af
	ldtx de, DrMasonText
	call PrintScrollableText_WithTextBoxLabel
	pop af
	ret


PracticeDuel_PrintTurnInstructions:
	call DrawPracticeDuelInstructionsTextBox
	call EnableLCD
	ld a, [wDuelTurns]
	ld hl, wPracticeDuelTurn
	cp [hl]
	ld [hl], a
	; calling PrintPracticeDuelInstructionsForCurrentTurn with a = 0 means that Dr. Mason's
	; instructions are also printed along with each of the point-by-point instructions
	ld a, 0
	jp nz, PrintPracticeDuelInstructionsForCurrentTurn
	; if we're here, the Player didn't follow the instructions, so they have to be repeated.
	; ask the player whether to show detailed instructions again, in order to
	; call PrintPracticeDuelInstructionsForCurrentTurn with either a = 0 or a = 1.
	ldtx de, DrMasonText
	ldtx hl, NeedPracticeAgainPracticeDuelText
	call PrintScrollableText_WithTextBoxLabel_NoWait
	call YesOrNoMenu
	jp PrintPracticeDuelInstructionsForCurrentTurn


; output:
;	carry = set:  if the Player didn't follow all of the instructions for the current turn
PracticeDuel_VerifyPlayerTurnActions:
	ld a, [wDuelTurns]
	srl a
	ld hl, PracticeDuelTurnVerificationPointerTable
	call JumpToFunctionInTable
	; return nc if the Player correctly followed all of the instructions
	ret nc
;	fallthrough

; output:
;	carry = set
PracticeDuel_RepeatInstructions:
	ldtx hl, FollowMyGuidancePracticeDuelText
	call PrintPracticeDuelDrMasonInstructions
	; restart the turn from the saved data of the previous turn
	ld a, $02
	call BankswitchSRAM
	ld de, sCurrentDuel
	call LoadSavedDuelData
	xor a
	call BankswitchSRAM
	; return carry in order to repeat instructions
	scf
	ret


PracticeDuel_PlayStaryuFromBench:
	ld a, [wDuelTurns]
	cp 7
	jr z, .its_sam_turn_4
	or a
	ret
.its_sam_turn_4
	; instruct the Player to replace the Knocked Out Seaking with the Benched Staryu
	call DrawPracticeDuelInstructionsTextBox
	call EnableLCD
	ld hl, PracticeDuelText_SamTurn4
	jp PrintPracticeDuelInstructions


; output:
;	carry = set:  if the Player selected the wrong Pokemon
PracticeDuel_ReplaceKnockedOutPokemon:
	ldh a, [hTempPlayAreaLocation_ff9d]
	cp PLAY_AREA_BENCH_1
	ret z
	; if player selected Drowzee instead (which is at PLAY_AREA_BENCH_2)
	call InitPlayAreaScreenVars_OnlyBench
	ldtx hl, SelectStaryuPracticeDuelText
	scf
	jr PrintPracticeDuelDrMasonInstructions


INCLUDE "data/duel/practice_text.asm"


; in a practice duel, draws the text box where the point-by-point
; instructions for the next player action will be written into
DrawPracticeDuelInstructionsTextBox:
	call EmptyScreen
	lb de, 0, 0
	lb bc, 20, 12
	call DrawRegularTextBox
;	fallthrough

; prints "<Player>'s Turn [wDuelTurns]" (usually) as the textbox label
PrintPracticeDuelInstructionsTextBoxLabel:
	ld a, [wDuelTurns]
	cp 7
	jr z, .replace_due_to_knockout
	; load the player's turn number to TX_RAM3 in order to print it
	srl a
	inc a
	ld hl, wTxRam3
	ld [hli], a
	xor a
	ld [hl], a
	lb de, 1, 0
	call InitTextPrinting
	ldtx hl, PlayersTurnPracticeDuelText
	jp PrintText
.replace_due_to_knockout
	; when the player needs to replace a Knocked Out Pokemon, the label text is different
	; this happens at the end of Sam's fourth turn
	lb de, 1, 0
	ldtx hl, ReplaceDueToKnockoutPracticeDuelText
	jp InitTextPrinting_ProcessTextFromID


; prints the instructions for the current turn of the practice duel,
; taken from one of the structs in PracticeDuelTextPointerTable.
; input:
;	a != 0:  only the point-by-point instructions are printed
;	a == 0:  Dr. Mason instructions are also shown in a textbox at the bottom of the screen
PrintPracticeDuelInstructionsForCurrentTurn:
	push af
	ld a, [wDuelTurns]
	and %11111110
	ld e, a
	ld d, $00
	ld hl, PracticeDuelTextPointerTable
	add hl, de
	ld a, [hli]
	ld h, [hl]
	ld l, a
	pop af
	or a
	jr nz, PrintPracticeDuelInstructions_Fast
;	fallthrough

; prints practice duel instructions given hl = PracticeDuelText_*
; each practicetext entry (see above) contains a Dr. Mason text along with
; a numbered instruction text, that is later printed without text delay.
; input:
;	hl = entry from PracticeDuelTextPointerTable (PracticeDuelText_*)
PrintPracticeDuelInstructions:
	xor a
	ld [wPracticeDuelTextY], a
	ld a, l
	ld [wPracticeDuelTextPointer], a
	ld a, h
	ld [wPracticeDuelTextPointer + 1], a
.print_instructions_loop
	call PrintNextPracticeDuelInstruction
	ld a, [hli]
	ld [wPracticeDuelTextY], a
	or a
	jr z, PrintPracticeDuelLetsPlayTheGame
	ld e, [hl]
	inc hl
	ld d, [hl]
	inc hl
	push hl
	ld l, e
	ld h, d
	ldtx de, DrMasonText
	call PrintScrollableText_WithTextBoxLabel
	pop hl
	ld e, [hl]
	inc hl
	ld d, [hl]
	inc hl
	push hl
	ld a, SINGLE_SPACED
	ld [wLineSeparation], a
	ld l, e
	ld h, d
	ld a, [wPracticeDuelTextY]
	ld e, a
	ld d, 1
	call InitTextPrinting_ProcessTextFromID
	xor a ; DOUBLE_SPACED
	ld [wLineSeparation], a
	pop hl
	jr .print_instructions_loop


; prints the generic Dr. Mason's text that completes all his practice duel instructions
PrintPracticeDuelLetsPlayTheGame:
	ldtx hl, LetsPlayTheGamePracticeDuelText
	jp PrintPracticeDuelDrMasonInstructions


; simplified version of PrintPracticeDuelInstructions that skips Dr. Mason's text
; and instead places the point-by-point instructions all at once.
; input:
;	hl = entry from PracticeDuelTextPointerTable (PracticeDuelText_*)
PrintPracticeDuelInstructions_Fast:
	ld a, [hli]
	or a
	jr z, PrintPracticeDuelLetsPlayTheGame
	ld e, a ; y
	ld d, 1 ; x
	call PrintPracticeDuelNumberedInstruction
	jr PrintPracticeDuelInstructions_Fast


; prints a practice duel point-by-point instruction at d,e, with text ID at hl,
; that has been read from an entry of PracticeDuelText_*
; preserves de
; input:
;	de = screen coordinates at which to begin printing the text
;	hl = entry from PracticeDuelTextPointerTable (PracticeDuelText_*)
PrintPracticeDuelNumberedInstruction:
	inc hl
	inc hl
	ld c, [hl]
	inc hl
	ld b, [hl]
	inc hl
	push hl
	ld l, c
	ld h, b
	ld a, SINGLE_SPACED
	ld [wLineSeparation], a
	call InitTextPrinting_ProcessTextFromID
	xor a ; DOUBLE_SPACED
	ld [wLineSeparation], a
	pop hl
	ret


; prints a single instruction bullet for the current turn.
; preserves hl
PrintNextPracticeDuelInstruction:
	ld a, $01
	ldh [hffb0], a
	push hl
	call PrintPracticeDuelInstructionsTextBoxLabel
	ld hl, wPracticeDuelTextPointer
	ld a, [hli]
	ld h, [hl]
	ld l, a
.next
	ld a, [wPracticeDuelTextY]
	cp [hl]
	jr c, .done
	ld a, [hli]
	or a
	jr z, .done
	ld e, a ; y
	ld d, 1 ; x
	call PrintPracticeDuelNumberedInstruction
	jr .next
.done
	pop hl
	xor a
	ldh [hffb0], a
	ret


PracticeDuelTurnVerificationPointerTable:
	dw PracticeDuelVerify_Turn1
	dw PracticeDuelVerify_Turn2
	dw PracticeDuelVerify_Turn3
	dw PracticeDuelVerify_Turn4
	dw PracticeDuelVerify_Turn5
	dw PracticeDuelVerify_Turn6
	dw PracticeDuelVerify_Turn7Or8
	dw PracticeDuelVerify_Turn7Or8


; output:
;	carry = set:  if the Player didn't follow all of the instructions for turn 1
PracticeDuelVerify_Turn1:
	ld a, [wTempCardID_ccc2]
	cp GOLDEEN
	jr nz, ReturnWrongAction
	ret


; output:
;	carry = set:  if the Player didn't follow all of the instructions for turn 2
PracticeDuelVerify_Turn2:
	ld a, [wTempCardID_ccc2]
	cp SEAKING
	jr nz, ReturnWrongAction
	ld a, [wSelectedAttack]
	cp SECOND_ATTACK
	jr nz, ReturnWrongAction
	ld e, PLAY_AREA_ARENA
	call GetPlayAreaCardAttachedEnergies
	ld a, [wAttachedEnergies + PSYCHIC]
	or a
	jr z, ReturnWrongAction
	ret


; output:
;	carry = set:  if the Player didn't follow all of the instructions for turn 3
PracticeDuelVerify_Turn3:
	ld a, [wTempCardID_ccc2]
	cp SEAKING
	jr nz, ReturnWrongAction
	ld e, PLAY_AREA_BENCH_1
	call GetPlayAreaCardAttachedEnergies
	ld a, [wAttachedEnergies + WATER]
	or a
	jr z, ReturnWrongAction
	ret


; output:
;	carry = set:  if the Player didn't follow all of the instructions for turn 4
PracticeDuelVerify_Turn4:
	ld a, [wPlayerNumberOfPokemonInPlayArea]
	cp 3
	jr nz, ReturnWrongAction
	ld e, PLAY_AREA_BENCH_2
	call GetPlayAreaCardAttachedEnergies
	ld a, [wAttachedEnergies + WATER]
	or a
	jr z, ReturnWrongAction
	ld a, [wTempCardID_ccc2]
	cp SEAKING
	jr nz, ReturnWrongAction
	ld a, [wSelectedAttack]
	cp SECOND_ATTACK
	ret z
;	fallthrough

ReturnWrongAction:
	scf
	ret


; output:
;	carry = set:  if the Player didn't follow all of the instructions for turn 5
PracticeDuelVerify_Turn5:
	ld e, PLAY_AREA_ARENA
	call GetPlayAreaCardAttachedEnergies
	ld a, [wAttachedEnergies + WATER]
	cp 2
	jr nz, ReturnWrongAction
	ld a, [wTempCardID_ccc2]
	cp STARYU
	jr nz, ReturnWrongAction
	ret


; output:
;	carry = set:  if the Player didn't follow all of the instructions for turn 6
PracticeDuelVerify_Turn6:
	ld e, PLAY_AREA_ARENA
	call GetPlayAreaCardAttachedEnergies
	ld a, [wAttachedEnergies + WATER]
	cp 3
	jr nz, ReturnWrongAction
	ld a, [wPlayerArenaCardHP]
	cp 40
	jr nz, ReturnWrongAction
	ld a, [wTempCardID_ccc2]
	cp STARYU
	jr nz, ReturnWrongAction
	ret

; output:
;	carry = set:  if the Player didn't follow all of the instructions for turn 7/8
PracticeDuelVerify_Turn7Or8:
	ld a, [wTempCardID_ccc2]
	cp STARMIE
	jr nz, ReturnWrongAction
	ld a, [wSelectedAttack]
	cp SECOND_ATTACK
	jr nz, ReturnWrongAction
	ret


; displays BOXMSG_PLAYERS_TURN or BOXMSG_OPPONENTS_TURN and
; prints DuelistTurnText in a textbox. also calls ExchangeRNG.
DisplayDuelistTurnScreen:
	call EmptyScreen
	ld c, BOXMSG_PLAYERS_TURN
	ldh a, [hWhoseTurn]
	cp PLAYER_TURN
	jr z, .got_turn
	inc c ; BOXMSG_OPPONENTS_TURN
.got_turn
	ld a, c
	call DrawDuelBoxMessage
	ldtx hl, DuelistTurnText
	call DrawWideTextBox_WaitForInput
	jp ExchangeRNG


; displays the screen that prompts the player to choose a Basic Pokemon card to
; put into play, either in the Arena or on the Bench, at the beginning of the duel.
; input:
;	a = 0:  if the player is being prompted to place an initial Active Pokémon
;	  = 1:  if the player is being prompted to place their initial Benched Pokémon
;	hl = text ID for the instructions
; output:
;	carry = set:  if the B button was pressed to exit the selection process
;	[wLoadedCard2] = all of the card's data (65 bytes):  if a Basic Pokémon was selected
DisplayPlaceInitialPokemonCardsScreen:
	ld [wPlacingInitialBenchPokemon], a
	push hl
	call CreateHandCardList
	call InitAndDrawCardListScreenLayout
	pop hl
	call SetCardListInfoBoxText
	ld a, PLAY_CHECK
	ld [wCardListItemSelectionMenuType], a
.display_card_list
	call DisplayCardList
	jr nc, .card_selected
	; attempted to exit screen
	ld a, [wPlacingInitialBenchPokemon]
	or a
	; player is forced to place a Pokemon card in the Arena
	jr z, .display_card_list
	; in the Bench, however, we can get away without placing anything
	; alternatively, the player doesn't want or can't place more Benched Pokemon
	scf
.done
	; valid Basic Pokemon card selected, or no card selected (Bench only)
	push af
	ld a, [wSortCardListByID]
	or a
	call nz, SortHandCardsByID
	pop af
	ret
.card_selected
	call CheckDeckIndexForBasicPokemon
	ccf
	jr nc, .done
	; invalid card selected, tell the player and go back
	ldtx hl, YouCannotSelectThisCardText
	call DrawWideTextBox_WaitForInput
	call DrawCardListScreenLayout
	jr .display_card_list


; draws the turn holder's discard pile screen
; output:
;	carry = set:  if the there are no cards in the turn holder's discard pile
OpenTurnHolderDiscardPileScreen:
	call CreateDiscardPileCardList
	jr c, .discard_pile_empty
	call InitAndDrawCardListScreenLayout
	call SetDiscardPileScreenTexts
	ld a, PAD_START + PAD_A
	ld [wNoItemSelectionMenuKeys], a
	call DisplayCardList
	or a
	ret
.discard_pile_empty
	ldtx hl, TheDiscardPileHasNoCardsText
	jp DrawWideTextBox_WaitForInput_ReturnCarry


; sets wCardListHeaderText and SetCardListInfoBoxText to the text
; that corresponds to the Discard Pile screen
SetDiscardPileScreenTexts:
	ldtx de, YourDiscardPileText
	ldh a, [hWhoseTurn]
	cp PLAYER_TURN
	jr z, .got_header_text
	ldtx de, OpponentsDiscardPileText
.got_header_text
	ldtx hl, ChooseTheCardYouWishToExamineText
	jp SetCardListHeaderText


; output:
;	carry = set:  if [wDuelTempList] = $ff (i.e. the list is empty)
InitAndDrawCardListScreenLayout_WithSelectCheckMenu:
	call InitAndDrawCardListScreenLayout
	ld a, SELECT_CHECK
	ld [wCardListItemSelectionMenuType], a
	ret


; draws the layout of the screen that displays the player's Hand card list or a
; Discard Pile card list, including a bottom-right image of the current card.
; since this loads the text for the Hand card list screen, SetDiscardPileScreenTexts
; is called after this if the screen corresponds to a Discard Pile list.
; the dimensions of text box where the card list is printed are 20x13, in order to accommodate
; another text box below it (wCardListInfoBoxText) as well as the image of the selected card.
; output:
;	carry = set:  if [wDuelTempList] = $ff (i.e. the list is empty)
InitAndDrawCardListScreenLayout:
	xor a
	ld hl, wSelectedDuelSubMenuItem
	ld [hli], a
	ld [hl], a
	ld [wSortCardListByID], a
	ld hl, wPrintSortNumberInCardListPtr
	ld [hli], a
	ld [hl], a
	ld [wCardListItemSelectionMenuType], a
	ld a, PAD_START
	ld [wNoItemSelectionMenuKeys], a
	ld hl, wCardListInfoBoxText
	ldtx [hl], PleaseSelectHandText, & $ff
	inc hl
	ldtx [hl], PleaseSelectHandText, >> 8
	inc hl ; wCardListHeaderText
	ldtx [hl], DuelistHandText, & $ff
	inc hl
	ldtx [hl], DuelistHandText, >> 8
;	fallthrough

; same as InitAndDrawCardListScreenLayout, except that variables like wSelectedDuelSubMenuItem,
; wNoItemSelectionMenuKeys, wCardListInfoBoxText, wCardListHeaderText, etc already set by caller.
; output:
;	carry = set:  if [wDuelTempList] = $ff (i.e. the list is empty)
DrawCardListScreenLayout:
	call ZeroObjectPositionsAndToggleOAMCopy
	call EmptyScreen
	call LoadSymbolsFont
	call LoadDuelCardSymbolTiles
	; draw the surrounding box
	lb de, 0, 0
	lb bc, 20, 13
	call DrawRegularTextBox
	; draw the image of the selected card
	ld a, $a0
	lb hl, 6, 1
	lb de, 12, 12
	lb bc, 8, 6
	call FillRectangle
	call ApplyBGP6OrSGB3ToCardImage
	ld hl, wPrintSortNumberInCardListPtr
	call CallIndirect
	ld a, [wDuelTempList]
	cp $ff
	scf
	ret z ; return carry if wDuelTempList is empty
	or a
	ret


; displays a list of cards and handles input in order to
; navigate through the list, select a card, open a card page, etc.
; input:
;	[wCardListInfoBoxText] = text ID for the text box (2 bytes)
;	[wCardListHeaderText] = text ID for the header (2 bytes)
;	[wSelectedDuelSubMenuItem] = initial item (is usually 0 to begin with the first card)
;	[wSelectedDuelSubMenuScrollOffset] = initial page scroll offset (is also usually 0)
;	wDuelTempList = $ff-terminated list with deck indices of cards to display
; output:
;	a & [hTempCardIndex_ff98] = selected card
;	carry = set:  if the B button was pressed to exit the card list screen
DisplayCardList:
	call DrawNarrowTextBox
	call PrintCardListHeaderAndInfoBoxTexts
.reload_list
	; get the list length
	call CountCardsInDuelTempList
	; get the position and scroll within the list
	ld hl, wSelectedDuelSubMenuItem
	ld e, [hl] ; initial item (in the visible page)
	inc hl
	ld d, [hl] ; initial page scroll offset
	ld hl, CardListParameters ; other list params
	call PrintCardListItems
	call LoadSelectedCardGfx
	call EnableLCD
.wait_button
	call DoFrame
	ldh a, [hDPadHeld]
	and PAD_CTRL_PAD
	jr z, .d_pad_not_pressed
	ld a, $01
	ldh [hffb0], a
	call PrintCardListHeaderAndInfoBoxTexts
	xor a
	ldh [hffb0], a
.d_pad_not_pressed
	call HandleMenuInput
	jr nc, .wait_button
	; refresh the position of the last checked card of the list, so that
	; the cursor points to said card when the list is reloaded
	ld hl, wSelectedDuelSubMenuScrollOffset
	ld a, [wListScrollOffset]
	ld [hld], a
	ld [hl], e ; hl = wSelectedDuelSubMenuItem, e = wCurMenuItem
	ldh a, [hKeysPressed]
	ld b, a
	bit B_PAD_SELECT, b
	jr nz, .select_pressed
	bit B_PAD_B, b
	jr nz, .b_pressed
	ld a, [wNoItemSelectionMenuKeys]
	and b
	jr nz, .open_card_page
	; display the item selection menu (PLAY|CHECK or SELECT|CHECK) for the selected card
	; open the card page if CHECK is selected
	ldh a, [hCurMenuItem]
	call GetCardInDuelTempList_OnlyDeckIndex
	call CardListItemSelectionMenu
	; jump back if B button was pressed to exit the item selection menu
	jr c, DisplayCardList
	ldh a, [hTempCardIndex_ff98]
	or a
	ret
.select_pressed
	; sort cards by ID if SELECT is pressed and return to the first item
	ld a, [wSortCardListByID]
	or a
	jr nz, .wait_button
	call SortCardsInDuelTempListByID
	xor a
	ld hl, wSelectedDuelSubMenuItem
	ld [hli], a
	ld [hl], a
	inc a ; TRUE
	ld [wSortCardListByID], a
	call EraseCursor
	jr .reload_list
.down_pressed
	call CountCardsInDuelTempList
	ld b, a
	ldh a, [hCurMenuItem]
	inc a
	cp b
	jr nc, .open_card_page ; if can't go down, reload card page of current card
.move_to_another_card
	; update hCurMenuItem, and wSelectedDuelSubMenuScrollOffset.
	; this means that when navigating up/down through card pages, the page is
	; scrolled to reflect the movement, rather than the cursor going up/down.
	ldh [hCurMenuItem], a
	ld hl, wSelectedDuelSubMenuScrollOffset
	ld [hld], a
	ld [hl], $00 ; wSelectedDuelSubMenuItem
	ld a, SFX_CURSOR
	call PlaySFX
.open_card_page
	; open the card page directly, without an item selection menu
	; in this mode, D_UP and D_DOWN can be used to open the card page
	; of the card above and below the current card
	ldh a, [hCurMenuItem]
	call GetCardInDuelTempList
	call LoadCardDataToBuffer1_FromDeckIndex
	call OpenCardPage_FromCheckHandOrDiscardPile
	ldh a, [hDPadHeld]
	bit B_PAD_UP, a
	jr nz, .up_pressed
	bit B_PAD_DOWN, a
	jr nz, .down_pressed
	; if B pressed, exit card page and reload the card list
	call DrawCardListScreenLayout
	jp DisplayCardList
.up_pressed
	ldh a, [hCurMenuItem]
	or a
	jr z, .open_card_page ; if can't go up, reload card page of current card
	dec a
	jr .move_to_another_card
.b_pressed
	ldh a, [hCurMenuItem]
	scf
	ret


; prints the text ID at wCardListHeaderText at 1,1
; and the text ID at wCardListInfoBoxText at 1,14
; input:
;	[wCardListInfoBoxText] = text ID for the text box (2 bytes)
;	[wCardListHeaderText] = text ID for the header (2 bytes)
PrintCardListHeaderAndInfoBoxTexts:
	lb de, 1, 14
	call AdjustCoordinatesForBGScroll
	ld hl, wCardListInfoBoxText
	ld a, [hli]
	ld h, [hl]
	ld l, a
	call InitTextPrinting_PrintTextNoDelay
	ld hl, wCardListHeaderText
	ld a, [hli]
	ld h, [hl]
	ld l, a
	lb de, 1, 1
	jp InitTextPrinting_PrintTextNoDelay


; prints the items of a list of cards (e.g. hand cards in a duel or cards from a booster pack)
; and initializes the parameters of the list given
; input:
;	wDuelTempList = card list source
;	a = number of cards in the list
;	de = initial page scroll offset, initial item (in the visible page)
;	hl = 9 bytes with the rest of the parameters
PrintCardListItems:
	call InitializeCardListParameters
	ld hl, wMenuUpdateFunc
	ld a, LOW(CardListMenuFunction)
	ld [hli], a
	ld [hl], HIGH(CardListMenuFunction)
	ld a, 2
	ld [wMenuYSeparation], a
	dec a ; 1
	ld [wCardListIndicatorYPosition], a
;	fallthrough

; like PrintCardListItems, except more parameters are already initialized
; called instead of PrintCardListItems to reload the list after moving up or down
ReloadCardListItems:
	ld e, SYM_SPACE
	ld a, [wListScrollOffset]
	or a
	jr z, .cant_go_up
	ld e, SYM_CURSOR_U
.cant_go_up
	ld a, [wMenuCursorYOffset]
	ld c, a
	ld a, [wCardListDisplayFormat]
	cp USE_BOOSTER_PACK_DISPLAY
	jr z, .use_default_offset
	dec c
.use_default_offset
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
	ld a, [wCardListDisplayFormat]
	cp USE_BOOSTER_PACK_DISPLAY
	jr nz, .adjust_offset
	dec c
.adjust_offset
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
	ld a, [wCardListDisplayFormat]
	cp USE_BOOSTER_PACK_DISPLAY
	jr z, .booster_pack
.next_card
	ld a, [hl]
	cp $ff
	ret z ; return if there are no more cards in the list to print
	push hl
	call LoadCardDataToBuffer1_FromDeckIndex
	call DrawCardSymbol
	ld a, [wListItemNameMaxLength]
	call CopyCardNameAndLevel
	ld hl, wDefaultText
	call InitTextPrinting_ProcessText
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
.booster_pack
	push bc
	push de
	push hl
	ld b, SCREEN_WIDTH
	lb de, 0, 2
	call DrawTextBoxSeparator
	pop hl
	pop de
	pop bc
.next_booster_pack_card
	ld a, [hli]
	cp $ff
	ret z ; return if there are no more cards in the list to print
	push hl
	push bc
	call LoadCardDataToBuffer1_FromDeckIndex
	ld d, 2
	ld a, [wLoadedCard1Rarity]
	call PrintCardPageRarityIcon
	ld d, 4
	ld a, 14 ; wListItemNameMaxLength
	call CopyCardNameAndLevel
	ld hl, wDefaultText
	call InitTextPrinting_ProcessText
	call EnableSRAM
	ld h, HIGH(sCardCollection)
	ld a, [wLoadedCard1ID]
	ld l, a
	ld a, [hl]
	call DisableSRAM
	bit CARD_NOT_OWNED_F, a
	jr z, .next_line ; current line is finished if this card was already owned
	ld b, 17
	ld c, e
	ld a, $9f ; new card symbol
	call WriteByteToBGMap0
	ld a, [wConsole]
	cp CONSOLE_CGB
	jr nz, .next_line
	call BankswitchVRAM1
	ld a, $04 ; CGB BG Palette 4 (used for borders)
	call WriteByteToBGMap0
	call BankswitchVRAM0
.next_line
	pop bc
	pop hl
	inc e
	inc e
	dec b
	jr nz, .next_booster_pack_card
	ret


; initializes parameters for a card list (e.g. hand cards in a duel or cards from a booster pack)
; preserves bc and de
; input:
;	a = number of cards in the list
;	de = initial page scroll offset, initial item (in the visible page)
;	hl = 9 bytes with the rest of the parameters
InitializeCardListParameters:
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
	inc a ; 1
	ld [wMenuYSeparation], a
	ret


; this function is always loaded to wMenuUpdateFunc by PrintCardListItems.
; takes care of things like handling page scrolling and calling the function at wListFunctionPointer.
; output:
;	carry = set:  if either the A or the B button were pressed (might be different if wListFunctionPointer isn't null)
;	[wCurMenuItem] = index for the currently selected item (based on the number of items on screen)
;	[hCurMenuItem] = index for the currently selected item (based on the number of items in the list)
;	               = -1:  if the B button was pressed (might be different if wListFunctionPointer isn't null)
CardListMenuFunction:
	ldh a, [hDPadHeld]
	ld b, a
	ld a, [wNumMenuItems]
	dec a
	ld c, a
	ld a, [wCurMenuItem]
; check d up
	bit B_PAD_UP, b
	jr z, .check_d_down
	cp c ; check if wCurMenuItem is the last visible item (because cursor wrapped around)
	jp nz, .continue ; ignore up input if no scrolling occurred
	; we're at the top of the page
	xor a
	ld [wCurMenuItem], a ; set to first item
	ld hl, wListScrollOffset
	ld a, [hl]
	or a ; can we scroll up?
	jr z, .no_more_items
	dec [hl] ; scroll page up
	jp .reload_list_and_continue
.check_d_down
	bit B_PAD_DOWN, b
	jr z, .check_d_left
	or a ; check if wCurMenuItem is the first visible item (because cursor wrapped around)
	jr nz, .secondary_end_of_list_check
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
	jp .reload_list_and_continue
.secondary_end_of_list_check
	ld hl, wListScrollOffset
	add [hl]
	ld hl, wNumListItems
	cp [hl]
	jp c, .continue
	; already on final list item
	ld hl, wCurMenuItem
	dec [hl]
.no_more_items
	xor a
	ld [wRefreshMenuCursorSFX], a
	jr .continue
.check_d_left
	bit B_PAD_LEFT, b
	jr z, .check_d_right
	ld a, [wListScrollOffset]
	or a
	jr z, .continue ; ignore left input if the page hasn't been scrolled
	ld hl, wNumMenuItems
	sub [hl]
	jr c, .top_of_page_reached
	ld [wListScrollOffset], a
	jr .reload_list_and_continue
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
	jr .reload_list_and_continue
.check_d_right
	bit B_PAD_RIGHT, b
	jr z, .continue
	ld a, [wNumMenuItems]
	ld hl, wNumListItems
	cp [hl]
	jr nc, .continue ; ignore right input if every card in the list can be displayed on the same screen
	ld a, [wListScrollOffset]
	ld hl, wNumMenuItems
	add [hl]
	ld c, a
	add [hl]
	dec a
	ld hl, wNumListItems
	cp [hl]
	jr nc, .bottom_of_page_reached
	ld a, c
	ld [wListScrollOffset], a
	jr .reload_list_and_continue
.bottom_of_page_reached
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
.reload_list_and_continue
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
	ld a, [wCardListDisplayFormat]
	cp USE_BOOSTER_PACK_DISPLAY
	jr nz, .not_booster
	inc b
.not_booster
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
	ld h, [hl]
	ld l, a
	or h
	jr z, .no_list_function
	ldh a, [hCurMenuItem]
	jp hl ; execute the function at wListFunctionPointer
.no_list_function
	ldh a, [hKeysPressed]
	and PAD_A | PAD_B
	ret z
	and PAD_B
	jr z, .pressed_a
	; pressed B
	ld a, -1
	ldh [hCurMenuItem], a
.pressed_a
	scf
	ret


; displays the SELECT|CHECK or PLAY|CHECK menu when a card of a list is selected and handles input
; input:
;	[wCardListItemSelectionMenuType] = which type of menu to display (*_CHECK constant)
; output:
;	carry = set:  if the B button was pressed to exit the card list screen
CardListItemSelectionMenu:
	ld a, [wCardListItemSelectionMenuType]
	or a
	ret z
	ldtx hl, SelectCheckText
	ld a, [wCardListItemSelectionMenuType]
	cp PLAY_CHECK
	jr nz, .got_text
;	ldh a, [hTempCardIndex_ff98]
;	call LoadCardDataToBuffer1_FromDeckIndex
;	ldtx hl, PlayCheckText
;	ld a, [wLoadedCard1Type]
;	cp TYPE_TRAINER
;	jr nz, .got_text
	ldtx hl, PlayCheckText
.got_text
	call DrawNarrowTextBox_PrintTextNoDelay
	ld hl, ItemSelectionMenuParameters
	xor a
	call InitializeMenuParameters
.wait_a_or_b
	call DoFrame
	call HandleMenuInput
	jr nc, .wait_a_or_b
	cp -1
	jr z, .b_pressed ; exit if the B button was pressed
	; A pressed
	or a
	ret z
	; CHECK option selected: open the card page
	ldh a, [hTempCardIndex_ff98]
	call LoadCardDataToBuffer1_FromDeckIndex
	call OpenCardPage_FromHand
	call DrawCardListScreenLayout
.b_pressed
	scf
	ret

ItemSelectionMenuParameters:
	db 1, 14 ; cursor x, cursor y
	db 2 ; y displacement between items
	db 2 ; number of items
	db SYM_CURSOR_R ; cursor tile number
	db SYM_SPACE ; tile behind cursor
	dw NULL ; function pointer if non-0


CardListParameters:
	db 1, 3 ; cursor x, cursor y
	db 4 ; item x
	db 14 ; maximum length, in tiles, occupied by the name and level string of each card in the list
	db 5 ; number of items selectable without scrolling
	db SYM_CURSOR_R ; cursor tile number
	db SYM_SPACE ; tile behind cursor
	dw CardListFunction ; function pointer if non-0


; loads the graphics of the card pointed to by the cursor whenever a d-pad key is released
; output:
;	carry = set:  if any of the other buttons were pressed (A/B/SELECT/START)
;	[hCurMenuItem] = -1:  if the B button was pressed
CardListFunction:
	ldh a, [hKeysPressed]
	bit B_PAD_B, a
	jr nz, .exit
	and PAD_A | PAD_SELECT | PAD_START
	jr nz, .action_button
	ldh a, [hKeysReleased]
	and PAD_CTRL_PAD
	ret z ; return unless the D_PAD key was released this frame
	call LoadSelectedCardGfx
	or a
	ret
.exit
	ld a, -1
	ldh [hCurMenuItem], a
.action_button
	scf
	ret


; loads the tiles and palette of the card selected in a card list screen
; input:
;	[hCurMenuItem] = index for wDuelTempList
LoadSelectedCardGfx:
	ldh a, [hCurMenuItem]
	call GetCardInDuelTempList
	call LoadCardDataToBuffer1_FromCardID
	ld de, v0Tiles1 + $20 tiles
	call LoadLoaded1CardGfx
	call SetBGP6OrSGB3ToCardPalette
	jp FlushAllPalettesOrSendPal23Packet


; uses a list index to retrieve the deck index and card ID of a card in wDuelTempList.
; preserves bc and hl
; input:
;	a = index for wDuelTempList
; output:
;	a & [hTempCardIndex_ff98] = deck index of the correct card from wDuelTempList ([wDuelTempList + a])
;	de = card ID of the correct card from wDuelTempList
GetCardInDuelTempList:
	push hl
	ld e, a
	ld d, $0
	ld hl, wDuelTempList
	add hl, de
	ld a, [hl]
	ldh [hTempCardIndex_ff98], a
	call GetCardIDFromDeckIndex
	pop hl
	ldh a, [hTempCardIndex_ff98]
	ret


; uses a list index to retrieve a deck index from wDuelTempList.
; preserves all registers except af
; input:
;	a = index for wDuelTempList
; output:
;	a & [hTempCardIndex_ff98] = deck index of the correct card from wDuelTempList ([wDuelTempList + a])
GetCardInDuelTempList_OnlyDeckIndex:
	push hl
	push de
	ld e, a
	ld d, $0
	ld hl, wDuelTempList
	add hl, de
	ld a, [hl]
	ldh [hTempCardIndex_ff98], a
	pop de
	pop hl
	ret


; draws the card page of the card at wLoadedCard1 and listens for input
; in order to switch the page or to exit.
; triggered by checking a hand or a discard pile card in the Check menu.
; D_UP and D_DOWN exit the card page allowing the caller to load the card page
; of the card above or below in the list.
; input:
;	[wLoadedCard1] = all of the card's data (card_data_struct)
OpenCardPage_FromCheckHandOrDiscardPile:
	ld a, PAD_B | PAD_UP | PAD_DOWN
	ld [wCardPageExitKeys], a
	xor a ; CARDPAGETYPE_NOT_PLAY_AREA
	jr OpenCardPage

; draws the card page of the card at wLoadedCard1 and listens for input
; in order to switch the page or to exit.
; triggered by checking an Active or Benched Pokemon in the Check menu.
; input:
;	[wLoadedCard1] = all of the card's data (card_data_struct)
OpenCardPage_FromCheckPlayArea:
	ld a, PAD_B
	ld [wCardPageExitKeys], a
	ld a, CARDPAGETYPE_PLAY_AREA
	jr OpenCardPage

; draws the card page of the card at wLoadedCard1 and listens for input
; in order to switch the page or to exit.
; triggered by checking a card in the Hand menu.
; input:
;	[wLoadedCard1] = all of the card's data (card_data_struct)
OpenCardPage_FromHand:
	ld a, PAD_B
	ld [wCardPageExitKeys], a
	xor a ; CARDPAGETYPE_NOT_PLAY_AREA
;	fallthrough

; draws the card page of the card at wLoadedCard1 and listens for input
; in order to switch the page or to exit.
; input:
;	a = type of card page to open (CARDPAGETYPE_* constant)
;	[wCardPageExitKeys] = which buttons will exit the card page
OpenCardPage:
	ld [wCardPageType], a
	call ZeroObjectPositionsAndToggleOAMCopy
	call EmptyScreen
	call FinishQueuedAnimations
	; load the graphics and display the card image of wLoadedCard1
	call LoadDuelCardSymbolTiles
	ld de, v0Tiles1 + $20 tiles
	call LoadLoaded1CardGfx
	call SetOBP1OrSGB3ToCardPalette
	call SetBGP6OrSGB3ToCardPalette
	call FlushAllPalettesOrSendPal23Packet
	lb de, $38, $30 ; X Position and Y Position of top-left corner
	call PlaceCardImageOAM
	lb de, 6, 4
	call ApplyBGP6OrSGB3ToCardImage
	; display the initial card page for the card at wLoadedCard1
	xor a
	ld [wCardPageNumber], a
.load_next
	call DisplayFirstOrNextCardPage
	ret c ; done if trying to advance past the last page with START or A_BUTTON
	call EnableLCD
.input_loop
	call DoFrame
	ldh a, [hDPadHeld]
	ld b, a
	ld a, [wCardPageExitKeys]
	and b
	ret nz ; done with loop
	; START and A_BUTTON advance to the next valid card page, but close it
	; after trying to advance from the last page
	ldh a, [hKeysPressed]
	and PAD_START | PAD_A
	jr nz, .load_next
	; D_RIGHT and D_LEFT advance to the next and previous valid card page respectively.
	; however, unlike START and A_BUTTON, D_RIGHT past the last page goes back to the start.
	ldh a, [hKeysPressed]
	and PAD_RIGHT | PAD_LEFT
	call nz, DisplayCardPageOnLeftOrRightPressed
	jr .input_loop


; displays the previous valid card page of the card at wLoadedCard1
; if bit B_PAD_LEFT of a is set, and the first or next valid card page otherwise.
; input:
;	a = [hKeysPressed]
DisplayCardPageOnLeftOrRightPressed:
	bit B_PAD_LEFT, a
	jr nz, .left
;.right
	call GoToFirstOrNextCardPage
	jr DisplayCardPage
.left
	call GoToPreviousCardPage
	jr DisplayCardPage


; displays the next valid card page or load the first valid card page if [wCardPageNumber] = 0
DisplayFirstOrNextCardPage:
	call GoToFirstOrNextCardPage
	ret c
;	fallthrough

; displays the card page with ID at wCardPageNumber of wLoadedCard1
; input:
;	[wCardPageNumber] = which card page to display
;	[wLoadedCard1] = all of the card's data (card_data_struct)
DisplayCardPage:
	ld a, [wCardPageNumber]
	ld hl, CardPageDisplayPointerTable
	call JumpToFunctionInTable
	call EnableLCD
	or a
	ret

CardPageDisplayPointerTable:
	dw DrawDuelMainScene
	dw DisplayCardPage_PokemonOverview     ; CARDPAGE_POKEMON_OVERVIEW
	dw DisplayCardPage_PokemonAttack1Page1 ; CARDPAGE_POKEMON_ATTACK1_1
	dw DisplayCardPage_PokemonAttack1Page2 ; CARDPAGE_POKEMON_ATTACK1_2
	dw DisplayCardPage_PokemonAttack2Page1 ; CARDPAGE_POKEMON_ATTACK2_1
	dw DisplayCardPage_PokemonAttack2Page2 ; CARDPAGE_POKEMON_ATTACK2_2
	dw DisplayCardPage_PokemonDescription  ; CARDPAGE_POKEMON_DESCRIPTION
	dw DrawDuelMainScene
	dw DrawDuelMainScene
	dw DisplayCardPage_Energy ; CARDPAGE_ENERGY
	dw DisplayCardPage_Energy ; CARDPAGE_ENERGY + 1
	dw DrawDuelMainScene
	dw DrawDuelMainScene
	dw DisplayCardPage_TrainerPage1 ; CARDPAGE_TRAINER_1
	dw DisplayCardPage_TrainerPage2 ; CARDPAGE_TRAINER_2
	dw DrawDuelMainScene


; given the current card page at [wCardPageNumber], go to the next valid card page or load
; the first valid card page of the current card at wLoadedCard1 if [wCardPageNumber] = 0
; preserves de
; input:
;	[wCardPageNumber] = current card page
; output:
;	carry = set:  if SwitchCardPage returned carry
;	[wCardPageNumber] = new card page
GoToFirstOrNextCardPage:
	ld a, [wCardPageNumber]
	or a
	jr nz, .advance_page
	; load the first page for this type of card
	ld a, [wLoadedCard1Type]
	ld b, a
	ld a, CARDPAGE_ENERGY
	bit TYPE_ENERGY_F, b
	jr nz, .set_initial_page
	ld a, CARDPAGE_TRAINER_1
	bit TYPE_TRAINER_F, b
	jr nz, .set_initial_page
	ld a, CARDPAGE_POKEMON_OVERVIEW
.set_initial_page
	ld [wCardPageNumber], a
	or a
	ret
.advance_page
	ld hl, wCardPageNumber
	inc [hl]
	ld a, [hl]
	call SwitchCardPage
	jr c, .set_card_page
	; stay in this page if it exists, or skip to previous page if it doesn't
	or a
	ret nz
	; non-existent page: skip to next
	jr .advance_page
.set_card_page
	ld [wCardPageNumber], a
	ret


; given the current card page at [wCardPageNumber], go to the previous
; valid card page for the current card at wLoadedCard1
; preserves bc and de
; input:
;	[wCardPageNumber] = current card page
; output:
;	carry = set:  if the second "call SwitchCardPage" returned carry
;	[wCardPageNumber] = new card page
GoToPreviousCardPage:
	ld hl, wCardPageNumber
	dec [hl]
	ld a, [hl]
	call SwitchCardPage
	jr c, .set_card_page
	; stay in this page if it exists, or skip to previous page if it doesn't
	or a
	ret nz
	; non-existent page: skip to previous
	jr GoToPreviousCardPage
.set_card_page
	ld [wCardPageNumber], a
.previous_page_loop
	call SwitchCardPage
	or a
	scf
	ret nz ; return carry with the current card page as long as that page exists
	ld hl, wCardPageNumber
	dec [hl]
	jr .previous_page_loop


; checks if the card page trying to switch to is valid for the card at wLoadedCard1
; preserves bc and de
; output:
;	carry/z flag = not set:  switch to this card page
;	carry = set:  switch to the card page output in a if D_LEFT/D_RIGHT were pressed,
;	              or exit if A_BUTTON/START were pressed
;	z flag = set:  non-existent page, so skip to next/previous
SwitchCardPage:
	ld hl, CardPageSwitchPointerTable
	jp JumpToFunctionInTable

CardPageSwitchPointerTable:
	dw CardPageSwitch_00
	dw CardPageSwitch_PokemonOverviewOrDescription ; CARDPAGE_POKEMON_OVERVIEW
	dw CardPageSwitch_PokemonAttack1Page1          ; CARDPAGE_POKEMON_ATTACK1_1
	dw CardPageSwitch_PokemonAttack1Page2          ; CARDPAGE_POKEMON_ATTACK1_2
	dw CardPageSwitch_PokemonAttack2Page1          ; CARDPAGE_POKEMON_ATTACK2_1
	dw CardPageSwitch_PokemonAttack2Page2          ; CARDPAGE_POKEMON_ATTACK2_2
	dw CardPageSwitch_PokemonOverviewOrDescription ; CARDPAGE_POKEMON_DESCRIPTION
	dw CardPageSwitch_PokemonEnd
	dw CardPageSwitch_08
	dw CardPageSwitch_EnergyOrTrainerPage1 ; CARDPAGE_ENERGY
	dw CardPageSwitch_TrainerPage2         ; CARDPAGE_ENERGY + 1
	dw CardPageSwitch_EnergyEnd
	dw CardPageSwitch_0c
	dw CardPageSwitch_EnergyOrTrainerPage1 ; CARDPAGE_TRAINER_1
	dw CardPageSwitch_TrainerPage2         ; CARDPAGE_TRAINER_2
	dw CardPageSwitch_TrainerEnd


; output:
;	carry = set
CardPageSwitch_00:
	ld a, CARDPAGE_POKEMON_DESCRIPTION
	scf
	ret

; keeps the current page
CardPageSwitch_PokemonOverviewOrDescription:
	ld a, $1
	or a
	ret ; nz


; keeps the current page if the Pokemon has at least 1 attack
; output:
;	z flag = set:  if the Pokemon doesn't have any attacks
CardPageSwitch_PokemonAttack1Page1:
	ld hl, wLoadedCard1Atk1Name
	jr CheckCardPageExists


; keeps the current page if the Pokemon's first attack has a two-page description
; output:
;	z flag = set:  if the first attack's description doesn't have a second page
CardPageSwitch_PokemonAttack1Page2:
	ld hl, wLoadedCard1Atk1Description + 2
	jr CheckCardPageExists


; keeps the current page if the Pokemon has 2 attacks
; output:
;	z flag = set:  if the Pokemon doesn't have a second attack
CardPageSwitch_PokemonAttack2Page1:
	ld hl, wLoadedCard1Atk2Name
	jr CheckCardPageExists


; keeps the current page if the Pokemon's second attack has a two-page description
; output:
;	z flag = set:  if the second attack's description doesn't have a second page
CardPageSwitch_PokemonAttack2Page2:
	ld hl, wLoadedCard1Atk2Description + 2
;	fallthrough

CheckCardPageExists:
	ld a, [hli]
	or [hl]
	ret


; output:
;	carry = set
CardPageSwitch_PokemonEnd:
	ld a, CARDPAGE_POKEMON_OVERVIEW
	scf
	ret


; output:
;	carry = set
CardPageSwitch_08:
	ld a, CARDPAGE_ENERGY + 1
	scf
	ret


; keeps the current page
CardPageSwitch_EnergyOrTrainerPage1:
	ld a, $1
	or a
	ret ; nz


; keeps the current page if the Trainer card has a two-page description
; output:
;	z flag = set:  if the Trainer card description doesn't have a second page
CardPageSwitch_TrainerPage2:
	ld hl, wLoadedCard1NonPokemonDescription + 2
	jr CheckCardPageExists


; output:
;	carry = set
CardPageSwitch_EnergyEnd:
	ld a, CARDPAGE_ENERGY
	scf
	ret


; output:
;	carry = set
CardPageSwitch_0c:
	ld a, CARDPAGE_TRAINER_2
	scf
	ret


; output:
;	carry = set
CardPageSwitch_TrainerEnd:
	ld a, CARDPAGE_TRAINER_1
	scf
	ret


; places OAM for a 8x6 image (64x48 pixels), using object size 8x16 and obj palette 1.
; starting tile number is $a0 (v0Tiles1 + $20 tiles).
; used to draw the image of a card in the check card screens.
; input:
;	de: screen coordinates for the top-left corner of the image
PlaceCardImageOAM:
	call Set_OBJ_8x16
	ld l, $a0
	ld c, 8 ; number of objects per row
.next_column
	ld b, 3 ; number of rows
	push de
.next_row
	push bc
	ld c, l ; tile number
	ld b, 1 ; attributes (palette)
	call SetOneObjectAttributes
	pop bc
	inc l
	inc l ; next 8x16 tile
	ld a, 16
	add e ; Y Position += 16 (next 8x16 row)
	ld e, a
	dec b
	jr nz, .next_row
	pop de
	ld a, 8
	add d ; X Position += 8 (next 8x16 column)
	ld d, a
	dec c
	jr nz, .next_column
	ld a, $01
	ld [wVBlankOAMCopyToggle], a
	ret


; given the deck index of a card in the play area,
; loads the card's graphics (tiles and palette) to de
; input:
;	a = card's deck index (0-59)
;	de = where in vram to copy the card's graphic data
LoadPlayAreaCardGfx:
	cp -1
	ret z ; return if the play area slot is empty
	call LoadCardDataToBuffer1_FromDeckIndex
;	fallthrough

; load the graphics (tiles and palette) of the card loaded in wLoadedCard1 to de
; input:
;	de = where in vram to copy the card's graphic data
;	[wLoadedCard1Gfx] = pointer for the card's graphic data (2 bytes)
LoadLoaded1CardGfx:
	ld hl, wLoadedCard1Gfx
	ld a, [hli]
	ld h, [hl]
	ld l, a
	lb bc, $30, TILE_SIZE
	jp LoadCardGfx


SetBGP7OrSGB2ToCardPalette:
	ld a, [wConsole]
	or a ; CONSOLE_DMG
	ret z
	cp CONSOLE_SGB
	jr z, SetSGB2ToCardPalette
	ld a, $07 ; CGB BG Palette 7
	jr CopyCGBCardPalette


SetSGB2ToCardPalette:
	ld hl, wCardPalette
	ld de, wTempSGBPacket + 1 ; PAL Packet color #0 (PAL23's SGB2)
	ld b, PAL_SIZE
	jp CopyNBytesFromHLToDE



SetBGP6OrSGB3ToCardPalette:
	ld a, [wConsole]
	or a ; CONSOLE_DMG
	ret z
	cp CONSOLE_SGB
	jr z, SetSGB3ToCardPalette
	ld a, $06 ; CGB BG Palette 6
	jr CopyCGBCardPalette


SetSGB3ToCardPalette:
	ld hl, wCardPalette + 2
	ld de, wTempSGBPacket + 9 ; Pal Packet color #4 (PAL23's SGB3)
	ld b, 6
	jp CopyNBytesFromHLToDE


SetOBP1OrSGB3ToCardPalette:
	ldgbpal a, SHADE_WHITE, SHADE_LIGHT, SHADE_DARK, SHADE_BLACK
	ld [wOBP0], a
	ld a, [wConsole]
	or a ; CONSOLE_DMG
	ret z
	cp CONSOLE_SGB
	jr z, SetSGB3ToCardPalette
	ld a, $09 ; CGB Object Palette 1
;	fallthrough

; input:
;	a = which CGB palette to fill with the card's palette
CopyCGBCardPalette:
	add a
	add a
	add a ; a *= PAL_SIZE
	ld e, a
	ld d, $00
	ld hl, wBackgroundPalettesCGB ; wObjectPalettesCGB - 8 palettes
	add hl, de
	ld de, wCardPalette
	ld b, PAL_SIZE
.copy_pal_loop
	ld a, [de]
	inc de
	ld [hli], a
	dec b
	jr nz, .copy_pal_loop
	ret


FlushAllPalettesOrSendPal23Packet:
	ld a, [wConsole]
	or a ; CONSOLE_DMG
	ret z
	cp CONSOLE_SGB
	jp nz, FlushAllPalettes ; not sgb

; sgb PAL23, 1 ; sgb_command, length
; rgb 28, 28, 24 (cream, main background color)
; colors 1-7 carried over
	ld a, PAL23 << 3 + 1
	ld hl, wTempSGBPacket
	ld [hli], a
	ld a, LOW(24 << 10 | 28 << 5 | 28)
	ld [hli], a
	ld a, HIGH(24 << 10 | 28 << 5 | 28)
	ld [hld], a
	dec hl
	xor a
	ld [wTempSGBPacket + $f], a
	jp SendSGB


; input:
;	de = screen coordinates of card image's top left tile
ApplyBGP6OrSGB3ToCardImage:
	ld a, [wConsole]
	or a ; CONSOLE_DMG
	ret z
	cp CONSOLE_SGB
	jr z, ApplySGB3
	ld a, $06 ; CGB BG Palette 6
;	fallthrough

; given the 8x6 card image with coordinates at de, fills its BGMap attributes with a
; input:
;	a = which background palette to use
;	de = screen coordinates of card image's top left tile
ApplyCardCGBAttributes:
	call BankswitchVRAM1
	lb hl, 0, 0
	lb bc, 8, 6
	call FillRectangle
	jp BankswitchVRAM0

ApplySGB3:
	ld a, 3 << 0 + 3 << 2 ; Color Palette Designation
;	fallthrough

; input:
;	a = SGB palette information
;	de = screen coordinates of card image's top left tile
SendCardAttrBlkPacket:
	call CreateCardAttrBlkPacket
	jp SendSGB


; input:
;	de = screen coordinates of card image's top left tile
ApplyBGP7OrSGB2ToCardImage:
	ld a, [wConsole]
	or a ; CONSOLE_DMG
	ret z
	cp CONSOLE_SGB
	jr z, .sgb
	ld a, $07 ; CGB BG Palette 7
	jr ApplyCardCGBAttributes
.sgb
	ld a, 2 << 0 + 2 << 2 ; Color Palette Designation
	jr SendCardAttrBlkPacket


; preserves bc and de
; input:
;	a = SGB palette information
;	de = screen coordinates of card image's top left tile
CreateCardAttrBlkPacket:
; sgb ATTR_BLK, 1 ; sgb_command, length
; db 1 ; number of data sets
	ld hl, wTempSGBPacket
	push hl
	ld [hl], ATTR_BLK << 3 + 1
	inc hl
	ld [hl], 1
	inc hl
	call CreateCardAttrBlkPacket_DataSet
	xor a
	ld [hli], a
	ld [hli], a
	ld [hli], a
	ld [hli], a
	pop hl
	ret


; preserves bc and de
; input:
;	a = SGB palette information
;	de = screen coordinates of card image's top left tile
;	hl = where in wram to store the data set
CreateCardAttrBlkPacket_DataSet:
; Control Code, Color Palette Designation, X1, Y1, X2, Y2
; db ATTR_BLK_CTRL_INSIDE + ATTR_BLK_CTRL_LINE, a, d, e, d+7, e+5 ; data set 1
	ld [hl], ATTR_BLK_CTRL_INSIDE + ATTR_BLK_CTRL_LINE
	inc hl
	ld [hl], a
	inc hl
	ld [hl], d
	inc hl
	ld [hl], e
	inc hl
	ld a, 7
	add d
	ld [hli], a
	ld a, 5
	add e
	ld [hli], a
	ret


; input:
;	[wLoadedCard1] = all of the Pokémon's data (card_data_struct)
DisplayCardPage_PokemonOverview:
	ld a, [wCardPageType]
	or a ; CARDPAGETYPE_NOT_PLAY_AREA
	jr nz, .play_area_card_page

; CARDPAGETYPE_NOT_PLAY_AREA
	; print surrounding box, card name at 5,1, type, set 2, and rarity
	call PrintPokemonCardPageGenericInformation
	; print fixed text and draw the card symbol associated to its TYPE_*
	ld hl, CardPageRetreatWRTextData
	call PlaceTextItems
	ld hl, CardPageLvHPTextData
	call PlaceTextItems
	lb de, 3, 2
	call DrawCardSymbol
	; print pre-evolution's name (if any)
	ld a, [wLoadedCard1Stage]
	or a
	jr z, .basic
	ld hl, wLoadedCard1PreEvoName
	lb de, 1, 3
	call InitTextPrinting_ProcessTextFromPointerToID
.basic
	; print card level and maximum HP
	lb bc, 12, 2
	ld a, [wLoadedCard1Level]
	call WriteTwoDigitNumberInTxSymbolFormat_TrimLeadingZero
	lb bc, 16, 2
	ld a, [wLoadedCard1HP]
	call WriteOneByteNumberInTxSymbolFormat_TrimLeadingZeros
	jr .print_numbers_and_energies

; CARDPAGETYPE_PLAY_AREA
.play_area_card_page
	; draw the surrounding box, and print fixed text
	call DrawCardPageSurroundingBox
	call LoadDuelCheckPokemonScreenTiles
	ld hl, CardPageRetreatWRTextData
	call PlaceTextItems
	ld a, 1
	ld [wCurPlayAreaY], a
	; print set 2 icon and rarity symbol at fixed positions
	call DrawCardPageSet2AndRarityIcons
	; print (Y coord at [wCurPlayAreaY]) card name, level, type, energies, HP, location...
	call PrintPlayAreaCardInformationAndLocation

; common for both card page types
.print_numbers_and_energies
	; print Pokedex number in the bottom right corner (16,16)
	lb bc, 16, 16
	ld hl, wLoadedCard1PokedexNumber
	ld a, [hli]
	ld h, [hl]
	ld l, a
	call WriteThreeDigitNumberInTxSymbolFormat
	; print the name, damage, and Energy cost of each attack and/or Pokemon Power that exists
	; first attack at 5,10 and second at 5,12
	lb bc, 5, 10

.attacks
	ld e, c
	ld hl, wLoadedCard1Atk1Name
	call PrintAttackOrPkmnPowerInformation
	inc c
	inc c ; 12
	ld e, c
	ld hl, wLoadedCard1Atk2Name
	call PrintAttackOrPkmnPowerInformation
	; print the retreat cost (some amount of colorless energies) at 8,14
	inc c
	inc c ; 14
	ld b, 8
	ld a, [wLoadedCard1RetreatCost]
	ld e, a
	inc e
.retreat_cost_loop
	dec e
	jr z, .retreat_cost_done
	ld a, SYM_COLORLESS
	call WriteByteToBGMap0
	inc b
	jr .retreat_cost_loop
.retreat_cost_done
	; print the colors (energies) of the weakness(es) and resistance(s)
	inc c ; 15
	ld a, [wCardPageType]
	or a
	jr z, .wr_from_loaded_card
	ld a, [wCurPlayAreaSlot]
	or a
	jr nz, .wr_from_loaded_card
	call GetArenaCardWeakness
	ld d, a
	call GetArenaCardResistance
	ld e, a
	jr .got_wr
.wr_from_loaded_card
	ld a, [wLoadedCard1Weakness]
	ld d, a
	ld a, [wLoadedCard1Resistance]
	ld e, a
.got_wr
	ld a, d
	ld b, 8
	call PrintCardPageWeaknessesOrResistances
	inc c ; 16
	ld a, e
;	fallthrough

; prints the Weakness or Resistance symbols on a Pokemon card page, given in a, at b,c
; preserves all registers except af
; input:
;	a = which type symbols to print (each type has a separate bit)
;	bc = screen coordinates at which to begin printing the type symbols
PrintCardPageWeaknessesOrResistances:
	push bc
	push de
	ld d, a
	xor a ; FIRE
.loop
	; each WR_* constant is a different bit. rotate the value to find out
	; which bits are set and therefore which WR_* values are active.
	; a is kept updated with the equivalent TYPE_* constant.
	inc a
	cp 8
	jr nc, .done
	rl d
	jr nc, .loop
	push af
	call WriteByteToBGMap0
	inc b
	pop af
	jr .loop
.done
	pop de
	pop bc
	ret


; displays the name, damage, and Energy cost of an attack or Pokemon Power.
; used in the Attack menu and in the card page of a Pokemon.
; preserves bc
; input:
;	hl = pointer to an attack name in an atk_data_struct (which can be inside a card_data_struct)
;	e = Y coordinate at which to start printing the information
PrintAttackOrPkmnPowerInformation:
	ld a, [hli]
	or [hl]
	ret z ; return if the attack slot is blank
	push bc
	push hl
	dec hl
	; print text ID pointed to by hl at 7,e
	ld d, 7
	call InitTextPrinting_ProcessTextFromPointerToID
	pop hl
	inc hl
	inc hl
	ld a, [wCardPageNumber]
	or a
	jr nz, .print_damage
	dec hl
	ld a, [hli]
	or [hl]
	jr z, .print_damage
	; if in Attack menu and attack 1 description exists,
	; print centered ellipsis (...) below attack name
	push hl
	ld d, 9
	inc e
	ldtx hl, AttackDescriptionEllipsisText
	call InitTextPrinting_ProcessTextFromID
	dec e
	pop hl ; wLoadedAttackDescription + 1
.print_damage
	inc hl
	inc hl
	inc hl ; wLoadedAttackDamage
	ld a, [hli]
	push hl
	or a
	jr z, .print_category
	; print attack damage at 15,(e+1) if non-0
	ld b, 15 ; unless damage has three digits, this is effectively 16
	ld c, e
	inc c
	call WriteOneByteNumberInTxSymbolFormat_TrimLeadingZeros
.print_category
	pop hl ; wLoadedAttackCategory
	ld a, [hl]
	and $ff ^ RESIDUAL
	jr z, .print_energy_cost
	cp POKEMON_POWER
	jr z, .print_pokemon_power
	; register a is DAMAGE_PLUS, DAMAGE_MINUS, or DAMAGE_X
	; print the damage modifier (+, -, x) at 18,(e+1) (after the damage value)
	add SYM_PLUS - DAMAGE_PLUS
	ld b, 18
	ld c, e
	inc c
	call WriteByteToBGMap0
.print_energy_cost
	ld bc, CARD_DATA_ATTACK1_ENERGY_COST - CARD_DATA_ATTACK1_CATEGORY
	add hl, bc
	ld c, e
	ld b, 2 ; bc = 2, e
	lb de, NUM_TYPES / 2, 0
.energy_loop
	ld a, [hl]
	swap a
	call PrintEnergiesOfColor
	ld a, [hli]
	call PrintEnergiesOfColor
	dec d
	jr nz, .energy_loop
	pop bc
	ret
.print_pokemon_power
	; print "PKMN PWR" at 2,e
	ld d, 2
	ldtx hl, PKMNPWRText
	call InitTextPrinting_ProcessTextFromID
	pop bc
	ret


; prints the amount of Energy required for type/color in e, and returns e ++ (next color).
; preserves hl
; input:
;	a = Energy requirement for the current type/color (in lower nybble)
;	e = which type/color symbol is being printed
;	bc = screen coordinates at which to begin printing the Energy symbols
PrintEnergiesOfColor:
	inc e
	and $0f
	ret z
	push de
	ld d, a
.print_energies_loop
	ld a, e
	call WriteByteToBGMap0
	inc b
	dec d
	jr nz, .print_energies_loop
	pop de
	ret


; prints surrounding box, card name at 5,1, type, set 2, and rarity.
; used in all CARDPAGE_POKEMON_* and ATTACKPAGE_*, except in
; CARDPAGE_POKEMON_OVERVIEW when wCardPageType is CARDPAGETYPE_PLAY_AREA.
; input:
;	[wLoadedCard1] = all of the Pokémon's data (card_data_struct)
PrintPokemonCardPageGenericInformation:
	call DrawCardPageSurroundingBox
	lb de, 5, 1
	ld hl, wLoadedCard1Name
	call InitTextPrinting_ProcessTextFromPointerToID
	ld a, [wCardPageType]
	or a ; CARDPAGETYPE_NOT_PLAY_AREA
	jr z, .from_loaded_card
	ld a, [wCurPlayAreaSlot]
	call GetPlayAreaCardColor
	jr .got_color
.from_loaded_card
	ld a, [wLoadedCard1Type]
.got_color
	lb bc, 18, 1
	inc a ; Energy text symbols start at 1, not 0
	call WriteByteToBGMap0
;	fallthrough

; prints the card's set 2 icon and the full width text character of the card's rarity
; input:
;	[wLoadedCard1] = all of the card's data (card_data_struct)
DrawCardPageSet2AndRarityIcons:
	ld a, [wLoadedCard1Set]
	call LoadCardSet2Tiles
	jr c, .icon_done
	; draw the 2x2 set 2 icon of this card
	ld a, $fc
	lb hl, 1, 2
	lb bc, 2, 2
	lb de, 15, 8
	call FillRectangle
.icon_done
	lb de, 18, 9
	ld a, [wLoadedCard1Rarity]
	cp NO_RARITY
	ret z
;	fallthrough

; given a card rarity constant in a, and CardRarityTextIDs in hl,
; prints the text character associated to it at d,e
; preserves de
; input:
;	a = CARD_DATA_RARITY constant
;	de = screen coordinates for printing the rarity icon
PrintCardPageRarityIcon:
	ld hl, CardRarityTextIDs
	inc a
	add a
	ld c, a
	ld b, $00
	add hl, bc
	jp InitTextPrinting_ProcessTextFromPointerToID

CardRarityTextIDs:
	tx EmptySpaceText      ; SPACE (NO_RARITY)
	tx CircleRarityText    ; CIRCLE
	tx DiamondRarityText   ; DIAMOND
	tx StarRarityText      ; STAR
	tx PromostarRarityText ; PROMOSTAR


; draws the 20x18 surrounding box and also colorizes the card image
DrawCardPageSurroundingBox:
	ld hl, wTextBoxFrameType
	set 7, [hl] ; colorize textbox border also on SGB (with SGB1)
	push hl
	lb de, 0, 0
	lb bc, 20, 18
	call DrawRegularTextBox
	pop hl
	res 7, [hl]
	lb de, 6, 4
	jp ApplyBGP6OrSGB3ToCardImage


CardPageRetreatWRTextData:
	textitem 1, 14, RetreatCostText
	textitem 1, 15, WeaknessText
	textitem 1, 16, ResistanceText
	textitem 15, 16, NumberSymbolText
	db $ff


CardPageLvHPTextData:
	textitem 11, 2, LvSymbolText
	textitem 15, 2, HPText
	db $ff


; input:
;	[wLoadedCard1] = all of the Pokémon's data (card_data_struct)
DisplayCardPage_PokemonAttack1Page1:
	ld hl, wLoadedCard1Atk1Name
	ld de, wLoadedCard1Atk1Description
	call DisplayPokemonAttackCardPage
	ld hl, wLoadedCard1Atk1Description + 2
;	fallthrough

; draws a down arrow symbol in the bottom right corner of the attack page
; if the description is continued on a second page.
; preserves de
; input:
;   hl = pointer to an attack description (e.g. wLoadedCard1Atk1Description + 2)
PrintDownArrowIfSecondDescriptionPage:
	ld a, [hli]
	or [hl]
	ret z
	lb bc, 18, 16
	ld a, SYM_CURSOR_D
	jp WriteByteToBGMap0


; input:
;	[wLoadedCard1] = all of the Pokémon's data (card_data_struct)
DisplayCardPage_PokemonAttack1Page2:
	ld hl, wLoadedCard1Atk1Name
	ld de, wLoadedCard1Atk1Description + 2
	call DisplayPokemonAttackCardPage
;	fallthrough

; draws an up arrow symbol in the bottom right corner of the attack page
; preserves de and hl
PrintUpArrowOnSecondDescriptionPage:
	lb bc, 18, 16
	ld a, SYM_CURSOR_U
	jp WriteByteToBGMap0


; input:
;	[wLoadedCard1] = all of the Pokémon's data (card_data_struct)
DisplayCardPage_PokemonAttack2Page1:
	ld hl, wLoadedCard1Atk2Name
	ld de, wLoadedCard1Atk2Description
	call DisplayPokemonAttackCardPage
	ld hl, wLoadedCard1Atk2Description + 2
	jr PrintDownArrowIfSecondDescriptionPage


; input:
;	[wLoadedCard1] = all of the Pokémon's data (card_data_struct)
DisplayCardPage_PokemonAttack2Page2:
	ld hl, wLoadedCard1Atk2Name
	ld de, wLoadedCard1Atk2Description + 2
	call DisplayPokemonAttackCardPage
	jr PrintUpArrowOnSecondDescriptionPage


; input:
;	[hl] = text ID for the attack name to print (2 bytes)
;	[de] = text ID for the attack description to print (2 bytes)
;	[wLoadedCard1] = all of the Pokémon's data (card_data_struct)
DisplayPokemonAttackCardPage:
	push de
	push hl
	; print surrounding box, card name at 5,1, type, set 2, and rarity
	call PrintPokemonCardPageGenericInformation
	; print name, damage, and Energy cost of attack or Pokemon Power starting at line 2
	ld e, 2
	pop hl
	call PrintAttackOrPkmnPowerInformation
	pop hl
;	fallthrough

; prints, if non-null, the description of the Trainer card, Energy card, attack,
; or Pokemon Power, given as a pointer to text ID in hl, starting at coordinates 1,11
; preserves bc
; input:
;	[hl] = text ID for the description to print (2 bytes)
PrintAttackOrNonPokemonCardDescription:
	ld a, [hli]
	or [hl]
	ret z
	dec hl
	lb de, 1, 11
	jp PrintAttackOrCardDescription


; input:
;	[wLoadedCard1] = all of the Pokémon's data (card_data_struct)
DisplayCardPage_PokemonDescription:
	; print surrounding box, card name at 5,1, type, set 2, and rarity
	call PrintPokemonCardPageGenericInformation
	; print "LENGTH", "WEIGHT", "Lv", and "HP" where it corresponds in the page
	ld hl, CardPageLengthWeightTextData
	call PlaceTextItems
	ld hl, CardPageLvHPTextData
	call PlaceTextItems
	; draw the card symbol associated to its TYPE_* at 3,2
	lb de, 3, 2
	call DrawCardSymbol
	; print the Level and HP numbers at 12,2 and 16,2 respectively
	lb bc, 12, 2
	ld a, [wLoadedCard1Level]
	call WriteTwoDigitNumberInTxSymbolFormat_TrimLeadingZero
	lb bc, 16, 2
	ld a, [wLoadedCard1HP]
	call WriteOneByteNumberInTxSymbolFormat_TrimLeadingZeros
	; print the Pokemon's category at 1,10 (just above the length and weight texts)
	lb de, 1, 10
	ld hl, wLoadedCard1Category
	call InitTextPrinting_ProcessTextFromPointerToID
	ld a, TX_KATAKANA
	call ProcessSpecialTextCharacter
	ldtx hl, PokemonText
	call ProcessTextFromID
	; print the length and weight values at 5,11 and 5,12 respectively
	lb bc, 5, 11
	ld hl, wLoadedCard1Length
	ld a, [hli]
	ld l, [hl]
	ld h, a
	call PrintPokemonCardLength
	lb bc, 5, 12
	ld hl, wLoadedCard1Weight
	ld a, [hli]
	ld h, [hl]
	ld l, a
	call PrintPokemonCardWeight
	ldtx hl, LbsText
	call InitTextPrinting_ProcessTextFromID
	; print the card's description without line separation
	ld a, SINGLE_SPACED
	ld [wLineSeparation], a
	ld hl, wLoadedCard1Description
	ld a, [hli]
	ld h, [hl]
	ld l, a
	call CountLinesOfTextFromID
	lb de, 1, 13
	cp 4
	jr nc, .print_description
	inc e ; move a line down, as the description is short enough to fit in three lines
.print_description
	ld a, 19 ; line length
	call InitTextPrintingInTextbox
	ld hl, wLoadedCard1Description
	call ProcessTextFromPointerToID
	xor a ; DOUBLE_SPACED
	ld [wLineSeparation], a
	ret

CardPageLengthWeightTextData:
	textitem 1, 11, LengthText
	textitem 1, 12, WeightText
	db $ff


; input:
;	[wLoadedCard1] = all of the Trainer card's data (card_data_struct)
DisplayCardPage_TrainerPage1:
	xor a ; HEADER_TRAINER
	ld hl, wLoadedCard1NonPokemonDescription
	call DisplayEnergyOrTrainerCardPage
	ld hl, wLoadedCard1NonPokemonDescription + 2
	jp PrintDownArrowIfSecondDescriptionPage


; input:
;	[wLoadedCard1] = all of the Trainer card's data (card_data_struct)
DisplayCardPage_TrainerPage2:
	xor a ; HEADER_TRAINER
	ld hl, wLoadedCard1NonPokemonDescription + 2
	call DisplayEnergyOrTrainerCardPage
	jp PrintUpArrowOnSecondDescriptionPage


; input:
;	[wLoadedCard1] = all of the Energy card's data (card_data_struct)
DisplayCardPage_Energy:
	ld a, HEADER_ENERGY
	ld hl, wLoadedCard1NonPokemonDescription
;	fallthrough

; input:
;	a = HEADER_* constant
;	[hl] = text ID for the card's description (2 bytes)
;	[wLoadedCard1] = all of the card's data (card_data_struct)
DisplayEnergyOrTrainerCardPage:
	push hl
	call LoadCardTypeHeaderTiles
	; draw surrounding box
	lb de, 0, 0
	lb bc, 20, 18
	call DrawRegularTextBox
	; print the card's name at 4,3
	lb de, 4, 3
	ld hl, wLoadedCard1Name
	call InitTextPrinting_ProcessTextFromPointerToID
	; colorize the card image
	lb de, 6, 4
	call ApplyBGP6OrSGB3ToCardImage
	; display the card type header
	ld a, $e0
	lb hl, 1, 8
	lb de, 6, 1
	lb bc, 8, 2
	call FillRectangle
	; print the set 2 icon and rarity symbol of the card
	call DrawCardPageSet2AndRarityIcons
	pop hl
	jp PrintAttackOrNonPokemonCardDescription


; draws a large picture of the card loaded in wLoadedCard1, including its image
; and a header indicating the type of card (TRAINER, ENERGY, PoKéMoN)
; input:
;	[wLoadedCard1] = all of the card's data (card_data_struct)
DrawLargePictureOfCard:
	call ZeroObjectPositionsAndToggleOAMCopy
	call EmptyScreen
	call LoadSymbolsFont
	call SetDefaultConsolePalettes
	ld a, LARGE_CARD_PICTURE
	ld [wDuelDisplayedScreen], a
	call LoadCardOrDuelMenuBorderTiles
	ld e, HEADER_TRAINER
	ld a, [wLoadedCard1Type]
	cp TYPE_TRAINER
	jr z, .draw
	ld e, HEADER_ENERGY
	and TYPE_ENERGY
	jr nz, .draw
	ld e, HEADER_POKEMON
.draw
	ld a, e
	call LoadCardTypeHeaderTiles
	ld de, v0Tiles1 + $20 tiles
	call LoadLoaded1CardGfx
	call SetBGP6OrSGB3ToCardPalette
	call FlushAllPalettesOrSendPal23Packet
	ld hl, LargeCardTileData
	call WriteDataBlocksToBGMap0
	lb de, 6, 3
	jp ApplyBGP6OrSGB3ToCardImage

LargeCardTileData:
	db  5,  0, $d0, $d4, $d4, $d4, $d4, $d4, $d4, $d4, $d4, $d1, 0 ; top border
	db  5,  1, $d6, $e0, $e1, $e2, $e3, $e4, $e5, $e6, $e7, $d7, 0 ; header top
	db  5,  2, $d6, $e8, $e9, $ea, $eb, $ec, $ed, $ee, $ef, $d7, 0 ; header bottom
	db  5,  3, $d6, $a0, $a6, $ac, $b2, $b8, $be, $c4, $ca, $d7, 0 ; image
	db  5,  4, $d6, $a1, $a7, $ad, $b3, $b9, $bf, $c5, $cb, $d7, 0 ; image
	db  5,  5, $d6, $a2, $a8, $ae, $b4, $ba, $c0, $c6, $cc, $d7, 0 ; image
	db  5,  6, $d6, $a3, $a9, $af, $b5, $bb, $c1, $c7, $cd, $d7, 0 ; image
	db  5,  7, $d6, $a4, $aa, $b0, $b6, $bc, $c2, $c8, $ce, $d7, 0 ; image
	db  5,  8, $d6, $a5, $ab, $b1, $b7, $bd, $c3, $c9, $cf, $d7, 0 ; image
	db  5,  9, $d6, 0                                              ; empty line 1 (left)
	db 14,  9, $d7, 0                                              ; empty line 1 (right)
	db  5, 10, $d6, 0                                              ; empty line 2 (left)
	db 14, 10, $d7, 0                                              ; empty line 2 (right)
	db  5, 11, $d2, $d5, $d5, $d5, $d5, $d5, $d5, $d5, $d5, $d3, 0 ; bottom border
	db $ff


; given a number in hl, print it divided by 10 at b,c, with decimal part
; separated by a dot (unless it's 0). used to print a Pokemon card's weight.
; input:
;	bc = screen coordinates at which to begin printing the Pokemon's weight
;	hl = Pokemon's weight *10
; output:
;	de = screen coordinates for the tile after the printed weight
PrintPokemonCardWeight:
	push bc
	ld de, -1
	ld bc, -10
.divide_by_10_loop
	inc de
	add hl, bc
	jr c, .divide_by_10_loop
	ld bc, 10
	add hl, bc
	pop bc
	push hl
	push bc
	ld l, e
	ld h, d
	call TwoByteNumberToTxSymbol_TrimLeadingZeros
	pop bc
	pop hl
	ld a, l
	ld hl, wStringBuffer + 5
	or a
	jr z, .decimal_done
	ld [hl], SYM_DOT
	inc hl
	add SYM_0
	ld [hli], a
.decimal_done
	ld [hl], TX_END
	push bc
	call BCCoordToBGMap0Address
	ld hl, wStringBuffer
.find_first_digit_loop
	ld a, [hli]
	or a
	jr z, .find_first_digit_loop
	dec hl
	push hl
	ld b, -1
.get_number_length_loop
	inc b
	ld a, [hli]
	or a
	jr nz, .get_number_length_loop
	pop hl
	push bc
	call SafeCopyDataHLtoDE
	pop bc
	pop de
	ld a, b
	add d
	ld d, a
	ret


; given a number in h and another in l, print them formatted as <l>'<h>" at b,c.
; used to print the length (feet and inches) of a Pokemon card.
; input:
;	bc = screen coordinates at which to begin printing the Pokemon's height
;	l = number of feet in the Pokemon's height
;	h = number of additional inches in the Pokemon's height
PrintPokemonCardLength:
	push hl
	ld l, h
	ld h, $00
	ldtx de, FeetText ; '
	call .print_feet_or_inches
	pop hl
	ld h, $00
	ldtx de, InchesText ; "
	; fallthrough

.print_feet_or_inches
; keep track how many digits each number consists of in wPokemonLengthPrintOffset,
; in order to align the rest of the string. the text with ID at de is printed after the number.
	push de
	push bc
	call TwoByteNumberToTxSymbol_TrimLeadingZeros
	ld a, b ; number of digits in the number (discounting any leading zeros)
	inc a
	ld [wPokemonLengthPrintOffset], a
	pop bc
	call CopyDataToBGMap0
	ld a, [wPokemonLengthPrintOffset]
	add b
	ld b, a
	pop hl
	ld e, c
	ld d, b
	call InitTextPrinting_ProcessTextFromID
	inc b
	ret


OpenPlayAreaScreenForViewing:
	ld a, PAD_START + PAD_A
	jr DisplayPlayAreaScreen

InitVarsAndOpenPlayAreaScreenForSelection_OnlyBench:
	call InitPlayAreaScreenVars_OnlyBench
	jr OpenPlayAreaScreenForSelection

InitVarsAndOpenPlayAreaScreenForSelection:
	call InitPlayAreaScreenVars
;	fallthrough

OpenPlayAreaScreenForSelection:
	ld a, PAD_START
;	fallthrough

; input:
;	a = which buttons open the card page directly, without an item selection menu
; output:
;	a = chosen Pokemon's play area location offset (PLAY_AREA_* constant)
;	carry = set:  if the B button was pressed to exit the Play Area screen
;	[hCurMenuItem] = same as register a
;	[hTempPlayAreaLocation_ff9d] = same as register a
DisplayPlayAreaScreen:
	ld [wNoItemSelectionMenuKeys], a
	ldh a, [hTempCardIndex_ff98]
	push af
	ld a, [wPlayAreaScreenLoaded]
	or a
	jr nz, .start_selection
	ld [wSelectedDuelSubMenuItem], a ; 0
	inc a ; 1 (TRUE)
	ld [wPlayAreaScreenLoaded], a
.reload_screen
	call ZeroObjectPositionsAndToggleOAMCopy
	call EmptyScreen
	call LoadDuelCardSymbolTiles
	call LoadDuelCheckPokemonScreenTiles
	call PrintPlayAreaCardList
	call EnableLCD
.start_selection
	ld hl, PlayAreaScreenMenuParameters_ActivePokemonIncluded
	ld a, [wExcludeArenaPokemon]
	or a
	jr z, .init_menu_params
	ld hl, PlayAreaScreenMenuParameters_ActivePokemonExcluded
.init_menu_params
	ld a, [wSelectedDuelSubMenuItem]
	call InitializeMenuParameters
	ld a, [wNumPlayAreaItems]
	ld [wNumMenuItems], a
.wait_input
	call DoFrame
	call SelectingBenchPokemonMenu
	jr nc, .use_normal_input
	cp CYCLE_PLAY_AREA_SCREENS
	jp z, .no_carry ; done if using the default SELECT button shortcuts
	pop af
	ldh [hTempCardIndex_ff98], a
	jr OpenPlayAreaScreenForSelection
.use_normal_input
	call HandleMenuInput
	jr nc, .wait_input
	ld a, e
	ld [wSelectedDuelSubMenuItem], a
	ld a, [wExcludeArenaPokemon]
	add e
	ld [wCurPlayAreaSlot], a
	ld a, [wNoItemSelectionMenuKeys]
	ld b, a
	ldh a, [hKeysPressed]
	and b
	jr z, .selection_made
; open card page
	ld a, [wCurPlayAreaSlot]
	add DUELVARS_ARENA_CARD
	get_turn_duelist_var
	cp -1 ; empty play area slot?
	jr z, .reload_screen
	call GetCardIDFromDeckIndex
	call LoadCardDataToBuffer1_FromCardID
	call OpenCardPage_FromCheckPlayArea
	jr .reload_screen
.selection_made
	ld a, [wExcludeArenaPokemon]
	ld c, a
	ldh a, [hCurMenuItem]
	add c
	ldh [hTempPlayAreaLocation_ff9d], a
	ldh a, [hCurMenuItem]
	inc a ; cp -1
	jr z, .set_carry ; exit if the B button was pressed
	ldh a, [hTempPlayAreaLocation_ff9d]
	add DUELVARS_ARENA_CARD_HP
	get_turn_duelist_var
	or a
	jr z, .start_selection ; loop back to the beginning if this Pokémon has 0 HP
.no_carry
	pop af
	ldh [hTempCardIndex_ff98], a
	ldh a, [hTempPlayAreaLocation_ff9d]
	ldh [hCurMenuItem], a
	or a
	ret
.set_carry
	pop af
	ldh [hTempCardIndex_ff98], a
	ldh a, [hTempPlayAreaLocation_ff9d]
	ldh [hCurMenuItem], a
	scf
	ret


PlayAreaScreenMenuParameters_ActivePokemonIncluded:
	db 0, 0 ; cursor x, cursor y
	db 3 ; y displacement between items
	db MAX_PLAY_AREA_POKEMON ; number of items
	db SYM_CURSOR_R ; cursor tile number
	db SYM_SPACE ; tile behind cursor
	dw PlayAreaScreenMenuFunction ; function pointer if non-0

PlayAreaScreenMenuParameters_ActivePokemonExcluded:
	db 0, 3 ; cursor x, cursor y
	db 3 ; y displacement between items
	db MAX_PLAY_AREA_POKEMON ; number of items
	db SYM_CURSOR_R ; cursor tile number
	db SYM_SPACE ; tile behind cursor
	dw PlayAreaScreenMenuFunction ; function pointer if non-0


; preserves all registers except af
; output:
;	carry = set:  if either A, B, or Start were pressed
;	[hCurMenuItem] = -1:  if the B button was pressed
PlayAreaScreenMenuFunction:
	ldh a, [hKeysPressed]
	and PAD_A | PAD_B | PAD_START
	ret z
	bit B_PAD_B, a
	jr z, .start_or_a
	ld a, -1
	ldh [hCurMenuItem], a
.start_or_a
	scf
	ret


; handles input upon pressing SELECT during a forced switch,
; usually after one of the Player's Pokémon has been Knocked Out.
; output:
;	carry = set:  if this screen was opened with the SELECT duel shortcut
;	              and the Player pressed the SELECT button again
SelectingBenchPokemonMenu:
	ldh a, [hKeysPressed]
	and PAD_SELECT
	ret z ; return if the SELECT button wasn't pressed
	ld a, [wPlayAreaSelectAction]
	or a
	ret z ; return if pressing SELECT does nothing
	cp CYCLE_PLAY_AREA_SCREENS
	jr z, .return_carry
	; must be FORCED_SWITCH_CHECK_MENU
	xor a
	ld [wCurrentDuelMenuItem], a
.open_submenu
	call DrawDuelMainScene
	ldtx hl, SelectingBenchPokemonHandExamineBackText
	call DrawWideTextBox_PrintTextNoDelay
	call .InitMenu
.loop_input
	call DoFrame
	ldh a, [hKeysPressed]
	and PAD_A
	jr nz, .a_pressed
	call .HandleInput
	call RefreshMenuCursor
	xor a
	call HandleSpecialDuelMainSceneHotkeys
	jr nc, .loop_input
	ldh a, [hKeysPressed]
	and PAD_SELECT
	jr z, .open_submenu
.back
	call InitPlayAreaScreenVars_OnlyBench
	inc a ; $00 -> $01
	ld [hl], a ; wPlayAreaSelectAction = FORCED_SWITCH_CHECK_MENU
.return_carry
	scf
	ret

.a_pressed
	ld a, [wCurrentDuelMenuItem]
	cp 2
	jr z, .back
	or a
	jr z, .check_hand
; examine
	call OpenDuelCheckMenu
	jr .open_submenu
.check_hand
	call OpenTurnHolderHandScreen_Simple
	jr .open_submenu

.HandleInput:
	ldh a, [hDPadHeld]
	bit B_PAD_B, a
	ret nz
	and PAD_RIGHT | PAD_LEFT
	ret z

	; right or left d-pad pressed
	ld b, a
	ld a, [wCurrentDuelMenuItem]
	bit B_PAD_LEFT, b
	jr z, .right_pressed
	dec a
	bit 7, a
	jr z, .got_menu_item
	ld a, 2
	jr .got_menu_item
.right_pressed
	inc a
	cp 3
	jr c, .got_menu_item
	xor a
.got_menu_item
	ld [wCurrentDuelMenuItem], a
	call EraseCursor
	; fallthrough

.InitMenu:
	ld a, [wCurrentDuelMenuItem]
	ld d, a
	add a
	add d
	add a
	add 2
	; a = wCurrentDuelMenuItem * 6 + 2 (either 2, 8, or 14)
	ld d, a ; cursor x coordinate
	ld e, 16 ; cursor y coordinate
	lb bc, SYM_CURSOR_R, SYM_SPACE
	jp SetCursorParametersForTextBox


; for each of the turn holder's play area Pokemon, prints its name, level,
; face down stage icon, type/color symbol, Special Conditions symbols (if any),
; PlusPower/Defender symbols (if any), attached Energy symbols (if any), and HP.
; also prints the play area locations (ACT/BPx indicators) for each of the six slots.
; output:
;	a = number of play area slots that were printed (out of 6)
PrintPlayAreaCardList_EnableLCD:
	call PrintPlayAreaCardList
	call EnableLCD
	ld a, [wNumPlayAreaItems]
	ret


; for each of the turn holder's play area Pokemon, prints its name, level,
; face down stage icon, type/color symbol, Special Condition symbol(s) (if any),
; PlusPower/Defender symbol(s) (if any), attached Energy symbol(s) (if any), and HP.
; also prints the play area locations (ACT/BPx indicators) for each of the six slots.
; output:
;	[wNumPlayAreaItems] = number of play area slots that were printed (out of 6)
PrintPlayAreaCardList:
	ld a, PLAY_AREA_CARD_LIST
	ld [wDuelDisplayedScreen], a
	ld de, wDuelTempList
	call SetListPointer
	ld a, DUELVARS_NUMBER_OF_POKEMON_IN_PLAY_AREA
	get_turn_duelist_var
	ld c, a
	ld b, PLAY_AREA_ARENA
.print_cards_info_loop
	; for each Pokemon in the play area, print its information (and location)
	push bc
	ld a, b
	ld hl, wCurPlayAreaSlot
	ld [hli], a
	add a ; *2
	add b ; *3
	ld [hl], a ; wCurPlayAreaY = wCurPlayAreaSlot * 3
	ld a, b
	add DUELVARS_ARENA_CARD
	get_turn_duelist_var
	call SetNextElementOfList
	call PrintPlayAreaCardInformationAndLocation
	pop bc
	inc b
	dec c
	jr nz, .print_cards_info_loop
	push bc
.print_locations_loop
	; print all play area location indicators (even if there's no Pokemon card on it)
	ld a, b
	cp MAX_PLAY_AREA_POKEMON
	jr z, .locations_printed
	ld hl, wCurPlayAreaSlot
	ld [hli], a
	add a ; *2
	add b ; *3
	ld [hl], a ; wCurPlayAreaY = wCurPlayAreaSlot * 3
	push bc
	call PrintPlayAreaCardLocation
	pop bc
	inc b
	jr .print_locations_loop
.locations_printed
	pop bc
	ld a, b
	ld [wNumPlayAreaItems], a
	ld a, [wExcludeArenaPokemon]
	or a
	ret z
	; if wExcludeArenaPokemon is set, decrement [wNumPlayAreaItems] and shift back wDuelTempList
	dec b
	ld a, b
	ld [wNumPlayAreaItems], a
	ld hl, wDuelTempList + 1
	ld de, wDuelTempList
	jp CopyNBytesFromHLToDE



; input:
;	[hTempPlayAreaLocation_ff9d] = play area location offset (PLAY_AREA_* constant)
InitAndPrintPlayAreaCardInformationAndLocation_WithTextBox:
	call InitAndPrintPlayAreaCardInformationAndLocation
	ld a, [wCurPlayAreaY]
	ld e, a
	ld d, 0
	jp SetCursorParametersForTextBox_Default


; input:
;	[hTempPlayAreaLocation_ff9d] = play area location offset (PLAY_AREA_* constant)
InitAndPrintPlayAreaCardInformationAndLocation:
	ld hl, wCurPlayAreaSlot
	ldh a, [hTempPlayAreaLocation_ff9d]
	ld [hli], a
	ld c, a
	add a ; *2
	add c ; *3
	ld [hl], a ; wCurPlayAreaY = wCurPlayAreaSlot * 3
;	fallthrough

; prints a turn holder's play area Pokemon's name, level, face down stage icon,
; type/color symbol, Special Condition symbol(s) (if any), PlusPower/Defender symbol(s) (if any),
; attached Energy symbol(s) (if any), HP bar, and the play area location (ACT/BPx indicator).
; total space occupied is a rectangle of 20x3 tiles.
; input:
;	[wCurPlayAreaSlot] = Pokemon's play area location offset (PLAY_AREA_* constant)
;	[wCurPlayAreaY] = Y coordinate to use when printing the Pokemon's information
PrintPlayAreaCardInformationAndLocation:
	ld a, [wCurPlayAreaSlot]
	add DUELVARS_ARENA_CARD
	get_turn_duelist_var
	inc a ; cp -1 (empty play area slot?)
	ret z ; return if there's no Pokémon in that location
	call PrintPlayAreaCardInformation
;	fallthrough

;  prints a turn holder's play area Pokemon's location (ACT/BPx indicator)
PrintPlayAreaCardLocation:
	; print the ACT/BPx indicator
	ld a, [wCurPlayAreaSlot]
	add a ; *2
	add a ; *4
	ld e, a
	ld d, $00
	ld hl, PlayAreaLocationTileNumbers
	add hl, de
	ldh a, [hWhoseTurn]
	cp PLAYER_TURN
	jr z, .write_tiles
	; move forward to the opponent's side tile numbers
	; they have black letters and white background instead of the other way around
	ld d, $0a
.write_tiles
	ld a, [wCurPlayAreaY]
	ld b, 1
	ld c, a
	ld a, [hli]
	add d
	call WriteByteToBGMap0
	inc c
	ld a, [hli]
	add d
	call WriteByteToBGMap0
	inc c
	ld a, [hli]
	add d
	jp WriteByteToBGMap0

PlayAreaLocationTileNumbers:
	db $e0, $e1, $e2, $00 ; ACT
	db $e3, $e4, $e5, $00 ; BP1
	db $e3, $e4, $e6, $00 ; BP2
	db $e3, $e4, $e7, $00 ; BP3
	db $e3, $e4, $e8, $00 ; BP4
	db $e3, $e4, $e9, $00 ; BP5


; prints a turn holder's play area Pokemon's name, level, face down stage icon,
; type/color symbol, Special Condition symbol(s) (if any), PlusPower/Defender symbol(s) (if any),
; attached Energy symbol(s) (if any), and HP bar.
; total space occupied is a rectangle of 20x3 tiles.
; input:
;	[wCurPlayAreaSlot] = Pokemon's play area location offset (PLAY_AREA_* constant)
;	[wCurPlayAreaY] = Y coordinate to use when printing the Pokemon's information
PrintPlayAreaCardInformation:
	; print name, level, color, stage, status, pluspower/defender
	call PrintPlayAreaCardHeader
	; print the symbols of the attached energies
	ld a, [wCurPlayAreaSlot]
	ld e, a
	ld a, [wCurPlayAreaY]
	inc a
	ld c, a
	ld b, 7
	ld a, 10 ; maximum number of symbols to print
	call PrintPlayAreaCardAttachedEnergies
	ld a, [wCurPlayAreaY]
	inc a
	ld e, a
	ld d, 5
	ldtx hl, ESymbolText
	call InitTextPrinting_ProcessTextFromID
	; print HP as #/# (current HP/max HP)
	inc e
	ldtx hl, HPSymbolText
	call InitTextPrinting_ProcessTextFromID
	ld b, 7
	ld c, e
	ld a, [wCurPlayAreaSlot]
;	fallthrough

; prints a Pokémon's HP as "#/#" (current HP value/maximum HP value).
; adjusts printing to account for either 2- or 3-digit HP values.
; if Pokémon has 0 HP, then prints "Knocked Out" instead.
; preserves c
; input:
;	a  = Pokémon's play area location offset (PLAY_AREA_* constant)
;	bc = screen coordinates at which to begin printing the given Pokémon's HP
; output:
;	[wLoadedCard1] = all of the Pokémon's card data (card_data_struct)
PrintCurrentAndMaxHP:
	ld e, a
	add DUELVARS_ARENA_CARD
	get_turn_duelist_var
	call LoadCardDataToBuffer1_FromDeckIndex
	ld a, e
	add DUELVARS_ARENA_CARD_HP
	get_turn_duelist_var
	or a
	jr z, .zero_hp
	cp 100
	push af
	jr nc, .current_hp_is_three_digits
	; current hp is 2 digits
	call WriteTwoDigitNumberInTxSymbolFormat_TrimLeadingZero
	jr .next
.current_hp_is_three_digits
	call WriteOneByteNumberInTxSymbolFormat_TrimLeadingZeros
	inc b
.next
	inc b
	inc b
	ld a, [wLoadedCard1HP]
	cp 100
	jr c, .max_hp_is_two_digits
	; max hp is 3 digits
	ld d, a
	ld a, SYM_SLASH
	call WriteByteToBGMap0
	inc b
	ld a, d    
	call WriteOneByteNumberInTxSymbolFormat_TrimLeadingZeros
	pop af
	ret nc ; return if the current HP value still uses 3 digits
	; Pokémon's current HP is now only 2 digits,
	; so make sure any previously printed final digit gets erased.
	inc b
	inc b
	inc b
	xor a ; SYM_SPACE
	jp WriteByteToBGMap0
.max_hp_is_two_digits
	call WriteOneByteNumberInTxSymbolFormat_TrimLeadingZeros
	pop af ; discard the stored current HP value before returning
	ld a, SYM_SLASH
	jp WriteByteToBGMap0

; print "Knocked Out" instead of HP numbers if the Pokémon's current HP = 0
.zero_hp
	ld d, b
	ld e, c
	ldtx hl, KnockOutText
	jp InitTextPrinting_ProcessTextFromID


; prints a turn holder's play area Pokemon's name, level, face down stage icon,
; type/color symbol, Special Condition symbol(s) (if any), and PlusPower/Defender symbol(s) (if any).
; input:
;	[wCurPlayAreaSlot] = Pokemon's play area location offset (PLAY_AREA_* constant)
;	[wCurPlayAreaY] = Y coordinate to use when printing the Pokemon's information
PrintPlayAreaCardHeader:
	; start by printing the Pokemon's name
	ld a, [wCurPlayAreaSlot]
	add DUELVARS_ARENA_CARD
	get_turn_duelist_var
	call LoadCardDataToBuffer1_FromDeckIndex
	ld a, [wCurPlayAreaY]
	ld e, a
	ld d, 4
	call InitTextPrinting
	; copy the name to wDefaultText (max. 10 characters)
	; then call ProcessText with hl = wDefaultText
	ld hl, wLoadedCard1Name
	ld a, [hli]
	ld h, [hl]
	ld l, a
	ld de, wDefaultText
	ld a, 10 ; card name maximum length
	call CopyTextData_FromTextID
	ld hl, wDefaultText
	call ProcessText

	; print the Pokemon's type/color and its level
	ld a, [wCurPlayAreaY]
	ld c, a
	ld b, 18
	ld a, [wCurPlayAreaSlot]
	call GetPlayAreaCardColor
	inc a ; Energy text symbol tiles start at 1, not 0
	call WriteByteToBGMap0
	ld b, 15
	ld a, [wLoadedCard1Level]
	call WriteTwoDigitNumberInTxSymbolFormat_TrimLeadingZero
	ld d, 14
	ld e, c
	ldtx hl, LvSymbolText
	call InitTextPrinting_ProcessTextFromID

	; print the 2x2 face down card image depending on the Pokemon's evolution stage
	ld a, [wCurPlayAreaSlot]
	add DUELVARS_ARENA_CARD_STAGE
	get_turn_duelist_var
	add a
	ld e, a
	ld d, $00
	ld hl, FaceDownCardTileNumbers
	add hl, de
	ld a, [hli] ; starting tile to fill the 2x2 rectangle with
	push hl
	push af
	lb hl, 1, 2
	lb bc, 2, 2
	ld a, [wCurPlayAreaY]
	ld e, a
	ld d, 2
	pop af
	call FillRectangle
	pop hl
	ld a, [wConsole]
	cp CONSOLE_CGB
	jr nz, .not_cgb
	; in cgb, we have to take care of coloring it too
	ld a, [hl]
	lb hl, 0, 0
	lb bc, 2, 2
	call BankswitchVRAM1
	call FillRectangle
	call BankswitchVRAM0

.not_cgb
	; print the Special Condition symbol(s), if any (only for the Active Pokemon card)
	ld hl, wCurPlayAreaSlot
	ld a, [hli]
	or a
	jr nz, .skip_status
	ld c, [hl] ; wCurPlayAreaY
	inc c
	inc c
	ld b, 2
	ld a, DUELVARS_ARENA_CARD_STATUS
	get_turn_duelist_var
	call CheckPrintCnfSlpPrz
	inc b
	call CheckPrintPoisoned
	inc b
	call CheckPrintDoublePoisoned

.skip_status
	; finally check whether to print the PlusPower and/or Defender symbols
	ld a, [wCurPlayAreaSlot]
	add DUELVARS_ARENA_CARD_ATTACHED_PLUSPOWER
	get_turn_duelist_var
	or a
	jr z, .not_pluspower
	ld a, [wCurPlayAreaY]
	inc a
	ld c, a
	ld b, 17
	ld a, SYM_PLUSPOWER
	call WriteByteToBGMap0
	inc b
	ld a, [hl]
	add SYM_0
	call WriteByteToBGMap0
.not_pluspower
	ld a, [wCurPlayAreaSlot]
	add DUELVARS_ARENA_CARD_ATTACHED_DEFENDER
	get_turn_duelist_var
	or a
	ret z ; return if there are no attached Defender cards
	ld a, [wCurPlayAreaY]
	inc a
	inc a
	ld c, a
	ld b, 17
	ld a, SYM_DEFENDER
	call WriteByteToBGMap0
	inc b
	ld a, [hl]
	add SYM_0
	jp WriteByteToBGMap0

FaceDownCardTileNumbers:
; starting tile number, cgb palette (grey, yellow/red, green/blue, pink/orange)
	db $d0, $02 ; BASIC
	db $d4, $02 ; STAGE1
	db $d8, $01 ; STAGE2
	db $dc, $01 ; STAGE2_WITHOUT_STAGE1


; given a Pokemon's status in a, prints the Poison symbol at bc if it's Poisoned
; preserves all registers
; input:
;	a = Active Pokémon's Special Conditions status (from DUELVARS_ARENA_CARD_STATUS)
;	bc = screen coordinates for printing the Poisoned symbol
CheckPrintPoisoned:
	push af
	and POISONED
	jr z, .print ; use SYM_SPACE
.poison
	ld a, SYM_POISONED
.print
	call WriteByteToBGMap0
	pop af
	ret


; given a Pokemon's status in a, prints the Poison symbol at bc if it's double poisoned
; preserves all registers
; input:
;	a = Active Pokémon's Special Conditions status (from DUELVARS_ARENA_CARD_STATUS)
;	bc = screen coordinates for printing the Poisoned symbol
CheckPrintDoublePoisoned:
	push af
	and DOUBLE_POISONED & (POISONED ^ $ff)
	jr nz, CheckPrintPoisoned.poison ; double poisoned (print SYM_POISONED)
	jr CheckPrintPoisoned.print ; not double poisoned (print SYM_SPACE)


; given a Pokemon's status in a, prints the corresponding symbol at bc
; if it's Confused, Asleep, or Paralyzed
; preserves all registers
; input:
;	a = Active Pokémon's Special Conditions status (from DUELVARS_ARENA_CARD_STATUS)
;	bc = screen coordinates for printing any symbols
CheckPrintCnfSlpPrz:
	push af
	and CNF_SLP_PRZ
	jr z, .print ; use SYM_SPACE if Active Pokémon isn't Asleep, Confused, or Paralyzed
	add SYM_POISONED
.print
	call WriteByteToBGMap0
	pop af
	ret


; prints the symbols of any Energy attached to a turn holder's Pokémon in the play area.
; always prints a number of symbols equal to the maximum value from a input.
; if amount of Energy is less than this maximum, then the remaining tiles are blank.
; if amount of Energy is more than this maximum, then the final symbol is replaced with a "+".
; input:
;	a  = maximum number of symbols to print (ath symbol is replaced with "+" if max is exceeded)
;	bc = screen coordinates at which to begin printing the Energy symbols
;	e  = Pokémon's play area location offset (PLAY_AREA_* constant)
PrintPlayAreaCardAttachedEnergies:
	push bc
	ld hl, wDefaultText
	ld [hli], a ; store maximum in wDefaultText
	push hl
	ld c, a
	call GetPlayAreaCardAttachedEnergies
	ld b, a ; wTotalAttachedEnergies
	; clear bytes from wDefaultText + 1 equal to the maximum value from a input
	xor a ; SYM_SPACE
.empty_loop
	ld [hli], a
	dec c
	jr nz, .empty_loop
	ld a, [wDefaultText]
	cp b
	jr nc, .get_symbols ; skip adding "+" if amount of Energy doesn't exceed max value from a input
	dec hl
	ld [hl], SYM_PLUS ; replace the last symbol with a "+"
.get_symbols
	pop hl ; wDefaultText + 1
	ld e, LOW(wAttachedEnergies)
	lb bc, SYM_FIRE, NUM_TYPES - 1
.next_color
	ld d, HIGH(wAttachedEnergies)
	ld a, [de] ; Energy count for the current type/color
	ld d, a
	inc e
	inc d
	jr .check_amount
.has_energy
	ld [hl], b
	inc hl
	ld a, SYM_PLUS
	cp [hl]
	jr z, .place_tiles
.check_amount
	dec d
	jr nz, .has_energy
	inc b
	dec c
	jr nz, .next_color
.place_tiles
	pop bc
	call BCCoordToBGMap0Address
	ld hl, wDefaultText
	ld a, [hli]
	ld b, a ; print a number of symbols equal to the original input in a
	jp SafeCopyDataHLtoDE


; output:
;	carry = set:  if the Player used the B button to exit the screen
;	[hTemp_ffa0] = deck index of the Pokémon with the Pokémon Power being used, if one was selected (0-59)
DisplayPlayAreaScreenToUsePkmnPower:
	xor a
	ld [wSelectedDuelSubMenuItem], a

.start
	call .DrawScreen
	ld hl, PlayAreaScreenMenuParameters_ActivePokemonIncluded
	ld a, [wSelectedDuelSubMenuItem]
	call InitializeMenuParameters
	ld a, [wNumPlayAreaItems]
	ld [wNumMenuItems], a
.loop_input
	call DoFrame
	call HandleMenuInput
	ldh [hTempPlayAreaLocation_ff9d], a
	ld [wHUDEnergyAndHPBarsX], a
	jr nc, .loop_input
	cp -1
	scf
	ret z ; return carry if the B button was pressed
	; A or START button were pressed
	ld [wSelectedDuelSubMenuItem], a
	ldh a, [hKeysPressed]
	and PAD_START
	jr nz, .open_card_page
	ldh a, [hCurMenuItem]
	add a
	ld e, a
	ld d, $00
	ld hl, wDuelTempList + 1
	add hl, de
	ld a, [hld]
	cp POKEMON_POWER
	jr nz, .loop_input
	; selected Pokémon has a Pokémon Power
	ld a, [hl]
	ldh [hTempCardIndex_ff98], a
	ld d, a
	ld e, FIRST_ATTACK_OR_PKMN_POWER
	call CopyAttackDataAndDamage_FromDeckIndex
	call DisplayUsePokemonPowerScreen
	ld a, EFFECTCMDTYPE_INITIAL_EFFECT_1
	call TryExecuteEffectCommandFunction
	jr nc, .power_can_be_used
	ldtx hl, PokemonPowerSelectNotRequiredText
	call DrawWideTextBox_WaitForInput
	jr .start

.power_can_be_used
	ldtx hl, UseThisPokemonPowerText
	call YesOrNoMenuWithText
	jr c, .start ; loop back to the beginning if "No" was selected
	ldh a, [hTempCardIndex_ff98]
	ldh [hTemp_ffa0], a
	or a
	ret

.open_card_page
	ldh a, [hCurMenuItem]
	add DUELVARS_ARENA_CARD
	get_turn_duelist_var
	call GetCardIDFromDeckIndex
	call LoadCardDataToBuffer1_FromCardID
	call OpenCardPage_FromCheckPlayArea
	jr .start

; output:
;	wDuelTempList = list with play area Pokémon info (format: <deck index>, <attack category>)
.DrawScreen:
	call ZeroObjectPositionsAndToggleOAMCopy
	call EmptyScreen
	call LoadDuelCardSymbolTiles
	call LoadDuelCheckPokemonScreenTiles
	ld de, wDuelTempList
	call SetListPointer
	ld a, DUELVARS_NUMBER_OF_POKEMON_IN_PLAY_AREA
	get_turn_duelist_var
	ld c, a
	ld b, PLAY_AREA_ARENA
.loop_play_area
	push hl
	push bc
	ld a, b
	ld [wHUDEnergyAndHPBarsX], a
	add a
	add b
	ld [wCurPlayAreaY], a
	ld a, b
	add DUELVARS_ARENA_CARD
	get_turn_duelist_var
	call SetNextElementOfList
	; print Pokémon's name, level, type, stage, status, pluspower/defender
	call PrintPlayAreaCardHeader
	; print the ACT/BPx indicator
	call PrintPlayAreaCardLocation
	; print name of Pokémon Power (if any power exists)
	ld a, [wLoadedCard1Atk1Category]
	cp POKEMON_POWER
	jr nz, .next ; skip printing name if this Pokémon doesn't have a Pokémon Power
	ld a, [wCurPlayAreaY]
	inc a
	ld e, a
	ld d, 4
	ld hl, wLoadedCard1Atk1Name
	call InitTextPrinting_ProcessTextFromPointerToID
.next
	ld a, [wLoadedCard1Atk1Category]
	call SetNextElementOfList
	pop bc
	pop hl
	inc b
	dec c
	jr nz, .loop_play_area
	ld a, b
	ld [wNumPlayAreaItems], a
	jp EnableLCD


; displays the screen that prompts the player to use the selected card's Pokemon Power.
; includes the card's information above, and the Pokemon Power's description below.
; input:
;	[hTempPlayAreaLocation_ff9d] = Pokemon's play area location offset (PLAY_AREA_* constant)
DisplayUsePokemonPowerScreen::
	ldh a, [hTempPlayAreaLocation_ff9d]
	ld hl, wCurPlayAreaSlot
	ld [hli], a
	ld [hl], 0 ; wCurPlayAreaY
	call ZeroObjectPositionsAndToggleOAMCopy
	call EmptyScreen
	call LoadDuelCardSymbolTiles
	call LoadDuelCheckPokemonScreenTiles
	call PrintPlayAreaCardInformationAndLocation
	lb de, 1, 4
	ld hl, wLoadedCard1Atk1Name
	call InitTextPrinting_ProcessTextFromPointerToID
	lb de, 1, 6
	ld hl, wLoadedCard1Atk1Description
;	fallthrough

; prints the description of an attack, a Pokemon Power, or a Trainer or Energy card
; without separating the lines of text with an empty line
; preserves bc
; input:
;	de = screen coordinates at which to start printing the text
;	[hl] = text ID for the description to print (2 bytes)
PrintAttackOrCardDescription:
	ld a, SINGLE_SPACED
	ld [wLineSeparation], a
	ld a, [hli]
	ld h, [hl]
	ld l, a
	call CountLinesOfTextFromID
	cp 7
	jr c, .print
	dec e ; move one line up to fit (assumes it will be enough)
.print
	ld a, 19
	call InitTextPrintingInTextbox
	call ProcessTextFromID
	xor a ; DOUBLE_SPACED
	ld [wLineSeparation], a
	ret


; when an opponent's Pokemon attacks, this displays a screen
; containing the description and information of the used attack
; input:
;	[wLoadedAttack] = Attacking Pokémon card's attack data (atk_data_struct)
;	[wTempCardID_ccc2] = Attacking Pokémon's card ID
DisplayOpponentUsedAttackScreen:
	call ZeroObjectPositionsAndToggleOAMCopy
	call EmptyScreen
	call LoadDuelCardSymbolTiles
	call LoadDuelFaceDownCardTiles
	ld a, [wTempCardID_ccc2]
	ld e, a
	call LoadCardDataToBuffer1_FromCardID
	ld a, CARDPAGE_POKEMON_OVERVIEW
	ld [wCardPageNumber], a
	ld e, 1
	ld hl, wLoadedAttackName
	call PrintAttackOrPkmnPowerInformation
	lb de, 1, 4
	ld hl, wLoadedAttackDescription
	jr PrintAttackOrCardDescription


; prints the name and description of a Trainer card, along with the
; "Used xxx" text in a text box. this function is used to show the player
; the information of a Trainer card being used by the opponent.
; input:
;	[wLoadedCard1] = all of the Trainer card's data (card_data_struct)
PrintUsedTrainerCardDescription:
	call EmptyScreen
	ld a, SINGLE_SPACED
	ld [wLineSeparation], a
	lb de, 1, 1
	ld hl, wLoadedCard1Name
	call InitTextPrinting_ProcessTextFromPointerToID
	ld a, 19
	lb de, 1, 3
	call InitTextPrintingInTextbox
	ld hl, wLoadedCard1NonPokemonDescription
	call ProcessTextFromPointerToID
	xor a ; DOUBLE_SPACED
	ld [wLineSeparation], a
	ldtx hl, UsedText
	jp DrawWideTextBox_WaitForInput


; saves the current duel state to SRAM.
; called between each two-player turn, just after player draws card (ROM bank 1 loaded)
SaveDuelStateToSRAM:
	ld a, $2
	call BankswitchSRAM
	; save duel data to sCurrentDuel
	call SaveDuelData
	xor a
	call BankswitchSRAM
	call EnableSRAM
	ld hl, s0a008
	ld a, [hl]
	inc [hl]
	call DisableSRAM
	; select hl = SRAM3:(a000 + $400 * [s0a008] & $3)
	; save wDuelTurns, non-turn holder's arena card ID, turn holder's arena card ID
	and $3
	add HIGH($a000) / 4
	ld l, $0
	ld h, a
	add hl, hl
	add hl, hl
	ld a, $3
	call BankswitchSRAM
	push hl
	ld a, DUELVARS_ARENA_CARD
	get_turn_duelist_var
	call _GetCardIDFromDeckIndex
	ld [wTempTurnDuelistCardID], a
	rst SwapTurn
	ld a, DUELVARS_ARENA_CARD
	get_turn_duelist_var
	call _GetCardIDFromDeckIndex
	ld [wTempNonTurnDuelistCardID], a
	rst SwapTurn
	pop hl
	push hl
	call EnableSRAM
	ld a, [wDuelTurns]
	ld [hli], a
	ld a, [wTempNonTurnDuelistCardID]
	ld [hli], a
	ld a, [wTempTurnDuelistCardID]
	ld [hli], a
	; save duel data to SRAM3:(a000 + $400 * [s0a008] & $3) + $0010
	pop hl
	ld de, $0010
	add hl, de
	ld e, l
	ld d, h
	call DisableSRAM
	call SaveDuelDataToDE
	xor a
	jp BankswitchSRAM


; saves data for the current duel to sCurrentDuel.
; byte 0 is $01, bytes 1 and 2 are the checksum, byte 3 is [wDuelType],
; and the next $33a bytes come from DuelDataToSave.
SaveDuelData::
;	farcall StubbedUnusedSaveDataValidation
	ld de, sCurrentDuel
;	fallthrough

; saves data for the current duel to de (in SRAM).
; byte 0 is $01, bytes 1 and 2 are the checksum, byte 3 is [wDuelType],
; and the next $33a bytes come from DuelDataToSave.
; input:
;	de = location in SRAM
SaveDuelDataToDE::
	call EnableSRAM
	push de
	inc de
	inc de
	inc de
	inc de
	ld hl, DuelDataToSave
	push de
.save_duel_data_loop
	; start copying data to de = sCurrentDuelData + $1
	ld c, [hl]
	inc hl
	ld b, [hl]
	inc hl
	ld a, c
	or b
	jr z, .data_done
	push hl
	push bc
	ld c, [hl]
	inc hl
	ld b, [hl]
	inc hl
	pop hl
	call CopyDataHLtoDE
	pop hl
	inc hl
	inc hl
	jr .save_duel_data_loop
.data_done
	pop hl
	; save a checksum to hl = sCurrentDuelData + $1
	lb de, $23, $45
	ld bc, $334 ; misses last 6 bytes to calculate checksum
.checksum_loop
	ld a, e
	sub [hl]
	ld e, a
	ld a, [hli]
	xor d
	ld d, a
	dec bc
	ld a, c
	or b
	jr nz, .checksum_loop
	pop hl
	ld a, $01
	ld [hli], a ; sCurrentDuel
	ld [hl], e ; sCurrentDuelChecksum
	inc hl
	ld [hl], d ; sCurrentDuelChecksum
	inc hl
	ld a, [wDuelType]
	ld [hl], a ; sCurrentDuelData
	jp DisableSRAM


; loads current Duel data from SRAM and also general save data
; output:
;	carry = set:  if the save data is not valid
LoadAndValidateDuelSaveData:
	ld hl, sCurrentDuel
	call ValidateSavedDuelData
	ret c
	ld de, sCurrentDuel
	call LoadSavedDuelData

	call ValidateGeneralSaveData
	ret nc
	call LoadGeneralSaveData
	or a
	ret


; loads the data saved in sCurrentDuelData to WRAM according to the distribution
; of DuelDataToSave. assumes saved data exists and that the checksum is valid.
; input:
;	de = sCurrentDuel
LoadSavedDuelData:
	call EnableSRAM
	inc de
	inc de
	inc de
	inc de
	ld hl, DuelDataToSave
.next_block
	ld c, [hl]
	inc hl
	ld b, [hl]
	inc hl
	ld a, c
	or b
	jp z, DisableSRAM ; done
	push hl
	push bc
	ld c, [hl]
	inc hl
	ld b, [hl]
	inc hl
	pop hl
.copy_loop
	ld a, [de]
	inc de
	ld [hli], a
	dec bc
	ld a, c
	or b
	jr nz, .copy_loop
	pop hl
	inc hl
	inc hl
	jr .next_block


DuelDataToSave:
;	dw address, number of bytes to copy
	dw wPlayerDuelVariables,   wOpponentDuelVariables - wPlayerDuelVariables
	dw wOpponentDuelVariables, wPlayerDeck - wOpponentDuelVariables
	dw wPlayerDeck,            wDuelTempList - wPlayerDeck
	dw wWhoseTurn,             wDuelTheme + $1 - wWhoseTurn
	dw hWhoseTurn,             $1
	dw wRNG1,                  wRNGCounter + $1 - wRNG1
	dw wAIDuelVars,            wAIDuelVarsEnd - wAIDuelVars
	dw NULL


; preserves de
; output:
;	carry = set:  if there is no data saved at sCurrentDuel or
;	              if the checksum isn't correct or
;	              if the value saved from wDuelType is DUELTYPE_LINK
ValidateSavedNonLinkDuelData:
	call EnableSRAM
	ld hl, sCurrentDuel
	ld a, [sCurrentDuelData]
	call DisableSRAM
	cp DUELTYPE_LINK
	scf
	ret z ; return carry to ignore any saved data from a link duel
;	fallthrough

; preserves de
; input:
;	hl = sCurrentDuel
; output:
;	carry = set:  if there is no data saved at sCurrentDuel or
;	              if the checksum isn't correct
ValidateSavedDuelData:
	call EnableSRAM
	push de
	ld a, [hli]
	or a
	jr z, .no_saved_data
	lb de, $23, $45
	ld bc, $334
	ld a, [hl]
	sub e
	ld e, a
	inc hl
	ld a, [hl]
	xor d
	ld d, a
	inc hl
	inc hl
.loop
	ld a, [hl]
	add e
	ld e, a
	ld a, [hli]
	xor d
	ld d, a
	dec bc
	ld a, c
	or b
	jr nz, .loop
	ld a, e
	or d
	jr z, .ok
.no_saved_data
	scf
.ok
	pop de
	jp DisableSRAM


; loads a player deck (sDeck*Cards) from SRAM to wPlayerDeck.
; sCurrentlySelectedDeck determines which sDeck*Cards source (0-3).
LoadPlayerDeck:
	call EnableSRAM
	ld a, [sCurrentlySelectedDeck]
	ld l, a
	ld h, sDeck2Cards - sDeck1Cards
	call HtimesL
	ld de, sDeck1Cards
	add hl, de
	ld de, wPlayerDeck
	ld b, DECK_SIZE
	call CopyNBytesFromHLToDE
	jp DisableSRAM


; loads opponent deck at wOpponentDeckID to wOpponentDeck, and initializes wPlayerDuelistType.
; on a duel against Sam, also loads PRACTICE_PLAYER_DECK to wPlayerDeck.
; also, sets wRNG1, wRNG2, and wRNGCounter to $57.
LoadOpponentDeck:
	xor a ; FALSE
	ld [wIsPracticeDuel], a
	ld a, [wOpponentDeckID]
	cp SAMS_NORMAL_DECK_ID
	jr z, .normal_sam_duel
	or a ; cp SAMS_PRACTICE_DECK_ID
	jr nz, .not_practice_duel
; only practice duels will display help messages, but
; any duel with Sam will force the PRACTICE_PLAYER_DECK
;.practice_sam_duel
	inc a ; TRUE
	ld [wIsPracticeDuel], a
.normal_sam_duel
	rst SwapTurn
	ld a, PRACTICE_PLAYER_DECK
	call LoadDeck
	rst SwapTurn
	ld hl, wRNG1
	ld a, $57
	ld [hli], a
	ld [hli], a
	ld [hl], a
	xor a ; SAMS_PRACTICE_DECK
	ld [wOpponentDeckID], a
.not_practice_duel
	inc a
	inc a ; convert from *_DECK_ID constant read from wOpponentDeckID to *_DECK constant
	call LoadDeck
	ld a, [wOpponentDeckID]
	cp NUM_DECK_IDS + 1
	jr c, .valid_deck
	ld a, PRACTICE_PLAYER_DECK_ID
	ld [wOpponentDeckID], a
.valid_deck
; set opponent as controlled by AI
	ld a, DUELVARS_DUELIST_TYPE
	get_turn_duelist_var
	ld a, [wOpponentDeckID]
	or DUELIST_TYPE_AI_OPP
	ld [hl], a
	ret


; handles menu for when player is waiting for
; Link Opponent to make a decision, where it's
; possible to examine the hand or duel main scene
HandleWaitingLinkOpponentMenu:
	ld a, 10
	call DoAFrames
	ld [wCurrentDuelMenuItem], a ; 0
.loop_outer
	ld a, PLAYER_TURN
	ldh [hWhoseTurn], a
	ldtx hl, WaitingHandExamineText
	call DrawWideTextBox_PrintTextNoDelay
	call .InitTextBoxMenu
.loop_inner
	call DoFrame
	call .HandleInput
	call RefreshMenuCursor
	ldh a, [hKeysPressed]
	bit B_PAD_A, a
	jr nz, .a_pressed
	ld a, $01
	call HandleSpecialDuelMainSceneHotkeys
	jr nc, .loop_inner
.duel_main_scene
	call DrawDuelMainScene
	jr .loop_outer
.a_pressed
	ld a, [wCurrentDuelMenuItem]
	or a
	jr z, .open_hand
; duel check
	call OpenDuelCheckMenu
	jr .duel_main_scene
.open_hand
	call OpenTurnHolderHandScreen_Simple
	jr .duel_main_scene

.HandleInput:
	ldh a, [hDPadHeld]
	bit B_PAD_B, a
	ret nz
	and PAD_LEFT | PAD_RIGHT
	ret z
	call EraseCursor
	ld hl, wCurrentDuelMenuItem
	ld a, [hl]
	xor $01
	ld [hl], a

.InitTextBoxMenu:
	ld d, 2
	ld a, [wCurrentDuelMenuItem]
	or a
	jr z, .set_cursor_params
	ld d, 8
.set_cursor_params
	ld e, 16
	lb bc, SYM_CURSOR_R, SYM_SPACE
	jp SetCursorParametersForTextBox


; handles the key shortcuts to access some duel functions
; while inside the Duel Main scene in some situations
; (while waiting for Link Opponent's turn & when
; selecting a Benched Pokémon, and choosing 'Examine')
; hotkeys:
; - Start     = Active Pokemon's card page
; - Select    = if a == 0: In Play Area
;               otherwise: In Play Area then both Play Areas
; - B + down  = player's Play Area
; - B + left  = player's Discard Pile
; - B + up    = opponent's Play Area
; - B + right = opponent's Discard Pile
; output:
;	carry = set:  if a duel shortcut was executed
HandleSpecialDuelMainSceneHotkeys:
	ld [wDuelMainSceneSelectHotkeyAction], a
	ldh a, [hKeysPressed]
	bit B_PAD_START, a
	jr nz, .start_pressed
	bit B_PAD_SELECT, a
	jr nz, .select_pressed
	ldh a, [hKeysHeld]
	and PAD_B
	ret z ; exit if the B button wasn't pressed
	ldh a, [hKeysPressed]
	bit B_PAD_DOWN, a
	jr nz, .down_pressed
	bit B_PAD_LEFT, a
	jr nz, .left_pressed
	bit B_PAD_UP, a
	jr nz, .up_pressed
	bit B_PAD_RIGHT, a
	jr nz, .right_pressed
	or a
	ret
.start_pressed
	ld a, DUELVARS_ARENA_CARD
	get_turn_duelist_var
	cp -1 ; empty play area slot?
	jr z, .return_carry
	call GetCardIDFromDeckIndex
	call LoadCardDataToBuffer1_FromCardID
	ld hl, wCurPlayAreaSlot
	xor a
	ld [hli], a
	ld [hl], a ; wCurPlayAreaY
	call OpenCardPage_FromCheckPlayArea
.return_carry
	scf
	ret
.select_pressed
	ld a, [wDuelMainSceneSelectHotkeyAction]
	or a
	jr nz, .both_duelist_play_areas
	call OpenInPlayAreaScreen_FromSelectButton
	scf
	ret
.both_duelist_play_areas
	call OpenVariousPlayAreaScreens_FromSelectPresses
	scf
	ret
.down_pressed
	call OpenTurnHolderPlayAreaScreen
	scf
	ret
.left_pressed
	call OpenTurnHolderDiscardPileScreen
	scf
	ret
.up_pressed
	call OpenNonTurnHolderPlayAreaScreen
	scf
	ret
.right_pressed
	call OpenNonTurnHolderDiscardPileScreen
	scf
	ret


SetLinkDuelTransmissionFrameFunction:
	call FinishQueuedAnimations
	ld hl, sp+$00
	ld a, l
	ld [wLinkOpponentTurnReturnAddress], a
	ld a, h
	ld [wLinkOpponentTurnReturnAddress + 1], a
	ld hl, wDoFrameFunction
	ld a, LOW(LinkOpponentTurnFrameFunction)
	ld [hli], a
	ld [hl], HIGH(LinkOpponentTurnFrameFunction)
	ret


; prints the notification text after an Energy card is attached to 1 of the turn holder's Pokemon
; input:
;	[hTempCardIndex_ff98] = deck index of the Energy card being attached (0-59)
;	[hTempPlayAreaLocation_ff9d] = target Pokemon's play area location offset (PLAY_AREA_* constant)
PrintAttachedEnergyToPokemon:
	ldh a, [hTempPlayAreaLocation_ff9d]
	add DUELVARS_ARENA_CARD
	get_turn_duelist_var
	call LoadCardNameToTxRam2_b
	ldh a, [hTempCardIndex_ff98]
	call LoadCardNameToTxRam2
	ldtx hl, AttachedEnergyToPokemonText
	jp DrawWideTextBox_WaitForInput


; plays the evolution sound effect and prints the PokemonEvolvedIntoPokemonText
; input:
;	[wPreEvolutionPokemonCard] = deck index of the Pokemon being evolved (0-59)
;	[hTempCardIndex_ff98] = deck index of the new Evolution card (0-59)
PrintPokemonEvolvedIntoPokemon:
	ld a, SFX_POKEMON_EVOLUTION
	call PlaySFX
	ld a, [wPreEvolutionPokemonCard]
	call LoadCardNameToTxRam2
	ldh a, [hTempCardIndex_ff98]
	call LoadCardNameToTxRam2_b
	ldtx hl, PokemonEvolvedIntoPokemonText
	jp DrawWideTextBox_WaitForInput


; handles the opponent's turn in a link duel.
; loops until either [wOpponentTurnEnded] or [wDuelFinished] is non-0.
DoLinkOpponentTurn:
	xor a ; FALSE
	ld [wOpponentTurnEnded], a
	ld [wSkipDuelistIsThinkingDelay], a
.link_opp_turn_loop
	ld a, [wSkipDuelistIsThinkingDelay]
	or a
	jr nz, .asm_6932
	call SetLinkDuelTransmissionFrameFunction
	call HandleWaitingLinkOpponentMenu
	ld a, [wDuelDisplayedScreen]
	cp CHECK_PLAY_AREA
	jr nz, .asm_6932
	lb de, $38, $9f
	call SetupText
.asm_6932
	xor a
	ld hl, wDoFrameFunction
	ld [hli], a
	ld [hl], a
	call SerialRecvDuelData
	ld a, OPPONENT_TURN
	ldh [hWhoseTurn], a
	ld a, [wSerialFlags]
	or a
	jp nz, DuelTransmissionError
	ld [wSkipDuelistIsThinkingDelay], a ; FALSE
	ldh a, [hOppActionTableIndex]
	cp NUM_OPP_ACTIONS
	jp nc, DuelTransmissionError
	ld hl, OppActionTable
	call JumpToFunctionInTable
	ld hl, wOpponentTurnEnded
	ld a, [wDuelFinished]
	or [hl]
	jr z, .link_opp_turn_loop
	ret


; related to AI taking their turn in a duel.
; called multiple times during one AI turn.
; each call results in the execution of an OppActionTable function.
; input:
;	a = OPPACTION_* constant
; output:
;	carry = set:  if the opponent's turn has ended
AIMakeDecision:
	ldh [hOppActionTableIndex], a
	ld hl, wOpponentTurnEnded
	ld [hl], 0
	ld hl, OppActionTable
	call JumpToFunctionInTable
	ld a, [wDuelFinished]
	ld hl, wOpponentTurnEnded
	or [hl]
	ret z
	scf
	ret


; actions for the opponent's turn.
; on a link duel, this is referenced by DoLinkOpponentTurn in a loop (on each opponent's HandleTurn).
; on a non-link duel (vs AI opponent), this is referenced by AIMakeDecision.
OppActionTable:
	table_width 2, OppActionTable
	dw DuelTransmissionError
	dw OppAction_PlayBasicPokemonCard
	dw OppAction_EvolvePokemonCard
	dw OppAction_PlayEnergyCard
	dw OppAction_AttemptRetreat
	dw OppAction_FinishTurnWithoutAttacking
	dw OppAction_PlayTrainerCard
	dw OppAction_ExecuteTrainerCardEffectCommands
	dw OppAction_BeginUseAttack
	dw OppAction_UseAttack
	dw OppAction_PlayAttackAnimationDealAttackDamage
	dw OppAction_DrawCard
	dw OppAction_UsePokemonPower
	dw OppAction_ExecutePokemonPowerEffect
	dw OppAction_ForceSwitchActive
	dw OppAction_NoAction
	dw OppAction_NoAction
	dw OppAction_TossCoinATimes
	dw OppAction_6b30
	dw OppAction_NoAction
	dw OppAction_UseMetronomeAttack
	dw OppAction_6b15
	dw DrawDuelMainScene
	assert_table_length NUM_OPP_ACTIONS


; preserves all registers except af
OppAction_DrawCard:
	call DrawCardFromDeck
	jp nc, AddCardToHand
	ret


OppAction_FinishTurnWithoutAttacking:
	call DrawDuelMainScene
	call ClearNonTurnTemporaryDuelvars
	ldtx hl, FinishedTurnWithoutAttackingText
	call DrawWideTextBox_WaitForInput
	ld a, TRUE
	ld [wOpponentTurnEnded], a
	ret


; attaches an Energy card from the hand to a Pokemon in own play area
; input:
;	[hTemp_ffa0] = deck index of the Energy card being attached (0-59)
;	[hTempPlayAreaLocation_ffa1] = target Pokemon's play area location offset (PLAY_AREA_* constant)
OppAction_PlayEnergyCard:
	ldh a, [hTempPlayAreaLocation_ffa1]
	ldh [hTempPlayAreaLocation_ff9d], a
	ld e, a
	ldh a, [hTemp_ffa0]
	ldh [hTempCardIndex_ff98], a
	call PutHandCardInPlayArea
	ldh a, [hTemp_ffa0]
	call LoadCardDataToBuffer1_FromDeckIndex
	call DrawLargePictureOfCard
	call PrintAttachedEnergyToPokemon
	ld hl, wOncePerTurnFlags
	set PLAYED_ENERGY_THIS_TURN_F, [hl]
	jp DrawDuelMainScene


; evolves a Pokemon in own play area
; input:
;	[hTempPlayAreaLocation_ffa1] = play area location offset of the card being evolved (PLAY_AREA_* constant)
;	[hTemp_ffa0] = deck index of the new Evolution card (0-59)
OppAction_EvolvePokemonCard:
	ldh a, [hTempPlayAreaLocation_ffa1]
	ldh [hTempPlayAreaLocation_ff9d], a
	ldh a, [hTemp_ffa0]
	ldh [hTempCardIndex_ff98], a
	call LoadCardDataToBuffer1_FromDeckIndex
	call DrawLargePictureOfCard
	call EvolvePokemonCardIfPossible
	call PrintPokemonEvolvedIntoPokemon
	call ProcessPlayedPokemonCard
	jp DrawDuelMainScene


; puts a Basic Pokemon card from the hand onto the Bench
; input:
;	[hTemp_ffa0] = Basic Pokemon's deck index (0-59)
OppAction_PlayBasicPokemonCard:
	ldh a, [hTemp_ffa0]
	ldh [hTempCardIndex_ff98], a
	call PutHandPokemonCardInPlayArea
	ldh [hTempPlayAreaLocation_ff9d], a
	add DUELVARS_ARENA_CARD_STAGE
	get_turn_duelist_var
	ld [hl], BASIC
	ldh a, [hTemp_ffa0]
	ldtx hl, PlacedOnTheBenchText
	call DisplayCardDetailScreen
	call ProcessPlayedPokemonCard
	jp DrawDuelMainScene


; attempts to retreat the Active Pokemon, and if successful, discards the
; required Energy cards and swaps the Active Pokemon with a Benched Pokemon
OppAction_AttemptRetreat:
	ld a, DUELVARS_ARENA_CARD
	get_turn_duelist_var
	push af
	call AttemptRetreat
	ldtx hl, RetreatWasUnsuccessfulText
	jr c, .failed
	xor a
	ld [wDuelDisplayedScreen], a
	ldtx hl, RetreatedToTheBenchText
.failed
	push hl
	call DrawDuelMainScene
	pop hl
	pop af
	call LoadCardNameToTxRam2
	jp DrawWideTextBox_WaitForInput


; plays a Trainer card from the hand
; input:
;	[hTempCardIndex_ff9f] = Trainer card's deck index (0-59)
OppAction_PlayTrainerCard:
	call LoadNonPokemonCardEffectCommands
	call DisplayUsedTrainerCardDetailScreen
	call PrintUsedTrainerCardDescription
	jp ExchangeRNG


; executes the effect commands of the Trainer card that is being played.
; used only for Trainer cards, as a continuation of OppAction_PlayTrainerCard.
; input:
;	[hTempCardIndex_ff9f] = Trainer card's deck index (0-59)
OppAction_ExecuteTrainerCardEffectCommands:
	ld a, EFFECTCMDTYPE_DISCARD_ENERGY
	call TryExecuteEffectCommandFunction
	ld a, EFFECTCMDTYPE_BEFORE_DAMAGE
	call TryExecuteEffectCommandFunction
	call DrawDuelMainScene
	ldh a, [hTempCardIndex_ff9f]
	call TryToDiscardCardFromHand
	call ExchangeRNG
	jp DrawDuelMainScene


; begins the execution of an attack and handles the attack potentially being
; unsuccessful due to an effect like Smokescreen
; input:
;	[hTempCardIndex_ff9f] = Attacking Pokemon's deck index (0-59)
;	[hTemp_ffa0] = the attack being used (0 = first attack, 1 = second attack)
OppAction_BeginUseAttack:
	; I added a 30 frame delay to better transition from the previous action.
	; Feel free to delete the following 2 lines.
	ld a, 30 ; frames to delay
	call WaitAFrames_AllowSkipDelay

	ldh a, [hTempCardIndex_ff9f]
	ld d, a
	ldh a, [hTemp_ffa0]
	ld e, a
	call CopyAttackDataAndDamage_FromDeckIndex
	call UpdateArenaCardIDsAndClearTwoTurnDuelVars
	call CheckSmokescreenSubstatus
	jr c, .has_status
	ld a, DUELVARS_ARENA_CARD_STATUS
	get_turn_duelist_var
	and CNF_SLP_PRZ
	cp CONFUSED
	jr z, .has_status
	jp ExchangeRNG

; the Attacking Pokemon is Confused or affected by the Smokescreen substatus
.has_status
	call DrawDuelMainScene
	call PrintPokemonsAttackText
	call WaitForWideTextBoxInput
	call ExchangeRNG
	call HandleSmokescreenSubstatus
	ret nc ; return if attack is successful (won the coin toss)
	call ClearNonTurnTemporaryDuelvars
	; end the turn if the attack fails
	ld a, TRUE
	ld [wOpponentTurnEnded], a
	ret


; displays the attack used by the opponent.
; also handles EFFECTCMDTYPE_DISCARD_ENERGY and damage to self from confusion.
OppAction_UseAttack:
	ld a, EFFECTCMDTYPE_DISCARD_ENERGY
	call TryExecuteEffectCommandFunction
	call CheckSelfConfusionDamage
	jr c, .confusion_damage
	call DisplayOpponentUsedAttackScreen
	call PrintPokemonsAttackText
	call WaitForWideTextBoxInput
	jp ExchangeRNG
.confusion_damage
	call HandleConfusionDamageToSelf
	; end the turn if dealing damage to self due to confusion
	ld a, TRUE
	ld [wOpponentTurnEnded], a
	ret


OppAction_PlayAttackAnimationDealAttackDamage:
	call PlayAttackAnimation_DealAttackDamage
	ld a, TRUE
	ld [wOpponentTurnEnded], a
	ret


; forces the Player to switch their Active Pokemon with 1 of their Benched Pokemon
OppAction_ForceSwitchActive:
	ldtx hl, SelectNewActivePokemonText
	call DrawWideTextBox_WaitForInput
	rst SwapTurn
	call InitPlayAreaScreenVars_OnlyBench
	inc a ; $00 -> $01
	ld [hl], a ; wPlayAreaSelectAction = FORCED_SWITCH_CHECK_MENU
.force_selection
	call OpenPlayAreaScreenForSelection
	jr c, .force_selection ; must choose, B button can't be used to exit
	rst SwapTurn
	jp SerialSendByte


; input:
;	[hTempCardIndex_ff9f] = deck index of the Pokemon using the Pokemon Power (0-59)
;	[hTemp_ffa0] = Pokemon's play area location offset (PLAY_AREA_* constant)
OppAction_UsePokemonPower:
	ldh a, [hTempCardIndex_ff9f]
	ld d, a
	ld e, FIRST_ATTACK_OR_PKMN_POWER ; Pokemon Powers are always in the first attack slot
	call CopyAttackDataAndDamage_FromDeckIndex
	ldh a, [hTemp_ffa0]
	ldh [hTempPlayAreaLocation_ff9d], a
	call DisplayUsePokemonPowerScreen
	ldh a, [hTempCardIndex_ff9f]
	call LoadCardNameToTxRam2
	ld hl, wLoadedAttackName
	ld a, [hli]
	ld [wTxRam2_b], a
	ld a, [hl]
	ld [wTxRam2_b + 1], a
	ldtx hl, WillUseThePokemonPowerText
	call DrawWideTextBox_WaitForInput
	jp ExchangeRNG


; executes the EFFECTCMDTYPE_BEFORE_DAMAGE command of the used Pokemon Power
OppAction_ExecutePokemonPowerEffect:
	xor a ; FALSE
	ld [wAttackAnimationIsPlaying], a
	ld a, EFFECTCMDTYPE_BEFORE_DAMAGE
	jp TryExecuteEffectCommandFunction


; executes the EFFECTCMDTYPE_AFTER_DAMAGE command of the used Pokemon Power
OppAction_6b15:
	ld a, EFFECTCMDTYPE_AFTER_DAMAGE
	jp TryExecuteEffectCommandFunction


OppAction_TossCoinATimes:
	call SerialRecv8Bytes
	jp TossCoinATimes


; input:
;	[hTemp_ffa0] = PLAYER_TURN
OppAction_6b30:
	ldh a, [hWhoseTurn]
	push af
	ldh a, [hTemp_ffa0]
	ldh [hWhoseTurn], a
	call PlayDeckShuffleAnimation
	pop af
	ldh [hWhoseTurn], a
	ret


OppAction_UseMetronomeAttack:
	call DrawDuelMainScene
	ld a, DUELVARS_ARENA_CARD_STATUS
	get_turn_duelist_var
	and CNF_SLP_PRZ
	cp CONFUSED
	jr z, .asm_6b56
	call PrintPokemonsAttackText
	call .asm_6b56
	jp WaitForWideTextBoxInput
.asm_6b56
	call SerialRecv8Bytes
	push bc
	rst SwapTurn
	call CopyAttackDataAndDamage_FromDeckIndex
	rst SwapTurn
	ldh a, [hTempCardIndex_ff9f]
	ld [wPlayerAttackingCardIndex], a
	ld a, [wSelectedAttack]
	ld [wPlayerAttackingAttackIndex], a
	ld a, [wTempCardID_ccc2]
	ld [wPlayerAttackingCardID], a
	call UpdateArenaCardIDsAndClearTwoTurnDuelVars
	pop bc
	ld a, c
	ld [wMetronomeEnergyCost], a
;	fallthrough

OppAction_NoAction:
	ret


; loads the text ID for the name of the card with deck index given in a to TxRam2
; also loads the card to wLoadedCard1
; preserves all registers except af
; input:
;	a = card's deck index (0-59)
; output:
;	[wLoadedCard1] = all of the given card's data (card_data_struct)
;	[wTxRam2] = text ID for the given card's name (2 bytes)
LoadCardNameToTxRam2:
	call LoadCardDataToBuffer1_FromDeckIndex
	ld a, [wLoadedCard1Name]
	ld [wTxRam2], a
	ld a, [wLoadedCard1Name + 1]
	ld [wTxRam2 + 1], a
	ret

; loads the text ID for the name of the card with deck index given in a to TxRam2_b
; also loads the card to wLoadedCard1
; preserves all registers except af
; input:
;	a = card's deck index (0-59)
; output:
;	[wLoadedCard1] = all of the given card's data (card_data_struct)
;	[wTxRam2_b] = text ID for the given card's name (2 bytes)
LoadCardNameToTxRam2_b:
	call LoadCardDataToBuffer1_FromDeckIndex
	ld a, [wLoadedCard1Name]
	ld [wTxRam2_b], a
	ld a, [wLoadedCard1Name + 1]
	ld [wTxRam2_b + 1], a
	ret


; draws the main duel screen, then prints the "<Pokemon Lvxx>'s <attack>" text
; The Pokemon's name is the turn holder's Active Pokemon,
; and the attack's name is taken from wLoadedAttackName.
; input:
;	[wLoadedAttack] = Attacking Pokémon card's attack data (atk_data_struct)
DrawDuelMainScene_PrintPokemonsAttackText:
	call DrawDuelMainScene
;	fallthrough

; prints the "<Pokemon Lvxx>'s <attack>" text
; The Pokemon's name is the turn holder's Active Pokemon,
; and the attack's name is taken from wLoadedAttackName.
; input:
;	[wLoadedAttack] = Attacking Pokémon card's attack data (atk_data_struct)
PrintPokemonsAttackText:
	ld a, DUELVARS_ARENA_CARD
	get_turn_duelist_var
	call LoadCardDataToBuffer1_FromDeckIndex
	ld a, 18
	call CopyCardNameAndLevel
	xor a ; TX_END
	ld [hl], a ; terminate the text string at wDefaultText
	; zero wTxRam2 so that the name & level text just loaded to wDefaultText is printed
	ld hl, wTxRam2
	ld [hli], a
	ld [hli], a
	ld a, [wLoadedAttackName]
	ld [hli], a ; wTxRam2_b
	ld a, [wLoadedAttackName + 1]
	ld [hl], a
	ldtx hl, PokemonsAttackText
	jp DrawWideTextBox_PrintText


; clears the SUBSTATUS1 and updates the double damage condition
; of the player whose turn is about to start.
; preserves bc and de
UpdateSubstatusConditions_StartOfTurn::
	ld a, DUELVARS_ARENA_CARD_SUBSTATUS1
	get_turn_duelist_var
	ld [hl], $0
	or a
	ret z ; return if the Active Pokémon wasn't affected by any SUBSTATUS1 effects
	cp SUBSTATUS1_NEXT_TURN_DOUBLE_DAMAGE
	ret nz
	ld a, DUELVARS_ARENA_CARD_SUBSTATUS3
	get_turn_duelist_var
	set SUBSTATUS3_THIS_TURN_DOUBLE_DAMAGE_F, [hl]
	ret


; makes all Pokemon in the turn holder's play area able to evolve. called from the
; player's second turn on, in order to allow evolution of all Pokemon already played.
; preserves de and b
SetAllPlayAreaPokemonCanEvolve:
	ld a, DUELVARS_NUMBER_OF_POKEMON_IN_PLAY_AREA
	get_turn_duelist_var
	ld c, a
	ld l, DUELVARS_ARENA_CARD_FLAGS
.next_pkmn_loop
	res USED_PKMN_POWER_THIS_TURN_F, [hl]
	set CAN_EVOLVE_THIS_TURN_F, [hl]
	inc l
	dec c
	jr nz, .next_pkmn_loop
	ret


; initializes variables that last for a single player's turn
; preserves all registers except af
InitVariablesToBeginTurn:
	xor a
	ld [wOncePerTurnFlags], a
	ld [wGotHeadsFromSmokescreenCheck], a
	ldh a, [hWhoseTurn]
	ld [wWhoseTurn], a
	ret


; clears the SUBSTATUS2/Headache, and updates the double damage condition
; of the player whose turn has ended.
; preserves bc and de
UpdateSubstatusConditions_EndOfTurn::
	ld a, DUELVARS_ARENA_CARD_SUBSTATUS3
	get_turn_duelist_var
	res SUBSTATUS3_HEADACHE_F, [hl]
	push hl
	ld a, DUELVARS_ARENA_CARD_SUBSTATUS2
	get_turn_duelist_var
	xor a
	ld [hl], a
	ld a, DUELVARS_ARENA_CARD_SUBSTATUS1
	get_turn_duelist_var
	pop hl
	cp SUBSTATUS1_NEXT_TURN_DOUBLE_DAMAGE
	ret z
	res SUBSTATUS3_THIS_TURN_DOUBLE_DAMAGE_F, [hl]
	ret


; applies and/or refreshes status conditions and other events that trigger between turns
HandleBetweenTurnsEvents:
	call IsArenaPokemonAsleepOrPoisoned
	jr c, .something_to_handle
	cp PARALYZED
	jr z, .something_to_handle
	rst SwapTurn
	call IsArenaPokemonAsleepOrPoisoned
	rst SwapTurn
	jr c, .something_to_handle
	call DiscardAttachedPluspowers
	rst SwapTurn
	call DiscardAttachedDefenders
	jp SwapTurn

.something_to_handle
	; either:
	; 1. turn holder's Active Pokemon is Paralyzed, Asleep, or Poisoned/double Poisoned
	; 2. non-turn holder's Active Pokemon is Asleep or Poisoned/double Poisoned
	call ResetAnimationQueue
	call ZeroObjectPositionsAndToggleOAMCopy
	call EmptyScreen
	ld a, BOXMSG_BETWEEN_TURNS
	call DrawDuelBoxMessage
	ldtx hl, BetweenTurnsText
	call DrawWideTextBox_WaitForInput

	ld a, DUELVARS_ARENA_CARD
	get_turn_duelist_var
	call _GetCardIDFromDeckIndex
	ld [wTempNonTurnDuelistCardID], a
	ld l, DUELVARS_ARENA_CARD_STATUS
	ld a, [hl]
	or a ; cp NO_STATUS
	jr z, .discard_pluspower
	; has at least 1 Special Condition
	call HandlePoisonDamage
	jr c, .discard_pluspower ; skip remaining status checks if the Pokémon was KO'd
	call HandleSleepCheck
	ld a, [hl]
	and CNF_SLP_PRZ
	cp PARALYZED
	jr nz, .discard_pluspower
	; heal paralysis by erasing everything but Poisoned/Double Poisoned
	ld a, DOUBLE_POISONED
	and [hl]
	ld [hl], a
	call RedrawTurnDuelistsMainSceneOrDuelHUD
	ldtx hl, IsCuredOfParalysisText
	call PrintCardNameFromCardIDInTextBox
	ld a, DUEL_ANIM_HEAL
	call PlayBetweenTurnsAnimation
	call WaitForWideTextBoxInput

.discard_pluspower
	call DiscardAttachedPluspowers
	rst SwapTurn
	ld a, DUELVARS_ARENA_CARD
	get_turn_duelist_var
	call _GetCardIDFromDeckIndex
	ld [wTempNonTurnDuelistCardID], a
	ld l, DUELVARS_ARENA_CARD_STATUS
	ld a, [hl]
	or a ; cp NO_STATUS
	jr z, .discard_defender
	call HandlePoisonDamage
	call nc, HandleSleepCheck ; only check Asleep status if the Pokémon wasn't KO'd
.discard_defender
	call DiscardAttachedDefenders
	rst SwapTurn
	jp HandleBetweenTurnKnockOuts


; resets the number of attached Defenders for each of the turn holder's Pokemon to 0
; and discards any PlusPower cards from the turn holder's play area
DiscardAttachedPluspowers:
	ld a, DUELVARS_ARENA_CARD_ATTACHED_PLUSPOWER
	get_turn_duelist_var
	ld e, MAX_PLAY_AREA_POKEMON
	xor a
.unattach_pluspower_loop
	ld [hli], a
	dec e
	jr nz, .unattach_pluspower_loop
	ld bc, PLUSPOWER
	jr MoveCardToDiscardPileIfInPlayArea


; resets the number of attached Defenders for each of the turn holder's Pokemon to 0
; and discards any Defender cards from the turn holder's play area
DiscardAttachedDefenders:
	ld a, DUELVARS_ARENA_CARD_ATTACHED_DEFENDER
	get_turn_duelist_var
	ld e, MAX_PLAY_AREA_POKEMON
	xor a
.unattach_defender_loop
	ld [hli], a
	dec e
	jr nz, .unattach_defender_loop
	ld bc, DEFENDER
;	fallthrough

; moves all of the cards with the given card ID in the given player's play area to the discard pile.
; input:
;	bc = card ID to check
;	h = hWhoseTurn constant (PLAYER_TURN or OPPONENT_TURN)
MoveCardToDiscardPileIfInPlayArea:
	ld l, DUELVARS_CARD_LOCATIONS + DECK_SIZE
.next_card
	dec l ; go through deck indices in reverse order
	ld a, [hl]
	and CARD_LOCATION_PLAY_AREA
	jr z, .skip ; jump if the card isn't in the play area
	ld a, l
	call GetCardIDFromDeckIndex
	ld a, c
	cp e
	jr nz, .skip ; jump if it isn't the card from input
;	ld a, b
;	cp d ; card IDs are 8-bit so d is always 0
;	jr nz, .skip
	ld a, l
	call PutCardInDiscardPile
.skip
	ld a, l
	or a
	jr nz, .next_card
	ret


; if not Poisoned, outputs in a any other condition (ASLEEP/CONFUSED/PARALYZED).
; preserves bc and de
; output:
;	carry = set:  if the turn holder's Active Pokemon is Asleep or Poisoned
IsArenaPokemonAsleepOrPoisoned:
	ld a, DUELVARS_ARENA_CARD_STATUS
	get_turn_duelist_var
	or a ; cp NO_STATUS
	ret z ; return if the Active Pokémon isn't affected by any Special Conditions
	; note that POISONED | DOUBLE_POISONED is the same as just DOUBLE_POISONED ($c0)
	; poison status masking is normally done with PSN_DBLPSN ($f0)
	and POISONED | DOUBLE_POISONED
	jr nz, .set_carry
	ld a, [hl]
	and CNF_SLP_PRZ
	cp ASLEEP
	jr z, .set_carry
	or a
	ret
.set_carry
	scf
	ret


RedrawTurnDuelistsMainSceneOrDuelHUD:
	ld a, [wDuelDisplayedScreen]
	cp DUEL_MAIN_SCENE
	jr z, RedrawTurnDuelistsDuelHUD
	ld hl, wWhoseTurn
	ldh a, [hWhoseTurn]
	cp [hl]
	jp z, DrawDuelMainScene
	rst SwapTurn
	call DrawDuelMainScene
	jp SwapTurn


; input:
;	a = animation ID (DUEL_ANIM_* constant)
PlayBetweenTurnsAnimation:
	push af
	ld a, [wDuelType]
	or a
	jr nz, .store_duelist_turn
	ld a, [wWhoseTurn]
	cp PLAYER_TURN
	jr z, .store_duelist_turn
	rst SwapTurn
	ldh a, [hWhoseTurn]
	ld [wDuelAnimDuelistSide], a
	rst SwapTurn
	jr .asm_6ccb

.store_duelist_turn
	ldh a, [hWhoseTurn]
	ld [wDuelAnimDuelistSide], a

.asm_6ccb
	xor a
	ld [wDuelAnimLocationParam], a
	ld a, DUEL_ANIM_SCREEN_MAIN_SCENE
	ld [wDuelAnimationScreen], a
	pop af

; play animation
	call PlayDuelAnimation
	call WaitForAnimationToFinish_AllowSkipDelay
;	fallthrough

RedrawTurnDuelistsDuelHUD:
	ld hl, wWhoseTurn
	ldh a, [hWhoseTurn]
	cp [hl]
	jp z, DrawDuelHUDs
	rst SwapTurn
	call DrawDuelHUDs
	jp SwapTurn


; inserts the name of the card at wTempNonTurnDuelistCardID into the text
; with ID at hl and then prints it in a text box at the bottom of the screen
; input:
;	hl = text ID
;	[wTempNonTurnDuelistCardID] = card ID from which to read the name data
PrintCardNameFromCardIDInTextBox:
	push hl
	ld a, [wTempNonTurnDuelistCardID]
	ld e, a
	call LoadCardDataToBuffer1_FromCardID
	ld hl, wLoadedCard1Name
	ld a, [hli]
	ld h, [hl]
	ld l, a
	call LoadTxRam2
	pop hl
	jp DrawWideTextBox_PrintText


; handles the Asleep check for the non-turn holder.
; this is done by flipping a coin and printing various notification texts.
; if coin flip is heads, the Asleep Special Condition is removed from the Pokemon.
; also plays the appropriate animation (either DUEL_ANIM_SLEEP or DUEL_ANIM_HEAL).
; preserves hl
; input:
;	h = hWhoseTurn constant (PLAYER_TURN or OPPONENT_TURN)
;	l = DUELVARS_ARENA_CARD_STATUS
;	[wTempNonTurnDuelistCardID] = card ID of the Pokemon being checked
HandleSleepCheck:
	ld a, [hl]
	and CNF_SLP_PRZ
	cp ASLEEP
	ret nz ; return if the Pokemon isn't Asleep

	push hl
	ld a, [wTempNonTurnDuelistCardID]
	ld e, a
	call LoadCardDataToBuffer1_FromCardID
	ld a, 18
	call CopyCardNameAndLevel
	xor a ; TX_END
	ld [hl], a ; terminate the text string at wDefaultText
	; zero wTxRam2 so that the name & level text just loaded to wDefaultText is printed
	ld hl, wTxRam2
	ld [hli], a
	ld [hl], a
	ldtx de, PokemonsSleepCheckText
	call TossCoin
	ld a, DUEL_ANIM_SLEEP
	ldtx hl, IsStillAsleepText
	jr nc, .tails

; coin toss was heads, so remove the Asleep condition
	pop hl
	push hl
	ld a, DOUBLE_POISONED ; Poisoned and Double Poisoned
	and [hl]
	ld [hl], a
	ld a, DUEL_ANIM_HEAL
	ldtx hl, IsCuredOfSleepText

.tails
	push af
	push hl
	call RedrawTurnDuelistsMainSceneOrDuelHUD
	pop hl
	call PrintCardNameFromCardIDInTextBox
	pop af
	call PlayBetweenTurnsAnimation
	call WaitForWideTextBoxInput
	pop hl
	ret


; preserves hl
; input:
;	h = hWhoseTurn constant (PLAYER_TURN or OPPONENT_TURN)
;	l = DUELVARS_ARENA_CARD_STATUS
; output:
;	carry = set:  if the poison damage reduced the Active Pokémon's HP to 0
HandlePoisonDamage:
	bit POISONED_F , [hl]
	ret z ; return if Pokemon isn't Poisoned

; load damage and text according to normal/double poison
	push hl
	bit DOUBLE_POISONED_F, [hl]
	ld a, PSN_DAMAGE
	ldtx hl, Received10DamageDueToPoisonText
	jr z, .not_double_poisoned
	ld a, DBLPSN_DAMAGE
	ldtx hl, Received20DamageDueToPoisonText

.not_double_poisoned
	push af
	ld [wDuelAnimDamage + 0], a
	xor a
	ld [wDuelAnimDamage + 1], a

	push hl
	call RedrawTurnDuelistsMainSceneOrDuelHUD
	pop hl
	call PrintCardNameFromCardIDInTextBox

; play animation
	ld a, DUEL_ANIM_POISON
	call PlayBetweenTurnsAnimation
	pop af

; deal poison damage
	ld e, a
	ld d, $00
	ld a, DUELVARS_ARENA_CARD_HP
	get_turn_duelist_var
	call SubtractHP
	push hl
	ld a, DUEL_ANIM_DAMAGE_HUD
	call PlayBetweenTurnsAnimation
	pop hl

	call PrintKnockedOutIfHLZero
	push af
	call WaitForWideTextBoxInput
	pop af
	pop hl
	ret


; this function applies all Special Conditions in order
; that have been added to the wStatusConditionQueue.
; this and the next function would be ideal candidates for moving to another bank
; if bank $01 becomes full. (saving over 80 bytes for +2 farcalls).
; output:
;	carry = set:  if any conditions were applied and the Defending Pokemon
;	              didn't have a "No Damage or Effect" status
ApplyStatusConditionQueue::
	xor a
	ld [wPlayerArenaCardLastTurnStatus], a
	ld [wOpponentArenaCardLastTurnStatus], a
	ld hl, wStatusConditionQueueIndex
	ld a, [hl]
	or a
	ret z
	ld e, a
	ld d, $00
	ld hl, wStatusConditionQueue
	add hl, de
	ld [hl], $00 ; terminator byte
	call CheckNoDamageOrEffect
	jr c, .no_damage_or_effect

; apply all status conditions unconditionally
	ld hl, wStatusConditionQueue
.apply_status_loop
	ld a, [hli]
	or a
	scf
	ret z ; return carry once all of the conditions have been applied
	ld d, a ; which duelist side
	call ApplyStatusConditionToArenaPokemon
	jr .apply_status_loop

.no_damage_or_effect
	ld a, l
	or h
	call nz, DrawWideTextBox_PrintText

; if no damage or effect to the Defending Pokemon,
; we will just apply the conditions to the turn holder's Pokemon
	ld hl, wStatusConditionQueue
.apply_own_status_loop
	ld a, [hli]
	or a
	ret z ; return no carry once all of the relevant conditions have been applied
	ld d, a
	ld a, [wWhoseTurn]
	cp d
	jr z, .apply_own_condition
	inc hl
	inc hl
	jr .apply_own_status_loop
.apply_own_condition
	call ApplyStatusConditionToArenaPokemon
	jr .apply_own_status_loop


; applies the Special Condition at hl+1 to the Active Pokemon.
; discards the Active Pokemon's conditions contained in the bitmask at hl.
; preserves bc
; input:
;	d = hWhoseTurn constant (PLAYER_TURN or OPPONENT_TURN)
;	hl = pointing to a byte in wStatusConditionQueue
ApplyStatusConditionToArenaPokemon:
	ld e, DUELVARS_ARENA_CARD_STATUS
	ld a, [de]
	and [hl]
	inc hl
	or [hl]
	ld [de], a
	dec hl
	ld e, DUELVARS_ARENA_CARD_LAST_TURN_STATUS
	ld a, [de]
	and [hl]
	inc hl
	or [hl]
	ld [de], a
	inc hl
	ret


; if the HP of Defending Pokemon (non-turn holder's Active Pokémon) is 0 and
; if the HP of the Attacking Pokemon (turn holder's Active Pokémon) HP is not,
; then the Attacking Pokemon is Knocked Out if it was affected by Destiny Bond.
HandleDestinyBondSubstatus::
	ld a, DUELVARS_ARENA_CARD_SUBSTATUS1
	call GetNonTurnDuelistVariable
	cp SUBSTATUS1_DESTINY_BOND
	ret nz ; return if Destiny Bond isn't active
	ld l, DUELVARS_ARENA_CARD
	ld a, [hl]
	inc a ; cp -1 (empty play area slot?)
	ret z ; return if there's no Defending Pokémon
	ld l, DUELVARS_ARENA_CARD_HP
	ld a, [hl]
	or a
	ret nz ; return if Defending Pokémon's HP > 0
	ld a, DUELVARS_ARENA_CARD_HP
	get_turn_duelist_var
	or a
	ret z ; return if the Attacking Pokémon is already Knocked Out
	ld [hl], 0
	call DrawDuelMainScene
	call DrawDuelHUDs
	ld a, DUELVARS_ARENA_CARD
	get_turn_duelist_var
	call LoadCardDataToBuffer2_FromDeckIndex
	ld hl, wLoadedCard2Name
	ld a, [hli]
	ld h, [hl]
	ld l, a
	call LoadTxRam2
	ldtx hl, KnockedOutDueToDestinyBondText
	jp DrawWideTextBox_WaitForInput


; output:
;	carry = set:  if the duel has ended
HandleDestinyBondAndBetweenTurnKnockOuts::
	call HandleDestinyBondSubstatus
;	fallthrough

; output:
;	carry = set:  if the duel has ended
HandleBetweenTurnKnockOuts:
	call .ClearDamageReductionSubstatus2_AllKnockedOutPokemon
	xor a
	ld [wDuelFinishParam], a
	; have turn holder draw Prizes for each of their opponent's Knocked Out Pokémon
	rst SwapTurn
	call Func_6fa5
	ld hl, wDuelFinishParam
	rl [hl] ; only update wDuelFinishParam if carry was set
	rst SwapTurn
	ld a, [wDuelFinishParam]
	or a
	jr z, .check_other_player
	; turn holder has drawn all of their Prize cards
	call CheckIfTurnDuelistPlayAreaPokemonAreAllKnockedOut
	jr c, .check_other_player
	; turn holder still has at least one Pokémon in the play area with more than 0 HP
	call CountKnockedOutPokemon
	ld c, a
	rst SwapTurn
	call CountPrizes
	rst SwapTurn
	dec a ; subtract 1 so carry will be set if number of KO'd Pokémon = number of Prizes
	cp c
	jr c, .check_other_player
	; non-turn holder will still have at least one Prize card, even after drawing any pending Prizes
	ld a, c
	rst SwapTurn
	call TakeAPrizes
	rst SwapTurn
	ld a, TURN_PLAYER_WON
	jr .set_duel_finished
.turn_player_lost
	ld a, TURN_PLAYER_LOST
	jr .set_duel_finished

.check_other_player
	; have non-turn holder draw Prizes for each of their opponent's Knocked Out Pokémon
	call Func_6fa5
	ld hl, wDuelFinishParam
	rl [hl]
	ld a, [wDuelFinishParam]
	cp $01
	jr nz, .try_to_continue_duel
	; non-turn holder has drawn all of their Prize cards or turn holder has run out of Pokémon
	rst SwapTurn
	call CheckIfTurnDuelistPlayAreaPokemonAreAllKnockedOut
	rst SwapTurn
	jr nc, .turn_player_lost ; jump if non-turn holder still has at least one Pokémon in play that isn't KO'd

.try_to_continue_duel
	rst SwapTurn
	call ReplaceKnockedOutPokemon
	ld hl, wDuelFinishParam
	rl [hl]
	rst SwapTurn
	call ReplaceKnockedOutPokemon
	ld hl, wDuelFinishParam
	rl [hl]
	ld a, [wDuelFinishParam]
	or a
	jr nz, .determine_outcome_of_duel
	xor a
.clean_up_play_area
	push af
	call MoveAllKnockedOutPokemonToDiscardPile
	call ShiftAllPokemonToFirstPlayAreaSlots
	pop af
	ret

.determine_outcome_of_duel
	ld e, a
	ld d, $00
	ld hl, .Data_6ed2
	add hl, de
	ld a, [hl]
.set_duel_finished
	ld [wDuelFinished], a
	scf
	jr .clean_up_play_area

.Data_6ed2:
	db DUEL_NOT_FINISHED, TURN_PLAYER_LOST, TURN_PLAYER_WON,  TURN_PLAYER_TIED
	db TURN_PLAYER_LOST,  TURN_PLAYER_LOST, TURN_PLAYER_TIED, TURN_PLAYER_LOST
	db TURN_PLAYER_WON,   TURN_PLAYER_TIED, TURN_PLAYER_WON,  TURN_PLAYER_WON
	db TURN_PLAYER_TIED,  TURN_PLAYER_LOST, TURN_PLAYER_WON,  TURN_PLAYER_TIED


; clears SUBSTATUS2_CANNOT_ATTACK_THIS, SUBSTATUS2_REDUCE_BY_10,
; and SUBSTATUS2_REDUCE_BY_20 for each Active Pokemon with 0 HP
.ClearDamageReductionSubstatus2_AllKnockedOutPokemon:
	rst SwapTurn
	call .ClearDamageReductionSubstatus2_TurnHolderKnockedOutPokemon
	rst SwapTurn
;	fallthrough

.ClearDamageReductionSubstatus2_TurnHolderKnockedOutPokemon
	ld a, DUELVARS_ARENA_CARD_HP
	get_turn_duelist_var
	or a
	ret nz
;	fallthrough

; clears some SUBSTATUS2 conditions from the turn holder's Active Pokemon.
; more specifically, those conditions that reduce the damage from an attack
; or prevent the opposing Pokemon from attacking the substatus condition inducer.
; preserves bc and de
ClearDamageReductionSubstatus2::
	ld a, DUELVARS_ARENA_CARD_SUBSTATUS2
	get_turn_duelist_var
	or a
	ret z ; return if the Active Pokémon isn't affected by any SUBSTATUS2 effects
	cp SUBSTATUS2_REDUCE_BY_20
	jr z, .zero
	cp SUBSTATUS2_REDUCE_BY_10
	jr z, .zero
	cp SUBSTATUS2_CANNOT_ATTACK_THIS
	ret nz
.zero
	ld [hl], 0
	ret


; moves each Pokémon with 0 HP in either play area to the discard pile (and any attached cards).
; preserves bc
MoveAllKnockedOutPokemonToDiscardPile:
	rst SwapTurn
	call MoveAllTurnHolderKnockedOutPokemonToDiscardPile
	rst SwapTurn
;	fallthrough

; for each Pokemon in the turn holder's play area (Arena and Bench),
; move that card to the discard pile if its HP is 0
; preserves bc
MoveAllTurnHolderKnockedOutPokemonToDiscardPile:
	ld a, DUELVARS_NUMBER_OF_POKEMON_IN_PLAY_AREA
	get_turn_duelist_var
	ld d, a
	ld l, DUELVARS_ARENA_CARD_HP
	ld e, PLAY_AREA_ARENA
.loop
	ld a, [hli]
	or a
	jr nz, .next
	push hl
	push de
	call MovePlayAreaCardToDiscardPile
	pop de
	pop hl
.next
	inc e
	dec d
	jr nz, .loop
	ret


; handles the turn holder replacing their Active Pokemon after it's been Knocked Out
; output:
;	carry = set:  if the turn holder doesn't have any Benched Pokemon
ReplaceKnockedOutPokemon:
	ld a, DUELVARS_ARENA_CARD_HP
	get_turn_duelist_var
	or a
	ret nz
	call ClearAllStatusConditions
	call CheckForAlivePokemonInBench
	jr nc, .can_replace_pokemon

; if we made it here, the duelist can't replace the Knocked Out Pokemon
	call DrawDuelMainScene
	ldtx hl, ThereAreNoPokemonInPlayAreaText
	call DrawWideTextBox_WaitForInput
	call ExchangeRNG
	scf
	ret

.can_replace_pokemon
	ld a, DUELVARS_DUELIST_TYPE
	get_turn_duelist_var
	cp DUELIST_TYPE_PLAYER
	jr nz, .opponent

; prompt the player to replace the Knocked Out Pokemon with one from the Bench
	call DrawDuelMainScene
	ldtx hl, ChooseNextActivePokemonText
	call DrawWideTextBox_WaitForInput
	call InitPlayAreaScreenVars_OnlyBench
	inc a ; $00 -> $01
	ld [hl], a ; wPlayAreaSelectAction = FORCED_SWITCH_CHECK_MENU
	ld a, PRACTICEDUEL_PLAY_STARYU_FROM_BENCH
	call DoPracticeDuelAction
.select_pokemon
	call OpenPlayAreaScreenForSelection
	jr c, .select_pokemon ; must choose, B button can't be used to exit
	call SerialSend8Bytes

; replace the Active Pokemon with the one at location [hTempPlayAreaLocation_ff9d]
.replace_pokemon
	call FinishQueuedAnimations
	ld a, PRACTICEDUEL_REPLACE_KNOCKED_OUT_POKEMON
	call DoPracticeDuelAction
	jr c, .select_pokemon
	ldh a, [hTempPlayAreaLocation_ff9d]
	ld d, a
	ld e, PLAY_AREA_ARENA
	call SwapPlayAreaPokemon
	ld a, DUELVARS_ARENA_CARD
	get_turn_duelist_var
	ldtx hl, DuelistPlacedACardText
	call DisplayCardDetailScreen
	call ExchangeRNG
	or a
	ret

; the AI opponent replaces the Knocked Out Pokemon with one from the Bench
.opponent
	cp DUELIST_TYPE_LINK_OPP
	jr z, .link_opponent
	call AIDoAction_KOSwitch
	ldh a, [hTemp_ffa0]
	ldh [hTempPlayAreaLocation_ff9d], a
	jr .replace_pokemon

; wait for link opponent to replace the Knocked Out Pokemon with one from the Bench
.link_opponent
	call DrawDuelMainScene
	ldtx hl, DuelistIsSelectingPokemonToPlaceInArenaText
	call DrawWideTextBox_PrintText
	call SerialRecv8Bytes
	ldh [hTempPlayAreaLocation_ff9d], a
	jr .replace_pokemon


; preserves de
; output:
;	a & b = how many Pokemon with HP > 0 are on the turn holder's Bench
;	carry = set:  if the turn holder has no Benched Pokemon with more than 0 HP
CheckForAlivePokemonInBench:
	ld a, DUELVARS_NUMBER_OF_POKEMON_IN_PLAY_AREA
	get_turn_duelist_var
	dec a ; ignore the Active Pokémon
	jr z, .set_carry ; return carry if there are no Benched Pokémon
	ld c, a ; number of Benched Pokémon
	ld b, 0 ; counter for Pokémon with HP > 0
	ld l, DUELVARS_BENCH1_CARD_HP
.loop_bench
	ld a, [hli]
	or a
	jr z, .next_pkmn ; jump if this Pokemon has 0 HP
	inc b
.next_pkmn
	dec c
	jr nz, .loop_bench
	ld a, b
	or a
	ret nz
.set_carry
	scf
	ret


; handles the non-turn holder drawing Prizes for each of the turn holder's KO'd Pokémon.
; output:
;	carry = set:  if the non-turn holder drew all of their Prize cards
Func_6fa5:
	call CountKnockedOutPokemon
	ret nc ; return if there are no Knocked Out Pokemon
	; at least one Pokemon is Knocked Out
	rst SwapTurn
	call TurnDuelistTakePrizes
	rst SwapTurn
	ret nc ; return if the non-turn holder hasn't drawn all of their Prizes
	rst SwapTurn
	call DrawDuelMainScene
	ldtx hl, TookAllThePrizesText
	call DrawWideTextBox_WaitForInput
	call ExchangeRNG
	scf
	jp SwapTurn


; returns in wNumberPrizeCardsToTake the number of Pokemon in the turn holder's
; play area that are still there despite having 0 HP (i.e. Knocked Out).
; Clefairy Doll and Mysterious Fossil are ignored.
; output:
;	a & [wNumberPrizeCardsToTake] = number of Knocked Out Pokemon in the turn holder's play area
;	carry = set:  if there is at least 1 Knocked Out Pokemon
;	
CountKnockedOutPokemon:
	ld a, DUELVARS_ARENA_CARD_HP
	get_turn_duelist_var
	ld d, h
	ld e, DUELVARS_ARENA_CARD
	lb bc, 0, MAX_PLAY_AREA_POKEMON
.loop
	ld a, [de]
	inc a ; cp -1 (empty play area slot?)
	jr z, .next ; jump if no Pokemon in this location
	ld a, [hli]
	or a
	jr nz, .next ; jump if this Pokemon's HP isn't 0
	; this Pokemon's HP has just become 0
	ld a, [de]
	call GetCardTypeFromDeckIndex_SaveDE
	cp TYPE_TRAINER
	jr z, .next ; jump if this is a Trainer card (Clefairy Doll or Mysterious Fossil)
	inc b
.next
	inc e
	dec c
	jr nz, .loop
	ld a, b
	ld [wNumberPrizeCardsToTake], a
	or a
	ret z
	scf
	ret


; has turn holder take amount of prizes that are in wNumberPrizeCardsToTake
; input:
;	[wNumberPrizeCardsToTake] = number of Prize cards waiting to be drawn
; output:
;	carry = set:  if all of the Prize cards were taken
TurnDuelistTakePrizes:
	call FinishQueuedAnimations
	ld a, [wNumberPrizeCardsToTake]
	ld hl, wTxRam3
	ld [hli], a
	xor a
	ld [hl], a
	ld a, DUELVARS_DUELIST_TYPE
	get_turn_duelist_var
	cp DUELIST_TYPE_PLAYER
	jr nz, .opponent

; player
	ldtx hl, WillDrawNPrizesText
	call DrawWideTextBox_WaitForInput
	ld a, [wNumberPrizeCardsToTake]
	call SelectPrizeCards
	ld hl, hTemp_ffa0
	ld d, [hl]
	inc hl
	ld e, [hl]
	call SerialSend8Bytes

.return_has_prizes
	call ExchangeRNG
	ld a, DUELVARS_PRIZES
	get_turn_duelist_var
	or a
	ret nz
	scf
	ret

.opponent
	ldh a, [hWhoseTurn]
	ld h, a
	ld l, PLAYER_TURN
	call DrawYourOrOppPlayAreaScreen_Bank0
	ldtx hl, WillDrawNPrizesText
	call DrawWideTextBox_PrintText
	call CountPrizes
	ld [wTempNumRemainingPrizeCards], a
	ld a, DUELVARS_DUELIST_TYPE
	get_turn_duelist_var
	cp DUELIST_TYPE_LINK_OPP
	jr z, .link_opponent
	ld a, 60 ; frames to delay
	call WaitAFrames_AllowSkipDelay
	call AIDoAction_TakePrize
	jr .asm_586f

.link_opponent
	call SerialRecv8Bytes
	ld a, DUELVARS_PRIZES
	get_turn_duelist_var
	ld [hl], d
	ld a, e
	cp $ff
	call nz, AddCardToHand

.asm_586f
	ld a, [wTempNumRemainingPrizeCards]
	ld hl, wNumberPrizeCardsToTake
	cp [hl]
	jr nc, .asm_587e
	ld hl, wTxRam3
	ld [hli], a
	xor a
	ld [hl], a
.asm_587e
	farcall Func_82b6
	ldtx hl, DrewNPrizesText
	call DrawWideTextBox_WaitForInput
	jr .return_has_prizes


; preserves de and b
; output:
;	carry = set:  if all of the turn holder's in-play Pokémon have been Knocked Out
CheckIfTurnDuelistPlayAreaPokemonAreAllKnockedOut:
	ld a, DUELVARS_NUMBER_OF_POKEMON_IN_PLAY_AREA
	get_turn_duelist_var
	ld c, a
	ld l, DUELVARS_ARENA_CARD_HP
.loop
	ld a, [hli]
	or a
	ret nz ; return no carry if this Pokémon has more than 0 HP
	dec c
	jr nz, .loop
	scf
	ret


; initializes variables when a duel begins, such as zeroing wDuelFinished or wDuelTurns,
; and setting wDuelType based on wPlayerDuelistType and wOpponentDuelistType
; preserves all registers except af
InitVariablesToBeginDuel:
	xor a
	ld [wDuelFinished], a
	ld [wDuelTurns], a
	ld [wcce7], a
	dec a ; $ff
	ld [wcc0f], a
	ld [wPlayerAttackingCardIndex], a
	ld [wPlayerAttackingAttackIndex], a
	call EnableSRAM
	ld a, [sSkipDelayAllowed]
	ld [wSkipDelayAllowed], a
	call DisableSRAM
	ld a, [wPlayerDuelistType]
	cp DUELIST_TYPE_LINK_OPP
	jr z, .set_duel_type
	bit 7, a ; DUELIST_TYPE_AI_OPP
	jr nz, .set_duel_type
	ld a, [wOpponentDuelistType]
	cp DUELIST_TYPE_LINK_OPP
	jr z, .set_duel_type
	bit 7, a ; DUELIST_TYPE_AI_OPP
	jr nz, .set_duel_type
	xor a ; DUELIST_TYPE_PLAYER
.set_duel_type
	ld [wDuelType], a
	ret


InitDuelVariables_BothDuelists:
	rst SwapTurn
	call InitDuelVariables_TurnDuelist
	rst SwapTurn
;	fallthrough

; initializes duel variables such as cards in the deck and hand or Pokemon in the play area
; player turn: [c200, c2ff]
; opponent turn: [c300, c3ff]
; preserves de
InitDuelVariables_TurnDuelist:
	ld a, DUELVARS_DUELIST_TYPE
	get_turn_duelist_var
	push hl
	push af
	xor a
	ld l, a
.zero_duel_variables_loop
	ld [hl], a
	inc l
	jr nz, .zero_duel_variables_loop ; wPlayerDuelVariables and wOpponentDuelVariables are each exactly $100 bytes long
	pop af
	pop hl
	ld [hl], a
	lb bc, 0, DECK_SIZE
	ld l, DUELVARS_DECK_CARDS
.init_duel_variables_loop
; zero card locations and cards in hand, and init order of cards in deck
	push hl
	ld [hl], b ; add current deck index to deck cards
	ld l, b ; DUELVARS_CARD_LOCATIONS + current deck index
	ld [hl], CARD_LOCATION_DECK
	pop hl
	inc l
	inc b
	dec c
	jr nz, .init_duel_variables_loop
	ld l, DUELVARS_ARENA_CARD
	ld c, MAX_PLAY_AREA_POKEMON + 1
	ld a, -1
.init_play_area
; initialize to $ff cards in Arena and Bench (plus a terminator)
	ld [hli], a
	dec c
	jr nz, .init_play_area
	ret


; draws [wDuelInitialPrizes] cards from each player's deck and places them as Prizes:
; writes their deck indices to DUELVARS_PRIZE_CARDS, sets their location to
; CARD_LOCATION_PRIZE, and sets [wDuelInitialPrizes] bits of DUELVARS_PRIZES.
InitPrizes_BothDuelists:
	rst SwapTurn
	call InitPrizes_TurnDuelist
	rst SwapTurn
;	fallthrough

; draws [wDuelInitialPrizes] cards from the turn holder's deck and places them as Prizes:
; writes their deck indices to DUELVARS_PRIZE_CARDS, sets their location to
; CARD_LOCATION_PRIZE, and sets [wDuelInitialPrizes] bits of DUELVARS_PRIZES.
InitPrizes_TurnDuelist:
	ldh a, [hWhoseTurn]
	ld h, a
	ld d, a
	ld e, DUELVARS_PRIZE_CARDS
	ld a, [wDuelInitialPrizes]
	ld c, a
	ld b, a
.draw_prizes_loop
	call DrawCardFromDeck
	ld [de], a
	inc de
	ld l, a
	ld [hl], CARD_LOCATION_PRIZE
	dec b
	jr nz, .draw_prizes_loop
	ld b, h
	ld e, c
	ld d, $00
	ld hl, PrizeBitmasks
	add hl, de
	ld a, [hl]
	ld h, b
	ld l, DUELVARS_PRIZES
	ld [hl], a
	ret

PrizeBitmasks:
	db %0, %1, %11, %111, %1111, %11111, %111111


; updates the turn holder's DUELVARS_PRIZES following that duelist
; drawing a number of prizes equal to register a
; preserves de
; input:
;	a = number of Prize cards that were drawn
TakeAPrizes:
	or a
	ret z
	ld c, a
	call CountPrizes
	sub c
	jr nc, .no_underflow
	xor a
.no_underflow
	ld c, a
	ld b, $00
	ld hl, PrizeBitmasks
	add hl, bc
	ld b, [hl]
	ld a, DUELVARS_PRIZES
	get_turn_duelist_var
	ld [hl], b
	ret


; initializes hTempCardIndex_ff9f and wTempTurnDuelistCardID to the turn holder's
; Active Pokemon, wTempNonTurnDuelistCardID to the non-turn holder's Active Pokemon,
; and zeroes other temporary variables that only last between each two-player turn.
; this is called when a Pokemon card is played or when an attack is used.
; preserves bc and de
UpdateArenaCardIDsAndClearTwoTurnDuelVars:
	ld a, DUELVARS_ARENA_CARD
	get_turn_duelist_var
	ldh [hTempCardIndex_ff9f], a
	call _GetCardIDFromDeckIndex
	ld [wTempTurnDuelistCardID], a
	rst SwapTurn
	ld a, DUELVARS_ARENA_CARD
	get_turn_duelist_var
	call _GetCardIDFromDeckIndex
	ld [wTempNonTurnDuelistCardID], a
	rst SwapTurn
	xor a
	ld [wStatusConditionQueueIndex], a
	ld [wIsDamageToSelf], a
	ld hl, wccec
	ld [hli], a ; wccec = $00
	ld [hli], a ; wEffectFailed = $00
	inc hl      ; skip wPreEvolutionPokemonCard
	ld [hli], a ; wDefendingWasForcedToSwitch = $00
	ld [hli], a ; wMetronomeEnergyCost = $00
	ld [hl], a  ; wNoEffectFromWhichStatus = $00
;	fallthrough

; same as ClearNonTurnTemporaryDuelvars, except the non-turn holder's
; Active Pokemon's status condition is copied to wccc5
; preserves bc and de
ClearNonTurnTemporaryDuelvars_CopyStatus::
	ld a, DUELVARS_ARENA_CARD_STATUS
	call GetNonTurnDuelistVariable
	ld [wccc5], a
;	fallthrough

; clears the non-turn holder's duelvars starting at DUELVARS_ARENA_CARD_DISABLED_ATTACK_INDEX.
; these duelvars only last a two-player turn at most.
; preserves bc and de
ClearNonTurnTemporaryDuelvars::
	ld a, DUELVARS_ARENA_CARD_DISABLED_ATTACK_INDEX
	call GetNonTurnDuelistVariable
	xor a
	ld [hli], a ; w*ArenaCardDisabledAttackIndex
	ld [hli], a ; w*ArenaCardLastTurnDamage + 0
	ld [hli], a ; w*ArenaCardLastTurnDamage + 1
	ld [hli], a ; w*ArenaCardLastTurnStatus
	ld [hli], a ; w*ArenaCardLastTurnSubstatus2
	ld [hli], a ; w*ArenaCardLastTurnChangeWeak
	ld [hli], a ; w*ArenaCardLastTurnEffect
	ld [hl], a  ; wc2f9/wc3f9 (unused duel variable?)
	ret


; updates non-turn holder's DUELVARS_ARENA_CARD_LAST_TURN_DAMAGE
; if wDefendingWasForcedToSwitch == 0: set to [wDealtDamage]
; if wDefendingWasForcedToSwitch != 0: set to 0
; preserves bc and de
UpdateArenaCardLastTurnDamage::
	ld a, DUELVARS_ARENA_CARD_LAST_TURN_DAMAGE
	call GetNonTurnDuelistVariable
	ld a, [wDefendingWasForcedToSwitch]
	or a
	jr nz, .zero
	ld a, [wDealtDamage]
	ld [hli], a
	ld a, [wDealtDamage + 1]
	ld [hl], a
	ret
.zero
	xor a
	ld [hli], a
	ld [hl], a
	ret


; plays all animations that are queued in wStatusConditionQueue.
; this function could be moved to another bank if bank $01 becomes full.
; (saving nearly 80 bytes for +2 farcalls, and 1 is already a bank1call)
PlayStatusConditionQueueAnimations::
	ld hl, wStatusConditionQueueIndex
	ld a, [hl]
	or a
	ret z
	ld e, a
	ld d, $00
	ld hl, wStatusConditionQueue
	add hl, de
	ld [hl], $00
	ld hl, wStatusConditionQueue
.loop
	ld a, [hli]
	or a
	ret z ; done with loop
	ld d, a
	inc hl
	ld a, [hli] ; which condition to inflict
	ld e, ATK_ANIM_SLEEP
	cp ASLEEP
	jr z, .got_anim
	ld e, ATK_ANIM_PARALYSIS
	cp PARALYZED
	jr z, .got_anim
	ld e, ATK_ANIM_POISON
	cp POISONED
	jr z, .got_anim
	ld e, ATK_ANIM_POISON
	cp DOUBLE_POISONED
	jr z, .got_anim
	ld e, ATK_ANIM_CONFUSION
	cp CONFUSED
	jr nz, .loop
	ldh a, [hWhoseTurn]
	cp d
	jr nz, .got_anim
	; if it's applied to the turn holder
	; then load the own confusion animation instead
	ld e, ATK_ANIM_OWN_CONFUSION
.got_anim
	ld a, e
	ld [wLoadedAttackAnimation], a
	xor a
	ld [wDuelAnimLocationParam], a
	push hl
	farcall PlayAttackAnimationCommands
	pop hl
	jr .loop


; when playing a Pokemon card, initializes some variables according to the
; card being played and checks if the card has Pokemon Power, to show it to
; the player, and possibly to use it if it triggers when the card is played.
; input:
;	[hTempCardIndex_ff98] = deck index of the Pokemon being played (0-59)
ProcessPlayedPokemonCard::
	ldh a, [hTempCardIndex_ff98]
	call ClearChangedTypesIfMuk
	ldh a, [hTempCardIndex_ff98]
	ld d, a
	ld e, FIRST_ATTACK_OR_PKMN_POWER
	call CopyAttackDataAndDamage_FromDeckIndex
	call UpdateArenaCardIDsAndClearTwoTurnDuelVars
	ldh a, [hTempCardIndex_ff98]
	ldh [hTempCardIndex_ff9f], a
	call _GetCardIDFromDeckIndex
	ld [wTempTurnDuelistCardID], a
	ld a, [wLoadedAttackCategory]
	cp POKEMON_POWER
	ret nz
	call DisplayUsePokemonPowerScreen
	ldh a, [hTempCardIndex_ff98]
	call LoadCardDataToBuffer1_FromDeckIndex
	ld hl, wLoadedCard1Name
	ld a, [hli]
	ld h, [hl]
	ld l, a
	call LoadTxRam2
	ldtx hl, HavePokemonPowerText
	call DrawWideTextBox_WaitForInput
	call ExchangeRNG
	ld a, [wLoadedCard1ID]
	cp MUK
	jr z, .use_pokemon_power
	call CheckIfPkmnPowersAreCurrentlyDisabled
	jr nc, .use_pokemon_power
	call DisplayUsePokemonPowerScreen
	ldtx hl, UnableDueToToxicGasText
	call DrawWideTextBox_WaitForInput
	jp ExchangeRNG

.use_pokemon_power
	ld hl, wLoadedAttackEffectCommands
	ld a, [hli]
	ld h, [hl]
	ld l, a
	ld a, EFFECTCMDTYPE_PKMN_POWER_TRIGGER
	call CheckMatchingCommand
	ret c ; return if command not found
	call DrawDuelMainScene
	ldh a, [hTempCardIndex_ff9f]
	call LoadCardDataToBuffer1_FromDeckIndex
	ld de, wLoadedCard1Name
	ld hl, wTxRam2
	ld a, [de]
	inc de
	ld [hli], a
	ld a, [de]
	ld [hli], a
	ld de, wLoadedAttackName
	ld a, [de]
	inc de
	ld [hli], a
	ld a, [de]
	ld [hl], a
	ldtx hl, WillUseThePokemonPowerText
	call DrawWideTextBox_WaitForInput
	call ExchangeRNG
	xor a ; FALSE
	ld [wAttackAnimationIsPlaying], a
	ld a, EFFECTCMDTYPE_PKMN_POWER_TRIGGER
	jp TryExecuteEffectCommandFunction


; if the ID of the card provided in register a as a deck index is MUK,
; then clear the changed type of all Active and Benched Pokemon.
; preserves de and b
; input:
;	a = deck index to check (0-59)
ClearChangedTypesIfMuk:
	call _GetCardIDFromDeckIndex
	cp MUK
	ret nz ; return if the Pokemon isn't a Muk
	rst SwapTurn
	call .zero_changed_types
	rst SwapTurn
.zero_changed_types
	ld a, DUELVARS_ARENA_CARD_CHANGED_TYPE
	get_turn_duelist_var
	ld c, MAX_PLAY_AREA_POKEMON
	xor a
.zero_changed_types_loop
	ld [hli], a
	dec c
	jr nz, .zero_changed_types_loop
	ret


; uses a Pokemon Power
UsePokemonPower:
	xor a ; FALSE
	ld [wAttackAnimationIsPlaying], a
	ld a, EFFECTCMDTYPE_INITIAL_EFFECT_2
	call TryExecuteEffectCommandFunction
	jr c, DisplayUsePokemonPowerScreen_WaitForInput
	ld a, EFFECTCMDTYPE_REQUIRE_SELECTION
	call TryExecuteEffectCommandFunction
	ret c
	ld a, OPPACTION_USE_PKMN_POWER
	call SetOppAction_SerialSendDuelData
	call ExchangeRNG
	ld a, OPPACTION_EXECUTE_PKMN_POWER_EFFECT
	call SetOppAction_SerialSendDuelData
	ld a, EFFECTCMDTYPE_BEFORE_DAMAGE
	call TryExecuteEffectCommandFunction
	ld a, OPPACTION_DUEL_MAIN_SCENE
	jp SetOppAction_SerialSendDuelData


; input:
;	hl = text ID
; output:
;	carry = set
DisplayUsePokemonPowerScreen_WaitForInput:
	push hl
	call DisplayUsePokemonPowerScreen
	pop hl
;	fallthrough

; input:
;	hl = text ID
; output:
;	carry = set
DrawWideTextBox_WaitForInput_ReturnCarry:
	call DrawWideTextBox_WaitForInput
	scf
	ret


; uses an attack (from DuelMenu_Attack) or a Pokemon Power (from DuelMenu_PkmnPower)
; input:
;	[wSelectedAttack] = attack index (0 = first attack, 1 = second attack)
;	[hTempCardIndex_ff9f] = Pokémon's deck index (0-59)
;	[wTempCardID_ccc2] = Pokémon's card ID
;	[wLoadedAttack] = Pokémon's attack data (atk_data_struct)
; output:
;	carry = set:  if the effect command returned with carry set
UseAttackOrPokemonPower::
	ld a, [wSelectedAttack]
	ld [wPlayerAttackingAttackIndex], a
	ldh a, [hTempCardIndex_ff9f]
	ld [wPlayerAttackingCardIndex], a
	ld a, [wTempCardID_ccc2]
	ld [wPlayerAttackingCardID], a
	ld a, [wLoadedAttackCategory]
	cp POKEMON_POWER
	jr z, UsePokemonPower
	call UpdateArenaCardIDsAndClearTwoTurnDuelVars
	ld a, EFFECTCMDTYPE_INITIAL_EFFECT_1
	call TryExecuteEffectCommandFunction
	jr c, DrawWideTextBox_WaitForInput_ReturnCarry
	call CheckSmokescreenSubstatus
	jr c, .sand_attack_smokescreen
	ld a, EFFECTCMDTYPE_INITIAL_EFFECT_2
	call TryExecuteEffectCommandFunction
	ret c
	call SendAttackDataToLinkOpponent
	jr .next
.sand_attack_smokescreen
	call SendAttackDataToLinkOpponent
	call HandleSmokescreenSubstatus
	jp c, ClearNonTurnTemporaryDuelvars
	ld a, EFFECTCMDTYPE_INITIAL_EFFECT_2
	call TryExecuteEffectCommandFunction
	ret c
.next
	ld a, OPPACTION_USE_ATTACK
	call SetOppAction_SerialSendDuelData
	ld a, EFFECTCMDTYPE_DISCARD_ENERGY
	call TryExecuteEffectCommandFunction
	call CheckSelfConfusionDamage
	jp c, HandleConfusionDamageToSelf
	call DrawDuelMainScene_PrintPokemonsAttackText
	call WaitForWideTextBoxInput
	call ExchangeRNG
	ld a, EFFECTCMDTYPE_REQUIRE_SELECTION
	call TryExecuteEffectCommandFunction
	ld a, OPPACTION_ATTACK_ANIM_AND_DAMAGE
	call SetOppAction_SerialSendDuelData
;	fallthrough

; input
;	[wLoadedAttack] = Pokémon's attack data (atk_data_struct)
PlayAttackAnimation_DealAttackDamage::
	xor a ; FALSE
	ld [wAttackAnimationIsPlaying], a
	ld a, [wLoadedAttackCategory]
	and RESIDUAL
	jr nz, .deal_damage
	rst SwapTurn
	call HandleNoDamageOrEffectSubstatus
	rst SwapTurn
.deal_damage
	xor a ; PLAY_AREA_ARENA
	ldh [hTempPlayAreaLocation_ff9d], a
	ld a, EFFECTCMDTYPE_BEFORE_DAMAGE
	call TryExecuteEffectCommandFunction
	call ApplyDamageModifiers_DamageToTarget
	call ApplyTransparencyIfApplicable
	ld hl, wDealtDamage
	ld [hl], e
	inc hl
	ld [hl], d
	ld b, PLAY_AREA_ARENA
	ld a, [wDamageEffectiveness]
	ld c, a
	ld a, DUELVARS_ARENA_CARD_HP
	call GetNonTurnDuelistVariable
	push de
	push hl
	call PlayAttackAnimation
	call PlayStatusConditionQueueAnimations
	call WaitAttackAnimation
	pop hl
	pop de
	call SubtractHP
	ld a, [wDuelDisplayedScreen]
	cp DUEL_MAIN_SCENE
	jr nz, .skip_draw_huds
	push hl
	call DrawDuelHUDs
	pop hl
.skip_draw_huds
	call PrintKnockedOutIfHLZero
;	fallthrough

HandleAfterDamageEffects::
	ld a, [wTempNonTurnDuelistCardID]
	push af
	ld a, EFFECTCMDTYPE_AFTER_DAMAGE
	call TryExecuteEffectCommandFunction
	pop af
	ld [wTempNonTurnDuelistCardID], a
	call HandleStrikesBack_AgainstNormalAttack
	call ApplyStatusConditionQueue
	call Func_1bb4
	call UpdateArenaCardLastTurnDamage
	call HandleDestinyBondAndBetweenTurnKnockOuts
	or a
	ret


; this is a simple version of PlayAttackAnimation_DealAttackDamage that doesn't
; take into account status conditions, damage modifiers, etc, for damage calculation.
; used for confusion damage to self and for damage to Benched Pokemon, for example
; preserves de and hl
; input:
;	b = play area location offset (PLAY_AREA_* constant), if applicable
;	c = wDamageEffectiveness constant (to print WEAK or RESIST if necessary)
;	de = damage dealt by the attack
;	h = hWhoseTurn constant  (for animation screen coordinates)
;	l = DUELVARS_ARENA_CARD_HP
;	[wLoadedAttackAnimation] = which animation to play (ATK_ANIM_* constant)
PlayAttackAnimation_DealAttackDamageSimple::
	push hl
	push de
	call PlayAttackAnimation
	call WaitAttackAnimation
	call SubtractHP
	ld a, [wDuelDisplayedScreen]
	cp DUEL_MAIN_SCENE
	call z, DrawDuelHUDs
	pop de
	pop hl
	ret


; called by UseAttackOrPokemonPower (on just an attack) in a link duel.
; it's used to send the other game data about the attack being used,
; triggering a call to OppAction_BeginUseAttack in the receiver.
SendAttackDataToLinkOpponent:
	ld a, [wccec]
	or a
	ret nz
	ldh a, [hTemp_ffa0]
	push af
	ldh a, [hTempCardIndex_ff9f]
	push af
	ld a, $1
	ld [wccec], a
	ld a, [wPlayerAttackingCardIndex]
	ldh [hTempCardIndex_ff9f], a
	ld a, [wPlayerAttackingAttackIndex]
	ldh [hTemp_ffa0], a
	ld a, OPPACTION_BEGIN_ATTACK
	call SetOppAction_SerialSendDuelData
	call ExchangeRNG
	pop af
	ldh [hTempCardIndex_ff9f], a
	pop af
	ldh [hTemp_ffa0], a
	ret


; preserves bc
; output:
;	de = ID for TossCoin notification text
;	carry = set:  if the turn holder's Active Pokemon is affected by Smokescreen
;	              and the result of the coin toss was tails
CheckSmokescreenSubstatus:
	ld a, DUELVARS_ARENA_CARD_SUBSTATUS2
	get_turn_duelist_var
	or a
	ret z ; return if the Active Pokémon isn't affected by any SUBSTATUS2 effects
	ldtx de, SmokescreenCheckText
	cp SUBSTATUS2_SMOKESCREEN
	jr z, .card_is_affected
	or a
	ret
.card_is_affected
	ld a, [wGotHeadsFromSmokescreenCheck]
	or a
	ret nz ; return no carry if coin flip already occurred and the result was heads
	scf
	ret


; output:
;	carry = set:  if the turn holder's attack was unsuccessful due to Smokescreen
;	[wGotHeadsFromSmokescreenCheck] = result of the coin toss (0 = tails, 1 = heads)
HandleSmokescreenSubstatus:
	call CheckSmokescreenSubstatus
	ret nc ; return if the Active Pokemon isn't affected by Smokescreen
	call TossCoin
	ld [wGotHeadsFromSmokescreenCheck], a
	ccf
	ret nc ; return if heads
	ldtx hl, AttackUnsuccessfulText
	jp DrawWideTextBox_WaitForInput_ReturnCarry


; flips a coin to see whether or not a Confused Pokemon will attack itself
; output:
;	carry = set:  if the Active Pokémon is Confused and it flipped a tails
;	[wConfusionAttackCheckWasUnsuccessful] = FALSE: if the attack will proceed as normal
;	                                       = TRUE:  if the Pokémon will attack itself (coin was tails)
CheckSelfConfusionDamage:
	xor a ; FALSE
	ld [wConfusionAttackCheckWasUnsuccessful], a
	ld a, DUELVARS_ARENA_CARD_STATUS
	get_turn_duelist_var
	and CNF_SLP_PRZ
	cp CONFUSED
	jr z, .confused
	or a
	ret
.confused
	ldtx de, ConfusionCheckDamageText
	call TossCoin
	ccf
	ret nc ; return without carry set if heads
	ld a, TRUE
	ld [wConfusionAttackCheckWasUnsuccessful], a
	ret ; c


; called when an Attacking Pokemon deals damage to itself due to confusion.
; displays the corresponding animation and deals 20 damage to the Attacking Pokemon.
HandleConfusionDamageToSelf:
	call DrawDuelMainScene
	ld a, TRUE
	ld [wIsDamageToSelf], a
	ldtx hl, DamageToSelfDueToConfusionText
	call DrawWideTextBox_PrintText
	ld a, ATK_ANIM_CONFUSION_HIT
	ld [wLoadedAttackAnimation], a
	ld a, 20 ; damage
	call DealDamageToSelf
	call Func_1bb4
	call HandleDestinyBondAndBetweenTurnKnockOuts
	call ClearNonTurnTemporaryDuelvars
	or a
	ret


Func_1bb4:
	call FinishQueuedAnimations
	call DrawDuelMainScene
	call DrawDuelHUDs
	xor a ; PLAY_AREA_ARENA
	ldh [hTempPlayAreaLocation_ff9d], a
	call PrintFailedEffectText
	call WaitForWideTextBoxInput
	jp ExchangeRNG


; prints one of the ThereWasNoEffectFrom*Text if wEffectFailed contains EFFECT_FAILED_NO_EFFECT,
; and prints WasUnsuccessfulText if wEffectFailed contains EFFECT_FAILED_UNSUCCESSFUL.
; this and the next function would be ideal candidates for moving to another bank
; if bank $01 becomes full. (saving over 100 bytes for +3 farcalls, and 2 are already bank1calls)
; input:
;	[hTempPlayAreaLocation_ff9d] = Attacking Pokémon's play area location offset (PLAY_AREA_* constant)
;	[wLoadedAttack] = Attacking Pokémon card's attack data (atk_data_struct)
; output:
;	carry = set:  if a text was printed
PrintFailedEffectText:
	ld a, [wEffectFailed]
	or a
	ret z
	cp EFFECT_FAILED_NO_EFFECT
	jr z, .no_effect_from_status
	; a = EFFECT_FAILED_UNSUCCESSFUL
	ldh a, [hTempPlayAreaLocation_ff9d]
	add DUELVARS_ARENA_CARD
	get_turn_duelist_var
	call LoadCardDataToBuffer1_FromDeckIndex
	ld a, 18
	call CopyCardNameAndLevel
	xor a ; TX_END
	ld [hl], a ; terminate the text string at wDefaultText
	; zero wTxRam2 so that the name & level text just loaded to wDefaultText is printed
	ld hl, wTxRam2
	ld [hli], a
	ld [hli], a
	ld de, wLoadedAttackName
	ld a, [de]
	inc de
	ld [hli], a ; wTxRam2_b
	ld a, [de]
	ld [hl], a
	ldtx hl, WasUnsuccessfulText
	call DrawWideTextBox_PrintText
	scf
	ret
.no_effect_from_status
	call PrintThereWasNoEffectFromStatusText
	call DrawWideTextBox_PrintText
	scf
	ret


; loads one of the "There was no effect from" texts depending on the value
; at wNoEffectFromWhichStatus (NO_STATUS or a status condition constant).
; preserves de
; output:
;	hl = ID for notification text
;	[wLoadedAttack] = Attacking Pokémon card's attack data (atk_data_struct)
PrintThereWasNoEffectFromStatusText:
	ld a, [wNoEffectFromWhichStatus]
	or a
	jr nz, .status
	ld hl, wLoadedAttackName
	ld a, [hli]
	ld h, [hl]
	ld l, a
	call LoadTxRam2
	ldtx hl, ThereWasNoEffectFromTxRam2Text
	ret
.status
	ld c, a
	ldtx hl, ThereWasNoEffectFromPoisonConfusionText
	cp POISONED | CONFUSED
	ret z
	ldtx hl, ThereWasNoEffectFromPoisonText
	and PSN_DBLPSN
	ret nz
	ld a, c
	and CNF_SLP_PRZ
	ldtx hl, ThereWasNoEffectFromParalysisText
	cp PARALYZED
	ret z
	ldtx hl, ThereWasNoEffectFromSleepText
	cp ASLEEP
	ret z
	ldtx hl, ThereWasNoEffectFromConfusionText
	ret


; doubles wDamage if the non-turn holder's Active Pokemon
; has Weakness to the type/color of the turn holder's Active Pokemon,
; reduces wDamage by 30 if the non-turn holder's Active Pokemon
; has Resistance to the type/color of the turn holder's Active Pokemon,
; and applies Pluspower, Defender, or any other kinds of damage modifications.
; sets the damage to 0 if reduction would result in a negative value.
; input:
;	[wDamage] = damage value to modify
; output:
;	de = updated damage value
ApplyDamageModifiers_DamageToTarget:
	xor a
	ld [wDamageEffectiveness], a
	ld hl, wDamage
	ld a, [hli]
	ld d, [hl]
	ld e, a
	or d
	jp z, PreventAllDamage ; set de to 0 if wDamage = 0
	xor a ; PLAY_AREA_ARENA
	ldh [hTempPlayAreaLocation_ff9d], a
	bit UNAFFECTED_BY_WEAKNESS_RESISTANCE_F, d
	jr z, .affected_by_wr
	res UNAFFECTED_BY_WEAKNESS_RESISTANCE_F, d
	xor a
	ld [wDamageEffectiveness], a
	call HandleDoubleDamageSubstatus
	jr .check_pluspower_and_defender
.affected_by_wr
	call HandleDoubleDamageSubstatus
	ldh a, [hTempPlayAreaLocation_ff9d]
	call GetPlayAreaCardColor
	call TranslateColorToWR
	ld b, a
	rst SwapTurn
	call GetArenaCardWeakness
	rst SwapTurn
	and b
	jr z, .not_weak
	sla e
	rl d
	ld hl, wDamageEffectiveness
	set WEAKNESS, [hl]
.not_weak
	rst SwapTurn
	call GetArenaCardResistance
	rst SwapTurn
	and b
	jr z, .check_pluspower_and_defender ; jump if Pokemon has no Resistance
	ld hl, -30 ; Resistance is always -30 in this game
	add hl, de
	ld e, l
	ld d, h
	ld hl, wDamageEffectiveness
	set RESISTANCE, [hl]
.check_pluspower_and_defender
	ld b, CARD_LOCATION_ARENA
	call ApplyAttachedPluspower
	rst SwapTurn
	ld b, CARD_LOCATION_ARENA
	call ApplyAttachedDefender
	call HandleDamageReduction
	bit 7, d
	call nz, PreventAllDamage; set damage in de to 0 if it's a negative number
	jp SwapTurn


; checks for anything else that might prevent the attack's damage.
; damage is set to 0 if anything is found.
; input:
;	de = damage being dealt by the attack
;	[wLoadedAttack] = Attacking Pokémon card's attack data (atk_data_struct)
ApplyTransparencyIfApplicable:
	ld a, [wLoadedAttackCategory]
	bit RESIDUAL_F, a
	ret nz ; return if the attack is residual
	ld a, [wNoDamageOrEffect]
	or a
	ret nz ; return if the attack's damage and effects were already negated
	ld a, e
	or d
	jr nz, .attack_opponent ; jump ahead if the attack's damage isn't 0
	ld a, DUELVARS_ARENA_CARD_SUBSTATUS2
	call GetNonTurnDuelistVariable
	or a
	jr nz, .attack_opponent ; jump ahead if the Defending Pokémon has a SUBSTATUS2
	ld a, [wStatusConditionQueueIndex]
	or a
	ret z ; return if there are no pending Special Conditions
.attack_opponent
	push de ; store the attack's damage on the stack
	rst SwapTurn
	xor a ; PLAY_AREA_ARENA
	ld [wTempPlayAreaLocation_cceb], a
	call HandleTransparency
	rst SwapTurn
	pop de ; restore the attack's damage
	ret nc ; return if Transparency isn't going to negate the attack
; Transparency was successful, so reset any SUBSTATUS2 effects and set damage to 0
	call DrawDuelMainScene
	ld a, DUELVARS_ARENA_CARD_SUBSTATUS2
	call GetNonTurnDuelistVariable
	ld [hl], $0
	ld de, 0
	ret


; called after a regular attack is resolved. if the Defending Pokémon
; has an active Strikes Back power and it received damage, then the
; Attacking Pokemon (turn holder's Active Pokemon) also receives 10 damage.
; input:
;	[wLoadedAttack] = Attacking Pokémon card's attack data (atk_data_struct)
;	[wTempTurnDuelistCardID] = Attacking Pokémon's card ID
;	[wTempNonTurnDuelistCardID] = Defending Pokémon's card ID
HandleStrikesBack_AgainstNormalAttack:
	ld a, [wTempNonTurnDuelistCardID]
	cp MACHAMP
	ret nz ; return if the Defending Pokemon isn't a Machamp
	ld a, [wLoadedAttackCategory]
	and RESIDUAL
	ret nz ; return if the attack was residual
	ld a, [wDealtDamage]
	or a
	ret z ; return if the attack didn't do any damage to the Defending Pokémon
	rst SwapTurn
	call CheckIsIncapableOfUsingPkmnPower_ArenaCard
	rst SwapTurn
	ret c  ; return if Pokemon Power can't be used because of status or Toxic Gas
	ld hl, 10 ; amount of damage to give the Attacking Pokemon
	push hl
	call LoadTxRam3
	ld a, [wTempTurnDuelistCardID]
	ld e, a
	call LoadCardDataToBuffer2_FromCardID
	ld hl, wLoadedCard2Name
	ld a, [hli]
	ld h, [hl]
	ld l, a
	call LoadTxRam2
	ld a, DUELVARS_ARENA_CARD_HP
	get_turn_duelist_var
	push af
	pop de
	call SubtractHP
	ldtx hl, ReceivesDamageDueToStrikesBackText
	call DrawWideTextBox_PrintText
	call WaitForWideTextBoxInput
	pop af
	or a
	ret z ; return if the Attacking Pokémon was already Knocked Out
	xor a ; PLAY_AREA_ARENA
	call PrintPlayAreaCardKnockedOutIfNoHP
	jp DrawDuelHUDs


;----------------------------------------
;        UNREFERENCED FUNCTIONS
;----------------------------------------
;
;; Before this function can be used again, SYM_HP_OK must be returned to gfx/fonts/symbols.png
;; and the TX_SYMBOL constant must also be redefined in constants/charmaps.asm
;; preserves de
;; input:
;;	d = maximum HP value
;;	e = current HP value
;DrawHPBar:
;	ld a, MAX_HP
;	ld c, SYM_SPACE
;	call .fill_hp_bar ; empty bar
;	ld a, d
;	ld c, SYM_HP_OK
;	call .fill_hp_bar ; fill (max. HP) with HP counters
;	ld a, d
;	sub e
;	ld c, SYM_DAMAGE_COUNTER
;	; fill (max. HP - current HP) with damaged HP counters
;.fill_hp_bar
;	or a
;	ret z
;	ld hl, wDefaultText
;	ld b, HP_BAR_LENGTH
;.tile_loop
;	ld [hl], c
;	inc hl
;	dec b
;	ret z
;	sub MAX_HP / HP_BAR_LENGTH
;	jr nz, .tile_loop
;	ret
;
;
;; preserves de
;; input:
;;	hl = attack cost (e.g. wLoadedAttackEnergyCost)
;; output:
;;	a & b = total amount of Energy needed to use the given attack
;;	hl = attack name (e.g. wLoadedAttackName)
;CountEnergyInAttackCost:
;	ld b, 0 ; initial counter
;	ld c, NUM_TYPES / 2
;.loop
;	ld a, [hl]
;	swap a
;	and $0f
;	add b
;	ld b, a
;	ld a, [hli]
;	and $0f
;	add b
;	ld b, a
;	dec c
;	jr nz, .loop
;	ret
;
;
;UnreferencedDrawCardFromDeckToHand:
;	call DrawCardFromDeck
;	call nc, AddCardToHand
;	ld a, OPPACTION_DRAW_CARD
;	call SetOppAction_SerialSendDuelData
;	jp PrintDuelMenuAndHandleInput.menu_items_printed
;
;
;Unknown_54e2:
;	db $00, $0c, $06, $0f, $00, $00, $00
;
;
;Func_5542:
;	call CreateDiscardPileCardList
;	ret c
;	call InitAndDrawCardListScreenLayout
;	call SetDiscardPileScreenTexts
;	jp DisplayCardList
;
;
;; colorizes both card images in the main duel scene
;Func_5a81:
;	ld a, [wConsole]
;	or a ; CONSOLE_DMG
;	ret z
;	cp CONSOLE_SGB
;	jr z, .sgb
;	lb de, 0, 5
;	call ApplyBGP7OrSGB2ToCardImage
;	lb de, 12, 1
;	jp ApplyBGP6OrSGB3ToCardImage
;.sgb
;	ld a, 2 << 0 + 2 << 2 ; Data Set #1: Color Palette Designation
;	lb de, 0, 5 ; Data Set #1: X, Y
;	call CreateCardAttrBlkPacket
;	push hl
;	ld a, 2
;	ld [wTempSGBPacket + 1], a ; set number of data sets to 2
;	ld hl, wTempSGBPacket + 8
;	ld a, 3 << 0 + 3 << 2 ; Data Set #2: Color Palette Designation
;	lb de, 12, 1 ; Data Set #2: X, Y
;	call CreateCardAttrBlkPacket_DataSet
;	pop hl
;	jp SendSGB
;
;
;Func_616e:
;	ldh [hTempPlayAreaLocation_ff9d], a
;	call ZeroObjectPositionsAndToggleOAMCopy
;	call EmptyScreen
;	call LoadDuelCardSymbolTiles
;	call LoadDuelCheckPokemonScreenTiles
;	xor a
;	ld [wExcludeArenaPokemon], a
;	call PrintPlayAreaCardList
;	call EnableLCD
;	jp InitAndPrintPlayAreaCardInformationAndLocation
;
;
;; prints 8 (Energy) symbols in a row that were previously stored in wDefaultText
;; input:
;;	bc = screen coordinates at which to begin printing the symbols
;;	wDefaultText = list of (TX_SYMBOL) tiles to print
;Func_6423:
;	ld hl, wDefaultText
;	ld e, $08
;.print_next_symbol
;	ld a, [hli]
;	call WriteByteToBGMap0
;	inc b
;	dec e
;	jr nz, .print_next_symbol
;	ret
;
;
;Func_6ba2:
;	call DrawWideTextBox_PrintText
;	ld a, [wDuelistType]
;	cp DUELIST_TYPE_LINK_OPP
;	ret z
;	jp WaitForWideTextBoxInput
;
;
;; used for testing
;; enters computer opponent selection screen
;; handles input to select/cancel/scroll through deck IDs
;; loads the NPC duel configurations if one was selected
;; output:
;;	carry = set:  if the selection was cancelled with the B button
;Func_7364:
;	xor a
;	ld [wTileMapFill], a
;	call ZeroObjectPositionsAndToggleOAMCopy
;	call EmptyScreen
;	call LoadSymbolsFont
;	lb de, $38, $9f
;	call SetupText
;	call DrawWideTextBox
;	call EnableLCD
;
;	xor a
;	ld [wOpponentDeckID], a
;	call DrawOpponentSelectionScreen
;.wait_input
;	call DoFrame
;	ldh a, [hDPadHeld]
;	or a
;	jr z, .wait_input
;	ld b, a
;
;	; handle selection/cancellation buttons
;	and PAD_A | PAD_START
;	jr nz, .select_opp
;	bit B_PAD_B, b
;	jr nz, .cancel
;
;	; handle D-pad inputs
;	; check right
;	ld a, [wOpponentDeckID]
;	bit B_PAD_RIGHT, b
;	jr z, .check_left
;	inc a ; next deck ID
;	cp NUM_DECK_IDS
;	jr c, .check_left
;	xor a ; wrap around to first deck ID
;
;.check_left
;	bit B_PAD_LEFT, b
;	jr z, .check_up
;	or a
;	jr nz, .not_first_deck_id
;	ld a, NUM_DECK_IDS - 1 ; wrap around to last deck ID
;	jr .check_up
;.not_first_deck_id
;	dec a ; previous deck ID
;
;.check_up
;	bit B_PAD_UP, b
;	jr z, .check_down
;	add 10
;	cp NUM_DECK_IDS
;	jr c, .check_down
;	xor a ; wrap around to first deck ID
;
;.check_down
;	bit B_PAD_DOWN, b
;	jr z, .got_deck_id
;	sub 10
;	jr nc, .got_deck_id
;	ld a, NUM_DECK_IDS - 1; wrap around to last deck ID
;
;.got_deck_id
;	ld [wOpponentDeckID], a
;	call DrawOpponentSelectionScreen
;	jr .wait_input
;
;.cancel
;	scf
;	ret
;.select_opp
;	ld a, [wOpponentDeckID]
;	ld [wNPCDuelDeckID], a
;	call GetNPCDuelConfigurations
;	or a
;	ret
;
;
;; draws the current opponent to be selected (his/her portrait and name)
;; and creates a text box for selection
;DrawOpponentSelectionScreen:
;	ld a, [wOpponentDeckID]
;	ld [wNPCDuelDeckID], a
;	call GetNPCDuelConfigurations
;	jr c, .ok
;	; duel configuration not found for the NPC
;	; so load a default portrait and name
;	xor a
;	ld [wOpponentPortrait], a
;	ld hl, wOpponentName
;	ld [hli], a
;	ld [hl], a
;.ok
;	ld hl, SelectComputerOpponentData
;	call PlaceTextItems
;	call DrawDuelistPortraitsAndNames
;	ld a, [wOpponentDeckID]
;	lb bc, 5, 16
;	call WriteOneByteNumberInTxSymbolFormat_TrimLeadingZeros
;	ld a, [wNPCDuelPrizes]
;	lb bc, 15, 10
;	jp WriteOneByteNumberInTxSymbolFormat_TrimLeadingZeros
;
;SelectComputerOpponentData:
;	textitem 10,  0, ClearOpponentNameText
;	textitem 10, 10, NumberOfPrizesText
;	textitem  3, 14, SelectComputerOpponentText
;	db $ff
;
;
;Func_74dc:
;	call EmptyScreen
;	call EnableLCD
;	ld a, GRASS_ENERGY
;	ld [wPrizeCardSelectionFrameCounter], a
;.wait_input
;	call DoFrame
;	ldh a, [hDPadHeld]
;	ld b, a
;	ld a, [wPrizeCardSelectionFrameCounter]
;. left
;	bit B_PAD_LEFT, b
;	jr z, .right
;	dec a ; previous card
;.right
;	bit B_PAD_RIGHT, b
;	jr z, .up
;	inc a ; next card
;.up
;	bit B_PAD_UP, b
;	jr z, .down
;	add 10
;.down
;	bit B_PAD_DOWN, b
;	jr z, .got_card_id
;	sub 10
;
;.got_card_id
;	ld [wPrizeCardSelectionFrameCounter], a
;	lb bc, 5, 5
;	call WriteOneByteNumberInTxSymbolFormat_TrimLeadingZeros
;	ldh a, [hKeysPressed]
;	and PAD_START
;	jr z, .wait_input
;	ld a, [wPrizeCardSelectionFrameCounter]
;	ld e, a
;	ld d, $0
;.card_loop
;	call LoadCardDataToBuffer1_FromCardID
;	ret c ; card not found
;	push de
;	ld a, e
;	farcall RequestToPrintCard
;	pop de
;	inc de
;	jr .card_loop
;
;
;; reloads a list of cards, except don't print their names
;Func_2827:
;	ld a, $01
;	ldh [hffb0], a
;	call ReloadCardListItems
;	xor a
;	ldh [hffb0], a
;	ret
;
;
;BuildVersion:
;	db "VER 12/20 09:36", TX_END
