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
- **[August 17, 2024](https://github.com/Sha0den/poketcg_v2/commit/1d61b53fe1d2b03d15fedbe902dd3035080b35cd):** 4 Files Changed
    - Use [Electro's tutorial](https://github.com/pret/poketcg/wiki/Make-AI-understand-attacks-with-any-energy-cost-combinations) to give the AI the ability to read more complex Energy requirements in attack costs (more than 2 types of Energy)
    - This isn't exactly a bug since there were no multicolored attacks in the base game

<br/>

- **[June 11, 2024](https://github.com/Sha0den/poketcg_v2/commit/114f2463ef738e36f6cbdc36eaceb5a9676d6f69):** 2 Files Changed
    - Change some mistaken calls to bank1calls

<br/>

- **[June 10, 2024](https://github.com/Sha0den/poketcg_v2/commit/3996431c2ce63dd11d4743483eaa071a7e2fbba7):** 2 Files Changed
    - Fix AI logic for using Dugtrio's Earthquake attack
    - Add AI logic for using Dragonite's Step In Pokémon Power (taken from poketcg2)

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

<br/>

- **[April 15, 2024](https://github.com/Sha0den/improvedpoketcg/commit/2a907f7c823e298803449fb872d10db0aff2d1d6):** 1 File Changed
    - Fix the AI not checking the Unable_Retreat substatus before retreating (credit to Oats)

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
- **August 20, 2024:** 4 Files Changed
    - Fix register preservation comments for 'BankPushROM', 'BankPushROM2', and 'GetCardType'
    - Adjust push/pop instructions surrounding calls to 'GetCardType'

<br/>

- **[August 20, 2024](https://github.com/Sha0den/poketcg_v2/commit/164c470aaa69b572173ec9f5194a5990eed8cf74):** 13 Files Changed
    - Try to standardize the function comments that are used in the unsorted engine files
    - Plus some labeling/corrections/optimizations/shuffling of functions in said files

<br/>

- **[August 18, 2024](https://github.com/Sha0den/poketcg_v2/commit/b0b4de78bbb026b745ce87d569f2ebff752c6974):** 3 Files Changed
    - Delete a few unnecessary functions from home/duel_menu.asm

<br/>

- **[August 18, 2024](https://github.com/Sha0den/poketcg_v2/commit/106e2372bfa6f430e41d4544375d32a16519c479):** 21 Files Changed
    - Make 'SwapTurn' a restart vector and replace each "call" with "rst" (you could also replace each "jp" with "rst" and a "ret" to free up even more space, at the cost of 4 cycles per byte saved)

<br/>

- **[August 18, 2024](https://github.com/Sha0den/poketcg_v2/commit/a3f730b15cf5587a098b6af4a107684e67988294):** 5 Files Changed
    - Move some functions from home/duel.asm and home/substatus.asm to engine/duel/core.asm
    - Shuffle a few functions in the home bank

<br/>

- **[August 17, 2024](https://github.com/Sha0den/poketcg_v2/commit/c52579cdc587b88d8103dfb9bad141eeb8f67f89):** 4 Files Changed
    - Use in-lined bank switches instead of farcalls for a few home bank functions and do the opposite for a couple of rarely used functions that are related to Mankey's Peek

<br/>

- **[August 17, 2024](https://github.com/Sha0den/poketcg_v2/commit/f8ae74bb130f69e77980961ec34160fae067097a):** 26 Files Changed
    - Make 'BankSwitchROM' a restart vector and replace each "call" with "rst" (you could also replace each "jp" with "rst" and a "ret" to free up even more space in the home bank, at the cost of 4 cycles per byte saved)

<br/>

- **[August 17, 2024](https://github.com/Sha0den/poketcg_v2/commit/aa5f126fcf7589bd10738cf0bb732f05b4624dfe):** 28 Files Changed
    - Use [Electro's tutorial](https://github.com/pret/poketcg/wiki/Save-space-and-improve-performance-with-RST-vectors) to make 'GetTurnDuelistVariable' a restart vector and replace each "call GetTurnDuelistVariable" with an rst macro

<br/>

- **[August 17, 2024](https://github.com/Sha0den/poketcg_v2/commit/b7df77baf845c570e40bc1cd8c5e9e8c1353b035):** 13 Files Changed
    - Remove the "debug_nop" rst

<br/>

- **[August 16, 2024](https://github.com/Sha0den/poketcg_v2/commit/df9b66c73c1c76d0ad48fbb1b6cf2228f6ea360a):** 10 Files Changed
    - Replace numerous instances of "call DisableSRAM/ret" with "jp SwapTurn"

<br/>

- **[August 16, 2024](https://github.com/Sha0den/poketcg_v2/commit/ce71442afc97cd8bcdf2a3cfb4dbed17d723717e):** 7 Files Changed
    - Replace numerous instances of "call SwapTurn/ret" with "jp SwapTurn"

<br/>

- **[August 16, 2024](https://github.com/Sha0den/poketcg_v2/commit/27f907125c4291fe9d8715094d38730daca9ab86):** 19 Files Changed
    - Eliminate some redundant bank 1 functions (mainly from engine/menus/common.asm)

<br/>

- **[August 15, 2024](https://github.com/Sha0den/poketcg_v2/commit/6c2492884a48e725b65165e9e8e7eff305bcff3c):** 5 Files Changed
    - Return 'FillBGMapLineWithA' and 'FillDEWithA' to engine/menu/deck_configuration.asm
    - Remove some unnecessary push af/pop af surrounding calls of 'BCCoordToBGMap0Address'

<br/>

- **[August 13, 2024](https://github.com/Sha0den/poketcg_v2/commit/018fa95ded992eda2701e3377412adbe0c05a421):** 5 Files Changed
    - Move 'CopyNBytesFromHLToDE' from engine/menu/deck_configuration.asm to home/copy.asm
    - Refactor several functions to make use of the new home bank function

<br/>

- **[August 13, 2024](https://github.com/Sha0den/poketcg_v2/commit/855f1eab2e27b35620a5e16e965e223d4b215993):** 16 Files Changed
    - Add 'InitTextPrinting_PrintTextNoDelay' and 'InitTextPrinting_ProcessText' functions
    - Edit some of the comments in home/menus.asm, home/print_text.asm, and home_process_text.asm, plus a few minor optimizations

<br/>

- **[August 11, 2024](https://github.com/Sha0den/poketcg_v2/commit/edc9a809d7096e625af1e26e41cea6bc2b79693f):** 11 Files Changed
    - Refactor and better organize all functions associated with writing numbers
    - [This commit](https://github.com/Sha0den/poketcg_v2/commit/c1249198e62a2e53fecb4c4feabf0c1097870614) swapped the FULLWIDTH3 fonts for TX_SYMBOL fonts in the fullwidth text functions, to avoid overwriting the numbers on screen with other font tiles once VRAM runs out of space for new font tiles

<br/>

- **[August 8, 2024](https://github.com/Sha0den/poketcg_v2/commit/75be99262d8db5f3222698eb5abbe832d5993fe2):** 10 Files Changed
    - Standardize the functions responsible for playing the confirm/cancel sound effects
    - Eliminate some unnecessary farcalls

<br/>

- **[August 5, 2024](https://github.com/Sha0den/poketcg_v2/commit/6f6424caf4c5ad4e6853d33f379a3188d97d7483):** 1 File Changed
    - Review and clean up engine/menus/deck_machine.asm
    - This file also had a small bug which was fixed in [this commit](https://github.com/Sha0den/poketcg_v2/commit/a75667fb625f0a177c98922351a605e7ee6356b4)

<br/>

- **[August 4, 2024](https://github.com/Sha0den/poketcg_v2/commit/37fd5f8676a6a3d2583fd40baf6b1bdff03437ba):** 8 Files Changed
    - Eliminate 8 farcalls by moving HandleAIMewtwoDeckStrategy from engine/duel/ai/common.asm to engine/duel/ai/core.asm

<br/>

- **[August 4, 2024](https://github.com/Sha0den/poketcg_v2/commit/a7e60b10a884b3c9bed2ff089cc6c32769e50b3a):** 6 Files Changed (1 was simply deleted)
    - Some refactoring to make use of the DoAFrames function
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
    - Delete BankswitchVRAM function and replace every bank20 call/jp with the inlined code

<br/>

- **[July 24, 2024](https://github.com/Sha0den/poketcg_v2/commit/a796362f634cac719181ae8cfb6ba055db1d1344):** 9 Files Changed
    - Eliminate some redundant pushes and pops (mostly in ai files)

<br/>

- **[July 24, 2024](https://github.com/Sha0den/poketcg_v2/commit/6f75e46422f3daa45fc5ae3860f19aad84e0a958):** 2 Files Changed
    - Eliminate some redundant code in home/duel.asm and home/serial.asm
    - Revise a lot of function comments in home/duel.asm

<br/>

- **[July 21, 2024](https://github.com/Sha0den/poketcg_v2/commit/b96a8555722cb16b35f7eb082f695f283dd28805):** 3 Files Changed
    - Try to standardize the function comments that are used in the effect functions files
    - Plus some corrections/optimizations/shuffling of functions in said files

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
    - Delete "Func_7415", "SetNoLineSeparation", and "SetOneLineSeparation" from engine/duel.core.asm, replacing any calls with the 2 lines of code from the deleted function
    - Move "Func_61a1" to engine/duel/effect_functions.asm
    - Move "ZeroObjectPositionsAndToggleOAMCopy" to home/objects.asm
    - Move "WaitAttackAnimation" to home/duel.asm
    - Move "SetCardListHeader" and "SetCardListInfoBoxText" to home/menus.asm

<br/>

- **[June 22, 2024](https://github.com/Sha0den/poketcg_v2/commit/90115177c0340127d97cf4dba6724703c17b448b):** 9 Files Changed
    - Add comments related to setting the carry flag for a variety of home bank functions
    - Perform minor optimizations in home/duel.asm related to setting the carry flag

<br/>

- **[June 21, 2024](https://github.com/Sha0den/poketcg_v2/commit/9ffd656449cac8b8781dedc4a466900ef8af1928):** 3 Files Changed
    - Try to standardize the function comments that are used in engine/bank20.asm and the engine/sequences files
    - Remove some unnecessary code from the aforementioned files

<br/>

- **[June 20, 2024](https://github.com/Sha0den/poketcg_v2/commit/0e5c4e7ac27f6c5fee1642ec227dc8edf24d5a11):** 4 Files Changed
    - Try to standardize the function comments that are used in the engine/gfx files
    - Remove several unnecessary push/pops in engine/gfx/sprite_animations.asm

<br/>

- **[June 19, 2024](https://github.com/Sha0den/poketcg_v2/commit/2b85afde883a2f142ba237b4077cc256d2d4b976):** 1 File Changed
    - Delete JPWriteByteToBGMap0 and add a slight optimization for PrintDuelResultStats

<br/>

- **[June 18, 2024](https://github.com/Sha0den/poketcg_v2/commit/afee23873ee49f2ace256d0319fc28d8b95e0b96):** 6 Files Changed
    - Delete ResetDoFrameFunction functions, and replace each call with the requisite lines of code

<br/>

- **[June 17, 2024](https://github.com/Sha0den/poketcg_v2/commit/2b8bfd555bbb4076890d0f962847224401c8e90d):** 51 Files Changed
    - Try to standardize the function comments that are used in the home bank files
    - Also eliminate some redundant code and update a few more ld's to ldh's
    - Further adjustments made in [This Commit](https://github.com/Sha0den/poketcg_v2/commit/acf60372628574a3e4c5d03c47c1ee058f1fe5ec)

<br/>

- **[June 9, 2024](https://github.com/Sha0den/poketcg_v2/commit/d289b673ae0d6f90b464b754b03736d6769da9c1):** 6 Files Changed
    - Remove some unnecessary farcalls and use "ldh" for "ld [hff__], a"

<br/>

- **[June 8, 2024](https://github.com/Sha0den/poketcg_v2/commit/6a516a2208165aa1f8296bfed4ce3b32033e2608):** 1 File Changed
    - Revise/add code comments and perform minor code optimizations in engine/save.asm

<br/>

- **[June 8, 2024](https://github.com/Sha0den/poketcg_v2/commit/4bd79c758a81be021487c9961d7873208009f5fd):** 1 File Changed
    - Revise/add code comments and perform minor code optimizations in engine/overworld_map.asm

<br/>

- **[June 6, 2024](https://github.com/Sha0den/poketcg_v2/commit/043ab5b4aa51c1164b2745cd367bb38ab703197e):** 40 Files Changed
    - Eliminate most tail calls in the non-ai engine files (replacing a call ret with a fallthrough/jr/jp)
    - Rearrange some functions in the non-ai engine files to replace some jp's with jr's or fallthroughs

<br/>

- **[June 3, 2024](https://github.com/Sha0den/poketcg_v2/commit/7ee531a00d768ea38ac6abcd5854b6a22d002f1c):** 22 Files Changed
    - Rearrange some functions in the home bank to replace some jp's with jr's or fallthroughs
    - Eliminate remaining home bank tail calls (replacing a call ret with a fallthrough/jr/jp)
        - *Intentially ignored BankpopROM tail calls (that function can't be jumped to)*

<br/>

- **[May 29, 2024](https://github.com/Sha0den/poketcg_v2/commit/d9cbaa4bd90be37a382faa9cd81c903b1f92d66f):** 35 Files Changed
    - Refactor code to minimize use of unconditional jr's
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
    - Replace many jp's with jr's and fallthroughs, moving functions as necessary
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
    - Replace some jp's with jr's
    - Replace some conditional jumps to returns with conditional returns (e.g. "ret z" instead of "jr z, .done")
    - Refactor some code in src/engine/duel/effect_functions.asm and effect_functions2.asm
    - Removed references to Sand Attack substatus (since it was merged with Smokescreen substatus)
    - *The changes to AIDecide_GustOfWind crash the game ([Link to Bug Fix](https://github.com/Sha0den/poketcg_v2/commit/4602ebf753565eeef9c9d46d8355182c05b531f7))*

<br/>

- **[May 7, 2024](https://github.com/Sha0den/improvedpoketcg/commit/c146befe2ff38d1b0137bb8a4d0a6dc2563a289f):** 9 Files Changed
    - Remove some redundant code

<br/>

- **[May 6, 2024](https://github.com/Sha0den/improvedpoketcg/commit/4da8cb3a494cfec17fbe2de9a57e4c2e3c6924c6):** 9 Files Changed (1 is Bug Fix)
    - Eliminate some home bank tail calls (replacing a call ret with a fallthrough/jr/jp)
    - Replace some conditional jumps to returns with conditional returns (e.g. "ret z" instead of "jr z, .done")
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
    - Replace some conditional jumps to returns with conditional returns (e.g. "ret z" instead of "jr z, .done")
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
    - Eliminate some same bank tail calls (replacing a call ret with a fallthrough/jr/jp)
    - Replace some mistaken farcalls/bank1calls with calls
    - *Relocating some of the home bank functions led to some crashes ([Reversion #1](https://github.com/Sha0den/improvedpoketcg/commit/eb38cd2a5b1b9b91d3c2a83baefe7a5a29917d2f), [Reversion #2](https://github.com/Sha0den/improvedpoketcg/commit/c3e01965877e98d425d696233ba56e8e43fa0a91), [Reversion #3](https://github.com/Sha0den/poketcg_v2/commit/0982afa57559a557f3ddbf6ecabe43151c00f2dd))*

<br/>

- **[April 29, 2024](https://github.com/Sha0den/improvedpoketcg/commit/eb4497ad2cef51dbe3690b09196b2e5046ae7ab7):** 14 Files Changed
    - Remove some redundant lines of code
    - Eliminate some same bank tail calls (replacing a call ret with a fallthrough/jr/jp)
    - Replace some conditional jumps to returns with conditional returns (e.g. "ret z" instead of "jr z, .done")

<br/>

- **[April 15, 2024](https://github.com/Sha0den/improvedpoketcg/commit/1ffe5922e6bcbe14ffd91422067e636788b4ebd2):** 19 Files Changed (Half are Miscellaneous Changes)
    - Massively condense Effect Commands and Effect Functions
 


<br/>
<br/>



## Miscellaneous Changes
- **[August 15, 2024](https://github.com/Sha0den/poketcg_v2/commit/d7050ca9cd207220c60d520d1c2f70f2175eb35c):** 3 Files Changed
    - Make the phantom cards (Venusaur Lv64 and Mew Lv15) obtainable without using Card Pop! by adding them to the list of possible Challenge Cup prizes

<br/>

- **[August 14, 2024](https://github.com/Sha0den/poketcg_v2/commit/576581a7aac4bb8e1da6ab8c1076aabbe927e3fb):** 8 Files Changed
    - Create engine/menus/gift_center.core.asm and move gift center functions in engine/menus/deck_configuration and engine/menu/deck_machine.asm to the new file
    - Organize functions in engine/menus/printer.asm (after importing PrinterMenu_DeckConfiguration)
    - Move and label unrelated menu parameter data from engine/menus/gift_center.asm to engine/menus/labels.asm

<br/>

- **[August 12, 2024](https://github.com/Sha0den/poketcg_v2/commit/3fa4a8c98343049ee5e2505aae7168b8353c1a9f):** 6 Files Changed
    - Pokedex numbers now use 2 bytes to support Pokemon from all generations
    - Although, the printing function will have to be edited if it exceeds 3 digits (1,000+)

<br/>

- **[August 11, 2024](https://github.com/Sha0den/poketcg_v2/commit/133b38fda44d1fee37d11d7ed805e47a3c616221):** 5 Files Changed
    - Move coss toss functions from engine/duel.core.asm to a separate file that's linked with a less important bank
    - Align the printed coin tally numbers

<br/>

- **[August 9, 2024](https://github.com/Sha0den/poketcg_v2/commit/0a96c62b8cb2588b01647e867eef0ce7ceee8721):** 1 File Changed
    - Comment out some unreferenced data in home/sgb.asm

<br/>

- **[August 3, 2024](https://github.com/Sha0den/poketcg_v2/commit/0849ad946e2b0cef4a08988d983e7e3f3516c674):** 1 File Changed
    - Use [Electro's tutorial](https://github.com/pret/poketcg/wiki/Remove-AI-artificial-delay) to remove the artificial delay applied to many of the AI's actions

<br/>

- **[July 23, 2024](https://github.com/Sha0den/poketcg_v2/commit/87cc896a64a7a987321b9fd94c8773aa509a6108):** 1 File Changed
    - Restructure home/math.asm

<br/>

- **[July 14, 2024](https://github.com/Sha0den/poketcg_v2/commit/b070252710fa41169a8ef69c36b2757ec928537e):** 1 File Changed
    - Add some more comments to home/substatus.asm

<br/>

- **[June 26, 2024](https://github.com/Sha0den/poketcg_v2/commit/a05fc6a1988ee931da2ba9e8cef6a197d77f5ef3):** 9 Files Changed
    - Remove some now unreferenced material and put it where it belongs (in debug files)

<br/>

- **[June 20, 2024](https://github.com/Sha0den/poketcg_v2/commit/15bf474bae975ce662a989f5f4410f84b5a7906b):** 3 Files Changed
    - Move debug.asm from engine/menus and debug_player_coordinates.asm from engine/overworld to engine/unused

<br/>

- **[June 19, 2024](https://github.com/Sha0den/poketcg_v2/commit/45a08ab02dd879c4c6cc03672c4c3d7b8cde3957):** 7 Files Changed (Plus 5 Files Relocated)
    - Comment out a few more unreferenced functions in the home bank
    - Move debug_sprites, unused_copyright.asm, and unused_save_validation.asm from engine to engine/unused
    - Move debug_main.asm and unknown.asm from engine/menus to engine/unused

<br/>

- **[June 18, 2024](https://github.com/Sha0den/poketcg_v2/commit/a852ba61fb251f4076828524a41d14d2b2d616cd):** 21 Files Changed (4 of these were removed from the repository)
    - Shuffle some functions in the home bank for better organization
    - Delete the redundant JPHblankCopyDataHLtoDE function
    - Add a missing colon to fix a build error from the commit below this one

<br/>

- **[June 18, 2024](https://github.com/Sha0den/poketcg_v2/commit/f5c84e957054bc2548219821aa6a2ec4d196d3a6):** 5 Files Changed
    - Shuffle some functions in the home bank that are related to printing numbers (and use more accurate labels)

<br/>

- **[June 17, 2024](https://github.com/Sha0den/poketcg_v2/commit/f7b97cccbcd62933c6bd8ade0834cf9aca1fca6f):** 3 Files Changed
    - Reorganize the functions in home/substatus.asm

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
    - Replace all uses of "ld a, [hff__]" in the repository with "ldh a, [hff__]"
    - Alter the number fonts stored in gfx/fonts/full_width?/0_2_digits_kanji1.png

<br/>

- **[June 2, 2024](https://github.com/Sha0den/poketcg_v2/commit/b16b83b296ee35aa3d05b7066ed8c649343e0879):** 16 Files Changed
    - Update the Glossary (both the overall display and the actual text information)
    - Increase the size of the font tile section in vram when viewing the Glossary from a duel
    - Create many new fullwidth and halfwidth font characters, plus 2 new text box symbols
    - Move a lot of texts from text3.asm to text2.asm (Needed more space for Glossary)
    - Move a lot of texts from text2.asm to text1.asm
    - Make some minor adjustments to several of the title menu texts in text3.asm

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
    - Text pointers were later adjusted in [This Commit](https://github.com/Sha0den/poketcg_v2/commit/09f3400366b809053a31210ddc368f6273896608)

<br/>

- **[May 12, 2024](https://github.com/Sha0den/improvedpoketcg/commit/a22046c5fd4ddf967e4ea0793a79abbdf80cc7aa):** 4 Files Changed
    - Add text speed constants and increase the default text speed to the fastest setting

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
    - Change the name of the rom file produced by this repository from poketcg.gbc to poketcg_v2.gbc

<br/>

- **[April 26, 2024](https://github.com/Sha0den/improvedpoketcg/commit/efbd16d2c95ac964c158107d56ffb04af067b3ad):** 1 File Changed
    - Align the list numbers in the top right of the card list header

<br/>

- **[April 16, 2024](https://github.com/Sha0den/improvedpoketcg/commit/31a2cf426dfcccbd4d25b5af3d18a77845a01dc2):** 3 Files Changed
    - Update fullwidth and halfwidth font graphics and some of the box messages
    - Further Adjustments to box_messages.png in [This Commit](https://github.com/Sha0den/improvedpoketcg/commit/673f4965565af76c3ff95c26988b2b024d04e380)

<br/>

- **[April 16, 2024](https://github.com/Sha0den/improvedpoketcg/commit/180ea5c9b6e0965a32b3cdc37b474b8b8a97c8ef):** 1 File Changed
    - Replace the word "Hand" with the hand icon from the duel graphics in the play area screens

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
- **[June 1, 2024](https://github.com/Sha0den/poketcg_v2/commit/3cccfcb07e93fa73d4bc0ab4978a295d98321e4a):** 2 Files Changed
    - Display lowercase halfwidth font characters
    - Increase size of half_width.png to account for future additions

<br/>

- **[May 15, 2024](https://github.com/Sha0den/improvedpoketcg/commit/29c218bf8169f5123b1e3b886217ea76cb506b8f):** 5 Files Changed
    - Add support for common accented characters (halfwidth and fullwidth)
    - Expand the halfwidth font graphics (at the cost of some kanji)
    - *This commit caused a major text display glitch ([Link to Bug Fix](https://github.com/Sha0den/improvedpoketcg/commit/dbe0431ed7e5492ea5fed6cfe99c48872abe4698))*

<br/>

- **[May 14, 2024](https://github.com/Sha0den/improvedpoketcg/commit/b37fdd04d9d228a46be2e27ecf64407bcf1a5302):** 3 Files Changed
    - The practice game with Sam at the start of the game is now optional

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

<br/>

- **[April 15, 2024](https://github.com/Sha0den/improvedpoketcg/commit/669e9b7f0d1b8ec54eb66012354434a5cb7ca7f3):** 1 File Changed
    - Cards can now have weakness or resistance to colorless (Use WR_COLORLESS)



<br/>
<br/>



## Other Bug Fixes And Commit Reversions
- **[August 18, 2024](https://github.com/Sha0den/poketcg_v2/commit/cbfce31cab1e997d446cd57bbed99990fb7ca27a):** 1 File Changed
    - Revert the textpointers because it screws up the printing of some empty texts (plus everything works fine without making any adjustments)
    - *This completely undoes [This Commit](https://github.com/Sha0den/poketcg_v2/commit/fe4c091b38639bc5b52078c9ac153a0eac12ae01)*

<br/>

- **[August 2, 2024](https://github.com/Sha0den/poketcg_v2/commit/af31753844fcabe625eab1a1439ade00567086f9):** 1 File Changed
    - Change a conditional return to a conditional jump to avoid missing a couple of pops
    - *This is a bug fix for [This Commit](https://github.com/Sha0den/poketcg_v2/commit/23905f186bfe79e892321a09135ca051a55c5c18)*

<br/>

- **[June 11, 2024](https://github.com/Sha0den/poketcg_v2/commit/0350841247da35c6b11c79f88f58ca5a1f1050bb):** 1 File Changed
    - Use "farcall" when CheckIfCanEvolveInto_BasicToStage2 is accessed by the AI Logic 2 bank
    - *This is a bug fix for [This Commit](https://github.com/Sha0den/improvedpoketcg/commit/1ffe5922e6bcbe14ffd91422067e636788b4ebd2)*

<br/>

- **[May 27, 2024](https://github.com/Sha0den/poketcg_v2/commit/4602ebf753565eeef9c9d46d8355182c05b531f7):** 1 File Changed
    - Revert a change to AIDecide_GustOfWind that was causing the game to crash
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
    - Put Func_3bb5 back in the home bank
    - *This is a possible bug fix for [This Commit](https://github.com/Sha0den/improvedpoketcg/commit/16f4361737eba3e68d5829d45276c6521bedc7d1)*

<br/>

- **[May 7, 2024](https://github.com/Sha0den/improvedpoketcg/commit/eb38cd2a5b1b9b91d3c2a83baefe7a5a29917d2f):** 4 Files Changed
    - Put AIDoAction functions back in the home bank
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
