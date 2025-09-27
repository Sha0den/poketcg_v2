;----------------------------------------------------------------------------------------------------
; DISCLAIMER:
;
; The functions found within this file cannot be used as effect commands.
; An effect command can only reference a function found within effect_functions.asm.
; However, it is possible for a function from effect_functions.asm
;	to "farcall" a function from effect_functions2.asm.
; Since effect_functions.asm and effect_functions2.asm are stored in separate memory banks,
;	neither "call" nor "jp" can be used to move from one to the other.
;	"Farcall" is the only option available for switching between functions in the two files.
;
; Most importantly, there is now a lot of free space in the main effect functions bank,
; 	so I would only recommend using this file to store larger, mostly self-contained functions,
;	like the search functions that have already been relocated.
; Depending on your knowledge of assembly programming and the scope of your project,
;	you might not need to use this file at all.
;
;----------------------------------------------------------------------------------------------------
; this file contains:
;	- effects that search the deck (e.g. Call for Family, Energy Search, etc.)
;	- effects that reorder the deck (Pokédex/Prophecy)
;	- Pokémon card data for Clefairy Doll and Mysterious Fossil
;----------------------------------------------------------------------------------------------------

; searches through the deck in wDuelTempList looking for certain cards,
; and prints text depending on whether at least one was found.
; if none were found, asks the Player whether to look in the deck anyway,
; and returns carry if No is selected.
; uses SEARCHEFFECT_* as input which determines what to search for:
;	SEARCHEFFECT_CARD_ID = search for card ID in e
;	SEARCHEFFECT_BASIC_ENERGY = search for any Basic Energy
;	SEARCHEFFECT_TRAINER = search for any Trainer card
;	SEARCHEFFECT_POKEMON = search for any Pokemon card
;	SEARCHEFFECT_EVOLUTION = search for any Evolution card (Stage1 or Stage2)
;	SEARCHEFFECT_BASIC_POKEMON = search for any Basic Pokemon card
;	SEARCHEFFECT_BASIC_FIGHTING = search for any Basic Fighting Pokemon
;	SEARCHEFFECT_NIDORAN = search for either NidoranM or NidoranF
; input:
;	d = SEARCHEFFECT_* constant
;	e = (optional) card ID to search for in deck (e = 0 if not using SEARCHEFFECT_CARD_ID)
;	hl = ID of the text to print if the deck has the card(s)
;	bc = ID of the text to store in RAM for ThereIsNoInTheDeckText 
; output:
;	carry = set:  if no cards were found and the player refused to check the deck
LookForCardsInDeck:
	push hl
	push bc
	ld a, [wDuelTempList]
	cp $ff
	jr z, .none_in_deck
	ld a, d
	ld hl, .search_table
	call JumpToFunctionInTable
	jr c, .none_in_deck
	pop bc
	pop hl
	jp DrawWideTextBox_WaitForInput

.none_in_deck
	pop hl
	call LoadTxRam2
	pop hl
	ldtx hl, ThereIsNoInTheDeckText
	call DrawWideTextBox_WaitForInput
	ldtx hl, WouldYouLikeToCheckTheDeckText
	jp YesOrNoMenuWithText_SetCursorToYes

.search_table
	dw .SearchDeckForCardID
	dw .SearchDeckForBasicEnergy
	dw .SearchDeckForTrainer
	dw .SearchDeckForPokemon
	dw .SearchDeckForEvolution
	dw .SearchDeckForBasicPokemon
	dw .SearchDeckForBasicFighting
	dw .SearchDeckForNidoran

.set_carry
	scf
	ret

; input:
;	e = card ID to check
; output:
;	carry = set:  if no cards with the ID from input were found in the player's deck
.SearchDeckForCardID
	ld hl, wDuelTempList
.loop_deck_e
	ld a, [hli]
	cp $ff
	jr z, .set_carry
	call _GetCardIDFromDeckIndex
	cp e
	jr nz, .loop_deck_e ; skip if wrong card ID
	or a
	ret

; output:
;	carry = set:  if no Basic Energy cards were found in the player's deck
.SearchDeckForBasicEnergy
	ld hl, wDuelTempList
.loop_deck_energy
	ld a, [hli]
	cp $ff
	jr z, .set_carry
	call CheckDeckIndexForBasicEnergy
	jr nc, .loop_deck_energy ; skip if not a Basic Energy
	or a
	ret

; output:
;	carry = set:  if no Trainer cards were found in the player's deck
.SearchDeckForTrainer
	ld hl, wDuelTempList
.loop_deck_trainer
	ld a, [hli]
	cp $ff
	jr z, .set_carry
	call GetCardIDFromDeckIndex
	call GetCardType
	cp TYPE_TRAINER
	jr nz, .loop_deck_trainer ; skip if not a Trainer
	or a
	ret

; output:
;	carry = set:  if no Pokemon were found in the player's deck
.SearchDeckForPokemon
	ld hl, wDuelTempList
.loop_deck_pkmn
	ld a, [hli]
	cp $ff
	jr z, .set_carry
	call GetCardIDFromDeckIndex
	call GetCardType
	cp TYPE_ENERGY
	jr nc, .loop_deck_pkmn ; skip if not a Pokemon
	or a
	ret

; output:
;	carry = set:  if no Evolution cards were found in the player's deck
.SearchDeckForEvolution
	ld hl, wDuelTempList
