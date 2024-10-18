; AI card retreat score bonus
; when the AI retreat routine runs through the Bench to choose
; a Pokémon to switch to, it checks this list, and if a card ID matches,
; it applies a retreat score bonus to this Pokémon.
; positive (negative) means more (less) likely to switch to this card.
MACRO ai_retreat
	db \1       ; card ID
	db $80 + \2 ; retreat score (ranges between -128 and 127)
ENDM


; AI card energy attach score bonus
; when the AI Energy attachment routine runs through the play area to choose a Pokémon
; to attach the Energy card to, it checks this list, and if a card ID matches,
; then it skips this Pokémon if the maximum amount of attached Energy
; has already been reached. If it hasn't, it also applies a positive
; (or negative) AI score to attach the Energy card to this Pokémon.
MACRO ai_energy
	db \1       ; card ID
	db \2       ; maximum number of attached cards
	db $80 + \3 ; energy score (ranges between -128 and 127)
ENDM


; stores in WRAM pointer to data in argument
; e.g. store_list_pointer wSomeListPointer, SomeData
MACRO store_list_pointer
	ld hl, \1
	ld de, \2
	ld [hl], e
	inc hl
	ld [hl], d
ENDM


; deck AIs are specialized to work on a given deck ID.
; they decide what happens during a turn, what Pokémon cards
; to pick during the start of the duel, etc.
; these scenarios are listed in AIACTION_* constants.
; each deck has a pointer table with the following structure:
; dw .do_turn       : never called
;
; dw .do_turn       : called to handle the main turn logic, from the beginning
;                     of the turn up to the attack (or lack thereof)
;
; dw .start_duel    : called at the start of the duel to initialize some
;                     variables and optionally set up CPU hand and deck
;
; dw .forced_switch : logic to determine what Pokémon to pick when there's
;                     an effect that forces the AI to switch in a Benched Pokémon
;
; dw .ko_switch     : logic for picking a new Active Pokémon after a KO
;
; dw .take_prize    : logic to decide which Prize card to pick

; optionally, decks can also declare card lists that will add
; more specialized logic during various generic AI routines,
; and read during the .start_duel routines.
; the pointers to these lists are stored in memory:
; wAICardListAvoidPrize    : list of cards to avoid being placed as Prizes
; wAICardListArenaPriority : priority list for selecting an initial Active Pokémon
; wAICardListBenchPriority : priority list for selecting initial Benched Pokémon
; wAICardListPlayFromHandPriority : priority list of cards to play from hand
; wAICardListRetreatBonus  : scores given to certain cards for retreating
; wAICardListEnergyBonus   : max number of Energy cards and card scores

INCLUDE "engine/duel/ai/decks/general.asm"
INCLUDE "engine/duel/ai/decks/sams_practice.asm"
INCLUDE "engine/duel/ai/decks/general_no_retreat.asm"
INCLUDE "engine/duel/ai/decks/legendary_moltres.asm"
INCLUDE "engine/duel/ai/decks/legendary_zapdos.asm"
INCLUDE "engine/duel/ai/decks/legendary_articuno.asm"
INCLUDE "engine/duel/ai/decks/legendary_dragonite.asm"
INCLUDE "engine/duel/ai/decks/first_strike.asm"
INCLUDE "engine/duel/ai/decks/rock_crusher.asm"
INCLUDE "engine/duel/ai/decks/go_go_rain_dance.asm"
INCLUDE "engine/duel/ai/decks/zapping_selfdestruct.asm"
INCLUDE "engine/duel/ai/decks/flower_power.asm"
INCLUDE "engine/duel/ai/decks/strange_psyshock.asm"
INCLUDE "engine/duel/ai/decks/wonders_of_science.asm"
INCLUDE "engine/duel/ai/decks/fire_charge.asm"
INCLUDE "engine/duel/ai/decks/im_ronald.asm"
INCLUDE "engine/duel/ai/decks/powerful_ronald.asm"
INCLUDE "engine/duel/ai/decks/invincible_ronald.asm"
INCLUDE "engine/duel/ai/decks/legendary_ronald.asm"
