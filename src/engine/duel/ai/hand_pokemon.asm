; determines whether AI plays Pokémon cards from its hand.
; considers each Basic Pokémon and then moves on to the Evolution cards.
AIDecidePlayPokemonCard:
	call CreateHandCardList
	call SortTempHandByIDList
	ld hl, wDuelTempList
	ld de, wHandTempList
	call CopyListWithFFTerminatorFromHLToDE_Bank5
	ld hl, wHandTempList

.next_hand_card
	ld a, [hli]
	cp $ff
	jr z, AIDecideEvolution

	ld [wTempAIPokemonCard], a
	call CheckDeckIndexForBasicPokemon
	jr nc, .next_hand_card ; skip this card if it isn't a Basic Pokémon

	push hl
	ld a, 130
	ld [wAIScore], a
	call AIDecidePlayLegendaryBirds

; decrease the AI score if there are more than 4 play area Pokémon,
; and increase the AI score if there aren't.
	ld a, DUELVARS_NUMBER_OF_POKEMON_IN_PLAY_AREA
	get_turn_duelist_var
	cp 4
	jr c, .has_4_or_fewer
	ld a, 20
	call SubFromAIScore
	jr .check_defending_can_ko
.has_4_or_fewer
	ld a, 50
	call AddToAIScore

; increase the AI score if the Defending Pokémon can KO the AI's Active Pokémon.
.check_defending_can_ko
	xor a ; PLAY_AREA_ARENA
	ldh [hTempPlayAreaLocation_ff9d], a
	call CheckIfDefendingPokemonCanKnockOut
	jr nc, .check_energy_cards
	ld a, 20
	call AddToAIScore

; increase the AI score if there are Energy cards in the AI's hand
; that can be used for this Pokémon's attacks.
.check_energy_cards
	ld a, [wTempAIPokemonCard]
	call GetAttacksEnergyCostBits
	call CheckEnergyFlagsNeededInList
	jr nc, .check_evolution_hand
	ld a, 20
	call AddToAIScore

; increase the AI score if an Evolution card in the hand matches this Pokémon.
.check_evolution_hand
	ld a, [wTempAIPokemonCard]
	call CheckForEvolutionInList
	jr nc, .check_evolution_deck
	ld a, 20
	call AddToAIScore

; increase the AI score if an Evolution card in the deck matches this Pokémon.
.check_evolution_deck
	ld a, [wTempAIPokemonCard]
	call CheckForEvolutionInDeck
	jr nc, .check_score
	ld a, 10
	call AddToAIScore

; if AI score is >= 180, play this Basic Pokémon from the hand.
.check_score
	ld a, [wAIScore]
	cp 180
	jr c, .skip
	ld a, [wTempAIPokemonCard]
	ldh [hTemp_ffa0], a
	call CheckIfCardCanBePlayed
	jr c, .skip
	ld a, OPPACTION_PLAY_BASIC_PKMN
	bank1call AIMakeDecision
	jr c, .done ; return if the opponent's turn ended
.skip
	pop hl
	jr .next_hand_card
.done
	pop hl
	ret


; determines whether AI plays Evolution cards from its hand
; to evolve Pokémon in the play area.
AIDecideEvolution:
; check if Prehistoric Power is active
	call IsPrehistoricPowerActive
	ccf
	ret nc

	call CreateHandCardList
	ld hl, wDuelTempList
	ld de, wHandTempList
	call CopyListWithFFTerminatorFromHLToDE_Bank5
	ld hl, wHandTempList

.next_hand_card
	ld a, [hli]
	cp $ff
	ret z
	ld [wTempAIPokemonCard], a
	push hl

; load evolution data to buffer1.
; skip if it's not a Pokémon card or if its stage is Basic.
	call LoadCardDataToBuffer1_FromDeckIndex
	ld a, [wLoadedCard1Type]
	cp TYPE_ENERGY
	jp nc, .done_hand_card
	ld a, [wLoadedCard1Stage]
	or a ; cp BASIC
	jp z, .done_hand_card