.loop_deck_evolution
	ld a, [hli]
	cp $ff
	jr z, .set_carry
	call CheckDeckIndexForStage1OrStage2Pokemon
	jr nc, .loop_deck_evolution ; skip if not a Stage 1/2 Pokemon
	or a
	ret

; output:
;	carry = set:  if no Basic Pokemon cards were found in the player's deck
.SearchDeckForBasicPokemon
	ld hl, wDuelTempList
.loop_deck_bscpkmn
	ld a, [hli]
	cp $ff
	jr z, .set_carry
	call CheckDeckIndexForBasicPokemon
	jr nc, .loop_deck_bscpkmn ; skip if not a Basic Pokemon
	or a
	ret

; output:
;	carry = set:  if no Basic Fighting Pokemon cards were found in the player's deck
.SearchDeckForBasicFighting
	ld hl, wDuelTempList
.loop_deck_fighting
	ld a, [hli]
	cp $ff
	jr z, .set_carry
	call LoadCardDataToBuffer2_FromDeckIndex
	ld a, [wLoadedCard2Type]
	cp TYPE_PKMN_FIGHTING
	jr nz, .loop_deck_fighting ; skip if type isn't Fighting
	ld a, [wLoadedCard2Stage]
	or a
	jr nz, .loop_deck_fighting ; skip if stage isn't Basic
	ret

; output:
;	carry = set:  if no NidoranM or NidoranF cards were found in the player's deck
.SearchDeckForNidoran
	ld hl, wDuelTempList
.loop_deck_nidoran
	ld a, [hli]
	cp $ff
	jp z, .set_carry
	call _GetCardIDFromDeckIndex
	cp NIDORANF
	ret z ; return no carry if a Nidoran F was found
	cp NIDORANM
	jr nz, .loop_deck_nidoran ; skip if not a Nidoran
	ret ; return no carry if a Nidoran M was found


; prompts the Player to choose a Basic Energy card from their deck
; output:
;	[hTemp_ffa0] = deck index of a Basic Energy card in the turn holder's deck (0-59, -1 if none)
FindBasicEnergy:
	call CreateDeckCardList
	ldtx hl, Choose1BasicEnergyCardFromDeckText
	ldtx bc, BasicEnergyCardText
	lb de, SEARCHEFFECT_BASIC_ENERGY, 0
	call LookForCardsInDeck
	jr c, .exit ; no Basic Energy cards in the deck

; draw deck list interface and print text
	bank1call InitAndDrawCardListScreenLayout_WithSelectCheckMenu
	ldtx hl, ChooseBasicEnergyCardText
	ldtx de, DuelistDeckText
	call SetCardListHeaderText

.read_input
	bank1call DisplayCardList
	jr c, .attempt_to_cancel ; the B button was pressed
	call CheckDeckIndexForBasicEnergy
	jr nc, .play_sfx ; not a Basic Energy card

; a Basic Energy card was selected
	ldh a, [hTempCardIndex_ff98]
	ldh [hTemp_ffa0], a
	or a
	ret

; see if the Player can exit the screen without selecting a card,
; that is, if the deck contains no Basic Energy cards.
.attempt_to_cancel
	ld hl, wDuelTempList
.next_card
	ld a, [hli]
	cp $ff
	jr z, .exit
	call CheckDeckIndexForBasicEnergy
	jr nc, .next_card
	; found a Basic Energy card, so play SFX and return to selection process
.play_sfx
	call PlaySFX_InvalidChoice
	jr .read_input

; no Basic Energy in the deck, can safely exit screen
.exit
	ld a, -1
	ldh [hTemp_ffa0], a
	or a
	ret


; uses a card's deck index to check whether or not it is a Basic Energy card
; preserves all registers except af
; input:
;	a = deck index (0-59) of the card being checked
; output:
;	carry = set:  if the card is a Basic Energy card
CheckDeckIndexForBasicEnergy:
	call GetCardTypeFromDeckIndex_SaveDE
	cp TYPE_ENERGY
	ccf
	ret nc ; return no carry if it's a Pokémon card
	cp TYPE_ENERGY + NUM_COLORED_TYPES
	ret ; c if Basic Energy, nc if Trainer/Special Energy


; prompts the Player to choose a Basic Energy card from their deck,
; then prompts the Player to choose a Pokémon from their play area to attach it to.
; output:
;	[hTemp_ffa0] = deck index of a Basic Energy card in the turn holder's deck (0-59, -1 if none)
;	[hTempPlayAreaLocation_ffa1] = target Pokémon's play area location offset (PLAY_AREA_* constant)
FindBasicEnergyToAttach:
	call CreateDeckCardList
	ldtx hl, Choose1BasicEnergyCardFromDeckText
	ldtx bc, BasicEnergyCardText
	lb de, SEARCHEFFECT_BASIC_ENERGY, 0
	call LookForCardsInDeck
	jr c, .exit ; no Basic Energy cards in the deck

; draw deck list interface and print text
	bank1call InitAndDrawCardListScreenLayout_WithSelectCheckMenu
	ldtx hl, ChooseBasicEnergyCardText
	ldtx de, DuelistDeckText
	call SetCardListHeaderText

.read_input
	bank1call DisplayCardList
	jr c, .attempt_to_cancel ; the B button was pressed
	call CheckDeckIndexForBasicEnergy
	jr nc, .play_sfx ; not a Basic Energy card

