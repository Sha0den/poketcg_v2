; this function handles attacks with the SPECIAL_AI_HANDLING flag set,
; and makes specific checks in each of these attacks to either return
; a positive score (value above $80) or a negative score (value below $80).
; $80 (128) is simply the base value. For example,
;	- if $82 (130) is returned, then 2 is added to this attack's score
;	- if $7a (122) is returned, then 6 is subtracted from this attack's score
; if an attack has the SPECIAL_AI_HANDLING flag but the Pokémon
; isn't listed below, then dismiss the attack by returning a score of 0.
; input:
;	[hTempPlayAreaLocation_ff9d] = Attacking Pokémon's play area location offset (PLAY_AREA_* constant)
HandleSpecialAIAttacks:
	ldh a, [hTempPlayAreaLocation_ff9d]
	add DUELVARS_ARENA_CARD
	get_turn_duelist_var
	call GetCardIDFromDeckIndex
	ld a, e

	cp NINETALES_LV35
	jp z, .MixUp
	cp MOLTRES_LV35
	jp z, .Wildfire
	cp ELECTRODE_LV35
	jp z, .EnergySpike
	cp ELECTRODE_LV42
	jp z, .ChainLightning
	cp ZAPDOS_LV68
	jp z, .BigThunder
	cp DUGTRIO
	jp z, .Earthquake
	cp GASTLY_LV8
	jp z, .DestinyBond
	cp GASTLY_LV17
	jp z, .EnergyConversion
	cp MEWTWO_LV60
	jp z, .EnergyAbsorption
	cp MEWTWO_ALT_LV60
	jp z, .EnergyAbsorption
	cp MEW_LV23
	jp z, .DevolutionBeam
	cp KANGASKHAN
	jp z, .Fetch
	cp PORYGON
	jp z, .Conversion
	cp GOLDUCK
	jp z, .HyperBeam
	cp DRAGONAIR
	jp z, .HyperBeam
	cp ODDISH
	jr z, .CallForFamily
	cp BELLSPROUT
	jr z, .CallForFamily
	cp KRABBY
	jr z, .CallForFamily
	cp NIDORANF
	jr z, .NidoranFCallForFamily
	cp MAROWAK_LV26
	jr z, .CallForFriend
	cp MAROWAK_LV32
	jr z, .Wail
	cp JIGGLYPUFF_LV13
	jr z, .FriendshipSong
	cp EXEGGUTOR
	jr z, .Teleport
	cp SCYTHER
	jr z, .SwordsDanceAndFocusEnergy
	cp VAPOREON_LV29
	jr z, .SwordsDanceAndFocusEnergy
	; return zero score.
	xor a
	ret


; if another copy of the card ID in e (i.e. the Attacking Pokémon) is found in the deck,
; return a score of $80 + slots available on the Bench.
; otherwise, dismiss the attack.
.CallForFamily:
	ld a, CARD_LOCATION_DECK
	call LookForCardIDInLocation_Bank5
	jr nc, .zero_score
;	fallthrough

.bench_space_bonus_score
	ld a, DUELVARS_NUMBER_OF_POKEMON_IN_PLAY_AREA
	get_turn_duelist_var
	cp MAX_PLAY_AREA_POKEMON
	jr nc, .zero_score
	ld b, a
	ld a, MAX_PLAY_AREA_POKEMON
	sub b
	add $80
	ret


; if any NidoranM or NidoranF is found in the deck,
; return a score of $80 + slots available on the Bench.
; otherwise, dismiss the attack.
.NidoranFCallForFamily:
	ld e, NIDORANM
	ld a, CARD_LOCATION_DECK
	call LookForCardIDInLocation_Bank5
	jr c, .bench_space_bonus_score
	ld e, NIDORANF
	ld a, CARD_LOCATION_DECK
	call LookForCardIDInLocation_Bank5
	jr c, .bench_space_bonus_score
	xor a
	ret


