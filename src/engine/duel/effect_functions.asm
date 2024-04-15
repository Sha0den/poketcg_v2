; (1) HERE ARE A VARIETY OF CHECK EFFECTS.
; THESE ARE USED TO DETERMINE WHETHER OR NOT A CARD OR ATTACK CAN BE PLAYED.

; returns carry if no cards left in deck
DeckCheck:
	ld a, DUELVARS_NUMBER_OF_CARDS_NOT_IN_DECK
	call GetTurnDuelistVariable
	ldtx hl, NoCardsLeftInTheDeckText
	cp DECK_SIZE
	ccf
	ret

; returns carry if neither player has any cards in the deck
BothPlayers_DeckCheck:
	ld a, DUELVARS_NUMBER_OF_CARDS_NOT_IN_DECK
	call GetTurnDuelistVariable
	cp DECK_SIZE
	jr c, .no_carry
	ld a, DUELVARS_NUMBER_OF_CARDS_NOT_IN_DECK
	call GetNonTurnDuelistVariable
	cp DECK_SIZE
	jr c, .no_carry
	ldtx hl, NoCardsLeftInTheDeckText
	scf
	ret
.no_carry
	or a
	ret

; return carry if not enough cards in hand for effect
OtherCardsInHandCheck:
	ld a, DUELVARS_NUMBER_OF_CARDS_IN_HAND
	call GetTurnDuelistVariable
	ldtx hl, NotEnoughCardsInHandText
	cp 3
	ret

; returns carry if no cards in the Discard Pile
; move ldtx to after call if you need to swapturn to check opponent's discard pile
DiscardPileCheck:
	ld a, DUELVARS_NUMBER_OF_CARDS_IN_DISCARD_PILE
	call GetTurnDuelistVariable
	ldtx hl, NoCardsInTheDiscardPileText
	cp 1
	ret

; returns carry if no Energy cards are in the Discard Pile.
DiscardedEnergyCheck:
	call CreateEnergyCardListFromDiscardPile_AllEnergy
	ldtx hl, NoEnergyCardsInDiscardPileText
	ret

; return carry if no Pokemon on the Bench.
BenchedPokemonCheck:
	ld a, DUELVARS_NUMBER_OF_POKEMON_IN_PLAY_AREA
	call GetTurnDuelistVariable
	ldtx hl, YouNoBenchedPokemonText
	cp 2
	ret

; return carry if opponent has no Benched Pokemon
Opponent_BenchedPokemonCheck:
	ld a, DUELVARS_NUMBER_OF_POKEMON_IN_PLAY_AREA
	call GetNonTurnDuelistVariable
	ldtx hl, OpponentNoBenchedPokemonText
	cp 2
	ret

; return carry if Bench is full.
BenchSpaceCheck:
	ld a, DUELVARS_NUMBER_OF_POKEMON_IN_PLAY_AREA
	call GetTurnDuelistVariable
	ldtx hl, NoSpaceOnTheBenchText
	cp MAX_PLAY_AREA_POKEMON
	ccf
	ret

; return carry if neither Play Area has room for more Bench Pokemon.
PlayArea_BenchCheck:
	ld a, DUELVARS_NUMBER_OF_POKEMON_IN_PLAY_AREA
	call GetTurnDuelistVariable
	cp MAX_PLAY_AREA_POKEMON
	jr c, .no_carry
	ld a, DUELVARS_NUMBER_OF_POKEMON_IN_PLAY_AREA
	call GetNonTurnDuelistVariable
	cp MAX_PLAY_AREA_POKEMON
	jr c, .no_carry
	ldtx hl, NoSpaceOnTheBenchText
	scf
	ret
.no_carry
	or a
	ret

; returns carry if Play Area has no damage counters.
PlayAreaDamageCheck:
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
	scf
	ret

; returns carry if none of the player's pokemon have any damage counters
YourPokemon_DamageCheck:
	call PlayAreaDamageCheck
	ldtx hl, NoPokemonWithDamageCountersText
	ret

; returns carry if player's active pokemon has no damage counters
ActivePokemon_DamageCheck:
	ld e, PLAY_AREA_ARENA
	call GetCardDamageAndMaxHP
	ldtx hl, NoDamageCountersText
	cp 10
	ret

; returns carry if the Active Pokemon has no special conditions
ActivePokemon_StatusCheck:
	ld a, DUELVARS_ARENA_CARD_STATUS
	call GetTurnDuelistVariable
	or a
	ret nz
	ldtx hl, NotAffectedByPoisonSleepParalysisOrConfusionText
	scf
	ret

; return carry if Defending Pokemon has no attacks
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

; checks if there is at least one Energy card
; attached to some card in the Turn Duelist's Play Area.
; returns carry set if none are found
PlayAreaAttachedEnergyCheck:
	ld a, DUELVARS_CARD_LOCATIONS
	call GetTurnDuelistVariable
.loop_deck
	ld a, [hl]
	bit CARD_LOCATION_PLAY_AREA_F, a
	jr z, .next_card ; skip if not in Play Area
	ld a, l
	call LoadCardDataToBuffer2_FromDeckIndex
	ld a, [wLoadedCard2Type]
	cp TYPE_TRAINER
	jr z, .next_card ; skip if it's a Trainer card
	cp TYPE_ENERGY
	jr nc, .found
.next_card
	inc l
	ld a, l
	cp DECK_SIZE
	jr c, .loop_deck
	scf
	ret
.found
	or a
	ret

; return carry if Active Pokemon has less than 2 Energy cards
ActivePokemon2CardsAttached_EnergyCheck:
	xor a ; PLAY_AREA_ARENA
	call CreateArenaOrBenchEnergyCardList
	call CountCardsInDuelTempList
	ldtx hl, NotEnoughEnergyCardsText
	cp 2
	ret

; return carry if no Fire Energy attached
ActivePokemon_FireEnergyCheck:
	ld e, PLAY_AREA_ARENA
	call GetPlayAreaCardAttachedEnergies
	ldtx hl, NotEnoughFireEnergyText
	ld a, [wAttachedEnergies]
	cp 1
	ret

; return carry if Active Pokemon has less than 2 Fire Energy
ActivePokemon_DoubleFireEnergyCheck:
	ld e, PLAY_AREA_ARENA
	call GetPlayAreaCardAttachedEnergies
	ld a, [wAttachedEnergies]
	ldtx hl, NotEnoughFireEnergyText
	cp 2
	ret

; return carry if no Psychic Energy attached
ActivePokemon_PsychicEnergyCheck:
	ld e, PLAY_AREA_ARENA
	call GetPlayAreaCardAttachedEnergies
	ld a, [wAttachedEnergies + PSYCHIC]
	ldtx hl, NotEnoughPsychicEnergyText
	cp 1
	ret

; return carry if Defending Pokemon is not asleep
DefendingPokemon_SleepCheck:
	ld a, DUELVARS_ARENA_CARD_STATUS
	call GetNonTurnDuelistVariable
	and CNF_SLP_PRZ
	cp ASLEEP
	ret z ; return if asleep
; not asleep, set carry and load text
	ldtx hl, OpponentIsNotAsleepText
	scf
	ret

;
; (2) NEXT ARE SOME FUNCTIONS THAT ARE FREQUENTLY CALLED BY MANY OTHER FUNCTIONS

TossCoin_BankB:
	call TossCoin
	ret

TossCoinATimes_BankB:
	call TossCoinATimes
	ret

; overwrites wDamage, wAIMinDamage and wAIMaxDamage with the value in a.
SetDefiniteDamage:
	ld [wDamage], a
	ld [wAIMinDamage], a
	ld [wAIMaxDamage], a
	xor a
	ld [wDamage + 1], a
	ret

; overwrites wAIMinDamage and wAIMaxDamage with value in wDamage.
SetDefiniteAIDamage:
	ld a, [wDamage]
	ld [wAIMinDamage], a
	ld [wAIMaxDamage], a
	ret

Func_2c08a:
	ld a, $1
;	fallthrough

Func_2c08c:
	push de
	push af
	ld a, OPPACTION_TOSS_COIN_A_TIMES
	call SetOppAction_SerialSendDuelData
	pop af
	pop de
	call SerialSend8Bytes
	call TossCoinATimes
	ret

Func_2c10b:
	ldh [hTempPlayAreaLocation_ff9d], a
	bank1call Func_61a1
	bank1call PrintPlayAreaCardList_EnableLCD
	bank1call Func_6194
	ret

; input:
;	a = attack animation to play
Func_2fea9:
	ld [wLoadedAttackAnimation], a
	bank1call Func_7415
	ld bc, $0
	ldh a, [hWhoseTurn]
	ld h, a
	bank1call PlayAttackAnimation
	bank1call WaitAttackAnimation
	ret

; prompts the Player with a Yes/No question
; whether to quit the screen, even though
; they can select more cards from list.
; [hCurSelectionItem] holds number of cards
; that were already selected by the Player.
; input:
;	- a = total number of cards that can be selected
; output:
;	- carry set if "No" was selected
AskWhetherToQuitSelectingCards:
	ld hl, hCurSelectionItem
	sub [hl]
	ld l, a
	ld h, $00
	call LoadTxRam3
	ldtx hl, YouCanSelectMoreCardsQuitText
	call YesOrNoMenuWithText
	ret

; returns carry if Player is the Turn Duelist
IsPlayerTurn:
	ld a, DUELVARS_DUELIST_TYPE
	call GetTurnDuelistVariable
	cp DUELIST_TYPE_PLAYER
	jr z, .player
	or a
	ret
.player
	scf
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

CardDiscardEffect:
	ldh a, [hTemp_ffa0]
	call PutCardInDiscardPile
	ret

VariableDiscardEffect:
	ldh a, [hTempList]
	call PutCardInDiscardPile
	ret

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

; (3) THIS IS THE START OF THE ATTACK FUNCTIONS
; ATTACK EFFECTS THAT REARRANGE, DRAW FROM, OR PULL CARDS OUT OF THE DECK ARE LISTED FIRST.

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
	bank1call SetCardListHeaderText
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
	jr c, .loop_selection ; if still more cards to select, loop back up

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

; non-turn duelist
	ld a, DUELVARS_NUMBER_OF_CARDS_NOT_IN_DECK
	call GetNonTurnDuelistVariable
	cp DECK_SIZE
	jr nc, .select_deck ; no cards, go back to deck selection
	call SwapTurn
	call HandleProphecyScreen
	call ProphecyLoopOrder
	call SwapTurn
	ret

.turn_duelist
	ld a, DUELVARS_NUMBER_OF_CARDS_NOT_IN_DECK
	call GetTurnDuelistVariable
	cp DECK_SIZE
	jr nc, .select_deck ; no cards, go back to deck selection
	call HandleProphecyScreen
	call ProphecyLoopOrder
	ret

Prophecy_AISelection:
; AI doesn't ever choose this attack so this does no sorting.
	ld a, $ff
	ldh [hTemp_ffa0], a
	ret

Prophecy_ReorderEffect:
	ld hl, hTempList
	ld a, [hli]
	or a
	jr z, Reordering ; own deck
	cp $ff
	ret z

	; opponent's deck
	call SwapTurn
	call Reordering
	call SwapTurn
	ret

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
	call PokedexLoopOrder

Pokedex_ReorderEffect:
; place cards in order to the hand.
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

.place_top_deck
; go to last card that was in the list
	dec hl
	dec hl
.loop_place_deck
; return the cards to the top of the deck
	ld a, [hld]
	call ReturnCardToDeck
	dec c
	jr nz, .loop_place_deck
; opponent notification from original Prophecy function
	call IsPlayerTurn
	ret c
	ldtx hl, RearrangedCardsInDuelistsDeckText
	call DrawWideTextBox_WaitForInput
	ret

DrawCard50PercentEffect:
	ldtx de, IfHeadsDraw1CardFromDeckText
	call TossCoin_BankB
	ret nc ; tails
	ldtx hl, Draw1CardFromTheDeckText
	call DrawWideTextBox_WaitForInput
	bank1call DisplayDrawOneCardScreen
	call DrawCardFromDeck
	ret c ; empty deck
	call AddCardToHand
	call LoadCardDataToBuffer1_FromDeckIndex
	ld a, [wDuelistType]
	cp DUELIST_TYPE_PLAYER
	ret nz
	; show card on screen if it was Player
	bank1call OpenCardPage_FromHand
	ret

DrawCardEffect:
	ldtx hl, Draw1CardFromTheDeckText
	call DrawWideTextBox_WaitForInput
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

Draw2Effect:
	ld a, 2
	bank1call DisplayDrawNCardsScreen
	ld c, 2
.loop_draw
	call DrawCardFromDeck
	jr c, .done
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
.done
	ret

AddCardFromDeckToHandEffect:
	ldh a, [hTemp_ffa0]
	cp $ff
	jr z, .done
; add to hand
	call SearchCardInDeckAndAddToHand
	call AddCardToHand
	call IsPlayerTurn
	jr c, .done ; done if Player played card
; display card in screen
	ldh a, [hTemp_ffa0]
	ldtx hl, WasPlacedInTheHandText
	bank1call DisplayCardDetailScreen
.done
;	fallthrough

Func_2c0bd:
	call ExchangeRNG
	bank1call Func_4f2d
	call ShuffleDeck
	ret

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
	jr z, .done

; add card to hand and attach it to the selected Pokemon
	call SearchCardInDeckAndAddToHand
	call AddCardToHand
	ldh a, [hTempPlayAreaLocation_ffa1]
	ld e, a
	ldh a, [hTemp_ffa0]
	call PutHandCardInPlayArea
	call IsPlayerTurn
	jr c, .done

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

.done
	call Func_2c0bd
	ret

EvolutionSearch_PlayerSelection:
	farcall FindEvolution
	ret

; returns carry if no card in Deck or if Bench if full
CallForF_CheckDeckAndPlayArea:
	call DeckCheck
	ret c ; return if no cards in deck
	ld a, DUELVARS_NUMBER_OF_POKEMON_IN_PLAY_AREA
	call GetTurnDuelistVariable
	ldtx hl, NoSpaceOnTheBenchText
	cp MAX_PLAY_AREA_POKEMON
	ccf
	ret

CallForF_PutInPlayAreaEffect:
	ldh a, [hTemp_ffa0]
	cp $ff
	jr z, .shuffle
	call SearchCardInDeckAndAddToHand
	call AddCardToHand
	call PutHandPokemonCardInPlayArea
	call IsPlayerTurn
	jr c, .shuffle
; display card on screen
	ldh a, [hTemp_ffa0]
	ldtx hl, PlacedOnTheBenchText
	bank1call DisplayCardDetailScreen
.shuffle
	call Func_2c0bd
	ret

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
	call DrawWideTextBox_WaitForInput
	ret

.successful
	call PickRandomBasicCardFromDeck
	jr nc, .put_in_bench
	ld a, ATK_ANIM_FRIENDSHIP_SONG
	jr Func_2c12e
	call .none_came_text
	call Func_2c0bd
	ret

.put_in_bench
	call SearchCardInDeckAndAddToHand
	call AddCardToHand
	call PutHandPokemonCardInPlayArea
	ld a, ATK_ANIM_FRIENDSHIP_SONG
	jr Func_2c12e
	ldh a, [hTempCardIndex_ff98]
	ldtx hl, PlacedOnTheBenchText
	bank1call DisplayCardDetailScreen
	call Func_2c0bd
	ret

Func_2c12e:
	ld [wLoadedAttackAnimation], a
	ldh a, [hTempPlayAreaLocation_ff9d]
	ld b, a
	ld c, $0 ; neither WEAKNESS nor RESISTANCE
	ldh a, [hWhoseTurn]
	ld h, a
	bank1call PlayAttackAnimation
	bank1call WaitAttackAnimation
	ret

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
	jr z, .set_carry
	call LoadCardDataToBuffer2_FromDeckIndex
	ld a, [wLoadedCard2Type]
	cp TYPE_ENERGY
	jr nc, .loop_deck ; skip non-Pokemon cards
	ld a, [wLoadedCard2Stage]
	or a
	jr nz, .loop_deck ; skip if not Basic
	ldh a, [hTempCardIndex_ff98]
	or a
	ret
.set_carry
	scf
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
	call SwapTurn
	ret

.FillBench
	call CreateDeckCardList
	ret c
	ld hl, wDuelTempList
	call ShuffleCards