; a Basic Energy card was selected
	ldh a, [hTempCardIndex_ff98]
	ldh [hTemp_ffa0], a

; now to choose an in-play Pokemon to attach it to
	call EmptyScreen
	ldtx hl, ChoosePokemonToAttachEnergyCardText
	call DrawWideTextBox_WaitForInput
	call InitPlayAreaScreenVars
.loop_input
	bank1call OpenPlayAreaScreenForSelection
	jr c, .loop_input ; must choose, B button can't be used to exit
	ldh [hTempPlayAreaLocation_ffa1], a
	ret

; see if the Player can exit the screen without selecting a card,
; that is, if the deck contains no Basic Energy cards.
.attempt_to_cancel
	ld hl, wDuelTempList
.next_card
	ld a, [hli]
	cp $ff
	jr z, .exit
	call CheckDeckIndexForBasicEnergy
	jr nc, .next_card
	; found a Basic Energy card, so play SFX and return to selection process
.play_sfx
	call PlaySFX_InvalidChoice
	jr .read_input

; no Basic Energy in the deck, can safely exit screen
.exit
	ld a, -1
	ldh [hTemp_ffa0], a
	or a
	ret


; finds the first Basic Energy card in the deck and attaches it to the AI's Active Pokemon.
; output:
;	[hTemp_ffa0] = deck index of a Basic Energy card in the AI's deck (0-59, -1 if none)
;	[hTempPlayAreaLocation_ffa1] = target Pokémon's play area location offset (PLAY_AREA_* constant)
AIFindBasicEnergyToAttach:
	call CreateDeckCardList
	ld hl, wDuelTempList
.loop_deck
	ld a, [hli]
	ldh [hTemp_ffa0], a
	cp $ff
	ret z ; reached the end of the list
	call CheckDeckIndexForBasicEnergy
	jr nc, .loop_deck ; card isn't a Basic Energy
	xor a ; PLAY_AREA_ARENA
	ldh [hTempPlayAreaLocation_ffa1], a
	ret


; prompts the Player to choose a Trainer card from their deck
; output:
;	[hTemp_ffa0] = deck index of a Trainer card in the turn holder's deck (0-59, -1 if none)
FindTrainer:
	call CreateDeckCardList
	ldtx hl, ChooseTrainerCardFromDeckText
	ldtx bc, TrainerCardText
	lb de, SEARCHEFFECT_TRAINER, 0
	call LookForCardsInDeck
	jr c, .exit ; no Trainer cards in the deck

; draw deck list interface and print text
	bank1call InitAndDrawCardListScreenLayout_WithSelectCheckMenu
	ldtx hl, ChooseTrainerCardText
	ldtx de, DuelistDeckText
	call SetCardListHeaderText

.read_input
	bank1call DisplayCardList
	jr c, .attempt_to_cancel ; the B button was pressed
	call GetCardIDFromDeckIndex
	call GetCardType
	cp TYPE_TRAINER
	jr nz, .play_sfx ; not a Trainer card

; a Trainer card was selected
	ldh a, [hTempCardIndex_ff98]
	ldh [hTemp_ffa0], a
	or a
	ret

; see if the Player can exit the screen without selecting a card,
; that is, if the deck contains no Trainer cards.
.attempt_to_cancel
	ld hl, wDuelTempList
.next_card
	ld a, [hli]
	cp $ff
	jr z, .exit
	call GetCardIDFromDeckIndex
	call GetCardType
	cp TYPE_TRAINER
	jr nz, .next_card
	; found a Trainer card, so play SFX and return to selection process
.play_sfx
	call PlaySFX_InvalidChoice
	jr .read_input

; no Trainer cards in the deck, can safely exit screen
.exit
	ld a, -1
	ldh [hTemp_ffa0], a
	or a
	ret


; finds the first Trainer card in the deck
; output:
;	[hTemp_ffa0] = deck index of a Trainer card in the turn holder's deck (0-59, -1 if none)
AIFindTrainer:
	call CreateDeckCardList
	ld hl, wDuelTempList
.loop_deck
	ld a, [hli]
	ldh [hTemp_ffa0], a
	cp $ff
	ret z ; reached the end of the list
	call GetCardIDFromDeckIndex
	call GetCardType
	cp TYPE_TRAINER
	jr nz, .loop_deck ; card isn't a Trainer card
	ret ; Trainer card found


; prompts the Player to choose a Pokémon card from their deck
; output:
;	[hTemp_ffa0] = deck index of a Pokémon in the turn holder's deck (0-59, -1 if none)
FindAnyPokemon:
	call CreateDeckCardList
	ldtx hl, ChoosePokemonFromDeckText
	ldtx bc, PokemonName
	lb de, SEARCHEFFECT_POKEMON, 0
	call LookForCardsInDeck
	jr c, .exit ; no Pokemon in the deck

; draw deck list interface and print text
	bank1call InitAndDrawCardListScreenLayout_WithSelectCheckMenu
	ldtx hl, ChoosePokemonCardText
	ldtx de, DuelistDeckText
	call SetCardListHeaderText

.read_input
	bank1call DisplayCardList
	jr c, .attempt_to_cancel ; the B button was pressed
	call GetCardIDFromDeckIndex
	call GetCardType
	cp TYPE_ENERGY
	jr nc, .play_sfx ; not a Pokemon