; checks for certain Basic Fighting Pokémon in the deck.
; if any of them are found, return a score of
; $80 + slots available on the Bench.
; otherwise, dismiss the attack.
.CallForFriend:
	ld e, GEODUDE
	ld a, CARD_LOCATION_DECK
	call LookForCardIDInLocation_Bank5
	jr c, .bench_space_bonus_score
	ld e, ONIX
	ld a, CARD_LOCATION_DECK
	call LookForCardIDInLocation_Bank5
	jr c, .bench_space_bonus_score
	ld e, CUBONE
	ld a, CARD_LOCATION_DECK
	call LookForCardIDInLocation_Bank5
	jr c, .bench_space_bonus_score
	ld e, RHYHORN
	ld a, CARD_LOCATION_DECK
	call LookForCardIDInLocation_Bank5
	jr c, .bench_space_bonus_score

; return zero score.
.zero_score
	xor a
	ret


; dismiss the attack if the AI has more Pokémon in play than the Player
; or if there are no Basic Pokémon in the AI's deck.
; otherwise, return a score of $80 + slots available on the AI's Bench.
.Wail:
	ld a, DUELVARS_NUMBER_OF_POKEMON_IN_PLAY_AREA
	get_turn_duelist_var
	ld b, a
	ld a, DUELVARS_NUMBER_OF_POKEMON_IN_PLAY_AREA
	call GetNonTurnDuelistVariable
	cp b
	jr c, .zero_score
;	fallthrough

; if any Basic Pokémon are found in the deck,
; return a score of $80 + slots available on the Bench.
; otherwise, dismiss the attack.
.FriendshipSong:
	call CheckIfAnyBasicPokemonInDeck
	jr c, .bench_space_bonus_score
	xor a
	ret


; if AI decides to retreat, return a score of $80 + 10.
; otherwise, dismiss the attack.
.Teleport:
	call AIDecideWhetherToRetreat
	jr nc, .zero_score
	ld a, $8a
	ret


; tests for the following conditions:
; - Defending Pokémon has a No Damage substatus
; - second attack is unusable
; - second attack deals no damage
; if any are true, returns score of $80 + 5.
.SwordsDanceAndFocusEnergy:
	ld a, [wAICannotDamage]
	or a
	jr nz, .swords_dance_focus_energy_success
	ld a, SECOND_ATTACK
	ld [wSelectedAttack], a
	call CheckIfSelectedAttackIsUnusable
	jr c, .swords_dance_focus_energy_success
	ld a, SECOND_ATTACK
	call EstimateDamage_VersusDefendingCard
	ld a, [wDamage]
	or a
	jr nz, .zero_score
.swords_dance_focus_energy_success
	ld a, $85
	ret


; checks the Defending Pokémon's type/color, then
; loops through own Bench looking for a Pokémon with that color.
; if none are found, returns score of $80 + 2. (If found, return 0)
.ChainLightning:
	rst SwapTurn
	call GetArenaCardColor
	rst SwapTurn
	ld b, a
	ld a, DUELVARS_BENCH
	get_turn_duelist_var
.loop_chain_lightning_bench
	ld a, [hli]
	cp -1 ; empty play area slot?
	jr z, .chain_lightning_success
	call GetCardIDFromDeckIndex
	call GetCardType
	cp b
	jr nz, .loop_chain_lightning_bench
	; return zero score
	xor a
	ret
.chain_lightning_success
	ld a, $82
	ret


; dismiss the attack if the Defending Pokémon can't KO the
; AI's Active Pokémon with its current amount of Energy.
; otherwise, return a score of $80 + 5.
.DestinyBond:
	call CheckIfDefendingPokemonCanKnockOut
	jr nc, .zero_score
	ld a, $85
	ret


; dismiss the attack if there are already 1 or more Energy cards in the hand
; or if there are fewer than 2 Energy cards in the discard pile.
; otherwise, return a score of $80 + 3.
.EnergyConversion:
	call CreateEnergyCardListFromHand
	jr nc, .zero_score
	farcall CreateEnergyCardListFromDiscardPile_AllEnergy
	cp 2
	jr c, .zero_score
	ld a, $83
	ret


