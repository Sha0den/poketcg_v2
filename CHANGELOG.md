Improved Pokémon Trading Card Game (a.k.a. poketcg_v2)
======================================================

## Bug Fixes For Base Game

- **[May 6, 2024](https://github.com/Sha0den/improvedpoketcg/commit/4da8cb3a494cfec17fbe2de9a57e4c2e3c6924c6):** 9 Files Changed (8 are Code Optimization)
    - Fix "Ninetails" typo

<br/>

- **[April 15, 2024](https://github.com/Sha0den/improvedpoketcg/commit/2a907f7c823e298803449fb872d10db0aff2d1d6):** 1 File Changed
    - Fix the AI not checking the Unable_Retreat substatus before retreating

<br/>

- **[April 15, 2024](https://github.com/Sha0den/improvedpoketcg/commit/05c13dd163f6c073fbcb7c455d05b762beec6a8d):** 24 Files Changed
    - Fix the AI repeating the Active Pokémon score bonus when attaching an Energy card
    - Fix designated cards not being set aside when the AI places Prize cards
    - Apply the AI score modifiers for retreating
    - Fix a flaw in AI's Professor Oak logic
    - Fix Rick never playing Energy Search
    - Fix Rick using the wrong Pokédex AI subroutine
    - Fix Chris never using Revive on Kangaskhan
    - Fix a flaw in the AI's Pokemon Trader logic for the PowerGenerator deck
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
    - Comment out many unreferenced functionsin the home bank
    - Remove src/home/ai.asm and src/home/damage.asm and unlink them from src/home.asm
    - Transfer some functions out of the home banks
    - Eliminate some same bank tail calls (replacing a call ret with a fallthrough/jr/jp)
    - Replace some mistaken farcalls/bank1calls with calls

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

- **[April 17, 2024](https://github.com/Sha0den/improvedpoketcg/commit/673f4965565af76c3ff95c26988b2b024d04e380):** 1 File Changed
    - Further Adjustments to box_messages.png

<br/>

- **[April 16, 2024](https://github.com/Sha0den/improvedpoketcg/commit/31a2cf426dfcccbd4d25b5af3d18a77845a01dc2):** 3 Files Changed
    - Update fullwidth and halfwidth font graphics and some of the box messages

<br/>

- **[April 15, 2024](https://github.com/Sha0den/improvedpoketcg/commit/ae0ee380fe2c32211f527c5a6d395c6484121a49)** 1 File Changed
    - Replace damage counter display with "current HP/max HP", allowing HP values to be as high as 250HP

<br/>

- **[April 15, 2024](https://github.com/Sha0den/improvedpoketcg/commit/1ffe5922e6bcbe14ffd91422067e636788b4ebd2):** 19 Files Changed (Half are Code Optimization)
    - Remove rom matching comparison, move card data to its own bank, add an extra bank for Text and Effect Functions, and update a wide variety of duel texts
 


<br/>
<br/>



## New Features
- **May 14, 2024:** 3 Files Changed
    - The practice game with Sam at the start of the game is now optional

<br/>

- **[May 10, 2024](https://github.com/Sha0den/improvedpoketcg/commit/13c38116fc85504d9e05b68de8133275213f6173):** 1 File Changed
    - Add a scroll arrow to a Trainer or Pokémon attack card page when the description is continued on another page

<br/>

- **[April 16, 2024](https://github.com/Sha0den/improvedpoketcg/commit/0679b2ca09c04106dcc7e8e80bd6ea02d0f14e4d):** 4 Files Changed
    - Display the Promostar symbol on card pages

<br/>

- **[April 16, 2024](https://github.com/Sha0den/improvedpoketcg/commit/180ea5c9b6e0965a32b3cdc37b474b8b8a97c8ef):** 1 File Changed
    - Replace the word "Hand" with the hand icon from the duel graphics in the play area screens

<br/>

- **[April 15, 2024](https://github.com/Sha0den/improvedpoketcg/commit/669e9b7f0d1b8ec54eb66012354434a5cb7ca7f3):** 1 File Changed
    - Cards can now have weakness or resistance to colorless (Use WR_COLORLESS)



<br/>
<br/>



## Other Bug Fixes And Commit Reversions
- **[May 8, 2024](https://github.com/Sha0den/improvedpoketcg/commit/c3e01965877e98d425d696233ba56e8e43fa0a91):** 2 Files Changed
    - Put Func_3bb5 back in the home bank

<br/>

- **[May 7, 2024](https://github.com/Sha0den/improvedpoketcg/commit/eb38cd2a5b1b9b91d3c2a83baefe7a5a29917d2f):** 4 Files Changed
    - Put AIDoAction functions back in the home bank

<br/>

- **[May 7, 2024](https://github.com/Sha0den/improvedpoketcg/commit/519e8348ae85be540ad4af4bb1b087ae72f02d13):** 4 Files Changed
    - Revert some set carry flag optimizations in the AI Logic 1 bank

<br/>

- **[April 15, 2024](https://github.com/Sha0den/improvedpoketcg/commit/e55f2176d099949e2baf95f4efba4b01121705ac):** 8 Files Changed
    - Fix some text display issues caused by the first commit



<br/>
<br/>



## Potential Hacks
- **[May 14, 2024](https://github.com/Sha0den/improvedpoketcg/commit/62a73e33e60c8e5b61d477bb1b9f0f675def074c):** Only Need to Change 1 File
    - Instructions for skipping the mandatory practice duel with Sam