; if no more space in the Bench, then return.
.check_bench
	push hl
	ld a, DUELVARS_NUMBER_OF_POKEMON_IN_PLAY_AREA
	call GetTurnDuelistVariable
	pop hl
	cp MAX_PLAY_AREA_POKEMON
	jr nc, .done

; there's still space, so look for the next
; Basic Pokemon card to put in the Bench.
.loop
	ld a, [hli]
	ldh [hTempCardIndex_ff98], a
	cp $ff
	jr z, .done
	call LoadCardDataToBuffer2_FromDeckIndex
	ld a, [wLoadedCard2Type]
	cp TYPE_ENERGY
	jr nc, .loop ; is Pokemon card?
	ld a, [wLoadedCard2Stage]
	or a
	jr nz, .loop ; is Basic?
; place card in Bench
	push hl
	ldh a, [hTempCardIndex_ff98]
	call SearchCardInDeckAndAddToHand
	call AddCardToHand
	call PutHandPokemonCardInPlayArea
	pop hl
	jr .check_bench

.done
	call Func_2c0bd
	ret

;
; (4) ATTACK EFFECTS THAT PULL CARDS OUT OF THE DISCARD PILE ARE NEXT.

; makes a list in wDuelTempList with the deck indices
; of cards found in Turn Duelist's Discard Pile.
; returns carry set if no Trainer cards found,
; also loads corresponding notification text
CreateTrainerCardListFromDiscardPile:
; get number of cards in Discard Pile
; and have hl point to the end of the
; Discard Pile list in wOpponentDeckCards.
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
; of all basic energy cards found in Turn Duelist's Discard Pile.
CreateEnergyCardListFromDiscardPile_OnlyBasic:
	ld c, $01
	jr CreateEnergyCardListFromDiscardPile

; makes a list in wDuelTempList with the deck indices
; of all energy cards (including Double Colorless)
; found in Turn Duelist's Discard Pile.
CreateEnergyCardListFromDiscardPile_AllEnergy:
	ld c, $00
;	fallthrough

; makes a list in wDuelTempList with the deck indices
; of energy cards found in Turn Duelist's Discard Pile.
; if (c == 0), all energy cards are allowed;
; if (c != 0), double colorless energy cards are not included.
; returns carry if no energy cards were found.
CreateEnergyCardListFromDiscardPile:
; get number of cards in Discard Pile
; and have hl point to the end of the
; Discard Pile list in wOpponentDeckCards.
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

; if (c != $00), then we dismiss Double Colorless
; energy cards found.
	ld a, c
	or a
	jr z, .copy
	ld a, [wLoadedCard2Type]
	cp TYPE_ENERGY_DOUBLE_COLORLESS
	jr nc, .next_card

.copy
	ld a, [hl]
	ld [de], a
	inc de

; goes through Discard Pile list in wOpponentDeckCards in descending order.
.next_card
	dec l
	dec b
	jr nz, .check_energy

; terminating byte on wDuelTempList
	ld a, $ff
	ld [de], a

; check if any energy card was found by checking
; whether the first byte in wDuelTempList is $ff.
; if none were found, return carry.
	ld a, [wDuelTempList]
	cp $ff
	jr z, .set_carry
	or a
	ret

.set_carry
	scf
	ret

; returns carry if no Trainer cards are in the Discard Pile.
Scavenge_DiscardPileAndEnergyCheck:
	call ActivePokemon_PsychicEnergyCheck
	ret c ; return if no Psychic energy attached
	call CreateTrainerCardListFromDiscardPile
	ldtx hl, NoTrainerCardsInDiscardPileText ; this is redundant
	ret

Scavenge_AISelection:
; AI picks first Energy card in list
	call DiscardAttachedPsychicEnergy_AISelection
; AI picks first Trainer card in list
	call CreateTrainerCardListFromDiscardPile
	ld a, [wDuelTempList]
	ldh [hTempPlayAreaLocation_ffa1], a
	ret

Scavenge_TrainerPlayerSelection:
	call CreateTrainerCardListFromDiscardPile
	bank1call Func_5591
	ldtx hl, PleaseSelectCardText
	ldtx de, YourDiscardPileText
	bank1call SetCardListHeaderText
.loop_input
	bank1call DisplayCardList
	jr c, .loop_input
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

; draws list of Energy Cards in Discard Pile for Player to select from.
; the Player can select up to 2 cards from the list.
; these cards are given in $ff-terminated list
; in hTempList.
Choose2EnergyFromDiscardPile_PlayerSelection:
	ldtx hl, Choose2EnergyCardsFromDiscardPileText
	push hl
	xor a
	ldh [hCurSelectionItem], a
	call CreateEnergyCardListFromDiscardPile_AllEnergy
	pop hl
	jr c, .finish

	call DrawWideTextBox_WaitForInput
.loop
; draws Discard Pile screen and textbox,
; and handles Player input
	bank1call InitAndDrawCardListScreenLayout
	ldtx hl, ChooseAnEnergyCardText
	ldtx de, YourDiscardPileText
	bank1call SetCardListHeaderText
	bank1call DisplayCardList
	jr nc, .selected

; Player is trying to exit screen,
; but can select up to 2 cards total.
; prompt Player to confirm exiting screen.
	ld a, 2
	call AskWhetherToQuitSelectingCards
	jr c, .loop
	jr .finish

.selected
; a card was selected, so add it to list
	call GetNextPositionInTempList
	ldh a, [hTempCardIndex_ff98]
	ld [hl], a
	call RemoveCardFromDuelTempList
	or a
	jr z, .finish ; no more cards?
	ldh a, [hCurSelectionItem]
	cp 2
	jr c, .loop ; already selected 2 cards?

.finish
; place terminating byte on list
	call GetNextPositionInTempList
	ld [hl], $ff
	or a
	ret

Choose2EnergyFromDiscardPile_AISelection:
; AI picks first 2 Energy cards
	call CreateEnergyCardListFromDiscardPile_AllEnergy
	ld hl, wDuelTempList
	ld de, hTempList
	ld c, 2
; pick first two Energy cards found
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

; loop cards that were chosen
; until $ff is reached,
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
	bank1call Func_4b38
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

;
; (5) ATTACK EFFECTS THAT BENEFIT THE PLAYER'S POKEMON ARE NEXT. (MAINLY HEAL EFFECTS)

SwitchAfterAttack_PlayerSelection:
	ldtx hl, SelectNewActivePokemonText
	call DrawWideTextBox_WaitForInput
	bank1call HasAlivePokemonInBench
	ld a, $01
	ld [wPlayAreaSelectAction], a
.loop
	bank1call OpenPlayAreaScreenForSelection
	jr c, .loop
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
; if Defending card is unaffected by attack,
; jump directly to switching this card only.
	call HandleNoDamageOrEffect
	jr c, .SwitchWithRandomBenchPokemon

; handle switching Defending card
	ld a, DUELVARS_ARENA_CARD_HP
	call GetNonTurnDuelistVariable
	or a
	jr nz, .skip_destiny_bond
	bank1call HandleDestinyBondSubstatus
.skip_destiny_bond
	call SwapTurn
	call .SwitchWithRandomBenchPokemon
	jr c, .skip_clear_damage
; clear dealt damage because Pokemon was switched
	xor a
	ld hl, wDealtDamage
	ld [hli], a
	ld [hl], a
.skip_clear_damage
	call SwapTurn
;	fallthrough for attacking card switch

.SwitchWithRandomBenchPokemon
	ld a, DUELVARS_NUMBER_OF_POKEMON_IN_PLAY_AREA
	call GetTurnDuelistVariable
	cp 2
	ret c ; return if no Bench Pokemon

; get random Bench location and swap
	dec a
	call Random
	inc a
	ld e, a
	call SwapArenaWithBenchPokemon

	xor a
	ld [wDuelDisplayedScreen], a
	ret

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

; load correct animation
	push de
	ld a, ATK_ANIM_HEAL
	ld [wLoadedAttackAnimation], a
	lb bc, PLAY_AREA_ARENA, $1 ; arrow
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
	ld a, 0
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
	bank1call WaitAttackAnimation
	ret

Healing50Percent_FlipEffect:
	ldtx de, AttackSuccessCheckText
	call TossCoin_BankB
	ldh [hTemp_ffa0], a
	jp nc, SetWasUnsuccessful
	ld a, ATK_ANIM_RECOVER
	ld [wLoadedAttackAnimation], a
	ret

Healing50Percent_Heal10Effect:
	ldh a, [hTemp_ffa0]
	or a
	ret z ; coin toss was tails
	ld e, PLAY_AREA_ARENA
	call GetCardDamageAndMaxHP
	or a
	ret z ; no damage counters
	ld a, DUELVARS_ARENA_CARD_HP
	call GetTurnDuelistVariable
	add 10
	ld [hl], a
	ret

Heal10_HealEffect:
	lb de, 0, 10
	call ApplyAndAnimateHPRecovery
	ret

Drain10Effect:
	ld hl, wDealtDamage
	ld a, [hli]
	or a
	ret z ; return if no damage dealt
	ld de, 10
	call ApplyAndAnimateHPRecovery
	ret
;Alt_Drain10Effect:
;	ld hl, wDealtDamage
;	ld a, [hli]
;	or [hl]
;	ret z ; return if no damage dealt
;	lb de, 0, 10
;	call ApplyAndAnimateHPRecovery
;	ret

DrainHalfEffect:
	ld hl, wDealtDamage
	ld a, [hli]
	ld h, [hl]
	ld l, a
	srl h
	rr l
	bit 0, l
	jr z, .rounded
	; round up to nearest 10
	ld de, 5 ; or 10 / 2
	add hl, de
.rounded
	ld e, l
	ld d, h
	call ApplyAndAnimateHPRecovery
	ret

DrainAllEffect:
	ld hl, wDealtDamage
	ld e, [hl]
	inc hl
	ld d, [hl]
	call ApplyAndAnimateHPRecovery
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
	call GetCardDamageAndMaxHP
	ldtx hl, NoDamageCountersText
	cp 10
	ret ; return carry if no damage

WaterRecover_PlayerSelection:
	ld a, TYPE_ENERGY_WATER
	call CreateListOfEnergyAttachedToActive
	xor a ; PLAY_AREA_ARENA
	bank1call DisplayEnergyDiscardScreen
	bank1call HandleEnergyDiscardMenuInput
	ret c
	ldh a, [hTempCardIndex_ff98]
	ldh [hTemp_ffa0], a ; store card chosen
	ret

WaterRecover_AISelection:
	ld a, TYPE_ENERGY_WATER
	call CreateListOfEnergyAttachedToActive
	ld a, [wDuelTempList] ; pick first card
	ldh [hTemp_ffa0], a
	ret

Recover_HealEffect:
	ld e, PLAY_AREA_ARENA
	call GetCardDamageAndMaxHP
	ld e, a ; all damage for recovery
	ld d, 0
	call ApplyAndAnimateHPRecovery
	ret

; returns carry if the player's Active Pokemon has no Psychic Energy attached
; or if it doesn't have any damage counters
PsychicRecover_EnergyAndHPCheck:
	call ActivePokemon_PsychicEnergyCheck
	ret c ; return if not enough energy
	call GetCardDamageAndMaxHP
	ldtx hl, NoDamageCountersText
	cp 10
	ret ; return carry if no damage

PsychicRecover_PlayerSelection:
	ld a, TYPE_ENERGY_PSYCHIC
	call CreateListOfEnergyAttachedToActive
	xor a ; PLAY_AREA_ARENA
	bank1call DisplayEnergyDiscardScreen
	bank1call HandleEnergyDiscardMenuInput
	ret c
	ldh a, [hTempCardIndex_ff98]
	ldh [hTemp_ffa0], a ; store card chosen
	ret

PsychicRecover_AISelection:
	ld a, TYPE_ENERGY_PSYCHIC
	call CreateListOfEnergyAttachedToActive
	ld a, [wDuelTempList] ; pick first card
	ldh [hTemp_ffa0], a
	ret

RemoveSpecialConditionsEffect:
	ld a, ATK_ANIM_FULL_HEAL
	call Func_2fea9
	ld a, DUELVARS_ARENA_CARD_STATUS
	call GetTurnDuelistVariable
	ld [hl], NO_STATUS
	bank1call DrawDuelHUDs
	ret

;
; (6) ATTACK EFFECTS THAT CAUSE SPECIAL CONDITIONS ARE NEXT

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

Poison50PercentEffect:
	ldtx de, PoisonCheckText
	call TossCoin_BankB
	ret nc

PoisonEffect:
	lb bc, CNF_SLP_PRZ, POISONED
	jr QueueStatusCondition

; Defending Pokémon becomes double poisoned (takes 20 damage per turn rather than 10)
DoublePoisonEffect:
	lb bc, CNF_SLP_PRZ, DOUBLE_POISONED
	jr QueueStatusCondition

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
	xor a
	; ...unless already so, or if affected by Muk's Toxic Gas
	call CheckCannotUseDueToStatus_OnlyToxicGasIfANon0
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

SetNoEffectFromStatus:
	ld a, EFFECT_FAILED_NO_EFFECT
	ld [wEffectFailed], a
	ret

SetWasUnsuccessful:
	ld a, EFFECT_FAILED_UNSUCCESSFUL
	ld [wEffectFailed], a
	ret

; Defending Pokemon and user become confused
ConfuseBothActivePokemonEffect:
	call ConfusionEffect
	call SwapTurn
	call ConfusionEffect
	call SwapTurn
	ret

AllOrNothingParalysisEffect:
	ld a, ATK_ANIM_HIT_EFFECT
	ld [wLoadedAttackAnimation], a
	ldtx de, AttackSuccessCheckText
	call TossCoin_BankB
	jp c, ParalysisEffect
; unsuccessful
	xor a ; ATK_ANIM_NONE
	ld [wLoadedAttackAnimation], a
	call SetDefiniteDamage
	call SetWasUnsuccessful
	ret

SpitPoison_Poison50PercentEffect:
	ldtx de, PoisonCheckText
	call TossCoin_BankB
	jp c, PoisonEffect
	ld a, ATK_ANIM_SPIT_POISON_SUCCESS
	ld [wLoadedAttackAnimation], a
	call SetNoEffectFromStatus
	ret

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
	ld a, [wDamage]
	ld [wAIMinDamage], a
	ld [wAIMaxDamage], a
	ret

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

MayInflictPoison_AIEffect:
	ld a, 5
	lb de, 0, 10
	jp UpdateExpectedAIDamage_AccountForPoison

InflictPoison_AIEffect:
	ld a, 10
	lb de, 10, 10
	jp UpdateExpectedAIDamage_AccountForPoison

Toxic_AIEffect:
	ld a, 20
	lb de, 20, 20
	jp UpdateExpectedAIDamage

; If heads, Defending Pokemon is Poisoned. If tails, it's Confused.
PoisonOrConfusionEffect:
	ldtx de, PoisonedIfHeadsConfusedIfTailsText
	call TossCoin_BankB
	jp c, PoisonEffect
	jp ConfusionEffect

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

; (7) ATTACK EFFECTS THAT CAUSE SUBSTATUS1 EFFECTS ARE NEXT.
; THESE ARE BENEFICIAL EFFECTS THAT ARE APPLIED TO THE PLAYER'S ACTIVE POKEMON.

; apply a status condition of type 1 identified by register a to the target
ApplySubstatus1ToDefendingCard:
	push af
	ld a, DUELVARS_ARENA_CARD_SUBSTATUS1
	call GetTurnDuelistVariable
	pop af
	ld [hli], a
	ret

SwordsDanceEffect:
	ld a, [wTempTurnDuelistCardID]
	cp SCYTHER
	ret nz
	ld a, SUBSTATUS1_NEXT_TURN_DOUBLE_DAMAGE
	call ApplySubstatus1ToDefendingCard
	ret

FocusEnergyEffect:
	ld a, [wTempTurnDuelistCardID]
	cp VAPOREON_LV29
	ret nz ; return if no VaporeonLv29
	ld a, SUBSTATUS1_NEXT_TURN_DOUBLE_DAMAGE
	call ApplySubstatus1ToDefendingCard
	ret

ImmunityEffect:
	ld a, SUBSTATUS1_IMMUNITY
	call ApplySubstatus1ToDefendingCard
	ret

; If heads, prevent all damage and attack effects done to user next turn
Immunity50PercentEffect:
	ldtx de, IfHeadsDoNotReceiveDamageOrEffectText
	call TossCoin_BankB
	ret nc ; return if tails
	ld a, ATK_ANIM_AGILITY_PROTECT
	ld [wLoadedAttackAnimation], a
	ld a, SUBSTATUS1_IMMUNITY
	call ApplySubstatus1ToDefendingCard
	ret