; dismiss the attack if it can't be used to KO one of the Player's Pokémon.
; otherwise, return a score of $80 + 5.
.DevolutionBeam:
	call LookForCardThatIsKnockedOutOnDevolution
	jr nc, .zero_score
	ld a, $85
	ret


; first checks if the Attacking Pokémon is Confused, and if so return 0.
; then checks number of Benched Pokémon that are viable to use:
; - if that number is < 2  and this attack is Conversion 1 OR
; - if that number is >= 2 and this attack is Conversion 2
; then return score of $80 + 2.
; otherwise return score of $80 + 1.
.Conversion:
	ld a, DUELVARS_ARENA_CARD_STATUS
	get_turn_duelist_var
	and CNF_SLP_PRZ
	cp CONFUSED
	jr z, .zero_score

	ld a, [wSelectedAttack]
	or a ; cp FIRST_ATTACK_OR_PKMN_POWER
	jr nz, .conversion_2

; conversion 1
	call CountNumberOfSetUpBenchPokemon
	cp 2
	jr c, .low_conversion_score
	ld a, $82
	ret

.conversion_2
	call CountNumberOfSetUpBenchPokemon
	cp 2
	jr nc, .low_conversion_score
	ld a, $82
	ret

.low_conversion_score
	ld a, $81
	ret


; if any Psychic Energy is found in the discard pile,
; return a score of $80 + 2. otherwise, dismiss the attack.
.EnergyAbsorption:
	ld e, PSYCHIC_ENERGY
	ld a, CARD_LOCATION_DISCARD_PILE
	call LookForCardIDInLocation_Bank5
	jr nc, .zero_score2
	ld a, $82
	ret


; if the Player has cards in their hand, AI calls Random:
; - 1/3 chance to encourage the attack regardless
; - 1/3 chance to dismiss the attack regardless
; - 1/3 change to make some checks to the Player's hand
; AI tallies number of Basic Pokémon in the hand, and if this
; number is >= 2, encourage the attack.
; otherwise, if it finds an Evolution card in the hand that
; can evolve a Pokémon in the Player's play area, encourage.
; if encouraged, returns a score of $80 + 3.
.MixUp:
	rst SwapTurn
	ld a, DUELVARS_NUMBER_OF_CARDS_IN_HAND
	get_turn_duelist_var
	or a
	jr z, .zero_score_after_swap_turn ; return if Player has no cards in hand

	ld a, 3
	call Random
	or a
	jr z, .encourage_mix_up
	dec a
	jr z, .zero_score_after_swap_turn
	call CreateHandCardList
;	or a
;	jr z, .zero_score_after_swap_turn ; return if Player has no cards in hand (again)
	ld a, DUELVARS_NUMBER_OF_POKEMON_IN_PLAY_AREA
	get_turn_duelist_var
	cp 3
	jr nc, .mix_up_check_play_area ; skip checking the opponent's hand if they have more than 2 play area Pokémon

	ld hl, wDuelTempList
	ld b, 0 ; counter
.loop_mix_up_hand
	ld a, [hli]
	cp $ff
	jr z, .tally_basic_cards
	call CheckDeckIndexForBasicPokemon
	jr nc, .loop_mix_up_hand ; skip if card isn't a Basic Pokémon
	; found a Basic Pokémon card
	inc b
	jr .loop_mix_up_hand
.tally_basic_cards
	ld a, b
	cp 2
	jr nc, .encourage_mix_up

; less than 2 Basic Pokémon in hand
.mix_up_check_play_area
	ld a, DUELVARS_ARENA_CARD
	get_turn_duelist_var
.loop_mix_up_play_area
	ld a, [hli]
	cp -1 ; empty play area slot?
	jr z, .zero_score_after_swap_turn
	push hl
	call CheckForEvolutionInList
	pop hl
	jr nc, .loop_mix_up_play_area

