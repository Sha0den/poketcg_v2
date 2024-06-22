;---------------------------------------------------------------------------------
; (1) HERE ARE A VARIETY OF CHECK EFFECTS.
; THESE ARE USED TO DETERMINE WHETHER OR NOT A CARD OR ATTACK CAN BE PLAYED.
;---------------------------------------------------------------------------------

; returns carry if neither player has any cards in the deck
BothPlayers_DeckCheck:
	ld a, DUELVARS_NUMBER_OF_CARDS_NOT_IN_DECK
	call GetNonTurnDuelistVariable
	cp DECK_SIZE
	jr c, NoCarryEF
;	fallthrough

; returns carry if there are no cards left in the Turn Duelist's deck
DeckCheck:
	ld a, DUELVARS_NUMBER_OF_CARDS_NOT_IN_DECK
	call GetTurnDuelistVariable
	ldtx hl, NoCardsLeftInTheDeckText
	cp DECK_SIZE
	ccf
	ret

; returns carry if there aren't enough cards in the Turn Duelist's hand
; used for Trainer cards that require you to discard 2 other cards from your hand
OtherCardsInHandCheck:
	ld a, DUELVARS_NUMBER_OF_CARDS_IN_HAND
	call GetTurnDuelistVariable
	ldtx hl, NotEnoughCardsInHandText
	cp 3
	ret

; returns carry if there are no cards in the Turn Duelist's discard pile
DiscardPileCheck:
	ld a, DUELVARS_NUMBER_OF_CARDS_IN_DISCARD_PILE
	call GetTurnDuelistVariable
	ldtx hl, NoCardsInTheDiscardPileText
	cp 1
	ret

; returns carry if there are no Energy cards in the Turn Duelist's discard pile.
DiscardedEnergyCheck:
	call CreateEnergyCardListFromDiscardPile_AllEnergy
	ldtx hl, NoEnergyCardsInDiscardPileText
	ret

; returns carry if there are no Benched Pokemon
TrainerCardAsPokemon_BenchCheck:
	ldh a, [hTempPlayAreaLocation_ff9d]
	ldh [hTemp_ffa0], a
;	fallthrough

; returns carry if there are no Pokemon on the Turn Duelist's Bench
BenchedPokemonCheck:
	ld a, DUELVARS_NUMBER_OF_POKEMON_IN_PLAY_AREA
	call GetTurnDuelistVariable
	ldtx hl, YouNoBenchedPokemonText
	cp 2
	ret

; returns carry if there are Pokemon on the opponent's Bench
Opponent_BenchedPokemonCheck:
	ld a, DUELVARS_NUMBER_OF_POKEMON_IN_PLAY_AREA
	call GetNonTurnDuelistVariable
	ldtx hl, OpponentNoBenchedPokemonText
	cp 2
	ret

; returns carry if neither player has space for more Benched Pokemon.
EitherPlayArea_BenchSpaceCheck:
	ld a, DUELVARS_NUMBER_OF_POKEMON_IN_PLAY_AREA
	call GetNonTurnDuelistVariable
	cp MAX_PLAY_AREA_POKEMON
	jr c, NoCarryEF
;	fallthrough

; returns carry if there are already 5 Pokemon on the Turn Duelist's Bench
BenchSpaceCheck:
	ld a, DUELVARS_NUMBER_OF_POKEMON_IN_PLAY_AREA
	call GetTurnDuelistVariable
	ldtx hl, NoSpaceOnTheBenchText
	cp MAX_PLAY_AREA_POKEMON
	ccf
	ret

NoCarryEF:
	or a
	ret

; returns carry if none of the Turn Duelist's Pokemon have any damage counters.
YourPokemon_DamageCheck:
	ld a, DUELVARS_NUMBER_OF_POKEMON_IN_PLAY_AREA
	call GetTurnDuelistVariable
	ld d, a
	ld e, PLAY_AREA_ARENA
.loop_play_area
	call GetCardDamageAndMaxHP
	or a
	ret nz ; found damage
	inc e
	dec d
	jr nz, .loop_play_area
	; no damage found
	ldtx hl, NoPokemonWithDamageCountersText
	scf
	ret

; returns carry if the player's Active Pokemon has no attached Water Energy
; or if it doesn't have any damage counters.
WaterRecover_EnergyAndHPCheck:
	ld e, PLAY_AREA_ARENA
	call GetPlayAreaCardAttachedEnergies
	ld a, [wAttachedEnergies + WATER]
	ldtx hl, NotEnoughWaterEnergyText
	cp 1
	ret c ; return if not enough energy
	jr ActivePokemon_DamageCheck

; returns carry if the player's Active Pokemon has no Psychic Energy attached
; or if it doesn't have any damage counters
PsychicRecover_EnergyAndHPCheck:
	call ActivePokemon_PsychicEnergyCheck
	ret c ; return if not enough energy
;	fallthrough

; returns carry if the Turn Duelist's Active Pokemon has no damage counters
ActivePokemon_DamageCheck:
	ld e, PLAY_AREA_ARENA
	call GetCardDamageAndMaxHP
	ldtx hl, NoDamageCountersText
	cp 10
	ret

; returns carry if the Turn Duelist's Active Pokemon has no special conditions
ActivePokemon_StatusCheck:
	ld a, DUELVARS_ARENA_CARD_STATUS
	call GetTurnDuelistVariable
	or a
	ret nz
	ldtx hl, NotAffectedBySpecialConditionsText
	scf
	ret

; checks if any of the Turn Duelist's in-play Pokemon
; have any Energy attached to them.
; returns carry set if none are found
YourPokemon_AttachedEnergyCheck:
	ld a, DUELVARS_CARD_LOCATIONS
	call GetTurnDuelistVariable
.loop_deck
	ld a, [hl]
	bit CARD_LOCATION_PLAY_AREA_F, a
	jr z, .next_card ; skip if not in Play Area
	ld a, l
	call LoadCardDataToBuffer2_FromDeckIndex
	ld a, [wLoadedCard2Type]
	and TYPE_ENERGY
	jr nz, NoCarryEF ; found an Energy card
.next_card
	inc l
	ld a, l
	cp DECK_SIZE
	jr c, .loop_deck
	scf
	ret

; returns carry if the Turn Duelist's Active Pokemon
; has fewer than 2 Energy cards attached to it
ActivePokemon_2EnergyCardsCheck:
	xor a ; PLAY_AREA_ARENA
	call CreateArenaOrBenchEnergyCardList
	call CountCardsInDuelTempList
	ldtx hl, NotEnoughEnergyCardsText
	cp 2
	ret

; returns carry if the Turn Duelist's Active Pokemon
; has no Fire Energy attached to it
ActivePokemon_FireEnergyCheck:
	ld e, PLAY_AREA_ARENA
	call GetPlayAreaCardAttachedEnergies
	ldtx hl, NotEnoughFireEnergyText
	ld a, [wAttachedEnergies + FIRE]
	cp 1
	ret

; returns carry if the Turn Duelist's Active Pokemon
; has fewer than 2 Fire Energy cards attached to it
ActivePokemon_DoubleFireEnergyCheck:
	ld e, PLAY_AREA_ARENA
	call GetPlayAreaCardAttachedEnergies
	ld a, [wAttachedEnergies + FIRE]
	ldtx hl, NotEnoughFireEnergyText
	cp 2
	ret

; returns carry if the Turn Duelist's Active Pokemon
; has no Psychic Energy attached to it
ActivePokemon_PsychicEnergyCheck:
	ld e, PLAY_AREA_ARENA
	call GetPlayAreaCardAttachedEnergies
	ld a, [wAttachedEnergies + PSYCHIC]
	ldtx hl, NotEnoughPsychicEnergyText
	cp 1
	ret

; returns carry if the Defending Pokemon has no attacks
DefendingPokemon_AttackCheck:
	call SwapTurn
	ld a, DUELVARS_ARENA_CARD
	call GetTurnDuelistVariable
	call LoadCardDataToBuffer2_FromDeckIndex
	ld a, [wLoadedCard2Atk1Category]
	cp POKEMON_POWER
	jr nz, .has_attack
	ld hl, wLoadedCard2Atk2Name
	ld a, [hli]
	or [hl]
	jr nz, .has_attack
; has no attack
	call SwapTurn
	ldtx hl, NoAttackMayBeChosenText
	scf
	ret
.has_attack
	call SwapTurn
	or a
	ret

; returns carry if the Defending Pokemon is not Asleep
DefendingPokemon_SleepCheck:
	ld a, DUELVARS_ARENA_CARD_STATUS
	call GetNonTurnDuelistVariable
	and CNF_SLP_PRZ
	cp ASLEEP
	ret z ; return nc if Asleep
	ldtx hl, OpponentIsNotAsleepText
	scf
	ret

; returns carry if neither player has any Evolved Pokemon.
EitherPlayArea_EvolvedPokemonCheck:
	call SwapTurn
	call YourPlayArea_EvolvedPokemonCheck
	call SwapTurn
	ret nc
;	fallthrough

; checks if there is at least one Evolved Pokemon
; in the Turn Duelist's Play Area.
; returns carry if none are found
YourPlayArea_EvolvedPokemonCheck:
	ld a, DUELVARS_ARENA_CARD
	call GetTurnDuelistVariable
	ld d, h
	ld e, DUELVARS_ARENA_CARD_STAGE
.loop
	ld a, [hli]
	cp $ff
	jr z, .set_carry
	ld a, [de]
	inc de
	or a
	jr z, .loop ; is Basic Stage
	ret
.set_carry
	ldtx hl, NoEvolvedPokemonText
	scf
	ret
;
;Alt_YourPlayArea_EvolvedPokemonCheck:
;	ld a, DUELVARS_NUMBER_OF_POKEMON_IN_PLAY_AREA
;	call GetTurnDuelistVariable
;	ld c, a
;	ld l, DUELVARS_ARENA_CARD
;.loop
;	ld a, [hli]
;	call LoadCardDataToBuffer2_FromDeckIndex
;	ld a, [wLoadedCard2Stage]
;	or a
;	ret nz ; found an Evolution card
;	dec c
;	jr nz, .loop
;
;	ldtx hl, NoEvolvedPokemonText
;	scf
;	ret

; checks if the Pokemon Power was already used that turn
; also checks for Muk's Toxic Gas or any relevant special conditions if active
; returns carry if the Pokemon Power can't be used
OncePerTurnPokePowerCheck:
	ldh a, [hTempPlayAreaLocation_ff9d]
	ldh [hTemp_ffa0], a
	add DUELVARS_ARENA_CARD_FLAGS
	call GetTurnDuelistVariable
	and USED_PKMN_POWER_THIS_TURN
	jr nz, .already_used
	ldh a, [hTempPlayAreaLocation_ff9d]
	jp CheckCannotUseDueToStatus_OnlyToxicGasIfANon0
.already_used
	ldtx hl, OnlyOncePerTurnText
;	fallthrough

SetCarryEF:
	scf
	ret


;---------------------------------------------------------------------------------
; (2) NEXT ARE SOME FUNCTIONS THAT ARE FREQUENTLY CALLED BY OTHER FUNCTIONS
;---------------------------------------------------------------------------------

; returns carry if the Player is the Turn Duelist
IsPlayerTurn:
	ld a, DUELVARS_DUELIST_TYPE
	call GetTurnDuelistVariable
	cp DUELIST_TYPE_PLAYER
	jr z, SetCarryEF ; player
	or a
	ret

TossCoin_BankB:
	jp TossCoin

TossCoinATimes_BankB:
	jp TossCoinATimes

; formerly Func_2c08a
Serial_TossCoin:
	ld a, $1
;	fallthrough

; formerly Func_2c08c
Serial_TossCoinATimes:
	push de
	push af
	ld a, OPPACTION_TOSS_COIN_A_TIMES
	call SetOppAction_SerialSendDuelData
	pop af
	pop de
	call SerialSend8Bytes
	jp TossCoinATimes

Func_61a1:
	xor a
	ld [wExcludeArenaPokemon], a
	ld a, [wDuelDisplayedScreen]
	cp PLAY_AREA_CARD_LIST
	ret z
	call ZeroObjectPositionsAndToggleOAMCopy
	call EmptyScreen
	call LoadDuelCardSymbolTiles
	jp LoadDuelCheckPokemonScreenTiles

Func_2c10b:
	ldh [hTempPlayAreaLocation_ff9d], a
	call Func_61a1
	bank1call PrintPlayAreaCardList_EnableLCD
	bank1call Func_6194
	ret

; formerly Func_2fea9
; input:
;	a = attack animation to play
PlayTrainerEffectAnimation:
	ld [wLoadedAttackAnimation], a
	xor a
	ld [wce7e], a
	ld bc, $0
	ldh a, [hWhoseTurn]
	ld h, a
	bank1call PlayAttackAnimation
	jp WaitAttackAnimation

; prompts the Player with a Yes/No question whether to quit the screen,
; even though they can select more cards from list.
; [hCurSelectionItem] holds the number of cards
; that were already selected by the Player.
; input:
;	a = total number of cards that can be selected
; output:
;	carry set if "No" was selected
AskWhetherToQuitSelectingCards:
	ld hl, hCurSelectionItem
	sub [hl]
	ld l, a
	ld h, $00
	call LoadTxRam3
	ldtx hl, YouCanSelectMoreCardsQuitText
	jp YesOrNoMenuWithText

CardDiscardEffect:
	ldh a, [hTemp_ffa0]
	jp PutCardInDiscardPile

AlternateCardDiscardEffect:
	ldh a, [hTempList]
	jp PutCardInDiscardPile

; draws the symbol in a next to the selection cursor,
; meant to be used when choosing a Pokemon
; from the detailed in-play Pokemon screen
; input:
;	a = TX_SYMBOL (SYM_?)
DrawSymbolOnPlayAreaCursor:
	ld c, a
	add a
	add c
	add 2
	; a = 3*a + 2
	ld c, a
	ld a, b
	ld b, 0
	jp WriteByteToBGMap0

; outputs in hl the next position in hTempList to place a new card,
; and increments hCurSelectionItem.
GetNextPositionInTempList:
	push de
	ld hl, hCurSelectionItem
	ld a, [hl]
	inc [hl]
	ld e, a
	ld d, $00
	ld hl, hTempList
	add hl, de
	pop de
	ret

; returns carry if Defending has No Damage or Effect
; if so, print its appropriate text.
HandleNoDamageOrEffect:
	call CheckNoDamageOrEffect
	ret nc
	ld a, l
	or h
	call nz, DrawWideTextBox_PrintText
	scf
	ret

; sets up the cursor for the detailed in-play Pokemon screen
PlayAreaSelectionMenuParameters:
	db 0, 0 ; cursor x, cursor y
	db 3 ; y displacement between items
	db MAX_PLAY_AREA_POKEMON ; number of items
	db SYM_CURSOR_R ; cursor tile number
	db SYM_SPACE ; tile behind cursor
	dw NULL ; function pointer if non-0


;---------------------------------------------------------------------------------
; (3) THIS IS THE START OF THE ATTACK FUNCTIONS
; EFFECTS THAT REARRANGE, DRAW FROM, OR PULL CARDS OUT OF THE DECK ARE FIRST.
;---------------------------------------------------------------------------------

; draw and handle player selection for reordering the top 3 cards of the deck.
; the resulting list is output in order in hTempList.
HandleProphecyScreen:
	ld a, DUELVARS_NUMBER_OF_CARDS_NOT_IN_DECK
	call GetTurnDuelistVariable
	ld b, a
	ld a, DECK_SIZE
	sub [hl] ; a = number of cards in deck

; store in c the number of cards that will be reordered.
; this number is 3, unless the deck has fewer cards than that,
; in which case it will be the number of cards remaining.
	ld c, 3
;	fallthrough

ReorderCardsOnTopOfDeck:
	cp c
	jr nc, .got_number_cards
	ld c, a ; store number of remaining cards in c
.got_number_cards
	ld a, c
	inc a
	ld [wNumberOfCardsToOrder], a

; store in wDuelTempList the cards that are going to be reordered.
	ld a, b
	add DUELVARS_DECK_CARDS
	ld l, a
	ld de, wDuelTempList
.loop_top_cards
	ld a, [hli]
	ld [de], a
	inc de
	dec c
	jr nz, .loop_top_cards
	ld a, $ff ; terminating byte
	ld [de], a

; wDuelTempList + 10 will be filled with numbers from 1 to the maximum number of cards to reorder.
; the first item in that list corresponds to the first card, second item to second card, etc.
; and the number in the list corresponds to the ordering number.
.start
	call CountCardsInDuelTempList
	ld b, a
	ld a, 1 ; start at 1
	; fill order list with zeroes
	ldh [hCurSelectionItem], a
	; initialize buffer ahead in wDuelTempList.
	ld hl, wDuelTempList + 10
	xor a
.loop_init_buffer
	ld [hli], a
	dec b
	jr nz, .loop_init_buffer
	ld [hl], $ff ; terminating byte

; display card list to order
	bank1call InitAndDrawCardListScreenLayout
	ldtx hl, ChooseTheOrderOfTheCardsText
	ldtx de, DuelistDeckText
	call SetCardListHeaderText
	bank1call Func_5735

.loop_selection
	bank1call DisplayCardList
	jr c, .clear ; if B is pressed, undo last order selection

; first check if this card was already selected
	ldh a, [hCurMenuItem]
	ld e, a
	ld d, $00
	ld hl, wDuelTempList + 10
	add hl, de
	ld a, [hl]
	or a
	jr nz, .loop_selection ; already chosen

; being here means card hasn't been selected yet,
; so add its order number to buffer and
; increment the sort number for the next card.
	ldh a, [hCurSelectionItem]
	ld [hl], a
	inc a
	ldh [hCurSelectionItem], a

; refresh screen
	push af
	bank1call Func_5744
	pop af

; check if we're done ordering
	ldh a, [hCurSelectionItem]
	ld hl, wNumberOfCardsToOrder
	cp [hl]
	jr c, .loop_selection ; reset loop if there are more cards to select

; confirm that the ordering has been completed
	call EraseCursor
	ldtx hl, IsThisOKText
	call YesOrNoMenuWithText_LeftAligned
	jr c, .start ; "No" returns back to beginning of selection

; write in hTempList the card list in order that was selected.
	ld hl, wDuelTempList + 10
	ld de, wDuelTempList
	ld c, 0
	ret

.clear
; check if any reordering was done.
	ld hl, hCurSelectionItem
	ld a, [hl]
	cp 1
	jr z, .loop_selection ; already at first input, nothing to undo

; clear the order that was selected thus far.
	dec a
	ld [hl], a
	ld c, a
	ld hl, wDuelTempList + 10
.loop_clear
	ld a, [hli]
	cp c
	jr nz, .loop_clear
	; clear this byte
	dec hl
	ld [hl], $00 ; overwrite order number with 0
	bank1call Func_5744
	jr .loop_selection

Prophecy_PlayerSelection:
	ldtx hl, ProcedureForProphecyText
	bank1call DrawWholeScreenTextBox
.select_deck
	bank1call DrawDuelMainScene
	ldtx hl, PleaseSelectTheDeckText
	call TwoItemHorizontalMenu
	ldh a, [hKeysHeld]
	and B_BUTTON
	jr nz, Prophecy_PlayerSelection ; loop back to start

	ldh a, [hCurMenuItem]
	ldh [hTempList], a ; store selection in first position in list
	or a
	jr z, .turn_duelist

; non-Turn Duelist
	ld a, DUELVARS_NUMBER_OF_CARDS_NOT_IN_DECK
	call GetNonTurnDuelistVariable
	cp DECK_SIZE
	jr nc, .select_deck ; no cards, go back to deck selection
	call SwapTurn
	call HandleProphecyScreen
	call ProphecyLoopOrder
	jp SwapTurn

.turn_duelist
	ld a, DUELVARS_NUMBER_OF_CARDS_NOT_IN_DECK
	call GetTurnDuelistVariable
	cp DECK_SIZE
	jr nc, .select_deck ; no cards, go back to deck selection
	call HandleProphecyScreen
;	fallthrough

ProphecyLoopOrder:
	ld a, [hli]
	cp $ff
	jr z, .done
	push hl
	push bc
	ld c, a
	ld b, $00
	ld hl, hTempList
	add hl, bc
	ld a, [de]
	ld [hl], a
	pop bc
	pop hl
	inc de
	inc c
	jr ProphecyLoopOrder

; now hTempList has the list of card deck indices
; in the order selected to be place on top of the deck.
.done
	ld b, $00
	ld hl, hTempList + 1
	add hl, bc
	ld [hl], $ff ; terminating byte
	or a
	ret

; AI doesn't ever choose this attack so this does no sorting.
Prophecy_AISelection:
	ld a, $ff
	ldh [hTemp_ffa0], a
	ret

Prophecy_ReorderEffect:
	ld hl, hTempList
	ld a, [hli]
	or a
	jr z, Reordering ; Turn Duelist's deck
	cp $ff
	ret z

	; non-Turn Duelist's deck
	call SwapTurn
	call Reordering
	jp SwapTurn

Pokedex_PlayerSelection:
; print text box
	ldtx hl, RearrangeThe5CardsAtTopOfDeckText
	call DrawWideTextBox_WaitForInput

; cap the number of cards to reorder up to the number of cards in deck (maximum of 5)
	ld a, DUELVARS_NUMBER_OF_CARDS_NOT_IN_DECK
	call GetTurnDuelistVariable
	ld b, a
	ld a, DECK_SIZE
	sub [hl]
	ld c, 5
	call ReorderCardsOnTopOfDeck
;	fallthrough

; almost identical to ProphecyLoop order
; uses hTempCardIndex_ff9f/hTempList instead of hTempList/hTempList + 1
PokedexLoopOrder:
	ld a, [hli]
	cp $ff
	jr z, .done
	push hl
	push bc
	ld c, a
	ld b, $00
	ld hl, hTempCardIndex_ff9f
	add hl, bc
	ld a, [de]
	ld [hl], a
	pop bc
	pop hl
	inc de
	inc c
	jr PokedexLoopOrder

; now hTempList has the list of card deck indices
; in the order selected to be place on top of the deck.
.done
	ld b, $00
	ld hl, hTempList
	add hl, bc
	ld [hl], $ff ; terminating byte
	or a
	ret

Pokedex_ReorderEffect:
	ld hl, hTempList
;	fallthrough

Reordering:
	ld c, 0

; add selected cards to hand in the specified order
.loop_place_hand
	ld a, [hli]
	cp $ff
	jr z, .place_top_deck
	call SearchCardInDeckAndAddToHand
	inc c
	jr .loop_place_hand

; go to the last card that was in the list
; and iterate in decreasing order,
; placing each card on top of the deck
.place_top_deck
	dec hl
	dec hl

; return the cards to the top of the deck
.loop_place_deck
	ld a, [hld]
	call ReturnCardToDeck
	dec c
	jr nz, .loop_place_deck
	
; opponent's notification from the original Prophecy function
	call IsPlayerTurn
	ret c
	ldtx hl, RearrangedCardsInDuelistsDeckText
	jp DrawWideTextBox_WaitForInput

DrawCard50PercentEffect:
	ldtx de, IfHeadsDraw1CardFromDeckText
	call TossCoin_BankB
	ret nc ; tails
;	fallthrough

; Used with EFFECTCMDTYPE_AFTER_DAMAGE for the effect of an attack
DrawCardEffect:
	ldtx hl, Draw1CardFromTheDeckText
	call DrawWideTextBox_WaitForInput
;	fallthrough

; Used with EFFECTCMDTYPE_BEFORE_DAMAGE for the effect of a Trainer card
Draw1CardFromDeck:
	bank1call DisplayDrawOneCardScreen
	call DrawCardFromDeck
	ret c ; return if deck is empty
	call AddCardToHand
	call LoadCardDataToBuffer1_FromDeckIndex
	ld a, [wDuelistType]
	cp DUELIST_TYPE_PLAYER
	ret nz
	; show card on screen if it was Player
	bank1call OpenCardPage_FromHand
	ret

; Used with EFFECTCMDTYPE_AFTER_DAMAGE for the effect of an attack
Draw2CardsEffect:
	ldtx hl, Draw2CardsText
	call DrawWideTextBox_WaitForInput
;	fallthrough

; Used with EFFECTCMDTYPE_BEFORE_DAMAGE for the effect of a Trainer card
Draw2CardsFromDeck:
	ld a, 2
;	fallthrough

; input:
;	a = number of cards to draw
DrawNCards_ShowCardDetails:
	ld c, a
	bank1call DisplayDrawNCardsScreen
.loop_draw
	call DrawCardFromDeck
	ret c
	ldh [hTempCardIndex_ff98], a
	call AddCardToHand
	call IsPlayerTurn
	jr nc, .skip_display_screen
	push bc
	bank1call DisplayPlayerDrawCardScreen
	pop bc
.skip_display_screen
	dec c
	jr nz, .loop_draw
	ret

; You can replace the question marks (?) in the following functions
; with whatever number of cards that you want to have the player draw.
; Obviously, the first function isn't necessary if you're creating a Trainer effect.
; After adding the numbers, remove a semicolon from each of the lines and create the new text.
;; Used with EFFECTCMDTYPE_AFTER_DAMAGE for the effect of an attack
;Draw?CardsEffect:
;	ldtx hl, Draw?CardsText
;	call DrawWideTextBox_WaitForInput
;;	fallthrough
;
;; Used with EFFECTCMDTYPE_BEFORE_DAMAGE for the effect of a Trainer card
;Draw?CardsFromDeck:
;	ld a, ?
;	jr DrawNCards_ShowCardDetails

ProfessorOakEffect:
; discard every card in the hand
	call CreateHandCardList
	call SortCardsInDuelTempListByID
	ld hl, wDuelTempList
.discard_loop
	ld a, [hli]
	cp $ff
	jr z, .draw_cards
	call RemoveCardFromHand
	call PutCardInDiscardPile
	jr .discard_loop
.draw_cards
	ld a, 7
;	fallthrough

; input:
;   a: number of cards to draw
DrawNCards_NoCardDetails:
	ld c, a
	bank1call DisplayDrawNCardsScreen
.loop_draw
	call DrawCardFromDeck
	ret c
	call AddCardToHand
	dec c
	jr nz, .loop_draw
	ret

AddCardFromDeckToHandEffect:
	ldh a, [hTemp_ffa0]
	cp $ff
	jr z, ShuffleCardsInDeck

; add to hand
	call SearchCardInDeckAndAddToHand
	call AddCardToHand
	call IsPlayerTurn
	jr c, ShuffleCardsInDeck ; done if Player played card

; display card in screen
	ldh a, [hTemp_ffa0]
	ldtx hl, WasPlacedInTheHandText
	bank1call DisplayCardDetailScreen
;	fallthrough

; formerly Func_2c0bd
ShuffleCardsInDeck:
	call ExchangeRNG
	bank1call DeckShuffleAnimation
	jp ShuffleDeck

EnergySearch_PlayerSelection:
	farcall FindBasicEnergy
	ret

AttachBasicEnergyFromDeck_PlayerSelection:
	farcall FindBasicEnergyToAttach
	ret

AttachBasicEnergyFromDeck_AISelection:
	farcall AIFindBasicEnergyToAttach

AttachBasicEnergyFromDeck_AttachEffect:
	ldh a, [hTemp_ffa0]
	cp $ff
	jr z, ShuffleCardsInDeck

; add card to the hand and attach it to the selected Pokemon
	call SearchCardInDeckAndAddToHand
	call AddCardToHand
	ldh a, [hTempPlayAreaLocation_ffa1]
	ld e, a
	ldh a, [hTemp_ffa0]
	call PutHandCardInPlayArea
	call IsPlayerTurn
	jr c, ShuffleCardsInDeck

; not Player, so show detail screen and which Pokemon was chosen to attach Energy
	ldh a, [hTempPlayAreaLocation_ffa1]
	add DUELVARS_ARENA_CARD
	call GetTurnDuelistVariable
	call LoadCardDataToBuffer1_FromDeckIndex
	ld hl, wLoadedCard1Name
	ld de, wTxRam2_b
	ld a, [hli]
	ld [de], a
	inc de
	ld a, [hli]
	ld [de], a
	ldh a, [hTemp_ffa0]
	ldtx hl, AttachedEnergyToPokemonText
	bank1call DisplayCardDetailScreen
	jr ShuffleCardsInDeck

TrainerSearch_PlayerSelection:
	farcall FindTrainer
	ret

TrainerSearch_AISelection:
	farcall AIFindTrainer
	ret

EvolutionSearch_PlayerSelection:
	farcall FindEvolution
	ret

EvolutionSearch_AISelection:
	farcall AIFindEvolution
	ret

; returns carry if the deck is empty or if the Bench if full
CallForF_CheckDeckAndPlayArea:
	call DeckCheck
	ret c ; return if no cards in deck
	jp BenchSpaceCheck

CallForF_PutInPlayAreaEffect:
	ldh a, [hTemp_ffa0]
	cp $ff
	jp z, ShuffleCardsInDeck ; finish because no card was selected
	call SearchCardInDeckAndAddToHand
	call AddCardToHand
	call PutHandPokemonCardInPlayArea
	call IsPlayerTurn
	jp c, ShuffleCardsInDeck

; display card on the screen
	ldh a, [hTemp_ffa0]
	ldtx hl, PlacedOnTheBenchText
	bank1call DisplayCardDetailScreen
	jp ShuffleCardsInDeck

CallForFamily_PlayerSelection:
	farcall FindBasicPokemon
	ret

CallForFamily_AISelection:
	farcall AIFindBasicPokemon
	ret

CallForFighting_PlayerSelection:
	farcall FindBasicFightingPokemon
	ret

CallForFighting_AISelection:
	farcall AIFindBasicFighting
	ret

CallForNidoran_PlayerSelection:
	farcall FindNidoran
	ret

CallForNidoran_AISelection:
	farcall AIFindNidoran
	ret

CallForOddish_PlayerSelection:
	farcall FindOddish
	ret

CallForOddish_AISelection:
	farcall AIFindOddish
	ret

CallForBellsprout_PlayerSelection:
	farcall FindBellsprout
	ret

CallForBellsprout_AISelection:
	farcall AIFindBellsprout
	ret

CallForKrabby_PlayerSelection:
	farcall FindKrabby
	ret

CallForKrabby_AISelection:
	farcall AIFindKrabby
	ret

CallForRandomBasic50PercentEffect:
	ldtx de, AttackSuccessCheckText
	call TossCoin_BankB
	jr c, .successful

.none_came_text
	ldtx hl, ThereWasNoEffectText
	jp DrawWideTextBox_WaitForInput

.successful
	call PickRandomBasicCardFromDeck
	jr nc, .put_in_bench
	ld a, ATK_ANIM_FRIENDSHIP_SONG
	call Func_2c12e
	call .none_came_text
	jp ShuffleCardsInDeck

.put_in_bench
	call SearchCardInDeckAndAddToHand
	call AddCardToHand
	call PutHandPokemonCardInPlayArea
	ld a, ATK_ANIM_FRIENDSHIP_SONG
	call Func_2c12e
	ldh a, [hTempCardIndex_ff98]
	ldtx hl, PlacedOnTheBenchText
	bank1call DisplayCardDetailScreen
	jp ShuffleCardsInDeck

Func_2c12e:
	ld [wLoadedAttackAnimation], a
	ldh a, [hTempPlayAreaLocation_ff9d]
	ld b, a
	ld c, $0 ; neither WEAKNESS nor RESISTANCE
	ldh a, [hWhoseTurn]
	ld h, a
	bank1call PlayAttackAnimation
	jp WaitAttackAnimation

