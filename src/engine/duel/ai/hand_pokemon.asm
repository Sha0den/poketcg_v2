; determines whether AI plays Pokémon cards from its hand.
; considers each Basic Pokémon and then moves on to the Evolution cards.
; output:
;	carry = set:  if the AI's turn ended
AIDecidePlayPokemonCard:
; don't bother looking at Basic Pokémon if there's no room on the Bench.
	ld a, DUELVARS_NUMBER_OF_POKEMON_IN_PLAY_AREA
	get_turn_duelist_var
	cp MAX_PLAY_AREA_POKEMON
	jp nc, AIDecideEvolution

; create a list of the cards in the AI's hand and sort it using the deck-specific
; priority list found at wAICardListPlayFromHandPriority, if one exists.
	call CreateHandCardList
	call SortTempHandByIDList
	ld hl, wDuelTempList
	ld de, wHandTempList
	call CopyListWithFFTerminatorFromHLToDE_Bank5
	ld hl, wHandTempList

.next_hand_card
	ld a, [hli]
	cp $ff
	jr z, AIDecideEvolution ; begin checking Evolution cards if every Basic Pokémon in the hand has been processed

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
	call AIDiscourage
	jr .check_defending_can_ko
.has_4_or_fewer
	ld a, 50
	call AIEncourage

; increase the AI score if the Defending Pokémon can KO the AI's Active Pokémon.
.check_defending_can_ko
	xor a ; PLAY_AREA_ARENA
	ldh [hTempPlayAreaLocation_ff9d], a
	call CheckIfDefendingPokemonCanKnockOut
	ld a, 20
	call c, AIEncourage ; add 20 if the current Active Pokémon might be KO'd next turn

; increase the AI score if there are Energy cards in the AI's hand
; that can be used for this Pokémon's attacks.
	ld a, [wTempAIPokemonCard]
	call GetAttacksEnergyCostBits
	call CheckEnergyFlagsNeededInList
	ld a, 20
	call c, AIEncourage ; add 20 if there's relevant Energy cards in the hand

; increase the AI score if an Evolution card in the hand matches this Pokémon.
	ld a, [wTempAIPokemonCard]
	call CheckForEvolutionInList
	jr nc, .check_evolution_deck
	ld a, 20
	call AIEncourage
	jr .check_score

; increase the AI score if an Evolution card in the deck matches this Pokémon.
.check_evolution_deck
	ld a, [wTempAIPokemonCard]
	call CheckForEvolutionInDeck
	ld a, 10
	call c, AIEncourage ; add 10 if there's a relevant Evolution card in the deck

; if AI score is >= 180, play this Basic Pokémon from the hand.
.check_score
	pop hl
	ld a, [wAIScore]
	cp 180
	jr c, .next_hand_card
	ld a, [wTempAIPokemonCard]
	ldh [hTemp_ffa0], a
	ld a, OPPACTION_PLAY_BASIC_PKMN
	push hl
	bank1call AIMakeDecision
	pop hl
	ret c ; return if the opponent's turn ended
	ld a, DUELVARS_NUMBER_OF_POKEMON_IN_PLAY_AREA
	push hl
	get_turn_duelist_var
	pop hl
	cp MAX_PLAY_AREA_POKEMON
	jr c, .next_hand_card
;	fallthrough if the Bench is now full

; determines whether AI plays Evolution cards
; from its hand to evolve Pokémon in the play area.
; output:
;	carry = set:  if the AI's turn ended
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
	ret z ; return no carry once every card in the hand has been checked
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
.loop_play_area
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
	xor a
	ld [wCurCardCanAttack], a ; FALSE
	ld [wCurCardCanKO], a ; FALSE
	ld [wSelectedAttack], a ; FIRST_ATTACK_OR_PKMN_POWER
	call CheckIfSelectedAttackIsUnusable
	jr nc, .can_attack
	ld a, SECOND_ATTACK
	ld [wSelectedAttack], a
	call CheckIfSelectedAttackIsUnusable
	jr c, .check_evolution_attacks
.can_attack
	ld a, TRUE
	ld [wCurCardCanAttack], a
	call CheckIfAnyAttackKnocksOutDefendingCard
	jr nc, .check_evolution_attacks
	call CheckIfSelectedAttackIsUnusable
	jr c, .check_evolution_attacks
	ld a, TRUE
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
	call AIEncourage
	jr .check_evolution_ko
.evolution_cant_attack
	ld a, [wCurCardCanAttack]
	or a
	jr z, .check_evolution_ko
	ld a, 2
	call AIDiscourage
	ld a, [wOncePerTurnFlags]
	and PLAYED_ENERGY_THIS_TURN
	jr nz, .check_evolution_ko
	call LookForEnergyNeededInHand
	ld a, 7
	call c, AIEncourage ; add 7 if the required Energy card is in the hand

