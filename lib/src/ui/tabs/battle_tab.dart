import 'dart:math';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/game_state.dart';
import '../../data/models/item.dart';
import '../widgets/item_drop_popup.dart';

class BattleTab extends StatelessWidget {
  const BattleTab({super.key});

  @override
  Widget build(BuildContext context) {
    final gs = context.watch<GameState>();
    final resumeStep = (gs.profile.highScore ~/ 50) * 50;
    return Center(
      child: ElevatedButton(
        onPressed: () async {
          final choice = await showDialog<_StartChoice>(
            context: context,
            builder: (ctx) {
              return AlertDialog(
                title: const Text('Start Journey'),
                content: Text(resumeStep >= 50
                    ? 'Start a new run from Step 0 (items reset), or resume from Step $resumeStep?'
                    : 'Start a new run from Step 0 (items reset).'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(_StartChoice.newRun),
                    child: const Text('New Run'),
                  ),
                  if (resumeStep >= 50)
                    ElevatedButton(
                      onPressed: () => Navigator.of(ctx).pop(_StartChoice.resume),
                      child: Text('Resume $resumeStep'),
                    ),
                ],
              );
            },
          );

          if (choice == null) return;
          if (choice == _StartChoice.newRun) {
            gs.resetForNewRun();
            // Begin at step 0
            // ignore: use_build_context_synchronously
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ActiveBattlePage(initialStep: 0)),
            );
          } else {
            gs.prepareForCheckpointRun();
            // ignore: use_build_context_synchronously
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => ActiveBattlePage(initialStep: resumeStep)),
            );
          }
        },
        child: const Text('Start'),
      ),
    );
  }
}

enum _StartChoice { newRun, resume }

class ActiveBattlePage extends StatefulWidget {
  const ActiveBattlePage({super.key, this.initialStep = 0});
  final int initialStep;

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
    _step = widget.initialStep;
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
      else if (_rnd.nextDouble() < 0.10) {
        var restorePoints = 10 + (_step ~/ 10);
        gs.loseHealth(-restorePoints);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Restored $restorePoints health!")),
        );
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
        // Accuracy check
        final hitChance = (0.8 + _sumStat(gs, ItemStatType.accuracy)).clamp(0.1, 0.98);
        final hit = _rnd.nextDouble() < hitChance;
        _nextPlayerHit = now.add(Duration(milliseconds: _playerIntervalMs));
        if (hit) {
          var damage = _calcPlayerDamage(gs);
          // Crit roll
          final critChance = _sumStat(gs, ItemStatType.critChance).clamp(0.0, 0.95);
          final critMult = 1.0 + _sumStat(gs, ItemStatType.critDamage);
          final isCrit = _rnd.nextDouble() < critChance;
          if (isCrit) {
            damage = max(1, (damage * critMult).round());
          }
          // Spawn damage float over monster
          final fx = 0.5 + (_rnd.nextDouble() - 0.5) * 0.18;
          _floats.add(_DamageFloat(
            text: isCrit ? '-$damage!' : '-$damage',
            color: isCrit ? Colors.yellowAccent : Colors.greenAccent,
            start: now,
            duration: const Duration(milliseconds: 800),
            xFrac: fx,
            yFrac: 0.24,
            rise: isCrit ? 44 : 36,
          ));
          // Reduce by monster defense
          final monDefense = _monster!.defense;
          final finalDamage = _reduceByDefense(damage, monDefense);
          setState(() {
            _monster = _monster!.hit(finalDamage);
          });
          if (_monster!.hp <= 0) {
            final drop = gs.maybeDrop(runScore: _step);
            setState(() => _monster = null);
            _stopCombat();
            if (drop != null && mounted) {
              //item drop!
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (_) => ItemDropPopup(item: drop, onEquip: () => gs.equip(drop)),
              );
            }
            return;
          }
        } else {
          // Miss float
          final fx = 0.5 + (_rnd.nextDouble() - 0.5) * 0.18;
          _floats.add(_DamageFloat(
            text: 'miss',
            color: Colors.white,
            start: now,
            duration: const Duration(milliseconds: 600),
            xFrac: fx,
            yFrac: 0.24,
            rise: 26,
          ));
        }
      }
      if (_nextMonsterHit != null && now.isAfter(_nextMonsterHit!)) {
        // Enemy accuracy vs player evasion
        final playerEvasion = _sumStat(gs, ItemStatType.evasion);
        final accBase = _monster!.accuracy; // 0..1
        final hitChance = (accBase - playerEvasion + 0.75).clamp(0.05, 0.98);
        final hit = _rnd.nextDouble() < hitChance;
        _nextMonsterHit = now.add(Duration(milliseconds: _monsterIntervalMs));
        if (hit) {
          final raw = 2 + (_step ~/ 5) + _rnd.nextInt(3);
          final defense = _calcPlayerDefense(gs);
          final dmg = _reduceByDefense(raw, defense);
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
          if (gs.profile.health <= 0) {
            _stopCombat();
            _handleDefeat();
            return;
          }
        } else {
          // Player evaded
          final fx = 0.15 + (_rnd.nextDouble() - 0.5) * 0.12;
          _floats.add(_DamageFloat(
            text: 'evade',
            color: Colors.white,
            start: now,
            duration: const Duration(milliseconds: 600),
            xFrac: fx,
            yFrac: 0.08,
            rise: 20,
          ));
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
    // Agility speeds up attacks: -10ms per agility point
    final agility = _sumStat(gs, ItemStatType.agility);
    final agilityBonus = (agility * 10).round();
    return (base - weaponBonus - agilityBonus).clamp(400, 2000);
  }

  int _calcPlayerDamage(GameState gs) {
    const base = 5;
    final weapon = gs.profile.weapon;
    final bonus = weapon?.power ?? 0;
    final extraAttack = _sumStat(gs, ItemStatType.attack).round();
    return base + bonus + extraAttack;
  }

  // Aggregate a stat across equipped items
  double _sumStat(GameState gs, ItemStatType t) {
    final p = gs.profile;
    double acc = 0;
    for (final it in [p.weapon, p.armor, p.ring, p.boots]) {
      if (it == null) continue;
      final v = it.stats[t];
      if (v != null) acc += v;
    }
    return acc;
  }

  int _calcPlayerDefense(GameState gs) {
    final p = gs.profile;
    int base = (p.armor?.power ?? 0) + (p.boots?.power ?? 0);
    final extra = _sumStat(gs, ItemStatType.defense).round();
    return base + extra;
  }

  int _reduceByDefense(int raw, int defense) {
    if (defense <= 0) return max(1, raw);
    final dr = defense / (defense + 50.0); // diminishing returns
    final reduced = (raw * (1 - dr)).round();
    return max(1, reduced);
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
              'assets/images/backgrounds/battle_bg.png',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stack) => Container(color: Colors.black),
            ),
          ),
          // Top HUD: step and monster HUD if present
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(12),
child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white24),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
            ),
          if (_monster != null)
            Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: const EdgeInsets.only(top: 64.0),
