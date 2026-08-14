# Card Game

An original trading card game in the spirit of Magic: The Gathering, with a
deliberately different core loop:

- **No dedicated resource cards.** Every creature can be tapped to bank
  resource, so creatures double as your mana base.
- **Resource is banked, not reset.** Untapped resource carries over between
  turns instead of emptying, so you can save up for expensive cards.
- **No life total, no attack step.** Creatures never fight each other or a
  player directly.
- **No simple removal.** Players interact through abilities and instant
  effects (locking a creature, draining resource, etc.), not
  "destroy target creature."
- **Victory conditions are chosen at deck-build time.** Instead of reducing
  an opponent's life to zero, each deck picks victory condition cards up
  front, and the game ends the moment one is fulfilled.

This repository currently holds the **core rule engine and a simple CPU
opponent**, written in Dart so the same code can later power a Flutter
mobile app without a rewrite. There is no UI yet.

## Project layout

```
lib/
  card_game.dart          barrel file exporting the public API
  src/models/              Card, CreatureCard, InstantCard, PersistentCard,
                            VictoryConditionCard, ResourcePool, Player,
                            battlefield state, abilities
  src/engine/               GameState + GameEngine (turn flow, actions,
                            victory checks)
  src/ai/                   a minimal rule-based CPU opponent
  src/content/               a small sample card pool used by the demo/tests
bin/demo.dart               CLI demo: runs a full CPU-vs-CPU match and
                            prints the turn log
test/                       unit tests covering the engine and a full match
```

## Getting started

Requires the [Dart SDK](https://dart.dev/get-dart) (no Flutter needed yet,
since there is no UI).

```
dart pub get
dart test
dart run bin/demo.dart
```

## Design notes

- A creature's "tap for resource" ability is universal and lives in the
  engine (`GameEngine.tapForResource`), not on individual cards, matching
  the design decision that every creature is part of the resource base.
- Because nothing else costs 0, each player is granted one free "Seedling"
  creature at game start (`GameEngine.startGame(starterCreature: ...)`) so
  there's a way to tap for the very first point of resource.
- Interaction is expressed as `Ability` / instant-card effects that read and
  mutate `GameState`, e.g. locking a creature from untapping for a turn
  (`Tide Binder`) or draining banked resource (`Energy Drain`) — see
  `lib/src/content/sample_cards.dart` for the full sample set.
