; generates a booster pack identified by its BOOSTER_* constant in a,
; and adds the drawn cards to the player's collection (sCardCollection).
; preserves all registers except af
; input:
;	a = which booster pack variant to generate (BOOSTER_*_* constant)
GenerateBoosterPack:
	push hl
	push bc
	push de
	ld [wBoosterPackID], a
.no_cards_found_loop
	call InitBoosterData
	call GenerateBoosterEnergies
	call GenerateBoosterNonEnergies
	jr c, .no_cards_found_loop
	call PutEnergiesAndNonEnergiesTogether
	pop de
	pop bc
	pop hl
	ret


; generates all Pokemon or Trainer cards (if any) for the current booster pack
; output:
;	carry = set:  if there aren't enough cards to add to the booster pack
GenerateBoosterNonEnergies:
	ld a, STAR
	ld [wBoosterCurrentRarity], a
.generate_card_loop
	call GetCurrentRarityAmount
	ld a, [hl]
	or a
	jr z, .no_more_of_current_rarity
	call FindCardsInSetAndRarity
	call CalculateTypeChances
	or a
	jr z, .no_valid_cards
	call Random
	call DetermineBoosterCardType
	call DetermineBoosterCard
	call UpdateBoosterCardTypesChanceByte
	call AddBoosterCardToDrawnNonEnergies
	call GetCurrentRarityAmount
	dec [hl] ; decrement amount left of current rarity
	jr .generate_card_loop
.no_more_of_current_rarity
	ld a, [wBoosterCurrentRarity]
	dec a
	ld [wBoosterCurrentRarity], a
	bit 7, a ; any rarity left to check?
	jr z, .generate_card_loop
	or a
	ret
.no_valid_cards
	scf
	ret


; returns with hl pointing to wBoosterData_CommonAmount, wBoosterData_UncommonAmount,
; or wBoosterData_RareAmount, depending on the value at [wBoosterCurrentRarity]
; preserves bc and de
; input:
;	[wBoosterCurrentRarity] = CARD_DATA_RARITY constant
; output:
;	hl =  wBoosterData_*Amount, where * is the rarity from input
GetCurrentRarityAmount:
	push bc
	ld hl, wBoosterData_CommonAmount
	ld a, [wBoosterCurrentRarity]
	ld c, a
	ld b, $0
	add hl, bc
	pop bc
	ret


; loops through all existing cards to see which ones belong to the current set and rarity,
; skipping any card already drawn in the current pack.
; output:
;	wBoosterViableCardList = list of available cards that match the current set and rarity
;	wBoosterAmountOfCardTypeTable = list with number of available cards that match the
;	                                current set and rarity for each booster card type
FindCardsInSetAndRarity:
	ld c, NUM_BOOSTER_CARD_TYPES
	ld hl, wBoosterAmountOfCardTypeTable
	xor a
.delete_type_table_loop
	ld [hli], a
	dec c
	jr nz, .delete_type_table_loop
	ld hl, wBoosterViableCardList
	ld [hl], a
	ld de, 1 ; GRASS_ENERGY
.check_card_viable_loop
	push de
	ld a, e
	ld [wBoosterCurrentCard], a
	call CheckCardAlreadyDrawn
	jr c, .finished_with_current_card
	call CheckCardInSetAndRarity
	jr c, .finished_with_current_card
	ld a, [wBoosterCurrentCardType]
	call GetBoosterCardType
	push af
	push hl
	ld c, a
	ld b, $00
	ld hl, wBoosterAmountOfCardTypeTable
	add hl, bc
	inc [hl]
	pop hl
	ld a, [wBoosterCurrentCard]
	ld [hli], a
	pop af
	ld [hli], a
	xor a
	ld [hl], a
.finished_with_current_card
	pop de
	inc e
	ld a, e
	cp NUM_CARDS + 1
	jr c, .check_card_viable_loop
	ret


