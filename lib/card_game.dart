/// Core rule engine for an original MTG-like trading card game: no life
/// points, no attack step, creatures double as the resource base, and
/// each deck wins by fulfilling the victory condition cards chosen at
/// deck-build time.
library;

export 'src/ai/cpu_player.dart';
export 'src/content/sample_cards.dart';
export 'src/engine/game_engine.dart';
export 'src/engine/game_state.dart';
export 'src/models/ability.dart';
export 'src/models/battlefield.dart';
export 'src/models/card.dart';
export 'src/models/creature_card.dart';
export 'src/models/instant_card.dart';
export 'src/models/persistent_card.dart';
export 'src/models/player.dart';
export 'src/models/resource_pool.dart';
export 'src/models/victory_condition_card.dart';
