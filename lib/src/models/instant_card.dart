import 'ability.dart';
import 'card.dart';

/// A one-shot effect card, resolved immediately when played and then
/// discarded. Used for the interaction the game does offer: taking a
/// resource, locking a creature, disrupting progress — never a plain
/// "destroy target creature" removal.
class InstantCard extends Card {
  final CardEffect effect;

  const InstantCard({
    required super.id,
    required super.name,
    required super.cost,
    required this.effect,
  }) : super(type: CardType.instant);
}
