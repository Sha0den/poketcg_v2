EffectCommands::
; Each attack has a two-byte effect pointer (attack's 7th param) that points to one of these structures.
; Similarly, Trainer cards have a two-byte pointer (7th param) to one of these structures, which determines the card's function.
; Energy cards also point to one of these, but their data is just $00.
;	db EFFECTCMDTYPE_* ($01 - $0a)
;	dw Function
;	...
;	db $00

; Commands are associated to a time or a scope (EFFECTCMDTYPE_*) that determines when their function is executed during the turn.
; - EFFECTCMDTYPE_INITIAL_EFFECT_1: Executed right after an attack or Trainer card is used. Bypasses effects like Smokescreen.
; - EFFECTCMDTYPE_INITIAL_EFFECT_2: Executed right after an attack, Pokémon Power, or Trainer card is used.
; - EFFECTCMDTYPE_DISCARD_ENERGY: For attacks or Trainer cards that require putting one or more attached Energy cards into the discard pile.
; - EFFECTCMDTYPE_REQUIRE_SELECTION: For attacks, Pokémon Powers, or Trainer cards requiring the user to select a card (e.g. from play area screen or card list).
; - EFFECTCMDTYPE_BEFORE_DAMAGE: Effect command of an attack executed prior to the damage step. For Trainer cards and Pokémon Powers, this is usually the main effect.
; - EFFECTCMDTYPE_AFTER_DAMAGE: Effect command executed after the damage step.
; - EFFECTCMDTYPE_AI_SWITCH_DEFENDING_PKMN: For attacks that may result in the Defending Pokémon being switched out. Called only for AI-executed attacks.
; - EFFECTCMDTYPE_PKMN_POWER_TRIGGER: Pokémon Power effects that trigger the moment the Pokémon card is played.
; - EFFECTCMDTYPE_AI: Used for AI scoring of attacks.
; - EFFECTCMDTYPE_AI_SELECTION: When AI is required to select a card

; Attacks that have an EFFECTCMDTYPE_REQUIRE_SELECTION also must have either an EFFECTCMDTYPE_AI_SWITCH_DEFENDING_PKMN or an
; EFFECTCMDTYPE_AI_SELECTION (for anything not involving switching the Defending Pokémon), to handle selections involving the AI.

; Effect Commands for attacks are listed first, sorted by the type of effect. The overall ordering is:
; 1) Effects related to taking cards out of the deck or discard pile 
; 2) Other effects that benefit the player (excepting substatus effects), this mainly includes switching and healing
; 3) Effects that inflict Special Conditions (Asleep, Confusion, Paralysis, Poison)
; 4) Substatus effects (double damage, damage/attack prevention, Destiny Bond, no Retreat, Conversion, and Headache)
; 5) Other non-damage effects that deal with your opponent's Pokémon
; 6) Damage Modifying Effects
; 7) Effects that harm your own Pokémon (e.g. discarding Energy as a cost, recoil, damage to your Bench, etc.)
; 8) Effects that damage the opponent's Bench
; 9) Miscellaneous random effects
;
; All 26 Pokémon Power effect commands are listed after that, sorted by Pokémon Type
; The Trainer effect commands are found next, sorted alphabetically
; Last are the Energy effects commands


ProphecyEffectCommands:
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_1, BothPlayers_DeckCheck
	dbw EFFECTCMDTYPE_REQUIRE_SELECTION, Prophecy_PlayerSelection
	dbw EFFECTCMDTYPE_AI_SELECTION, Prophecy_AISelection
	dbw EFFECTCMDTYPE_AFTER_DAMAGE, Prophecy_ReorderEffect
	db  $00

FlipToDrawCardEffectCommands:
	dbw EFFECTCMDTYPE_AFTER_DAMAGE, DrawCard50PercentEffect
	db  $00

DrawCardEffectCommands:
	dbw EFFECTCMDTYPE_AFTER_DAMAGE, DrawCardEffect
	db  $00

Draw2EffectCommands:
	dbw EFFECTCMDTYPE_AFTER_DAMAGE, Draw2CardsEffect
	db  $00

AttachBasicEnergyFromDeckEffectCommands:
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_1, DeckCheck
	dbw EFFECTCMDTYPE_REQUIRE_SELECTION, AttachBasicEnergyFromDeck_PlayerSelection
	dbw EFFECTCMDTYPE_AI_SELECTION, AttachBasicEnergyFromDeck_AISelection
	dbw EFFECTCMDTYPE_AFTER_DAMAGE, AttachBasicEnergyFromDeck_AttachEffect
	db  $00

; This is an attack effect that searches for a Trainer card
; and adds it to the player's hand. (a.k.a. Errand-Running)
; Feel free to delete this effect command or modify it into a Trainer effect.
TrainerSearchEffectCommands:
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_1, DeckCheck
	dbw EFFECTCMDTYPE_REQUIRE_SELECTION, TrainerSearch_PlayerSelection
	dbw EFFECTCMDTYPE_AI_SELECTION, TrainerSearch_AISelection
	dbw EFFECTCMDTYPE_AFTER_DAMAGE, AddCardFromDeckToHandEffect
	db  $00

; This is an attack effect that searches for an Evolution card
; and adds it to the player's hand. (a.k.a. Fast Evolution)
; Feel free to delete this effect command or modify it into a Trainer effect.
EvolutionSearchEffectCommands:
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_1, DeckCheck
	dbw EFFECTCMDTYPE_REQUIRE_SELECTION, EvolutionSearch_PlayerSelection
	dbw EFFECTCMDTYPE_AI_SELECTION, EvolutionSearch_AISelection
	dbw EFFECTCMDTYPE_AFTER_DAMAGE, AddCardFromDeckToHandEffect
	db  $00

CallForFamilyEffectCommands:
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_1, CallForF_CheckDeckAndPlayArea
	dbw EFFECTCMDTYPE_REQUIRE_SELECTION, CallForFamily_PlayerSelection
	dbw EFFECTCMDTYPE_AI_SELECTION, CallForFamily_AISelection
	dbw EFFECTCMDTYPE_AFTER_DAMAGE, CallForF_PutInPlayAreaEffect

CallForFightingFriendEffectCommands:
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_1, CallForF_CheckDeckAndPlayArea
	dbw EFFECTCMDTYPE_REQUIRE_SELECTION, CallForFighting_PlayerSelection
	dbw EFFECTCMDTYPE_AI_SELECTION, CallForFighting_AISelection
	dbw EFFECTCMDTYPE_AFTER_DAMAGE, CallForF_PutInPlayAreaEffect
	db  $00

