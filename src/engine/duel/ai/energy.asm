; AI decides whether to play an Energy card from their hand and
; determines which Pokémon to attach it to. If a Pokémon was selected,
; it will then try to attach an Energy card from its hand to that Pokémon.
; output:
;	carry = set:  if an Energy card was played from the hand
AIProcessAndTryToPlayEnergy:
	xor a
	ld [wAIEnergyAttachLogicFlags], a
.has_logic_flags
	call CreateEnergyCardListFromHand
	jr nc, AIProcessEnergyCards
	; no Energy cards to play
	ld a, [wAIEnergyAttachLogicFlags]
	or a
	jp nz, RetrievePlayAreaAIScoreFromBackup
	ret


; AI chooses an Energy card to play, but does not play it.
; does not consider whether the Pokémon have evolutions to be played.
; output:
;	carry = set:  if the AI chose a play area Pokémon to attach a potential Energy card to
;	[hTempPlayAreaLocation_ff9d] = that Pokémon's play area location offset (PLAY_AREA_* constant)
AIProcessButDontPlayEnergy_SkipEvolution:
	ld a, AI_ENERGY_FLAG_DONT_PLAY | AI_ENERGY_FLAG_SKIP_EVOLUTION
	jr AIProcessButDontPlayEnergy_SkipEvolutionAndArena.load_flags


; AI chooses an Energy card to play, but does not play it.
; does not consider whether the Pokémon have evolutions to be played
; and will only decide to attach an Energy card to a Benched Pokémon.
; output:
;	carry = set:  if the AI chose a Benched Pokémon to attach a potential Energy card to
;	[hTempPlayAreaLocation_ff9d] = that Pokémon's play area location offset (PLAY_AREA_* constant)
AIProcessButDontPlayEnergy_SkipEvolutionAndArena:
	ld a, AI_ENERGY_FLAG_DONT_PLAY | AI_ENERGY_FLAG_SKIP_EVOLUTION | AI_ENERGY_FLAG_SKIP_ARENA_CARD
.load_flags
	ld [wAIEnergyAttachLogicFlags], a

; backup wPlayAreaAIScore in wTempPlayAreaAIScore.
	ld hl, wPlayAreaAIScore
	ld de, wTempPlayAreaAIScore
	ld b, MAX_PLAY_AREA_POKEMON
	call CopyNBytesFromHLToDE
	ld a, [wAIScore]
	ld [de], a
;	fallthrough

; AI decides whether to play an Energy card from their hand
; and determines which Pokémon to attach it to.
AIProcessEnergyCards:
; initialize the play area AI score
	ld a, $80
	ld b, MAX_PLAY_AREA_POKEMON
	ld hl, wPlayAreaEnergyAIScore
.loop
	ld [hli], a
	dec b
	jr nz, .loop

; Legendary Articuno Deck has its own Energy card logic
	ld a, [wOpponentDeckID]
	cp LEGENDARY_ARTICUNO_DECK_ID
	jp z, ScoreLegendaryArticunoCards

; start the main play area loop
	ld b, PLAY_AREA_ARENA
	ld a, DUELVARS_NUMBER_OF_POKEMON_IN_PLAY_AREA
	get_turn_duelist_var
	ld c, a

.loop_play_area
	push bc
	ld a, b
	ldh [hTempPlayAreaLocation_ff9d], a
	ld a, $80
	ld [wAIScore], a
	ld a, -1
	ld [wTempAI], a
	ld a, [wAIEnergyAttachLogicFlags]
	and AI_ENERGY_FLAG_SKIP_EVOLUTION
	jr nz, .check_venusaur

; check if the needed Energy is found in the hand
; and if there's an evolution in the hand or deck.
; increase the AI score if both are true.
	call CreateHandCardList
	ldh a, [hTempPlayAreaLocation_ff9d]
	add DUELVARS_ARENA_CARD
	get_turn_duelist_var
	ld [wCurCardCanAttack], a
	call GetAttacksEnergyCostBits
	call CheckEnergyFlagsNeededInList
	jp nc, .store_score
	ld a, [wCurCardCanAttack]
	call CheckForEvolutionInList
	jr nc, .no_evolution_in_hand
	ld [wTempAI], a ; store the Evolution card
	ld a, 2
	call AIEncourage
	jr .check_venusaur

