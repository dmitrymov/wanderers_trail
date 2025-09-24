import 'dart:math';

import 'package:flame/cache.dart';
import 'package:flame/components.dart';
import 'package:flame/sprite.dart';

import '../state/game_state.dart';
import 'difficulty.dart';

class EnemySpriteLoader {
  EnemySpriteLoader(this.gs, {Random? rng}) : _rng = rng ?? Random();

  final GameState gs;
  final Random _rng;

  // Deterministic: pick the variant by difficulty index (0..)
  Future<Sprite> loadByDifficulty({
    required String enemyKey, // e.g., 'bandit'
    required Difficulty difficulty,
  }) async {
    // Clamp desired index against available variants.
    final variants = gs.enemyVariantPaths(enemyKey);
    if (variants.isEmpty) {
      // Fallback to flat path
      final path = 'assets/images/enemies/${enemyKey.toLowerCase()}.png';
      return Sprite.load(path);
    }
    final idx = difficulty.maxVariantIndex.clamp(0, variants.length - 1);
    final path = variants[idx];
    return Sprite.load(path);
  }

  // Random within difficulty: easy picks among [0], normal among [0..1], hard among [0..2],
  // bounded by actual variant count.
  Future<Sprite> loadRandomWithinDifficulty({
    required String enemyKey,
    required Difficulty difficulty,
  }) async {
    final variants = gs.enemyVariantPaths(enemyKey);
    if (variants.isEmpty) {
      final path = 'assets/images/enemies/${enemyKey.toLowerCase()}.png';
      return Sprite.load(path);
    }
    final maxIdx = min(difficulty.maxVariantIndex, variants.length - 1);
    final idx = _rng.nextInt(maxIdx + 1); // 0..maxIdx inclusive
    return Sprite.load(variants[idx]);
  }

  // Optional convenience to preload all variants for a given enemy key.
  Future<void> preloadAllVariants(String enemyKey, Images images) async {
    final variants = gs.enemyVariantPaths(enemyKey);
    if (variants.isEmpty) {
      final path = 'assets/images/enemies/${enemyKey.toLowerCase()}.png';
      await images.load(path);
      return;
    }
    await Future.wait(variants.map(images.load));
  }
}

// A simple Flame SpriteComponent using the loader.
class EnemySpriteComponent extends SpriteComponent {
  EnemySpriteComponent({
    required this.gs,
    required this.enemyKey,
    required this.difficulty,
    Vector2? size,
  }) : super(size: size ?? Vector2.all(64));

  final GameState gs;
  final String enemyKey;
  final Difficulty difficulty;

  late final EnemySpriteLoader _loader = EnemySpriteLoader(gs);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    sprite = await _loader.loadByDifficulty(enemyKey: enemyKey, difficulty: difficulty);
  }
}
