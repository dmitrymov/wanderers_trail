import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/game_state.dart';
import '../widgets/item_drop_popup.dart';
import 'package:flame/input.dart';

class BattleTab extends StatefulWidget {
  const BattleTab({super.key});

  @override
  State<BattleTab> createState() => _BattleTabState();
}

class _BattleTabState extends State<BattleTab> {
  int _runScore = 0;
  late CombatGame _game;

  @override
  void initState() {
    super.initState();
    _game = CombatGame(onPerfect: _onPerfect, onGood: _onGood, onMiss: _onMiss);
  }

  void _onPerfect() {
    setState(() => _runScore += 3);
    _maybeDrop();
  }

  void _onGood() {
    setState(() => _runScore += 1);
    _maybeDrop();
  }

  void _onMiss() {
    setState(() => _runScore = (_runScore - 1).clamp(0, 999999));
  }

  void _maybeDrop() {
    final gs = context.read<GameState>();
    final drop = gs.maybeDrop(runScore: _runScore);
    if (drop != null) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => ItemDropPopup(item: drop, onEquip: () => gs.equip(drop)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final gs = context.watch<GameState>();
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Health: ${gs.profile.health}'),
              Text('Stamina: ${gs.profile.stamina}'),
              Text('Score: $_runScore'),
            ],
          ),
        ),
        Expanded(
          child: GameWidget(game: _game),
        ),
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ElevatedButton(
                onPressed: () {
                  setState(() => _runScore = 0);
                  _game.reset();
                },
                child: const Text('New Journey'),
              ),
              ElevatedButton(
                onPressed: () {
                  gs.updateHighScore(_runScore);
                },
                child: const Text('Save Score'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// Minimal timing bar combat game
class CombatGame extends FlameGame with TapDetector {
  CombatGame({required this.onPerfect, required this.onGood, required this.onMiss});

  final VoidCallback onPerfect;
  final VoidCallback onGood;
  final VoidCallback onMiss;

  double _t = 0; // 0..1 position of marker
  bool _forward = true;
  Rect _perfectZone = Rect.zero;
  Rect _goodZone = Rect.zero;

  @override
  Color backgroundColor() => const Color(0xFF111111);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _layoutZones();
  }

  void _layoutZones() {
    final bar = Rect.fromLTWH(size.x * 0.1, size.y * 0.45, size.x * 0.8, 12);
    final perfectWidth = bar.width * 0.08;
    final goodWidth = bar.width * 0.2;
    final px = bar.left + bar.width * 0.5 - perfectWidth / 2;
    _perfectZone = Rect.fromLTWH(px, bar.top - 8, perfectWidth, 28);
    final gx = bar.left + bar.width * 0.5 - goodWidth / 2;
    _goodZone = Rect.fromLTWH(gx, bar.top - 8, goodWidth, 28);
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    _layoutZones();
  }

  @override
  void update(double dt) {
    super.update(dt);
    final speed = 0.9; // seconds per sweep
    final delta = dt / speed;
    _t += _forward ? delta : -delta;
    if (_t > 1) {
      _t = 1;
      _forward = false;
    }
    if (_t < 0) {
      _t = 0;
      _forward = true;
    }
  }

  @override
  void onTap() {
    final bar = Rect.fromLTWH(size.x * 0.1, size.y * 0.45, size.x * 0.8, 12);
    final x = bar.left + bar.width * _t;
    final marker = Rect.fromLTWH(x - 4, bar.top - 8, 8, 28);
    if (_perfectZone.overlaps(marker)) {
      onPerfect();
    } else if (_goodZone.overlaps(marker)) {
      onGood();
    } else {
      onMiss();
    }
  }

  void reset() {
    _t = 0;
    _forward = true;
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final paintBar = Paint()..color = const Color(0xFF444444);
    final paintGood = Paint()..color = const Color(0xFF2E7D32);
    final paintPerfect = Paint()..color = const Color(0xFFFFD600);
    final paintMarker = Paint()..color = const Color(0xFF90CAF9);

    final bar = Rect.fromLTWH(size.x * 0.1, size.y * 0.45, size.x * 0.8, 12);
    // bar
    canvas.drawRRect(RRect.fromRectAndRadius(bar, const Radius.circular(6)), paintBar);
    // good zone
    canvas.drawRRect(RRect.fromRectAndRadius(_goodZone, const Radius.circular(6)), paintGood);
    // perfect zone
    canvas.drawRRect(RRect.fromRectAndRadius(_perfectZone, const Radius.circular(6)), paintPerfect);

    // marker
    final x = bar.left + bar.width * _t;
    final marker = Rect.fromLTWH(x - 4, bar.top - 8, 8, 28);
    canvas.drawRRect(RRect.fromRectAndRadius(marker, const Radius.circular(4)), paintMarker);
  }
}
