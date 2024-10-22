AIActionTable_GoGoRainDance:
	dw AIMainTurnLogic                ; .do_turn (unused)
	dw AIMainTurnLogic                ; .do_turn
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
	db LAPRAS
	db HORSEA
	db GOLDEEN
	db SQUIRTLE
	db $00

.list_bench
	db SQUIRTLE
	db HORSEA
	db GOLDEEN
	db LAPRAS
	db $00

.list_retreat
	ai_retreat SQUIRTLE,  -3
	ai_retreat WARTORTLE, -2
	ai_retreat HORSEA,    -1
	db $00

.list_energy
	ai_energy SQUIRTLE,  2, +0
	ai_energy WARTORTLE, 3, +0
	ai_energy BLASTOISE, 5, +0
	ai_energy GOLDEEN,   1, +0
	ai_energy SEAKING,   2, +0
	ai_energy HORSEA,    2, +0
	ai_energy SEADRA,    3, +0
	ai_energy LAPRAS,    3, +0
	db $00

.list_prize
	db GAMBLER
	db ENERGY_RETRIEVAL
	db SUPER_ENERGY_RETRIEVAL
	db BLASTOISE
	db $00

.store_list_pointers
	store_list_pointer wAICardListAvoidPrize, .list_prize
	store_list_pointer wAICardListArenaPriority, .list_arena
	store_list_pointer wAICardListBenchPriority, .list_bench
	store_list_pointer wAICardListPlayFromHandPriority, .list_bench
	store_list_pointer wAICardListRetreatBonus, .list_retreat
	store_list_pointer wAICardListEnergyBonus, .list_energy
	ret