CallForNidoranEffectCommands:
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_1, CallForF_CheckDeckAndPlayArea
	dbw EFFECTCMDTYPE_REQUIRE_SELECTION, CallForNidoran_PlayerSelection
	dbw EFFECTCMDTYPE_AI_SELECTION, CallForNidoran_AISelection
	dbw EFFECTCMDTYPE_AFTER_DAMAGE, CallForF_PutInPlayAreaEffect
	db  $00

CallForOddishEffectCommands:
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_1, CallForF_CheckDeckAndPlayArea
	dbw EFFECTCMDTYPE_REQUIRE_SELECTION, CallForOddish_PlayerSelection
	dbw EFFECTCMDTYPE_AI_SELECTION, CallForOddish_AISelection
	dbw EFFECTCMDTYPE_AFTER_DAMAGE, CallForF_PutInPlayAreaEffect
	db  $00

CallForBellsproutEffectCommands:
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_1, CallForF_CheckDeckAndPlayArea
	dbw EFFECTCMDTYPE_REQUIRE_SELECTION, CallForBellsprout_PlayerSelection
	dbw EFFECTCMDTYPE_AI_SELECTION, CallForBellsprout_AISelection
	dbw EFFECTCMDTYPE_AFTER_DAMAGE, CallForF_PutInPlayAreaEffect
	db  $00

CallForKrabbyEffectCommands:
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_1, CallForF_CheckDeckAndPlayArea
	dbw EFFECTCMDTYPE_REQUIRE_SELECTION, CallForKrabby_PlayerSelection
	dbw EFFECTCMDTYPE_AI_SELECTION, CallForKrabby_AISelection
	dbw EFFECTCMDTYPE_AFTER_DAMAGE, CallForF_PutInPlayAreaEffect
	db  $00

CallForRandomBasic50PercentEffectCommands:
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_1, CallForF_CheckDeckAndPlayArea
	dbw EFFECTCMDTYPE_AFTER_DAMAGE, CallForRandomBasic50PercentEffect
	db  $00

RandomBenchFillEffectCommands:
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_1, EitherPlayArea_BenchSpaceCheck
	dbw EFFECTCMDTYPE_AFTER_DAMAGE, RandomlyFillBothBenchesEffect
	db  $00

ScavengeEffectCommands:
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_1, Scavenge_DiscardPileAndEnergyCheck
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_2, DiscardAttachedPsychicEnergy_PlayerSelection
	dbw EFFECTCMDTYPE_DISCARD_ENERGY, CardDiscardEffect
	dbw EFFECTCMDTYPE_REQUIRE_SELECTION, Scavenge_TrainerPlayerSelection
	dbw EFFECTCMDTYPE_AI_SELECTION, Scavenge_AISelection
	dbw EFFECTCMDTYPE_AFTER_DAMAGE, Scavenge_MoveToHandEffect
	db  $00

EnergyConversionEffectCommands:
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_1, DiscardedEnergyCheck
	dbw EFFECTCMDTYPE_REQUIRE_SELECTION, Choose2EnergyFromDiscardPile_PlayerSelection
	dbw EFFECTCMDTYPE_AI_SELECTION, Choose2EnergyFromDiscardPile_AISelection
	dbw EFFECTCMDTYPE_AFTER_DAMAGE, EnergyConversion_RecoilAndMoveCardsToHand
	db  $00

EnergyAbsorptionEffectCommands:
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_1, DiscardedEnergyCheck
	dbw EFFECTCMDTYPE_REQUIRE_SELECTION, Choose2EnergyFromDiscardPile_PlayerSelection
	dbw EFFECTCMDTYPE_AI_SELECTION, Choose2EnergyFromDiscardPile_AISelection
	dbw EFFECTCMDTYPE_AFTER_DAMAGE, EnergyAbsorption_AttachEffect
	db  $00

SwitchAfterAttackEffectCommands:
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_1, BenchedPokemonCheck
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_2, SwitchAfterAttack_PlayerSelection
	dbw EFFECTCMDTYPE_AI_SELECTION, SwitchAfterAttack_AISelection
	dbw EFFECTCMDTYPE_AFTER_DAMAGE, SwitchAfterAttack_SwitchEffect
	db  $00

AlsoSwitchAfterAttackEffectCommands:
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_2, AlsoSwitchAfterAttack_PlayerSelection
	dbw EFFECTCMDTYPE_AI_SELECTION, SwitchAfterAttack_AISelection
	dbw EFFECTCMDTYPE_AFTER_DAMAGE, SwitchAfterAttack_SwitchEffect
	db  $00

RandomlySwitchBothActiveEffectCommands:
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, GaleAnimationEffect
	dbw EFFECTCMDTYPE_AFTER_DAMAGE, RandomlySwitchBothActivePokemon
	db  $00

FlipToHeal10EffectCommands:
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_1, ActivePokemon_DamageCheck
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, Healing50Percent_FlipEffect
	dbw EFFECTCMDTYPE_AFTER_DAMAGE, Healing50Percent_Heal10Effect
	db  $00

Heal10EffectCommands:
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_1, ActivePokemon_DamageCheck
	dbw EFFECTCMDTYPE_AFTER_DAMAGE, Heal10_HealEffect
	db  $00

Drain10EffectCommands:
	dbw EFFECTCMDTYPE_AFTER_DAMAGE, Drain10Effect
	db  $00

DrainHalfEffectCommands:
	dbw EFFECTCMDTYPE_AFTER_DAMAGE, DrainHalfEffect
	db  $00

DrainAllEffectCommands:
	dbw EFFECTCMDTYPE_AFTER_DAMAGE, DrainAllEffect
	db  $00

WaterRecoverEffectCommands:
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_1, WaterRecover_EnergyAndHPCheck
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_2, DiscardAttachedWaterEnergy_PlayerSelection
	dbw EFFECTCMDTYPE_AI_SELECTION, DiscardAttachedWaterEnergy_AISelection
	dbw EFFECTCMDTYPE_DISCARD_ENERGY, CardDiscardEffect
	dbw EFFECTCMDTYPE_AFTER_DAMAGE, Recover_HealEffect
	db  $00

