ChallengeMachine_Reset:
	call ChallengeMachine_Initialize
	call EnableSRAM
	ld hl, sPlayerInChallengeMachine
	xor a
	ld [hli], a
	ld [hli], a ; sTotalChallengeMachineWins
	ld [hli], a
	ld [hli], a ; sPresentConsecutiveWins
	ld [hli], a
	ld [hli], a ; sPresentConsecutiveWinsBackup
	ld [hl], a
	jp DisableSRAM


; if a challenge is already in progress, then resume the challenge.
; otherwise, start a new challenge with 5 rounds.
ChallengeMachine_Start::
	xor a ; DOUBLE_SPACED
	ld [wLineSeparation], a
	call LoadConsolePaletteData
	call ChallengeMachine_Initialize

	call EnableSRAM
	ld a, [sPlayerInChallengeMachine]
	call DisableSRAM
	cp $ff
	jr z, .resume_challenge

; new challenge
	call ChallengeMachine_PickOpponentSequence
	call ChallengeMachine_DrawScoreScreen
	call FlashWhiteScreen
	ldtx hl, PlayTheChallengeMachineText
	call YesOrNoMenuWithText_SetCursorToYes
	jp c, .end_challenge

	ldtx hl, LetUsChooseYourOpponentText
	call PrintScrollableText_NoTextBoxLabel
	call FadeScreenToWhite
	call EnableSRAM
	xor a
	ld [sPresentConsecutiveWinsBackup], a
	ld [sPresentConsecutiveWinsBackup + 1], a
	call DisableSRAM

	call ChallengeMachine_DrawOpponentList
	call FlashWhiteScreen
	ldtx hl, YourOpponentsForThisGameText
	call PrintScrollableText_NoTextBoxLabel
; begin challenge loop
.next_opponent
	call ChallengeMachine_GetCurrentOpponent
	call ChallengeMachine_AreYouReady
	jr nc, .start_duel
	ldtx hl, IfYouQuitTheDuelText
	call PrintScrollableText_NoTextBoxLabel
	ldtx hl, WouldYouLikeToQuitTheDuelText
	call YesOrNoMenuWithText
	jr c, .next_opponent
	jp .quit

.start_duel
	call EnableSRAM
	ld a, $ff
	ld [sPlayerInChallengeMachine], a
	call DisableSRAM
	call ChallengeMachine_Duel
.resume_challenge
	call EnableSRAM
	xor a
	ld [sPlayerInChallengeMachine], a
	call DiscardSavedDuelData
;	call DisableSRAM ; already called during DiscardSavedDuelData 
	call ChallengeMachine_GetCurrentOpponent
	call ChallengeMachine_RecordDuelResult
	call ChallengeMachine_DrawOpponentList
	call FlashWhiteScreen
	ld a, [wDuelResult]
	or a
	jr nz, .lost
; won
	call ChallengeMachine_DuelWon
	call EnableSRAM
	ld a, [sChallengeMachineOpponentNumber]
	cp NUM_CHALLENGE_MACHINE_OPPONENTS - 1
	jr z, .defeated_five_opponents
	ld hl, sChallengeMachineOpponentNumber
	inc [hl]
	call DisableSRAM
	jr .next_opponent

.defeated_five_opponents
	ld hl, sTotalChallengeMachineWins
	call ChallengeMachine_IncrementHLMax999
	call FadeScreenToWhite
	call ChallengeMachine_CheckForNewRecord
	call ChallengeMachine_DrawScoreScreen
	call FlashWhiteScreen
	call EnableSRAM
	ld a, [sTotalChallengeMachineWins]
	ld [wTxRam3], a
	ld a, [sTotalChallengeMachineWins + 1]
	ld [wTxRam3 + 1], a
	call DisableSRAM
	ldtx hl, SuccessfullyDefeated5OpponentsText
	call PrintScrollableText_NoTextBoxLabel
	jr .end_challenge

.lost
	call ChallengeMachine_GetCurrentOpponent
	call EnableSRAM
	ld a, [sChallengeMachineOpponentNumber]
	inc a
	ld hl, wTxRam3
	ld [hli], a
	xor a
	ld [hl], a
	call DisableSRAM
	call ChallengeMachine_GetOpponentNameAndDeck
	ld a, [wOpponentName]
	ld [wTxRam2], a
	ld a, [wOpponentName + 1]
	ld [wTxRam2 + 1], a
	ldtx hl, LostToTheNthOpponentText
	call PrintScrollableText_NoTextBoxLabel
