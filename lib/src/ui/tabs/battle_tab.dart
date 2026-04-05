import 'dart:math';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/game_state.dart';
import '../../data/models/item.dart';
import '../../data/models/item_display_helpers.dart';

import '../theme/tokens.dart';
import '../widgets/item_drop_popup.dart';
import '../widgets/panel.dart';
import '../widgets/stat_bar.dart';
import '../overlay/overlay_service.dart';
import 'character_tab.dart';

class BattleTab extends StatelessWidget {
  const BattleTab({super.key});

  @override
  Widget build(BuildContext context) {
    final gs = context.watch<GameState>();
    final resumeStep = (gs.profile.highScore ~/ 50) * 50;
    final canContinue = (gs.profile.savedStep ?? 0) > 0;
    final scheme = Theme.of(context).colorScheme;
    final muted = scheme.onSurface.withValues(alpha: 0.72);

    Future<void> openStartDialog() async {
      final choice = await showDialog<_StartChoice>(
        context: context,
        builder: (ctx) {
          return AlertDialog(
            title: const Text('Start journey'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (canContinue)
                  Text(
                    'Continue from step ${gs.profile.savedStep} (equipment kept).',
                  ),
                if (resumeStep >= 50)
                  Text(
                    'Resume checkpoint: step $resumeStep (equipment kept).',
                  ),
                const Text('New run: step 0 (equipment reset).'),
              ],
            ),
            actions: [
              if (canContinue)
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(_StartChoice.continueRun),
                  child: const Text('Continue'),
                ),
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(_StartChoice.newRun),
                child: const Text('New run'),
              ),
              if (resumeStep >= 50)
                FilledButton(
                  onPressed: () => Navigator.of(ctx).pop(_StartChoice.resume),
                  child: Text('Resume $resumeStep'),
                ),
            ],
          );
        },
      );

      if (choice == null || !context.mounted) return;
      if (choice == _StartChoice.newRun) {
        gs.resetForNewRun();
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => const ActiveBattlePage(initialStep: 0),
          ),
        );
      } else if (choice == _StartChoice.resume) {
        gs.prepareForCheckpointRun();
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ActiveBattlePage(initialStep: resumeStep),
          ),
        );
      } else if (choice == _StartChoice.continueRun) {
        final step = gs.profile.savedStep ?? 0;
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ActiveBattlePage(initialStep: step),
          ),
        );
      }
    }

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTokens.gap24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(AppTokens.gap24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(
                    Icons.route_rounded,
                    size: 56,
                    color: scheme.primary,
                  ),
                  const SizedBox(height: AppTokens.gap16),
                  Text(
                    'The trail',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: AppTokens.gap8),
                  Text(
                    'Advance steps, survive encounters, beat your high score, '
                    'and collect gear along the way.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: muted,
                          height: 1.4,
                        ),
                  ),
                  const SizedBox(height: AppTokens.gap24),
                  Row(
                    children: [
                      _HubStatChip(
                        icon: Icons.emoji_events_outlined,
                        label: 'Best',
                        value: '${gs.profile.highScore}',
                      ),
                      const SizedBox(width: AppTokens.gap8),
                      _HubStatChip(
                        icon: Icons.flag_outlined,
                        label: 'Saved',
                        value: canContinue
                            ? '${gs.profile.savedStep}'
                            : '—',
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTokens.gap24),
                  FilledButton.icon(
                    onPressed: openStartDialog,
                    icon: const Icon(Icons.play_arrow_rounded),
                    label: const Text('Start journey'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HubStatChip extends StatelessWidget {
  const _HubStatChip({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTokens.gap12,
          vertical: AppTokens.gap12,
        ),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHigh.withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(AppTokens.r12),
          border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.6)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 22, color: scheme.primary),
            const SizedBox(width: AppTokens.gap8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  Text(
                    value,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum _StartChoice { newRun, resume, continueRun }

class ActiveBattlePage extends StatefulWidget {
  const ActiveBattlePage({super.key, this.initialStep = 0});
  final int initialStep;

  @override
  State<ActiveBattlePage> createState() => _ActiveBattlePageState();
}

class _ActiveBattlePageState extends State<ActiveBattlePage> {
  bool _leaveDialogOpen = false;

  void _requestLeave() {
    if (!mounted || _leaveDialogOpen) return;
    _leaveDialogOpen = true;
    // Schedule after current frame to avoid Navigator lock during back-pop
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showLeaveDialog();
    });
  }

  Future<void> _showLeaveDialog() async {
    if (!mounted) {
      _leaveDialogOpen = false;
      return;
    }
    final gs2 = context.read<GameState>();
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Leave battle?'),
            content: const Text(
              'Leaving will save your progress. You can continue from your last save point. Equipment will be preserved.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Stay'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text('Leave'),
              ),
            ],
          ),
    );
    _leaveDialogOpen = false;
    if (confirm == true) {
      gs2.leaveBattleAndResetEquipment(saveStep: _step);
      gs2.setCombatActive(false);
      _stopCombat();
      if (mounted) Navigator.of(context).pop();
    }
  }

  int _step = 0;
  Monster? _monster;
  late final Random _rnd;
  GameState? _gsRef; // provider reference cached for use in dispose

  // Auto-combat timing
  Timer? _combatTimer;
  DateTime? _nextPlayerHit;
  DateTime? _nextMonsterHit;
  int _playerIntervalMs = 1000;
  int _monsterIntervalMs = 1000;

  final List<_DamageFloat> _floats = [];

  /// Attack timers + floating damage: repaint only this listener’s builders (not the whole page).
  final ValueNotifier<int> _combatRepaint = ValueNotifier(0);

  // Poison effect tracking
  DateTime? _nextPoisonTick;
  int _poisonTicksRemaining = 0;
  int _poisonDamagePerTick = 0;
  int _poisonIntervalMs = 1000;

  // Combat Log
  final List<_LogEntry> _logs = [];
  final ScrollController _logScrollController = ScrollController();

  /// Short on-screen notice when an encounter starts.
  String? _encounterBanner;
  Timer? _encounterBannerTimer;

  /// 1.0 matches original combat speed. Use ~1.08 if you want slightly calmer fights (was 1.6 and felt sluggish).
  static const double _combatPaceScale = 1.0;

  /// After both you and the enemy resolve an attack, log HP lost this exchange.
  int _exchangeRound = 1;
  int _dmgToMonsterThisExchange = 0;
  int _dmgToPlayerThisExchange = 0;
  bool _playerResolvedExchange = false;
  bool _monsterResolvedExchange = false;

  // Power Strike
  final _shakeKey = GlobalKey<ShakeWidgetState>();
  DateTime? _lastPowerStrike;
  static const int _powerStrikeCooldownSec = 10;

  bool get _canPowerStrike {
    if (_monster == null) return false;
    if (_lastPowerStrike == null) return true;
    return DateTime.now().difference(_lastPowerStrike!).inSeconds >=
        _powerStrikeCooldownSec;
  }

  void _performPowerStrike(GameState gs) {
    if (!_canPowerStrike) return;

    setState(() {
      _lastPowerStrike = DateTime.now();
    });

    final damage = (_calcPlayerDamage(gs) * 1.5).round();
    final monDefense = _monster!.defense;
    final finalDamage = _reduceByDefense(damage, monDefense);

    _log(
      'Power Strike! hit ${_monster!.name} for $finalDamage!',
      Colors.orangeAccent,
    );

    _floats.add(
      _DamageFloat(
        text: '$finalDamage (Power!)',
        color: Colors.orange,
        start: DateTime.now(),
        duration: const Duration(milliseconds: 1500),
        xFrac: 0.5,
        yFrac: 0.3,
        rise: 56,
        punch: true,
        fontSize: 26,
      ),
    );

    setState(() {
      _monster = _monster!.hit(finalDamage);
    });

    _notePlayerDamageToMonster(finalDamage);

    // Reset player attack timer to give instant gratification (attack now, then wait usual interval)
    _nextPlayerHit = DateTime.now().add(
      Duration(milliseconds: _playerIntervalMs),
    );

    if (_monster!.hp <= 0) {
      _onMonsterDefeated(gs);
    }
  }

  void _log(String text, Color color) {
    setState(() {
      _logs.add(_LogEntry(text, color));
      // Keep only last 50
      if (_logs.length > 50) _logs.removeAt(0);
    });
    // Scroll to bottom
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_logScrollController.hasClients) {
        _logScrollController.animateTo(
          _logScrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  int _scaleCombatMs(int ms) =>
      (ms * _combatPaceScale).round().clamp(400, 2000);

  void _resetExchangeRoundTracking() {
    _exchangeRound = 1;
    _dmgToMonsterThisExchange = 0;
    _dmgToPlayerThisExchange = 0;
    _playerResolvedExchange = false;
    _monsterResolvedExchange = false;
  }

  void _onPlayerAttackResolved(int damageToMonster) {
    if (_monster == null) return;
    _playerResolvedExchange = true;
    _dmgToMonsterThisExchange += damageToMonster;
    _tryFinishExchangeRound();
  }

  /// Extra player damage (e.g. Power Strike) before the enemy acts this exchange.
  void _notePlayerDamageToMonster(int damageToMonster) {
    if (_monster == null) return;
    if (_playerResolvedExchange && !_monsterResolvedExchange) {
      _dmgToMonsterThisExchange += damageToMonster;
      return;
    }
    _onPlayerAttackResolved(damageToMonster);
  }

  void _onMonsterAttackResolved(int damageToPlayer) {
    if (_monster == null) return;
    _monsterResolvedExchange = true;
    _dmgToPlayerThisExchange += damageToPlayer;
    _tryFinishExchangeRound();
  }

  void _tryFinishExchangeRound() {
    if (!_playerResolvedExchange || !_monsterResolvedExchange) return;
    final m = _monster;
    if (m == null) return;
    _log(
      'Round $_exchangeRound · ${m.name} −$_dmgToMonsterThisExchange HP · You −$_dmgToPlayerThisExchange HP',
      Colors.cyanAccent,
    );
    _exchangeRound++;
    _dmgToMonsterThisExchange = 0;
    _dmgToPlayerThisExchange = 0;
    _playerResolvedExchange = false;
    _monsterResolvedExchange = false;
  }

  void _showEncounterBanner(String monsterName) {
    _encounterBannerTimer?.cancel();
    _encounterBanner = monsterName;
    _encounterBannerTimer = Timer(const Duration(milliseconds: 2800), () {
      if (!mounted) return;
      setState(() => _encounterBanner = null);
    });
  }

  @override
  void initState() {
    super.initState();
    _rnd = Random();
    _step = widget.initialStep;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _gsRef ??= context.read<GameState>();
  }

  void _advance(GameState gs) {
    if (gs.profile.health <= 0) {
      _handleDefeat();
      return;
    }
    // If fighting, do nothing; stamina only consumed when moving forward.
    if (_monster != null) {
      return;
    }

    const baseStaminaCost = 5;
    const hpPenaltyWhenExhausted = 2;
    // Apply stamina cost reduction from items (percentage)
    final reduction = _sumStat(
      gs,
      ItemStatType.staminaCostReduction,
    ).clamp(0.0, 0.9);
    final staminaCost = (baseStaminaCost * (1.0 - reduction)).round().clamp(
      1,
      baseStaminaCost,
    );
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
    // Move forward when no monster is present.
    setState(() {
      _step += 1;
      // 35% chance to encounter a monster.
      if (_rnd.nextDouble() < 0.35) {
        _monster = Monster.randomForStep(gs, _step, _rnd);
        _startCombat(gs);
      } else if (_rnd.nextDouble() < 0.10) {
        var restorePoints = 10 + (_step ~/ 10);
        gs.loseHealth(-restorePoints);
        OverlayService.showToast('Restored $restorePoints health!');
      }
    });
    // Update best step and autosave/checkpoint
    gs.updateHighScore(_step);
    if (_step % 5 == 0) {
      gs.saveRunProgress(_step);
    }
    if (_step % 50 == 0) {
      OverlayService.showToast('Checkpoint reached: Step $_step');
    }
  }

  void _startCombat(GameState gs) {
    _stopCombat(notify: false);
    if (_monster == null) return;
    context.read<GameState>().setCombatActive(true);
    _playerIntervalMs = _scaleCombatMs(_calcPlayerIntervalMs(gs));
    _monsterIntervalMs = _scaleCombatMs(_monster!.attackMs);
    final now = DateTime.now();
    _nextPlayerHit = now.add(Duration(milliseconds: _playerIntervalMs));
    _nextMonsterHit = now.add(Duration(milliseconds: _monsterIntervalMs));
    _combatRepaint.value++;

    final encounterName = _monster!.name;
    _log('Attacked by $encounterName!', Colors.orangeAccent);
    _showEncounterBanner(encounterName);

    _combatTimer = Timer.periodic(const Duration(milliseconds: 100), (t) {
      if (!mounted || _monster == null) {
        _stopCombat();
        return;
      }
      final now = DateTime.now();
      // Safety: if somehow monster HP already 0, end immediately
      if (_monster!.hp <= 0) {
        _onMonsterDefeated(gs);
        return;
      }
      if (_nextPlayerHit != null && now.isAfter(_nextPlayerHit!)) {
        // Accuracy check
        final hitChance = (0.8 + _sumStat(gs, ItemStatType.accuracy)).clamp(
          0.1,
          0.98,
        );
        final hit = _rnd.nextDouble() < hitChance;
        _nextPlayerHit = now.add(Duration(milliseconds: _playerIntervalMs));
        if (hit) {
          var damage = _calcPlayerDamage(gs);
          // Crit roll
          final critChance = _sumStat(
            gs,
            ItemStatType.critChance,
          ).clamp(0.0, 0.95);
          final critMult = 1.0 + _sumStat(gs, ItemStatType.critDamage);
          final isCrit = _rnd.nextDouble() < critChance;
          if (isCrit) {
            damage = max(1, (damage * critMult).round());
          }
          // Spawn damage float over monster
          final fx = 0.5 + (_rnd.nextDouble() - 0.5) * 0.18;
          _floats.add(
            _DamageFloat(
              text: isCrit ? '-$damage!' : '-$damage',
              color: isCrit ? Colors.yellowAccent : Colors.greenAccent,
              start: now,
              duration: const Duration(milliseconds: 1400),
              xFrac: fx,
              yFrac: 0.24,
              rise: isCrit ? 52 : 44,
              punch: true,
              fontSize: isCrit ? 26 : 23,
            ),
          );
          // Reduce by monster defense
          final monDefense = _monster!.defense;
          final finalDamage = _reduceByDefense(damage, monDefense);

          if (isCrit) {
            _log(
              'Critical hit on ${_monster!.name} for $finalDamage!',
              Colors.yellowAccent,
            );
          } else {
            _log('Hit ${_monster!.name} for $finalDamage.', Colors.greenAccent);
          }

          setState(() {
            _monster = _monster!.hit(finalDamage);
          });
          _onPlayerAttackResolved(finalDamage);
          if (_monster!.hp <= 0) {
            _onMonsterDefeated(gs);
            return;
          }
        } else {
          // Miss float
          final fx = 0.5 + (_rnd.nextDouble() - 0.5) * 0.18;
          _log('You missed ${_monster!.name}.', Colors.white38);
          _floats.add(
            _DamageFloat(
              text: 'MISS',
              color: Colors.white70,
              start: now,
              duration: const Duration(milliseconds: 1000),
              xFrac: fx,
              yFrac: 0.24,
              rise: 28,
              punch: false,
              fontSize: 20,
            ),
          );
          _onPlayerAttackResolved(0);
        }
      }
      if (_nextMonsterHit != null && now.isAfter(_nextMonsterHit!)) {
        // Enemy accuracy vs player evasion
        final playerEvasion = _sumStat(gs, ItemStatType.evasion);
        final accBase = _monster!.accuracy; // 0..1
        final hitChance = (accBase - playerEvasion + 0.75).clamp(0.05, 0.98);
        final hit = _rnd.nextDouble() < hitChance;
        _nextMonsterHit = now.add(Duration(milliseconds: _monsterIntervalMs));
        var monsterSwingDamage = 0;
        if (hit) {
          int raw = 2 + (_step ~/ 5) + _rnd.nextInt(3);
          if (_monster!.type == MonsterType.slime) {
            // Higher tier slimes hit harder (less reduction)
            final base = gs.cfgNum(['slime', 'damage_factor', 'base'], 0.7);
            final per = gs.cfgNum(['slime', 'damage_factor', 'per_tier'], 0.05);
            final maxF = gs.cfgNum(['slime', 'damage_factor', 'max'], 0.95);
            final factor = (base + per * _monster!.tier).clamp(base, maxF);
            raw = max(1, (raw * factor).round());
          }
          final defense = _calcPlayerDefense(gs);
          final dmg = _reduceByDefense(raw, defense);
          monsterSwingDamage = dmg;
          // Spawn damage float near player HUD
          final fx = 0.15 + (_rnd.nextDouble() - 0.5) * 0.12;
          _floats.add(
            _DamageFloat(
              text: '-$dmg',
              color: Colors.redAccent,
              start: now,
              duration: const Duration(milliseconds: 1400),
              xFrac: fx,
              yFrac: 0.08,
              rise: 38,
              punch: true,
              fontSize: 24,
            ),
          );
          gs.loseHealth(dmg);
          _log('${_monster!.name} hit you for $dmg.', Colors.redAccent);
          _shakeKey.currentState?.shake();
          if (_monster!.type == MonsterType.spider) {
            final t = _monster!.tier;
            final baseTicks = gs.cfgInt(['spider', 'poison', 'ticks_base'], 5);
            final ticksPer = gs.cfgInt([
              'spider',
              'poison',
              'ticks_per_tier',
            ], 1);
            final dmgBase = gs.cfgInt(['spider', 'poison', 'damage_base'], 2);
            final dmgPer = gs.cfgInt([
              'spider',
              'poison',
              'damage_per_tier',
            ], 1);
            final intBase = gs.cfgInt([
              'spider',
              'poison',
              'interval_base_ms',
            ], 1000);
            final intDelta = gs.cfgInt([
              'spider',
              'poison',
              'interval_delta_per_tier',
            ], -50);
            final intMin = gs.cfgInt([
              'spider',
              'poison',
              'interval_min_ms',
            ], 600);
            final ticks = baseTicks + t * ticksPer;
            final perTick = dmgBase + t * dmgPer;
            final int interval =
                max(intMin, min(2000, intBase + t * intDelta)).toInt();
            _applyPoison(
              ticks: ticks,
              damagePerTick: perTick,
              intervalMs: interval,
            );
            final fx2 = 0.15 + (_rnd.nextDouble() - 0.5) * 0.12;
            _floats.add(
              _DamageFloat(
                text: 'poisoned',
                color: Colors.lightGreenAccent,
                start: now,
                duration: const Duration(milliseconds: 700),
                xFrac: fx2,
                yFrac: 0.08,
                rise: 18,
              ),
            );
          }
          // Wolf: chance for a rapid second claw at higher tiers
          if (_monster!.type == MonsterType.wolf) {
            final base = gs.cfgNum(['wolf', 'extra_claw', 'base_chance'], 0.2);
            final per = gs.cfgNum([
              'wolf',
              'extra_claw',
              'chance_per_tier',
            ], 0.1);
            final maxChance = gs.cfgNum([
              'wolf',
              'extra_claw',
              'max_chance',
            ], 0.6);
            final dmgFactor = gs.cfgNum([
              'wolf',
              'extra_claw',
              'damage_factor',
            ], 0.5);
            final chance = (base + per * _monster!.tier).clamp(base, maxChance);
            if (_rnd.nextDouble() < chance) {
              final extra = max(1, (dmg * dmgFactor).round());
              monsterSwingDamage += extra;
              final fx3 = 0.18 + (_rnd.nextDouble() - 0.5) * 0.12;
              _floats.add(
                _DamageFloat(
                  text: '-$extra',
                  color: Colors.redAccent,
                  start: now,
                  duration: const Duration(milliseconds: 1200),
                  xFrac: fx3,
                  yFrac: 0.1,
                  rise: 30,
                  punch: true,
                  fontSize: 22,
                ),
              );
              gs.loseHealth(extra);
              _log('Wolf double claw hit for $extra!', Colors.redAccent);
              _shakeKey.currentState?.shake();
            }
          }
          // Bandit: steals coins at higher tiers
          if (_monster!.type == MonsterType.bandit) {
            final base = gs.cfgInt(['bandit', 'coin_steal', 'base'], 1);
            final per = gs.cfgInt(['bandit', 'coin_steal', 'per_tier'], 2);
            final maxSt = gs.cfgInt(['bandit', 'coin_steal', 'max'], 50);
            final int steal =
                max(base, min(maxSt, base + _monster!.tier * per)).toInt();
            final int taken =
                (gs.profile.coins >= steal) ? steal : gs.profile.coins;
            if (taken > 0) {
              gs.addCoins(-taken);
              _log(
                'Bandit stole $taken coins!',
                Colors.orangeAccent,
              );
            }
          }
          _onMonsterAttackResolved(monsterSwingDamage);
          if (gs.profile.health <= 0) {
            gs.setCombatActive(false);
            _stopCombat();
            _handleDefeat();
            return;
          }
        } else {
          // Player evaded
          final fx = 0.15 + (_rnd.nextDouble() - 0.5) * 0.12;
          _log('You evaded ${_monster!.name} attack.', Colors.lightBlueAccent);
          _floats.add(
            _DamageFloat(
              text: 'EVADE',
              color: Colors.lightBlueAccent,
              start: now,
              duration: const Duration(milliseconds: 1000),
              xFrac: fx,
              yFrac: 0.08,
              rise: 26,
              punch: false,
              fontSize: 20,
            ),
          );
          _onMonsterAttackResolved(0);
        }
      }
      // Poison damage over time on player
      if (_poisonTicksRemaining > 0 &&
          _nextPoisonTick != null &&
          now.isAfter(_nextPoisonTick!)) {
        _nextPoisonTick = now.add(Duration(milliseconds: _poisonIntervalMs));
        final pdmg = max(1, _poisonDamagePerTick);
        final fx = 0.15 + (_rnd.nextDouble() - 0.5) * 0.12;
        _floats.add(
          _DamageFloat(
            text: '-$pdmg',
            color: Colors.lightGreenAccent,
            start: now,
            duration: const Duration(milliseconds: 800),
            xFrac: fx,
            yFrac: 0.08,
            rise: 20,
          ),
        );
        gs.loseHealth(pdmg);
        _log('Poison deals $pdmg damage.', Colors.purpleAccent);
        _shakeKey.currentState?.shake();
        _poisonTicksRemaining -= 1;
        if (gs.profile.health <= 0) {
          context.read<GameState>().setCombatActive(false);
          _stopCombat();
          _handleDefeat();
          return;
        }
      }
      // Cleanup expired floats
      _floats.removeWhere((f) => now.difference(f.start) > f.duration);
      // Localized repaint: avoid rebuilding background + scaffold every tick.
      if (mounted && (_monster != null || _floats.isNotEmpty)) {
        _combatRepaint.value++;
      }
    });
  }

  void _stopCombat({bool notify = true}) {
    final needsFrame =
        _encounterBanner != null || _encounterBannerTimer != null || _combatTimer != null;
    _encounterBannerTimer?.cancel();
    _encounterBannerTimer = null;
    _encounterBanner = null;
    _combatTimer?.cancel();
    _combatTimer = null;
    _nextPlayerHit = null;
    _nextMonsterHit = null;
    // Clear poison state
    _nextPoisonTick = null;
    _poisonTicksRemaining = 0;
    _poisonDamagePerTick = 0;
    _resetExchangeRoundTracking();
    if (notify && needsFrame && mounted) setState(() {});
  }

  int _calcPlayerIntervalMs(GameState gs) {
    const base = 1000;
    final weapon = gs.profile.weapon;
    final weaponBonus = weapon == null ? 0 : (weapon.power * 20);
    // Agility speeds up attacks: -10ms per agility point
    final agility = _sumStat(gs, ItemStatType.agility);
    final agilityBonus = (agility * 10).round();
    final raw = (base - weaponBonus - agilityBonus).clamp(400, 2000);
    final mult = gs.attackSpeedMultiplier <= 0 ? 1.0 : gs.attackSpeedMultiplier;
    final adjusted = (raw / mult).round();
    return adjusted.clamp(400, 2000);
  }

  int _calcPlayerDamage(GameState gs) {
    // Use computed stats including permanent upgrades and items
    return max(1, gs.statsSummary.attack);
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
    return gs.statsSummary.defense;
  }

  int _reduceByDefense(int raw, int defense) {
    if (defense <= 0) return max(1, raw);
    final dr = defense / (defense + 50.0); // diminishing returns
    final reduced = (raw * (1 - dr)).round();
    return max(1, reduced);
  }

  void _applyPoison({
    required int ticks,
    required int damagePerTick,
    int intervalMs = 1000,
  }) {
    // Stack up to a reasonable cap to avoid infinite growth
    _poisonTicksRemaining = (_poisonTicksRemaining + ticks).clamp(0, 15);
    _poisonDamagePerTick = damagePerTick;
    _poisonIntervalMs = _scaleCombatMs(intervalMs);
    final now = DateTime.now();
    _nextPoisonTick =
        (_nextPoisonTick == null || now.isAfter(_nextPoisonTick!))
            ? now.add(Duration(milliseconds: _poisonIntervalMs))
            : _nextPoisonTick;
  }

  double _progressTo(DateTime? next, int intervalMs) {
    if (_monster == null || next == null || intervalMs <= 0) return 0;
    final remaining = next.difference(DateTime.now()).inMilliseconds;
    final v = 1 - (remaining / intervalMs);
    return v.clamp(0.0, 1.0);
  }

  int _coinsForKill() {
    // Simple scaling: +2 base, +1 every 10 steps
    return 2 + (_step ~/ 10);
  }

  void _onMonsterDefeated(GameState gs) {
    final coins = _coinsForKill();
    if (coins > 0) {
      gs.addCoins(coins);
      OverlayService.showToast(
        '+$coins coins',
      ); //TODO: now its displayed in middle of item drop popup
    }
    final drop = gs.maybeDrop(runScore: _step);
    setState(() => _monster = null);
    gs.setCombatActive(false);
    _stopCombat();
    if (drop != null && mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder:
            (_) => ItemDropPopup(item: drop, onEquip: () => gs.equip(drop)),
      );
    } else {
      final msg = gs.applyTemporaryBlessing();
      if (mounted) {
        OverlayService.showToast(msg);
      }
    }
  }

  void _handleDefeat() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (_) => AlertDialog(
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

  void _showBlessingInfo(BuildContext context, GameState gs) {
    final spdPct = ((gs.attackSpeedMultiplier - 1) * 100).toStringAsFixed(0);
    final regPct = ((gs.staminaRegenMultiplier - 1) * 100).toStringAsFixed(0);
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      backgroundColor: Colors.black87,
      builder:
          (_) => Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: const [
                    Icon(Icons.auto_awesome, color: Colors.amberAccent),
                    SizedBox(width: 8),
                    Text(
                      'Blessing of Vigor',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Time remaining: ${gs.blessRemainingSeconds}s',
                  style: const TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 8),
                Text(
                  'Effects:',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '• Attack Speed +$spdPct%',
                  style: const TextStyle(color: Colors.white70),
                ),
                Text(
                  '• Stamina Regen +$regPct%',
                  style: const TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
    );
  }

  void _openCharacterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      useSafeArea: true,
      builder: (sheetCtx) {
        final h = MediaQuery.of(sheetCtx).size.height;
        return SizedBox(
          height: h * 0.92,
          child: Scaffold(
            appBar: AppBar(
              title: const Text('Character'),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.of(sheetCtx).pop(),
              ),
            ),
            body: const CharacterTab(),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    // Mark combat inactive on leave (just in case)
    _gsRef?.setCombatActive(false);
    _stopCombat(notify: false);
    _combatRepaint.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gs = context.watch<GameState>();
    final p = gs.profile;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        _requestLeave();
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Battle'),
          backgroundColor: Colors.black87,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: _requestLeave,
          ),
          actions: [
            IconButton(
              tooltip: 'Character',
              icon: const Icon(Icons.person, color: Colors.white),
              onPressed: _openCharacterSheet,
            ),
            TextButton.icon(
              onPressed: _requestLeave,
              icon: const Icon(Icons.exit_to_app, color: Colors.white),
              label: const Text('Leave', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
        body: ShakeWidget(
          key: _shakeKey,
          child: Stack(
            children: [
              // Background path image (using existing asset for now)
              Positioned.fill(
                child: RepaintBoundary(
                  child: Image.asset(
                    'assets/images/backgrounds/battle_bg.png',
                    fit: BoxFit.cover,
                    errorBuilder:
                        (context, error, stack) =>
                            Container(color: Colors.black),
                  ),
                ),
              ),
              if (_encounterBanner != null)
                Positioned(
                  top: 8,
                  left: 12,
                  right: 12,
                  child: Material(
                    color: Colors.black.withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(12),
                    elevation: 6,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.warning_amber_rounded,
                            color: Colors.orangeAccent,
                            size: 28,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Attacked by $_encounterBanner!',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              // HUDs (top and enemy) stacked vertically in SafeArea so enemy HUD starts under HP/Stamina HUD
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Panel(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Step: $_step',
                                  style: const TextStyle(color: Colors.white),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '| Best: ${gs.profile.highScore}',
                                  style: const TextStyle(
                                      color: Colors.white54, fontSize: 12),
                                ),
                                const SizedBox(width: 12),
                                const Icon(
                                  Icons.monetization_on,
                                  color: Colors.amber,
                                  size: 18,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${p.coins}',
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ],
                            ),
                            if (gs.isBlessActive)
                              InkWell(
                                borderRadius: BorderRadius.circular(6),
                                onTap: () => _showBlessingInfo(context, gs),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.auto_awesome,
                                      color: Colors.amberAccent,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Bless ${gs.blessRemainingSeconds}s',
                                      style: const TextStyle(
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            SizedBox(
                              width: 180,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  StatBar(
                                    label: 'HP',
                                    value: p.health,
                                    max: p.maxHealth,
                                    color: Colors.red,
                                    icon: Icons.favorite,
                                  ),
                                  const SizedBox(height: 6),
                                  StatBar(
                                    label: 'Stamina',
                                    value: p.stamina,
                                    max: p.maxStamina,
                                    color: Colors.green,
                                    icon: Icons.bolt,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      ValueListenableBuilder<int>(
                        valueListenable: _combatRepaint,
                        builder: (context, _, __) {
                          final m = _monster;
                          if (m == null) return const SizedBox.shrink();
                          return Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const SizedBox(height: 12),
                              Panel(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      m.name,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    SizedBox(
                                      width: 96,
                                      height: 96,
                                      child: Image.asset(
                                        m.imageAsset,
                                        fit: BoxFit.contain,
                                        errorBuilder:
                                            (c, e, s) => const Icon(
                                              Icons.pest_control,
                                              color: Colors.white54,
                                              size: 64,
                                            ),
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    _MonsterHpBar(
                                      current: m.hp,
                                      max: m.maxHp,
                                    ),
                                    const SizedBox(height: 8),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 24.0,
                                      ),
                                      child: Column(
                                        children: [
                                          _AttackProgressBar(
                                            label: 'You',
                                            value: _progressTo(
                                              _nextPlayerHit,
                                              _playerIntervalMs,
                                            ),
                                            color: Colors.green,
                                          ),
                                          const SizedBox(height: 6),
                                          _AttackProgressBar(
                                            label: m.name,
                                            value: _progressTo(
                                              _nextMonsterHit,
                                              _monsterIntervalMs,
                                            ),
                                            color: Colors.redAccent,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                      Expanded(
                        child: _BattleLogList(
                          logs: _logs,
                          controller: _logScrollController,
                        ),
                      ),
                      const SizedBox(height: 140),
                    ],
                  ),
                ),
              ),
              // Floating damage numbers overlay (isolated repaints via [_combatRepaint])
              if (_monster != null || _floats.isNotEmpty)
                Positioned.fill(
                  child: ValueListenableBuilder<int>(
                    valueListenable: _combatRepaint,
                    builder: (context, _, __) {
                      if (_floats.isEmpty) {
                        return const SizedBox.shrink();
                      }
                      return IgnorePointer(
                        child: Stack(
                          children:
                              _floats.map((f) {
                                final align = Alignment(
                                  f.xFrac * 2 - 1,
                                  f.yFrac * 2 - 1,
                                );
                                final now = DateTime.now();
                                final rawP =
                                    (now.difference(f.start).inMilliseconds /
                                            f.duration.inMilliseconds)
                                        .clamp(0.0, 1.0);
                                final moveP =
                                    Curves.easeOut.transform(rawP);
                                final dy = -f.rise * moveP;
                                final opacity =
                                    (1 - Curves.easeIn.transform(rawP))
                                        .clamp(0.0, 1.0);
                                final punchT =
                                    (rawP / 0.2).clamp(0.0, 1.0);
                                final punchScale = f.punch
                                    ? 1.32 -
                                        0.32 *
                                            Curves.easeOut.transform(punchT)
                                    : 1.0;
                                return Align(
                                  alignment: align,
                                  child: Opacity(
                                    opacity: opacity,
                                    child: Transform.translate(
                                      offset: Offset(0, dy),
                                      child: Transform.scale(
                                        scale: punchScale,
                                        child: Text(
                                          f.text,
                                          style: TextStyle(
                                            color: f.color,
                                            fontSize: f.fontSize,
                                            fontWeight: FontWeight.w800,
                                            letterSpacing:
                                                f.punch ? 0.3 : 0,
                                            shadows: const [
                                              Shadow(
                                                blurRadius: 6,
                                                color: Colors.black87,
                                                offset: Offset(0, 2),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                        ),
                      );
                    },
                  ),
                ),
              // Bottom inventory + advance button
              Align(
                alignment: Alignment.bottomCenter,
                child: SafeArea(
                  minimum: const EdgeInsets.only(
                    bottom: 12,
                    left: 12,
                    right: 12,
                  ),
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
                                  onPressed: _requestLeave,
                                  child: const Text('Leave'),
                                ),
                              ),
                            ],
                          )
                        else
                          SizedBox(
                            width: double.infinity,
                            child: Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed:
                                        _monster == null
                                            ? () => _advance(gs)
                                            : null,
                                    child: Text(
                                      _monster == null
                                          ? 'Advance'
                                          : 'Fighting...',
                                    ),
                                  ),
                                ),
                                if (_monster != null) ...[
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.orange,
                                        foregroundColor: Colors.black,
                                      ),
                                      onPressed:
                                          _canPowerStrike
                                              ? () => _performPowerStrike(gs)
                                              : null,
                                      child:
                                          _canPowerStrike
                                              ? const Text('Power Strike')
                                              : Text(
                                                '${(_powerStrikeCooldownSec - DateTime.now().difference(_lastPowerStrike!).inSeconds)}s',
                                              ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InventoryBar extends StatelessWidget {
  String _statLine(ItemStatType t, double v) => formatStatEntry(t, v);

  Color _rarityColor(ItemRarity? r) => Color(rarityColorValue(r));

  String _assetForItem(Item item) =>
      item.imageAsset ?? 'assets/images/items/${item.type.name}.png';

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
          case ItemType.weapon:
            base = 'Attack +${item.power}';
            break;
          case ItemType.armor:
            base = 'Defense +${item.power}';
            break;
          case ItemType.ring:
            base = 'Accuracy +${item.power}';
            break;
          case ItemType.boots:
            base = 'Defense +${item.power}';
            break;
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
                    child: Image.asset(
                      _assetForItem(item),
                      fit: BoxFit.contain,
                      errorBuilder:
                          (c, e, s) => Icon(Icons.inventory_2, color: color),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      item.name,
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '$label — $base',
                style: const TextStyle(color: Colors.white70),
              ),
              if (extras.isNotEmpty) ...[
                const SizedBox(height: 8),
                const Text(
                  'Additional Stats',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                for (final e in extras)
                  Text(
                    '• ${_statLine(e.key, e.value)}',
                    style: const TextStyle(color: Colors.white70),
                  ),
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
          onTap:
              item == null
                  ? null
                  : () => _showItemDetails(context, label, item),
          child: Container(
            height: 90,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: _rarityColor(item?.rarity)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 6),
            alignment: Alignment.center,
            child:
                item == null
                    ? const SizedBox.shrink()
                    : Tooltip(
                      message: item.stats.entries
                          .map((e) => _statLine(e.key, e.value))
                          .join('\n'),
                      preferBelow: false,
                      child: SizedBox(
                        width: 60,
                        height: 60,
                        child: Image.asset(
                          _assetForItem(item),
                          fit: BoxFit.contain,
                          errorBuilder:
                              (c, e, s) => Icon(
                                Icons.inventory_2,
                                color: _rarityColor(item.rarity),
                              ),
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
  const _AttackProgressBar({
    required this.label,
    required this.value,
    required this.color,
  });
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
            Text(
              label,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
            Text(
              '${(value * 100).toInt()}%',
              style: const TextStyle(color: Colors.white38, fontSize: 12),
            ),
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
  final bool punch; // brief pop scale for hits
  final double fontSize;
  _DamageFloat({
    required this.text,
    required this.color,
    required this.start,
    required this.duration,
    required this.xFrac,
    required this.yFrac,
    required this.rise,
    this.punch = false,
    this.fontSize = 21,
  });
}

enum MonsterType { slime, wolf, bandit, spider }

class Monster {
  final String name;
  final MonsterType type;
  final int tier; // art/behavior tier inferred from stats
  final int hp;
  final int maxHp;
  final int attackMs; // attack interval in milliseconds
  final int defense; // reduces damage taken
  final double accuracy; // 0..1 base accuracy
  final String imageAsset; // enemy image asset path
  const Monster({
    required this.name,
    required this.type,
    required this.tier,
    required this.hp,
    required this.maxHp,
    required this.attackMs,
    required this.defense,
    required this.accuracy,
    required this.imageAsset,
  });

  Monster hit(int damage) => Monster(
    name: name,
    type: type,
    tier: tier,
    hp: (hp - damage).clamp(0, maxHp),
    maxHp: maxHp,
    attackMs: attackMs,
    defense: defense,
    accuracy: accuracy,
    imageAsset: imageAsset,
  );

  static Monster randomForStep(GameState gs, int step, Random rnd) {
    final maxHp = 12 + (step ~/ 5);
    final hp = maxHp;
    // Base 1000ms, adjust +/- up to 200ms, slightly faster as step increases
    final variance = rnd.nextInt(401) - 200; // -200..+200
    final faster = (step ~/ 15) * 50; // -0, -50, -100...
    int ms = (1000 + variance - faster).clamp(500, 2000);

    // Defense scales slowly
    final defense = (2 + (step ~/ 6) + rnd.nextInt(3));
    // Accuracy scales slightly with progress and variance
    final accBase = 0.70 + (step * 0.004).clamp(0, 0.2);
    final accVar = (rnd.nextDouble() - 0.5) * 0.1; // +/-0.05
    final accuracy = (accBase + accVar).clamp(0.4, 0.95);

    const names = ['Slime', 'Wolf', 'Bandit', 'Spider'];
    final name = names[rnd.nextInt(names.length)];
    final type = switch (name) {
      'Slime' => MonsterType.slime,
      'Wolf' => MonsterType.wolf,
      'Bandit' => MonsterType.bandit,
      'Spider' => MonsterType.spider,
      _ => MonsterType.slime,
    };

    // Wolf attacks faster baseline
    final attackMs = name == 'Wolf' ? (ms - 300).clamp(400, 2000) : ms;

    // Difficulty index derived from monster stats (not step)
    final hpDiv = gs.cfgNum(['score_weights', 'hp_div'], 50.0);
    final defDiv = gs.cfgNum(['score_weights', 'def_div'], 5.0);
    final spdDiv = gs.cfgNum(['score_weights', 'attack_speed_div'], 400.0);
    final accBias = gs.cfgNum(['score_weights', 'accuracy_bias'], 0.6);
    final accWeight = gs.cfgNum(['score_weights', 'accuracy_weight'], 5.0);
    final score =
        (maxHp / hpDiv) +
        (defense / defDiv) +
        ((1200 - attackMs) / spdDiv) +
        ((accuracy - accBias) * accWeight);
    // Keep combat tier behavior derived from stats as before
    final int tierIndex =
        max(0, min(999, score.isNaN ? 0 : score.floor())).toInt();
    // Image variant based on checkpoints of 50 steps: 0.. for [0-49]=0, [50-99]=1, etc.
    final int imageIndex = (step ~/ 50);
    final image = gs.pickEnemyImage(name, difficultyIndex: imageIndex);

    return Monster(
      name: name,
      type: type,
      tier: tierIndex,
      hp: hp,
      maxHp: maxHp,
      attackMs: attackMs,
      defense: defense,
      accuracy: accuracy,
      imageAsset: image,
    );
  }
}

class _LogEntry {
  final String text;
  final Color color;
  const _LogEntry(this.text, this.color);
}

class _BattleLogList extends StatelessWidget {
  final List<_LogEntry> logs;
  final ScrollController controller;
  const _BattleLogList({required this.logs, required this.controller});

  @override
  Widget build(BuildContext context) {
    if (logs.isEmpty) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.black45,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white10),
      ),
      child: ListView.builder(
        controller: controller,
        itemCount: logs.length,
        itemBuilder: (context, index) {
          final log = logs[index];
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Text(
              log.text,
              style: TextStyle(
                color: log.color,
                fontSize: 13,
                shadows: const [
                  Shadow(
                    color: Colors.black,
                    offset: Offset(1, 1),
                    blurRadius: 2,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class ShakeWidget extends StatefulWidget {
  final Widget child;
  const ShakeWidget({super.key, required this.child});
  @override
  ShakeWidgetState createState() => ShakeWidgetState();
}

class ShakeWidgetState extends State<ShakeWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) _controller.reset();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void shake() {
    _controller.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final v = _controller.value;
        final offset = sin(v * pi * 8) * 8 * (1 - v);
        return Transform.translate(offset: Offset(offset, 0), child: child);
      },
      child: widget.child,
    );
  }
}
