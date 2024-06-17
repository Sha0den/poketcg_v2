; copies c bytes of data from hl to de, b times.
; used to copy gfx data with c = TILE_SIZE
; input:
;	b = number of times to copy
;	c = number of bytes to copy
;	hl = address from which to start copying the data
;	de = where to copy the data
CopyGfxData::
	ld a, [wLCDC]
	rla
	jr nc, .next_tile
.hblank_copy
	push bc
	push hl
	push de
	ld b, c
	call JPHblankCopyDataHLtoDE
	ld b, $0
	pop hl
	add hl, bc
	ld e, l
	ld d, h
	pop hl
	add hl, bc
	pop bc
	dec b
	jr nz, .hblank_copy
	ret
.next_tile
	push bc
.copy_tile
	ld a, [hli]
	ld [de], a
	inc de
	dec c
	jr nz, .copy_tile
	pop bc
	dec b
	jr nz, .next_tile
	ret


; copies bc bytes from hl to de
; preserves all registers except af
; input:
;	bc = number of bytes to copy
;	hl = address from which to start copying the data
;	de = where to copy the data
CopyDataHLtoDE_SaveRegisters::
	push hl
	push de
	push bc
	call CopyDataHLtoDE
	pop bc
	pop de
	pop hl
	ret


; copies bc bytes from hl to de
; input:
;	bc = number of bytes to copy
;	hl = address from which to start copying the data
;	de = where to copy the data
CopyDataHLtoDE::
	ld a, [hli]
	ld [de], a
	inc de
	dec bc
	ld a, c
	or b
	jr nz, CopyDataHLtoDE
	ret
