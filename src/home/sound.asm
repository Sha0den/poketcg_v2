SetupSound::
	farcall _SetupSound
	ret


; preserves all registers except af
StopMusic::
	xor a ; MUSIC_STOP
;	fallthrough

; preserves all registers
; input:
;	a = music ID to play (MUSIC_* constant)
PlaySong::
	farcall _PlaySong
	ret


; preserves all registers except af
; output:
;	a = 0:  if the song has finished
;	a = 1:  if the song is still playing
AssertSongFinished::
	farcall _AssertSongFinished
	ret


; preserves all registers except af
; output:
;	a = 0:  if the SFX has finished
;	a = 1:  if the SFX is still playing
AssertSFXFinished::
	farcall _AssertSFXFinished
	ret


; preserves all registers except af
PlaySFX_InvalidChoice::
	ld a, SFX_DENIED
;	fallthrough

; preserves all registers except af
; input:
;	a = sound effect ID (SFX_* constant)
PlaySFX::
	farcall _PlaySFX
	ret


PauseSong::
	farcall _PauseSong
	ret


ResumeSong::
	farcall _ResumeSong
	ret


; preserves all registers except af
PlayDefaultSong::
	push hl
	push bc
	call AssertSongFinished
	or a
	push af
	call GetDefaultSong
	ld c, a
	pop af
	jr z, .asm_3a11
	ld a, c
	ld hl, wSongOverride
	cp [hl]
	jr z, .asm_3a1c
.asm_3a11
	ld a, c
	cp NUM_SONGS
	jr nc, .asm_3a1c
	ld [wSongOverride], a
	call PlaySong
.asm_3a1c
	pop bc
	pop hl
	ret


; preserves all registers except af
; output:
;	a = MUSIC_RONALD:  if Ronald is on the map and it's not Ishihara's House, Challenge Hall, or Pokemon Dome
;	a = [wDefaultSong]:  if none of the above conditions are true
GetDefaultSong::
	ld a, [wRonaldIsInMap]
	or a
	jr z, .default_song
	; only set Ronald's theme if it's not in one of the following maps
	ld a, [wOverworldMapSelection]
	cp OWMAP_ISHIHARAS_HOUSE
	jr z, .default_song
	cp OWMAP_CHALLENGE_HALL
	jr z, .default_song
	cp OWMAP_POKEMON_DOME
	jr z, .default_song
	ld a, MUSIC_RONALD
	ret
.default_song
	ld a, [wDefaultSong]
	ret


; preserves all registers except af
WaitForSongToFinish::
	call DoFrameIfLCDEnabled
	call AssertSongFinished
	or a
	jr nz, WaitForSongToFinish
	ret


Func_37a5::
	ldh a, [hBankROM]
	push af
	push hl
	srl h
	srl h
	srl h
	ld a, BANK(CardGraphics)
	add h
	rst BankswitchROM
	pop hl
	add hl, hl
	add hl, hl
	add hl, hl
	res 7, h
	set 6, h ; $4000 ≤ hl ≤ $7fff
	call Func_37c5
	pop af
	jp BankswitchROM

Func_37c5::
	ld c, $08
.asm_37c7
	ld b, $06
.asm_37c9
	push bc
	ld c, $08
.asm_37cc
	ld b, $02
.asm_37ce
	push bc
	push hl
	ld c, [hl]
	ld b, $04
.asm_37d3
	rr c
	rra
	sra a
	dec b
	jr nz, .asm_37d3
	ld hl, $c0
	add hl, de
	ld [hli], a
	inc hl
	ld [hl], a
	ld b, $04
.asm_37e4
	rr c
	rra
	sra a
	dec b
	jr nz, .asm_37e4
	ld [de], a
	ld hl, $2
	add hl, de
	ld [hl], a
	pop hl
	pop bc
	inc de
	inc hl
	dec b
	jr nz, .asm_37ce
	inc de
	inc de
	dec c
	jr nz, .asm_37cc
	pop bc
	dec b
	jr nz, .asm_37c9
	ld a, $c0
	add e
	ld e, a
	ld a, $00
	adc d
	ld d, a
	dec c
	jr nz, .asm_37c7
	ret


;----------------------------------------
;        UNREFERENCED FUNCTIONS
;----------------------------------------
;
;Func_3c87::
;	push af
;	call PauseSong
;	pop af
;	call PlaySong
;	call WaitForSongToFinish
;	jp ResumeSong
