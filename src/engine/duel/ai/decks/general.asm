; AI logic used by general decks
AIActionTable_GeneralDecks:
	dw AIMainTurnLogic                ; .do_turn (unused)
	dw AIMainTurnLogic                ; .do_turn
	dw .start_duel
	dw AIDecideBenchPokemonToSwitchTo ; .forced_switch
	dw AIDecideBenchPokemonToSwitchTo ; .ko_switch
	dw AIPickPrizeCards               ; .take_prize

.start_duel
	call InitAIDuelVars
	jp AIPlayInitialBasicCards


; handle AI routines for a whole turn
AIMainTurnLogic:
; initialize variables
	call InitAITurnVars
	ld a, AI_TRAINER_CARD_PHASE_01
	call AIProcessHandTrainerCards
	call HandleAIAntiMewtwoDeckStrategy
	jp nc, .try_attack
; handle Pkmn Powers
	farcall HandleAIGoGoRainDanceEnergy
	farcall HandleAIDamageSwap
	farcall HandleAIPkmnPowers
	ret c ; return if turn ended
; process Trainer cards
; phase 2 through 4.
	ld a, AI_TRAINER_CARD_PHASE_02
	call AIProcessHandTrainerCards
	ld a, AI_TRAINER_CARD_PHASE_03
	call AIProcessHandTrainerCards
	ld a, AI_TRAINER_CARD_PHASE_04
	call AIProcessHandTrainerCards
; play Pokemon from hand
	call AIDecidePlayPokemonCard
	ret c ; return if turn ended
; process Trainer cards
; phase 5 through 12.
	ld a, AI_TRAINER_CARD_PHASE_05
	call AIProcessHandTrainerCards
	ld a, AI_TRAINER_CARD_PHASE_06
	call AIProcessHandTrainerCards
	ld a, AI_TRAINER_CARD_PHASE_07
	call AIProcessHandTrainerCards
	ld a, AI_TRAINER_CARD_PHASE_08
	call AIProcessHandTrainerCards
	call AIProcessRetreat
	ld a, AI_TRAINER_CARD_PHASE_10
	call AIProcessHandTrainerCards
	ld a, AI_TRAINER_CARD_PHASE_11
	call AIProcessHandTrainerCards
	ld a, AI_TRAINER_CARD_PHASE_12
	call AIProcessHandTrainerCards
; play Energy card if possible
	ld a, [wOncePerTurnFlags]
	and PLAYED_ENERGY_THIS_TURN
	call z, AIProcessAndTryToPlayEnergy
; play Pokemon from hand again
	call AIDecidePlayPokemonCard
	ret c ; return if turn ended
; handle Pkmn Powers again
	farcall HandleAIDamageSwap
	farcall HandleAIPkmnPowers
	ret c ; return if turn ended
	farcall HandleAIGoGoRainDanceEnergy
	ld a, AI_ENERGY_TRANS_ATTACK
	farcall HandleAIEnergyTrans
; process Trainer cards phases 13 and 15
	ld a, AI_TRAINER_CARD_PHASE_13
	call AIProcessHandTrainerCards
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
	ld a, AI_TRAINER_CARD_PHASE_03
	call AIProcessHandTrainerCards
	ld a, AI_TRAINER_CARD_PHASE_04
	call AIProcessHandTrainerCards
	call AIDecidePlayPokemonCard
	ret c ; return if turn ended
	ld a, AI_TRAINER_CARD_PHASE_05
	call AIProcessHandTrainerCards
	ld a, AI_TRAINER_CARD_PHASE_06
	call AIProcessHandTrainerCards
	ld a, AI_TRAINER_CARD_PHASE_07
	call AIProcessHandTrainerCards
	ld a, AI_TRAINER_CARD_PHASE_08
	call AIProcessHandTrainerCards
	call AIProcessRetreat
	ld a, AI_TRAINER_CARD_PHASE_10
	call AIProcessHandTrainerCards
	ld a, AI_TRAINER_CARD_PHASE_11
	call AIProcessHandTrainerCards
	ld a, AI_TRAINER_CARD_PHASE_12
	call AIProcessHandTrainerCards
	ld a, [wOncePerTurnFlags]
	and PLAYED_ENERGY_THIS_TURN
	call z, AIProcessAndTryToPlayEnergy
	call AIDecidePlayPokemonCard
	ret c ; return if turn ended
	farcall HandleAIDamageSwap
	farcall HandleAIPkmnPowers
	ret c ; return if turn ended
	farcall HandleAIGoGoRainDanceEnergy
	ld a, AI_ENERGY_TRANS_ATTACK
	farcall HandleAIEnergyTrans
	ld a, AI_TRAINER_CARD_PHASE_13
	call AIProcessHandTrainerCards
	; skip AI_TRAINER_CARD_PHASE_15
.try_attack
	ld a, AI_ENERGY_TRANS_TO_BENCH
	farcall HandleAIEnergyTrans
; attack if possible, if not,
; finish turn without attacking.
	call AIProcessAndTryToUseAttack
	ret c ; return if AI attacked
	ld a, OPPACTION_FINISH_NO_ATTACK
	bank1call AIMakeDecision
	ret


; handles AI retreating logic
AIProcessRetreat:
	ld a, [wAIRetreatedThisTurn]
	or a
	ret nz ; return, already retreated this turn

	call AIDecideWhetherToRetreat
	ret nc ; return if not retreating

	call AIDecideBenchPokemonToSwitchTo
	ret c ; return if no Bench Pokemon

; store Play Area to retreat to and
; set wAIRetreatedThisTurn to true
	ld [wAIPlayAreaCardToSwitch], a
	ld a, TRUE
	ld [wAIRetreatedThisTurn], a
	ld hl, wPreviousAIFlags
	res 0, [hl] ; clear AI_FLAG_USED_PLUSPOWER so preselected attack will be ignored

; if AI can use Switch from hand, use it instead...
	ld a, AI_TRAINER_CARD_PHASE_09
	call AIProcessHandTrainerCards
	ld a, [wPreviousAIFlags]
	and AI_FLAG_USED_SWITCH
	jr nz, .used_switch
; ... else try retreating normally.
	ld a, AI_ENERGY_TRANS_RETREAT
	farcall HandleAIEnergyTrans
	ld a, [wAIPlayAreaCardToSwitch]
	jp AITryToRetreat

.used_switch
; if AI used switch, unset its AI flag
	ld a, [wPreviousAIFlags]
	and ~AI_FLAG_USED_SWITCH ; clear Switch flag
	ld [wPreviousAIFlags], a
	ret