PsychicRecoverEffectCommands:
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_1, PsychicRecover_EnergyAndHPCheck
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_2, DiscardAttachedPsychicEnergy_PlayerSelection
	dbw EFFECTCMDTYPE_AI_SELECTION, DiscardAttachedPsychicEnergy_AISelection
	dbw EFFECTCMDTYPE_DISCARD_ENERGY, CardDiscardEffect
	dbw EFFECTCMDTYPE_AFTER_DAMAGE, Recover_HealEffect
	db  $00

FlipToInflictSleepNoDamageEffectCommands:
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, Sleep50PercentWithoutDamageEffect
	db  $00

FlipToInflictSleepEffectCommands:
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, Sleep50PercentEffect
	db  $00

InflictSleepEffectCommands:
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, SleepEffect
	db  $00

DreamEaterEffectCommands:
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_1, DefendingPokemon_SleepCheck
	db  $00

FlipToInflictConfusionNoDamageEffectCommands:
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, Confusion50PercentWithoutDamageEffect
	db  $00

FlipToInflictConfusionEffectCommands:
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, Confusion50PercentEffect
	db  $00

InflictConfusionEffectCommands:
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, ConfusionEffect
	db  $00

BothActiveAreConfusedEffectCommands:
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, ConfuseBothActivePokemonEffect
	db  $00

FlipToInflictParalysisEffectCommands:
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, Paralysis50PercentEffect
	db  $00

ClampEffectCommands:
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, AllOrNothingParalysisEffect
	db  $00

FlipToInflictPoisonEffectCommands:
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, Poison50PercentEffect
	dbw EFFECTCMDTYPE_AI, MayInflictPoison_AIEffect
	db  $00

SpitPoisonEffectCommands:
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, SpitPoison_Poison50PercentEffect
	dbw EFFECTCMDTYPE_AI, MayInflictPoison_AIEffect
	db  $00

InflictPoisonEffectCommands:
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, PoisonEffect
	dbw EFFECTCMDTYPE_AI, InflictPoison_AIEffect
	db  $00

ToxicEffectCommands:
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, DoublePoisonEffect
	dbw EFFECTCMDTYPE_AI, Toxic_AIEffect
	db  $00

FlipToInflictPoisonOrConfusionEffectCommands:
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, PoisonOrConfusionEffect
	dbw EFFECTCMDTYPE_AI, InflictPoison_AIEffect
	db  $00

FlipToInflictPoisonAndConfusionEffectCommands:
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, PoisonConfusion50PercentEffect
	dbw EFFECTCMDTYPE_AI, MayInflictPoison_AIEffect
	db  $00

ScytherSwordsDanceEffectCommands:
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, SwordsDanceEffect
	db  $00

VaporeonFocusEnergyEffectCommands:
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, FocusEnergyEffect
	db  $00

MewtwoBarrierEffectCommands:
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_1, ActivePokemon_PsychicEnergyCheck
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_2, DiscardAttachedPsychicEnergy_PlayerSelection
	dbw EFFECTCMDTYPE_AI_SELECTION, DiscardAttachedPsychicEnergy_AISelection
	dbw EFFECTCMDTYPE_DISCARD_ENERGY, CardDiscardEffect
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, ImmunityEffect
	db  $00

AgilityEffectCommands:
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, Immunity50PercentEffect
	db  $00

FlyEffectCommands:
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, AllOrNothingImmunityEffect
	dbw EFFECTCMDTYPE_AI, FlipFor30_AIEffect
	db  $00

FlipToPreventAllDamageEffectCommands:
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, DamageProtection50PercentEffect
	db  $00

HardenEffectCommands:
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, HardenEffect
	db  $00

Prevent10DamageEffectCommands:
	dbw EFFECTCMDTYPE_AFTER_DAMAGE, Prevent10DamageEffect
	db  $00

Prevent20DamageEffectCommands:
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, Prevent20DamageEffect
	db  $00

HalveDamageEffectCommands:
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, HalveDamageEffect
	db  $00

DestinyBondEffectCommands:
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_1, ActivePokemon_PsychicEnergyCheck
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_2, DiscardAttachedPsychicEnergy_PlayerSelection
	dbw EFFECTCMDTYPE_AI_SELECTION, DiscardAttachedPsychicEnergy_AISelection
	dbw EFFECTCMDTYPE_DISCARD_ENERGY, CardDiscardEffect
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, DestinyBondEffect
	db  $00

CannotAttackEffectCommands:
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, CannotAttack50PercentEffect
	db  $00

FlipToPreventAttackingThisPokemonEffectCommands:
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, CannotAttackThis50PercentEffect
	db  $00

SmokescreenEffectCommands:
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, SmokescreenEffect
	db  $00

AmnesiaEffectCommands:
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_1, DefendingPokemon_AttackCheck
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_2, Amnesia_PlayerSelection
	dbw EFFECTCMDTYPE_AI_SELECTION, Amnesia_AISelection
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, AttackDisableEffect
	db  $00

ReduceBy10EffectCommands:
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, ReduceBy10Effect
	db  $00

ReduceBy20EffectCommands:
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, ReduceBy20Effect
	db  $00

FlipToPreventRetreatEffectCommands:
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, NoRetreat50PercentEffect
	db  $00

PreventRetreatEffectCommands:
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, NoRetreatEffect
	db  $00

Conversion1EffectCommands:
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_1, Conversion1_WeaknessCheck
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_2, Conversion1_PlayerSelection
	dbw EFFECTCMDTYPE_AI_SELECTION, Conversion1_AISelection
	dbw EFFECTCMDTYPE_AFTER_DAMAGE, Conversion1_ChangeWeaknessEffect
	db  $00

Conversion2EffectCommands:
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_1, Conversion2_ResistanceCheck
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_2, Conversion2_PlayerSelection
	dbw EFFECTCMDTYPE_AI_SELECTION, Conversion2_AISelection
	dbw EFFECTCMDTYPE_AFTER_DAMAGE, Conversion2_ChangeResistanceEffect
	db  $00

PreventTrainersNextTurnEffectCommands:
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, PreventTrainersEffect
	db  $00

DiscardEnergyDefendingPokemonEffectCommands:
	dbw EFFECTCMDTYPE_REQUIRE_SELECTION, DiscardEnergyDefendingPokemon_PlayerSelection
	dbw EFFECTCMDTYPE_AI_SELECTION, DiscardEnergyDefendingPokemon_AISelection
	dbw EFFECTCMDTYPE_AFTER_DAMAGE, DefendingPokemonEnergy_DiscardEffect
	db  $00