AllOrNothingImmunityEffect:
	ldtx de, AttackSuccessCheckText
	call TossCoin_BankB
	jr c, .heads
	xor a ; ATK_ANIM_NONE
	ld [wLoadedAttackAnimation], a
	call SetDefiniteDamage
	call SetWasUnsuccessful
	ret
.heads
	ld a, ATK_ANIM_AGILITY_PROTECT
	ld [wLoadedAttackAnimation], a
	ld a, SUBSTATUS1_IMMUNITY
	call ApplySubstatus1ToDefendingCard
	ret

; If heads, prevent all damage done to user next turn
DamageProtection50PercentEffect:
	ldtx de, IfHeadsNoDamageNextTurnText
	call TossCoin_BankB
	jp nc, SetWasUnsuccessful
	ld a, ATK_ANIM_PROTECT
	ld [wLoadedAttackAnimation], a
	ld a, SUBSTATUS1_NO_DAMAGE
	call ApplySubstatus1ToDefendingCard
	ret

; Prevent all damage done to user next turn, as long as it's 30 or less
HardenEffect:
	ld a, SUBSTATUS1_HARDEN
	call ApplySubstatus1ToDefendingCard
	ret

; Prevent 10 damage done to user next turn
Prevent10DamageEffect:
	ld a, SUBSTATUS1_REDUCE_BY_10
	call ApplySubstatus1ToDefendingCard
	ret

; Prevent 20 damage done to user next turn
Prevent20DamageEffect:
	ld a, SUBSTATUS1_REDUCE_BY_20
	call ApplySubstatus1ToDefendingCard
	ret

HalveDamageEffect:
	ld a, SUBSTATUS1_HALVE_DAMAGE
	call ApplySubstatus1ToDefendingCard
	ret

DestinyBondEffect:
	ld a, SUBSTATUS1_DESTINY_BOND
	call ApplySubstatus1ToDefendingCard
	ret

; (8) ATTACK EFFECTS THAT CAUSE SUBSTATUS2 EFFECTS ARE NEXT.
; THESE ARE HARMFUL EFFECTS THAT ARE APPLIED TO THE OPPONENT'S ACTIVE POKEMON.

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
	ld l, $f6
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
	call ApplySubstatus2ToDefendingCard
	ret

CannotAttackThis50PercentLeerEffect:
	ldtx de, IfHeadsOpponentCannotAttackText
	call TossCoin_BankB
	jp nc, SetWasUnsuccessful
	ld a, ATK_ANIM_LEER
	ld [wLoadedAttackAnimation], a
	ld a, SUBSTATUS2_CANNOT_ATTACK_THIS
	call ApplySubstatus2ToDefendingCard
	ret

CannotAttackThis50PercentTailWagEffect:
	ldtx de, IfHeadsOpponentCannotAttackText
	call TossCoin_BankB
	jp nc, SetWasUnsuccessful
	ld a, ATK_ANIM_LURE
	ld [wLoadedAttackAnimation], a
	ld a, SUBSTATUS2_CANNOT_ATTACK_THIS
	call ApplySubstatus2ToDefendingCard
	ret

SmokescreenEffect:
	ld a, SUBSTATUS2_SMOKESCREEN
	call ApplySubstatus2ToDefendingCard
	ret

Amnesia_PlayerSelection:
	ldtx hl, ChooseAttackOpponentWillNotBeAbleToUseText
	call DrawWideTextBox_WaitForInput
	call HandleDefendingPokemonAttackSelection
	ld a, e
	ldh [hTemp_ffa0], a
	ret

Amnesia_AISelection:
	call AIPickAttackForAmnesia
	ldh [hTemp_ffa0], a
	ret

; handles AI logic to pick attack for Amnesia
AIPickAttackForAmnesia:
; load Defending Pokemon attacks
	call SwapTurn
	ld e, PLAY_AREA_ARENA
	call GetPlayAreaCardAttachedEnergies
	call HandleEnergyBurn
	ld a, DUELVARS_ARENA_CARD
	call GetTurnDuelistVariable
	ld d, a
	call LoadCardDataToBuffer2_FromDeckIndex
; if has no attack 1 name, return
	ld hl, wLoadedCard2Atk1Name
	ld a, [hli]
	or [hl]
	jr z, .chosen

; if Defending Pokemon has enough energy for second attack, choose it
	ld e, SECOND_ATTACK
	bank1call _CheckIfEnoughEnergiesToAttack
	jr nc, .chosen
; otherwise if first attack isn't a Pkmn Power, choose it instead.
	ld e, FIRST_ATTACK_OR_PKMN_POWER
	ld a, [wLoadedCard2Atk1Category]
	cp POKEMON_POWER
	jr nz, .chosen
; if it is a Pkmn Power, choose second attack.
	ld e, SECOND_ATTACK
.chosen
	ld a, e
	call SwapTurn
	ret

; applies Amnesia effect on Defending Pokemon for attack index in hTemp_ffa0
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

; the rest of the routine for opponent to announce which attack was disabled
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
	call SwapTurn
	ret

; handles the Player selection of attack to use Amnesia or Metronome on.
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

; Prevent 10 damage done to user by Defending Pokémon next turn
ReduceBy10Effect:
	ld a, SUBSTATUS2_REDUCE_BY_10
	call ApplySubstatus2ToDefendingCard
	ret

; Prevent 20 damage done to user by Defending Pokémon next turn
ReduceBy20Effect:
	ld a, SUBSTATUS2_REDUCE_BY_20
	call ApplySubstatus2ToDefendingCard
	ret

; If heads, defending Pokemon can't retreat next turn
NoRetreat50PercentEffect:
	ldtx de, AcidCheckText
	call TossCoin_BankB
	ret nc
	ld a, SUBSTATUS2_UNABLE_RETREAT
	call ApplySubstatus2ToDefendingCard
	ret

NoRetreatEffect:
	ld a, SUBSTATUS2_UNABLE_RETREAT
	call ApplySubstatus2ToDefendingCard
	ret

; return carry if Defending card has no weakness
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

Conversion1_AISelection:
	call AISelectConversionColor
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
	call ApplySubstatus2ToDefendingCard
	ret

; returns carry if Active Pokemon has no Resistance.
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

Conversion2_AISelection:
; AI will choose Defending Pokemon's color
; unless it is colorless.
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
	call SwapTurn
	ret

Conversion2_ChangeResistanceEffect:
; apply changed resistance
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
	call DrawWideTextBox_PrintText
	ret

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
	jr z, .set_carry
	ld e, a
	ld d, $00
	ld hl, ShiftListItemToColor
	add hl, de
	ld a, [hl]
	or a
	ret
.set_carry
	scf
	ret

.menu_params
	db 1, 1 ; cursor x, cursor y
	db 2 ; y displacement between items
	db MAX_PLAY_AREA_POKEMON ; number of items
	db SYM_CURSOR_R ; cursor tile number
	db SYM_SPACE ; tile behind cursor
	dw NULL ; function pointer if non-0

.DrawScreen:
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
	; tile, BG
	db $e4, $02
	db $e0, $01
	db $eC, $02
	db $e8, $01
	db $f0, $03
	db $f4, $03

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

; handles AI logic for selecting a new color for weakness/resistance.
; Conversion1 looks in own Bench for a non-colorless card that can attack.
; Conversion2 looks in opponent's Bench for a non-colorless card that can attack.
AISelectConversionColor:
	ld a, DUELVARS_NUMBER_OF_POKEMON_IN_PLAY_AREA
	call GetTurnDuelistVariable
	ld d, a
	ld e, PLAY_AREA_ARENA
	jr .next_pkmn_atk

; look for a non-colorless Bench Pokemon
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

; none found in Bench.
; next, look for a non-colorless Bench Pokemon
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

; The previous function is actually Substatus3 and not 2.
; (9) ANY OTHER NON-DAMAGE ATTACK EFFECTS THAT DEAL WITH YOUR OPPONENT'S POKEMON ARE NEXT.

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
	jr c, .loop_input

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
;	jr c, .loop_input
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
	ret c ; return if attack had no effect
	
	; check if energy card was chosen to discard
	ldh a, [hTemp_ffa0]
	cp $ff
	ret z ; return if none selected

	; discard Energy from Defending Pokemon
	; this doesn't update DUELVARS_ARENA_CARD_LAST_TURN_EFFECT
	call SwapTurn
	call PutCardInDiscardPile
	ld a, DUELVARS_ARENA_CARD_LAST_TURN_EFFECT
	call GetTurnDuelistVariable
	ld [hl], LAST_TURN_EFFECT_DISCARD_ENERGY
	call SwapTurn
	ret

; handles the selection of a forced switch by link/AI opponent or by the player.
; outputs the Play Area location of the chosen bench card in hTempPlayAreaLocation_ff9d.
DuelistSelectForcedSwitch:
	ld a, DUELVARS_DUELIST_TYPE
	call GetNonTurnDuelistVariable
	cp DUELIST_TYPE_LINK_OPP
	jr z, .link_opp

	cp DUELIST_TYPE_PLAYER
	jr z, .player

; AI opponent
	call SwapTurn
	bank1call AIDoAction_ForcedSwitch
	call SwapTurn

	ld a, [wPlayerAttackingAttackIndex]
	ld e, a
	ld a, [wPlayerAttackingCardIndex]
	ld d, a
	ld a, [wPlayerAttackingCardID]
	call CopyAttackDataAndDamage_FromCardID
	call UpdateArenaCardIDsAndClearTwoTurnDuelVars
	ret

.player
	ldtx hl, SelectNewActivePokemonText
	call DrawWideTextBox_WaitForInput
	call SwapTurn
	bank1call HasAlivePokemonInBench
	ld a, $01
	ld [wPlayAreaSelectAction], a
.asm_2c4c0
	bank1call OpenPlayAreaScreenForSelection
	jr c, .asm_2c4c0
	call SwapTurn
	ret

.link_opp
; get selection from link opponent
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

HandleSwitchDefendingPokemonEffect:
	ld e, a
	cp $ff
	ret z

; check Defending Pokemon's HP
	ld a, DUELVARS_ARENA_CARD_HP
	call GetNonTurnDuelistVariable
	or a
	jr nz, .switch

; if 0, handle Destiny Bond first
	push de
	bank1call HandleDestinyBondSubstatus
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
; the PLAY_AREA_* location of the Bench Pokemon that was selected for switch.
OpponentSwitchesActive50Percent_SelectEffect:
	xor a
	ldh [hTemp_ffa0], a

; return failure if no Pokemon to switch to
	ld a, DUELVARS_NUMBER_OF_POKEMON_IN_PLAY_AREA
	call GetNonTurnDuelistVariable
	cp 2
	ret c

; toss coin and store whether it was tails (0) or heads (1) in hTemp_ffa0.
; return if it was tails.
	ldtx de, IfHeadsChangeOpponentsActivePokemonText
	call Func_2c08a
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
	call HandleSwitchDefendingPokemonEffect
	ret

OpponentSwitchesActive_SwitchEffect:
	ldh a, [hTemp_ffa0]
	call HandleSwitchDefendingPokemonEffect
	ret

Recoil20OpponentSwitchesActiveEffect:
	ld a, 20
	call DealRecoilDamageToSelf
	ldh a, [hTemp_ffa0]
	call HandleSwitchDefendingPokemonEffect
	ret

; return in hTempPlayAreaLocation_ffa1 the PLAY_AREA_* location of the Bench Pokemon that was selected
SwitchDefendingPokemon_PlayerSelection:
	ldtx hl, SelectNewDefendingPokemonText
	call DrawWideTextBox_WaitForInput
	call SwapTurn
	bank1call HasAlivePokemonInBench
	bank1call OpenPlayAreaScreenForSelection
	ldh a, [hTempPlayAreaLocation_ff9d]
	ldh [hTemp_ffa0], a
	call SwapTurn
	ret
;
;Alt_SwitchDefendingPokemon_PlayerSelection:
;	ldtx hl, SelectNewDefendingPokemonText
;	call DrawWideTextBox_WaitForInput
;	call SwapTurn
;	bank1call HasAlivePokemonInBench
;.select_pokemon
;	bank1call OpenPlayAreaScreenForSelection
;	jr c, .select_pokemon
;	ldh a, [hTempPlayAreaLocation_ff9d]
;	ldh [hTemp_ffa0], a
;	call SwapTurn
;	ret

; Return in hTemp_ffa0 the PLAY_AREA_* of the non-turn holder's Pokemon card in bench with the lowest (remaining) HP.
; if multiple cards are tied for the lowest HP, the one with the highest PLAY_AREA_* is returned.
SwitchDefendingPokemon_AISelection:
	call GetBenchPokemonWithLowestHP
	ldh [hTemp_ffa0], a
	ret

; Return in a the PLAY_AREA_* of the non-turn holder's Pokemon card in bench with the lowest (remaining) HP.
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
	call SwapTurn
	ret

; Defending Pokemon is swapped out for the one with the PLAY_AREA_* at hTemp_ffa0
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

GustOfWind_SwitchEffect:
; play whirlwind animation
	ld a, ATK_ANIM_GUST_OF_WIND
	call Func_2fea9

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

; returns carry if neither player has any evolved Pokemon.
PlayArea_EvolvedPokemonCheck:
	call CheckIfTurnDuelistHasEvolvedCards
	ret nc
	call SwapTurn
	call CheckIfTurnDuelistHasEvolvedCards
	call SwapTurn
	ldtx hl, NoEvolvedPokemonText
	ret

; returns carry if Turn Duelist has no Evolution cards in Play Area.
CheckIfTurnDuelistHasEvolvedCards:
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
	scf
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
	jr nz, .set_carry

; a Play Area was selected
	ldh a, [hCurMenuItem]
	or a
	jr nz, .opp_chosen

; player chosen
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

.set_carry
	scf
	ret

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
	jr c, .unaffected
.skip_handle_no_damage_effect
	call .DevolvePokemon
.unaffected
	call SwapTurn
	ret

.DevolvePokemon
	ld a, ATK_ANIM_DEVOLUTION_BEAM
	ld [wLoadedAttackAnimation], a
	ldh a, [hTempPlayAreaLocation_ffa1]
	ld b, a
	ld c, $00
	ldh a, [hWhoseTurn]
	ld h, a
	bank1call PlayAttackAnimation
	bank1call WaitAttackAnimation

; load selected card's data
	ldh a, [hTempPlayAreaLocation_ffa1]
	ldh [hTempPlayAreaLocation_ff9d], a
	ld [wTempPlayAreaLocation_cceb], a
	add DUELVARS_ARENA_CARD
	call GetTurnDuelistVariable
	call LoadCardDataToBuffer1_FromDeckIndex

; check if car is affected
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
	call DrawWideTextBox_WaitForInput
	ret

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

; check if this devolution KO's card
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
	ret c
	ldh a, [hTempPlayAreaLocation_ff9d]
	add DUELVARS_ARENA_CARD_STAGE
	call GetTurnDuelistVariable
	or a
	jr z, .loop ; if Basic, loop
	ret

; overwrites HP and Stage data of the card that was
; devolved in the Play Area to the values of new card.
; if the damage exceeds HP of pre-evolution,
; then HP is set to zero.
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
	sub b ; subtract damage from new HP
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

; look at all card locations and move any Active Pokemon to the hand
	call SwapTurn
	ld a, DUELVARS_CARD_LOCATIONS
	call GetTurnDuelistVariable
.loop_locations
	ld a, [hl]
	cp CARD_LOCATION_ARENA
	jr nz, .next_card
	; Active Pokemon found, put in hand
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
	call SwapTurn
	ret

;
; (10) THE DAMAGE-MODIFYING ATTACK EFFECTS ARE NEXT.

; Ignores Weakness and Resistance for attack damage
NoColorEffect:
	ld hl, wDamage + 1
	set UNAFFECTED_BY_WEAKNESS_RESISTANCE_F, [hl]
	ret

NoColor_NullEffect:
	ret

HalveHPOfDefendingPokemon_AIEffect:
	call HalveHPOfDefendingPokemon
	jp SetDefiniteAIDamage

HalveHPOfDefendingPokemon:
	ld a, DUELVARS_ARENA_CARD_HP
	call GetNonTurnDuelistVariable
	srl a
	bit 0, a
	jr z, .rounded
	; round up
	add 5
