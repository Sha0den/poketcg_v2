AIActionTable_FirstStrike:
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
	db HITMONCHAN
	db MACHOP
	db HITMONLEE
	db MANKEY
	db $00

.list_bench
	db MACHOP
	db HITMONLEE
	db HITMONCHAN
	db MANKEY
	db $00

.list_retreat
	ai_retreat MACHOP,  -1
	ai_retreat MACHOKE, -1
	ai_retreat MANKEY,  -2
	db $00

.list_energy
	ai_energy MACHOP,     3, +0
	ai_energy MACHOKE,    4, +0
	ai_energy MACHAMP,    4, -1
	ai_energy HITMONCHAN, 3, +0
	ai_energy HITMONLEE,  3, +0
	ai_energy MANKEY,     2, -1
	ai_energy PRIMEAPE,   3, -1
	db $00

.list_prize
	db HITMONLEE
	db HITMONCHAN
	db $00

.store_list_pointers
	store_list_pointer wAICardListAvoidPrize, .list_prize
	store_list_pointer wAICardListArenaPriority, .list_arena
	store_list_pointer wAICardListBenchPriority, .list_bench
	store_list_pointer wAICardListPlayFromHandPriority, .list_bench
	store_list_pointer wAICardListRetreatBonus, .list_retreat
	store_list_pointer wAICardListEnergyBonus, .list_energy
	ret
