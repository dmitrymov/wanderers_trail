import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/game_state.dart';
import '../widgets/item_drop_popup.dart';

class BattleTab extends StatelessWidget {
  const BattleTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ElevatedButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const ActiveBattlePage()),
          );
        },
        child: const Text('Start'),
      ),
    );
  }
}

class ActiveBattlePage extends StatefulWidget {
  const ActiveBattlePage({super.key});

  @override
  State<ActiveBattlePage> createState() => _ActiveBattlePageState();
}

class _ActiveBattlePageState extends State<ActiveBattlePage> with SingleTickerProviderStateMixin {
  int _step = 0;
  Monster? _monster;
  bool _showCombat = false;
  late final Random _rnd;

  @override
  void initState() {
    super.initState();
    _rnd = Random();
  }

  void _advance(GameState gs) {
    if (_monster != null) {
      // Engage combat on advance when monster present.
      setState(() => _showCombat = true);
      return;
    }
    // Consume a bit of stamina to move forward.
    gs.addCoins(0); // trigger save; no coin change.
    setState(() {
      _step += 1;
      // 35% chance to encounter a monster.
      if (_rnd.nextDouble() < 0.35) {
        _monster = Monster.randomForStep(_step, _rnd);
        _showCombat = true;
      }
    });
  }

  void _onCombatResult(GameState gs, CombatResult r) {
    if (_monster == null) return;
    final dmg = switch (r) {
      CombatResult.perfect => 10,
      CombatResult.good => 5,
      CombatResult.miss => 0,
    };
    setState(() {
      _monster = _monster!.hit(dmg);
      _showCombat = false;
    });
    if (_monster != null && _monster!.hp <= 0) {
      // Monster defeated -> maybe drop.
      final drop = gs.maybeDrop(runScore: _step);
      setState(() => _monster = null);
      if (drop != null && mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => ItemDropPopup(item: drop, onEquip: () => gs.equip(drop)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final gs = context.watch<GameState>();
    final p = gs.profile;

    return Scaffold(
      body: Stack(
        children: [
          // Background path image (using existing asset for now)
          Positioned.fill(
            child: Image.asset(
              'assets/images/main_screen.png',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stack) => Container(color: Colors.black),
            ),
          ),
          // Top HUD: step and monster HUD if present
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Step: $_step', style: const TextStyle(color: Colors.white)),
                  Text('HP: ${p.health}', style: const TextStyle(color: Colors.white)),
                  Text('Stamina: ${p.stamina}', style: const TextStyle(color: Colors.white)),
                ],
              ),
            ),
          ),
          if (_monster != null)
            Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: const EdgeInsets.only(top: 64.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _monster!.name,
                      style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    _MonsterHpBar(current: _monster!.hp, max: _monster!.maxHp),
                  ],
                ),
              ),
            ),
          // Bottom inventory + advance button
          Align(
            alignment: Alignment.bottomCenter,
            child: SafeArea(
              minimum: const EdgeInsets.only(bottom: 12, left: 12, right: 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _InventoryBar(),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => _advance(gs),
                      child: const Text('Advance'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_showCombat)
            CombatOverlay(
              onResult: (r) => _onCombatResult(gs, r),
            ),
        ],
      ),
    );
  }
}

class _InventoryBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final p = context.watch<GameState>().profile;
    Widget cell(String label, String? value) => Expanded(
          child: Container(
            height: 52,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white24),
            ),
            alignment: Alignment.center,
            child: Text(
              value == null ? label : '$label: $value',
              style: const TextStyle(color: Colors.white, fontSize: 12),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        );
    return Row(
      children: [
        cell('Weapon', p.weapon?.name),
        const SizedBox(width: 8),
        cell('Armor', p.armor?.name),
        const SizedBox(width: 8),
        cell('Ring', p.ring?.name),
        const SizedBox(width: 8),
        cell('Boots', p.boots?.name),
      ],
    );
  }
}