FlipToMakeOpponentSwitchActiveEffectCommands:
	dbw EFFECTCMDTYPE_REQUIRE_SELECTION, OpponentSwitchesActive50Percent_SelectEffect
	dbw EFFECTCMDTYPE_AI_SWITCH_DEFENDING_PKMN, OpponentSwitchesActive50Percent_SelectEffect
	dbw EFFECTCMDTYPE_AFTER_DAMAGE, OpponentSwitchesActive_SwitchEffect
	db  $00

OpponentSwitchesActiveAnd20DamageToSelfEffectCommands:
	dbw EFFECTCMDTYPE_REQUIRE_SELECTION, OpponentSwitchesActive_BenchCheck
	dbw EFFECTCMDTYPE_AI_SWITCH_DEFENDING_PKMN, OpponentSwitchesActive_BenchCheck
	dbw EFFECTCMDTYPE_AFTER_DAMAGE, Recoil20OpponentSwitchesActiveEffect
	db  $00

OpponentSwitchesActiveEffectCommands:
	dbw EFFECTCMDTYPE_REQUIRE_SELECTION, OpponentSwitchesActive_BenchCheck
	dbw EFFECTCMDTYPE_AI_SWITCH_DEFENDING_PKMN, OpponentSwitchesActive_BenchCheck
	dbw EFFECTCMDTYPE_AFTER_DAMAGE, OpponentSwitchesActive_SwitchEffect
	db  $00

SwitchDefendingPokemonEffectCommands:
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_1, Opponent_BenchedPokemonCheck
	dbw EFFECTCMDTYPE_REQUIRE_SELECTION, SwitchDefendingPokemon_PlayerSelection
	dbw EFFECTCMDTYPE_AI_SELECTION, ChooseWeakestBenchedPokemon_AISelection
	dbw EFFECTCMDTYPE_AFTER_DAMAGE, SwitchDefendingPokemon_SwitchEffect
	db  $00

DevolutionBeamEffectCommands:
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_1, EitherPlayArea_EvolvedPokemonCheck
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_2, DevolutionBeam_PlayerSelection
	dbw EFFECTCMDTYPE_AI_SELECTION, DevolutionBeam_AISelection
;	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, DevolutionBeam_LoadAnimation
	dbw EFFECTCMDTYPE_AFTER_DAMAGE, DevolutionBeam_DevolveEffect
	db  $00

ReturnDefendingPokemonToTheHandEffectCommands:
	dbw EFFECTCMDTYPE_AFTER_DAMAGE, ReturnDefendingPokemonToTheHandEffect
	db  $00

DamageUnaffectedByWeaknessOrResistanceEffectCommands:
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, NoColorEffect
	dbw EFFECTCMDTYPE_AFTER_DAMAGE, NullEffect
	dbw EFFECTCMDTYPE_AI, NoColorEffect
	db  $00

SuperFangEffectCommands:
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, HalveHPOfDefendingPokemon
	dbw EFFECTCMDTYPE_AI, HalveHPOfDefendingPokemon
	db  $00

KarateChopEffectCommands:
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, KarateChop_DamageSubtractionEffect
	dbw EFFECTCMDTYPE_AI, KarateChop_DamageSubtractionEffect
	db  $00

FlailEffectCommands:
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, Flail_HPCheck
	dbw EFFECTCMDTYPE_AI, Flail_HPCheck
	db  $00

RageEffectCommands:
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, Rage_DamageBoostEffect
	dbw EFFECTCMDTYPE_AI, Rage_DamageBoostEffect
	db  $00

RageAndFlipForSelfConfusionEffectCommands:
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, RageAndSelfConfusion50PercentEffect
	dbw EFFECTCMDTYPE_AI, Rage_DamageBoostEffect
	db  $00

FlipForSelfConfusionEffectCommands:
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, SelfConfusion_50PercentEffect
	db  $00

MeditateEffectCommands:
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, CompoundingDamageCounters_DamageBoostEffect
	dbw EFFECTCMDTYPE_AI, CompoundingDamageCounters_DamageBoostEffect
	db  $00

PsywaveEffectCommands:
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, DefendingPokemonEnergy_10xDamageEffect
	dbw EFFECTCMDTYPE_AI, DefendingPokemonEnergy_10xDamageEffect
	db  $00

PsychicEffectCommands:
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, DefendingPokemonEnergy_10MoreDamageEffect
	dbw EFFECTCMDTYPE_AI, DefendingPokemonEnergy_10MoreDamageEffect
	db  $00

WWaterGunEffectCommands:
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, WWaterGunEffect
	dbw EFFECTCMDTYPE_AI, WWaterGunEffect
	db  $00

WCWaterGunEffectCommands:
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, WCWaterGunEffect
	dbw EFFECTCMDTYPE_AI, WCWaterGunEffect
	db  $00

WWCWaterGunEffectCommands:
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, WWCWaterGunEffect
	dbw EFFECTCMDTYPE_AI, WWCWaterGunEffect
	db  $00

WWWHydroPumpEffectCommands:
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, WWWHydroPumpEffect
	dbw EFFECTCMDTYPE_AI, WWWHydroPumpEffect
	db  $00

EachBenched10MoreDamageEffectCommands:
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, EachBenched10MoreDamageEffect
	dbw EFFECTCMDTYPE_AI, EachBenched10MoreDamageEffect
	db  $00

EachNidoking20MoreDamageEffectCommands:
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, EachNidoking20MoreDamageEffect
	dbw EFFECTCMDTYPE_AI, EachNidoking20MoreDamageEffect
	db  $00

LeekSlapEffectCommands:
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_1, LeekSlap_OncePerDuelCheck
	dbw EFFECTCMDTYPE_DISCARD_ENERGY, LeekSlap_SetUsedThisDuelFlag
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, NoDamage50PercentEffect
	dbw EFFECTCMDTYPE_AI, FlipFor30_AIEffect
	db  $00

FlipFor30EffectCommands:
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, NoDamage50PercentEffect
	dbw EFFECTCMDTYPE_AI, FlipFor30_AIEffect
	db  $00

FlipFor70EffectCommands:
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, NoDamage50PercentEffect
	dbw EFFECTCMDTYPE_AI, FlipFor70_AIEffect
	db  $00

FlipFor80EffectCommands:
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, NoDamage50PercentEffect
	dbw EFFECTCMDTYPE_AI, FlipFor80_AIEffect
	db  $00

