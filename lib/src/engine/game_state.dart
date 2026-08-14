import '../models/player.dart';

/// The full state of a match in progress: both players, whose turn it is,
/// and a human-readable log of what has happened so far.
class GameState {
  final Player player1;
  final Player player2;
  int turnNumber = 1;
  late Player activePlayer;
  final List<String> log = [];

  GameState(this.player1, this.player2) {
    activePlayer = player1;
  }

  Player opponentOf(Player p) => p == player1 ? player2 : player1;

  void logEvent(String message) => log.add('[Turn $turnNumber] $message');
}