; returns in a and [hTempCardIndex_ff98] the deck index
; of random Basic Pokemon card in deck.
; returns carry if no Pokemon were found.
PickRandomBasicCardFromDeck:
	call CreateDeckCardList
	ret c ; return if deck is empty
	ld hl, wDuelTempList
	call ShuffleCards
.loop_deck
	ld a, [hli]
	ldh [hTempCardIndex_ff98], a
	cp $ff
	jp z, SetCarryEF
	call CheckDeckIndexForBasicPokemon
	jr nc, .loop_deck ; skip if not a Basic Pokemon
	ldh a, [hTempCardIndex_ff98]
	or a
	ret

RandomlyFillBothBenchesEffect:
	call SwapTurn
	call .FillBench
	call SwapTurn
	call .FillBench

; display both Play Areas
	ldtx hl, BasicPokemonWasPlacedOnEachBenchText
	call DrawWideTextBox_WaitForInput
	bank1call HasAlivePokemonInPlayArea
	bank1call OpenPlayAreaScreenForSelection
	call SwapTurn
	bank1call HasAlivePokemonInPlayArea
	bank1call OpenPlayAreaScreenForSelection
	jp SwapTurn

.FillBench
	call CreateDeckCardList
	ret c
	ld hl, wDuelTempList
	call ShuffleCards

; return if there's no more space on the Bench
.check_bench
	push hl
	ld a, DUELVARS_NUMBER_OF_POKEMON_IN_PLAY_AREA
	call GetTurnDuelistVariable
	pop hl
	cp MAX_PLAY_AREA_POKEMON
	jp nc, ShuffleCardsInDeck ; finish because bench is full

; there's still space, so look for the next
; Basic Pokemon card to put on the Bench.
.loop
	ld a, [hli]
	ldh [hTempCardIndex_ff98], a
	cp $ff
	jp z, ShuffleCardsInDeck ; done with loop
	call CheckDeckIndexForBasicPokemon
	jr nc, .loop ; skip if not a Basic Pokemon
; place card onto the Bench
	push hl
	ldh a, [hTempCardIndex_ff98]
	call SearchCardInDeckAndAddToHand
	call AddCardToHand
	call PutHandPokemonCardInPlayArea
	pop hl
	jr .check_bench


;---------------------------------------------------------------------------------
; (4) ATTACK EFFECTS THAT PULL CARDS OUT OF THE DISCARD PILE ARE NEXT.
;---------------------------------------------------------------------------------

; returns carry if there isn't a Psychic Energy to discard
; or if there are no Trainer cards in the discard pile
Scavenge_DiscardPileAndEnergyCheck:
	call ActivePokemon_PsychicEnergyCheck
	ret c ; return if no Psychic energy attached
	jr CreateTrainerCardListFromDiscardPile

; returns carry if there aren't enough cards in the hand to discard
; or if there are no Trainer cards in the discard pile
ItemFinderCheck:
	call OtherCardsInHandCheck
	ret c
;	fallthrough

; makes a list in wDuelTempList with the deck indices
; of cards found in the Turn Duelist's discard pile.
; returns carry set if no Trainer cards were found,
; also loads the corresponding notification text
CreateTrainerCardListFromDiscardPile:
; get number of cards in the discard pile and have hl point
; to the end of the discard pile list in wOpponentDeckCards.
	ld a, DUELVARS_NUMBER_OF_CARDS_IN_DISCARD_PILE
	call GetTurnDuelistVariable
	ld b, a
	add DUELVARS_DECK_CARDS
	ld l, a

	ld de, wDuelTempList
	inc b
	jr .next_card

.check_trainer
	ld a, [hl]
	call LoadCardDataToBuffer2_FromDeckIndex
	ld a, [wLoadedCard2Type]
	cp TYPE_TRAINER
	jr nz, .next_card

	ld a, [hl]
	ld [de], a
	inc de

.next_card
	dec l
	dec b
	jr nz, .check_trainer

	ld a, $ff ; terminating byte
	ld [de], a
	ld a, [wDuelTempList]
	cp $ff
	jr z, .no_trainers
	or a
	ret
.no_trainers
	ldtx hl, NoTrainerCardsInDiscardPileText
	scf
	ret

; makes a list in wDuelTempList with the deck indices
; of all Basic Energy cards found in the Turn Duelist's discard pile.
CreateEnergyCardListFromDiscardPile_OnlyBasic:
	ld c, $01
	jr CreateEnergyCardListFromDiscardPile

; makes a list in wDuelTempList with the deck indices
; of all Energy cards (including Special Energy cards)
; found in the Turn Duelist's discard pile.
CreateEnergyCardListFromDiscardPile_AllEnergy:
	ld c, $00
;	fallthrough

; makes a list in wDuelTempList with the deck indices
; of Energy cards found in the Turn Duelist's discard pile.
; if (c == 0), all Energy cards are allowed;
; if (c != 0), Special Energy cards are not included.
; returns carry if no energy cards were found.
CreateEnergyCardListFromDiscardPile:
; get number of cards in the discard pile
; and have hl point to the end of the
; discard pile list in wOpponentDeckCards.
	ld a, DUELVARS_NUMBER_OF_CARDS_IN_DISCARD_PILE
	call GetTurnDuelistVariable
	ld b, a
	add DUELVARS_DECK_CARDS
	ld l, a

	ld de, wDuelTempList
	inc b
	jr .next_card

.check_energy
	ld a, [hl]
	call LoadCardDataToBuffer2_FromDeckIndex
	ld a, [wLoadedCard2Type]
	and TYPE_ENERGY
	jr z, .next_card

; if (c != $00), then we dismiss any Special Energy cards
	ld a, c
	or a
	jr z, .copy
	ld a, [wLoadedCard2Type]
	cp TYPE_ENERGY + NUM_COLORED_TYPES
	jr nc, .next_card

.copy
	ld a, [hl]
	ld [de], a
	inc de

; goes through the discard pile list in wOpponentDeckCards in descending order.
.next_card
	dec l
	dec b
	jr nz, .check_energy

; terminating byte on wDuelTempList
	ld a, $ff
	ld [de], a

; check if any energy card was found by checking
; whether the first byte in wDuelTempList is $ff.
; returns carry if none were found
	ld a, [wDuelTempList]
	cp $ff
	jp z, SetCarryEF
	or a
	ret

; makes a list in wDuelTempList with all of the Basic Pokemon cards
; that are in the Turn Duelist's discard pile.
; returns carry if none are found.
CreateBasicPokemonCardListFromDiscardPile:
; gets hl to point to the last card in the discard pile
; and iterates the cards in reverse order.
	ld a, DUELVARS_NUMBER_OF_CARDS_IN_DISCARD_PILE
	call GetTurnDuelistVariable
	ld b, a
	add DUELVARS_DECK_CARDS
	ld l, a
	ld de, wDuelTempList
	inc b
	jr .next_discard_pile_card

.check_card
	ld a, [hl]
	call CheckDeckIndexForBasicPokemon
	jr nc, .next_discard_pile_card ; skip if not a Basic Pokemon

; write this card's index to wDuelTempList
	ld a, [hl]
	ld [de], a
	inc de
.next_discard_pile_card
	dec l
	dec b
	jr nz, .check_card

; done with the loop.
	ld a, $ff ; terminating byte
	ld [de], a
	ld a, [wDuelTempList]
	cp $ff
	jp z, SetCarryEF
	or a
	ret

; AI picks the first available Energy/Trainer in the location
Scavenge_AISelection:
	call DiscardAttachedPsychicEnergy_AISelection
	call CreateTrainerCardListFromDiscardPile
	ld a, [wDuelTempList]
	ldh [hTempPlayAreaLocation_ffa1], a
	ret

Scavenge_TrainerPlayerSelection:
	call CreateTrainerCardListFromDiscardPile
	bank1call Func_5591
	ldtx hl, PleaseSelectCardText
	ldtx de, YourDiscardPileText
	call SetCardListHeaderText
.loop_input
	bank1call DisplayCardList
	jr c, .loop_input ; must choose, B button can't be used to exit
	ldh a, [hTempCardIndex_ff98]
	ldh [hTempPlayAreaLocation_ffa1], a
	ret

Scavenge_MoveToHandEffect:
	ldh a, [hTempPlayAreaLocation_ffa1]
	call MoveDiscardPileCardToHand
	call AddCardToHand
	call IsPlayerTurn
	ret c
	ldh a, [hTempPlayAreaLocation_ffa1]
	ldtx hl, WasPlacedInTheHandText
	bank1call DisplayCardDetailScreen
	ret

; draws a list of Energy cards in the discard pile
; the Player can select up to 2 cards from the list.
; these cards are given in $ff-terminated list in hTempList.
Choose2EnergyFromDiscardPile_PlayerSelection:
	xor a
	ldh [hCurSelectionItem], a
	call CreateEnergyCardListFromDiscardPile_AllEnergy
	ldtx hl, Choose2EnergyCardsFromDiscardPileText
	jr c, .finish

	call DrawWideTextBox_WaitForInput
.loop
; draws the discard pile screen and textbox,
; and handles Player input
	bank1call InitAndDrawCardListScreenLayout
	ldtx hl, ChooseAnEnergyCardText
	ldtx de, YourDiscardPileText
	call SetCardListHeaderText
	bank1call DisplayCardList
	jr nc, .selected

; Player is trying to exit screen,
; but can select up to 2 cards total.
; prompt Player to confirm exiting screen.
	ld a, 2
	call AskWhetherToQuitSelectingCards
	jr c, .loop
	jr .finish

; a card was selected, so add it to the list
.selected
	call GetNextPositionInTempList
	ldh a, [hTempCardIndex_ff98]
	ld [hl], a
	call RemoveCardFromDuelTempList
	or a
	jr z, .finish ; no more cards?
	ldh a, [hCurSelectionItem]
	cp 2
	jr c, .loop ; already selected 2 cards?

; place terminating byte on list
.finish
	call GetNextPositionInTempList
	ld [hl], $ff
	or a
	ret

; AI picks the first 2 Energy cards in the discard pile
Choose2EnergyFromDiscardPile_AISelection:
	call CreateEnergyCardListFromDiscardPile_AllEnergy
	ld hl, wDuelTempList
	ld de, hTempList
	ld c, 2 ; need 2 Energy
.loop
	ld a, [hli]
	cp $ff
	jr z, .done
	ld [de], a
	inc de
	dec c
	jr nz, .loop
.done
	ld a, $ff ; terminating byte
	ld [de], a
	ret

EnergyConversion_RecoilAndMoveCardsToHand:
; damage itself
	ld a, 10
	call DealRecoilDamageToSelf

; loop cards that were chosen until $ff is reached,
; and move them to the hand.
	ld hl, hTempList
	ld de, wDuelTempList
.loop_cards
	ld a, [hli]
	ld [de], a
	inc de
	cp $ff
	jr z, .done
	call MoveDiscardPileCardToHand
	call AddCardToHand
	jr .loop_cards

.done
	call IsPlayerTurn
	ret c
	bank1call DisplayCardListDetails
	ret

EnergyAbsorption_AttachEffect:
	ld hl, hTempList
.loop
	ld a, [hli]
	cp $ff
	ret z
	push hl
	call MoveDiscardPileCardToHand
	call GetTurnDuelistVariable
	ld [hl], CARD_LOCATION_ARENA
	pop hl
	jr .loop


;---------------------------------------------------------------------------------
; (5) ATTACK EFFECTS THAT BENEFIT THE PLAYER'S POKEMON ARE NEXT. (MAINLY HEALING)
;---------------------------------------------------------------------------------

SwitchAfterAttack_PlayerSelection:
	ldtx hl, SelectNewActivePokemonText
	call DrawWideTextBox_WaitForInput
	bank1call HasAlivePokemonInBench
	ld a, $01
	ld [wPlayAreaSelectAction], a
.loop_input
	bank1call OpenPlayAreaScreenForSelection
	jr c, .loop_input ; must choose, B button can't be used to exit
	ldh a, [hTempPlayAreaLocation_ff9d]
	ldh [hTemp_ffa0], a
	ret

SwitchAfterAttack_AISelection:
	ld a, DUELVARS_NUMBER_OF_POKEMON_IN_PLAY_AREA
	call GetTurnDuelistVariable
	call Random
	ldh [hTemp_ffa0], a
	ret

SwitchAfterAttack_SwitchEffect:
	ldh a, [hTemp_ffa0]
	ld e, a
	call SwapArenaWithBenchPokemon
	xor a
	ld [wDuelDisplayedScreen], a
	ret

GaleAnimationEffect:
	ld a, ATK_ANIM_GALE
	ld [wLoadedAttackAnimation], a
	ret

RandomlySwitchBothActivePokemon:
; if the Defending Pokemon is unaffected by the attack,
; then jump directly to switching this card.
	call HandleNoDamageOrEffect
	jr c, .SwitchWithRandomBenchPokemon

; handle switching the Defending Pokemon
	ld a, DUELVARS_ARENA_CARD_HP
	call GetNonTurnDuelistVariable
	or a
	jr nz, .skip_destiny_bond
	call HandleDestinyBondSubstatus
.skip_destiny_bond
	call SwapTurn
	call .SwitchWithRandomBenchPokemon
	jr c, .skip_clear_damage
; clear dealt damage because the Pokemon was switched
	xor a
	ld hl, wDealtDamage
	ld [hli], a
	ld [hl], a
.skip_clear_damage
	call SwapTurn
	; fallthrough for switching the attacking Pokemon

.SwitchWithRandomBenchPokemon
	ld a, DUELVARS_NUMBER_OF_POKEMON_IN_PLAY_AREA
	call GetTurnDuelistVariable
	cp 2
	ret c ; return if there are no Benched Pokemon

; get a random Bench location and swap
	dec a
	call Random
	inc a
	ld e, a
	call SwapArenaWithBenchPokemon

	xor a
	ld [wDuelDisplayedScreen], a
	ret

Healing50Percent_FlipEffect:
	ldtx de, AttackSuccessCheckText
	call TossCoin_BankB
	ldh [hTemp_ffa0], a
	ret c ; flipped heads
	xor a ; ATK_ANIM_NONE
	ld [wLoadedAttackAnimation], a
	jp SetWasUnsuccessful

Healing50Percent_Heal10Effect:
	ldh a, [hTemp_ffa0]
	or a
	ret z ; coin toss was tails
	ld e, PLAY_AREA_ARENA
	call GetCardDamageAndMaxHP
	or a
	ret z ; no damage counters to remove
	ld a, DUELVARS_ARENA_CARD_HP
	call GetTurnDuelistVariable
	add 10
	ld [hl], a
	ret

Drain10Effect:
	ld hl, wDealtDamage
	ld a, [hli]
	or a
	ret z ; return if no damage was dealt
;	fallthrough

Heal10_HealEffect:
	ld de, 10
	jr ApplyAndAnimateHPRecovery

DrainHalfEffect:
	ld hl, wDealtDamage
	ld a, [hli]  ; wDamageEffectiveness
	or a
	ret z  ; return if no damage was dealt
	call HalfARoundedUp
	ld e, a
	ld d, [hl]
	jr ApplyAndAnimateHPRecovery
;
;Alt_DrainHalfEffect:
;	ld hl, wDealtDamage
;	ld a, [hli]
;	ld h, [hl]
;	ld l, a
;	srl h
;	rr l
;	bit 0, l
;	jr z, .rounded
;	; round up to nearest 10
;	ld de, 5 ; or 10 / 2
;	add hl, de
;.rounded
;	ld e, l
;	ld d, h
;	jr ApplyAndAnimateHPRecovery

DrainAllEffect:
	ld hl, wDealtDamage
	ld e, [hl]
	inc hl ; wDamageEffectiveness
	ld d, [hl]
;	fallthrough

; applies HP recovery on Pokemon after an attack
; with HP recovery effect, and handles its animation.
; input:
;	d = damage effectiveness
;	e = HP amount to recover
ApplyAndAnimateHPRecovery:
	push de
	ld hl, wccbd
	ld [hl], e
	inc hl
	ld [hl], d

; gets the Active Pokemon's damage
	ld e, PLAY_AREA_ARENA
	call GetCardDamageAndMaxHP
	pop de
	or a
	ret z ; return if no damage

; load the correct animation
	push de
	ld a, ATK_ANIM_HEAL
	ld [wLoadedAttackAnimation], a
	ld bc, $01 ; arrow
	bank1call PlayAttackAnimation

; compare HP to be restored with max HP.
; if HP to be restored would cause HP to
; be larger than max HP, cap it accordingly
	ld e, PLAY_AREA_ARENA
	call GetCardDamageAndMaxHP
	ld b, $00
	pop de
	ld a, DUELVARS_ARENA_CARD_HP
	call GetTurnDuelistVariable
	add e
	ld e, a
	xor a
	adc d
	ld d, a
	; de = damage dealt + current HP
	; bc = max HP of card
	call CompareDEtoBC
	jr c, .skip_cap
	; cap de to value in bc
	ld e, c
	ld d, b

.skip_cap
	ld [hl], e ; apply new HP to the Active Pokemon
	jp WaitAttackAnimation

Recover_HealEffect:
	ld e, PLAY_AREA_ARENA
	call GetCardDamageAndMaxHP
	ld e, a ; all damage for recovery
	ld d, 0
	jr ApplyAndAnimateHPRecovery

RemoveSpecialConditionsEffect:
	ld a, ATK_ANIM_FULL_HEAL
	call PlayTrainerEffectAnimation
	ld a, DUELVARS_ARENA_CARD_STATUS
	call GetTurnDuelistVariable
	ld [hl], NO_STATUS
	bank1call DrawDuelHUDs
	ret


;---------------------------------------------------------------------------------
; (6) ATTACK EFFECTS THAT CAUSE SPECIAL CONDITIONS ARE NEXT
;---------------------------------------------------------------------------------

Sleep50PercentEffect:
	ldtx de, SleepCheckText
	call TossCoin_BankB
	ret nc

SleepEffect:
	lb bc, PSN_DBLPSN, ASLEEP
	jr QueueStatusCondition

Confusion50PercentEffect:
	ldtx de, ConfusionCheckText
	call TossCoin_BankB
	ret nc

ConfusionEffect:
	lb bc, PSN_DBLPSN, CONFUSED
	jr QueueStatusCondition

Paralysis50PercentEffect:
	ldtx de, ParalysisCheckText
	call TossCoin_BankB
	ret nc

ParalysisEffect: 
	lb bc, PSN_DBLPSN, PARALYZED
	jr QueueStatusCondition

; the Defending Pokémon becomes double poisoned
; it takes 20 damage per turn rather than 10
DoublePoisonEffect:
	lb bc, CNF_SLP_PRZ, DOUBLE_POISONED
	jr QueueStatusCondition

Poison50PercentEffect:
	ldtx de, PoisonCheckText
	call TossCoin_BankB
	ret nc

PoisonEffect:
	lb bc, CNF_SLP_PRZ, POISONED
;	fallthrough

QueueStatusCondition:
	ldh a, [hWhoseTurn]
	ld hl, wWhoseTurn
	cp [hl]
	jr nz, .can_induce_status
	ld a, [wTempNonTurnDuelistCardID]
	cp CLEFAIRY_DOLL
	jr z, .cant_induce_status
	cp MYSTERIOUS_FOSSIL
	jr z, .cant_induce_status
	; Snorlax's Thick Skinned prevents it from being statused...
	cp SNORLAX
	jr nz, .can_induce_status
	call SwapTurn
	; ...unless already so, or if affected by Muk's Toxic Gas
	call CheckCannotUseDueToStatus
	call SwapTurn
	jr c, .can_induce_status

.cant_induce_status
	ld a, c
	ld [wNoEffectFromWhichStatus], a
	call SetNoEffectFromStatus
	or a
	ret

.can_induce_status
	ld hl, wStatusConditionQueueIndex
	push hl
	ld e, [hl]
	ld d, $0
	ld hl, wStatusConditionQueue
	add hl, de
	call SwapTurn
	ldh a, [hWhoseTurn]
	ld [hli], a
	call SwapTurn
	ld [hl], b ; mask of status conditions not to discard on the target
	inc hl
	ld [hl], c ; status condition to inflict to the target
	pop hl
	; advance wStatusConditionQueueIndex
	inc [hl]
	inc [hl]
	inc [hl]
	scf
	ret

; If heads, Defending Pokemon is Poisoned. If tails, it's Confused.
PoisonOrConfusionEffect:
	ldtx de, PoisonedIfHeadsConfusedIfTailsText
	call TossCoin_BankB
	jr c, PoisonEffect
	jr ConfusionEffect

AllOrNothingParalysisEffect:
	ldtx de, AttackSuccessCheckText
	call TossCoin_BankB
	jr c, ParalysisEffect
	; unsuccessful
	xor a ; ATK_ANIM_NONE
	ld [wLoadedAttackAnimation], a
	call SetDefiniteDamage
	jp SetWasUnsuccessful

SpitPoison_Poison50PercentEffect:
	ldtx de, PoisonCheckText
	call TossCoin_BankB
	jr c, PoisonEffect
	ld a, ATK_ANIM_SPIT_POISON_SUCCESS
	ld [wLoadedAttackAnimation], a
;	fallthrough

SetNoEffectFromStatus:
	ld a, EFFECT_FAILED_NO_EFFECT
	ld [wEffectFailed], a
	ret

MayInflictPoison_AIEffect:
	ld a, 5
	lb de, 0, 10
;	fallthrough

; Stores information about the attack damage for AI purposes
; taking into account poison damage between turns.
; if target poisoned
;	[wAIMinDamage] <- [wDamage]
;	[wAIMaxDamage] <- [wDamage]
; else
;	[wAIMinDamage] <- [wDamage] + d
;	[wAIMaxDamage] <- [wDamage] + e
;	[wDamage]      <- [wDamage] + a
UpdateExpectedAIDamage_AccountForPoison:
	push af
	ld a, DUELVARS_ARENA_CARD_STATUS
	call GetNonTurnDuelistVariable
	and POISONED | DOUBLE_POISONED
	jr z, UpdateExpectedAIDamage.skip_push_af
	pop af
	jp SetDefiniteAIDamage

InflictPoison_AIEffect:
	ld a, 10
	lb de, 10, 10
	jr UpdateExpectedAIDamage_AccountForPoison

Toxic_AIEffect:
	ld a, 20
	lb de, 20, 20 ; min damage should be 0 if already double poisoned
	jr UpdateExpectedAIDamage_AccountForPoison

; Sets some variables for AI use
;	[wAIMinDamage] <- [wDamage] + d
;	[wAIMaxDamage] <- [wDamage] + e
;	[wDamage]      <- [wDamage] + a
UpdateExpectedAIDamage:
	push af

.skip_push_af
	ld hl, wDamage
	ld a, [hl]
	add d
	ld [wAIMinDamage], a
	ld a, [hl]
	add e
	ld [wAIMaxDamage], a
	pop af
	add [hl]
	ld [hl], a
	ret

Sleep50PercentWithoutDamageEffect:
	call Sleep50PercentEffect
	call nc, SetWasUnsuccessful
	ret

Confusion50PercentWithoutDamageEffect:
	call Confusion50PercentEffect
	call nc, SetWasUnsuccessful
	ret

PoisonConfusion50PercentEffect:
	ldtx de, VenomPowderCheckText
	call TossCoin_BankB
	ret nc ; return if tails
	; heads
	call PoisonEffect
	call ConfusionEffect
	ret c
	ld a, CONFUSED | POISONED
	ld [wNoEffectFromWhichStatus], a
	ret

; the Defending Pokemon and the user both become Confused
ConfuseBothActivePokemonEffect:
	call ConfusionEffect
	call SwapTurn
	call ConfusionEffect
	jp SwapTurn


;---------------------------------------------------------------------------------
; (7) ATTACK EFFECTS THAT CAUSE SUBSTATUS1 EFFECTS ARE NEXT.
; THESE ARE BENEFICIAL EFFECTS THAT ARE APPLIED TO THE PLAYER'S ACTIVE POKEMON.
;---------------------------------------------------------------------------------

SwordsDanceEffect:
	ld a, [wTempTurnDuelistCardID]
	cp SCYTHER
	ret nz
	ld a, SUBSTATUS1_NEXT_TURN_DOUBLE_DAMAGE
;	fallthrough

; apply a status condition of type 1 identified by register a to the target
ApplySubstatus1ToDefendingCard:
	push af
	ld a, DUELVARS_ARENA_CARD_SUBSTATUS1
	call GetTurnDuelistVariable
	pop af
	ld [hli], a
	ret

FocusEnergyEffect:
	ld a, [wTempTurnDuelistCardID]
	cp VAPOREON_LV29
	ret nz ; return if no VaporeonLv29
	ld a, SUBSTATUS1_NEXT_TURN_DOUBLE_DAMAGE
	jr ApplySubstatus1ToDefendingCard

ImmunityEffect:
	ld a, SUBSTATUS1_IMMUNITY
	jr ApplySubstatus1ToDefendingCard

; If heads, prevent all damage and attack effects done to user next turn
Immunity50PercentEffect:
	ldtx de, IfHeadsDoNotReceiveDamageOrEffectText
	call TossCoin_BankB
	ret nc ; return if tails
	ld a, ATK_ANIM_AGILITY_PROTECT
	ld [wLoadedAttackAnimation], a
	ld a, SUBSTATUS1_IMMUNITY
	jr ApplySubstatus1ToDefendingCard

AllOrNothingImmunityEffect:
	ldtx de, AttackSuccessCheckText
	call TossCoin_BankB
	jr c, .heads
	xor a ; ATK_ANIM_NONE
	ld [wLoadedAttackAnimation], a
	call SetDefiniteDamage
	jp SetWasUnsuccessful
.heads
	ld a, ATK_ANIM_AGILITY_PROTECT
	ld [wLoadedAttackAnimation], a
	ld a, SUBSTATUS1_IMMUNITY
	jr ApplySubstatus1ToDefendingCard

; If heads, prevent all damage done to user next turn
DamageProtection50PercentEffect:
	ldtx de, IfHeadsNoDamageNextTurnText
	call TossCoin_BankB
	jp c, .heads
	xor a ; ATK_ANIM_NONE
	ld [wLoadedAttackAnimation], a
	jp SetWasUnsuccessful
.heads
	ld a, SUBSTATUS1_NO_DAMAGE
	jr ApplySubstatus1ToDefendingCard

; Prevent all damage done to user next turn, as long as it's 30 or less
HardenEffect:
	ld a, SUBSTATUS1_HARDEN
	jr ApplySubstatus1ToDefendingCard

; Prevent 10 damage done to user next turn
Prevent10DamageEffect:
	ld a, SUBSTATUS1_REDUCE_BY_10
	jr ApplySubstatus1ToDefendingCard

; Prevent 20 damage done to user next turn
Prevent20DamageEffect:
	ld a, SUBSTATUS1_REDUCE_BY_20
	jr ApplySubstatus1ToDefendingCard

HalveDamageEffect:
	ld a, SUBSTATUS1_HALVE_DAMAGE
	jr ApplySubstatus1ToDefendingCard

DestinyBondEffect:
	ld a, SUBSTATUS1_DESTINY_BOND
	jr ApplySubstatus1ToDefendingCard


;---------------------------------------------------------------------------------
; (8) ATTACK EFFECTS THAT CAUSE SUBSTATUS2 EFFECTS ARE NEXT.
; THESE ARE HARMFUL EFFECTS THAT ARE APPLIED TO THE OPPONENT'S ACTIVE POKEMON.
; (THE LAST FUNCTION IS ACTUALLY SUBSTATUS3)
;---------------------------------------------------------------------------------

; Prevent 10 damage done to user by the Defending Pokémon next turn
ReduceBy10Effect:
	ld a, SUBSTATUS2_REDUCE_BY_10
	jr ApplySubstatus2ToDefendingCard

; Prevent 20 damage done to user by the Defending Pokémon next turn
ReduceBy20Effect:
	ld a, SUBSTATUS2_REDUCE_BY_20
	jr ApplySubstatus2ToDefendingCard

; If heads, the Defending Pokemon can't retreat next turn
NoRetreat50PercentEffect:
	ldtx de, AcidCheckText
	call TossCoin_BankB
	ret nc
	ld a, SUBSTATUS2_UNABLE_RETREAT
	jr ApplySubstatus2ToDefendingCard

NoRetreatEffect:
	ld a, SUBSTATUS2_UNABLE_RETREAT
	jr ApplySubstatus2ToDefendingCard

SmokescreenEffect:
	ld a, SUBSTATUS2_SMOKESCREEN
;	fallthrough

; apply a status condition of type 2 identified by register a to the target,
; unless prevented by wNoDamageOrEffect
ApplySubstatus2ToDefendingCard:
	push af
	call CheckNoDamageOrEffect
	jr c, .no_damage_orEffect
	ld a, DUELVARS_ARENA_CARD_SUBSTATUS2
	call GetNonTurnDuelistVariable
	pop af
	ld [hl], a
	ld l, DUELVARS_ARENA_CARD_LAST_TURN_SUBSTATUS2
	ld [hl], a
	ret

.no_damage_orEffect
	pop af
	push hl
	bank1call DrawDuelMainScene
	pop hl
	ld a, l
	or h
	call nz, DrawWideTextBox_PrintText
	ret

CannotAttack50PercentEffect:
	ldtx de, IfHeadsOpponentCannotAttackText
	call TossCoin_BankB
	ret nc
	ld a, SUBSTATUS2_CANNOT_ATTACK
	jr ApplySubstatus2ToDefendingCard

CannotAttackThis50PercentEffect:
	ldtx de, IfHeadsOpponentCannotAttackText
	call TossCoin_BankB
	jp c, .heads
	xor a ; ATK_ANIM_NONE
	ld [wLoadedAttackAnimation], a
	jp SetWasUnsuccessful
.heads
	ld a, SUBSTATUS2_CANNOT_ATTACK_THIS
	jr ApplySubstatus2ToDefendingCard

Amnesia_PlayerSelection:
	ldtx hl, ChooseAttackOpponentWillNotBeAbleToUseText
	call DrawWideTextBox_WaitForInput
	call HandleDefendingPokemonAttackSelection
	ld a, e
	ldh [hTemp_ffa0], a
	ret

Amnesia_AISelection:
; load the Defending Pokemon's attacks
	call SwapTurn
	ld e, PLAY_AREA_ARENA
	call GetPlayAreaCardAttachedEnergies
	call HandleEnergyBurn
	ld a, DUELVARS_ARENA_CARD
	call GetTurnDuelistVariable
	ld d, a
	call LoadCardDataToBuffer2_FromDeckIndex
	ld hl, wLoadedCard2Atk1Name
	ld a, [hli]
	or [hl]
	jr z, .chosen ; done if card doesn't have an attack 1 name

; if the Defending Pokemon has enough energy for its second attack, choose it
	ld e, SECOND_ATTACK
	bank1call _CheckIfEnoughEnergiesToAttack
	jr nc, .chosen
; otherwise choose the first attack, unless its a Pokemon Power
	ld e, FIRST_ATTACK_OR_PKMN_POWER
	ld a, [wLoadedCard2Atk1Category]
	cp POKEMON_POWER
	jr nz, .chosen
; if it's a Pokemon Power, choose the second attack.
	ld e, SECOND_ATTACK
.chosen
	ld a, e
	ldh [hTemp_ffa0], a
	jp SwapTurn

; applies Amnesia effect on the Defending Pokemon for attack index in hTemp_ffa0
AttackDisableEffect:
	ld a, SUBSTATUS2_AMNESIA
	call ApplySubstatus2ToDefendingCard
	ld a, [wNoDamageOrEffect]
	or a
	ret nz ; no effect

