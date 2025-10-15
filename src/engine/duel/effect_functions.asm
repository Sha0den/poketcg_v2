;---------------------------------------------------------------------------------
; (1) HERE ARE A VARIETY OF CHECK EFFECTS.
; THESE ARE USED TO DETERMINE WHETHER OR NOT A CARD OR ATTACK CAN BE PLAYED.
;---------------------------------------------------------------------------------

; preserves bc and de
; output:
;	hl = ID for notification text:  if one or both decks are empty
;	carry = set:  if neither player has any cards remaining in their deck
BothPlayers_DeckCheck:
	ld a, DUELVARS_NUMBER_OF_CARDS_NOT_IN_DECK
	call GetNonTurnDuelistVariable
	cp DECK_SIZE
	ccf
	ret nc
;	fallthrough

; preserves bc and de
; output:
;	hl = ID for notification text
;	carry = set:  if there are no cards still in the turn holder's deck
DeckCheck:
	ld a, DUELVARS_NUMBER_OF_CARDS_NOT_IN_DECK
	get_turn_duelist_var
	ldtx hl, NoCardsLeftInTheDeckText
	cp DECK_SIZE
	ccf
	ret


; used for Trainer cards that require you to discard 2 other cards from your hand
; preserves bc and de
; output:
;	hl = ID for notification text
;	carry = set:  if there are less than 3 cards in the turn holder's hand
OtherCardsInHandCheck:
	ld a, DUELVARS_NUMBER_OF_CARDS_IN_HAND
	get_turn_duelist_var
	ldtx hl, NotEnoughCardsInHandText
	cp 3
	ret


; preserves bc and de
; output:
;	hl = ID for notification text
;	carry = set:  if there are no cards in the turn holder's discard pile
DiscardPileCheck:
	ld a, DUELVARS_NUMBER_OF_CARDS_IN_DISCARD_PILE
	get_turn_duelist_var
	ldtx hl, NoCardsInTheDiscardPileText
	cp 1
	ret


; output:
;	hl = ID for notification text
;	carry = set:  if there are no Energy cards in the turn holder's discard pile
DiscardedEnergyCheck:
	call CreateEnergyCardListFromDiscardPile_AllEnergy
	ldtx hl, NoEnergyCardsInDiscardPileText
	ret


; preserves bc and de
; output:
;	hl = ID for notification text
;	carry = set:  if there are no Pokemon on the turn holder's Bench
;	[hTemp_ffa0] = play area location offset of the Trainer/Pokemon (PLAY_AREA_* constant)
TrainerCardAsPokemon_BenchCheck:
	ldh a, [hTempPlayAreaLocation_ff9d]
	ldh [hTemp_ffa0], a
;	fallthrough

; preserves bc and de
; output:
;	hl = ID for notification text
;	carry = set:  if there are no Pokemon on the turn holder's Bench
BenchedPokemonCheck:
	ld a, DUELVARS_NUMBER_OF_POKEMON_IN_PLAY_AREA
	get_turn_duelist_var
	ldtx hl, YouNoBenchedPokemonText
	cp 2
	ret


; preserves bc and de
; output:
;	hl = ID for notification text
;	carry = set:  if there are no Pokemon on the opponent's Bench
Opponent_BenchedPokemonCheck:
	ld a, DUELVARS_NUMBER_OF_POKEMON_IN_PLAY_AREA
	call GetNonTurnDuelistVariable
	ldtx hl, OpponentNoBenchedPokemonText
	cp 2
	ret


; preserves bc and de
; output:
;	hl = ID for notification text:  if one or both players has 5 Benched Pokemon
;	carry = set:  if neither player has space for more Benched Pokemon
EitherPlayArea_BenchSpaceCheck:
	ld a, DUELVARS_NUMBER_OF_POKEMON_IN_PLAY_AREA
	call GetNonTurnDuelistVariable
	cp MAX_PLAY_AREA_POKEMON
	ccf
	ret nc
;	fallthrough

; preserves bc and de
; output:
;	hl = ID for notification text
;	carry = set:  if there are already 5 Pokemon on the turn holder's Bench
BenchSpaceCheck:
	ld a, DUELVARS_NUMBER_OF_POKEMON_IN_PLAY_AREA
	get_turn_duelist_var
	ldtx hl, NoSpaceOnTheBenchText
	cp MAX_PLAY_AREA_POKEMON
	ccf
	ret


; output:
;	hl = ID for notification text:  if the below condition is true
;	carry = set:  if none of the turn holder's Pokemon have any damage counters
YourPokemon_DamageCheck:
	ld a, DUELVARS_NUMBER_OF_POKEMON_IN_PLAY_AREA
	get_turn_duelist_var
	ld d, a
	ld e, PLAY_AREA_ARENA
.loop_play_area
	call GetCardDamageAndMaxHP
	or a
	ret nz ; return nc if the Pokemon has damage
	inc e
	dec d
	jr nz, .loop_play_area
	; no damage found
	ldtx hl, NoPokemonWithDamageCountersText
	scf
	ret


; output:
;	hl = ID for notification text
;	carry = set:  if the turn holder's Active Pokemon has no attached Water Energy or
;	              if the turn holder's Active Pokemon doesn't have any damage counters
WaterRecover_EnergyAndHPCheck:
	ld e, PLAY_AREA_ARENA
	call GetPlayAreaCardAttachedEnergies
	ld a, [wAttachedEnergies + WATER]
	ldtx hl, NotEnoughWaterEnergyText
	cp 1
	ret c ; return if no Water Energy are attached
	jr ActivePokemon_DamageCheck

; output:
;	hl = ID for notification text
;	carry = set:  if the turn holder's Active Pokemon has no attached Psychic Energy or
;	              if the turn holder's Active Pokemon doesn't have any damage counters
PsychicRecover_EnergyAndHPCheck:
	call ActivePokemon_PsychicEnergyCheck
	ret c ; return if no Psychic Energy are attached
;	fallthrough

; output:
;	hl = ID for notification text
;	carry = set:  if the turn holder's Active Pokemon doesn't have any damage counters
ActivePokemon_DamageCheck:
	ld e, PLAY_AREA_ARENA
	call GetCardDamageAndMaxHP
	ldtx hl, NoDamageCountersText
	cp 10
	ret


; preserves bc and de
; output:
;	hl = ID for notification text:  if the below condition is true
;	carry = set:  if the turn holder's Active Pokemon isn't affected by any Special Conditions
ActivePokemon_StatusCheck:
	ld a, DUELVARS_ARENA_CARD_STATUS
	get_turn_duelist_var
	or a ; cp NO_STATUS
	ret nz ; return nc if the Active Pokemon has a Special Condition
	ldtx hl, NotAffectedBySpecialConditionsText
	scf
	ret


; checks if any of the turn holder's in-play Pokemon have any Energy attached to them
; preserves bc and de
; output:
;	carry = set:  if none of the turn holder's Pokemon have any attached Energy
YourPokemon_AttachedEnergyCheck:
	ldh a, [hWhoseTurn]
	ld h, a
	ld l, DUELVARS_CARD_LOCATIONS + DECK_SIZE
.loop_deck
	dec l ; go through deck indices in reverse order
	ld a, [hl]
	bit CARD_LOCATION_PLAY_AREA_F, a
	jr z, .next_card ; skip if not in the play area
	ld a, l
	call GetCardTypeFromDeckIndex_SaveDE
	and TYPE_ENERGY
	ret nz ; return no carry if an Energy card was found
.next_card
	ld a, l
	or a
	jr nz, .loop_deck
	scf
	ret


; output:
;	hl = ID for notification text
;	carry = set:  if the turn holder's Active Pokemon has
;	              fewer than 2 Energy cards attached to it
ActivePokemon_2EnergyCardsCheck:
	xor a ; PLAY_AREA_ARENA
	call CreateArenaOrBenchEnergyCardList
	ldtx hl, NotEnoughEnergyCardsText
	cp 2
	ret


; preserves bc
; output:
;	hl = ID for notification text
;	carry = set:  if the turn holder's Active Pokemon has no attached Fire Energy
ActivePokemon_FireEnergyCheck:
	ld e, PLAY_AREA_ARENA
	call GetPlayAreaCardAttachedEnergies
	ldtx hl, NotEnoughFireEnergyText
	ld a, [wAttachedEnergies + FIRE]
	cp 1
	ret


; preserves bc
; output:
;	hl = ID for notification text
;	carry = set:  if the turn holder's Active Pokemon has
;	              fewer than 2 Fire Energy attached to it
ActivePokemon_DoubleFireEnergyCheck:
	ld e, PLAY_AREA_ARENA
	call GetPlayAreaCardAttachedEnergies
	ld a, [wAttachedEnergies + FIRE]
	ldtx hl, NotEnoughFireEnergyText
	cp 2
	ret


; preserves bc
; output:
;	hl = ID for notification text
;	carry = set:  if the turn holder's Active Pokemon has no attached Psychic Energy
ActivePokemon_PsychicEnergyCheck:
	ld e, PLAY_AREA_ARENA
	call GetPlayAreaCardAttachedEnergies
	ld a, [wAttachedEnergies + PSYCHIC]
	ldtx hl, NotEnoughPsychicEnergyText
	cp 1
	ret


; preserves bc and de
; output:
;	hl = ID for notification text:  if the below condition is true
;	carry = set:  if the opponent's Active Pokemon doesn't have any attacks
DefendingPokemon_AttackCheck:
	rst SwapTurn
	ld a, DUELVARS_ARENA_CARD
	get_turn_duelist_var
	call LoadCardDataToBuffer2_FromDeckIndex
	ld a, [wLoadedCard2Atk1Category]
	cp POKEMON_POWER
	jr nz, .has_attack
	ld hl, wLoadedCard2Atk2Name
	ld a, [hli]
	or [hl]
	jr nz, .has_attack
; has no attack
	ldtx hl, NoAttackMayBeChosenText
	scf
	jp SwapTurn
.has_attack
	or a
	jp SwapTurn


; preserves bc and de
; output:
;	hl = ID for notification text:  if the below condition is true
;	carry = set:  if the opponent's Active Pokemon is not Asleep
DefendingPokemon_SleepCheck:
	ld a, DUELVARS_ARENA_CARD_STATUS
	call GetNonTurnDuelistVariable
	and CNF_SLP_PRZ
	cp ASLEEP
	ret z ; return nc if Asleep
	ldtx hl, OpponentIsNotAsleepText
	scf
	ret


; preserves bc
; output:
;	hl = ID for notification text:  if the below condition is true
;	carry = set:  if neither player has any Evolved Pokemon
EitherPlayArea_EvolvedPokemonCheck:
	rst SwapTurn
	call YourPlayArea_EvolvedPokemonCheck
	rst SwapTurn
	ret nc ; return if the opponent has an Evolved Pokemon
;	fallthrough

; checks if there is at least one Evolved Pokemon in the turn holder's play area
; preserves bc
; output:
;	hl = ID for notification text:  if the below condition is true
;	carry = set:  if the turn holder doesn't have any Evolved Pokemon
YourPlayArea_EvolvedPokemonCheck:
	ld a, DUELVARS_ARENA_CARD
	get_turn_duelist_var
	ld d, h
	ld e, DUELVARS_ARENA_CARD_STAGE
.loop
	ld a, [hli]
	cp -1 ; empty play area slot?
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

; preserves de
; output:
;	hl = ID for notification text:  if the below condition is true
;	carry = set:  if the turn holder doesn't have any Evolved Pokemon
;Alt_YourPlayArea_EvolvedPokemonCheck:
;	ld a, DUELVARS_NUMBER_OF_POKEMON_IN_PLAY_AREA
;	get_turn_duelist_var
;	ld c, a
;	ld l, DUELVARS_ARENA_CARD
;.loop
;	ld a, [hli]
;	call LoadCardDataToBuffer2_FromDeckIndex
;	ld a, [wLoadedCard2Stage]
;	or a
;	ret nz ; return nc if it's an Evolution card
;	dec c
;	jr nz, .loop
;
;	ldtx hl, NoEvolvedPokemonText
;	scf
;	ret


; checks if the Pokemon Power was already used that turn
; also checks for Muk's Toxic Gas or any relevant Special Conditions if it's the Active Pokemon
; preserves bc and de
; output:
;	hl = ID for notification text
;	carry = set:  if the Pokemon Power cannot be used
;	[hTemp_ffa0] = play area location offset of the user (PLAY_AREA_* constant)
OncePerTurnPokePowerCheck:
	ldh a, [hTempPlayAreaLocation_ff9d]
	ldh [hTemp_ffa0], a
	add DUELVARS_ARENA_CARD_FLAGS
	get_turn_duelist_var
	and USED_PKMN_POWER_THIS_TURN
	jr nz, .already_used
	ldh a, [hTempPlayAreaLocation_ff9d]
	jp CheckIsIncapableOfUsingPkmnPower
.already_used
	ldtx hl, OnlyOncePerTurnText
;	fallthrough

SetCarryEF:
	scf
	ret


;---------------------------------------------------------------------------------
; (2) NEXT ARE SOME FUNCTIONS THAT ARE FREQUENTLY CALLED BY OTHER FUNCTIONS
;---------------------------------------------------------------------------------

; preserves bc and de
; output:
;	carry = set:  if the Player is the turn holder
IsPlayerTurn:
	ld a, DUELVARS_DUELIST_TYPE
	get_turn_duelist_var
	cp DUELIST_TYPE_PLAYER
	jr z, SetCarryEF ; player
	or a
	ret


SetupPlayAreaScreen:
	xor a
	ld [wExcludeArenaPokemon], a
	ld a, [wDuelDisplayedScreen]
	cp PLAY_AREA_CARD_LIST
	ret z
	call ZeroObjectPositionsAndToggleOAMCopy
	call EmptyScreen
	call LoadDuelCardSymbolTiles
	jp LoadDuelCheckPokemonScreenTiles


; sets up and draws the screen that shows the turn holder's play area Pokemon.
; the cursor is set to the given location and A/B input from the Player exits the screen.
; input:
;	a = play area location offset (PLAY_AREA_* constant)
DrawPlayAreaScreenToShowChanges:
	ldh [hTempPlayAreaLocation_ff9d], a
	call SetupPlayAreaScreen
	bank1call PrintPlayAreaCardList_EnableLCD
	bank1call InitAndPrintPlayAreaCardInformationAndLocation_WithTextBox
	ret


; preserves de
; input:
;	a = attack animation to play
PlayTrainerEffectAnimation:
	ld [wLoadedAttackAnimation], a
	xor a ; FALSE
	ld [wAttackAnimationIsPlaying], a
	lb bc, PLAY_AREA_ARENA, $00 ; neither WEAKNESS nor RESISTANCE
	ldh a, [hWhoseTurn]
	ld h, a
	call PlayAttackAnimation
	jp WaitAttackAnimation


; prompts the Player with a Yes/No question whether to quit the screen,
; even though they can select more cards from list.
; [hCurSelectionItem] holds the number of cards
; that were already selected by the Player.
; input:
;	a = total number of cards that can be selected
; output:
;	carry = set:  if "No" was selected
AskWhetherToQuitSelectingCards:
	ld hl, hCurSelectionItem
	sub [hl]
	ld hl, wTxRam3
	ld [hli], a
	xor a
	ld [hl], a
	ldtx hl, YouCanSelectMoreCardsQuitText
	jp YesOrNoMenuWithText


; preserves all registers except af
; input:
;	[hTemp_ffa0] = deck index of the card to put in the discard pile (0-59)
CardDiscardEffect:
	ldh a, [hTemp_ffa0]
	jp PutCardInDiscardPile


; draws the symbol in b next to the selection cursor,
; meant to be used when choosing a Pokemon from the detailed in-play Pokemon screen
; preserves de and hl
; input:
;	a = play area location offset (PLAY_AREA_* constant)
;	b = TX_SYMBOL (SYM_*)
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


; preserves bc and de
; output:
;	hl = next position in hTempList to place a new card
;	[hCurSelectionItem] += 1
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


; checks whether the opponent's Active Pokemon has a No Damage or Effect substatus,
; and if it does, then prints the appropriate text
; output:
;	carry = set:  if the Defending Pokemon has a No Damage or Effect substatus
HandleNoDamageOrEffect:
	call CheckNoDamageOrEffect
	ret nc ; return if the attack is successful
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
; handles the Player's selection for reordering the top 3 cards of either player's deck
; (actual logic is in effect_functions2.asm)
; output:
;	[hTempList] = which deck was chosen (0 = turn holder's deck, 1 = opponent's deck)
;	hTempList + 1 = $ff-terminated list with deck indices of cards to place on top of the deck
Prophecy_PlayerSelection:
	farcall HandleProphecyPlayerSelection
	ret


; AI doesn't ever choose this attack so this does no sorting.
Prophecy_AISelection:
	ld a, $ff
	ldh [hTemp_ffa0], a
	ret


; input:
;	[hTempList] = 0: reorder the turn holder's deck
;	[hTempList] > 0: reorder the opponent's deck
;	hTempList + 1 = $ff-terminated list with deck indices of cards to place on top of the deck
Prophecy_ReorderEffect:
	ld hl, hTempList
	ld a, [hli]
	or a
	jr z, Reordering ; turn holder's deck
	cp $ff
	ret z ; return if nothing was selected for reordering (current AI effect)

	; opponent's deck
	rst SwapTurn
	call Reordering
	jp SwapTurn


; handles the Player's selection for reordering the top 5 cards of their deck
; (actual logic is in effect_functions2.asm)
; output:
;	hTempList + 1 = $ff-terminated list with deck indices of cards to place on top of the deck
Pokedex_PlayerSelection:
	farcall HandlePokedexPlayerSelection
	ret


; input:
;	hTempList + 1 = $ff-terminated list with deck indices of cards to place on top of the deck
Pokedex_ReorderEffect:
	ld hl, hTempList + 1
;	fallthrough

; input:
;	hl = $ff-terminated list with deck indices of cards to place on top of the deck
Reordering:
	ld c, 0 ; counter for number of cards to reorder

; add selected cards to hand in the specified order
.loop_place_hand
	ld a, [hli]
	cp $ff
	jr z, .place_top_deck
	call RemoveCardFromDeck
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
	ret c ; return if it's the Player's turn
	ldtx hl, RearrangedCardsInDuelistsDeckText
	jp DrawWideTextBox_WaitForInput


; flips a coin, and if heads, the turn holder draws a card from their deck
DrawCard50PercentEffect:
	ldtx de, IfHeadsDraw1CardFromDeckText
	call TossCoin
	ret nc ; return if tails
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
	ret c ; return if the deck is empty
	call AddCardToHand
	call LoadCardDataToBuffer1_FromDeckIndex
	ld a, [wDuelistType]
	cp DUELIST_TYPE_PLAYER
	ret nz ; return if it isn't the Player's turn
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
; output:
;	carry = set:  if a card couldn't be drawn because the deck was empty
DrawNCards_ShowCardDetails:
	ld c, a
	bank1call DisplayDrawNCardsScreen
.loop_draw
	call DrawCardFromDeck
	ret c ; return if the deck is empty
	ldh [hTempCardIndex_ff98], a
	call AddCardToHand
	call IsPlayerTurn
	jr nc, .skip_display_screen ; don't show card(s) on screen if it's the opponent's turn
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


; discards all cards in the turn holder's hand and
; then, the turn holder draws 7 cards from their deck.
ProfessorOakEffect:
; discard every card in the hand
	call CreateHandCardList
	call SortCardsInDuelTempListByID
	ld hl, wDuelTempList
.discard_loop
	ld a, [hli]
	cp $ff
	jr z, .draw_cards
	call MoveCardFromHandToDiscardPile
	jr .discard_loop
.draw_cards
	ld a, 7
;	fallthrough

; preserves de and hl
; input:
;   a: number of cards to draw
; output:
;	carry = set:  if a card couldn't be drawn because the deck was empty
DrawNCards_NoCardDetails:
	ld c, a
	bank1call DisplayDrawNCardsScreen
.loop_draw
	call DrawCardFromDeck
	ret c ; return if the deck is empty
	call AddCardToHand
	dec c
	jr nz, .loop_draw
	ret


; moves a given card from the turn holder's deck to their hand
; input:
;	[hTemp_ffa0] = deck index of a card in the turn holder's deck (0-59, -1 if none)
AddCardFromDeckToHandEffect:
	ldh a, [hTemp_ffa0]
	cp -1
	jr z, ShuffleCardsInDeck ; shuffle and return if no card was selected

; add to hand
	call MoveCardFromDeckToHand

; show the selected card on the screen if this effect wasn't initiated by the Player
	call IsPlayerTurn
	jr c, ShuffleCardsInDeck ; shuffle and return if it's the Player's turn
	ldh a, [hTemp_ffa0]
	ldtx hl, WasPlacedInTheHandText
	bank1call DisplayCardDetailScreen
;	fallthrough

ShuffleCardsInDeck:
	call ExchangeRNG
	bank1call PlayDeckShuffleAnimation
	jp ShuffleDeck


; handles the Player's selection of a Basic Energy card from their deck
; (actual logic is in effect_functions2.asm)
; output:
;	[hTemp_ffa0] = deck index of a Basic Energy card in the Player's deck (0-59, -1 if none)
EnergySearch_PlayerSelection:
	farcall FindBasicEnergy
	ret


; handles the Player's selection of a Basic Energy card from their deck
; and a Pokemon from their play area (actual logic is in effect_functions2.asm)
; output:
;	[hTemp_ffa0] = deck index of a Basic Energy card in the Player's deck (0-59, -1 if none)
;	[hTempPlayAreaLocation_ffa1] = target Pokémon's play area location offset (PLAY_AREA_* constant)
AttachBasicEnergyFromDeck_PlayerSelection:
	farcall FindBasicEnergyToAttach
	ret


; AI attaches the first Basic Energy card that it finds in the deck
; to its Active Pokemon. (actual logic is in effect_functions2.asm)
; this function isn't normally used. the real selection effect is located in
; engine/duel/ai/core.asm under the AISelectSpecialAttackParameters function.
; output:
;	[hTemp_ffa0] = deck index of a Basic Energy card in the AI's deck (0-59, -1 if none)
;	[hTempPlayAreaLocation_ffa1] = target Pokémon's play area location offset (PLAY_AREA_* constant)
AttachBasicEnergyFromDeck_AISelection:
	farcall AIFindBasicEnergyToAttach
	ret


; attaches a given Energy card in the turn holder's deck to a given Pokemon in the play area
; input:
;	[hTemp_ffa0] = deck index of the Energy card to attach from the deck (0-59, -1 if none)
;	[hTempPlayAreaLocation_ffa1] = target Pokémon's play area location offset (PLAY_AREA_* constant)
AttachBasicEnergyFromDeck_AttachEffect:
	ldh a, [hTemp_ffa0]
	cp -1
	jr z, ShuffleCardsInDeck ; shuffle and return if no card was selected

; add card to the hand and attach it to the selected Pokemon
	call MoveCardFromDeckToHand
	ldh a, [hTempPlayAreaLocation_ffa1]
	ld e, a
	ldh a, [hTemp_ffa0]
	call PutHandCardInPlayArea
	call IsPlayerTurn
	jr c, ShuffleCardsInDeck ; shuffle and return if it's the Player's turn

; not Player, so show detail screen and which Pokemon was chosen to attach Energy
	ldh a, [hTempPlayAreaLocation_ffa1]
	add DUELVARS_ARENA_CARD
	get_turn_duelist_var
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


; handles the Player's selection of a Trainer card from their deck
; (actual logic is in effect_functions2.asm)
; output:
;	[hTemp_ffa0] = deck index of a Trainer card in the Player's deck (0-59, -1 if none)
TrainerSearch_PlayerSelection:
	farcall FindTrainer
	ret


; AI picks the first Trainer card in the deck (actual logic is in effect_functions2.asm)
; output:
;	[hTemp_ffa0] = deck index of a Trainer card in the AI's deck (0-59, -1 if none)
TrainerSearch_AISelection:
	farcall AIFindTrainer
	ret


; handles the Player's selection of an Evolution card from their deck
; (actual logic is in effect_functions2.asm)
; output:
;	[hTemp_ffa0] = deck index of an Evolution card in the Player's deck (0-59, -1 if none)
EvolutionSearch_PlayerSelection:
	farcall FindEvolution
	ret


; AI tries to pick an Evolution card from the deck that evolves from its Active Pokémon.
; if that fails, it picks the first Evolution card that it finds in the deck.
; (actual logic is in effect_functions2.asm)
; output:
;	[hTemp_ffa0] = deck index of an Evolution card in the AI's deck (0-59, -1 if none)
EvolutionSearch_AISelection:
	farcall AIFindEvolution
	ret


; preserves bc and de
; output:
;	hl = ID for notification text
;	carry = set:  if there are no cards in the turn holder's deck or
;	              if there are already 5 Pokemon on the turn holder's Bench
CallForF_CheckDeckAndPlayArea:
	call DeckCheck
	ret c ; return if the deck is empty
	jp BenchSpaceCheck


; puts a Pokemon from the turn holder's deck onto their Bench
; input:
;	[hTemp_ffa0] = deck index of the Pokemon from the deck (0-59, -1 if none)
CallForF_PutInPlayAreaEffect:
	ldh a, [hTemp_ffa0]
	cp -1
	jp z, ShuffleCardsInDeck ; shuffle and return if no card was selected
	call MoveCardFromDeckToHand
	call PutHandPokemonCardInPlayArea

; show the selected card on the screen if this effect wasn't initiated by the Player
	call IsPlayerTurn
	jp c, ShuffleCardsInDeck ; shuffle and return if it's the Player's turn
	ldh a, [hTemp_ffa0]
	ldtx hl, PlacedOnTheBenchText
	bank1call DisplayCardDetailScreen
	jp ShuffleCardsInDeck


; handles the Player's selection of a Basic Pokemon from their deck
; (actual logic is in effect_functions2.asm)
; output:
;	[hTemp_ffa0] = deck index of a Basic Pokémon card in the Player's deck (0-59, -1 if none)
CallForFamily_PlayerSelection:
	farcall FindBasicPokemon
	ret


; AI picks the first Basic Pokemon in the deck (actual logic is in effect_functions2.asm)
; output:
;	[hTemp_ffa0] = deck index of a Basic Pokémon card in the AI's deck (0-59, -1 if none)
CallForFamily_AISelection:
	farcall AIFindBasicPokemon
	ret


; handles the Player's selection of a Fighting-type Basic Pokemon card from their deck
; (actual logic is in effect_functions2.asm)
; output:
;	[hTemp_ffa0] = deck index of a Basic Fighting Pokémon card in the Player's deck (0-59, -1 if none)
CallForFighting_PlayerSelection:
	farcall FindBasicFightingPokemon
	ret


; AI picks the first Basic Fighting Pokemon in the deck (actual logic is in effect_functions2.asm)
; output:
;	[hTemp_ffa0] = deck index of a Basic Fighting Pokémon card in the AI's deck (0-59, -1 if none)
CallForFighting_AISelection:
	farcall AIFindBasicFighting
	ret


; handles the Player's selection of a Nidoran F/M card from their deck
; (actual logic is in effect_functions2.asm)
; output:
;	[hTemp_ffa0] = deck index of a Nidoran F/M card in the Player's deck (0-59, -1 if none)
CallForNidoran_PlayerSelection:
	farcall FindNidoran
	ret


; AI picks the first Nidoran F/M in the deck (actual logic is in effect_functions2.asm)
; output:
;	[hTemp_ffa0] = deck index of a Nidoran F/M card in the AI's deck (0-59, -1 if none)
CallForNidoran_AISelection:
	farcall AIFindNidoran
	ret


; handles the Player's selection of an Oddish card from their deck
; (actual logic is in effect_functions2.asm)
; output:
;	[hTemp_ffa0] = deck index of an Oddish card in the Player's deck (0-59, -1 if none)
CallForOddish_PlayerSelection:
	farcall FindOddish
	ret


; AI picks the first Oddish in the deck (actual logic is in effect_functions2.asm)
; output:
;	[hTemp_ffa0] = deck index of an Oddish card in the AI's deck (0-59, -1 if none)
CallForOddish_AISelection:
	farcall AIFindOddish
	ret


; handles the Player's selection of a Bellsprout card from their deck
; (actual logic is in effect_functions2.asm)
; output:
;	[hTemp_ffa0] = deck index of a Bellsprout card in the Player's deck (0-59, -1 if none)
CallForBellsprout_PlayerSelection:
	farcall FindBellsprout
	ret


; AI picks the first Bellsprout in the deck (actual logic in effect_functions2.asm)
; output:
;	[hTemp_ffa0] = deck index of a Bellsprout card in the AI's deck (0-59, -1 if none)
CallForBellsprout_AISelection:
	farcall AIFindBellsprout
	ret


; handles the Player's selection of a Krabby card from their deck
; (actual logic is in effect_functions2.asm)
; output:
;	[hTemp_ffa0] = deck index of a Krabby card in the Player's deck (0-59, -1 if none)
CallForKrabby_PlayerSelection:
	farcall FindKrabby
	ret


; AI picks the first Krabby in the deck (actual logic is in effect_functions2.asm)
; output:
;	[hTemp_ffa0] = deck index of a Krabby card in the AI's deck (0-59, -1 if none)
CallForKrabby_AISelection:
	farcall AIFindKrabby
	ret


; flips a coin, and if heads, put a random Basic Pokemon
; from the turn holder's deck onto their Bench
CallForRandomBasic50PercentEffect:
	ldtx de, AttackSuccessCheckText
	call TossCoin
	jr c, .successful

.none_came_text
	ldtx hl, ThereWasNoEffectText
	jp DrawWideTextBox_WaitForInput

.successful
	call PickRandomBasicCardFromDeck
	jr nc, .put_in_bench
	ld a, ATK_ANIM_FRIENDSHIP_SONG
	call PlayAttackAnimationOverAttackingPokemon
	call .none_came_text
	jp ShuffleCardsInDeck

.put_in_bench
	call MoveCardFromDeckToHand
	call PutHandPokemonCardInPlayArea
	ld a, ATK_ANIM_FRIENDSHIP_SONG
	call PlayAttackAnimationOverAttackingPokemon
	ldh a, [hTempCardIndex_ff98]
	ldtx hl, PlacedOnTheBenchText
	bank1call DisplayCardDetailScreen
	jp ShuffleCardsInDeck


; preserves de
; input:
;	a = which attack animation to play (ATK_ANIM_* constant)
PlayAttackAnimationOverAttackingPokemon:
	ld [wLoadedAttackAnimation], a
	ldh a, [hTempPlayAreaLocation_ff9d]
	ld b, a
	ld c, $0 ; neither WEAKNESS nor RESISTANCE
	ldh a, [hWhoseTurn]
	ld h, a
	call PlayAttackAnimation
	jp WaitAttackAnimation


; output:
;	a & [hTempCardIndex_ff98] = deck index of a random Basic Pokémon in the turn holder's deck (0-59, -1 if none)
;	carry = set:  if there are no Basic Pokémon in the turn holder's deck
PickRandomBasicCardFromDeck:
	call CreateDeckCardList
	ret c ; return if the deck is empty
	ld hl, wDuelTempList
	call ShuffleCards
.loop_deck
	ld a, [hli]
	ldh [hTempCardIndex_ff98], a
	cp $ff
	scf
	ret z ; return carry if there are no more cards to check
	call CheckDeckIndexForBasicPokemon
	jr nc, .loop_deck ; skip if not a Basic Pokemon
	ldh a, [hTempCardIndex_ff98]
	or a
	ret


; puts random Basic Pokemon from each player's deck onto their Bench
; until both Benches have 5 Pokemon
RandomlyFillBothBenchesEffect:
	rst SwapTurn
	call .FillBench
	rst SwapTurn
	call .FillBench

; display both Play Areas
	ldtx hl, BasicPokemonWasPlacedOnEachBenchText
	call DrawWideTextBox_WaitForInput
	bank1call InitVarsAndOpenPlayAreaScreenForSelection
	rst SwapTurn
	bank1call InitVarsAndOpenPlayAreaScreenForSelection
	jp SwapTurn