; start looping Pokémon in the play area to find a card to evolve.
	ld a, DUELVARS_NUMBER_OF_POKEMON_IN_PLAY_AREA
	get_turn_duelist_var
	ld c, a
	ld b, PLAY_AREA_ARENA
.next_bench_pokemon
	ld e, b
	ld a, [wTempAIPokemonCard]
	ld d, a
	call CheckIfCanEvolveInto
	push bc
	jp c, .done_bench_pokemon

; store this play area location offset in wTempAI
; and initialize the AI score.
	ld a, b
	ld [wTempAI], a
	ldh [hTempPlayAreaLocation_ff9d], a
	ld a, $80
	ld [wAIScore], a
	call AIDecideSpecialEvolutions

; check if the card can use any attacks
; and if any of those attacks can KO.
	xor a ; FIRST_ATTACK_OR_PKMN_POWER
	ld [wSelectedAttack], a
	call CheckIfSelectedAttackIsUnusable
	jr nc, .can_attack
	ld a, SECOND_ATTACK
	ld [wSelectedAttack], a
	call CheckIfSelectedAttackIsUnusable
	jr c, .cant_attack_or_ko
.can_attack
	ld a, TRUE
	ld [wCurCardCanAttack], a
	call CheckIfAnyAttackKnocksOutDefendingCard
	jr nc, .check_evolution_attacks
	call CheckIfSelectedAttackIsUnusable
	jr c, .check_evolution_attacks
	ld a, TRUE
	ld [wCurCardCanKO], a
	jr .check_evolution_attacks
.cant_attack_or_ko
	xor a ; FALSE
	ld [wCurCardCanAttack], a
	ld [wCurCardCanKO], a

; check the Evolution card to see if it can use any of its attacks, and
; increase the AI score if it can. if it can't, then decrease the score, and
; if an Energy card that is needed can be played from the hand, then increase the score.
.check_evolution_attacks
	ldh a, [hTempPlayAreaLocation_ff9d]
	add DUELVARS_ARENA_CARD
	get_turn_duelist_var
	push af
	ld a, [wTempAIPokemonCard]
	ld [hl], a
	xor a ; FIRST_ATTACK_OR_PKMN_POWER
	ld [wSelectedAttack], a
	call CheckIfSelectedAttackIsUnusable
	jr nc, .evolution_can_attack
	ld a, SECOND_ATTACK
	ld [wSelectedAttack], a
	call CheckIfSelectedAttackIsUnusable
	jr c, .evolution_cant_attack
.evolution_can_attack
	ld a, 5
	call AddToAIScore
	jr .check_evolution_ko
.evolution_cant_attack
	ld a, [wCurCardCanAttack]
	or a
	jr z, .check_evolution_ko
	ld a, 2
	call SubFromAIScore
	ld a, [wAlreadyPlayedEnergy]
	or a
	jr nz, .check_evolution_ko
	call LookForEnergyNeededInHand
	jr nc, .check_evolution_ko
	ld a, 7
	call AddToAIScore

; if it's an Active Pokémon:
; decrease the AI score if the Evolution card can't KO but the current Pokémon can.
; increase the AI score if the Evolution card can also KO.
.check_evolution_ko
	ld a, [wCurCardCanAttack]
	or a
	jr z, .check_defending_can_ko_evolution
	ld a, [wTempAI]
	or a ; cp PLAY_AREA_ARENA
	jr nz, .check_defending_can_ko_evolution
	; it's the Active Pokémon
	call CheckIfActiveCardCanKnockOut
	jr nc, .evolution_cant_ko
	ld a, 5
	call AddToAIScore
	jr .check_defending_can_ko_evolution
.evolution_cant_ko
	ld a, [wCurCardCanKO]
	or a
	jr z, .check_defending_can_ko_evolution
	ld a, 20
	call SubFromAIScore