; a Pokemon was selected
	ldh a, [hTempCardIndex_ff98]
	ldh [hTemp_ffa0], a
	or a
	ret

; see if the Player can exit the screen without selecting a card,
; that is, if the deck contains no Pokemon.
.attempt_to_cancel
	ld hl, wDuelTempList
.next_card
	ld a, [hli]
	cp $ff
	jr z, .exit
	call GetCardIDFromDeckIndex
	call GetCardType
	cp TYPE_ENERGY
	jr nc, .next_card
	; found a Pokemon, so play SFX and return to selection process
.play_sfx
	call PlaySFX_InvalidChoice
	jr .read_input

; no Pokemon in the deck, can safely exit screen
.exit
	ld a, -1
	ldh [hTemp_ffa0], a
	or a
	ret


; prompts the Player to choose an Evolution card from their deck
; output:
;	[hTemp_ffa0] = deck index of an Evolution card in the turn holder's deck (0-59, -1 if none)
FindEvolution:
	call CreateDeckCardList
	ldtx hl, ChooseEvolutionCardFromDeckText
	ldtx bc, EvolutionCardText
	lb de, SEARCHEFFECT_EVOLUTION, 0
	call LookForCardsInDeck
	jr c, .exit ; no Evolution cards in the deck

; draw deck list interface and print text
	bank1call InitAndDrawCardListScreenLayout_WithSelectCheckMenu
	ldtx hl, ChooseEvolutionCardText
	ldtx de, DuelistDeckText
	call SetCardListHeaderText

.read_input
	bank1call DisplayCardList
	jr c, .attempt_to_cancel ; the B button was pressed
	call CheckDeckIndexForStage1OrStage2Pokemon
	jr nc, .play_sfx ; not an Evolution card

; an Evolution card was selected
	ldh a, [hTempCardIndex_ff98]
	ldh [hTemp_ffa0], a
	or a
	ret

; see if the Player can exit the screen without selecting a card,
; that is, if the deck contains no Evolution cards.
.attempt_to_cancel
	ld hl, wDuelTempList
.next_card
	ld a, [hli]
	cp $ff
	jr z, .exit
	call CheckDeckIndexForStage1OrStage2Pokemon
	jr nc, .next_card
	; found an Evolution card, so play SFX and return to selection process
.play_sfx
	call PlaySFX_InvalidChoice
	jr .read_input

; no Evolution cards in the deck, can safely exit screen
.exit
	ld a, -1
	ldh [hTemp_ffa0], a
	or a
	ret


; uses a card's deck index to check whether or not it is an Evolution card
; preserves all registers except af
; input:
;	a = deck index (0-59) of the card being checked
; output:
;	carry = set:  if the card is an Evolution card
CheckDeckIndexForStage1OrStage2Pokemon:
	call LoadCardDataToBuffer2_FromDeckIndex
	ld a, [wLoadedCard2Type]
	cp TYPE_ENERGY
	ret nc ; not a Pokemon
	ld a, [wLoadedCard2Stage]
	or a
	ret z ; is Basic
	; is an evolution
	scf
	ret


; searches the deck for an Evolution card that evolves from the Active Pokémon.
; if that fails, find the first Evolution card in the deck.
; output:
;	[hTemp_ffa0] = deck index of an Evolution card in the turn holder's deck (0-59, -1 if none)
AIFindEvolution:
	lb de, DECK_SIZE, PLAY_AREA_ARENA
.loop_all_cards
	dec d ; go through deck indices in reverse order
	ld a, d ; DUELVARS_CARD_LOCATIONS + current deck index
	get_turn_duelist_var
	cp CARD_LOCATION_DECK
	jr nz, .next_card ; skip if not in the deck
	ld a, d
	call CheckDeckIndexForStage1OrStage2Pokemon
	jr nc, .next_card ; skip if not an Evolution card
	call CheckIfCanEvolveInto
	jr nc, .found_active_pkmn_evolution
.next_card
	ld a, d
	or a
	jr nz, .loop_all_cards

; no Evolution card in the deck evolves from the Active Pokémon,
; so just return with the first evolution Evolution card.
	call CreateDeckCardList
	ld hl, wDuelTempList
.loop_deck
	ld a, [hli]
	ldh [hTemp_ffa0], a
	cp $ff
	ret z ; reached the end of the list
	call CheckDeckIndexForStage1OrStage2Pokemon
	jr nc, .loop_deck ; card isn't an Evolution card
	ret ; Evolution card found

.found_active_pkmn_evolution
	ld a, d
	ldh [hTemp_ffa0], a
	ret


; prompts the Player to choose a Basic Pokémon card from their deck
; output:
;	[hTemp_ffa0] = deck index of a Basic Pokémon in the turn holder's deck (0-59, -1 if none)
FindBasicPokemon:
	call CreateDeckCardList
	ldtx hl, ChooseBasicPokemonFromDeckText
	ldtx bc, BasicPokemonText
	lb de, SEARCHEFFECT_BASIC_POKEMON, $00
	call LookForCardsInDeck
	jr c, .exit ; no Basic Pokemon in the deck

; draw deck list interface and print text
	bank1call InitAndDrawCardListScreenLayout_WithSelectCheckMenu
	ldtx hl, ChooseBasicPokemonText
	ldtx de, DuelistDeckText
	call SetCardListHeaderText

