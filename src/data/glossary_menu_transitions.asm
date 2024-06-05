; related to wMenuInputTablePointer
; with this table, the cursor moves into the proper location based on the input.
; x coordinate, y coordinate, , D-pad up, D-pad down, D-pad right, D-pad left
OpenGlossaryScreen_TransitionTable:
	cursor_transition $08, $20, $00, $04, $01, $05, $05
	cursor_transition $08, $30, $00, $00, $02, $06, $06
	cursor_transition $08, $40, $00, $01, $03, $07, $07
	cursor_transition $08, $50, $00, $02, $04, $08, $08
	cursor_transition $08, $60, $00, $03, $00, $09, $09
	cursor_transition $60, $20, $00, $09, $06, $00, $00
	cursor_transition $60, $30, $00, $05, $07, $01, $01
	cursor_transition $60, $40, $00, $06, $08, $02, $02
	cursor_transition $60, $50, $00, $07, $09, $03, $03
	cursor_transition $88, $60, $00, $08, $05, $04, $04 ; next page