.quit
	call ChallengeMachine_PrintFinalConsecutiveWinStreak
	call FadeScreenToWhite
	call ChallengeMachine_CheckForNewRecord
	call ChallengeMachine_DrawScoreScreen
	call FlashWhiteScreen
	call EnableSRAM
; reset streak
	xor a
	ld [sPresentConsecutiveWins], a
	ld [sPresentConsecutiveWins + 1], a
	call DisableSRAM
.end_challenge ; end, win or lose
	call EnableSRAM
	ld a, [sPresentConsecutiveWins]
	ld [sPresentConsecutiveWinsBackup], a
	ld a, [sPresentConsecutiveWins + 1]
	ld [sPresentConsecutiveWinsBackup + 1], a
	call ChallengeMachine_ShowNewRecord
	call DisableSRAM
	ldtx hl, WeAwaitYourNextChallengeText
	jp PrintScrollableText_NoTextBoxLabel


; updates wChallengeMachineOpponent with the current
; opponent in the sChallengeMachineOpponents list
; preserves bc
; input:
;	sChallengeMachineOpponents = list with indices for ChallengeMachine_OpponentDeckIDs
;	[sChallengeMachineOpponentNumber] = position in the current challenge (0-4)
; output:
;	[wChallengeMachineOpponent] = ChallengeMachine_OpponentDeckIDs index for next opponent
ChallengeMachine_GetCurrentOpponent:
	call EnableSRAM
	ld a, [sChallengeMachineOpponentNumber]
	ld e, a
	ld d, 0
	ld hl, sChallengeMachineOpponents
	add hl, de
	ld a, [hl]
	ld [wChallengeMachineOpponent], a
	jp DisableSRAM


; plays the appropriate match start theme,
; then initiates a duel with the current opponent
; input:
;	[sChallengeMachineOpponentNumber] = position in the current challenge (0-4)
ChallengeMachine_Duel:
	call ChallengeMachine_PrepareDuel
	call EnableSRAM
	ld a, [sChallengeMachineOpponentNumber]
	ld e, a
	call DisableSRAM
	ld d, 0
	ld hl, ChallengeMachine_SongIDs
	add hl, de
	ld a, [hl]
	call PlaySong
	call WaitForSongToFinish
	xor a
	ld [wSongOverride], a
	call SaveGeneralSaveData
	bank1call StartDuel_VSAIOpp
	ret

ChallengeMachine_SongIDs:
	db MUSIC_MATCH_START_1
	db MUSIC_MATCH_START_1
	db MUSIC_MATCH_START_1
	db MUSIC_MATCH_START_2
	db MUSIC_MATCH_START_2


; get the current opponent's name, deck, and prize count
; preserves bc
; input:
;	[sChallengeMachineOpponentNumber] = position in the current challenge (0-4)
;	[wChallengeMachineOpponent] = index for ChallengeMachine_OpponentDeckIDs
; output:
;	[wNPCDuelPrizes] = number of Prize cards to use in the upcoming duel
ChallengeMachine_PrepareDuel:
	call ChallengeMachine_GetOpponentNameAndDeck
	call EnableSRAM
	ld a, [sChallengeMachineOpponentNumber]
	ld e, a
	call DisableSRAM
	ld d, 0
	ld hl, ChallengeMachine_Prizes
	add hl, de
	ld a, [hl]
	ld [wNPCDuelPrizes], a
	ret

ChallengeMachine_Prizes:
	db PRIZES_4
	db PRIZES_4
	db PRIZES_4
	db PRIZES_6
	db PRIZES_6


