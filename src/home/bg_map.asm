; reads structs:
;   x (1 byte), y (1 byte), data (n bytes), $00
;   x (1 byte), y (1 byte), data (n bytes), $00
;   ...
;   $ff
; for each struct, writes data to BGMap0-translated x,y
; input:
;	hl = location of data to copy into vram
WriteDataBlocksToBGMap0::
	call WriteDataBlockToBGMap0
	bit 7, [hl] ; check for $ff
	jr z, WriteDataBlocksToBGMap0
	ret


; writes data to BGMap0-translated x,y
; reads struct:
;	x (1 byte), y (1 byte), data (n bytes), $00
; input:
;	hl = location of data to copy into vram
WriteDataBlockToBGMap0::
	ld b, [hl]
	inc hl
	ld c, [hl]
	inc hl
	push hl ; hl = address containing the data
	push bc ; b,c = x,y
	ld b, -1
.find_zero_loop
	inc b
	ld a, [hli]
	or a
	jr nz, .find_zero_loop
	ld a, b ; length of data
	pop bc ; x,y
	call BCCoordToBGMap0Address
	ld b, a ; length of data
	pop hl ; address containing the data
	or a
	jr z, .move_to_next
	push bc
	push hl
	call SafeCopyDataHLtoDE ; copy data to de (BGMap0 translated x,y)
	pop hl
	pop bc

.move_to_next
	inc b ; length of data += 1 (to account for the last $0)
	ld c, b
	ld b, 0
	add hl, bc ; point to next structure
	ret


; writes a to [v*BGMap0 + TILEMAP_WIDTH * c + b]
; preserves all registers except af
; input:
;	a = byte to draw
;	bc = screen coordinates at which to draw the byte
WriteByteToBGMap0::
	push af
	ld a, [wLCDC]
	rla
	jr c, .lcd_on
	pop af
	push hl
	push de
	push bc
	call BCCoordToBGMap0Address
	ld [de], a
	pop bc
	pop de
	pop hl
	ret
.lcd_on
	pop af
;	fallthrough

; writes a to [v*BGMap0 + TILEMAP_WIDTH * c + b] during hblank
; preserves all registers except af
; input:
;	a = byte to draw
;	bc = screen coordinates at which to draw the byte
HblankWriteByteToBGMap0::
	push hl
	push de
	push bc
	ld hl, wTempByte
	push hl
	ld [hl], a
	call BCCoordToBGMap0Address
	pop hl
	ld b, 1
	call HblankCopyDataHLtoDE
	pop bc
	pop de
	pop hl
	ret


; copies a bytes of data from hl to vBGMap0 address pointed to by bc coordinates
; preserves bc
; input:
;	a = number of bytes to copy
;	hl = data to copy
;	bc = screen coordinates at which to draw the data
CopyDataToBGMap0::
	push bc
	push hl
	call BCCoordToBGMap0Address
	ld b, a
	pop hl
	call SafeCopyDataHLtoDE
	pop bc
	ret


; maps coordinates at bc to a BGMap0 address.
; preserves a register
; input:
;	bc = screen coordinates
; output:
;	de = v*BGMap0 + TILEMAP_WIDTH * c + b in de.
BCCoordToBGMap0Address::
	ld l, c
	ld h, $0
	add hl, hl
	add hl, hl
	add hl, hl
	add hl, hl
	add hl, hl
	ld c, b
	ld b, HIGH(v0BGMap0)
	add hl, bc
	ld e, l
	ld d, h
	ret


; maps coordinates at de to a BGMap0 address.
; preserves bc and de
; input:
;	de = screen coordinates
; output:
;	hl = v*BGMap0 + TILEMAP_WIDTH * e + d
DECoordToBGMap0Address::
	ld l, e
	ld h, $0
	add hl, hl
	add hl, hl
	add hl, hl
	add hl, hl
	add hl, hl
	ld a, l
	add d
	ld l, a
	ld a, h
	adc HIGH(v0BGMap0)
	ld h, a
	ret


;----------------------------------------
;        UNREFERENCED FUNCTIONS
;----------------------------------------
;
; reads struct:
;   x (1 byte), y (1 byte), data (n bytes), $00
; writes data to BGMap0-translated x,y
; important: make sure VRAM can be accessed first, else use WriteDataBlockToBGMap0
;UnsafeWriteDataBlockToBGMap0::
;	ld a, [hli]
;	ld b, a
;	ld a, [hli]
;	ld c, a
;	call BCCoordToBGMap0Address
;	jr .next
;.loop
;	ld [de], a
;	inc de
;.next
;	ld a, [hli]
;	or a
;	jr nz, .loop
;	ret