.rounded
	call SetDefiniteDamage
	ret

KarateChop_AIEffect:
	jr KarateChop_DamageSubtractionEffect
	jp SetDefiniteAIDamage

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
	call SetDefiniteDamage
	ret

Flail_AIEffect:
	call Flail_HPCheck
	jp SetDefiniteAIDamage

Flail_HPCheck:
	ld e, PLAY_AREA_ARENA
	call GetCardDamageAndMaxHP
	call SetDefiniteDamage
	ret

Rage_AIEffect:
	call Rage_DamageBoostEffect
	jp SetDefiniteAIDamage

Rage_DamageBoostEffect:
	ld e, PLAY_AREA_ARENA
	call GetCardDamageAndMaxHP
	call AddToDamage
	ret

RageAndSelfConfusion50PercentEffect:
	call Rage_DamageBoostEffect
	ldtx de, IfTailsYourPokemonBecomesConfusedText
	call TossCoin_BankB
	ret c ; return if heads
	call SwapTurn
	call ConfusionEffect
	call SwapTurn
	ret

CompoundingDamageCounters_AIEffect:
	call CompoundingDamageCounters_DamageBoostEffect
	jp SetDefiniteAIDamage

CompoundingDamageCounters_DamageBoostEffect:
; add damage counters of Defending card to damage
	call SwapTurn
	ld e, PLAY_AREA_ARENA
	call GetCardDamageAndMaxHP
	call SwapTurn
	call AddToDamage
	ret

; output in de the number of energy cards attached to the Defending Pokemon times 10.
; used for attacks that deal 10x number of energy cards attached to the Defending card.
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

Psychic_AIEffect:
	call DefendingPokemonEnergy_10MoreDamageEffect
	jp SetDefiniteAIDamage

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
	; Water energy cards from calculations
	; if they pay for colorless instead.
	ld a, [wTotalAttachedEnergies]
	cp [hl]
	jr nz, .check_bonus ; skip if at least 1 non-Water energy attached

	; Water is the only energy color attached
	ld a, c
	add b
	ld b, a
	; b += c

.check_bonus
	ld a, [hl]
	sub b
	jr c, .skip_bonus ; is water energy <  b?
	jr z, .skip_bonus ; is water energy == b?

; a holds number of water energy not payed for energy cost
	cp 3
	jr c, .less_than_3
	ld a, 2 ; cap this to 2 for bonus effect
.less_than_3
	call ATimes10
	call AddToDamage ; add 10 * a to damage

.skip_bonus
	ld a, [wDamage]
	ld [wAIMinDamage], a
	ld [wAIMaxDamage], a
	ret

WWaterGunEffect:
	lb bc, 1, 0
	jp ApplyExtraWaterEnergyDamageBonus

WCWaterGunEffect:
	lb bc, 1, 1
	jr ApplyExtraWaterEnergyDamageBonus

WWCWaterGunEffect:
	lb bc, 2, 1
	jp ApplyExtraWaterEnergyDamageBonus

WWWHydroPumpEffect:
	lb bc, 3, 0
	jp ApplyExtraWaterEnergyDamageBonus

EachBenched10MoreDamageEffect:
	ld a, DUELVARS_NUMBER_OF_POKEMON_IN_PLAY_AREA
	call GetTurnDuelistVariable
	dec a ; don't count Active Pokemon
	call ATimes10
	call AddToDamage
	ret

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
	ld a, d
	cp $00 ; why check d? Card IDs are only 1 byte long
	jr nz, .next
	inc c
.next
	inc hl
	jr .loop
.done
; c holds number of Nidoking found in Play Area
	ld a, c
	add a
	call ATimes10
	call AddToDamage ; adds 2 * 10 * c
	ret

; return carry if already used attack in this duel
LeekSlap_OncePerDuelCheck:
; can only use attack if it was never used before this duel
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
	call SetDefiniteDamage
	ret
;
;Alt_NoDamage50PercentEffect:
;	ldtx de, AttackSuccessCheckText
;	call TossCoin_BankB
;	jr c, .heads
;; tails
;	xor a
;	call SetDefiniteDamage
;	call SetWasUnsuccessful
;	ret
;.heads
;	ld a, ATK_ANIM_HIT
;	ld [wLoadedAttackAnimation], a
;	ret

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

FlipFor20_AIEffect:
	ld a, 20 / 2
	lb de, 0, 20
	jp SetExpectedAIDamage

FlipFor30_AIEffect:
	ld a, 30 / 2
	lb de, 0, 30
	jp SetExpectedAIDamage

FlipFor40_AIEffect:
	ld a, 40 / 2
	lb de, 0, 40
	jp SetExpectedAIDamage

;FlipFor50_AIEffect:
;	ld a, 50 / 2
;	lb de, 0, 50
;	jp SetExpectedAIDamage
;
FlipFor60_AIEffect:
	ld a, 60 / 2
	lb de, 0, 60
	jp SetExpectedAIDamage

FlipFor70_AIEffect:
	ld a, 70 / 2
	lb de, 0, 70
	jp SetExpectedAIDamage

FlipFor80_AIEffect:
	ld a, 80 / 2
	lb de, 0, 80
	jp SetExpectedAIDamage

FlipFor120_AIEffect:
	ld a, 120 / 2
	lb de, 0, 120
	jp SetExpectedAIDamage

Flip2For10_MultiplierEffect:
	ld hl, 10
	call LoadTxRam3
	ldtx de, DamageCheckIfHeadsXDamageText
	ld a, 2
	call TossCoinATimes_BankB
	call ATimes10
	call SetDefiniteDamage
	ret

Flip3For10_MultiplierEffect:
	ld hl, 10
	call LoadTxRam3
	ldtx de, DamageCheckIfHeadsXDamageText
	ld a, 3
	call TossCoinATimes_BankB
	call ATimes10
	call SetDefiniteDamage
	ret

Flip8For10_MultiplierEffect:
	ld hl, 10
	call LoadTxRam3
	ldtx de, DamageCheckIfHeadsXDamageText
	ld a, 8
	call TossCoinATimes_BankB
	call ATimes10
	call SetDefiniteDamage
	ret

FlipXFor10_AIEffect:
	ld a, 10
	lb de, 0, 100
	jp SetExpectedAIDamage

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

Flip2For20_MultiplierEffect:
	ld hl, 20
	call LoadTxRam3
	ldtx de, DamageCheckIfHeadsXDamageText
	ld a, 2
	call TossCoinATimes_BankB
	add a ; a = 2 * heads
	call ATimes10
	call SetDefiniteDamage
	ret

Flip3For20_MultiplierEffect:
	ld hl, 20
	call LoadTxRam3
	ldtx de, DamageCheckIfHeadsXDamageText
	ld a, 3
	call TossCoinATimes_BankB
	add a
	call ATimes10
	call SetDefiniteDamage
	ret

Flip4For20_MultiplierEffect:
	ld hl, 20
	call LoadTxRam3
	ldtx de, DamageCheckIfHeadsXDamageText
	ld a, 4
	call TossCoinATimes_BankB
	add a ; a = 2 * heads
	call ATimes10
	call SetDefiniteDamage
	ret

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

; Flip coins equal to attached energies; deal 20x number of heads
FlipEachEnergyFor20_MultiplierEffect:
	ld e, PLAY_AREA_ARENA
	call GetPlayAreaCardAttachedEnergies
	ld hl, 20
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
	ld hl, 30
	call LoadTxRam3
	ldtx de, DamageCheckIfHeadsXDamageText
	ld a, 2
	call TossCoinATimes_BankB
	ld e, a
	add a ; a = 2 * heads
	add e ; a = 3 * heads
	call ATimes10
	call SetDefiniteDamage ; 3 * 10 * heads
	ret

Flip2For40_MultiplierEffect:
	ld hl, 40
	call LoadTxRam3
	ldtx de, DamageCheckIfHeadsXDamageText
	ld a, 2
	call TossCoinATimes_BankB
	add a ; a = 2 * heads
	add a
	call ATimes10
	call SetDefiniteDamage
	ret

Flip3For40SelfConfusion_MultiplierEffect:
	ld hl, 40
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
	call SwapTurn
	ret

FlipForPlus10_DamageBoostEffect:
	ld hl, 10
	call LoadTxRam3
	ldtx de, DamageCheckIfHeadsPlusDamageText
	call TossCoin_BankB
	ret nc ; return if tails
	ld a, 10
	call AddToDamage
	ret

FlipForPlus20_DamageBoostEffect:
	ld hl, 20
	call LoadTxRam3
	ldtx de, DamageCheckIfHeadsPlusDamageText
	call TossCoin_BankB
	ret nc ; return if tails
	ld a, 20
	call AddToDamage
	ret

Plus10From20_AIEffect:
	ld a, 30 / 2
	lb de, 20, 30
	jp SetExpectedAIDamage

Plus20From10_AIEffect:
	ld a, 30 / 2
	lb de, 10, 30
	jp SetExpectedAIDamage

Plus10OrRecoil_AIEffect:
	ld a, (30 + 40) / 2
	lb de, 30, 40
	jp SetExpectedAIDamage

; If heads 10 more damage; if tails, 10 damage to itself
Plus10OrRecoil_ModifierEffect:
	ldtx de, IfHeadPlus10IfTails10ToYourselfText
	call TossCoin_BankB
	ldh [hTemp_ffa0], a
	ret nc ; return if got tails
	ld a, 10
	call AddToDamage
	ret

Plus10OrRecoil_RecoilEffect:
	ldh a, [hTemp_ffa0]
	or a
	ret nz ; return if got heads
	ld a, 10
	call DealRecoilDamageToSelf
	ret

;
; (11) ATTACK EFFECTS THAT NEGATIVELY AFFECT THE PLAYER'S POKEMON ARE NEXT.

Recoil10_50PercentEffect:
	ld hl, 10
	call LoadTxRam3
	ldtx de, IfTailsDamageToYourselfTooText
	call TossCoin_BankB
	ldh [hTemp_ffa0], a
	ret

Recoil10_RecoilEffect:
	ld hl, 10
	call LoadTxRam3
	ldh a, [hTemp_ffa0]
	or a
	ret nz ; return if heads
	ld a, 10
	call DealRecoilDamageToSelf
	ret

FlipToRecoil30_50PercentEffect:
	ld hl, 30
	call LoadTxRam3
	ldtx de, IfTailsDamageToYourselfTooText
	call TossCoin_BankB
	ldh [hTemp_ffa0], a
	ret

FlipToRecoil30_RecoilEffect:
	ld hl, 30
	call LoadTxRam3
	ldh a, [hTemp_ffa0]
	or a
	ret nz ; return if heads
	ld a, 30
	call DealRecoilDamageToSelf
	ret

Recoil20Effect:
	ld a, 20
	call DealRecoilDamageToSelf
	ret

Recoil30Effect:
	ld a, 30
	call DealRecoilDamageToSelf
	ret

Recoil80Effect:
	ld a, 80
	call DealRecoilDamageToSelf
	ret

SelfConfusion_50PercentEffect:
	ldtx de, IfTailsYourPokemonBecomesConfusedText
	call TossCoin_BankB
	ret c ; return if heads
; confuse Pokemon
	ld a, ATK_ANIM_MULTIPLE_SLASH
	ld [wLoadedAttackAnimation], a
	call SwapTurn
	call ConfusionEffect
	call SwapTurn
	ret

; creates in wDuelTempList list of attached Fire Energy cards
; that are attached to the the player's Active Pokemon card.
CreateListOfFireEnergyAttachedToActive:
	ld a, TYPE_ENERGY_FIRE
	; fallthrough

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

DiscardAttachedFireEnergy_AISelection:
	call CreateListOfFireEnergyAttachedToActive
	ld a, [wDuelTempList]
	ldh [hTempList], a ; pick first in list
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
	jr c, .done
	ld hl, hCurSelectionItem
	inc [hl]
	call RemoveCardFromDuelTempList
	jr c, .done
	bank1call DisplayEnergyDiscardMenu
	jr .loop

.done
; return carry if no cards were discarded
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
	; only discard number of cards that are left in deck
	ld c, a

.start_discard
	push bc
	inc c
	jr .check_remaining

.loop
	; discard top card from deck
	call DrawCardFromDeck
	call nc, PutCardInDiscardPile
.check_remaining
	dec c
	jr nz, .loop

	pop hl
	call LoadTxRam3
	ldtx hl, DiscardedCardsFromDeckText
	call DrawWideTextBox_PrintText
	call SwapTurn
	ret

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
	ret c
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
	call VariableDiscardEffect
	ldh a, [hTempList + 1]
	call PutCardInDiscardPile
	ret

; handle input and display of Energy card list
DiscardAttachedPsychicEnergy_PlayerSelection:
	ld a, TYPE_ENERGY_PSYCHIC
	call CreateListOfEnergyAttachedToActive
	xor a ; PLAY_AREA_ARENA
	bank1call DisplayEnergyDiscardScreen
	bank1call HandleEnergyDiscardMenuInput
	ret c
	ldh a, [hTempCardIndex_ff98]
	ldh [hTemp_ffa0], a
;	or a ; this was used in Scavenge
	ret

DiscardAttachedPsychicEnergy_AISelection:
; AI picks the first energy in list
	ld a, TYPE_ENERGY_PSYCHIC
	call CreateListOfEnergyAttachedToActive
	ld a, [wDuelTempList]
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
	ret c
	call GetNextPositionInTempList
	ldh a, [hTempCardIndex_ff98]
	ld [hl], a
	ld hl, wEnergyDiscardMenuNumerator
	inc [hl]
	ldh a, [hCurSelectionItem]
	cp 2
	jr nc, .done
	ldh a, [hTempCardIndex_ff98]
	call RemoveCardFromDuelTempList
	bank1call DisplayEnergyDiscardMenu
	jr .loop_input
.done
; return when 2 have been chosen
	or a
	ret

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
	call PutCardInDiscardPile
	ret

DiscardAllAttachedEnergyEffect:
	xor a
	call CreateArenaOrBenchEnergyCardList
	ld hl, wDuelTempList
; put all energy cards in Discard Pile
.loop
	ld a, [hli]
	cp $ff
	ret z
	call PutCardInDiscardPile
	jr .loop

; deal damage to all the turn holder's Benched Pokemon
; input: a = amount of damage to deal to each Pokemon
DealDamageToAllBenchedPokemon:
	ld e, a
	ld d, $00
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

OwnBench_10DamageEffect:
	ld a, $01
	ld [wIsDamageToSelf], a
	ld a, 10
	call DealDamageToAllBenchedPokemon
	ret

DamageEitherBench_50PercentEffect:
	ldtx de, DamageToOppBenchIfHeadsDamageToYoursIfTailsText
	call TossCoin_BankB
	ldh [hTemp_ffa0], a ; store coin result
	ret

DamageEitherBench_10DamageEffect:
	ldh a, [hTemp_ffa0]
	or a
	jr nz, .opp_bench

; own bench
	ld a, $01
	ld [wIsDamageToSelf], a
	ld a, 10
	call DealDamageToAllBenchedPokemon
	ret

.opp_bench
	call SwapTurn
	ld a, 10
	call DealDamageToAllBenchedPokemon
	call SwapTurn
	ret

Selfdestruct40Effect:
	ld a, 40
	call DealRecoilDamageToSelf

; own bench
	ld a, $01
	ld [wIsDamageToSelf], a
	ld a, 10
	call DealDamageToAllBenchedPokemon
	call SwapTurn

; opponent's bench
	xor a
	ld [wIsDamageToSelf], a
	ld a, 10
	call DealDamageToAllBenchedPokemon
	call SwapTurn
	ret

Selfdestruct60Effect:
	ld a, 60
	call DealRecoilDamageToSelf
	ld a, $01
	ld [wIsDamageToSelf], a
	ld a, 10
	call DealDamageToAllBenchedPokemon
	call SwapTurn
	xor a
	ld [wIsDamageToSelf], a
	ld a, 10
	call DealDamageToAllBenchedPokemon
	call SwapTurn
	ret

Explosion80DamageEffect:
	ld a, 80
	call DealRecoilDamageToSelf
	ld a, $01
	ld [wIsDamageToSelf], a
	ld a, 20
	call DealDamageToAllBenchedPokemon
	call SwapTurn
	xor a
	ld [wIsDamageToSelf], a
	ld a, 20
	call DealDamageToAllBenchedPokemon
	call SwapTurn
	ret

