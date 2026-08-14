import '../engine/game_engine.dart';
import '../models/card.dart';
import '../models/creature_card.dart';
import '../models/instant_card.dart';
import '../models/persistent_card.dart';
import '../models/player.dart';

/// A minimal rule-based opponent: bank resource greedily, then spend it
/// on the biggest affordable cards first. Good enough to exercise the
/// engine end-to-end; not meant to be strong play.
class CpuPlayer {
  final Player player;
  final GameEngine engine;

  CpuPlayer(this.player, this.engine);

  void takeTurn() {
    _tapAllForResource();
    _spendResourceGreedily();
  }

  void _tapAllForResource() {
    for (final creature in List.of(player.creatures)) {
      if (!creature.tapped) {
        engine.tapForResource(player, creature);
      }
    }
  }

  void _spendResourceGreedily() {
    var playedSomething = true;
    while (playedSomething) {
      playedSomething = false;

      final affordable = player.hand
          .where((card) => player.resource.canAfford(card.cost))
          .toList()
        ..sort((a, b) => b.cost.compareTo(a.cost));

      for (final card in affordable) {
        if (_tryPlay(card)) {
          playedSomething = true;
          break;
        }
      }
    }
  }

  bool _tryPlay(Card card) {
    if (card is CreatureCard) {
      return engine.playCreature(player, card);
    }
    if (card is InstantCard) {
      final opponent = engine.state.opponentOf(player);
      return engine.playInstant(player, card, targetPlayer: opponent);
    }
    if (card is PersistentCard) {
      return engine.playPersistent(player, card);
    }
    return false;
  }
}