; set selected attack as disabled
	ld a, DUELVARS_ARENA_CARD_DISABLED_ATTACK_INDEX
	call GetNonTurnDuelistVariable
	ldh a, [hTemp_ffa0]
	ld [hl], a

	ld l, DUELVARS_ARENA_CARD_LAST_TURN_EFFECT
	ld [hl], LAST_TURN_EFFECT_AMNESIA

	call IsPlayerTurn
	ret c ; return if Player

; the rest of the routine is for the opponent to announce which attack was disabled
	call SwapTurn
	ld a, DUELVARS_ARENA_CARD
	call GetTurnDuelistVariable
	ld d, a
	ldh a, [hTemp_ffa0]
	ld e, a
	call GetAttackName
	call LoadTxRam2
	ldtx hl, WasChosenForTheEffectOfAmnesiaText
	call DrawWideTextBox_WaitForInput
	jp SwapTurn

; handles the Player selection of the attack to use Amnesia or Metronome on.
; returns carry if none selected.
; outputs:
;	d = card index of defending card
;	e = attack index selected
HandleDefendingPokemonAttackSelection:
	bank1call DrawDuelMainScene
	call SwapTurn
	xor a
	ldh [hCurSelectionItem], a

.start
	bank1call PrintAndLoadAttacksToDuelTempList
	push af
	ldh a, [hCurSelectionItem]
	ld hl, .menu_parameters
	call InitializeMenuParameters
	pop af

	ld [wNumMenuItems], a
	call EnableLCD
.loop_input
	call DoFrame
	ldh a, [hKeysPressed]
	bit B_BUTTON_F, a
	jr nz, .set_carry
	and START
	jr nz, .open_atk_page
	call HandleMenuInput
	jr nc, .loop_input
	cp -1
	jr z, .loop_input

; an attack was selected
	ldh a, [hCurMenuItem]
	add a
	ld e, a
	ld d, $00
	ld hl, wDuelTempList
	add hl, de
	ld d, [hl]
	inc hl
	ld e, [hl]
	call SwapTurn
	or a
	ret

.set_carry
	call SwapTurn
	scf
	ret

.open_atk_page
	ldh a, [hCurMenuItem]
	ldh [hCurSelectionItem], a
	ld a, DUELVARS_ARENA_CARD
	call GetTurnDuelistVariable
	call LoadCardDataToBuffer1_FromDeckIndex
	bank1call OpenAttackPage
	call SwapTurn
	bank1call DrawDuelMainScene
	call SwapTurn
	jr .start

.menu_parameters
	db 1, 13 ; cursor x, cursor y
	db 2 ; y displacement between items
	db 2 ; number of items
	db SYM_CURSOR_R ; cursor tile number
	db SYM_SPACE ; tile behind cursor
	dw NULL ; function pointer if non-0

; loads in hl the pointer to attack's name.
; input:
;	d = deck index of card
; 	e = attack index (0 = first attack, 1 = second attack)
GetAttackName:
	ld a, d
	call LoadCardDataToBuffer1_FromDeckIndex
	ld hl, wLoadedCard1Atk1Name
	inc e
	dec e
	jr z, .load_name
	ld hl, wLoadedCard1Atk2Name
.load_name
	ld a, [hli]
	ld h, [hl]
	ld l, a
	ret

; returns carry if the Defending Pokemon has no weakness
Conversion1_WeaknessCheck:
	call SwapTurn
	ld a, DUELVARS_ARENA_CARD
	call GetTurnDuelistVariable
	call LoadCardDataToBuffer2_FromDeckIndex
	call SwapTurn
	ld a, [wLoadedCard2Weakness]
	or a
	ret nz
	ldtx hl, NoWeaknessText
	scf
	ret

Conversion1_PlayerSelection:
	ldtx hl, ChooseWeaknessYouWishToChangeText
	xor a ; PLAY_AREA_ARENA
	call HandleColorChangeScreen
	ldh [hTemp_ffa0], a
	ret

Conversion1_ChangeWeaknessEffect:
	call HandleNoDamageOrEffect
	ret c ; is unaffected

; apply changed weakness
	ld a, DUELVARS_ARENA_CARD_CHANGED_WEAKNESS
	call GetNonTurnDuelistVariable
	ldh a, [hTemp_ffa0]
	call TranslateColorToWR
	ld [hl], a
	ld l, DUELVARS_ARENA_CARD_LAST_TURN_CHANGE_WEAK
	ld [hl], a

; print text box
	call SwapTurn
	ldtx hl, ChangedTheWeaknessOfPokemonToColorText
	call PrintActivePokemonNameAndColorText
	call SwapTurn

; apply substatus
	ld a, SUBSTATUS2_CONVERSION2
	jp ApplySubstatus2ToDefendingCard

; returns carry if the Active Pokemon has no Resistance.
Conversion2_ResistanceCheck:
	ld a, DUELVARS_ARENA_CARD
	call GetTurnDuelistVariable
	call LoadCardDataToBuffer2_FromDeckIndex
	ld a, [wLoadedCard2Resistance]
	or a
	ret nz
	ldtx hl, NoResistanceText
	scf
	ret

Conversion2_PlayerSelection:
	ldtx hl, ChooseResistanceYouWishToChangeText
	ld a, $80
	call HandleColorChangeScreen
	ldh [hTemp_ffa0], a
	ret

; AI will choose the Defending Pokemon's color, unless it's Colorless
Conversion2_AISelection:
	call SwapTurn
	ld a, DUELVARS_ARENA_CARD
	call GetTurnDuelistVariable
	call LoadCardDataToBuffer1_FromDeckIndex
	call SwapTurn
	ld a, [wLoadedCard1Type]
	cp COLORLESS
	jr z, .is_colorless
	ldh [hTemp_ffa0], a
	ret

.is_colorless
	call SwapTurn
	call AISelectConversionColor
	jp SwapTurn

; apply the change to the Pokemon's resistance
Conversion2_ChangeResistanceEffect:
	ld a, DUELVARS_ARENA_CARD_CHANGED_RESISTANCE
	call GetTurnDuelistVariable
	ldh a, [hTemp_ffa0]
	call TranslateColorToWR
	ld [hl], a
	ldtx hl, ChangedTheResistanceOfPokemonToColorText
;	fallthrough

; prints text that requires card name and color,
; with the card name of the player's Active Pokemon
; and color in [hTemp_ffa0].
; input:
;	hl = text to print
PrintActivePokemonNameAndColorText:
	push hl
	ld a, DUELVARS_ARENA_CARD
	call GetTurnDuelistVariable
	call LoadCardDataToBuffer1_FromDeckIndex
	ldh a, [hTemp_ffa0]
	call LoadCardNameAndInputColor
	pop hl
	jp DrawWideTextBox_PrintText

; handles drawing and selection of screen for choosing a color (excluding colorless),
; used for Shift Pokemon Power and Conversion attacks.
; outputs in a the color that was selected or returns carry if B button was pressed.
; input:
;	a  = Play Area location (PLAY_AREA_*), with:
;	     bit 7 not set if it's applying to opponent's card
;	     bit 7 set if it's applying to player's card
;	hl = text to be printed in the bottom box
; output:
;	a = color that was selected
HandleColorChangeScreen:
	or a
	call z, SwapTurn
	push af
	call .DrawScreen
	pop af
	call z, SwapTurn

	ld hl, .menu_params
	xor a
	call InitializeMenuParameters
	call EnableLCD

.loop_input
	call DoFrame
	call HandleMenuInput
	jr nc, .loop_input
	cp -1 ; b pressed?
	jp z, SetCarryEF
	ld e, a
	ld d, $00
	ld hl, ShiftListItemToColor
	add hl, de
	ld a, [hl]
	or a
	ret

.menu_params
	db 1, 1 ; cursor x, cursor y
	db 2 ; y displacement between items
	db MAX_PLAY_AREA_POKEMON ; number of items
	db SYM_CURSOR_R ; cursor tile number
	db SYM_SPACE ; tile behind cursor
	dw NULL ; function pointer if non-0

.DrawScreen
	push hl
	push af
	call EmptyScreen
	call ZeroObjectPositions
	call LoadDuelCardSymbolTiles

; load card data
	pop af
	and $7f
	ld [wTempPlayAreaLocation_cceb], a
	add DUELVARS_ARENA_CARD
	call GetTurnDuelistVariable
	call LoadCardDataToBuffer1_FromDeckIndex

; draw card gfx
	ld de, v0Tiles1 + $20 tiles ; destination offset of loaded gfx
	ld hl, wLoadedCard1Gfx
	ld a, [hli]
	ld h, [hl]
	ld l, a
	lb bc, $30, TILE_SIZE
	call LoadCardGfx
	bank1call SetBGP6OrSGB3ToCardPalette
	bank1call FlushAllPalettesOrSendPal23Packet
	ld a, $a0
	lb hl, 6, 1
	lb de, 9, 2
	lb bc, 8, 6
	call FillRectangle
	bank1call ApplyBGP6OrSGB3ToCardImage

; print card name and level at the top
	ld a, 16
	call CopyCardNameAndLevel
	ld [hl], $00
	lb de, 7, 0
	call InitTextPrinting
	ld hl, wDefaultText
	call ProcessText

; list all the colors
	ld hl, ShiftMenuData
	call PlaceTextItems

; print card's color, resistance and weakness
	ld a, [wTempPlayAreaLocation_cceb]
	call GetPlayAreaCardColor
	inc a
	lb bc, 15, 9
	call WriteByteToBGMap0
	ld a, [wTempPlayAreaLocation_cceb]
	call GetPlayAreaCardWeakness
	lb bc, 15, 10
	bank1call PrintCardPageWeaknessesOrResistances
	ld a, [wTempPlayAreaLocation_cceb]
	call GetPlayAreaCardResistance
	lb bc, 15, 11
	bank1call PrintCardPageWeaknessesOrResistances

	call DrawWideTextBox

; print list of color names on all list items
	lb de, 4, 1
	ldtx hl, ColorListText
	call InitTextPrinting_ProcessTextFromID

; print input hl to text box
	lb de, 1, 14
	pop hl
	call InitTextPrinting_ProcessTextFromID

; draw and apply palette to color icons
	ld hl, ColorTileAndBGP
	lb de, 2, 0
	ld c, NUM_COLORED_TYPES
.loop_colors
	ld a, [hli]
	push de
	push bc
	push hl
	lb hl, 1, 2
	lb bc, 2, 2
	call FillRectangle

	ld a, [wConsole]
	cp CONSOLE_CGB
	jr nz, .skip_vram1
	pop hl
	push hl
	call BankswitchVRAM1
	ld a, [hl]
	lb hl, 0, 0
	lb bc, 2, 2
	call FillRectangle
	call BankswitchVRAM0

.skip_vram1
	pop hl
	pop bc
	pop de
	inc hl
	inc e
	inc e
	dec c
	jr nz, .loop_colors
	ret

ShiftListItemToColor:
	db GRASS
	db FIRE
	db WATER
	db LIGHTNING
	db FIGHTING
	db PSYCHIC

ShiftMenuData:
	; x, y, text id
	textitem 10,  9, TypeText
	textitem 10, 10, WeaknessText
	textitem 10, 11, ResistanceText
	db $ff

ColorTileAndBGP:
	; tile, cgb palette
	db ICON_TILE_GRASS,     $02
	db ICON_TILE_FIRE,      $01
	db ICON_TILE_WATER,     $02
	db ICON_TILE_LIGHTNING, $01
	db ICON_TILE_FIGHTING,  $03
	db ICON_TILE_PSYCHIC,   $03

; loads wTxRam2 and wTxRam2_b:
; [wTxRam2]   <- wLoadedCard1Name
; [wTxRam2_b] <- input color as text symbol
; input:
;	a = type (color) constant
LoadCardNameAndInputColor:
	add a
	ld e, a
	ld d, $00
	ld hl, ColorToTextSymbol
	add hl, de

; load wTxRam2 with card's name
	ld de, wTxRam2
	ld a, [wLoadedCard1Name]
	ld [de], a
	inc de
	ld a, [wLoadedCard1Name + 1]
	ld [de], a

; load wTxRam2_b with ColorToTextSymbol
	inc de
	ld a, [hli]
	ld [de], a
	inc de
	ld a, [hli]
	ld [de], a
	ret

ColorToTextSymbol:
	tx FireSymbolText
	tx GrassSymbolText
	tx LightningSymbolText
	tx WaterSymbolText
	tx FightingSymbolText
	tx PsychicSymbolText

Conversion1_AISelection:
;	fallthrough

; handles AI logic for selecting a new color for weakness/resistance.
; Conversion1 looks in own Bench for a non-colorless card that can attack.
; Conversion2 looks in opponent's Bench for a non-colorless card that can attack.
AISelectConversionColor:
	ld a, DUELVARS_NUMBER_OF_POKEMON_IN_PLAY_AREA
	call GetTurnDuelistVariable
	ld d, a
	ld e, PLAY_AREA_ARENA
	jr .next_pkmn_atk

; look for a non-colorless Benched Pokemon
; that has enough energy to use an attack.
.loop_atk
	push de
	call GetPlayAreaCardAttachedEnergies
	ld a, e
	add DUELVARS_ARENA_CARD
	call GetTurnDuelistVariable
	ld d, a
	call LoadCardDataToBuffer1_FromDeckIndex
	ld a, [wLoadedCard1Type]
	cp COLORLESS
	jr z, .skip_pkmn_atk ; skip colorless Pokemon
	ld e, FIRST_ATTACK_OR_PKMN_POWER
	bank1call _CheckIfEnoughEnergiesToAttack
	jr nc, .found
	ld e, SECOND_ATTACK
	bank1call _CheckIfEnoughEnergiesToAttack
	jr nc, .found
.skip_pkmn_atk
	pop de
.next_pkmn_atk
	inc e
	dec d
	jr nz, .loop_atk

; none found on the Bench.
; next, look for a non-colorless Benched Pokemon
; that has any Energy cards attached.
	ld d, e ; number of Play Area Pokemon
	ld e, PLAY_AREA_ARENA
	jr .next_pkmn_energy

.loop_energy
	push de
	call GetPlayAreaCardAttachedEnergies
	ld a, [wTotalAttachedEnergies]
	or a
	jr z, .skip_pkmn_energy
	ld a, e
	add DUELVARS_ARENA_CARD
	call GetTurnDuelistVariable
	ld d, a
	call LoadCardDataToBuffer1_FromDeckIndex
	ld a, [wLoadedCard1Type]
	cp COLORLESS
	jr nz, .found
.skip_pkmn_energy
	pop de
.next_pkmn_energy
	inc e
	dec d
	jr nz, .loop_energy

; otherwise, just select a random energy.
	ld a, NUM_COLORED_TYPES
	call Random
	ldh [hTemp_ffa0], a
	ret

.found
	pop de
	ld a, [wLoadedCard1Type]
	and TYPE_PKMN
	ldh [hTemp_ffa0], a
	ret

PreventTrainersEffect:
	ld a, DUELVARS_ARENA_CARD_SUBSTATUS3
	call GetNonTurnDuelistVariable
	set SUBSTATUS3_HEADACHE_F, [hl]
	ret


;---------------------------------------------------------------------------------
; (9) ANY OTHER NON-DAMAGE ATTACK EFFECTS THAT AFFECT THE OPPONENT'S POKEMON ARE NEXT.
;---------------------------------------------------------------------------------

; handles screen for selecting an Energy card to discard from the Defending Pokemon
; and store the Player selection in [hTemp_ffa0].
DiscardEnergyDefendingPokemon_PlayerSelection:
	call SwapTurn
	xor a ; PLAY_AREA_ARENA
	call CreateArenaOrBenchEnergyCardList
	jr c, .no_energy

	ldtx hl, ChooseDiscardEnergyCardFromOpponentText
	call DrawWideTextBox_WaitForInput
	xor a ; PLAY_AREA_ARENA
	bank1call DisplayEnergyDiscardScreen
.loop_input
	bank1call HandleEnergyDiscardMenuInput
	jr c, .loop_input ; must choose, B button can't be used to exit

	call SwapTurn
	ldh a, [hTempCardIndex_ff98]
	ldh [hTemp_ffa0], a ; store selected card to discard
	ret

.no_energy
	call SwapTurn
	ld a, $ff
	ldh [hTemp_ffa0], a
	ret
;
;Alt_DiscardEnergyDefendingPokemon_PlayerSelection:
;	call SwapTurn
;	ld e, PLAY_AREA_ARENA
;	call GetPlayAreaCardAttachedEnergies
;	ld a, [wTotalAttachedEnergies]
;	or a
;	jr z, .no_energy
;
;; draw Energy Card list screen
;	ldtx hl, ChooseDiscardEnergyCardFromOpponentText
;	call DrawWideTextBox_WaitForInput
;	xor a ; PLAY_AREA_ARENA
;	call CreateArenaOrBenchEnergyCardList
;	xor a ; PLAY_AREA_ARENA
;	bank1call DisplayEnergyDiscardScreen
;
;.loop_input
;	bank1call HandleEnergyDiscardMenuInput
;	jr c, .loop_input ; must choose, B button can't be used to exit
;
;	call SwapTurn
;	ldh a, [hTempCardIndex_ff98]
;	ldh [hTemp_ffa0], a ; store selected card to discard
;	ret
;
;.no_energy
;	call SwapTurn
;	ld a, $ff
;	ldh [hTemp_ffa0], a
;	or a
;	ret

DiscardEnergyDefendingPokemon_AISelection:
	call EnergyRemoval_AISelection
	ldh [hTemp_ffa0], a
	ret

DefendingPokemonEnergy_DiscardEffect:
	call HandleNoDamageOrEffect
	ret c ; return if the attack had no effect
	
	; check if an Energy card was chosen to discard
	ldh a, [hTemp_ffa0]
	cp $ff
	ret z ; return if none selected

	; discard an Energy from the Defending Pokemon
	; this doesn't update DUELVARS_ARENA_CARD_LAST_TURN_EFFECT
	call SwapTurn
	call PutCardInDiscardPile
	ld a, DUELVARS_ARENA_CARD_LAST_TURN_EFFECT
	call GetTurnDuelistVariable
	ld [hl], LAST_TURN_EFFECT_DISCARD_ENERGY
	jp SwapTurn

; handles the selection of a forced switch by link/AI opponent or by the player.
; outputs the Play Area location of the chosen Benched Pokemon in hTempPlayAreaLocation_ff9d.
DuelistSelectForcedSwitch:
	ld a, DUELVARS_DUELIST_TYPE
	call GetNonTurnDuelistVariable
	cp DUELIST_TYPE_LINK_OPP
	jr z, .link_opp

	cp DUELIST_TYPE_PLAYER
	jr z, .player

; AI opponent
	call SwapTurn
	call AIDoAction_ForcedSwitch
	call SwapTurn

	ld a, [wPlayerAttackingAttackIndex]
	ld e, a
	ld a, [wPlayerAttackingCardIndex]
	ld d, a
	ld a, [wPlayerAttackingCardID]
	call CopyAttackDataAndDamage_FromCardID
	jp UpdateArenaCardIDsAndClearTwoTurnDuelVars

.player
	ldtx hl, SelectNewActivePokemonText
	call DrawWideTextBox_WaitForInput
	call SwapTurn
	bank1call HasAlivePokemonInBench
	ld a, $01
	ld [wPlayAreaSelectAction], a
.loop_input
	bank1call OpenPlayAreaScreenForSelection
	jr c, .loop_input ; must choose, B button can't be used to exit
	jp SwapTurn

; get selection from link opponent
.link_opp
	ld a, OPPACTION_FORCE_SWITCH_ACTIVE
	call SetOppAction_SerialSendDuelData
.loop
	call SerialRecvByte
	jr nc, .received
	halt
	nop
	jr .loop
.received
	ldh [hTempPlayAreaLocation_ff9d], a
	ret

; returns carry if the opponent doesn't have any Benched Pokemon
OpponentSwitchesActive_BenchCheck:
	ld a, DUELVARS_NUMBER_OF_POKEMON_IN_PLAY_AREA
	call GetNonTurnDuelistVariable
	cp 2
	jr nc, .has_bench
	; no Benched Pokemon
	ld a, $ff
	ldh [hTemp_ffa0], a
	ret
.has_bench
	call DuelistSelectForcedSwitch
	ldh a, [hTempPlayAreaLocation_ff9d]
	ldh [hTemp_ffa0], a
	ret

; outputs in hTemp_ffa0 the result of the coin toss (0 = tails, 1 = heads).
; in case it was heads, stores in hTempPlayAreaLocation_ffa1
; the PLAY_AREA_* location of the Benched Pokemon that was selected for the switch.
OpponentSwitchesActive50Percent_SelectEffect:
	xor a
	ldh [hTemp_ffa0], a

; returns carry if no there isn't a Benched Pokemon to switch with
	ld a, DUELVARS_NUMBER_OF_POKEMON_IN_PLAY_AREA
	call GetNonTurnDuelistVariable
	cp 2
	ret c

; toss coin and store whether it was tails (0) or heads (1) in hTemp_ffa0.
; return if it was tails.
	ldtx de, IfHeadsChangeOpponentsActivePokemonText
	call Serial_TossCoin
	ldh [hTemp_ffa0], a
	ret nc

	call DuelistSelectForcedSwitch
	ldh a, [hTempPlayAreaLocation_ff9d]
	ldh [hTempPlayAreaLocation_ffa1], a
	ret

; if coin toss at hTemp_ffa0 was heads and it's possible, switch the Defending Pokemon
OpponentSwitchesActive50Percent_SwitchEffect:
	ldh a, [hTemp_ffa0]
	or a
	ret z
	ldh a, [hTempPlayAreaLocation_ffa1]
	jr HandleSwitchDefendingPokemonEffect

OpponentSwitchesActive_SwitchEffect:
	ldh a, [hTemp_ffa0]
;	fallthrough

HandleSwitchDefendingPokemonEffect:
	ld e, a
	cp $ff
	ret z

; check the Defending Pokemon's HP
	ld a, DUELVARS_ARENA_CARD_HP
	call GetNonTurnDuelistVariable
	or a
	jr nz, .switch

; if 0, handle Destiny Bond first
	push de
	call HandleDestinyBondSubstatus
	pop de

.switch
	call HandleNoDamageOrEffect
	ret c

; attack was successful, switch Defending Pokemon
	call SwapTurn
	call SwapArenaWithBenchPokemon
	call SwapTurn

	xor a
	ld [wccc5], a
	ld [wDuelDisplayedScreen], a
	inc a
	ld [wDefendingWasForcedToSwitch], a
	ret

Recoil20OpponentSwitchesActiveEffect:
	ld a, 20
	call DealRecoilDamageToSelf
	ldh a, [hTemp_ffa0]
	jr HandleSwitchDefendingPokemonEffect

AlsoDamageTo1Benched_PlayerSelection:
	ld a, $ff
	ldh [hTemp_ffa0], a
	ld a, DUELVARS_NUMBER_OF_POKEMON_IN_PLAY_AREA
	call GetNonTurnDuelistVariable
	cp 2
	ret c ; has no Benched Pokemon
;	fallthrough

; opens the Play Area screen to select a Benched Pokemon to damage
; and store its location before returning
DamageTo1Benched_PlayerSelection:
	ldtx hl, ChoosePkmnInTheBenchToGiveDamageText
	jr MustChooseOpposingBenchedPokemon

; return in hTempPlayAreaLocation_ffa1 the PLAY_AREA_* location of the Benched Pokemon that was selected
SwitchDefendingPokemon_PlayerSelection:
	ldtx hl, SelectNewDefendingPokemonText
;	fallthrough

MustChooseOpposingBenchedPokemon:
	call DrawWideTextBox_WaitForInput
	call SwapTurn
	bank1call HasAlivePokemonInBench
.loop_input
	bank1call OpenPlayAreaScreenForSelection
	jr c, .loop_input ; must choose, B button can't be used to exit
	ldh a, [hTempPlayAreaLocation_ff9d]
	ldh [hTemp_ffa0], a
	jp SwapTurn

; AI always picks the Benched Pokemon with the lowest remaining HP
AlsoChooseWeakestBenchedPokemon_AISelection:
	ld a, $ff
	ldh [hTemp_ffa0], a
	ld a, DUELVARS_NUMBER_OF_POKEMON_IN_PLAY_AREA
	call GetNonTurnDuelistVariable
	cp 2
	ret c ; return if no Benched Pokemon
;	fallthrough

; Return in hTemp_ffa0 the PLAY_AREA_* of the non-turn holder's Benched Pokemon with the lowest (remaining) HP.
; if multiple cards are tied for the lowest HP, the one with the highest PLAY_AREA_* is returned.
ChooseWeakestBenchedPokemon_AISelection:
	call GetBenchPokemonWithLowestHP
	ldh [hTemp_ffa0], a
	ret

; Return in a the PLAY_AREA_* of the non-turn holder's Benched Pokemon with the lowest (remaining) HP.
; if multiple cards are tied for the lowest HP, the one with the highest PLAY_AREA_* is returned.
GetBenchPokemonWithLowestHP:
	call SwapTurn
	ld a, DUELVARS_NUMBER_OF_POKEMON_IN_PLAY_AREA
	call GetTurnDuelistVariable
	ld c, a
	lb de, PLAY_AREA_ARENA, $ff
	ld b, d
	ld a, DUELVARS_BENCH1_CARD_HP
	call GetTurnDuelistVariable
	jr .start

; find Play Area location with least amount of HP
.loop_bench
	ld a, e
	cp [hl]
	jr c, .next ; skip if HP is higher
	ld e, [hl]
	ld d, b

.next
	inc hl
.start
	inc b
	dec c
	jr nz, .loop_bench

	ld a, d
	jp SwapTurn

; Defending Pokemon is swapped out for the one with the PLAY_AREA_* at hTemp_ffa0,
; unless Mew's Neutralizing Shield or Haunter's Transparency prevents it.
SwitchDefendingPokemon_SwitchEffect:
	call SwapTurn
	ldh a, [hTemp_ffa0]
	ld e, a
	call HandleNShieldAndTransparency
	call nc, SwapArenaWithBenchPokemon
	call SwapTurn
	xor a
	ld [wDuelDisplayedScreen], a
	ret

; identical to SwitchDefendingPokemon_PlayerSelection
; except the player can choose not to play the card
; by canceling the selection with the B button 
GustOfWind_PlayerSelection:
	ldtx hl, SelectNewDefendingPokemonText
	call DrawWideTextBox_WaitForInput
	call SwapTurn
	bank1call HasAlivePokemonInBench
	bank1call OpenPlayAreaScreenForSelection
	ldh a, [hTempPlayAreaLocation_ff9d]
	ldh [hTemp_ffa0], a
	jp SwapTurn

GustOfWind_SwitchEffect:
; play whirlwind animation
	ld a, ATK_ANIM_GUST_OF_WIND
	call PlayTrainerEffectAnimation

; switch Active Pokemon
	call SwapTurn
	ldh a, [hTemp_ffa0]
	ld e, a
	call SwapArenaWithBenchPokemon
	call SwapTurn
	call ClearDamageReductionSubstatus2
	xor a
	ld [wDuelDisplayedScreen], a
	ret

; returns carry if Player cancelled selection.
; otherwise, output in hTemp_ffa0 which Play Area
; was selected ($0 = own Play Area, $1 = opp. Play Area)
; and in hTempPlayAreaLocation_ffa1 selected card.
DevolutionBeam_PlayerSelection:
	ldtx hl, ProcedureForDevolutionBeamText
	bank1call DrawWholeScreenTextBox

.start
	bank1call DrawDuelMainScene
	ldtx hl, PleaseSelectThePlayAreaText
	call TwoItemHorizontalMenu
	ldh a, [hKeysHeld]
	and B_BUTTON
	jp nz, SetCarryEF

; a Play Area was selected
	ldh a, [hCurMenuItem]
	or a
	jr nz, .opp_chosen

; player was chosen
	call HandleEvolvedCardSelection
	jr c, .start

	xor a
.store_selection
	ld hl, hTemp_ffa0
	ld [hli], a ; store which player's Play Area selected
	ldh a, [hTempPlayAreaLocation_ff9d]
	ld [hl], a ; store which card selected
	or a
	ret

.opp_chosen
	call SwapTurn
	call HandleEvolvedCardSelection
	call SwapTurn
	jr c, .start
	ld a, $01
	jr .store_selection

DevolutionBeam_AISelection:
	ld a, $01
	ldh [hTemp_ffa0], a
	call SwapTurn
	call FindFirstNonBasicCardInPlayArea
	call SwapTurn
	jr c, .found
	xor a
	ldh [hTemp_ffa0], a
	call FindFirstNonBasicCardInPlayArea
.found
	ldh [hTempPlayAreaLocation_ffa1], a
	ret

; finds first Evolution in Play Area and outputs its location in a, with carry set.
; returns carry if none are found.
FindFirstNonBasicCardInPlayArea:
	ld a, DUELVARS_NUMBER_OF_POKEMON_IN_PLAY_AREA
	call GetTurnDuelistVariable
	ld c, a

	ld b, PLAY_AREA_ARENA
	ld l, DUELVARS_ARENA_CARD_STAGE
.loop
	ld a, [hli]
	or a
	jr nz, .not_basic
	inc b
	dec c
	jr nz, .loop
	or a
	ret
.not_basic
	ld a, b
	scf
	ret

; This seems completely pointless.
;DevolutionBeam_LoadAnimation:
;	xor a ; ATK_ANIM_NONE
;	ld [wLoadedAttackAnimation], a
;	ret
;
DevolutionBeam_DevolveEffect:
	ldh a, [hTemp_ffa0]
	or a
	jr z, .DevolvePokemon
	cp $ff
	ret z

; opponent's Play Area
	call SwapTurn
	ldh a, [hTempPlayAreaLocation_ffa1]
	jr nz, .skip_handle_no_damage_effect
	call HandleNoDamageOrEffect
	jp c, SwapTurn
.skip_handle_no_damage_effect
	call .DevolvePokemon
	jp SwapTurn

.DevolvePokemon
	ld a, ATK_ANIM_DEVOLUTION_BEAM
	ld [wLoadedAttackAnimation], a
	ldh a, [hTempPlayAreaLocation_ffa1]
	ld b, a
	ld c, $00
	ldh a, [hWhoseTurn]
	ld h, a
	bank1call PlayAttackAnimation
	call WaitAttackAnimation

; load selected card's data
	ldh a, [hTempPlayAreaLocation_ffa1]
	ldh [hTempPlayAreaLocation_ff9d], a
	ld [wTempPlayAreaLocation_cceb], a
	add DUELVARS_ARENA_CARD
	call GetTurnDuelistVariable
	call LoadCardDataToBuffer1_FromDeckIndex

; check if card is affected
	ld a, [wLoadedCard1ID]
	ld [wTempNonTurnDuelistCardID], a
	ld de, $0
	ldh a, [hTempPlayAreaLocation_ff9d]
	or a
	jr nz, .skip_substatus_check
	call HandleNoDamageOrEffectSubstatus
	jr c, .check_no_damage_effect
.skip_substatus_check
	call HandleDamageReductionOrNoDamageFromPkmnPowerEffects
.check_no_damage_effect
	call CheckNoDamageOrEffect
	jr nc, .devolve
	jp DrawWideTextBox_WaitForInput

.devolve
	ldh a, [hTempPlayAreaLocation_ffa1]
	ldh [hTempPlayAreaLocation_ff9d], a
	add DUELVARS_ARENA_CARD
	call GetTurnDuelistVariable
	bank1call GetCardOneStageBelow
	call PrintDevolvedCardNameAndLevelText

	ld a, d
	call UpdateDevolvedCardHPAndStage
	call ResetDevolvedCardStatus

; add the evolved card to the hand
	ld a, e
	call AddCardToHand