child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white24),
                  ),
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                    Text(
                      _monster!.name,
                      style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: 96,
                      height: 96,
                      child: Image.asset(
                        _monster!.imageAsset,
                        fit: BoxFit.contain,
                        errorBuilder: (c, e, s) => const Icon(Icons.pest_control, color: Colors.white54, size: 64),
                      ),
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
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white24),
                ),
                padding: const EdgeInsets.all(12),
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
          ),
        ],
      ),
    );
  }
}

class _InventoryBar extends StatelessWidget {
  Color _rarityColor(ItemRarity? r) {
    switch (r) {
      case ItemRarity.uncommon:
        return Colors.green;
      case ItemRarity.rare:
        return Colors.blue;
      case ItemRarity.legendary:
        return const Color(0xFFFFD700);
      case ItemRarity.mystic:
        return Colors.redAccent;
      case ItemRarity.normal:
      default:
        return Colors.white24;
    }
  }

  String _assetForItem(Item item) {
    // Prefer per-item image asset if provided; otherwise fallback by type
    return item.imageAsset ?? 'assets/images/items/${item.type.name}.png';
  }

  String _statLine(ItemStatType t, double v) {
    String label;
    bool percent = false;
    switch (t) {
      case ItemStatType.attack: label = 'Attack'; break;
      case ItemStatType.defense: label = 'Defense'; break;
      case ItemStatType.accuracy: label = 'Accuracy'; percent = true; break;
      case ItemStatType.agility: label = 'Agility'; break;
      case ItemStatType.critChance: label = 'Crit Chance'; percent = true; break;
      case ItemStatType.critDamage: label = 'Crit Damage'; percent = true; break;
      case ItemStatType.health: label = 'Health'; break;
      case ItemStatType.evasion: label = 'Evasion'; percent = true; break;
      case ItemStatType.stamina: label = 'Stamina'; break;
    }
    return percent ? '$label +${(v * 100).toStringAsFixed(0)}%'
                   : '$label +${v.toStringAsFixed(v % 1 == 0 ? 0 : 1)}';
  }