.read_input
	bank1call DisplayCardList
	jr c, .attempt_to_cancel ; the B button was pressed
	call CheckDeckIndexForBasicPokemon
	jr nc, .play_sfx ; not a Basic Pokemon

; a Basic Pokemon was selected
	ldh a, [hTempCardIndex_ff98]
	ldh [hTemp_ffa0], a
	or a
	ret

; see if the Player can exit the screen without selecting a card,
; that is, if the deck contains no Basic Pokemon.
.attempt_to_cancel
	ld hl, wDuelTempList
.next_card
	ld a, [hli]
	cp $ff
	jr z, .exit
	call CheckDeckIndexForBasicPokemon
	jr nc, .next_card
	; found a Basic Pokemon, so play SFX and return to selection process
.play_sfx
	call PlaySFX_InvalidChoice
	jr .read_input

; no Basic Pokemon in the deck, can safely exit screen
.exit
	ld a, -1
	ldh [hTemp_ffa0], a
	or a
	ret


; finds the first Basic Pokémon card in the turn holder's deck
; output:
;	[hTemp_ffa0] = deck index of a Basic Pokémon in the turn holder's deck (0-59, -1 if none)
AIFindBasicPokemon:
	call CreateDeckCardList
	ld hl, wDuelTempList
.loop_deck
	ld a, [hli]
	ldh [hTemp_ffa0], a
	cp $ff
	ret z ; reached the end of the list
	call CheckDeckIndexForBasicPokemon
	jr nc, .loop_deck ; card isn't a Basic Pokemon
	ret ; Basic Pokemon found


; prompts the Player to choose a Basic Fighting Pokémon card from their deck
; output:
;	[hTemp_ffa0] = deck index of a Basic Fighting Pokémon in the turn holder's deck (0-59, -1 if none)
FindBasicFightingPokemon:
	call CreateDeckCardList
	ldtx hl, ChooseBasicFightingPokemonFromDeckText
	ldtx bc, BasicFightingPokemonText
	lb de, SEARCHEFFECT_BASIC_FIGHTING, $00
	call LookForCardsInDeck
	jr c, .exit ; no Basic Fighting Pokemon in the deck

; draw deck list interface and print text
	bank1call InitAndDrawCardListScreenLayout_WithSelectCheckMenu
	ldtx hl, ChooseBasicFightingPokemonText
	ldtx de, DuelistDeckText
	call SetCardListHeaderText

.read_input
	bank1call DisplayCardList
	jr c, .attempt_to_cancel ; the B button was pressed
	call LoadCardDataToBuffer2_FromDeckIndex
	ld a, [wLoadedCard2Type]
	cp FIGHTING
	jr nz, .play_sfx ; not a Fighting Pokemon
	ld a, [wLoadedCard2Stage]
	or a
	jr nz, .play_sfx ; not a Basic Pokemon

; a Basic Fighting Pokemon was selected
	ldh a, [hTempCardIndex_ff98]
	ldh [hTemp_ffa0], a
	or a
	ret

; see if the Player can exit the screen without selecting a card,
; that is, if the deck contains no Basic Fighting Pokemon.
.attempt_to_cancel
	ld hl, wDuelTempList
.next_card
	ld a, [hli]
	cp $ff
	jr z, .exit
	call LoadCardDataToBuffer2_FromDeckIndex
	ld a, [wLoadedCard2Type]
	cp FIGHTING
	jr nz, .next_card ; not a Fighting Pokemon, move on to the next card
	ld a, [wLoadedCard2Stage]
	or a
	jr nz, .next_card
	; found a Basic Fighting Pokemon, so play SFX and return to selection process
.play_sfx
	call PlaySFX_InvalidChoice
	jr .read_input

; no Basic Fighting Pokemon in the deck, can safely exit screen
.exit
	ld a, -1
	ldh [hTemp_ffa0], a
	or a
	ret


; finds the first Basic Fighting Pokémon card in the turn holder's deck
; output:
;	[hTemp_ffa0] = deck index of a Basic Fighting Pokémon in the turn holder's deck (0-59, -1 if none)
AIFindBasicFighting:
	call CreateDeckCardList
	ld hl, wDuelTempList
.loop_deck
	ld a, [hli]
	ldh [hTemp_ffa0], a
	cp $ff
	ret z ; reached the end of the list
	call LoadCardDataToBuffer2_FromDeckIndex
	ld a, [wLoadedCard2Type]
	cp FIGHTING
	jr nz, .loop_deck ; card isn't a Fighting Pokemon
	ld a, [wLoadedCard2Stage]
	or a
	jr nz, .loop_deck ; card isn't a Basic Pokemon
	ret ; Fighting Pokemon found


; prompts the Player to choose a Nidoran F or a Nidoran M card from their deck
; output:
;	[hTemp_ffa0] = deck index of a Nidoran in the turn holder's deck (0-59, -1 if none)
FindNidoran:
	call CreateDeckCardList
	ldtx hl, ChooseNidoranFromDeckText
	ldtx bc, NidoranMNidoranFText
	lb de, SEARCHEFFECT_NIDORAN, $00
	call LookForCardsInDeck
	jr c, .exit ; no Nidoran in the deck

; draw deck list interface and print text
	bank1call InitAndDrawCardListScreenLayout_WithSelectCheckMenu
	ldtx hl, ChooseNidoranText
	ldtx de, DuelistDeckText
	call SetCardListHeaderText