; decrease the AI score if the Defending Pokémon can still KO after evolution.
.check_defending_can_ko_evolution
	ld a, [wTempAI]
	or a
	jr nz, .check_mr_mime
	xor a ; PLAY_AREA_ARENA
	ldh [hTempPlayAreaLocation_ff9d], a
	call CheckIfDefendingPokemonCanKnockOut
	jr nc, .check_mr_mime
	ld a, 5
	call SubFromAIScore

; decrease the AI score if the Evolution card can't damage the Player's Mr Mime.
.check_mr_mime
	ld a, [wTempAI]
	call CheckDamageToMrMime
	jr c, .check_defending_can_ko
	ld a, 20
	call SubFromAIScore

; increase the AI score if the Defending Pokémon can KO the current card.
.check_defending_can_ko
	ld a, [wTempAI]
	add DUELVARS_ARENA_CARD
	get_turn_duelist_var
	pop af
	ld [hl], a
	ld a, [wTempAI]
	or a
	jr nz, .check_2nd_stage_hand
	xor a ; PLAY_AREA_ARENA
	ldh [hTempPlayAreaLocation_ff9d], a
	call CheckIfDefendingPokemonCanKnockOut
	jr nc, .check_status
	ld a, 5
	call AddToAIScore

; increase the AI score if the current card has a Special Condition.
.check_status
	ld a, DUELVARS_ARENA_CARD_STATUS
	get_turn_duelist_var
	or a ; cp NO_STATUS
	jr z, .check_2nd_stage_hand
	ld a, 4
	call AddToAIScore

; increase the AI score by 2 if there's a Stage 2 Evolution card
; in the hand that can be used to evolve this Evolution card.
.check_2nd_stage_hand
	ld a, [wTempAIPokemonCard]
	call CheckForEvolutionInList
	jr nc, .check_2nd_stage_deck
	ld a, 2
	call AddToAIScore
	jr .check_damage

; increase the AI score by 1 if there's a Stage 2 Evolution card
; in the deck that can be used to evolve this Evolution card.
.check_2nd_stage_deck
	ld a, [wTempAIPokemonCard]
	call CheckForEvolutionInDeck
	jr nc, .check_damage
	ld a, 1
	call AddToAIScore

; decrease AI score proportional to damage
; AI score -= floor(Damage / 40)
.check_damage
	ld a, [wTempAI]
	ld e, a
	call GetCardDamageAndMaxHP
	or a
	jr z, .check_mysterious_fossil
	srl a
	srl a
	call ConvertHPToDamageCounters_Bank5
	call SubFromAIScore

; increase the AI score if it's Mysterious Fossil
; or if wLoadedCard1Unknown2 is set to $02 (which is never true).
.check_mysterious_fossil
	ld a, [wTempAI]
	add DUELVARS_ARENA_CARD
	get_turn_duelist_var
	call LoadCardDataToBuffer1_FromDeckIndex
	cp MYSTERIOUS_FOSSIL
	jr z, .mysterious_fossil
	ld a, [wLoadedCard1Unknown2]
	cp $02
	jr nz, .pikachu_deck
	ld a, 2
	call AddToAIScore
	jr .pikachu_deck

.mysterious_fossil
	ld a, 5
	call AddToAIScore

; decrease the AI score for evolving Pikachu if using the Pikachu Deck.
.pikachu_deck
	ld a, [wOpponentDeckID]
	cp PIKACHU_DECK_ID
	jr nz, .check_score
	ld a, [wLoadedCard1ID]
	cp PIKACHU_LV12
	jr z, .pikachu
	cp PIKACHU_LV14
	jr z, .pikachu
	cp PIKACHU_LV16
	jr z, .pikachu
	cp PIKACHU_ALT_LV16
	jr nz, .check_score
.pikachu
	ld a, 3
	call SubFromAIScore

; if AI score >= 133, go through with the evolution.
.check_score
	ld a, [wAIScore]
	cp 133
	jr c, .done_bench_pokemon
	ld a, [wTempAI]
	ldh [hTempPlayAreaLocation_ffa1], a
	ld a, [wTempAIPokemonCard]
	ldh [hTemp_ffa0], a
	ld a, OPPACTION_EVOLVE_PKMN
	bank1call AIMakeDecision

	; disregard PlusPower attack choice if the Active Pokémon evolved
	ld a, [wTempAI]
	or a
	jr nz, .skip_reset_pluspower_atk
	ld hl, wPreviousAIFlags
	res 0, [hl] ; AI_FLAG_USED_PLUSPOWER