; stores the result of the last duel in the current
; position of the sChallengeMachineDuelResults list
; preserves bc
; input:
;	[sChallengeMachineOpponentNumber] = position in the current challenge (0-4)
;	[wDuelResult] = outcome of last duel (0 = win, 1 = loss)
; output:
;	[sChallengeMachineDuelResults + sChallengeMachineOpponentNumber] = 1:  if the Player won the duel
;	[sChallengeMachineDuelResults + sChallengeMachineOpponentNumber] = 2:  if the Player lost the duel
;	[sPresentConsecutiveWins] += 1:  if the Player won the duel
ChallengeMachine_RecordDuelResult:
	call EnableSRAM
	ld a, [sChallengeMachineOpponentNumber]
	ld e, a
	ld d, 0
	ld hl, sChallengeMachineDuelResults
	add hl, de
	ld a, [wDuelResult]
	or a
	jr z, .won
	ld a, 2 ; lost
	ld [hl], a
	jp DisableSRAM
.won
	ld a, 1 ; won
	ld [hl], a
	call DisableSRAM
	ld hl, sPresentConsecutiveWins
;	fallthrough

; increments the value at hl without going above 999
; input:
;	[hl] = number to increase by 1
ChallengeMachine_IncrementHLMax999:
	call EnableSRAM
	inc hl
	ld a, [hld]
	cp HIGH(999)
	jr nz, .increment
	ld a, [hl]
	cp LOW(999)
	jp z, DisableSRAM ; done
.increment
	ld a, [hl]
	add 1
	ld [hli], a
	ld a, [hl]
	adc 0
	ld [hl], a
	jp DisableSRAM


; updates sMaximumConsecutiveWins if the player set a new record
ChallengeMachine_CheckForNewRecord:
	call EnableSRAM
	ld hl, sMaximumConsecutiveWins + 1
	ld a, [sPresentConsecutiveWins + 1]
	cp [hl]
	jr nz, .high_bytes_different
; high bytes equal, check low bytes
	dec hl
	ld a, [sPresentConsecutiveWins]
	cp [hl]
.high_bytes_different
	jp c, DisableSRAM ; no record
	jp z, DisableSRAM ; no record
; new record
	ld hl, sMaximumConsecutiveWins
	ld a, [sPresentConsecutiveWins]
	ld [hli], a
	ld a, [sPresentConsecutiveWins + 1]
	ld [hl], a
	ld hl, sPlayerName
	ld de, sChallengeMachineRecordHolderName
	ld b, NAME_BUFFER_LENGTH
	call CopyNBytesFromHLToDE
; remember to show congrats message later
	ld a, TRUE
	ld [sConsecutiveWinRecordIncreased], a
	jp DisableSRAM


; prints the next opponent's name and asks the
; player if they want to begin the next duel
; input:
;	[sChallengeMachineOpponentNumber] = position in the current challenge (0-4)
;	[sPresentConsecutiveWins] = current win streak (2 bytes)
ChallengeMachine_AreYouReady:
	call EnableSRAM
	ld a, [sChallengeMachineOpponentNumber]
	inc a
	ld [wTxRam3], a
	ld [wTxRam3_b], a
	xor a
	ld [wTxRam3 + 1], a
	ld [wTxRam3_b + 1], a
	ldtx hl, NthOpponentIsText
	ld a, [sPresentConsecutiveWins + 1]
	or a
	jr nz, .streak
	ld a, [sPresentConsecutiveWins]
	cp 2
	jr c, .no_streak
.streak
	ldtx hl, XConsecutiveWinsNthOpponentIsText
	ld a, [sPresentConsecutiveWins]
	ld [wTxRam3], a
	ld a, [sPresentConsecutiveWins + 1]
	ld [wTxRam3 + 1], a
.no_streak
	call DisableSRAM
	push hl ; text ID
	call ChallengeMachine_GetOpponentNameAndDeck
	ld a, [wOpponentName]
	ld [wTxRam2], a
	ld a, [wOpponentName + 1]
	ld [wTxRam2 + 1], a
	pop hl ; text ID
	call PrintScrollableText_NoTextBoxLabel
	ldtx hl, WouldYouLikeToBeginTheDuelText
	jp YesOrNoMenuWithText_SetCursorToYes


; prints opponent win count and plays a jingle for beating 5 opponents
; input:
;	[sChallengeMachineOpponentNumber] = position in the current challenge (0-4)
ChallengeMachine_DuelWon:
	call EnableSRAM
	ld a, [sChallengeMachineOpponentNumber]
	inc a
	ld hl, wTxRam3
	ld [hli], a
	xor a
	ld [hl], a
	ldtx hl, WonAgainstXOpponentsText
	ld a, [sChallengeMachineOpponentNumber]
	call DisableSRAM
	cp NUM_CHALLENGE_MACHINE_OPPONENTS - 1
	jr z, .beat_five_opponents
	jp PrintScrollableText_NoTextBoxLabel