.no_evolution_in_hand
	ld a, [wCurCardCanAttack]
	call CheckForEvolutionInDeck
	ld a, 1
	call c, AIEncourage ; add 1 if there's a relevant Evolution card in the deck

; if there's a VenusaurLv67 in the AI's play area with
; an active Energy Trans, then increase the AI score by 1.
.check_venusaur
	call CheckIfPkmnPowersAreCurrentlyDisabled
	jr c, .check_if_active
	ld a, VENUSAUR_LV67
	call CountTurnDuelistPokemonWithActivePkmnPower
	ld a, 1
	call c, AIEncourage ; add 1 if Energy Trans is active

.check_if_active
	ldh a, [hTempPlayAreaLocation_ff9d]
	or a ; cp PLAY_AREA_ARENA
	jr nz, .bench

; arena
	ld a, [wAIBarrierFlagCounter]
	bit AI_MEWTWO_MILL_F, a
	jr z, .add_to_score

; decrease the AI score by 5 if the Player is running a MewtwoLv53 mill deck.
	ld a, 5
	call AIDiscourage

; decrease the AI score by 10 if the Defending Pokémon can KO the AI's Active Pokémon.
.check_defending_can_ko
	call CheckIfDefendingPokemonCanKnockOut
	jr nc, .ai_score_bonus
	ld a, 10
	call AIDiscourage

; if either poison damage or the Defending Pokémon will KO,
; check if there are any Benched Pokémon,
; and if there are not, then increase the AI score by 6.
.check_bench
	ld a, DUELVARS_NUMBER_OF_POKEMON_IN_PLAY_AREA
	get_turn_duelist_var
	dec a ; cp 1
	ld a, 6
	call z, AIEncourage ; add 6 if there are no Pokémon on the Bench
	jr .ai_score_bonus

; increase the AI score by 4 if the Player isn't running a MewtwoLv53 mill deck.
.add_to_score
	ld a, 4
	call AIEncourage

; decrease the AI score by 10 if poison damage will
; KO the AI's Active Pokémon at the end of the turn.
	ld a, DUELVARS_ARENA_CARD_HP
	get_turn_duelist_var
	call ConvertHPToDamageCounters_Bank5
	cp 3
	jr nc, .check_defending_can_ko
	; hp < 30
	cp 2
	jr z, .has_20_hp
	; hp = 10
	ld a, DUELVARS_ARENA_CARD_STATUS
	get_turn_duelist_var
	and POISONED
	jr z, .check_defending_can_ko
	jr .poison_will_ko
.has_20_hp
	ld a, DUELVARS_ARENA_CARD_STATUS
	get_turn_duelist_var
	and DOUBLE_POISONED
	jr z, .check_defending_can_ko
.poison_will_ko
	ld a, 10
	call AIDiscourage
	jr .check_bench

; decrease the AI score by 3 - (bench HP)/10
; if the Benched Pokémon's HP < 30
.bench
	add DUELVARS_ARENA_CARD_HP
	get_turn_duelist_var
	call ConvertHPToDamageCounters_Bank5
	cp 3
	jr nc, .ai_score_bonus
; hp < 30
	ld b, a
	ld a, 3
	sub b
	call AIDiscourage

; check list in wAICardListEnergyBonus
.ai_score_bonus
	ld hl, wAICardListEnergyBonus
	ld a, [hli]
	ld h, [hl]
	ld l, a
	or h
	jr z, .check_boss_deck ; skip if pointer is null

	push hl
	ldh a, [hTempPlayAreaLocation_ff9d]
	add DUELVARS_ARENA_CARD
	get_turn_duelist_var
	call GetCardIDFromDeckIndex
	pop hl

.loop_id_list
	ld a, [hli]
	or a
	jr z, .check_boss_deck
	cp e
	jr nz, .next_id

	; number of attached Energy cards
	ld a, [hli]
	ld d, a
	push de
	ldh a, [hTempPlayAreaLocation_ff9d]
	ld e, a
	call GetPlayAreaCardAttachedEnergies
;	ld a, [wTotalAttachedEnergies] ; already loaded
	pop de
	cp d
	jr c, .check_id_score
	; already reached target number of Energy cards
	ld a, 10
	call AIDiscourage
	jr .check_boss_deck

