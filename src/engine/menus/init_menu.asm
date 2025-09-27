; empties screen in preparation to draw some menu
InitMenuScreen:
	xor a ; SYM_SPACE
	ld [wTileMapFill], a
	call EmptyScreen
	call LoadSymbolsFont
	lb de, $30, $7f
	call SetupText
	call Set_OBJ_8x8
	xor a
	ldh [hSCX], a
	ldh [hSCY], a
	ld a, [wLCDC]
	bit B_LCDC_ENABLE, a
	jr nz, .skip_clear_scroll
	xor a
	ldh [rSCX], a
	ldh [rSCY], a
.skip_clear_scroll
	call SetDefaultPalettes
	jp ZeroObjectPositionsAndToggleOAMCopy
