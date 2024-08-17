; Checks if the command type at a is one of the commands of the attack or
; card effect currently in use, and executes its associated function if so.
; input:
;	a = command type to check
;	[wLoadedAttackEffectCommands] = pointer to the list of commands for the current attack or Trainer card
TryExecuteEffectCommandFunction::
	push af
	; grab pointer to command list from wLoadedAttackEffectCommands
	ld hl, wLoadedAttackEffectCommands
	ld a, [hli]
	ld h, [hl]
	ld l, a
	pop af
	call CheckMatchingCommand
	jr nc, .execute_function
	; return if no matching command was found
	or a
	ret

.execute_function
	; execute the function at [wEffectFunctionsBank]:hl
	ldh a, [hBankROM]
	push af
	ld a, [wEffectFunctionsBank]
	rst BankswitchROM
	or a
	call CallHL
	push af
	; restore original bank and return
	pop bc
	pop af
	rst BankswitchROM
	push bc
	pop af
	ret


; preserves de
; input:
;	a = command type to check
;	hl = list of commands for the current attack or Trainer card
; output:
;	carry = set:  if the command type from input wasn't found
CheckMatchingCommand::
	ld c, a
	ld a, l
	or h
	jr nz, .not_null_pointer
	; return carry if pointer is NULL
	scf
	ret

.not_null_pointer
	ldh a, [hBankROM]
	push af
	ld a, BANK(EffectCommands)
	rst BankswitchROM
	; store the bank number of command functions ($b) in wEffectFunctionsBank
	ld a, BANK("Effect Functions")
	ld [wEffectFunctionsBank], a
.check_command_loop
	ld a, [hli]
	or a
	jr z, .no_more_commands
	cp c
	jr z, .matching_command_found
	; skip function pointer for this command and move to the next one
	inc hl
	inc hl
	jr .check_command_loop

.matching_command_found
	; load function pointer for this command
	ld a, [hli]
	ld h, [hl]
	ld l, a
	; restore bank and return nc
	pop af
	rst BankswitchROM
	or a
	ret

.no_more_commands
	; restore bank and return carry
	pop af
	rst BankswitchROM
	scf
	ret
