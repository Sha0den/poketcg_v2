; Save a pointer to a list, given at de, to wListPointer
; preserves all registers
; input:
;	de = list that will be pointed to
; output:
;	[wListPointer] = location of the list from input
SetListPointer::
	push hl
	ld hl, wListPointer
	ld [hl], e
	inc hl
	ld [hl], d
	pop hl
	ret


; Sets the current element of the list at wListPointer to a,
; and advances the list to the next element
; preserves all registers
; input:
;	a = the new current item in the list
; output:
;	[wListPointer] = address of the next item in the list
SetNextElementOfList::
	push hl
	push de
	ld hl, wListPointer
	ld e, [hl]
	inc hl
	ld d, [hl]
	ld [de], a
	inc de
;	fallthrough

; assumes that there was a push hl and push de before this
; input:
;	de = new pointer to load
;	hl = wListPointer + 1
SetListToNextPosition::
	ld [hl], d
	dec hl
	ld [hl], e
	pop de
	pop hl
	ret


;----------------------------------------
;        UNREFERENCED FUNCTIONS
;----------------------------------------
;
; preserves all registers except af
; output:
;	a = item in list originally pointed to by wListPointer
;	[wListPointer] = address of the next item in the list
;GetNextElementOfList::
;	push hl
;	push de
;	ld hl, wListPointer
;	ld e, [hl]
;	inc hl
;	ld d, [hl]
;	ld a, [de]
;	inc de
;	jr SetListToNextPosition