; check if this devolution KO's the Pokemon
	ldh a, [hTempPlayAreaLocation_ffa1]
	call PrintPlayAreaCardKnockedOutIfNoHP

	xor a
	ld [wDuelDisplayedScreen], a
	ret

; handles Player selection of an evolved card in Play Area.
; returns carry if Player cancelled operation.
HandleEvolvedCardSelection:
	bank1call HasAlivePokemonInPlayArea
.loop
	bank1call OpenPlayAreaScreenForSelection
	ret c ; exit if the B button was pressed
	ldh a, [hTempPlayAreaLocation_ff9d]
	add DUELVARS_ARENA_CARD_STAGE
	call GetTurnDuelistVariable
	or a
	jr z, .loop ; if Basic, reset loop
	ret

; overwrites HP and Stage data of the card that was
; devolved in the Play Area to the values of new card.
; if the damage exceeds the HP of the previous stage,
; then its HP is set to zero.
; input:
;	a = card index of pre-evolved card
UpdateDevolvedCardHPAndStage:
	push bc
	push de
	push af
	ldh a, [hTempPlayAreaLocation_ff9d]
	ld e, a
	call GetCardDamageAndMaxHP
	ld b, a ; store damage
	ld a, e
	add DUELVARS_ARENA_CARD
	call GetTurnDuelistVariable
	pop af

	ld [hl], a
	call LoadCardDataToBuffer2_FromDeckIndex
	ld a, e
	add DUELVARS_ARENA_CARD_HP
	ld l, a
	ld a, [wLoadedCard2HP]
	sub b ; subtract damage from the new HP value
	jr nc, .got_hp
	; damage exceeds HP
	xor a ; 0 HP
.got_hp
	ld [hl], a
	ld a, e
; overwrite card stage
	add DUELVARS_ARENA_CARD_STAGE
	ld l, a
	ld a, [wLoadedCard2Stage]
	ld [hl], a
	pop de
	pop bc
	ret

; reset various status after devolving card.
ResetDevolvedCardStatus:
; if it's the Active Pokemon, remove any special conditions
	ldh a, [hTempPlayAreaLocation_ff9d]
	or a
	jr nz, .skip_clear_status
	call ClearAllStatusConditions
.skip_clear_status
; reset changed color status
	ldh a, [hTempPlayAreaLocation_ff9d]
	add DUELVARS_ARENA_CARD_CHANGED_TYPE
	call GetTurnDuelistVariable
	ld [hl], $00
; reset C2 flags
	ldh a, [hTempPlayAreaLocation_ff9d]
	add DUELVARS_ARENA_CARD_FLAGS
	ld l, a
	ld [hl], $00
	ret

; prints the text "<X> devolved to <Y>!" with the proper card names and levels.
; input:
;	d = deck index of the lower stage card
;	e = deck index of card that was devolved
PrintDevolvedCardNameAndLevelText:
	push de
	ld a, e
	call LoadCardDataToBuffer1_FromDeckIndex
	ld bc, wTxRam2
	ld hl, wLoadedCard1Name
	ld a, [hli]
	ld [bc], a
	inc bc
	ld a, [hl]
	ld [bc], a

	inc bc ; wTxRam2_b
	xor a
	ld [bc], a
	inc bc
	ld [bc], a

	ld a, d
	call LoadCardDataToBuffer1_FromDeckIndex
	ld a, 18
	call CopyCardNameAndLevel
	ld [hl], $00
	ldtx hl, PokemonDevolvedToText
	call DrawWideTextBox_WaitForInput
	pop de
	ret

ReturnDefendingPokemonToTheHandEffect:
	call HandleNoDamageOrEffect
	ret c ; is unaffected

	ld a, DUELVARS_ARENA_CARD_HP
	call GetNonTurnDuelistVariable
	or a
	ret z ; return if Pokemon was KO'd

; look at the location of every one of the opponent's cards and
; put all cards that are in the opposing Arena into the opponent's hand.
	call SwapTurn
	ld a, DUELVARS_CARD_LOCATIONS
	call GetTurnDuelistVariable
.loop_locations
	ld a, [hl]
	cp CARD_LOCATION_ARENA
	jr nz, .next_card
	; Arena card, so move to hand
	ld a, l
	call AddCardToHand
.next_card
	inc l
	ld a, l
	cp DECK_SIZE
	jr c, .loop_locations

; empty the Arena card slot
	ld l, DUELVARS_ARENA_CARD
	ld a, [hl]
	ld [hl], $ff
	ld l, DUELVARS_ARENA_CARD_HP
	ld [hl], 0
	call LoadCardDataToBuffer1_FromDeckIndex
	ld hl, wLoadedCard1Name
	ld a, [hli]
	ld h, [hl]
	ld l, a
	call LoadTxRam2
	ldtx hl, PokemonAndAllAttachedCardsReturnedToHandText
	call DrawWideTextBox_WaitForInput
	xor a
	ld [wDuelDisplayedScreen], a
	jp SwapTurn


;---------------------------------------------------------------------------------
; (10) THE DAMAGE-MODIFYING ATTACK EFFECTS ARE NEXT.
;---------------------------------------------------------------------------------

; Ignores Weakness and Resistance for attack damage
NoColorEffect:
	ld hl, wDamage + 1
	set UNAFFECTED_BY_WEAKNESS_RESISTANCE_F, [hl]
;	fallthrough

NullEffect:
	ret

HalveHPOfDefendingPokemon_AIEffect:
	call HalveHPOfDefendingPokemon
	jr SetDefiniteAIDamage

HalveHPOfDefendingPokemon:
	ld a, DUELVARS_ARENA_CARD_HP
	call GetNonTurnDuelistVariable
	srl a
	bit 0, a
	jp z, SetDefiniteDamage ; no need to round
	add 5 ; round up to the nearest 10
	jp SetDefiniteDamage

KarateChop_AIEffect:
	call KarateChop_DamageSubtractionEffect
	jr SetDefiniteAIDamage

KarateChop_DamageSubtractionEffect:
	ld e, PLAY_AREA_ARENA
	call GetCardDamageAndMaxHP
	ld e, a
	ld hl, wDamage
	ld a, [hl]
	sub e
	ld [hli], a
	ld a, [hl]
	sbc 0
	ld [hl], a
	rla
	ret nc
; cap it to 0 damage
	xor a
	jp SetDefiniteDamage

Flail_AIEffect:
	call Flail_HPCheck
	jr SetDefiniteAIDamage

Flail_HPCheck:
	ld e, PLAY_AREA_ARENA
	call GetCardDamageAndMaxHP
	jp SetDefiniteDamage

Rage_AIEffect:
	call Rage_DamageBoostEffect
;	fallthrough

; overwrites wAIMinDamage and wAIMaxDamage with value in wDamage.
SetDefiniteAIDamage:
	ld a, [wDamage]
	ld [wAIMinDamage], a
	ld [wAIMaxDamage], a
	ret

Rage_DamageBoostEffect:
	ld e, PLAY_AREA_ARENA
	call GetCardDamageAndMaxHP
	jp AddToDamage

RageAndSelfConfusion50PercentEffect:
	call Rage_DamageBoostEffect
	ldtx de, IfTailsYourPokemonBecomesConfusedText
	call TossCoin_BankB
	ret c ; return if heads
	call SwapTurn
	call ConfusionEffect
	jp SwapTurn

CompoundingDamageCounters_AIEffect:
	call CompoundingDamageCounters_DamageBoostEffect
	jr SetDefiniteAIDamage

; add the damage already on the Defending Pokemon to the attack's damage
CompoundingDamageCounters_DamageBoostEffect:
	call SwapTurn
	ld e, PLAY_AREA_ARENA
	call GetCardDamageAndMaxHP
	call SwapTurn
	jp AddToDamage

Psychic_AIEffect:
	call DefendingPokemonEnergy_10MoreDamageEffect
	jr SetDefiniteAIDamage

DefendingPokemonEnergy_10MoreDamageEffect:
	call DefendingPokemonEnergyDamageMultiplier
	ld hl, wDamage
	ld a, e
	add [hl]
	ld [hli], a
	ld a, d
	adc [hl]
	ld [hl], a
	ret

; output in de the number of Energy cards attached to the Defending Pokemon times 10.
; used for attacks that deal 10x number of Energy cards attached to the Defending card.
DefendingPokemonEnergyDamageMultiplier:
	call SwapTurn
	ld a, DUELVARS_CARD_LOCATIONS
	call GetTurnDuelistVariable

	ld c, 0
.loop
	ld a, [hl]
	cp CARD_LOCATION_ARENA
	jr nz, .next
	; is the Active Pokemon
	ld a, l
	call GetCardIDFromDeckIndex
	call GetCardType
	and TYPE_ENERGY
	jr z, .next
	; is Energy attached to Active Pokemon
	inc c
.next
	inc l
	ld a, l
	cp DECK_SIZE
	jr c, .loop

	call SwapTurn
	ld l, c
	ld h, $00
	ld b, $00
	add hl, hl ; hl =  2 * c
	add hl, hl ; hl =  4 * c
	add hl, bc ; hl =  5 * c
	add hl, hl ; hl = 10 * c
	ld e, l
	ld d, h
	ret

DefendingPokemonEnergyTimes10_DamageEffect:
	call DefendingPokemonEnergyDamageMultiplier
	ld hl, wDamage
	ld [hl], e
	inc hl
	ld [hl], d
	ret

WWaterGunEffect:
	lb bc, 1, 0
	jr ApplyExtraWaterEnergyDamageBonus

WCWaterGunEffect:
	lb bc, 1, 1
	jr ApplyExtraWaterEnergyDamageBonus

WWCWaterGunEffect:
	lb bc, 2, 1
	jr ApplyExtraWaterEnergyDamageBonus

WWWHydroPumpEffect:
	lb bc, 3, 0
;	fallthrough

; applies the bonus damage for attacks that get stronger with extra Water energy cards.
; this bonus is always 10 more damage for each extra Water energy
; and is always capped at a maximum of 20 damage.
; input:
;	b = number of Water Energy listed in Attack Cost
;	c = number of Colorless Energy listed in Attack Cost
ApplyExtraWaterEnergyDamageBonus:
	ld a, [wMetronomeEnergyCost]
	or a
	jr z, .not_metronome
	ld c, a ; amount of colorless needed for Metronome
	ld b, 0 ; no Water energy needed for Metronome

.not_metronome
	push bc
	ldh a, [hTempPlayAreaLocation_ff9d]
	ld e, a
	call GetPlayAreaCardAttachedEnergies
	pop bc

	ld hl, wAttachedEnergies + WATER
	ld a, c
	or a
	jr z, .check_bonus ; is Energy cost all water energy?

	; it's not, so we need to remove the
	; Water Energy cards from calculations
	; if they pay for colorless instead.
	ld a, [wTotalAttachedEnergies]
	cp [hl]
	jr nz, .check_bonus ; skip if at least 1 non-Water Energy attached

	; Water is the only type of Energy attached
	ld a, c
	add b
	ld b, a
	; b += c

.check_bonus
	ld a, [hl]
	sub b
	jp c, SetDefiniteAIDamage ; is Water Energy <  b?
	jp z, SetDefiniteAIDamage ; is Water Energy == b?

; a holds the number of Water Energy not used to pay for the cost of the attack
	cp 3
	jr c, .less_than_3
	ld a, 2 ; cap this to 2 for bonus effect
.less_than_3
	call ATimes10
	call AddToDamage ; add 10 * a to damage
	jp SetDefiniteAIDamage

EachBenched10MoreDamageEffect:
	ld a, DUELVARS_NUMBER_OF_POKEMON_IN_PLAY_AREA
	call GetTurnDuelistVariable
	dec a ; don't count Active Pokemon
	call ATimes10
	jp AddToDamage

EachNidoking20MoreDamageEffect:
	ld a, DUELVARS_ARENA_CARD
	call GetTurnDuelistVariable
	ld c, PLAY_AREA_ARENA
.loop
	ld a, [hl]
	cp $ff
	jr z, .done
	call GetCardIDFromDeckIndex
	ld a, e
	cp NIDOKING
	jr nz, .next
;	ld a, d
;	cp $00 ; why check d? Card IDs are only 1 byte long
;	jr nz, .next
	inc c
.next
	inc hl
	jr .loop
.done
; c holds the number of Nidoking found in the Play Area
	ld a, c
	add a
	call ATimes10
	jp AddToDamage ; adds 2 * 10 * c

; can only use the attack if it was not used previously in the duel
; returns carry if Leek Slap was already used
LeekSlap_OncePerDuelCheck:
	ld a, DUELVARS_ARENA_CARD_FLAGS
	call GetTurnDuelistVariable
	and USED_LEEK_SLAP_THIS_DUEL
	ret z
	ldtx hl, ThisAttackCannotBeUsedTwiceText
	scf
	ret

LeekSlap_SetUsedThisDuelFlag:
	ld a, DUELVARS_ARENA_CARD_FLAGS
	call GetTurnDuelistVariable
	set USED_LEEK_SLAP_THIS_DUEL_F, [hl]
	ret

NoDamage50PercentEffect:
	ldtx de, AttackSuccessCheckText
	call TossCoin_BankB
	ret c
	xor a ; 0 damage
	ld [wLoadedAttackAnimation], a ; 0 = ATK_ANIM_NONE
	call SetDefiniteDamage
;	fallthrough

SetWasUnsuccessful:
	ld a, EFFECT_FAILED_UNSUCCESSFUL
	ld [wEffectFailed], a
	ret

FlipFor20_AIEffect:
	ld a, 20 / 2
	lb de, 0, 20
;	fallthrough

; Stores information about the attack damage for AI purposes
; [wDamage]      <- a (average amount of damage)
; [wAIMinDamage] <- d (minimum)
; [wAIMaxDamage] <- e (maximum)
SetExpectedAIDamage:
	ld [wDamage], a
	xor a
	ld [wDamage + 1], a
	ld a, d
	ld [wAIMinDamage], a
	ld a, e
	ld [wAIMaxDamage], a
	ret

FlipFor30_AIEffect:
	ld a, 30 / 2
	lb de, 0, 30
	jr SetExpectedAIDamage

FlipFor40_AIEffect:
	ld a, 40 / 2
	lb de, 0, 40
	jr SetExpectedAIDamage

;FlipFor50_AIEffect:
;	ld a, 50 / 2
;	lb de, 0, 50
;	jr SetExpectedAIDamage
;
FlipFor60_AIEffect:
	ld a, 60 / 2
	lb de, 0, 60
	jr SetExpectedAIDamage

FlipFor70_AIEffect:
	ld a, 70 / 2
	lb de, 0, 70
	jr SetExpectedAIDamage

FlipFor80_AIEffect:
	ld a, 80 / 2
	lb de, 0, 80
	jr SetExpectedAIDamage

FlipFor120_AIEffect:
	ld a, 120 / 2
	lb de, 0, 120
	jr SetExpectedAIDamage

FlipXFor10_AIEffect:
	ld a, 10
	lb de, 0, 100
	jr SetExpectedAIDamage

; input:
;   a: number of coins to flip
; outputs:
;   a: amount of bonus damage to add (heads x 10)
;   [wCoinTossTotalNum]: number of flipped coins
;   [wCoinTossNumHeads]: number of flipped heads
Plus10DamagePerHeads_TossCoins:
	ld e, a
	ld hl, 10 ; ram number for text display
	call LoadTxRam3
	ld a, e
	ldtx de, DamageCheckIfHeadsXDamageText
	call TossCoinATimes_BankB
	call ATimes10
	ret

Flip2For10_MultiplierEffect:
	ld a, 2
	call Plus10DamagePerHeads_TossCoins
;	fallthrough

; overwrites wDamage, wAIMinDamage and wAIMaxDamage with the value in a.
SetDefiniteDamage:
	ld [wDamage], a
	ld [wAIMinDamage], a
	ld [wAIMaxDamage], a
	xor a
	ld [wDamage + 1], a
	ret

Flip3For10_MultiplierEffect:
	ld a, 3
	call Plus10DamagePerHeads_TossCoins
	jr SetDefiniteDamage

Flip8For10_MultiplierEffect:
	ld a, 8
	call Plus10DamagePerHeads_TossCoins
	jr SetDefiniteDamage

FlipXFor10_MultiplierEffect:
	xor a
	ldh [hTemp_ffa0], a
.loop_coin_toss
	ldtx de, FlipUntilFailAppears10DamageForEachHeadsText
	xor a
	call TossCoinATimes_BankB
	jr nc, .tails
	ld hl, hTemp_ffa0
	inc [hl] ; increase heads count
	jr .loop_coin_toss

.tails
; store resulting damage
	ldh a, [hTemp_ffa0]
	ld l, a
	ld h, 10
	call HtimesL
	ld de, wDamage
	ld a, l
	ld [de], a
	inc de
	ld a, h
	ld [de], a
	ret

; input:
;   a: number of coins to flip
; outputs:
;   a: amount of bonus damage to add (heads x 20)
;   [wCoinTossTotalNum]: number of flipped coins
;   [wCoinTossNumHeads]: number of flipped heads
Plus20DamagePerHeads_TossCoins:
	ld e, a
	ld hl, 20 ; ram number for text display
	call LoadTxRam3
	ld a, e
	ldtx de, DamageCheckIfHeadsXDamageText
	call TossCoinATimes_BankB
	add a ; a = 2 * heads
	call ATimes10
	ret

Flip2For20_MultiplierEffect:
	ld a, 2
	call Plus20DamagePerHeads_TossCoins
	jr SetDefiniteDamage

Flip3For20_MultiplierEffect:
	ld a, 3
	call Plus20DamagePerHeads_TossCoins
	jr SetDefiniteDamage

Flip4For20_MultiplierEffect:
	ld a, 4
	call Plus20DamagePerHeads_TossCoins
	jr SetDefiniteDamage

FlipEachEnergyFor20_AIEffect:
	ldh a, [hTempPlayAreaLocation_ff9d]
	ld e, a
	call GetPlayAreaCardAttachedEnergies
	ld a, [wTotalAttachedEnergies]
	call SetDamageToATimes20
	inc h
	jr nz, .capped
	ld l, 255
.capped
	ld a, l
	ld [wAIMaxDamage], a
	srl a
	ld [wDamage], a
	xor a
	ld [wAIMinDamage], a
	ret

; Flip coins equal to the amount of attached Energy; deal 20x number of heads
FlipEachEnergyFor20_MultiplierEffect:
	ld e, PLAY_AREA_ARENA
	call GetPlayAreaCardAttachedEnergies
	ld hl, 20 ; ram number for text display
	call LoadTxRam3
	ld a, [wTotalAttachedEnergies]
	ldtx de, DamageCheckIfHeadsXDamageText
	call TossCoinATimes_BankB
;	fallthrough

; set damage to 20*a. Also return result in hl
SetDamageToATimes20:
	ld l, a
	ld h, $00
	ld e, l
	ld d, h
	add hl, hl
	add hl, hl
	add hl, de
	add hl, hl
	add hl, hl
	ld a, l
	ld [wDamage], a
	ld a, h
	ld [wDamage + 1], a
	ret

Flip2For30_MultiplierEffect:
	ld hl, 30 ; ram number for text display
	call LoadTxRam3
	ldtx de, DamageCheckIfHeadsXDamageText
	ld a, 2
	call TossCoinATimes_BankB
	ld e, a
	add a ; a = 2 * heads
	add e ; a = 3 * heads
	call ATimes10
	jp SetDefiniteDamage ; 3 * 10 * heads

Flip2For40_MultiplierEffect:
	ld hl, 40 ; ram number for text display
	call LoadTxRam3
	ldtx de, DamageCheckIfHeadsXDamageText
	ld a, 2
	call TossCoinATimes_BankB
	add a ; a = 2 * heads
	add a
	call ATimes10
	jp SetDefiniteDamage

Flip3For40SelfConfusion_MultiplierEffect:
	ld hl, 40 ; ram number for text display
	call LoadTxRam3
	ldtx de, DamageCheckIfHeadsXDamageText
	ld a, 3
	call TossCoinATimes_BankB
	add a ; a = 2 * heads
	add a
	call ATimes10
	call SetDefiniteDamage ; a = 4 * 10 * heads
	call SwapTurn
	call ConfusionEffect
	jp SwapTurn

FlipForPlus10_DamageBoostEffect:
	ld hl, 10 ; ram number for text display
	call LoadTxRam3
	ldtx de, DamageCheckIfHeadsPlusDamageText
	call TossCoin_BankB
	ret nc ; return if tails
	ld a, 10
;	fallthrough

; [wDamage] += a
AddToDamage:
	push hl
	ld hl, wDamage
	add [hl]
	ld [hli], a
	ld a, 0
	adc [hl]
	ld [hl], a
	pop hl
	ret

; unreferenced counterpart of AddToDamage
; [wDamage] -= a
;SubtractFromDamage:
;	push de
;	push hl
;	ld e, a
;	ld hl, wDamage
;	ld a, [hl]
;	sub e
;	ld [hli], a
;	ld a, [hl]
;	sbc 0
;	ld [hl], a
;	pop hl
;	pop de
;	ret

FlipForPlus20_DamageBoostEffect:
	ld hl, 20 ; ram number for text display
	call LoadTxRam3
	ldtx de, DamageCheckIfHeadsPlusDamageText
	call TossCoin_BankB
	ret nc ; return if tails
	ld a, 20
	jr AddToDamage

Plus10From20_AIEffect:
	ld a, (20 + 30) / 2
	lb de, 20, 30
	jp SetExpectedAIDamage

Plus20From10_AIEffect:
	ld a, (10 + 30) / 2
	lb de, 10, 30
	jp SetExpectedAIDamage

Plus10OrRecoil_AIEffect:
	ld a, (30 + 40) / 2
	lb de, 30, 40
	jp SetExpectedAIDamage

; if heads, 10 more damage
; if tails, 10 damage to itself
Plus10OrRecoil_ModifierEffect:
	ldtx de, IfHeadPlus10IfTails10ToYourselfText
	call TossCoin_BankB
	ldh [hTemp_ffa0], a
	ret nc ; return if got tails
	ld a, 10
	jr AddToDamage

Plus10OrRecoil_RecoilEffect:
	ldh a, [hTemp_ffa0]
	or a
	ret nz ; return if got heads
	ld a, 10
	jp DealRecoilDamageToSelf


;---------------------------------------------------------------------------------
; (11) ATTACK EFFECTS THAT NEGATIVELY AFFECT THE PLAYER'S POKEMON ARE NEXT.
;---------------------------------------------------------------------------------

Recoil10_50PercentEffect:
	ld hl, 10 ; ram number for text display
	call LoadTxRam3
	ldtx de, IfTailsDamageToYourselfTooText
	call TossCoin_BankB
	ldh [hTemp_ffa0], a
	ret

Recoil10_RecoilEffect:
	ld hl, 10 ; ram number for text display
	call LoadTxRam3
	ldh a, [hTemp_ffa0]
	or a
	ret nz ; return if heads
	ld a, 10
	jp DealRecoilDamageToSelf

FlipToRecoil30_50PercentEffect:
	ld hl, 30 ; ram number for text display
	call LoadTxRam3
	ldtx de, IfTailsDamageToYourselfTooText
	call TossCoin_BankB
	ldh [hTemp_ffa0], a
	ret

FlipToRecoil30_RecoilEffect:
	ld hl, 30 ; ram number for text display
	call LoadTxRam3
	ldh a, [hTemp_ffa0]
	or a
	ret nz ; return if heads
	ld a, 30
	jp DealRecoilDamageToSelf

Recoil20Effect:
	ld a, 20
	jp DealRecoilDamageToSelf

Recoil30Effect:
	ld a, 30
	jp DealRecoilDamageToSelf

Recoil80Effect:
	ld a, 80
	jp DealRecoilDamageToSelf

SelfConfusion_50PercentEffect:
	ldtx de, IfTailsYourPokemonBecomesConfusedText
	call TossCoin_BankB
	ret c ; return if heads
	; make the attacking Pokemon Confused
	ld a, ATK_ANIM_MULTIPLE_SLASH
	ld [wLoadedAttackAnimation], a
	call SwapTurn
	call ConfusionEffect
	jp SwapTurn

; creates in wDuelTempList a list of Fire Energy cards
; that are attached to the player's Active Pokemon.
CreateListOfFireEnergyAttachedToActive:
	ld a, TYPE_ENERGY_FIRE
;	fallthrough

; creates in wDuelTempList a list of cards that
; are in the Arena of the same type as input a.
; this is called to list Energy cards of a specific type
; that are attached to the player's Active Pokemon.
; input:
;	a = TYPE_ENERGY_* constant
; output:
;	a = number of cards in list;
;	wDuelTempList filled with cards, terminated by $ff
CreateListOfEnergyAttachedToActive:
	ld b, a
	ld c, 0
	ld de, wDuelTempList
	ld a, DUELVARS_CARD_LOCATIONS
	call GetTurnDuelistVariable
.loop
	ld a, [hl]
	cp CARD_LOCATION_ARENA
	jr nz, .next
	push de
	ld a, l
	call GetCardIDFromDeckIndex
	call GetCardType
	pop de
	cp b
	jr nz, .next ; is same as input type?
	ld a, l
	ld [de], a
	inc de
	inc c
.next
	inc l
	ld a, l
	cp DECK_SIZE
	jr c, .loop

	ld a, $ff
	ld [de], a
	ld a, c
	ret

DiscardAttachedFireEnergy_PlayerSelection:
	call CreateListOfFireEnergyAttachedToActive
	xor a
	bank1call DisplayEnergyDiscardScreen
	bank1call HandleEnergyDiscardMenuInput
	ldh a, [hTempCardIndex_ff98]
	ldh [hTempList], a
	ret

; AI picks the first Fire Energy card in the list
DiscardAttachedFireEnergy_AISelection:
	call CreateListOfFireEnergyAttachedToActive
	ld a, [wDuelTempList]
	ldh [hTempList], a
	ret

; AI always chooses 0 cards to discard
DiscardXAttachedFireEnergy_AISelection:
	xor a
	ldh [hTempList], a
	ret

DiscardXAttachedFireEnergy_PlayerSelection:
	ldtx hl, DiscardOppDeckAsManyFireEnergyCardsText
	call DrawWideTextBox_WaitForInput

	xor a
	ldh [hCurSelectionItem], a
	call CreateListOfFireEnergyAttachedToActive
	xor a
	bank1call DisplayEnergyDiscardScreen

; show list to Player and for each card selected to discard, increase a counter and store it.
; this will be the output used by DiscardXAttachedFireEnergy_DiscardEffect.
	xor a
	ld [wEnergyDiscardMenuDenominator], a
.loop
	ldh a, [hCurSelectionItem]
	ld [wEnergyDiscardMenuNumerator], a
	bank1call HandleEnergyDiscardMenuInput
	jr c, .done ; finish if the B button was pressed
	ld hl, hCurSelectionItem
	inc [hl]
	call RemoveCardFromDuelTempList
	jr c, .done
	bank1call DisplayEnergyDiscardMenu
	jr .loop

.done
; returns carry if no cards were discarded
; output the result in hTemp_ffa0
	ldh a, [hCurSelectionItem]
	ldh [hTemp_ffa0], a
	or a
	ret nz
	scf
	ret

DiscardXAttachedFireEnergy_DiscardEffect:
	call CreateListOfFireEnergyAttachedToActive
	ldh a, [hTemp_ffa0]
	or a
	ret z ; no cards to discard

; discard cards from wDuelTempList equal to the number of cards that were input in hTemp_ffa0.
; these are all the Fire Energy cards attached to the Active Pokemon,
; so it will discard the cards in order of attachment and not the order selected by the player.
	ld c, a
	ld hl, wDuelTempList
.loop_discard
	ld a, [hli]
	call PutCardInDiscardPile
	dec c
	jr nz, .loop_discard
	ret

OpponentDeck_DiscardXCardsEffect:
	ldh a, [hTemp_ffa0]
	ld c, a
	ld b, $00
	call SwapTurn
	ld a, DUELVARS_NUMBER_OF_CARDS_NOT_IN_DECK
	call GetTurnDuelistVariable
	ld a, DECK_SIZE
	sub [hl]
	cp c
	jr nc, .start_discard
	; only discard the number of cards that are left in the deck
	ld c, a

.start_discard
	push bc
	inc c
	jr .check_remaining

.loop
	; discard the top card from the deck
	call DrawCardFromDeck
	call nc, PutCardInDiscardPile
.check_remaining
	dec c
	jr nz, .loop

	pop hl
	call LoadTxRam3
	ldtx hl, DiscardedCardsFromDeckText
	call DrawWideTextBox_PrintText
	jp SwapTurn

Discard2AttachedFireEnergy_PlayerSelection:
	ldtx hl, ChooseAndDiscard2FireEnergyCardsText
	call DrawWideTextBox_WaitForInput

	xor a
	ldh [hCurSelectionItem], a
	call CreateListOfFireEnergyAttachedToActive
	xor a
	bank1call DisplayEnergyDiscardScreen
.loop_input
	bank1call HandleEnergyDiscardMenuInput
	ret c ; exit if the B button was pressed
	call GetNextPositionInTempList
	ldh a, [hTempCardIndex_ff98]
	ld [hl], a
	call RemoveCardFromDuelTempList
	ldh a, [hCurSelectionItem]
	cp 2
	ret nc ; return when 2 have been chosen
	bank1call DisplayEnergyDiscardMenu
	jr .loop_input

Discard2AttachedFireEnergy_AISelection:
	call DiscardAttachedFireEnergy_AISelection
	ld a, [wDuelTempList + 1]
	ldh [hTempList + 1], a
	ret

Discard2AttachedFireEnergy_DiscardEffect:
	ldh a, [hTempList]
	call PutCardInDiscardPile
	ldh a, [hTempList + 1]
	jp PutCardInDiscardPile

DiscardAttachedWaterEnergy_PlayerSelection:
	ld a, TYPE_ENERGY_WATER
	jr DiscardAnAttachedEnergyOfSpecifiedType

DiscardAttachedPsychicEnergy_PlayerSelection:
	ld a, TYPE_ENERGY_PSYCHIC
;	fallthrough

; handle the display and input of the attached Energy card list
; input:
;	a = TYPE_ENERGY_* constant
DiscardAnAttachedEnergyOfSpecifiedType:
	call CreateListOfEnergyAttachedToActive
	xor a ; PLAY_AREA_ARENA
	bank1call DisplayEnergyDiscardScreen
	bank1call HandleEnergyDiscardMenuInput
	ret c ; exit if the B button was pressed
	ldh a, [hTempCardIndex_ff98]
	ldh [hTemp_ffa0], a ; store card chosen
	ret

DiscardAttachedWaterEnergy_AISelection:
	ld a, TYPE_ENERGY_WATER
	jr DiscardFirstAttachedEnergyOfSpecifiedType

DiscardAttachedPsychicEnergy_AISelection:
	ld a, TYPE_ENERGY_PSYCHIC
;	fallthrough

; AI picks the first suitable Energy in the list
; input:
;	a = TYPE_ENERGY_* constant
DiscardFirstAttachedEnergyOfSpecifiedType:
	call CreateListOfEnergyAttachedToActive
	ld a, [wDuelTempList] ; pick first card
	ldh [hTemp_ffa0], a
	ret

Discard2AttachedEnergyCards_PlayerSelection:
	ldtx hl, ChooseAndDiscard2EnergyCardsText
	call DrawWideTextBox_WaitForInput

	xor a
	ldh [hCurSelectionItem], a
	xor a
	call CreateArenaOrBenchEnergyCardList
	call SortCardsInDuelTempListByID
	xor a
	bank1call DisplayEnergyDiscardScreen

	ld a, 2
	ld [wEnergyDiscardMenuDenominator], a