Explosion100DamageEffect:
	ld a, 100
	call DealRecoilDamageToSelf

; own bench
	ld a, $01
	ld [wIsDamageToSelf], a
	ld a, 20
	call DealDamageToAllBenchedPokemon

; opponent's bench
	call SwapTurn
	xor a
	ld [wIsDamageToSelf], a
	ld a, 20
	call DealDamageToAllBenchedPokemon
	call SwapTurn
	ret

;
; (12) ATTACK EFFECTS THAT DAMAGE THE OPPONENT'S BENCH ARE NEXT.

AlsoDamageTo1Benched_PlayerSelection:
	ld a, $ff
	ldh [hTemp_ffa0], a
	ld a, DUELVARS_NUMBER_OF_POKEMON_IN_PLAY_AREA
	call GetNonTurnDuelistVariable
	cp 2
	ret c ; has no Bench Pokemon
	call DamageTo1Benched_PlayerSelection
	ret
;
;Alt_AlsoDamageTo1Benched_PlayerSelection:
;	ld a, DUELVARS_NUMBER_OF_POKEMON_IN_PLAY_AREA
;	call GetNonTurnDuelistVariable
;	cp 2
;	jr nc, .has_bench
;; no bench Pokemon to damage.
;	ld a, $ff
;	ldh [hTemp_ffa0], a
;	ret
;
;.has_bench
;; opens Play Area screen to select Benched Pokemon to damage and store it before returning
;	ldtx hl, ChoosePkmnInTheBenchToGiveDamageText
;	call DrawWideTextBox_WaitForInput
;	call SwapTurn
;	bank1call HasAlivePokemonInBench
;.loop_input
;	bank1call OpenPlayAreaScreenForSelection
;	jr c, .loop_input
;	ldh a, [hTempPlayAreaLocation_ff9d]
;	ldh [hTemp_ffa0], a
;	call SwapTurn
;	ret

AlsoDamageTo1Benched_AISelection:
	ld a, $ff
	ldh [hTemp_ffa0], a
	ld a, DUELVARS_NUMBER_OF_POKEMON_IN_PLAY_AREA
	call GetNonTurnDuelistVariable
	cp 2
	ret c ; return if no Bench Pokemon
; AI always picks Pokemon with lowest HP remaining
	call GetBenchPokemonWithLowestHP
	ldh [hTemp_ffa0], a
	ret

Also10DamageTo1Benched_DamageEffect:
	ldh a, [hTemp_ffa0]
	cp $ff
	ret z ; no target chosen
	call SwapTurn
	ld b, a
	ld de, 10
	call DealDamageToPlayAreaPokemon_RegularAnim
	call SwapTurn
	ret

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
	bank1call Func_61a1
.start
	bank1call PrintPlayAreaCardList_EnableLCD
	push af
	ld a, [wCurGigashockItem]
	ld hl, BenchSelectionMenuParameters
	call InitializeMenuParameters
	pop af

; exclude Active Pokemon from number of items
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
	call Func_3794
	jr .loop_input

.not_chosen
; mark this Play Area location
	ldh a, [hCurMenuItem]
	inc a
	ld b, SYM_LIGHTNING
	call DrawSymbolOnPlayAreaCursor
; store it in the list of chosen Bench Pokemon
	call GetNextPositionInTempList
	ldh a, [hCurMenuItem]
	inc a
	ld [hl], a

; check if 3 were chosen already
	ldh a, [hCurSelectionItem]
	ld c, a
	cp 3
	jr nc, .chosen ; check if already chose 3

	ld a, DUELVARS_NUMBER_OF_POKEMON_IN_PLAY_AREA
	call GetTurnDuelistVariable
	dec a
	cp c
	jr nz, .start ; if sill more options available, loop back
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

; returns carry if Bench Pokemon in register a was already chosen.
.CheckIfChosenAlready:
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

DrawSymbolOnPlayAreaCursor:
	ld c, a
	add a
	add c
	add 2
	; a = 3*a + 2
	ld c, a
	ld a, b
	ld b, 0
	call WriteByteToBGMap0
	ret

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

.start_selection
; has more than 3 Bench cards, proceed to sort them
; by lowest remaining HP to highest, and pick first 3.
	call SwapTurn
	dec a
	ld c, a
	ld b, PLAY_AREA_BENCH_1

; first select all of the Bench Pokemon and write to list
	ld hl, hTempList
.loop_all
	ld [hl], b
	inc hl
	inc b
	dec c
	jr nz, .loop_all
	ld [hl], $00 ; end list with $00

; then check each of the Bench Pokemon HP
; sort them from lowest remaining HP to highest.
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
	; a Bench Pokemon was found with less HP
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
	call SwapTurn
	ret

AlsoDamageTo3Benched_10DamageEffect:
	call SwapTurn
	ld hl, hTempList
.loop_selection
	ld a, [hli]
	cp $ff
	jr z, .done
	push hl
	ld b, a
	ld de, 10
	call DealDamageToPlayAreaPokemon_RegularAnim
	pop hl
	jr .loop_selection
.done
	call SwapTurn
	ret

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
	ld a, $01
	ld [wIsDamageToSelf], a
	call .DamageSameColorBench
	ret

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
	jr nz, .next_bench ; skip if not same color
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
.skip_recoil

; deal damage for Benched Pokemon that got heads
	call SwapTurn
	ld hl, hTempPlayAreaLocation_ffa1
	ld b, PLAY_AREA_BENCH_1
.loop_bench
	ld a, [hli]
	cp $ff
	jr z, .done
	or a
	jr z, .skip_damage ; skip if tails
	ld de, 20
	call DealDamageToPlayAreaPokemon_RegularAnim
.skip_damage
	inc b
	jr .loop_bench

.done
	call SwapTurn
	ret

; displays text for current Benched Pokemon, printing its Bench number and name.
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

; opens Play Area screen to select Benched Pokemon to damage and store it before returning
DamageTo1Benched_PlayerSelection:
	ldtx hl, ChoosePkmnInTheBenchToGiveDamageText
	call DrawWideTextBox_WaitForInput
	call SwapTurn
	bank1call HasAlivePokemonInBench
.loop_input
	bank1call OpenPlayAreaScreenForSelection
	jr c, .loop_input
	ldh a, [hTempPlayAreaLocation_ff9d]
	ldh [hTemp_ffa0], a
	call SwapTurn
	ret

DamageTo1Benched_AISelection:
; chooses Bench Pokemon with least amount of remaining HP
	call GetBenchPokemonWithLowestHP
	ldh [hTemp_ffa0], a
	ret

DamageTo1Benched_20DamageEffect:
	call SwapTurn
	ldh a, [hTemp_ffa0]
	ld b, a
	ld de, 20
	call DealDamageToPlayAreaPokemon_RegularAnim
	call SwapTurn
	ret

;
; (13) THE REMAINING ATTACK EFFECTS THAT UTILIZE RANDOMNESS ARE NEXT. (ALSO METRONOME AND MIRROR MOVE)

; randomly finds an occupied zone in turn player's Play Area and stores the location in a.
PickRandomPlayAreaCard:
	ld a, DUELVARS_NUMBER_OF_POKEMON_IN_PLAY_AREA
	call GetTurnDuelistVariable
	call Random
	or a
	ret

RandomEnemy20DamageEffect:
	call SwapTurn
	call PickRandomPlayAreaCard
	ld b, a
	ld a, ATK_ANIM_CAT_PUNCH_PLAY_AREA
	ld [wLoadedAttackAnimation], a
	ld de, 20
	call DealDamageToPlayAreaPokemon
	call SwapTurn
	ret

RandomEnemy30DamageEffect:
	call SwapTurn
	call PickRandomPlayAreaCard
	ld b, a
	ld de, 30
	call DealDamageToPlayAreaPokemon_RegularAnim
	call SwapTurn
	ret

; Used for EFFECTCMDTYPE_BEFORE_DAMAGE in Effect Commands, seems unneccessary
;RandomDamage_ZeroDamage:
;	xor a
;	call SetDefiniteDamage
;	ret
;
RandomEnemy40DamageEffect:
	call SwapTurn
	call PickRandomPlayAreaCard
	ld b, a
	ld de, 40
	call DealDamageToPlayAreaPokemon_RegularAnim
	call SwapTurn
	ret

Random70DamageEffect:
	call ExchangeRNG
	ld de, 70 ; damage to inflict
	call RandomlyDamagePlayAreaPokemon
	ret

; randomly damages a Pokemon in play, except card that is in [hTempPlayAreaLocation_ff9d].
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
	ld a, $01
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
	call DealDamageToPlayAreaPokemon
	ret

.opp_play_area
	xor a
	ld [wIsDamageToSelf], a
	call SwapTurn
	ld a, DUELVARS_NUMBER_OF_POKEMON_IN_PLAY_AREA
	call GetTurnDuelistVariable
	call Random
	ld b, a
	call .damage
	call SwapTurn
	ret

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
	dw .no_effect ; this will actually activate recovery effect afterwards
	dw .no_effect
	dw .more_damage
	dw .no_damage

.more_damage
	ld a, 20
	call SetDefiniteDamage
	ret

.no_damage
	ld a, ATK_ANIM_GLOW_EFFECT
	ld [wLoadedAttackAnimation], a
	xor a
	call SetDefiniteDamage
	call SetNoEffectFromStatus
.no_effect
	ret

MysteryAttack_RecoverEffect:
; in case the 5th option was chosen for random effect,
; trigger recovery effect for 10 HP.
	ldh a, [hTemp_ffa0]
	cp 4
	ret nz
	lb de, 0, 10
	call ApplyAndAnimateHPRecovery
	ret

OpponentHand_ReplacePokemonInEffect:
	call SwapTurn
	call CreateHandCardList
	call SortCardsInDuelTempListByID

; first go through Hand and place all Pokemon cards in the Deck.
	ld hl, wDuelTempList
	ld c, 0
.loop_hand
	ld a, [hl]
	cp $ff
	jr z, .done_hand
	call .CheckIfCardIsPkmnCard
	jr nc, .next_hand
	; found Pkmn card, place in deck
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

	call Func_2c0bd
	call CreateDeckCardList
	pop bc
	ldh a, [hCurSelectionItem]
	or a
	jr z, .done ; if no cards were removed from Hand, return

; c holds the number of cards that were placed in the Deck.
; now pick Pokemon from the Deck to place in Hand.
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
.done
	call SwapTurn
	ret

; returns carry if card index in a is a Pokemon
.CheckIfCardIsPkmnCard:
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

; is a card that is in the Play Area
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
; is an Energy card attached to Pokemon in Play Area
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

; divide number of Energy cards by number of Pokemon in Play Area
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
; go to next Pokemon in Play Area
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
	call Func_2c10b
	ret

MorphEffect:
	call ExchangeRNG
	call .PickRandomBasicPokemonFromDeck
	jr nc, .successful
	ldtx hl, AttackUnsuccessfulText
	call DrawWideTextBox_WaitForInput
	ret

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

; picks a random Pokemon in the Deck to morph.
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
	jr z, .set_carry
	call LoadCardDataToBuffer2_FromDeckIndex
	ld a, [wLoadedCard2Type]
	cp TYPE_ENERGY
	jr nc, .loop_deck ; skip non-Pokemon cards
	ld a, [wLoadedCard2Stage]
	or a
	jr nz, .loop_deck ; skip if not Basic
	ld a, [wLoadedCard2ID]
	cp DUELVARS_ARENA_CARD
	jr z, .loop_deck ; skip cards with same ID as the Active Pokemon
	ldh a, [hTempCardIndex_ff98]
	or a
	ret
.set_carry
	scf
	ret

; does nothing for AI.
Metronome_AISelection:
	ret

ClefableMetronome_UseAttackEffect:
	ld a, 1 ; energy cost of this attack
	call HandlePlayerMetronomeEffect
	ret

ClefairyMetronome_UseAttackEffect:
	ld a, 3 ; energy cost of this attack
;	fallthrough

; handles Metronome selection, and validates whether it can use the selected attack.
; if unsuccessful, returns carry.
; input: a = amount of colorless energy needed for Metronome
HandlePlayerMetronomeEffect:
	ld [wMetronomeEnergyCost], a
	ldtx hl, ChooseOppAttackToBeUsedWithMetronomeText
	call DrawWideTextBox_WaitForInput

	call HandleDefendingPokemonAttackSelection
	ret c ; return if operation cancelled

; store this attack as selected attack to use
	ld hl, wMetronomeSelectedAttack
	ld [hl], d
	inc hl
	ld [hl], e

; compare selected attack's name to current attack to rule out Metronome (and avoid infinite loop).
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
.set_carry
	scf
	ret

.try_use
; run the attack checks to determine whether it can be used.
	ld a, EFFECTCMDTYPE_INITIAL_EFFECT_1
	call TryExecuteEffectCommandFunction
	jr c, .failed
	ld a, EFFECTCMDTYPE_INITIAL_EFFECT_2
	call TryExecuteEffectCommandFunction
	jr c, .set_carry
	; successful

; send data to link opponent
	bank1call SendAttackDataToLinkOpponent
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
	jr z, .pick_amnesia_attack
	ret
.discard_energy
	call EnergyRemoval_AISelection
	ldh [hTemp_ffa0], a
	ret
.pick_amnesia_attack
	call AIPickAttackForAmnesia
	ldh [hTemp_ffa0], a
	ret

MirrorMove_BeforeDamage:
; if was attacked with Amnesia, apply it to the selected attack
	ld a, DUELVARS_ARENA_CARD_LAST_TURN_EFFECT
	call GetTurnDuelistVariable
	cp LAST_TURN_EFFECT_AMNESIA
	jr z, .apply_amnesia

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
; check if there was a status applied to Defending Pokemon
; from the attack it used.
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

.apply_amnesia
	call AttackDisableEffect
	ret

.ExecuteStatusEffect:
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

; execute Energy discard effect for card chosen
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
	ret z ; defending Pokemon has no weakness to change

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
	call SwapTurn
	ret

; (14) POKEMON POWER EFFECTS START HERE.
; 12/26 POWERS ARE ACTUALLY HANDLED ELSEWHERE (They are paired with NoEffect_SetCarry)

; returns carry if Pokemon Power can't be used.
OncePerTurnPokePowerCheck:
	ldh a, [hTempPlayAreaLocation_ff9d]
	ldh [hTemp_ffa0], a
	add DUELVARS_ARENA_CARD_FLAGS
	call GetTurnDuelistVariable
	and USED_PKMN_POWER_THIS_TURN
	jr nz, .already_used
	ldh a, [hTempPlayAreaLocation_ff9d]
	call CheckCannotUseDueToStatus_OnlyToxicGasIfANon0
	ret
.already_used
	ldtx hl, OnlyOncePerTurnText
	scf
	ret

NoEffect_SetCarry:
	scf
	ret

PlayAreaSelectionMenuParameters:
	db 0, 0 ; cursor x, cursor y
	db 3 ; y displacement between items
	db MAX_PLAY_AREA_POKEMON ; number of items
	db SYM_CURSOR_R ; cursor tile number
	db SYM_SPACE ; tile behind cursor
	dw NULL ; function pointer if non-0

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
	bank1call Func_61a1
	bank1call PrintPlayAreaCardList_EnableLCD
	ret

.player
	xor a
	ldh [hCurSelectionItem], a
	bank1call Func_61a1

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
	jr c, .play_sfx ; no Grass attached

	ldh [hAIEnergyTransEnergyCard], a
	ldh a, [hAIEnergyTransEnergyCard] ; useless
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
	call Func_3794
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

SolarPowerCheck:
	ldh a, [hTempPlayAreaLocation_ff9d]
	ldh [hTemp_ffa0], a
	add DUELVARS_ARENA_CARD_FLAGS
	call GetTurnDuelistVariable
	and USED_PKMN_POWER_THIS_TURN
	jr nz, .already_used

	ldh a, [hTempPlayAreaLocation_ff9d]
	call CheckCannotUseDueToStatus_OnlyToxicGasIfANon0
	ret c ; can't use power due to status or Toxic Gas

; returns carry if no Active Pokemon are affected by special conditions
	ld a, DUELVARS_ARENA_CARD_STATUS
	call GetTurnDuelistVariable
	or a
	jr nz, .has_status
	ld a, DUELVARS_ARENA_CARD_STATUS
	call GetNonTurnDuelistVariable
	or a
	jr z, .no_status
.has_status
	or a
	ret
.already_used
	ldtx hl, OnlyOncePerTurnText
	scf
	ret