.FillBench
	call CreateDeckCardList
	ret c ; return if the deck is empty
	ld hl, wDuelTempList
	call ShuffleCards

; return if there's no more space on the Bench
.check_bench
	push hl
	ld a, DUELVARS_NUMBER_OF_POKEMON_IN_PLAY_AREA
	get_turn_duelist_var
	pop hl
	cp MAX_PLAY_AREA_POKEMON
	jp nc, ShuffleCardsInDeck ; shuffle and return if the Bench is full

; there's still space, so look for the next
; Basic Pokemon card to put on the Bench.
.loop
	ld a, [hli]
	ldh [hTempCardIndex_ff98], a
	cp $ff
	jp z, ShuffleCardsInDeck ; shuffle and return if there are no more cards to check
	call CheckDeckIndexForBasicPokemon
	jr nc, .loop ; skip if not a Basic Pokemon
; place card onto the Bench
	push hl
	ldh a, [hTempCardIndex_ff98]
	call MoveCardFromDeckToHand
	call PutHandPokemonCardInPlayArea
	pop hl
	jr .check_bench


;---------------------------------------------------------------------------------
; (4) ATTACK EFFECTS THAT PULL CARDS OUT OF THE DISCARD PILE ARE NEXT.
;---------------------------------------------------------------------------------

; output:
;	hl = ID for notification text
;	carry = set:  if there isn't an attached Psychic Energy to discard or
;	              if there are no Trainer cards in the turn holder's discard pile
Scavenge_DiscardPileAndEnergyCheck:
	call ActivePokemon_PsychicEnergyCheck
	ret c ; return if no Psychic Energy are attached
	jr CreateTrainerCardListFromDiscardPile


; output:
;	hl = ID for notification text
;	carry = set:  if there aren't at least 2 other cards in the turn holder's hand or
;	              if there are no Trainer cards in the turn holder's discard pile
ItemFinderCheck:
	call OtherCardsInHandCheck
	ret c ; return if not enough cards in hand
;	fallthrough

; makes a list in wDuelTempList with the deck indices of all
; Trainer cards that are in the turn holder's discard pile.
; output:
;	a = number of Trainer cards in the turn holder's discard pile
;	hl = ID for notification text:  if the below condition is true
;	carry = set:  if there are no Trainer cards in the turn holder's discard pile
;	wDuelTempList = $ff-terminated list with deck indices of all discarded Trainer cards
CreateTrainerCardListFromDiscardPile:
; check whether there are any cards in the turn holder's discard pile.
	ld c, 0 ; counter for number of discarded Trainer cards
	ld de, wDuelTempList
	ld a, DUELVARS_NUMBER_OF_CARDS_IN_DISCARD_PILE
	get_turn_duelist_var
	or a
	jr z, .terminate_list ; skip to the end if no cards in discard pile

; store the number of cards in the discard pile and have hl point to the
; end of the discard pile list in wPlayerDeckCards/wOpponentDeckCards.
	ld b, a
	add DUELVARS_DECK_CARDS - 1 ; point to last card in discard pile
	ld l, a

.check_card
	ld a, [hl]
	call GetCardTypeFromDeckIndex_SaveDE
	cp TYPE_TRAINER
	jr nz, .next_discard_pile_card
	; found a Trainer card, so write this card's deck index to wDuelTempList
	ld a, [hl]
	ld [de], a
	inc de
	inc c
.next_discard_pile_card
	dec l ; goes through the discard pile list in descending order
	dec b
	jr nz, .check_card

.terminate_list
	ld a, $ff ; list is $ff-terminated
	ld [de], a ; add terminating byte to wDuelTempList
	ld a, c
	or a
	ret nz ; return no carry if there's at least one card in the list
	; list is empty, so return carry with the notification text in hl
	ldtx hl, NoTrainerCardsInDiscardPileText
	scf
	ret


; makes a list in wDuelTempList with the deck indices of all
; Basic Energy cards that are in the turn holder's discard pile.
; output:
;	a & c = number of Basic Energy cards in the turn holder's discard pile
;	carry = set:  if there are no Basic Energy cards in the turn holder's discard pile
;	wDuelTempList = $ff-terminated list with deck indices of all discarded Basic Energy cards
CreateEnergyCardListFromDiscardPile_OnlyBasic:
	ld a, TYPE_ENERGY + NUM_COLORED_TYPES ; only Basic Energy cards have a lower type index than this
	ld [wEnergyCardListFilter], a
	jr CreateEnergyCardListFromDiscardPile

; makes a list in wDuelTempList with the deck indices of all Energy cards
; (even Special Energy cards) that are in the turn holder's discard pile.
; output:
;	a & c = number of Energy cards in the turn holder's discard pile
;	carry = set:  if there are no Energy cards in the turn holder's discard pile
;	wDuelTempList = $ff-terminated list with deck indices of all discarded Energy cards
CreateEnergyCardListFromDiscardPile_AllEnergy:
	ld a, TYPE_TRAINER ; all Energy cards have a lower type index than this
	ld [wEnergyCardListFilter], a
;	fallthrough

; input:
;	[wEnergyCardListFilter] = determines whether only Basic Energy cards are included in the list
; output:
;	a & c = number of relevant Energy cards in the turn holder's discard pile
;	carry = set:  if there are no relevant Energy cards in the turn holder's discard pile
;	wDuelTempList = $ff-terminated list with deck indices of all relevant Energy cards in the discard pile
CreateEnergyCardListFromDiscardPile:
; check whether there are any cards in the turn holder's discard pile.
	ld c, 0 ; counter for number of Energy cards in list
	ld de, wDuelTempList
	ld a, DUELVARS_NUMBER_OF_CARDS_IN_DISCARD_PILE
	get_turn_duelist_var
	or a
	jr z, .terminate_list ; skip to the end if no cards in discard pile

; store the number of cards in the discard pile and have hl point to the
; end of the discard pile list in wPlayerDeckCards/wOpponentDeckCards.
	ld b, a
	add DUELVARS_DECK_CARDS - 1 ; point to last card in discard pile
	ld l, a

.check_card
	ld a, [hl]
	call LoadCardDataToBuffer2_FromDeckIndex
	ld a, [wLoadedCard2Type]
	and TYPE_ENERGY
	jr z, .next_card ; skip if not an Energy card
	push bc
	ld a, [wEnergyCardListFilter]
	ld b, a
	ld a, [wLoadedCard2Type]
	cp b
	pop bc
	jr nc, .next_card
	; write this card's deck index to wDuelTempList
	ld a, [hl]
	ld [de], a
	inc de
	inc c
.next_card
	dec l ; goes through the discard pile list in descending order
	dec b
	jr nz, .check_card

.terminate_list
	ld a, $ff ; list is $ff-terminated
	ld [de], a ; add terminating byte to wDuelTempList
	ld a, c
	or a
	ret nz ; return no carry if there's at least one card in the list
	; list is empty, so return carry
	scf
	ret


; makes a list in wDuelTempList with the deck indices of all
; Basic Pokemon cards that are in the turn holder's discard pile.
; output:
;	a & c = number of Basic Pokémon cards in the turn holder's discard pile
;	carry = set:  if there are no Basic Pokémon cards in the turn holder's discard pile
;	wDuelTempList = $ff-terminated list with deck indices of all discarded Basic Pokémon cards
CreateBasicPokemonCardListFromDiscardPile:
; check whether there are any cards in the turn holder's discard pile.
	ld c, 0 ; counter for number of discarded Pokémon cards
	ld de, wDuelTempList
	ld a, DUELVARS_NUMBER_OF_CARDS_IN_DISCARD_PILE
	get_turn_duelist_var
	or a
	jr z, .terminate_list ; skip to the end if no cards in discard pile

; store the number of cards in the discard pile and have hl point to the
; end of the discard pile list in wPlayerDeckCards/wOpponentDeckCards.
	ld b, a
	add DUELVARS_DECK_CARDS - 1 ; point to last card in discard pile
	ld l, a

.check_card
	ld a, [hl]
	call CheckDeckIndexForBasicPokemon
	jr nc, .next_discard_pile_card ; skip if not a Basic Pokemon
	; found a Basic Pokémon card, so write this card's deck index to wDuelTempList
	ld a, [hl]
	ld [de], a
	inc de
	inc c
.next_discard_pile_card
	dec l ; goes through the discard pile list in descending order
	dec b
	jr nz, .check_card

.terminate_list
	ld a, $ff ; list is $ff-terminated
	ld [de], a ; add terminating byte to wDuelTempList
	ld a, c
	or a
	ret nz ; return no carry if there's at least one card in the list
	; list is empty, so return carry
	scf
	ret


; AI picks the first available Energy and Trainer card from the respective location
; output:
;	[hTemp_ffa0] = deck index of the Psychic Energy card to discard
;	[hTempPlayAreaLocation_ffa1] = deck index of a Trainer card in own discard pile (0-59)
Scavenge_AISelection:
	call DiscardAttachedPsychicEnergy_AISelection
	call CreateTrainerCardListFromDiscardPile
	ld a, [wDuelTempList]
	ldh [hTempPlayAreaLocation_ffa1], a
	ret


; handles the Player's selection of a Trainer card from their discard pile
; output:
;	[hTempPlayAreaLocation_ffa1] = deck index of a Trainer card in own discard pile (0-59)
Scavenge_TrainerPlayerSelection:
	call CreateTrainerCardListFromDiscardPile
	bank1call InitAndDrawCardListScreenLayout_WithSelectCheckMenu
	ldtx hl, PleaseSelectCardText
	ldtx de, YourDiscardPileText
	call SetCardListHeaderText
.loop_input
	bank1call DisplayCardList
	jr c, .loop_input ; must choose, B button can't be used to exit
	ldh [hTempPlayAreaLocation_ffa1], a
	ret


; moves a given card from the turn holder's discard pile to their hand
; input:
;	[hTempPlayAreaLocation_ffa1] = deck index of the discarded Trainer card to move to the hand (0-59)
Scavenge_MoveToHandEffect:
	ldh a, [hTempPlayAreaLocation_ffa1]
	call MoveCardFromDiscardPileToHand

; show the selected card on the screen if this effect wasn't initiated by the Player
	call IsPlayerTurn
	ret c ; return if it's the Player's turn
	ldh a, [hTempPlayAreaLocation_ffa1]
	ldtx hl, WasPlacedInTheHandText
	bank1call DisplayCardDetailScreen
	ret


; draws a list of Energy cards in the discard pile.
; the Player can select up to 2 cards from the list.
; output:
;	hTempList = $ff-terminated list with deck indices of discarded Energy cards
Choose2EnergyFromDiscardPile_PlayerSelection:
	xor a
	ldh [hCurSelectionItem], a
	call CreateEnergyCardListFromDiscardPile_AllEnergy
	jr c, .finish

	ldtx hl, Choose2EnergyCardsFromDiscardPileText
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
	jr c, .finish ; exit if there are no more Energy cards to select
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
; output:
;	hTempList = $ff-terminated list with deck indices of discarded Energy cards
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


; the turn holder's Active Pokemon does 10 damage to itself and 1 or more cards
; from the turn holder's discard pile are moved to their hand
; input:
;	hTempList = $ff-terminated list with deck indices of 
;	            discarded Energy cards to move to the hand
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
	call MoveCardFromDiscardPileToHand
	jr .loop_cards

; show the selected card(s) on the screen if this effect wasn't initiated by the Player
.done
	call IsPlayerTurn
	ret c ; return if it's the Player's turn
	bank1call DisplayCardListDetails
	ret


; attaches 1 or more Energy cards in the turn holder's discard pile to the Active Pokemon
; this function isn't normally used. the real selection effect is located in
; engine/duel/ai/core.asm under the AISelectSpecialAttackParameters function.
; preserves bc and de
; input:
;	hTempList = $ff-terminated list with deck indices of discarded Energy cards to attach
EnergyAbsorption_AttachEffect:
	ld hl, hTempList
.loop
	ld a, [hli]
	cp $ff
	ret z ; reached the end of the list
	push hl
	call RemoveCardFromDiscardPile
	get_turn_duelist_var
	ld [hl], CARD_LOCATION_ARENA
	pop hl
	jr .loop


;---------------------------------------------------------------------------------
; (5) ATTACK EFFECTS THAT BENEFIT THE PLAYER'S POKEMON ARE NEXT. (MAINLY HEALING)
;---------------------------------------------------------------------------------

; if the given card being removed from the play area is the Active Pokemon,
; then the Player needs to choose a Benched Pokemon to move to the Arena.
; used for Pokemon Powers, so the selection process can be cancelled with the B button
; input:
;	[hTemp_ffa0] = play area location offset of the Pokemon being removed (PLAY_AREA_* constant)
; output:
;	carry = set:  if the operation was cancelled by the Player (with B button)
;	[hTempPlayAreaLocation_ffa1] = play area location offset of the chosen Benched Pokemon
PossibleSwitch_PlayerSelection:
	ldh a, [hTemp_ffa0]
	or a
	ret nz ; return if user isn't the Active Pokemon

	ldtx hl, SelectNewActivePokemonText
	call DrawWideTextBox_WaitForInput
	bank1call InitVarsAndOpenPlayAreaScreenForSelection_OnlyBench
;	ret c ; exit if the B button was pressed
	ldh [hTempPlayAreaLocation_ffa1], a
	ret


; handles the Player's selection of a Benched Pokémon for a damage-dealing attack (which doesn't use BenchedPokemonCheck)
; output:
;	carry = set:  if the operation was cancelled by the Player (with B button)
;	[hTemp_ffa0] = play area location offset of a Pokémon on own Bench (PLAY_AREA_* constant, -1 if none)
AlsoSwitchAfterAttack_PlayerSelection:
	ld a, DUELVARS_NUMBER_OF_POKEMON_IN_PLAY_AREA
	get_turn_duelist_var
	cp 1
	jr z, SwitchAfterAttack_AISelection.no_bench
;	fallthrough

; handles the Player's selection of a Benched Pokémon for an attack that has BenchedPokemonCheck as an Initial_Effect_1 command
; output:
;	carry = set:  if the operation was cancelled by the Player (with B button)
;	[hTemp_ffa0] = play area location offset of a Pokémon on own Bench (PLAY_AREA_* constant)
SwitchAfterAttack_PlayerSelection:
	ldtx hl, SelectNewActivePokemonText
	call DrawWideTextBox_WaitForInput
	call InitPlayAreaScreenVars_OnlyBench
	inc a ; $00 -> $01
	ld [hl], a ; wPlayAreaSelectAction = FORCED_SWITCH_CHECK_MENU
	bank1call OpenPlayAreaScreenForSelection
;	ret c ; exit if the B button was pressed
	ldh [hTemp_ffa0], a
	ret


; AI picks a random Benched Pokemon.
; this function isn't normally used. the real selection effect is located in
; engine/duel/ai/core.asm under the AISelectSpecialAttackParameters function.
; preserves bc and de
; output:
;	[hTemp_ffa0] = play area location offset of a random Benched Pokemon (PLAY_AREA_* constant, -1 if none)
SwitchAfterAttack_AISelection:
	ld a, DUELVARS_NUMBER_OF_POKEMON_IN_PLAY_AREA
	get_turn_duelist_var
	dec a ; can't select the Active Pokémon
	jr z, .no_bench
	call Random
	inc a ; first value should be PLAY_AREA_BENCH_1, not PLAY_AREA_ARENA
	ldh [hTemp_ffa0], a
	ret
.no_bench
	ld a, -1
	ldh [hTemp_ffa0], a
	ret


; switches the turn holder's Active Pokemon with a given Benched Pokemon
; preserves bc and hl
; input:
;	[hTemp_ffa0] = location of the Benched Pokémon to switch with Active (PLAY_AREA_* constant, -1 if none)
SwitchAfterAttack_SwitchEffect:
	ldh a, [hTemp_ffa0]
	ld e, a
	inc a ; cp -1
	ret z
	call SwapArenaWithBenchPokemon
	xor a
	ld [wDuelDisplayedScreen], a
	ret


; preserves all registers except af
GaleAnimationEffect:
	ld a, ATK_ANIM_GALE
	ld [wLoadedAttackAnimation], a
	ret


; switches each player's Active Pokemon with a random Pokemon from the Bench
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
	; Defending Pokémon is Knocked Out
	bank1call HandleDestinyBondSubstatus
.skip_destiny_bond
	rst SwapTurn
	call .SwitchWithRandomBenchPokemon
	rst SwapTurn
	jr c, .SwitchWithRandomBenchPokemon ; skip clearing damage if there was no switch
; clear dealt damage because the Pokemon was switched
	xor a
	ld hl, wDealtDamage
	ld [hli], a
	ld [hl], a
;	fallthrough for switching the attacking Pokemon

; preserves bc
; output:
;	carry = set:  if there were no Pokémon on the Bench to switch with the Active Pokémon
.SwitchWithRandomBenchPokemon
	ld a, DUELVARS_NUMBER_OF_POKEMON_IN_PLAY_AREA
	get_turn_duelist_var
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


; flips a coin, and if tails, cancels the attack effect/animation
; preserves hl
; output:
;	[hTemp_ffa0] = result of the coin toss (0 = tails, 1 = heads)
Healing50Percent_FlipEffect:
	ldtx de, AttackSuccessCheckText
	call TossCoin
	ldh [hTemp_ffa0], a
	ret c ; return if heads
	xor a ; ATK_ANIM_NONE
	ld [wLoadedAttackAnimation], a
	jp SetWasUnsuccessful


; if coin toss result was heads, removes a damage counter from the turn holder's Active Pokemon
; preserves de
; input:
;	[hTemp_ffa0] = result of the coin toss (0 = tails, 1 = heads)
Healing50Percent_Heal10Effect:
	ldh a, [hTemp_ffa0]
	or a
	ret z ; return if coin toss result was tails
	ld e, PLAY_AREA_ARENA
	call GetCardDamageAndMaxHP
	or a
	ret z ; return if no damage counters
	ld a, DUELVARS_ARENA_CARD_HP
	get_turn_duelist_var
	add 10
	ld [hl], a
	ret


; if the attack did damage, removes a damage counter from the Attacking Pokemon
Drain10Effect:
	ld hl, wDealtDamage
	ld a, [hli]
	or a
	ret z ; return if no damage was dealt
;	fallthrough

; removes a damage counter from the turn holder's Active Pokemon
Heal10_HealEffect:
	ld de, 10
	jr ApplyAndAnimateHPRecovery


; heals damage from the Attacking Pokemon equal
; to half the damage dealt by the attack.
; assumes damage is only 1 byte (maximum of 250).
DrainHalfEffect:
	ld hl, wDealtDamage
	ld a, [hli]  ; wDamageEffectiveness
	or a
	ret z  ; return if no damage was dealt
	call HalfARoundedUp
	ld e, a
	ld d, [hl]
	jr ApplyAndAnimateHPRecovery

; accounts for damage amounts that are greater than 250.
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


; heals damage from the Attacking Pokemon equal to the damage dealt by the attack
DrainAllEffect:
	ld hl, wDealtDamage
	ld e, [hl]
	inc hl
	ld d, [hl]
;	fallthrough

; applies HP recovery on Pokemon after an attack
; with HP recovery effect, and handles its animation.
; input:
;	de = HP amount to recover
ApplyAndAnimateHPRecovery:
	push de
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
	lb bc, PLAY_AREA_ARENA, $01 ; WEAKNESS
	ldh a, [hWhoseTurn]
	ld h, a
	call PlayAttackAnimation

; compare HP to be restored with max HP.
; if HP to be restored would cause HP to
; be larger than max HP, cap it accordingly
	ld e, PLAY_AREA_ARENA
	call GetCardDamageAndMaxHP
	ld b, $00
	pop de
	ld a, DUELVARS_ARENA_CARD_HP
	get_turn_duelist_var
	add e
	ld e, a
	ld a, 0
	adc d
	ld d, a
	; de = current HP + recovery amount from input
	; bc = max HP of card
	call CompareDEtoBC
	jr c, .skip_cap
	; cap de to value in bc
	ld e, c
	ld d, b
.skip_cap
	ld [hl], e ; apply new HP to the Active Pokemon
	jp WaitAttackAnimation


; heals all damage from the turn holder's Active Pokemon
Recover_HealEffect:
	ld e, PLAY_AREA_ARENA
	call GetCardDamageAndMaxHP
	ld e, a ; all damage for recovery
	ld d, 0
	jr ApplyAndAnimateHPRecovery


; the turn holder's Active Pokemon recovers from any Special Conditions
RemoveSpecialConditionsEffect:
	ld a, ATK_ANIM_FULL_HEAL
	call PlayTrainerEffectAnimation
	ld a, DUELVARS_ARENA_CARD_STATUS
	get_turn_duelist_var
	ld [hl], NO_STATUS
	bank1call DrawDuelHUDs
	ret


;---------------------------------------------------------------------------------
; (6) ATTACK EFFECTS THAT CAUSE SPECIAL CONDITIONS ARE NEXT
;---------------------------------------------------------------------------------

; flips a coin, and if heads, the opponent's Active Pokemon becomes Asleep.
Sleep50PercentEffect:
	ldtx de, SleepCheckText
	call TossCoin
	ret nc ; return if tails
;	fallthrough

; the opponent's Active Pokemon becomes Asleep.
SleepEffect:
	lb bc, PSN_DBLPSN, ASLEEP
	jr QueueStatusCondition


; flips a coin, and if heads, the opponent's Active Pokemon becomes Confused.
Confusion50PercentEffect:
	ldtx de, ConfusionCheckText
	call TossCoin
	ret nc ; return if tails
;	fallthrough

; the opponent's Active Pokemon becomes Confused.
ConfusionEffect:
	lb bc, PSN_DBLPSN, CONFUSED
	jr QueueStatusCondition


; flips a coin, and if heads, the opponent's Active Pokemon becomes Paralyzed.
Paralysis50PercentEffect:
	ldtx de, ParalysisCheckText
	call TossCoin
	ret nc ; return if tails
;	fallthrough

; the opponent's Active Pokemon becomes Paralyzed.
ParalysisEffect: 
	lb bc, PSN_DBLPSN, PARALYZED
	jr QueueStatusCondition


; the opponent's Active Pokémon becomes double Poisoned.
; (it receives 2 damage counters after each turn)
DoublePoisonEffect:
	lb bc, CNF_SLP_PRZ, DOUBLE_POISONED
	jr QueueStatusCondition


; flips a coin, and if heads, the opponent's Active Pokemon becomes Poisoned.
Poison50PercentEffect:
	ldtx de, PoisonCheckText
	call TossCoin
	ret nc ; return if tails
;	fallthrough

; the opponent's Active Pokemon becomes Poisoned.
PoisonEffect:
	lb bc, CNF_SLP_PRZ, POISONED
;	fallthrough

; tries to apply the Special Condition in register c to the opponent's Active Pokemon
; input:
;	c = special condition to inflict
;	b = special conditions to mask (the opposite nibble)
; output:
;	carry = set:  if the special condition was applied
QueueStatusCondition:
	ldh a, [hWhoseTurn]
	ld hl, wWhoseTurn
	cp [hl]
	jr nz, .can_induce_status
	rst SwapTurn
	call CheckIfActiveCardCanBeAffectedByStatus
	rst SwapTurn
	jr nc, .cant_induce_status

.can_induce_status
	ld hl, wStatusConditionQueueIndex
	push hl
	ld e, [hl]
	ld d, $0
	ld hl, wStatusConditionQueue
	add hl, de
	rst SwapTurn
	ldh a, [hWhoseTurn]
	ld [hli], a
	rst SwapTurn
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

.cant_induce_status
	ld a, c
	ld [wNoEffectFromWhichStatus], a
;	fallthrough

SetNoEffectFromStatus:
	ld a, EFFECT_FAILED_NO_EFFECT
	ld [wEffectFailed], a
	ret


; flips a coin and gives the opponent's Active Pokemon a Special Condition.
; if heads, it becomes Poisoned, and if tails, it becomes Confused.
PoisonOrConfusionEffect:
	ldtx de, PoisonedIfHeadsConfusedIfTailsText
	call TossCoin
	jr c, PoisonEffect
	jr ConfusionEffect


; flips a coin, and if heads, the opponent's Active Pokemon becomes Paralyzed.
; if tails, the attack's damage and effect are negated.
AllOrNothingParalysisEffect:
	ldtx de, AttackSuccessCheckText
	call TossCoin
	jr c, ParalysisEffect
	; unsuccessful
	xor a ; ATK_ANIM_NONE
	ld [wLoadedAttackAnimation], a
	call SetDefiniteDamage
	jp SetWasUnsuccessful