.loop_input
	bank1call HandleEnergyDiscardMenuInput
	ret c ; exit if the B button was pressed
	call GetNextPositionInTempList
	ldh a, [hTempCardIndex_ff98]
	ld [hl], a
	ld hl, wEnergyDiscardMenuNumerator
	inc [hl]
	ldh a, [hCurSelectionItem]
	cp 2
	jp nc, NoCarryEF ; end loop and return when 2 have been chosen
	ldh a, [hTempCardIndex_ff98]
	call RemoveCardFromDuelTempList
	bank1call DisplayEnergyDiscardMenu
	jr .loop_input

Discard2AttachedEnergyCards_AISelection:
	xor a ; PLAY_AREA_ARENA
	call CreateArenaOrBenchEnergyCardList
	ld hl, wDuelTempList
	ld a, [hli]
	ldh [hTempList], a
	ld a, [hl]
	ldh [hTempList + 1], a
	ret

Discard2AttachedEnergyCards_DiscardEffect:
	ld hl, hTempList
	ld a, [hli]
	call PutCardInDiscardPile
	ld a, [hli]
	jp PutCardInDiscardPile

DiscardAllAttachedEnergyEffect:
	xor a
	call CreateArenaOrBenchEnergyCardList
	ld hl, wDuelTempList
; put all Energy cards in the discard pile
.loop
	ld a, [hli]
	cp $ff
	ret z
	call PutCardInDiscardPile
	jr .loop

OwnBench_10DamageEffect:
	ld a, TRUE
	ld [wIsDamageToSelf], a
	ld de, 10
;	fallthrough

; deal damage to all of the turn holder's Benched Pokemon
; input:
;	de = amount of damage to deal to each Pokemon
DealDamageToAllBenchedPokemon:
	ld a, DUELVARS_NUMBER_OF_POKEMON_IN_PLAY_AREA
	call GetTurnDuelistVariable
	ld c, a
	ld b, PLAY_AREA_ARENA
	jr .skip_to_bench
.loop
	push bc
	call DealDamageToPlayAreaPokemon_RegularAnim
	pop bc
.skip_to_bench
	inc b
	dec c
	jr nz, .loop
	ret

DamageEitherBench_50PercentEffect:
	ldtx de, DamageToOppBenchIfHeadsDamageToYoursIfTailsText
	call TossCoin_BankB
	ldh [hTemp_ffa0], a ; store coin result
	ret

DamageEitherBench_10DamageEffect:
	ldh a, [hTemp_ffa0]
	or a
	jr z, OwnBench_10DamageEffect
	
	; damage opponent's bench
	call SwapTurn
	ld de, 10
	call DealDamageToAllBenchedPokemon
	jp SwapTurn

Selfdestruct40Effect:
	ld a, 40
	call DealRecoilDamageToSelf
;	fallthrough

DamageBothBenches_10DamageEffect:
	call OwnBench_10DamageEffect

	; damage opponent's bench
	call SwapTurn
	xor a
	ld [wIsDamageToSelf], a
	ld de, 10
	call DealDamageToAllBenchedPokemon
	jp SwapTurn

Selfdestruct60Effect:
	ld a, 60
	call DealRecoilDamageToSelf
	jr DamageBothBenches_10DamageEffect

Explosion80DamageEffect:
	ld a, 80
	call DealRecoilDamageToSelf
	jr DamageBothBenches_20DamageEffect
	
Explosion100DamageEffect:
	ld a, 100
	call DealRecoilDamageToSelf
;	fallthrough

DamageBothBenches_20DamageEffect:
; own bench
	ld a, TRUE
	ld [wIsDamageToSelf], a
	ld de, 20
	call DealDamageToAllBenchedPokemon
; opponent's bench
	call SwapTurn
	xor a
	ld [wIsDamageToSelf], a
	ld de, 20
	call DealDamageToAllBenchedPokemon
	jp SwapTurn


;---------------------------------------------------------------------------------
; (12) ATTACK EFFECTS THAT DAMAGE THE OPPONENT'S BENCH ARE NEXT.
;---------------------------------------------------------------------------------

Also10DamageTo1Benched_DamageEffect:
	ldh a, [hTemp_ffa0]
	cp $ff
	ret z ; no target chosen
	call SwapTurn
	ld b, a
	ld de, 10
	call DealDamageToPlayAreaPokemon_RegularAnim
	jp SwapTurn

AlsoDamageTo3Benched_PlayerSelection:
	call SwapTurn
	ld a, DUELVARS_NUMBER_OF_POKEMON_IN_PLAY_AREA
	call GetTurnDuelistVariable
	cp 2
	jr nc, .has_bench
	call SwapTurn
	ld a, $ff
	ldh [hTempList], a
	ret

.has_bench
	ldtx hl, ChooseUpTo3PkmnOnBenchToGiveDamageText
	call DrawWideTextBox_WaitForInput

; init number of items in list and cursor position
	xor a
	ldh [hCurSelectionItem], a
	ld [wCurGigashockItem], a
	call Func_61a1
.start
	bank1call PrintPlayAreaCardList_EnableLCD
	push af
	ld a, [wCurGigashockItem]
	ld hl, BenchSelectionMenuParameters
	call InitializeMenuParameters
	pop af

; exclude the Active Pokemon from the number of items
	dec a
	ld [wNumMenuItems], a

.loop_input
	call DoFrame
	call HandleMenuInput
	jr nc, .loop_input
	cp -1
	jr z, .try_cancel

	ld [wCurGigashockItem], a
	call .CheckIfChosenAlready
	jr nc, .not_chosen
	; play SFX
	call PlaySFX_InvalidChoice
	jr .loop_input

.not_chosen
; mark this Play Area location
	ldh a, [hCurMenuItem]
	inc a
	ld b, SYM_LIGHTNING
	call DrawSymbolOnPlayAreaCursor
; store it in the list of chosen Benched Pokemon
	call GetNextPositionInTempList
	ldh a, [hCurMenuItem]
	inc a
	ld [hl], a

; check if 3 were chosen already
	ldh a, [hCurSelectionItem]
	ld c, a
	cp 3
	jr nc, .chosen

	ld a, DUELVARS_NUMBER_OF_POKEMON_IN_PLAY_AREA
	call GetTurnDuelistVariable
	dec a
	cp c
	jr nz, .start ; if more options are available, loop back
	; fallthrough if no other options available to choose

.chosen
	ldh a, [hCurMenuItem]
	inc a
	call Func_2c10b
	ldh a, [hKeysPressed]
	and B_BUTTON
	jr nz, .try_cancel
	call SwapTurn
	call GetNextPositionInTempList
	ld [hl], $ff ; terminating byte
	ret

.try_cancel
	ldh a, [hCurSelectionItem]
	or a
	jr z, .start ; none selected, can safely loop back to start

; undo last selection made
	dec a
	ldh [hCurSelectionItem], a
	ld e, a
	ld d, $00
	ld hl, hTempList
	add hl, de
	ld a, [hl]

	push af
	ld b, SYM_SPACE
	call DrawSymbolOnPlayAreaCursor
	call EraseCursor
	pop af

	dec a
	ld [wCurGigashockItem], a
	jr .start

; returns carry if a Benched Pokemon in register a was already chosen.
.CheckIfChosenAlready
	inc a
	ld c, a
	ldh a, [hCurSelectionItem]
	ld b, a
	ld hl, hTempList
	inc b
	jr .next_check
.check_chosen
	ld a, [hli]
	cp c
	scf
	ret z ; return if chosen already
.next_check
	dec b
	jr nz, .check_chosen
	or a
	ret

BenchSelectionMenuParameters:
	db 0, 3 ; cursor x, cursor y
	db 3 ; y displacement between items
	db MAX_PLAY_AREA_POKEMON ; number of items
	db SYM_CURSOR_R ; cursor tile number
	db SYM_SPACE ; tile behind cursor
	dw NULL ; function pointer if non-0

AlsoDamageTo3Benched_AISelection:
; if Bench has 3 Pokemon or less, no need for selection,
; since AI will choose them all.
	ld a, DUELVARS_NUMBER_OF_POKEMON_IN_PLAY_AREA
	call GetNonTurnDuelistVariable
	cp MAX_PLAY_AREA_POKEMON - 1
	jr nc, .start_selection

; select them all
	ld hl, hTempList
	ld b, PLAY_AREA_ARENA
	jr .next_bench
.select_bench
	ld [hl], b
	inc hl
.next_bench
	inc b
	dec a
	jr nz, .select_bench
	ld [hl], $ff ; terminating byte
	ret

; there are more than 3 Benched Pokemon,
; so sort them from lowest remaining HP to highest,
; and pick the first 3 in the list.
.start_selection
	call SwapTurn
	dec a
	ld c, a
	ld b, PLAY_AREA_BENCH_1

; first, select all of the Benched Pokemon and add them to the list
	ld hl, hTempList
.loop_all
	ld [hl], b
	inc hl
	inc b
	dec c
	jr nz, .loop_all
	ld [hl], $00 ; end list with $00

; then check every Benched Pokemon's current HP,
; and sort them from lowest to highest.
	ld de, hTempList
.loop_outer
	ld a, [de]
	add DUELVARS_ARENA_CARD_HP
	call GetTurnDuelistVariable
	ld c, a
	ld l, e
	ld h, d
	inc hl

.loop_inner
	ld a, [hli]
	or a
	jr z, .next ; reaching $00 means it's end of list

	push hl
	add DUELVARS_ARENA_CARD_HP
	call GetTurnDuelistVariable
	pop hl
	cp c
	jr c, .loop_inner
	; a Benched Pokemon was found with less HP
	ld c, a ; store its HP

; switch the two
	dec hl
	ld b, [hl]
	ld a, [de]
	ld [hli], a
	ld a, b
	ld [de], a
	jr .loop_inner

.next
	inc de
	ld a, [de]
	or a
	jr nz, .loop_outer

; done
	ld a, $ff ; terminating byte
	ldh [hTempList + 3], a
	jp SwapTurn

AlsoDamageTo3Benched_10DamageEffect:
	call SwapTurn
	ld hl, hTempList
.loop_selection
	ld a, [hli]
	cp $ff
	jp z, SwapTurn ; done with loop
	push hl
	ld b, a
	ld de, 10
	call DealDamageToPlayAreaPokemon_RegularAnim
	pop hl
	jr .loop_selection

Also10DamageToSameColorOnBenchEffect:
	ld a, 10
	call SetDefiniteDamage
	call SwapTurn
	call GetArenaCardColor
	call SwapTurn
	ldh [hCurSelectionItem], a
	cp COLORLESS
	ret z ; don't damage if colorless

; opponent's Bench
	call SwapTurn
	call .DamageSameColorBench
	call SwapTurn

; own Bench
	ld a, TRUE
	ld [wIsDamageToSelf], a
	; fallthrough

.DamageSameColorBench
	ld a, DUELVARS_NUMBER_OF_POKEMON_IN_PLAY_AREA
	call GetTurnDuelistVariable
	ld e, a
	ld d, PLAY_AREA_ARENA
	jr .next_bench

.check_damage
	ld a, d
	call GetPlayAreaCardColor
	ld c, a
	ldh a, [hCurSelectionItem]
	cp c
	jr nz, .next_bench ; skip if not the same color
; apply damage to this Bench card
	push de
	ld b, d
	ld de, 10
	call DealDamageToPlayAreaPokemon_RegularAnim
	pop de

.next_bench
	inc d
	dec e
	jr nz, .check_damage
	ret

ThunderstormEffect:
	ld a, 1
	ldh [hCurSelectionItem], a

	call SwapTurn
	ld a, DUELVARS_NUMBER_OF_POKEMON_IN_PLAY_AREA
	call GetTurnDuelistVariable
	ld c, a
	ld b, 0
	ld e, b
	jr .next_pkmn

.check_damage
	push de
	push bc
	call .DisplayText
	ld de, $0
	call SwapTurn
	call TossCoin_BankB
	call SwapTurn
	push af
	call GetNextPositionInTempList
	pop af
	ld [hl], a ; store result in list
	pop bc
	pop de
	jr c, .next_pkmn
	inc b ; increase number of tails

.next_pkmn
	inc e
	dec c
	jr nz, .check_damage

; all coins were tossed for each Benched Pokemon
	call GetNextPositionInTempList
	ld [hl], $ff
	ld a, b
	ldh [hTemp_ffa0], a
	call ResetAnimationQueue
	call SwapTurn

; tally recoil damage
	ldh a, [hTemp_ffa0]
	or a
	jr z, .skip_recoil
	; deal number of tails times 10 to self
	call ATimes10
	call DealRecoilDamageToSelf

; deal damage for Benched Pokemon that got heads
.skip_recoil
	call SwapTurn
	ld hl, hTempPlayAreaLocation_ffa1
	ld b, PLAY_AREA_BENCH_1
.loop_bench
	ld a, [hli]
	cp $ff
	jp z, SwapTurn ; done with loop
	or a
	jr z, .skip_damage ; skip if tails
	ld de, 20
	call DealDamageToPlayAreaPokemon_RegularAnim
.skip_damage
	inc b
	jr .loop_bench

; displays text for the current Benched Pokemon,
; printing its Bench number and name.
.DisplayText
	ld b, e
	ldtx hl, BenchText
	ld de, wDefaultText
	call CopyText
	ld a, $30 ; 0 FW character
	add b
	ld [de], a
	inc de
	ld a, $20 ; space FW character
	ld [de], a
	inc de

	ld a, DUELVARS_ARENA_CARD
	add b
	call GetTurnDuelistVariable
	call LoadCardDataToBuffer2_FromDeckIndex
	ld hl, wLoadedCard2Name
	ld a, [hli]
	ld h, [hl]
	ld l, a
	call CopyText

	xor a
	ld [wDuelDisplayedScreen], a
	ret

DamageTo1Benched_20DamageEffect:
	call SwapTurn
	ldh a, [hTemp_ffa0]
	ld b, a
	ld de, 20
	call DealDamageToPlayAreaPokemon_RegularAnim
	jp SwapTurn


;---------------------------------------------------------------------------------
; (13) THE REMAINING ATTACK EFFECTS THAT UTILIZE RANDOMNESS ARE NEXT.
; (METRONOME AND MIRROR MOVE ARE ALSO INCLUDED)
;---------------------------------------------------------------------------------

; randomly finds an occupied zone in the Turn Player's Play Area
; and stores the location in a.
PickRandomPlayAreaCard:
	ld a, DUELVARS_NUMBER_OF_POKEMON_IN_PLAY_AREA
	call GetTurnDuelistVariable
	call Random
	or a
	ret

; also loads the Cat Punch animation
RandomEnemy20DamageEffect:
	call SwapTurn
	call PickRandomPlayAreaCard
	ld b, a
	ld a, ATK_ANIM_CAT_PUNCH_PLAY_AREA
	ld [wLoadedAttackAnimation], a
	ld de, 20
	call DealDamageToPlayAreaPokemon
	jp SwapTurn

RandomEnemy30DamageEffect:
	call SwapTurn
	call PickRandomPlayAreaCard
	ld b, a
	ld de, 30
	call DealDamageToPlayAreaPokemon_RegularAnim
	jp SwapTurn

; ZeroDamage was used with EFFECTCMDTYPE_BEFORE_DAMAGE
; in the ArticunoQuickfreezeEffectCommands.
; The developers most likely intended to put 40 damage for
; the Ice Breath attack in cards.asm so that the number
; would be displayed when looking at the card.
; Had that been done, then the ZeroDamage function would
; remove the damage before it was dealt to the Defending Pokemon.
;ZeroDamage:
;	xor a
;	jp SetDefiniteDamage
;
RandomEnemy40DamageEffect:
	call SwapTurn
	call PickRandomPlayAreaCard
	ld b, a
	ld de, 40
	call DealDamageToPlayAreaPokemon_RegularAnim
	jp SwapTurn

Random70DamageEffect:
	call ExchangeRNG
	ld de, 70 ; damage to inflict
;	fallthrough

; randomly damages another in-play Pokemon
; ignores the card that is in [hTempPlayAreaLocation_ff9d]
; plays thunder animation when Play Area is shown.
; input:
;	de = amount of damage to deal
RandomlyDamagePlayAreaPokemon:
	xor a
	ld [wNoDamageOrEffect], a

; choose randomly which Play Area to attack
	call UpdateRNGSources
	and 1
	jr nz, .opp_play_area

; own Play Area
	ld a, TRUE
	ld [wIsDamageToSelf], a
	ld a, DUELVARS_NUMBER_OF_POKEMON_IN_PLAY_AREA
	call GetTurnDuelistVariable
	call Random
	ld b, a
	; can't select Zapdos
	ldh a, [hTempPlayAreaLocation_ff9d]
	cp b
	jr z, RandomlyDamagePlayAreaPokemon ; re-roll Pokemon to attack

.damage
	ld a, ATK_ANIM_THUNDER_PLAY_AREA
	ld [wLoadedAttackAnimation], a
	jp DealDamageToPlayAreaPokemon

.opp_play_area
	xor a
	ld [wIsDamageToSelf], a
	call SwapTurn
	ld a, DUELVARS_NUMBER_OF_POKEMON_IN_PLAY_AREA
	call GetTurnDuelistVariable
	call Random
	ld b, a
	call .damage
	jp SwapTurn

MysteryAttack_RandomEffect:
	ld a, 10
	call SetDefiniteDamage

; chooses a random effect from 8 possible options.
	call UpdateRNGSources
	and %111
	ldh [hTemp_ffa0], a
	ld hl, .random_effect
	jp JumpToFunctionInTable

.random_effect
	dw ParalysisEffect
	dw PoisonEffect
	dw SleepEffect
	dw ConfusionEffect
	dw .no_effect ; this will actually activate the recovery effect afterwards
	dw .no_effect
	dw .more_damage
	dw .no_damage

.more_damage
	ld a, 20
	jp SetDefiniteDamage

.no_damage
	ld a, ATK_ANIM_GLOW_EFFECT
	ld [wLoadedAttackAnimation], a
	xor a
	call SetDefiniteDamage
	call SetNoEffectFromStatus
.no_effect
	ret

; in case the 5th option was chosen for the random effect,
; trigger the recovery effect for 10 HP.
MysteryAttack_RecoverEffect:
	ldh a, [hTemp_ffa0]
	cp 4
	ret nz
	ld de, 10
	jp ApplyAndAnimateHPRecovery

OpponentHand_ReplacePokemonInEffect:
	call SwapTurn
	call CreateHandCardList
	call SortCardsInDuelTempListByID

; first go through the hand and place all Pokemon cards back into the deck.
	ld hl, wDuelTempList
	ld c, 0
.loop_hand
	ld a, [hl]
	cp $ff
	jr z, .done_hand
	call .CheckIfCardIsPkmnCard
	jr nc, .next_hand
; found a Pokemon card to place in the deck
	inc c
	ld a, [hl]
	call RemoveCardFromHand
	call ReturnCardToDeck
.next_hand
	inc hl
	jr .loop_hand

.done_hand
	ld a, c
	ldh [hCurSelectionItem], a
	push bc
	ldtx hl, ThePkmnCardsInHandAndDeckWereShuffledText
	call DrawWideTextBox_WaitForInput

	call ShuffleCardsInDeck
	call CreateDeckCardList
	pop bc
	ldh a, [hCurSelectionItem]
	or a
	jp z, SwapTurn ; return if no cards were removed from the hand

; c holds the number of cards that were placed in the deck.
; now pick Pokemon from the deck to place in the hand.
	ld hl, wDuelTempList
.loop_deck
	ld a, [hl]
	call .CheckIfCardIsPkmnCard
	jr nc, .next_deck
	dec c
	ld a, [hl]
	call SearchCardInDeckAndAddToHand
	call AddCardToHand
.next_deck
	inc hl
	ld a, c
	or a
	jr nz, .loop_deck
	jp SwapTurn

; returns carry if card index in a is a Pokemon
.CheckIfCardIsPkmnCard
	call LoadCardDataToBuffer2_FromDeckIndex
	ld a, [wLoadedCard2Type]
	cp TYPE_ENERGY
	ret

ShuffleAttachedEnergyEffect:
	ld a, DUELVARS_CARD_LOCATIONS
	call GetTurnDuelistVariable

; writes in wDuelTempList all deck indices of Energy cards
; attached to Pokemon in the Turn Duelist's Play Area.
	ld de, wDuelTempList
	ld c, 0
.loop_card_locations
	ld a, [hl]
	and CARD_LOCATION_PLAY_AREA
	jr z, .next_card_location

; is a card that is in the Turn Duelist's Play Area
	push hl
	push de
	push bc
	ld a, l
	call GetCardIDFromDeckIndex
	call GetCardType
	pop bc
	pop de
	pop hl
	and TYPE_ENERGY
	jr z, .next_card_location
; is an Energy card attached to a Pokemon in the Turn Duelist's Play Area
	ld a, l
	ld [de], a
	inc de
	inc c
.next_card_location
	inc l
	ld a, l
	cp DECK_SIZE
	jr c, .loop_card_locations
	ld a, $ff ; terminating byte
	ld [de], a

; divide the number of Energy cards by the number of in-play Pokemon
	ld a, DUELVARS_NUMBER_OF_POKEMON_IN_PLAY_AREA
	call GetTurnDuelistVariable
	ld b, a
	ld a, c
	ld c, -1
.loop_division
	inc c
	sub b
	jr nc, .loop_division
	; c = floor(a / b)

; evenly divides the Energy cards randomly to every Pokemon in the Play Area.
	push bc
	ld hl, wDuelTempList
	call CountCardsInDuelTempList
	call ShuffleCards
	ld d, c
	ld e, PLAY_AREA_ARENA
.start_attach
	ld c, d
	inc c
	jr .check_done
.attach_energy
	ld a, [hli]
	push hl
	push de
	push bc
	call AddCardToHand
	call PutHandCardInPlayArea
	pop bc
	pop de
	pop hl
.check_done
	dec c
	jr nz, .attach_energy
; go to next Pokemon in the Turn Duelist's Play Area
	inc e ; next in Play Area
	dec b
	jr nz, .start_attach
	pop bc

	push hl
	ld hl, hTempList

; fill hTempList with PLAY_AREA_* locations that have Pokemon in them.
	push hl
	xor a
.loop_init
	ld [hli], a
	inc a
	cp b
	jr nz, .loop_init
	pop hl

; shuffle them and distribute the remaining cards in random order.
	ld a, b
	call ShuffleCards
	pop hl
	ld de, hTempList
.next_random_pokemon
	ld a, [hl]
	cp $ff
	jr z, .done
	push hl
	push de
	ld a, [de]
	ld e, a
	ld a, [hl]
	call AddCardToHand
	call PutHandCardInPlayArea
	pop de
	pop hl
	inc hl
	inc de
	jr .next_random_pokemon

.done
	bank1call DrawDuelMainScene
	bank1call DrawDuelHUDs
	ldtx hl, TheEnergyCardFromPlayAreaWasMovedText
	call DrawWideTextBox_WaitForInput
	xor a
	jp Func_2c10b

MorphEffect:
	call ExchangeRNG
	call .PickRandomBasicPokemonFromDeck
	jr nc, .successful
	ldtx hl, AttackUnsuccessfulText
	jp DrawWideTextBox_WaitForInput

.successful
	ld a, DUELVARS_ARENA_CARD_STAGE
	call GetTurnDuelistVariable
	or a
	jr z, .skip_discard_stage_below

; if this is an Evolved Pokemon (in case it's used by Clefable's Metronome attack),
; then first discard the lower stage card.
	push hl
	xor a
	ldh [hTempPlayAreaLocation_ff9d], a
	bank1call GetCardOneStageBelow
	ld a, d
	call PutCardInDiscardPile
	pop hl
	ld [hl], BASIC

.skip_discard_stage_below
; overwrite card ID
	ldh a, [hTempCardIndex_ff98]
	call GetCardIDFromDeckIndex
	ld a, DUELVARS_ARENA_CARD
	call GetTurnDuelistVariable
	ldh [hTempCardIndex_ff98], a
	call _GetCardIDFromDeckIndex
	ld [hl], e

; overwrite HP to new card's maximum HP
	ld e, PLAY_AREA_ARENA
	call GetCardDamageAndMaxHP
	ld a, DUELVARS_ARENA_CARD_HP
	call GetTurnDuelistVariable
	ld [hl], c

; clear changed color and status
	ld l, DUELVARS_ARENA_CARD_CHANGED_TYPE
	ld [hl], $00
	call ClearAllStatusConditions

; load both card's names for printing text
	ld a, [wTempTurnDuelistCardID]
	ld e, a
	ld d, $00
	call LoadCardDataToBuffer2_FromCardID
	ld hl, wLoadedCard2Name
	ld de, wTxRam2
	ld a, [hli]
	ld [de], a
	inc de
	ld a, [hl]
	ld [de], a
	inc de
	ldh a, [hTempCardIndex_ff98]
	call LoadCardDataToBuffer2_FromDeckIndex
	ld hl, wLoadedCard2Name
	ld a, [hli]
	ld [de], a
	inc de
	ld a, [hl]
	ld [de], a
	ldtx hl, MetamorphsToText
	call DrawWideTextBox_WaitForInput

	xor a
	ld [wDuelDisplayedScreen], a
	ret

; picks a random Pokemon from the deck to morph into.
; needs to be a Basic Pokemon that doesn't have
; the same ID as the Active Pokemon.
; returns carry if no Pokemon were found.
.PickRandomBasicPokemonFromDeck
	call CreateDeckCardList
	ret c ; return if deck is empty
	ld hl, wDuelTempList
	call ShuffleCards
.loop_deck
	ld a, [hli]
	ldh [hTempCardIndex_ff98], a
	cp $ff
	jp z, SetCarryEF
	call CheckDeckIndexForBasicPokemon
	jr nc, .loop_deck ; skip if not a Basic Pokemon
	ld a, [wLoadedCard2ID]
	cp DUELVARS_ARENA_CARD
	jr z, .loop_deck ; skip cards with same ID as the Active Pokemon
	ldh a, [hTempCardIndex_ff98]
	or a
	ret

; does nothing for AI.
Metronome_AISelection:
	ret

ClefairyMetronome_UseAttackEffect:
	ld a, 3 ; energy cost of this attack
	jr HandlePlayerMetronomeEffect

ClefableMetronome_UseAttackEffect:
	ld a, 1 ; energy cost of this attack
;	fallthrough

; handles Metronome selection, and validates whether it can use the selected attack.
; if unsuccessful, returns carry.
; input: a = amount of colorless energy needed for Metronome
HandlePlayerMetronomeEffect:
	ld [wMetronomeEnergyCost], a
	ldtx hl, ChooseOppAttackToBeUsedWithMetronomeText
	call DrawWideTextBox_WaitForInput

	call HandleDefendingPokemonAttackSelection
	ret c ; return if operation was cancelled

; store this attack as the selected attack to use
	ld hl, wMetronomeSelectedAttack
	ld [hl], d
	inc hl
	ld [hl], e

; compare the selected attack's name to the current attack
; in order to rule out another Metronome (to avoid an infinite loop).
	ld hl, wLoadedAttackName
	ld a, [hli]
	ld h, [hl]
	ld l, a
	push hl
	call SwapTurn
	call CopyAttackDataAndDamage_FromDeckIndex
	call SwapTurn
	pop de
	ld hl, wLoadedAttackName
	ld a, e
	cp [hl]
	jr nz, .try_use
	inc hl
	ld a, d
	cp [hl]
	jr nz, .try_use
	; cannot select Metronome
	ldtx hl, UnableToSelectText
.failed
	call DrawWideTextBox_WaitForInput
; set carry
	scf
	ret

.try_use
; run the attack checks to determine whether it can be used.
	ld a, EFFECTCMDTYPE_INITIAL_EFFECT_1
	call TryExecuteEffectCommandFunction
	jr c, .failed
	ld a, EFFECTCMDTYPE_INITIAL_EFFECT_2
	call TryExecuteEffectCommandFunction
	ret c
	; successful

; send data to link opponent
	call SendAttackDataToLinkOpponent
	ld a, OPPACTION_USE_METRONOME_ATTACK
	call SetOppAction_SerialSendDuelData
	ld hl, wMetronomeSelectedAttack
	ld d, [hl]
	inc hl
	ld e, [hl]
	ld a, [wMetronomeEnergyCost]
	ld c, a
	call SerialSend8Bytes

	ldh a, [hTempCardIndex_ff9f]
	ld [wPlayerAttackingCardIndex], a
	ld a, [wSelectedAttack]
	ld [wPlayerAttackingAttackIndex], a
	ld a, [wTempCardID_ccc2]
	ld [wPlayerAttackingCardID], a
	or a
	ret

MirrorMove_AIEffect:
	ld a, DUELVARS_ARENA_CARD_LAST_TURN_DAMAGE
	call GetTurnDuelistVariable
	ld a, [hl]
	ld [wAIMinDamage], a
	ld [wAIMaxDamage], a
	ret

; returns carry if the Pokemon wasn't attacked in the previous turn
MirrorMove_AttackedCheck:
	ld a, DUELVARS_ARENA_CARD_LAST_TURN_DAMAGE
	call GetTurnDuelistVariable
	ld a, [hli]
	or [hl]
	inc hl
	or [hl]
	inc hl
	ret nz ; return if has last turn damage
	ld a, [hli]
	or a
	ret nz ; return if has last turn status
	; no attack received last turn
	ldtx hl, YouDidNotReceiveAnAttackToMirrorMoveText
	scf
	ret

MirrorMove_AmnesiaCheck:
	ld a, $ff
	ldh [hTemp_ffa0], a
	ld a, DUELVARS_ARENA_CARD_LAST_TURN_EFFECT
	call GetTurnDuelistVariable
	or a
	ret z ; no effect
	cp LAST_TURN_EFFECT_AMNESIA
	jp z, Amnesia_PlayerSelection
	or a
	ret

MirrorMove_PlayerSelection:
	ld a, DUELVARS_ARENA_CARD_LAST_TURN_EFFECT
	call GetTurnDuelistVariable
	or a
	ret z ; no effect
; handle Energy card discard effect
	cp LAST_TURN_EFFECT_DISCARD_ENERGY
	jp z, DiscardEnergyDefendingPokemon_PlayerSelection
	ret

MirrorMove_AISelection:
	ld a, $ff
	ldh [hTemp_ffa0], a
	ld a, DUELVARS_ARENA_CARD_LAST_TURN_EFFECT
	call GetTurnDuelistVariable
	or a
	ret z ; no effect
	cp LAST_TURN_EFFECT_DISCARD_ENERGY
	jr z, .discard_energy
	cp LAST_TURN_EFFECT_AMNESIA
	jp z, Amnesia_AISelection
	ret
.discard_energy
	call EnergyRemoval_AISelection
	ldh [hTemp_ffa0], a
	ret

MirrorMove_BeforeDamage:
; if user was attacked with Amnesia, apply it to the selected attack
	ld a, DUELVARS_ARENA_CARD_LAST_TURN_EFFECT
	call GetTurnDuelistVariable
	cp LAST_TURN_EFFECT_AMNESIA
	jp z, AttackDisableEffect ; Amnesia

; otherwise, check if there was last turn damage,
; and write it to wDamage.
	ld a, DUELVARS_ARENA_CARD_LAST_TURN_DAMAGE
	call GetTurnDuelistVariable
	ld de, wDamage
	ld a, [hli]
	ld [de], a
	inc de
	ld a, [hld]
	ld [de], a
	or [hl]
	jr z, .no_damage
	ld a, ATK_ANIM_HIT
	ld [wLoadedAttackAnimation], a
