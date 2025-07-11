; wSpriteAnimBuffer
DEF SPRITE_ANIM_BUFFER_CAPACITY EQU 16 ; sprites

; sprite_anim_struct constants
	const_def
	const SPRITE_ANIM_ENABLED
	const SPRITE_ANIM_ATTRIBUTES
	const SPRITE_ANIM_COORD_X
	const SPRITE_ANIM_COORD_Y
	const SPRITE_ANIM_TILE_ID
	const SPRITE_ANIM_ID
	const SPRITE_ANIM_BANK
	const SPRITE_ANIM_POINTER
	const_skip ; pointer
	const SPRITE_ANIM_FRAME_OFFSET_POINTER
	const_skip ; pointer
	const SPRITE_ANIM_FRAME_BANK
	const SPRITE_ANIM_FRAME_DATA_POINTER
	const_skip ; pointer
	const SPRITE_ANIM_COUNTER
	const SPRITE_ANIM_FLAGS
DEF SPRITE_ANIM_LENGTH EQU const_value

; SPRITE_ANIM_FLAGS values
	const_def
	const SPRITE_ANIM_FLAG_X_INVERTED_F  ; $0
	const SPRITE_ANIM_FLAG_Y_INVERTED_F  ; $1
	const SPRITE_ANIM_FLAG_CENTERED_F    ; $2
	const SPRITE_ANIM_FLAG_3_F           ; $3
	const_skip
	const SPRITE_ANIM_FLAG_X_FLIP_F      ; $5
	const SPRITE_ANIM_FLAG_Y_FLIP_F      ; $6
	const SPRITE_ANIM_FLAG_UNSKIPPABLE_F ; $7

DEF SPRITE_ANIM_FLAG_X_INVERTED  EQU 1 << SPRITE_ANIM_FLAG_X_INVERTED_F
DEF SPRITE_ANIM_FLAG_Y_INVERTED  EQU 1 << SPRITE_ANIM_FLAG_Y_INVERTED_F
DEF SPRITE_ANIM_FLAG_CENTERED    EQU 1 << SPRITE_ANIM_FLAG_CENTERED_F
DEF SPRITE_ANIM_FLAG_3           EQU 1 << SPRITE_ANIM_FLAG_3_F
DEF SPRITE_ANIM_FLAG_X_FLIP      EQU 1 << SPRITE_ANIM_FLAG_X_FLIP_F
DEF SPRITE_ANIM_FLAG_Y_FLIP      EQU 1 << SPRITE_ANIM_FLAG_Y_FLIP_F
DEF SPRITE_ANIM_FLAG_UNSKIPPABLE EQU 1 << SPRITE_ANIM_FLAG_UNSKIPPABLE_F