.encourage_mix_up
	rst SwapTurn
	ld a, $83
	ret

.zero_score_after_swap_turn
	rst SwapTurn
.zero_score2
	xor a
	ret


; dismiss the attack if there are more than 10 cards left in the Player's deck and the
; Defending Pokémon can't KO the AI's Active Pokémon with its current amount of Energy.
; also dismiss the attack if there are no cards left in the Player's deck.
; if the AI's Active Pokémon can be KO'd, then increase the score by 5.
; also increase the score depending on how many cards are left in the Player's deck.
; (e.g. +0 if 10 cards left, +1 if 9 cards left, +2 if 8 cards left, ... +9 if 1 card left)
.Wildfire:
	call CheckIfDefendingPokemonCanKnockOut
	ld c, 0 ; initial score modifier if not KO'd next turn
	jr nc, .no_ko
	ld c, 5 ; add 5 to the score if the Active Pokémon will be KO'd
.no_ko
	ld a, DUELVARS_NUMBER_OF_CARDS_NOT_IN_DECK
	call GetNonTurnDuelistVariable
	ld b, a
	ld a, DECK_SIZE
	sub b
	or a
	jr z, .zero_score2 ; don't use if there are no cards in the Player's deck to discard
	ld b, a ; number of cards left in the Player's deck
	ld a, 10
	sub b
	jr c, .return_score ; don't adjust score further if there are more than 10 cards in the deck
	add c
	ld c, a
.return_score
	ld a, c
	or a
	ret z
	add $80
	ret


; return score of $80 + 3.
.BigThunder:
	ld a, $83
	ret


; dismiss attack if cards in deck <= 20.
; otherwise return a score of $80 + 0.
.Fetch:
	ld a, DUELVARS_NUMBER_OF_CARDS_NOT_IN_DECK
	get_turn_duelist_var
	cp 41
	jr nc, .zero_score2
	ld a, $80
	ret


; dismiss the attack if the number of Pokémon on the user's Bench
; which would be KO'd after using Earthquake is greater than or equal to
; the number of Prize cards that the Player has not yet drawn
.Earthquake:
	xor a ; Active won't be KO'd
	ld b, 20 ; damage to Bench
	call CheckIfDamageToAllTurnHolderBenchedPokemonLosesDuel
	jr c, .zero_score2
	ld a, $80
	ret


; if there are any Lightning Energy cards in the deck,
; return a score of $80 + 3. otherwise, dismiss the attack.
.EnergySpike:
	ld a, CARD_LOCATION_DECK
	ld e, LIGHTNING_ENERGY
	call LookForCardIDInLocation_Bank5
	jr nc, .zero_score2
	call AIProcessButDontPlayEnergy_SkipEvolution
	jr nc, .zero_score2
	ld a, $83
	ret


; only incentivize the attack if the Player's Active Pokémon,
; has any attached Energy cards, and if so,
; return a score of $80 + 3.
.HyperBeam:
	rst SwapTurn
	ld e, PLAY_AREA_ARENA
	call GetPlayAreaCardAttachedEnergies
	rst SwapTurn
;	ld a, [wTotalAttachedEnergies] ; already loaded
	or a
	jr z, .hyper_beam_neutral
	ld a, $83
	ret
.hyper_beam_neutral
	ld a, $80
	ret


; preserves bc and de
; output:
;	carry = set:  if there are any Basic Pokémon cards in the deck
CheckIfAnyBasicPokemonInDeck:
	ldh a, [hWhoseTurn]
	ld h, a
	ld l, DUELVARS_CARD_LOCATIONS + DECK_SIZE
.loop
	dec l ; go through deck indices in reverse order
	ld a, [hl]
	cp CARD_LOCATION_DECK
	jr nz, .next
	ld a, l
	call CheckDeckIndexForBasicPokemon
	ret c
.next
	ld a, l
	or a
	jr nz, .loop
	ret ; nc