; preserves all registers except af
; input:
;	e = card ID to check
;	[wBoosterData_Set] = BOOSTER_* constant (0-3)
; output:
;	carry = set:  if the given card doesn't belong to the current set and rarity
CheckCardInSetAndRarity:
	push bc
	ld a, e
	call GetCardTypeRarityAndSet
	ld [wBoosterCurrentCardType], a
	ld a, [wBoosterCurrentRarity]
	cp b ; current card's rarity
	jr nz, .invalid_card ; return carry if this card's rarity doesn't match the currently selected rarity
;	ld a, [wBoosterCurrentCardType]
;	call GetBoosterCardType
;	cp BOOSTER_CARD_TYPE_ENERGY
;	jr z, .done ; ignore the booster set and return no carry if an Energy is needed and this card is the correct rarity and type
	ld a, c ; current card's set
	swap a
	and $0f
	ld c, a
	ld a, [wBoosterData_Set]
	cp c
	jr z, .done ; return no carry if this card's set also matches the booster's set
.invalid_card
	scf
.done
	pop bc
	ret


; converts a card's TYPE_* constant given in a to its BOOSTER_CARD_TYPE_* constant
; preserves all registers except af
; input:
;	a = TYPE_* constant
; output:
;	a = BOOSTER_CARD_TYPE_* constant
GetBoosterCardType:
	push hl
	push bc
	ld hl, CardTypeTable
	cp NUM_CARD_TYPES
	jr nc, .load_type
	ld c, a
	ld b, $00
	add hl, bc
.load_type
	ld a, [hl]
	pop bc
	pop hl
	ret

CardTypeTable:
	table_width 1, CardTypeTable
	db BOOSTER_CARD_TYPE_FIRE      ; TYPE_PKMN_FIRE
	db BOOSTER_CARD_TYPE_GRASS     ; TYPE_PKMN_GRASS
	db BOOSTER_CARD_TYPE_LIGHTNING ; TYPE_PKMN_LIGHTNING
	db BOOSTER_CARD_TYPE_WATER     ; TYPE_PKMN_WATER
	db BOOSTER_CARD_TYPE_FIGHTING  ; TYPE_PKMN_FIGHTING
	db BOOSTER_CARD_TYPE_PSYCHIC   ; TYPE_PKMN_PSYCHIC
	db BOOSTER_CARD_TYPE_COLORLESS ; TYPE_PKMN_COLORLESS
	db BOOSTER_CARD_TYPE_TRAINER   ; TYPE_PKMN_UNUSED
	db BOOSTER_CARD_TYPE_ENERGY    ; TYPE_ENERGY_FIRE
	db BOOSTER_CARD_TYPE_ENERGY    ; TYPE_ENERGY_GRASS
	db BOOSTER_CARD_TYPE_ENERGY    ; TYPE_ENERGY_LIGHTNING
	db BOOSTER_CARD_TYPE_ENERGY    ; TYPE_ENERGY_WATER
	db BOOSTER_CARD_TYPE_ENERGY    ; TYPE_ENERGY_FIGHTING
	db BOOSTER_CARD_TYPE_ENERGY    ; TYPE_ENERGY_PSYCHIC
	db BOOSTER_CARD_TYPE_ENERGY    ; TYPE_ENERGY_COLORLESS
	db BOOSTER_CARD_TYPE_TRAINER   ; TYPE_ENERGY_UNUSED
	db BOOSTER_CARD_TYPE_TRAINER   ; TYPE_TRAINER
	assert_table_length NUM_CARD_TYPES


