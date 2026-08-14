import '../models/ability.dart';
import '../models/battlefield.dart';
import '../models/card.dart';
import '../models/creature_card.dart';
import '../models/instant_card.dart';
import '../models/persistent_card.dart';
import '../models/player.dart';
import 'game_state.dart';

/// Drives a match turn by turn: untap, draw, main-phase actions, and the
/// victory check. There is deliberately no combat phase — creatures never
/// attack each other or a player, so "actions" here are limited to tapping
/// for resource, playing cards, and activating abilities.
class GameEngine {
  final GameState state;
  Player? winner;

  GameEngine(this.state);

  /// Deals each player their opening hand and, if [starterCreature] is
  /// given, puts one copy of it into play for each player untapped. The
  /// sample content pool relies on this: with no card that costs 0, a
  /// player needs a creature already in play to tap for their very first
  /// point of resource.
  void startGame({int startingHandSize = 5, CreatureCard? starterCreature}) {
    for (final p in [state.player1, state.player2]) {
      if (starterCreature != null) {
        p.creatures.add(BattlefieldCreature(starterCreature));
      }
      for (var i = 0; i < startingHandSize; i++) {
        final card = p.drawCard();
        if (card != null) p.hand.add(card);
      }
    }
    state.logEvent('Game start: ${state.player1} vs ${state.player2}');
  }

  /// Untaps [player]'s creatures, except ones still serving out a lock
  /// placed on them by an opponent's ability.
  void untapStep(Player player) {
    for (final creature in player.creatures) {
      if (creature.lockedUntapTurns > 0) {
        creature.lockedUntapTurns--;
      } else {
        creature.tapped = false;
      }
    }
  }

  void drawStep(Player player) {
    final card = player.drawCard();
    if (card != null) {
      player.hand.add(card);
      state.logEvent('$player draws ${card.name}');
    } else {
      state.logEvent('$player has no cards left to draw');
    }
  }

  /// Applies every persistent effect's automatic per-turn resource bonus.
  /// Call once at the start of [player]'s main phase.
  void applyPersistentBonuses(Player player) {
    for (final instance in player.persistents) {
      final bonus = instance.card.autoResourcePerTurn;
      if (bonus > 0) {
        player.resource.add(bonus);
        state.logEvent(
          '$player gains $bonus resource from ${instance.card.name} '
          '(total ${player.resource.amount})',
        );
      }
    }
  }

  /// Taps a creature the base way every creature can: to bank resource.
  bool tapForResource(Player player, BattlefieldCreature creature) {
    if (!player.creatures.contains(creature) || creature.tapped) return false;
    creature.tapped = true;
    player.resource.add(creature.card.resourceValue);
    state.logEvent(
      '$player taps ${creature.card.name} for ${creature.card.resourceValue} '
      'resource (total ${player.resource.amount})',
    );
    return true;
  }

  bool playCreature(Player player, CreatureCard card) {
    if (!_canPlay(player, card)) return false;
    player.resource.spend(card.cost);
    player.hand.remove(card);
    player.creatures.add(BattlefieldCreature(card));
    state.logEvent('$player plays creature ${card.name}');
    return true;
  }

  bool playInstant(
    Player player,
    InstantCard card, {
    BattlefieldCreature? targetCreature,
    Player? targetPlayer,
  }) {
    if (!_canPlay(player, card)) return false;
    player.resource.spend(card.cost);
    player.hand.remove(card);
    state.logEvent('$player casts ${card.name}');
    card.effect(
      state,
      player,
      targetCreature: targetCreature,
      targetPlayer: targetPlayer,
    );
    return true;
  }

  bool playPersistent(Player player, PersistentCard card) {
    if (!_canPlay(player, card)) return false;
    player.resource.spend(card.cost);
    player.hand.remove(card);
    final instance = PersistentEffectInstance(card);
    player.persistents.add(instance);
    state.logEvent('$player plays persistent effect ${card.name}');
    card.onEnter?.call(state, player);
    return true;
  }

  bool activateAbility(
    Player player,
    BattlefieldCreature creature,
    Ability ability, {
    BattlefieldCreature? targetCreature,
    Player? targetPlayer,
  }) {
    if (!player.creatures.contains(creature)) return false;
    if (ability.requiresTap && creature.tapped) return false;
    if (!player.resource.canAfford(ability.cost)) return false;

    if (ability.requiresTap) creature.tapped = true;
    player.resource.spend(ability.cost);
    state.logEvent('$player activates ${ability.name} on ${creature.card.name}');
    ability.effect(
      state,
      player,
      targetCreature: targetCreature,
      targetPlayer: targetPlayer,
    );
    return true;
  }

  bool _canPlay(Player player, Card card) =>
      player.hand.contains(card) && player.resource.canAfford(card.cost);

  /// Checks every victory condition either player chose at deck-build
  /// time. Returns the winner, if any, and also records it on [winner].
  Player? checkVictory() {
    for (final player in [state.player1, state.player2]) {
      for (final condition in player.victoryConditions) {
        if (condition.isSatisfied(state, player)) {
          winner = player;
          state.logEvent('$player wins by fulfilling "${condition.name}"');
          return player;
        }
      }
    }
    return null;
  }

  void endStep(Player player) => checkVictory();

  void passTurn() {
    state.turnNumber++;
    state.activePlayer = state.opponentOf(state.activePlayer);
  }
}