.skip_reset_pluspower_atk
	pop bc
	jr .done_hand_card

.done_bench_pokemon
	pop bc
	inc b
	dec c
	jp nz, .next_bench_pokemon
.done_hand_card
	pop hl
	jp .next_hand_card


; determines the AI score for evolving Charmeleon,
; Magikarp, Dragonair, and Grimer in certain decks.
; input:
;	[wLoadedCard2ID] = card ID of an evolving Pokémon to score
AIDecideSpecialEvolutions:
; check if deck applies
	ld a, [wOpponentDeckID]
	cp LEGENDARY_DRAGONITE_DECK_ID
	jr z, .legendary_dragonite
	cp INVINCIBLE_RONALD_DECK_ID
	jr z, .invincible_ronald
	cp LEGENDARY_RONALD_DECK_ID
	jr z, .legendary_ronald
	ret

.legendary_dragonite
	ld a, [wLoadedCard2ID]
	cp CHARMELEON
	jr z, .charmeleon
	cp MAGIKARP
	jr z, .magikarp
	cp DRAGONAIR
	jr z, .dragonair
	ret

; check if there are at least 3 Energy cards attached to Charmeleon and
; if adding the Energy cards in the hand brings the total to at least 6.
.charmeleon
	ldh a, [hTempPlayAreaLocation_ff9d]
	ld e, a
	call CountNumberOfEnergyCardsAttached
	cp 3
	jr c, .not_enough_energy
	push af
	call CreateEnergyCardListFromHand
	pop bc
	; a = number of Energy cards in hand
	add b
	cp 6
	jr c, .not_enough_energy
	ld a, 3
	jp AddToAIScore
.not_enough_energy
	ld a, 10
	jp SubFromAIScore

; check if Magikarp is not the Active Pokémon
; and has at least 2 Energy cards attached to it.
.magikarp
	ldh a, [hTempPlayAreaLocation_ff9d]
	or a ; cp PLAY_AREA_ARENA
	ret z
	ld e, a
	call CountNumberOfEnergyCardsAttached
	cp 2
	ret c
	ld a, 3
	jp AddToAIScore

.invincible_ronald
	ld a, [wLoadedCard2ID]
	cp GRIMER
	jr z, .grimer
	ret

; check if Grimer is not the Active Pokémon
.grimer
	ldh a, [hTempPlayAreaLocation_ff9d]
	or a ; cp PLAY_AREA_ARENA
	ret z
	ld a, 10
	jp AddToAIScore

.legendary_ronald
	ld a, [wLoadedCard2ID]
	cp DRAGONAIR
	jr z, .dragonair
	ret

.dragonair
	ldh a, [hTempPlayAreaLocation_ff9d]
	or a ; cp PLAY_AREA_ARENA
	jr z, .is_active

; if Dragonair is Benched, count the number of damage counters on each of the AI's Pokémon.
; decrease the AI score if there are fewer than 8 damage counters in the play area.
; otherwise, check if there's a Muk in either play area.
	ld a, DUELVARS_NUMBER_OF_POKEMON_IN_PLAY_AREA
	get_turn_duelist_var
	ld b, a
	ld c, 0 ; damage counter counter
	ld e, c ; PLAY_AREA_ARENA
.loop
	push bc
	call GetCardDamageAndMaxHP
	pop bc
	call ConvertHPToDamageCounters_Bank5
	add c
	ld c, a
	inc e
	dec b
	jr nz, .loop
	ld a, 7
	cp c
	jr c, .check_muk
.lower_score
	ld a, 10
	jp SubFromAIScore