.next_id
	inc hl
	inc hl
	jr .loop_id_list

.check_id_score
	ld a, [hli]
	cp $80
	jr c, .decrease_score_1
	sub $80
	call AIEncourage
	jr .check_boss_deck

.decrease_score_1
	ld d, a
	ld a, $80
	sub d
	call AIDiscourage

; if it's a boss deck, then call HandleAIEnergyScoringForRepeatedBenchPokemon and
; apply the values to the AI score determined for this card.
.check_boss_deck
	call CheckIfNotABossDeckID
	jr c, .skip_boss_deck

	call HandleAIEnergyScoringForRepeatedBenchPokemon

	; applies wPlayAreaEnergyAIScore
	ldh a, [hTempPlayAreaLocation_ff9d]
	ld c, a
	ld b, $00
	ld hl, wPlayAreaEnergyAIScore
	add hl, bc
	ld a, [hl]
	cp $80
	jr c, .decrease_score_2
	sub $80
	call AIEncourage
	jr .skip_boss_deck

.decrease_score_2
	ld b, a
	ld a, $80
	sub b
	call AIDiscourage

.skip_boss_deck
	ld a, 1
	call AIEncourage

; increase the AI score for both attacks,
; according to their Energy requirements.
	xor a ; FIRST_ATTACK_OR_PKMN_POWER
	call DetermineAIScoreOfAttackEnergyRequirement
	ld a, SECOND_ATTACK
	call DetermineAIScoreOfAttackEnergyRequirement

; store bench score for this card.
.store_score
	ldh a, [hTempPlayAreaLocation_ff9d]
	ld c, a
	ld b, $00
	ld hl, wPlayAreaAIScore
	add hl, bc
	ld a, [wAIScore]
	ld [hl], a
	pop bc
	inc b
	dec c
	jp nz, .loop_play_area

; the play area loop is over and the score for each card has been calculated.
; now to determine the highest score and decide whether to play an Energy card.
	call FindPlayAreaCardWithHighestAIScore
	jr nc, .not_found

	ld a, [wAIEnergyAttachLogicFlags]
	or a
	jr z, .play_card
	scf
	jp RetrievePlayAreaAIScoreFromBackup

.play_card
	call CreateEnergyCardListFromHand
	jp AITryToPlayEnergyCard

; there was no suitable Pokémon to attach an Energy card to, so return no carry
; after determining whether or not any backup AI play area scores need to be loaded.
.not_found
	ld a, [wAIEnergyAttachLogicFlags]
	or a
	ret z
	jp RetrievePlayAreaAIScoreFromBackup


; checks score related to the given attack, in order to determine whether to play an Energy card.
; the AI score is increased/decreased accordingly.
; input:
;	a = which attack to check (0 = first attack, 1 = second attack)
;	[hTempPlayAreaLocation_ff9d] = this Pokémon's play area location offset (PLAY_AREA_* constant)
;	[wTempAI] = deck index of a card that evolves from this Pokémon in the AI's hand (0-59, -1 if none)
DetermineAIScoreOfAttackEnergyRequirement:
	ld [wSelectedAttack], a
	call CheckEnergyNeededForAttack
	jr c, .not_enough_energy
	ld a, ATTACK_FLAG2_ADDRESS | ATTACHED_ENERGY_BOOST_F
	call CheckLoadedAttackFlag
	jr c, .attached_energy_boost
	ld a, ATTACK_FLAG2_ADDRESS | DISCARD_ENERGY_F
	call CheckLoadedAttackFlag
	jr c, .discard_energy
	jp .check_evolution

.attached_energy_boost
	ld a, [wLoadedAttackEffectParam]
	cp MAX_ENERGY_BOOST_IS_LIMITED
	jr z, .check_surplus_energy

	; is MAX_ENERGY_BOOST_IS_NOT_LIMITED,
	; which is equal to 3, so increase the AI score by that amount.
	call AIEncourage
	jp .check_evolution

.check_surplus_energy
	call CheckIfNoSurplusEnergyForAttack
	jr c, .asm_166cd
	cp 3 ; check amount of surplus Energy
	jr c, .asm_166cd