.read_input
	bank1call DisplayCardList
	jr c, .attempt_to_cancel ; the B button was pressed
	call GetCardIDFromDeckIndex
	ld bc, NIDORANF
	call CompareDEtoBC
	jr z, .selected_nidoran
	ld bc, NIDORANM
	call CompareDEtoBC
	jr nz, .play_sfx ; not a Nidoran

.selected_nidoran
	ldh a, [hTempCardIndex_ff98]
	ldh [hTemp_ffa0], a
	or a
	ret

; see if the Player can exit the screen without selecting a card,
; that is, if the deck contains no NidoranF or NidoranM cards.
.attempt_to_cancel
	ld hl, wDuelTempList
.next_card
	ld a, [hli]
	cp $ff
	jr z, .exit
	call GetCardIDFromDeckIndex
	ld bc, NIDORANF
	call CompareDEtoBC
	jr z, .play_sfx ; found a Nidoran, return to selection process
	ld bc, NIDORANM
	jr nz, .next_card
	; found a Nidoran, so play SFX and return to selection process
.play_sfx
	call PlaySFX_InvalidChoice
	jr .read_input

; no Nidoran in the deck, can safely exit screen
.exit
	ld a, -1
	ldh [hTemp_ffa0], a
	or a
	ret


; finds the first Nidoran F/M card in the turn holder's deck
; output:
;	[hTemp_ffa0] = deck index of a Nidoran in the turn holder's deck (0-59, -1 if none)
AIFindNidoran:
	call CreateDeckCardList
	ld hl, wDuelTempList
.loop_deck
	ld a, [hli]
	ldh [hTemp_ffa0], a
	cp $ff
	ret z ; reached the end of the list
	call _GetCardIDFromDeckIndex
	cp NIDORANF
	ret z ; Nidoran found
	cp NIDORANM
	jr nz, .loop_deck ; card isn't a Nidoran
	ret ; Nidoran found


; prompts the Player to choose an Oddish card from their deck
; output:
;	[hTemp_ffa0] = deck index of an Oddish in the turn holder's deck (0-59, -1 if none)
FindOddish:
	call CreateDeckCardList
	ldtx hl, ChooseAnOddishFromDeckText
	ldtx bc, OddishName
	lb de, SEARCHEFFECT_CARD_ID, ODDISH
	call LookForCardsInDeck
	jr c, .exit ; no Oddish in the deck

; draw deck list interface and print text
	bank1call InitAndDrawCardListScreenLayout_WithSelectCheckMenu
	ldtx hl, ChooseAnOddishText
	ldtx de, DuelistDeckText
	call SetCardListHeaderText

.read_input
	bank1call DisplayCardList
	jr c, .attempt_to_cancel ; the B button was pressed
	call GetCardIDFromDeckIndex
	ld bc, ODDISH
	call CompareDEtoBC
	jr nz, .play_sfx ; not an Oddish

; an Oddish was selected
	ldh a, [hTempCardIndex_ff98]
	ldh [hTemp_ffa0], a
	or a
	ret

; see if the Player can exit the screen without selecting a card,
; that is, if the deck contains no Oddish cards.
.attempt_to_cancel
	ld hl, wDuelTempList
.next_card
	ld a, [hli]
	cp $ff
	jr z, .exit
	call GetCardIDFromDeckIndex
	ld bc, ODDISH
	call CompareDEtoBC
	jr nz, .next_card
	; found an Oddish, so play SFX and return to selection process
.play_sfx
	call PlaySFX_InvalidChoice
	jr .read_input


; no Oddish in the deck, can safely exit screen
.exit
	ld a, -1
	ldh [hTemp_ffa0], a
	or a
	ret


; finds the first Oddish card in the turn holder's deck
; output:
;	[hTemp_ffa0] = deck index of an Oddish in the turn holder's deck (0-59, -1 if none)
AIFindOddish:
	call CreateDeckCardList
	ld hl, wDuelTempList
.loop_deck
	ld a, [hli]
	ldh [hTemp_ffa0], a
	cp $ff
	ret z ; reached the end of the list
	call _GetCardIDFromDeckIndex
	cp ODDISH
	jr nz, .loop_deck ; card isn't an Oddish
	ret ; Oddish found


; prompts the Player to choose a Bellsprout card from their deck
; output:
;	[hTemp_ffa0] = deck index of a Bellsprout in the turn holder's deck (0-59, -1 if none)
FindBellsprout:
	call CreateDeckCardList
	ldtx hl, ChooseABellsproutFromDeckText
	ldtx bc, BellsproutName
	lb de, SEARCHEFFECT_CARD_ID, BELLSPROUT
	call LookForCardsInDeck
	jr c, .exit ; no Bellsprout in the Deck

; draw deck list interface and print text
	bank1call InitAndDrawCardListScreenLayout_WithSelectCheckMenu
	ldtx hl, ChooseABellsproutText
	ldtx de, DuelistDeckText
	call SetCardListHeaderText

.read_input
	bank1call DisplayCardList
	jr c, .attempt_to_cancel ; the B button was pressed
	call GetCardIDFromDeckIndex
	ld bc, BELLSPROUT
	call CompareDEtoBC
	jr nz, .play_sfx ; not a Bellsprout

