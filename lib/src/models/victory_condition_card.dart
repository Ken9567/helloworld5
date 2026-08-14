import '../engine/game_state.dart';
import 'card.dart';
import 'player.dart';

/// A victory condition, chosen during deck building rather than drawn
/// during the game. A player wins the instant one of their chosen
/// conditions is satisfied — there is no life total to whittle down.
class VictoryConditionCard extends Card {
  final bool Function(GameState state, Player owner) isSatisfied;

  const VictoryConditionCard({
    required super.id,
    required super.name,
    required this.isSatisfied,
  }) : super(cost: 0, type: CardType.victoryCondition);
}
