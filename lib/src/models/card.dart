/// The four kinds of card in the game.
///
/// There is deliberately no "attack"-oriented type: creatures exist to be
/// tapped for resource or to carry abilities, not to fight each other.
enum CardType { creature, instant, persistent, victoryCondition }

/// Common definition shared by every card. Concrete card kinds
/// ([CreatureCard], [InstantCard], [PersistentCard], [VictoryConditionCard])
/// extend this with the data specific to how they behave in play.
abstract class Card {
  final String id;
  final String name;
  final int cost;
  final CardType type;

  const Card({
    required this.id,
    required this.name,
    required this.cost,
    required this.type,
  });

  @override
  String toString() => name;
}
