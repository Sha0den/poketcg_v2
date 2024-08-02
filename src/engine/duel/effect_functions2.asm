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
	call DrawWideTextBox_WaitForInput
	or a
	ret

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
	push de
	call GetCardIDFromDeckIndex
	ld a, e
	pop de
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
	call GetCardIDFromDeckIndex
	ld a, e
	cp NIDORANF
	jr z, .found_nidoran
	cp NIDORANM
	jr nz, .loop_deck_nidoran ; skip if not a Nidoran
.found_nidoran
	or a
	ret


; output:
;	[hTemp_ffa0] = deck index of the chosen card ($ff if no card was chosen)
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

; play SFX and loop back
.play_sfx
	call PlaySFX_InvalidChoice
	jr .read_input

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
	jr .play_sfx ; found a Basic Energy card, return to selection process

; no Basic Energy in the deck, can safely exit screen
.exit
	ld a, $ff
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
;	call LoadCardDataToBuffer2_FromDeckIndex
;	ld a, [wLoadedCard2Type]
	call GetCardIDFromDeckIndex
	call GetCardType
	cp TYPE_ENERGY
	jr c, .no_carry ; it's a Pokemon
	cp TYPE_ENERGY + NUM_COLORED_TYPES
	ret c ; it's a Basic Energy
; it must be a Trainer or Special Energy
.no_carry
	or a
	ret


; output:
;	[hTemp_ffa0] = deck index of the chosen Basic Energy ($ff if none was chosen)
;	[hTempPlayAreaLocation_ffa1] = play area location offset of the chosen Pokemon (PLAY_AREA_* constant)
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
	bank1call HasAlivePokemonInPlayArea
.loop_input
	bank1call OpenPlayAreaScreenForSelection
	jr c, .loop_input ; must choose, B button can't be used to exit
	ldh [hTempPlayAreaLocation_ffa1], a
	ret

; play SFX and loop back
.play_sfx
	call PlaySFX_InvalidChoice
	jr .read_input

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
	jr .play_sfx ; found a Basic Energy card, return to selection process

; no Basic Energy in the deck, can safely exit screen
.exit
	ld a, $ff
	ldh [hTemp_ffa0], a
	or a
	ret


; Broken, AI doesn't select any card
; output:
;	[hTemp_ffa0] = $ff (no card was chosen)
AIFindBasicEnergyToAttach:
	ld a, $ff
	ldh [hTemp_ffa0], a
	ret

; Maybe this could be used to replace the broken ai function.
; I'm not entirely sure; more code might be needed.
; finds the first basic energy in the deck
; and attaches it to the Active Pokemon
; output:
;	[hTemp_ffa0] = deck index of the chosen card ($ff if no card was chosen)
;AIFindBasicEnergyToAttach:
;	call CreateDeckCardList
;	ld hl, wDuelTempList
;.loop_deck
;	ld a, [hli]
;	ldh [hTemp_ffa0], a
;	cp $ff
;	ret z ; reached the end of the list
;	call CheckDeckIndexForBasicEnergy
;	jr nc, .loop_deck ; card isn't a Basic Energy
;	xor a ; PLAY_AREA_ARENA
;	ldh a, [hTempPlayAreaLocation_ff9d]
;	ldh [hTempPlayAreaLocation_ffa1], a
;	ret


; output:
;	[hTemp_ffa0] = deck index of the chosen card ($ff if no card was chosen)
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
	call LoadCardDataToBuffer2_FromDeckIndex
	ld a, [wLoadedCard2Type]
	cp TYPE_TRAINER
	jr nz, .play_sfx ; not a Trainer card

; a Trainer card was selected
	ldh a, [hTempCardIndex_ff98]
	ldh [hTemp_ffa0], a
	or a
	ret

; play SFX and loop back
.play_sfx
	call PlaySFX_InvalidChoice
	jr .read_input

; see if the Player can exit the screen without selecting a card,
; that is, if the deck contains no Trainer cards.
.attempt_to_cancel
	ld hl, wDuelTempList
