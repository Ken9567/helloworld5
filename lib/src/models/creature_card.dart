import 'ability.dart';
import 'card.dart';

/// A creature card. Every creature can be tapped for [resourceValue]
/// resource — that ability is universal and lives in the game engine, not
/// here — and may additionally carry activated [abilities] such as
/// interaction effects.
class CreatureCard extends Card {
  final int resourceValue;
  final List<Ability> abilities;

  const CreatureCard({
    required super.id,
    required super.name,
    required super.cost,
    this.resourceValue = 1,
    this.abilities = const [],
  }) : super(type: CardType.creature);
}
