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
;	e = (optional) card ID to search for in deck
;	hl = text to print if the deck has the card(s)
; output:
;	carry set if refused to look at deck
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
	call YesOrNoMenuWithText_SetCursorToYes
	ret

.search_table
	dw .SearchDeckForCardID
	dw .SearchDeckForBasicEnergy
    dw .SearchDeckForTrainer
	dw .SearchDeckForPokemon
	dw .SearchDeckForEvolution
	dw .SearchDeckForBasicPokemon
	dw .SearchDeckForBasicFighting
	dw .SearchDeckForNidoran

; returns carry if no card with same card ID as e is found in the player's deck
.SearchDeckForCardID
	ld hl, wDuelTempList
.loop_deck_e
	ld a, [hli]
	cp $ff
	jp z, SetCarryEF2
	push de
	call GetCardIDFromDeckIndex
	ld a, e
	pop de
	cp e
	jr nz, .loop_deck_e ; skip if wrong card id
	or a
	ret

; returns carry if no Basic Energy cards are found in the player's deck
.SearchDeckForBasicEnergy
	ld hl, wDuelTempList
.loop_deck_energy
	ld a, [hli]
	cp $ff
	jr z, SetCarryEF2
	call CheckDeckIndexForBasicEnergy
	jr nc, .loop_deck_energy ; skip if not a basic energy
	or a
	ret

; returns carry if no Trainer cards are found in the player's deck
.SearchDeckForTrainer
    ld hl, wDuelTempList
.loop_deck_trainer
    ld a, [hli]
    cp $ff
    jr z, SetCarryEF2
    call GetCardIDFromDeckIndex
    call GetCardType
    cp TYPE_TRAINER
    jr nz, .loop_deck_trainer ; skip if not a Trainer
    or a
    ret

; returns carry if no Pokemon are found in the player's deck
.SearchDeckForPokemon
	ld hl, wDuelTempList
.loop_deck_pkmn
	ld a, [hli]
	cp $ff
	jr z, SetCarryEF2
	call GetCardIDFromDeckIndex
	call GetCardType
	cp TYPE_ENERGY
	jr nc, .loop_deck_pkmn ; skip if not a Pokemon
	or a
	ret

; returns carry if no Evolution cards are found in the player's deck
.SearchDeckForEvolution
	ld hl, wDuelTempList
.loop_deck_evolution
	ld a, [hli]
	cp $ff
	jr z, SetCarryEF2
	call CheckDeckIndexForStage1OrStage2Pokemon
	jr nc, .loop_deck_evolution ; skip if not a Stage 1/2 Pokemon
	ret

; returns carry if no Basic Pokemon are found in the player's deck
.SearchDeckForBasicPokemon
	ld hl, wDuelTempList
.loop_deck_bscpkmn
	ld a, [hli]
	cp $ff
	jr z, SetCarryEF2
	call CheckDeckIndexForBasicPokemon
	jr nc, .loop_deck_bscpkmn ; skip if not a Basic Pokemon
	ret

; returns carry if no Basic Fighting Pokemon are found in the player's deck
.SearchDeckForBasicFighting
	ld hl, wDuelTempList
.loop_deck_fighting
	ld a, [hli]
	cp $ff
	jr z, SetCarryEF2
	call LoadCardDataToBuffer2_FromDeckIndex
	ld a, [wLoadedCard2Type]
	cp TYPE_PKMN_FIGHTING
	jr nz, .loop_deck_fighting ; skip if type isn't Fighting
	ld a, [wLoadedCard2Stage]
	or a
	jr nz, .loop_deck_fighting ; skip if stage isn't Basic
	ret

; returns carry if no NidoranM or NidoranF are found in the player's deck
.SearchDeckForNidoran
	ld hl, wDuelTempList
.loop_deck_nidoran
	ld a, [hli]
	cp $ff
	jr z, SetCarryEF2
	call GetCardIDFromDeckIndex
	ld a, e
	cp NIDORANF
	jr z, .found_nidoran
	cp NIDORANM
	jr nz, .loop_deck_nidoran ; skip if not a Nidoran
.found_nidoran
	or a
	ret

SetCarryEF2:
	scf
	ret

FindBasicEnergy:
	ld a, $ff
	ldh [hTemp_ffa0], a
	call CreateDeckCardList
	ldtx hl, Choose1BasicEnergyCardFromDeckText
	lb de, SEARCHEFFECT_BASIC_ENERGY, 0
	ldtx bc, BasicEnergyText
	call LookForCardsInDeck
	ret c ; skip showing the deck

	bank1call Func_5591
	ldtx hl, ChooseBasicEnergyCardText
	ldtx de, DuelistDeckText
	bank1call SetCardListHeaderText