.next_card
	ld a, [hli]
	cp $ff
	jr z, .exit
	call LoadCardDataToBuffer2_FromDeckIndex
	ld a, [wLoadedCard2Type]
	cp TYPE_TRAINER
	jr nz, .next_card
	jr .play_sfx ; found a Trainer card, return to selection process

; no Trainer cards in the deck, can safely exit screen
.exit
	ld a, $ff
	ldh [hTemp_ffa0], a
	or a
	ret


; finds the first Trainer card in the deck
; output:
;	[hTemp_ffa0] = deck index of the chosen card ($ff if no card was chosen)
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


; output:
;	[hTempList + 1] = deck index of the chosen card ($ff if no card was chosen)
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
	ldh a, [hTempCardIndex_ff98]
	call LoadCardDataToBuffer2_FromDeckIndex
	ld a, [wLoadedCard2Type]
	cp TYPE_ENERGY
	jr nc, .play_sfx ; not a Pokemon

; a Pokemon was selected
	ldh a, [hTempCardIndex_ff98]
	ldh [hTempList + 1], a
	or a
	ret

; play SFX and loop back
.play_sfx
	call PlaySFX_InvalidChoice
	jr .read_input

; see if the Player can exit the screen without selecting a card,
; that is, if the deck contains no Pokemon.
.attempt_to_cancel
	ld hl, wDuelTempList
.next_card
	ld a, [hli]
	cp $ff
	jr z, .exit
	call LoadCardDataToBuffer2_FromDeckIndex
	ld a, [wLoadedCard2Type]
	cp TYPE_ENERGY
	jr nc, .next_card
	jr .play_sfx ; found a Pokemon, return to selection process

; no Pokemon in the deck, can safely exit screen
.exit
	ld a, $ff
	ldh [hTempList + 1], a
	or a
	ret


; output:
;	[hTemp_ffa0] = deck index of the chosen card ($ff if no card was chosen)
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

; play SFX and loop back
.play_sfx
	call PlaySFX_InvalidChoice
	jr .read_input

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
	jr .play_sfx ; found an Evolution card, return to selection process

; no Evolution cards in the deck, can safely exit screen
.exit
	ld a, $ff
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


; finds the first Evolution card in the deck
; output:
;	[hTemp_ffa0] = deck index of the chosen card ($ff if no card was chosen)
AIFindEvolution:
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


; output:
;	[hTemp_ffa0] = deck index of the chosen card ($ff if no card was chosen)
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

; play SFX and loop back
.play_sfx
	call PlaySFX_InvalidChoice
	jr .read_input

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
	jr .play_sfx ; found a Basic Pokemon, return to selection process

; no Basic Pokemon in the deck, can safely exit screen
.exit
	ld a, $ff
	ldh [hTemp_ffa0], a
	or a
	ret


; finds the first Basic Pokemon in the deck
; output:
;	[hTemp_ffa0] = deck index of the chosen card ($ff if no card was chosen)
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


; output:
;	[hTemp_ffa0] = deck index of the chosen card ($ff if no card was chosen)
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

; play SFX and loop back
.play_sfx
	call PlaySFX_InvalidChoice
	jr .read_input

; see if the Player can exit the screen without selecting a card,
; that is, if the deck contains no Basic Fighting Pokemon.
.attempt_to_cancel
	ld hl, wDuelTempList
.next_card
	ld a, [hli]
	cp $ff
	jr z, .exit
	call LoadCardDataToBuffer2_FromDeckIndex
	ld a, [wLoadedCard1Type]
	cp FIGHTING
	jr nz, .next_card ; not a Fighting Pokemon, move on to the next card
	ld a, [wLoadedCard1Stage]
	or a
	jr nz, .next_card
	jr .play_sfx ; found a Basic Fighting Pokemon, return to selection process

; no Basic Fighting Pokemon in the deck, can safely exit screen
.exit
	ld a, $ff
	ldh [hTemp_ffa0], a
	or a
	ret