.beat_five_opponents
	call PauseSong
	ld a, MUSIC_MEDAL
	call PlaySong
	ldtx hl, Defeated5OpponentsText
	call PrintScrollableText_NoTextBoxLabel
	call WaitForSongToFinish
	jp ResumeSong


; when a player's streak ends, this is called to print the final consecutive win count
; input:
;	[sPresentConsecutiveWins] = current win streak (2 bytes)
ChallengeMachine_PrintFinalConsecutiveWinStreak:
	call EnableSRAM
	ld a, [sPresentConsecutiveWins]
	ld [wTxRam3], a
	ld a, [sPresentConsecutiveWins + 1]
	ld [wTxRam3 + 1], a
	or a
	jr nz, .streak
	ld a, [sPresentConsecutiveWins]
	cp 2
	jp c, DisableSRAM ; no streak
.streak
	ldtx hl, ConsecutiveWinsEndedAtText
	call PrintScrollableText_NoTextBoxLabel
	jp DisableSRAM


; plays a jingle if the player achieved a new record
; input:
;	[sConsecutiveWinRecordIncreased] = 0:  return without doing anything
;	[sMaximumConsecutiveWins] = current high score
ChallengeMachine_ShowNewRecord:
	call EnableSRAM
	ld a, [sConsecutiveWinRecordIncreased]
	or a
	ret z ; no new record
	ld a, [sMaximumConsecutiveWins]
	ld [wTxRam3], a
	ld a, [sMaximumConsecutiveWins + 1]
	ld [wTxRam3 + 1], a
	call DisableSRAM
	call PauseSong
	ld a, MUSIC_MEDAL
	call PlaySong
	ldtx hl, ConsecutiveWinRecordIncreasedText
	call PrintScrollableText_NoTextBoxLabel
	call WaitForSongToFinish
	jp ResumeSong


ChallengeMachine_DrawScoreScreen:
	call InitMenuScreen
	lb de, $30, $bf
	call SetupText
	lb de,  0,  0
	lb bc, 20, 13
	call DrawRegularTextBox
	lb de,  0, 12
	lb bc, 20,  6
	call DrawRegularTextBox
	call EnableSRAM
	ld hl, sChallengeMachineRecordHolderName
	ld de, wDefaultText
	ld b, NAME_BUFFER_LENGTH
	call CopyNBytesFromHLToDE
	call DisableSRAM
	; zero wTxRam2 so that the name just loaded to wDefaultText is printed
	ld hl, wTxRam2
	xor a
	ld [hli], a
	ld [hl], a
	ld hl, ChallengeMachine_PlayerScoreLabels
	call PrintLabels
	ld hl, ChallengeMachine_PlayerScoreValues
;	fallthrough

; prints all scores in the table pointed to by hl
; input:
;	hl = pointer for a $0000 terminated table with the following format:
;	     2-byte pointer for a 16-bit number in SRAM, x coordinate, y coordinate
ChallengeMachine_PrintScores:
.loop
	call EnableSRAM
	ld a, [hli]
	ld e, a
	ld a, [hli]
	ld d, a
	or e
	jp z, DisableSRAM; done
	ld b, [hl]
	inc hl
	ld c, [hl]
	inc hl
	push hl
	push bc
	ld a, [de]
	ld l, a
	inc de
	ld a, [de]
	ld h, a
	call ThreeDigitNumberToTxSymbol_TrimLeadingZeros
	pop bc
	call BCCoordToBGMap0Address
	ld hl, wDecimalChars
	ld b, 3
	call SafeCopyDataHLtoDE
	pop hl
	jr .loop


ChallengeMachine_PlayerScoreLabels:
	db 1, 0
	tx ChallengeMachineText

	db 1, 2
	tx PlayersScoreText

	db 2, 4
	tx Defeated5OpponentsXTimesText

	db 2, 6
	tx PresentConsecutiveWinsText

	db 1, 8
	tx MaximumConsecutiveWinsText

	db 17, 6
	tx WinsText

	db 16, 10
	tx WinsText
	db $ff


