; something window scroll
; preserves all registers
Func_3e44::
	push af
	push hl
	push bc
	push de
	ld hl, wd657
	bit 0, [hl]
	jr nz, .done
	set 0, [hl]
	ld b, $00
	ld hl, wd658
	ld c, [hl]
	inc [hl]
	ld hl, wd64b
	add hl, bc
	ld a, [hl]
	ldh [rWX], a
	ld hl, rLCDC
	cp $a7
	jr c, .disable_sprites
	set 1, [hl] ; enable sprites
	jr .asm_3e6c
.disable_sprites
	res 1, [hl] ; disable sprites
.asm_3e6c
	ld hl, wd651
	add hl, bc
	ld a, [hl]
	cp $8f
	jr c, .asm_3e9a
	ld a, [wd665]
	or a
	jr z, .asm_3e93
	ld hl, wd659
	ld de, wd64b
	ld b, $6
	call CopyNBytesFromHLToDE
	ld hl, wd65f
	ld de, wd651
	ld b, $6
	call CopyNBytesFromHLToDE
.asm_3e93
	xor a
	ld [wd665], a
	ld [wd658], a
.asm_3e9a
	ldh [rLYC], a
	ld hl, wd657
	res 0, [hl]
.done
	pop de
	pop bc
	pop hl
	pop af
	ret


; applies background scroll for lines 0 to 96 using the values at BGScrollData
; skips if wApplyBGScroll is non-0
; preserves all registers
ApplyBackgroundScroll::
	push af
	push hl
	call DisableInt_LYCoincidence
	ld hl, rSTAT
	res B_STAT_LYCF, [hl] ; reset coincidence flag
	ei
	ld hl, wApplyBGScroll
	ld a, [hl]
	or a
	jr nz, .done
	inc [hl]
	push bc
	push de
	xor a
	ld [wNextScrollLY], a
.ly_loop
	ld a, [wNextScrollLY]
	ld b, a
.wait_ly
	ldh a, [rLY]
	cp $60
	jr nc, .ly_over_0x60
	cp b ; already hit LY=b?
	jr c, .wait_ly
	call GetNextBackgroundScroll
	ld hl, rSTAT
.wait_hblank_or_vblank
	bit B_STAT_BUSY, [hl]
	jr nz, .wait_hblank_or_vblank
	ldh [rSCX], a
	ldh a, [rLY]
	inc a
	ld [wNextScrollLY], a
	jr .ly_loop
.ly_over_0x60
	xor a
	ldh [rSCX], a
	ldh [rLYC], a
	call GetNextBackgroundScroll
	ldh [hSCX], a
	pop de
	pop bc
	xor a
	ld [wApplyBGScroll], a
	call EnableInt_LYCoincidence
.done
	pop hl
	pop af
	ret


BGScrollData::
	db  0,  0,  0,  1,  1,  1,  2,  2,  2,  3,  3,  3,  3,  3,  3,  3
	db  4,  3,  3,  3,  3,  3,  3,  3,  2,  2,  2,  1,  1,  1,  0,  0
	db  0, -1, -1, -1, -2, -2, -2, -3, -3, -3, -4, -4, -4, -4, -4, -4
	db -5, -4, -4, -4, -4, -4, -4, -3, -3, -3, -2, -2, -2, -1, -1, -1

; preserves de
; output:
;	a = x rotated right [wBGScrollMod]-1 times (max 3 times)
;	    x = BGScrollData[(wVBlankCounter + a) & $3f]
GetNextBackgroundScroll::
	ld hl, wVBlankCounter
	add [hl]
	and $3f
	ld c, a
	ld b, $00
	ld hl, BGScrollData
	add hl, bc
	ld a, [wBGScrollMod]
	ld c, a
	ld a, [hl]
	dec c
	ret z
	dec c
	jr z, .halve
	dec c
	jr z, .quarter
; effectively zero
	sra a
.quarter
	sra a
.halve
	sra a
	ret


; enables lcdc interrupt on LYC=LC coincidence
; preserves all registers except af
EnableInt_LYCoincidence::
	push hl
	ld hl, rSTAT
	set B_STAT_LYC, [hl]
	xor a
	ld hl, rIE
	set B_IE_STAT, [hl]
	pop hl
	ret


; disables lcdc interrupt and the LYC=LC coincidence trigger
; preserves all registers except af
DisableInt_LYCoincidence::
	push hl
	ld hl, rSTAT
	res B_STAT_LYC, [hl]
	xor a
	ld hl, rIE
	res B_IE_STAT, [hl]
	pop hl
	ret
