; for the sprite at wOAM + [wOAMOffset] / 4, set its attributes from registers e, d, c, b
; preserves all registers except af
; input:
;	b = Attributes/Flags
;	c = Tile/Pattern Number
;	d = X Position
;	e = Y Position
; output:
;	carry = set:  if [wOAMOffset] > OAM_SIZE (beyond the end of wOAM)
SetOneObjectAttributes::
	push hl
	ld a, [wOAMOffset]
	ld l, a
	ld h, HIGH(wOAM)
	cp OAM_SIZE
	jr nc, .beyond_oam
	ld [hl], e ; Y Position
	inc hl
	ld [hl], d ; X Position
	inc hl
	ld [hl], c ; Tile/Pattern Number
	inc hl
	ld [hl], b ; Attributes/Flags
	inc hl
	ld a, l
	ld [wOAMOffset], a
	pop hl
	or a
	ret
.beyond_oam
	pop hl
	scf
	ret


ZeroObjectPositionsAndToggleOAMCopy::
	call ZeroObjectPositions
	ld a, $01
	ld [wVBlankOAMCopyToggle], a
	ret


; sets the Y Position and X Position of all sprites in wOAM to $00
; preserves de
ZeroObjectPositions::
	xor a
	ld [wOAMOffset], a
	ld hl, wOAM
	ld c, OAM_COUNT
.loop
	ld [hli], a
	ld [hli], a
	inc hl
	inc hl
	dec c
	jr nz, .loop
	ret


;----------------------------------------
;        UNREFERENCED FUNCTIONS
;----------------------------------------
;
; sets attributes for [hl] sprites starting from wOAM + [wOAMOffset] / 4
; preserves de
; output:
;	carry = set:  if the end of wOAM was reached before finishing
;SetManyObjectsAttributes::
;	push hl
;	ld a, [wOAMOffset]
;	ld c, a
;	ld b, HIGH(wOAM)
;	cp OAM_SIZE
;	jr nc, .beyond_oam
;	pop hl
;	ld a, [hli] ; [hl] = how many obj?
;.copy_obj_loop
;	push af
;	ld a, [hli]
;	add e
;	ld [bc], a ; Y Position <- [hl + 1 + 4*i] + e
;	inc bc
;	ld a, [hli]
;	add d
;	ld [bc], a ; X Position <- [hl + 2 + 4*i] + d
;	inc bc
;	ld a, [hli]
;	ld [bc], a ; Tile/Pattern Number <- [hl + 3 + 4*i]
;	inc bc
;	ld a, [hli]
;	ld [bc], a ; Attributes/Flags <- [hl + 4 + 4*i]
;	inc bc
;	ld a, c
;	cp OAM_SIZE
;	jr nc, .beyond_oam
;	pop af
;	dec a
;	jr nz, .copy_obj_loop
;	or a
;.done
;	ld hl, wOAMOffset
;	ld [hl], c
;	ret
;.beyond_oam
;	pop hl
;	scf
;	jr .done
