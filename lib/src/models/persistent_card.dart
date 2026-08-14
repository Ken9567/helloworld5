import '../engine/game_state.dart';
import 'card.dart';
import 'player.dart';

/// An enchantment-like card: once played it stays on the battlefield and
/// keeps affecting the game until something removes it.
class PersistentCard extends Card {
  /// Runs once, the moment the card enters play.
  final void Function(GameState state, Player owner)? onEnter;

  /// Runs once, if something ever removes the card from play.
  final void Function(GameState state, Player owner)? onLeave;

  /// If set, the engine adds this much resource to the owner's pool at the
  /// start of every one of the owner's main phases while the card is in
  /// play (an ongoing economy effect, e.g. a passive resource generator).
  final int autoResourcePerTurn;

  const PersistentCard({
    required super.id,
    required super.name,
    required super.cost,
    this.onEnter,
    this.onLeave,
    this.autoResourcePerTurn = 0,
  }) : super(type: CardType.persistent);
}