; decrease the AI score by 5 if there is too much Energy attached to this Pokémon.
; the attack either has a limited Energy Boost (e.g. Water Gun) and 3+ extra Energy are already attached
; or an Energy discard cost (e.g. Flamethrower) and 1 or more extra Energy are already attached.
.asm_166c5
	ld a, 5
	call AIDiscourage
	jp .check_evolution

; increase the AI score by 2 if the Pokémon doesn't have extra attached Energy or
; if it does have surplus Energy but the amount of attached Energy is less than 3.
.asm_166cd
	ld a, 2
	call AIEncourage

; check whether the selected attack has the ATTACHED_ENERGY_BOOST flag and
; increase the AI score by 20 if attaching another Energy will KO the Defending Pokémon.
; increase the score by another 10 if it's the Active Pokémon that is being checked.
	ld a, ATTACK_FLAG2_ADDRESS | ATTACHED_ENERGY_BOOST_F
	call CheckLoadedAttackFlag
	jp nc, .check_evolution
	ld a, [wSelectedAttack]
	call EstimateDamage_VersusDefendingCard
	ld a, DUELVARS_ARENA_CARD_HP
	call GetNonTurnDuelistVariable
	dec a ; subtract 1 so carry will be set if final HP = 0
	ld hl, wDamage
	sub [hl]
	jp c, .check_evolution ; skip ahead if the attack can KO the Defending Pokémon
	ld a, [wDamage]
	add 10 + 1 ; boost gained by attaching another Energy card plus 1 (so carry will be set if final HP = 0)
	ld b, a
	ld a, DUELVARS_ARENA_CARD_HP
	call GetNonTurnDuelistVariable
	sub b
	jr nc, .check_evolution ; skip ahead if the attack still won't KO

.attaching_kos_player
	ld a, 20
	call AIEncourage
	ldh a, [hTempPlayAreaLocation_ff9d]
	or a ; cp PLAY_AREA_ARENA
	ld a, 10
	call z, AIEncourage ; add 10 if this is the Active Pokémon
	jr .check_evolution

; checks if there is surplus Energy for an attack that requires discarding attached Energy.
; if the current card is ZapdosLv64, don't increase the score.
; if there is no surplus Energy, encourage playing an Energy card.
.discard_energy
	ld a, [wLoadedCard1ID]
	cp ZAPDOS_LV64
	jr z, .check_evolution
	call CheckIfNoSurplusEnergyForAttack
	jr c, .asm_166cd
	jr .asm_166c5

; decrease the AI score if the IGNORE_THIS_ATTACK flag is set. (Magnetic Storm and Prophecy)
.not_enough_energy
	ld a, ATTACK_FLAG2_ADDRESS | IGNORE_THIS_ATTACK_F
	call CheckLoadedAttackFlag
	ld a, 5
	call c, AIDiscourage ; subtract 5 if this flag is set

; if there is an Energy card in the hand that provides the needed type/color,
; or if Colorless Energy is needed, then increase the AI score.
;	call CheckEnergyNeededForAttack
	ld a, b
	or a
	jr z, .check_colorless_needed
	call GetEnergyCardNeeded
	call LookForCardIDInHand
	jr c, .check_colorless_needed
	ld a, 4
	call AIEncourage
	jr .check_total_needed
.check_colorless_needed
	ld a, c
	or a
	jr z, .check_evolution
	ld a, 3
	call AIEncourage

; increase the AI score by 3 if only one Energy card is needed for the attack.
.check_total_needed
	ld a, b
	add c
	dec a
	jr nz, .check_evolution
	ld a, 3
	call AIEncourage

; increase the AI score by 20 if the attack KOs the Defending Pokémon.
	ld a, [wSelectedAttack]
	call EstimateDamage_VersusDefendingCard
	ld a, DUELVARS_ARENA_CARD_HP
	call GetNonTurnDuelistVariable
	dec a ; subtract 1 so carry will be set if final HP = 0
	ld hl, wDamage
	sub [hl]
	jr nc, .check_evolution ; skip ahead if the attack won't KO
.atk_kos_defending
	ld a, 20
	call AIEncourage

; add 10 more in case it's the Active Pokémon
	ldh a, [hTempPlayAreaLocation_ff9d]
	or a ; cp PLAY_AREA_ARENA
	ld a, 10
	call z, AIEncourage ; add 10 if this is the Active Pokémon

.check_evolution
	ld a, [wTempAI] ; deck index of evolution in hand
	cp -1
	ret z