; a Bellsprout was selected
	ldh a, [hTempCardIndex_ff98]
	ldh [hTemp_ffa0], a
	or a
	ret

; see if the Player can exit the screen without selecting a card,
; that is, if the deck contains no Bellsprout cards.
.attempt_to_cancel
	ld hl, wDuelTempList
.next_card
	ld a, [hli]
	cp $ff
	jr z, .exit
	call GetCardIDFromDeckIndex
	ld bc, BELLSPROUT
	call CompareDEtoBC
	jr nz, .next_card
	; found a Bellsprout, so play SFX and return to selection process
.play_sfx
	call PlaySFX_InvalidChoice
	jr .read_input

; no Bellsprout in the deck, can safely exit screen
.exit
	ld a, -1
	ldh [hTemp_ffa0], a
	or a
	ret


; finds the first Bellsprout card in the turn holder's deck
; output:
;	[hTemp_ffa0] = deck index of a Bellsprout in the turn holder's deck (0-59, -1 if none)
AIFindBellsprout:
	call CreateDeckCardList
	ld hl, wDuelTempList
.loop_deck
	ld a, [hli]
	ldh [hTemp_ffa0], a
	cp $ff
	ret z ; reached the end of the list
	call _GetCardIDFromDeckIndex
	cp BELLSPROUT
	jr nz, .loop_deck ; card isn't a Bellsprout
	ret ; Bellsprout found


; prompts the Player to choose a Krabby card from their deck
; output:
;	[hTemp_ffa0] = deck index of a Krabby in the turn holder's deck (0-59, -1 if none)
FindKrabby:
	call CreateDeckCardList
	ldtx hl, ChooseAKrabbyFromDeckText
	ldtx bc, KrabbyName
	lb de, SEARCHEFFECT_CARD_ID, KRABBY
	call LookForCardsInDeck
	jr c, .exit ; no Krabby in the deck

; draw deck list interface and print text
	bank1call InitAndDrawCardListScreenLayout_WithSelectCheckMenu
	ldtx hl, ChooseAKrabbyText
	ldtx de, DuelistDeckText
	call SetCardListHeaderText

.read_input
	bank1call DisplayCardList
	jr c, .attempt_to_cancel ; the B button was pressed
	call GetCardIDFromDeckIndex
	ld bc, KRABBY
	call CompareDEtoBC
	jr nz, .play_sfx ; not a Krabby

; a Krabby was selected
	ldh a, [hTempCardIndex_ff98]
	ldh [hTemp_ffa0], a
	or a
	ret

; see if the Player can exit the screen without selecting a card,
; that is, if the deck contains Krabby cards.
.attempt_to_cancel
	ld hl, wDuelTempList
.next_card
	ld a, [hli]
	cp $ff
	jr z, .exit
	call GetCardIDFromDeckIndex
	ld bc, KRABBY
	call CompareDEtoBC
	jr nz, .next_card
	; found a Krabby, so play SFX and return to selection process
.play_sfx
	call PlaySFX_InvalidChoice
	jr .read_input

; no Krabby in the deck, can safely exit screen
.exit
	ld a, -1
	ldh [hTemp_ffa0], a
	or a
	ret


; finds the first Krabby card in the turn holder's deck
; output:
;	[hTemp_ffa0] = deck index of a Krabby in the turn holder's deck (0-59, -1 if none)
AIFindKrabby:
	call CreateDeckCardList
	ld hl, wDuelTempList
.loop_deck
	ld a, [hli]
	ldh [hTemp_ffa0], a
	cp $ff
	ret z ; reached the end of the list
	call _GetCardIDFromDeckIndex
	cp KRABBY
	jr nz, .loop_deck ; card isn't a Krabby
	ret ; Krabby found




; handles the Player's selection for reordering the top 5 cards of their deck
; output:
;	hTempList + 1 = $ff-terminated list with deck indices of cards to place on top of the deck
HandlePokedexPlayerSelection:
; print text box
	ldtx hl, RearrangeThe5CardsAtTopOfDeckText
	call DrawWideTextBox_WaitForInput
	ld c, 5 ; number of cards that will be reordered
	jr ReorderCardsOnTopOfDeck


; output:
;	[hTempList] = which deck was chosen (0 = turn holder's deck, 1 = opponent's deck)
;	hTempList + 1 = $ff-terminated list with deck indices of cards to place on top of the deck
HandleProphecyPlayerSelection:
	ldtx hl, ProcedureForProphecyText
	call DrawWholeScreenTextBox
.select_deck
	bank1call DrawDuelMainScene
	ldtx hl, PleaseSelectTheDeckText
	call TwoItemHorizontalMenu
	ldh a, [hKeysHeld]
	and PAD_B
	jr nz, HandleProphecyPlayerSelection ; loop back to start

	ldh a, [hCurMenuItem]
	ldh [hTempList], a ; store selection in first position in list
	or a
	jr z, .turn_duelist

; non-turn duelist
	ld a, DUELVARS_NUMBER_OF_CARDS_NOT_IN_DECK
	call GetNonTurnDuelistVariable
	cp DECK_SIZE
	jr nc, .select_deck ; no cards, go back to deck selection
	rst SwapTurn
	call HandleProphecyScreen
	jp SwapTurn

