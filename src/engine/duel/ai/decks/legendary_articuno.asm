AIActionTable_LegendaryArticuno:
	dw AIDoTurn_LegendaryArticuno     ; .do_turn (unused)
	dw AIDoTurn_LegendaryArticuno     ; .do_turn
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
	db CHANSEY
	db LAPRAS
	db DITTO
	db SEEL
	db ARTICUNO_LV35
	db ARTICUNO_LV37
	db $00

.list_bench
	db ARTICUNO_LV35
	db SEEL
	db LAPRAS
	db CHANSEY
	db DITTO
	db $00

.list_retreat
	ai_retreat SEEL,  -3
	ai_retreat DITTO, -3
	db $00

.list_energy
	ai_energy SEEL,          3, +1
	ai_energy DEWGONG,       4, +0
	ai_energy LAPRAS,        3, +0
	ai_energy ARTICUNO_LV35, 4, +1
	ai_energy ARTICUNO_LV37, 3, +0
	ai_energy CHANSEY,       0, -8
	ai_energy DITTO,         3, +0
	db $00

.list_prize
	db GAMBLER
	db ARTICUNO_LV37
	db $00

.store_list_pointers
	store_list_pointer wAICardListAvoidPrize, .list_prize
	store_list_pointer wAICardListArenaPriority, .list_arena
	store_list_pointer wAICardListBenchPriority, .list_bench
	store_list_pointer wAICardListPlayFromHandPriority, .list_bench
	store_list_pointer wAICardListRetreatBonus, .list_retreat
	store_list_pointer wAICardListEnergyBonus, .list_energy
	ret


; this routine handles how Legendary Articuno
; prioritizes playing energy cards to each Pokémon.
; first, it makes sure that all Lapras have at least
; 3 energy cards before moving on to Articuno,
; and then to Dewgong and Seel
ScoreLegendaryArticunoCards:
	rst SwapTurn
	call CountPrizes
	rst SwapTurn
	cp 3
	ret c

; player prizes >= 3
; if Lapras has more than half HP and enough Energy
; to use each of its attacks, then start with Articuno.
; otherwise, check if Articuno or Dewgong have more than half HP
; and enough Energy to use each of their attacks. If either one does,
; then consider Lapras before moving on to Articuno.
	ld a, LAPRAS
	call CheckForSetUpBenchPokemonWithThisID
	jr c, .articuno
	ld a, ARTICUNO_LV35
	call CheckForSetUpBenchPokemonWithThisID
	jr c, .lapras
	ld a, DEWGONG
	call CheckForSetUpBenchPokemonWithThisID
	jr c, .lapras
	jr .articuno

; the following routines check for certain card IDs in the Bench
; and call RaiseAIScoreToAllMatchingIDsInBench if these are found.
; for Lapras, an additional check is made to its attached Energy count,
; which skips calling the routine if this count is >= 3.
.lapras
	ld a, LAPRAS
	ld b, PLAY_AREA_BENCH_1
	call LookForCardIDInPlayArea_Bank5
	jr nc, .articuno
	ld e, a
	call GetPlayAreaCardAttachedEnergies
	ld a, [wAttachedEnergies + WATER]
	cp 3
	jr nc, .articuno
	ld a, LAPRAS
	jp RaiseAIScoreToAllMatchingIDsInBench

.articuno
	ld a, ARTICUNO_LV35
	ld b, PLAY_AREA_BENCH_1
	call LookForCardIDInPlayArea_Bank5
	jr nc, .dewgong
	ld a, ARTICUNO_LV35
	jp RaiseAIScoreToAllMatchingIDsInBench

.dewgong
	ld a, DEWGONG
	ld b, PLAY_AREA_BENCH_1
	call LookForCardIDInPlayArea_Bank5
	jr nc, .seel
	ld a, DEWGONG
	jp RaiseAIScoreToAllMatchingIDsInBench

.seel
	ld a, SEEL
	ld b, PLAY_AREA_BENCH_1
	call LookForCardIDInPlayArea_Bank5
	ret nc
	ld a, SEEL
	jp RaiseAIScoreToAllMatchingIDsInBench


AIDoTurn_LegendaryArticuno:
; initialize variables
	call InitAITurnVars
	ld a, AI_TRAINER_CARD_PHASE_01
	call AIProcessHandTrainerCards
	call HandleAIAntiMewtwoDeckStrategy
	jr nc, .try_attack
; process Trainer cards
	ld a, AI_TRAINER_CARD_PHASE_02
	call AIProcessHandTrainerCards
; play Pokemon from hand
	call AIDecidePlayPokemonCard
	ret c ; return if turn ended
	call AIProcessRetreat
	ld a, AI_TRAINER_CARD_PHASE_10
	call AIProcessHandTrainerCards
; play Energy card if possible
	ld a, [wOncePerTurnFlags]
	and PLAYED_ENERGY_THIS_TURN
	call z, AIProcessAndTryToPlayEnergy
; play Pokemon from hand again
	call AIDecidePlayPokemonCard
	ret c ; return if turn ended
; process Trainer cards phases 13 and 15
	ld a, AI_TRAINER_CARD_PHASE_13
	call AIProcessHandTrainerCards
	ld a, AI_TRAINER_CARD_PHASE_15
	call AIProcessHandTrainerCards
; if used Professor Oak, process new hand
	ld a, [wPreviousAIFlags]
	and AI_FLAG_USED_PROFESSOR_OAK
	jr z, .try_attack
	ld a, AI_TRAINER_CARD_PHASE_01
	call AIProcessHandTrainerCards
	ld a, AI_TRAINER_CARD_PHASE_02
	call AIProcessHandTrainerCards
	call AIDecidePlayPokemonCard
	ret c ; return if turn ended
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
