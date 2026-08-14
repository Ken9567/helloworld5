/// A player's banked resource. Unlike mana in most trading card games,
/// this pool does *not* empty at end of turn: creatures tap to add to it
/// over time, so players can save up across several turns for an
/// expensive card.
class ResourcePool {
  int _amount = 0;

  int get amount => _amount;

  void add(int value) {
    if (value < 0) throw ArgumentError.value(value, 'value', 'must be >= 0');
    _amount += value;
  }

  bool canAfford(int cost) => _amount >= cost;

  void spend(int cost) {
    if (!canAfford(cost)) {
      throw StateError('Not enough resource: have $_amount, need $cost');
    }
    _amount -= cost;
  }
}