.read_input
	bank1call DisplayCardList
	jr c, .try_exit ; B button was pressed?
	ldh a, [hTempCardIndex_ff98]
	ldh [hTemp_ffa0], a
	call CheckDeckIndexForBasicEnergy
	jr nc, .play_sfx
	or a
	ret

; play SFX and loop back
.play_sfx
	call PlaySFX_InvalidChoice
	jr .read_input

; see if the Player can exit the screen without selecting a card,
; that is, if the deck contains no Basic Energy cards.
.try_exit
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

; check if card index in a is a Basic Energy card
; sets the carry flag if the check is a success
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

FindBasicEnergyToAttach:
	ld a, $ff
	ldh [hTemp_ffa0], a

; search the cards in the deck
	call CreateDeckCardList
	ldtx hl, Choose1BasicEnergyCardFromDeckText
	ldtx bc, BasicEnergyText
	lb de, SEARCHEFFECT_BASIC_ENERGY, 0
	call LookForCardsInDeck
	ret c

	bank1call Func_5591
	ldtx hl, ChooseBasicEnergyCardText
	ldtx de, DuelistDeckText
	bank1call SetCardListHeaderText
.select_card
	bank1call DisplayCardList
	jr c, .try_cancel
	call CheckDeckIndexForBasicEnergy
	jr nc, .play_sfx ; skip if not a Basic Energy

	ldh a, [hTempCardIndex_ff98]
	ldh [hTemp_ffa0], a
	call EmptyScreen
	ldtx hl, ChoosePokemonToAttachEnergyCardText
	call DrawWideTextBox_WaitForInput

; choose a Pokemon in the Play Area to attach the card to
	bank1call HasAlivePokemonInPlayArea
.loop_input
	bank1call OpenPlayAreaScreenForSelection
	jr c, .loop_input
	ldh a, [hTempPlayAreaLocation_ff9d]
	ldh [hTempPlayAreaLocation_ffa1], a
	ret

; play SFX and loop back
.play_sfx
	call PlaySFX_InvalidChoice
	jr .select_card

; see if the Player can exit the screen without selecting a card,
; that is, if the deck contains no Basic Energy cards.
.try_cancel
	ld a, DUELVARS_CARD_LOCATIONS
	call GetTurnDuelistVariable
.loop_deck
	ld a, [hl]
	cp CARD_LOCATION_DECK
	jr nz, .next_card
	ld a, l
	call GetCardIDFromDeckIndex
	call GetCardType
	and TYPE_ENERGY
	jr z, .next_card ; not an Energy card, move on to the next card
	cp TYPE_ENERGY + NUM_COLORED_TYPES
	jr c, .play_sfx ; found a Basic Energy card, return to selection process
.next_card
	inc l
	ld a, l
	cp DECK_SIZE
	jr c, .loop_deck

; no Basic Energy in the deck, can safely exit screen
	ld a, $ff
	ldh [hTemp_ffa0], a
	or a
	ret

; Broken, AI doesn't select any card
AIFindBasicEnergyToAttach:
	ld a, $ff
	ldh [hTemp_ffa0], a
	ret

; Maybe this could be used to replace the broken ai function.
; I'm not entirely sure; more code might be needed.
; finds the first basic energy in the deck
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
;	or a ; reset the carry flag
;	ret ; a Basic Energy was found

FindAnyPokemon:
; create a list of every Pokemon in the deck
	call CreateDeckCardList
	ldtx hl, ChoosePokemonFromDeckText
	ldtx bc, PokemonName
	lb de, SEARCHEFFECT_POKEMON, 0
	call LookForCardsInDeck
	jr c, .no_pkmn ; return if the Player chose not to check the deck

; handle input
	bank1call Func_5591
	ldtx hl, ChoosePokemonCardText
	ldtx de, DuelistDeckText
	bank1call SetCardListHeaderText
.read_input
	bank1call DisplayCardList
	jr c, .try_exit ; B button was pressed
	ldh a, [hTempCardIndex_ff98]
	call LoadCardDataToBuffer2_FromDeckIndex
	ld a, [wLoadedCard2Type]
	cp TYPE_ENERGY
	jr nc, .play_sfx ; can't select a non-Pokemon card
	ldh a, [hTempCardIndex_ff98]
	ldh [hTempList + 1], a
	or a
	ret

.no_pkmn
	ld a, $ff
	ldh [hTempList + 1], a
	or a
	ret

