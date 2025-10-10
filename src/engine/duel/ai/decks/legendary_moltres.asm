AIActionTable_LegendaryMoltres:
	dw AIDoTurn_LegendaryMoltres      ; .do_turn (unused)
	dw AIDoTurn_LegendaryMoltres      ; .do_turn
	dw .start_duel
	dw AIDecideBenchPokemonToSwitchTo ; .forced_switch
	dw AIDecideBenchPokemonToSwitchTo ; .ko_switch
	dw AIPickPrizeCards               ; .take_prize

.start_duel
	call InitAIDuelVars
	call .store_list_pointers
	call SetUpBossStartingHandAndDeck
	call TrySetUpBossStartingPlayArea
	ret nc ; Play Area set up was successful
	jp AIPlayInitialBasicCards

.list_arena
	db MAGMAR_LV31
	db GROWLITHE
	db VULPIX
	db MAGMAR_LV24
	db MOLTRES_LV35
	db MOLTRES_LV37
	db $00

.list_bench
	db MOLTRES_LV35
	db VULPIX
	db GROWLITHE
	db MAGMAR_LV31
	db MAGMAR_LV24
	db $00

.list_play_hand
	db MOLTRES_LV37
	db MOLTRES_LV35
	db VULPIX
	db GROWLITHE
	db MAGMAR_LV31
	db MAGMAR_LV24
	db $00

.list_retreat
	ai_retreat GROWLITHE, -5
	ai_retreat VULPIX,    -5
	db $00

.list_energy
	ai_energy VULPIX,         3, +0
	ai_energy NINETALES_LV35, 3, +1
	ai_energy GROWLITHE,      3, +1
	ai_energy ARCANINE_LV45,  4, +1
	ai_energy MAGMAR_LV24,    4, -1
	ai_energy MAGMAR_LV31,    1, -1
	ai_energy MOLTRES_LV37,   3, +2
	ai_energy MOLTRES_LV35,   4, +2
	db $00

.list_prize
	db ENERGY_REMOVAL
	db MOLTRES_LV37
	db $00

.store_list_pointers
	store_list_pointer wAICardListAvoidPrize, .list_prize
	store_list_pointer wAICardListArenaPriority, .list_arena
	store_list_pointer wAICardListBenchPriority, .list_bench
	store_list_pointer wAICardListPlayFromHandPriority, .list_play_hand
	store_list_pointer wAICardListRetreatBonus, .list_retreat
	store_list_pointer wAICardListEnergyBonus, .list_energy
	ret


AIDoTurn_LegendaryMoltres:
; initialize variables
	call InitAITurnVars
	call HandleAIAntiMewtwoDeckStrategy
	jr nc, .try_attack
; process Trainer cards
; phase 2 through 4.
	ld a, AI_TRAINER_CARD_PHASE_02
	call AIProcessHandTrainerCards
	ld a, AI_TRAINER_CARD_PHASE_04
	call AIProcessHandTrainerCards

; check if AI can play MoltresLv37
; from hand and if so, play it.
	ld a, DUELVARS_NUMBER_OF_POKEMON_IN_PLAY_AREA
	get_turn_duelist_var
	cp MAX_PLAY_AREA_POKEMON
	jr nc, .skip_moltres ; skip if bench is full
	ld a, DUELVARS_NUMBER_OF_CARDS_NOT_IN_DECK
	get_turn_duelist_var
	cp DECK_SIZE - 9
	jr nc, .skip_moltres ; skip if cards in deck <= 9
	call CheckIfPkmnPowersAreCurrentlyDisabled
	jr c, .skip_moltres ; skip if Moltres's Firegiver power can't be used
	ld a, MOLTRES_LV37
	call LookForCardIDInHandList_Bank5
	jr nc, .skip_moltres ; skip if no MoltresLv37 in hand
	ldh [hTemp_ffa0], a
	ld a, OPPACTION_PLAY_BASIC_PKMN
	bank1call AIMakeDecision

.skip_moltres
; play Pokemon from hand
	call AIDecidePlayPokemonCard
	ret c ; return if turn ended
; process Trainer cards
	ld a, AI_TRAINER_CARD_PHASE_05
	call AIProcessHandTrainerCards
	call AIProcessRetreat
	ld a, AI_TRAINER_CARD_PHASE_10
	call AIProcessHandTrainerCards
	ld a, AI_TRAINER_CARD_PHASE_11
	call AIProcessHandTrainerCards
; play Energy card if possible
	ld a, [wOncePerTurnFlags]
	and PLAYED_ENERGY_THIS_TURN
	jr nz, .skip_attach_energy

; if MagmarLv31 is the Active Pokémon and has no attached Energy,
; try attaching an Energy card to it from the hand.
; otherwise, run normal AI Energy attach routine.
	ld a, DUELVARS_ARENA_CARD
	get_turn_duelist_var
	call _GetCardIDFromDeckIndex
	cp MAGMAR_LV31
	jr nz, .attach_normally
	; MagmarLv31 is the Active Pokémon
	call CreateEnergyCardListFromHand
	jr c, .skip_attach_energy
	ld e, PLAY_AREA_ARENA
	call GetPlayAreaCardAttachedEnergies
	or a
	jr nz, .attach_normally
	xor a ; PLAY_AREA_ARENA
	ldh [hTempPlayAreaLocation_ff9d], a
	call AITryToPlayEnergyCard
	jr c, .skip_attach_energy

.attach_normally
; play Energy card if possible
	call AIProcessAndTryToPlayEnergy
.skip_attach_energy
; try playing Pokemon cards from hand again
	call AIDecidePlayPokemonCard
	ret c ; return if turn ended
	ld a, AI_TRAINER_CARD_PHASE_13
	call AIProcessHandTrainerCards

.try_attack
; attack if possible, if not,
; finish turn without attacking.
	call AIProcessAndTryToUseAttack
	ret c
	ld a, OPPACTION_FINISH_NO_ATTACK
	bank1call AIMakeDecision
	ret