Flip2For10EffectCommands:
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, Flip2For10_MultiplierEffect
	dbw EFFECTCMDTYPE_AI, FlipFor20_AIEffect
	db  $00

Flip3For10EffectCommands:
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, Flip3For10_MultiplierEffect
	dbw EFFECTCMDTYPE_AI, FlipFor30_AIEffect
	db  $00

Flip8For10EffectCommands:
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, Flip8For10_MultiplierEffect
	dbw EFFECTCMDTYPE_AI, FlipFor80_AIEffect
	db  $00

FlipXFor10EffectCommands:
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, FlipXFor10_MultiplierEffect
	dbw EFFECTCMDTYPE_AI, FlipXFor10_AIEffect
	db  $00

Flip2For20EffectCommands:
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, Flip2For20_MultiplierEffect
	dbw EFFECTCMDTYPE_AI, FlipFor40_AIEffect
	db  $00

Flip3For20EffectCommands:
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, Flip3For20_MultiplierEffect
	dbw EFFECTCMDTYPE_AI, FlipFor60_AIEffect
	db  $00

Flip4For20EffectCommands:
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, Flip4For20_MultiplierEffect
	dbw EFFECTCMDTYPE_AI, FlipFor80_AIEffect
	db  $00

BigEggsplosionEffectCommands:
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, FlipEachEnergyFor20_MultiplierEffect
	dbw EFFECTCMDTYPE_AI, FlipEachEnergyFor20_AIEffect
	db  $00

Flip2For30EffectCommands:
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, Flip2For30_MultiplierEffect
	dbw EFFECTCMDTYPE_AI, FlipFor60_AIEffect
	db  $00

Flip2For40EffectCommands:
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, Flip2For40_MultiplierEffect
	dbw EFFECTCMDTYPE_AI, FlipFor80_AIEffect
	db  $00

Flip3For40SelfConfusionEffectCommands:
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, Flip3For40SelfConfusion_MultiplierEffect
	dbw EFFECTCMDTYPE_AI, FlipFor120_AIEffect
	db  $00

FlipForPlus10Base20EffectCommands:
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, FlipForPlus10_DamageBoostEffect
	dbw EFFECTCMDTYPE_AI, Plus10From20_AIEffect
	db  $00

FlipForPlus20Base10EffectCommands:
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, FlipForPlus20_DamageBoostEffect
	dbw EFFECTCMDTYPE_AI, Plus20From10_AIEffect
	db  $00

FlipForPlus10Or10DamageToSelfEffectCommands:
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, Plus10OrRecoil_ModifierEffect
	dbw EFFECTCMDTYPE_AFTER_DAMAGE, Plus10OrRecoil_RecoilEffect
	dbw EFFECTCMDTYPE_AI, Plus10OrRecoil_AIEffect
	db  $00

FlipFor10DamageToSelfEffectCommands:
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, Recoil10_50PercentEffect
	dbw EFFECTCMDTYPE_AFTER_DAMAGE, Recoil10_RecoilEffect
	db  $00

FlipFor30DamageToSelfEffectCommands:
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, FlipToRecoil30_50PercentEffect
	dbw EFFECTCMDTYPE_AFTER_DAMAGE, FlipToRecoil30_RecoilEffect
	db  $00

Also20DamageToSelfEffectCommands:
	dbw EFFECTCMDTYPE_AFTER_DAMAGE, Recoil20Effect
	db  $00

Also30DamageToSelfEffectCommands:
	dbw EFFECTCMDTYPE_AFTER_DAMAGE, Recoil30Effect
	db  $00

Also80DamageToSelfEffectCommands:
	dbw EFFECTCMDTYPE_AFTER_DAMAGE, Recoil80Effect
	db  $00

DiscardAttachedFireEnergyEffectCommands:
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_1, ActivePokemon_FireEnergyCheck
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_2, DiscardAttachedFireEnergy_PlayerSelection
	dbw EFFECTCMDTYPE_AI_SELECTION, DiscardAttachedFireEnergy_AISelection
	dbw EFFECTCMDTYPE_DISCARD_ENERGY, CardDiscardEffect
	db  $00

WildfireEffectCommands:
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_1, ActivePokemon_FireEnergyCheck
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_2, DiscardXAttachedFireEnergy_PlayerSelection
	dbw EFFECTCMDTYPE_AI_SELECTION, DiscardXAttachedFireEnergy_AISelection
	dbw EFFECTCMDTYPE_DISCARD_ENERGY, DiscardXAttachedFireEnergy_DiscardEffect
	dbw EFFECTCMDTYPE_AFTER_DAMAGE, OpponentDeck_DiscardXCardsEffect
	db  $00

FlamesOfRageEffectCommands:
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_1, ActivePokemon_DoubleFireEnergyCheck
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_2, Discard2AttachedFireEnergy_PlayerSelection
	dbw EFFECTCMDTYPE_AI_SELECTION, Discard2AttachedFireEnergy_AISelection
	dbw EFFECTCMDTYPE_DISCARD_ENERGY, Discard2AttachedEnergyCards_DiscardEffect
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, Rage_DamageBoostEffect
	dbw EFFECTCMDTYPE_AI, Rage_DamageBoostEffect
	db  $00

Discard2AttachedEnergyCardsEffectCommands:
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_1, ActivePokemon_2EnergyCardsCheck
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_2, Discard2AttachedEnergyCards_PlayerSelection
	dbw EFFECTCMDTYPE_AI_SELECTION, Discard2AttachedEnergyCards_AISelection
	dbw EFFECTCMDTYPE_DISCARD_ENERGY, Discard2AttachedEnergyCards_DiscardEffect
	db  $00

DiscardAllAttachedEnergyEffectCommands:
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, DiscardAllAttachedEnergyEffect
	db  $00

EarthquakeEffectCommands:
	dbw EFFECTCMDTYPE_AFTER_DAMAGE, OwnBench_10DamageEffect
	db  $00

BlizzardEffectCommands:
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, DamageEitherBench_50PercentEffect
	dbw EFFECTCMDTYPE_AFTER_DAMAGE, DamageEitherBench_10DamageEffect
	db  $00

Selfdestruct40And10EffectCommands:
	dbw EFFECTCMDTYPE_AFTER_DAMAGE, Selfdestruct40Effect
	db  $00

Selfdestruct60And10EffectCommands:
	dbw EFFECTCMDTYPE_AFTER_DAMAGE, Selfdestruct60Effect
	db  $00