ChallengeMachine_PlayerScoreValues:
	dw sTotalChallengeMachineWins
	db 12, 4

	dw sPresentConsecutiveWins
	db 14, 6

	dw sMaximumConsecutiveWins
	db 13, 10

	dw NULL


ChallengeMachine_DrawOpponentList:
	call InitMenuScreen
	lb de, $30, $bf
	call SetupText
	lb de,  0,  0
	lb bc, 20, 13
	call DrawRegularTextBox
	lb de,  0, 12
	lb bc, 20,  6
	call DrawRegularTextBox
	ld hl, ChallengeMachine_OpponentNumberLabels
	call PrintLabels
	call ChallengeMachine_PrintOpponentInfo
;	fallthrough

; input:
;	sChallengeMachineDuelResults = list of wins/losses (1 = win, 2 = loss, 0 = duel pending)
ChallengeMachine_PrintDuelResultIcons:
	ld hl, sChallengeMachineDuelResults
	ld c, NUM_CHALLENGE_MACHINE_OPPONENTS ; loop counter
	lb de, 1, 2 ; starting screen coordinates
.print_loop
	push hl
	push bc
	push de
	call InitTextPrinting
	call EnableSRAM
	ld a, [hl]
	add a
	ld e, a
	ld d, 0
	ld hl, ChallengeMachine_DuelResultIcons
	add hl, de
	ld a, [hli]
	ld h, [hl]
	ld l, a
	call PrintTextNoDelay
	pop de
	pop bc
	pop hl
	inc hl
	; down two rows
	inc e
	inc e
	dec c
	jr nz, .print_loop
	jp DisableSRAM

ChallengeMachine_DuelResultIcons:
	tx ChallengeMachineNotDuelledIconText
	tx ChallengeMachineDuelWonIconText
	tx ChallengeMachineDuelLostIconText


ChallengeMachine_OpponentNumberLabels:
	db 1, 0
	tx ChallengeMachineText

	db 2, 2
	tx ChallengeMachineOpponent1Text

	db 2, 4
	tx ChallengeMachineOpponent2Text

	db 2, 6
	tx ChallengeMachineOpponent3Text

	db 2, 8
	tx ChallengeMachineOpponent4Text

	db 2, 10
	tx ChallengeMachineOpponent5Text
	db $ff


; input:
;	sChallengeMachineOpponents = list with indices for ChallengeMachine_OpponentDeckIDs
ChallengeMachine_PrintOpponentInfo:
	ld hl, sChallengeMachineOpponents
	lb bc, 0, 2 ; starting screen coordinates
	ld e, NUM_CHALLENGE_MACHINE_OPPONENTS ; loop counter
.loop
	push hl
	push bc
	push de
	call EnableSRAM
	ld a, [hl]
	ld [wChallengeMachineOpponent], a
	ld b, 14 ; x-position
	call ChallengeMachine_PrintOpponentName
	ld b, 4 ; x-position
	call ChallengeMachine_PrintOpponentClubStatus
	pop de
	pop bc
	pop hl
	inc hl ; next opponent
	; move down two rows
	inc c
	inc c
	dec e ; decrement loop counter
	jr nz, .loop
	jp DisableSRAM


; preserves bc
; input:
;	bc = screen coordinates at which to start printing the text
;	[wChallengeMachineOpponent] = index for ChallengeMachine_OpponentDeckIDs
; output:
;	de = screen coordinates from input bc
ChallengeMachine_PrintOpponentName:
	push bc
	call ChallengeMachine_GetOpponentNameAndDeck
	ld de, 2 ; name
	add hl, de
	call ChallengeMachine_PrintText
	pop bc
	ret


; input:
;	bc = screen coordinates at which to start printing the text
;	[hl] = text ID
; output:
;	de = screen coordinates from input bc
ChallengeMachine_PrintText:
	ld a, [hli]
	ld h, [hl]
	ld l, a
	ld e, c
	ld d, b
	push de
	call InitTextPrinting_PrintTextNoDelay
	pop de
	ret


