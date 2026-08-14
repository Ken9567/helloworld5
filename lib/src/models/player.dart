import 'dart:math';

import 'battlefield.dart';
import 'card.dart';
import 'resource_pool.dart';
import 'victory_condition_card.dart';

/// One participant in a game: their draw pile, hand, battlefield, banked
/// resource, and the victory conditions they chose at deck-build time.
class Player {
  final String name;
  final ResourcePool resource = ResourcePool();
  final List<Card> deck;
  final List<Card> hand = [];
  final List<BattlefieldCreature> creatures = [];
  final List<PersistentEffectInstance> persistents = [];
  final List<VictoryConditionCard> victoryConditions;

  Player({
    required this.name,
    required List<Card> deck,
    required this.victoryConditions,
    Random? random,
  }) : deck = List.of(deck)..shuffle(random ?? Random());

  Card? drawCard() => deck.isEmpty ? null : deck.removeAt(0);

  @override
  String toString() => name;
}
