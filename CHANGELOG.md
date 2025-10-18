# Pokémon Trading Card Game, Version 2

### Types of Changes:
- [**Bug Fixes For Base Game**](#bug-fixes-for-base-game)
- [**Code Optimization**](#code-optimization)
- [**Miscellaneous Changes**](#miscellaneous-changes)
- [**New Features**](#new-features)
- [**Other Bug Fixes And Commit Reversions**](#other-bug-fixes-and-commit-reversions)
- [**Potential Hacks**](#potential-hacks)

<br/>
<br/>

## Bug Fixes For Base Game

- **[December 6, 2024](https://github.com/Sha0den/poketcg_v2/commit/6cb8f87e0433424b3f0b59ee83fa595a59a84838):** 5 Files Changed
    - Have AI compare amount of attached Energy with each of a Pokémon's attacks when deciding whether a Pokémon is set up, rather than checking if its second attack is usable
        - *this avoids the problem of some Pokémon not having a second attack and also ignores looking at temporary effects that prevent attacking, such as status/substatus/amnesia*
    - Also correct a faulty jump in engine/duel/ai/energy.asm and a math error in home/substatus.asm (all identified in PR #156 of the original disassembly)

<br/>

- **[November 10, 2024](https://github.com/Sha0den/poketcg_v2/commit/3d689aaaf7e151143acd201cb1e9d07a7b983095):** 2 Files Changed
    - Mysterious Fossil and Clefairy Doll are now only considered Basic Pokémon while in the play area
        - *engine/duel/core.asm changes reference `CheckDeckIndexForBasicPokemon` from home/duel.asm, which isn't present in the base disassembly*

<br/>

- **[October 29, 2024](https://github.com/Sha0den/poketcg_v2/commit/3add6c41eed4a983cd971d00060b03134cbfea14):** 2 Files Changed
    - AI now accounts for Energy Burn when evaluating whether or not a Benched Charizard is able to attack

<br/>

- **[October 25, 2024](https://github.com/Sha0den/poketcg_v2/commit/36785feaf2623794af2675260ed881c01c9851c7):** 9 Files Changed
    - Update engine/duel/ai/special_attacks.asm and add entries for MarowakLv32's Wail, GastlyLv8's Destiny Bond, and GastlyLv17's Energy Conversion (all 3 are now usable by AI)
    - Add AI logic for using Moltres's Wildfire attack and replace IGNORE_THIS_ATTACK flag with SPECIAL_AI_HANDLING. (Courtney can now use Wildfire to deck out the Player)
    - Add AI logic for using VenusaurLv64's Solar Power Pokémon Power. (although no AI opponents have VenusaurLv64 in their deck)
    - Also update a few effect functions and refactor the ConvertHPToDamageCounters functions in the AI Logic banks (unrelated to the bug fixing)

<br/>

- **[September 12, 2024](https://github.com/Sha0den/poketcg_v2/commit/cba5b2646b518893a6dc61d6e2991eb13db057e0):** 1 File Changed
    - Prevent the Morph attack from transforming the user into a copy of the exact same card

<br/>

- **[September 3, 2024](https://github.com/Sha0den/poketcg_v2/commit/686b3842584ef587fe3a73947eaf8521ca91b5db):** 2 Files Changed
    - Prevent the header text on the card album and card list screens from being overwritten by new font tiles when scrolling the page
    - This display glitch would only have occurred if the size of the card or booster pack lists were increased or the card names were altered

<br/>

- **[August 17, 2024](https://github.com/Sha0den/poketcg_v2/commit/1d61b53fe1d2b03d15fedbe902dd3035080b35cd):** 4 Files Changed
    - Use [Electro's tutorial](https://github.com/pret/poketcg/wiki/Make-AI-understand-attacks-with-any-energy-cost-combinations) to give the AI the ability to read more complex Energy requirements in attack costs (more than 2 types of Energy)
    - This isn't exactly a bug since there were no multicolored attacks in the base game

<br/>

- **[June 11, 2024](https://github.com/Sha0den/poketcg_v2/commit/114f2463ef738e36f6cbdc36eaceb5a9676d6f69):** 2 Files Changed
    - Replace many uses of `call` with `bank1call` when dealing with functions in bank $01 from the home bank. (It's probably best not to assume that bank 1 will always be loaded.)

<br/>

- **[June 10, 2024](https://github.com/Sha0den/poketcg_v2/commit/3996431c2ce63dd11d4743483eaa071a7e2fbba7):** 2 Files Changed
    - Fix AI logic for using Dugtrio's Earthquake attack
    - Add AI logic for using Dragonite's Step In Pokémon Power (taken from poketcg2)
        - `HandleAIStepIn` correction: `CheckIfDefendingPokemonCanKnockOut` should use `farcall`

<br/>

- **[May 21, 2024](https://github.com/Sha0den/poketcg_v2/commit/637b2675313f43498707565d050d9fcf825319db):** 3 Files Changed
    - Finish fixing the "Big Lightning" and "Dive Bomb" animations
    - Split "Gfx 12" and "Anims 1" into 2 banks
    - Split "Anims 4" and "Palettes1" into 2 banks

<br/>

- **[May 21, 2024](https://github.com/Sha0den/poketcg_v2/commit/3e7fab86d81231648bee2b0256eef81262d78f24):** 17 Files Changed (bugs_and_glitches.md was also removed)
    - Apply new graphics fixes in [bugs_and_glitches.md](https://github.com/pret/poketcg/blob/master/bugs_and_glitches.md#graphics). More specifically:
    - Fix the lower left tiles of the pool area in the Water Club using the wrong color
    - Fix the emblems in the Club entrances using some incorrect tiles
    - Fix a problem with the frame data being used for NPCs with a green palette
    - (Partially) Fix a problem with the "Big Lightning" duel animation
    - (Partially) Fix a problem with the "Dive Bomb" duel animation

<br/>

- **[May 6, 2024](https://github.com/Sha0den/improvedpoketcg/commit/4da8cb3a494cfec17fbe2de9a57e4c2e3c6924c6):** 9 Files Changed (8 are Code Optimization)
    - Fix "Ninetails" typo
    - *A lot more typos were fixed on [May 21, 2024](https://github.com/Sha0den/poketcg_v2/commit/4ac1004d0f7b04743060b5fb916a9fb7640f7cea), [June 7, 2024](https://github.com/Sha0den/poketcg_v2/commit/2414fbf2b12b0fed4b4a3b5fb40cbde95f443ef0), [June 8, 2025](https://github.com/Sha0den/poketcg_v2/commit/f17fcbab1f162220e3cccd2dbdf6eb217a534831), [June 23, 2025](https://github.com/Sha0den/poketcg_v2/commit/6499592040fd7aa41c10a291737bb1d55fc8f6e8), [June 26, 2025](https://github.com/Sha0den/poketcg_v2/commit/7bba92a147bf110ca356f0b7685ae155cf653c50), and [September 26, 2025](https://github.com/Sha0den/poketcg_v2/commit/97f5158c992b3dba198991775d77959f665fd599)*

<br/>

- **[April 15, 2024](https://github.com/Sha0den/improvedpoketcg/commit/2a907f7c823e298803449fb872d10db0aff2d1d6):** 1 File Changed
    - Fix the AI not checking the Unable_Retreat substatus before retreating (credit to Oats)
    - *This was updated in [this commit](https://github.com/Sha0den/poketcg_v2/commit/2c24787cac54a6e85f9f4914c733ab8a980d9a37) (it no longer prevents Switch from being played)*
        - *Check out [bugs_and_glitches.md](https://github.com/pret/poketcg/blob/master/bugs_and_glitches.md) for specific instructions*

<br/>

- **[April 15, 2024](https://github.com/Sha0den/improvedpoketcg/commit/05c13dd163f6c073fbcb7c455d05b762beec6a8d):** 24 Files Changed
    - Apply all of the changes currently laid out in [bugs_and_glitches.md](https://github.com/pret/poketcg/blob/master/bugs_and_glitches.md). More specifically:
    - Fix the AI repeating the Active Pokémon score bonus when attaching an Energy card
    - Fix designated cards not being set aside when the AI places Prize cards
    - Apply the AI score modifiers for retreating
    - Fix a flaw in AI's Professor Oak logic
    - Fix Rick never playing Energy Search
    - Fix Rick using the wrong Pokédex AI subroutine
    - Fix Chris never using Revive on Kangaskhan
    - Fix a flaw in the AI's Pokémon Trader logic for the PowerGenerator deck
    - Fix various flaws in the AI's Full Heal logic
    - Prevent the AI from attacking with a Pokémon Power after playing PlusPower and then evolving
    - Fix the AI never using Energy Trans to retreat
    - Fix Sam's practice deck checking for the wrong card ID
    - Fix various flaws in the AI logic for the Shift Pokémon Power
    - Prevent the AI from being able to use Cowardice without waiting a turn
    - Fix the wrong name being displayed in the Challenge Cup
    - Fix a flaw in the Card Pop logic when comparing player names
    - Add a missing return to the InitPromotionalCardAndDeckCounterSaveData function in src/engine/menus/deck_selection.asm
 


<br/>
<br/>



## Code Optimization

- **October 18, 2025:** 5 Files Changed
    - Move `CheckSkipDelayAllowed` function from src/engine/duel/core.asm to src/home/frames.asm and add `WaitAFrames_AllowSkipDelay` function in same file
    - Add `WaitForAnimationToFinish_AllowSkipDelay` function to src/home/duel.asm
    - Replace some frequently used code in src/engine/duel/core.asm with calls to the above functions
    - Reference the above functions to allow players to skip even more duel delays by holding the B button (e.g. coin flip animations, artificial AI delays, etc.)

<br/>

- **[October 17, 2025](https://github.com/Sha0den/poketcg_v2/commit/e2d701aeb193a385fc6938146b27ef4cadf547d9):** 1 File Changed
    - Refactor `AddCardToHand` and `PutCardInDiscardPile` to match the more optimized `ReturnCardToDeck`
    - Refactor `EmptyPlayAreaSlot` and `PutHandPokemonCardInPlayArea` to make better use of the fact that the play area duel variables are placed together

<br/>

- **[October 16, 2025](https://github.com/Sha0den/poketcg_v2/commit/eace7a43c072901a0fd6ae853e74e3e2bfeaf4e2):** 5 Files Changed
    - Various optimizations and comment changes in src/home/duel.asm. Significant changes include:
        - Refactor `RemoveCardFromDeck`, `RemoveCardFromHand`, and `RemoveCardFromDiscardPile` so that they work better and more similarly
        - Delete the `GetCardIDFromDeckIndex_bc` function and refactor the former calls in `ShuffleDeck`
        - Delete the `CopyAttackDataAndDamage_FromCardID` function and replace the single call in effect functions
    - Rework `CARD_LOCATION_JUST_DRAWN` into a normal 8-bit ID rather than a bit flag
    - Also fix a typo in `ParalyzeBookText` and add further input comments to the `HandleEnergyBurn` function in src/home/card_color.asm

<br/>

- **[October 14, 2025](https://github.com/Sha0den/poketcg_v2/commit/cf02a1af01e796a3c9a290dec747bbbebac8fda0):** 5 Files Changed
    - Rename `RemoveCardFromDeck` in src/engine/menus/deck_configuration.asm to `RemoveCardFromCurDeckCards`
    - Rename `SearchCardInDeckAndAddToHand` in src/home/duel.asm to `RemoveCardFromDeck`
    - Rename `MoveDiscardPileCardToHand` in src/home/duel.asm to `RemoveCardFromDiscardPile`
    - Rename `MoveHandCardToDiscardPile` in src/home/duel.asm to `TryToDiscardCardFromHand`
    - Rename `DealConfusionDamageToSelf` in src/home/duel.asm to `DealDamageToSelf`
    - Create `MoveCardFromDeckToHand` function in src/home/duel.asm and use it to replace `call RemoveCardFromDeck` + `call AddCardToHand`
    - Create `MoveCardFromDiscardPileToHand` function in src/home/duel.asm and use it to replace `call RemoveCardFromDiscardPile` + `call AddCardToHand`
    - Create `MoveCardFromHandToDiscardPile` function in src/home/duel.asm and use it to replace `call RemoveCardFromHand` + `call PutCardInDiscardPile`
    - Create `MoveCardFromHandToTopOfDeck` function in src/home/duel.asm and use it to replace `call RemoveCardFromHand` + `call ReturnCardToDeck`

<br/>

- **[September 22, 2025](https://github.com/Sha0den/poketcg_v2/commit/6fc7f1ef380ed7c2e525f9ec133f483a3e7be361):** 2 Files Changed
    - Merge effect commands for Leer and Tail Wag
    - Rename various effect commands to make them more obvious (e.g. "MayDrawCard" -> "FlipToDrawCard")

<br/>

- **[September 21, 2025](https://github.com/Sha0den/poketcg_v2/commit/919888a50c83f6ed11df09f61972550b5334f328):** 3 Files Changed
    - Swap ASLEEP/CONFUSED constants to match the text symbol order
    - Refactor `CheckPrintCnfSlpPrz` in src/engine/duel/core.asm
    - Add a few comments related to checking duel variables for NO_STATUS

<br/>

- **[September 9, 2025](https://github.com/Sha0den/poketcg_v2/commit/f04e024524167326b82ecd11c6009363915ff69c):** 6 Files Changed
    - Replace kanji in Fullwidth0 fonts (0_2_digits_kanji1.png) with main ascii characters ($20-$7e) and prioritize those over the ones in Fullwidth3
        - *FW0 fonts only need 1 byte per character for text data, whereas FW3 fonts need 2*

<br/>

- **[July 14, 2025](https://github.com/Sha0den/poketcg_v2/commit/c2f366cd0edbe88e7695d1d0ce77c8a29faf1c6a):** 3 Files Changed
    - Implement various optimizations in src/audio/music1.asm, src/audio/music2.asm, and src/audio/sfx.asm
    - Several unreferenced functions in those files were also commented out and placed at the end of its respective file

<br/>

- **[July 11, 2025](https://github.com/Sha0den/poketcg_v2/commit/b2ca4ba2a42015e3cdadf7cc784886afa1b5dd96):** 2 Files Changed
    - Edit `ApplyAndAnimateHPRecovery` function in engine/duel/effect_functions.asm (mostly corrections, but 2 more wram bytes are now unused)

<br/>

- **[May 19, 2025](https://github.com/Sha0den/poketcg_v2/commit/731d69bcb53a1ddda793f35eabe0e7467335c5e6):** 1 File Changed
    - Refactor `DealDamageToAllBenchedPokemon` function in engine/duel/effect_functions.asm

<br/>

- **[December 16, 2024](https://github.com/Sha0den/poketcg_v2/commit/ca27fe4c88d57894a7acdd136314d07ae7f3cda0):** 9 Files Changed
    - Add more calls to `ZeroObjectPositionsAndToggleOAMCopy` and revert to the original order of instructions for that function in home/objects.asm
        - *having the fallthrough would be ideal, but I don't fully understand what the variable load does (something during vblank), so it's probably best to keep the orignal code*

<br/>

- **[December 10, 2024](https://github.com/Sha0den/poketcg_v2/commit/6d0f71e8b91d3b31b79559f22a062e12b89dd522):** 12 Files Changed
    - Miscellaneous small optimizations throughout the AI logic files (plus more comments and a few fixes)
    - Move `AITryUseAttack` from engine/duel/ai/core.asm to engine/duel/ai/attacks.asm
    - Move `AISelectSpecialAttackParameters` from engine/duel/ai/core.asm to engine/duel/ai/special_attacks.asm

<br/>

- **[December 9, 2024](https://github.com/Sha0den/poketcg_v2/commit/cf0172fa077954b802a62840b1a6f550d15c1ae5):** 2 Files Changed
    - Update AI attack logic (engine/duel/ai/attacks.asm)

<br/>

- **[December 5, 2024](https://github.com/Sha0den/poketcg_v2/commit/3ec1ad5dfe3a9a65b638e05bc1b7623b4a18e30f):** 32 Files Changed
    - A wide variety of code optimizations throughout the home and engine files (plus a few corrections)

<br/>

- **[December 4, 2024](https://github.com/Sha0den/poketcg_v2/commit/b6a204da0d1297318db880263380a7bf7c58386a):** 8 Files Changed
    - Major update to the engine/menus files associated with decks and deck building, refactoring A LOT of code and relabeling numerous subroutines

<br/>

- **[December 1, 2024](https://github.com/Sha0den/poketcg_v2/commit/a88234c5bf7b12580d6f788b6e72599b09af66a5):** 1 File Changed
    - Make a wide variety of small optimizations throughout engine/duel/core.asm (plus some label and comment changes)
    - *This commit caused a small glitch which allowed continued scrolling in card lists past the final list entry. ([Link to Bug Fix](https://github.com/Sha0den/poketcg_v2/commit/d902160229dcf3737e14f7ab5d1bd8d67219adec))*

<br/>

- **[November 29, 2024](https://github.com/Sha0den/poketcg_v2/commit/7df3379c8db9846c89243ae6efb319fff9835c3f):** 12 Files Changed
    - Replace `sla a` with `add a` (instances in engine/menus/deck_machine.asm not included; they'll be changed in an upcoming update)

<br/>

- **[November 26, 2024](https://github.com/Sha0den/poketcg_v2/commit/c96a79943ed492b10f2cccfd44d8062d4fdca3f3):** 8 Files Changed
    - Replace `ei` + `ret` with `reti` and `xor $ff` with `cpl`

<br/>

- **[November 24, 2024](https://github.com/Sha0den/poketcg_v2/commit/29b04f2533c70b94653c1acfa9200a3c03898a01):** 2 Files Changed
    - Rewrite the SwitchAfterAttack (Teleport) functions to allow cancelling the attack and create a new effect command for a switch attack that does damage
    - Also clean up some effect functions code that includes `call Random`

<br/>

- **[November 21, 2024](https://github.com/Sha0den/poketcg_v2/commit/56a6afe4a22a0132d5d7b875441c784c14e5c9d8):** 1 File Changed
    - A lot of edits to engine/input_name.asm: labeling, comments, reformating, and refactoring

<br/>

- **[November 20, 2024](https://github.com/Sha0den/poketcg_v2/commit/ac959e618ce1c7b0fdc3147d1badc7321e8f4598):** 19 Files Changed
    - Simplify a lot of code relating to storing and loading pointers in wram

<br/>

- **[November 19, 2024](https://github.com/Sha0den/poketcg_v2/commit/759f08842339c25764c08ecc9e0a0b36272987e6):** 4 Files Changed
    - Refactor a lot of code pertaining to the loading of list pointers when the AI is using a boss deck
    - Change a couple of `cp 1` instructions in those files with `dec a`

<br/>

- **[November 14, 2024](https://github.com/Sha0den/poketcg_v2/commit/5bdad3517e026f2de7021ffaa8f91583ff4bcab7):** 3 Files Changed
    - Refactor some code in engine/menus/duel.asm and engine/menus/play_area.asm
    - Replace a couple of values in engine/menus/duel_init.asm with constants

<br/>

- **[November 12, 2024](https://github.com/Sha0den/poketcg_v2/commit/67af4d1cf7c222b48f497be2ea0457ee7da40980):** 2 Files Changed
    - Rename `ConvertWordToNumericalDigits` engine/menus/print_stats.asm to `ThreeDigitNumberToTxSymbol_TrimLeadingZeros`
    - Plus a few additional comments and a minor refactor of another function in the same file

<br/>

- **[November 12, 2024](https://github.com/Sha0den/poketcg_v2/commit/9366afb18896ae4f8c026516fa89e92381fe37e8):** 1 File Changed
    - Update various comments in engine/menus/mail.asm and implement several minor optimizations

<br/>

- **[November 10, 2024](https://github.com/Sha0den/poketcg_v2/commit/6ba45d6b804745203b419cb58d09445ad30d99d9):** 1 File Changed
    - Use a fallthrough for `.play_sfx` subroutine in each of the deck search (Find*) functions in engine/duel/effect_functions2.asm

<br/>

- **[November 9, 2024](https://github.com/Sha0den/poketcg_v2/commit/51e9c896ca1acc3a66e5d637654bb3c6da68e7a8):** 26 Files Changed
    - Change various instances of $ff to -1 to better comply with the original disassembly's style guide (-1 = empty/false, $ff = list/data terminator)
    - Change some instances of `cp -1` with inc a (so long as the flag differences seemed irrelevant)
    - Remove some redundant loads following menu input functions (when the necessary variable was already loaded to the a register)
    - Edit a lot of input/output comments in the effect function and ai logic files (mostly related to deck indices)

<br/>

- **[November 4, 2024](https://github.com/Sha0den/poketcg_v2/commit/3cf5d16b2d16ed007741a24f0fb16bae620408ce):** 2 Files Changed
    - Move several card list display functions from home/menus.asm (bank $00) to engine/duel/core.asm (bank $01)

<br/>

- **[November 4, 2024](https://github.com/Sha0den/poketcg_v2/commit/70b040d55da09d1620751649e8ef31a3595d2a52):** 9 Files Changed
    - Implement a variety of minor optimizations, all of which are related to printing card lists
    - Correct a few constants (NUM_DECK_SAVE_MACHINE_SLOTS instead of DECK_SIZE and MAX_PLAY_AREA_POKEMON instead of 6)

<br/>

- **[November 2, 2024](https://github.com/Sha0den/poketcg_v2/commit/855713117893d55bdae1137d37cc0f0edf3a6c59):** 17 Files Changed
    - Implement a variety of minor optimizations, most of which are related to the `xor a` instruction setting the a register to 0

<br/>

- **[November 2, 2024](https://github.com/Sha0den/poketcg_v2/commit/23d680517992f61bce8f677dd82adeea52bea52c):** 6 Files Changed
    - Create a `ClearData` function in the home bank and use it to replace the equivalent code in numerous functions

<br/>

- **[November 2, 2024](https://github.com/Sha0den/poketcg_v2/commit/49b05c1d70863e47495f4ea41e86dee41571c01d):** 4 Files Changed
    - Add a `call EnableSRAM` to the start of various functions that end with `jp DisableSRAM`
    - Refactor `CopyPalsToSRAMBuffer` and `LoadPalsFromSRAMBuffer` to remove some redundant code and reduce the amount of cycles used

<br/>

- **[November 1, 2024](https://github.com/Sha0den/poketcg_v2/commit/8ec7f4037239de99d758e5fad16e55a9c64f1a78):** 2 Files Changed
    - Remove `SetMenuItem` from home/menus.asm and inline the code for the single call in engine/duel/core.asm
    - Move `HandleDuelMenuInput` from home/menus.asm (bank $00) to engine/duel/core.asm (bank $01)

<br/>

- **[October 31, 2024](https://github.com/Sha0den/poketcg_v2/commit/9dd0b2d316e844cd67190fb855ae312a1f7085d7):** 9 Files Changed
    - Replace several instances of loading an 8-bit constant into a 16-bit register pair before copying memory with alternate code that only uses a single register
    - Remove `FillMemoryWithA` function from the home bank and replace the 2 calls with (significantly optimized) inlined code that accomplishes the same thing

<br/>

- **[October 31, 2024](https://github.com/Sha0den/poketcg_v2/commit/5158b5994898fdd1801c7df3da6a12e08789cdd7):** 9 Files Changed
    - Replace various copy code with calls to either `CopyNBytesFromHLToDE` or `CopyNBytesFromDEToHL`

<br/>

- **[October 31, 2024](https://github.com/Sha0den/poketcg_v2/commit/fa8765cf82284b83ef7fab91a9aa8890eeeabee7):** 15 Files Changed (although 2 are no longer in the build)
    - Reorganize default palette data and put actual functions in the home bank (now, nothing is stored in engine/duel/core.asm)

<br/>

- **[October 30, 2024](https://github.com/Sha0den/poketcg_v2/commit/27608aa47ef7aac694cf2260d9acc1510d4c6e20):** 3 Files Changed
    - Update some code that checks for the Amnesia attack effect (all related to the `HandleAmnesiaSubstatus` function)

<br/>

- **[October 30, 2024](https://github.com/Sha0den/poketcg_v2/commit/ca55af69053bef9b7e5d6af4c438d2ea4e54a298):** 5 Files Changed
    - Have `CheckUnableToRetreatDueToEffect` check if the Active Pokémon is Asleep or Paralyzed
    - Replace `HandleCantAttackSubstatus` with `CheckUnableToAttackDueToEffect`, which also checks if the Active Pokémon is Asleep or Paralyzed

<br/>

- **[October 30, 2024](https://github.com/Sha0den/poketcg_v2/commit/11890aefed1a428d97da4a1ce08a8cf35db6a780):** 5 Files Changed
    - Replace individual Snorlax and Trainer Pokémon checks with calls to the newly created `CheckIfActiveCardCanBeAffectedByStatus` function in home/substatus

<br/>

- **[October 29, 2024](https://github.com/Sha0den/poketcg_v2/commit/dcb521edfa4736846ca31ce3c3f60a4173f64ec6):** 7 Files Changed
    - Combine the default effect commands for Clefairy Doll and Mysterious Fossil
    - Move `ConvertSpecialTrainerCardToPokemon` from engine/duel/core.asm (bank $01) to engine/duel/effect_functions.asm (bank $09)
    - Move `HandleNShieldAndTransparency` from home/substatus.asm (bank $00) to engine/duel/effect_functions2.asm (bank $0a)
    - Move `HandleStrikesBack_AgainstDamagingAttack` from home/substatus.asm to home/duel.asm (to mirror the other Strikes Back function, which is also stored near its call)
    - Also adjust some comments in both of the Strikes Back functions, as well as a minor optimization for the one in engine/duel/core.asm

<br/>

- **[October 28, 2024](https://github.com/Sha0den/poketcg_v2/commit/30d47a5636d781c8be555ee64a3d364ab2d35e20):** 3 Files Changed
    - Move `ClearDamageReductionSubstatus2`, `UpdateSubstatusConditions_StartOfTurn`, `UpdateSubstatusConditions_EndOfTurn`, and `HandleDestinyBondSubstatus` from home/substatus.asm (bank $00) to engine/duel/core.asm (bank $01)
    - Refactor `HandleDestinyBondSubstatus`

<br/>

- **[October 28, 2024](https://github.com/Sha0den/poketcg_v2/commit/905ad0b3792aaf3025bfff64f34f303592166b25):** 5 Files Changed
    - Add constants for both of the wPlayAreaSelectAction variables
    - Replace the HasAlivePokemonIn* functions in engine/duel/core.asm and with `InitPlayAreaScreenVars` and `InitPlayAreaScreenVars_OnlyBench` (placed in home/duel.asm to reduce bank1calls)
    - The `call HasAlivePokemonInBench` in `CheckAbleToRetreat` was replaced with an inline check that uses DUELVARS_NUMBER_OF_POKEMON_IN_PLAY_AREA
    - The `call HasAlivePokemonInBench` in `ReplaceKnockedOutPokemon`, which was the only call that actually made use of the alive Pokémon check, was replaced by a call to another new function: `CheckForAlivePokemonInBench`
    - Also remove some redundant code in a few of the play area screen functions

<br/>

- **[October 27, 2024](https://github.com/Sha0den/poketcg_v2/commit/3e3113395e32d8cc13e0657b6d59355987a8e4b5):** 3 Files Changed
    - Move `UpdateArenaCardIDsAndClearTwoTurnDuelVars` and `SendAttackDataToLinkOpponent` from home/duel.asm (bank $00) to engine/duel/core.asm (bank $01)

<br/>

- **[October 27, 2024](https://github.com/Sha0den/poketcg_v2/commit/1453ffe28e9d9eb3b32068fd2c1bfeab1b0b20c7):** 4 Files Changed
    - Replace 10 bank1calls by moving `PlayAttackAnimation` from engine/duel/core.asm (bank $01) to home/duel.asm (bank $00)
    - Reorder several functions in home/duel.asm for better organization
    - Use a conditional call/jp to the `PreventAllDamage` function to remove a few bytes from `ApplyDamageModifiers_DamageToTarget` and `DealDamageToPlayAreaPokemon`

<br/>

- **[October 27, 2024](https://github.com/Sha0den/poketcg_v2/commit/90e932be77bc0df9fc8ee9fd7f83e48db3f45514):** 3 Files Changed
    - Move `GetCardInDuelTempList_OnlyDeckIndex`, `GetCardInDuelTempList`, `ApplyDamageModifiers_DamageToTarget`, and `PrintFailedEffectText` from home/duel.asm (bank $00) to engine/duel/core.asm (bank $01)
    - Make a couple of minor changes to `ApplyDamageModifiers_DamageToTarget`

<br/>

- **[October 26, 2024](https://github.com/Sha0den/poketcg_v2/commit/22a5ebe2132879c50ea85a37e551a8538392475c):** 5 Files Changed (although 1 is no longer in the build)
    - Replace 6 bank1calls by moving `DrawWholeScreenTextBox` from engine/duel/core.asm (bank $01) to home/menus.asm (bank $00)

<br/>

- **[October 26, 2024](https://github.com/Sha0den/poketcg_v2/commit/770f9c68a53dc85414d197f6c7a918ca77e6abc3):** 2 Files Changed
    - Replace 2 farcalls by moving `CheckWhichDecksToDismantleToBuildSavedDeck` from engine/auto_deck_machines.asm (bank $06) to engine/menus/deck_machines.asm (bank $02)

<br/>

- **[October 26, 2024](https://github.com/Sha0den/poketcg_v2/commit/85d01a223e4f9036094448df19b700ab30f015a4):** 4 Files Changed
    - Move `DiscardSavedDuelData` from bank $01 to bank $04 to (4 bank1calls -> 3 calls and 1 farcall)
    - Remove some redundant code near the calls to said function

<br/>

- **[October 24, 2024](https://github.com/Sha0den/poketcg_v2/commit/be950e54b78f3461aa1d537ba8da06dcff4b6ba5):** 3 Files Changed
    - Various optimizations in engine/duel/effect_functions.asm that revolve around damage adjustments

<br/>

- **[October 23, 2024](https://github.com/Sha0den/poketcg_v2/commit/259cf40788c4ee2014a0c0c0e2f3cd6a115537e6):** 2 Files Changed
    - Reconfigure a few AI effect commands (`SetDefiniteAIDamage` is redundant if `SetDefiniteDamage` was already called)

<br/>

- **[October 22, 2024](https://github.com/Sha0den/poketcg_v2/commit/505305c696aa4d275830deeef9ac6653351c4f68):** 20 Files Changed
    - Perform various optimizations and update a few of the comments in the engine/duel/ai/decks files

<br/>

- **[October 21, 2024](https://github.com/Sha0den/poketcg_v2/commit/6a9679cf3680c436faf38fede278d9762787076e):** 3 Files Changed
    - Merge the Cowardice Pokémon Power logic (`HandleAICowardice`) into the `HandleAIPkmnPowers` function
    - Put `HandleAIStepIn` in the proper place (after the other functions that are called by `HandleAIPkmnPowers`)
    - The Energy Trans AI functions were also moved below the HandleAIPkmnPowers functions in the [previous commit](https://github.com/Sha0den/poketcg_v2/commit/e2ca1d888cf7692ab13db66819e742c47bd3ca31)

<br/>

- **[October 21, 2024](https://github.com/Sha0den/poketcg_v2/commit/d8ad3a6a2c866fca574781a9e1ece79b0d261631):** 3 Files Changed
    - Swap some variables in the Potion effect functions and AI logic to eliminate the need for a separate `AIPlay_Potion` function

<br/>

- **[October 21, 2024](https://github.com/Sha0den/poketcg_v2/commit/a3d1a4e0a10be97ec18bb0bcca5b446267720286):** 6 Files Changed
    - Remove the `EnergyRemoval_AISelection` effect function since Trainer cards don't use AISelection effect commands
    - Replace the call to that function in `DiscardEnergyDefendingPokemon_AISelection` with a farcall to the real Energy Removal AI logic
    - Move `CheckIfEnergyIsUseful` from engine/duel/ai/core.asm to engine/duel/ai/common.asm to minimize farcalls

<br/>

- **[October 21, 2024](https://github.com/Sha0den/poketcg_v2/commit/ad68f274e15acb7fff1fd8243e229afbf5621a7a):** 7 Files Changed
    - Refactor a lot of functions that loop through DUELVARS_CARD_LOCATIONS

<br/>

- **[October 20, 2024](https://github.com/Sha0den/poketcg_v2/commit/67be952c18bc41bf4f67ebb785d895869e65a730):** 3 Files Changed
    - Various optimizations in engine/duel/core.asm, home/duel.asm, and home/substatus.asm

<br/>

- **[October 19, 2024](https://github.com/Sha0den/poketcg_v2/commit/b0f134ded8387b4fefba042be505ea42cdadd2d4):** 9 Files Changed
    - Make a dedicated function for checking if Toxic Gas is in effect (labeled `CheckIfPkmnPowersAreCurrentlyDisabled` in case other disabling effects are added)

<br/>

- **[October 19, 2024](https://github.com/Sha0den/poketcg_v2/commit/1926adefc60d7ab79ab845eca4308e801035f9ba):** 1 File Changed
    - Condense the Pokémon Power checks being performed during `HandleStrikesBack_AgainstDamagingAttack`
    - *The changes were spread out over two commits because I mistakenly thought that the developers overlooked something. [SECOND COMMIT](https://github.com/Sha0den/poketcg_v2/commit/012e2841921122bdf43c6cdd115436ef9f90a076)*

<br/>

- **[October 18, 2024](https://github.com/Sha0den/poketcg_v2/commit/eaecc5cb00bca6f7489955f6980cf0151712fb1f):** 13 Files Changed
    - Try to standardize the function comments that are used in the engine/duel/ai files (excluding the decks folder)
    - Plus several more code changes in said files (only big change was to `_AIProcessHandTrainerCards`)
    - *A small (but very important) mistake in `_AIProcessHandTrainerCards` was fixed in [This Commit](https://github.com/Sha0den/poketcg_v2/commit/bacaa181c7e2fc484b038c37ee17a5f345540796) and [This Commit](https://github.com/Sha0den/poketcg_v2/commit/f5567f7a3860ed5dc502bcf75458002735427448)*

<br/>

- **[October 15, 2024](https://github.com/Sha0den/poketcg_v2/commit/2c24787cac54a6e85f9f4914c733ab8a980d9a37):** 16 Files Changed
    - Countless optimizations and refactoring in engine/duel/ai files
    - Several functions in said files were relocated and a few others were completely removed
    - Numerous corrections were also made and some of the functions were even expanded
    - *Small AI Energy reversion to fix Rain Dance in [This Commit](https://github.com/Sha0den/poketcg_v2/commit/e489039247565544d26dc6339812820cb3708bf6)*

<br/>

- **[October 10, 2024](https://github.com/Sha0den/poketcg_v2/commit/9512496c1b8161e7e0a0196bc3a7a38fcb17fa10):** 19 Files Changed
    - Miscellaneous optimizations, mostly related to storing information in RAM

<br/>

- **[October 9, 2024](https://github.com/Sha0den/poketcg_v2/commit/f7a85492e5f41651962c34b31d88123e2e979956):** 3 Files Changed
    - Thoroughly review engine/duel/core.asm, updating comments, code, and even some labels
    - Change the name of a subroutine in home/copy.asm into `CopyNBytesFromDEToHL` and use it in a couple of other files

<br/>

- **[October 4, 2024](https://github.com/Sha0den/poketcg_v2/commit/3fe70f141410ba19fc361755f4e83b2beeb99f0f):** 4 Files Changed
    - Thoroughly review the effect functions files, optimizing and occasionally correcting miscellaneous code
    - Update various comments in the effect functions files (also correct `RemoveCardFromDuelTempList`'s output comments in home/duel.asm)
    - Reorder a lot of the individual effect commands (EFFECTCMDTYPE_*) to reflect the actual order of execution
    - *This commit made it impossible for the AI to properly use Porygon's Conversion 2 attack ([Link to Bug Fix](https://github.com/Sha0den/poketcg_v2/commit/ed452d2ef754469d53ba8d608803cf620e90524f))*
    - *This commit also made it impossible for the AI to handle a forced switch from an attack like Whirlwind ([Link to Bug Fix](https://github.com/Sha0den/poketcg_v2/commit/141cff8fd083f30a7f3142f00148e6359ce36f00))*

<br/>

- **[October 1, 2024](https://github.com/Sha0den/poketcg_v2/commit/25cd3432fd601532fc09df09182e802ae802b562):** 1 File Changed
    - Refactor some code and delete a couple of useless lines in home/duel.asm

<br/>

- **[September 30, 2024](https://github.com/Sha0den/poketcg_v2/commit/74b3bb534c4e2a833984e7b81a3fde87ba6f4754):** 32 Files Changed
    - Add/edit a lot of function comments and move a couple of functions (within the same file)
    - Change several magic numbers to the correct constants and add constants for wLineSeparation

<br/>

- **[September 15, 2024](https://github.com/Sha0den/poketcg_v2/commit/fc428d659332548d2c5f5a856518db642db3e29b):** 1 File Changed
    - Some more comments and minor optimizations in home/substatus.asm

<br/>

- **[September 10, 2024](https://github.com/Sha0den/poketcg_v2/commit/115b22557cfb56883fdbca6b1f41c38d3f4bfa85):** 28 Files Changed
    - Replace some jumps that skip over a call with a conditional call (e.g. `call nz`)
    - Replace various instances of 2 numbers being separately loaded into a register pair with a 16-bit load
    - Replace a few uses of `jp` with `jr` and remove a few duplicate `xor a` instructions

<br/>

- **[September 9, 2024](https://github.com/Sha0den/poketcg_v2/commit/cf1016154b7bd1fff82761e55bbbad7138168d50):** 10 Files Changed
    - Eliminate some more tail calls (replacing a `call` and subsequent `ret` with a fallthrough/`jr`/`jp`)

<br/>

- **[September 9, 2024](https://github.com/Sha0den/poketcg_v2/commit/033036f9a242f651e3491c62c51164246d6603df):** 6 Files Changed
    - Remove some more unreferenced functions from the build

<br/>

- **[September 5, 2024](https://github.com/Sha0den/poketcg_v2/commit/623ad9e66c831b60fb67885debddb175175639cd):** 3 Files Changed
    - Make some changes to the effect functions files pertaining to hram labels and eliminate some unnecessary functions in the process.
    - *A missing `ret` was added in [This Commit](https://github.com/Sha0den/poketcg_v2/commit/b009fbaf8dc9aceeb71fbfa9fbbd1ae14c7826b0).*

<br/>

- **[September 1, 2024](https://github.com/Sha0den/poketcg_v2/commit/42156996bbfb3063a016f6319bf8bc051ec79866):** 11 Files Changed
    - Eliminate some unnecessary loading of card data to wram

<br/>

- **[August 31, 2024](https://github.com/Sha0den/poketcg_v2/commit/4ffe5340de65058833e822ae7e257e399ca4653f):** 6 Files Changed
    - Replace `call GetNonTurnDuelistVariable` with the rst macro for `GetTurnDuelistVariable` when `SwapTurn` is being called immediately afterward

<br/>

- **[August 31, 2024](https://github.com/Sha0den/poketcg_v2/commit/ed2e448356415704766b786cfe3c065ea09d926f):** 16 Files Changed
    - Make `_GetCardIDFromDeckIndex` preserve hl and use it instead of `GetCardIDFromDeckIndex` when loading the ID into the a register

<br/>

- **[August 30, 2024](https://github.com/Sha0den/poketcg_v2/commit/7ab6093a8da3e4428df536256b59b0fff77f5c64):** 13 Files Changed
    - Update comments and labels for the 7 pairs of identical functions in engine/duel/ai/core.asm and engine/duel/ai/common.asm (and add an 8th)
    - Shuffle some data around in both of these files

<br/>

- **[August 30, 2024](https://github.com/Sha0den/poketcg_v2/commit/8335d834594459e06b086ecb5d5b799d71436bb0):** 2 Files Changed
    - Consolidate some identical functions in engine/duel/ai/trainer_cards.asm

<br/>

- **[August 29, 2024](https://github.com/Sha0den/poketcg_v2/commit/4366d412043bb39d3359bcf68eacda70fdf0edb6):** 23 Files Changed
    - Remove some unnecessary `ret` instructions in the src/scripts files
    - Fix Amanda's booster pack rewards (now Water-focused instead of Lightning)

<br/>

- **[August 29, 2024](https://github.com/Sha0den/poketcg_v2/commit/66b1e80c8853588458ca4579d3c7885501986444):** 5 Files Changed (1 was deleted)
    - Move all palette data into a single file/bank
    - Add comments to explain what each palette set is used for

<br/>

- **[August 20, 2024](https://github.com/Sha0den/poketcg_v2/commit/0f1b7a282f8738c11b20a3ca9be823c0c7e47ba0):** 13 Files Changed
    - Comment out some unnecessary loads and make use of a new function in the home bank: `GetCardTypeFromDeckIndex_SaveDE`
    - Remove some redundant code in the engine/duel/ai files (e.g. unnecessary stack pushes and pops)
    - Replace some uses of `jp` in said files with `jr` or inlined code and eliminate tail calls (replacing a `call` and subsequent `ret` with a fallthrough/`jr`/`jp`)
    - Rearrange a couple of functions in said files
    - Rename `CopyHandCardList` and `CopyBuffer` to `CopyListWithFFTerminatorFromHLToDE_Bank5` and `CopyListWithFFTerminatorFromHLToDE_Bank8`

<br/>

- **[August 20, 2024](https://github.com/Sha0den/poketcg_v2/commit/a1ace62a57cc82e42ec2d866818b6022bc42add1):** 4 Files Changed
    - Fix register preservation comments for `BankPushROM`, `BankPushROM2`, and `GetCardType`
    - Adjust push/pop instructions surrounding calls to `GetCardType`

<br/>

- **[August 20, 2024](https://github.com/Sha0den/poketcg_v2/commit/164c470aaa69b572173ec9f5194a5990eed8cf74):** 13 Files Changed
    - Try to standardize the function comments that are used in the unsorted engine files
    - Plus some labeling/corrections/optimizations/shuffling of functions in said files

<br/>

- **[August 18, 2024](https://github.com/Sha0den/poketcg_v2/commit/b0b4de78bbb026b745ce87d569f2ebff752c6974):** 3 Files Changed
    - Delete a few unnecessary functions from home/duel_menu.asm

<br/>

- **[August 18, 2024](https://github.com/Sha0den/poketcg_v2/commit/106e2372bfa6f430e41d4544375d32a16519c479):** 21 Files Changed
    - Make `SwapTurn` a restart vector and replace each `call` with `rst` (you could also replace each `jp` with `rst` and a subsequent `ret` to free up even more space, at the cost of 4 cycles per byte saved)

<br/>

- **[August 18, 2024](https://github.com/Sha0den/poketcg_v2/commit/a3f730b15cf5587a098b6af4a107684e67988294):** 5 Files Changed
    - Move some functions from home/duel.asm and home/substatus.asm to engine/duel/core.asm
    - Shuffle a few functions in the home bank

<br/>

- **[August 17, 2024](https://github.com/Sha0den/poketcg_v2/commit/c52579cdc587b88d8103dfb9bad141eeb8f67f89):** 4 Files Changed
    - Use in-lined bank switches instead of `farcall` for a few home bank functions and do the opposite for a couple of rarely used functions that are related to Mankey's Peek

<br/>

- **[August 17, 2024](https://github.com/Sha0den/poketcg_v2/commit/f8ae74bb130f69e77980961ec34160fae067097a):** 26 Files Changed
    - Make `BankSwitchROM` a restart vector and replace each `call` with `rst` (you could also replace each `jp` with `rst` and a subsequent `ret` to free up even more space in the home bank, at the cost of 4 cycles per byte saved)

<br/>

- **[August 17, 2024](https://github.com/Sha0den/poketcg_v2/commit/aa5f126fcf7589bd10738cf0bb732f05b4624dfe):** 28 Files Changed
    - Use [Electro's tutorial](https://github.com/pret/poketcg/wiki/Save-space-and-improve-performance-with-RST-vectors) to make `GetTurnDuelistVariable` a restart vector and replace each `call GetTurnDuelistVariable` with an rst macro

<br/>

- **[August 17, 2024](https://github.com/Sha0den/poketcg_v2/commit/b7df77baf845c570e40bc1cd8c5e9e8c1353b035):** 13 Files Changed
    - Remove all references to the `debug_nop` restart vector

<br/>

- **[August 16, 2024](https://github.com/Sha0den/poketcg_v2/commit/df9b66c73c1c76d0ad48fbb1b6cf2228f6ea360a):** 10 Files Changed
    - Replace numerous instances of `call DisableSRAM` and a later `ret` with `jp DisableSRAM`

<br/>

- **[August 16, 2024](https://github.com/Sha0den/poketcg_v2/commit/ce71442afc97cd8bcdf2a3cfb4dbed17d723717e):** 7 Files Changed
    - Replace numerous instances of `call SwapTurn` and a later `ret` with `jp SwapTurn`

<br/>

- **[August 16, 2024](https://github.com/Sha0den/poketcg_v2/commit/27f907125c4291fe9d8715094d38730daca9ab86):** 19 Files Changed
    - Eliminate some redundant bank 1 functions (mainly from engine/menus/common.asm)

<br/>

- **[August 15, 2024](https://github.com/Sha0den/poketcg_v2/commit/6c2492884a48e725b65165e9e8e7eff305bcff3c):** 5 Files Changed
    - Return `FillBGMapLineWithA` and `FillDEWithA` to engine/menu/deck_configuration.asm
    - Remove some unnecessary `push af` and `pop af` instructions surrounding calls of `BCCoordToBGMap0Address`

<br/>

- **[August 14, 2024](https://github.com/Sha0den/poketcg_v2/commit/576581a7aac4bb8e1da6ab8c1076aabbe927e3fb):** 8 Files Changed
    - Create engine/menus/gift_center.core.asm and move gift center functions in engine/menus/deck_configuration and engine/menu/deck_machine.asm to the new file
    - Organize functions in engine/menus/printer.asm (after importing `PrinterMenu_DeckConfiguration`)
    - Move and label unrelated menu parameter data from engine/menus/gift_center.asm to engine/menus/labels.asm

<br/>

- **[August 13, 2024](https://github.com/Sha0den/poketcg_v2/commit/018fa95ded992eda2701e3377412adbe0c05a421):** 5 Files Changed
    - Move `CopyNBytesFromHLToDE` from engine/menu/deck_configuration.asm to home/copy.asm
    - Refactor several functions to make use of the new home bank function

<br/>

- **[August 13, 2024](https://github.com/Sha0den/poketcg_v2/commit/855f1eab2e27b35620a5e16e965e223d4b215993):** 16 Files Changed
    - Add `InitTextPrinting_PrintTextNoDelay` and `InitTextPrinting_ProcessText` functions
    - Edit some of the comments in home/menus.asm, home/print_text.asm, and home_process_text.asm, plus a few minor optimizations

<br/>

- **[August 11, 2024](https://github.com/Sha0den/poketcg_v2/commit/133b38fda44d1fee37d11d7ed805e47a3c616221):** 5 Files Changed
    - Move coss toss functions from engine/duel.core.asm to a separate file that's linked with a less important bank
    - Align the printed coin tally numbers

<br/>

- **[August 11, 2024](https://github.com/Sha0den/poketcg_v2/commit/edc9a809d7096e625af1e26e41cea6bc2b79693f):** 11 Files Changed
    - Refactor and better organize all functions associated with writing numbers
    - *[This Commit](https://github.com/Sha0den/poketcg_v2/commit/c1249198e62a2e53fecb4c4feabf0c1097870614) swapped the FULLWIDTH3 fonts for TX_SYMBOL fonts in the fullwidth text functions, to avoid overwriting the numbers on screen with other font tiles once VRAM runs out of space for new font tiles*

<br/>

- **[August 9, 2024](https://github.com/Sha0den/poketcg_v2/commit/0a96c62b8cb2588b01647e867eef0ce7ceee8721):** 1 File Changed
    - Comment out some unreferenced data in home/sgb.asm

<br/>

- **[August 8, 2024](https://github.com/Sha0den/poketcg_v2/commit/75be99262d8db5f3222698eb5abbe832d5993fe2):** 10 Files Changed
    - Standardize the functions responsible for playing the confirm/cancel sound effects
    - Eliminate some unnecessary uses of `farcall`

<br/>

- **[August 5, 2024](https://github.com/Sha0den/poketcg_v2/commit/6f6424caf4c5ad4e6853d33f379a3188d97d7483):** 1 File Changed
    - Review and clean up engine/menus/deck_machine.asm
    - *This file also had a small bug which was fixed in [This Commit](https://github.com/Sha0den/poketcg_v2/commit/a75667fb625f0a177c98922351a605e7ee6356b4)*

<br/>

- **[August 4, 2024](https://github.com/Sha0den/poketcg_v2/commit/37fd5f8676a6a3d2583fd40baf6b1bdff03437ba):** 8 Files Changed
    - Eliminate 8 uses of `farcall` by moving `HandleAIMewtwoDeckStrategy` from engine/duel/ai/common.asm to engine/duel/ai/core.asm

<br/>

- **[August 4, 2024](https://github.com/Sha0den/poketcg_v2/commit/a7e60b10a884b3c9bed2ff089cc6c32769e50b3a):** 6 Files Changed (1 was simply deleted)
    - Some refactoring to make use of the `DoAFrames` function
    - Plus some minor home bank clean up

<br/>

- **[August 4, 2024](https://github.com/Sha0den/poketcg_v2/commit/9c61a29d8d38a4c17809979a68b35fbef8513e56):** 5 Files Changed
    - Try to standardize the function comments that are used in the engine/link files
    - Plus some corrections/optimizations in said files

<br/>

- **[August 2, 2024](https://github.com/Sha0den/poketcg_v2/commit/44fc27ab53be4baed0c310fa6a970a90964641f1):** 2 Files Changed
    - Move Prophecy/Pokedex player select effects to engine/duel/effect_functions2.asm

<br/>

- **[August 2, 2024](https://github.com/Sha0den/poketcg_v2/commit/328feb0d910fe875b7226f6868993094b9754813):** 5 Files Changed
    - Move several functions from engine/duel/core.asm to engine/duel/effect_functions.asm
    - Label numerous functions in engine/duel/core.asm and engine/duel/effect_functions.asm

<br/>

- **[August 2, 2024](https://github.com/Sha0den/poketcg_v2/commit/6b7d716a262bc4d6971aa6e2954dc7b85d726f8b):** 3 Files Changed
    - Move a few functions from banks 0/1 to bank 6 (engine/link/link_duel.asm)

<br/>

- **[August 1, 2024](https://github.com/Sha0den/poketcg_v2/commit/8f11d7eeea33e822b14a4cf76b0af9a22ed1153f):** 2 Files Changed
    - Restructure TossCoin functions in home/coin_toss.asm
    - Eliminate a redundant call in home/print_text.asm

<br/>

- **[August 1, 2024](https://github.com/Sha0den/poketcg_v2/commit/23905f186bfe79e892321a09135ca051a55c5c18):** 2 Files Changed
    - Try to standardize the function comments that are used in engine/duel/core.asm
    - Plus some corrections/optimizations/shuffling of functions in said file

<br/>

- **[July 30, 2024](https://github.com/Sha0den/poketcg_v2/commit/a9b7e3235658e1dd0817372a9f0b2fc048e27385):** 3 Files Changed
    - Try to standardize the function comments that are used in the engine/duel/animations files
    - Plus some corrections/optimizations/shuffling of functions in said files

<br/>

- **[July 25, 2024](https://github.com/Sha0den/poketcg_v2/commit/64e64318ae0c40f6aa22eea5b8f3b4c7a7931a9a):** 2 Files Changed
    - Delete the `BankswitchVRAM` function and replace every bank20 `call BankswitchVRAM` and `jp BankswitchVRAM` with the inlined code

<br/>

- **[July 24, 2024](https://github.com/Sha0den/poketcg_v2/commit/a796362f634cac719181ae8cfb6ba055db1d1344):** 9 Files Changed
    - Eliminate some redundant stack pushes and pops (mostly in ai files)

<br/>

- **[July 24, 2024](https://github.com/Sha0den/poketcg_v2/commit/6f75e46422f3daa45fc5ae3860f19aad84e0a958):** 2 Files Changed
    - Eliminate some redundant code in home/duel.asm and home/serial.asm
    - Revise a lot of function comments in home/duel.asm

<br/>

- **[July 23, 2024](https://github.com/Sha0den/poketcg_v2/commit/87cc896a64a7a987321b9fd94c8773aa509a6108):** 1 File Changed
    - Restructure home/math.asm

<br/>

- **[July 21, 2024](https://github.com/Sha0den/poketcg_v2/commit/b96a8555722cb16b35f7eb082f695f283dd28805):** 3 Files Changed
    - Try to standardize the function comments that are used in the effect functions files
    - Plus some corrections/optimizations/shuffling of functions in said files

<br/>

- **[July 14, 2024](https://github.com/Sha0den/poketcg_v2/commit/b070252710fa41169a8ef69c36b2757ec928537e):** 1 File Changed
    - Add some more comments to home/substatus.asm

<br/>

- **[June 26, 2024](https://github.com/Sha0den/poketcg_v2/commit/a05fc6a1988ee931da2ba9e8cef6a197d77f5ef3):** 9 Files Changed
    - Remove some now unreferenced material and put it where it belongs (in debug files)

<br/>

- **[June 26, 2024](https://github.com/Sha0den/poketcg_v2/commit/32960c5081f9c5c653b2552b04b1fd21b8883016):** 17 Files Changed
    - Try to standardize the function comments that are used in the engine/menus files
    - Plus some corrections/optimizations/shuffling of functions in said files

<br/>

- **[June 24, 2024](https://github.com/Sha0den/poketcg_v2/commit/9b47a3046ecab3e451a1b68aae396dd837712634):** 6 Files Changed
    - Try to standardize the function comments that are used in the engine/overworld files
    - Also perform many small optimizations in the engine/overworld files

<br/>

- **[June 22, 2024](https://github.com/Sha0den/poketcg_v2/commit/fbbd4f3f7422ba5a9abcd6878e842c0aec178e02):** 19 Files Changed
    - Delete `Func_7415`, `SetNoLineSeparation`, and `SetOneLineSeparation` from engine/duel.core.asm, replacing any calls with the 2 lines of code from the deleted function
    - Move `SetupPlayAreaScreen` to engine/duel/effect_functions.asm
    - Move `ZeroObjectPositionsAndToggleOAMCopy` to home/objects.asm
    - Move `WaitAttackAnimation` to home/duel.asm
    - Move `SetCardListHeader` and `SetCardListInfoBoxText` to home/menus.asm

<br/>

- **[June 22, 2024](https://github.com/Sha0den/poketcg_v2/commit/90115177c0340127d97cf4dba6724703c17b448b):** 9 Files Changed
    - Add comments related to setting the carry flag for a variety of home bank functions
    - Perform minor optimizations in home/duel.asm related to setting the carry flag

<br/>

- **[June 21, 2024](https://github.com/Sha0den/poketcg_v2/commit/9ffd656449cac8b8781dedc4a466900ef8af1928):** 3 Files Changed
    - Try to standardize the function comments that are used in engine/bank20.asm and the engine/sequences files
    - Remove some unnecessary code from the aforementioned files

<br/>

- **[June 20, 2024](https://github.com/Sha0den/poketcg_v2/commit/15bf474bae975ce662a989f5f4410f84b5a7906b):** 3 Files Changed
    - Move debug.asm from engine/menus and debug_player_coordinates.asm from engine/overworld to engine/unused

<br/>

- **[June 20, 2024](https://github.com/Sha0den/poketcg_v2/commit/0e5c4e7ac27f6c5fee1642ec227dc8edf24d5a11):** 4 Files Changed
    - Try to standardize the function comments that are used in the engine/gfx files
    - Remove several unnecessary stack pushes and pops in engine/gfx/sprite_animations.asm

<br/>

- **[June 19, 2024](https://github.com/Sha0den/poketcg_v2/commit/45a08ab02dd879c4c6cc03672c4c3d7b8cde3957):** 7 Files Changed (Plus 5 Files Relocated)
    - Comment out a few more unreferenced functions in the home bank
    - Move debug_sprites, unused_copyright.asm, and unused_save_validation.asm from engine to engine/unused
    - Move debug_main.asm and unknown.asm from engine/menus to engine/unused

<br/>

- **[June 19, 2024](https://github.com/Sha0den/poketcg_v2/commit/2b85afde883a2f142ba237b4077cc256d2d4b976):** 1 File Changed
    - Delete `JPWriteByteToBGMap0` and add a slight optimization for `PrintDuelResultStats`

<br/>

- **[June 18, 2024](https://github.com/Sha0den/poketcg_v2/commit/afee23873ee49f2ace256d0319fc28d8b95e0b96):** 6 Files Changed
    - Delete `ResetDoFrameFunction` functions, and replace each call with the requisite lines of code

<br/>

- **[June 18, 2024](https://github.com/Sha0den/poketcg_v2/commit/a852ba61fb251f4076828524a41d14d2b2d616cd):** 21 Files Changed (4 of these were removed from the repository)
    - Shuffle some functions in the home bank for better organization
    - Delete the redundant `JPHblankCopyDataHLtoDE` function
    - Add a missing colon to fix a build error from the commit below this one

<br/>

- **[June 18, 2024](https://github.com/Sha0den/poketcg_v2/commit/f5c84e957054bc2548219821aa6a2ec4d196d3a6):** 5 Files Changed
    - Shuffle some functions in the home bank that are related to printing numbers (and use more accurate labels)

<br/>

- **[June 17, 2024](https://github.com/Sha0den/poketcg_v2/commit/f7b97cccbcd62933c6bd8ade0834cf9aca1fca6f):** 3 Files Changed
    - Reorganize the functions in home/substatus.asm

<br/>

- **[June 17, 2024](https://github.com/Sha0den/poketcg_v2/commit/2b8bfd555bbb4076890d0f962847224401c8e90d):** 51 Files Changed
    - Try to standardize the function comments that are used in the home bank files
    - Also eliminate some redundant code and swap out a few more `ld` instructions with `ldh`
    - *Further adjustments made in [This Commit](https://github.com/Sha0den/poketcg_v2/commit/acf60372628574a3e4c5d03c47c1ee058f1fe5ec)*

<br/>

- **[June 9, 2024](https://github.com/Sha0den/poketcg_v2/commit/d289b673ae0d6f90b464b754b03736d6769da9c1):** 6 Files Changed
    - Remove some unnecessary uses of `farcall` (instead of `call`) and `ld [hff__], a` (instead of `ldh [hff__]`)

<br/>

- **[June 8, 2024](https://github.com/Sha0den/poketcg_v2/commit/6a516a2208165aa1f8296bfed4ce3b32033e2608):** 1 File Changed
    - Revise/add code comments and perform minor code optimizations in engine/save.asm

<br/>

- **[June 8, 2024](https://github.com/Sha0den/poketcg_v2/commit/4bd79c758a81be021487c9961d7873208009f5fd):** 1 File Changed
    - Revise/add code comments and perform minor code optimizations in engine/overworld_map.asm

<br/>

- **[June 6, 2024](https://github.com/Sha0den/poketcg_v2/commit/043ab5b4aa51c1164b2745cd367bb38ab703197e):** 40 Files Changed
    - Eliminate most tail calls in the non-ai engine files (replacing a `call` and subsequent `ret` with a fallthrough/`jr`/`jp`)
    - Rearrange some functions in the non-ai engine files to replace some uses of `jp` with `jr` or a fallthrough

<br/>

- **[June 3, 2024](https://github.com/Sha0den/poketcg_v2/commit/7ee531a00d768ea38ac6abcd5854b6a22d002f1c):** 22 Files Changed
    - Rearrange some functions in the home bank to replace some uses of `jp` with `jr` or a fallthrough
    - Eliminate remaining home bank tail calls (replacing a `call` and subsequent `ret` with a fallthrough/`jr`/`jp`)
        - *Intentially ignored `BankpopROM` tail calls (that function can't be jumped to)*

<br/>

- **[May 29, 2024](https://github.com/Sha0den/poketcg_v2/commit/d9cbaa4bd90be37a382faa9cd81c903b1f92d66f):** 35 Files Changed
    - Refactor code to minimize use of unconditional `jr` instructions
    - Other minor optimizations, most of which involve jumps

<br/>

- **[May 27, 2024](https://github.com/Sha0den/poketcg_v2/commit/2ebfcd7572efe3007ed6fa75a8719fc4c395a04f):** 11 Files Changed
    - Refactor a variety of code pertaining to the effect functions
    - Fix numerous errors in the effect functions code
    - Replace some hexadecimal numbers with the appropriate icon tile offset constants
    - Miscellaneous Text Changes

<br/>

- **[May 17, 2024](https://github.com/Sha0den/improvedpoketcg/commit/ebd54a7d1dff4084a149f63f822959c088e70e8f):** 3 Files Changed
    - Review most of the code comments in the effect functions files
    - Replace many uses of `jp` with `jr` and fallthroughs, moving functions as necessary
    - Refactor several effect functions

<br/>

- **[May 10, 2024](https://github.com/Sha0den/improvedpoketcg/commit/e910babd0c69b6d87ed1e20b4f7ef6fda3cc2b4e):** 2 Files Changed
    - Refactor some code in src/engine/duel/effect_functions2.asm

<br/>

- **[May 10, 2024](https://github.com/Sha0den/improvedpoketcg/commit/1fc0c919be2bc0d5a52d230bc37de9e74ed47c37):** 2 Files Changed
    - Refactor some code in src/engine/duel/effect_functions.asm

<br/>

- **[May 8, 2024](https://github.com/Sha0den/improvedpoketcg/commit/569060cc0e7d3ffd3a56d4e556aa25c4387d5edd):** 36 Files Changed
    - Remove some redundant code
    - Use `jr` instead of `jp` for numerous shorter jumps
    - Replace some conditional jumps to returns with conditional returns (e.g. `ret z` instead of `jr z, .done`)
    - Refactor some code in src/engine/duel/effect_functions.asm and effect_functions2.asm
    - Removed references to Sand Attack substatus (since it was merged with Smokescreen substatus)
    - *The changes to AIDecide_GustOfWind crash the game ([Link to Bug Fix](https://github.com/Sha0den/poketcg_v2/commit/4602ebf753565eeef9c9d46d8355182c05b531f7))*

<br/>

- **[May 7, 2024](https://github.com/Sha0den/improvedpoketcg/commit/c146befe2ff38d1b0137bb8a4d0a6dc2563a289f):** 9 Files Changed
    - Remove some redundant code

<br/>

- **[May 6, 2024](https://github.com/Sha0den/improvedpoketcg/commit/4da8cb3a494cfec17fbe2de9a57e4c2e3c6924c6):** 9 Files Changed (1 is Bug Fix)
    - Eliminate some home bank tail calls (replacing a `call` and subsequent `ret` with a fallthrough/`jr`/`jp`)
    - Replace some conditional jumps to returns with conditional returns (e.g. `ret z` instead of `jr z, .done`)
    - Remove some redundant code
    - Refactor some code in src/engine/duel/effect_functions.asm
    - Add a couple of division functions to src/home/math.asm

<br/>

- **[May 4, 2024](https://github.com/Sha0den/improvedpoketcg/commit/8e5497cdb3950f1c19e8bc55a15afacb544bef7e):** 7 Files Changed
    - Combine various subroutines related to setting or resetting the carry flag for Effect Functions and AI Logic banks

<br/>

- **[May 4, 2024](https://github.com/Sha0den/improvedpoketcg/commit/8e71e22a71c4d8e39ba31ed851a550cb1cca1c09):** 52 Files Changed
    - Comment out most unreferenced functions and move them to a section at the end of each file
    - Unlink debug_main.asm, debug_sprites.asm, unknown.asm, unused_copyright.asm, and unused_save_validation.asm from src/main.asm and src/layout.link
    - Remove some redundant lines of code
    - Replace some conditional jumps to returns with conditional returns (e.g. `ret z` instead of `jr z, .done`)
    - Replace various conditional jumps to set carry subroutines in the home bank with jumps to the ReturnCarry function

<br/>

- **[May 4, 2024](https://github.com/Sha0den/improvedpoketcg/commit/7b59707e529d248be59d125abc1bd282e5e789b3):** 12 Files Changed
    - Replace any mistaken bank1calls with calls
    - Label several unlabeled functions in src/engine/duel/core.asm and effect_functions.asm

<br/>

- **[April 30, 2024](https://github.com/Sha0den/improvedpoketcg/commit/16f4361737eba3e68d5829d45276c6521bedc7d1):** 26 Files Changed
    - Comment out many unreferenced functions in the home bank
    - Remove src/home/ai.asm and src/home/damage.asm and unlink them from src/home.asm
    - Transfer some functions out of the home banks
    - Eliminate some same bank tail calls (replacing a `call` and subsequent `ret` with a fallthrough/`jr`/`jp`)
    - Replace some mistaken uses of `farcalls` and `bank1call` with `call`
    - *Relocating some of the home bank functions led to some crashes ([Reversion #1](https://github.com/Sha0den/improvedpoketcg/commit/eb38cd2a5b1b9b91d3c2a83baefe7a5a29917d2f), [Reversion #2](https://github.com/Sha0den/improvedpoketcg/commit/c3e01965877e98d425d696233ba56e8e43fa0a91), [Reversion #3](https://github.com/Sha0den/poketcg_v2/commit/0982afa57559a557f3ddbf6ecabe43151c00f2dd))*

<br/>

- **[April 29, 2024](https://github.com/Sha0den/improvedpoketcg/commit/eb4497ad2cef51dbe3690b09196b2e5046ae7ab7):** 14 Files Changed
    - Remove some redundant lines of code
    - Eliminate some same bank tail calls (replacing a `call` and subsequent `ret` with a fallthrough/`jr`/`jp`)
    - Replace some conditional jumps to returns with conditional returns (e.g. `ret z` instead of `jr z, .done`)

<br/>

- **[April 15, 2024](https://github.com/Sha0den/improvedpoketcg/commit/1ffe5922e6bcbe14ffd91422067e636788b4ebd2):** 19 Files Changed (Half are Miscellaneous Changes)
    - Massively condense Effect Commands and Effect Functions
 


<br/>
<br/>



## Miscellaneous Changes

- **[October 11, 2025](https://github.com/Sha0den/poketcg_v2/commit/9261880af434b4074709323b8daceaddd9f15df5):** 2 Files Changed
    - Create a left-facing cursor icon and add it to the text symbols (`CURSOR_L`)
    - Relocate `CURSOR_D` and `POKEMON` text symbols so that all 4 cursors are grouped together after the status symbols

<br/>

- **[October 10, 2025](https://github.com/Sha0den/poketcg_v2/commit/931b668efad1476731b25b2082b68c57563df7d2):** 13 Files Changed
    - Make `wAlreadyPlayedEnergy` and `wConfusionRetreatCheckWasUnsuccessful` into bit flags on a single wram byte (wOncePerTurnFlags)
    - Plus a minor optimization in `CheckSelfConfusionDamage` and a few extra comments in src/wram.asm

<br/>

- **[October 9, 2025](https://github.com/Sha0den/poketcg_v2/commit/b2931545551de449bfccf76c90f6e67ff230272b):** 6 Files Changed
    - Various improvements from my [Speed up the start of the game tutorial](https://github.com/pret/poketcg/wiki/Speed-up-the-start-of-the-game):
        - Revise the optional tutorial changes from [This Commit](https://github.com/Sha0den/improvedpoketcg/commit/b37fdd04d9d228a46be2e27ecf64407bcf1a5302)
        - Pressing the B button will now skip the delay for all Message Speeds other than 1
        - I also decreased the default text speed to 4 (1 extra frame per font tile)

<br/>

- **[October 7, 2025](https://github.com/Sha0den/poketcg_v2/commit/f3b054372fcc8772b6edd73cedbea3cbc0a54cbe):** 5 Files Changed
    - Free up another text symbol by removing the reference mark (※); it's still in the fullwidth3 fonts
    - Adjust attack menu to display a centered ellipsis (•••) below the attack name when an attack has an effect (rather than a reference mark to the far right)
    - Create `CountEnergyInAttackCost` and add it to the Unreferenced Functions section in src/engine/duel/core.asm (I decided not to adjust attack cost printing)

<br/>

- **[September 26, 2025](https://github.com/Sha0den/poketcg_v2/commit/97f5158c992b3dba198991775d77959f665fd599):** 7 Files Changed
    - Print the default `ReceivedPromotionalCardText` upon receiving a Flying/Surfing Pikachu and delete their custom text entries
        - This effectively just replaces "Flyin' Pikachu" with "Flying Pikachu Lv12" and "Surfin' Pikachu" with "Surfing Pikachu Lv13!"
    - Undo changes to one of the lines of text in the practice duel and recapitalize various instances of the phrase "Card Master"
    - Also fix a lot more typos from the original game

<br/>

- **[September 20, 2025](https://github.com/Sha0den/poketcg_v2/commit/51165185bfb986bb2992500a00ff3fb4d61858c4):** 6 Files Changed
    - Create a 16x8 (technically 13x7) HP symbol for the duel screens and update the previous E symbol I made to match it
    - Rearrange the PlusPower/Defender symbols on the various duel screens
        - They're stacked vertically on the right side of the play area and card page screens (PlusPower after Energy and Defender after HP)
        - They're listed directly below the Pokémon's HP on the main duel screen (Defender is placed several tiles to the right if PlusPower is also attached)
    - Rewrite `PrintPlayAreaCardAttachedEnergies` to make the maximum amount of symbols that are printed an input variable (rather than always capping at 8)
        - The main duel screen still uses the original limit, but as many as 10 symbols can now be shown on the play area and card page screens
    - Create `PrintCurrentAndMaxHP` function to remove some duplicate code
    - *[The following commit](https://github.com/Sha0den/poketcg_v2/commit/af4a9239f21365c4b45ed81f0376857af6597476) included the changes made to src/engine/duel/core.asm (I somehow managed to exclude yet another file)*

<br/>

- **[September 17, 2025](https://github.com/Sha0den/poketcg_v2/commit/4ba7e23c1410e359a15fbad803037c3e83880125):** 18 Files Changed
    - Free up 3 text symbols by using traditional fullwidth/halfwidth fonts for the Lv, HP, and E symbols
    - Redesign the Lv and E symbols
    - *[The following commit](https://github.com/Sha0den/poketcg_v2/commit/f119425f4f051891b2868fb3745ef57de419612e) added the changes to `0_2_digits_kanji1.png` (I somehow forgot to include the file.)*
    - *And [the commit after that](https://github.com/Sha0den/poketcg_v2/commit/d293c1a9d0c0bc9d4d06592f54ec138868cae35d) fixed the warning message that was shown after compiling the rom*

<br/>

- **[September 7, 2025](https://github.com/Sha0den/poketcg_v2/commit/40ff8b442ae20d9fa2cb7228b94b713088d13110):** 2 Files Changed
    - Speed up animations for shuffling decks, drawing cards, flipping coins, and the Firegiver Pokémon Power (credit to JappaWakka/Paperfire88)

<br/>

- **[July 10, 2025](https://github.com/Sha0den/poketcg_v2/commit/1e8542517507c7fade1863725401a36ee39eac13):** 1 File Changed
    - Make text capitalization more consistent in the Credits sequence (Titles are all caps, but names use standard casing)

<br/>

- **[July 7, 2025](https://github.com/Sha0den/poketcg_v2/commit/4505d0e1db565f7c8f3e4be9bd6b78b0268d2559):** 7 Files Changed
    - Adjust horizontal spacing between entries in each of the check menu screens (deck select, deck machines, and in-duel)
        - the offset is now variable (uses wCheckMenuCursorXPositionOffset instead of always adding 10)
    - Edit some of the text labels used for the various check menu options
    - Replace "Cancel" in deck select submenu with "Dismantle This Deck" and reorder options in deck save machine submenu
    - Rewrite the instructions for sending cards to another player to account for the changes to the deck building menu (now opened with START instead of B)

<br/>

- **[July 2, 2025](https://github.com/Sha0den/poketcg_v2/commit/6e569c4b3253dee0df3109a8d85100411e888fc3):** 1 File Changed
    - The SELECT button can now be used in the deck select screen to make the currently selected deck the player's active deck
    - Adjust the sound effect that is played when an empty deck slot is chosen

<br/>

- **[June 27, 2025](https://github.com/Sha0den/poketcg_v2/commit/9a1f7284738512a1c7d2796726956483133b82f4):** 5 Files Changed
    - Add tiles for a START button to the fullwidth3 fonts
    - Add a notification to the deck building screen explaining that the menu can be opened by pressing START

<br/>

- **[December 15, 2024](https://github.com/Sha0den/poketcg_v2/commit/4dd1d90c9d5908ce6522bd3407af88b68fddbd4d):** 14 Files Changed
    - Major update to the deck building screen menu
        - Input changes: Deck building menu is now opened via the START button (instead of B), but either button will close it. Pressing B button in the deck builder now asks the player whether they want to quit; if "Yes" is selected and the deck is both valid and different from the original configuration, then it will also ask the player whether they want to save the new version. Since START now opens the menu, the confirmation screen can only be accessed through the menu option.
        - New menu options: "Cancel" and "Modify" are replaced by "Discard Changes", which resets the deck to the original configuration (but doesn't exit the deck builder), and "Empty Deck", which removes every card from the deck (but doesn't exit the deck builder or affect the actual save data). Also renamed "Confirm" to "View Deck List", "Name" to "Change Name", "Save" to "Save and Quit", and "Dismantle" to "Delete Deck".
        - Add a Deck Statistics window below the window with the menu options. This displays the deck name along with the number of Basic Pokémon, Evolutions, Trainers, and Energy.
    - Add a halfwidth overline character that can be used to underline text from the previous line (also updated fullwidth3 lowercase "k" character)
    - Create `InitTextPrinting_ProcessCenteredText` function for printing center aligned text and use it in `YesOrNoMenuWithText` (also add SFX after choosing "Yes" or "No")
    - Create `WriteOneByteNumberInHalfwidthTextFormat_TrimLeadingZeros` function and add it to home/write_number.asm
    - Create some clear functions in home/tiles.asm to be used as alternatives to `EmptyScreen` for minor screen transitions
    - *[The following commit](https://github.com/Sha0den/poketcg_v2/commit/b9549e134b73b6189cc7b01f388529c54c840fea) reverted the center alignment change to `YesOrNoMenuWithText` because it didn't account for ramtext or adjust the coordinates for background scrolling (I might revisit the idea later)*

<br/>

- **[November 23, 2024](https://github.com/Sha0den/poketcg_v2/commit/36efe66857cb965b1d7883a930afa9415766c032):** 4 Files Changed
    - Use the deck naming screen when naming the Player at the start of the game
        - *The Player's name now uses halfwidth font, so it can be up to 12 characters long*
        - *All of the old player naming functions were commented out and moved to the end of the file*
    
<br/>

- **[November 8, 2024](https://github.com/Sha0den/poketcg_v2/commit/151a63eb0641e3c8fa649ff24f3e11bd3f43a3d1):** 5 Files Changed
    - Increase minimum probability for a type when generating a booster pack card to 5% (1/160 -> 8/160), to encourage more variety
    - Officially add Double Colorless Energy to the Mystery set and remove the code that allows any Energy card to be included in a booster, regardless of set
        - *Energy cards are still treated differently in the card album to ensure they appear at the end of the set list*
    - Optimize many of the functions in engine/booster_packs.asm
    - *Further changes were made to the card album Energy code in the [following commit](https://github.com/Sha0den/poketcg_v2/commit/973dac5db8b51079e527d73bd80d9a7960146a44), to more easily adapt to possible changes to the card pool*

<br/>

- **[November 7, 2024](https://github.com/Sha0den/poketcg_v2/commit/c86d7d74d4cd475c0a48a4a91c5301f293557fa2):** 12 Files Changed
    - Update numerous aspects of the Card Album display (includes some changes to texts and ram, as well as editing the Fullwidth0 question mark)
    - Also optimize various code and update some of the comments and labels in engine/menus/card_album.asm

<br/>

- **[October 26, 2024](https://github.com/Sha0den/poketcg_v2/commit/445c35d61ddbcd21d6c1b2baed7326427431ea34):** 7 Files Changed
    - Change Unknown2 byte for Pokémon card data to PokemonFlags and update constants, card data, and AI logic accordingly

<br/>

- **[October 23, 2024](https://github.com/Sha0den/poketcg_v2/commit/b26e4b94074c9c47839c1f7b59e8fc13d3344593):** 6 Files Changed
    - Update various attack data, AI logic, and constants relating to the attack flags that are stored in card data

<br/>

- **[September 10, 2024](https://github.com/Sha0den/poketcg_v2/commit/706cf64f04e7ac7d71bd505bc35c2b6e0a91d9fa):** 2 Files Changed (1 was deleted)
    - Remove remaining rom comparison references in `Makefile` and delete `rom.sha1`

<br/>

- **[September 9, 2024](https://github.com/Sha0den/poketcg_v2/commit/d87ba6cad6f1fde098f4260f1003de499a09f97e):** 128 Files Deleted
    - Remove the .match files for the map graphics data

<br/>

- **[August 27, 2024](https://github.com/Sha0den/poketcg_v2/commit/f6a9e26233234a45d170ad9776bd6e0b48f58408):** 4 Files Changed
    - Update the palettes and icons for Ronald's and the Player's duelist portraits (most changes were taken from the sequel's portraits)
    - Identify palettes that are used for all of the duelist portraits

<br/>

- **[August 15, 2024](https://github.com/Sha0den/poketcg_v2/commit/d7050ca9cd207220c60d520d1c2f70f2175eb35c):** 3 Files Changed
    - Make the phantom cards (Venusaur Lv64 and Mew Lv15) obtainable without using Card Pop! by adding them to the list of possible Challenge Cup prizes

<br/>

- **[August 12, 2024](https://github.com/Sha0den/poketcg_v2/commit/3fa4a8c98343049ee5e2505aae7168b8353c1a9f):** 6 Files Changed
    - Pokedex numbers now use 2 bytes to support Pokemon from all generations
    - Although, the printing function will have to be edited if it exceeds 3 digits (1,000+)

<br/>

- **[August 3, 2024](https://github.com/Sha0den/poketcg_v2/commit/0849ad946e2b0cef4a08988d983e7e3f3516c674):** 1 File Changed
    - Use [Electro's tutorial](https://github.com/pret/poketcg/wiki/Remove-AI-artificial-delay) to remove the artificial delay applied to many of the AI's actions

<br/>

- **[June 13, 2024](https://github.com/Sha0den/poketcg_v2/commit/cbe3b8afba7bebd0cb490fdf7f8a81d6dd92390d):** 1 File Changed
    - Make the default player name (Mark) mixed case and have it be displayed with halfwidth font tiles to match the rest of the game's text

<br/>

- **[June 9, 2024](https://github.com/Sha0den/poketcg_v2/commit/dd9ea3eb13636a9e10f35340549c051dc2037248):** 1 File Changed (technically 2 since I renamed the original sprite)
    - Use JappaWakka's updated Double Colorless Energy sprite (with 2 Energy symbols)

<br/>

- **[June 7, 2024](https://github.com/Sha0den/poketcg_v2/commit/2414fbf2b12b0fed4b4a3b5fb40cbde95f443ef0):** 17 Files Changed
    - Revise various texts and combine some texts that are identical

<br/>

- **[June 5, 2024](https://github.com/Sha0den/poketcg_v2/commit/6efa226438dbbea8da455ef84f284525fd2b8306):** 10 Files Changed
    - Make small adjustments to the menu screens related to deck selection
    - Replace hand_cards icon with a deck_box icon I made (used to represent the active deck)
    - Also add a deck icon next to the other completed decks on the deck selection screens
    - Revise/add code comments and perform minor code optimizations in both engine/menus/deck_configuration.asm and engine/menus/deck/selection.asm
    - Replace all uses of `ld a, [hff__]` in the repository with `ldh a, [hff__]`
    - Alter the number fonts stored in gfx/fonts/full_width?/0_2_digits_kanji1.png

<br/>

- **[June 2, 2024](https://github.com/Sha0den/poketcg_v2/commit/b16b83b296ee35aa3d05b7066ed8c649343e0879):** 16 Files Changed
    - Update the Glossary (both the overall display and the actual text information)
    - Increase the size of the font tile section in vram when viewing the Glossary from a duel
    - Create many new fullwidth and halfwidth font characters, plus 2 new text box symbols
    - Move a lot of texts from text3.asm to text2.asm (Needed more space for Glossary)
    - Move a lot of texts from text2.asm to text1.asm
    - Make some minor adjustments to several of the title menu texts in text3.asm
    - *The newly added `DrawTextBoxSeparator` function was later fixed in [This Commit](https://github.com/Sha0den/poketcg_v2/commit/1125a231a37aa3217d2684badcbfff5776fad9bc).*

<br/>

- **[May 30, 2024](https://github.com/Sha0den/poketcg_v2/commit/265a0f002e721711d2daec6be55d5b1672caf384):** 1 File Changed
    - Attempt to identify all unused wram bytes (total is around 2 kilobytes)
    - Edit some of the existing comments in wram.asm and create some new ones as well

<br/>

- **[May 21, 2024](https://github.com/Sha0den/poketcg_v2/commit/4ac1004d0f7b04743060b5fb916a9fb7640f7cea):** 22 Files Changed
    - Fix minor typos and remove end of line spaces in the text files
    - Adjust texts to better fit the 2 line display used by the text boxes
    - Rewrite some of the larger texts, like glossary pages and tutorial messages
    - Use spaces to center most of the Trainer and Energy card descriptions

<br/>

- **[May 15, 2024](https://github.com/Sha0den/improvedpoketcg/commit/d2b3e7dd7191c401256f5bd9e3aabf8829871862):** 1 File Changed
    - Decrease the wait time during the overworld section of the game's intro

<br/>

- **[May 15, 2024](https://github.com/Sha0den/improvedpoketcg/commit/9901b4b04b2df70f8eb4918b05c20da6bc281efc):** 2 Files Changed
    - Give Text Offsets its own bank (instead of sharing one with Text 1)
    - *Text pointers were later adjusted in [This Commit](https://github.com/Sha0den/poketcg_v2/commit/09f3400366b809053a31210ddc368f6273896608)*

<br/>

- **[May 12, 2024](https://github.com/Sha0den/improvedpoketcg/commit/a22046c5fd4ddf967e4ea0793a79abbdf80cc7aa):** 4 Files Changed
    - Add text speed constants and increase the default text speed to the fastest setting
    - *The default text speed was eventually decreased to 4 in a later commit*

<br/>

- **[May 11, 2024](https://github.com/Sha0den/improvedpoketcg/commit/cc8e8f12c8e65bd2d2f2c3618f2ec43a66d62c86):** 1 File Changed
    - Adjust scroll arrows in the card album (no longer on top of the border)

<br/>

- **[May 10, 2024](https://github.com/Sha0den/improvedpoketcg/commit/3f90bae82966445864bc3054d5204667d93b7ef9):** 8 Files Changed
    - Replace the "No" text symbol with a fullwidth "#" and display leading zeroes in Pokédex numbers

<br/>

- **[May 8, 2024](https://github.com/Sha0den/improvedpoketcg/commit/3d4d1a18b5a69749b178d77c5ec54a11ed687fff):** 13 Files Changed
    - Remove dead space (ds $--) in the GFX and Text banks

<br/>

- **[May 6, 2024](https://github.com/Sha0den/improvedpoketcg/commit/8b73cb2b06e28ab4d1c0b7148f1198c6a8ef4443):** 1 File Changed
    - Change the name of the rom file produced by this repository from "poketcg.gbc" to "poketcg_v2.gbc"

<br/>

- **[April 26, 2024](https://github.com/Sha0den/improvedpoketcg/commit/efbd16d2c95ac964c158107d56ffb04af067b3ad):** 1 File Changed
    - Align the list numbers in the top right of the card list header

<br/>

- **[April 16, 2024](https://github.com/Sha0den/improvedpoketcg/commit/31a2cf426dfcccbd4d25b5af3d18a77845a01dc2):** 3 Files Changed
    - Update fullwidth and halfwidth font graphics and some of the box messages
    - *Further Adjustments to box_messages.png in [This Commit](https://github.com/Sha0den/improvedpoketcg/commit/673f4965565af76c3ff95c26988b2b024d04e380)*

<br/>

- **[April 16, 2024](https://github.com/Sha0den/improvedpoketcg/commit/180ea5c9b6e0965a32b3cdc37b474b8b8a97c8ef):** 1 File Changed
    - Replace the word "Hand" with the hand icon from the duel graphics in the play area screens
    - *Note that the "11" in the first line of `_DrawPlayAreaToPlacePrizeCards.player_icon_coordinates` should also be changed to "10" (applied in [This Commit](https://github.com/Sha0den/poketcg_v2/commit/6499592040fd7aa41c10a291737bb1d55fc8f6e8))*

<br/>

- **[April 15, 2024](https://github.com/Sha0den/improvedpoketcg/commit/1ffe5922e6bcbe14ffd91422067e636788b4ebd2):** 19 Files Changed (Half are Code Optimization)
    - Remove rom matching comparison
    - Split "Decks" and "Cards" into 2 banks
    - Add another Text bank, which uses the newly created text14.asm
    - Add another Effect Functions bank, which uses the newly created effect_functions2.asm
    - Update a wide variety of duel texts
 


<br/>
<br/>



## New Features

- **[November 23, 2024](https://github.com/Sha0den/poketcg_v2/commit/1ddbd58ad2236e388cd5cfc7c7d2b50ad42de644):** 12 Files Changed
    - Redesign the deck naming screen to allow more variety when naming
        - *Keyboard now has 3 layouts (switch between them by pressing SELECT or the Uppercase/Lowercase/Accents buttons)*
    - Update and reformat the halfwidth/fullwidth3 font graphics and redistribute the graphics data to account for the larger size
    - *[The following commit](https://github.com/Sha0den/poketcg_v2/commit/36efe66857cb965b1d7883a930afa9415766c032) replaces the original player naming screen with the new deck naming screen (also makes the player name use halfwidth font)*

<br/>

- **[November 5, 2024](https://github.com/Sha0den/poketcg_v2/commit/750a585911a4652d4f8a7b85557da7995ee89bc8):** 12 Files Changed
    - Implement new booster pack card list display that informs the player which cards from the booster pack are newly obtained (using a red ! symbol)
        - *Most of the edited functions from engine/duel/core.asm were originally located in home/menus.asm*
    - Separate BoosterPackText into 2 texts: 1 for the card album's table of contents and another for the booster pack card list header

<br/>

- **[August 22, 2024](https://github.com/Sha0den/poketcg_v2/commit/f621d292bce067b1f346896554dde4f944a1949d):** 22 Files Changed
    - Use [Electro's tutorial](https://github.com/pret/poketcg/wiki/Add-female-player-character) to add the option to play as Mint, the female protagonist from the sequel
    - *Some texts with gender-specific pronouns were eventually fixed in [This Commit](https://github.com/Sha0den/poketcg_v2/commit/6499592040fd7aa41c10a291737bb1d55fc8f6e8)*

<br/>

- **[June 1, 2024](https://github.com/Sha0den/poketcg_v2/commit/3cccfcb07e93fa73d4bc0ab4978a295d98321e4a):** 2 Files Changed
    - Display lowercase halfwidth font characters
    - Increase size of half_width.png to account for future additions

<br/>

- **[May 15, 2024](https://github.com/Sha0den/improvedpoketcg/commit/29c218bf8169f5123b1e3b886217ea76cb506b8f):** 5 Files Changed
    - Add support for common accented characters (halfwidth and fullwidth)
    - Expand the halfwidth font graphics (at the cost of some kanji)
    - *This commit caused a major text display glitch ([Link to Bug Fix](https://github.com/Sha0den/improvedpoketcg/commit/dbe0431ed7e5492ea5fed6cfe99c48872abe4698))*
    - *[The deck naming screen update](https://github.com/Sha0den/poketcg_v2/commit/1ddbd58ad2236e388cd5cfc7c7d2b50ad42de644) includes more edits to halfwidth and fullwidth font data (also redistributed data in src/gfx.asm and updated pointers in home/tiles.asm as a more sensible alternative to commenting out some of the Japanese font data)*

<br/>

- **[May 14, 2024](https://github.com/Sha0den/improvedpoketcg/commit/b37fdd04d9d228a46be2e27ecf64407bcf1a5302):** 3 Files Changed
    - The practice game with Sam at the start of the game is now optional
        - *Please reference my tutorial at [https://github.com/pret/poketcg/wiki/Speed-up-the-start-of-the-game](https://github.com/pret/poketcg/wiki/Speed-up-the-start-of-the-game) if attempting to copy this change to another repository (the original code isn't optimized)*

<br/>

- **[May 10, 2024](https://github.com/Sha0den/improvedpoketcg/commit/13c38116fc85504d9e05b68de8133275213f6173):** 1 File Changed
    - Add a scroll arrow to a Trainer or Pokémon attack card page when the description is continued on another page (credit to Oats)

<br/>

- **[April 16, 2024](https://github.com/Sha0den/improvedpoketcg/commit/0679b2ca09c04106dcc7e8e80bd6ea02d0f14e4d):** 4 Files Changed
    - Display the Promostar symbol on card pages

<br/>

- **[April 15, 2024](https://github.com/Sha0den/improvedpoketcg/commit/ae0ee380fe2c32211f527c5a6d395c6484121a49):** 1 File Changed
    - Replace damage counter display with "current HP/max HP"
    - The maximum HP value of a Pokémon is now 250 (was 120)
        - *Please reference my tutorial at [https://github.com/pret/poketcg/wiki/Replace-damage-counters-with-numbers-to-allow-higher-HP-values-(120-→-250)](https://github.com/pret/poketcg/wiki/Replace-damage-counters-with-numbers-to-allow-higher-HP-values-(120-→-250)) if attempting to copy this change to another repository (the original code isn't optimized)*

<br/>

- **[April 15, 2024](https://github.com/Sha0den/improvedpoketcg/commit/669e9b7f0d1b8ec54eb66012354434a5cb7ca7f3):** 1 File Changed
    - Cards can now have Weakness or Resistance to Colorless (Use WR_COLORLESS)



<br/>
<br/>



## Other Bug Fixes And Commit Reversions

- **[October 14 2025](https://github.com/Sha0den/poketcg_v2/commit/141cff8fd083f30a7f3142f00148e6359ce36f00):** 1 File Changed
    - Fix AI output for `DuelistSelectForcedSwitch` function (AI will now switch after being attacked with Ram, Terror Strike, or Whirlwind)
    - *This is a bug fix for [This Commit](https://github.com/Sha0den/poketcg_v2/commit/3fe70f141410ba19fc361755f4e83b2beeb99f0f)*

<br/>

- **[October 9, 2025](https://github.com/Sha0den/poketcg_v2/commit/dd19fa91a96f86da2a85af35e17a4d16477573b7):** 1 File Changed
    - Undo "bugfix" for `Func_fc279` in src/audio/sfx.asm (which actually caused audio glitches), and instead delete the function and inline the 1 relevant load
    - *This completely undoes [This Commit](https://github.com/Sha0den/poketcg_v2/commit/a2f7df8d521655fa22a13e21c3713ffb5b101c72)*

<br/>

- **September 25 2025:** 2 Files Changed
    - Implement a few fixes related to loading opponent's card data without first calling `SwapTurn` (AI will now correctly use Conversion 2 once more)
        - The instance in src/engine/duel/ai/retreat.asm was actually present in the base game
    - *This is a bug fix for [This Commit](https://github.com/Sha0den/poketcg_v2/commit/3fe70f141410ba19fc361755f4e83b2beeb99f0f)*

<br/>

- **[July 1 2025](https://github.com/Sha0den/poketcg_v2/commit/c0d1e2dbe78107ac2feaea493df94e5ef96c3bfc):** 1 File Changed
    - Fix a small issue with the deck building screen where the static card type cursor at the top of the screen wasn't always being redrawn after exiting the menu
    - *This is a bug fix for [This Commit](https://github.com/Sha0den/poketcg_v2/commit/4dd1d90c9d5908ce6522bd3407af88b68fddbd4d)*

<br/>

- **[June 23, 2025](https://github.com/Sha0den/poketcg_v2/commit/6499592040fd7aa41c10a291737bb1d55fc8f6e8):** 9 Files Changed
    - Fix a lot more typos and text issues, several of which were related to the player character possibly being female *(A few more were fixed in [the following commit](https://github.com/Sha0den/poketcg_v2/commit/7bba92a147bf110ca356f0b7685ae155cf653c50).)*
    - Adjust the player's hand icon on the duel setup screen so that it isn't partially covered up by the text box
    - *Thanks to JappaWakka for pointing out most of the errors that were fixed in this and the previous typo commits.*

<br/>

- **[June 8, 2025](https://github.com/Sha0den/poketcg_v2/commit/f17fcbab1f162220e3cccd2dbdf6eb217a534831):** 5 Files Changed
    - Fix numerous small typos *(A couple more were fixed in [the previous commit](https://github.com/Sha0den/poketcg_v2/commit/05c1fd87d04213dffac0ad4b3f742d8ef6df7783).)*
    - Reverse order of male & female symbols in halfwidth fonts to match src/constants/charmaps.asm (also edit halfwidth comma)

<br/>

- **[December 27, 2024](https://github.com/Sha0den/poketcg_v2/commit/d902160229dcf3737e14f7ab5d1bd8d67219adec):** 1 File Changed
    - Revert a small change to `CardListMenuFunction` in engine/duel/core.asm. The secondary down input check was not redundant; it's needed after exiting from a card page.
    - *This is a bug fix for [This Commit](https://github.com/Sha0den/poketcg_v2/commit/a88234c5bf7b12580d6f788b6e72599b09af66a5)*

<br/>

- **[November 19, 2024](https://github.com/Sha0den/poketcg_v2/commit/e489039247565544d26dc6339812820cb3708bf6):** 1 File Changed
    - Revert a small change to engine/duel/ai/energy.asm (because Rain Dance was causing the game to freeze)
    - *This is a bug fix for [This Commit](https://github.com/Sha0den/poketcg_v2/commit/2c24787cac54a6e85f9f4914c733ab8a980d9a37)*

<br/>

- **[October 21, 2024](https://github.com/Sha0den/poketcg_v2/commit/bacaa181c7e2fc484b038c37ee17a5f345540796):** 1 File Changed
    - Fix an oversight (merging 2 jumps when one of them was conditional) with the new `_AIProcessHandTrainerCards` code
    - Ended up making another oversight (missing `pop hl`) that was addressed in [This Commit](https://github.com/Sha0den/poketcg_v2/commit/f5567f7a3860ed5dc502bcf75458002735427448)
    - *These are bug fixes for [This Commit](https://github.com/Sha0den/poketcg_v2/commit/eaecc5cb00bca6f7489955f6980cf0151712fb1f)*

<br/>

- **[September 11, 2024](https://github.com/Sha0den/poketcg_v2/commit/1125a231a37aa3217d2684badcbfff5776fad9bc):** 3 Files Changed
    - Make `DrawTextBoxSeparator` function SGB-compatible (it no longer crashes the game)
    - *This is a bug fix for [This Commit](https://github.com/Sha0den/poketcg_v2/commit/b16b83b296ee35aa3d05b7066ed8c649343e0879)*

<br/>

- **[August 18, 2024](https://github.com/Sha0den/poketcg_v2/commit/cbfce31cab1e997d446cd57bbed99990fb7ca27a):** 1 File Changed
    - Revert the textpointers because it screws up the printing of some empty texts (plus everything works fine without making any adjustments)
    - *This completely undoes [This Commit](https://github.com/Sha0den/poketcg_v2/commit/fe4c091b38639bc5b52078c9ac153a0eac12ae01)*

<br/>

- **[August 2, 2024](https://github.com/Sha0den/poketcg_v2/commit/af31753844fcabe625eab1a1439ade00567086f9):** 1 File Changed
    - Change a conditional return to a conditional jump to avoid missing a couple of pops
    - *This is a bug fix for [This Commit](https://github.com/Sha0den/poketcg_v2/commit/23905f186bfe79e892321a09135ca051a55c5c18)*

<br/>

- **[June 11, 2024](https://github.com/Sha0den/poketcg_v2/commit/0350841247da35c6b11c79f88f58ca5a1f1050bb):** 1 File Changed
    - Use `farcall` when `CheckIfCanEvolveInto_BasicToStage2` is accessed by the AI Logic 2 bank
    - *This is a bug fix for [This Commit](https://github.com/Sha0den/improvedpoketcg/commit/1ffe5922e6bcbe14ffd91422067e636788b4ebd2)*

<br/>

- **[May 27, 2024](https://github.com/Sha0den/poketcg_v2/commit/4602ebf753565eeef9c9d46d8355182c05b531f7):** 1 File Changed
    - Revert a change to `AIDecide_GustOfWind` that was causing the game to crash
    - *This is a bug fix for [This Commit](https://github.com/Sha0den/poketcg_v2/commit/569060cc0e7d3ffd3a56d4e556aa25c4387d5edd)*

<br/>

- **[May 24, 2024](https://github.com/Sha0den/poketcg_v2/commit/0982afa57559a557f3ddbf6ecabe43151c00f2dd):** 5 Files Changed
    - Put a few more functions back in the home bank
    - At least the booster pack one was causing a crash
    - *This is a bug fix for [This Commit](https://github.com/Sha0den/improvedpoketcg/commit/16f4361737eba3e68d5829d45276c6521bedc7d1)*

<br/>

- **[May 23, 2024](https://github.com/Sha0den/poketcg_v2/commit/5969356ada125d565e72bf34d37ca90f2ce8f73e):** 8 Files Changed
    - Put all of the animation and palette data back in their original locations
    - *This completely undoes [This Commit](https://github.com/Sha0den/poketcg_v2/commit/35903e93b9fb412009cec5f03ae57e90fa101c00) that sorted all of the animation and palette data in the proper banks*

<br/>

- **[May 22, 2024](https://github.com/Sha0den/poketcg_v2/commit/7d81aabc704174c6b6447946c7cd6871f52660ae):** 2 Files Changed
    - Revert some text changes relating to duel texts
    - *This cancels out some of the changes from [This Commit](https://github.com/Sha0den/improvedpoketcg/commit/1ffe5922e6bcbe14ffd91422067e636788b4ebd2)*

<br/>

- **[May 15, 2024](https://github.com/Sha0den/improvedpoketcg/commit/dbe0431ed7e5492ea5fed6cfe99c48872abe4698):** 1 File Changed
    - Removed Fullwidth4 instead of 1 & 2 to fix the wrong characters being displayed
    - *This is a major bug fix for [This Commit](https://github.com/Sha0den/improvedpoketcg/commit/29c218bf8169f5123b1e3b886217ea76cb506b8f)*

<br/>

- **[May 8, 2024](https://github.com/Sha0den/improvedpoketcg/commit/c3e01965877e98d425d696233ba56e8e43fa0a91):** 2 Files Changed
    - Put `Func_3bb5` back in the home bank
    - *This is a possible bug fix for [This Commit](https://github.com/Sha0den/improvedpoketcg/commit/16f4361737eba3e68d5829d45276c6521bedc7d1)*

<br/>

- **[May 7, 2024](https://github.com/Sha0den/improvedpoketcg/commit/eb38cd2a5b1b9b91d3c2a83baefe7a5a29917d2f):** 4 Files Changed
    - Put `AIDoAction` functions back in the home bank
    - *This is a major bug fix for [This Commit](https://github.com/Sha0den/improvedpoketcg/commit/16f4361737eba3e68d5829d45276c6521bedc7d1)*

<br/>

- **[May 7, 2024](https://github.com/Sha0den/improvedpoketcg/commit/519e8348ae85be540ad4af4bb1b087ae72f02d13):** 4 Files Changed
    - Revert some set carry flag optimizations in the AI Logic 1 bank
    - *This cancels out some of the changes from [This Commit](https://github.com/Sha0den/improvedpoketcg/commit/8e5497cdb3950f1c19e8bc55a15afacb544bef7e)*

<br/>

- **[April 15, 2024](https://github.com/Sha0den/improvedpoketcg/commit/e55f2176d099949e2baf95f4efba4b01121705ac):** 8 Files Changed
    - Fix some text display issues caused by the first commit
    - *This is a minor bug fix for [This Commit](https://github.com/Sha0den/improvedpoketcg/commit/1ffe5922e6bcbe14ffd91422067e636788b4ebd2)*



<br/>
<br/>



## Potential Hacks
- **[August 16, 2024](https://github.com/Sha0den/poketcg_v2/commit/2843d5458f802c3b1b918b8b04b6d6f30d46e005):** Only Need to Change 1 File
    - Instructions for giving the Player a full card collection (credit to Oats)

<br/>

- **[May 14, 2024](https://github.com/Sha0den/improvedpoketcg/commit/62a73e33e60c8e5b61d477bb1b9f0f675def074c):** Only Need to Change 1 File
    - Instructions for skipping the mandatory practice duel with Sam
    - This is less relevant now that the practice duel is optional
