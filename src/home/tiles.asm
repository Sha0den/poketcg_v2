; loads the graphics and draws the duel box message given a BOXMSG_* constant in a
; input:
;	a = box message ID (BOXMSG_* constant)
DrawDuelBoxMessage::
	ld l, a
	ld h, 40 tiles / 4 ; boxes are 10x4 tiles
	call HtimesL
	add hl, hl
	add hl, hl
	; hl = a * 40 tiles
	ld de, DuelBoxMessages
	add hl, de
	ld de, v0Tiles1 + $20 tiles
	ld b, 40
	call CopyFontsOrDuelGraphicsTiles
	ld a, $a0
	lb hl, 1, 10
	lb bc, 10, 4
	lb de, 5, 4
;	fallthrough

; Fills a bxc rectangle at de and at sp-$26 using tiles,
; starting with the one from a, in the following pattern:
;	| a+0*l+0*h | a+0*l+1*h | a+0*l+2*h |
;	| a+1*l+0*h | a+1*l+1*h | a+1*l+2*h |
;	| a+2*l+0*h | a+2*l+1*h | a+2*l+2*h |
; preserves de
; input:
;	a = starting tile number
;	bc = width and height of the image being drawn
;	de = screen coordinates at which to start drawing the image
;	hl = ?
FillRectangle::
	push de
	push af
	push hl
	add sp, -TILEMAP_WIDTH
	call DECoordToBGMap0Address
.next_row
	push hl
	push bc
	ld hl, sp+$25
	ld d, [hl]
	ld hl, sp+$27
	ld a, [hl]
	ld hl, sp+$4
	push hl
.next_tile
	ld [hli], a
	add d
	dec b
	jr nz, .next_tile
	pop de
	pop bc
	pop hl
	push hl
	push bc
	ld c, b
	ld b, 0
	call SafeCopyDataDEtoHL
	ld hl, sp+$24
	ld a, [hl]
	ld hl, sp+$27
	add [hl]
	ld [hl], a
	pop bc
	pop de
	ld hl, TILEMAP_WIDTH
	add hl, de
	dec c
	jr nz, .next_row
	add sp, $24
	pop de
	ret


; erases all object sprites and replaces the background with blank tiles.
; on CGB, screen color will be the first color from CGB Background Palette 0.
ClearScreen::
	call ZeroObjectPositionsAndToggleOAMCopy
;	fallthrough

; replaces all background sprites currently on the screen with SYM_SPACE (blank 8x8 tile).
; on CGB, screen color will be the first color from CGB Background Palette 0.
ClearBackground::
	lb bc, 20, 18
	lb de, 0, 0
;	fallthrough

; replaces all background sprites in the area dictated by bc and de with SYM_SPACE (blank 8x8 tile).
; on CGB, the cleared area's color will be the first color from CGB Background Palette 0.
; input:
;	bc = width and height of the area being cleared
;	de = screen coordinates at which to start clearing background sprites
ClearRectangle:
	ld a, [wConsole]
	cp CONSOLE_CGB
	jr nz, .clear ; only clear sprites if not on a Game Boy Color
	push bc
	push de
	call BankswitchVRAM1
	call .clear ; replace all assigned palettes with CGB BG Palette 0 (monochrome)
	call BankswitchVRAM0
	pop de
	pop bc
.clear
	xor a ; SYM_SPACE
	ld h, a
	ld l, a
	jr FillRectangle

; replaces a wide text box (and its contents) with blank tiles.
ClearWideTextBox::
	lb bc, 20, 6
	lb de, 0, 12
	jr ClearRectangle


