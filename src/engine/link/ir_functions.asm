; input:
;	hl = text ID
LoadLinkConnectingScene:
	push hl
	call SetSpriteAnimationsAsVBlankFunction
	ld a, SCENE_GAMEBOY_LINK_CONNECTING
	lb bc, 0, 0
	call LoadScene
	pop hl
	call DrawWideTextBox_PrintText
	jp EnableLCD


; shows Link Not Connected scene, then asks the player if they want to try again
; input:
;	hl = text ID
; output:
;	carry = set:  if the player selected "No"
LoadLinkNotConnectedSceneAndAskWhetherToTryAgain:
	push hl
	call RestoreVBlankFunction
	call SetSpriteAnimationsAsVBlankFunction
	ld a, SCENE_GAMEBOY_LINK_NOT_CONNECTED
	lb bc, 0, 0
	call LoadScene
	pop hl
	call DrawWideTextBox_WaitForInput
	ldtx hl, WouldYouLikeToTryAgainText
	call YesOrNoMenuWithText_SetCursorToYes
;	fallthrough

; preserves af
ClearRPAndRestoreVBlankFunction:
	push af
	xor a
	ldh [rRP], a
	call RestoreVBlankFunction
	pop af
	ret


; prepares IR communication parameter data
; input:
;	a = IRPARAM_* constant for the function of this connection
InitIRCommunications:
	ld hl, wOwnIRCommunicationParams
	ld [hl], a
	inc hl
	ld [hl], $50
	inc hl
	ld [hl], $4b
	inc hl
	ld [hl], $31
	ld a, $ff
	ld [wIRCommunicationErrorCode], a
	ld a, PLAYER_TURN
	ldh [hWhoseTurn], a
; clear wNameBuffer and wOpponentName
	xor a
	ld [wNameBuffer], a
	ld hl, wOpponentName
	ld [hli], a
	ld [hl], a
; load the Player's name from SRAM to wDefaultText
	call EnableSRAM
	ld hl, sPlayerName
	ld de, wDefaultText
	ld c, NAME_BUFFER_LENGTH
.loop
	ld a, [hli]
	ld [de], a
	inc de
	dec c
	jr nz, .loop
	jp DisableSRAM


; input:
;	a = IRPARAM_* constant
; output:
;	carry = set (& a = $0):  if there was a communication error
;	carry = set (& a = $1):  if the operation was cancelled by the Player
PrepareSendCardOrDeckConfigurationThroughIR:
	call InitIRCommunications

; pressing A button triggers request for IR communication
.loop_frame
	call DoFrame
	ldh a, [hKeysPressed]
	bit B_PAD_B, a
	jr nz, .b_btn
	ldh a, [hKeysHeld]
	bit B_PAD_A, a
	jr z, .loop_frame
; A button
	call TrySendIRRequest
	jr nc, .request_success
	or a
	jr z, .loop_frame
	xor a
	scf
	ret

.b_btn
	; cancelled by the player
	ld a, $01
	scf
	ret

.request_success
	call ExchangeIRCommunicationParameters
	ret c
	ld a, [wOtherIRCommunicationParams + 3]
	cp $31
	jr nz, SetIRCommunicationErrorCode_Error
	or a
	ret


; exchanges player names and IR communication parameters
; checks whether parameters for communication match
; and if they don't, an error is issued
; output:
;	carry = set (& a = $0):  if there was an error
ExchangeIRCommunicationParameters:
	ld hl, wOwnIRCommunicationParams
	ld de, wOtherIRCommunicationParams
	ld c, 4
	call RequestDataTransmissionThroughIR
	jr c, .error
	ld hl, wOtherIRCommunicationParams + 1
	ld a, [hli]
	cp $50
	jr nz, .error
	ld a, [hli]
	cp $4b
	jr nz, .error
	ld a, [wOwnIRCommunicationParams]
	ld hl, wOtherIRCommunicationParams
	cp [hl] ; do parameters match?
	jr nz, SetIRCommunicationErrorCode_Error

; receives wDefaultText from other device
; and writes it to wNameBuffer
	ld hl, wDefaultText
	ld de, wNameBuffer
	ld c, NAME_BUFFER_LENGTH
	call RequestDataTransmissionThroughIR
	jr c, .error
; transmits wDefaultText to be
; written in wNameBuffer in the other device
	ld hl, wDefaultText
	ld de, wNameBuffer
	ld c, NAME_BUFFER_LENGTH
	call RequestDataReceivalThroughIR
	jr c, .error
	or a
	ret

.error
	xor a
	scf
	ret


; output:
;	a = $01
;	carry = set
SetIRCommunicationErrorCode_Error:
	ld hl, wIRCommunicationErrorCode
	ld [hl], $01
	ld de, wIRCommunicationErrorCode
	ld c, 1
	call RequestDataReceivalThroughIR
	call RequestCloseIRCommunication
	ld a, $01
	scf
	ret