; prints the opponent's rank (e.g. Club Member) and element (Club's Energy Symbol)
; preserves bc
; input:
;	[wChallengeMachineOpponent] = index for ChallengeMachine_OpponentDeckIDs
ChallengeMachine_PrintOpponentClubStatus:
	push bc
	call ChallengeMachine_GetOpponentNameAndDeck
	push hl
	ld de, 6 ; rank
	add hl, de
	call ChallengeMachine_PrintText
	ld a, d
	add $07
	ld d, a
	pop hl
	ld bc, 8 ; element
	add hl, bc
	ld a, [hli]
	ld h, [hl]
	ld l, a
	or h
	call nz, InitTextPrinting_PrintTextNoDelay
	pop bc
	ret


; preserves bc and de
; input:
;	[wChallengeMachineOpponent] = index for ChallengeMachine_OpponentDeckIDs
; output:
;	hl = pointer for an entry from DeckIDDuelConfigurations
ChallengeMachine_GetOpponentNameAndDeck:
	push de
	ld a, [wChallengeMachineOpponent]
	ld e, a
	ld d, 0
	ld hl, ChallengeMachine_OpponentDeckIDs
	add hl, de
	ld a, [hl]
	ld [wNPCDuelDeckID], a
	call _GetChallengeMachineDuelConfigurations
	pop de
	ret


; if this is the first time the Challenge Machine has ever been used on this cartridge,
; then clear all variables and set Dr. Mason as the record holder.
ChallengeMachine_Initialize:
	call EnableSRAM
	ld a, [sChallengeMachineMagic]
	cp $e3
	jr nz, .init_vars
	ld a, [sChallengeMachineMagic + 1]
	cp $95
	jr z, .done

.init_vars
	ld hl, sChallengeMachineMagic
	ld c, sChallengeMachineEnd - sChallengeMachineStart
	ld a, $e3
	ld [hli], a
	ld a, $95
	ld [hli], a

	xor a
.clear_loop
	ld [hli], a
	dec c
	jr nz, .clear_loop

	ld hl, ChallengeMachine_DrMasonText
	ld de, sChallengeMachineRecordHolderName
	ld bc, NAME_BUFFER_LENGTH
	call CopyDataHLtoDE_SaveRegisters
	ld a, 1
	ld [sMaximumConsecutiveWins], a
	xor a
	ld [sMaximumConsecutiveWins + 1], a

.done
	ld a, [sPlayerInChallengeMachine]
	jp DisableSRAM

ChallengeMachine_DrMasonText:
	text "Dr. Mason", TX_END, TX_END, TX_END, TX_END, TX_END, TX_END


; picks the next opponent sequence and clears challenge variables
; preserves de
; output:
;	sChallengeMachineOpponents = list with (5) indices for ChallengeMachine_OpponentDeckIDs
ChallengeMachine_PickOpponentSequence:
	call EnableSRAM

; pick first opponent
	ld a, CLUB_MASTERS_START
	call Random
	ld [sChallengeMachineOpponents], a

.pick_second_opponent
	ld a, CLUB_MASTERS_START
	call Random
	ld c, 1
	call ChallengeMachine_CheckIfOpponentAlreadySelected
	jr c, .pick_second_opponent
	ld [sChallengeMachineOpponents + 1], a

.pick_third_opponent
	ld a, CLUB_MASTERS_START
	call Random
	ld c, 2
	call ChallengeMachine_CheckIfOpponentAlreadySelected
	jr c, .pick_third_opponent
	ld [sChallengeMachineOpponents + 2], a

; pick fourth opponent
	ld a, GRAND_MASTERS_START - CLUB_MASTERS_START
	call Random
	add CLUB_MASTERS_START
	ld [sChallengeMachineOpponents + 3], a

; pick fifth opponent
	call UpdateRNGSources
	ld hl, ChallengeMachine_FinalOpponentProbabilities
.next
	sub [hl]
	jr c, .got_opponent
	inc hl
	inc hl
	jr .next
.got_opponent
	inc hl
	ld a, [hl]
	ld [sChallengeMachineOpponents + 4], a

	xor a
	ld [sChallengeMachineOpponentNumber], a
	ld [sConsecutiveWinRecordIncreased], a
	ld hl, sChallengeMachineDuelResults
	ld c, NUM_CHALLENGE_MACHINE_OPPONENTS
