SECTION "Audio Callback", ROM0

; jumps to 3f:hl, then switches to bank 3d
Bankswitch3dTo3f::
	push af
	ld a, $3f
	rst BankswitchROM
	pop af
	ld bc, .bankswitch3d
	push bc
	jp hl
.bankswitch3d
	ld a, $3d
	jp BankswitchROM
