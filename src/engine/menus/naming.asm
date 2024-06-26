DisplayPlayerNamingScreen:
	; clear the name buffer.
	ld hl, wNameBuffer ; c500: name buffer.
	ld bc, NAME_BUFFER_LENGTH
	ld a, TX_END
	call FillMemoryWithA

	; get player's name from the user into hl
	ld hl, wNameBuffer
	farcall InputPlayerName

	farcall WhiteOutDMGPals
	call DoFrameIfLCDEnabled
	call DisableLCD
	ld hl, wNameBuffer
	; get the first byte of the name buffer
	ld a, [hl]
	or a
	; check if anything was typed
	jr nz, .no_name
	ld hl, .default_name
.no_name
	; set the default name
	ld de, sPlayerName
	ld bc, NAME_BUFFER_LENGTH
	call EnableSRAM
	call CopyDataHLtoDE_SaveRegisters
	; this seems to be for checking integrity
	call UpdateRNGSources
	ld [sPlayerName+$e], a
	call UpdateRNGSources
	ld [sPlayerName+$f], a
	jp DisableSRAM

; the default player name, only used if the player didn't type anything
.default_name
	text "Mark"
	done