; play SFX and loop back
.play_sfx
	call PlaySFX_InvalidChoice
	jr .read_input

; see if the Player can exit the screen without selecting a card,
; that is, if the deck contains no Pokemon.
.try_exit
	ld hl, wDuelTempList
.loop
	ld a, [hli]
	cp $ff
	jr z, .no_pkmn
	call LoadCardDataToBuffer2_FromDeckIndex
	ld a, [wLoadedCard2Type]
	cp TYPE_ENERGY
	jr nc, .loop
	jr .play_sfx ; no, need to select a Pokemon

FindEvolution:
	ld a, $ff
	ldh [hTemp_ffa0], a
	call CreateDeckCardList
	ldtx hl, ChooseEvolutionPokemonFromDeckText
	lb de, SEARCHEFFECT_EVOLUTION, 0
	ldtx bc, EvolutionPokemonText
	call LookForCardsInDeck
	ret c ; skip showing the deck

	bank1call Func_5591
	ldtx hl, ChooseEvolutionPokemonText
	ldtx de, DuelistDeckText
	bank1call SetCardListHeaderText
.read_input
	bank1call DisplayCardList
	jr c, .try_exit ; B button was pressed?
	ldh a, [hTempCardIndex_ff98]
	ldh [hTemp_ffa0], a
	call CheckDeckIndexForStage1OrStage2Pokemon
	jr nc, .play_sfx
	or a
	ret

; play SFX and loop back
.play_sfx
	call PlaySFX_InvalidChoice
	jr .read_input

; see if the Player can exit the screen without selecting a card,
; that is, if the deck contains no Evolution cards.
.try_exit
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

; check if card index in a is an Evolution card
; sets the carry flag if the check is a success
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
	or a ; reset the carry flag
	ret ; Evolution card found

FindBasicPokemon:
	ld a, $ff
	ldh [hTemp_ffa0], a

	call CreateDeckCardList
	ldtx hl, ChooseBasicPokemonFromDeckText
	ldtx bc, BasicPokemonText
	lb de, SEARCHEFFECT_BASIC_POKEMON, $00
	call LookForCardsInDeck
	ret c

; draw deck list interface and print text
	bank1call Func_5591
	ldtx hl, ChooseBasicPokemonText
	ldtx de, DuelistDeckText
	bank1call SetCardListHeaderText

.loop
	bank1call DisplayCardList
	jr c, .pressed_b

	call CheckDeckIndexForBasicPokemon
	jr nc, .play_sfx ; not a Basic Pokemon
	ldh a, [hTempCardIndex_ff98]
	ldh [hTemp_ffa0], a
	or a
	ret

; play SFX and loop back
.play_sfx
	call PlaySFX_InvalidChoice
	jr .loop

; see if the Player can exit the screen without selecting a card,
; that is, if the deck contains no Basic Pokemon.
.pressed_b
	ld a, DUELVARS_CARD_LOCATIONS
	call GetTurnDuelistVariable
.loop_b_press
	ld a, [hl]
	cp CARD_LOCATION_DECK
	jr nz, .next
	ld a, l
	call LoadCardDataToBuffer2_FromDeckIndex
	ld a, [wLoadedCard2Type]
	cp TYPE_ENERGY
	jr nc, .next ; not a Pokemon, move on to the next card
	ld a, [wLoadedCard1Stage]
	or a
	jr z, .play_sfx ; found a Basic Pokemon, return to selection process
.next
	inc l
	ld a, l
	cp DECK_SIZE
	jr c, .loop_b_press

; no Basic Pokemon in the deck, can safely exit screen
	ld a, $ff
	ldh [hTemp_ffa0], a
	or a
	ret

; finds the first Basic Pokemon in the deck
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
	or a ; reset the carry flag
	ret ; Basic Pokemon found

FindBasicFightingPokemon:
	ld a, $ff
	ldh [hTemp_ffa0], a

	call CreateDeckCardList
	ldtx hl, ChooseBasicFightingPokemonFromDeckText
	ldtx bc, FightingPokemonText
	lb de, SEARCHEFFECT_BASIC_FIGHTING, $00
	call LookForCardsInDeck
	ret c

; draw deck list interface and print text
	bank1call Func_5591
	ldtx hl, ChooseBasicFightingPokemonText
	ldtx de, DuelistDeckText
	bank1call SetCardListHeaderText