; if it's an Active Pokémon:
; decrease the AI score if the Evolution card can't KO but the current Pokémon can.
; increase the AI score if the Evolution card can also KO.
.check_evolution_ko
	ld a, [wTempAI]
	or a ; cp PLAY_AREA_ARENA
	jr nz, .check_defending_can_ko_evolution
	; it's the Active Pokémon
	call CheckIfActiveCardCanKnockOut
	jr nc, .evolution_cant_ko
	ld a, 5
	call AIEncourage
	jr .check_defending_can_ko_evolution
.evolution_cant_ko
	ld a, [wCurCardCanKO]
	or a
	ld a, 20
	call nz, AIDiscourage ; subtract 20 if evolving will prevent a KO

; decrease the AI score if the Defending Pokémon can still KO after evolution.
.check_defending_can_ko_evolution
	ld a, [wTempAI]
	or a ; cp PLAY_AREA_ARENA
	jr nz, .check_mr_mime
	ldh [hTempPlayAreaLocation_ff9d], a ; PLAY_AREA_ARENA
	call CheckIfDefendingPokemonCanKnockOut
	ld a, 5
	call c, AIDiscourage ; subtract 5 if it might be KO'd next turn

; decrease the AI score if the Evolution card can't damage the Player's Mr Mime.
.check_mr_mime
	ld a, [wTempAI]
	call CheckDamageToMrMime
	ld a, 20
	call nc, AIDiscourage ; subtract 20 if it can't damage opposing Mr. Mime

; increase the AI score if the Defending Pokémon can KO the current card.
	ld a, [wTempAI]
	add DUELVARS_ARENA_CARD
	get_turn_duelist_var
	pop af
	ld [hl], a
	ld a, [wTempAI]
	or a ; cp PLAY_AREA_ARENA
	jr nz, .check_2nd_stage_hand
	ldh [hTempPlayAreaLocation_ff9d], a ; PLAY_AREA_ARENA
	call CheckIfDefendingPokemonCanKnockOut
	ld a, 5
	call c, AIEncourage ; add 5 if pre-evolution might be KO'd next turn

; increase the AI score if the current card is affected by a Special Condition.
	ld a, DUELVARS_ARENA_CARD_STATUS
	get_turn_duelist_var
	or a ; cp NO_STATUS
	ld a, 4
	call nz, AIEncourage ; add 4 if evolving will heal 1 or more Special Conditions

; increase the AI score if the current card is affected by a negative attack effect.
	ld a, DUELVARS_ARENA_CARD_SUBSTATUS2
	get_turn_duelist_var
	or a
	ld a, 3
	call nz, AIEncourage ; add 3 if evolving will heal a harmful substatus

; increase the AI score by 2 if there's a Stage 2 Evolution card
; in the hand that can be used to evolve this Evolution card.
.check_2nd_stage_hand
	ld a, [wTempAIPokemonCard]
	call CheckForEvolutionInList
	jr nc, .check_2nd_stage_deck
	ld a, 2
	call AIEncourage
	jr .check_damage

; increase the AI score by 1 if there's a Stage 2 Evolution card
; in the deck that can be used to evolve this Evolution card.
.check_2nd_stage_deck
	ld a, [wTempAIPokemonCard]
	call CheckForEvolutionInDeck
	ld a, 1
	call c, AIEncourage ; add 1 if next evolution is in the deck

; decrease AI score proportional to damage
; AI score -= floor(Damage / 40)
.check_damage
	ld a, [wTempAI]
	ld e, a
	call GetCardDamageAndMaxHP
	or a
	jr z, .check_mysterious_fossil
	srl a ; /2
	srl a ; /4
	call ConvertHPToDamageCounters_Bank5
	call AIDiscourage

; increase the AI score by 5 if it's Mysterious Fossil
; or by 2 if this Pokémon's AI_ENCOURAGE_EVOLUTION flag is set.
.check_mysterious_fossil
	ld a, [wTempAI]
	add DUELVARS_ARENA_CARD
	get_turn_duelist_var
	call LoadCardDataToBuffer1_FromDeckIndex
	cp MYSTERIOUS_FOSSIL
	jr z, .mysterious_fossil
	ld a, [wLoadedCard1PokemonFlags]
	and AI_ENCOURAGE_EVOLUTION
	ld a, 2
	call nz, AIEncourage ; add 2 if flag is set
	jr .pikachu_deck

.mysterious_fossil
	ld a, 5
	call AIEncourage

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
	call AIDiscourage

; if AI score >= 133 (initial score of 128 plus 5), go through with the evolution.
.check_score
	ld a, [wAIScore]
	cp $85
	jr c, .done_bench_pokemon
	ld a, [wTempAI]
	ldh [hTempPlayAreaLocation_ffa1], a
	ld a, [wTempAIPokemonCard]
	ldh [hTemp_ffa0], a
	ld a, OPPACTION_EVOLVE_PKMN
	bank1call AIMakeDecision

	; disregard PlusPower attack choice if the Active Pokémon evolved
	ld a, [wTempAI]
	or a ; cp PLAY_AREA_ARENA
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
	jp nz, .loop_play_area
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
	jp AIEncourage
