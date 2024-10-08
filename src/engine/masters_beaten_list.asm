; preserves all registers except af
ClearMasterBeatenList:
	push hl
	push bc
	ld c, $a
	ld hl, wMastersBeatenList
	xor a
.loop
	ld [hli], a
	dec c
	jr nz, .loop
	pop bc
	pop hl
	ret


; writes Master in register a to first empty slot in wMastersBeatenList
; preserves all registers except af
; input:
;	a = master to add to wMastersBeatenList ($1-$a)
AddMasterBeatenToList:
	push hl
	push bc
	ld b, a
	ld c, $a
	ld hl, wMastersBeatenList
.loop
	ld a, [hl]
	or a
	jr z, .found_empty_slot
	cp b
	jr z, .exit
	inc hl
	dec c
	jr nz, .loop
	jr .exit

.found_empty_slot
	ld a, b
	ld [hl], a

.exit
	pop bc
	pop hl
	ret


; iterates all masters and attempts to add each of them to wMastersBeatenList
; preserves all registers except af
AddAllMastersToMastersBeatenList:
	ld a, $01
.loop
	push af
	call AddMasterBeatenToList
	pop af
	inc a
	cp $0b
	jr c, .loop
	ret