.clear_results
	ld [hli], a
	dec c
	jr nz, .clear_results
	ld a, [sPresentConsecutiveWinsBackup]
	ld [sPresentConsecutiveWins], a
	ld a, [sPresentConsecutiveWinsBackup + 1]
	ld [sPresentConsecutiveWins + 1], a
	jp DisableSRAM

ChallengeMachine_FinalOpponentProbabilities:
	db  56, GRAND_MASTERS_START + 0 ; 56/256, courtney
	db  56, GRAND_MASTERS_START + 1 ; 56/256, steve
	db  56, GRAND_MASTERS_START + 2 ; 56/256, jack
	db  56, GRAND_MASTERS_START + 3 ; 56/256, rod
	db   8, GRAND_MASTERS_START + 4 ;  8/256, aaron
	db   8, GRAND_MASTERS_START + 5 ;  8/256, aaron
	db   8, GRAND_MASTERS_START + 6 ;  8/256, aaron
	db 255, GRAND_MASTERS_START + 7 ;  8/256, imakuni (catch-all)


; preserves de
; input:
;	a = index for ChallengeMachine_OpponentDeckIDs
;	c = how many entries need to be checked for duplicates
;	sChallengeMachineOpponents = list with indices for ChallengeMachine_OpponentDeckIDs
; output:
;	carry = set:  if the opponent in a is already among the first c opponents in sChallengeMachineOpponents
ChallengeMachine_CheckIfOpponentAlreadySelected:
	ld hl, sChallengeMachineOpponents
.loop
	cp [hl]
	jr z, .found
	inc hl
	dec c
	jr nz, .loop
; not found
	or a
	ret
.found
	scf
	ret


ChallengeMachine_OpponentDeckIDs:
.club_members
	db MUSCLES_FOR_BRAINS_DECK_ID
	db HEATED_BATTLE_DECK_ID
	db LOVE_TO_BATTLE_DECK_ID
	db EXCAVATION_DECK_ID
	db BLISTERING_POKEMON_DECK_ID
	db HARD_POKEMON_DECK_ID
	db WATERFRONT_POKEMON_DECK_ID
	db LONELY_FRIENDS_DECK_ID
	db SOUND_OF_THE_WAVES_DECK_ID
	db PIKACHU_DECK_ID
	db BOOM_BOOM_SELFDESTRUCT_DECK_ID
	db POWER_GENERATOR_DECK_ID
	db ETCETERA_DECK_ID
	db FLOWER_GARDEN_DECK_ID
	db KALEIDOSCOPE_DECK_ID
	db GHOST_DECK_ID
	db NAP_TIME_DECK_ID
	db STRANGE_POWER_DECK_ID
	db FLYIN_POKEMON_DECK_ID
	db LOVELY_NIDORAN_DECK_ID
	db POISON_DECK_ID
	db ANGER_DECK_ID
	db FLAMETHROWER_DECK_ID
	db RESHUFFLE_DECK_ID
.club_masters
	db FIRST_STRIKE_DECK_ID
	db ROCK_CRUSHER_DECK_ID
	db GO_GO_RAIN_DANCE_DECK_ID
	db ZAPPING_SELFDESTRUCT_DECK_ID
	db FLOWER_POWER_DECK_ID
	db STRANGE_PSYSHOCK_DECK_ID
	db WONDERS_OF_SCIENCE_DECK_ID
	db FIRE_CHARGE_DECK_ID
.grand_masters
	db LEGENDARY_MOLTRES_DECK_ID
	db LEGENDARY_ZAPDOS_DECK_ID
	db LEGENDARY_ARTICUNO_DECK_ID
	db LEGENDARY_DRAGONITE_DECK_ID
	db LIGHTNING_AND_FIRE_DECK_ID
	db WATER_AND_FIGHTING_DECK_ID
	db GRASS_AND_PSYCHIC_DECK_ID
	db IMAKUNI_DECK_ID

DEF CLUB_MASTERS_START  EQU ChallengeMachine_OpponentDeckIDs.club_masters - ChallengeMachine_OpponentDeckIDs.club_members
DEF GRAND_MASTERS_START EQU ChallengeMachine_OpponentDeckIDs.grand_masters - ChallengeMachine_OpponentDeckIDs.club_members
