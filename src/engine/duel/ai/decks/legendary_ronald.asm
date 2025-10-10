AIActionTable_LegendaryRonald:
	dw AIDoTurn_LegendaryRonald       ; .do_turn (unused)
	dw AIDoTurn_LegendaryRonald       ; .do_turn
	dw .start_duel
	dw AIDecideBenchPokemonToSwitchTo ; .forced_switch
	dw AIDecideBenchPokemonToSwitchTo ; .ko_switch
	dw AIPickPrizeCards               ; .take_prize

.start_duel
	call InitAIDuelVars
	call .store_list_pointers
	call SetUpBossStartingHandAndDeck
	call TrySetUpBossStartingPlayArea
	ret nc
	jp AIPlayInitialBasicCards

.list_arena
	db KANGASKHAN
	db DRATINI
	db EEVEE
	db ZAPDOS_LV68
	db ARTICUNO_LV37
	db MOLTRES_LV37
	db $00

.list_bench
	db KANGASKHAN
	db DRATINI
	db EEVEE
	db $00

.list_play_hand
	db MOLTRES_LV37
	db ZAPDOS_LV68
	db KANGASKHAN
	db DRATINI
	db EEVEE
	db ARTICUNO_LV37
	db $00

.list_retreat
	ai_retreat EEVEE, -2
	db $00

.list_energy
	ai_energy FLAREON_LV22,   3, +0
	ai_energy MOLTRES_LV37,   3, +0
	ai_energy VAPOREON_LV29,  3, +0
	ai_energy ARTICUNO_LV37,  0, -8
	ai_energy JOLTEON_LV24,   4, +0
	ai_energy ZAPDOS_LV68,    0, -8
	ai_energy KANGASKHAN,     4, -1
	ai_energy EEVEE,          3, +0
	ai_energy DRATINI,        3, +0
	ai_energy DRAGONAIR,      4, +0
	ai_energy DRAGONITE_LV41, 3, +0
	db $00

.list_prize
	db MOLTRES_LV37
	db ARTICUNO_LV37
	db ZAPDOS_LV68
	db DRAGONITE_LV41
	db GAMBLER
	db $00

.store_list_pointers
	store_list_pointer wAICardListAvoidPrize, .list_prize
	store_list_pointer wAICardListArenaPriority, .list_arena
	store_list_pointer wAICardListBenchPriority, .list_bench
	store_list_pointer wAICardListPlayFromHandPriority, .list_play_hand
	store_list_pointer wAICardListRetreatBonus, .list_retreat
	store_list_pointer wAICardListEnergyBonus, .list_energy
	ret


AIDoTurn_LegendaryRonald:
; initialize variables
	call InitAITurnVars
; process Trainer cards
	ld a, AI_TRAINER_CARD_PHASE_01
	call AIProcessHandTrainerCards
	ld a, AI_TRAINER_CARD_PHASE_02
	call AIProcessHandTrainerCards
	ld a, AI_TRAINER_CARD_PHASE_04
	call AIProcessHandTrainerCards

; check if AI can play MoltresLv37
; from hand and if so, play it.
	ld a, DUELVARS_NUMBER_OF_POKEMON_IN_PLAY_AREA
	get_turn_duelist_var
	cp MAX_PLAY_AREA_POKEMON
	jr nc, .skip_moltres_1 ; skip if bench is full
	ld a, DUELVARS_NUMBER_OF_CARDS_NOT_IN_DECK
	get_turn_duelist_var
	cp DECK_SIZE - 9
	jr nc, .skip_moltres_1 ; skip if cards in deck <= 9
	call CheckIfPkmnPowersAreCurrentlyDisabled
	jr c, .skip_moltres_1 ; skip if Moltres's Firegiver power can't be used
	ld a, MOLTRES_LV37
	call LookForCardIDInHandList_Bank5
	jr nc, .skip_moltres_1 ; skip if no MoltresLv37 in hand
	ldh [hTemp_ffa0], a
	ld a, OPPACTION_PLAY_BASIC_PKMN
	bank1call AIMakeDecision

.skip_moltres_1
; play Pokemon from hand
	call AIDecidePlayPokemonCard
	ret c ; return if turn ended
; process Trainer cards
	ld a, AI_TRAINER_CARD_PHASE_05
	call AIProcessHandTrainerCards
	ld a, AI_TRAINER_CARD_PHASE_07
	call AIProcessHandTrainerCards
	call AIProcessRetreat
	ld a, AI_TRAINER_CARD_PHASE_10
	call AIProcessHandTrainerCards
; play Energy card if possible
	ld a, [wOncePerTurnFlags]
	and PLAYED_ENERGY_THIS_TURN
	call z, AIProcessAndTryToPlayEnergy
; try playing Pokemon cards from hand again
	call AIDecidePlayPokemonCard
	ret c ; return if turn ended
	ld a, AI_TRAINER_CARD_PHASE_15
	call AIProcessHandTrainerCards
; if used Professor Oak, process new hand
; if not, then proceed to attack.
	ld a, [wPreviousAIFlags]
	and AI_FLAG_USED_PROFESSOR_OAK
	jr z, .try_attack
	ld a, AI_TRAINER_CARD_PHASE_01
	call AIProcessHandTrainerCards
	ld a, AI_TRAINER_CARD_PHASE_02
	call AIProcessHandTrainerCards
	ld a, AI_TRAINER_CARD_PHASE_04
	call AIProcessHandTrainerCards

; check if AI can play MoltresLv37
; from hand and if so, play it.
	ld a, DUELVARS_NUMBER_OF_POKEMON_IN_PLAY_AREA
	get_turn_duelist_var
	cp MAX_PLAY_AREA_POKEMON
	jr nc, .skip_moltres_2 ; skip if bench is full
	ld a, DUELVARS_NUMBER_OF_CARDS_NOT_IN_DECK
	get_turn_duelist_var
	cp DECK_SIZE - 9
	jr nc, .skip_moltres_2 ; skip if cards in deck <= 9
	call CheckIfPkmnPowersAreCurrentlyDisabled
	jr c, .skip_moltres_2 ; skip if Moltres's Firegiver power can't be used
	ld a, MOLTRES_LV37
	call LookForCardIDInHandList_Bank5
	jr nc, .skip_moltres_2 ; skip if no MoltresLv37 in hand
	ldh [hTemp_ffa0], a
	ld a, OPPACTION_PLAY_BASIC_PKMN
	bank1call AIMakeDecision

.skip_moltres_2
	call AIDecidePlayPokemonCard
	ret c ; return if turn ended
	ld a, AI_TRAINER_CARD_PHASE_05
	call AIProcessHandTrainerCards
	ld a, AI_TRAINER_CARD_PHASE_07
	call AIProcessHandTrainerCards
	call AIProcessRetreat
	ld a, AI_TRAINER_CARD_PHASE_10
	call AIProcessHandTrainerCards
	ld a, [wOncePerTurnFlags]
	and PLAYED_ENERGY_THIS_TURN
	call z, AIProcessAndTryToPlayEnergy
	call AIDecidePlayPokemonCard
	ret c ; return if turn ended
.try_attack
; attack if possible, if not,
; finish turn without attacking.
	call AIProcessAndTryToUseAttack
	ret c ; return if turn ended
	ld a, OPPACTION_FINISH_NO_ATTACK
	bank1call AIMakeDecision
	ret