.turn_duelist
	ld a, DUELVARS_NUMBER_OF_CARDS_NOT_IN_DECK
	get_turn_duelist_var
	cp DECK_SIZE
	jr nc, .select_deck ; no cards, go back to deck selection
;	fallthrough

; draws and handles the Player's selection for reordering the top 3 cards of the deck.
; the resulting list is output in order in hTempList.
; output:
;	hTempList + 1 = $ff-terminated list with deck indices of cards to place on top of the deck
HandleProphecyScreen:
	ld c, 3 ; number of cards that will be reordered
;	fallthrough

; input:
;	c = number of cards to reorder
ReorderCardsOnTopOfDeck:
; cap the number of cards to reorder up to the number of cards in deck.
	ld a, DUELVARS_NUMBER_OF_CARDS_NOT_IN_DECK
	get_turn_duelist_var
	ld b, a
	ld a, DECK_SIZE
	sub [hl] ; a = number of cards in deck
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
	call PrintSortNumberInCardList_SetPointer

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
	ld hl, wPrintSortNumberInCardListPtr
	call CallIndirect

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
.loop_order
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
	jr .loop_order

; now hTempList has the list of card deck indices
; in the order selected to be place on top of the deck.
.done
	ld b, $00
	ld hl, hTempList + 1
	add hl, bc
	ld [hl], $ff ; terminating byte
	or a
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
	ld hl, wPrintSortNumberInCardListPtr
	call CallIndirect
	jr .loop_selection


; preserves bc and de
; output:
;	[wPrintSortNumberInCardListPtr] = pointer for PrintSortNumberInCardList function
;	[wSortCardListByID] = 1
PrintSortNumberInCardList_SetPointer:
	ld hl, wPrintSortNumberInCardListPtr
	ld a, LOW(PrintSortNumberInCardList)
	ld [hli], a
	ld [hl], HIGH(PrintSortNumberInCardList)
	ld a, TRUE
	ld [wSortCardListByID], a
	ret


; goes through the list at wDuelTempList + 10
; and prints the number stored in each entry
; beside the corresponding card in screen.
; used in lists for reordering cards in the deck.
; preserves de
; input:
;	wDuelTempList + 10 = $ff terminated list containing numbers for sorting
PrintSortNumberInCardList:
	lb bc, 1, 2 ; initial screen coordinates for printing
	ld hl, wDuelTempList + 10
.next
	ld a, [hli]
	cp $ff
	ret z ; finished with loops
	or a ; SYM_SPACE
	jr z, .space
	add SYM_0 ; load number symbol
.space
	call WriteByteToBGMap0
	; move two lines down
	inc c
	inc c
	jr .next




; given the deck index of a turn holder's card in register a,
; and a pointer in hl to the wLoadedCard* buffer where the card data is loaded,
; checks if the card is Clefairy Doll or Mysterious Fossil, and, if so, converts it
; to a Pokémon card in the wLoadedCard* buffer, using .trainer_to_pkmn_data.
; preserves de
; input:
;	a = deck index of the card to check
;	de = its card ID
;	hl = contains its card_data_struct (e.g. wLoadedCard1)
ConvertSpecialTrainerCardToPokemon::
	ld c, a
	ld a, [hl]
	cp TYPE_TRAINER
	ret nz ; return if the card is not a Trainer
	push hl
	ld a, c
	get_turn_duelist_var
	and CARD_LOCATION_PLAY_AREA
	pop hl
	ret z ; return if the card is not in the play area
	ld a, e
	cp MYSTERIOUS_FOSSIL
;	jr nz, .check_for_clefairy_doll
;	ld a, d ; card IDs are 8-bit so d is always 0
;	cp $00 ; MYSTERIOUS_FOSSIL >> 8
	jr z, .start_ram_data_overwrite
.check_for_clefairy_doll
	cp CLEFAIRY_DOLL
	ret nz
;	ld a, d ; card IDs are 8-bit so d is always 0
;	cp $00 ; CLEFAIRY_DOLL >> 8
;	ret nz
.start_ram_data_overwrite
	push de
	ld [hl], TYPE_PKMN_COLORLESS
	ld bc, CARD_DATA_HP
	add hl, bc
	ld de, .trainer_to_pkmn_data
	ld c, CARD_DATA_PKMN_FLAGS - CARD_DATA_HP
	call CopyNBytesFromDEToHL
	pop de
	ret

.trainer_to_pkmn_data
	db 10                 ; CARD_DATA_HP
	ds $07                ; CARD_DATA_ATTACK1_NAME - (CARD_DATA_HP + 1)
	tx DiscardName        ; CARD_DATA_ATTACK1_NAME
	tx DiscardDescription ; CARD_DATA_ATTACK1_DESCRIPTION
	ds $03                ; CARD_DATA_ATTACK1_CATEGORY - (CARD_DATA_ATTACK1_DESCRIPTION + 2)
	db POKEMON_POWER      ; CARD_DATA_ATTACK1_CATEGORY
	dw DiscardTrainerPokemonEffectCommands ; CARD_DATA_ATTACK1_EFFECT_COMMANDS
	ds $18                ; CARD_DATA_RETREAT_COST - (CARD_DATA_ATTACK1_EFFECT_COMMANDS + 2)
	db UNABLE_RETREAT     ; CARD_DATA_RETREAT_COST
	ds $0d                ; PKMN_CARD_DATA_LENGTH - (CARD_DATA_RETREAT_COST + 1)