.loop
	bank1call DisplayCardList
	jr c, .pressed_b

	call LoadCardDataToBuffer2_FromDeckIndex
	ld a, [wLoadedCard2Type]
	cp FIGHTING
	jr nz, .play_sfx ; is Fighting?
	ld a, [wLoadedCard2Stage]
	or a
	jr nz, .play_sfx ; is Basic?
	ldh a, [hTempCardIndex_ff98]
	ldh [hTemp_ffa0], a
	or a
	ret

; play SFX and loop back
.play_sfx
	call PlaySFX_InvalidChoice
	jr .loop

; see if the Player can exit the screen without selecting a card,
; that is, if the deck contains no Basic Fighting Pokemon.
.pressed_b
	ld a, DUELVARS_CARD_LOCATIONS
	call GetTurnDuelistVariable
.loop_b_press
	ld a, [hl]
	cp CARD_LOCATION_DECK
	jr nz, .next
	ld a, l
	call LoadCardDataToBuffer2_FromDeckIndex
	ld a, [wLoadedCard1Type]
	cp FIGHTING
	jr nz, .next ; not a Fighting Pokemon, move on to the next card
	ld a, [wLoadedCard1Stage]
	or a
	jr z, .play_sfx ; found a Basic Fighting Pokemon, return to selection
.next
	inc l
	ld a, l
	cp DECK_SIZE
	jr c, .loop_b_press

; no Basic Fighting Pokemon in the deck, can safely exit screen
	ld a, $ff
	ldh [hTemp_ffa0], a
	or a
	ret

; finds the first Basic Fighting Pokemon in the deck
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
	jr nz, .loop_deck
	ld a, [wLoadedCard2Stage]
	or a
	jr nz, .loop_deck ; card isn't a Basic Fighting Pokemon
	ret ; Fighting Pokemon found

FindNidoran:
	ld a, $ff
	ldh [hTemp_ffa0], a

	call CreateDeckCardList
	ldtx hl, ChooseNidoranFromDeckText
	ldtx bc, NidoranMNidoranFText
	lb de, SEARCHEFFECT_NIDORAN, $00
	call LookForCardsInDeck
	ret c

; draw deck list interface and print text
	bank1call Func_5591
	ldtx hl, ChooseNidoranText
	ldtx de, DuelistDeckText
	bank1call SetCardListHeaderText

.loop
	bank1call DisplayCardList
	jr c, .pressed_b
	call GetCardIDFromDeckIndex
	ld bc, NIDORANF
	call CompareDEtoBC
	jr z, .selected_nidoran
	ld bc, NIDORANM
	call CompareDEtoBC
	jr nz, .play_sfx

.selected_nidoran
	ldh a, [hTempCardIndex_ff98]
	ldh [hTemp_ffa0], a
	or a
	ret

; play SFX and loop back
.play_sfx
	call PlaySFX_InvalidChoice
	jr .loop

; see if the Player can exit the screen without selecting a card,
; that is, if the deck contains no NidoranF or NidoranM cards.
.pressed_b
	ld a, DUELVARS_CARD_LOCATIONS
	call GetTurnDuelistVariable
.loop_b_press
	ld a, [hl]
	cp CARD_LOCATION_DECK
	jr nz, .next
	ld a, l
	call GetCardIDFromDeckIndex
	ld bc, NIDORANF
	call CompareDEtoBC
	jr z, .play_sfx ; found a Nidoran, return to selection
	ld bc, NIDORANM
	jr z, .play_sfx ; found a Nidoran, return to selection
.next
	inc l
	ld a, l
	cp DECK_SIZE
	jr c, .loop_b_press

; no Nidoran in the deck, can safely exit screen
	ld a, $ff
	ldh [hTemp_ffa0], a
	or a
	ret

; finds the first Nidoran in the deck
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
	ret z
	cp NIDORANM
	jr nz, .loop_deck ; card isn't a Nidoran
	ret ; Nidoran found

FindOddish:
	ld a, $ff
	ldh [hTemp_ffa0], a

	call CreateDeckCardList
	ldtx hl, ChooseAnOddishFromDeckText
	ldtx bc, OddishName
	lb de, SEARCHEFFECT_CARD_ID, ODDISH
	call LookForCardsInDeck
	ret c

; draw deck list interface and print text
	bank1call Func_5591
	ldtx hl, ChooseAnOddishText
	ldtx de, DuelistDeckText
	bank1call SetCardListHeaderText

.loop
	bank1call DisplayCardList
	jr c, .pressed_b
	call GetCardIDFromDeckIndex
	ld bc, ODDISH
	call CompareDEtoBC
	jr nz, .play_sfx

