DisplayPlayerNamingScreen:
	; clear the name buffer.
	ld hl, wNameBuffer ; c500: name buffer.
	ld b, NAME_BUFFER_LENGTH
	xor a ; TX_END
.clear_loop
	ld [hli], a
	dec b
	jr nz, .clear_loop

	; get player's name from the user into hl
	farcall InputPlayerName

	farcall WhiteOutDMGPals
	call DoFrameIfLCDEnabled
	call DisableLCD
	ld hl, wNameBuffer
	; get the first byte of the name buffer
	ld a, [hl]
	or a
	; check if anything was typed
	jr nz, .got_name

	ld a, EVENT_PLAYER_GENDER
	farcall GetEventValue
	or a
	ld hl, .default_name_male
	jr z, .got_name
	ld hl, .default_name_female

.got_name
	; set the default name
	ld de, sPlayerName
	ld b, NAME_BUFFER_LENGTH
	call EnableSRAM
	call CopyNBytesFromHLToDE
	; this seems to be for checking integrity
	call UpdateRNGSources
	ld [sPlayerName+$e], a
	call UpdateRNGSources
	ld [sPlayerName+$f], a
	jp DisableSRAM

; default male player name that's used if the naming screen is skipped
.default_name_male
	text "Mark"
	done

; default female player name that's used if the naming screen is skipped
.default_name_female
	text "Mint"
	done