.no_status
	ldtx hl, NotAffectedByPoisonSleepParalysisOrConfusionText
	scf
	ret

SolarPower_RemoveStatusEffect:
	ld a, ATK_ANIM_HEAL_BOTH_SIDES
	ld [wLoadedAttackAnimation], a
	bank1call Func_7415
	ldh a, [hTempPlayAreaLocation_ff9d]
	ld b, a
	ld c, $00
	ldh a, [hWhoseTurn]
	ld h, a
	bank1call PlayAttackAnimation
	bank1call WaitAttackAnimation

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

HealCheck:
	ldh a, [hTempPlayAreaLocation_ff9d]
	ldh [hTemp_ffa0], a
	add DUELVARS_ARENA_CARD_FLAGS
	call GetTurnDuelistVariable
	and USED_PKMN_POWER_THIS_TURN
	jr nz, .already_used

	call PlayAreaDamageCheck
	ldtx hl, NoPokemonWithDamageCountersText
	ret c ; no damage counters to heal

	ldh a, [hTempPlayAreaLocation_ff9d]
	call CheckCannotUseDueToStatus_OnlyToxicGasIfANon0
	ret

.already_used
	ldtx hl, OnlyOncePerTurnText
	scf
	ret

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
	jr c, .loop_input
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
; flag Pkmn Power as being used regardless of coin outcome
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
	call ExchangeRNG
	ret

Shift_PlayerSelection:
	ldtx hl, ChoosePokemonToCopyWithShiftText
	ldh a, [hTemp_ffa0]
	or $80
	call HandleColorChangeScreen
	ldh [hAIPkmnPowerEffectParam], a
	ret c ; cancelled

; check whether the selected color is valid
	; look in Turn Duelist's Play Area
	call .CheckColorInPlayArea
	ret nc
	; look in NonTurn Duelist's Play Area
	call SwapTurn
	call .CheckColorInPlayArea
	call SwapTurn
	ret nc
	; not found in either Duelist's Play Area
	ldtx hl, UnableToSelectText
	call DrawWideTextBox_WaitForInput
	jr Shift_PlayerSelection ; loop back to start

; checks if input color in a exists in Turn Duelist's Play Area, no returns carry.
.CheckColorInPlayArea:
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
	call DrawWideTextBox_WaitForInput
	ret


; returns carry if Pokemon Power cannot be used
; or if the Active Pokemon is not Charizard
;EnergyBurnCheck_Unreferenced:
;	xor a
;	bank1call CheckCannotUseDueToStatus_OnlyToxicGasIfANon0
;	ret c
;	ld a, DUELVARS_ARENA_CARD
;	push de
;	call GetTurnDuelistVariable
;	call GetCardIDFromDeckIndex
;	ld a, e
;	pop de
;	cp CHARIZARD
;	jr nz, .not_charizard
;	or a
;	ret
;.not_charizard
;	scf
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
	call Func_2c0bd
	ret

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
; load correct attack animation depending
; on what side the effect is from.
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
	bank1call WaitAttackAnimation

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
; update and print number of cards in hand
	ld a, DUELVARS_NUMBER_OF_CARDS_IN_HAND
	call GetTurnDuelistVariable
	inc a
	bank1call WriteTwoDigitNumberInTxSymbolFormat
; update and print number of cards in deck
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
	call Func_2c0bd
	ret

; returns carry if can't use Cowardice
CowardiceCheck:
	ldh a, [hTempPlayAreaLocation_ff9d]
	ldh [hTemp_ffa0], a
	call CheckCannotUseDueToStatus_OnlyToxicGasIfANon0
	ret c ; return if cannot use

	ld a, DUELVARS_NUMBER_OF_POKEMON_IN_PLAY_AREA
	call GetTurnDuelistVariable
	ldtx hl, YouNoBenchedPokemonText
	cp 2
	ret c ; return if no bench

	ldh a, [hTempPlayAreaLocation_ff9d]
	add DUELVARS_ARENA_CARD_FLAGS
	call GetTurnDuelistVariable
	ldtx hl, CannotBeUsedInTurnWhichWasPlayedText
	and CAN_EVOLVE_THIS_TURN
	scf
	ret z ; return if was played this turn

	or a
	ret

Cowardice_PlayerSelection:
	ldh a, [hTemp_ffa0]
	or a
	ret nz ; return if not Arena card
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

; put card in Discard Pile temporarily, so that
; all cards attached are discarded as well.
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
; add card to hand and adjust Play Area
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
	bank1call PrintFailedEffectText
	call WaitForWideTextBoxInput
	ret

.heads
	call ParalysisEffect
	ldh a, [hTempPlayAreaLocation_ff9d]
	ld b, a
	ld c, $00
	ldh a, [hWhoseTurn]
	ld h, a
	bank1call PlayAttackAnimation
	bank1call PlayStatusConditionQueueAnimations
	bank1call WaitAttackAnimation
	bank1call ApplyStatusConditionQueue
	bank1call DrawDuelHUDs
	bank1call PrintFailedEffectText
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
	jr .prize_or_deck

.hand
; AI chose to look at random card in hand,
; so display it to the Player on screen.
	call SwapTurn
	ldtx hl, PeekWasUsedToLookInYourHandText
	bank1call DisplayCardDetailScreen
	call SwapTurn
	ret

.prize_or_deck
; AI chose either a prize card or Player's top deck card,
; so show Play Area and draw cursor appropriately.
	call FinishQueuedAnimations
	call SwapTurn
	ldh a, [hAIPkmnPowerEffectParam]
	xor $80
	call DrawAIPeekScreen
	call SwapTurn
	ldtx hl, CardPeekWasUsedOnText
	call DrawWideTextBox_WaitForInput
	ret

; returns carry if Damage Swap cannot be used.
DamageSwapCheck:
	ldh a, [hTempPlayAreaLocation_ff9d]
	ldh [hTemp_ffa0], a
	call PlayAreaDamageCheck
	jr c, .no_damage
	ldh a, [hTempPlayAreaLocation_ff9d]
	call CheckCannotUseDueToStatus_OnlyToxicGasIfANon0
	ret
.no_damage
	ldtx hl, NoPokemonWithDamageCountersText
	scf
	ret

DamageSwap_SelectAndSwapEffect:
	ld a, DUELVARS_DUELIST_TYPE
	call GetTurnDuelistVariable
	cp DUELIST_TYPE_PLAYER
	jr z, .player
; non-player
	bank1call Func_61a1
	bank1call PrintPlayAreaCardList_EnableLCD
	ret

.player
	ldtx hl, ProcedureForDamageSwapText
	bank1call DrawWholeScreenTextBox
	xor a
	ldh [hCurSelectionItem], a
	bank1call Func_61a1

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

; if card has no damage, play sfx and return to start
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
	ld b, SYM_HP_NOK
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

; try to give the card selected the damage counter
; if it would KO, ignore it.
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
	call Func_3794
	jr .loop_input_first

; tries to give damage counter to hPlayAreaEffectTarget,
; and if successful updates UI screen.
DamageSwap_SwapEffect:
	ldh a, [hPlayAreaEffectTarget]
	call TryGiveDamageCounter
	ret c
	bank1call PrintPlayAreaCardList_EnableLCD
	or a
	ret

; tries to give the damage counter to the target
; chosen by the Player (hPlayAreaEffectTarget).
; returns carry if the damage counter would KO the Pokemon
TryGiveDamageCounter:
	add DUELVARS_ARENA_CARD_HP
	call GetTurnDuelistVariable
	sub 10
	jr z, .set_carry ; would bring HP to zero?
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
.set_carry
	scf
	ret

; returns carry if Strange Behavior cannot be used.
StrangeBehaviorCheck:
; does Play Area have any damage counters?
	ldh a, [hTempPlayAreaLocation_ff9d]
	ldh [hTemp_ffa0], a
	call PlayAreaDamageCheck
	ldtx hl, NoPokemonWithDamageCountersText
	jr c, .set_carry
; can Slowbro receive any damage counters without KO-ing?
	ldh a, [hTempPlayAreaLocation_ff9d]
	add DUELVARS_ARENA_CARD_HP
	call GetTurnDuelistVariable
	ldtx hl, CannotUseBecauseItWillBeKnockedOutText
	cp 10 + 10
	jr c, .set_carry
; can Pokemon Power be used?
	ldh a, [hTempPlayAreaLocation_ff9d]
	call CheckCannotUseDueToStatus_OnlyToxicGasIfANon0
	ret

.set_carry
	scf
	ret

StrangeBehavior_SelectAndSwapEffect:
	ld a, DUELVARS_DUELIST_TYPE
	call GetTurnDuelistVariable
	cp DUELIST_TYPE_PLAYER
	jr z, .player

; not player
	bank1call Func_61a1
	bank1call PrintPlayAreaCardList_EnableLCD
	ret

.player
	ldtx hl, ProcedureForStrangeBehaviorText
	bank1call DrawWholeScreenTextBox

	xor a
	ldh [hCurSelectionItem], a
	bank1call Func_61a1
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
	jr z, .play_sfx ; can't select card without damage

	ldh a, [hTemp_ffa0]
	call TryGiveDamageCounter
	jr c, .play_sfx
	ld a, OPPACTION_6B15
	call SetOppAction_SerialSendDuelData
	jr .start

.play_sfx
	call Func_3794
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
	ldh a, [hTempPlayAreaLocation_ff9d]
	ldh [hTemp_ffa0], a

; fails if power has already been used
	add DUELVARS_ARENA_CARD_FLAGS
	call GetTurnDuelistVariable
	ldtx hl, OnlyOncePerTurnText
	and USED_PKMN_POWER_THIS_TURN
	jr nz, .set_carry

; fails if opponent only has 1 Pokemon
	call SwapTurn
	ld a, DUELVARS_NUMBER_OF_POKEMON_IN_PLAY_AREA
	call GetTurnDuelistVariable
	call SwapTurn
	ldtx hl, CannotUseSinceTheresOnly1PkmnText
	cp 2
	jr c, .set_carry

; fails if opponent's Pokemon have no damage counters
	call SwapTurn
	call PlayAreaDamageCheck
	call SwapTurn
	ldtx hl, NoPokemonWithDamageCountersText
	jr c, .set_carry

; return carry if power cannot be used due to Toxic Gas or status.
	ldh a, [hTempPlayAreaLocation_ff9d]
	call CheckCannotUseDueToStatus_OnlyToxicGasIfANon0
	ret

.set_carry
	scf
	ret

Curse_PlayerSelection:
	ldtx hl, ProcedureForCurseText
	bank1call DrawWholeScreenTextBox
	call SwapTurn
	xor a
	ldh [hCurSelectionItem], a
	bank1call Func_61a1
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
	call Func_3794
	jr .loop_input_first

.picked_first
; give 10 HP to card selected, draw the scene,
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
	ld b, SYM_HP_NOK
	call DrawSymbolOnPlayAreaCursor

; handle input to pick the target to receive the damage counter.
.loop_input_second
	call DoFrame
	call HandleMenuInput
	jr nc, .loop_input_second
	ldh [hPlayAreaEffectTarget], a
	cp $ff
	jr nz, .a_press ; was a pressed?

; b press erases the damage counter symbol
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

.cancel
; return carry if operation was cancelled.
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
	bank1call Func_61a1
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
	jr z, .set_carry

	add DUELVARS_ARENA_CARD_FLAGS
	call GetTurnDuelistVariable
	ldtx hl, OnlyOncePerTurnText
	and USED_PKMN_POWER_THIS_TURN
	jr nz, .set_carry

	ldh a, [hTempPlayAreaLocation_ff9d]
	call CheckCannotUseDueToStatus_OnlyToxicGasIfANon0
	ret

.set_carry
	scf
	ret

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
	bank1call WaitAttackAnimation
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
	bank1call WaitAttackAnimation
.next_pkmn
	pop de
	inc e
	dec d
	jr nz, .loop_play_area
	ret

;
; (15) TRAINER CARD EFFECTS ARE NEXT. (Bill/Energy Search/Gust of Wind/Pokedex are sorted with attacks effects)

; handles screen for Player to select 2 cards from the hand to discard.
; first prints text informing Player to choose cards to discard
; then runs HandlePlayerSelection2HandCards routine.
Discard2Cards_PlayerSelection:
	ldtx hl, Choose2CardsFromHandToDiscardText
	ldtx de, ChooseTheCardToDiscardText
;	fallthrough

; handles screen for Player to select 2 cards from the hand
; to activate some Trainer card effect.
; assumes Trainer card index being used is in [hTempCardIndex_ff9f].
; stores selection of cards in hTempList.
; returns carry if Player cancels operation.
; input:
;	hl = text to print in text box;
;	de = text to print in screen header.
HandlePlayerSelection2HandCards:
	push de
	call DrawWideTextBox_WaitForInput

; remove the Trainer card being used from list of cards to select from hand.
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
	bank1call SetCardListInfoBoxText
	push hl
	bank1call DisplayCardList
	pop hl
	jr c, .set_carry ; was B pressed?
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
.set_carry
	scf
	ret

; heals amount of damage in register e for card in
; Play Area location in [hTempPlayAreaLocation_ff9d].
; plays healing animation and prints text with card's name.
; input:
;	e = amount of HP to heal
;	[hTempPlayAreaLocation_ff9d] = Play Area location of card to heal
HealPlayAreaCardHP:
	ld e, a
	ld d, $00

; play heal animation
	push de
	bank1call Func_7415
	ld a, ATK_ANIM_HEALING_WIND_PLAY_AREA
	ld [wLoadedAttackAnimation], a
	ldh a, [hTempPlayAreaLocation_ff9d]
	ld b, a
	ld c, $01
	ldh a, [hWhoseTurn]
	ld h, a
	bank1call PlayAttackAnimation
	bank1call WaitAttackAnimation
	pop hl

; print Pokemon card name and damage healed
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

PlayThisAsBasicPokemonEffect:
	ldh a, [hTempCardIndex_ff9f]
	call PutHandPokemonCardInPlayArea
	ret

; returns carry if no Benched Pokemon
TrainerCardAsPokemon_BenchCheck:
	ldh a, [hTempPlayAreaLocation_ff9d]
	ldh [hTemp_ffa0], a
	call BenchedPokemonCheck
	ret

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
	jr nz, .shift_cards
	ldh a, [hTempPlayAreaLocation_ffa1]
	ld e, a
	call SwapArenaWithBenchPokemon
.shift_cards
	call ShiftAllPokemonToFirstPlayAreaSlots
	ret

; returns carry if not enough cards in hand to discard
; or if there are no cards left in the deck.
ComputerSearchCheck:
	call OtherCardsInHandCheck
	ret c
	call DeckCheck
	ret

ComputerSearch_PlayerDeckSelection:
	call CreateDeckCardList
	bank1call Func_5591
	ldtx hl, ChooseCardToPlaceInHandText
	ldtx de, DuelistDeckText
	bank1call SetCardListHeaderText
.loop_input
	bank1call DisplayCardList
	jr c, .loop_input ; can't exit with B button
	ldh [hTempList + 2], a
	ret

ComputerSearch_DiscardAddToHandEffect:
; discard cards from hand
	ld hl, hTempList
	ld a, [hli]
	call RemoveCardFromHand
	call PutCardInDiscardPile
	ld a, [hli]
	call RemoveCardFromHand
	call PutCardInDiscardPile

; add card from deck to hand
	ld a, [hl]
	call SearchCardInDeckAndAddToHand
	call AddCardToHand
	call Func_2c0bd
	ret

Defender_PlayerSelection:
	ldtx hl, ChoosePokemonToAttachDefenderToText
	call DrawWideTextBox_WaitForInput
	bank1call HasAlivePokemonInPlayArea
	bank1call OpenPlayAreaScreenForSelection
	ldh a, [hTempPlayAreaLocation_ff9d]
	ldh [hTemp_ffa0], a
	ret

Defender_AttachDefenderEffect:
; attach Trainer card to Play Area Pokemon
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
	call Func_2c10b
	ret

; returns carry if player has no Evolution cards in Play Area
EvolvedPokemonCheck:
	ld a, DUELVARS_NUMBER_OF_POKEMON_IN_PLAY_AREA
	call GetTurnDuelistVariable
	ld c, a
	ld l, DUELVARS_ARENA_CARD
.loop
	ld a, [hli]
	call LoadCardDataToBuffer2_FromDeckIndex
	ld a, [wLoadedCard2Stage]
	or a
	ret nz ; found an Evolution card
	dec c
	jr nz, .loop

	ldtx hl, NoEvolvedPokemonText
	scf
	ret

