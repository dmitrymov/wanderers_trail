import 'dart:math';
import 'dart:async';

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

class _ActiveBattlePageState extends State<ActiveBattlePage> {
  int _step = 0;
  Monster? _monster;
  late final Random _rnd;

  // Auto-combat timing
  Timer? _combatTimer;
  DateTime? _nextPlayerHit;
  DateTime? _nextMonsterHit;
  int _playerIntervalMs = 1000;
  int _monsterIntervalMs = 1000;

  final List<_DamageFloat> _floats = [];

  @override
  void initState() {
    super.initState();
    _rnd = Random();
  }

  void _advance(GameState gs) {
    if (gs.profile.health <= 0) {
      _handleDefeat();
      return;
    }
    const staminaCost = 5;
    const hpPenaltyWhenExhausted = 2;
    final currentStamina = gs.profile.stamina;

    if (currentStamina >= staminaCost) {
      gs.tryConsumeStamina(staminaCost);
    } else if (currentStamina > 0) {
      // Consume remaining stamina (partial).
      gs.tryConsumeStamina(currentStamina);
    } else {
      // Stamina is 0 -> lose HP per step instead.
      gs.loseHealth(hpPenaltyWhenExhausted);
      if (gs.profile.health <= 0) {
        _handleDefeat();
        return;
      }
    }

    if (_monster != null) {
      // Already fighting; advancing doesn't do extra strikes.
      return;
    }
    // Move forward when no monster is present.
    setState(() {
      _step += 1;
      // 35% chance to encounter a monster.
      if (_rnd.nextDouble() < 0.35) {
        _monster = Monster.randomForStep(_step, _rnd);
        _startCombat(gs);
      }
    });
  }

