import 'package:card_game/card_game.dart';
import 'package:test/test.dart';

Player _bareplayer(String name, {List<Card> deck = const []}) => Player(
      name: name,
      deck: deck,
      victoryConditions: const [],
    );

void main() {
  group('ResourcePool', () {
    test('banks resource instead of resetting', () {
      final pool = ResourcePool();
      pool.add(2);
      pool.spend(1);
      expect(pool.amount, 1);
      pool.add(3);
      expect(pool.amount, 4);
    });

    test('spend throws when insufficient', () {
      final pool = ResourcePool();
      pool.add(1);
      expect(() => pool.spend(2), throwsStateError);
    });
  });

  group('GameEngine turn flow', () {
    late Player p1;
    late Player p2;
    late GameState state;
    late GameEngine engine;

    setUp(() {
      p1 = _bareplayer('P1');
      p2 = _bareplayer('P2');
      state = GameState(p1, p2);
      engine = GameEngine(state);
    });

    test('tapping a creature for resource banks it across turns', () {
      final creature = BattlefieldCreature(sprout());
      p1.creatures.add(creature);

      expect(engine.tapForResource(p1, creature), isTrue);
      expect(creature.tapped, isTrue);
      expect(p1.resource.amount, 1);

      // Tapping again before untapping does nothing.
      expect(engine.tapForResource(p1, creature), isFalse);
      expect(p1.resource.amount, 1);

      engine.untapStep(p1);
      expect(creature.tapped, isFalse);
      // Resource persists across the untap step (banked, not reset).
      expect(p1.resource.amount, 1);

      expect(engine.tapForResource(p1, creature), isTrue);
      expect(p1.resource.amount, 2);
    });

    test('playing a creature spends resource and enters the battlefield', () {
      p1.resource.add(1);
      final card = sprout();
      p1.hand.add(card);

      expect(engine.playCreature(p1, card), isTrue);
      expect(p1.resource.amount, 0);
      expect(p1.hand, isEmpty);
      expect(p1.creatures, hasLength(1));
      expect(p1.creatures.single.card, same(card));
    });

    test('cannot play a card that is unaffordable', () {
      final card = oldOak(); // costs 3
      p1.hand.add(card);

      expect(engine.playCreature(p1, card), isFalse);
      expect(p1.hand, contains(card));
      expect(p1.creatures, isEmpty);
    });

    test('energy drain moves resource from target to caster', () {
      p2.resource.add(2);
      final drain = energyDrain();
      p1.resource.add(2);
      p1.hand.add(drain);

      expect(
        engine.playInstant(p1, drain, targetPlayer: p2),
        isTrue,
      );
      expect(p1.resource.amount, 2); // spent 2 to cast, gained 2 back
      expect(p2.resource.amount, 0);
    });

    test('tap-lock ability keeps target tapped through its next untap', () {
      final locker = BattlefieldCreature(tideBinder());
      final target = BattlefieldCreature(sprout());
      p1.creatures.add(locker);
      p2.creatures.add(target);
      p1.resource.add(1);

      final ability = locker.card.abilities.single;
      expect(
        engine.activateAbility(p1, locker, ability, targetCreature: target),
        isTrue,
      );
      expect(target.tapped, isTrue);
      expect(target.lockedUntapTurns, 1);

      engine.untapStep(p2);
      expect(target.tapped, isTrue, reason: 'still locked for one more untap');
      expect(target.lockedUntapTurns, 0);

      engine.untapStep(p2);
      expect(target.tapped, isFalse);
    });

    test('persistent auto resource bonus applies once per main phase', () {
      final ley = leyLine();
      p1.persistents.add(PersistentEffectInstance(ley));

      engine.applyPersistentBonuses(p1);
      expect(p1.resource.amount, 1);

      engine.applyPersistentBonuses(p1);
      expect(p1.resource.amount, 2);
    });

    test('victory condition ends the game for the player who meets it', () {
      final vcPlayer = Player(
        name: 'Winner',
        deck: const [],
        victoryConditions: [reservoirFull()],
      );
      final other = Player(name: 'Other', deck: const [], victoryConditions: const []);
      final vState = GameState(vcPlayer, other);
      final vEngine = GameEngine(vState);

      expect(vEngine.checkVictory(), isNull);

      vcPlayer.resource.add(12);
      expect(vEngine.checkVictory(), same(vcPlayer));
      expect(vEngine.winner, same(vcPlayer));
    });
  });

  group('CpuPlayer', () {
    test('a full CPU-vs-CPU match terminates with a winner', () {
      final p1 = Player(
        name: 'Alice',
        deck: buildSampleDeck(),
        victoryConditions: buildSampleVictoryConditions(),
      );
      final p2 = Player(
        name: 'Bob',
        deck: buildSampleDeck(),
        victoryConditions: buildSampleVictoryConditions(),
      );
      final state = GameState(p1, p2);
      final engine = GameEngine(state);
      engine.startGame(starterCreature: seedling());

      const maxTurns = 80;
      while (engine.winner == null && state.turnNumber <= maxTurns) {
        final active = state.activePlayer;
        engine.untapStep(active);
        engine.drawStep(active);
        engine.applyPersistentBonuses(active);
        CpuPlayer(active, engine).takeTurn();
        engine.endStep(active);
        if (engine.winner != null) break;
        engine.passTurn();
      }

      expect(engine.winner, isNotNull,
          reason: 'sample decks should be able to reach a victory condition '
              'within $maxTurns turns');
    });
  });
}