; temporarily replace this card with the Evolution card from the hand.
	ld b, a
	ldh a, [hTempPlayAreaLocation_ff9d]
	add DUELVARS_ARENA_CARD
	get_turn_duelist_var
	push af
	ld [hl], b

; check for Energy still needed for the evolution to attack.
; as long as the IGNORE_THIS_ATTACK flag is not set, check what type/color is needed.
; if there is an Energy card in the hand that provides the needed type/color,
; or if Colorless Energy is needed, then increase the AI score.
	call CheckEnergyNeededForAttack
	jr nc, .done
	ld a, ATTACK_FLAG2_ADDRESS | IGNORE_THIS_ATTACK_F
	call CheckLoadedAttackFlag
	jr c, .done
	ld a, b
	or a
	jr z, .check_colorless_needed_evo
	call GetEnergyCardNeeded
	call LookForCardIDInHand
	jr c, .check_colorless_needed_evo
	ld a, 2
	call AIEncourage
	jr .done
.check_colorless_needed_evo
	ld a, c
	or a
	ld a, 1
	call nz, AIEncourage ; add 1 if Colorless Energy is needed to attack

; recover the original card in that play area location.
.done
	ldh a, [hTempPlayAreaLocation_ff9d]
	add DUELVARS_ARENA_CARD
	get_turn_duelist_var
	pop af
	ld [hl], a
	ret


; finds the Pokémon with the highest AI play area score, unless highest score < $85.
; if AI_ENERGY_FLAG_SKIP_ARENA_CARD is set in wAIEnergyAttachLogicFlags,
; it doesn't include the Active Pokémon and there's no minimum score value.
; output:
;	a/d/[hTempPlayAreaLocation_ff9d] = play area location offset of the Pokémon with the highest
;	                                   AI play area score:  if either set carry condition was true
;	carry = set:  if the Active Pokémon was included and there was a play area score >= $85
;	           OR if the Active Pokémon was ignored and there's at least 1 Benched Pokémon
FindPlayAreaCardWithHighestAIScore:
	ld a, [wAIEnergyAttachLogicFlags]
	and AI_ENERGY_FLAG_SKIP_ARENA_CARD
	jr nz, .only_bench

	ld a, DUELVARS_NUMBER_OF_POKEMON_IN_PLAY_AREA
	get_turn_duelist_var
	ld b, a
	ld c, PLAY_AREA_ARENA
	ld d, c
	ld e, c ; initial highest play area score = 0
	ld hl, wPlayAreaAIScore
; find the highest play area AI score.
	call .loop
; if highest AI score is below $85, return no carry.
; else, store the play area location offset and return carry.
	ld a, e
	cp $85
	ccf
	ret nc ; return if the score is insufficient
	ld a, d
	ldh [hTempPlayAreaLocation_ff9d], a
	scf
	ret

; same as above but only check Benched Pokémon scores.
.only_bench
	ld a, DUELVARS_NUMBER_OF_POKEMON_IN_PLAY_AREA
	get_turn_duelist_var
	dec a ; cp 1
	ret z ; return no carry if there are no Benched Pokémon

	ld b, a
	ld e, 0 ; initial score for comparison
	ld c, PLAY_AREA_BENCH_1
	ld d, c
	ld hl, wPlayAreaAIScore + 1
	call .loop

; in this case, there is no minimum threshold AI score.
	ld a, d
	ldh [hTempPlayAreaLocation_ff9d], a
	scf
	ret

.loop
	ld a, [hli]
	cp e
	jr c, .next
	jr z, .next
	ld e, a ; overwrite highest score found
	ld d, c ; overwrite the play area location offset of the highest score
.next
	inc c
	dec b
	jr nz, .loop
	ret