Selfdestruct80And20EffectCommands:
	dbw EFFECTCMDTYPE_AFTER_DAMAGE, Explosion80DamageEffect
	db  $00

Selfdestruct100And20EffectCommands:
	dbw EFFECTCMDTYPE_AFTER_DAMAGE, Explosion100DamageEffect
	db  $00

Also10DamageTo1BenchedEffectCommands:
	dbw EFFECTCMDTYPE_REQUIRE_SELECTION, AlsoDamageTo1Benched_PlayerSelection
	dbw EFFECTCMDTYPE_AI_SELECTION, AlsoChooseWeakestBenchedPokemon_AISelection
	dbw EFFECTCMDTYPE_AFTER_DAMAGE, Also10DamageTo1Benched_DamageEffect
	db  $00

Also10DamageTo3BenchedEffectCommands:
	dbw EFFECTCMDTYPE_REQUIRE_SELECTION, AlsoDamageTo3Benched_PlayerSelection
	dbw EFFECTCMDTYPE_AI_SELECTION, AlsoDamageTo3Benched_AISelection
	dbw EFFECTCMDTYPE_AFTER_DAMAGE, AlsoDamageTo3Benched_10DamageEffect
	db  $00

ChainLightningEffectCommands:
	dbw EFFECTCMDTYPE_AFTER_DAMAGE, Also10DamageToSameColorOnBenchEffect
	db  $00

ThunderstormEffectCommands:
	dbw EFFECTCMDTYPE_AFTER_DAMAGE, ThunderstormEffect
	db  $00

Benched20DamageEffectCommands:
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_1, Opponent_BenchedPokemonCheck
	dbw EFFECTCMDTYPE_REQUIRE_SELECTION, DamageTo1Benched_PlayerSelection
	dbw EFFECTCMDTYPE_AI_SELECTION, ChooseWeakestBenchedPokemon_AISelection
	dbw EFFECTCMDTYPE_AFTER_DAMAGE, DamageTo1Benched_20DamageEffect
	db  $00

RandomEnemy20DamageEffectCommands:
	dbw EFFECTCMDTYPE_AFTER_DAMAGE, RandomEnemy20DamageEffect
	db  $00

RandomEnemy30DamageEffectCommands:
	dbw EFFECTCMDTYPE_AFTER_DAMAGE, RandomEnemy30DamageEffect
	db  $00

RandomEnemy40DamageEffectCommands:
	dbw EFFECTCMDTYPE_AFTER_DAMAGE, RandomEnemy40DamageEffect
	db  $00

Random70DamageEffectCommands:
	dbw EFFECTCMDTYPE_AFTER_DAMAGE, Random70DamageEffect
	db  $00

MysteryAttackEffectCommands:
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, MysteryAttack_RandomEffect
	dbw EFFECTCMDTYPE_AFTER_DAMAGE, MysteryAttack_RecoverEffect
	dbw EFFECTCMDTYPE_AI, FlipFor20_AIEffect
	db  $00

MixUpEffectCommands:
	dbw EFFECTCMDTYPE_AFTER_DAMAGE, OpponentHand_ReplacePokemonInEffect
	db  $00

MagneticStormEffectCommands:
	dbw EFFECTCMDTYPE_AFTER_DAMAGE, ShuffleAttachedEnergyEffect
	db  $00

DittoMorphEffectCommands:
	dbw EFFECTCMDTYPE_AFTER_DAMAGE, MorphEffect
	db  $00

ClefairyMetronomeEffectCommands:
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_1, DefendingPokemon_AttackCheck
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_2, ClefairyMetronome_UseAttackEffect
	dbw EFFECTCMDTYPE_AI_SELECTION, Metronome_AISelection
	db  $00

ClefableMetronomeEffectCommands:
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_1, DefendingPokemon_AttackCheck
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_2, ClefableMetronome_UseAttackEffect
	dbw EFFECTCMDTYPE_AI_SELECTION, Metronome_AISelection
	db  $00

MirrorMoveEffectCommands:
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_1, MirrorMove_AttackedCheck
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_2, MirrorMove_AmnesiaCheck
	dbw EFFECTCMDTYPE_REQUIRE_SELECTION, MirrorMove_PlayerSelection
	dbw EFFECTCMDTYPE_AI_SELECTION, MirrorMove_AISelection
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, MirrorMove_BeforeDamage
	dbw EFFECTCMDTYPE_AFTER_DAMAGE, MirrorMove_AfterDamage
	dbw EFFECTCMDTYPE_AI, MirrorMove_AIEffect
	db  $00


;--------------------------------------------------------------------------------------------------------------
; POKEMON POWER EFFECT COMMANDS START HERE.
; Only 14/26 Pokémon Powers have an actual effect function. (passive powers are handled elsewhere)
; Pokémon Powers generally only use EFFECTCMDTYPE_INITIAL_EFFECT_2, EFFECTCMDTYPE_PKMN_POWER_TRIGGER,
; 	EFFECTCMDTYPE_REQUIRE_SELECTION (Player only), EFFECTCMDTYPE_BEFORE_DAMAGE,
; 	and EFFECTCMDTYPE_AFTER_DAMAGE (AI only)
; AI decisions are handled in engine/duel/ai/pkmn_powers.asm (rather than an EFFECTCMDTYPE_AI_SELECTION).
;--------------------------------------------------------------------------------------------------------------

; also handled in engine/duel/ai/pkmn_powers.asm
VenusaurEnergyTransEffectCommands:
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_2, EnergyTransCheck
	dbw EFFECTCMDTYPE_REQUIRE_SELECTION, EnergyTrans_PrintProcedureText
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, EnergyTrans_TransferEffect
	dbw EFFECTCMDTYPE_AFTER_DAMAGE, EnergyTrans_AIEffect
	db  $00

; also handled in engine/duel/ai/pkmn_powers.asm
VenusaurSolarPowerEffectCommands:
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_2, SolarPowerCheck
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, SolarPower_RemoveStatusEffect
	db  $00

; also handled in engine/duel/ai/pkmn_powers.asm
VileplumeHealEffectCommands:
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_2, HealCheck
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, Heal_RemoveDamageEffect
	db  $00

; also handled in home/card_color.asm and engine/duel/ai/pkmn_powers.asm
VenomothShiftEffectCommands:
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_2, OncePerTurnPokePowerCheck
	dbw EFFECTCMDTYPE_REQUIRE_SELECTION, Shift_PlayerSelection
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, Shift_ChangeColorEffect
	db  $00