  void _showItemDetails(BuildContext context, String label, Item item) {
    final color = _rarityColor(item.rarity);
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      backgroundColor: Colors.black87,
      builder: (_) {
        final extras = item.stats.entries.toList();
        String base;
        switch (item.type) {
          case ItemType.weapon: base = 'Attack +${item.power}'; break;
          case ItemType.armor: base = 'Defense +${item.power}'; break;
          case ItemType.ring: base = 'Accuracy +${item.power}'; break;
          case ItemType.boots: base = 'Defense +${item.power}'; break;
        }
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  SizedBox(
                    width: 40,
                    height: 40,
                    child: Image.asset(_assetForItem(item), fit: BoxFit.contain,
                      errorBuilder: (c, e, s) => Icon(Icons.inventory_2, color: color)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Text('${item.name}', style: TextStyle(color: color, fontWeight: FontWeight.bold))),
                ],
              ),
              const SizedBox(height: 8),
              Text('$label — $base', style: const TextStyle(color: Colors.white70)),
              if (extras.isNotEmpty) ...[
                const SizedBox(height: 8),
                const Text('Additional Stats', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                for (final e in extras)
                  Text('• ${_statLine(e.key, e.value)}', style: const TextStyle(color: Colors.white70)),
              ],
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<GameState>().profile;

Widget cell(String label, Item? item) => Expanded(
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: item == null ? null : () => _showItemDetails(context, label, item),
              child: Container(
                height: 90,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _rarityColor(item?.rarity)),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 6),
                alignment: Alignment.center,
                child: item == null
                    ? const SizedBox.shrink()
                    : Tooltip(
                        message: item.stats.entries.map((e) => _statLine(e.key, e.value)).join('\n'),
                        preferBelow: false,
                        child: SizedBox(
                          width: 60,
                          height: 60,
                          child: Image.asset(
                            _assetForItem(item),
                            fit: BoxFit.contain,
                            errorBuilder: (c, e, s) => Icon(Icons.inventory_2, color: _rarityColor(item.rarity)),
                          ),
                        ),
                      ),
              ),
            ),
          ),
        );

    return Row(
      children: [
        cell('Weapon', p.weapon),
        const SizedBox(width: 8),
        cell('Armor', p.armor),
        const SizedBox(width: 8),
        cell('Ring', p.ring),
        const SizedBox(width: 8),
        cell('Boots', p.boots),
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
  final int defense; // reduces damage taken
  final double accuracy; // 0..1 base accuracy
  final String imageAsset; // enemy image asset path
  const Monster({
    required this.name,
    required this.hp,
    required this.maxHp,
    required this.attackMs,
    required this.defense,
    required this.accuracy,
    required this.imageAsset,
  });

  Monster hit(int damage) => Monster(
        name: name,
        hp: (hp - damage).clamp(0, maxHp),
        maxHp: maxHp,
        attackMs: attackMs,
        defense: defense,
        accuracy: accuracy,
        imageAsset: imageAsset,
      );

  static Monster randomForStep(int step, Random rnd) {
    final maxHp = 12 + (step ~/ 5);
    final hp = maxHp;
    // Base 1000ms, adjust +/- up to 200ms, slightly faster as step increases
    final variance = rnd.nextInt(401) - 200; // -200..+200
    final faster = (step ~/ 15) * 50; // -0, -50, -100...
    final ms = (1000 + variance - faster).clamp(500, 2000);

    // Defense scales slowly
    final defense = (2 + (step ~/ 6) + rnd.nextInt(3));
    // Accuracy scales slightly with progress and variance
    final accBase = 0.70 + (step * 0.004).clamp(0, 0.2);
    final accVar = (rnd.nextDouble() - 0.5) * 0.1; // +/-0.05
    final accuracy = (accBase + accVar).clamp(0.4, 0.95);

    const names = ['Slime', 'Wolf', 'Bandit', 'Spider'];
    final name = names[rnd.nextInt(names.length)];
    final image = 'assets/images/enemies/' + name.toLowerCase() + '.png';
    return Monster(
      name: name,
      hp: hp,
      maxHp: maxHp,
      attackMs: ms,
      defense: defense,
      accuracy: accuracy,
      imageAsset: image,
    );
  }
}

