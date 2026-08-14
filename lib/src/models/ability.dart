import '../engine/game_state.dart';
import 'battlefield.dart';
import 'player.dart';

/// Signature shared by every effect in the game: instant cards, activated
/// abilities, and anything else that reaches out and changes game state.
///
/// [owner] is whoever controls the effect. [targetCreature] / [targetPlayer]
/// are resolved by the caller (a human choice or the CPU's own logic)
/// before the effect runs.
typedef CardEffect = void Function(
  GameState state,
  Player owner, {
  BattlefieldCreature? targetCreature,
  Player? targetPlayer,
});

/// An activated ability a creature carries in addition to its built-in
/// "tap for resource" action. Interaction in this game happens through
/// abilities like this one rather than through simple removal spells.
class Ability {
  final String name;
  final String description;
  final int cost;
  final bool requiresTap;
  final CardEffect effect;

  const Ability({
    required this.name,
    required this.description,
    this.cost = 0,
    this.requiresTap = true,
    required this.effect,
  });

  @override
  String toString() => name;
}
