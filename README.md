# Pokémon Trading Card Game, Version 2

This is a modified disassembly of Pokémon Trading Card Game for the Game Boy Color. It was originally designed to be used as a base for future romhacks, but it can also be used as an improvement hack for people looking to replay the original game. A lot of the changes deal with more efficient code and better function comments and are therefore not likely to be noticed by prospective players, but there are plenty of other differences that are much easier to see. All displayed text is now mixed case instead of uppercase only, and the in-game keyboard was significantly expanded to offer more variety when naming both the protagonist and custom decks. Players can choose to play as either Mark or Mint, like in the sequel. The tutorial at the start of the game is now optional. Various text throughout the game was edited to better fit the 2-line display in the textboxes, and some of the menu screens were redesigned; the glossary in particular is almost entirely different from its original incarnation. It's also worth noting that numerous glitches present in the base game were fixed. For a full overview of the changes that were made to the original game, see [**CHANGELOG.md**](CHANGELOG.md). However, seeing as a picture is worth a thousand words, here are a few side by side comparisons between the original game and poketcg_v2.

![Starting a New Game](https://i.imgur.com/dwp4Xjp.png) ![Deck Building](https://i.imgur.com/GkRZwuQ.png) ![Glossary](https://i.imgur.com/8vzOY4Z.png)



<br/>

## Building the rom file
To assemble, first download RGBDS (https://github.com/gbdev/rgbds/releases) and extract it to /usr/local/bin.
Run `make` in your shell. This will output a file named "poketcg_v2.gbc".

For more detailed instructions about how to set up the repository, see [**INSTALL.md**](INSTALL.md).



<br/>

## See also:
- [Discord server for PokeTCG Hacking]
- [Discord server for pret]
- [Hacking Tutorials]
- [Unaltered Disassembly]

[Discord server for PokeTCG Hacking]: https://discord.gg/K2kfTx2xRf
[Discord server for pret]: https://discord.gg/d5dubZ3
[Hacking Tutorials]: https://github.com/pret/poketcg/wiki/Tutorials
[Unaltered Disassembly]: https://github.com/pret/poketcg