; actual effect handled in home/substatus.asm, engine/duel/core.asm, and in other Pokémon Power effects
MukToxicGasEffectCommands:
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_1, SetCarryEF ; passive pokemon power
	db  $00

; actual effect handled in home/card_color.asm and various functions that check attached Energy
CharizardEnergyBurnEffectCommands:
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_1, SetCarryEF ; passive pokemon power
	db  $00

MoltresFiregiverEffectCommands:
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_1, SetCarryEF ; passive pokemon power
	dbw EFFECTCMDTYPE_PKMN_POWER_TRIGGER, Firegiver_AddToHandEffect
	db  $00

; actual effect handled in engine/duel/core.asm and engine/duel/ai/pkmn_powers.asm
BlastoiseRainDanceEffectCommands:
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_1, SetCarryEF ; passive pokemon power
	db  $00

; also handled in engine/duel/ai/pkmn_powers.asm
TentacoolCowardiceEffectCommands:
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_2, CowardiceCheck
	dbw EFFECTCMDTYPE_REQUIRE_SELECTION, PossibleSwitch_PlayerSelection
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, Cowardice_RemoveFromPlayAreaEffect
	db  $00

; actual effect handled in engine/duel/core.asm, engine/menus/duel.asm,
; engine/menus/play_area.asm, and home/substatus.asm
OmanyteClairvoyanceEffectCommands:
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_1, SetCarryEF ; passive pokemon power
	db  $00

ArticunoQuickfreezeEffectCommands:
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_1, SetCarryEF ; passive pokemon power
	dbw EFFECTCMDTYPE_PKMN_POWER_TRIGGER, Quickfreeze_Paralysis50PercentEffect
	db  $00

ZapdosPealOfThunderEffectCommands:
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_1, SetCarryEF ; passive pokemon power
	dbw EFFECTCMDTYPE_PKMN_POWER_TRIGGER, PealOfThunder_RandomlyDamageEffect
	db  $00

; also handled in engine/duel/ai/pkmn_powers.asm
MankeyPeekEffectCommands:
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_2, OncePerTurnPokePowerCheck
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, Peek_SelectEffect
	db  $00

; actual effect handled in engine/duel/core.asm & home/duel.asm
MachampStrikesBackEffectCommands:
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_1, SetCarryEF ; passive pokemon power
	db  $00

; actual effect handled in home/substatus.asm
KabutoKabutoArmorEffectCommands:
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_1, SetCarryEF ; passive pokemon power
	db  $00

; actual effect handled in home/substatus.asm and in any function that deals with evolution
AerodactylPrehistoricPowerEffectCommands:
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_1, SetCarryEF ; passive pokemon power
	db  $00

; also handled in engine/duel/ai/pkmn_powers.asm
AlakazamDamageSwapEffectCommands:
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_2, DamageSwapCheck
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, DamageSwap_SelectAndSwapEffect
	dbw EFFECTCMDTYPE_AFTER_DAMAGE, DamageSwap_SwapEffect
	db  $00

; also handled in engine/duel/ai/pkmn_powers.asm
SlowbroStrangeBehaviorEffectCommands:
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_2, StrangeBehaviorCheck
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, StrangeBehavior_SelectAndSwapEffect
	dbw EFFECTCMDTYPE_AFTER_DAMAGE, StrangeBehavior_SwapEffect
	db  $00

; actual effect handled in home/substatus.asm and engine/duel/effect_functions.asm
HaunterTransparencyEffectCommands:
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_1, SetCarryEF ; passive pokemon power
	db  $00

; also handled in engine/duel/ai/pkmn_powers.asm
GengarCurseEffectCommands:
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_2, CurseCheck
	dbw EFFECTCMDTYPE_REQUIRE_SELECTION, Curse_PlayerSelection
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, Curse_TransferDamageEffect
	db  $00

; actual effect handled in home/substatus.asm
MrMimeInvisibleWallEffectCommands:
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_1, SetCarryEF ; passive pokemon power
	db  $00

; actual effect handled in home/substatus.asm and engine/duel/effect_functions.asm
MewNeutralizingShieldEffectCommands:
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_1, SetCarryEF ; passive pokemon power
	db  $00

; actual effect handled in home/duel.asm
DodrioRetreatAidEffectCommands:
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_1, SetCarryEF ; passive pokemon power
	db  $00

; actual effect handled in the effect functions that cause special conditions
SnorlaxThickSkinnedEffectCommands:
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_1, SetCarryEF ; passive pokemon power
	db  $00

; also handled in engine/duel/ai/pkmn_powers.asm
DragoniteStepInEffectCommands:
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_2, StepInCheck
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, StepIn_SwitchEffect
	db  $00

DragoniteHealingWindEffectCommands:
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_1, SetCarryEF ; passive pokemon power
	dbw EFFECTCMDTYPE_PKMN_POWER_TRIGGER, HealingWind_PlayAreaHealEffect
	db  $00


;--------------------------------------------------------------------------------------------------------------
; TRAINER CARD EFFECT COMMANDS START HERE.
; Trainer cards only use EFFECTCMDTYPE_INITIAL_EFFECT_1, EFFECTCMDTYPE_INITIAL_EFFECT_2 (Player only),
; EFFECTCMDTYPE_DISCARD_ENERGY, EFFECTCMDTYPE_REQUIRE_SELECTION (Player only), and EFFECTCMDTYPE_BEFORE_DAMAGE.
; AI decisions are handled in engine/duel/ai/trainer/cards.asm (rather than an EFFECTCMDTYPE_AI_SELECTION).
;--------------------------------------------------------------------------------------------------------------

PlayThisAsBasicPokemonEffectCommands:
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_1, BenchSpaceCheck
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, PlayThisAsBasicPokemonEffect
	db  $00

; special card data for Trainer Pokémon is stored in engine/duel/effect_functions2.asm
DiscardTrainerPokemonEffectCommands:
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_2, TrainerCardAsPokemon_BenchCheck
	dbw EFFECTCMDTYPE_REQUIRE_SELECTION, PossibleSwitch_PlayerSelection
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, TrainerCardAsPokemon_DiscardEffect
	db  $00

BillEffectCommands:
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, Draw2CardsEffect
	db  $00

ComputerSearchEffectCommands:
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_1, ComputerSearchCheck
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_2, Discard2Cards_PlayerSelection
	dbw EFFECTCMDTYPE_REQUIRE_SELECTION, ComputerSearch_PlayerDeckSelection
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, ComputerSearch_DiscardAddToHandEffect
	db  $00