DEF SPRITE_FRAME_OFFSET_SIZE EQU 4

	const_def
	const SPRITE_OW_PLAYER          ; $00
	const SPRITE_OW_RONALD          ; $01
	const SPRITE_OW_DRMASON         ; $02
	const SPRITE_OW_ISHIHARA        ; $03
	const SPRITE_OW_IMAKUNI         ; $04
	const SPRITE_OW_NIKKI           ; $05
	const SPRITE_OW_RICK            ; $06
	const SPRITE_OW_KEN             ; $07
	const SPRITE_OW_AMY             ; $08
	const SPRITE_OW_ISAAC           ; $09
	const SPRITE_OW_MITCH           ; $0a
	const SPRITE_OW_GENE            ; $0b
	const SPRITE_OW_MURRAY          ; $0c
	const SPRITE_OW_COURTNEY        ; $0d
	const SPRITE_OW_STEVE           ; $0e
	const SPRITE_OW_JACK            ; $0f
	const SPRITE_OW_ROD             ; $10
	const SPRITE_OW_BOY             ; $11
	const SPRITE_OW_LAD             ; $12
	const SPRITE_OW_SPECS           ; $13
	const SPRITE_OW_BUTCH           ; $14
	const SPRITE_OW_MANIA           ; $15
	const SPRITE_OW_JOSHUA          ; $16
	const SPRITE_OW_HOOD            ; $17
	const SPRITE_OW_TECH            ; $18
	const SPRITE_OW_CHAP            ; $19
	const SPRITE_OW_MAN             ; $1a
	const SPRITE_OW_PAPPY           ; $1b
	const SPRITE_OW_GIRL            ; $1c
	const SPRITE_OW_LASS1           ; $1d
	const SPRITE_OW_LASS2           ; $1e
	const SPRITE_OW_LASS3           ; $1f
	const SPRITE_OW_SWIMMER         ; $20
	const SPRITE_OW_CLERK           ; $21
	const SPRITE_OW_GAL             ; $22
	const SPRITE_OW_WOMAN           ; $23
	const SPRITE_OW_GRANNY          ; $24
	const SPRITE_OW_MAP_OAM         ; $25
	const SPRITE_OW_TORCH           ; $26
	const SPRITE_OW_LEGENDARY_CARD  ; $27
	const SPRITE_DUEL_GLOW          ; $28
	const SPRITE_DUEL_PARALYSIS     ; $29
	const SPRITE_DUEL_SLEEP         ; $2a
	const SPRITE_DUEL_STAR          ; $2b
	const SPRITE_DUEL_POISON        ; $2c
	const SPRITE_DUEL_HIT           ; $2d
	const SPRITE_DUEL_DAMAGE        ; $2e
	const SPRITE_DUEL_THUNDER       ; $2f
	const SPRITE_DUEL_LIGHTNING     ; $30
	const SPRITE_DUEL_SPARK         ; $31
	const SPRITE_DUEL_BIG_LIGHTNING ; $32
	const SPRITE_DUEL_FLAME         ; $33
	const SPRITE_DUEL_FIRE_SPIN     ; $34
	const SPRITE_DUEL_FIRE_BIRD     ; $35
	const SPRITE_DUEL_WATER_DROP    ; $36
	const SPRITE_DUEL_WATER_GUN     ; $37
	const SPRITE_DUEL_WHIRLPOOL     ; $38
	const SPRITE_DUEL_HYDRO_PUMP    ; $39
	const SPRITE_DUEL_SNOW          ; $3a
	const SPRITE_DUEL_PSYCHIC       ; $3b
	const SPRITE_DUEL_LEER          ; $3c
	const SPRITE_DUEL_BEAM          ; $3d
	const SPRITE_DUEL_HYPER_BEAM    ; $3e
	const SPRITE_DUEL_ROCK_THROW    ; $3f
	const SPRITE_DUEL_PUNCH         ; $40
	const SPRITE_DUEL_STRETCH_KICK  ; $41
	const SPRITE_DUEL_SLASH         ; $42
	const SPRITE_DUEL_WHIP          ; $43
	const SPRITE_DUEL_SONICBOOM     ; $44
	const SPRITE_DUEL_DRILL         ; $45
	const SPRITE_DUEL_POT           ; $46
	const SPRITE_DUEL_BONE          ; $47
	const SPRITE_DUEL_PLANET        ; $48
	const SPRITE_DUEL_NEEDLES       ; $49
	const SPRITE_DUEL_GAS           ; $4a
	const SPRITE_DUEL_POWDER        ; $4b
	const SPRITE_DUEL_GOO           ; $4c
	const SPRITE_DUEL_BUBBLE        ; $4d
	const SPRITE_DUEL_STRING        ; $4e
	const SPRITE_DUEL_HEART         ; $4f
	const SPRITE_DUEL_LURE          ; $50
	const SPRITE_DUEL_SKULL         ; $51
	const SPRITE_DUEL_SMALL_STAR    ; $52
	const SPRITE_DUEL_NOTE          ; $53
	const SPRITE_DUEL_SOUND         ; $54
	const SPRITE_DUEL_PETAL         ; $55
	const SPRITE_DUEL_PROTECT       ; $56
	const SPRITE_DUEL_BARRIER       ; $57
	const SPRITE_DUEL_SPEED         ; $58
	const SPRITE_DUEL_WHIRLWIND     ; $59
	const SPRITE_DUEL_CRY           ; $5a
	const SPRITE_DUEL_QUESTION_MARK ; $5b
	const SPRITE_DUEL_EXPLOSION     ; $5c
	const SPRITE_DUEL_HEAL          ; $5d
	const SPRITE_DUEL_DRAIN         ; $5e
	const SPRITE_DUEL_SMALL_GLOW    ; $5f
	const SPRITE_DUEL_BALL          ; $60
	const SPRITE_DUEL_CAT_POW       ; $61
	const SPRITE_DUEL_WAVE          ; $62
	const SPRITE_DUEL_CARD          ; $63
	const SPRITE_DUEL_COIN          ; $64
	const SPRITE_DUEL_RESULT        ; $65
	const SPRITE_LINK               ; $66
	const SPRITE_PRINTER            ; $67
	const SPRITE_CARD_POP           ; $68
	const SPRITE_BOOSTER_PACK_OAM   ; $69
	const SPRITE_PRESS_START        ; $6a
	const SPRITE_GRASS              ; $6b
	const SPRITE_FIRE               ; $6c
	const SPRITE_WATER              ; $6d
	const SPRITE_COLORLESS          ; $6e
	const SPRITE_LIGHTNING          ; $6f
	const SPRITE_PSYCHIC            ; $70
	const SPRITE_FIGHTING           ; $71
	const SPRITE_OW_MINT            ; $72

DEF NUM_SPRITES EQU const_value