; output:
;	carry = set (& a = $ff):  if there was an error
SetIRCommunicationErrorCode_NoError:
	ld hl, wOwnIRCommunicationParams
	ld [hl], $00
	ld de, wIRCommunicationErrorCode
	ld c, 1
	call RequestDataReceivalThroughIR
	ret c
	call RequestCloseIRCommunication
	or a
	ret


; makes device receptive to receive data from other device
; to write in wDuelTempList (either list of cards or a deck configuration)
; input:
;	a = IRPARAM_* constant
; output:
;	carry = set (& a = $0):  if there was an error
;	carry = set (& a = $1):  if the operation was cancelled
TryReceiveCardOrDeckConfigurationThroughIR:
	call InitIRCommunications
.loop_receive_request
	xor a
	ld [wDuelTempList], a
	call TryReceiveIRRequest
	jr nc, .receive_data
	bit 1, a
	jr nz, .cancelled
	jr .loop_receive_request
.receive_data
	call ExecuteReceivedIRCommands
	ld a, [wIRCommunicationErrorCode]
	or a
	ret z ; no error
	xor a
	scf
	ret

.cancelled
	ld a, $01
	scf
	ret


; output:
;	carry = set:  if an error occurred and the Player chose to quit
SendCard::
	call StopMusic
	ldtx hl, SendingACardText
	call LoadLinkConnectingScene
	ld a, IRPARAM_SEND_CARDS
	call PrepareSendCardOrDeckConfigurationThroughIR
	jr c, .fail

	; send cards
	xor a
	ld [wDuelTempList + DECK_SIZE], a
	ld hl, wDuelTempList
	ld e, l
	ld d, h
	ld c, DECK_SIZE + 1
	call RequestDataReceivalThroughIR
	jr c, .fail
	call SetIRCommunicationErrorCode_NoError
	jr c, .fail
	call ExecuteReceivedIRCommands
	jr c, .fail
	ld a, [wOwnIRCommunicationParams + 1]
	cp $4f
	jr nz, .fail
	call PlayCardPopSong
	xor a
	jp ClearRPAndRestoreVBlankFunction

.fail
	call PlayCardPopSong
	ldtx hl, CardTransferWasntSuccessfulText
	call LoadLinkNotConnectedSceneAndAskWhetherToTryAgain
	jr nc, SendCard ; loop back and try again
	; failed
	scf
	ret


; preserves all registers except af
PlayCardPopSong:
	ld a, MUSIC_CARD_POP
	jp PlaySong


; output:
;	carry = set:  if an error occurred and the Player chose to quit
ReceiveCard::
	call StopMusic
	ldtx hl, ReceivingACardText
	call LoadLinkConnectingScene
	ld a, IRPARAM_SEND_CARDS
	call TryReceiveCardOrDeckConfigurationThroughIR
	ld a, $4f
	ld [wOwnIRCommunicationParams + 1], a
	ld hl, wOwnIRCommunicationParams
	ld e, l
	ld d, h
	ld c, 4
	call RequestDataReceivalThroughIR
	jr c, .fail
	call RequestCloseIRCommunication
	jr c, .fail
	call PlayCardPopSong
	or a
	jp ClearRPAndRestoreVBlankFunction

.fail
	call PlayCardPopSong
	ldtx hl, CardTransferWasntSuccessfulText
	call LoadLinkNotConnectedSceneAndAskWhetherToTryAgain
	jr nc, ReceiveCard ; loop back and try again
	scf
	ret


; output:
;	carry = set:  if an error occurred and the Player chose to quit
SendDeckConfiguration::
	call StopMusic
	ldtx hl, SendingADeckConfigurationText
	call LoadLinkConnectingScene
	ld a, IRPARAM_SEND_DECK
	call PrepareSendCardOrDeckConfigurationThroughIR
	jr c, .fail
	ld hl, wDuelTempList
	ld e, l
	ld d, h
	ld c, DECK_STRUCT_SIZE
	call RequestDataReceivalThroughIR
	jr c, .fail
	call SetIRCommunicationErrorCode_NoError
	jr c, .fail
	call PlayCardPopSong
	call ClearRPAndRestoreVBlankFunction
	or a
	ret

.fail
	call PlayCardPopSong
	ldtx hl, DeckConfigurationTransferWasntSuccessfulText
	call LoadLinkNotConnectedSceneAndAskWhetherToTryAgain
	jr nc, SendDeckConfiguration ; loop back and try again
	scf
	ret


; output:
;	carry = set:  if an error occurred and the Player chose to quit
ReceiveDeckConfiguration::
	call StopMusic
	ldtx hl, ReceivingDeckConfigurationText
	call LoadLinkConnectingScene
	ld a, IRPARAM_SEND_DECK
	call TryReceiveCardOrDeckConfigurationThroughIR
	jr c, .fail
	call PlayCardPopSong
	call ClearRPAndRestoreVBlankFunction
	or a
	ret

.fail
	call PlayCardPopSong
	ldtx hl, DeckConfigurationTransferWasntSuccessfulText
	call LoadLinkNotConnectedSceneAndAskWhetherToTryAgain
	jr nc, ReceiveDeckConfiguration ; loop back and try again
	scf
	ret
