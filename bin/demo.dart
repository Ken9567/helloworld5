import 'package:card_game/card_game.dart';

/// Runs a full CPU-vs-CPU match on the sample card pool and prints the
/// turn-by-turn log, so the engine can be exercised without any UI yet.
void main() {
  const maxTurns = 60;

  final player1 = Player(
    name: 'Alice',
    deck: buildSampleDeck(),
    victoryConditions: buildSampleVictoryConditions(),
  );
  final player2 = Player(
    name: 'Bob',
    deck: buildSampleDeck(),
    victoryConditions: buildSampleVictoryConditions(),
  );

  final state = GameState(player1, player2);
  final engine = GameEngine(state);
  engine.startGame(starterCreature: seedling());

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

  for (final line in state.log) {
    print(line);
  }

  print('---');
  if (engine.winner != null) {
    print('Winner: ${engine.winner}');
  } else {
    print('No winner after $maxTurns turns.');
  }
}
