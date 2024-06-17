; preserves all registers
DoFrameIfLCDEnabled::
	push af
	ldh a, [rLCDC]
	bit LCDC_ENABLE_F, a
	jr z, .done
	call DoFrame
.done
	pop af
	ret