; loads the four tiles of the card set 2 icon constant provided in register a
; input:
;	a = set 2 icon constant (JUNGLE, FOSSIL, GB, or PRO)
;	   (probably obtained from wLoadedCard#Set)
; output:
;	carry = set:  if the set from input does not have an icon
LoadCardSet2Tiles::
	and $7 ; mask out PRO
	ld e, a
	ld d, $00
	ld hl, .tile_offsets
	add hl, de
	ld a, [hl]
	cp -1
	ccf
	ret z
	ld e, a
	ld hl, DuelOtherGraphics + $1d tiles
	add hl, de
	ld de, v0Tiles1 + $7c tiles
	ld b, $04
	call CopyFontsOrDuelGraphicsTiles
	or a
	ret

.tile_offsets
	; PRO/NONE, JUNGLE, FOSSIL, -1, -1, -1, -1, GB
	db -1, $0 tiles, $4 tiles, -1, -1, -1, -1, $8 tiles


; loads the Deck and Hand icons for the "Draw X card(s) from the deck." screen
LoadDuelDrawCardsScreenTiles::
	ld hl, DuelOtherGraphics + $29 tiles
	ld de, v0Tiles1 + $74 tiles
	ld b, $08
	jp CopyFontsOrDuelGraphicsTiles


; loads the 8 tiles that make up the border of the main duel menu as well as the border
; of a large card picture (displayed after drawing the card or placing it in the Arena).
LoadCardOrDuelMenuBorderTiles::
	ld hl, DuelOtherGraphics + $15 tiles
	ld de, v0Tiles1 + $50 tiles
	ld b, $08
	jr CopyFontsOrDuelGraphicsTiles


; loads the graphics of a card type header, used to display
; a picture of a card after drawing it or placing it in the Arena.
; input:
;	a = which header to load (HEADER_* constant)
LoadCardTypeHeaderTiles::
	ld d, a
	ld e, 0
	ld hl, DuelCardHeaderGraphics
	add hl, de
	ld de, v0Tiles1 + $60 tiles
	ld b, $10
	jr CopyFontsOrDuelGraphicsTiles


; loads the symbols that are displayed near the names in a list of cards
; (e.g. hand cards in a duel or cards from a booster pack)
; preserves bc and de
LoadDuelCardSymbolTiles::
	ld hl, DuelDmgSgbSymbolGraphics
	ld a, [wConsole]
	cp CONSOLE_CGB
	jr nz, .copy
	ld hl, DuelCgbSymbolGraphics
.copy
	ld de, v0Tiles1 + $50 tiles
	ld b, $30
	jr CopyFontsOrDuelGraphicsTiles


; loads the face down Basic/Stage 1/Stage 2 card images shown in the check Pokemon screens
LoadDuelFaceDownCardTiles::
	ld b, $10
	jr LoadDuelCheckPokemonScreenTiles.got_num_tiles

; same as LoadDuelFaceDownCardTiles, but also loads the ACT / BPx tiles
LoadDuelCheckPokemonScreenTiles::
	ld b, $24
.got_num_tiles
	ld hl, DuelDmgSgbSymbolGraphics + $30 tiles
	ld a, [wConsole]
	cp CONSOLE_CGB
	jr nz, .copy
	ld hl, DuelCgbSymbolGraphics + $30 tiles
.copy
	ld de, v0Tiles1 + $50 tiles
	jr CopyFontsOrDuelGraphicsTiles


; loads the tiles for the "Placing the prizes..." screen
LoadPlacingThePrizesScreenTiles::
	; load the Pokeball field tiles for the face-down Active Pokemon
	ld hl, DuelOtherGraphics
	ld de, v0Tiles1 + $20 tiles
	ld b, $d
	call CopyFontsOrDuelGraphicsTiles
;	fallthrough

; loads the Deck and the Discard Pile icons
LoadDeckAndDiscardPileIcons::
	ld hl, DuelDmgSgbSymbolGraphics + $54 tiles
	ld a, [wConsole]
	cp CONSOLE_CGB
	jr nz, .copy
	ld hl, DuelCgbSymbolGraphics + $54 tiles
.copy
	ld de, v0Tiles1 + $50 tiles
	ld b, $30
	jr CopyFontsOrDuelGraphicsTiles


; loads the tiles for the [O] and [X] symbols used to display the results of a coin toss
LoadDuelCoinTossResultTiles::
	ld hl, DuelOtherGraphics + $d tiles
	ld de, v0Tiles2 + $30 tiles
	ld b, $8
	jr CopyFontsOrDuelGraphicsTiles


; loads the tiles of the text characters used with TX_SYMBOL
LoadSymbolsFont::
	ld hl, SymbolsFont - $4000
	ld de, v0Tiles2 ; destination
	ld b, (SymbolsFontEnd - SymbolsFont) / TILE_SIZE ; number of tiles
;	fallthrough

; if hl ≤ $3fff, then copy b tiles from Gfx1:(hl+$4000) to de
; if $4000 ≤ hl ≤ $7fff, then copy b tiles from Gfx2:hl to de
; input:
;	hl = location of graphics to copy
;	de = where to put the graphics in VRAM
;	b = number of tiles to copy
CopyFontsOrDuelGraphicsTiles::
	ld a, BANK(Fonts) ; BANK(DuelGraphics)
	call BankpushROM
	ld c, TILE_SIZE
	call CopyGfxData
	call BankpopROM
	ret


; copies gfx data into sram
Func_212f::
; loads symbols fonts to sGfxBuffer1
	ld hl, SymbolsFont - $4000
	ld de, sGfxBuffer1
	ld b, $30
	call CopyFontsOrDuelGraphicsTiles
; text box frame tiles
	ld hl, DuelOtherGraphics + $15 tiles
	ld de, sGfxBuffer1 + $30 tiles
	ld b, $8
	call CopyFontsOrDuelGraphicsTiles
	call GetCardSymbolData
	sub $d0
	ld l, a
	ld h, $00
	add hl, hl
	add hl, hl
	add hl, hl
	add hl, hl ; *16
	ld de, DuelDmgSgbSymbolGraphics
	add hl, de
	ld de, sGfxBuffer1 + $38 tiles
	ld b, $4
	call CopyFontsOrDuelGraphicsTiles
	ld hl, DuelDmgSgbSymbolGraphics
	ld de, sGfxBuffer4 + $10 tiles
	ld b, $30
	jr CopyFontsOrDuelGraphicsTiles


; loads the tiles for the latin, katakana, and hiragana fonts into VRAM
; from gfx/fonts/full_width/3.1bpp and gfx/fonts/full_width/4.1bpp
LoadFullWidthFontTiles::
	ld hl, FullWidthFonts + $3cc tiles_1bpp - $4000
	ld a, BANK(Fonts) ; BANK(DuelGraphics)
	call BankpushROM
	push hl
	ld e, l
	ld d, h
	ld hl, v0Tiles0
	call Copy1bppTiles
	pop de
	ld hl, v0Tiles2
	call Copy1bppTiles
	ld hl, v0Tiles1
	call Copy1bppTiles
	call BankpopROM
	ret


; copies 128 1bpp tiles from de to hl as 2bpp
; input:
;	de = address from which to start copying the tiles
;	hl = where to copy the tiles (in VRAM)
Copy1bppTiles::
	ld b, $80
.tile_loop
	ld c, TILE_SIZE_1BPP
.pixel_loop
	ld a, [de]
	inc de
	ld [hli], a
	ld [hli], a
	dec c
	jr nz, .pixel_loop
	dec b
	jr nz, .tile_loop
	ret


;----------------------------------------
;        UNREFERENCED FUNCTIONS
;----------------------------------------
;
; loads the symbols for Stage 1 Pokemon, Stage 2 Pokemon, and Trainer cards.
; unlike LoadDuelCardSymbolTiles, this excludes the Basic Pokemon symbol and all of the Energy symbols.
;LoadDuelCardSymbolTiles2::
;	ld hl, DuelDmgSgbSymbolGraphics + $4 tiles
;	ld a, [wConsole]
;	cp CONSOLE_CGB
;	jr nz, .copy
;	ld hl, DuelCgbSymbolGraphics + $4 tiles
;.copy
;	ld de, v0Tiles1 + $54 tiles
;	ld b, $c
;	jr CopyFontsOrDuelGraphicsTiles
;
;
;Func_1f96::
;	add sp, -10
;	ld hl, sp+0
;	ld [hli], a ; sp-10 <- a
;	ld [hl], $00 ; sp-9 <- 0
;	inc hl
;	ld a, [de]
;	inc de
;	ld [hli], a ; sp-8 <- [de]
;	ld [hl], $00 ; sp-7 <- 0
;	ld hl, sp+5
;	ld a, [de]
;	inc de
;	ld [hld], a ; sp-5 <- [de+1]
;	ld a, [de]
;	inc de
;	ld [hl], a ; sp-6 <- [de+2]
;	ld hl, sp+6
;	ld a, [de]
;	inc de
;	ld [hli], a ; sp-4 <- [de+3]
;	ld a, [de]
;	inc de
;	ld [hli], a ; sp-3 <- [de+4]
;	ld a, [de]
;	inc de
;	ld l, a ; l <- [de+5]
;	ld a, [de]
;	dec de
;	ld h, a ; h <- [de+6]
;	or l
;	jr z, .asm_1fbd
;	add hl, de
;.asm_1fbd
;	ld e, l
;	ld d, h ; de += hl
;	ld hl, sp+8
;	ld [hl], e ; sp-2 <- e
;	inc hl
;	ld [hl], d ; sp-1 <- d
;	ld hl, sp+0
;	ld e, [hl] ; e <- sp
;	jr .asm_2013
;	push hl
;	push de
;	push hl
;	add sp, -4
;	ld hl, sp+0
;	ld [hl], c
;	inc hl
;	ld [hl], $00
;	inc hl
;	ld [hl], b
;	ld hl, sp+8
;	xor a
;	ld [hli], a
;	ld [hl], a
;.asm_1fdb
;	call DoFrame
;	ld hl, sp+3
;	ld [hl], a
;	ld c, a
;	and $09
;	jr nz, .asm_2032
;	ld a, c
;	and $06
;	jr nz, .asm_203c
;	ld hl, sp+2
;	ld b, [hl]
;	ld hl, sp+0
;	ld a, [hl]
;	bit 6, c
;	jr nz, .asm_1ffe
;	bit 7, c
;	jr nz, .asm_2007
;	call Func_2046
;	jr .asm_1fdb
;.asm_1ffe
;	dec a
;	bit 7, a
;	jr z, .asm_200c
;	ld a, b
;	dec a
;	jr .asm_200c
;.asm_2007
;	inc a
;	cp b
;	jr c, .asm_200c
;	xor a
;.asm_200c
;	ld e, a
;	call Func_2051
;	ld hl, sp+0
;	ld [hl], e
;.asm_2013
;	inc hl
;	ld [hl], $00
;	inc hl
;	ld b, [hl]
;	inc hl
;	ld c, [hl]
;	ld hl, sp+8
;	ld a, [hli]
;	ld h, [hl]
;	ld l, a
;	or h
;	jr z, .asm_202d
;	ld a, e
;	ld de, .asm_2028
;	push de
;	jp hl
;.asm_2028
;	jr nc, .asm_202d
;	ld hl, sp+0
;	ld [hl], a
;.asm_202d
;	call Func_2046
;	jr .asm_1fdb
;.asm_2032
;	call Func_2051
;	ld hl, sp+0
;	ld a, [hl]
;	add sp, 10
;	or a
;	ret
;.asm_203c
;	call Func_2051
;	ld hl, sp+0
;	ld a, [hl]
;	add sp, 10
;	scf
;	ret
;
;
;Func_2046::
;	ld hl, sp+3
;	ld a, [hl]
;	inc [hl]
;	and $0f
;	ret nz
;	bit 4, [hl]
;	jr z, Func_2055
;	; fallthrough
;
;Func_2051::
;	ld hl, sp+9
;	jr Func_2057
;
;
;Func_2055::
;	ld hl, sp+8
;	; fallthrough
;
;Func_2057::
;	ld e, [hl]
;	ld hl, sp+2
;	ld a, [hl]
;	ld hl, sp+6
;	add [hl]
;	inc hl
;	ld c, a
;	ld b, [hl]
;	ld a, e
;	call HblankWriteByteToBGMap0
;	ret