; Oddish was selected
	ldh a, [hTempCardIndex_ff98]
	ldh [hTemp_ffa0], a
	or a
	ret

.play_sfx
	; play SFX and loop back
	call PlaySFX_InvalidChoice
	jr .loop

; see if the Player can exit the screen without selecting a card,
; that is, if the deck contains no Oddish cards.
.pressed_b
	ld a, DUELVARS_CARD_LOCATIONS
	call GetTurnDuelistVariable
.loop_b_press
	ld a, [hl]
	cp CARD_LOCATION_DECK
	jr nz, .next
	ld a, l
	call GetCardIDFromDeckIndex
	ld bc, ODDISH
	call CompareDEtoBC
	jr z, .play_sfx ; found an Oddish, return to selection
.next
	inc l
	ld a, l
	cp DECK_SIZE
	jr c, .loop_b_press

; no Oddish in the deck, can safely exit screen
	ld a, $ff
	ldh [hTemp_ffa0], a
	or a
	ret

; finds the first Oddish in the deck
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

FindBellsprout:
	ld a, $ff
	ldh [hTemp_ffa0], a

	call CreateDeckCardList
	ldtx hl, ChooseABellsproutFromDeckText
	ldtx bc, BellsproutName
	lb de, SEARCHEFFECT_CARD_ID, BELLSPROUT
	call LookForCardsInDeck
	ret c

; draw deck list interface and print text
	bank1call Func_5591
	ldtx hl, ChooseABellsproutText
	ldtx de, DuelistDeckText
	bank1call SetCardListHeaderText

.loop
	bank1call DisplayCardList
	jr c, .pressed_b
	call GetCardIDFromDeckIndex
	ld bc, BELLSPROUT
	call CompareDEtoBC
	jr nz, .play_sfx

; Bellsprout was selected
	ldh a, [hTempCardIndex_ff98]
	ldh [hTemp_ffa0], a
	or a
	ret

; play SFX and loop back
.play_sfx
	call PlaySFX_InvalidChoice
	jr .loop

; see if the Player can exit the screen without selecting a card,
; that is, if the deck contains no Bellsprout cards.
.pressed_b
	ld a, DUELVARS_CARD_LOCATIONS
	call GetTurnDuelistVariable
.loop_b_press
	ld a, [hl]
	cp CARD_LOCATION_DECK
	jr nz, .next
	ld a, l
	call GetCardIDFromDeckIndex
	ld bc, BELLSPROUT
	call CompareDEtoBC
	jr z, .play_sfx ; found a Bellsprout, return to selection
.next
	inc l
	ld a, l
	cp DECK_SIZE
	jr c, .loop_b_press

; no Bellsprout in the deck, can safely exit screen
	ld a, $ff
	ldh [hTemp_ffa0], a
	or a
	ret

; finds the first Bellsprout in the deck
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

FindKrabby:
	ld a, $ff
	ldh [hTemp_ffa0], a

	call CreateDeckCardList
	ldtx hl, ChooseAKrabbyFromDeckText
	ldtx bc, KrabbyName
	lb de, SEARCHEFFECT_CARD_ID, KRABBY
	call LookForCardsInDeck
	ret c

; draw deck list interface and print text
	bank1call Func_5591
	ldtx hl, ChooseAKrabbyText
	ldtx de, DuelistDeckText
	bank1call SetCardListHeaderText

.loop
	bank1call DisplayCardList
	jr c, .pressed_b
	call GetCardIDFromDeckIndex
	ld bc, KRABBY
	call CompareDEtoBC
	jr nz, .play_sfx

; Krabby was selected
	ldh a, [hTempCardIndex_ff98]
	ldh [hTemp_ffa0], a
	or a
	ret

; play SFX and loop back
.play_sfx
	call PlaySFX_InvalidChoice
	jr .loop

; see if the Player can exit the screen without selecting a card,
; that is, if the deck contains Krabby cards.
.pressed_b
	ld a, DUELVARS_CARD_LOCATIONS
	call GetTurnDuelistVariable
.loop_b_press
	ld a, [hl]
	cp CARD_LOCATION_DECK
	jr nz, .next
	ld a, l
	call GetCardIDFromDeckIndex
	ld bc, KRABBY
	call CompareDEtoBC
	jr z, .play_sfx ; found a Krabby, return to selection
.next
	inc l
	ld a, l
	cp DECK_SIZE
	jr c, .loop_b_press

; no Krabby in the deck, can safely exit screen
	ld a, $ff
	ldh [hTemp_ffa0], a
	or a
	ret

; finds the first Krabby in the deck
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