; flips a coin, and if heads, the opponent's Active Pokemon becomes Poisoned.
; if tails, changes the attack's animation and [wEffectFailed]
; (because the attack doesn't do damage and had no other effect)
SpitPoison_Poison50PercentEffect:
	ldtx de, PoisonCheckText
	call TossCoin
	jr c, PoisonEffect
	; unsuccessful
	ld a, ATK_ANIM_SPIT_POISON_SUCCESS
	ld [wLoadedAttackAnimation], a
	jr SetNoEffectFromStatus


; preserves bc
Toxic_AIEffect:
	ld a, 20
	lb de, 20, 20
	jr UpdateExpectedAIDamage_AccountForPoison


; preserves bc
InflictPoison_AIEffect:
	ld a, 10
	lb de, 10, 10
	jr UpdateExpectedAIDamage_AccountForPoison


; preserves bc
MayInflictPoison_AIEffect:
	ld a, 5
	lb de, 0, 10
;	fallthrough

; Stores information about the attack damage for AI purposes,
; taking into account poison damage between turns.
; if target is already Poisoned:
;	[wAIMinDamage] <- [wDamage]
;	[wAIMaxDamage] <- [wDamage]
; else:
;	[wAIMinDamage] <- [wDamage] + d
;	[wAIMaxDamage] <- [wDamage] + e
;	[wDamage]      <- [wDamage] + a
; preserves bc and de
; input:
;	a = average damage that would be added
;	d = minimum damage that would be added
;	e = maximum damage that would be added
UpdateExpectedAIDamage_AccountForPoison:
	push af
	ld a, DUELVARS_ARENA_CARD_STATUS
	call GetNonTurnDuelistVariable
	and POISONED | DOUBLE_POISONED
	jr z, UpdateExpectedAIDamage.skip_push_af
	pop af
	; Defending Pokémon is already Poisoned, so use default damage
;	fallthrough

; overwrites wAIMinDamage and wAIMaxDamage with value in wDamage
; preserves all registers except af
SetDefiniteAIDamage:
	ld a, [wDamage]
	ld [wAIMinDamage], a
	ld [wAIMaxDamage], a
	ret


; Sets some variables for AI use
;	[wAIMinDamage] <- [wDamage] + d
;	[wAIMaxDamage] <- [wDamage] + e
;	[wDamage]      <- [wDamage] + a
; preserves bc and de
; input:
;	a = average damage that would be added
;	d = minimum damage that would be added
;	e = maximum damage that would be added
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


; flips a coin, and if heads, the opponent's Active Pokemon becomes Asleep.
; if tails, calls SetWasUnsuccessful because the attack had no other effect/damage.
Sleep50PercentWithoutDamageEffect:
	call Sleep50PercentEffect
	jp nc, SetWasUnsuccessful
	ret


; flips a coin, and if heads, the opponent's Active Pokemon becomes Poisoned.
; if tails, calls SetWasUnsuccessful because the attack had no other effect/damage.
Confusion50PercentWithoutDamageEffect:
	call Confusion50PercentEffect
	jp nc, SetWasUnsuccessful
	ret


; flips a coin, and if heads, the opponent's Active Pokemon becomes Poisoned and Confused.
PoisonConfusion50PercentEffect:
	ldtx de, VenomPowderCheckText
	call TossCoin
	ret nc ; return if tails
	; heads
	call PoisonEffect
	call ConfusionEffect
	ret c ; return if the Special Conditions were applied
	ld a, CONFUSED | POISONED
	ld [wNoEffectFromWhichStatus], a
	ret


; both Active Pokemon become Confused.
ConfuseBothActivePokemonEffect:
	call ConfusionEffect
	rst SwapTurn
	call ConfusionEffect
	jp SwapTurn


;---------------------------------------------------------------------------------
; (7) ATTACK EFFECTS THAT CAUSE SUBSTATUS1 EFFECTS ARE NEXT.
; THESE ARE BENEFICIAL EFFECTS THAT ARE APPLIED TO THE PLAYER'S ACTIVE POKEMON.
;---------------------------------------------------------------------------------

; preserves bc and de
SwordsDanceEffect:
	ld a, [wTempTurnDuelistCardID]
	cp SCYTHER
	ret nz ; return if Scyther isn't the Active Pokemon
	ld a, SUBSTATUS1_NEXT_TURN_DOUBLE_DAMAGE
;	fallthrough

; applies a status condition of type 1 to the turn holder's Active Pokemon
; preserves af, bc, and de
; input:
;	a = SUBSTATUS1_* constant
ApplySubstatus1ToDefendingCard:
	push af
	ld a, DUELVARS_ARENA_CARD_SUBSTATUS1
	get_turn_duelist_var
	pop af
	ld [hli], a
	ret


; preserves bc and de
FocusEnergyEffect:
	ld a, [wTempTurnDuelistCardID]
	cp VAPOREON_LV29
	ret nz ; return if VaporeonLv29 isn't the Active Pokemon
	ld a, SUBSTATUS1_NEXT_TURN_DOUBLE_DAMAGE
	jr ApplySubstatus1ToDefendingCard


; prevents all damage and attack effects done to the turn holder's Active Pokemon next turn
; preserves bc and de
ImmunityEffect:
	ld a, SUBSTATUS1_IMMUNITY
	jr ApplySubstatus1ToDefendingCard


; flips a coin, and if heads, prevents all damage and attack effects
; done to the turn holder's Active Pokemon next turn
Immunity50PercentEffect:
	ldtx de, IfHeadsDoNotReceiveDamageOrEffectText
	call TossCoin
	ret nc ; return if tails
	ld a, ATK_ANIM_AGILITY_PROTECT
	ld [wLoadedAttackAnimation], a
	ld a, SUBSTATUS1_IMMUNITY
	jr ApplySubstatus1ToDefendingCard


; flips a coin, and if tails, sets the attack damage to 0 and cancels the animation.
; if heads, prevents all damage and attack effects done to the Attacking Pokemon next turn.
AllOrNothingImmunityEffect:
	ldtx de, AttackSuccessCheckText
	call TossCoin
	jr c, .heads
	; tails
	xor a ; ATK_ANIM_NONE
	ld [wLoadedAttackAnimation], a
	call SetDefiniteDamage
	jp SetWasUnsuccessful
.heads
	ld a, ATK_ANIM_AGILITY_PROTECT
	ld [wLoadedAttackAnimation], a
	ld a, SUBSTATUS1_IMMUNITY
	jr ApplySubstatus1ToDefendingCard


; flips a coin, and if heads, prevents all damage done
; to the turn holder's Active Pokemon next turn
DamageProtection50PercentEffect:
	ldtx de, IfHeadsNoDamageNextTurnText
	call TossCoin
	jp c, .heads
	; tails
	xor a ; ATK_ANIM_NONE
	ld [wLoadedAttackAnimation], a
	jp SetWasUnsuccessful
.heads
	ld a, SUBSTATUS1_NO_DAMAGE
	jr ApplySubstatus1ToDefendingCard


; prevents all damage done to the turn holder's Active Pokemon next turn,
; as long as it's 30 or less
; preserves bc and de
HardenEffect:
	ld a, SUBSTATUS1_HARDEN
	jr ApplySubstatus1ToDefendingCard


; prevents 10 damage done to the turn holder's Active Pokemon next turn
; preserves bc and de
Prevent10DamageEffect:
	ld a, SUBSTATUS1_REDUCE_BY_10
	jr ApplySubstatus1ToDefendingCard


; prevents 20 damage done to the turn holder's Active Pokemon next turn
; preserves bc and de
Prevent20DamageEffect:
	ld a, SUBSTATUS1_REDUCE_BY_20
	jr ApplySubstatus1ToDefendingCard


; halves all damage done to the turn holder's Active Pokemon next turn (damage is rounded down)
; preserves bc and de
HalveDamageEffect:
	ld a, SUBSTATUS1_HALVE_DAMAGE
	jr ApplySubstatus1ToDefendingCard


; KO's the opponent's Active Pokemon if the turn holder's Active Pokemon is KO'd next turn
; preserves bc and de
DestinyBondEffect:
	ld a, SUBSTATUS1_DESTINY_BOND
	jr ApplySubstatus1ToDefendingCard


;---------------------------------------------------------------------------------
; (8) ATTACK EFFECTS THAT CAUSE SUBSTATUS2 EFFECTS ARE NEXT.
; THESE ARE HARMFUL EFFECTS THAT ARE APPLIED TO THE OPPONENT'S ACTIVE POKEMON.
; (THE LAST FUNCTION IS ACTUALLY SUBSTATUS3)
;---------------------------------------------------------------------------------

; the Defending Pokémon's attacks do 10 less damage during the next turn
ReduceBy10Effect:
	ld a, SUBSTATUS2_REDUCE_BY_10
	jr ApplySubstatus2ToDefendingCard


; the Defending Pokémon's attacks do 20 less damage during the next turn
ReduceBy20Effect:
	ld a, SUBSTATUS2_REDUCE_BY_20
	jr ApplySubstatus2ToDefendingCard


; flips a coin, and if heads, the Defending Pokemon can't retreat during the next turn
NoRetreat50PercentEffect:
	ldtx de, AcidCheckText
	call TossCoin
	ret nc ; return if tails
	ld a, SUBSTATUS2_UNABLE_RETREAT
	jr ApplySubstatus2ToDefendingCard


; the Defending Pokemon can't retreat during the next turn
NoRetreatEffect:
	ld a, SUBSTATUS2_UNABLE_RETREAT
	jr ApplySubstatus2ToDefendingCard


; the Defending Pokemon must flip a coin to attack next turn
SmokescreenEffect:
	ld a, SUBSTATUS2_SMOKESCREEN
;	fallthrough

; applies a status condition of type 2 to the opponent's Active Pokemon,
; unless this is prevented by wNoDamageOrEffect
; input:
;	a = SUBSTATUS2_* constant
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
	jp nz, DrawWideTextBox_PrintText
	ret


; flips a coin, and if heads, the Defending Pokemon can't attack during the next turn
CannotAttack50PercentEffect:
	ldtx de, IfHeadsOpponentCannotAttackText
	call TossCoin
	ret nc ; return if tails
	ld a, SUBSTATUS2_CANNOT_ATTACK
	jr ApplySubstatus2ToDefendingCard


; flips a coin, and if heads, the Defending Pokemon can't attack
; the turn holder's Active Pokemon during the next turn
CannotAttackThis50PercentEffect:
	ldtx de, IfHeadsOpponentCannotAttackText
	call TossCoin
	jp c, .heads
	; tails
	xor a ; ATK_ANIM_NONE
	ld [wLoadedAttackAnimation], a
	jp SetWasUnsuccessful
.heads
	ld a, SUBSTATUS2_CANNOT_ATTACK_THIS
	jr ApplySubstatus2ToDefendingCard


; handles the Player's selection of an opponent's attack for Amnesia
; output:
;	carry = set:  if the operation was cancelled by the Player (with B button)
;	[hTemp_ffa0] & a = selected attack index (0 = first attack, 1 = second attack)
Amnesia_PlayerSelection:
	ldtx hl, ChooseAttackOpponentWillNotBeAbleToUseText
	call DrawWideTextBox_WaitForInput
	call HandleDefendingPokemonAttackSelection
;	ret c ; exit if the B button was pressed
	ld a, e
	ldh [hTemp_ffa0], a
	ret


; handles the AI's selection of an attack on the Player's Active Pokemon
; output:
;	[hTemp_ffa0] & a = selected attack index (0 = first attack, 1 = second attack)
Amnesia_AISelection:
; load the Defending Pokemon's attacks
	rst SwapTurn
	ld e, PLAY_AREA_ARENA
	call GetPlayAreaCardAttachedEnergies
	call HandleEnergyBurn
	ld a, DUELVARS_ARENA_CARD
	get_turn_duelist_var
	ld d, a
	call LoadCardDataToBuffer2_FromDeckIndex
	ld hl, wLoadedCard2Atk1Name
	ld a, [hli]
	or [hl]
	jr z, .second_attack ; done if card doesn't have an attack 1 name

; if the Defending Pokemon has enough Energy for its second attack, choose it
	ld e, SECOND_ATTACK
	bank1call _CheckIfEnoughEnergiesToAttack
	jr nc, .chosen
; otherwise, choose the first attack, unless its a Pokemon Power
	ld e, FIRST_ATTACK_OR_PKMN_POWER
	ld a, [wLoadedCard2Atk1Category]
	cp POKEMON_POWER
	jr nz, .chosen
; if it's a Pokemon Power, choose the second attack.
.second_attack
	ld e, SECOND_ATTACK
.chosen
	ld a, e
	ldh [hTemp_ffa0], a
	jp SwapTurn


; applies Amnesia effect on the Defending Pokemon for attack index in hTemp_ffa0
; input:
;	[hTemp_ffa0] = which attack to disable (0 = first attack, 1 = second attack)
AttackDisableEffect:
	ld a, SUBSTATUS2_AMNESIA
	call ApplySubstatus2ToDefendingCard
	ld a, [wNoDamageOrEffect]
	or a
	ret nz ; return if the attack had no effect

; set selected attack as disabled
	ld a, DUELVARS_ARENA_CARD_DISABLED_ATTACK_INDEX
	call GetNonTurnDuelistVariable
	ldh a, [hTemp_ffa0]
	ld [hl], a

	ld l, DUELVARS_ARENA_CARD_LAST_TURN_EFFECT
	ld [hl], LAST_TURN_EFFECT_AMNESIA

	call IsPlayerTurn
	ret c ; return if it's the Player's turn

; the rest of the routine is for the opponent to announce which attack was disabled
	rst SwapTurn
	ld a, DUELVARS_ARENA_CARD
	get_turn_duelist_var
	ld d, a
	ldh a, [hTemp_ffa0]
	ld e, a
	call GetAttackName
	call LoadTxRam2
	ldtx hl, WasChosenForTheEffectOfAmnesiaText
	call DrawWideTextBox_WaitForInput
	jp SwapTurn


; handles the Player's selection of an attack on the opponent's Active Pokemon
; output:
;	d = Defending Pokemon's card index
;	e = selected attack index (0 = first attack, 1 = second attack)
;	carry = set:  if no attack was selected
HandleDefendingPokemonAttackSelection:
	bank1call DrawDuelMainScene
	rst SwapTurn
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
	bit B_PAD_B, a
	jr nz, .set_carry ; exit if the B button was pressed
	and PAD_START
	jr nz, .open_atk_page
	call HandleMenuInput
	jr nc, .loop_input
	cp -1
	jr z, .loop_input ; loop back if the B button was pressed

; an attack was selected
	add a
	ld e, a
	ld d, $00
	ld hl, wDuelTempList
	add hl, de
	ld d, [hl]
	inc hl
	ld e, [hl]
	or a
	jp SwapTurn

.set_carry
	scf
	jp SwapTurn

.open_atk_page
	ldh a, [hCurMenuItem]
	ldh [hCurSelectionItem], a
	ld a, DUELVARS_ARENA_CARD
	get_turn_duelist_var
	call LoadCardDataToBuffer1_FromDeckIndex
	bank1call OpenAttackPage
	rst SwapTurn
	bank1call DrawDuelMainScene
	rst SwapTurn
	jr .start

.menu_parameters
	db 1, 13 ; cursor x, cursor y
	db 2 ; y displacement between items
	db 2 ; number of items
	db SYM_CURSOR_R ; cursor tile number
	db SYM_SPACE ; tile behind cursor
	dw NULL ; function pointer if non-0


; preserves bc
; input:
;	d = deck index of the card (0-59)
; 	e = attack index (0 = first attack, 1 = second attack)
; output:
;	hl = text ID for the attack's name
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


; preserves bc and de
; output:
;	hl = ID for notification text:  if the below condition is true
;	carry = set:  if the Defending Pokemon has no Weakness
Conversion1_WeaknessCheck:
	rst SwapTurn
	ld a, DUELVARS_ARENA_CARD
	get_turn_duelist_var
	call LoadCardDataToBuffer2_FromDeckIndex
	rst SwapTurn
	ld a, [wLoadedCard2Weakness]
	or a
	ret nz ; return if the Defending Pokemon has a Weakness
	ldtx hl, NoWeaknessText
	scf
	ret


; output:
;	carry = set:  if the operation was cancelled by the Player (with B button)
;	[hTemp_ffa0] & a = selected type/color (TYPE_PKMN_* constant)
Conversion1_PlayerSelection:
	ldtx hl, ChooseWeaknessYouWishToChangeText
	xor a ; PLAY_AREA_ARENA
	call HandleColorChangeScreen
;	ret c ; exit if the B button was pressed
	ldh [hTemp_ffa0], a
	ret


; changes the the Weakness of the opponent's Active Pokemon to a given type
; input:
;	[hTemp_ffa0] =  selected type/color (TYPE_PKMN_* constant)
Conversion1_ChangeWeaknessEffect:
	call HandleNoDamageOrEffect
	ret c ; return if the attack had no effect

; apply changed weakness
	ld a, DUELVARS_ARENA_CARD_CHANGED_WEAKNESS
	call GetNonTurnDuelistVariable
	ldh a, [hTemp_ffa0]
	call TranslateColorToWR
	ld [hl], a
	ld l, DUELVARS_ARENA_CARD_LAST_TURN_CHANGE_WEAK
	ld [hl], a

; print text box
	rst SwapTurn
	ldtx hl, ChangedTheWeaknessOfPokemonToColorText
	call PrintActivePokemonNameAndColorText
	rst SwapTurn

; apply substatus
	ld a, SUBSTATUS2_CONVERSION2
	jp ApplySubstatus2ToDefendingCard


; preserves bc and de
; output:
;	hl = ID for notification text:  if the below condition is true
;	carry = set:  if the turn holder's Active Pokemon has no Resistance
Conversion2_ResistanceCheck:
	ld a, DUELVARS_ARENA_CARD
	get_turn_duelist_var
	call LoadCardDataToBuffer2_FromDeckIndex
	ld a, [wLoadedCard2Resistance]
	or a
	ret nz ; return if the Active Pokemon has a Resistance
	ldtx hl, NoResistanceText
	scf
	ret


; output:
;	carry = set:  if the operation was cancelled by the Player (with B button)
;	[hTemp_ffa0] & a = selected type/color (TYPE_PKMN_* constant)
Conversion2_PlayerSelection:
	ldtx hl, ChooseResistanceYouWishToChangeText
	ld a, $80
	call HandleColorChangeScreen
;	ret c ; exit if the B button was pressed
	ldh [hTemp_ffa0], a
	ret


; AI picks the color of the opponent's Active Pokemon, unless it's Colorless
; output:
;	[hTemp_ffa0] & a = selected type/color (TYPE_PKMN_* constant)
Conversion2_AISelection:
	rst SwapTurn
	ld a, DUELVARS_ARENA_CARD
	get_turn_duelist_var
	call GetCardTypeFromDeckIndex_SaveDE
	rst SwapTurn
	cp COLORLESS
	jr z, .is_colorless
	ldh [hTemp_ffa0], a
	ret

.is_colorless
	rst SwapTurn
	call AISelectConversionColor
	jp SwapTurn


; changes the Resistance of the turn holder's Active Pokemon to a given type
; input:
;	[hTemp_ffa0] = selected type/color (TYPE_PKMN_* constant)
Conversion2_ChangeResistanceEffect:
	ld a, DUELVARS_ARENA_CARD_CHANGED_RESISTANCE
	get_turn_duelist_var
	ldh a, [hTemp_ffa0]
	call TranslateColorToWR
	ld [hl], a
	ldtx hl, ChangedTheResistanceOfPokemonToColorText
;	fallthrough

; prints text that requires card name and color,
; with the card name of the player's Active Pokemon
; and color in [hTemp_ffa0].
; input:
;	hl = ID of the text to print
;	[hTemp_ffa0] = selected type/color (TYPE_PKMN_* constant)
PrintActivePokemonNameAndColorText:
	push hl
	ld a, DUELVARS_ARENA_CARD
	get_turn_duelist_var
	call LoadCardDataToBuffer1_FromDeckIndex
	ldh a, [hTemp_ffa0]
	call LoadCardNameAndInputColor
	pop hl
	jp DrawWideTextBox_PrintText


; handles the Player's selection of a type/color (excluding Colorless).
; used for Shift Pokemon Power and Conversion attacks.
; input:
;	a  = play area location offset (PLAY_AREA_* constant), with:
;	     bit 7 not set if it's applying to opponent's card
;	     bit 7 set if it's applying to player's card
;	hl = ID of the text to be printed in the bottom box
; output:
;	a = selected type/color (TYPE_PKMN_* constant)
;	carry = set:  if the operation was cancelled by the Player (with B button)
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
	cp -1
	scf
	ret z ; return carry if the B button was pressed

; A button was pressed
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
	get_turn_duelist_var
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
	ld [hl], TX_END
	lb de, 7, 0
	ld hl, wDefaultText
	call InitTextPrinting_ProcessText

; list all the colors
	ld hl, ShiftMenuData
	call PlaceTextItems

; print card's color, resistance and weakness
	ld a, [wTempPlayAreaLocation_cceb]
	call GetPlayAreaCardColor
	inc a ; skip SYM_SPACE tile
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
	; x, y, text ID
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
;	[wTxRam2]   <- wLoadedCard1Name
;	[wTxRam2_b] <- input color as text symbol
; preserves bc
; input:
;	a = selected type/color (TYPE_PKMN_* constant)
;	[wLoadedCard1Name] = text ID for a card name (2 bytes)
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
	ld a, [hl]
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

; handles AI logic for selecting a new Weakness/Resistance.
; Conversion1 looks in own Bench for a non-Colorless Pokemon that can attack.
; Conversion2 looks in opponent's Bench for a non-Colorless Pokemon that can attack.
; output:
;	[hTemp_ffa0] & a = selected type/color (TYPE_PKMN_* constant)
AISelectConversionColor:
	ld a, DUELVARS_NUMBER_OF_POKEMON_IN_PLAY_AREA
	get_turn_duelist_var
	ld d, a
	ld e, PLAY_AREA_ARENA
	jr .next_pkmn_atk

; look for a non-Colorless Benched Pokemon
; that has enough Energy to use an attack.
.loop_atk
	push de
	call GetPlayAreaCardAttachedEnergies
	ld a, e
	add DUELVARS_ARENA_CARD
	get_turn_duelist_var
	ld d, a
	call LoadCardDataToBuffer1_FromDeckIndex
	ld a, [wLoadedCard1Type]
	cp COLORLESS
	jr z, .skip_pkmn_atk ; skip Colorless Pokemon
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
; next, look for a non-Colorless Benched Pokemon
; that has any Energy cards attached.
	ld d, e ; number of Pokemon in the play area
	ld e, PLAY_AREA_ARENA
	jr .next_pkmn_energy

.loop_energy
	push de
	call GetPlayAreaCardAttachedEnergies
;	ld a, [wTotalAttachedEnergies] ; already loaded
	or a
	jr z, .skip_pkmn_energy
	ld a, e
	add DUELVARS_ARENA_CARD
	get_turn_duelist_var
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

; otherwise, just select a random color
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


; preserves bc and de
PreventTrainersEffect:
	ld a, DUELVARS_ARENA_CARD_SUBSTATUS3
	call GetNonTurnDuelistVariable
	set SUBSTATUS3_HEADACHE_F, [hl]
	ret


;---------------------------------------------------------------------------------
; (9) ANY OTHER NON-DAMAGE ATTACK EFFECTS THAT AFFECT THE OPPONENT'S POKEMON ARE NEXT.
;---------------------------------------------------------------------------------

; handles the Player's selection of an Energy card attached to the opponent's Active Pokemon
; output:
;	carry = set:  if the Defending Pokémon doesn't have any attached Energy cards
;	[hTemp_ffa0] = deck index of an Energy card attached to the Defending Pokémon (0-59, -1 if none)
DiscardEnergyDefendingPokemon_PlayerSelection:
	rst SwapTurn
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

	ldh [hTemp_ffa0], a ; store selected card to discard
	jp SwapTurn

.no_energy
	ld a, -1
	ldh [hTemp_ffa0], a
	jp SwapTurn


; AI tries to pick an attached Double Colorless Energy. if none are found,
; AI tries to pick an Energy card that is useful for the Defending Pokémon.
; if none are found again, then the Energy card is chosen at random.
; output:
;	[hTemp_ffa0] = deck index of an Energy card attached to the Defending Pokémon (0-59, -1 if none)
DiscardEnergyDefendingPokemon_AISelection:
	rst SwapTurn
	xor a ; PLAY_AREA_ARENA
	farcall PickAttachedEnergyCardToRemove
	ldh [hTemp_ffa0], a
	jp SwapTurn


; discards a given Energy card from the opponent's Active Pokemon
; input:
;	[hTemp_ffa0] = deck index of the Energy card to discard from the Defending Pokémon (0-59, -1 if none)
DefendingPokemonEnergy_DiscardEffect:
	call HandleNoDamageOrEffect
	ret c ; return if the attack had no effect
	
	; check if an Energy card was chosen to discard
	ldh a, [hTemp_ffa0]
	cp -1
	ret z ; return if none selected

	; discard an Energy from the Defending Pokemon
	; this doesn't update DUELVARS_ARENA_CARD_LAST_TURN_EFFECT
	rst SwapTurn
	call PutCardInDiscardPile
	ld a, DUELVARS_ARENA_CARD_LAST_TURN_EFFECT
	get_turn_duelist_var
	ld [hl], LAST_TURN_EFFECT_DISCARD_ENERGY
	jp SwapTurn


; handles the selection of a forced switch by the link/AI opponent or by the Player
; output:
;	a & [hTempPlayAreaLocation_ff9d] = play area location offset of the chosen Benched Pokemon
DuelistSelectForcedSwitch:
	ld a, DUELVARS_DUELIST_TYPE
	call GetNonTurnDuelistVariable
	cp DUELIST_TYPE_LINK_OPP
	jr z, .link_opp

	cp DUELIST_TYPE_PLAYER
	jr z, .player

; AI opponent
	rst SwapTurn
	call AIDoAction_ForcedSwitch
	rst SwapTurn

	ld a, [wPlayerAttackingAttackIndex]
	ld e, a
	ld a, [wPlayerAttackingCardIndex]
	ld d, a
	ld a, [wPlayerAttackingCardID]
	call CopyAttackDataAndDamage_FromCardID
	bank1call UpdateArenaCardIDsAndClearTwoTurnDuelVars
	ldh a, [hTempPlayAreaLocation_ff9d]
	ret

.player
	ldtx hl, SelectNewActivePokemonText
	call DrawWideTextBox_WaitForInput
	rst SwapTurn
	call InitPlayAreaScreenVars_OnlyBench
	inc a ; $00 -> $01
	ld [hl], a ; wPlayAreaSelectAction = FORCED_SWITCH_CHECK_MENU
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


; ouput:
;	carry = set:  if the opponent doesn't have any Benched Pokemon
;	[hTemp_ffa0] = play area location offset of a Pokémon on the opponent's Bench (PLAY_AREA_* constant, -1 if none)
OpponentSwitchesActive_BenchCheck:
	ld a, -1
	ldh [hTemp_ffa0], a
	ld a, DUELVARS_NUMBER_OF_POKEMON_IN_PLAY_AREA
	call GetNonTurnDuelistVariable
	cp 2
	ret c ; return with the default variable if the opponent's Bench is empty
	call DuelistSelectForcedSwitch
	ldh [hTemp_ffa0], a
	ret


; if the opponent has 1 or more Benched Pokemon, flips a coin, and if heads,
; has the opponent select a Pokemon on their Bench to switch with their Active Pokemon
; output:
;	[hTemp_ffa0] = play area location offset of the chosen Benched Pokemon (PLAY_AREA_* constant):
;	               if there's a Benched Pokemon and the coin toss result was heads
OpponentSwitchesActive50Percent_SelectEffect:
	ld a, -1
	ldh [hTemp_ffa0], a
	ld a, DUELVARS_NUMBER_OF_POKEMON_IN_PLAY_AREA
	call GetNonTurnDuelistVariable
	cp 2
	ret c ; return with the default variable if the opponent's Bench is empty

; toss a coin and proceed with the switch if heads
	ldtx de, IfHeadsChangeOpponentsActivePokemonText
	call TossCoin
	ret nc ; return with the default variable if the coin toss result was tails
	call DuelistSelectForcedSwitch
	ldh [hTemp_ffa0], a
	ret


; user does 20 damage to itself and switches the opponent's Active Pokemon
; with a given Pokemon on the opponent's Bench
; input:
;	[hTemp_ffa0] = play area location offset of the chosen Benched Pokemon (PLAY_AREA_* constant)
Recoil20OpponentSwitchesActiveEffect:
	ld a, 20
	call DealRecoilDamageToSelf
;	fallthrough

; switches the opponent's Active Pokemon with a given Pokemon on their Bench
; input:
;	[hTemp_ffa0] = play area location offset of the chosen Benched Pokemon (PLAY_AREA_* constant, -1 if none)
OpponentSwitchesActive_SwitchEffect:
	ldh a, [hTemp_ffa0]
	cp -1
	ret z ; return if there's no target

; check the Defending Pokemon's HP
	ld a, DUELVARS_ARENA_CARD_HP
	call GetNonTurnDuelistVariable
	or a
	jr nz, .switch
	; Defending Pokémon is Knocked Out
	bank1call HandleDestinyBondSubstatus
.switch
	call HandleNoDamageOrEffect
	ret c ; return if the attack had no effect

; attack was successful, switch Defending Pokemon
	rst SwapTurn
	ldh a, [hTemp_ffa0]
	ld e, a
	call SwapArenaWithBenchPokemon
	rst SwapTurn

	xor a
	ld [wccc5], a
	ld [wDuelDisplayedScreen], a
	inc a
	ld [wDefendingWasForcedToSwitch], a
	ret


; output:
;	carry = set:  if the opponent doesn't have any Benched Pokemon
;	[hTemp_ffa0] = play area location offset of a Pokémon on the opponent's Bench (PLAY_AREA_* constant, -1 if none)
AlsoDamageTo1Benched_PlayerSelection:
	ld a, -1
	ldh [hTemp_ffa0], a
	ld a, DUELVARS_NUMBER_OF_POKEMON_IN_PLAY_AREA
	call GetNonTurnDuelistVariable
	cp 2
	ret c ; return if no Pokemon on opponent's Bench
;	fallthrough

; opens the Play Area screen to select a Benched Pokemon to damage
; output:
;	[hTemp_ffa0] = play area location offset of the chosen Benched Pokemon (PLAY_AREA_* constant)
DamageTo1Benched_PlayerSelection:
	ldtx hl, ChoosePkmnInTheBenchToGiveDamageText
	jr MustChooseOpposingBenchedPokemon


; opens the Play Area screen to select a Benched Pokemon to switch with the Defending Pokemon
; output:
;	[hTemp_ffa0] = play area location offset of the chosen Benched Pokemon (PLAY_AREA_* constant)
SwitchDefendingPokemon_PlayerSelection:
	ldtx hl, SelectNewDefendingPokemonText
;	fallthrough

; handles the Player's selection of a Pokemon on the opponent's Bench
; input:
;	hl = ID for the text instructions
MustChooseOpposingBenchedPokemon:
	call DrawWideTextBox_WaitForInput
	rst SwapTurn
	call InitPlayAreaScreenVars_OnlyBench
.loop_input
	bank1call OpenPlayAreaScreenForSelection
	jr c, .loop_input ; must choose, B button can't be used to exit
	ldh [hTemp_ffa0], a
	jp SwapTurn


; AI picks the Benched Pokemon with the lowest remaining HP
; output:
;	carry = set:  if the opponent doesn't have any Benched Pokemon
;	[hTemp_ffa0] = play area location offset of a Pokémon on the opponent's Bench (PLAY_AREA_* constant, -1 if none)
AlsoChooseWeakestBenchedPokemon_AISelection:
	ld a, -1
	ldh [hTemp_ffa0], a
	ld a, DUELVARS_NUMBER_OF_POKEMON_IN_PLAY_AREA
	call GetNonTurnDuelistVariable
	cp 2
	ret c ; return if no Pokemon on opponent's Bench
;	fallthrough

; AI picks the Benched Pokemon with the lowest remaining HP
; output:
;	[hTemp_ffa0] = play area location offset of the chosen Benched Pokemon (PLAY_AREA_* constant)
ChooseWeakestBenchedPokemon_AISelection:
	call GetBenchPokemonWithLowestHP
	ldh [hTemp_ffa0], a
	ret


; finds the non-turn holder's Benched Pokemon with the lowest (remaining) HP.
; if multiple cards are tied for the lowest HP, the one with the highest PLAY_AREA_* is returned.
; output:
;	a = play area location offset of the Benched Pokemon with the least HP (PLAY_AREA_* constant)
GetBenchPokemonWithLowestHP:
	rst SwapTurn
	ld a, DUELVARS_NUMBER_OF_POKEMON_IN_PLAY_AREA
	get_turn_duelist_var
	ld c, a
	lb de, PLAY_AREA_ARENA, $ff
	ld b, d
	ld a, DUELVARS_BENCH1_CARD_HP
	get_turn_duelist_var
	jr .start

; find the location of the Pokemon with the least amount of remaining HP
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


; switches the opponent's Active Pokemon with a given Pokemon on their Bench,
; unless the effect is prevented by Mew's Neutralizing Shield or Haunter's Transparency.
; input:
;	[hTemp_ffa0] = play area location offset of the chosen Benched Pokemon (PLAY_AREA_* constant)
SwitchDefendingPokemon_SwitchEffect:
	rst SwapTurn
	ldh a, [hTemp_ffa0]
	ld e, a
	call HandleNShieldAndTransparency
	call nc, SwapArenaWithBenchPokemon
	xor a
	ld [wDuelDisplayedScreen], a
	jp SwapTurn


; identical to SwitchDefendingPokemon_PlayerSelection
; except the player can choose not to play the card
; by canceling the selection with the B button
; output:
;	carry = set:  if the operation was cancelled by the Player (with B button)
;	[hTemp_ffa0] = play area location offset of the chosen Benched Pokemon (PLAY_AREA_* constant)
GustOfWind_PlayerSelection:
	ldtx hl, SelectNewDefendingPokemonText
	call DrawWideTextBox_WaitForInput
	rst SwapTurn
	bank1call InitVarsAndOpenPlayAreaScreenForSelection_OnlyBench
	rst SwapTurn
;	ret c ; exit if the B button was pressed
	ldh [hTemp_ffa0], a
	ret


; plays the Gust of Wind animation and switches the opponent's Active Pokemon
; with a given Pokemon on the opponent's Bench
; input:
;	[hTemp_ffa0] = play area location offset of the chosen Benched Pokemon (PLAY_AREA_* constant)
GustOfWind_SwitchEffect:
; play whirlwind animation
	ld a, ATK_ANIM_GUST_OF_WIND
	call PlayTrainerEffectAnimation

; switch Active Pokemon
	rst SwapTurn
	ldh a, [hTemp_ffa0]
	ld e, a
	call SwapArenaWithBenchPokemon
	rst SwapTurn
	bank1call ClearDamageReductionSubstatus2
	xor a
	ld [wDuelDisplayedScreen], a
	ret


; handles the Player's selection of an Evolved Pokemon in either play area
; output:
;	carry = set:  if the operation was cancelled by the Player (with B button)
;	[hTemp_ffa0] = location of the chosen Pokemon ($0 = own play area, $1 = opponent's play area)
;	[hTempPlayAreaLocation_ffa1] = Pokemon's play area location offset (PLAY_AREA_* constant)
DevolutionBeam_PlayerSelection:
	ldtx hl, ProcedureForDevolutionBeamText
	call DrawWholeScreenTextBox

.start
	bank1call DrawDuelMainScene
	ldtx hl, PleaseSelectThePlayAreaText
	call TwoItemHorizontalMenu
	ldh a, [hKeysHeld]
	and PAD_B
	scf
	ret nz ; return carry if the B button was pressed

; a play area was selected
	ldh a, [hCurMenuItem]
	or a
	jr nz, .opp_chosen

; own play area was chosen
	call HandleEvolvedCardSelection
	jr c, .start

	xor a
.store_selection
	ld hl, hTemp_ffa0
	ld [hli], a ; store which player's play area was selected
	ldh a, [hTempPlayAreaLocation_ff9d]
	ld [hl], a ; store which card was selected
	or a
	ret

.opp_chosen
	rst SwapTurn
	call HandleEvolvedCardSelection
	rst SwapTurn
	jr c, .start
	ld a, $01
	jr .store_selection


; handles the Player's selection of an Evolved Pokemon in the turn holder's play area
; input:
;	[hTempPlayAreaLocation_ff9d] = chosen Pokémon's play area location offset (PLAY_AREA_* constant)
; output:
;	carry = set:  if the operation was cancelled by the Player (with B button)
HandleEvolvedCardSelection:
	call InitPlayAreaScreenVars
.loop
	bank1call OpenPlayAreaScreenForSelection
	ret c ; exit if the B button was pressed
	add DUELVARS_ARENA_CARD_STAGE
	get_turn_duelist_var
	or a
	jr z, .loop ; if Basic, reset loop
	ret


; AI picks the first Evolved Pokemon in the Player's play area.
; if none were found, it picks the first Evolved Pokemon in its own play area.
; this function isn't normally used. the real selection effect is located in
; engine/duel/ai/core.asm under the AISelectSpecialAttackParameters function.
; preserves de
; output:
;	[hTemp_ffa0] = location of the chosen Pokemon ($0 = own play area, $1 = opponent's play area)
;	[hTempPlayAreaLocation_ffa1] = Pokemon's play area location offset (PLAY_AREA_* constant)
DevolutionBeam_AISelection:
	ld a, $01
	ldh [hTemp_ffa0], a
	rst SwapTurn
	call FindFirstNonBasicCardInPlayArea
	rst SwapTurn
	jr c, .found
	xor a
	ldh [hTemp_ffa0], a
	call FindFirstNonBasicCardInPlayArea
.found
	ldh [hTempPlayAreaLocation_ffa1], a
	ret


; finds the first Evolved Pokemon in the turn holder's play area and stores its location in a
; preserves de
; output:
;	a = play area location offset (PLAY_AREA_* constant)
;	carry = set:  if an Evolved Pokémon was found in the play area
FindFirstNonBasicCardInPlayArea:
	ld a, DUELVARS_NUMBER_OF_POKEMON_IN_PLAY_AREA
	get_turn_duelist_var
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


; removes the top Evolution card from a given Evolved Pokemon in the play area and
; places it in it's owner's hand, reverting the Pokemon to the previous stage's card
; input:
;	[hTemp_ffa0] = location of the chosen Pokemon (0 = own play area, 1 = opponent's play area, -1 = nothing selected)
;	[hTempPlayAreaLocation_ffa1] = Pokemon's play area location offset (PLAY_AREA_* constant)
DevolutionBeam_DevolveEffect:
	ldh a, [hTemp_ffa0]
	or a
	jr z, .DevolvePokemon ; own play area
	cp -1
	ret z ; return if there's no target

; opponent's play area
	rst SwapTurn
	ldh a, [hTempPlayAreaLocation_ffa1]
	or a
	call z, HandleNoDamageOrEffect ; check wNoDamageOrEffect status if target is Defending Pokémon
	jp c, SwapTurn ; done if the target is unaffected by the attack
	call .DevolvePokemon
	jp SwapTurn

.DevolvePokemon
	ld a, ATK_ANIM_DEVOLUTION_BEAM
	ld [wLoadedAttackAnimation], a
	ldh a, [hTempPlayAreaLocation_ffa1]
	ld b, a
	ld c, $00 ; neither WEAKNESS nor RESISTANCE
	ldh a, [hWhoseTurn]
	ld h, a
	call PlayAttackAnimation
	call WaitAttackAnimation

; load selected card's data
	ldh a, [hTempPlayAreaLocation_ffa1]
	ldh [hTempPlayAreaLocation_ff9d], a
	ld [wTempPlayAreaLocation_cceb], a
	add DUELVARS_ARENA_CARD
	get_turn_duelist_var
	call LoadCardDataToBuffer1_FromDeckIndex

; check if card is affected
	ld [wTempNonTurnDuelistCardID], a
	ld de, $0
	ldh a, [hTempPlayAreaLocation_ff9d]
	or a
	call z, HandleNoDamageOrEffectSubstatus ; set wNoDamageOrEffect status if target is Defending Pokémon
	call nc, HandleDamageReductionOrNoDamageFromPkmnPowerEffects ; handle damage modifiers if target isn't immune
	call CheckNoDamageOrEffect
	jp c, DrawWideTextBox_WaitForInput ; done if the target is unaffected by the attack

	ldh a, [hTempPlayAreaLocation_ffa1]
	ldh [hTempPlayAreaLocation_ff9d], a
	call GetCardOneStageBelow
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


; if there is an Evolved Pokemon in the given location, list the card indices
; of all stages in that location and return the card one stage below in d.
; input:
;	[hTempPlayAreaLocation_ff9d] = which play area location to check (PLAY_AREA_* constant)
; output:
;	a & e = deck index of the Pokemon in the given location (0-59)
;	d = deck index for the previous stage of the Pokemon in the given location (0-59, -1 if none)
;	carry = set:  if the Pokemon in the given location is Basic
;	[wAllStagesIndices] = deck index of the Basic Pokemon in the given location (0-59, -1 if none)
;	[wAllStagesIndices + 1] = deck index of the Stage 1 Pokemon in the given location (0-59, -1 if none)
;	[wAllStagesIndices + 2] = deck index of the Stage 2 Pokemon in the given location (0-59, -1 if none)
GetCardOneStageBelow:
	ldh a, [hTempPlayAreaLocation_ff9d]
	add DUELVARS_ARENA_CARD
	get_turn_duelist_var
	call LoadCardDataToBuffer2_FromDeckIndex
	ld a, [wLoadedCard2Stage]
	or a
	jr nz, .not_basic
	scf
	ret

.not_basic
	ld hl, wAllStagesIndices
	ld a, -1
	ld [hli], a
	ld [hli], a
	ld [hl], a

; loads deck indices of the stages present in hTempPlayAreaLocation_ff9d.
; the three stages are loaded consecutively in wAllStagesIndices.
	ldh a, [hTempPlayAreaLocation_ff9d]
	or CARD_LOCATION_PLAY_AREA
	ld c, a
	ldh a, [hWhoseTurn]
	ld h, a
	ld l, DUELVARS_CARD_LOCATIONS + DECK_SIZE
.loop
	dec l ; go through deck indices in reverse order
	ld a, [hl]
	cp c
	jr nz, .next ; skip if wrong card location
	ld a, l
	call LoadCardDataToBuffer2_FromDeckIndex
	ld a, [wLoadedCard2Type]
	cp TYPE_ENERGY
	jr nc, .next ; skip if not a Pokémon
	ld b, l
	push hl
	ld a, [wLoadedCard2Stage]
	ld e, a
	ld d, $00
	ld hl, wAllStagesIndices
	add hl, de
	ld [hl], b
	pop hl
.next
	ld a, l
	or a
	jr nz, .loop

; if card at hTempPlayAreaLocation_ff9d is a stage 1, load d with basic card.
; otherwise if stage 2, load d with the stage 1 card.
	ldh a, [hTempPlayAreaLocation_ff9d]
	add DUELVARS_ARENA_CARD_STAGE
	get_turn_duelist_var
	ld hl, wAllStagesIndices ; pointing to basic
	cp STAGE1
	jr z, .done
	; if stage1 was skipped, hl should point to Basic stage card
	cp STAGE2_WITHOUT_STAGE1
	jr z, .done
	inc hl ; pointing to stage 1
.done
	ld d, [hl]
	ldh a, [hTempPlayAreaLocation_ff9d]
	add DUELVARS_ARENA_CARD
	get_turn_duelist_var
	ld e, a
	or a
	ret


; overwrites the HP and Stage data of the card that was
; devolved to the values of the new card.
; if the damage exceeds the HP of the previous stage,
; then its HP is set to zero.
; preserves bc and de
; input:
;	a = deck index for the previous stage of the Pokemon in the given location (0-59, -1 if none)
;	[hTempPlayAreaLocation_ff9d] = devolved Pokémon's play area location offset (PLAY_AREA_* constant)
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
	get_turn_duelist_var
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


; resets various status conditions and attack effects on the devolved Pokemon
; preserves bc and de
; input:
;	[hTempPlayAreaLocation_ff9d] = devolved Pokémon's play area location offset (PLAY_AREA_* constant)
ResetDevolvedCardStatus:
; if it's the Active Pokemon, remove any special conditions
	ldh a, [hTempPlayAreaLocation_ff9d]
	or a
	call z, ClearAllStatusConditions
; reset changed color status
	ldh a, [hTempPlayAreaLocation_ff9d]
	add DUELVARS_ARENA_CARD_CHANGED_TYPE
	get_turn_duelist_var
	ld [hl], $00
; reset C2 flags
	ldh a, [hTempPlayAreaLocation_ff9d]
	add DUELVARS_ARENA_CARD_FLAGS
	ld l, a
	ld [hl], $00
	ret


; prints the text "<X> devolved to <Y>!" with the proper card names and levels
; preserves de
; input:
;	d = deck index of the lower stage card (0-59)
;	e = deck index of the card that was devolved (0-59)
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

	ld a, d
	call LoadCardDataToBuffer1_FromDeckIndex
	ld a, 18
	call CopyCardNameAndLevel
	xor a ; TX_END
	ld [hl], a ; terminate the text string at wDefaultText
	; zero wTxRam2_b so that the name & level text just loaded to wDefaultText is printed
	ld hl, wTxRam2_b
	ld [hli], a
	ld [hl], a
	ldtx hl, PokemonDevolvedToText
	call DrawWideTextBox_WaitForInput
	pop de
	ret


; returns the opponent's Active Pokemon and any attached cards to the opponent's hand
ReturnDefendingPokemonToTheHandEffect:
	call HandleNoDamageOrEffect
	ret c ; return if the attack had no effect

	ld a, DUELVARS_ARENA_CARD_HP
	call GetNonTurnDuelistVariable
	or a
	ret z ; return if the attack Knocked Out the Defending Pokemon

; look at the location of every one of the opponent's cards and
; put all cards that are in the opposing Arena into the opponent's hand.
	rst SwapTurn
	ld l, DUELVARS_CARD_LOCATIONS + DECK_SIZE
.loop_locations
	dec l ; go through deck indices in reverse order
	ld a, [hl]
	cp CARD_LOCATION_ARENA
	jr nz, .next_card
	; Arena card, so move to hand
	ld a, l
	call AddCardToHand
.next_card
	ld a, l
	or a
	jr nz, .loop_locations

; empty the Arena card slot
	ld l, DUELVARS_ARENA_CARD
	ld a, [hl]
	ld [hl], -1 ; empty play area slot
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

; ignores Weakness and Resistance when calculating attack damage
; preserves bc and de
NoColorEffect:
	ld hl, wDamage + 1
	set UNAFFECTED_BY_WEAKNESS_RESISTANCE_F, [hl]
;	fallthrough

NullEffect:
	ret


; sets attack damage to half the Defending Pokemon's remaining HP (rounded up)
; preserves bc and de
HalveHPOfDefendingPokemon:
	ld a, DUELVARS_ARENA_CARD_HP
	call GetNonTurnDuelistVariable
	call HalfARoundedUp
	jp SetDefiniteDamage

; reduces attack damage by 10 for each damage counter on the user
KarateChop_DamageSubtractionEffect:
	ld e, PLAY_AREA_ARENA
	call GetCardDamageAndMaxHP
;	fallthrough

; preserves all registers except af
; input:
;	a = amount to subtract from the base damage
;	[wDamage] = base damage
; output:
;	[wDamage]      = updated damage amount (minimum damage = 0)
;	[wAIMinDamage] = updated damage amount (minimum damage = 0)
;	[wAIMaxDamage] = updated damage amount (minimum damage = 0)
SubtractFromDamage:
	push de
	push hl
	ld e, a
	ld hl, wDamage
	ld a, [hl]
	sub e
	jr nc, .store_damage
	; difference is a negative number, so set damage to 0
	xor a
.store_damage
	ld [hli], a ; wDamage
	inc hl
	ld [hli], a ; wAIMinDamage
	ld [hl], a  ; wAIMaxDamage
	pop hl
	pop de
	ret

; reduces attack damage by 10 for each damage counter on the user
;Alt_KarateChop_DamageSubtractionEffect:
;	ld e, PLAY_AREA_ARENA
;	call GetCardDamageAndMaxHP
;	ld e, a
;	ld hl, wDamage
;	ld a, [hl]
;	sub e
;	ld [hli], a
;	ld a, [hl]
;	sbc 0
;	ld [hl], a
;	rla
;	ret nc ; return if the attack damage isn't negative
;	; cap it to 0 damage
;	xor a
;	jp SetDefiniteDamage


; sets attack damage to 10 times the number of damage counters on the user
; preserves b, d, and hl
Flail_HPCheck:
	ld e, PLAY_AREA_ARENA
	call GetCardDamageAndMaxHP
	jp SetDefiniteDamage


; increases attack damage by 10 for each damage counter on the user
; preserves b, d, and hl
Rage_DamageBoostEffect:
	ld e, PLAY_AREA_ARENA
	call GetCardDamageAndMaxHP
	jr AddToDamage


RageAndSelfConfusion50PercentEffect:
	call Rage_DamageBoostEffect
	ldtx de, IfTailsYourPokemonBecomesConfusedText
	call TossCoin
	ret c ; return if heads
	rst SwapTurn
	call ConfusionEffect
	jp SwapTurn


; increases attack damage by 10 for each damage counter already on the Defending Pokemon
; preserves b, d, and hl
CompoundingDamageCounters_DamageBoostEffect:
	rst SwapTurn
	ld e, PLAY_AREA_ARENA
	call GetCardDamageAndMaxHP
	rst SwapTurn
	jr AddToDamage


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

; applies the bonus damage for attacks that get stronger with extra Water Energy.
; this bonus is always 10 more damage for each extra Water energy
; and is always capped at a maximum of 20 damage.
; input:
;	b = number of Water Energy listed in Attack Cost
;	c = number of Colorless Energy listed in Attack Cost
;	[hTempPlayAreaLocation_ff9d] = play area location offset of the Pokémon being checked
ApplyExtraWaterEnergyDamageBonus:
	ld a, [wMetronomeEnergyCost]
	or a
	jr z, .not_metronome
	ld c, a ; amount of Colorless Energy needed for Metronome
	ld b, 0 ; no Water Energy is needed for Metronome

.not_metronome
	ldh a, [hTempPlayAreaLocation_ff9d]
	ld e, a
	call GetPlayAreaCardAttachedEnergies
	ld hl, wAttachedEnergies + WATER
	ld a, c
	or a
	jr z, .check_bonus ; skip ahead if there's no Colorless Energy in the attack cost

; we'll need to remove any Water Energy cards from the calculations if they pay for Colorless instead.
	ld a, [wTotalAttachedEnergies]
	sub [hl]
	jr z, .all_attached_energy_is_water
	; at least 1 non-Water Energy is attached
	ld e, a
	ld a, c
	sub e
	jr c, .check_bonus ; skip ahead if there's more than enough non-Water Energy attached
	ld c, a ; amount of Colorless Energy in attack cost that is being payed with Water Energy
.all_attached_energy_is_water
	ld a, c
	add b
	ld b, a
	; b += c

.check_bonus
	ld a, [hl]
	inc b ; increase attack cost by 1 so carry will be set if actual difference = 0
	sub b
	jp c, SetDefiniteAIDamage ; use default damage if amount of attached Water Energy <= the attack cost
	inc a ; reverse the result of the earlier "inc b" instruction

; a holds the number of Water Energy not used to pay for the cost of the attack
	cp 3
	jr c, .less_than_3
	ld a, 2 ; cap this to 2 for bonus effect
.less_than_3
	call ATimes10
;	fallthrough

; preserves all registers except af
; input:
;	a = amount to add to the base damage
;	[wDamage] = base damage
; output:
;	[wDamage]      = updated damage amount (capped at 250)
;	[wAIMinDamage] = updated damage amount (capped at 250)
;	[wAIMaxDamage] = updated damage amount (capped at 250)
AddToDamage:
	push hl
	ld hl, wDamage
	add [hl]
	jr nc, .store_damage
	; total damage exceeded 1 byte (more than 255)
	ld a, 250 ; damage is capped at 250
.store_damage
	ld [hli], a ; wDamage
	inc hl
	ld [hli], a ; wAIMinDamage
	ld [hl], a  ; wAIMaxDamage
	pop hl
	ret


; increases attack damage by 10 for each Energy card attached to the Defending Pokemon
DefendingPokemonEnergy_10MoreDamageEffect:
	rst SwapTurn
	xor a ; PLAY_AREA_ARENA
	call CreateArenaOrBenchEnergyCardList
	rst SwapTurn
	; a = number of Energy cards attached to the Defending Pokémon
	call ATimes10
	jr AddToDamage


; sets attack damage to 10 times the number of Energy cards attached to the Defending Pokemon
DefendingPokemonEnergy_10xDamageEffect:
	rst SwapTurn
	xor a ; PLAY_AREA_ARENA
	call CreateArenaOrBenchEnergyCardList
	rst SwapTurn
	; a = number of Energy cards attached to the Defending Pokémon
	call ATimes10
	jp SetDefiniteDamage


; increases attack damage by 10 for each Pokemon in the turn holder's play area
EachBenched10MoreDamageEffect:
	ld a, DUELVARS_NUMBER_OF_POKEMON_IN_PLAY_AREA
	get_turn_duelist_var
	dec a ; don't count Active Pokemon
	call ATimes10
	jr AddToDamage


; increases attack damage by 20 for each Nidoking in the turn holder's play area
; preserves de
EachNidoking20MoreDamageEffect:
	ld a, DUELVARS_ARENA_CARD
	get_turn_duelist_var
	ld c, 0 ; Nidoking counter
.loop
	ld a, [hli]
	cp -1 ; empty play area slot?
	jr z, .done
	call _GetCardIDFromDeckIndex
	cp NIDOKING
	jr nz, .loop
	inc c
	jr .loop
.done
; c holds the number of Nidoking found in the play area
	ld a, c
	add a
	call ATimes10
	jr AddToDamage ; adds 2 * 10 * c


; can only use the attack if it was not used previously in the duel
; preserves bc and de
; output:
;	hl = ID for notification text:  if the below condition is true
;	carry = set:  if Leek Slap was already used this duel
LeekSlap_OncePerDuelCheck:
	ld a, DUELVARS_ARENA_CARD_FLAGS
	get_turn_duelist_var
	and USED_LEEK_SLAP_THIS_DUEL
	ret z ; return if this is the first use
	ldtx hl, ThisAttackCannotBeUsedTwiceText
	scf
	ret


; preserves bc and de
LeekSlap_SetUsedThisDuelFlag:
	ld a, DUELVARS_ARENA_CARD_FLAGS
	get_turn_duelist_var
	set USED_LEEK_SLAP_THIS_DUEL_F, [hl]
	ret


; flips a coin, and if tails, the attack fails (no damage or effect)
; preserves hl
NoDamage50PercentEffect:
	ldtx de, AttackSuccessCheckText
	call TossCoin
	ret c ; return if heads
	xor a ; 0 damage
	ld [wLoadedAttackAnimation], a ; 0 = ATK_ANIM_NONE
	call SetDefiniteDamage
;	fallthrough

; this is called when an attack does no damage and its effect fails
; preserves all registers except af
SetWasUnsuccessful:
	ld a, EFFECT_FAILED_UNSUCCESSFUL
	ld [wEffectFailed], a
	ret


; preserves bc and hl
FlipFor20_AIEffect:
	ld a, 20 / 2
	lb de, 0, 20
;	fallthrough

; stores information about the attack damage for AI purposes
; preserves all registers except af
; input:
;	a = average amount of damage done by the attack (stored in [wDamage])
;	d = minimum amount of damage done by the attack (stored in [wAIMinDamage])
;	e = maximum amount of damage done by the attack (stored in [wAIMaxDamage])
SetExpectedAIDamage:
	ld [wDamage], a
	xor a
	ld [wDamage + 1], a
	ld a, d
	ld [wAIMinDamage], a
	ld a, e
	ld [wAIMaxDamage], a
	ret


; preserves bc and hl
FlipFor30_AIEffect:
	ld a, 30 / 2
	lb de, 0, 30
	jr SetExpectedAIDamage


; preserves bc and hl
FlipFor40_AIEffect:
	ld a, 40 / 2
	lb de, 0, 40
	jr SetExpectedAIDamage


; preserves bc and hl
;FlipFor50_AIEffect:
;	ld a, 50 / 2
;	lb de, 0, 50
;	jr SetExpectedAIDamage


; preserves bc and hl
FlipFor60_AIEffect:
	ld a, 60 / 2
	lb de, 0, 60
	jr SetExpectedAIDamage


; preserves bc and hl
FlipFor70_AIEffect:
	ld a, 70 / 2
	lb de, 0, 70
	jr SetExpectedAIDamage


; preserves bc and hl
FlipFor80_AIEffect:
	ld a, 80 / 2
	lb de, 0, 80
	jr SetExpectedAIDamage


; preserves bc and hl
FlipFor120_AIEffect:
	ld a, 120 / 2
	lb de, 0, 120
	jr SetExpectedAIDamage


; preserves bc and hl
FlipXFor10_AIEffect:
	ld a, 10
	lb de, 0, 100
	jr SetExpectedAIDamage


; input:
;	a = number of coins to flip
; output:
;	a = amount of bonus damage to add (heads x 10)
;	[wCoinTossTotalNum] = number of flipped coins
;	[wCoinTossNumHeads] = number of flipped heads
Plus10DamagePerHeads_TossCoins:
	ld e, a
	ld hl, 10 ; ram number for text display
	call LoadTxRam3
	ld a, e
	ldtx de, DamageCheckIfHeadsXDamageText
	call TossCoinATimes
;	fallthrough

; preserves all registers except af
; input:
;	a = number to multiply by 10
; output:
;	a *= 10 (capped at 250)
ATimes10::
	cp 25
	jr nc, .reached_cap
	push de
	ld e, a
	add a
	add a
	add e
	add a
	pop de
	ret
.reached_cap
	ld a, 250
	ret


; flips 2 coins and sets attack damage to 10 times the number of heads
Flip2For10_MultiplierEffect:
	ld a, 2
	call Plus10DamagePerHeads_TossCoins
;	fallthrough

; overwrites wDamage, wAIMinDamage and wAIMaxDamage with the value in a
; preserves all registers except af
; input:
;	a = updated attack damage
SetDefiniteDamage:
	ld [wDamage], a
	ld [wAIMinDamage], a
	ld [wAIMaxDamage], a
	xor a
	ld [wDamage + 1], a
	ret


; flips 3 coins and sets attack damage to 10 times the number of heads
Flip3For10_MultiplierEffect:
	ld a, 3
	call Plus10DamagePerHeads_TossCoins
	jr SetDefiniteDamage


; flips 8 coins and sets attack damage to 10 times the number of heads
Flip8For10_MultiplierEffect:
	ld a, 8
	call Plus10DamagePerHeads_TossCoins
	jr SetDefiniteDamage


; flips coins until a tails appears and sets attack damage to 10 times the number of heads
; output:
;	[hTemp_ffa0] = number of flipped heads
FlipXFor10_MultiplierEffect:
	xor a
	ldh [hTemp_ffa0], a
.loop_coin_toss
	ldtx de, FlipUntilFailAppears10DamageForEachHeadsText
	xor a
	call TossCoinATimes
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
;   a = number of coins to flip
; output:
;   a = amount of bonus damage to add (heads x 20)
;	[wCoinTossTotalNum] = number of flipped coins
;	[wCoinTossNumHeads] = number of flipped heads
Plus20DamagePerHeads_TossCoins:
	ld e, a
	ld hl, 20 ; ram number for text display
	call LoadTxRam3
	ld a, e
	ldtx de, DamageCheckIfHeadsXDamageText
	call TossCoinATimes
	add a ; a = 2 * heads
	jr ATimes10


; flips 2 coins and sets attack damage to 20 times the number of heads
Flip2For20_MultiplierEffect:
	ld a, 2
	call Plus20DamagePerHeads_TossCoins
	jr SetDefiniteDamage


; flips 3 coins and sets attack damage to 20 times the number of heads
Flip3For20_MultiplierEffect:
	ld a, 3
	call Plus20DamagePerHeads_TossCoins
	jr SetDefiniteDamage


; flips 4 coins and sets attack damage to 20 times the number of heads
Flip4For20_MultiplierEffect:
	ld a, 4
	call Plus20DamagePerHeads_TossCoins
	jr SetDefiniteDamage


; preserves bc
FlipEachEnergyFor20_AIEffect:
	ldh a, [hTempPlayAreaLocation_ff9d]
	ld e, a
	call GetPlayAreaCardAttachedEnergies
;	ld a, [wTotalAttachedEnergies] ; already loaded
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


; flips coins equal to the amount of Energy attached to the user,
; then sets the attack damage to 20 times the number of heads
; output:
;	[wCoinTossTotalNum] = number of flipped coins
;	[wCoinTossNumHeads] = number of flipped heads
FlipEachEnergyFor20_MultiplierEffect:
	ld hl, 20 ; ram number for text display
	call LoadTxRam3
	ld e, PLAY_AREA_ARENA
	call GetPlayAreaCardAttachedEnergies
;	ld a, [wTotalAttachedEnergies] ; already loaded
	ldtx de, DamageCheckIfHeadsXDamageText
	call TossCoinATimes
;	fallthrough

; sets attack damage to 20 times the value in a
; preserves bc
; output:
;	hl = 20*a
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


; flips 2 coins and sets attack damage to 30 times the number of heads
Flip2For30_MultiplierEffect:
	ld hl, 30 ; ram number for text display
	call LoadTxRam3
	ldtx de, DamageCheckIfHeadsXDamageText
	ld a, 2
	call TossCoinATimes
	ld e, a
	add a ; a = 2 * heads
	add e ; a = 3 * heads
	call ATimes10
	jp SetDefiniteDamage ; 3 * 10 * heads


; flips 2 coins and sets attack damage to 40 times the number of heads
Flip2For40_MultiplierEffect:
	ld hl, 40 ; ram number for text display
	call LoadTxRam3
	ldtx de, DamageCheckIfHeadsXDamageText
	ld a, 2
	call TossCoinATimes
	add a ; a = 2 * heads
	add a
	call ATimes10
	jp SetDefiniteDamage


; flips 3 coins and sets attack damage to 40 times the number of heads, then confuses the user
Flip3For40SelfConfusion_MultiplierEffect:
	ld hl, 40 ; ram number for text display
	call LoadTxRam3
	ldtx de, DamageCheckIfHeadsXDamageText
	ld a, 3
	call TossCoinATimes
	add a ; a = 2 * heads
	add a
	call ATimes10
	call SetDefiniteDamage ; a = 4 * 10 * heads
	rst SwapTurn
	call ConfusionEffect
	jp SwapTurn


; flips a coin, and if heads, increases the attack damage by 10
FlipForPlus10_DamageBoostEffect:
	ld hl, 10 ; ram number for text display
	call LoadTxRam3
	ldtx de, DamageCheckIfHeadsPlusDamageText
	call TossCoin
	ret nc ; return if tails
	ld hl, wDamage
	ld a, [hl]
	add 10
	ld [hl], a
	ret

; flips a coin, and if heads, increases the attack damage by 20
FlipForPlus20_DamageBoostEffect:
	ld hl, 20 ; ram number for text display
	call LoadTxRam3
	ldtx de, DamageCheckIfHeadsPlusDamageText
	call TossCoin
	ret nc ; return if tails
	ld hl, wDamage
	ld a, [hl]
	add 20
	ld [hl], a
	ret


; preserves bc and hl
Plus10From20_AIEffect:
	ld a, (20 + 30) / 2
	lb de, 20, 30
	jp SetExpectedAIDamage


; preserves bc and hl
Plus20From10_AIEffect:
	ld a, (10 + 30) / 2
	lb de, 10, 30
	jp SetExpectedAIDamage


; preserves bc and hl
Plus10OrRecoil_AIEffect:
	ld a, (30 + 40) / 2
	lb de, 30, 40
	jp SetExpectedAIDamage


; flips a coin, and if heads, increases the attack damage by 10
; output:
;	[hTemp_ffa0] = result of the coin toss (0 = tails, 1 = heads)
Plus10OrRecoil_ModifierEffect:
	ldtx de, IfHeadPlus10IfTails10ToYourselfText
	call TossCoin
	ldh [hTemp_ffa0], a
	ret nc ; return if tails
	ld hl, wDamage
	ld a, [hl]
	add 10
	ld [hl], a
	ret


; ; if coin toss result was tails, user does 10 damage to itself
; input:
;	[hTemp_ffa0] = result of the coin toss (0 = tails, 1 = heads)
Plus10OrRecoil_RecoilEffect:
	ldh a, [hTemp_ffa0]
	or a
	ret nz ; return if the result of the coin toss was heads
	ld a, 10
	jp DealRecoilDamageToSelf


;---------------------------------------------------------------------------------
; (11) ATTACK EFFECTS THAT NEGATIVELY AFFECT THE PLAYER'S POKEMON ARE NEXT.
;---------------------------------------------------------------------------------

; flips a coin and stores the result
; output:
;	[hTemp_ffa0] & a = result of the coin toss (0 = tails, 1 = heads)
Recoil10_50PercentEffect:
	ld hl, 10 ; ram number for text display
	call LoadTxRam3
	ldtx de, IfTailsDamageToYourselfTooText
	call TossCoin
	ldh [hTemp_ffa0], a
	ret


; if coin toss result was tails, user does 10 damage to itself
; input:
;	[hTemp_ffa0] = result of the coin toss (0 = tails, 1 = heads)
Recoil10_RecoilEffect:
	ld hl, 10 ; ram number for text display
	call LoadTxRam3
	ldh a, [hTemp_ffa0]
	or a
	ret nz ; return if the result of the coin toss was heads
	ld a, 10
	jp DealRecoilDamageToSelf


; flips a coin and stores the result
; output:
;	[hTemp_ffa0] & a = result of the coin toss (0 = tails, 1 = heads)
FlipToRecoil30_50PercentEffect:
	ld hl, 30 ; ram number for text display
	call LoadTxRam3
	ldtx de, IfTailsDamageToYourselfTooText
	call TossCoin
	ldh [hTemp_ffa0], a
	ret


; if coin toss result was tails, user does 30 damage to itself
; input:
;	[hTemp_ffa0] = result of the coin toss (0 = tails, 1 = heads)
FlipToRecoil30_RecoilEffect:
	ld hl, 30 ; ram number for text display
	call LoadTxRam3
	ldh a, [hTemp_ffa0]
	or a
	ret nz ; return if the result of the coin toss was heads
	ld a, 30
	jp DealRecoilDamageToSelf


; user does 20 damage to itself
Recoil20Effect:
	ld a, 20
	jp DealRecoilDamageToSelf


; user does 30 damage to itself
Recoil30Effect:
	ld a, 30
	jp DealRecoilDamageToSelf


; user does 80 damage to itself
Recoil80Effect:
	ld a, 80
	jp DealRecoilDamageToSelf


; flips a coin, and if tails, user is Confused
SelfConfusion_50PercentEffect:
	ldtx de, IfTailsYourPokemonBecomesConfusedText
	call TossCoin
	ret c ; return if heads
	; make the Attacking Pokemon Confused
	ld a, ATK_ANIM_MULTIPLE_SLASH
	ld [wLoadedAttackAnimation], a
	rst SwapTurn
	call ConfusionEffect
	jp SwapTurn


; creates in wDuelTempList a list of Fire Energy cards
; that are attached to the turn holder's Active Pokemon.
; output:
;	a & c = number of Fire Energy cards attached to the turn holder's Active Pokémon
;	wDuelTempList = $ff-terminated list with deck indices of Fire Energy cards in the Arena
CreateListOfFireEnergyAttachedToActive:
	ld a, TYPE_ENERGY_FIRE
;	fallthrough

; creates in wDuelTempList a list of cards that
; are in the turn holder's Arena of the same type as input a.
; this is called to list Energy cards of a specific type
; that are attached to the player's Active Pokemon.
; input:
;	a = TYPE_ENERGY_* constant
; output:
;	a & c = number of Energy cards attached to the Active Pokemon matching input color
;	wDuelTempList = $ff-terminated list with deck indices of the relevant Energy cards
CreateListOfEnergyAttachedToActive:
	ld b, a
	xor a
	ld c, a ; initial Energy card counter = 0
	ld de, wDuelTempList
	; a = DUELVARS_CARD_LOCATIONS
	get_turn_duelist_var
	; hl = starting address for turn holder's card location data
.loop
	ld a, [hl]
	cp CARD_LOCATION_ARENA
	jr nz, .next
	ld a, l
	call GetCardTypeFromDeckIndex_SaveDE
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

	ld a, $ff ; terminating byte
	ld [de], a
	ld a, c
	ret


; handles the Player's selection of a Fire Energy attached to their Active Pokemon
; output:
;	carry = set:  if the operation was cancelled by the Player (with B button)
;	[hTemp_ffa0] = deck index of a Fire Energy attached to the turn holder's Active Pokémon (0-59)
DiscardAttachedFireEnergy_PlayerSelection:
	call CreateListOfFireEnergyAttachedToActive
	xor a ; PLAY_AREA_ARENA
	bank1call DisplayEnergyDiscardScreen
	bank1call HandleEnergyDiscardMenuInput
;	ret c ; exit if the B button was pressed
	ldh [hTemp_ffa0], a
	ret


; makes a list of every Fire Energy attached to the AI's Active Pokemon
; and the AI picks the first card in that list
; output:
;	[hTemp_ffa0] = deck index of a Fire Energy attached to the turn holder's Active Pokémon (0-59)
DiscardAttachedFireEnergy_AISelection:
	call CreateListOfFireEnergyAttachedToActive
	ld a, [wDuelTempList]
	ldh [hTemp_ffa0], a
	ret


; AI always chooses to discard 0 Fire Energy cards.
; this function isn't normally used. the real selection effect is located in
; engine/duel/ai/core.asm under the AISelectSpecialAttackParameters function.
; output:
;	[hTemp_ffa0] = number of Fire Energy cards to discard (always 0)
DiscardXAttachedFireEnergy_AISelection:
	xor a
	ldh [hTemp_ffa0], a
	ret


; handles the Player's selection of any number of Fire Energy attached to their Active Pokemon
; output:
;	carry = set:  if no Fire Energy cards were selected to be discarded
;	[hTemp_ffa0] = number of Fire Energy cards that were chosen
DiscardXAttachedFireEnergy_PlayerSelection:
	ldtx hl, DiscardOppDeckAsManyFireEnergyCardsText
	call DrawWideTextBox_WaitForInput

	xor a
	ldh [hCurSelectionItem], a
	call CreateListOfFireEnergyAttachedToActive
	xor a ; PLAY_AREA_ARENA
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
	jr c, .done ; exit if there are no more Fire Energy cards to discard
	bank1call DisplayEnergyDiscardMenu
	jr .loop

; outputs the result in hTemp_ffa0 and returns carry if no cards were discarded
.done
	ldh a, [hCurSelectionItem]
	ldh [hTemp_ffa0], a
	or a
	ret nz ; return if 1 or more Fire Energy was selected
	scf
	ret


; discards a given number of Fire Energy cards from the turn holder's Active Pokemon
; input
;	[hTemp_ffa0] = number of Fire Energy cards to discard from the user
DiscardXAttachedFireEnergy_DiscardEffect:
	call CreateListOfFireEnergyAttachedToActive
	ldh a, [hTemp_ffa0]
	or a
	ret z ; return if no cards to discard

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


; discards a given number of cards from the top of the opponent's deck
; input:
;	[hTemp_ffa0] = number of cards to discard from the opponent's deck
OpponentDeck_DiscardXCardsEffect:
	rst SwapTurn
	ldh a, [hTemp_ffa0]
	or a
	jr z, .print_text
	ld c, a
	ld a, DUELVARS_NUMBER_OF_CARDS_NOT_IN_DECK
	get_turn_duelist_var
	ld a, DECK_SIZE
	sub [hl]
	cp c
	jr nc, .discard_full_amount
	; only discard the number of cards that are left in the deck
	ld c, a
.discard_full_amount
	ld b, c ; store number to print later with text
.discard_loop
	; discard the top card from the deck
	call DrawCardFromDeck
	call nc, PutCardInDiscardPile
	dec c
	jr nz, .discard_loop
	ld a, b
.print_text
	ld hl, wTxRam3
	ld [hli], a
	xor a
	ld [hl], a
	ldtx hl, DiscardedCardsFromDeckText
	call DrawWideTextBox_PrintText
	jp SwapTurn


; handles the Player's selection of 2 Fire Energy attached to their Active Pokemon
; output:
;	carry = set:  if the operation was cancelled by the Player (with B button)
;	[hTempList] = deck index of a Fire Energy attached to the turn holder's Active Pokémon (0-59)
;	[hTempList + 1] = deck index of another Fire Energy attached to the turn holder's Active Pokémon (0-59)
Discard2AttachedFireEnergy_PlayerSelection:
	ldtx hl, ChooseAndDiscard2FireEnergyCardsText
	call DrawWideTextBox_WaitForInput

	xor a
	ldh [hCurSelectionItem], a
	call CreateListOfFireEnergyAttachedToActive
	xor a ; PLAY_AREA_ARENA
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
	ret nc ; return if 2 Fire Energy have been chosen
	bank1call DisplayEnergyDiscardMenu
	jr .loop_input


; makes a list of every Fire Energy attached to the AI's Active Pokemon
; and the AI picks the first 2 cards in that list
; output:
;	[hTempList] = deck index of a Fire Energy attached to the turn holder's Active Pokémon (0-59)
;	[hTempList + 1] = deck index of another Fire Energy attached to the turn holder's Active Pokémon (0-59)
Discard2AttachedFireEnergy_AISelection:
	call DiscardAttachedFireEnergy_AISelection
	ld a, [wDuelTempList + 1]
	ldh [hTempList + 1], a
	ret


; output:
;	carry = set:  if the operation was cancelled by the Player (with B button)
;	[hTemp_ffa0] = deck index of a Water Energy attached to the turn holder's Active Pokémon (0-59)
DiscardAttachedWaterEnergy_PlayerSelection:
	ld a, TYPE_ENERGY_WATER
	jr DiscardAnAttachedEnergyOfSpecifiedType

; output:
;	carry = set:  if the operation was cancelled by the Player (with B button)
;	[hTemp_ffa0] = deck index of a Psychic Energy attached to the turn holder's Active Pokémon (0-59)
DiscardAttachedPsychicEnergy_PlayerSelection:
	ld a, TYPE_ENERGY_PSYCHIC
;	fallthrough

; handles the Player's selection of a specific Energy card attached to their Active Pokemon
; input:
;	a = TYPE_ENERGY_* constant
; output:
;	carry = set:  if the operation was cancelled by the Player (with B button)
;	[hTemp_ffa0] = deck index of an Energy card which provides Energy of the given type/color
;	               that is attached to the turn holder's Active Pokémon (0-59)
DiscardAnAttachedEnergyOfSpecifiedType:
	call CreateListOfEnergyAttachedToActive
	xor a ; PLAY_AREA_ARENA
	bank1call DisplayEnergyDiscardScreen
	bank1call HandleEnergyDiscardMenuInput
;	ret c ; exit if the B button was pressed
	ldh [hTemp_ffa0], a ; store chosen card
	ret


; output:
;	[hTemp_ffa0] = deck index of a Water Energy attached to the turn holder's Active Pokémon (0-59)
DiscardAttachedWaterEnergy_AISelection:
	ld a, TYPE_ENERGY_WATER
	jr DiscardFirstAttachedEnergyOfSpecifiedType

; output:
;	[hTemp_ffa0] = deck index of a Psychic Energy attached to the turn holder's Active Pokémon (0-59)
DiscardAttachedPsychicEnergy_AISelection:
	ld a, TYPE_ENERGY_PSYCHIC
;	fallthrough

; AI picks the first suitable Energy card in the list of attached Energy
; input:
;	a = TYPE_ENERGY_* constant
; output:
;	[hTemp_ffa0] = deck index of an Energy card which provides Energy of the given type/color
;	               that is attached to the turn holder's Active Pokémon (0-59)
DiscardFirstAttachedEnergyOfSpecifiedType:
	call CreateListOfEnergyAttachedToActive
	ld a, [wDuelTempList] ; pick first card
	ldh [hTemp_ffa0], a
	ret


; handles the Player's selection of 2 Energy cards attached to their Active Pokemon
; output:
;	carry = set:  if the operation was cancelled by the Player (with B button)
;	[hTempList] = deck index of an Energy card attached to the turn holder's Active Pokémon (0-59)
;	[hTempList + 1] = deck index of another Energy card attached to the turn holder's Active Pokémon (0-59)
Discard2AttachedEnergyCards_PlayerSelection:
	ldtx hl, ChooseAndDiscard2EnergyCardsText
	call DrawWideTextBox_WaitForInput

	xor a
	ldh [hCurSelectionItem], a
	; a = PLAY_AREA_ARENA
	call CreateArenaOrBenchEnergyCardList
	call SortCardsInDuelTempListByID
	xor a ; PLAY_AREA_ARENA
	bank1call DisplayEnergyDiscardScreen

	ld a, 2
	ld [wEnergyDiscardMenuDenominator], a
.loop_input
	bank1call HandleEnergyDiscardMenuInput
	ret c ; exit if the B button was pressed
	call GetNextPositionInTempList
	ldh a, [hTempCardIndex_ff98]
	ld [hl], a
	call RemoveCardFromDuelTempList
	ldh a, [hCurSelectionItem]
	cp 2
	ret nc ; end loop and return when 2 have been chosen
	ld hl, wEnergyDiscardMenuNumerator
	inc [hl]
	bank1call DisplayEnergyDiscardMenu
	jr .loop_input


; makes a list of every Energy card attached to the AI's Active Pokemon
; and the AI picks the first 2 cards in that list
; output:
;	[hTempList] = deck index of an Energy card attached to the turn holder's Active Pokémon (0-59)
;	[hTempList + 1] = deck index of another Energy card attached to the turn holder's Active Pokémon (0-59)
Discard2AttachedEnergyCards_AISelection:
	xor a ; PLAY_AREA_ARENA
	call CreateArenaOrBenchEnergyCardList
	ld hl, wDuelTempList
	ld a, [hli]
	ldh [hTempList], a
	ld a, [hl]
	ldh [hTempList + 1], a
	ret


; discards 2 given Energy cards from the turn holder's Active Pokemon
; preserves all registers except af
; input:
;	[hTempList] = deck index of the first card to discard (0-59)
;	[hTempList + 1] = deck index of the second card to discard (0-59)
Discard2AttachedEnergyCards_DiscardEffect:
	ldh a, [hTempList]
	call PutCardInDiscardPile
	ldh a, [hTempList + 1]
	jp PutCardInDiscardPile


; discards all Energy attached to the turn holder's Active Pokemon
DiscardAllAttachedEnergyEffect:
	xor a ; PLAY_AREA_ARENA
	call CreateArenaOrBenchEnergyCardList
	ld hl, wDuelTempList
; put all Energy cards in the discard pile
.loop
	ld a, [hli]
	cp $ff
	ret z ; return if no more Energy to discard
	call PutCardInDiscardPile
	jr .loop


; does 10 damage to each of the turn holder's Benched Pokemon
OwnBench_10DamageEffect:
	ld a, TRUE
	ld [wIsDamageToSelf], a
	ld de, 10
;	fallthrough

; does de damage to each of the turn holder's Benched Pokemon
; preserves de
; input:
;	de = amount of damage to deal to each Pokemon
DealDamageToAllBenchedPokemon:
	ld a, DUELVARS_NUMBER_OF_POKEMON_IN_PLAY_AREA
	get_turn_duelist_var
	ld c, a
	ld b, PLAY_AREA_ARENA
.loop
	inc b
	dec c
	ret z
	call DealDamageToPlayAreaPokemon_RegularAnim
	jr .loop


; flips a coin and stores the result
; preserves hl
; output:
;	a & [hTemp_ffa0] = result of the coin toss (0 = tails, 1 = heads)
DamageEitherBench_50PercentEffect:
	ldtx de, DamageToOppBenchIfHeadsDamageToYoursIfTailsText
	call TossCoin
	ldh [hTemp_ffa0], a ; store coin result
	ret


; if tails, does 10 damage to each of the turn holder's Benched Pokemon
; if heads, does 10 damage to each of the opponent's Benched Pokemon
; input:
;	[hTemp_ffa0] = result of the coin toss (0 = tails, 1 = heads)
DamageEitherBench_10DamageEffect:
	ldh a, [hTemp_ffa0]
	or a
	jr z, OwnBench_10DamageEffect
	
	; damage opponent's bench
	rst SwapTurn
	ld de, 10
	call DealDamageToAllBenchedPokemon
	jp SwapTurn


; user does 40 damage to itself and 10 damage to each Benched Pokemon
Selfdestruct40Effect:
	ld a, 40
	call DealRecoilDamageToSelf
;	fallthrough

; does 10 damage to each Benched Pokemon
DamageBothBenches_10DamageEffect:
	call OwnBench_10DamageEffect

	; damage opponent's bench
	rst SwapTurn
	xor a ; FALSE
	ld [wIsDamageToSelf], a
	ld de, 10
	call DealDamageToAllBenchedPokemon
	jp SwapTurn


; user does 60 damage to itself and 10 damage to each Benched Pokemon
Selfdestruct60Effect:
	ld a, 60
	call DealRecoilDamageToSelf
	jr DamageBothBenches_10DamageEffect


; user does 80 damage to itself and 20 damage to each Benched Pokemon
Explosion80DamageEffect:
	ld a, 80
	call DealRecoilDamageToSelf
	jr DamageBothBenches_20DamageEffect


; user does 100 damage to itself and 20 damage to each Benched Pokemon
Explosion100DamageEffect:
	ld a, 100
	call DealRecoilDamageToSelf
;	fallthrough

; does 20 damage to each Benched Pokemon
DamageBothBenches_20DamageEffect:
; own bench
	ld a, TRUE
	ld [wIsDamageToSelf], a
	ld de, 20
	call DealDamageToAllBenchedPokemon
; opponent's bench
	rst SwapTurn
	xor a ; FALSE
	ld [wIsDamageToSelf], a
	ld de, 20
	call DealDamageToAllBenchedPokemon
	jp SwapTurn


;---------------------------------------------------------------------------------
; (12) ATTACK EFFECTS THAT DAMAGE THE OPPONENT'S BENCH ARE NEXT.
;---------------------------------------------------------------------------------

; does 10 damage to a given Benched Pokemon
; preserves hl
; input:
;	[hTemp_ffa0] = play area location offset of the chosen Benched Pokemon (PLAY_AREA_* constant, -1 if none)
Also10DamageTo1Benched_DamageEffect:
	ldh a, [hTemp_ffa0]
	cp -1
	ret z ; return if there's no target
	rst SwapTurn
	ld b, a
	ld de, 10 ; damage being dealt
	call DealDamageToPlayAreaPokemon_RegularAnim
	jp SwapTurn


; handles the Player's selection of up to 3 Pokemon on the opponent's Bench
; output:
;	hTempList = $ff-terminated list with play area location offsets of opponent's Pokémon
AlsoDamageTo3Benched_PlayerSelection:
; return with an empty list if there are no Benched Pokémon to target
	rst SwapTurn
	ld a, DUELVARS_NUMBER_OF_POKEMON_IN_PLAY_AREA
	get_turn_duelist_var
	cp 2
	jr nc, .has_bench
	ld a, $ff
	ldh [hTempList], a
	jp SwapTurn

.has_bench
	ldtx hl, ChooseUpTo3PkmnOnBenchToGiveDamageText
	call DrawWideTextBox_WaitForInput

; init number of items in list and cursor position
	xor a
	ldh [hCurSelectionItem], a
	ld [wCurGigashockItem], a
	call SetupPlayAreaScreen
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
	jr z, .try_cancel ; try to exit if the B button was pressed

; A button was pressed
	ld [wCurGigashockItem], a
	call .CheckIfChosenAlready
	jr nc, .not_chosen
	; play SFX
	call PlaySFX_InvalidChoice
	jr .loop_input

.not_chosen
; mark this Play Area location
	ldh a, [hCurMenuItem]
	inc a ; ignore the Active Pokémon
	ld b, SYM_LIGHTNING
	call DrawSymbolOnPlayAreaCursor
; store it in the list of chosen Benched Pokemon
	call GetNextPositionInTempList
	ldh a, [hCurMenuItem]
	inc a ; ignore the Active Pokémon
	ld [hl], a

; check if 3 were chosen already
	ldh a, [hCurSelectionItem]
	ld c, a
	cp 3
	jr nc, .chosen

	ld a, DUELVARS_NUMBER_OF_POKEMON_IN_PLAY_AREA
	get_turn_duelist_var
	dec a ; ignore the Active Pokémon
	cp c
	jr nz, .start ; if more options are available, loop back
	; fallthrough if no other options available to choose

.chosen
	ldh a, [hCurMenuItem]
	inc a ; ignore the Active Pokémon
	call DrawPlayAreaScreenToShowChanges
	ldh a, [hKeysPressed]
	and PAD_B
	jr nz, .try_cancel
	call GetNextPositionInTempList
	ld [hl], $ff ; terminating byte
	jp SwapTurn

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

; preserves de
; input:
;	a = list index for the chosen Pokémon (index = play area location offset - 1)
; output:
;	carry = set:  if the given Pokémon was already chosen
.CheckIfChosenAlready
	inc a
	ld c, a
	ldh a, [hCurSelectionItem]
	or a
	ret z ; return no carry if this is the first selection
	ld b, a
	ld hl, hTempList
.check_chosen
	ld a, [hli]
	cp c
	scf
	ret z ; return if already chosen
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


; AI picks the 3 Pokemon on the Player's Bench with the least amount of HP
; output:
;	hTempList = $ff-terminated list with play area location offsets of opponent's Pokémon
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
	rst SwapTurn
	dec a ; ignore the Active Pokémon
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
	ld [hl], $00 ; terminating byte

; then check every Benched Pokemon's current HP,
; and sort them from lowest to highest.
	ld de, hTempList
.loop_outer
	ld a, [de]
	add DUELVARS_ARENA_CARD_HP
	get_turn_duelist_var
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
	get_turn_duelist_var
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


; does 10 damage to a number of given Pokemon on the opponent's Bench
; input:
;	hTempList = $ff-terminated list with play area location offsets of opponent's Pokémon
AlsoDamageTo3Benched_10DamageEffect:
	rst SwapTurn
	ld hl, hTempList
.loop_selection
	ld a, [hli]
	cp $ff
	jp z, SwapTurn ; done with loop
	ld b, a
	ld de, 10
	call DealDamageToPlayAreaPokemon_RegularAnim
	jr .loop_selection


; does 10 damage to each Benched Pokemon that shares a type with the opponent's Active Pokemon
Also10DamageToSameColorOnBenchEffect:
	ld a, 10
	call SetDefiniteDamage
	rst SwapTurn
	call GetArenaCardColor
	rst SwapTurn
	ldh [hCurSelectionItem], a
	cp COLORLESS
	ret z ; don't damage if Colorless

; opponent's Bench
	rst SwapTurn
	call .DamageSameColorBench
	rst SwapTurn

; own Bench
	ld a, TRUE
	ld [wIsDamageToSelf], a
	; fallthrough

.DamageSameColorBench
	ld a, DUELVARS_NUMBER_OF_POKEMON_IN_PLAY_AREA
	get_turn_duelist_var
	ld d, a
	ld e, PLAY_AREA_ARENA
	jr .next_bench ; skip the Defending Pokémon

.check_damage
	ld a, e
	call GetPlayAreaCardColor
	ld c, a
	ldh a, [hCurSelectionItem]
	cp c
	jr nz, .next_bench ; skip if not the same color
; apply damage to this Benched Pokemon
	push de
	ld b, e
	ld de, 10
	call DealDamageToPlayAreaPokemon_RegularAnim
	pop de

.next_bench
	inc e
	dec d
	jr nz, .check_damage
	ret


; flips a coin for each Pokemon on the opponent's Bench.
; if heads, does 20 damage to the Benched Pokemon.
; if tails, the user does 10 damage to itself.
ThunderstormEffect:
	xor a
	ldh [hCurSelectionItem], a

	rst SwapTurn
	ld a, DUELVARS_NUMBER_OF_POKEMON_IN_PLAY_AREA
	get_turn_duelist_var
	ld c, a
	ld b, 0 ; counter for number of tails
	ld e, b ; PLAY_AREA_ARENA
	jr .next_pkmn ; skip the Defending Pokémon

.check_damage
	push de
	push bc
	call .DisplayText
	ldtx de, NullText
	rst SwapTurn
	call TossCoin
	rst SwapTurn
	push af
	call GetNextPositionInTempList
	pop af
	ld [hl], a ; store coin toss result in list
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
	ld [hl], $ff ; terminate list
	call ResetAnimationQueue
	rst SwapTurn

; tally recoil damage
	ld a, b
	or a
	jr z, .skip_recoil
	; deal damage to self equal to number of tails times 10
	call ATimes10
	call DealRecoilDamageToSelf

; deal damage for Benched Pokemon that got heads
.skip_recoil
	rst SwapTurn
	ld hl, hTempList
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
; input:
;	e = current Pokémon's play area location offset (PLAY_AREA_* constant)
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
	get_turn_duelist_var
	call LoadCardDataToBuffer2_FromDeckIndex
	ld hl, wLoadedCard2Name
	ld a, [hli]
	ld h, [hl]
	ld l, a
	call CopyText

	xor a
	ld [wDuelDisplayedScreen], a
	ret


; does 20 damage to a given Benched Pokemon
; preserves hl
; input:
;	[hTemp_ffa0] = play area location offset of the chosen Benched Pokemon (PLAY_AREA_* constant)
DamageTo1Benched_20DamageEffect:
	rst SwapTurn
	ldh a, [hTemp_ffa0]
	ld b, a
	ld de, 20
	call DealDamageToPlayAreaPokemon_RegularAnim
	jp SwapTurn


;---------------------------------------------------------------------------------
; (13) THE REMAINING ATTACK EFFECTS THAT UTILIZE RANDOMNESS ARE NEXT.
; (METRONOME AND MIRROR MOVE ARE ALSO INCLUDED)
;---------------------------------------------------------------------------------

; randomly finds an occupied zone in the turn holder's play area
; preserves bc and de
; ouput:
;	a = play area location offset of the random Pokemon (PLAY_AREA_* constant)
PickRandomPlayAreaCard:
	ld a, DUELVARS_NUMBER_OF_POKEMON_IN_PLAY_AREA
	get_turn_duelist_var
	jp Random


; does 20 damage to a randomly chosen Pokemon in the opponent's play area
; using the Cat Punch animation
RandomEnemy20DamageEffect:
	rst SwapTurn
	call PickRandomPlayAreaCard
	ld b, a
	ld a, ATK_ANIM_CAT_PUNCH_PLAY_AREA
	ld [wLoadedAttackAnimation], a
	ld de, 20
	call DealDamageToPlayAreaPokemon
	jp SwapTurn


; does 30 damage to a randomly chosen Pokemon in the opponent's play area
RandomEnemy30DamageEffect:
	rst SwapTurn
	call PickRandomPlayAreaCard
	ld b, a
	ld de, 30
	call DealDamageToPlayAreaPokemon_RegularAnim
	jp SwapTurn


; ZeroDamage was used with EFFECTCMDTYPE_BEFORE_DAMAGE
; in the RandomEnemy40DamageEffectCommands.
; The developers most likely intended to put 40 damage for
; the Ice Breath attack in cards.asm so that the number
; would be displayed when looking at the card.
; Had that been done, then the ZeroDamage function would
; remove the damage before it was dealt to the Defending Pokemon.
;ZeroDamage:
;	xor a
;	jp SetDefiniteDamage
;
; does 40 damage to a randomly chosen Pokemon in the opponent's play area
RandomEnemy40DamageEffect:
	rst SwapTurn
	call PickRandomPlayAreaCard
	ld b, a
	ld de, 40
	call DealDamageToPlayAreaPokemon_RegularAnim
	jp SwapTurn


; does 70 damage to a randomly chosen Pokemon (other than user) in either play area
; and plays a thunder animation when the Play Area screen is shown
Random70DamageEffect:
	call ExchangeRNG
	ld de, 70 ; damage to inflict
;	fallthrough

; randomly damages another in-play Pokemon.
; ignores the card that is in [hTempPlayAreaLocation_ff9d].
; plays a thunder animation when the Play Area screen is shown.
; input:
;	de = amount of damage to deal
RandomlyDamagePlayAreaPokemon:
	xor a
	ld [wNoDamageOrEffect], a

; choose randomly which play area to attack
	call UpdateRNGSources
	and 1
	jr nz, .opp_play_area

; own play area
	ld a, TRUE
	ld [wIsDamageToSelf], a
	call PickRandomPlayAreaCard
	ld b, a
	; can't select the Pokemon that used the attack
	ldh a, [hTempPlayAreaLocation_ff9d]
	cp b
	jr z, RandomlyDamagePlayAreaPokemon ; re-roll Pokemon to attack

.damage
	ld a, ATK_ANIM_THUNDER_PLAY_AREA
	ld [wLoadedAttackAnimation], a
	jp DealDamageToPlayAreaPokemon

.opp_play_area
	xor a ; FALSE
	ld [wIsDamageToSelf], a
	rst SwapTurn
	call PickRandomPlayAreaCard
	ld b, a
	call .damage
	jp SwapTurn


; chooses a random effect from 8 possible options
; output:
;	[hTemp_ffa0] = which effect was chosen for Mystery Attack (0-7)
MysteryAttack_RandomEffect:
	ld a, 10 ; base damage
	call SetDefiniteDamage

	call UpdateRNGSources
	and %111 ; random number is 3 bits, so 8 possibilities
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

.no_effect
	ret

.more_damage
	ld a, 20
	jp SetDefiniteDamage

.no_damage
	ld a, ATK_ANIM_GLOW_EFFECT
	ld [wLoadedAttackAnimation], a
	xor a
	call SetDefiniteDamage
	jp SetNoEffectFromStatus


; in case the 5th option was chosen for the random effect,
; trigger the recovery effect for 10 HP.
; input:
;	[hTemp_ffa0] = which effect was chosen for Mystery Attack (0-7)
MysteryAttack_RecoverEffect:
	ldh a, [hTemp_ffa0]
	cp 4
	ret nz ; return if another effect was chosen
	ld de, 10
	jp ApplyAndAnimateHPRecovery


; replaces the Pokemon in the opponent's hand with randomly chosen Pokemon from the deck
OpponentHand_ReplacePokemonInEffect:
	rst SwapTurn
	call CreateHandCardList
	call SortCardsInDuelTempListByID

; first go through the hand and place all Pokemon cards back into the deck.
	ld hl, wDuelTempList
	ld c, 0 ; counter for cards being removed from the hand
.loop_hand
	ld a, [hl]
	cp $ff
	jr z, .done_hand
	call GetCardTypeFromDeckIndex_SaveDE
	cp TYPE_ENERGY
	jr nc, .next_hand ; skip if not a Pokemon
; found a Pokemon card to place in the deck
	inc c
	ld a, [hl]
	call MoveCardFromHandToTopOfDeck
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
	ld a, c
	or a
	jp z, SwapTurn ; return if no cards were removed from the hand

; c holds the number of cards that were placed in the deck.
; now pick Pokemon from the deck to place in the hand.
	ld hl, wDuelTempList
.loop_deck
	ld a, [hl]
	call GetCardTypeFromDeckIndex_SaveDE
	cp TYPE_ENERGY
	jr nc, .next_deck ; skip if not a Pokemon
	dec c
	ld a, [hl]
	call MoveCardFromDeckToHand
.next_deck
	inc hl
	ld a, c
	or a
	jr nz, .loop_deck
	jp SwapTurn


; removes and then randomly reattaches all Energy cards in the turn holder's play area
ShuffleAttachedEnergyEffect:
	xor a
	ld c, a ; initial Energy card counter = 0
	ld de, wDuelTempList
	; a = DUELVARS_CARD_LOCATIONS
	get_turn_duelist_var
	; hl = starting address for turn holder's card location data

; writes in wDuelTempList the deck indices of any Energy card
; that is attached to 1 of the turn holder's Pokemon
.loop_card_locations
	ld a, [hl]
	and CARD_LOCATION_PLAY_AREA
	jr z, .next_card_location

; is a card that is in the turn holder's play area
	ld a, l
	call GetCardTypeFromDeckIndex_SaveDE
	and TYPE_ENERGY
	jr z, .next_card_location
; is an Energy card attached to a Pokemon in the turn holder's play area
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

; divide the number of Energy cards by the number of Pokemon
	ld a, DUELVARS_NUMBER_OF_POKEMON_IN_PLAY_AREA
	get_turn_duelist_var
	ld b, a
	ld a, c
	ld c, -1
.loop_division
	inc c
	sub b
	jr nc, .loop_division
	; c = floor(a / b)

; evenly divides the Energy cards randomly to every Pokemon in the play area.
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
	call AddCardToHand
	call PutHandCardInPlayArea
	pop hl
.check_done
	dec c
	jr nz, .attach_energy
; go to next Pokemon in the turn holder's play area
	inc e ; next Play Area location
	dec b
	jr nz, .start_attach
	pop bc

	push hl
	ld hl, hTempList

; fill hTempList with PLAY_AREA_* locations that have Pokemon in them
	push hl
	xor a
.loop_init
	ld [hli], a
	inc a
	cp b
	jr nz, .loop_init
	pop hl

; shuffle them and distribute the remaining cards in a random order
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
	jp DrawPlayAreaScreenToShowChanges


; replaces the user with a copy of a random Basic Pokemon from the deck
MorphEffect:
	call ExchangeRNG
	call .PickRandomBasicPokemonFromDeck
	jr nc, .successful
	ldtx hl, AttackUnsuccessfulText
	jp DrawWideTextBox_WaitForInput

.successful
	ld a, DUELVARS_ARENA_CARD_STAGE
	get_turn_duelist_var
	or a
	jr z, .skip_discard_stage_below

; if this is an Evolved Pokemon (in case it's used by Clefable's Metronome attack),
; then first discard the lower stage card.
	push hl
	xor a ; PLAY_AREA_ARENA
	ldh [hTempPlayAreaLocation_ff9d], a
	call GetCardOneStageBelow
	ld a, d
	call PutCardInDiscardPile
	pop hl
	ld [hl], BASIC

.skip_discard_stage_below
; overwrite card ID
	ldh a, [hTempCardIndex_ff98]
	call GetCardIDFromDeckIndex
	ld a, DUELVARS_ARENA_CARD
	get_turn_duelist_var
	ldh [hTempCardIndex_ff98], a
	push de
	ld e, a
	ld d, $0
	ld hl, wPlayerDeck
	ldh a, [hWhoseTurn]
	cp PLAYER_TURN
	jr z, .deck_loaded
	ld hl, wOpponentDeck
.deck_loaded
	add hl, de
	pop de
	ld [hl], e

; overwrite HP to new card's maximum HP
	ld e, PLAY_AREA_ARENA
	call GetCardDamageAndMaxHP
	ld a, DUELVARS_ARENA_CARD_HP
	get_turn_duelist_var
	ld [hl], c

; clear changed color and status
	ld l, DUELVARS_ARENA_CARD_CHANGED_TYPE
	ld [hl], $00
	call ClearAllStatusConditions

; load both card's names for printing text
	ld a, [wTempTurnDuelistCardID]
	ld e, a
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
; output:
;	a & [hTempCardIndex_ff98] = deck index of the chosen Basic Pokemon from the deck (0-59, -1 if none)
;	carry = set:  if no Basic Pokemon were found in the deck (other than the Pokemon using this attack)
.PickRandomBasicPokemonFromDeck
	call CreateDeckCardList
	ret c ; return if the deck is empty
	ld hl, wDuelTempList
	push hl
	call ShuffleCards
	ld a, DUELVARS_ARENA_CARD
	get_turn_duelist_var
	call GetCardIDFromDeckIndex
	pop hl
.loop_deck
	ld a, [hli]
	ldh [hTempCardIndex_ff98], a
	cp $ff
	scf
	ret z ; return carry if there are no more cards to check
	call CheckDeckIndexForBasicPokemon
	jr nc, .loop_deck ; skip if not a Basic Pokemon
	ld a, [wLoadedCard2ID]
	cp e
	jr z, .loop_deck ; skip cards with same ID as the Active Pokemon
	ldh a, [hTempCardIndex_ff98]
	or a
	ret


; AI doesn't pick anything
Metronome_AISelection:
	ret


ClefairyMetronome_UseAttackEffect:
	ld a, 3 ; Energy cost of this attack
	jr HandlePlayerMetronomeEffect

ClefableMetronome_UseAttackEffect:
	ld a, 1 ; Energy cost of this attack
;	fallthrough

; handles Metronome selection, and validates whether it can use the selected attack
; input:
;	a = amount of Colorless Energy needed to use Metronome
; output:
;	carry = set:  if Metronome could not be used or if the player cancelled (with B button)
HandlePlayerMetronomeEffect:
	ld [wMetronomeEnergyCost], a
	ldtx hl, ChooseOppAttackToBeUsedWithMetronomeText
	call DrawWideTextBox_WaitForInput

	call HandleDefendingPokemonAttackSelection
	ret c ; exit if the B button was pressed

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
	rst SwapTurn
	call CopyAttackDataAndDamage_FromDeckIndex
	rst SwapTurn
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
; run the attack checks to determine whether it can be used
	ld a, EFFECTCMDTYPE_INITIAL_EFFECT_1
	call TryExecuteEffectCommandFunction
	jr c, .failed
	ld a, EFFECTCMDTYPE_INITIAL_EFFECT_2
	call TryExecuteEffectCommandFunction
	ret c ; return if the attack can't be used
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


; preserves bc and de
MirrorMove_AIEffect:
	ld a, DUELVARS_ARENA_CARD_LAST_TURN_DAMAGE
	get_turn_duelist_var
	ld [wAIMinDamage], a
	ld [wAIMaxDamage], a
	ret


; preserves bc and de
; output:
;	hl = ID for notification text:  if the below condition is true
;	carry = set:  if the user wasn't attacked in the previous turn
MirrorMove_AttackedCheck:
	ld a, DUELVARS_ARENA_CARD_LAST_TURN_DAMAGE
	get_turn_duelist_var
	ld a, [hli]
	or [hl]
	inc hl
	or [hl]
	inc hl
	ret nz ; return if the previous turn's attack did damage or caused a status/substatus
	ld a, [hli]
	or a
	ret nz ; return if the previous turn's attack had an effect
	; no attack received last turn
	ldtx hl, YouDidNotReceiveAnAttackToMirrorMoveText
	scf
	ret


; output:
;	[hTemp_ffa0] = selected attack index (0 = first attack, 1 = second attack, -1 = none selected)
MirrorMove_AmnesiaCheck:
	ld a, -1
	ldh [hTemp_ffa0], a
	ld a, DUELVARS_ARENA_CARD_LAST_TURN_EFFECT
	get_turn_duelist_var
	or a
	ret z ; return if no effect was stored
	cp LAST_TURN_EFFECT_AMNESIA
	jp z, Amnesia_PlayerSelection
	or a
	ret


; output:
;	[hTemp_ffa0] = deck index of the selected Energy card (if applicable)
MirrorMove_PlayerSelection:
	ld a, DUELVARS_ARENA_CARD_LAST_TURN_EFFECT
	get_turn_duelist_var
	or a
	ret z ; return if no effect was stored
; handle Energy card discard effect
	cp LAST_TURN_EFFECT_DISCARD_ENERGY
	jp z, DiscardEnergyDefendingPokemon_PlayerSelection
	ret


; output:
;	[hTemp_ffa0] = index for the relevant effect
MirrorMove_AISelection:
	ld a, -1
	ldh [hTemp_ffa0], a
	ld a, DUELVARS_ARENA_CARD_LAST_TURN_EFFECT
	get_turn_duelist_var
	or a
	ret z ; return if no effect was stored
	cp LAST_TURN_EFFECT_DISCARD_ENERGY
	jp z, DiscardEnergyDefendingPokemon_AISelection
	cp LAST_TURN_EFFECT_AMNESIA
	jp z, Amnesia_AISelection
	ret


; input:
;	[hTemp_ffa0] = index for the relevant effect
MirrorMove_BeforeDamage:
; if user was attacked with Amnesia, apply it to the selected attack
	ld a, DUELVARS_ARENA_CARD_LAST_TURN_EFFECT
	get_turn_duelist_var
	cp LAST_TURN_EFFECT_AMNESIA
	jp z, AttackDisableEffect ; Amnesia

; otherwise, check if there was last turn damage and write it to wDamage
	ld a, DUELVARS_ARENA_CARD_LAST_TURN_DAMAGE
	get_turn_duelist_var
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
	ret nz ; return if the attack had no effect
	ld a, DUELVARS_ARENA_CARD_LAST_TURN_EFFECT
	get_turn_duelist_var
	cp LAST_TURN_EFFECT_DISCARD_ENERGY
	jr nz, .change_weakness

; execute Energy discard effect for the chosen card
	rst SwapTurn
	ldh a, [hTemp_ffa0]
	call PutCardInDiscardPile
	ld a, DUELVARS_ARENA_CARD_LAST_TURN_EFFECT
	get_turn_duelist_var
	ld [hl], LAST_TURN_EFFECT_DISCARD_ENERGY
	rst SwapTurn

.change_weakness
	ld a, DUELVARS_ARENA_CARD_LAST_TURN_CHANGE_WEAK
	get_turn_duelist_var
	or a
	ret z ; return if Weakness wasn't changed last turn

	push hl
	rst SwapTurn
	ld a, DUELVARS_ARENA_CARD
	get_turn_duelist_var
	call LoadCardDataToBuffer2_FromDeckIndex
	rst SwapTurn
	pop hl

	ld a, [wLoadedCard2Weakness]
	or a
	ret z ; return if the Defending Pokemon has no Weakness to change

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
	rst SwapTurn
	push af
	ld a, DUELVARS_ARENA_CARD
	get_turn_duelist_var
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

; preserves bc and de
; output:
;	hl = ID for notification text
;	carry =set:  if Energy Trans cannot be used or if there aren't any
;	             Grass Energy attached to any of the turn holder's Pokemon
;	[hTemp_ffa0] = play area location offset of the user (PLAY_AREA_* constant)
EnergyTransCheck:
	ldh a, [hTempPlayAreaLocation_ff9d]
	ldh [hTemp_ffa0], a
	call CheckIsIncapableOfUsingPkmnPower
	ret c ; can't use due to status or Toxic Gas

; search play area for at least 1 Grass Energy
	ldh a, [hWhoseTurn]
	ld h, a
	ld l, DUELVARS_CARD_LOCATIONS + DECK_SIZE
.loop_deck
	dec l ; go through deck indices in reverse order
	ld a, [hl]
	and CARD_LOCATION_PLAY_AREA
	jr z, .next
	ld a, l
	call GetCardTypeFromDeckIndex_SaveDE
	cp TYPE_ENERGY_GRASS
	ret z ; return if it's a Grass Energy
.next
	ld a, l
	or a
	jr nz, .loop_deck

; none found
	ldtx hl, NoGrassEnergyText
	scf
	ret


EnergyTrans_PrintProcedureText:
	ldtx hl, ProcedureForEnergyTransferText
	call DrawWholeScreenTextBox
	or a
	ret


EnergyTrans_TransferEffect:
	ld a, DUELVARS_DUELIST_TYPE
	get_turn_duelist_var
	cp DUELIST_TYPE_PLAYER
	jr z, .player
; not player
	call SetupPlayAreaScreen
	bank1call PrintPlayAreaCardList_EnableLCD
	ret

.player
	xor a
	ldh [hCurSelectionItem], a
	call SetupPlayAreaScreen

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
	cp -1
	ret z; exit if the B button was pressed

; A button was pressed
	ldh [hAIPkmnPowerEffectParam], a
	ldh [hCurSelectionItem], a
	call CheckIfCardHasGrassEnergyAttached
	jr c, .play_sfx ; no attached Grass Energy

	ldh [hAIEnergyTransEnergyCard], a
	; temporarily take away the Energy to update the Play Area screen
	call AddCardToHand
	bank1call PrintPlayAreaCardList_EnableLCD
	ldh a, [hAIPkmnPowerEffectParam]
	ld e, a
	ldh a, [hAIEnergyTransEnergyCard]
	; give the Energy card back
	call PutHandCardInPlayArea

	; draw Grass symbol near the cursor
	ld a, e
	ld b, SYM_GRASS
	call DrawSymbolOnPlayAreaCursor

; handle the action of placing a Grass Energy card
.loop_input_put
	call DoFrame
	call HandleMenuInput
	jr nc, .loop_input_put
	cp -1
	jr z, .remove_symbol ; revert the play area screen if B button was pressed

; A button was pressed
	ldh [hCurSelectionItem], a
	ldh [hAIEnergyTransPlayAreaLocation], a
	ld a, OPPACTION_6B15
	call SetOppAction_SerialSendDuelData
	ldh a, [hAIEnergyTransPlayAreaLocation]
	ld e, a
	ldh a, [hAIEnergyTransEnergyCard]
	; give Energy card being held to this Pokemon
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


; preserves bc and d
; input:
;	a =  play area location offset to check (PLAY_AREA_* constant)
; output:
;	a = deck index of a Grass Energy card attached to the Pokémon in the given location, if any
;	carry = set:  if no Grass Energy are attached to the Pokemon in that location
CheckIfCardHasGrassEnergyAttached:
	or CARD_LOCATION_PLAY_AREA
	ld e, a
	ldh a, [hWhoseTurn]
	ld h, a
	ld l, DUELVARS_CARD_LOCATIONS + DECK_SIZE
.loop
	dec l ; go through deck indices in reverse order
	ld a, [hl]
	cp e
	ld a, l
	jr nz, .next ; skip if wrong location
	call GetCardTypeFromDeckIndex_SaveDE
	cp TYPE_ENERGY_GRASS
	ld a, l
	ret z ; return no carry with current deck index in a if it's a Grass Energy card
.next
	or a
	jr nz, .loop
	scf
	ret


; input:
;	[hAIEnergyTransEnergyCard] = deck index of the Grass Energy card being transferred (0-59)
;	[hAIEnergyTransPlayAreaLocation] = play area location offset of the Pokemon
;	                                   receiving the Grass Energy card (PLAY_AREA_* constant)
EnergyTrans_AIEffect:
	ldh a, [hAIEnergyTransPlayAreaLocation]
	ld e, a
	ldh a, [hAIEnergyTransEnergyCard]
	call AddCardToHand
	call PutHandCardInPlayArea
	bank1call PrintPlayAreaCardList_EnableLCD
	ret


; preserves bc and de
; output:
;	hl = ID for notification text
;	carry = set:  if Solar Power cannot be used or
;	              if there are no Special Conditions to remove
;	[hTemp_ffa0] = play area location offset of the user (PLAY_AREA_* constant)
SolarPowerCheck:
	call OncePerTurnPokePowerCheck
	ret c ; already used power or can't use due to status or Toxic Gas

	ld a, DUELVARS_ARENA_CARD_STATUS
	get_turn_duelist_var
	or a ; cp NO_STATUS
	ret nz ; return no carry if the turn holder's Active Pokémon has a Special Condition
	ld a, DUELVARS_ARENA_CARD_STATUS
	call GetNonTurnDuelistVariable
	or a ; cp NO_STATUS
	ret nz ; return no carry if the non-turn holder's Active Pokémon has a Special Condition
	; neither Active Pokemon are affected by any Special Conditions
	ldtx hl, NotAffectedBySpecialConditionsText
	scf
	ret


; removes any Special Conditions affecting either of the Active Pokemon
; input:
;	[hTemp_ffa0] = play area location offset of the user (PLAY_AREA_* constant)
SolarPower_RemoveStatusEffect:
	ld a, ATK_ANIM_HEAL_BOTH_SIDES
	ld [wLoadedAttackAnimation], a
	xor a ; FALSE
	ld [wAttackAnimationIsPlaying], a
	ldh a, [hTempPlayAreaLocation_ff9d]
	ld b, a
	ld c, $00 ; neither WEAKNESS nor RESISTANCE
	ldh a, [hWhoseTurn]
	ld h, a
	call PlayAttackAnimation
	call WaitAttackAnimation

	ldh a, [hTemp_ffa0]
	add DUELVARS_ARENA_CARD_FLAGS
	get_turn_duelist_var
	set USED_PKMN_POWER_THIS_TURN_F, [hl]
	ld l, DUELVARS_ARENA_CARD_STATUS
	ld [hl], NO_STATUS

	ld a, DUELVARS_ARENA_CARD_STATUS
	call GetNonTurnDuelistVariable
	ld [hl], NO_STATUS
	bank1call DrawDuelHUDs
	ret


; output:
;	hl = ID for notification text
;	carry = set:  if Heal cannot be used or if none of the turn holder's
;	              Pokemon have any damage counters on them
;	[hTemp_ffa0] = play area location offset of the user (PLAY_AREA_* constant)
HealCheck:
	call OncePerTurnPokePowerCheck
	ret c ; already used power or can't use due to status or Toxic Gas
	jp YourPokemon_DamageCheck


; flips a coin, and if heads, the player removes a damage counter
; from one of their Pokemon with damage counters on it
; input:
;	[hTemp_ffa0] = play area location offset of the user (PLAY_AREA_* constant)
Heal_RemoveDamageEffect:
	ldtx de, IfHeadsHealIsSuccessfulText
	call TossCoin
	ldh [hAIPkmnPowerEffectParam], a
	jr nc, .done ; flipped tails?

	ld a, DUELVARS_DUELIST_TYPE
	get_turn_duelist_var
	cp DUELIST_TYPE_LINK_OPP
	jr z, .link_opp
	and DUELIST_TYPE_AI_OPP
	jr nz, .done

; player
	ldtx hl, ChoosePokemonToHealText
	call DrawWideTextBox_WaitForInput
	call InitPlayAreaScreenVars
.loop_input
	bank1call OpenPlayAreaScreenForSelection
	jr c, .loop_input ; must choose, B button can't be used to exit
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
	get_turn_duelist_var
	set USED_PKMN_POWER_THIS_TURN_F, [hl]
	ldh a, [hAIPkmnPowerEffectParam]
	or a
	ret z ; return if coin toss result was tails

	ldh a, [hPlayAreaEffectTarget]
	add DUELVARS_ARENA_CARD_HP
	get_turn_duelist_var
	add 10 ; remove 1 damage counter
	ld [hl], a
	ldh a, [hPlayAreaEffectTarget]
	call DrawPlayAreaScreenToShowChanges
	jp ExchangeRNG


; handles the Player's selection of a Pokemon type/color in the play area
; input:
;	carry = set:  if the operation was cancelled by the Player (with B button)
;	[hTemp_ffa0] = play area location offset of the user (PLAY_AREA_* constant)
;	[hAIPkmnPowerEffectParam] = selected type/color (TYPE_PKMN_* constant)
Shift_PlayerSelection:
	ldtx hl, ChoosePokemonToCopyWithShiftText
	ldh a, [hTemp_ffa0]
	or $80
	call HandleColorChangeScreen
	ret c ; exit if the B button was pressed

; check whether the selected color is valid
	; first look in the turn holder's play area
	ldh [hAIPkmnPowerEffectParam], a
	call .CheckColorInPlayArea
	ret nc ; return if the color was found
	; then look in the opponent's play area
	rst SwapTurn
	call .CheckColorInPlayArea
	rst SwapTurn
	ret nc ; return if the color was found
	; not found in either play area
	ldtx hl, UnableToSelectText
	call DrawWideTextBox_WaitForInput
	jr Shift_PlayerSelection ; loop back to start

; preserves de
; input:
;	[hAIPkmnPowerEffectParam] = selected type/color (TYPE_PKMN_* constant)
; output:
;	carry = set:  if the color from input wasn't found in the turn holder's play area
.CheckColorInPlayArea
	ld a, DUELVARS_NUMBER_OF_POKEMON_IN_PLAY_AREA
	get_turn_duelist_var
	ld c, a
	ld b, PLAY_AREA_ARENA
	ldh a, [hAIPkmnPowerEffectParam]
	ld l, a
.loop_play_area
	ld a, b
	call GetPlayAreaCardColor
	cp l
	ret z ; return no carry if color was found
	inc b
	dec c
	jr nz, .loop_play_area
	; not found
	scf
	ret


; changes the user's type to a given color
; input:
;	[hTemp_ffa0] = play area location offset of the user (PLAY_AREA_* constant)
;	[hAIPkmnPowerEffectParam] = selected type/color (TYPE_PKMN_* constant)
Shift_ChangeColorEffect:
	ldh a, [hTemp_ffa0]
	ld e, a
	add DUELVARS_ARENA_CARD
	get_turn_duelist_var
	call LoadCardDataToBuffer1_FromDeckIndex

	ld a, e
	add DUELVARS_ARENA_CARD_FLAGS
	get_turn_duelist_var
	set USED_PKMN_POWER_THIS_TURN_F, [hl]

	ld a, e
	add DUELVARS_ARENA_CARD_CHANGED_TYPE
	ld l, a
	ldh a, [hAIPkmnPowerEffectParam]
	or HAS_CHANGED_COLOR
	ld [hl], a
	call LoadCardNameAndInputColor
	ldtx hl, ChangedTheColorOfText
	jp DrawWideTextBox_WaitForInput


; randomly puts 1-4 Fire Energy cards from the turn holder's deck into their hand
Firegiver_AddToHandEffect:
; fill wDuelTempList with all Fire Energy card deck indices
	xor a
	ld c, a ; initial Fire Energy counter = 0
	ld de, wDuelTempList
	; a = DUELVARS_CARD_LOCATIONS
	get_turn_duelist_var
	; hl = starting address for turn holder's card location data
.loop_cards
	ld a, [hl]
	cp CARD_LOCATION_DECK
	jr nz, .next
	ld a, l
	call GetCardTypeFromDeckIndex_SaveDE
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
	ld a, $ff ; terminating byte
	ld [de], a

; check how many were found
	ld a, c
	or a
	jr nz, .found
	; return if none found
	ldtx hl, ThereWasNoFireEnergyText
	call DrawWideTextBox_WaitForInput
	jp ShuffleCardsInDeck

; pick a random number between 1 and 4, up to the maximum number of
; Fire Energy cards that were found.
.found
	ld a, 4
	call Random
	inc a
	cp c
	jr c, .ok
	ld a, c

.ok
	ldh [hCurSelectionItem], a
	ld c, a
; load the correct attack animation, depending on whose turn it is
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
	ld hl, wDuelTempList
.loop_energy
	push hl
	push bc
	lb bc, PLAY_AREA_ARENA, $00 ; neither WEAKNESS nor RESISTANCE
	ldh a, [hWhoseTurn]
	ld h, a
	call PlayAttackAnimation
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
	get_turn_duelist_var
	inc a
	call WriteTwoDigitNumberInTxSymbolFormat_TrimLeadingZero
; update and print the number of cards in the deck
	ld a, DUELVARS_NUMBER_OF_CARDS_NOT_IN_DECK
	get_turn_duelist_var
	ld a, DECK_SIZE - 1
	sub [hl]
	ld c, e
	call WriteTwoDigitNumberInTxSymbolFormat_TrimLeadingZero
	pop bc
	pop hl

; load Fire Energy card index and add to hand
	ld a, [hli]
	call MoveCardFromDeckToHand
	dec c
	jr nz, .loop_energy

; load the number of cards added to hand and print text
	ldh a, [hCurSelectionItem]
	ld hl, wTxRam3
	ld [hli], a
	xor a
	ld [hl], a
	ldtx hl, DrewFireEnergyFromTheHandText
	call DrawWideTextBox_WaitForInput
	jp ShuffleCardsInDeck


; preserves bc and de
; output:
;	hl = ID for notification text
;	carry = set:  if Cowardice cannot be used or if there are no other Pokemon in play
;	[hTemp_ffa0] = play area location offset of the user (PLAY_AREA_* constant)
CowardiceCheck:
	ldh a, [hTempPlayAreaLocation_ff9d]
	ldh [hTemp_ffa0], a
	call CheckIsIncapableOfUsingPkmnPower
	ret c ; can't use due to status or Toxic Gas

	ld a, DUELVARS_NUMBER_OF_POKEMON_IN_PLAY_AREA
	get_turn_duelist_var
	ldtx hl, YouNoBenchedPokemonText
	cp 2
	ret c ; can't use if there are no other Pokemon in the play area

	ldh a, [hTempPlayAreaLocation_ff9d]
	add DUELVARS_ARENA_CARD_FLAGS
	get_turn_duelist_var
	ldtx hl, CannotBeUsedInTurnWhichWasPlayedText
	and CAN_EVOLVE_THIS_TURN
	scf
	ret z ; can't use if the Pokemon was played this turn

	or a
	ret


; returns the user to the hand, discarding all attached cards and moving a
; preselected Benched Pokemon to the Arena if the user was the Active Pokemon
; preserves bc
; input:
;	[hTemp_ffa0] = play area location offset of the user (PLAY_AREA_* constant)
;	[hTempPlayAreaLocation_ffa1] = play area location offset of the chosen Benched Pokemon
Cowardice_RemoveFromPlayAreaEffect:
	ldh a, [hTemp_ffa0]
	add DUELVARS_ARENA_CARD
	get_turn_duelist_var

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
	ldh a, [hTempPlayAreaLocation_ffa1]
	ld e, a
	call SwapArenaWithBenchPokemon

.skip_switch
; return card to the hand and adjust the Play Area screen
	pop af
	call MoveCardFromDiscardPileToHand
	call ShiftAllPokemonToFirstPlayAreaSlots

	xor a
	ld [wDuelDisplayedScreen], a
	ret


; flips a coin, and if heads, the opponent's Active Pokemon is Paralyzed
Quickfreeze_Paralysis50PercentEffect:
	ldtx de, ParalysisCheckText
	call TossCoin
	jr c, .heads

; tails
	call SetWasUnsuccessful
	bank1call DrawDuelMainScene
	bank1call PrintFailedEffectText
	jp WaitForWideTextBoxInput

.heads
	call ParalysisEffect
	ldh a, [hTempPlayAreaLocation_ff9d]
	ld b, a
	ld c, $00 ; neither WEAKNESS nor RESISTANCE
	ldh a, [hWhoseTurn]
	ld h, a
	call PlayAttackAnimation
	bank1call PlayStatusConditionQueueAnimations
	call WaitAttackAnimation
	bank1call ApplyStatusConditionQueue
	bank1call DrawDuelHUDs
	bank1call PrintFailedEffectText
	jp c, WaitForWideTextBoxInput
	ret


; does 30 damage to a randomly chosen Pokemon (other than user) in either play area
PealOfThunder_RandomlyDamageEffect:
	call ExchangeRNG
	ld de, 30 ; damage to inflict
	call RandomlyDamagePlayAreaPokemon
	bank1call HandleDestinyBondAndBetweenTurnKnockOuts
	ret


; input:
;	[hTemp_ffa0] = play area location offset of the user (PLAY_AREA_* constant)
Peek_SelectEffect:
; set Pokemon Power used flag
	ldh a, [hTemp_ffa0]
	add DUELVARS_ARENA_CARD_FLAGS
	get_turn_duelist_var
	set USED_PKMN_POWER_THIS_TURN_F, [hl]

	ld a, DUELVARS_DUELIST_TYPE
	get_turn_duelist_var
	cp DUELIST_TYPE_LINK_OPP
	jr z, .link_opp
	and DUELIST_TYPE_AI_OPP
	jr nz, .ai_opp

; player
	call FinishQueuedAnimations
	farcall HandlePeekSelection
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
; AI chose either a Prize card or the top card of the Player's deck,
; so show the Play Area screen and draw the cursor in the right location.
	call FinishQueuedAnimations
	rst SwapTurn
	ldh a, [hAIPkmnPowerEffectParam]
	xor $80
	farcall DrawAIPeekScreen
	rst SwapTurn
	ldtx hl, CardPeekWasUsedOnText
	jp DrawWideTextBox_WaitForInput

.hand
; AI chose to look at a random card in the hand,
; so display it to the Player on screen.
	rst SwapTurn
	ldtx hl, PeekWasUsedToLookInYourHandText
	bank1call DisplayCardDetailScreen
	jp SwapTurn


; output:
;	hl = ID for notification text
;	carry = set:  if Damage Swap cannot be used or if none of the turn holder's
;	              Pokemon have any damage counters on them
;	[hTemp_ffa0] = play area location offset of the user (PLAY_AREA_* constant)
DamageSwapCheck:
	ldh a, [hTempPlayAreaLocation_ff9d]
	ldh [hTemp_ffa0], a
	call CheckIsIncapableOfUsingPkmnPower
	ret c ; can't use due to a Special Condition or Toxic Gas
	jp YourPokemon_DamageCheck


; handles the Player's selection of damage counters in their play area for Damage Swap
; output:
;	[hPlayAreaEffectTarget] = play area location offset of Pokemon receiving the damage counter
DamageSwap_SelectAndSwapEffect:
	ld a, DUELVARS_DUELIST_TYPE
	get_turn_duelist_var
	cp DUELIST_TYPE_PLAYER
	jr z, .player
; not the Player
	call SetupPlayAreaScreen
	bank1call PrintPlayAreaCardList_EnableLCD
	ret

.player
	ldtx hl, ProcedureForDamageSwapText
	call DrawWholeScreenTextBox
	xor a
	ldh [hCurSelectionItem], a
	call SetupPlayAreaScreen

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
	cp -1
	ret z ; exit if the B button was pressed

; A button was pressed
	ldh [hTempPlayAreaLocation_ffa1], a
	ldh [hCurSelectionItem], a

; if a card has no damage, play sfx and return to start
	call GetCardDamageAndMaxHP
	or a
	jr z, .no_damage

; temporarily take damage away to draw UI
	ldh a, [hTempPlayAreaLocation_ffa1]
	add DUELVARS_ARENA_CARD_HP
	get_turn_duelist_var
	push af
	push hl
	add 10
	ld [hl], a
	bank1call PrintPlayAreaCardList_EnableLCD
	pop hl
	pop af
	ld [hl], a

; draw a damage counter next to the cursor
	ldh a, [hTempPlayAreaLocation_ffa1]
	ld b, SYM_DAMAGE_COUNTER
	call DrawSymbolOnPlayAreaCursor

; handle selection of Pokemon to give damage to
.loop_input_second
	call DoFrame
	call HandleMenuInput
	jr nc, .loop_input_second
	; if B is pressed, return damage counter
	; to the Pokemon that it was taken from
	cp -1
	jr z, .update_ui ; jump if the B button was pressed

; A button was pressed, so try to give the selected Pokemon
; the damage counter, unless doing so would KO that Pokemon.
	ldh [hPlayAreaEffectTarget], a
	ldh [hCurSelectionItem], a
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


; tries to give damage counter to hPlayAreaEffectTarget and updates UI screen if successful
; input:
;	[hTempPlayAreaLocation_ffa1] = play area location offset of the Pokemon losing a damage counter
;	[hPlayAreaEffectTarget] = play area location offset of the Pokemon gaining the damage counter
; output:
;	carry = set:  if adding the damage counter would KO the Pokemon
DamageSwap_SwapEffect:
	ldh a, [hPlayAreaEffectTarget]
	call TryGiveDamageCounter
	ret c ; return if the Pokemon would be KO'd
	bank1call PrintPlayAreaCardList_EnableLCD
	or a
	ret


; tries to give a damage counter to a given Pokemon
; preserves bc and de
; input:
;	a = play area location offset of the Pokemon gaining a damage counter (PLAY_AREA_* constant)
;	[hTempPlayAreaLocation_ffa1] = play area location offset of the Pokemon losing a damage counter
; output:
;	carry = set:  if adding the damage counter would KO the Pokemon
TryGiveDamageCounter:
	add DUELVARS_ARENA_CARD_HP
	get_turn_duelist_var
	sub 10
	scf
	ret z ; return carry if transferring would reduce the Pokémon's HP to zero
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


; output:
;	hl = ID for notification text
;	carry = set:  if Strange Behavior cannot be used or if none of the turn holder's
;	              Pokemon have any damage counters on them
;	[hTemp_ffa0] = play area location offset of the user (PLAY_AREA_* constant)
StrangeBehaviorCheck:
; can Pokemon Power be used?
	ldh a, [hTempPlayAreaLocation_ff9d]
	ldh [hTemp_ffa0], a
	call CheckIsIncapableOfUsingPkmnPower
	ret c ; return if the user has a Special Condition or if Toxic Gas is active
; can Slowbro receive any damage counters without KO-ing?
	ldh a, [hTempPlayAreaLocation_ff9d]
	add DUELVARS_ARENA_CARD_HP
	get_turn_duelist_var
	ldtx hl, CannotUseBecauseItWillBeKnockedOutText
	cp 10 + 10
	ret c ; return if the user would be KO'd
; do any of the turn holder's Pokemon have any damage counters?
	jp YourPokemon_DamageCheck


; handles the Player's selection of damage counters in their play area for Strange Behavior
; input:
;	[hTemp_ffa0] = play area location offset of the user (PLAY_AREA_* constant)
StrangeBehavior_SelectAndSwapEffect:
	ld a, DUELVARS_DUELIST_TYPE
	get_turn_duelist_var
	cp DUELIST_TYPE_PLAYER
	jr z, .player

; not the Player
	call SetupPlayAreaScreen
	bank1call PrintPlayAreaCardList_EnableLCD
	ret

.player
	ldtx hl, ProcedureForStrangeBehaviorText
	call DrawWholeScreenTextBox

	xor a
	ldh [hCurSelectionItem], a
	call SetupPlayAreaScreen
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
	ret z ; exit if the B button was pressed

; A button was pressed
	ldh [hCurSelectionItem], a
	ldh [hTempPlayAreaLocation_ffa1], a
	ld hl, hTemp_ffa0
	cp [hl]
	jr z, .play_sfx ; can't select the user

	call GetCardDamageAndMaxHP
	or a
	jr z, .play_sfx ; can't select a Pokemon without damage

	ldh a, [hTemp_ffa0]
	call TryGiveDamageCounter
	jr c, .play_sfx ; can't transfer if the user would be KO'd
	ld a, OPPACTION_6B15
	call SetOppAction_SerialSendDuelData
	jr .start

.play_sfx
	call PlaySFX_InvalidChoice
	jr .loop_input


; tries to give damage counter to the user and updates UI screen if successful
; input:
;	[hTemp_ffa0] = play area location offset of the user (PLAY_AREA_* constant)
;	[hTempPlayAreaLocation_ffa1] = play area location offset of the Pokémon losing a damage counter
; output:
;	carry = set:  if adding the damage counter would KO the user
StrangeBehavior_SwapEffect:
	ldh a, [hTemp_ffa0]
	call TryGiveDamageCounter
	ret c ; return if the Pokemon would be KO'd
	bank1call PrintPlayAreaCardList_EnableLCD
	or a
	ret


; output:
;	hl = ID for notification text
;	carry = set:  if Curse cannot be used or
;	              if the opponent only has 1 Pokemon or
;	              if none of the opponent's Pokemon are damaged
;	[hTemp_ffa0] = play area location offset of the user (PLAY_AREA_* constant)
CurseCheck:
	call OncePerTurnPokePowerCheck
	ret c ; already used power or can't use due to status or Toxic Gas
	ld a, DUELVARS_NUMBER_OF_POKEMON_IN_PLAY_AREA
	call GetNonTurnDuelistVariable
	ldtx hl, CannotUseSinceTheresOnly1PkmnText
	cp 2
	ret c ; return if the opponent only has 1 Pokemon
	; returns carry if none of the opponent's Pokemon have any damage counters
	rst SwapTurn
	call YourPokemon_DamageCheck
	jp SwapTurn


; handles the Player's selection for moving a damage counter in the opponent's play area
; output:
;	carry = set:  if the operation was cancelled by the Player (with B button)
;	[hTempPlayAreaLocation_ffa1] = play area location offset of the Pokemon losing the damage counter
;	[hPlayAreaEffectTarget] = play area location offset of the Pokemon gaining the damage counter
Curse_PlayerSelection:
	ldtx hl, ProcedureForCurseText
	call DrawWholeScreenTextBox
	rst SwapTurn
	xor a
	ldh [hCurSelectionItem], a
	call SetupPlayAreaScreen
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
	cp -1
	jr z, .cancel ; exit if the B button was pressed

; A button was pressed
	ldh [hCurSelectionItem], a
	ldh [hTempPlayAreaLocation_ffa1], a
	call GetCardDamageAndMaxHP
	or a
	jr nz, .picked_first ; test if has damage
	; play sfx and loop back if that Pokémon doesn't have any damage counters
	call PlaySFX_InvalidChoice
	jr .loop_input_first

.picked_first
; give 10 HP to the selected Pokemon, draw the scene,
; then immediately revert this.
	ldh a, [hTempPlayAreaLocation_ffa1]
	add DUELVARS_ARENA_CARD_HP
	get_turn_duelist_var
	push af
	push hl
	add 10
	ld [hl], a
	bank1call PrintPlayAreaCardList_EnableLCD
	pop hl
	pop af
	ld [hl], a

; draw a damage counter next to the cursor
	ldh a, [hTempPlayAreaLocation_ffa1]
	ld b, SYM_DAMAGE_COUNTER
	call DrawSymbolOnPlayAreaCursor

; handle input to pick the target to receive the damage counter
.loop_input_second
	call DoFrame
	call HandleMenuInput
	jr nc, .loop_input_second
	ldh [hPlayAreaEffectTarget], a
	cp -1 ; was B pressed?
	jr nz, .a_press ; jump if it wasn't the B button (which means it was the A button)

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
; so store this play area location offset
; and erase the damage counter by the cursor.
	ldh a, [hTempPlayAreaLocation_ffa1]
	ld b, SYM_SPACE
	call DrawSymbolOnPlayAreaCursor
	call EraseCursor
	jp SwapTurn

; returns carry if the operation was cancelled
.cancel
	scf
	jp SwapTurn


; transfers a damage counter between 2 of the opponent's Pokemon
; input:
;	[hTemp_ffa0] = play area location offset of the user (PLAY_AREA_* constant)
;	[hTempPlayAreaLocation_ffa1] = play area location offset of the Pokemon losing the damage counter
;	[hPlayAreaEffectTarget] = play area location offset of the Pokemon gaining the damage counter
Curse_TransferDamageEffect:
; set Pokemon Power as used
	ldh a, [hTemp_ffa0]
	add DUELVARS_ARENA_CARD_FLAGS
	get_turn_duelist_var
	set USED_PKMN_POWER_THIS_TURN_F, [hl]

; figure out the type of duelist that used Curse.
; if it was the player, no need to draw the Play Area screen.
	rst SwapTurn
	ld a, DUELVARS_DUELIST_TYPE
	call GetNonTurnDuelistVariable
	cp DUELIST_TYPE_PLAYER
	jr z, .vs_player

; vs. opponent
	call SetupPlayAreaScreen
.vs_player
; transfer the damage counter between the targets that were selected
	ldh a, [hPlayAreaEffectTarget]
	add DUELVARS_ARENA_CARD_HP
	get_turn_duelist_var
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
	bank1call InitAndPrintPlayAreaCardInformationAndLocation_WithTextBox

.done
	rst SwapTurn
	call ExchangeRNG
	bank1call HandleDestinyBondAndBetweenTurnKnockOuts
	ret


; preserves bc and de
; output:
;	hl = ID for notification text
;	carry = set:  if Step In cannot be used
;	[hTemp_ffa0] = play area location offset of the user (PLAY_AREA_* constant)
StepInCheck:
; first check if this Pokemon is on the Bench
	ldh a, [hTempPlayAreaLocation_ff9d]
	ldh [hTemp_ffa0], a
	ldtx hl, CanOnlyBeUsedOnTheBenchText
	or a ; cp PLAY_AREA_ARENA
	jp nz, OncePerTurnPokePowerCheck
	; return carry if this is the Active Pokémon
	scf
	ret


; switches the user with the Active Pokemon
; preserves bc
; input:
;	[hTemp_ffa0] = play area location offset of the user (PLAY_AREA_* constant)
StepIn_SwitchEffect:
	ldh a, [hTemp_ffa0]
	ld e, a
	call SwapArenaWithBenchPokemon
	ld a, DUELVARS_ARENA_CARD_FLAGS
	get_turn_duelist_var
	set USED_PKMN_POWER_THIS_TURN_F, [hl]
	ret


; removes 2 damage counters from each of the turn holder's Pokemon
HealingWind_PlayAreaHealEffect:
; play initial animation
	ldh a, [hTempPlayAreaLocation_ff9d]
	ld b, a
	ld c, $00 ; neither WEAKNESS nor RESISTANCE
	ldh a, [hWhoseTurn]
	ld h, a
	call PlayAttackAnimation
	call WaitAttackAnimation
	ld a, ATK_ANIM_HEALING_WIND_PLAY_AREA
	ld [wLoadedAttackAnimation], a

	ld a, DUELVARS_NUMBER_OF_POKEMON_IN_PLAY_AREA
	get_turn_duelist_var
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
	get_turn_duelist_var
	add e
	ld [hl], a

; play heal animation
	ldh a, [hTempPlayAreaLocation_ff9d]
	ld b, a
	ld c, $01 ; WEAKNESS
	ldh a, [hWhoseTurn]
	ld h, a
	call PlayAttackAnimation
	call WaitAttackAnimation
.next_pkmn
	pop de
	inc e
	dec d
	jr nz, .loop_play_area
	ret


; this is called to potentially negate a non-damaging attack, like Lure.
; preserves de
; input:
;	e = play area location offset of the Pokémon being checked (PLAY_AREA_* constant)
; output:
;	carry = set:  if the turn holder's Active Pokémon is MEW_LV8 or HAUNTER_LV17
HandleNShieldAndTransparency:
	push de
	ld a, DUELVARS_ARENA_CARD
	add e
	get_turn_duelist_var
	call _GetCardIDFromDeckIndex
	cp MEW_LV8
	jr z, .nshield
	cp HAUNTER_LV17
	jr z, .transparency
.done
	pop de
	or a
	ret

.nshield
	ld a, DUELVARS_ARENA_CARD_STAGE
	call GetNonTurnDuelistVariable
	or a
	jr z, .done
	ld a, NO_DAMAGE_OR_EFFECT_NSHIELD
	ld [wNoDamageOrEffect], a
	ldtx hl, NoDamageOrEffectDueToNShieldText
.print_text
	call DrawWideTextBox_WaitForInput
	pop de
	scf
	ret

.transparency
	xor a
	ld [wDuelDisplayedScreen], a
	ldtx de, TransparencyCheckText
	call TossCoin
	jr nc, .done
	ld a, NO_DAMAGE_OR_EFFECT_TRANSPARENCY
	ld [wNoDamageOrEffect], a
	ldtx hl, NoDamageOrEffectDueToTransparencyText
	jr .print_text


;---------------------------------------------------------------------------------
; (15) TRAINER CARD EFFECTS ARE NEXT.
; (Bill/Energy Search/Gust of Wind/Pokedex/Professor Oak are sorted with attacks effects)
;---------------------------------------------------------------------------------

; handles screen for the Player to select 2 cards from the hand to discard.
; first prints text informing the Player to choose cards to discard
; then runs the HandlePlayerSelection2HandCards routine.
; output:
;	carry = set:  if the operation was cancelled by the Player (with B button)
;	[hTempList] = deck index of the first card that was selected from the hand
;	[hTempList + 1] = deck index of the second card that was selected from the hand
Discard2Cards_PlayerSelection:
	ldtx hl, Choose2CardsFromHandToDiscardText
	ldtx de, ChooseTheCardToDiscardText
;	fallthrough

; handles the screen for the Player to select 2 cards from the hand.
; this is an activation cost for several Trainer card effects.
; assumes the effect is coming from a Trainer card which needs to be removed
; from the hand before any selections can be made.
; input:
;	hl = text to print in the initial text box
;	de = text to print in a subsequent text box
; output:
;	carry = set:  if the operation was cancelled by the Player (with B button)
;	[hTempList] = deck index of the first card that was selected from the hand (0-59)
;	[hTempList + 1] = deck index of the second card that was selected from the hand (0-59)
HandlePlayerSelection2HandCards:
	push de
	call DrawWideTextBox_WaitForInput

; remove the card being played from the list of cards to select from hand.
	call CreateHandCardList
	ldh a, [hTempCardIndex_ff9f] ; deck index of the Trainer card being played
	call RemoveCardFromDuelTempList

	xor a
	ldh [hCurSelectionItem], a
	pop hl
.loop
	push hl
	bank1call InitAndDrawCardListScreenLayout_WithSelectCheckMenu
	pop hl
	call SetCardListInfoBoxText
	push hl
	bank1call DisplayCardList
	pop hl
	ret c ; exit if the B button was pressed
	push hl
	call GetNextPositionInTempList
	ldh a, [hTempCardIndex_ff98]
	ld [hl], a
	call RemoveCardFromDuelTempList
	pop hl
	ldh a, [hCurSelectionItem]
	cp 2
	jr c, .loop ; is selection over?
	ret


; assumes the deck index of the card being played is in [hTempCardIndex_ff9f]
; preserves bc
PlayThisAsBasicPokemonEffect:
	ldh a, [hTempCardIndex_ff9f]
	jp PutHandPokemonCardInPlayArea


; discards the Pokemon in a given location and if it was the Active Pokemon,
; moves the Pokemon in another given location to the Arena
; preserves bc
; input:
;	[hTemp_ffa0] = play area location offset of the Trainer Pokemon (PLAY_AREA_* constant)
;	[hTempPlayAreaLocation_ffa1] = chosen Benched Pokémon's location:  if hTemp_ffa0 = PLAY_AREA_ARENA
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


; preserves bc and de
; ouput:
;	hl = ID for notification text
;	carry = set:  if there aren't at least 2 other cards in the turn holder's hand or
;	              if there are no cards left in the turn holder's deck
ComputerSearchCheck:
	call OtherCardsInHandCheck
	ret c ; return if not enough cards in hand
	jp DeckCheck


; handles the Player's selection of any 1 card from the deck
; output:
;	[hTempList + 2] = deck index of the card to move from the deck to the hand (0-59)
ComputerSearch_PlayerDeckSelection:
	call CreateDeckCardList
	bank1call InitAndDrawCardListScreenLayout_WithSelectCheckMenu
	ldtx hl, ChooseCardToPlaceInHandText
	ldtx de, DuelistDeckText
	call SetCardListHeaderText
.loop_input
	bank1call DisplayCardList
	jr c, .loop_input ; must choose, B button can't be used to exit
	ldh [hTempList + 2], a
	ret


; discards 2 given cards from the turn holder's hand and
; moves another given card from the turn holder's deck to their hand
; input:
;	[hTempList] = deck index of the first card to discard from the hand (0-59)
;	[hTempList + 1] = deck index of the second card to discard from the hand (0-59)
;	[hTempList + 2] = deck index of the card to move from the deck to the hand (0-59)
ComputerSearch_DiscardAddToHandEffect:
; discard 2 cards from the hand
	ld hl, hTempList
	ld a, [hli]
	call MoveCardFromHandToDiscardPile
	ld a, [hli]
	call MoveCardFromHandToDiscardPile

; add a card from the deck to the hand
	ld a, [hl]
	call MoveCardFromDeckToHand
	jp ShuffleCardsInDeck


; handles the Player's selection of a Pokemon in their Play Area
; output:
;	carry = set:  if the operation was cancelled by the Player (with B button)
;	[hTemp_ffa0] = play area location offset of the chosen Pokemon (PLAY_AREA_* constant)
Defender_PlayerSelection:
	ldtx hl, ChoosePokemonToAttachDefenderToText
	call DrawWideTextBox_WaitForInput
	bank1call InitVarsAndOpenPlayAreaScreenForSelection
;	ret c ; exit if the B button was pressed
	ldh [hTemp_ffa0], a
	ret


; puts this card into play in a given play area location and
; increases the number of Defender effects in that location by 1.
; assumes the deck index of the card being played is in [hTempCardIndex_ff9f].
; input:
;	[hTemp_ffa0] = play area location offset of the chosen Pokemon (PLAY_AREA_* constant)
Defender_AttachDefenderEffect:
; attach the Trainer card to the selected Pokemon
	ldh a, [hTemp_ffa0]
	ld e, a
	ldh a, [hTempCardIndex_ff9f]
	call PutHandCardInPlayArea

; increase the number of Defender cards in this location by 1
	ldh a, [hTemp_ffa0]
	add DUELVARS_ARENA_CARD_ATTACHED_DEFENDER
	get_turn_duelist_var
	inc [hl]

; show the selected Pokemon on the screen if this effect wasn't initiated by the Player
	call IsPlayerTurn
	ret c ; return if it's the Player's turn
	ldh a, [hTemp_ffa0]
	jp DrawPlayAreaScreenToShowChanges


; handles the Player's selection of an Evolved Pokemon in their play area for Devolution Spray
; output:
;	carry = set:  if the operation was cancelled by the Player (with B button)
;	hTempList = $ff-terminated list with devolution information
DevolutionSpray_PlayerSelection:
; display textbox
	ldtx hl, ChooseEvolutionCardAndPressAButtonToDevolveText
	call DrawWideTextBox_WaitForInput

; have Player select an an Evolved Pokemon in the Play Area screen
	ld a, 1
	ldh [hCurSelectionItem], a
	call InitPlayAreaScreenVars
.read_input
	bank1call OpenPlayAreaScreenForSelection
	ret c ; exit if the B button was pressed
	call GetCardOneStageBelow
	jr c, .read_input ; can't select a Basic Pokemon

; get pre-evolution card data
	ldh a, [hTempPlayAreaLocation_ff9d]
	add DUELVARS_ARENA_CARD_HP
	get_turn_duelist_var
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
	bank1call InitAndPrintPlayAreaCardInformationAndLocation_WithTextBox
	jr c, .done_selection ; end selection if B button was pressed
	; do one more devolution
	call GetCardOneStageBelow

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

; rewrite all duelvars from before the selection was done.
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


; discards a specified number of Evolution cards from a given
; Evolved Pokemon in the turn holder's play area
; input:
;	hTempList = $ff-terminated list with devolution information
DevolutionSpray_DevolutionEffect:
; first byte in list is the chosen play area location
	ld hl, hTempList
	ld a, [hli]
	ldh [hTempPlayAreaLocation_ff9d], a
	add DUELVARS_ARENA_CARD
	get_turn_duelist_var
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
	call GetCardOneStageBelow
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
	bank1call HandleDestinyBondAndBetweenTurnKnockOuts
	ret


; preserves bc and de
; output:
;	hl = ID for notification text
;	carry = set:  if either player has no Energy cards attached to any of their Pokemon
SuperEnergyRemoval_EnergyCheck:
	call YourPokemon_AttachedEnergyCheck
	ldtx hl, NoEnergyCardsAttachedToPokemonInYourPlayAreaText
	ret c ; return if no attached Energy in own play area
;	fallthrough

; preserves bc and de
; output:
;	hl = ID for notification text
;	carry = set:  if the opponent has no Energy cards attached to any of their Pokemon
EnergyRemovalCheck:
	rst SwapTurn
	call YourPokemon_AttachedEnergyCheck
	ldtx hl, NoEnergyCardsAttachedToPokemonInOppPlayAreaText
	jp SwapTurn


; output:
;	carry = set:  if the operation was cancelled by the Player (with B button)
;	[hTempList] = play area location offset of the chosen Pokemon (PLAY_AREA_* constant)
;	[hTempList + 1] = deck index of the selected Energy card (0-59)
EnergyRemoval_PlayerSelection:
	ldtx hl, ChoosePokemonToRemoveEnergyFromText
	call DrawWideTextBox_WaitForInput
	rst SwapTurn
	call HandlePokemonAndEnergySelectionScreen
	jp SwapTurn


; discards a given Energy card from a given Pokemon in the opponent's play area
; input:
;	[hTempList] = play area location offset of the chosen Pokemon (PLAY_AREA_* constant)
;	[hTempList + 1] = deck index of the selected Energy card (0-59)
EnergyRemoval_DiscardEffect:
	rst SwapTurn
	ldh a, [hTempList + 1]
	call PutCardInDiscardPile
	rst SwapTurn

; show the selected Pokemon on the screen if this effect wasn't initiated by the Player
	call IsPlayerTurn
	ret c ; return if it's the Player's turn
	rst SwapTurn
	ldh a, [hTempList]
	call DrawPlayAreaScreenToShowChanges
	jp SwapTurn


; handles the Player's selection of a Pokemon in the play area,
; then opens a screen to choose one of the Energy cards attached to the selected Pokemon.
; output:
;	carry = set:  if the operation was cancelled by the Player (with B button)
;	[hTempList] = play area location offset of the chosen Pokemon (PLAY_AREA_* constant)
;	[hTempList + 1] = deck index of the selected Energy card (0-59)
HandlePokemonAndEnergySelectionScreen:
	bank1call InitVarsAndOpenPlayAreaScreenForSelection
	ret c ; exit if the B button was pressed
	ld e, a
	call GetPlayAreaCardAttachedEnergies
;	ld a, [wTotalAttachedEnergies] ; already loaded
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
;	ret c ; exit if the B button was pressed
	ldh [hTempList + 1], a
	ldh a, [hTempPlayAreaLocation_ff9d]
	ldh [hTempList], a
	ret


; output:
;	carry = set:  if the operation was cancelled by the Player (with B button)
;	[hTempList] = play area location offset of the turn holder's Pokemon (PLAY_AREA_* constant)
;	[hTempList + 1] = deck index of the Energy card to discard from the turn holder's play area (0-59)
;	[hTempList + 2] = play area location offset of the opponent's Pokemon (PLAY_AREA_* constant)
;	[hTempList + 3] = $ff-terminated list with deck indices of Energy cards to discard from the opponent's play area
SuperEnergyRemoval_PlayerSelection:
; handle selection of Energy to discard in own play area
	ldtx hl, ChoosePokemonInYourAreaThenPokemonInYourOppText
	call DrawWideTextBox_WaitForInput
	call HandlePokemonAndEnergySelectionScreen
	ret c ; exit if the B button was pressed

	ldtx hl, ChoosePokemonToRemoveEnergyFromText
	call DrawWideTextBox_WaitForInput

	rst SwapTurn
	ld a, 3
	ldh [hCurSelectionItem], a
.select_opp_pkmn
	bank1call InitVarsAndOpenPlayAreaScreenForSelection
	jp c, SwapTurn ; exit if the B button was pressed
	ld e, a
	call GetPlayAreaCardAttachedEnergies
;	ld a, [wTotalAttachedEnergies] ; already loaded
	or a
	jr nz, .has_energy ; has at least 1 attached Energy card
	; no Energy, loop back
	ldtx hl, NoEnergyCardsAttachedText
	call DrawWideTextBox_WaitForInput
	jr .select_opp_pkmn

.has_energy
; store this Pokemon's Play Area location
	ldh a, [hTempPlayAreaLocation_ff9d]
	ldh [hTempList + 2], a
; store which Energy card to discard from it
	call CreateArenaOrBenchEnergyCardList
	ldh a, [hTempPlayAreaLocation_ff9d]
	bank1call DisplayEnergyDiscardScreen
	ld a, 2
	ld [wEnergyDiscardMenuDenominator], a

.loop_discard_energy_selection
	bank1call HandleEnergyDiscardMenuInput
	jr nc, .energy_selected
	; B button was pressed
	ld a, 5 ; 2 target Pokémon + 3 target Energy cards
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
	jr c, .done ; exit if there are no more Energy cards to select
	ldh a, [hCurSelectionItem]
	cp 5 ; 2 target Pokémon + 3 target Energy cards
	jr nc, .done ; no more Energy cards to select
	ld hl, wEnergyDiscardMenuNumerator
	inc [hl]
	bank1call DisplayEnergyDiscardMenu
	jr .loop_discard_energy_selection

.done
	call GetNextPositionInTempList
	ld [hl], $ff ; terminating byte
	or a
	jp SwapTurn


; discards a given Energy card from a given Pokemon in the turn holder's play area,
; then discards 1 or more given Energy cards from a given Pokemon in the opponent's play area
; input:
;	[hTempList] = play area location offset of the turn holder's Pokemon (PLAY_AREA_* constant)
;	[hTempList + 1] = deck index of the Energy card to discard from the turn holder's play area (0-59)
;	[hTempList + 2] = play area location offset of the opponent's Pokemon (PLAY_AREA_* constant)
;	[hTempList + 3] = $ff-terminated list with deck indices of Energy cards to discard from the opponent's play area
SuperEnergyRemoval_DiscardEffect:
	ld hl, hTempList + 1

; discard an Energy card from one of the turn holder's Pokemon
	ld a, [hli]
	call PutCardInDiscardPile

; iterate and discard Energy cards from the opponent's Pokemon
	inc hl
	rst SwapTurn
.loop
	ld a, [hli]
	cp $ff
	jr z, .done_discard
	call PutCardInDiscardPile
	jr .loop

.done_discard
	rst SwapTurn
	call IsPlayerTurn
	ret c ; return if it's the Player's turn

; otherwise, show the affected Pokemon in the opponent's play area
	ldh a, [hTempList]
	call DrawPlayAreaScreenToShowChanges
	xor a
	ld [wDuelDisplayedScreen], a
	rst SwapTurn
	ldh a, [hTempList + 2]
	call DrawPlayAreaScreenToShowChanges
	jp SwapTurn


; output:
;	hl = ID for notification text
;	carry = set:  if there isn't another card in the turn holder's hand or
;	              if there are no Basic Energy cards in the turn holder's discard pile
EnergyRetrievalCheck:
	ld a, DUELVARS_NUMBER_OF_CARDS_IN_HAND
	get_turn_duelist_var
	ldtx hl, NotEnoughCardsInHandText
	cp 2
	ret c ; return if this is the only card in the hand
	call CreateEnergyCardListFromDiscardPile_OnlyBasic
	ldtx hl, NoBasicEnergyCardsInDiscardPileText
	ret


; handles the Player's selection of a card from their hand.
; assumes the effect is coming from a Trainer card which needs to be removed
; from the hand before a selection can be made.
; output:
;	carry = set:  if the operation was cancelled by the Player (with B button)
;	[hTempList] = deck index of the chosen card from the turn holder's hand (0-59)
EnergyRetrieval_PlayerHandSelection:
	ldtx hl, ChooseCardToDiscardFromHandText
	call DrawWideTextBox_WaitForInput

; create a list of cards in the turn holder's hand and then
; remove the Trainer card being played from the list of choices.
	call CreateHandCardList
	ldh a, [hTempCardIndex_ff9f]
	call RemoveCardFromDuelTempList

; display the list on screen and have the player select 1 of the cards
	bank1call InitAndDrawCardListScreenLayout_WithSelectCheckMenu
	bank1call DisplayCardList
;	ret c ; exit if the B button was pressed
	ldh [hTempList], a
	ret


; handles the Player's selection of up to 2 Basic Energy cards from their discard pile
; output:
;	[hTempList + 1] = deck index of a Basic Energy card in the discard pile (0-59)
;	[hTempList + 2] = deck index of another Basic Energy card in the discard pile (0-59)
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
	ld [hl], a ; store selected Energy card
	call RemoveCardFromDuelTempList
	jr c, .done ; exit if there are no more Energy cards to select
	ldh a, [hCurSelectionItem]
	cp 2 + 1 ; includes the card selected from the hand
	jr c, .select_card

.done
	call GetNextPositionInTempList
	ld [hl], $ff ; terminating byte
	or a
	ret


; discards a given card from the turn holder's hand and moves the remaining
; cards in the list from the turn holder's discard pile to their hand
; input:
;	hTempList = $ff-terminated list with deck indices of previously selected cards
EnergyRetrieval_DiscardAndAddToHandEffect:
	ld hl, hTempList
.discard
	ld a, [hli]
	call MoveCardFromHandToDiscardPile
	ld de, wDuelTempList
.loop
	ld a, [hli]
	ld [de], a
	inc de
	cp $ff
	jr z, .done
	call MoveCardFromDiscardPileToHand
	jr .loop

; show the selected cards on the screen if this effect wasn't initiated by the Player
.done
	call IsPlayerTurn
	ret c ; return if it's the Player's turn
	bank1call DisplayCardListDetails
	ret


; output:
;	hl = ID for notification text
;	carry = set:  if there aren't at least 2 other cards in the turn holder's hand or
;	              if there are no Basic Energy cards in the turn holder's discard pile
SuperEnergyRetrieval_HandEnergyCheck:
	call OtherCardsInHandCheck
	ret c ; return if not enough cards in hand
	call CreateEnergyCardListFromDiscardPile_OnlyBasic
	ldtx hl, NoBasicEnergyCardsInDiscardPileText
	ret


; handles the Player's selection for choosing a number of Basic Energy cards
; in their discard pile. stores the deck indices of the chosen cards in hTempList
; and adds a terminating byte ($ff) to the list before returning.
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
	ld a, 4 + 2 ; includes the cards selected from the hand
	call AskWhetherToQuitSelectingCards
	jr c, .loop_discard_pile_selection ; player selected to continue
	jr .done

.store_selected_card
	call GetNextPositionInTempList
	ldh a, [hTempCardIndex_ff98]
	ld [hl], a ; store selected Energy card
	call RemoveCardFromDuelTempList
	jr c, .done ; exit if there are no more Energy cards to select
	ldh a, [hCurSelectionItem]
	cp 4 + 2 ; includes the cards selected from the hand
	jr c, .loop_discard_pile_selection

.done
	call GetNextPositionInTempList
	ld [hl], $ff ; terminating byte
	or a
	ret


; discards 2 given cards from the turn holder's hand and
; moves 1 or more given cards from their discard pile to their hand
; input:
;	hTempList = $ff-terminated list with deck indices of previously selected cards
SuperEnergyRetrieval_DiscardAndAddToHandEffect:
; discard 2 cards selected from the hand
	ld hl, hTempList
	ld a, [hli]
	call MoveCardFromHandToDiscardPile
	jr EnergyRetrieval_DiscardAndAddToHandEffect.discard


; shuffles the turn holder's hand into their deck and flips a coin.
; if heads, the turn holder draws 8 cards from their deck, and if tails, they draw 1.
; assumes the effect is coming from a Trainer card which needs to be removed
; from the hand before it is shuffled into the deck
GamblerEffect:
	ldtx de, CardCheckIfHeads8CardsIfTails1CardText
	call TossCoin
	ldh [hTemp_ffa0], a ; store the coin toss result for later

; discard the Trainer card being played from the turn holder's hand
	ldh a, [hTempCardIndex_ff9f]
	call MoveCardFromHandToDiscardPile

; shuffle the hand cards into the deck
	call CreateHandCardList
	call SortCardsInDuelTempListByID
	ld hl, wDuelTempList
.loop_return_deck
	ld a, [hli]
	cp $ff
	jr z, .check_coin_toss
	call MoveCardFromHandToTopOfDeck
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


; handles the Player's selection for choosing 2 cards to discard from their hand
; and then choosing a Trainer card from their discard pile to add to their hand
;output:
;	carry = set:  if the operation was cancelled by the Player (with B button)
;	[hTempList] = deck index of the first card that was selected from the hand (0-59)
;	[hTempList + 1] = deck index of the second card that was selected from the hand (0-59)
;	[hTempList + 2] = deck index of the Trainer card that was selected from the discard pile (0-59)
ItemFinder_PlayerSelection:
	call Discard2Cards_PlayerSelection
	ret c ; exit if the B button was pressed

; cards were selected to discard from the hand.
; now to choose a Trainer card from the discard pile.
	call CreateTrainerCardListFromDiscardPile
	bank1call InitAndDrawCardListScreenLayout_WithSelectCheckMenu
	ldtx hl, ChooseCardToPlaceInHandText
	ldtx de, YourDiscardPileText
	call SetCardListHeaderText
	bank1call DisplayCardList
;	ret c ; exit if the B button was pressed
	ldh [hTempList + 2], a ; placed after the 2 cards selected to discard
	ret


; discards 2 given cards from the turn holder's hand and moves another given card
; from the turn holder's discard pile to their hand
; input:
;	[hTempList] = deck index of the first card to discard from the hand (0-59)
;	[hTempList + 1] = deck index of the second card to discard from the hand (0-59)
;	[hTempList + 2] = deck index of the card to move from the discard pile to the hand (0-59)
ItemFinder_DiscardAddToHandEffect:
; discard cards from the hand
	ld hl, hTempList
	ld a, [hli]
	call MoveCardFromHandToDiscardPile
	ld a, [hli]
	call MoveCardFromHandToDiscardPile

; place the card from the discard pile into the hand
	ld a, [hl]
	call MoveCardFromDiscardPileToHand

; show the selected card on the screen if this effect wasn't initiated by the Player
	call IsPlayerTurn
	ret c ; return if it's the Player's turn
	ldh a, [hTempList + 2]
	ldtx hl, WasPlacedInTheHandText
	bank1call DisplayCardDetailScreen
	ret


; tries to make the turn holder's Active Pokemon Confused
ImakuniEffect:
	call CheckIfActiveCardCanBeAffectedByStatus
	jr nc, .failed

; plays confusion animation and the turn holder's Active Pokemon becomes Confused
	ld a, ATK_ANIM_OWN_CONFUSION
	call PlayTrainerEffectAnimation
	ld a, DUELVARS_ARENA_CARD_STATUS
	get_turn_duelist_var
	and PSN_DBLPSN
	or CONFUSED
	ld [hl], a
	bank1call DrawDuelHUDs
	ret

.failed
; plays confusion animation and prints failure text
	ld a, ATK_ANIM_OWN_CONFUSION
	call PlayTrainerEffectAnimation
	ldtx hl, ThereWasNoEffectText
	jp DrawWideTextBox_WaitForInput


; shuffles the opponent's hand into their deck, and the opponent draws 7 cards
ImposterProfessorOakEffect:
	rst SwapTurn
	call CreateHandCardList
	call SortCardsInDuelTempListByID

; first return all cards in the hand to the deck.
	ld hl, wDuelTempList
.loop_return_deck
	ld a, [hli]
	cp $ff
	jr z, .done_return
	call MoveCardFromHandToTopOfDeck
	jr .loop_return_deck

; then draw 7 cards from the deck.
.done_return
	call ShuffleCardsInDeck
	ld a, 7
	call DrawNCards_NoCardDetails
	jp SwapTurn


; reveals each player's hand to their opponent and then shuffles any Trainer cards
; in a player's hand into that player's deck.
; assumes the effect is coming from a Trainer card which needs to be removed
; from the hand before it is revealed to the opponent.
LassEffect:
; first discard the Trainer card being played from the turn holder's hand
	ldh a, [hTempCardIndex_ff9f]
	call MoveCardFromHandToDiscardPile

	ldtx hl, PleaseCheckTheOpponentsHandText
	call DrawWideTextBox_WaitForInput

	call .DisplayLinkOrCPUHand
	; do the opponent's hand first
	rst SwapTurn
	call .ShuffleDuelistHandTrainerCardsInDeck
	rst SwapTurn
	; then do the turn holder's hand, fallthrough

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
	call GetCardTypeFromDeckIndex_SaveDE
	cp TYPE_TRAINER
	jr nz, .loop_hand
	ldh a, [hTempCardIndex_ff98]
	call MoveCardFromHandToTopOfDeck
	push hl
	ld hl, hCurSelectionItem
	inc [hl]
	pop hl
	jr .loop_hand
.done
; show card list
	ldh a, [hCurSelectionItem]
	or a
	jp nz, ShuffleCardsInDeck ; only shuffle if there were any Trainer cards
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
	rst SwapTurn
	call .DisplayOppHand
	jp SwapTurn

.DisplayOppHand
	call CreateHandCardList
	jr c, .no_cards
	bank1call InitAndDrawCardListScreenLayout
	ldtx hl, ChooseTheCardYouWishToExamineText
	ldtx de, DuelistHandText
	call SetCardListHeaderText
	ld a, PAD_A | PAD_START
	ld [wNoItemSelectionMenuKeys], a
	bank1call DisplayCardList
	ret
.no_cards
	ldtx hl, DuelistHasNoCardsInHandText
	jp DrawWideTextBox_WaitForInput


; output:
;	carry = set:  if the operation was cancelled by the Player (with B button)
;	[hTempList] = deck index of the first card that was selected from the hand (0-59)
;	[hTempList + 1] = deck index of the second card that was selected from the hand (0-59)
Maintenance_PlayerSelection:
	ldtx hl, Choose2HandCardsFromHandToReturnToDeckText
	ldtx de, ChooseTheCardToPutBackText
	jp HandlePlayerSelection2HandCards


; shuffles 2 given cards from the turn holder's hand into their deck
; and then, that player draws 1 card.
; input:
;	[hTempList] = deck index of the first card to remove from the hand (0-59)
;	[hTempList + 1] = deck index of the second card to remove from the hand (0-59)
Maintenance_ReturnToDeckAndDrawEffect:
; return both selected cards to the deck
	ldh a, [hTempList]
	call MoveCardFromHandToTopOfDeck
	ldh a, [hTempList + 1]
	call MoveCardFromHandToTopOfDeck
	call ShuffleCardsInDeck

; draw one card
	bank1call DisplayDrawOneCardScreen
	call DrawCardFromDeck
	ldh [hTempCardIndex_ff98], a
	call AddCardToHand

; show the drawn card on the screen if this effect was initiated by the Player
	call IsPlayerTurn
	ret nc ; return if it isn't the Player's turn
	bank1call DisplayPlayerDrawCardScreen
	ret


; shuffles a given Benched Pokemon and all of its attached cards into the deck
; input:
;	[hTemp_ffa0] = play area location offset of the chosen Benched Pokemon (PLAY_AREA_* constant)
MrFuji_ReturnToDeckEffect:
; get Play Area location's card index
	ldh a, [hTemp_ffa0]
	add DUELVARS_ARENA_CARD
	get_turn_duelist_var
	ldh [hTempCardIndex_ff98], a

; find all cards that are in the same location (previous stages
; and attached Energy) and return them all to the deck.
	ldh a, [hTemp_ffa0]
	or CARD_LOCATION_PLAY_AREA
	ld e, a
	ld l, DUELVARS_CARD_LOCATIONS + DECK_SIZE
.loop_cards
	dec l ; go through deck indices in reverse order
	ld a, [hl]
	cp e
	jr nz, .next_card
	ld a, l
	call ReturnCardToDeck
.next_card
	ld a, l
	or a
	jr nz, .loop_cards

; clear the Play Area location of the card
	ldh a, [hTemp_ffa0]
	ld e, a
	call EmptyPlayAreaSlot
	ld l, DUELVARS_NUMBER_OF_POKEMON_IN_PLAY_AREA
	dec [hl]
	call ShiftAllPokemonToFirstPlayAreaSlots

; if this effect wasn't initiated by the Player,
; print the selected Pokemon's name and show the card on screen.
	call IsPlayerTurn
	jp c, ShuffleCardsInDeck ; shuffle and return if it's the Player's turn
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


; puts this card into play attached to the turn holder's Active Pokemon
; and increases the number of PlusPower effects in the Arena by 1.
; assumes the deck index of the card being played is in [hTempCardIndex_ff9f]
; preserves bc
PlusPowerEffect:
; attach this card to the Active Pokemon
	ld e, PLAY_AREA_ARENA
	ldh a, [hTempCardIndex_ff9f]
	call PutHandCardInPlayArea

; increase number of PlusPower cards in this location by 1
	ld a, DUELVARS_ARENA_CARD_ATTACHED_PLUSPOWER
	get_turn_duelist_var
	inc [hl]
	ret


; flips a coin and handles the Player's selection of a Pokemon from the deck if heads
; (most of the logic is in effect_functions2.asm)
; output:
;	[hTemp_ffa0] = deck index of the chosen card (0-59, -1 if none or coin was tails)
PokeBall_PlayerSelection:
	ldtx de, TrainerCardSuccessCheckText
	call TossCoin
	jr nc, .tails
	farcall FindAnyPokemon
	ret
.tails
	ld a, -1
	ldh [hTemp_ffa0], a
	ret


; output:
;	hl = ID for notification text:  if the below condition is true
;	carry = set:  if Pokemon Breeder cannot be used
PokemonBreederCheck:
	call CreatePlayableStage2PokemonCardListFromHand
	jp nc, IsPrehistoricPowerActive
	ldtx hl, ConditionsForEvolvingToStage2NotFulfilledText
	ret


; handles the Player's selection of a Stage 2 Evolution card in their hand
; and a corresponding Basic Pokemon in their play area
; output:
;	carry = set:  if the operation was cancelled by the Player (with B button)
;	[hTemp_ffa0] = deck index of a Stage 2 Evolution card in the Player's hand (0-59)
;	[hTempPlayAreaLocation_ffa1] = location of the Pokémon being evolved (PLAY_AREA_* constant)
PokemonBreeder_PlayerSelection:
; create a list of playable Stage2 cards in the hand
	call CreatePlayableStage2PokemonCardListFromHand
	bank1call InitAndDrawCardListScreenLayout_WithSelectCheckMenu

; handle the Player's selection of a Stage2 card
	ldtx hl, PleaseSelectCardText
	ldtx de, DuelistHandText
	call SetCardListHeaderText
	bank1call DisplayCardList
	ret c ; exit if the B button was pressed
	ldh [hTemp_ffa0], a
	ldtx hl, ChooseBasicPokemonToEvolveText
	call DrawWideTextBox_WaitForInput

; handle the Player selection's of a Basic Pokemon to evolve
	call InitPlayAreaScreenVars
.read_input
	bank1call OpenPlayAreaScreenForSelection
	ret c ; exit if the B button was pressed
	ldh [hTempPlayAreaLocation_ffa1], a
	ld e, a
	ldh a, [hTemp_ffa0]
	ld d, a
	call CheckIfCanEvolveInto_BasicToStage2
	jr c, .read_input ; loop back if this card is not able to evolve
	ret ; nc


; evolves an in-play Pokemon with a Stage 2 Evolution card in the turn holder's hand
; input:
;	[hTemp_ffa0] = deck index of the Stage 2 Evolution card from the hand (0-59)
;	[hTempPlayAreaLocation_ffa1] = location of the Pokémon being evolved (PLAY_AREA_* constant)
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
	get_turn_duelist_var
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
	xor a ; TX_END
	ld [hl], a ; terminate the text string at wDefaultText
	; zero wTxRam2_b so that the name & level text just loaded to wDefaultText is printed
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
	bank1call ProcessPlayedPokemonCard
	pop af
	ldh [hTempCardIndex_ff9f], a
	ret


; output:
;	a & b = number of Stage 2 Evolution cards in the turn holder's hand that
;	        are future evolutions of Basic Pokémon in the turn holder's play area
;	carry = set:  if there are no Stage 2 Evolution cards in the turn holder's hand that
;	              are future evolutions of Basic Pokémon in the turn holder's play area
;	wDuelTempList = $ff-terminated list with deck indices of Stage 2 Evolution cards
;	                in the hand that are future evolutions of in-play Basic Pokémon
CreatePlayableStage2PokemonCardListFromHand:
	call CreateHandCardList
	ret c ; return if no cards in hand

; check if the Stage2 card in the hand can be used
; to evolve a Basic Pokemon in the play area,
; and if so, add it to the wDuelTempList.
	ld hl, wDuelTempList
	ld e, l
	ld d, h
	ld b, 0 ; counter for number of Stage 2 Pokémon in hand that will work
.loop_hand
	ld a, [hl]
	cp $ff
	jr z, .done
	call .CheckIfCanEvolveAnyPlayAreaBasicCard
	jr c, .next_hand_card
	ld a, [hl]
	ld [de], a
	inc de
	inc b
.next_hand_card
	inc hl
	jr .loop_hand

.done
	ld a, $ff ; terminating byte
	ld [de], a
	ld a, b
	or a
	ret nz
	; returns carry if list is empty
	scf
	ret

; preserves all registers except af
; input:
;	a = deck index of a card from the hand to compare with the Basic Pokemon (0-59)
; output:
;	carry = set:  if the card from input is not a Stage 2 Evolution card or
;	              if it cannot be used to evolve a Basic Pokemon in the play area
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

; check if can evolve any in-play Pokemon
	push hl
	push bc
	ld a, DUELVARS_NUMBER_OF_POKEMON_IN_PLAY_AREA
	get_turn_duelist_var
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


; checks if the turn holder's Pokemon at location e can evolve this turn and
; that it's a Basic Pokemon whose Stage 2 Evolution card is in the player's hand.
; input:
;	e = play area location offset of the Pokemon being evolved (PLAY_AREA_* constant)
;	d = deck index of a Stage 2 Evolution card to match against the Basic Pokemon (0-59)
; output:
;	carry = set:  if the given Pokemon is unable to evolve this turn or
;	              if it isn't a Basic Pokemon with a matching Stage 2 in the hand
CheckIfCanEvolveInto_BasicToStage2:
	ld a, e
	add DUELVARS_ARENA_CARD_FLAGS
	get_turn_duelist_var
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
	ret z ; nc
.cant_evolve
	scf
	ret


; removes all damage counters from each of the turn holder's in-play Pokemon
; and discards all Energy attached to any Pokemon that was healed
PokemonCenter_HealDiscardEnergyEffect:
	ld a, DUELVARS_NUMBER_OF_POKEMON_IN_PLAY_AREA
	get_turn_duelist_var
	ld d, a
	ld e, PLAY_AREA_ARENA

; go through every Pokemon in the play area to look for damage
.loop_play_area
; check its damage
	ld a, e
	ldh [hTempPlayAreaLocation_ff9d], a
	call GetCardDamageAndMaxHP
	or a
	jr z, .next_pkmn ; skip the Pokemon if it doesn't have any damage

; heal all of its damage
	push de
	call HealPlayAreaCardHP

; loop all cards in the deck and discard all Energy cards
; that are attached to this Play Area location's Pokemon.
	ldh a, [hTempPlayAreaLocation_ff9d]
	or CARD_LOCATION_PLAY_AREA
	ld e, a
	ld l, DUELVARS_CARD_LOCATIONS + DECK_SIZE
.loop_deck
	dec l ; go through deck indices in reverse order
	ld a, [hl]
	cp e
	jr nz, .next_card_deck ; skip if not attached to any card
	ld a, l
	call GetCardTypeFromDeckIndex_SaveDE
	and TYPE_ENERGY
	jr z, .next_card_deck ; skip if not an Energy
	ld a, l
	call PutCardInDiscardPile
.next_card_deck
	ld a, l
	or a
	jr nz, .loop_deck

	pop de
.next_pkmn
	inc e
	dec d
	jr nz, .loop_play_area
	ret


; output:
;	hl = ID for notification text
;	carry = set:  if there are already 5 Pokemon on the opponent's Bench or
;	              if there are no Basic Pokemon in the opponent's discard pile
PokemonFluteCheck:
	ld a, DUELVARS_NUMBER_OF_POKEMON_IN_PLAY_AREA
	call GetNonTurnDuelistVariable
	ldtx hl, NoSpaceOnTheBenchText
	cp MAX_PLAY_AREA_POKEMON
	ccf
	ret c ; return if no space on opponent's Bench

; check the opponent's discard pile
	rst SwapTurn
	call CreateBasicPokemonCardListFromDiscardPile
	ldtx hl, CannotUsePokemonFluteText
	jp SwapTurn


; handles the Player's selection of a Basic Pokemon card from the opponent's discard pile
; output:
;	carry = set:  if the operation was cancelled by the Player (with B button)
;	[hTemp_ffa0] = deck index of a Basic Pokémon in the opponent's discard pile (0-59)
PokemonFlute_PlayerSelection:
; create a list of relevant cards in the opponent's discard pile
	rst SwapTurn
	call CreateBasicPokemonCardListFromDiscardPile

; display selection screen and store the Player's selection
	bank1call InitAndDrawCardListScreenLayout_WithSelectCheckMenu
	ldtx hl, ChoosePokemonToPlaceInPlayText
	ldtx de, OpponentsDiscardPileText
	call SetCardListHeaderText
	bank1call DisplayCardList
;	ret c ; exit if the B button was pressed
	ldh [hTemp_ffa0], a
	jp SwapTurn


; puts a Pokemon from the opponent's discard pile onto their Bench
; input:
;	[hTemp_ffa0] = deck index of a (Basic) Pokémon in the opposing discard pile (0-59)
PokemonFlute_PlaceInPlayAreaText:
; place the selected card on the opponent's Bench
	rst SwapTurn
	ldh a, [hTemp_ffa0]
	call MoveCardFromDiscardPileToHand
	call PutHandPokemonCardInPlayArea
	rst SwapTurn

; show the selected card on the screen if this effect wasn't initiated by the Player
	call IsPlayerTurn
	ret c ; return if it's the Player's turn
	rst SwapTurn
	ldh a, [hTemp_ffa0]
	ldtx hl, CardWasChosenText
	bank1call DisplayCardDetailScreen
	jp SwapTurn


; output:
;	hl = ID for notification text
;	carry = set:  if there isn't a Pokemon in the turn holder's hand
PokemonTraderCheck:
	ld a, DUELVARS_NUMBER_OF_CARDS_IN_HAND
	get_turn_duelist_var
	ldtx hl, NoPokemonInHandText
	cp 2
	ret c ; return if this is the only card in the player's hand
	call CreatePokemonCardListFromHand
	ldtx hl, NoPokemonInHandText
	ret


; handles the Player's selection of a Pokemon card from their hand
; output:
;	carry = set:  if the operation was cancelled by the Player (with B button)
;	[hTemp_ffa0] = deck index of the chosen Pokemon from the Player's hand (0-59)
PokemonTrader_PlayerHandSelection:
; print text box
	ldtx hl, ChoosePokemonFromYourHandText
	call DrawWideTextBox_WaitForInput

; create list with all Pokemon cards in the hand
	call CreatePokemonCardListFromHand
	bank1call InitAndDrawCardListScreenLayout_WithSelectCheckMenu

; handle Player selection
	ldtx hl, ChoosePokemonToReturnToTheDeckText
	ldtx de, DuelistHandText
	call SetCardListHeaderText
	bank1call DisplayCardList
;	ret c ; exit if the B button was pressed
	ldh [hTemp_ffa0], a
	ret


; handles the Player's selection of a Pokemon card from their deck for Pokemon Trader
; output:
;	[hTempPlayAreaLocation_ffa1] = deck index of the chosen Pokemon from the Player's deck (0-59)
PokemonTrader_PlayerDeckSelection:
; temporarily place the chosen card from the hand into the deck
; because it is a potential search target
	ldh a, [hTemp_ffa0]
	call MoveCardFromHandToTopOfDeck

; display the list of cards from the deck
	ldtx hl, ChoosePokemonFromDeckText
	call DrawWideTextBox_WaitForInput
	call CreateDeckCardList
	bank1call InitAndDrawCardListScreenLayout_WithSelectCheckMenu
	ldtx hl, ChoosePokemonCardText
	ldtx de, DuelistDeckText
	call SetCardListHeaderText

; handle Player selection
.read_input
	bank1call DisplayCardList
	jr c, .read_input ; must choose, B button can't be used to exit
	call GetCardTypeFromDeckIndex_SaveDE
	cp TYPE_ENERGY
	jr nc, .read_input ; can't select non-Pokemon cards

; a valid card was selected, store its card index and
; place the selected card from the hand back into the hand.
	ldh a, [hTempCardIndex_ff98]
	ldh [hTempPlayAreaLocation_ffa1], a
	ldh a, [hTemp_ffa0]
	call MoveCardFromDeckToHand
	or a
	ret


; swaps a given card in the turn holder's hand with another given card in their deck
; input:
;	[hTemp_ffa0] = deck index of the card to move from the hand to the deck (0-59)
;	[hTempPlayAreaLocation_ffa1] = deck index of the card to move from the deck to the hand (0-59)
PokemonTrader_TradeCardsEffect:
; place the card from the hand into the deck
	ldh a, [hTemp_ffa0]
	call MoveCardFromHandToTopOfDeck

; place the card from the deck into the hand
	ldh a, [hTempPlayAreaLocation_ffa1]
	call MoveCardFromDeckToHand

; show the selected cards on the screen if this effect wasn't initiated by the Player
	call IsPlayerTurn
	jp c, ShuffleCardsInDeck ; shuffle and return if it's the Player's turn
	ldh a, [hTemp_ffa0]
	ldtx hl, PokemonWasReturnedToDeckText
	bank1call DisplayCardDetailScreen
	ldh a, [hTempPlayAreaLocation_ffa1]
	ldtx hl, WasPlacedInTheHandText
	bank1call DisplayCardDetailScreen
	jp ShuffleCardsInDeck


; makes a list in wDuelTempList that contains the deck indices of
; every Pokemon card in the turn holder's hand
; output:
;	a & b = number of Pokémon cards in the turn holder's hand
;	carry = set:  if there isn't a Pokémon in the turn holder's hand
;	wDuelTempList = $ff-terminated list with deck indices of all Pokémon in the hand
CreatePokemonCardListFromHand:
	ld a, DUELVARS_NUMBER_OF_CARDS_IN_HAND
	get_turn_duelist_var
	ld c, a
	ld b, 0 ; counter for number of Pokémon in hand
	ld l, DUELVARS_HAND
	ld de, wDuelTempList
.loop
	ld a, [hl]
	call GetCardTypeFromDeckIndex_SaveDE
	cp TYPE_ENERGY
	jr nc, .next_hand_card ; skip if not a Pokemon
	ld a, [hl]
	ld [de], a
	inc de
	inc b
.next_hand_card
	inc l
	dec c
	jr nz, .loop
	ld a, $ff ; terminating byte
	ld [de], a
	ld a, b
	or a
	ret nz
	scf
	ret


; handles the Player's selection of a damaged Pokemon in their play area
; and sets the amount of damage to heal
; output:
;	carry = set:  if the operation was cancelled by the Player (with B button)
;	[hTemp_ffa0] = amount of HP to heal (usually 20, 10 if capped)
;	[hTempPlayAreaLocation_ffa1] = play area location offset of the Pokemon to heal (PLAY_AREA_* constant)
Potion_PlayerSelection:
	call InitPlayAreaScreenVars
.read_input
	bank1call OpenPlayAreaScreenForSelection
	ret c ; exit if the B button was pressed
	ldh [hTempPlayAreaLocation_ffa1], a
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
	ldh [hTemp_ffa0], a
	or a
	ret


; input:
;	[hTemp_ffa0] = amount of HP to heal
;	[hTempPlayAreaLocation_ffa1] = play area location offset of the Pokemon to heal (PLAY_AREA_* constant)
HealEffect:
	ldh a, [hTempPlayAreaLocation_ffa1]
	ldh [hTempPlayAreaLocation_ff9d], a
	ldh a, [hTemp_ffa0]
;	fallthrough

; heals a given amount of damage from the Pokemon in a given location.
; also plays the healing animation and prints text with the Pokemon's name.
; input:
;	a = amount of HP to heal
;	[hTempPlayAreaLocation_ff9d] = play area location offset of the Pokemon to heal (PLAY_AREA_* constant)
HealPlayAreaCardHP:
	ld e, a
	ld d, $00

; play the heal animation
	push de
	xor a ; FALSE
	ld [wAttackAnimationIsPlaying], a
	ld a, ATK_ANIM_HEALING_WIND_PLAY_AREA
	ld [wLoadedAttackAnimation], a
	ldh a, [hTempPlayAreaLocation_ff9d]
	ld b, a
	ld c, $01 ; WEAKNESS
	ldh a, [hWhoseTurn]
	ld h, a
	call PlayAttackAnimation
	call WaitAttackAnimation
	pop hl

; print the Pokemon's card name and damage that was healed
	push hl
	call LoadTxRam3
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
	ld [hl], a
	ldtx hl, PokemonHealedDamageText
	call DrawWideTextBox_WaitForInput
	pop de

; heal the target Pokemon
	ldh a, [hTempPlayAreaLocation_ff9d]
	add DUELVARS_ARENA_CARD_HP
	get_turn_duelist_var
	add e
	ld [hl], a
	ret


; flips a coin and handles the Player's selection of a card from their discard pile if heads
; output:
;	[hTemp_ffa0] = deck index of a card in the Player's discard pile (0-59, -1 if coin was tails)
Recycle_PlayerSelection:
	ldtx de, TrainerCardSuccessCheckText
	call TossCoin
	jr nc, .tails

	call CreateDiscardPileCardList
	bank1call InitAndDrawCardListScreenLayout_WithSelectCheckMenu
	ldtx hl, PleaseSelectCardText
	ldtx de, YourDiscardPileText
	call SetCardListHeaderText
.read_input
	bank1call DisplayCardList
	jr c, .read_input ; must choose, B button can't be used to exit
	; a card was chosen from the discard pile
	ldh [hTemp_ffa0], a
	ret

.tails
	ld a, -1
	ldh [hTemp_ffa0], a
	ret


; moves a given card from the turn holder's discard pile to the top of their deck
; input:
;	[hTemp_ffa0] = deck index of a card in the turn holder's discard pile (0-59, -1 if none)
Recycle_AddToHandEffect:
	ldh a, [hTemp_ffa0]
	cp -1
	ret z ; return if no card was selected
	call RemoveCardFromDiscardPile
	call ReturnCardToDeck

; show the selected card on the screen if this effect wasn't initiated by the Player
	call IsPlayerTurn
	ret c ; return if it's the Player's turn
	ldh a, [hTemp_ffa0]
	ldtx hl, CardWasChosenText
	bank1call DisplayCardDetailScreen
	ret


; ouput:
;	hl = ID for notification text
;	carry = set:  if there are no Basic Pokemon in the turn holder's discard pile or
;	              if there are already 5 Pokemon on the turn holder's Bench
ReviveCheck:
	call CreateBasicPokemonCardListFromDiscardPile
	ldtx hl, NoBasicPokemonInYourDiscardPileText
	ret c ; return if no Basic Pokemon in discard pile
	jp BenchSpaceCheck


; handles the Player's selection of a Basic Pokemon from their discard pile
; output:
;	carry = set:  if the operation was cancelled by the Player (with B button)
;	[hTemp_ffa0] = deck index of a Basic Pokémon card in the Player's discard pile (0-59)
Revive_PlayerSelection:
; create a list of Basic Pokemon from the discard pile
	ldtx hl, ChooseBasicPokemonToPlaceOnBenchText
	call DrawWideTextBox_WaitForInput
	call CreateBasicPokemonCardListFromDiscardPile
	bank1call InitAndDrawCardListScreenLayout_WithSelectCheckMenu

; display screen to select Pokemon
	ldtx hl, PleaseSelectCardText
	ldtx de, YourDiscardPileText
	call SetCardListHeaderText
	bank1call DisplayCardList
;	ret c ; exit if the B button was pressed
	ldh [hTemp_ffa0], a ; store selection
	ret


; puts a Pokemon from the turn holder's discard pile onto their Bench
; and sets its current HP to half its maximum HP (rounded up)
; input:
;	[hTemp_ffa0] = deck index of the chosen Pokemon in the turn holder's discard pile (0-59)
Revive_PlaceInPlayAreaEffect:
; place selected Pokemon onto the Bench
	ldh a, [hTemp_ffa0]
	call MoveCardFromDiscardPileToHand
	call PutHandPokemonCardInPlayArea

; set HP to half, rounded up
	add DUELVARS_ARENA_CARD_HP
	get_turn_duelist_var
	call HalfARoundedUp
	ld [hl], a
	call IsPlayerTurn
	ret c ; return if it's the Player's turn

; otherwise, show the selected Pokemon on the screen
	ldh a, [hTemp_ffa0]
	ldtx hl, PlacedOnTheBenchText
	bank1call DisplayCardDetailScreen
	ret


; handles the Player's selection of a Pokemon to remove from the play area
; and if it was the Active Pokemon, also handles selection of a Benched Pokemon
; output:
;	carry = set:  if the operation was cancelled by the Player (with B button)
;	[hTemp_ffa0] = play area location offset of the Pokemon to scoop up (PLAY_AREA_* constant)
;	[hTempPlayAreaLocation_ffa1] = play area location offset of a chosen Benched Pokemon:  if [hTemp_ffa0] = 0
ScoopUp_PlayerSelection:
; print text box
	ldtx hl, ChoosePokemonToScoopUpText
	call DrawWideTextBox_WaitForInput

; handle Player selection
	bank1call InitVarsAndOpenPlayAreaScreenForSelection
	ret c ; exit if the B button was pressed

	ldh [hTemp_ffa0], a
	or a
	ret nz ; return if target isn't the Active Pokemon

; handle switching to a Pokemon on the Bench and store the selected location
	call EmptyScreen
	ldtx hl, SelectNewActivePokemonText
	call DrawWideTextBox_WaitForInput
	bank1call InitVarsAndOpenPlayAreaScreenForSelection_OnlyBench
;	ret c ; exit if the B button was pressed
	ldh [hTempPlayAreaLocation_ffa1], a
	ret


; returns a Basic Pokemon from the turn holder's play area to their hand, discarding any attached cards
; input:
;	[hTemp_ffa0] = play area location offset of the Pokemon to scoop up (PLAY_AREA_* constant)
;	[hTempPlayAreaLocation_ffa1] = play area location offset of a chosen Benched Pokemon:  if [hTemp_ffa0] = 0
ScoopUp_ReturnToHandEffect:
; if card was in Bench, simply return Pokémon to hand
	ldh a, [hTemp_ffa0]
	or a
	jr nz, .scoop_up_effect ; not the Active Pokemon

; if the target was the Active Pokemon, then we need switch it
; with the chosen Benched Pokemon before applying the return to hand effect,
; because the Arena can't be empty when calling ShiftAllPokemonToFirstPlayAreaSlots
	ldh a, [hTempPlayAreaLocation_ffa1]
	ld e, a
	call SwapArenaWithBenchPokemon ; also clears status conditions
	ld a, e

.scoop_up_effect
; store chosen card location for Scoop Up
	ld e, a
	or CARD_LOCATION_PLAY_AREA
	ld d, a

; find any Basic Pokemon card that are in the selected play area location
; and add them to the hand, discarding all attached cards.
	ldh a, [hWhoseTurn]
	ld h, a
	ld l, DUELVARS_CARD_LOCATIONS + DECK_SIZE
.loop
	dec l ; go through deck indices in reverse order
	ld a, [hl]
	cp d
	jr nz, .next_card ; skip if not in the selected location
	ld a, l
	call CheckDeckIndexForBasicPokemon
	jr nc, .next_card ; skip if not a Basic Pokemon
; found
	ld a, l
	ldh [hTempCardIndex_ff98], a
	call AddCardToHand
.next_card
	ld a, l
	or a
	jr nz, .loop

; since the card has been moved to the hand, MovePlayAreaCardToDiscardPile will
; take care of discarding every higher stage card and any other attached cards.
	call MovePlayAreaCardToDiscardPile
	call ShiftAllPokemonToFirstPlayAreaSlots

; show the selected card on the screen if this effect wasn't initiated by the Player
	call IsPlayerTurn
	ret c ; return if it's the Player's turn
	ldtx hl, PokemonWasReturnedToHandText
	ldh a, [hTempCardIndex_ff98]
	bank1call DisplayCardDetailScreen
	ret


; output:
;	hl = ID for notification text
;	carry = set:  if none of the turn holder's Pokemon have any damage counters or
;	              if none of the turn holder's Pokemon have any attached Energy
SuperPotion_DamageEnergyCheck:
	call YourPokemon_DamageCheck
	ret c ; return if there is no damage to heal
	call YourPokemon_AttachedEnergyCheck
	ldtx hl, NoEnergyCardsAttachedToPokemonInYourPlayAreaText
	ret


; handles the Player's selection of a Pokemon in their play area with both
; damage counters and attached Energy, then sets the amount of damage to heal
; output:
;	carry = set:  if the operation was cancelled by the Player (with B button)
;	[hTemp_ffa0] = deck index of an Energy card attached to the target Pokémon (0-59)
;	[hTempPlayAreaLocation_ffa1] = target Pokémon's play area location offset (PLAY_AREA_* constant)
;	[hPlayAreaEffectTarget] = amount of HP to heal (up to 40)
SuperPotion_PlayerSelection:
	ldtx hl, ChoosePokemonToHealText
	call DrawWideTextBox_WaitForInput
.start
	call InitPlayAreaScreenVars
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
;	ld a, [wTotalAttachedEnergies] ; already loaded
	or a
	jr nz, .got_pkmn
	; no Energy cards attached to that Pokemon
	ldtx hl, NoEnergyCardsAttachedText
	call DrawWideTextBox_WaitForInput
	jr .start

.got_pkmn
; Pokemon has damage and Energy cards attached to it,
; so prompt the Player to select an Energy to discard.
	ldh a, [hCurMenuItem]
	call CreateArenaOrBenchEnergyCardList
	ldh a, [hCurMenuItem]
	bank1call DisplayEnergyDiscardScreen
	bank1call HandleEnergyDiscardMenuInput
	ret c ; exit if the B button was pressed
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


; input:
;	[hTemp_ffa0] = deck index of the (Energy) card that should be discarded (0-59)
;	[hTempPlayAreaLocation_ffa1] = target Pokémon's play area location offset (PLAY_AREA_* constant)
;	[hPlayAreaEffectTarget] = amount of HP to heal
SuperPotion_HealEffect:
	ldh a, [hTemp_ffa0]
	call PutCardInDiscardPile
	ldh a, [hTempPlayAreaLocation_ffa1]
	ldh [hTempPlayAreaLocation_ff9d], a
	ldh a, [hPlayAreaEffectTarget]
	jp HealPlayAreaCardHP


; output:
;	carry = set:  if the operation was cancelled by the Player (with B button)
;	[hTemp_ffa0] = play area location offset of the chosen Benched Pokemon (PLAY_AREA_* constant)
MrFuji_PlayerSelection:
	ldtx hl, ChoosePokemonToReturnToTheDeckText
	jr ChooseBenchedPokemon

; output:
;	carry = set:  if the operation was cancelled by the Player (with B button)
;	[hTemp_ffa0] = play area location offset of the chosen Benched Pokemon (PLAY_AREA_* constant)
Switch_PlayerSelection:
	ldtx hl, SelectNewActivePokemonText
;	fallthrough

; handles the Player's selection of a Benched Pokemon
; input:
;	hl = ID of the text containing the instructions
; output:
;	carry = set:  if the operation was cancelled by the Player (with B button)
;	[hTemp_ffa0] = play area location offset of the chosen Benched Pokemon (PLAY_AREA_* constant)
ChooseBenchedPokemon:
	call DrawWideTextBox_WaitForInput
	bank1call InitVarsAndOpenPlayAreaScreenForSelection_OnlyBench
;	ret c ; exit if the B button was pressed
	ldh [hTemp_ffa0], a
	ret


; switches a given Pokemon on the turn holder's Bench with their Active Pokemon
; preserves bc and hl
; input:
;	[hTemp_ffa0] = play area location offset of the chosen Benched Pokémon (PLAY_AREA_* constant)
SwitchEffect:
	ldh a, [hTemp_ffa0]
	ld e, a
	jp SwapArenaWithBenchPokemon


;----------------------------------------
;        UNREFERENCED FUNCTIONS
;----------------------------------------
;
; original AddToDamage function
; preserves all registers except af
; input:
;	a = amount to add to the damage
; output:
;	[wDamage] += a
;AddToDamage:
;	push hl
;	ld hl, wDamage
;	add [hl]
;	ld [hli], a
;	ld a, 0
;	adc [hl]
;	ld [hl], a
;	pop hl
;	ret
;
;
; original SubtractFromDamage function
; preserves all registers except af
; input:
;	a = amount to subtract from the damage
; output:
;	[wDamage] -= a
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
;
;
; preserves hl
;Serial_TossZeroCoins:
;	xor a
;	jr Serial_TossCoinATimes
;
; preserves hl
;Serial_TossCoin:
;	ld a, $1
;	; fallthrough
;
; input:
;	a = number of coin tosses
; output:
;	[wCoinTossTotalNum] = number of flipped coins
;	[wCoinTossNumHeads] = number of flipped heads
;Serial_TossCoinATimes:
;	push de
;	push af
;	ld a, OPPACTION_TOSS_COIN_A_TIMES
;	call SetOppAction_SerialSendDuelData
;	pop af
;	pop de
;	call SerialSend8Bytes
;	jp TossCoinATimes
;
;
; output:
;	a = $01
;Func_2c0a8:
;	ldh a, [hTemp_ffa0]
;	push af
;	ldh a, [hWhoseTurn]
;	ldh [hTemp_ffa0], a
;	ld a, OPPACTION_6B30
;	call SetOppAction_SerialSendDuelData
;	bank1call PlayDeckShuffleAnimation
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
;	get_turn_duelist_var
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
;	get_turn_duelist_var
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
;
;
; preserves bc and de
; output:
;	carry = set:  if Energy Burn cannot be used or
;	              if the Active Pokemon is not Charizard
;EnergyBurnCheck_Unreferenced:
;	call CheckIsIncapableOfUsingPkmnPower_ArenaCard
;	ret c ; can't use due to status or Toxic Gas
;	ld a, DUELVARS_ARENA_CARD
;	get_turn_duelist_var
;	call _GetCardIDFromDeckIndex
;	cp CHARIZARD
;	ret z ; nc
;	scf
;	ret