  void _startCombat(GameState gs) {
    _stopCombat();
    if (_monster == null) return;
    _playerIntervalMs = _calcPlayerIntervalMs(gs);
    _monsterIntervalMs = _monster!.attackMs;
    final now = DateTime.now();
    _nextPlayerHit = now.add(Duration(milliseconds: _playerIntervalMs));
    _nextMonsterHit = now.add(Duration(milliseconds: _monsterIntervalMs));

    _combatTimer = Timer.periodic(const Duration(milliseconds: 100), (t) {
      if (!mounted || _monster == null) {
        _stopCombat();
        return;
      }
      final now = DateTime.now();
      if (_nextPlayerHit != null && now.isAfter(_nextPlayerHit!)) {
        final damage = _calcPlayerDamage(gs);
        // Spawn damage float over monster
        final fx = 0.5 + (_rnd.nextDouble() - 0.5) * 0.18;
        _floats.add(_DamageFloat(
          text: '-$damage',
          color: Colors.greenAccent,
          start: now,
          duration: const Duration(milliseconds: 800),
          xFrac: fx,
          yFrac: 0.24,
          rise: 36,
        ));
        setState(() {
          _monster = _monster!.hit(damage);
        });
        _nextPlayerHit = now.add(Duration(milliseconds: _playerIntervalMs));
        if (_monster!.hp <= 0) {
          final drop = gs.maybeDrop(runScore: _step);
          setState(() => _monster = null);
          _stopCombat();
          if (drop != null && mounted) {
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (_) => ItemDropPopup(item: drop, onEquip: () => gs.equip(drop)),
            );
          }
          return;
        }
      }
      if (_nextMonsterHit != null && now.isAfter(_nextMonsterHit!)) {
        final dmg = 2 + (_step ~/ 5) + _rnd.nextInt(3);
        // Spawn damage float near player HUD
        final fx = 0.15 + (_rnd.nextDouble() - 0.5) * 0.12;
        _floats.add(_DamageFloat(
          text: '-$dmg',
          color: Colors.redAccent,
          start: now,
          duration: const Duration(milliseconds: 800),
          xFrac: fx,
          yFrac: 0.08,
          rise: 30,
        ));
        gs.loseHealth(dmg);
        _nextMonsterHit = now.add(Duration(milliseconds: _monsterIntervalMs));
        if (gs.profile.health <= 0) {
          _stopCombat();
          _handleDefeat();
          return;
        }
      }
      // Cleanup expired floats
      _floats.removeWhere((f) => now.difference(f.start) > f.duration);
      // Always repaint to update progress bars smoothly and show floats.
      if (mounted) setState(() {});
    });
  }

  void _stopCombat() {
    _combatTimer?.cancel();
    _combatTimer = null;
    _nextPlayerHit = null;
    _nextMonsterHit = null;
  }

  int _calcPlayerIntervalMs(GameState gs) {
    const base = 1000;
    final weapon = gs.profile.weapon;
    final weaponBonus = weapon == null ? 0 : (weapon.power * 20);
    return (base - weaponBonus).clamp(400, 2000);
  }

  int _calcPlayerDamage(GameState gs) {
    const base = 5;
    final weapon = gs.profile.weapon;
    final bonus = weapon?.power ?? 0;
    return base + bonus;
  }

  double _progressTo(DateTime? next, int intervalMs) {
    if (_monster == null || next == null || intervalMs <= 0) return 0;
    final remaining = next.difference(DateTime.now()).inMilliseconds;
    final v = 1 - (remaining / intervalMs);
    return v.clamp(0.0, 1.0);
  }

  void _handleDefeat() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('Defeated'),
        content: Text('You were defeated on step $_step.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // close dialog
              Navigator.of(context).pop(); // leave battle page
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _stopCombat();
    super.dispose();
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
                    const SizedBox(height: 8),
                    // Attack speed progress bars
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: Column(
                        children: [
                          _AttackProgressBar(
                            label: 'You',
                            value: _progressTo(_nextPlayerHit, _playerIntervalMs),
                            color: Colors.green,
                          ),
                          const SizedBox(height: 6),
                          _AttackProgressBar(
                            label: _monster!.name,
                            value: _progressTo(_nextMonsterHit, _monsterIntervalMs),
                            color: Colors.redAccent,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          // Floating damage numbers overlay
          if (_floats.isNotEmpty)
            Positioned.fill(
              child: IgnorePointer(
                child: Stack(
                  children: _floats.map((f) {
                    final align = Alignment(f.xFrac * 2 - 1, f.yFrac * 2 - 1);
                    final now = DateTime.now();
                    final p = (now.difference(f.start).inMilliseconds / f.duration.inMilliseconds).clamp(0.0, 1.0);
                    final dy = -f.rise * p;
                    final opacity = 1 - p;
                    return Align(
                      alignment: align,
                      child: Opacity(
                        opacity: opacity,
                        child: Transform.translate(
                          offset: Offset(0, dy),
                          child: Text(
                            f.text,
                            style: TextStyle(
                              color: f.color,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              shadows: const [Shadow(blurRadius: 4, color: Colors.black, offset: Offset(1, 1))],
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
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
                  if (gs.profile.health <= 0)
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: null,
                            child: const Text('Advance'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text('Return'),
                          ),
                        ),
                      ],
                    )
                  else
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _monster == null ? () => _advance(gs) : null,
                        child: Text(_monster == null ? 'Advance' : 'Fighting...'),
                      ),
                    ),
                ],
              ),
            ),
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

class _AttackProgressBar extends StatelessWidget {
  const _AttackProgressBar({required this.label, required this.value, required this.color});
  final String label;
  final double value; // 0..1
  final Color color;
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
            Text('${(value * 100).toInt()}%', style: const TextStyle(color: Colors.white38, fontSize: 12)),
          ],
        ),
        const SizedBox(height: 2),
        Container(
          height: 10,
          decoration: BoxDecoration(
            color: Colors.white24,
            borderRadius: BorderRadius.circular(5),
          ),
          alignment: Alignment.centerLeft,
          child: FractionallySizedBox(
            widthFactor: value,
            child: Container(
              height: 10,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(5),
              ),
            ),
          ),
        ),
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

class _DamageFloat {
  final String text;
  final Color color;
  final DateTime start;
  final Duration duration;
  final double xFrac; // 0..1 across width
  final double yFrac; // 0..1 across height
  final double rise; // pixels upward
  _DamageFloat({
    required this.text,
    required this.color,
    required this.start,
    required this.duration,
    required this.xFrac,
    required this.yFrac,
    required this.rise,
  });
}

class Monster {
  final String name;
  final int hp;
  final int maxHp;
  final int attackMs; // attack interval in milliseconds
  const Monster({required this.name, required this.hp, required this.maxHp, required this.attackMs});

  Monster hit(int damage) => Monster(name: name, hp: (hp - damage).clamp(0, maxHp), maxHp: maxHp, attackMs: attackMs);

  static Monster randomForStep(int step, Random rnd) {
    final maxHp = 12 + (step ~/ 5);
    final hp = maxHp;
    // Base 1000ms, adjust +/- up to 200ms, slightly faster as step increases
    final variance = rnd.nextInt(401) - 200; // -200..+200
    final faster = (step ~/ 15) * 50; // -0, -50, -100...
    final ms = (1000 + variance - faster).clamp(500, 2000);
    const names = ['Slime', 'Wolf', 'Bandit', 'Spider'];
    return Monster(name: names[rnd.nextInt(names.length)], hp: hp, maxHp: maxHp, attackMs: ms);
  }
}