.not_enough_energy
	ld a, 10
	jp AIDiscourage

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
	jp AIEncourage

.invincible_ronald
	ld a, [wLoadedCard2ID]
	cp GRIMER
	ret nz

; check if Grimer is not the Active Pokémon
.grimer
	ldh a, [hTempPlayAreaLocation_ff9d]
	or a ; cp PLAY_AREA_ARENA
	ret z
.raise_score
	ld a, 10
	jp AIEncourage

.legendary_ronald
	ld a, [wLoadedCard2ID]
	cp DRAGONAIR
	ret nz

.dragonair
	ldh a, [hTempPlayAreaLocation_ff9d]
	ld e, a
	call AIDecidePlayLegendaryDragonite
	jr nc, .raise_score
	ld a, 10
	jp AIDiscourage


; if evolving the Active Pokémon, checks whether DragoniteLv41 would be able to attack.
; if that check fails or if it's evolving a Benched Pokémon, then only play DragoniteLv41
; if its Healing Wind power would remove at least 6 damage counters from the play area.
; input:
;	e = play area location offset of the Pokémon being evolved (PLAY_AREA_* constant)
; output:
;	carry = set:  if DragoniteLv41 is evolving the Active Pokémon and it wouldn't have enough Energy to attack
;	           OR if fewer than 6 damage counters would be removed by DragoniteLv41's Healing Wind power
AIDecidePlayLegendaryDragonite:
; check whether DragoniteLv41 is being used to evolve the Active Pokémon.
	ld a, e
	or a ; cp PLAY_AREA_ARENA
	jr nz, .not_active

	call GetPlayAreaCardAttachedEnergies
;	ld a, [wTotalAttachedEnergies] ; already loaded
	cp 3
	ret nc ; return no carry if at least 3 Energy are attached

.not_active
	call CheckIfPkmnPowersAreCurrentlyDisabled
	ret c ; return carry if DragoniteLv41's Pokémon Power would be negated

; count the number of damage counters on each of the AI's Pokémon.
	ld b, 0 ; initial counter for number of damage counters in play area that will be removed
	ld a, DUELVARS_NUMBER_OF_POKEMON_IN_PLAY_AREA
	get_turn_duelist_var
	ld d, a
	ld e, b ; PLAY_AREA_ARENA
.loop
	call GetCardDamageAndMaxHP
	call ConvertHPToDamageCounters_Bank5
	or a
	jr z, .next ; skip this Pokémon if it doesn't have any damage counters
	cp 2
	jr c, .add_damage ; don't cap if there's only 1 damage counter
	ld a, 2 ; maximum number of damage counters removed by Healing Wind
.add_damage
	add b
	ld b, a
.next
	inc e
	dec d
	jr nz, .loop

; return no carry if at least 6 damage counters will be removed. otherwise, carry.
	cp 6
	ret


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
	ret nz ; return if the AI isn't using any of the listed decks

; check if card applies
.begin
	ld a, [wLoadedCard2ID]
	cp ZAPDOS_LV68
	jr z, .zapdos
	cp MOLTRES_LV37
	jr z, .moltres
	cp ARTICUNO_LV37
	ret nz ; return if this card isn't one of the Legendary Basic Pokémon

.articuno
	ld a, DUELVARS_NUMBER_OF_POKEMON_IN_PLAY_AREA
	get_turn_duelist_var
	dec a ; cp 1
	ret z ; return without adjusting score if there are no Benched Pokémon

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
	jr z, .check_if_quickfreeze_power_can_be_used

	; return if Bench space is limited
	ld a, DUELVARS_NUMBER_OF_POKEMON_IN_PLAY_AREA
	get_turn_duelist_var
	cp MAX_PLAY_AREA_POKEMON - 1
	ret nc

.check_if_quickfreeze_power_can_be_used
	; check if Articuno's Quickfreeze power can be used
	call CheckIfPkmnPowersAreCurrentlyDisabled
	jr c, .subtract
	; check if the Defending Pokémon is able to be Paralyzed
	rst SwapTurn
	call CheckIfActiveCardCanBeAffectedByStatus
	rst SwapTurn
	jr nc, .subtract

; add
	ld a, 70
	jp AIEncourage

.moltres
	; check if Moltres's Firegiver power can be used
	call CheckIfPkmnPowersAreCurrentlyDisabled
	jr c, .subtract
	; check if there are enough cards in the deck
	ld a, DUELVARS_NUMBER_OF_CARDS_NOT_IN_DECK
	get_turn_duelist_var
	cp 56 ; max number of cards not in deck to activate
	ret c
.subtract
	ld a, 100
	jp AIDiscourage

.zapdos
	; check if Zapdos's Peal of Thunder power can be used
	call CheckIfPkmnPowersAreCurrentlyDisabled
	jr c, .subtract
	ret