; input:
;	[hTempPlayAreaLocation_ff9d] = play area location offset of the Pokémon to check
;	[wSelectedAttack] = which attack to check (0 = first attack, 1 = second attack)
; output:
;	carry = set:  if there's an Evolution card in the AI's hand or deck
;	              that evolves from the Pokémon in the given location
;	              and if that card needs Energy to use the given attack
CheckIfEvolutionNeedsEnergyForAttack:
	call CreateHandCardList
	ldh a, [hTempPlayAreaLocation_ff9d]
	add DUELVARS_ARENA_CARD
	get_turn_duelist_var
	call CheckCardEvolutionInHandOrDeck
	ret nc ; return if it doesn't have an evolution

	ld b, a ; deck index of a suitable evolution in the hand or deck
	ldh a, [hTempPlayAreaLocation_ff9d]
	add DUELVARS_ARENA_CARD
	get_turn_duelist_var
	push af
	ld [hl], b
	call CheckEnergyNeededForAttack
	; carry set if not enough energy
	ldh a, [hTempPlayAreaLocation_ff9d]
	add DUELVARS_ARENA_CARD
	get_turn_duelist_var
	pop de
	ld [hl], d
	ret


; input:
;	[hTempPlayAreaLocation_ff9d] = Pokémon's play area location offset (PLAY_AREA_* constant)
;	[wSelectedAttack] = which attack to check (0 = first attack, 1 = second attack)
; output:
;	b = TRUE:  if it needs non-Colorless Energy
;	c = TRUE:  if it only needs Colorless Energy
;	e = Energy card ID relevant to the given attack:  if the given attack isn't
;	    ZapdosLv64's Thunderbolt, Charizard's Fire Spin, or Exeggutor's Big Eggsplosion
;	carry = set:  if the discarding attack isn't ZapdosLv64's Thunderbolt
GetEnergyCardForDiscardOrEnergyBoostAttack:
; load card ID and check selected attack index.
	ldh a, [hTempPlayAreaLocation_ff9d]
	add DUELVARS_ARENA_CARD
	get_turn_duelist_var
	call LoadCardDataToBuffer2_FromDeckIndex
	ld b, a
	ld a, [wSelectedAttack]
	or a ; cp FIRST_ATTACK_OR_PKMN_POWER
	jr z, .first_attack

; check if second attack is ZapdosLv64's Thunderbolt,
; Charizard's Fire Spin or Exeggutor's Big Eggsplosion,
; for these to be treated differently.
; for both attacks, load its Energy cost.
	ld a, b
	cp ZAPDOS_LV64
	ret z ; return no carry if ZapdosLv64's Thunderbolt
	cp CHARIZARD
	jr z, .charizard_or_exeggutor
	cp EXEGGUTOR
	jr z, .charizard_or_exeggutor
	ld hl, wLoadedCard2Atk2EnergyCost
	jr .fire
.first_attack
	ld hl, wLoadedCard2Atk1EnergyCost

; check which type/color of Energy the attack requires,
; and load in e the card ID of a corresponding Energy card,
; then return with the carry flag set.
.fire
	ld a, [hli]
	ld b, a
	and $f0
	jr z, .grass
	ld e, FIRE_ENERGY
	jr .set_carry
.grass
	ld a, b
	and $0f
	jr z, .lightning
	ld e, GRASS_ENERGY
	jr .set_carry
.lightning
	ld a, [hli]
	ld b, a
	and $f0
	jr z, .water
	ld e, LIGHTNING_ENERGY
	jr .set_carry
.water
	ld a, b
	and $0f
	jr z, .fighting
	ld e, WATER_ENERGY
	jr .set_carry
.fighting
	ld a, [hli]
	ld b, a
	and $f0
	jr z, .psychic
	ld e, FIGHTING_ENERGY
	jr .set_carry
.psychic
	ld e, PSYCHIC_ENERGY

.set_carry
	lb bc, TRUE, FALSE
	scf
	ret

; Charizard's Fire Spin and Exeggutor's Big Eggsplosion, return carry.
.charizard_or_exeggutor
	lb bc, FALSE, TRUE
	scf
	ret


; called after the AI has decided which Pokémon to attach
; the Energy card in the hand to. AI does checks to determine whether
; this card needs more Energy or not and chooses the right Energy card to play.
; input:
;	[hTempPlayAreaLocation_ff9d] = Pokémon's play area location offsest (PLAY_AREA_* constant)
; output:
;	carry = set:  if an Energy card was played from the hand
AITryToPlayEnergyCard:
; check if Energy cards are still needed for any attacks.
; if first attack doesn't need, test for the second attack.
	xor a
	ld [wTempAI], a
	ld [wSelectedAttack], a ; FIRST_ATTACK_OR_PKMN_POWER
	call CheckEnergyNeededForAttack
	jr nc, .second_attack
	ld a, b
	or a
	jr nz, .check_deck
	ld a, c
	or a
	jr nz, .check_deck

