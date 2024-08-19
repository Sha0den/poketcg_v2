OpenDuelCheckMenu::
	ldh a, [hBankROM]
	push af
	ld a, BANK(_OpenDuelCheckMenu)
	rst BankswitchROM
	call _OpenDuelCheckMenu
	pop af
	jp BankswitchROM


OpenInPlayAreaScreen_FromSelectButton::
	ldh a, [hBankROM]
	push af
	ld a, BANK(OpenInPlayAreaScreen)
	rst BankswitchROM
	ld a, $1
	ld [wInPlayAreaFromSelectButton], a
	call OpenInPlayAreaScreen
	pop bc
	ld a, b
	jp BankswitchROM


; loads tiles and icons to display Your Play Area / Opp. Play Area screen,
; and draws the screen according to the turn player
; similar to DrawYourOrOppPlayArea (bank 2) except it also draws a wide text box.
; this is because bank 2's DrawYourOrOppPlayArea is supposed to come from the Check Menu,
; so the text box is always already there.
; input:
;	h = hWhoseTurn constant (for wCheckMenuPlayAreaWhichDuelist)
;	l = hWhoseTurn constant (for wCheckMenuPlayAreaWhichLayout)
DrawYourOrOppPlayAreaScreen_Bank0::
	ld a, h
	ld [wCheckMenuPlayAreaWhichDuelist], a
	ld a, l
	ld [wCheckMenuPlayAreaWhichLayout], a
	ldh a, [hBankROM]
	push af
	ld a, BANK(_DrawYourOrOppPlayAreaScreen)
	rst BankswitchROM
	call _DrawYourOrOppPlayAreaScreen
	call DrawWideTextBox
	pop af
	jp BankswitchROM


; input:
;	a = number of prize cards that the player needs to select
SelectPrizeCards::
	ld [wNumberOfPrizeCardsToSelect], a
	ldh a, [hBankROM]
	push af
	ld a, BANK(_SelectPrizeCards)
	rst BankswitchROM
	call _SelectPrizeCards
	pop af
	jp BankswitchROM


DrawPlayAreaToPlacePrizeCards::
	ldh a, [hBankROM]
	push af
	ld a, BANK(_DrawPlayAreaToPlacePrizeCards)
	rst BankswitchROM
	call _DrawPlayAreaToPlacePrizeCards
	pop af
	jp BankswitchROM