DevolutionSpray_PlayerSelection:
; display textbox
	ldtx hl, ChooseEvolutionCardAndPressAButtonToDevolveText
	call DrawWideTextBox_WaitForInput

; have Player select an Evolution card in Play Area
	ld a, 1
	ldh [hCurSelectionItem], a
	bank1call HasAlivePokemonInPlayArea
.read_input
	bank1call OpenPlayAreaScreenForSelection
	ret c ; exit if B was pressed
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
; show Play Area screen with static cursor
; so that the Player either presses A to do one more devolution
; or presses B to finish selection.
	bank1call Func_6194
	jr c, .done_selection ; if B pressed, end selection instead
	; do one more devolution
	bank1call GetCardOneStageBelow

.update_data
; overwrite the card data to new devolved stats
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

; store this Play Area location in first item of temp list
	ldh a, [hTempPlayAreaLocation_ff9d]
	ldh [hTempList], a

; update Play Area location display of this Pokemon
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
; this is so that if "No" is selected in confirmation menu,
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
; first byte in list is Play Area location chosen
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
	; devolve card to its stage below
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

; returns carry if opponent has no energy cards attached
EnergyRemovalCheck:
	call SwapTurn
	call PlayAreaAttachedEnergyCheck
	ldtx hl, NoEnergyCardsAttachedToPokemonInOppPlayAreaText
	call SwapTurn
	ret

EnergyRemoval_PlayerSelection:
	ldtx hl, ChoosePokemonToRemoveEnergyFromText
	call DrawWideTextBox_WaitForInput
	call SwapTurn
	call HandlePokemonAndEnergySelectionScreen
	call SwapTurn
	ret

; returns in a the card index of the Energy card attached to Defending Pokemon
; that is to be discarded by the AI for an effect.
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
	; no energy, return
	ld a, $ff
	jr .done

.has_energy
	ld a, DUELVARS_ARENA_CARD
	call GetTurnDuelistVariable
	call LoadCardDataToBuffer1_FromDeckIndex
	ld e, COLORLESS
	ld a, [wAttachedEnergies + COLORLESS]
	or a
	jr nz, .pick_color ; has colorless attached?

	; no colorless energy attached.
	; if it's colorless Pokemon, just
	; pick any energy card at random...
	ld a, [wLoadedCard1Type]
	cp COLORLESS
	jr nc, .choose_random

	; ...if not, check if it has its
	; own color energy attached.
	; if it doesn't, pick at random.
	ld e, a
	ld d, $00
	ld hl, wAttachedEnergies
	add hl, de
	ld a, [hl]
	or a
	jr z, .choose_random

; pick attached card with same color as e
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
.done
	call SwapTurn
	ret

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
	call SwapTurn
	ret

; returns carry if neither duelist has any attached Energy cards
SuperEnergyRemoval_EnergyCheck:
	call PlayAreaAttachedEnergyCheck
	ldtx hl, NoEnergyCardsAttachedToPokemonInYourPlayAreaText
	ret c
	call SwapTurn
	call PlayAreaAttachedEnergyCheck
	ldtx hl, NoEnergyCardsAttachedToPokemonInOppPlayAreaText
	call SwapTurn
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
	jr nc, .opp_pkmn_selected
	; B was pressed
	call SwapTurn
	ret ; return if operation was cancelled
.opp_pkmn_selected
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
	bank1call CreateArenaOrBenchEnergyCardList
	ldh a, [hTempPlayAreaLocation_ff9d]
	bank1call DisplayEnergyDiscardScreen
	ld a, 2
	ld [wEnergyDiscardMenuDenominator], a

.loop_discard_energy_selection
	bank1call HandleEnergyDiscardMenuInput
	jr nc, .energy_selected
	; B pressed
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
; store energy cards to discard from opponent
	call GetNextPositionInTempList
	ldh a, [hTempCardIndex_ff98]
	ld [hl], a
	call RemoveCardFromDuelTempList
	ld hl, wEnergyDiscardMenuNumerator
	inc [hl]
	ldh a, [hCurSelectionItem]
	cp 5
	jr nc, .done ; no more energy cards to select
	ld a, [wDuelTempList]
	cp $ff
	jr z, .done ; no more energy cards to select
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

; discard energy card of own Play Area
	ld a, [hli]
	call PutCardInDiscardPile

; iterate and discard opponent's energy cards
	inc hl
	call SwapTurn
.loop
	ld a, [hli]
	cp $ff
	jr z, .done_discard
	call PutCardInDiscardPile
	jr .loop

.done_discard
; if it's Player's turn, return...
	call SwapTurn
	call IsPlayerTurn
	ret c
; ...otherwise show Play Area of affected Pokemon
; in opponent's Play Area
	ldh a, [hTemp_ffa0]
	call Func_2c10b
; in player's Play Area
	xor a
	ld [wDuelDisplayedScreen], a
	call SwapTurn
	ldh a, [hPlayAreaEffectTarget]
	call Func_2c10b
	call SwapTurn
	ret

; returns carry if no other card in hand to discard
; or if there are no Basic Energy cards in Discard Pile.
EnergyRetrievalCheck:
	ld a, DUELVARS_NUMBER_OF_CARDS_IN_HAND
	call GetTurnDuelistVariable
	cp 2
	ldtx hl, NotEnoughCardsInHandText
	ret c ; return if doesn't have another card to discard
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
	ld a, 1 ; start at 1 due to card selected from hand
	ldh [hCurSelectionItem], a
	ldtx hl, Choose2BasicEnergyCardsFromDiscardPileText
	call DrawWideTextBox_WaitForInput
	call CreateEnergyCardListFromDiscardPile_OnlyBasic

.select_card
	bank1call InitAndDrawCardListScreenLayout
	ldtx hl, PleaseSelectCardText
	ldtx de, YourDiscardPileText
	bank1call SetCardListHeaderText
	bank1call DisplayCardList
	jr nc, .selected
	; B was pressed
	ld a, 2 + 1 ; includes the card selected from hand
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
	cp 2 + 1 ; includes the card selected from hand
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
	bank1call Func_4b38
	ret

; returns carry if not enough cards in hand to discard
; or if the Discard Pile has no basic Energy cards
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
	bank1call SetCardListHeaderText
	bank1call DisplayCardList
	jr nc, .store_selected_card
	; B pressed
	ld a, 6
	call AskWhetherToQuitSelectingCards
	jr c, .loop_discard_pile_selection ; player selected to continue
	jr .done

.store_selected_card
	ldh a, [hTempCardIndex_ff98]
	call GetTurnDuelistVariable
	call GetNextPositionInTempList
	ldh a, [hTempCardIndex_ff98]
	ld [hl], a ; store selected energy card
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

; put selected cards in hand
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
; if not, show card list selected by Opponent
	bank1call Func_4b38
	ret

GamblerEffect:
	ldtx de, CardCheckIfHeads8CardsIfTails1CardText
	call TossCoin_BankB
	ldh [hTemp_ffa0], a
; discard Gambler card from hand
	ldh a, [hTempCardIndex_ff9f]
	call RemoveCardFromHand
	call PutCardInDiscardPile

; shuffle cards into deck
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
	call Func_2c0bd
	ld c, 8
	ldh a, [hTemp_ffa0]
	or a
	jr nz, .draw_cards ; coin toss was heads?
	; if tails, number of cards to draw is 1
	ld c, 1

; correct number of cards to draw is in c
.draw_cards
	ld a, c
	bank1call DisplayDrawNCardsScreen
.draw_loop
	call DrawCardFromDeck
	jr c, .done
	call AddCardToHand
	dec c
	jr nz, .draw_loop
.done
	ret

; returns carry if not enough cards in hand to discard
; or if there are no cards in the Discard Pile
ItemFinderCheck:
	call OtherCardsInHandCheck
	ret c
	call CreateTrainerCardListFromDiscardPile
	ret

ItemFinder_PlayerSelection:
	call Discard2Cards_PlayerSelection
	ret c ; was operation cancelled?

; cards were selected to discard from hand.
; now to choose a Trainer card from Discard Pile.
	call CreateTrainerCardListFromDiscardPile
	bank1call Func_5591
	ldtx hl, ChooseCardToPlaceInHandText
	ldtx de, YourDiscardPileText
	bank1call SetCardListHeaderText
	bank1call DisplayCardList
	ldh [hTempList + 2], a ; placed after the 2 cards selected to discard
	ret

ItemFinder_DiscardAddToHandEffect:
; discard cards from hand
	ld hl, hTempList
	ld a, [hli]
	call RemoveCardFromHand
	call PutCardInDiscardPile
	ld a, [hli]
	call RemoveCardFromHand
	call PutCardInDiscardPile

; place card from Discard Pile to hand
	ld a, [hl]
	call MoveDiscardPileCardToHand
	call AddCardToHand
	call IsPlayerTurn
	ret c
; display card in screen
	ldh a, [hTempList + 2]
	ldtx hl, WasPlacedInTheHandText
	bank1call DisplayCardDetailScreen
	ret

ImakuniEffect:
	ld a, DUELVARS_ARENA_CARD
	call GetTurnDuelistVariable
	call LoadCardDataToBuffer1_FromDeckIndex
	ld a, [wLoadedCard1ID]

; cannot confuse Clefairy Doll and Mysterious Fossil
	cp CLEFAIRY_DOLL
	jr z, .failed
	cp MYSTERIOUS_FOSSIL
	jr z, .failed

; cannot confuse Snorlax if its Pokemon Power is active
	cp SNORLAX
	jr nz, .success
	xor a
	call CheckCannotUseDueToStatus_OnlyToxicGasIfANon0
	jr c, .success
	; fallthrough if Thick Skinned is active

.failed
; play confusion animation and print failure text
	ld a, ATK_ANIM_OWN_CONFUSION
	call Func_2fea9
	ldtx hl, ThereWasNoEffectText
	call DrawWideTextBox_WaitForInput
	ret

.success
; play confusion animation and confuse card
	ld a, ATK_ANIM_OWN_CONFUSION
	call Func_2fea9
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

; first return all cards in hand to the deck.
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
	call Func_2c0bd
	ld a, 7
	bank1call DisplayDrawNCardsScreen
	ld c, 7
.loop_draw
	call DrawCardFromDeck
	jr c, .done
	call AddCardToHand
	dec c
	jr nz, .loop_draw
.done
	call SwapTurn
	ret

LassEffect:
; first discard Lass card that was used
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
	; do for Turn Duelist
;	fallthrough

.ShuffleDuelistHandTrainerCardsInDeck
	call CreateHandCardList
	call SortCardsInDuelTempListByID
	xor a
	ldh [hCurSelectionItem], a
	ld hl, wDuelTempList

; go through all cards in hand and any Trainer card is returned to deck.
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
	call nz, Func_2c0bd ; only show list if there were any Trainer cards
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
	call SwapTurn
	ret

.DisplayOppHand
	call CreateHandCardList
	jr c, .no_cards
	bank1call InitAndDrawCardListScreenLayout
	ldtx hl, ChooseTheCardYouWishToExamineText
	ldtx de, DuelistHandText
	bank1call SetCardListHeaderText
	ld a, A_BUTTON | START
	ld [wNoItemSelectionMenuKeys], a
	bank1call DisplayCardList
	ret
.no_cards
	ldtx hl, DuelistHasNoCardsInHandText
	call DrawWideTextBox_WaitForInput
	ret

Maintenance_PlayerSelection:
	ldtx hl, Choose2HandCardsFromHandToReturnToDeckText
	ldtx de, ChooseTheCardToPutBackText
	call HandlePlayerSelection2HandCards
	ret

Maintenance_ReturnToDeckAndDrawEffect:
; return both selected cards to the deck
	ldh a, [hTempList]
	call RemoveCardFromHand
	call ReturnCardToDeck
	ldh a, [hTempList + 1]
	call RemoveCardFromHand
	call ReturnCardToDeck
	call Func_2c0bd

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

MrFuji_PlayerSelection:
	ldtx hl, ChoosePokemonToReturnToTheDeckText
	call DrawWideTextBox_WaitForInput
	bank1call HasAlivePokemonInBench
	bank1call OpenPlayAreaScreenForSelection
	ldh a, [hTempPlayAreaLocation_ff9d]
	ldh [hTemp_ffa0], a
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

; clear Play Area location of card
	ldh a, [hTemp_ffa0]
	ld e, a
	call EmptyPlayAreaSlot
	ld l, DUELVARS_NUMBER_OF_POKEMON_IN_PLAY_AREA
	dec [hl]
	call ShiftAllPokemonToFirstPlayAreaSlots

; if Trainer card wasn't played by the Player,
; print the selected Pokemon's name and show card on screen.
	call IsPlayerTurn
	jr c, .done
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
.done
	call Func_2c0bd
	ret

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
	call Func_2c08a
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
	jr z, .done ; skip if no Pokemon was chosen

; add Pokemon card to hand and show in screen if
; it wasn't the Player who played the Trainer card.
	call SearchCardInDeckAndAddToHand
	call AddCardToHand
	call IsPlayerTurn
	jr c, .done
	ldh a, [hTempList + 1]
	ldtx hl, WasPlacedInTheHandText
	bank1call DisplayCardDetailScreen
.done
	call Func_2c0bd
	ret

PokemonBreederCheck:
	call CreatePlayableStage2PokemonCardListFromHand
	jr c, .cannot_evolve
	bank1call IsPrehistoricPowerActive
	ret
.cannot_evolve
	ldtx hl, ConditionsForEvolvingToStage2NotFulfilledText
	scf
	ret

PokemonBreeder_PlayerSelection:
; create hand list of playable Stage2 cards
	call CreatePlayableStage2PokemonCardListFromHand
	bank1call Func_5591

; handle Player selection of Stage2 card
	ldtx hl, PleaseSelectCardText
	ldtx de, DuelistHandText
	bank1call SetCardListHeaderText
	bank1call DisplayCardList
	ret c ; exit if B was pressed

	ldh a, [hTempCardIndex_ff98]
	ldh [hTemp_ffa0], a
	ldtx hl, ChooseBasicPokemonToEvolveText
	call DrawWideTextBox_WaitForInput

; handle Player selection of Basic card to evolve
	bank1call HasAlivePokemonInPlayArea
.read_input
	bank1call OpenPlayAreaScreenForSelection
	ret c ; exit if B was pressed
	ldh a, [hTempPlayAreaLocation_ff9d]
	ldh [hTempPlayAreaLocation_ffa1], a
	ld e, a
	ldh a, [hTemp_ffa0]
	ld d, a
	call CheckIfCanEvolveInto_BasicToStage2
	jr c, .read_input ; loop back if cannot evolve this card
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

; load the Basic Pokemon card name to RAM
	add DUELVARS_ARENA_CARD
	call GetTurnDuelistVariable
	call LoadCardDataToBuffer1_FromDeckIndex
	ld hl, wLoadedCard1Name
	ld a, [hli]
	ld h, [hl]
	ld l, a
	call LoadTxRam2

; evolve card and overwrite its stage as STAGE2_WITHOUT_STAGE1
	ldh a, [hTempCardIndex_ff98]
	call EvolvePokemonCard
	ld [hl], STAGE2_WITHOUT_STAGE1

; load Stage2 Pokemon card name to RAM
	ldh a, [hTempCardIndex_ff98]
	call LoadCardDataToBuffer1_FromDeckIndex
	ld a, 18
	call CopyCardNameAndLevel
	xor a
	ld [hl], a ; $0 character
	ld hl, wTxRam2_b
	ld [hli], a
	ld [hl], a

; display Pokemon picture and play sfx and print the corresponding card names.
	bank1call DrawLargePictureOfCard
	ld a, SFX_5E
	call PlaySFX
	ldtx hl, PokemonEvolvedIntoPokemonText
	call DrawWideTextBox_WaitForInput
	bank1call ProcessPlayedPokemonCard
	pop af
	ldh [hTempCardIndex_ff9f], a
	ret

; creates list in wDuelTempList of all Stage2 Pokemon cards
; in the hand that can evolve a Basic Pokemon card in Play Area.
; returns carry if that list is empty.
CreatePlayableStage2PokemonCardListFromHand:
	call CreateHandCardList
	ret c ; return if no hand cards

; check if hand Stage2 Pokemon cards can be made
; to evolve a Basic Pokemon in the Play Area and,
; if so, add it to the wDuelTempList.
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
	ret z ; return carry if empty
	; not empty
	or a
	ret