; finds the first Basic Fighting Pokemon in the deck
; output:
;	[hTemp_ffa0] = deck index of the chosen card ($ff if no card was chosen)
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


; output:
;	[hTemp_ffa0] = deck index of the chosen card ($ff if no card was chosen)
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

; play SFX and loop back
.play_sfx
	call PlaySFX_InvalidChoice
	jr .read_input

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
	jr .play_sfx ; found a Nidoran, return to selection process

; no Nidoran in the deck, can safely exit screen
.exit
	ld a, $ff
	ldh [hTemp_ffa0], a
	or a
	ret


; finds the first Nidoran in the deck
; output:
;	[hTemp_ffa0] = deck index of the chosen card ($ff if no card was chosen)
AIFindNidoran:
	call CreateDeckCardList
	ld hl, wDuelTempList
.loop_deck
	ld a, [hli]
	ldh [hTemp_ffa0], a
	cp $ff
	ret z ; reached the end of the list
	call GetCardIDFromDeckIndex
	ld a, e
	cp NIDORANF
	ret z ; Nidoran found
	cp NIDORANM
	jr nz, .loop_deck ; card isn't a Nidoran
	ret ; Nidoran found


; output:
;	[hTemp_ffa0] = deck index of the chosen card ($ff if no card was chosen)
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

; play SFX and loop back
.play_sfx
	call PlaySFX_InvalidChoice
	jr .read_input

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
	jr .play_sfx ; found a Oddish, return to selection process

; no Oddish in the deck, can safely exit screen
.exit
	ld a, $ff
	ldh [hTemp_ffa0], a
	or a
	ret


; finds the first Oddish in the deck
; output:
;	[hTemp_ffa0] = deck index of the chosen card ($ff if no card was chosen)
AIFindOddish:
	call CreateDeckCardList
	ld hl, wDuelTempList
.loop_deck
	ld a, [hli]
	ldh [hTemp_ffa0], a
	cp $ff
	ret z ; reached the end of the list
	call GetCardIDFromDeckIndex
	ld a, e
	cp ODDISH
	jr nz, .loop_deck ; card isn't an Oddish
	ret ; Oddish found


; output:
;	[hTemp_ffa0] = deck index of the chosen card ($ff if no card was chosen)
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

; play SFX and loop back
.play_sfx
	call PlaySFX_InvalidChoice
	jr .read_input

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
	jr .play_sfx ; found a Bellsprout, return to selection process

; no Bellsprout in the deck, can safely exit screen
.exit
	ld a, $ff
	ldh [hTemp_ffa0], a
	or a
	ret


; finds the first Bellsprout in the deck
; output:
;	[hTemp_ffa0] = deck index of the chosen card ($ff if no card was chosen)
AIFindBellsprout:
	call CreateDeckCardList
	ld hl, wDuelTempList
.loop_deck
	ld a, [hli]
	ldh [hTemp_ffa0], a
	cp $ff
	ret z ; reached the end of the list
	call GetCardIDFromDeckIndex
	ld a, e
	cp BELLSPROUT
	jr nz, .loop_deck ; card isn't a Bellsprout
	ret ; Bellsprout found


; output:
;	[hTemp_ffa0] = deck index of the chosen card ($ff if no card was chosen)
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

; play SFX and loop back
.play_sfx
	call PlaySFX_InvalidChoice
	jr .read_input

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
	jr .play_sfx ; found a Krabby, return to selection process

; no Krabby in the deck, can safely exit screen
.exit
	ld a, $ff
	ldh [hTemp_ffa0], a
	or a
	ret


; finds the first Krabby in the deck
; output:
;	[hTemp_ffa0] = deck index of the chosen card ($ff if no card was chosen)
AIFindKrabby:
	call CreateDeckCardList
	ld hl, wDuelTempList
.loop_deck
	ld a, [hli]
	ldh [hTemp_ffa0], a
	cp $ff
	ret z ; reached the end of the list
	call GetCardIDFromDeckIndex
	ld a, e
	cp KRABBY
	jr nz, .loop_deck ; card isn't a Krabby
	ret ; Krabby found
