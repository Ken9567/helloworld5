import 'creature_card.dart';
import 'persistent_card.dart';

/// A creature card's live state once it is on the battlefield: whether it
/// is tapped, and whether an effect has locked it from untapping.
class BattlefieldCreature {
  final CreatureCard card;
  bool tapped = false;

  /// Number of the owner's future untap steps this creature will skip.
  /// Set by interaction effects (e.g. a "stun" ability) instead of a
  /// removal spell.
  int lockedUntapTurns = 0;

  BattlefieldCreature(this.card);

  @override
  String toString() => '${card.name}${tapped ? " (tapped)" : ""}';
}

/// A persistent (enchantment-like) card's live state once it is in play.
class PersistentEffectInstance {
  final PersistentCard card;

  PersistentEffectInstance(this.card);

  @override
  String toString() => card.name;
}