class _MonsterHpBar extends StatelessWidget {
  const _MonsterHpBar({required this.current, required this.max});
  final int current;
  final int max;
  @override
  Widget build(BuildContext context) {
    final pct = (current / max).clamp(0, 1).toDouble();
    return Container(
      width: 220,
      height: 14,
      decoration: BoxDecoration(
        color: Colors.white24,
        borderRadius: BorderRadius.circular(7),
      ),
      alignment: Alignment.centerLeft,
      child: FractionallySizedBox(
        widthFactor: pct,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.redAccent,
            borderRadius: BorderRadius.circular(7),
          ),
        ),
      ),
    );
  }
}

class Monster {
  final String name;
  final int hp;
  final int maxHp;
  const Monster({required this.name, required this.hp, required this.maxHp});

  Monster hit(int damage) => Monster(name: name, hp: (hp - damage).clamp(0, maxHp), maxHp: maxHp);

  static Monster randomForStep(int step, Random rnd) {
    final maxHp = 12 + (step ~/ 5);
    final hp = maxHp;
    const names = ['Slime', 'Wolf', 'Bandit', 'Spider'];
    return Monster(name: names[rnd.nextInt(names.length)], hp: hp, maxHp: maxHp);
  }
}

enum CombatResult { perfect, good, miss }

class CombatOverlay extends StatefulWidget {
  const CombatOverlay({super.key, required this.onResult});
  final void Function(CombatResult result) onResult;

  @override
  State<CombatOverlay> createState() => _CombatOverlayState();
}

class _CombatOverlayState extends State<CombatOverlay> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat(reverse: true);
    _anim = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _controller, curve: Curves.linear));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap() {
    final t = _anim.value; // 0..1 across the bar
    // Define zones: perfect centered 8%, good centered 20%
    const perfectHalf = 0.04;
    const goodHalf = 0.10;
    const center = 0.5;
    final dx = (t - center).abs();
    CombatResult r;
    if (dx <= perfectHalf) {
      r = CombatResult.perfect;
    } else if (dx <= goodHalf) {
      r = CombatResult.good;
    } else {
      r = CombatResult.miss;
    }
    widget.onResult(r);
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Material(
        color: Colors.black.withValues(alpha: 0.6),
        child: InkWell(
          onTap: _handleTap,
          child: Center(
            child: SizedBox(
              width: MediaQuery.of(context).size.width * 0.8,
              child: AnimatedBuilder(
                animation: _anim,
                builder: (context, _) {
                  return CustomPaint(
                    painter: _TimingBarPainter(t: _anim.value),
                    child: const SizedBox(height: 48),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TimingBarPainter extends CustomPainter {
  final double t;
  _TimingBarPainter({required this.t});

  @override
  void paint(Canvas canvas, Size size) {
    final bar = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, size.height / 2 - 6, size.width, 12),
      const Radius.circular(6),
    );
    final paintBar = Paint()..color = const Color(0xFF444444);
    final paintGood = Paint()..color = const Color(0xFF2E7D32);
    final paintPerfect = Paint()..color = const Color(0xFFFFD600);
    final paintMarker = Paint()..color = const Color(0xFF90CAF9);

    canvas.drawRRect(bar, paintBar);

    // Zones centered
    final perfectW = size.width * 0.08;
    final goodW = size.width * 0.20;
    final centerX = size.width / 2;
    final perfectRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(centerX, size.height / 2), width: perfectW, height: 28),
      const Radius.circular(6),
    );
    final goodRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(centerX, size.height / 2), width: goodW, height: 28),
      const Radius.circular(6),
    );
    canvas.drawRRect(goodRect, paintGood);
    canvas.drawRRect(perfectRect, paintPerfect);

    // Marker
    final markerX = t * size.width;
    final markerRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(markerX - 4, size.height / 2 - 14, 8, 28),
      const Radius.circular(4),
    );
    canvas.drawRRect(markerRect, paintMarker);
  }

  @override
  bool shouldRepaint(covariant _TimingBarPainter oldDelegate) => oldDelegate.t != t;
}