DefenderEffectCommands:
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_2, Defender_PlayerSelection
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, Defender_AttachDefenderEffect
	db  $00

DevolutionSprayEffectCommands:
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_1, YourPlayArea_EvolvedPokemonCheck
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_2, DevolutionSpray_PlayerSelection
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, DevolutionSpray_DevolutionEffect
	db  $00

EnergyRemovalEffectCommands:
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_1, EnergyRemovalCheck
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_2, EnergyRemoval_PlayerSelection
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, EnergyRemoval_DiscardEffect
	db  $00

EnergyRetrievalEffectCommands:
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_1, EnergyRetrievalCheck
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_2, EnergyRetrieval_PlayerHandSelection
	dbw EFFECTCMDTYPE_REQUIRE_SELECTION, EnergyRetrieval_PlayerDiscardPileSelection
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, EnergyRetrieval_DiscardAndAddToHandEffect
	db  $00

EnergySearchEffectCommands:
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_1, DeckCheck
	dbw EFFECTCMDTYPE_REQUIRE_SELECTION, EnergySearch_PlayerSelection
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, AddCardFromDeckToHandEffect
	db  $00

FullHealEffectCommands:
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_1, ActivePokemon_StatusCheck
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, RemoveSpecialConditionsEffect
	db  $00

GamblerEffectCommands:
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, GamblerEffect
	db  $00

GustOfWindEffectCommands:
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_1, Opponent_BenchedPokemonCheck
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_2, GustOfWind_PlayerSelection
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, GustOfWind_SwitchEffect
	db  $00

ImakuniEffectCommands:
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, ImakuniEffect
	db  $00

ImposterProfessorOakEffectCommands:
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, ImposterProfessorOakEffect
	db  $00

ItemFinderEffectCommands:
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_1, ItemFinderCheck
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_2, ItemFinder_PlayerSelection
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, ItemFinder_DiscardAddToHandEffect
	db  $00

LassEffectCommands:
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, LassEffect
	db  $00

MaintenanceEffectCommands:
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_1, OtherCardsInHandCheck
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_2, Maintenance_PlayerSelection
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, Maintenance_ReturnToDeckAndDrawEffect
	db  $00

MrFujiEffectCommands:
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_1, BenchedPokemonCheck
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_2, MrFuji_PlayerSelection
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, MrFuji_ReturnToDeckEffect
	db  $00

PlusPowerEffectCommands:
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, PlusPowerEffect
	db  $00

PokeBallEffectCommands:
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_1, DeckCheck
	dbw EFFECTCMDTYPE_REQUIRE_SELECTION, PokeBall_PlayerSelection
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, AddCardFromDeckToHandEffect
	db  $00

PokedexEffectCommands:
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_1, DeckCheck
	dbw EFFECTCMDTYPE_REQUIRE_SELECTION, Pokedex_PlayerSelection
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, Pokedex_ReorderEffect
	db  $00

PokemonBreederEffectCommands:
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_1, PokemonBreederCheck
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_2, PokemonBreeder_PlayerSelection
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, PokemonBreeder_EvolveEffect
	db  $00

PokemonCenterEffectCommands:
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_1, YourPokemon_DamageCheck
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, PokemonCenter_HealDiscardEnergyEffect
	db  $00

PokemonFluteEffectCommands:
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_1, PokemonFluteCheck
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_2, PokemonFlute_PlayerSelection
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, PokemonFlute_PlaceInPlayAreaText
	db  $00

PokemonTraderEffectCommands:
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_1, PokemonTraderCheck
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_2, PokemonTrader_PlayerHandSelection
	dbw EFFECTCMDTYPE_REQUIRE_SELECTION, PokemonTrader_PlayerDeckSelection
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, PokemonTrader_TradeCardsEffect
	db  $00

PotionEffectCommands:
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_1, YourPokemon_DamageCheck
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_2, MayChoosePokemonToHeal_PlayerSelection
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, Heal20FromChosenPokemonEffect
	db  $00

ProfessorOakEffectCommands:
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, ProfessorOakEffect
	db  $00

RecycleEffectCommands:
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_1, DiscardPileCheck
	dbw EFFECTCMDTYPE_REQUIRE_SELECTION, Recycle_PlayerSelection
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, Recycle_AddToHandEffect
	db  $00

ReviveEffectCommands:
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_1, ReviveCheck
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_2, Revive_PlayerSelection
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, Revive_PlaceInPlayAreaEffect
	db  $00

ScoopUpEffectCommands:
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_1, BenchedPokemonCheck
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_2, ScoopUp_PlayerSelection
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, ScoopUp_ReturnToHandEffect
	db  $00

SuperEnergyRemovalEffectCommands:
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_1, SuperEnergyRemoval_EnergyCheck
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_2, SuperEnergyRemoval_PlayerSelection
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, SuperEnergyRemoval_DiscardEffect
	db  $00

SuperEnergyRetrievalEffectCommands:
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_1, SuperEnergyRetrieval_HandEnergyCheck
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_2, Discard2Cards_PlayerSelection
	dbw EFFECTCMDTYPE_REQUIRE_SELECTION, SuperEnergyRetrieval_PlayerDiscardPileSelection
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, SuperEnergyRetrieval_DiscardAndAddToHandEffect
	db  $00

SuperPotionEffectCommands:
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_1, SuperPotion_DamageEnergyCheck
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_2, SuperPotion_PlayerSelection
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, SuperPotion_HealEffect
	db  $00

SwitchEffectCommands:
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_1, BenchedPokemonCheck
	dbw EFFECTCMDTYPE_INITIAL_EFFECT_2, Switch_PlayerSelection
	dbw EFFECTCMDTYPE_BEFORE_DAMAGE, SwitchEffect
	db  $00


;--------------------------------------------------------------------------------------------------------------
; ENERGY CARD EFFECT COMMANDS START HERE.
; The actual effects for providing Energy are scattered throughout the duel engine.
;--------------------------------------------------------------------------------------------------------------

GrassEnergyEffectCommands:
	db  $00

FireEnergyEffectCommands:
	db  $00

WaterEnergyEffectCommands:
	db  $00

LightningEnergyEffectCommands:
	db  $00

FightingEnergyEffectCommands:
	db  $00

PsychicEnergyEffectCommands:
	db  $00

DoubleColorlessEnergyEffectCommands:
	db  $00