.no_damage
	inc hl
	inc hl ; DUELVARS_ARENA_CARD_LAST_TURN_STATUS
; check if there was a status applied to the Defending Pokemon from the attack
	push hl
	ld a, DUELVARS_ARENA_CARD_STATUS
	call GetNonTurnDuelistVariable
	ld e, l
	ld d, h
	pop hl
	ld a, [hli]
	or a
	jr z, .no_status
	push hl
	push de
	call .ExecuteStatusEffect
	pop de
	pop hl
.no_status
; hl is at DUELVARS_ARENA_CARD_LAST_TURN_SUBSTATUS2
; apply substatus2 to self
	ld e, DUELVARS_ARENA_CARD_SUBSTATUS2
	ld a, [hli]
	ld [de], a
	ret

.ExecuteStatusEffect
	ld c, a
	and PSN_DBLPSN
	jr z, .cnf_slp_prz
	ld b, a
	cp DOUBLE_POISONED
	push bc
	call z, DoublePoisonEffect
	pop bc
	ld a, b
	cp POISONED
	push bc
	call z, PoisonEffect
	pop bc
.cnf_slp_prz
	ld a, c
	and CNF_SLP_PRZ
	ret z
	cp CONFUSED
	jp z, ConfusionEffect
	cp ASLEEP
	jp z, SleepEffect
	cp PARALYZED
	jp z, ParalysisEffect
	ret

MirrorMove_AfterDamage:
	ld a, [wNoDamageOrEffect]
	or a
	ret nz ; is unaffected
	ld a, DUELVARS_ARENA_CARD_LAST_TURN_EFFECT
	call GetTurnDuelistVariable
	cp LAST_TURN_EFFECT_DISCARD_ENERGY
	jr nz, .change_weakness

; execute Energy discard effect for the chosen card
	call SwapTurn
	ldh a, [hTemp_ffa0]
	call PutCardInDiscardPile
	ld a, DUELVARS_ARENA_CARD_LAST_TURN_EFFECT
	call GetTurnDuelistVariable
	ld [hl], LAST_TURN_EFFECT_DISCARD_ENERGY
	call SwapTurn

.change_weakness
	ld a, DUELVARS_ARENA_CARD_LAST_TURN_CHANGE_WEAK
	call GetTurnDuelistVariable
	ld a, [hl]
	or a
	ret z ; weakness wasn't changed last turn

	push hl
	call SwapTurn
	ld a, DUELVARS_ARENA_CARD
	call GetTurnDuelistVariable
	call LoadCardDataToBuffer2_FromDeckIndex
	call SwapTurn
	pop hl

	ld a, [wLoadedCard2Weakness]
	or a
	ret z ; the Defending Pokemon has no weakness to change

; apply same color weakness to Defending Pokemon
	ld a, [hl]
	push af
	ld a, DUELVARS_ARENA_CARD_CHANGED_WEAKNESS
	call GetNonTurnDuelistVariable
	pop af
	ld [hl], a

; print message of weakness color change
	ld c, -1
.loop_color
	inc c
	rla
	jr nc, .loop_color
	ld a, c
	call SwapTurn
	push af
	ld a, DUELVARS_ARENA_CARD
	call GetTurnDuelistVariable
	call LoadCardDataToBuffer1_FromDeckIndex
	pop af
	call LoadCardNameAndInputColor
	ldtx hl, ChangedTheWeaknessOfPokemonToColorText
	call DrawWideTextBox_PrintText
	jp SwapTurn