; calculates the chance of each type (BOOSTER_CARD_TYPE_*) for the next card
; preserves de
; input:
;	wBoosterAmountOfCardTypeTable = list with number of available cards that match the
;	                                current set and rarity for each booster card type
;	wBoosterData_TypeChances = list with base probabilities for each booster card type
; output:
;	a & [wd4ca] = sum of all chances
;	wBoosterTempTypeChancesTable = list with adjusted probabilities for each booster card type
;	                               (if no type X cards in set have current rarity, type X's probability = 0)
CalculateTypeChances:
	ld c, NUM_BOOSTER_CARD_TYPES
	xor a
	ld hl, wBoosterTempTypeChancesTable
.delete_temp_type_chance_table_loop
	ld [hli], a
	dec c
	jr nz, .delete_temp_type_chance_table_loop
	ld [wd4ca], a
	ld bc, $00
.check_if_type_is_valid
	ld hl, wBoosterAmountOfCardTypeTable
	add hl, bc
	ld a, [hl]
	or a
	jr z, .amount_of_type_or_chance_zero
	ld hl, wBoosterData_TypeChances
	add hl, bc
	ld a, [hl]
	or a
	jr z, .amount_of_type_or_chance_zero
	ld hl, wBoosterTempTypeChancesTable
	add hl, bc
	ld [hl], a
	ld a, [wd4ca]
	add [hl]
	ld [wd4ca], a
.amount_of_type_or_chance_zero
	inc c
	ld a, c
	cp NUM_BOOSTER_CARD_TYPES
	jr c, .check_if_type_is_valid
	ld a, [wd4ca]
	ret


; preserves de and b
; input:
;	a = random number between 0 and the sum of all chances (exclusive)
;	wBoosterTempTypeChancesTable = list with probabilities for each booster card type
; output:
;	a & c & [wBoosterJustDrawnCardType] = chosen type (BOOSTER_CARD_TYPE_* constant)
DetermineBoosterCardType:
	ld c, BOOSTER_CARD_TYPE_GRASS
	ld hl, wBoosterTempTypeChancesTable
.loop_through_card_types
	sub [hl]
	jr c, .found_card_type
	inc hl
	inc c
	jr .loop_through_card_types
.found_card_type
	ld a, c
	ld [wBoosterJustDrawnCardType], a
	ret


; generates a random number between 0 and the amount of cards matching the current type
; and uses that number to determine the card to draw from the booster pack.
; preserves de
; input:
;	c & [wBoosterJustDrawnCardType] = BOOSTER_CARD_TYPE_* constant
;	wBoosterAmountOfCardTypeTable = list with number of available cards that match the
;	                                current set and rarity for each booster card type

;	wBoosterViableCardList = list of available cards that match the current set and rarity
; output:
;	carry = set:  if there were no valid cards
;	[wBoosterCurrentCard] = card ID that was chosen
DetermineBoosterCard:
	ld b, $00
	ld hl, wBoosterAmountOfCardTypeTable
	add hl, bc
	ld a, [hl]
	call Random
	ld [wd4ca], a
	ld hl, wBoosterViableCardList
.find_matching_card_loop
	ld a, [hli]
	or a
	jr z, .no_valid_card_found
	ld [wBoosterCurrentCard], a
	ld a, [wBoosterJustDrawnCardType]
	cp [hl]
	jr nz, .card_incorrect_type
	ld a, [wd4ca]
	or a
	ret z ; return no carry if this is the randomly chosen card
	dec a
	ld [wd4ca], a
.card_incorrect_type
	inc hl
	jr .find_matching_card_loop
.no_valid_card_found
	scf
	ret


; lowers the chance of getting the same type of card multiple times.
; more specifically, when a card of type T is drawn, T's new chances become
; max (8, [wBoosterData_TypeChances[T]] - [wBoosterAveragedTypeChances]).
; preserves all registers except af
; input:
;	[wBoosterJustDrawnCardType] = BOOSTER_CARD_TYPE_* constant
;	[wBoosterData_TypeChances] = list with base probabilities for each booster card type (9 bytes)
;	[wBoosterAveragedTypeChances] = average of all base booster card type probabilities
UpdateBoosterCardTypesChanceByte:
	push hl
	push bc
	ld a, [wBoosterJustDrawnCardType]
	ld c, a
	ld b, $00
	ld hl, wBoosterData_TypeChances
	add hl, bc
	ld a, [wBoosterAveragedTypeChances]
	ld c, a
	ld a, [hl]
	sub c
	jr c, .use_minimum ; set chance to minimum amount if difference was negative
	cp 8
	jr nc, .more_than_minimum ; use difference if >= 8
.use_minimum
	ld a, 8 ; minimum chance is 5% (assuming the sum of all type chances = 160)
.more_than_minimum
	ld [hl], a
	pop bc
	pop hl
	ret


; generates between 0 and 10 Energy cards for the current booster pack.
; the number of Energy cards and their probabilities vary with each booster.
; the Energy cards are added to wBoosterTempEnergiesDrawn and wTempCardCollection.
; input:
;	[wBoosterData_EnergyFunctionPointer] = function pointer or card ID of an Energy card (2 bytes)
GenerateBoosterEnergies:
	ld hl, wBoosterData_EnergyFunctionPointer + 1
	ld a, [hld]
	or a
	jr z, .no_function_pointer
	ld l, [hl]
	ld h, a
	jp hl
.no_function_pointer
	ld a, [hl]
	or a
	ret z ; return if no hardcoded Energy either
	push af
	call AddBoosterEnergyToDrawnEnergies
	pop af
	ret


EnergyBoosterLightningFireData:
	db LIGHTNING_ENERGY, FIRE_ENERGY

EnergyBoosterWaterFightingData:
	db WATER_ENERGY, FIGHTING_ENERGY

EnergyBoosterGrassPsychicData:
	db GRASS_ENERGY, PSYCHIC_ENERGY


; generates a booster containing 5 Lightning Energy cards and 5 Fire Energy cards
; preserves de
GenerateEnergyBoosterLightningFire:
	ld hl, EnergyBoosterLightningFireData
	jr GenerateTwoTypesEnergyBooster

; generates a booster containing 5 Water Energy cards and 5 Fighting Energy cards
; preserves de
GenerateEnergyBoosterWaterFighting:
	ld hl, EnergyBoosterWaterFightingData
	jr GenerateTwoTypesEnergyBooster

; generates a booster containing 5 Grass Energy cards and 5 Psychic Energy cards
; preserves de
GenerateEnergyBoosterGrassPsychic:
	ld hl, EnergyBoosterGrassPsychicData
;	fallthrough

; generates a booster pack which contains 10 Energy cards,
; split evenly between 2 different Energy cards
; preserves de
; input:
;	hl = data listing which 2 Energy cards to use
GenerateTwoTypesEnergyBooster:
	ld b, $02
.add_two_energies_to_booster_loop
	ld c, NUM_CARDS_IN_BOOSTER / 2
.add_energy_to_booster_loop
	ld a, [hl]
	call AddBoosterEnergyToDrawnEnergies
	dec c
	jr nz, .add_energy_to_booster_loop
	inc hl
	dec b
	jr nz, .add_two_energies_to_booster_loop
;	fallthrough

; preserves all registers except af
ZeroBoosterRarityData:
	xor a
	ld [wBoosterData_CommonAmount], a
	ld [wBoosterData_UncommonAmount], a
	ld [wBoosterData_RareAmount], a
	ret


; generates a booster pack which contains 10 random Basic Energy cards
; preserves all registers except af
GenerateRandomEnergyBooster:
	ld a, NUM_CARDS_IN_BOOSTER
.generate_energy_loop
	push af
	call GenerateRandomEnergy
	pop af
	dec a
	jr nz, .generate_energy_loop
	jr ZeroBoosterRarityData


; generates a random Energy card
; preserves all registers except af
GenerateRandomEnergy:
	ld a, NUM_COLORED_TYPES
	call Random
	add GRASS_ENERGY
;	fallthrough

; adds the (Energy) card at a to wBoosterTempEnergiesDrawn and wTempCardCollection
; preserves all registers except af
; input:
;	a = card ID to add to wBoosterTempEnergiesDrawn
AddBoosterEnergyToDrawnEnergies:
	ld [wBoosterCurrentCard], a
;	fallthrough

; adds the (Energy) card at [wBoosterCurrentCard] to wBoosterTempEnergiesDrawn and wTempCardCollection
; preserves all registers except af
; input:
;	[wBoosterCurrentCard] = card ID to add to wBoosterTempEnergiesDrawn
AddBoosterCardToDrawnEnergies:
	push hl
	ld hl, wBoosterTempEnergiesDrawn
	call AppendCurrentCardToHL
	call AddBoosterCardToTempCardCollection
	pop hl
	ret


; adds the (non-Energy) card at [wBoosterCurrentCard] to wBoosterTempNonEnergiesDrawn and wTempCardCollection
; preserves all registers except af
; input:
;	[wBoosterCurrentCard] = card ID to add to the lists
AddBoosterCardToDrawnNonEnergies:
	push hl
	ld hl, wBoosterTempNonEnergiesDrawn
	call AppendCurrentCardToHL
	call AddBoosterCardToTempCardCollection
	pop hl
	ret


; puts the card at [wBoosterCurrentCard] at the end of the booster card list at hl
; preserves bc and de
; input:
;	hl = $00 terminated list with card IDs (in wBoosterCardsDrawn)
;	[wBoosterCurrentCard] = card ID to add to the lists
AppendCurrentCardToHL:
	ld a, [hli]
	or a
	jr nz, AppendCurrentCardToHL
	dec hl
	ld a, [wBoosterCurrentCard]
	ld [hli], a
	xor a
	ld [hl], a
	ret


; trims empty slots in wBoosterCardsDrawn between non-Energy and Energy cards
; preserves all registers except af
; input:
;	wBoosterTempNonEnergiesDrawn = $00 terminated list
;	wBoosterTempEnergiesDrawn = $00 terminated list
; output:
;	wBoosterCardsDrawn = $00 terminated list containing all entries from both input lists
PutEnergiesAndNonEnergiesTogether:
	push hl
	ld hl, wBoosterTempEnergiesDrawn
.loop_through_extra_cards
	ld a, [hli]
	or a
	jr z, .end_of_cards
	ld [wBoosterCurrentCard], a
	push hl
	ld hl, wBoosterTempNonEnergiesDrawn
	call AppendCurrentCardToHL
	pop hl
	jr .loop_through_extra_cards
.end_of_cards
	pop hl
	ret


; adds the card at [wBoosterCurrentCard] to wTempCardCollection
; preserves all registers except af
; input:
;	[wBoosterCurrentCard] = card ID
AddBoosterCardToTempCardCollection:
	push hl
	ld h, HIGH(wTempCardCollection)
	ld a, [wBoosterCurrentCard]
	ld l, a
	inc [hl]
	pop hl
	ret


; checks if the card at [wBoosterCurrentCard] has already been added to wTempCardCollection
; preserves all registers except af
; input:
;	[wBoosterCurrentCard] = card ID
; output:
;	carry = set:  if the given card was already added to wTempCardCollection
CheckCardAlreadyDrawn:
	push hl
	ld h, HIGH(wTempCardCollection)
	ld a, [wBoosterCurrentCard]
	ld l, a
	ld a, [hl]
	pop hl
	cp $01
	ccf
	ret


; clears wBoosterCardsDrawn and wTempCardCollection.
; copies booster data to wBoosterData_Set, wBoosterData_EnergyFunctionPointer, and wBoosterData_TypeChances.
; copies rarity amounts to wBoosterData_*Amount and averages them into wBoosterAveragedTypeChances.
; output:
;	[wBoosterData_Set] = BOOSTER_* constant (0-3)
;	[wBoosterData_EnergyFunctionPointer] = function pointer or card ID of an Energy card (2 bytes)
;	[wBoosterData_TypeChances] = list with base probabilities for each booster card type (9 bytes)
;	[wBoosterData_CommonAmount] = how many commons should be in a booster pack from that set (either 5 or 6)
;	[wBoosterData_UncommonAmount] = how many uncommons should be in a booster pack from that set (always 3)
;	[wBoosterData_RareAmount] = how many rares should be in a booster pack from that set (always 1)
;	[wBoosterAveragedTypeChances] = average of all base booster card type probabilities
InitBoosterData:
	ld c, wBoosterCardsDrawnEnd - wBoosterCardsDrawn
	ld hl, wBoosterCardsDrawn
	xor a
.clear_player_deck_loop
	ld [hli], a
	dec c
	jr nz, .clear_player_deck_loop
	; c = $00, so the following code will loop $100 times
	ld hl, wTempCardCollection
.clear_temp_card_collection_loop
	ld [hli], a
	dec c
	jr nz, .clear_temp_card_collection_loop
	call FindBoosterDataPointer
	ld de, wBoosterData_Set
	ld b, wBoosterData_TypeChances - wBoosterData_Set + NUM_BOOSTER_CARD_TYPES ; Pack2 - Pack1
	call CopyNBytesFromHLToDE ; load booster pack data to wram
	call LoadRarityAmountsToWram
	ld bc, $0
	lb de, NUM_BOOSTER_CARD_TYPES, NUM_BOOSTER_CARD_TYPES
	ld hl, wBoosterData_TypeChances
.add_chance_bytes_loop
	ld a, [hli]
	add c
	ld c, a
	dec d
	jr nz, .add_chance_bytes_loop
	; divide the sum of all type probabilities by the total number of booster card types (e.g. 160/9)
	call DivideBCbyDE
	ld a, c
	ld [wBoosterAveragedTypeChances], a
	ret


; gets the pointer to the data of the booster pack at [wBoosterPackID]
; preserves bc and de
; input:
;	[wBoosterPackID] = which booster pack variant (BOOSTER_*_* constant)
; output:
;	hl = data pointer for a BoosterPack_* entry from BoosterDataJumptable
FindBoosterDataPointer:
	push bc
	ld a, [wBoosterPackID]
	add a
	ld c, a
	ld b, $0
	ld hl, BoosterDataJumptable
	add hl, bc
	ld a, [hli]
	ld h, [hl]
	ld l, a
	pop bc
	ret

BoosterDataJumptable:
	table_width 2, BoosterDataJumptable
	dw BoosterPack_ColosseumNeutral
	dw BoosterPack_ColosseumGrass
	dw BoosterPack_ColosseumFire
	dw BoosterPack_ColosseumWater
	dw BoosterPack_ColosseumLightning
	dw BoosterPack_ColosseumFighting
	dw BoosterPack_ColosseumTrainer
	dw BoosterPack_EvolutionNeutral
	dw BoosterPack_EvolutionGrass
	dw BoosterPack_EvolutionNeutralFireEnergy
	dw BoosterPack_EvolutionWater
	dw BoosterPack_EvolutionFighting
	dw BoosterPack_EvolutionPsychic
	dw BoosterPack_EvolutionTrainer
	dw BoosterPack_MysteryNeutral
	dw BoosterPack_MysteryGrassColorless
	dw BoosterPack_MysteryWaterColorless
	dw BoosterPack_MysteryLightningColorless
	dw BoosterPack_MysteryFightingColorless
	dw BoosterPack_MysteryTrainerColorless
	dw BoosterPack_LaboratoryMostlyNeutral
	dw BoosterPack_LaboratoryGrass
	dw BoosterPack_LaboratoryWater
	dw BoosterPack_LaboratoryPsychic
	dw BoosterPack_LaboratoryTrainer
	dw BoosterPack_EnergyLightningFire
	dw BoosterPack_EnergyWaterFighting
	dw BoosterPack_EnergyGrassPsychic
	dw BoosterPack_RandomEnergies
	assert_table_length NUM_BOOSTERS


; loads rarity amounts of the booster pack set at [wBoosterData_Set] to wBoosterData*Amount
; preserves de
; input:
;	[wBoosterData_Set] = BOOSTER_* constant (0-3)
; output:
;	[wBoosterData_CommonAmount] = how many commons should be in a booster pack from that set (either 5 or 6)
;	[wBoosterData_UncommonAmount] = how many uncommons should be in a booster pack from that set (always 3)
;	[wBoosterData_RareAmount] = how many rares should be in a booster pack from that set (always 1)
LoadRarityAmountsToWram:
	ld a, [wBoosterData_Set]
	add a
	add a
	ld c, a
	ld b, $00
	ld hl, BoosterSetRarityAmountsTable
	add hl, bc
	inc hl
	ld a, [hli]
	ld [wBoosterData_CommonAmount], a
	ld a, [hli]
	ld [wBoosterData_UncommonAmount], a
	ld a, [hli]
	ld [wBoosterData_RareAmount], a
	ret


INCLUDE "data/booster_packs.asm"