.second_attack
	ld a, SECOND_ATTACK
	ld [wSelectedAttack], a
	call CheckEnergyNeededForAttack
	jr nc, .check_discard_or_energy_boost
	ld a, b
	or a
	jr nz, .check_deck
	ld a, c
	or a
	jr nz, .check_deck

; neither attack needs Energy cards to be used.
; check whether these attacks can be given
; extra Energy cards for their effects.
.check_discard_or_energy_boost
	ld a, $01
	ld [wTempAI], a

; for both attacks, check if it has the effect of
; discarding Energy cards or an attached Energy boost.
	xor a ; FIRST_ATTACK_OR_PKMN_POWER
	ld [wSelectedAttack], a
	call CheckEnergyNeededForAttack
	ld a, ATTACK_FLAG2_ADDRESS | ATTACHED_ENERGY_BOOST_F
	call CheckLoadedAttackFlag
	jr c, .energy_boost_or_discard_energy
	ld a, ATTACK_FLAG2_ADDRESS | DISCARD_ENERGY_F
	call CheckLoadedAttackFlag
	jr c, .energy_boost_or_discard_energy

	ld a, SECOND_ATTACK
	ld [wSelectedAttack], a
	call CheckEnergyNeededForAttack
	ld a, ATTACK_FLAG2_ADDRESS | ATTACHED_ENERGY_BOOST_F
	call CheckLoadedAttackFlag
	jr c, .energy_boost_or_discard_energy
	ld a, ATTACK_FLAG2_ADDRESS | DISCARD_ENERGY_F
	call CheckLoadedAttackFlag
	jr c, .energy_boost_or_discard_energy

; if none of the attacks have those flags, do an additional
; check to ascertain whether the Evolution card needs Energy
; to use its second attack. return no carry if all these checks fail.
	call CheckIfEvolutionNeedsEnergyForAttack
	ret nc
	call CreateEnergyCardListFromHand
	jr .check_deck

; for attacks that discard Energy or get boost for
; additional Energy cards, get the Energy card ID required by attack.
; if it's ZapdosLv64's Thunderbolt attack, return.
.energy_boost_or_discard_energy
	call GetEnergyCardForDiscardOrEnergyBoostAttack
	ret nc

; some decks allow Basic Pokémon to be given a Double Colorless Energy
; in anticipation of evolution, so play the card if that is the case.
.check_deck
	call CheckSpecificDecksToAttachDoubleColorless
	jr c, .play_energy_card

	ld a, b
	or a
	jr z, .colorless_energy

; in this case, Pokémon needs a specific Basic Energy card.
; look for the needed Basic Energy card in the hand and play it.
	call GetEnergyCardNeeded
	call LookForCardIDInHand
	ldh [hTemp_ffa0], a
	jr nc, .play_energy_card

