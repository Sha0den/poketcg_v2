AIActionTable_LegendaryDragonite:
	dw AIDoTurn_LegendaryDragonite    ; .do_turn (unused)
	dw AIDoTurn_LegendaryDragonite    ; .do_turn
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
	db LAPRAS
	db CHARMANDER
	db DRATINI
	db MAGIKARP
	db $00

.list_bench
	db CHARMANDER
	db MAGIKARP
	db DRATINI
	db LAPRAS
	db KANGASKHAN
	db $00

.list_retreat
	ai_retreat CHARMANDER, -1
	ai_retreat MAGIKARP,   -5
	db $00

.list_energy
	ai_energy CHARMANDER,     3, +1
	ai_energy CHARMELEON,     4, +1
	ai_energy CHARIZARD,      5, +0
	ai_energy MAGIKARP,       3, +1
	ai_energy GYARADOS,       4, -1
	ai_energy DRATINI,        2, +0
	ai_energy DRAGONAIR,      4, +0
	ai_energy DRAGONITE_LV41, 3, -1
	ai_energy KANGASKHAN,     2, -2
	ai_energy LAPRAS,         3, +0
	db $00

.list_prize
	db GAMBLER
	db DRAGONITE_LV41
	db KANGASKHAN
	db $00

.store_list_pointers
	store_list_pointer wAICardListAvoidPrize, .list_prize
	store_list_pointer wAICardListArenaPriority, .list_arena
	store_list_pointer wAICardListBenchPriority, .list_bench
	store_list_pointer wAICardListPlayFromHandPriority, .list_bench
	store_list_pointer wAICardListRetreatBonus, .list_retreat
	store_list_pointer wAICardListEnergyBonus, .list_energy
	ret


AIDoTurn_LegendaryDragonite:
; initialize variables
	call InitAITurnVars
	ld a, AI_TRAINER_CARD_PHASE_01
	call AIProcessHandTrainerCards
	call HandleAIAntiMewtwoDeckStrategy
	jp nc, .try_attack
; process Trainer cards
	ld a, AI_TRAINER_CARD_PHASE_02
	call AIProcessHandTrainerCards
; play Pokemon from hand
	call AIDecidePlayPokemonCard
	ret c ; return if turn ended
	ld a, AI_TRAINER_CARD_PHASE_07
	call AIProcessHandTrainerCards
	call AIProcessRetreat
	ld a, AI_TRAINER_CARD_PHASE_10
	call AIProcessHandTrainerCards
	ld a, AI_TRAINER_CARD_PHASE_11
	call AIProcessHandTrainerCards
; play Energy card if possible
	ld a, [wOncePerTurnFlags]
	and PLAYED_ENERGY_THIS_TURN
	jr nz, .skip_energy_attach_1

; if the Active Pokémon is a Kangaskhan
; and it doesn't have any attached Energy,
; try attaching an Energy card to it from the hand.
; otherwise, run the normal AI energy attach routine.
	ld a, DUELVARS_ARENA_CARD
	get_turn_duelist_var
	call _GetCardIDFromDeckIndex
	cp KANGASKHAN
	jr nz, .attach_normally
	call CreateEnergyCardListFromHand
	jr c, .skip_energy_attach_1
	ld e, PLAY_AREA_ARENA
	call GetPlayAreaCardAttachedEnergies
	or a
	jr nz, .attach_normally
	xor a ; PLAY_AREA_ARENA
	ldh [hTempPlayAreaLocation_ff9d], a
	call AITryToPlayEnergyCard
	jr c, .skip_energy_attach_1
.attach_normally
	call AIProcessAndTryToPlayEnergy

.skip_energy_attach_1
; play Pokemon from hand again
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
	call AIDecidePlayPokemonCard
	ret c ; return if turn ended
	ld a, AI_TRAINER_CARD_PHASE_07
	call AIProcessHandTrainerCards
	call AIProcessRetreat
	ld a, AI_TRAINER_CARD_PHASE_10
	call AIProcessHandTrainerCards
	ld a, AI_TRAINER_CARD_PHASE_11
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
