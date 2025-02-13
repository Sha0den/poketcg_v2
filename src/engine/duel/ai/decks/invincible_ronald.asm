AIActionTable_InvincibleRonald:
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
	db KANGASKHAN
	db MAGMAR_LV31
	db CHANSEY
	db GEODUDE
	db SCYTHER
	db GRIMER
	db $00

.list_bench
	db GRIMER
	db SCYTHER
	db GEODUDE
	db CHANSEY
	db MAGMAR_LV31
	db KANGASKHAN
	db $00

.list_retreat
	ai_retreat GRIMER, -1
	db $00

.list_energy
	ai_energy GRIMER,         1, -1
	ai_energy MUK,            3, -1
	ai_energy SCYTHER,        4, +1
	ai_energy MAGMAR_LV31,    2, +0
	ai_energy GEODUDE,        2, +0
	ai_energy GRAVELER,       3, +0
	ai_energy CHANSEY,        4, +0
	ai_energy KANGASKHAN,     4, -1
	db $00

.list_prize
	db GAMBLER
	db $00

.store_list_pointers
	store_list_pointer wAICardListAvoidPrize, .list_prize
	store_list_pointer wAICardListArenaPriority, .list_arena
	store_list_pointer wAICardListBenchPriority, .list_bench
	store_list_pointer wAICardListPlayFromHandPriority, .list_bench
	store_list_pointer wAICardListRetreatBonus, .list_retreat
	store_list_pointer wAICardListEnergyBonus, .list_energy
	ret