; in this case, Pokémon just needs Colorless (any Basic Energy card).
; if it's the Active Pokémon, check if it needs 2 Colorless.
; if it does (and also doesn't additionally need a non-Colorless Energy),
; look for a Double Colorless Energy card in the hand and play it if found.
.colorless_energy
	ldh a, [hTempPlayAreaLocation_ff9d]
	or a ; cp PLAY_AREA_ARENA
	jr nz, .look_for_any_energy
	ld a, c
	or a
	jr z, .check_if_done
	cp 2
	jr nz, .look_for_any_energy

	; needs two colorless
	ld hl, wDuelTempList
.loop_1
	ld a, [hli]
	cp $ff
	jr z, .look_for_any_energy
	ldh [hTemp_ffa0], a
	call _GetCardIDFromDeckIndex
	cp DOUBLE_COLORLESS_ENERGY
	jr nz, .loop_1
	jr .play_energy_card

; otherwise, look for any Energy card and play it.
; if it's a boss deck, don't play Double Colorless Energy in this situation.
.look_for_any_energy
	ld hl, wDuelTempList
	call CountCardsInDuelTempList
	call ShuffleCards
.loop_2
	ld a, [hli]
	cp $ff
	jr z, .check_if_done
	call CheckIfOpponentHasBossDeckID
	jr nc, .load_card
	ld b, a
	call _GetCardIDFromDeckIndex
	cp DOUBLE_COLORLESS_ENERGY
	jr z, .loop_2
	ld a, b
.load_card
	ldh [hTemp_ffa0], a

; plays the Energy card loaded in hTemp_ffa0 and sets the carry flag.
.play_energy_card
	ldh a, [hTempPlayAreaLocation_ff9d]
	ldh [hTempPlayAreaLocation_ffa1], a
	ld a, OPPACTION_PLAY_ENERGY
	bank1call AIMakeDecision
	scf
	ret

; wTempAI is 1 if the attack had a Discard/Energy Boost effect,
; and 0 otherwise. If 1, then return. If not one, check if
; there is still a second attack to check.
.check_if_done
	ld a, [wTempAI]
	or a
	ret nz
	ld a, [wSelectedAttack]
	or a ; cp FIRST_ATTACK_OR_PKMN_POWER
	jp z, .second_attack
	ret


; checks if playing certain decks so that the AI can decide whether to attach
; a Double Colorless Energy to a Pokémon that does not need that Energy
; for any of its attacks but which has an Evolution card that does.
; preserves all registers except af
; input:
;	[hTempPlayAreaLocation_ff9d] = play area location offset of the Pokémon to check (PLAY_AREA_* constant)
; output:
;	a & [hTemp_ffa0] = deck index of a Double Colorless Energy card in the AI's hand:  if carry = set
;	carry = set:  if the Energy card should be attached to one of these special Pokémon
CheckSpecificDecksToAttachDoubleColorless:
	push bc
	push de
	push hl

; check if AI is playing any of the applicable decks.
	ld a, [wOpponentDeckID]
	cp LEGENDARY_DRAGONITE_DECK_ID
	jr z, .legendary_dragonite_deck
	cp FIRE_CHARGE_DECK_ID
	jr z, .fire_charge_deck
	cp LEGENDARY_RONALD_DECK_ID
	jr z, .legendary_ronald_deck

.no_carry
	pop hl
	pop de
	pop bc
	or a
	ret

; if playing Legendary Dragonite deck,
; check for Charmander and Dratini.
.legendary_dragonite_deck
	call .get_id
	cp CHARMANDER
	jr z, .check_colorless_attached
	cp DRATINI
	jr z, .check_colorless_attached
	jr .no_carry

; if playing Fire Charge deck,
; check for Growlithe.
.fire_charge_deck
	call .get_id
	cp GROWLITHE
	jr z, .check_colorless_attached
	jr .no_carry

; if playing Legendary Ronald deck,
; check for Dratini.
.legendary_ronald_deck
	call .get_id
	cp DRATINI
	jr z, .check_colorless_attached
	jr .no_carry

; check if the Pokémon has any attached Colorless Energy cards,
; and if there are any, return no carry.
.check_colorless_attached
	ldh a, [hTempPlayAreaLocation_ff9d]
	ld e, a
	call GetPlayAreaCardAttachedEnergies
	ld a, [wAttachedEnergies + COLORLESS]
	or a
	jr nz, .no_carry

; the Pokémon has no Colorless Energy, so look for a Double Colorless Energy
; in the hand and if found, return carry with its deck index in a and hTempffa0.
	ld a, DOUBLE_COLORLESS_ENERGY
	call LookForCardIDInHand
	jr c, .no_carry
	ldh [hTemp_ffa0], a
	pop hl
	pop de
	pop bc
	scf
	ret

.get_id
	ldh a, [hTempPlayAreaLocation_ff9d]
	add DUELVARS_ARENA_CARD
	get_turn_duelist_var
	jp _GetCardIDFromDeckIndex


;----------------------------------------
;        UNREFERENCED FUNCTIONS
;----------------------------------------
;
; processes AI Energy card playing logic
; with AI_ENERGY_FLAG_DONT_PLAY flag on
;Func_16488:
;	ld a, AI_ENERGY_FLAG_DONT_PLAY
;	ld [wAIEnergyAttachLogicFlags], a
;	ld hl, wPlayAreaAIScore
;	ld de, wTempPlayAreaAIScore
;	ld b, MAX_PLAY_AREA_POKEMON
;	call CopyNBytesFromHLToDE
;	ld a, [wAIScore]
;	ld [de], a
;	jp AIProcessAndTryToPlayEnergy.has_logic_flags
