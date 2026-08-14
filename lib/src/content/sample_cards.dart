import '../engine/game_state.dart';
import '../models/ability.dart';
import '../models/battlefield.dart';
import '../models/card.dart';
import '../models/creature_card.dart';
import '../models/instant_card.dart';
import '../models/persistent_card.dart';
import '../models/player.dart';
import '../models/victory_condition_card.dart';

/// A small hand-written card pool used by the demo CLI and the tests to
/// exercise every card type and the interaction system. Not meant to be
/// a balanced or complete card set.

final tideBinderStun = Ability(
  name: 'Tide Lock',
  description:
      "Tap target opponent creature; it won't untap for its controller's "
      'next untap step.',
  cost: 1,
  requiresTap: true,
  effect: (state, owner, {targetCreature, targetPlayer}) {
    if (targetCreature == null) return;
    targetCreature.tapped = true;
    targetCreature.lockedUntapTurns += 1;
    state.logEvent(
      '${targetCreature.card.name} is locked and will not untap next turn',
    );
  },
);

/// A free starting creature granted to each player before the opening
/// hand is dealt (see [GameEngine.startGame]). Without it nobody could
/// ever tap for their first point of resource, since every other
/// creature in the sample pool has to be paid for out of the pool it
/// would itself help fill.
CreatureCard seedling() => const CreatureCard(
      id: 'seedling',
      name: 'Seedling',
      cost: 0,
      resourceValue: 1,
    );

CreatureCard sprout() => const CreatureCard(
      id: 'sprout',
      name: 'Sprout',
      cost: 1,
      resourceValue: 1,
    );

CreatureCard oldOak() => const CreatureCard(
      id: 'old-oak',
      name: 'Old Oak',
      cost: 3,
      resourceValue: 2,
    );

CreatureCard tideBinder() => CreatureCard(
      id: 'tide-binder',
      name: 'Tide Binder',
      cost: 2,
      resourceValue: 1,
      abilities: [tideBinderStun],
    );

InstantCard energyDrain() => const InstantCard(
      id: 'energy-drain',
      name: 'Energy Drain',
      cost: 2,
      effect: _energyDrainEffect,
    );

void _energyDrainEffect(
  GameState state,
  Player owner, {
  BattlefieldCreature? targetCreature,
  Player? targetPlayer,
}) {
  if (targetPlayer == null) return;
  final amount =
      targetPlayer.resource.amount < 2 ? targetPlayer.resource.amount : 2;
  if (amount <= 0) return;
  targetPlayer.resource.spend(amount);
  owner.resource.add(amount);
  state.logEvent(
    '${owner.name} drains $amount resource from ${targetPlayer.name}',
  );
}

PersistentCard leyLine() => const PersistentCard(
      id: 'ley-line',
      name: 'Ley Line',
      cost: 2,
      autoResourcePerTurn: 1,
    );

VictoryConditionCard grandBloom() => VictoryConditionCard(
      id: 'grand-bloom',
      name: 'Grand Bloom',
      isSatisfied: (state, owner) => owner.creatures.length >= 4,
    );

VictoryConditionCard reservoirFull() => VictoryConditionCard(
      id: 'reservoir-full',
      name: 'Reservoir Full',
      isSatisfied: (state, owner) => owner.resource.amount >= 12,
    );

/// Builds a themed deck: enough creatures to run the resource engine, a
/// couple of interaction/economy spells, and no victory conditions mixed
/// into the draw pile (those are chosen separately at deck-build time).
List<Card> buildSampleDeck() => [
      for (var i = 0; i < 6; i++) sprout(),
      for (var i = 0; i < 3; i++) oldOak(),
      for (var i = 0; i < 3; i++) tideBinder(),
      for (var i = 0; i < 2; i++) energyDrain(),
      for (var i = 0; i < 2; i++) leyLine(),
    ];

List<VictoryConditionCard> buildSampleVictoryConditions() => [
      grandBloom(),
      reservoirFull(),
    ];