;---------------------------------------------------------------------------------
; (14) POKEMON POWER EFFECTS START HERE.
; 12/26 POWERS ARE ACTUALLY HANDLED ELSEWHERE (They're paired with SetCarryEF)
;---------------------------------------------------------------------------------

; returns carry if no Grass Energy are in the Play Area
EnergyTransCheck:
	ldh a, [hTempPlayAreaLocation_ff9d]
	ldh [hTemp_ffa0], a
	ldh a, [hTempPlayAreaLocation_ff9d]
	call CheckCannotUseDueToStatus_OnlyToxicGasIfANon0
	ret c ; cannot use Pkmn Power

; search in Play Area for at least 1 Grass Energy
	ld a, DUELVARS_CARD_LOCATIONS
	call GetTurnDuelistVariable
.loop_deck
	ld a, [hl]
	and CARD_LOCATION_PLAY_AREA
	jr z, .next
	push hl
	ld a, l
	call GetCardIDFromDeckIndex
	call GetCardType
	pop hl
	cp TYPE_ENERGY_GRASS
	ret z
.next
	inc l
	ld a, l
	cp DECK_SIZE
	jr c, .loop_deck

; none found
	ldtx hl, NoGrassEnergyText
	scf
	ret

EnergyTrans_PrintProcedureText:
	ldtx hl, ProcedureForEnergyTransferText
	bank1call DrawWholeScreenTextBox
	or a
	ret

EnergyTrans_TransferEffect:
	ld a, DUELVARS_DUELIST_TYPE
	call GetTurnDuelistVariable
	cp DUELIST_TYPE_PLAYER
	jr z, .player
; not player
	call Func_61a1
	bank1call PrintPlayAreaCardList_EnableLCD
	ret

.player
	xor a
	ldh [hCurSelectionItem], a
	call Func_61a1

.draw_play_area
	bank1call PrintPlayAreaCardList_EnableLCD
	push af
	ldh a, [hCurSelectionItem]
	ld hl, PlayAreaSelectionMenuParameters
	call InitializeMenuParameters
	pop af
	ld [wNumMenuItems], a

; handle the action of taking a Grass Energy card
.loop_input_take
	call DoFrame
	call HandleMenuInput
	jr nc, .loop_input_take
	cp -1 ; b press?
	ret z

; a press
	ldh [hAIPkmnPowerEffectParam], a
	ldh [hCurSelectionItem], a
	call CheckIfCardHasGrassEnergyAttached
	jr c, .play_sfx ; no attached Grass Energy

	ldh [hAIEnergyTransEnergyCard], a
	; temporarily take card away to draw Play Area
	call AddCardToHand
	bank1call PrintPlayAreaCardList_EnableLCD
	ldh a, [hAIPkmnPowerEffectParam]
	ld e, a
	ldh a, [hAIEnergyTransEnergyCard]
	; give card back
	call PutHandCardInPlayArea

	; draw Grass symbol near cursor
	ldh a, [hAIPkmnPowerEffectParam]
	ld b, SYM_GRASS
	call DrawSymbolOnPlayAreaCursor

; handle the action of placing a Grass Energy card
.loop_input_put
	call DoFrame
	call HandleMenuInput
	jr nc, .loop_input_put
	cp -1 ; b press?
	jr z, .remove_symbol

; a press
	ldh [hCurSelectionItem], a
	ldh [hAIEnergyTransPlayAreaLocation], a
	ld a, OPPACTION_6B15
	call SetOppAction_SerialSendDuelData
	ldh a, [hAIEnergyTransPlayAreaLocation]
	ld e, a
	ldh a, [hAIEnergyTransEnergyCard]
	; give card being held to this Pokemon
	call AddCardToHand
	call PutHandCardInPlayArea

.remove_symbol
	ldh a, [hAIPkmnPowerEffectParam]
	ld b, SYM_SPACE
	call DrawSymbolOnPlayAreaCursor
	call EraseCursor
	jr .draw_play_area

.play_sfx
	call PlaySFX_InvalidChoice
	jr .loop_input_take

; returns carry if no Grass Energy cards attached to card in Play Area location of a.
; input:
;	a = PLAY_AREA_* of location to check
CheckIfCardHasGrassEnergyAttached:
	or CARD_LOCATION_PLAY_AREA
	ld e, a

	ld a, DUELVARS_CARD_LOCATIONS
	call GetTurnDuelistVariable
.loop
	ld a, [hl]
	cp e
	jr nz, .next
	push de
	push hl
	ld a, l
	call GetCardIDFromDeckIndex
	call GetCardType
	pop hl
	pop de
	cp TYPE_ENERGY_GRASS
	jr z, .no_carry
.next
	inc l
	ld a, l
	cp DECK_SIZE
	jr c, .loop
	scf
	ret
.no_carry
	ld a, l
	or a
	ret

EnergyTrans_AIEffect:
	ldh a, [hAIEnergyTransPlayAreaLocation]
	ld e, a
	ldh a, [hAIEnergyTransEnergyCard]
	call AddCardToHand
	call PutHandCardInPlayArea
	bank1call PrintPlayAreaCardList_EnableLCD
	ret

; returns carry if Solar Power cannot be used
SolarPowerCheck:
	call OncePerTurnPokePowerCheck
	ret c ; already used power or can't use due to status or Toxic Gas

; returns carry if no Active Pokemon are affected by special conditions
	ld a, DUELVARS_ARENA_CARD_STATUS
	call GetTurnDuelistVariable
	or a
	jr nz, .has_status
	ld a, DUELVARS_ARENA_CARD_STATUS
	call GetNonTurnDuelistVariable
	or a
	jr nz, .has_status
; neither active has any special conditions
	ldtx hl, NotAffectedBySpecialConditionsText
	scf
	ret
.has_status
	or a
	ret

SolarPower_RemoveStatusEffect:
	ld a, ATK_ANIM_HEAL_BOTH_SIDES
	ld [wLoadedAttackAnimation], a
	xor a
	ld [wce7e], a
	ldh a, [hTempPlayAreaLocation_ff9d]
	ld b, a
	ld c, $00
	ldh a, [hWhoseTurn]
	ld h, a
	bank1call PlayAttackAnimation
	call WaitAttackAnimation

	ldh a, [hTemp_ffa0]
	add DUELVARS_ARENA_CARD_FLAGS
	call GetTurnDuelistVariable
	set USED_PKMN_POWER_THIS_TURN_F, [hl]
	ld l, DUELVARS_ARENA_CARD_STATUS
	ld [hl], NO_STATUS

	ld a, DUELVARS_ARENA_CARD_STATUS
	call GetNonTurnDuelistVariable
	ld [hl], NO_STATUS
	bank1call DrawDuelHUDs
	ret

; returns carry if the power was already used,
; or if the power can't be used due to a special condition or Muk's Toxic Gas
; or if there are no damage counters to remove
HealCheck:
	call OncePerTurnPokePowerCheck
	ret c
	jp YourPokemon_DamageCheck

Heal_RemoveDamageEffect:
	ldtx de, IfHeadsHealIsSuccessfulText
	call TossCoin_BankB
	ldh [hAIPkmnPowerEffectParam], a
	jr nc, .done

	ld a, DUELVARS_DUELIST_TYPE
	call GetTurnDuelistVariable
	cp DUELIST_TYPE_LINK_OPP
	jr z, .link_opp
	and DUELIST_TYPE_AI_OPP
	jr nz, .done

; player
	ldtx hl, ChoosePokemonToHealText
	call DrawWideTextBox_WaitForInput
	bank1call HasAlivePokemonInPlayArea
.loop_input
	bank1call OpenPlayAreaScreenForSelection
	jr c, .loop_input ; must choose, B button can't be used to exit
	ldh a, [hTempPlayAreaLocation_ff9d]
	ldh [hPlayAreaEffectTarget], a
	ld e, a
	call GetCardDamageAndMaxHP
	or a
	jr z, .loop_input ; has no damage counters
	ldh a, [hTempPlayAreaLocation_ff9d]
	call SerialSend8Bytes
	jr .done

.link_opp
	call SerialRecv8Bytes
	ldh [hPlayAreaEffectTarget], a
	; fallthrough

.done
; flag the Pokemon Power as being used regardless of coin outcome
	ldh a, [hTemp_ffa0]
	add DUELVARS_ARENA_CARD_FLAGS
	call GetTurnDuelistVariable
	set USED_PKMN_POWER_THIS_TURN_F, [hl]
	ldh a, [hAIPkmnPowerEffectParam]
	or a
	ret z ; return if coin was tails

	ldh a, [hPlayAreaEffectTarget]
	add DUELVARS_ARENA_CARD_HP
	call GetTurnDuelistVariable
	add 10 ; remove 1 damage counter
	ld [hl], a
	ldh a, [hPlayAreaEffectTarget]
	call Func_2c10b
	jp ExchangeRNG

Shift_PlayerSelection:
	ldtx hl, ChoosePokemonToCopyWithShiftText
	ldh a, [hTemp_ffa0]
	or $80
	call HandleColorChangeScreen
	ldh [hAIPkmnPowerEffectParam], a
	ret c ; cancelled

; check whether the selected color is valid
; look in the Turn Duelist's Play Area
	call .CheckColorInPlayArea
	ret nc
	; look in non-Turn Duelist's Play Area
	call SwapTurn
	call .CheckColorInPlayArea
	call SwapTurn
	ret nc
	; not found in either Play Area
	ldtx hl, UnableToSelectText
	call DrawWideTextBox_WaitForInput
	jr Shift_PlayerSelection ; loop back to start

; checks if input color in a exists in the Turn Duelist's Play Area
; returns carry if the input color isn't present
.CheckColorInPlayArea
	ld a, DUELVARS_NUMBER_OF_POKEMON_IN_PLAY_AREA
	call GetTurnDuelistVariable
	ld c, a
	ld b, PLAY_AREA_ARENA
.loop_play_area
	push bc
	ld a, b
	call GetPlayAreaCardColor
	pop bc
	ld hl, hAIPkmnPowerEffectParam
	cp [hl]
	ret z ; found
	inc b
	dec c
	jr nz, .loop_play_area
	; not found
	scf
	ret

Shift_ChangeColorEffect:
	ldh a, [hTemp_ffa0]
	add DUELVARS_ARENA_CARD
	call GetTurnDuelistVariable
	call LoadCardDataToBuffer1_FromDeckIndex

	ldh a, [hTemp_ffa0]
	add DUELVARS_ARENA_CARD_FLAGS
	call GetTurnDuelistVariable
	set USED_PKMN_POWER_THIS_TURN_F, [hl]

	ldh a, [hTemp_ffa0]
	add DUELVARS_ARENA_CARD_CHANGED_TYPE
	ld l, a
	ldh a, [hAIPkmnPowerEffectParam]
	or HAS_CHANGED_COLOR
	ld [hl], a
	call LoadCardNameAndInputColor
	ldtx hl, ChangedTheColorOfText
	jp DrawWideTextBox_WaitForInput

; returns carry if Pokemon Power cannot be used
; or if the Active Pokemon is not Charizard
;EnergyBurnCheck_Unreferenced:
;	call CheckCannotUseDueToStatus
;	ret c
;	ld a, DUELVARS_ARENA_CARD
;	push de
;	call GetTurnDuelistVariable
;	call GetCardIDFromDeckIndex
;	ld a, e
;	pop de
;	cp CHARIZARD
;	jp nz, SetCarryEF
;	or a
;	ret

Firegiver_AddToHandEffect:
; fill wDuelTempList with all Fire Energy card deck indices
	ld a, DUELVARS_CARD_LOCATIONS
	call GetTurnDuelistVariable
	ld de, wDuelTempList
	ld c, 0
.loop_cards
	ld a, [hl]
	cp CARD_LOCATION_DECK
	jr nz, .next
	push hl
	push de
	ld a, l
	call GetCardIDFromDeckIndex
	call GetCardType
	pop de
	pop hl
	cp TYPE_ENERGY_FIRE
	jr nz, .next
	ld a, l
	ld [de], a
	inc de
	inc c
.next
	inc l
	ld a, l
	cp DECK_SIZE
	jr c, .loop_cards
	ld a, $ff
	ld [de], a

; check how many were found
	ld a, c
	or a
	jr nz, .found
	; return if none found
	ldtx hl, ThereWasNoFireEnergyText
	call DrawWideTextBox_WaitForInput
	jp ShuffleCardsInDeck

.found
; pick a random number between 1 and 4,
; up to the maximum number of Fire Energy
; cards that were found.
	ld a, 4
	call Random
	inc a
	cp c
	jr c, .ok
	ld a, c

.ok
	ldh [hCurSelectionItem], a
; load the correct attack animation, depending on who the Turn Duelist is
	ld d, ATK_ANIM_FIREGIVER_PLAYER
	ld a, [wDuelistType]
	cp DUELIST_TYPE_PLAYER
	jr z, .player_1
; opponent
	ld d, ATK_ANIM_FIREGIVER_OPP
.player_1
	ld a, d
	ld [wLoadedAttackAnimation], a

; start loop for adding Energy cards to hand
	ldh a, [hCurSelectionItem]
	ld c, a
	ld hl, wDuelTempList
.loop_energy
	push hl
	push bc
	lb bc, PLAY_AREA_ARENA, $0
	ldh a, [hWhoseTurn]
	ld h, a
	bank1call PlayAttackAnimation
	call WaitAttackAnimation

; load correct coordinates to update the number of cards
; in hand and deck during animation.
	lb bc, 18, 7 ; x, y for hand number
	ld e, 3 ; y for deck number
	ld a, [wLoadedAttackAnimation]
	cp ATK_ANIM_FIREGIVER_PLAYER
	jr z, .player_2
	lb bc, 4, 5 ; x, y for hand number
	ld e, 10 ; y for deck number

.player_2
; update and print the number of cards in the hand
	ld a, DUELVARS_NUMBER_OF_CARDS_IN_HAND
	call GetTurnDuelistVariable
	inc a
	bank1call WriteTwoDigitNumberInTxSymbolFormat
; update and print the number of cards in the deck
	ld a, DUELVARS_NUMBER_OF_CARDS_NOT_IN_DECK
	call GetTurnDuelistVariable
	ld a, DECK_SIZE - 1
	sub [hl]
	ld c, e
	bank1call WriteTwoDigitNumberInTxSymbolFormat
	pop bc
	pop hl

; load Fire Energy card index and add to hand
	ld a, [hli]
	call SearchCardInDeckAndAddToHand
	call AddCardToHand
	dec c
	jr nz, .loop_energy

; load the number of cards added to hand and print text
	ldh a, [hCurSelectionItem]
	ld l, a
	ld h, $00
	call LoadTxRam3
	ldtx hl, DrewFireEnergyFromTheHandText
	call DrawWideTextBox_WaitForInput
	jp ShuffleCardsInDeck

; returns carry if Cowardice can't be used 
CowardiceCheck:
	ldh a, [hTempPlayAreaLocation_ff9d]
	ldh [hTemp_ffa0], a
	call CheckCannotUseDueToStatus_OnlyToxicGasIfANon0
	ret c ; return if there's a special condition or Muk

	ld a, DUELVARS_NUMBER_OF_POKEMON_IN_PLAY_AREA
	call GetTurnDuelistVariable
	ldtx hl, YouNoBenchedPokemonText
	cp 2
	ret c ; return if there are no Benched Pokemon

	ldh a, [hTempPlayAreaLocation_ff9d]
	add DUELVARS_ARENA_CARD_FLAGS
	call GetTurnDuelistVariable
	ldtx hl, CannotBeUsedInTurnWhichWasPlayedText
	and CAN_EVOLVE_THIS_TURN
	scf
	ret z ; return if card was played this turn

	or a
	ret

Cowardice_PlayerSelection:
	ldh a, [hTemp_ffa0]
	or a
	ret nz ; return if not the Active Pokemon
	ldtx hl, SelectNewActivePokemonText
	call DrawWideTextBox_WaitForInput
	bank1call HasAlivePokemonInBench
	bank1call OpenPlayAreaScreenForSelection
	ldh a, [hTempPlayAreaLocation_ff9d]
	ldh [hAIPkmnPowerEffectParam], a
	ret

Cowardice_RemoveFromPlayAreaEffect:
	ldh a, [hTemp_ffa0]
	add DUELVARS_ARENA_CARD
	call GetTurnDuelistVariable

; temporarily put card in the discard pile,
; so that all attached cards are discarded as well.
	push af
	ldh a, [hTemp_ffa0]
	ld e, a
	call MovePlayAreaCardToDiscardPile

; if it was the Active Pokemon, move selected
; Benched Pokemon to the Arena, otherwise skip.
	ldh a, [hTemp_ffa0]
	or a
	jr nz, .skip_switch
	ldh a, [hAIPkmnPowerEffectParam]
	ld e, a
	call SwapArenaWithBenchPokemon

.skip_switch
; return card to the hand and adjust the Play Area
	pop af
	call MoveDiscardPileCardToHand
	call AddCardToHand
	call ShiftAllPokemonToFirstPlayAreaSlots

	xor a
	ld [wDuelDisplayedScreen], a
	ret

Quickfreeze_Paralysis50PercentEffect:
	ldtx de, ParalysisCheckText
	call TossCoin_BankB
	jr c, .heads

; tails
	call SetWasUnsuccessful
	bank1call DrawDuelMainScene
	call PrintFailedEffectText
	jp WaitForWideTextBoxInput

.heads
	call ParalysisEffect
	ldh a, [hTempPlayAreaLocation_ff9d]
	ld b, a
	ld c, $00
	ldh a, [hWhoseTurn]
	ld h, a
	bank1call PlayAttackAnimation
	bank1call PlayStatusConditionQueueAnimations
	call WaitAttackAnimation
	bank1call ApplyStatusConditionQueue
	bank1call DrawDuelHUDs
	call PrintFailedEffectText
	call c, WaitForWideTextBoxInput
	ret

PealOfThunder_RandomlyDamageEffect:
	call ExchangeRNG
	ld de, 30 ; damage to inflict
	call RandomlyDamagePlayAreaPokemon
	bank1call Func_6e49
	ret

Peek_SelectEffect:
; set Pokemon Power used flag
	ldh a, [hTemp_ffa0]
	add DUELVARS_ARENA_CARD_FLAGS
	call GetTurnDuelistVariable
	set USED_PKMN_POWER_THIS_TURN_F, [hl]

	ld a, DUELVARS_DUELIST_TYPE
	call GetTurnDuelistVariable
	cp DUELIST_TYPE_LINK_OPP
	jr z, .link_opp
	and DUELIST_TYPE_AI_OPP
	jr nz, .ai_opp

; player
	call FinishQueuedAnimations
	call HandlePeekSelection
	ldh [hAIPkmnPowerEffectParam], a
	call SerialSend8Bytes
	ret

.link_opp
	call SerialRecv8Bytes
	ldh [hAIPkmnPowerEffectParam], a

.ai_opp
	ldh a, [hAIPkmnPowerEffectParam]
	bit AI_PEEK_TARGET_HAND_F, a
	jr z, .prize_or_deck
	and (~AI_PEEK_TARGET_HAND & $ff) ; unset bit to get deck index
; if masked value is higher than $40, then it means
; that AI chose to look at Player's deck.
; all deck indices will be smaller than $40.
	cp $40
	jr c, .hand
	ldh a, [hAIPkmnPowerEffectParam]

.prize_or_deck
; AI chose either a prize card or the top card of the Player's deck,
; so show the Play Area and draw the cursor in the right location.
	call FinishQueuedAnimations
	call SwapTurn
	ldh a, [hAIPkmnPowerEffectParam]
	xor $80
	call DrawAIPeekScreen
	call SwapTurn
	ldtx hl, CardPeekWasUsedOnText
	jp DrawWideTextBox_WaitForInput

.hand
; AI chose to look at a random card in the hand,
; so display it to the Player on screen.
	call SwapTurn
	ldtx hl, PeekWasUsedToLookInYourHandText
	bank1call DisplayCardDetailScreen
	jp SwapTurn

; returns carry if Damage Swap cannot be used.
DamageSwapCheck:
	ldh a, [hTempPlayAreaLocation_ff9d]
	ldh [hTemp_ffa0], a
	call YourPokemon_DamageCheck
	ret c
	ldh a, [hTempPlayAreaLocation_ff9d]
	jp CheckCannotUseDueToStatus_OnlyToxicGasIfANon0

DamageSwap_SelectAndSwapEffect:
	ld a, DUELVARS_DUELIST_TYPE
	call GetTurnDuelistVariable
	cp DUELIST_TYPE_PLAYER
	jr z, .player
; not the Player
	call Func_61a1
	bank1call PrintPlayAreaCardList_EnableLCD
	ret

.player
	ldtx hl, ProcedureForDamageSwapText
	bank1call DrawWholeScreenTextBox
	xor a
	ldh [hCurSelectionItem], a
	call Func_61a1

.start
	bank1call PrintPlayAreaCardList_EnableLCD
	push af
	ldh a, [hCurSelectionItem]
	ld hl, PlayAreaSelectionMenuParameters
	call InitializeMenuParameters
	pop af
	ld [wNumMenuItems], a

; handle selection of Pokemon to take damage from
.loop_input_first
	call DoFrame
	call HandleMenuInput
	jr nc, .loop_input_first
	cp $ff
	ret z ; quit when B button is pressed

	ldh [hTempPlayAreaLocation_ffa1], a
	ldh [hCurSelectionItem], a

; if a card has no damage, play sfx and return to start
	call GetCardDamageAndMaxHP
	or a
	jr z, .no_damage

; take damage away temporarily to draw UI.
	ldh a, [hTempPlayAreaLocation_ffa1]
	add DUELVARS_ARENA_CARD_HP
	call GetTurnDuelistVariable
	push af
	push hl
	add 10
	ld [hl], a
	bank1call PrintPlayAreaCardList_EnableLCD
	pop hl
	pop af
	ld [hl], a

; draw damage counter in cursor
	ldh a, [hTempPlayAreaLocation_ffa1]
	ld b, SYM_DAMAGE_COUNTER
	call DrawSymbolOnPlayAreaCursor

; handle selection of Pokemon to give damage to
.loop_input_second
	call DoFrame
	call HandleMenuInput
	jr nc, .loop_input_second
	; if B is pressed, return damage counter
	; to card that it was taken from
	cp $ff
	jr z, .update_ui

; try to give the selected Pokemon the damage counter
; if it would KO the Pokemon, then ignore it.
	ldh [hPlayAreaEffectTarget], a
	ldh [hCurSelectionItem], a
	ldh a, [hPlayAreaEffectTarget]
	call TryGiveDamageCounter
	jr c, .loop_input_second

	ld a, OPPACTION_6B15
	call SetOppAction_SerialSendDuelData

.update_ui
	ldh a, [hTempPlayAreaLocation_ffa1]
	ld b, SYM_SPACE
	call DrawSymbolOnPlayAreaCursor
	call EraseCursor
	jr .start

.no_damage
	call PlaySFX_InvalidChoice
	jr .loop_input_first

; tries to give the damage counter to hPlayAreaEffectTarget,
; and if successful updates UI screen.
DamageSwap_SwapEffect:
	ldh a, [hPlayAreaEffectTarget]
	call TryGiveDamageCounter
	ret c
	bank1call PrintPlayAreaCardList_EnableLCD
	or a
	ret

; tries to give the damage counter to the target
; chosen by the Player (hPlayAreaEffectTarget or hTemp_ffa0).
; returns carry if the damage counter would KO the Pokemon
TryGiveDamageCounter:
	add DUELVARS_ARENA_CARD_HP
	call GetTurnDuelistVariable
	sub 10
	jp z, SetCarryEF ; would bring HP to zero?
; has enough HP to receive a damage counter
	ld [hl], a
	ldh a, [hTempPlayAreaLocation_ffa1]
	add DUELVARS_ARENA_CARD_HP
	ld l, a
	ld a, 10
	add [hl]
	ld [hl], a
	or a
	ret

; returns carry if Strange Behavior cannot be used.
StrangeBehaviorCheck:
; does Play Area have any damage counters?
	ldh a, [hTempPlayAreaLocation_ff9d]
	ldh [hTemp_ffa0], a
	call YourPokemon_DamageCheck
	ret c
; can Slowbro receive any damage counters without KO-ing?
	ldh a, [hTempPlayAreaLocation_ff9d]
	add DUELVARS_ARENA_CARD_HP
	call GetTurnDuelistVariable
	ldtx hl, CannotUseBecauseItWillBeKnockedOutText
	cp 10 + 10
	ret c
; can Pokemon Power be used?
	ldh a, [hTempPlayAreaLocation_ff9d]
	jp CheckCannotUseDueToStatus_OnlyToxicGasIfANon0

StrangeBehavior_SelectAndSwapEffect:
	ld a, DUELVARS_DUELIST_TYPE
	call GetTurnDuelistVariable
	cp DUELIST_TYPE_PLAYER
	jr z, .player

; not the Player
	call Func_61a1
	bank1call PrintPlayAreaCardList_EnableLCD
	ret

.player
	ldtx hl, ProcedureForStrangeBehaviorText
	bank1call DrawWholeScreenTextBox

	xor a
	ldh [hCurSelectionItem], a
	call Func_61a1
.start
	bank1call PrintPlayAreaCardList_EnableLCD
	push af
	ldh a, [hCurSelectionItem]
	ld hl, PlayAreaSelectionMenuParameters
	call InitializeMenuParameters
	pop af

	ld [wNumMenuItems], a
.loop_input
	call DoFrame
	call HandleMenuInput
	jr nc, .loop_input
	cp -1
	ret z ; return when B button is pressed

	ldh [hCurSelectionItem], a
	ldh [hTempPlayAreaLocation_ffa1], a
	ld hl, hTemp_ffa0
	cp [hl]
	jr z, .play_sfx ; can't select Slowbro itself

	call GetCardDamageAndMaxHP
	or a
	jr z, .play_sfx ; can't select a Pokemon without damage

	ldh a, [hTemp_ffa0]
	call TryGiveDamageCounter
	jr c, .play_sfx
	ld a, OPPACTION_6B15
	call SetOppAction_SerialSendDuelData
	jr .start

.play_sfx
	call PlaySFX_InvalidChoice
	jr .loop_input

StrangeBehavior_SwapEffect:
	ldh a, [hTemp_ffa0]
	call TryGiveDamageCounter
	ret c
	bank1call PrintPlayAreaCardList_EnableLCD
	or a
	ret

; returns carry if Pokemon Power cannot be used
; and sets the correct text in hl for failure.
CurseCheck:
	call OncePerTurnPokePowerCheck
	ret c
	; returns carry if the opponent only has 1 Pokemon
	ld a, DUELVARS_NUMBER_OF_POKEMON_IN_PLAY_AREA
	call GetNonTurnDuelistVariable
	ldtx hl, CannotUseSinceTheresOnly1PkmnText
	cp 2
	ret c
	; returns carry if none of the opponent's Pokemon have any damage counters
	call SwapTurn
	call YourPokemon_DamageCheck
	jp SwapTurn

Curse_PlayerSelection:
	ldtx hl, ProcedureForCurseText
	bank1call DrawWholeScreenTextBox
	call SwapTurn
	xor a
	ldh [hCurSelectionItem], a
	call Func_61a1
.start
	bank1call PrintPlayAreaCardList_EnableLCD
	push af
	ldh a, [hCurSelectionItem]
	ld hl, PlayAreaSelectionMenuParameters
	call InitializeMenuParameters
	pop af
	ld [wNumMenuItems], a

; first pick a target to take 1 damage counter from.
.loop_input_first
	call DoFrame
	call HandleMenuInput
	jr nc, .loop_input_first
	cp $ff
	jr z, .cancel
	ldh [hCurSelectionItem], a
	ldh [hTempPlayAreaLocation_ffa1], a
	call GetCardDamageAndMaxHP
	or a
	jr nz, .picked_first ; test if has damage
	; play sfx
	call PlaySFX_InvalidChoice
	jr .loop_input_first

.picked_first
; give 10 HP to the selected Pokemon, draw the scene,
; then immediately revert this.
	ldh a, [hTempPlayAreaLocation_ffa1]
	add DUELVARS_ARENA_CARD_HP
	call GetTurnDuelistVariable
	push af
	push hl
	add 10
	ld [hl], a
	bank1call PrintPlayAreaCardList_EnableLCD
	pop hl
	pop af
	ld [hl], a

; draw damage counter on cursor
	ldh a, [hTempPlayAreaLocation_ffa1]
	ld b, SYM_DAMAGE_COUNTER
	call DrawSymbolOnPlayAreaCursor

; handle input to pick the target to receive the damage counter.
.loop_input_second
	call DoFrame
	call HandleMenuInput
	jr nc, .loop_input_second
	ldh [hPlayAreaEffectTarget], a
	cp $ff
	jr nz, .a_press ; was a pressed?

; pressing the B button erases the damage counter symbol
; and loops back to the beginning.
	ldh a, [hTempPlayAreaLocation_ffa1]
	ld b, SYM_SPACE
	call DrawSymbolOnPlayAreaCursor
	call EraseCursor
	jr .start

.a_press
	ld hl, hTempPlayAreaLocation_ffa1
	cp [hl]
	jr z, .loop_input_second ; same as first?
; a different Pokemon was picked,
; so store this Play Area location
; and erase the damage counter in the cursor.
	ldh a, [hTempPlayAreaLocation_ffa1]
	ld b, SYM_SPACE
	call DrawSymbolOnPlayAreaCursor
	call EraseCursor
	call SwapTurn
	or a
	ret

; returns carry if the operation was cancelled
.cancel
	call SwapTurn
	scf
	ret

Curse_TransferDamageEffect:
; set Pokemon Power as used
	ldh a, [hTempList]
	add DUELVARS_ARENA_CARD_FLAGS
	call GetTurnDuelistVariable
	set USED_PKMN_POWER_THIS_TURN_F, [hl]

; figure out the type of duelist that used Curse.
; if it was the player, no need to draw the Play Area screen.
	call SwapTurn
	ld a, DUELVARS_DUELIST_TYPE
	call GetNonTurnDuelistVariable
	cp DUELIST_TYPE_PLAYER
	jr z, .vs_player

; vs. opponent
	call Func_61a1
.vs_player
; transfer the damage counter to the targets that were selected.
	ldh a, [hPlayAreaEffectTarget]
	add DUELVARS_ARENA_CARD_HP
	call GetTurnDuelistVariable
	sub 10
	ld [hl], a
	ldh a, [hTempPlayAreaLocation_ffa1]
	add DUELVARS_ARENA_CARD_HP
	ld l, a
	ld a, 10
	add [hl]
	ld [hl], a

	bank1call PrintPlayAreaCardList_EnableLCD
	ld a, DUELVARS_DUELIST_TYPE
	call GetNonTurnDuelistVariable
	cp DUELIST_TYPE_PLAYER
	jr z, .done
; vs. opponent
	ldh a, [hPlayAreaEffectTarget]
	ldh [hTempPlayAreaLocation_ff9d], a
	bank1call Func_6194

.done
	call SwapTurn
	call ExchangeRNG
	bank1call Func_6e49
	ret

; returns carry if power cannot be used
StepInCheck:
; first check if this Pokemon is on the Bench
	ldh a, [hTempPlayAreaLocation_ff9d]
	ldh [hTemp_ffa0], a
	ldtx hl, CanOnlyBeUsedOnTheBenchText
	or a
	jp z, SetCarryEF
	jp OncePerTurnPokePowerCheck

StepIn_SwitchEffect:
	ldh a, [hTemp_ffa0]
	ld e, a
	call SwapArenaWithBenchPokemon
	ld a, DUELVARS_ARENA_CARD_FLAGS
	call GetTurnDuelistVariable
	set USED_PKMN_POWER_THIS_TURN_F, [hl]
	ret

HealingWind_PlayAreaHealEffect:
; play initial animation
	ldh a, [hTempPlayAreaLocation_ff9d]
	ld b, a
	ld c, $00
	ldh a, [hWhoseTurn]
	ld h, a
	bank1call PlayAttackAnimation
	call WaitAttackAnimation
	ld a, ATK_ANIM_HEALING_WIND_PLAY_AREA
	ld [wLoadedAttackAnimation], a

	ld a, DUELVARS_NUMBER_OF_POKEMON_IN_PLAY_AREA
	call GetTurnDuelistVariable
	ld d, a
	ld e, PLAY_AREA_ARENA
.loop_play_area
	push de
	ld a, e
	ldh [hTempPlayAreaLocation_ff9d], a
	call GetCardDamageAndMaxHP
	or a
	jr z, .next_pkmn ; skip if no damage

; if less than 20 damage, cap recovery at 10 damage
	ld de, 20
	cp e
	jr nc, .heal
	ld e, a

.heal
; add HP to this card
	ldh a, [hTempPlayAreaLocation_ff9d]
	add DUELVARS_ARENA_CARD_HP
	call GetTurnDuelistVariable
	add e
	ld [hl], a

; play heal animation
	ldh a, [hTempPlayAreaLocation_ff9d]
	ld b, a
	ld c, $01
	ldh a, [hWhoseTurn]
	ld h, a
	bank1call PlayAttackAnimation
	call WaitAttackAnimation
.next_pkmn
	pop de
	inc e
	dec d
	jr nz, .loop_play_area
	ret


;---------------------------------------------------------------------------------
; (15) TRAINER CARD EFFECTS ARE NEXT.
; (Bill/Energy Search/Gust of Wind/Pokedex are sorted with attacks effects)
;---------------------------------------------------------------------------------

; handles screen for the Player to select 2 cards from the hand to discard.
; first prints text informing the Player to choose cards to discard
; then runs the HandlePlayerSelection2HandCards routine.
Discard2Cards_PlayerSelection:
	ldtx hl, Choose2CardsFromHandToDiscardText
	ldtx de, ChooseTheCardToDiscardText
;	fallthrough

; handles the screen for the Player to select 2 cards from the hand
; this is an activation cost for several Trainer card effects.
; assumes the Trainer card index being used is in [hTempCardIndex_ff9f].
; stores selection of cards in hTempList.
; returns carry if Player cancels operation.
; input:
;	hl = text to print in text box;
;	de = text to print in screen header.
HandlePlayerSelection2HandCards:
	push de
	call DrawWideTextBox_WaitForInput

; remove the card being used from the list of cards to select from hand.
	call CreateHandCardList
	ldh a, [hTempCardIndex_ff9f]
	call RemoveCardFromDuelTempList

	xor a
	ldh [hCurSelectionItem], a
	pop hl
.loop
	push hl
	bank1call Func_5591
	pop hl
	call SetCardListInfoBoxText
	push hl
	bank1call DisplayCardList
	pop hl
	ret c ; was B pressed?
	push hl
	call GetNextPositionInTempList
	ldh a, [hTempCardIndex_ff98]
	ld [hl], a
	call RemoveCardFromDuelTempList
	pop hl
	ldh a, [hCurSelectionItem]
	cp 2
	jr c, .loop ; is selection over?
	or a
	ret

PlayThisAsBasicPokemonEffect:
	ldh a, [hTempCardIndex_ff9f]
	jp PutHandPokemonCardInPlayArea

TrainerCardAsPokemon_PlayerSelectSwitch:
	ldh a, [hTemp_ffa0]
	or a
	ret nz ; no need to switch if it's not the Active Pokemon

	ldtx hl, SelectNewActivePokemonText
	call DrawWideTextBox_WaitForInput
	bank1call HasAlivePokemonInBench
	bank1call OpenPlayAreaScreenForSelection
	ldh a, [hTempPlayAreaLocation_ff9d]
	ldh [hTempPlayAreaLocation_ffa1], a
	ret

TrainerCardAsPokemon_DiscardEffect:
	ldh a, [hTemp_ffa0]
	ld e, a
	call MovePlayAreaCardToDiscardPile
	ldh a, [hTemp_ffa0]
	or a
	jp nz, ShiftAllPokemonToFirstPlayAreaSlots
	ldh a, [hTempPlayAreaLocation_ffa1]
	ld e, a
	call SwapArenaWithBenchPokemon
	jp ShiftAllPokemonToFirstPlayAreaSlots

; returns carry if there aren't enough cards in the hand to discard
; or if there are no cards left in the deck.
ComputerSearchCheck:
	call OtherCardsInHandCheck
	ret c
	jp DeckCheck

ComputerSearch_PlayerDeckSelection:
	call CreateDeckCardList
	bank1call Func_5591
	ldtx hl, ChooseCardToPlaceInHandText
	ldtx de, DuelistDeckText
	call SetCardListHeaderText
.loop_input
	bank1call DisplayCardList
	jr c, .loop_input ; must choose, B button can't be used to exit
	ldh [hTempList + 2], a
	ret

ComputerSearch_DiscardAddToHandEffect:
; discard 2 cards from the hand
	ld hl, hTempList
	ld a, [hli]
	call RemoveCardFromHand
	call PutCardInDiscardPile
	ld a, [hli]
	call RemoveCardFromHand
	call PutCardInDiscardPile

; add a card from the deck to the hand
	ld a, [hl]
	call SearchCardInDeckAndAddToHand
	call AddCardToHand
	jp ShuffleCardsInDeck

Defender_PlayerSelection:
	ldtx hl, ChoosePokemonToAttachDefenderToText
	call DrawWideTextBox_WaitForInput
	bank1call HasAlivePokemonInPlayArea
	bank1call OpenPlayAreaScreenForSelection
	ldh a, [hTempPlayAreaLocation_ff9d]
	ldh [hTemp_ffa0], a
	ret

Defender_AttachDefenderEffect:
; attach the Trainer card to the in-play Pokemon
	ldh a, [hTemp_ffa0]
	ld e, a
	ldh a, [hTempCardIndex_ff9f]
	call PutHandCardInPlayArea

; increase number of Defender cards in this location by 1
	ldh a, [hTemp_ffa0]
	add DUELVARS_ARENA_CARD_ATTACHED_DEFENDER
	call GetTurnDuelistVariable
	inc [hl]
	call IsPlayerTurn
	ret c

	ldh a, [hTemp_ffa0]
	jp Func_2c10b

DevolutionSpray_PlayerSelection:
; display textbox
	ldtx hl, ChooseEvolutionCardAndPressAButtonToDevolveText
	call DrawWideTextBox_WaitForInput

; have Player select an an Evolved Pokemon in the Play Area
	ld a, 1
	ldh [hCurSelectionItem], a
	bank1call HasAlivePokemonInPlayArea
.read_input
	bank1call OpenPlayAreaScreenForSelection
	ret c ; exit if the B button was pressed
	bank1call GetCardOneStageBelow
	jr c, .read_input ; can't select Basic cards

; get pre-evolution card data
	ldh a, [hTempPlayAreaLocation_ff9d]
	add DUELVARS_ARENA_CARD_HP
	call GetTurnDuelistVariable
	push hl
	push af
	ldh a, [hTempPlayAreaLocation_ff9d]
	add DUELVARS_ARENA_CARD_STAGE
	ld l, a
	ld a, [hl]
	push hl
	push af
	ldh a, [hTempPlayAreaLocation_ff9d]
	add DUELVARS_ARENA_CARD
	ld l, a
	ld a, [hl]
	push hl
	push af
	jr .update_data

.repeat_devolution
; show the Play Area screen with a static cursor
; so that the Player either presses A to do one more devolution
; or presses B to finish selecting.
	bank1call Func_6194
	jr c, .done_selection ; end selection if B button was pressed
	; do one more devolution
	bank1call GetCardOneStageBelow

.update_data
; overwrite the card data to the newly devolved stats
	ld a, d
	call UpdateDevolvedCardHPAndStage
	call GetNextPositionInTempList
	ld [hl], e
	ld a, d
	call LoadCardDataToBuffer2_FromDeckIndex
	ld a, [wLoadedCard2Stage]
	or a
	jr nz, .repeat_devolution ; can do one more devolution

.done_selection
	call GetNextPositionInTempList
	ld [hl], $ff ; terminating byte

; store this Play Area location in the first item of temp list
	ldh a, [hTempPlayAreaLocation_ff9d]
	ldh [hTempList], a

; update the Play Area location display of this Pokemon
	call EmptyScreen
	ldh a, [hTempPlayAreaLocation_ff9d]
	ld hl, wHUDEnergyAndHPBarsX
	ld [hli], a
	ld [hl], $00
	bank1call PrintPlayAreaCardInformationAndLocation
	call EnableLCD
	pop bc
	pop hl

; rewrite all duelvars from before the selection was done
; this is so that if "No" is selected in the confirmation menu,
; then the Pokemon isn't devolved and remains unchanged.
	ld [hl], b
	ldtx hl, IsThisOKText
	call YesOrNoMenuWithText
	pop bc
	pop hl

	ld [hl], b
	pop bc
	pop hl

	ld [hl], b
	ret

DevolutionSpray_DevolutionEffect:
; first byte in list is the chosen Play Area location
	ld hl, hTempList
	ld a, [hli]
	ldh [hTempPlayAreaLocation_ff9d], a
	add DUELVARS_ARENA_CARD
	call GetTurnDuelistVariable
	push hl
	push af

; loop through devolutions selected
	ld hl, hTempList + 1
.loop_devolutions
	ld a, [hl]
	cp $ff
	jr z, .check_ko ; list is over
	; devolve card to its previous stage
	push hl
	bank1call GetCardOneStageBelow
	ld a, d
	call UpdateDevolvedCardHPAndStage
	call ResetDevolvedCardStatus
	pop hl
	ld a, [hli]
	call PutCardInDiscardPile
	jr .loop_devolutions

.check_ko
	pop af
	ld e, a
	pop hl
	ld d, [hl]
	call PrintDevolvedCardNameAndLevelText
	ldh a, [hTempList]
	call PrintPlayAreaCardKnockedOutIfNoHP
	bank1call Func_6e49
	ret

; returns carry if either player doesn't have any attached Energy cards
SuperEnergyRemoval_EnergyCheck:
	call YourPokemon_AttachedEnergyCheck
	ldtx hl, NoEnergyCardsAttachedToPokemonInYourPlayAreaText
	ret c
;	fallthrough

; returns carry if the opponent has no Energy cards
; attached to any of their in-play Pokemon
EnergyRemovalCheck:
	call SwapTurn
	call YourPokemon_AttachedEnergyCheck
	ldtx hl, NoEnergyCardsAttachedToPokemonInOppPlayAreaText
	jp SwapTurn

EnergyRemoval_PlayerSelection:
	ldtx hl, ChoosePokemonToRemoveEnergyFromText
	call DrawWideTextBox_WaitForInput
	call SwapTurn
	call HandlePokemonAndEnergySelectionScreen
	jp SwapTurn

; returns in a the card index of the Energy card
; that is to be discarded by the AI (only looks at the Defending Pokemon)
; outputs $ff is none was found.
; output:
;	a = deck index of attached energy card chosen
EnergyRemoval_AISelection:
	call SwapTurn
	ld e, PLAY_AREA_ARENA
	call GetPlayAreaCardAttachedEnergies

	xor a
	call CreateArenaOrBenchEnergyCardList
	jr nc, .has_energy
	; no energy, so return
	ld a, $ff
	jp SwapTurn ; done

.has_energy
	ld a, DUELVARS_ARENA_CARD
	call GetTurnDuelistVariable
	call LoadCardDataToBuffer1_FromDeckIndex
	ld e, COLORLESS
	ld a, [wAttachedEnergies + COLORLESS]
	or a
	jr nz, .pick_color ; choose a Double Colorless Energy

	; no Colorless Energy are attached to the Defending Pokemon.
	; if the Defending Pokemon is Colorless, just pick a random Energy card.
	ld a, [wLoadedCard1Type]
	cp COLORLESS
	jr nc, .choose_random

	; check if there's an attached Energy card
	; that is the same color as the Defending Pokemon
	; if not, just pick a random Energy card.
	ld e, a
	ld d, $00
	ld hl, wAttachedEnergies
	add hl, de
	ld a, [hl]
	or a
	jr z, .choose_random

; choose an attached Energy card with the same color as e
.pick_color
	ld hl, wDuelTempList
.loop_energy
	ld a, [hli]
	cp $ff
	jr z, .choose_random
	call LoadCardDataToBuffer2_FromDeckIndex
	ld a, [wLoadedCard2Type]
	and TYPE_PKMN
	cp e
	jr nz, .loop_energy
	dec hl

.done_chosen
	ld a, [hl]
	jp SwapTurn

.choose_random
	call CountCardsInDuelTempList
	ld hl, wDuelTempList
	call ShuffleCards
	jr .done_chosen

EnergyRemoval_DiscardEffect:
	call SwapTurn
	ldh a, [hTempPlayAreaLocation_ffa1]
	call PutCardInDiscardPile
	call SwapTurn
	call IsPlayerTurn
	ret c

; show Player which Pokemon was affected
	call SwapTurn
	ldh a, [hTemp_ffa0]
	call Func_2c10b
	jp SwapTurn

; handles Player selection for Pokemon in the Play Area,
; then opens a screen to choose one of the Energy cards
; attached to the selected Pokemon.
; outputs the selection in:
;	[hTemp_ffa0] = play area location
;	[hTempPlayAreaLocation_ffa1] = index of energy card
HandlePokemonAndEnergySelectionScreen:
	bank1call HasAlivePokemonInPlayArea
	bank1call OpenPlayAreaScreenForSelection
	ret c ; exit if the B button was pressed
	ld e, a
	call GetPlayAreaCardAttachedEnergies
	ld a, [wTotalAttachedEnergies]
	or a
	jr nz, .has_energy
	ldtx hl, NoEnergyCardsAttachedText
	call DrawWideTextBox_WaitForInput
	jr HandlePokemonAndEnergySelectionScreen ; loop back to start

.has_energy
	ldh a, [hCurMenuItem]
	call CreateArenaOrBenchEnergyCardList
	ldh a, [hCurMenuItem]
	bank1call DisplayEnergyDiscardScreen
	bank1call HandleEnergyDiscardMenuInput
	ldh a, [hTempPlayAreaLocation_ff9d]
	ldh [hTemp_ffa0], a
	ldh a, [hTempCardIndex_ff98]
	ldh [hTempPlayAreaLocation_ffa1], a
	ret

SuperEnergyRemoval_PlayerSelection:
; handle selection of Energy to discard in own Play Area
	ldtx hl, ChoosePokemonInYourAreaThenPokemonInYourOppText
	call DrawWideTextBox_WaitForInput
	call HandlePokemonAndEnergySelectionScreen
	ret c ; return if operation was cancelled

	ldtx hl, ChoosePokemonToRemoveEnergyFromText
	call DrawWideTextBox_WaitForInput

	call SwapTurn
	ld a, 3
	ldh [hCurSelectionItem], a
.select_opp_pkmn
	bank1call HasAlivePokemonInPlayArea
	bank1call OpenPlayAreaScreenForSelection
	jp c, SwapTurn ; exit if the B button was pressed
	ld e, a
	call GetPlayAreaCardAttachedEnergies
	ld a, [wTotalAttachedEnergies]
	or a
	jr nz, .has_energy ; has any energy cards attached?
	; no energy, loop back
	ldtx hl, NoEnergyCardsAttachedText
	call DrawWideTextBox_WaitForInput
	jr .select_opp_pkmn

.has_energy
; store this Pokemon's Play Area location
	ldh a, [hTempPlayAreaLocation_ff9d]
	ldh [hPlayAreaEffectTarget], a
; store which energy card to discard from it
	call CreateArenaOrBenchEnergyCardList
	ldh a, [hTempPlayAreaLocation_ff9d]
	bank1call DisplayEnergyDiscardScreen
	ld a, 2
	ld [wEnergyDiscardMenuDenominator], a

.loop_discard_energy_selection
	bank1call HandleEnergyDiscardMenuInput
	jr nc, .energy_selected
	; B button was pressed
	ld a, 5
	call AskWhetherToQuitSelectingCards
	jr nc, .done ; finish operation
	; player selected to continue selection
	ld a, [wEnergyDiscardMenuNumerator]
	push af
	ldh a, [hTempPlayAreaLocation_ff9d]
	bank1call DisplayEnergyDiscardScreen
	ld a, 2
	ld [wEnergyDiscardMenuDenominator], a
	pop af
	ld [wEnergyDiscardMenuNumerator], a
	jr .loop_discard_energy_selection

.energy_selected
; store Energy cards to discard from the opponent's Pokemon
	call GetNextPositionInTempList
	ldh a, [hTempCardIndex_ff98]
	ld [hl], a
	call RemoveCardFromDuelTempList
	ld hl, wEnergyDiscardMenuNumerator
	inc [hl]
	ldh a, [hCurSelectionItem]
	cp 5
	jr nc, .done ; no more Energy cards to select
	ld a, [wDuelTempList]
	cp $ff
	jr z, .done ; no more Energy cards to select
	bank1call DisplayEnergyDiscardMenu
	jr .loop_discard_energy_selection

.done
	call GetNextPositionInTempList
	ld [hl], $ff
	call SwapTurn
	or a
	ret

SuperEnergyRemoval_DiscardEffect:
	ld hl, hTempList + 1

; discard an Energy card from one of the Turn Duelist's Pokemon
	ld a, [hli]
	call PutCardInDiscardPile

; iterate and discard Energy cards from the opponent's Pokemon
	inc hl
	call SwapTurn
.loop
	ld a, [hli]
	cp $ff
	jr z, .done_discard
	call PutCardInDiscardPile
	jr .loop

.done_discard
	call SwapTurn
	call IsPlayerTurn
	ret c ; return if it's the Player's turn

; otherwise show the affected Pokemon in the opponent's Play Area
	ldh a, [hTemp_ffa0]
	call Func_2c10b
	xor a
	ld [wDuelDisplayedScreen], a
	call SwapTurn
	ldh a, [hPlayAreaEffectTarget]
	call Func_2c10b
	jp SwapTurn

; returns carry if there isn't another card in the hand to discard
; or if there are no Basic Energy cards in the discard pile.
EnergyRetrievalCheck:
	ld a, DUELVARS_NUMBER_OF_CARDS_IN_HAND
	call GetTurnDuelistVariable
	ldtx hl, NotEnoughCardsInHandText
	cp 2
	ret c ; return if this is the only card in the hand
	call CreateEnergyCardListFromDiscardPile_OnlyBasic
	ldtx hl, NoBasicEnergyCardsInDiscardPileText
	ret

EnergyRetrieval_PlayerHandSelection:
	ldtx hl, ChooseCardToDiscardFromHandText
	call DrawWideTextBox_WaitForInput
	call CreateHandCardList
	ldh a, [hTempCardIndex_ff9f]
	call RemoveCardFromDuelTempList
	bank1call Func_5591
	bank1call DisplayCardList
	ldh a, [hTempCardIndex_ff98]
	ldh [hTempList], a
	ret

EnergyRetrieval_PlayerDiscardPileSelection:
	ld a, 1 ; start at 1 to ignore the card being discarded from the hand
	ldh [hCurSelectionItem], a
	ldtx hl, Choose2BasicEnergyCardsFromDiscardPileText
	call DrawWideTextBox_WaitForInput
	call CreateEnergyCardListFromDiscardPile_OnlyBasic

.select_card
	bank1call InitAndDrawCardListScreenLayout
	ldtx hl, PleaseSelectCardText
	ldtx de, YourDiscardPileText
	call SetCardListHeaderText
	bank1call DisplayCardList
	jr nc, .selected
	; B button was pressed
	ld a, 2 + 1 ; includes the card selected from the hand
	call AskWhetherToQuitSelectingCards
	jr c, .select_card ; player selected No
	jr .done

.selected
	call GetNextPositionInTempList
	ldh a, [hTempCardIndex_ff98]
	ld [hl], a
	call RemoveCardFromDuelTempList
	jr c, .done
	ldh a, [hCurSelectionItem]
	cp 2 + 1 ; includes the card selected from the hand
	jr c, .select_card

.done
	call GetNextPositionInTempList
	ld [hl], $ff ; terminating byte
	or a
	ret

EnergyRetrieval_DiscardAndAddToHandEffect:
	ld hl, hTempList
	ld a, [hli]
	call RemoveCardFromHand
	call PutCardInDiscardPile
	ld de, wDuelTempList
.loop
	ld a, [hli]
	ld [de], a
	inc de
	cp $ff
	jr z, .done
	call MoveDiscardPileCardToHand
	call AddCardToHand
	jr .loop
.done
	call IsPlayerTurn
	ret c
	bank1call DisplayCardListDetails
	ret

; returns carry if there aren't enough cards in the hand to discard
; or if the discard pile has no Basic Energy cards
SuperEnergyRetrieval_HandEnergyCheck:
	call OtherCardsInHandCheck
	ret c
	call CreateEnergyCardListFromDiscardPile_OnlyBasic
	ldtx hl, NoBasicEnergyCardsInDiscardPileText
	ret

SuperEnergyRetrieval_PlayerDiscardPileSelection:
	ldtx hl, ChooseUpTo4FromDiscardPileText
	call DrawWideTextBox_WaitForInput
	call CreateEnergyCardListFromDiscardPile_OnlyBasic

.loop_discard_pile_selection
	bank1call InitAndDrawCardListScreenLayout
	ldtx hl, PleaseSelectCardText
	ldtx de, YourDiscardPileText
	call SetCardListHeaderText
	bank1call DisplayCardList
	jr nc, .store_selected_card
	; B button was pressed
	ld a, 6
	call AskWhetherToQuitSelectingCards
	jr c, .loop_discard_pile_selection ; player selected to continue
	jr .done

.store_selected_card
	ldh a, [hTempCardIndex_ff98]
	call GetTurnDuelistVariable
	call GetNextPositionInTempList
	ldh a, [hTempCardIndex_ff98]
	ld [hl], a ; store selected Energy card
	call RemoveCardFromDuelTempList
	jr c, .done
	; this shouldn't happen
	ldh a, [hCurSelectionItem]
	cp 6
	jr c, .loop_discard_pile_selection

.done
; insert terminating byte
	call GetNextPositionInTempList
	ld [hl], $ff
	or a
	ret

SuperEnergyRetrieval_DiscardAndAddToHandEffect:
; discard 2 cards selected from the hand
	ld hl, hTemp_ffa0
	ld a, [hli]
	call RemoveCardFromHand
	call PutCardInDiscardPile
	ld a, [hli]
	call RemoveCardFromHand
	call PutCardInDiscardPile

; put selected cards from the discard pile into the hand
	ld de, wDuelTempList
.loop
	ld a, [hli]
	ld [de], a
	inc de
	cp $ff
	jr z, .done
	call MoveDiscardPileCardToHand
	call AddCardToHand
	jr .loop

.done
; if Player played the card, exit
	call IsPlayerTurn
	ret c
; if not, show the list of selected cards to the opponent
	bank1call DisplayCardListDetails
	ret

GamblerEffect:
	ldtx de, CardCheckIfHeads8CardsIfTails1CardText
	call TossCoin_BankB
	ldh [hTemp_ffa0], a
; discard the card being used from the hand
	ldh a, [hTempCardIndex_ff9f]
	call RemoveCardFromHand
	call PutCardInDiscardPile

; shuffle the hand cards into the deck
	call CreateHandCardList
	call SortCardsInDuelTempListByID
	ld hl, wDuelTempList
.loop_return_deck
	ld a, [hli]
	cp $ff
	jr z, .check_coin_toss
	call RemoveCardFromHand
	call ReturnCardToDeck
	jr .loop_return_deck

.check_coin_toss
	call ShuffleCardsInDeck
	ld c, 8
	ldh a, [hTemp_ffa0]
	or a
	jr nz, .draw_cards ; coin toss was heads?
	; if tails, number of cards to draw is 1
	ld c, 1

; correct number of cards to draw is stored in c
.draw_cards
	ld a, c
	jp DrawNCards_NoCardDetails

ItemFinder_PlayerSelection:
	call Discard2Cards_PlayerSelection
	ret c ; was operation cancelled?

; cards were selected to discard from the hand.
; now to choose a Trainer card from the discard pile.
	call CreateTrainerCardListFromDiscardPile
	bank1call Func_5591
	ldtx hl, ChooseCardToPlaceInHandText
	ldtx de, YourDiscardPileText
	call SetCardListHeaderText
	bank1call DisplayCardList
	ldh [hTempList + 2], a ; placed after the 2 cards selected to discard
	ret

ItemFinder_DiscardAddToHandEffect:
; discard cards from the hand
	ld hl, hTempList
	ld a, [hli]
	call RemoveCardFromHand
	call PutCardInDiscardPile
	ld a, [hli]
	call RemoveCardFromHand
	call PutCardInDiscardPile

; place the card from the discard pile into the hand
	ld a, [hl]
	call MoveDiscardPileCardToHand
	call AddCardToHand
	call IsPlayerTurn
	ret c
; display card on screen
	ldh a, [hTempList + 2]
	ldtx hl, WasPlacedInTheHandText
	bank1call DisplayCardDetailScreen
	ret

ImakuniEffect:
	ld a, DUELVARS_ARENA_CARD
	call GetTurnDuelistVariable
	call LoadCardDataToBuffer1_FromDeckIndex
	ld a, [wLoadedCard1ID]

; cannot confuse Clefairy Doll or Mysterious Fossil
	cp CLEFAIRY_DOLL
	jr z, .failed
	cp MYSTERIOUS_FOSSIL
	jr z, .failed

; cannot confuse Snorlax if its Pokemon Power is active
	cp SNORLAX
	jr nz, .success
	call CheckCannotUseDueToStatus
	jr c, .success
	; fallthrough if Thick Skinned is active

.failed
; play confusion animation and print failure text
	ld a, ATK_ANIM_OWN_CONFUSION
	call PlayTrainerEffectAnimation
	ldtx hl, ThereWasNoEffectText
	jp DrawWideTextBox_WaitForInput

.success
; play confusion animation and confuse card
	ld a, ATK_ANIM_OWN_CONFUSION
	call PlayTrainerEffectAnimation
	ld a, DUELVARS_ARENA_CARD_STATUS
	call GetTurnDuelistVariable
	and PSN_DBLPSN
	or CONFUSED
	ld [hl], a
	bank1call DrawDuelHUDs
	ret

ImposterProfessorOakEffect:
	call SwapTurn
	call CreateHandCardList
	call SortCardsInDuelTempListByID

; first return all cards in the hand to the deck.
	ld hl, wDuelTempList
.loop_return_deck
	ld a, [hli]
	cp $ff
	jr z, .done_return
	call RemoveCardFromHand
	call ReturnCardToDeck
	jr .loop_return_deck

; then draw 7 cards from the deck.
.done_return
	call ShuffleCardsInDeck
	ld a, 7
	call DrawNCards_NoCardDetails
	jp SwapTurn

LassEffect:
; first discard the card that was just used
	ldh a, [hTempCardIndex_ff9f]
	call RemoveCardFromHand
	call PutCardInDiscardPile

	ldtx hl, PleaseCheckTheOpponentsHandText
	call DrawWideTextBox_WaitForInput

	call .DisplayLinkOrCPUHand
	; do for non-Turn Duelist
	call SwapTurn
	call .ShuffleDuelistHandTrainerCardsInDeck
	call SwapTurn
	; do for Turn Duelist, fallthrough

.ShuffleDuelistHandTrainerCardsInDeck
	call CreateHandCardList
	call SortCardsInDuelTempListByID
	xor a
	ldh [hCurSelectionItem], a
	ld hl, wDuelTempList

; go through every card in the hand and any Trainer card is returned to the deck.
.loop_hand
	ld a, [hli]
	ldh [hTempCardIndex_ff98], a
	cp $ff
	jr z, .done
	call GetCardIDFromDeckIndex
	call GetCardType
	cp TYPE_TRAINER
	jr nz, .loop_hand
	ldh a, [hTempCardIndex_ff98]
	call RemoveCardFromHand
	call ReturnCardToDeck
	push hl
	ld hl, hCurSelectionItem
	inc [hl]
	pop hl
	jr .loop_hand
.done
; show card list
	ldh a, [hCurSelectionItem]
	or a
	call nz, ShuffleCardsInDeck ; only shuffle if there were any Trainer cards
	ret

.DisplayLinkOrCPUHand
	ld a, [wDuelType]
	or a
	jr z, .cpu_opp

; link duel
	ldh a, [hWhoseTurn]
	push af
	ld a, OPPONENT_TURN
	ldh [hWhoseTurn], a
	call .DisplayOppHand
	pop af
	ldh [hWhoseTurn], a
	ret

.cpu_opp
	call SwapTurn
	call .DisplayOppHand
	jp SwapTurn

.DisplayOppHand
	call CreateHandCardList
	jr c, .no_cards
	bank1call InitAndDrawCardListScreenLayout
	ldtx hl, ChooseTheCardYouWishToExamineText
	ldtx de, DuelistHandText
	call SetCardListHeaderText
	ld a, A_BUTTON | START
	ld [wNoItemSelectionMenuKeys], a
	bank1call DisplayCardList
	ret
.no_cards
	ldtx hl, DuelistHasNoCardsInHandText
	jp DrawWideTextBox_WaitForInput

Maintenance_PlayerSelection:
	ldtx hl, Choose2HandCardsFromHandToReturnToDeckText
	ldtx de, ChooseTheCardToPutBackText
	jp HandlePlayerSelection2HandCards

Maintenance_ReturnToDeckAndDrawEffect:
; return both selected cards to the deck
	ldh a, [hTempList]
	call RemoveCardFromHand
	call ReturnCardToDeck
	ldh a, [hTempList + 1]
	call RemoveCardFromHand
	call ReturnCardToDeck
	call ShuffleCardsInDeck

; draw one card
	ld a, 1
	bank1call DisplayDrawNCardsScreen
	call DrawCardFromDeck
	ldh [hTempCardIndex_ff98], a
	call AddCardToHand
	call IsPlayerTurn
	ret nc
	; show card on screen if played by Player
	bank1call DisplayPlayerDrawCardScreen
	ret

MrFuji_ReturnToDeckEffect:
; get Play Area location's card index
	ldh a, [hTemp_ffa0]
	add DUELVARS_ARENA_CARD
	call GetTurnDuelistVariable
	ldh [hTempCardIndex_ff98], a

; find all cards that are in the same location (previous stages
; and attached Energy) and return them all to the deck.
	ldh a, [hTemp_ffa0]
	or CARD_LOCATION_PLAY_AREA
	ld e, a
	ld a, DUELVARS_CARD_LOCATIONS
	call GetTurnDuelistVariable
.loop_cards
	push de
	push hl
	ld a, [hl]
	cp e
	jr nz, .next_card
	ld a, l
	call ReturnCardToDeck
.next_card
	pop hl
	pop de
	inc l
	ld a, l
	cp DECK_SIZE
	jr c, .loop_cards

; clear the Play Area location of the card
	ldh a, [hTemp_ffa0]
	ld e, a
	call EmptyPlayAreaSlot
	ld l, DUELVARS_NUMBER_OF_POKEMON_IN_PLAY_AREA
	dec [hl]
	call ShiftAllPokemonToFirstPlayAreaSlots

; if the Trainer card wasn't played by the Player,
; print the selected Pokemon's name and show the card on screen.
	call IsPlayerTurn
	jp c, ShuffleCardsInDeck
	ldh a, [hTempCardIndex_ff98]
	call LoadCardDataToBuffer1_FromDeckIndex
	ld hl, wLoadedCard1Name
	ld a, [hli]
	ld h, [hl]
	ld l, a
	call LoadTxRam2
	bank1call DrawLargePictureOfCard
	ldtx hl, PokemonAndAllAttachedCardsWereReturnedToDeckText
	call DrawWideTextBox_WaitForInput
	jp ShuffleCardsInDeck

PlusPowerEffect:
; attach this card to the Active Pokemon
	ld e, PLAY_AREA_ARENA
	ldh a, [hTempCardIndex_ff9f]
	call PutHandCardInPlayArea

; increase number of PlusPower cards in this location by 1
	ld a, DUELVARS_ARENA_CARD_ATTACHED_PLUSPOWER
	call GetTurnDuelistVariable
	inc [hl]
	ret

PokeBall_PlayerSelection:
	ldtx de, TrainerCardSuccessCheckText
	call Serial_TossCoin
	ldh [hTempList], a ; store coin result
	ret nc
	farcall FindAnyPokemon
	ret

PokeBall_AddToHandEffect:
	ldh a, [hTempList]
	or a
	ret z ; return if coin toss was tails

	ldh a, [hTempList + 1]
	cp $ff
	jp z, ShuffleCardsInDeck ; skip if no Pokemon was chosen

; add the Pokemon card to the hand and show on screen if
; it wasn't the Player who played the Trainer card.
	call SearchCardInDeckAndAddToHand
	call AddCardToHand
	call IsPlayerTurn
	jp c, ShuffleCardsInDeck ; done
	ldh a, [hTempList + 1]
	ldtx hl, WasPlacedInTheHandText
	bank1call DisplayCardDetailScreen
	jp ShuffleCardsInDeck

; returns carry if Pokemon Breeder cannot be used
PokemonBreederCheck:
	call CreatePlayableStage2PokemonCardListFromHand
	jr c, .cannot_evolve
	jp IsPrehistoricPowerActive
.cannot_evolve
	ldtx hl, ConditionsForEvolvingToStage2NotFulfilledText
	scf
	ret

PokemonBreeder_PlayerSelection:
; create a list of playable Stage2 cards in the hand
	call CreatePlayableStage2PokemonCardListFromHand
	bank1call Func_5591

; handle the Player's selection of a Stage2 card
	ldtx hl, PleaseSelectCardText
	ldtx de, DuelistHandText
	call SetCardListHeaderText
	bank1call DisplayCardList
	ret c ; exit if the B button was pressed

	ldh a, [hTempCardIndex_ff98]
	ldh [hTemp_ffa0], a
	ldtx hl, ChooseBasicPokemonToEvolveText
	call DrawWideTextBox_WaitForInput

; handle the Player selection's of a Basic Pokemon to evolve
	bank1call HasAlivePokemonInPlayArea
.read_input
	bank1call OpenPlayAreaScreenForSelection
	ret c ; exit if the B button was pressed
	ldh a, [hTempPlayAreaLocation_ff9d]
	ldh [hTempPlayAreaLocation_ffa1], a
	ld e, a
	ldh a, [hTemp_ffa0]
	ld d, a
	call CheckIfCanEvolveInto_BasicToStage2
	jr c, .read_input ; loop back if this card is not able to evolve
	or a
	ret

PokemonBreeder_EvolveEffect:
	ldh a, [hTempCardIndex_ff9f]
	push af
	ld hl, hTemp_ffa0
	ld a, [hli]
	ldh [hTempCardIndex_ff98], a
	ld a, [hl] ; hTempPlayAreaLocation_ffa1
	ldh [hTempPlayAreaLocation_ff9d], a

; load the card name of the Basic Pokemon to RAM
	add DUELVARS_ARENA_CARD
	call GetTurnDuelistVariable
	call LoadCardDataToBuffer1_FromDeckIndex
	ld hl, wLoadedCard1Name
	ld a, [hli]
	ld h, [hl]
	ld l, a
	call LoadTxRam2

; evolve the Basic Pokemon and overwrite its stage as STAGE2_WITHOUT_STAGE1
	ldh a, [hTempCardIndex_ff98]
	call EvolvePokemonCard
	ld [hl], STAGE2_WITHOUT_STAGE1

; load the card name of the Stage2 Pokemon to RAM
	ldh a, [hTempCardIndex_ff98]
	call LoadCardDataToBuffer1_FromDeckIndex
	ld a, 18
	call CopyCardNameAndLevel
	xor a
	ld [hl], a ; $0 character
	ld hl, wTxRam2_b
	ld [hli], a
	ld [hl], a

; display the card image, play the evolution sound effect,
; and print the corresponding card names.
	bank1call DrawLargePictureOfCard
	ld a, SFX_POKEMON_EVOLUTION
	call PlaySFX
	ldtx hl, PokemonEvolvedIntoPokemonText
	call DrawWideTextBox_WaitForInput
	call ProcessPlayedPokemonCard
	pop af
	ldh [hTempCardIndex_ff9f], a
	ret

; create a list in wDuelTempList of every Stage2 Pokemon card in the hand
; in that is a future evolution of a Basic Pokemon in the Play Area.
; returns carry if that list is empty.
CreatePlayableStage2PokemonCardListFromHand:
	call CreateHandCardList
	ret c ; return if no hand cards

; check if the Stage2 card in the hand can be used
; to evolve a Basic Pokemon in the Play Area,
; and if so, add it to the wDuelTempList.
	ld hl, wDuelTempList
	ld e, l
	ld d, h
.loop_hand
	ld a, [hl]
	cp $ff
	jr z, .done
	call .CheckIfCanEvolveAnyPlayAreaBasicCard
	jr c, .next_hand_card
	ld a, [hl]
	ld [de], a
	inc de
.next_hand_card
	inc hl
	jr .loop_hand

.done
	ld a, $ff ; terminating byte
	ld [de], a
	ld a, [wDuelTempList]
	cp $ff
	scf
	ret z ; returns carry if empty
	; not empty
	or a
	ret

; returns carry if Stage2 card in a cannot evolve any
; of the Basic Pokemon in the Play Area using Pokemon Breeder.
.CheckIfCanEvolveAnyPlayAreaBasicCard
	push de
	ld d, a
	call LoadCardDataToBuffer2_FromDeckIndex
	ld a, [wLoadedCard2Type]
	cp TYPE_ENERGY
	jr nc, .set_carry ; skip if not a Pokemon
	ld a, [wLoadedCard2Stage]
	cp STAGE2
	jr nz, .set_carry ; skip if not Stage2

; check if can evolve any Play Area cards
	push hl
	push bc
	ld a, DUELVARS_NUMBER_OF_POKEMON_IN_PLAY_AREA
	call GetTurnDuelistVariable
	ld c, a
	ld e, PLAY_AREA_ARENA
.loop_play_area
	push bc
	push de
	call CheckIfCanEvolveInto_BasicToStage2
	pop de
	pop bc
	jr nc, .done_play_area
	inc e
	dec c
	jr nz, .loop_play_area
; set carry
	scf
.done_play_area
	pop bc
	pop hl
	pop de
	ret
.set_carry
	pop de
	scf
	ret

; check if the player's Pokemon card at e can evolve this turn and
; that is a Basic Pokemon card whose Stage2 evolution is in the player's hand.
; e is the play area location offset (PLAY_AREA_*) of the Pokemon trying to evolve.
; d is the deck index (0-59) of the Pokemon that was selected to be the evolution target.
; returns carry if it isn't a Basic with a matching Stage2,
; or if evolution isn't possible this turn.
CheckIfCanEvolveInto_BasicToStage2:
	ld a, e
	add DUELVARS_ARENA_CARD_FLAGS
	call GetTurnDuelistVariable
	and CAN_EVOLVE_THIS_TURN
	jr z, .cant_evolve
	; can evolve
	ld a, e
	add DUELVARS_ARENA_CARD
	ld l, a
	ld a, [hl]
	call LoadCardDataToBuffer2_FromDeckIndex
	ld a, d
	call LoadCardDataToBuffer1_FromDeckIndex
	ld hl, wLoadedCard1PreEvoName
	ld e, [hl]
	inc hl
	ld d, [hl]
	call LoadCardDataToBuffer1_FromName
	ld hl, wLoadedCard2Name
	ld de, wLoadedCard1PreEvoName
	ld a, [de]
	cp [hl]
	jr nz, .cant_evolve
	inc de
	inc hl
	ld a, [de]
	cp [hl]
	jr nz, .cant_evolve
	or a
	ret
.cant_evolve
	xor a
	scf
	ret

PokemonCenter_HealDiscardEnergyEffect:
	ld a, DUELVARS_NUMBER_OF_POKEMON_IN_PLAY_AREA
	call GetTurnDuelistVariable
	ld d, a
	ld e, PLAY_AREA_ARENA

; go through every Pokemon in the Play Area to look for damage
.loop_play_area
; check its damage
	ld a, e
	ldh [hTempPlayAreaLocation_ff9d], a
	call GetCardDamageAndMaxHP
	or a
	jr z, .next_pkmn ; skip the Pokemon if it doesn't have any damage

; heal all of its damage
	push de
	ld e, a
	ld d, $00
	call HealPlayAreaCardHP

; loop all cards in the deck and discard all Energy cards
; that are attached to this Play Area location's Pokemon.
	ldh a, [hTempPlayAreaLocation_ff9d]
	or CARD_LOCATION_PLAY_AREA
	ld e, a
	ld a, $00
	call GetTurnDuelistVariable
.loop_deck
	ld a, [hl]
	cp e
	jr nz, .next_card_deck ; skip if not attached to any card
	ld a, l
	call LoadCardDataToBuffer2_FromDeckIndex
	ld a, [wLoadedCard2Type]
	and TYPE_ENERGY
	jr z, .next_card_deck ; skip if not an Energy
	ld a, l
	call PutCardInDiscardPile
.next_card_deck
	inc l
	ld a, l
	cp DECK_SIZE
	jr c, .loop_deck

	pop de
.next_pkmn
	inc e
	dec d
	jr nz, .loop_play_area
	ret

; returns carry if the opponent's Bench is full
; or if there are no Basic Pokemon cards in the opponent's discard pile.
PokemonFluteCheck:
	ld a, DUELVARS_NUMBER_OF_POKEMON_IN_PLAY_AREA
	call GetNonTurnDuelistVariable
	ldtx hl, NoSpaceOnTheBenchText
	cp MAX_PLAY_AREA_POKEMON
	ccf
	ret c ; not enough space on the Bench
	; check the discard pile
	call SwapTurn
	call CreateBasicPokemonCardListFromDiscardPile
	ldtx hl, CannotUsePokemonFluteText
	jp SwapTurn

PokemonFlute_PlayerSelection:
; create a list of relevant cards in the opponent's discard pile
	call SwapTurn
	call CreateBasicPokemonCardListFromDiscardPile

; display selection screen and store the Player's selection
	bank1call Func_5591
	ldtx hl, ChoosePokemonToPlaceInPlayText
	ldtx de, OpponentsDiscardPileText
	call SetCardListHeaderText
	bank1call DisplayCardList
	call SwapTurn
	ldh a, [hTempCardIndex_ff98]
	ldh [hTemp_ffa0], a
	ret

PokemonFlute_PlaceInPlayAreaText:
; place the selected card on the opponent's Bench
	call SwapTurn
	ldh a, [hTemp_ffa0]
	call MoveDiscardPileCardToHand
	call AddCardToHand
	call PutHandPokemonCardInPlayArea
	call SwapTurn

; display the Pokemon on screen if it wasn't the Player who used Pokemon Flute.
	call IsPlayerTurn
	ret c
	call SwapTurn
	ldh a, [hTemp_ffa0]
	ldtx hl, CardWasChosenText
	bank1call DisplayCardDetailScreen
	jp SwapTurn

; returns carry if there are no other cards in hand,
; or if there are no Pokemon cards in hand.
PokemonTraderCheck:
	ld a, DUELVARS_NUMBER_OF_CARDS_IN_HAND
	call GetTurnDuelistVariable
	ldtx hl, NoPokemonInHandText
	cp 2
	ret c ; return if no other cards in hand
	call CreatePokemonCardListFromHand
	ldtx hl, NoPokemonInHandText
	ret

PokemonTrader_PlayerHandSelection:
; print text box
	ldtx hl, ChoosePokemonFromYourHandText
	call DrawWideTextBox_WaitForInput

; create list with all Pokemon cards in the hand
	call CreatePokemonCardListFromHand
	bank1call Func_5591

; handle Player selection
	ldtx hl, ChoosePokemonToReturnToTheDeckText
	ldtx de, DuelistHandText
	call SetCardListHeaderText
	bank1call DisplayCardList
	ldh [hTemp_ffa0], a
	ret

PokemonTrader_PlayerDeckSelection:
; temporarily place the chosen card from the hand into the deck
; because it is a potential search target
	ldh a, [hTemp_ffa0]
	call RemoveCardFromHand
	call ReturnCardToDeck

; display the list of cards from the deck
	ldtx hl, ChoosePokemonFromDeckText
	call DrawWideTextBox_WaitForInput
	call CreateDeckCardList
	bank1call Func_5591
	ldtx hl, ChoosePokemonCardText
	ldtx de, DuelistDeckText
	call SetCardListHeaderText

; handle Player selection
.read_input
	bank1call DisplayCardList
	jr c, .read_input ; must choose, B button can't be used to exit
	call LoadCardDataToBuffer2_FromDeckIndex
	ld a, [wLoadedCard2Type]
	cp TYPE_ENERGY
	jr nc, .read_input ; can't select non-Pokemon cards

; a valid card was selected, store its card index and
; place the selected card from the hand back into the hand.
	ldh a, [hTempCardIndex_ff98]
	ldh [hTempPlayAreaLocation_ffa1], a
	ldh a, [hTemp_ffa0]
	call SearchCardInDeckAndAddToHand
	call AddCardToHand
	or a
	ret

PokemonTrader_TradeCardsEffect:
; place the card from the hand into the deck
	ldh a, [hTemp_ffa0]
	call RemoveCardFromHand
	call ReturnCardToDeck

; place the card from the deck into the hand
	ldh a, [hTempPlayAreaLocation_ffa1]
	call SearchCardInDeckAndAddToHand
	call AddCardToHand

; display cards if Pokemon Trader wasn't played by the Turn Player
	call IsPlayerTurn
	jp c, ShuffleCardsInDeck ; done
	ldh a, [hTemp_ffa0]
	ldtx hl, PokemonWasReturnedToDeckText
	bank1call DisplayCardDetailScreen
	ldh a, [hTempPlayAreaLocation_ffa1]
	ldtx hl, WasPlacedInTheHandText
	bank1call DisplayCardDetailScreen
	jp ShuffleCardsInDeck

; makes a list in wDuelTempList with all Pokemon in the Turn Duelist's hand.
; returns carry if the list is empty
CreatePokemonCardListFromHand:
	ld a, DUELVARS_NUMBER_OF_CARDS_IN_HAND
	call GetTurnDuelistVariable
	ld c, a
	ld l, DUELVARS_HAND
	ld de, wDuelTempList
.loop
	ld a, [hl]
	call LoadCardDataToBuffer2_FromDeckIndex
	ld a, [wLoadedCard2Type]
	cp TYPE_ENERGY
	jr nc, .next_hand_card
	ld a, [hl]
	ld [de], a
	inc de
.next_hand_card
	inc l
	dec c
	jr nz, .loop
	ld a, $ff ; terminating byte
	ld [de], a
	ld a, [wDuelTempList]
	cp $ff
	jp z, SetCarryEF
	or a
	ret

Potion_PlayerSelection:
	bank1call HasAlivePokemonInPlayArea
.read_input
	bank1call OpenPlayAreaScreenForSelection
	ret c ; exit if the B button was pressed
	ldh a, [hTempPlayAreaLocation_ff9d]
	ldh [hTemp_ffa0], a
	ld e, a
	call GetCardDamageAndMaxHP
	or a
	jr z, .read_input ; no damage, loop back to start
; cap damage
	ld c, 20
	cp 20
	jr nc, .skip_cap
	ld c, a
.skip_cap
	ld a, c
	ldh [hTempPlayAreaLocation_ffa1], a
	or a
	ret

HealEffect:
	ldh a, [hTemp_ffa0]
	ldh [hTempPlayAreaLocation_ff9d], a
	ldh a, [hTempPlayAreaLocation_ffa1]
;	fallthrough

; heals the amount of damage in register e for the card
; in the Play Area location stored in [hTempPlayAreaLocation_ff9d].
; plays the healing animation and prints text with the card's name.
; input:
;	e = amount of HP to heal
;	[hTempPlayAreaLocation_ff9d] = Play Area location of the card to heal
HealPlayAreaCardHP:
	ld e, a
	ld d, $00

; play the heal animation
	push de
	xor a
	ld [wce7e], a
	ld a, ATK_ANIM_HEALING_WIND_PLAY_AREA
	ld [wLoadedAttackAnimation], a
	ldh a, [hTempPlayAreaLocation_ff9d]
	ld b, a
	ld c, $01
	ldh a, [hWhoseTurn]
	ld h, a
	bank1call PlayAttackAnimation
	call WaitAttackAnimation
	pop hl

; print the Pokemon's card name and damage that was healed
	push hl
	call LoadTxRam3
	ld hl, $0000
	call LoadTxRam2
	ldh a, [hTempPlayAreaLocation_ff9d]
	add DUELVARS_ARENA_CARD
	call GetTurnDuelistVariable
	call LoadCardDataToBuffer1_FromDeckIndex
	ld a, 18
	call CopyCardNameAndLevel
	ld [hl], $00 ; terminating character on end of the name
	ldtx hl, PokemonHealedDamageText
	call DrawWideTextBox_WaitForInput
	pop de

; heal the target Pokemon
	ldh a, [hTempPlayAreaLocation_ff9d]
	add DUELVARS_ARENA_CARD_HP
	call GetTurnDuelistVariable
	add e
	ld [hl], a
	ret

Recycle_PlayerSelection:
	ldtx de, TrainerCardSuccessCheckText
	call Serial_TossCoin
	jr nc, .tails

	call CreateDiscardPileCardList
	bank1call Func_5591
	ldtx hl, PleaseSelectCardText
	ldtx de, YourDiscardPileText
	call SetCardListHeaderText
.read_input
	bank1call DisplayCardList
	jr c, .read_input ; must choose, B button can't be used to exit

; a card was chosen from the discard pile
	ldh a, [hTempCardIndex_ff98]
	ldh [hTempList], a
	ret

.tails
	ld a, $ff
	ldh [hTempList], a
	or a
	ret

Recycle_AddToHandEffect:
	ldh a, [hTempList]
	cp $ff
	ret z ; return if no card was selected

; add a card to the hand and show on screen
; if it wasn't the Player who used Recycle.
	call MoveDiscardPileCardToHand
	call ReturnCardToDeck
	call IsPlayerTurn
	ret c
	ldh a, [hTempList]
	ldtx hl, CardWasChosenText
	bank1call DisplayCardDetailScreen
	ret

; returns carry if there are no Basic Pokemon in the discard pile or the Bench is full
ReviveCheck:
	call CreateBasicPokemonCardListFromDiscardPile
	ldtx hl, NoBasicPokemonInYourDiscardPileText
	ret c
	jp BenchSpaceCheck

Revive_PlayerSelection:
; create a list of Basic Pokemon from the discard pile
	ldtx hl, ChooseBasicPokemonToPlaceOnBenchText
	call DrawWideTextBox_WaitForInput
	call CreateBasicPokemonCardListFromDiscardPile
	bank1call Func_5591

; display screen to select Pokemon
	ldtx hl, PleaseSelectCardText
	ldtx de, YourDiscardPileText
	call SetCardListHeaderText
	bank1call DisplayCardList

; store selection
	ldh a, [hTempCardIndex_ff98]
	ldh [hTemp_ffa0], a
	ret

Revive_PlaceInPlayAreaEffect:
; place selected Pokemon onto the Bench
	ldh a, [hTemp_ffa0]
	call MoveDiscardPileCardToHand
	call AddCardToHand
	call PutHandPokemonCardInPlayArea

; set HP to half, rounded up
	add DUELVARS_ARENA_CARD_HP
	call GetTurnDuelistVariable
	srl a
	bit 0, a
	jr z, .rounded
	add 5 ; round up HP to the nearest 10
.rounded
	ld [hl], a
	call IsPlayerTurn
	ret c ; done if it was the Player who used Revive

; display card on screen
	ldh a, [hTemp_ffa0]
	ldtx hl, PlacedOnTheBenchText
	bank1call DisplayCardDetailScreen
	ret

ScoopUp_PlayerSelection:
; print text box
	ldtx hl, ChoosePokemonToScoopUpText
	call DrawWideTextBox_WaitForInput

; handle Player selection
	bank1call HasAlivePokemonInPlayArea
	bank1call OpenPlayAreaScreenForSelection
	ret c ; exit if the B button was pressed

	ldh [hTemp_ffa0], a
	or a
	ret nz ; return if it wasn't the Active Pokemon

; handle switching to a Pokemon on the Bench and store the selected location
	call EmptyScreen
	ldtx hl, SelectNewActivePokemonText
	call DrawWideTextBox_WaitForInput
	bank1call HasAlivePokemonInBench
	bank1call OpenPlayAreaScreenForSelection
	ldh [hTempPlayAreaLocation_ffa1], a
	ret

ScoopUp_ReturnToHandEffect:
; if card was in Bench, simply return Pokémon to hand
	ldh a, [hTemp_ffa0]
	or a
	jr nz, .not_active

; if the target was the Active Pokemon, then we need switch it
; with the selected Benched Pokemon before applying the return to hand effect,
; because the Arena can't be empty when calling ShiftAllPokemonToFirstPlayAreaSlots
	ldh a, [hTempPlayAreaLocation_ffa1]
	ld e, a
	call SwapArenaWithBenchPokemon ; also clears status conditions
	ldh a, [hTempPlayAreaLocation_ffa1]
	jr .scoop_up_effect

.not_active
	ldh a, [hTemp_ffa0]
	; fallthrough

.scoop_up_effect
; store chosen card location for Scoop Up
	ld d, a
	or CARD_LOCATION_PLAY_AREA
	ld e, a

; find Basic Pokemon card that is in the selected Play Area location
; and add it to the hand, discarding all attached cards.
	ld a, DUELVARS_CARD_LOCATIONS
	call GetTurnDuelistVariable
.loop
	ld a, [hl]
	cp e
	jr nz, .next_card ; skip if not in the selected location
	ld a, l
	call CheckDeckIndexForBasicPokemon
	jr nc, .next_card ; skip if not a Basic Pokemon
; found
	ld a, l
	ldh [hTempCardIndex_ff98], a
	call AddCardToHand
.next_card
	inc l
	ld a, l
	cp DECK_SIZE
	jr c, .loop

; since the card has been moved to the hand, MovePlayAreaCardToDiscardPile will
; take care of discarding every higher stage card and any other attached cards.
	ld e, d
	call MovePlayAreaCardToDiscardPile
	call ShiftAllPokemonToFirstPlayAreaSlots

; show the card details screen and print the corresponding text
; if it wasn't the Player who used the card
	call IsPlayerTurn
	ret c
	ldtx hl, PokemonWasReturnedToHandText
	ldh a, [hTempCardIndex_ff98]
	bank1call DisplayCardDetailScreen
	ret

; returns carry if there are no damage counters
; or no Attached Energy cards in the Play Area.
SuperPotion_DamageEnergyCheck:
	call YourPokemon_DamageCheck
	ret c ; no damage counters
	call YourPokemon_AttachedEnergyCheck
	ldtx hl, NoEnergyCardsAttachedToPokemonInYourPlayAreaText
	ret

SuperPotion_PlayerSelection:
	ldtx hl, ChoosePokemonToHealText
	call DrawWideTextBox_WaitForInput
.start
	bank1call HasAlivePokemonInPlayArea
.read_input
	bank1call OpenPlayAreaScreenForSelection
	ret c ; exit if the B button was pressed
	ld e, a
	call GetCardDamageAndMaxHP
	or a
	jr z, .read_input ; loop back if Pokemon has no damage
	ldh a, [hCurMenuItem]
	ld e, a
	call GetPlayAreaCardAttachedEnergies
	ld a, [wTotalAttachedEnergies]
	or a
	jr nz, .got_pkmn
	; no energy cards attached
	ldtx hl, NoEnergyCardsAttachedText
	call DrawWideTextBox_WaitForInput
	jr .start

.got_pkmn
; Pokemon has damage and Energy cards attached to it,
; prompt the Player for select an Energy to discard.
	ldh a, [hCurMenuItem]
	call CreateArenaOrBenchEnergyCardList
	ldh a, [hCurMenuItem]
	bank1call DisplayEnergyDiscardScreen
	bank1call HandleEnergyDiscardMenuInput
	ret c ; exit if the B button was pressed

	ldh a, [hTempCardIndex_ff98]
	ldh [hTemp_ffa0], a
	ldh a, [hTempPlayAreaLocation_ff9d]
	ldh [hTempPlayAreaLocation_ffa1], a
	ld e, a

; cap the healing if it would exceed the Pokemon's max HP.
	call GetCardDamageAndMaxHP
	ld c, 40
	cp 40
	jr nc, .heal
	ld c, a
.heal
	ld a, c
	ldh [hPlayAreaEffectTarget], a
	or a
	ret

SuperPotion_HealEffect:
	ldh a, [hTemp_ffa0]
	call PutCardInDiscardPile
	ldh a, [hTempPlayAreaLocation_ffa1]
	ldh [hTempPlayAreaLocation_ff9d], a
	ldh a, [hPlayAreaEffectTarget]
	jp HealPlayAreaCardHP

MrFuji_PlayerSelection:
	ldtx hl, ChoosePokemonToReturnToTheDeckText
	jr ChooseBenchedPokemon

Switch_PlayerSelection:
	ldtx hl, SelectNewActivePokemonText
;	fallthrough

; input:
;	[hl] = text containing instructions
ChooseBenchedPokemon:
	call DrawWideTextBox_WaitForInput
	bank1call HasAlivePokemonInBench
	bank1call OpenPlayAreaScreenForSelection
	ldh a, [hTempPlayAreaLocation_ff9d]
	ldh [hTemp_ffa0], a
	ret

SwitchEffect:
	ldh a, [hTemp_ffa0]
	ld e, a
	jp SwapArenaWithBenchPokemon

;
;----------------------------------------
;        UNREFERENCED FUNCTIONS
;----------------------------------------
;
; formerly Func_2c08c
;Serial_TossZeroCoins:
;	xor a
;	jp Serial_TossCoinATimes
;
;
;Func_2c0a8:
;	ldh a, [hTemp_ffa0]
;	push af
;	ldh a, [hWhoseTurn]
;	ldh [hTemp_ffa0], a
;	ld a, OPPACTION_6B30
;	call SetOppAction_SerialSendDuelData
;	bank1call DeckShuffleAnimation
;	ld c, a
;	pop af
;	ldh [hTemp_ffa0], a
;	ld a, c
;	ret
;
;
;Func_2c6d9:
;	ldtx hl, IncompleteText
;	jp DrawWideTextBox_WaitForInput
;
;
;CopyPlayAreaHPToBackup_Unreferenced:
;	ld a, DUELVARS_NUMBER_OF_POKEMON_IN_PLAY_AREA
;	call GetTurnDuelistVariable
;	ld c, a
;	ld l, DUELVARS_ARENA_CARD_HP
;	ld de, wBackupPlayerAreaHP
;.loop_play_area
;	ld a, [hli]
;	ld [de], a
;	inc de
;	dec c
;	jr nz, .loop_play_area
;	ret
;
;
;CopyPlayAreaHPFromBackup_Unreferenced:
;	ld a, DUELVARS_NUMBER_OF_POKEMON_IN_PLAY_AREA
;	call GetTurnDuelistVariable
;	ld c, a
;	ld l, DUELVARS_ARENA_CARD_HP
;	ld de, wBackupPlayerAreaHP
;.asm_2efd9
;	ld a, [de]
;	inc de
;	ld [hli], a
;	dec c
;	jr nz, .asm_2efd9
;	ret