; if Dragonair is the Active Pokémon, check its damage/HP.
; if this result is >= 50 and at least 3 Energy are attached,
; then check if there's a Muk in either play area.
.is_active
	ld e, PLAY_AREA_ARENA
	call GetCardDamageAndMaxHP
	cp 50
	jr c, .lower_score
	ld e, PLAY_AREA_ARENA
	call GetPlayAreaCardAttachedEnergies
;	ld a, [wTotalAttachedEnergies] ; already loaded
	cp 3
	jr c, .lower_score

; increase the AI score if there isn't a Muk in the play area.
.check_muk
	ld a, MUK
	call CountPokemonIDInBothPlayAreas
	jr c, .lower_score
	ld a, 10
	jp AddToAIScore


; determines the AI score for playing the promotional Articuno, Zapdos, and Moltres cards.
; input:
;	[wLoadedCard2ID] = card ID for the Pokémon being checked
AIDecidePlayLegendaryBirds:
; check if deck applies
	ld a, [wOpponentDeckID]
	cp LEGENDARY_ZAPDOS_DECK_ID
	jr z, .begin
	cp LEGENDARY_ARTICUNO_DECK_ID
	jr z, .begin
	cp LEGENDARY_RONALD_DECK_ID
	jr z, .begin
	ret

; check if card applies
.begin
	ld a, [wLoadedCard2ID]
	cp ARTICUNO_LV37
	jr z, .articuno
	cp MOLTRES_LV37
	jr z, .moltres
	cp ZAPDOS_LV68
	jr z, .zapdos
	ret

.articuno
	; exit if there aren't enough Pokémon in the play area
	ld a, DUELVARS_NUMBER_OF_POKEMON_IN_PLAY_AREA
	get_turn_duelist_var
	cp 2
	ret c

	call CheckIfActiveCardCanKnockOut
	jr c, .subtract
	call CheckIfActivePokemonCanUseAnyNonResidualAttack
	jr nc, .subtract
	call AIDecideWhetherToRetreat
	jr c, .subtract

	; check if the Defending Pokémon is Asleep, Confused, or Paralyzed
	ld a, DUELVARS_ARENA_CARD_STATUS
	call GetNonTurnDuelistVariable
	and CNF_SLP_PRZ
	or a
	jr nz, .subtract

	; check for a Defending Pokémon's Pokémon Power
	rst SwapTurn
	ld a, DUELVARS_ARENA_CARD
	get_turn_duelist_var
	ld d, a
	ld e, FIRST_ATTACK_OR_PKMN_POWER
	call CopyAttackDataAndDamage_FromDeckIndex
	rst SwapTurn
	ld a, [wLoadedAttackCategory]
	cp POKEMON_POWER
	jr z, .check_muk_and_snorlax

	; return if no space on the Bench
	ld a, DUELVARS_NUMBER_OF_POKEMON_IN_PLAY_AREA
	get_turn_duelist_var
	cp MAX_BENCH_POKEMON
	jr c, .check_muk_and_snorlax
	ret

.check_muk_and_snorlax
	; check for a Muk in either play area
	ld a, MUK
	call CountPokemonIDInBothPlayAreas
	jr c, .subtract
	; check if the Defending Pokémon is a Snorlax
	rst SwapTurn
	ld a, DUELVARS_ARENA_CARD
	get_turn_duelist_var
	call _GetCardIDFromDeckIndex
	rst SwapTurn
	cp SNORLAX
	jr z, .subtract

; add
	ld a, 70
	jp AddToAIScore

.moltres
	; check for a Muk in either play area
	ld a, MUK
	call CountPokemonIDInBothPlayAreas
	jr c, .subtract
	; check if there are enough cards in the deck
	ld a, DUELVARS_NUMBER_OF_CARDS_NOT_IN_DECK
	get_turn_duelist_var
	cp 56 ; max number of cards not in deck to activate
	ret c
.subtract
	ld a, 100
	jp SubFromAIScore

.zapdos
	; check for a Muk in either play area
	ld a, MUK
	call CountPokemonIDInBothPlayAreas
	jr c, .subtract
	ret
