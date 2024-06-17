; preserves all registers except af
SaveGeneralSaveData::
	farcall _SaveGeneralSaveData
	ret


; preserves all registers except af
LoadGeneralSaveData::
	farcall _LoadGeneralSaveData
	ret


; preserves all registers except af
; output:
;	carry = set:  if no error is found in sGeneralSaveData
ValidateGeneralSaveData::
	farcall _ValidateGeneralSaveData
	ret


; adds the card with card ID in register a to the player's collection
; and updates album progress in RAM
; preserves all registers except af
; input:
;	a = ID of card to add to the player's collection
AddCardToCollectionAndUpdateAlbumProgress::
	farcall _AddCardToCollectionAndUpdateAlbumProgress
	ret


; saves the player's progress
; preserves all registers
; input:
;	c = 0:  save the player at their current position
;	c !=0:  save the player in Mason's lab
SaveGame::
	push af
	push bc
;	push de ; not necessary
	push hl
	ld c, $00
	farcall _SaveGame
	pop hl
;	pop de ; not necessary
	pop bc
	pop af
	ret