; returns carry if Stage2 card in a cannot evolve any
; of the Basic Pokemon in Play Area through Pokemon Breeder.
.CheckIfCanEvolveAnyPlayAreaBasicCard
	push de
	ld d, a
	call LoadCardDataToBuffer2_FromDeckIndex
	ld a, [wLoadedCard2Type]
	cp TYPE_ENERGY
	jr nc, .set_carry ; skip if not Pokemon card
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

; check if the player's Pokemon card at e can evolve this turn, and is a Basic
; Pokemon card whose Stage2 evolution is in the player's hand.
; e is the play area location offset (PLAY_AREA_*) of the Pokemon trying to evolve.
; d is the deck index (0-59) of the Pokemon that was selected to be the evolution target.
; returns carry if not a Basic with a matching Stage2, or if evolution isn't possible this turn.
CheckIfCanEvolveInto_BasicToStage2:
	ld a, e
	add DUELVARS_ARENA_CARD_FLAGS
	call GetTurnDuelistVariable
	and CAN_EVOLVE_THIS_TURN
	jr nz, .can_evolve
	jr .cant_evolve
.can_evolve
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
	jr z, .next_pkmn ; if no damage, skip Pokemon

; heal all its damage
	push de
	ld e, a
	ld d, $00
	call HealPlayAreaCardHP

; loop all cards in deck and discard all Energy cards
; that are attached to this Play Area location's Pokemon.
	ldh a, [hTempPlayAreaLocation_ff9d]
	or CARD_LOCATION_PLAY_AREA
	ld e, a
	ld a, $00
	call GetTurnDuelistVariable
.loop_deck
	ld a, [hl]
	cp e
	jr nz, .next_card_deck ; not attached to card, skip
	ld a, l
	call LoadCardDataToBuffer2_FromDeckIndex
	ld a, [wLoadedCard2Type]
	and TYPE_ENERGY
	jr z, .next_card_deck ; not Energy, skip
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

; returns carry if opponent's Bench is full or if there are
; no Basic Pokemon cards in opponent's Discard Pile.
PokemonFluteCheck:
	ld a, DUELVARS_NUMBER_OF_POKEMON_IN_PLAY_AREA
	call GetNonTurnDuelistVariable
	ldtx hl, NoSpaceOnTheBenchText
	cp MAX_PLAY_AREA_POKEMON
	ccf
	ret c ; not enough space in Bench
	; check Discard Pile
	call SwapTurn
	call CreateBasicPokemonCardListFromDiscardPile
	ldtx hl, CannotUsePokemonFluteText
	call SwapTurn
	ret

PokemonFlute_PlayerSelection:
; create Discard Pile list
	call SwapTurn
	call CreateBasicPokemonCardListFromDiscardPile

; display selection screen and store Player's selection
	bank1call Func_5591
	ldtx hl, ChoosePokemonToPlaceInPlayText
	ldtx de, OpponentsDiscardPileText
	bank1call SetCardListHeaderText
	bank1call DisplayCardList
	call SwapTurn
	ldh a, [hTempCardIndex_ff98]
	ldh [hTemp_ffa0], a
	ret

PokemonFlute_PlaceInPlayAreaText:
; place selected card on opponent's Bench
	call SwapTurn
	ldh a, [hTemp_ffa0]
	call MoveDiscardPileCardToHand
	call AddCardToHand
	call PutHandPokemonCardInPlayArea
	call SwapTurn

; unless it was the Player who played the card,
; display the Pokemon card on screen.
	call IsPlayerTurn
	ret c
	call SwapTurn
	ldh a, [hTemp_ffa0]
	ldtx hl, CardWasChosenText
	bank1call DisplayCardDetailScreen
	call SwapTurn
	ret

; return carry if no other cards in hand,
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
	ldtx hl, ChoosePokemonToPutInDeckText
	call DrawWideTextBox_WaitForInput

; create list with all Pokemon cards in hand
	call CreatePokemonCardListFromHand
	bank1call Func_5591

; handle Player selection
	ldtx hl, ChoosePokemonToPutInDeckText
	ldtx de, DuelistHandText
	bank1call SetCardListHeaderText
	bank1call DisplayCardList
	ldh [hTemp_ffa0], a
	ret

PokemonTrader_PlayerDeckSelection:
; temporarily place chosen hand card in deck
; so it can be potentially chosen to be traded.
	ldh a, [hTemp_ffa0]
	call RemoveCardFromHand
	call ReturnCardToDeck

; display deck card list screen
	ldtx hl, ChoosePokemonFromDeckText
	call DrawWideTextBox_WaitForInput
	call CreateDeckCardList
	bank1call Func_5591
	ldtx hl, ChoosePokemonCardText
	ldtx de, DuelistDeckText
	bank1call SetCardListHeaderText

; handle Player selection
.read_input
	bank1call DisplayCardList
	jr c, .read_input ; pressing B loops back to selection
	call LoadCardDataToBuffer2_FromDeckIndex
	ld a, [wLoadedCard2Type]
	cp TYPE_ENERGY
	jr nc, .read_input ; can't select non-Pokemon cards

; a valid card was selected, store its card index and
; place the selected hand card back to the hand.
	ldh a, [hTempCardIndex_ff98]
	ldh [hTempPlayAreaLocation_ffa1], a
	ldh a, [hTemp_ffa0]
	call SearchCardInDeckAndAddToHand
	call AddCardToHand
	or a
	ret

PokemonTrader_TradeCardsEffect:
; place hand card in deck
	ldh a, [hTemp_ffa0]
	call RemoveCardFromHand
	call ReturnCardToDeck

; place deck card in hand
	ldh a, [hTempPlayAreaLocation_ffa1]
	call SearchCardInDeckAndAddToHand
	call AddCardToHand

; display cards if Pokemon Trader wasn't played by the turn player
	call IsPlayerTurn
	jr c, .done
	ldh a, [hTemp_ffa0]
	ldtx hl, PokemonWasReturnedToDeckText
	bank1call DisplayCardDetailScreen
	ldh a, [hTempPlayAreaLocation_ffa1]
	ldtx hl, WasPlacedInTheHandText
	bank1call DisplayCardDetailScreen
.done
	call Func_2c0bd
	ret

; makes list in wDuelTempList with all Pokemon in Turn Duelist's hand.
; returns carry if list is empty.
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
	jr z, .set_carry
	or a
	ret
.set_carry
	scf
	ret

Potion_PlayerSelection:
	bank1call HasAlivePokemonInPlayArea
.read_input
	bank1call OpenPlayAreaScreenForSelection
	ret c ; exit is B was pressed
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
	call HealPlayAreaCardHP
	ret

ProfessorOakEffect:
; discard hand
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
	bank1call DisplayDrawNCardsScreen
	ld c, 7
.draw_loop
	call DrawCardFromDeck
	jr c, .done
	call AddCardToHand
	dec c
	jr nz, .draw_loop
.done
	ret

Recycle_PlayerSelection:
	ldtx de, TrainerCardSuccessCheckText
	call Func_2c08a
	jr nc, .tails

	call CreateDiscardPileCardList
	bank1call Func_5591
	ldtx hl, PleaseSelectCardText
	ldtx de, YourDiscardPileText
	bank1call SetCardListHeaderText
.read_input
	bank1call DisplayCardList
	jr c, .read_input ; can't cancel with B button

; Discard Pile card was chosen
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

; add card to hand and show in screen if
; it wasn't the Player who played the Trainer card.
	call MoveDiscardPileCardToHand
	call ReturnCardToDeck
	call IsPlayerTurn
	ret c
	ldh a, [hTempList]
	ldtx hl, CardWasChosenText
	bank1call DisplayCardDetailScreen
	ret

; makes list in wDuelTempList with all Basic Pokemon cards
; that are in Turn Duelist's Discard Pile.
; returns carry if none are found.
CreateBasicPokemonCardListFromDiscardPile:
; gets hl to point at end of Discard Pile cards
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
	call LoadCardDataToBuffer2_FromDeckIndex
	ld a, [wLoadedCard2Type]
	cp TYPE_ENERGY
	jr nc, .next_discard_pile_card ; if not Pokemon card, skip
	ld a, [wLoadedCard2Stage]
	or a
	jr nz, .next_discard_pile_card ; if not Basic stage, skip

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
	jr z, .set_carry
	or a
	ret
.set_carry
	scf
	ret

; returns carry if Bench is full or there are no Basic Pokemon in the Discard Pile.
ReviveCheck:
	ld a, DUELVARS_NUMBER_OF_POKEMON_IN_PLAY_AREA
	call GetTurnDuelistVariable
	ldtx hl, NoSpaceOnTheBenchText
	cp MAX_PLAY_AREA_POKEMON
	ccf
	ret c
	call CreateBasicPokemonCardListFromDiscardPile
	ldtx hl, NoBasicPokemonInYourDiscardPileText
	ret

Revive_PlayerSelection:
; create Basic Pokemon card list from Discard Pile
	ldtx hl, ChooseBasicPokemonToPlaceOnBenchText
	call DrawWideTextBox_WaitForInput
	call CreateBasicPokemonCardListFromDiscardPile
	bank1call Func_5591

; display screen to select Pokemon
	ldtx hl, PleaseSelectCardText
	ldtx de, YourDiscardPileText
	bank1call SetCardListHeaderText
	bank1call DisplayCardList

; store selection
	ldh a, [hTempCardIndex_ff98]
	ldh [hTemp_ffa0], a
	ret

Revive_PlaceInPlayAreaEffect:
; place selected Pokemon in the Bench
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
	add 5 ; round up HP to nearest 10
.rounded
	ld [hl], a
	call IsPlayerTurn
	ret c ; done if Player played Revive

; display card
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
	ret c ; exit if B was pressed

	ldh [hTemp_ffa0], a
	or a
	ret nz ; if it wasn't the Active Pokemon, we are done

; handle switching to a Pokemon in Bench and store location selected.
	call EmptyScreen
	ldtx hl, SelectNewActivePokemonText
	call DrawWideTextBox_WaitForInput
	bank1call HasAlivePokemonInBench
	bank1call OpenPlayAreaScreenForSelection
	ldh [hTempPlayAreaLocation_ffa1], a
	ret

ScoopUp_ReturnToHandEffect:
; store chosen card location to Scoop Up
	ldh a, [hTemp_ffa0]
	or CARD_LOCATION_PLAY_AREA
	ld e, a

; find Basic Pokemon card that is in the selected Play Area location
; and add it to the hand, discarding all cards attached.
	ld a, DUELVARS_CARD_LOCATIONS
	call GetTurnDuelistVariable
.loop
	ld a, [hl]
	cp e
	jr nz, .next_card ; skip if not in selected location
	ld a, l
	call LoadCardDataToBuffer2_FromDeckIndex
	ld a, [wLoadedCard2Type]
	cp TYPE_ENERGY
	jr nc, .next_card ; skip if not Pokemon card
	ld a, [wLoadedCard2Stage]
	or a
	jr nz, .next_card  ; skip if not Basic stage
; found
	ld a, l
	ldh [hTempCardIndex_ff98], a
	call AddCardToHand
	; optimization: break loop here, since
	; no two Basic Pokemon cards may occupy
	; the same Play Area location.
.next_card
	inc l
	ld a, l
	cp DECK_SIZE
	jr c, .loop

; since the card has been moved to hand, MovePlayAreaCardToDiscardPile will
; take care of discarding every higher stage cards and other cards attached.
	ldh a, [hTemp_ffa0]
	ld e, a
	call MovePlayAreaCardToDiscardPile

; if Active Pokemon, remove any special conditions
	ldh a, [hTemp_ffa0]
	or a
	jr nz, .skip_clear_status
	call ClearAllStatusConditions
.skip_clear_status

; if card was not played by Player, show detail screen
; and print corresponding text.
	call IsPlayerTurn
	jr c, .shift_or_switch
	ldtx hl, ActivePokemonWasReturnedToHandText
	ldh a, [hTemp_ffa0]
	or a
	jr z, .display_detail_screen
	ldtx hl, BenchedPokemonWasReturnedToHandText
.display_detail_screen
	ldh a, [hTempCardIndex_ff98]
	bank1call DisplayCardDetailScreen

.shift_or_switch
; if card was in Bench, simply shift Pokemon slots...
	ldh a, [hTemp_ffa0]
	or a
	jr z, .switch
	call ShiftAllPokemonToFirstPlayAreaSlots
	ret

.switch
; ...if Active Pokemon, switch with selected Pokemon on the Bench
	ldh a, [hTempPlayAreaLocation_ffa1]
	ld d, a
	ld e, PLAY_AREA_ARENA
	call SwapPlayAreaPokemon
	call ShiftAllPokemonToFirstPlayAreaSlots
	ret

; returns carry if there are no damage counters
; or no Attached Energy cards in the Play Area.
SuperPotion_DamageEnergyCheck:
	call PlayAreaDamageCheck
	ldtx hl, NoPokemonWithDamageCountersText
	ret c ; no damage counters
	call PlayAreaAttachedEnergyCheck
	ldtx hl, NoEnergyCardsAttachedToPokemonInYourPlayAreaText
	ret

SuperPotion_PlayerSelection:
	ldtx hl, ChoosePokemonToHealText
	call DrawWideTextBox_WaitForInput
.start
	bank1call HasAlivePokemonInPlayArea
.read_input
	bank1call OpenPlayAreaScreenForSelection
	ret c ; exit if B is pressed
	ld e, a
	call GetCardDamageAndMaxHP
	or a
	jr z, .read_input ; Pokemon has no damage?
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
; Pokemon has damage and Energy cards attached,
; prompt the Player for Energy selection to discard.
	ldh a, [hCurMenuItem]
	bank1call CreateArenaOrBenchEnergyCardList
	ldh a, [hCurMenuItem]
	bank1call DisplayEnergyDiscardScreen
	bank1call HandleEnergyDiscardMenuInput
	ret c ; exit if B was pressed

	ldh a, [hTempCardIndex_ff98]
	ldh [hTemp_ffa0], a
	ldh a, [hTempPlayAreaLocation_ff9d]
	ldh [hTempPlayAreaLocation_ffa1], a
	ld e, a

; cap the healing damage if it would make it exceed max HP.
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
	call HealPlayAreaCardHP
	ret

; handles Player selection for Pokemon in Play Area,
; then opens screen to choose one of the energy cards
; attached to that selected Pokemon.
; outputs the selection in:
;	[hTemp_ffa0] = play area location
;	[hTempPlayAreaLocation_ffa1] = index of energy card
HandlePokemonAndEnergySelectionScreen:
	bank1call HasAlivePokemonInPlayArea
	bank1call OpenPlayAreaScreenForSelection
	ret c ; exit if B is pressed
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
	bank1call CreateArenaOrBenchEnergyCardList
	ldh a, [hCurMenuItem]
	bank1call DisplayEnergyDiscardScreen
	bank1call HandleEnergyDiscardMenuInput
	ldh a, [hTempPlayAreaLocation_ff9d]
	ldh [hTemp_ffa0], a
	ldh a, [hTempCardIndex_ff98]
	ldh [hTempPlayAreaLocation_ffa1], a
	ret

Switch_PlayerSelection:
	ldtx hl, SelectNewActivePokemonText
	call DrawWideTextBox_WaitForInput
	bank1call HasAlivePokemonInBench
	bank1call OpenPlayAreaScreenForSelection
	ldh a, [hTempPlayAreaLocation_ff9d]
	ldh [hTemp_ffa0], a
	ret

SwitchEffect:
	ldh a, [hTemp_ffa0]
	ld e, a
	call SwapArenaWithBenchPokemon
	ret

;
; (16) THESE FUNCTIONS WERE ALL UNUSED, SO I COMMENTED THEM OUT.
;
;Func_2c087:
;	xor a
;	jr Func_2c08c
;
;Func_2c0a8:
;	ldh a, [hTemp_ffa0]
;	push af
;	ldh a, [hWhoseTurn]
;	ldh [hTemp_ffa0], a
;	ld a, OPPACTION_6B30
;	call SetOppAction_SerialSendDuelData
;	bank1call Func_4f2d
;	ld c, a
;	pop af
;	ldh [hTemp_ffa0], a
;	ld a, c
;	ret
;
;Func_2c6d9:
;	ldtx hl, IncompleteText
;	call DrawWideTextBox_WaitForInput
;	ret
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
