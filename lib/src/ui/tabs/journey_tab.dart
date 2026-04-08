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

class JourneyTab extends StatelessWidget {
  const JourneyTab({super.key});

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
          return _StartRunDialog(gs: gs);
        },
      );

      if (choice == null || !context.mounted) return;
      
      if (choice.type == _StartChoiceType.newRun) {
        gs.setIsEndlessMode(choice.isEndless);
        gs.resetForNewRun();
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ActiveJourneyPage(
              initialStep: 0, 
              level: choice.level,
            ),
          ),
        );
      } else if (choice.type == _StartChoiceType.resume) {
        gs.setIsEndlessMode(false); // checkpoints only for levels? Or keep current
        gs.prepareForCheckpointRun();
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ActiveJourneyPage(initialStep: resumeStep),
          ),
        );
      } else if (choice.type == _StartChoiceType.continueRun) {
        final step = gs.profile.savedStep ?? 0;
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ActiveJourneyPage(initialStep: step),
          ),
        );
      }
    }

    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            scheme.surface,
            scheme.surfaceContainerHigh.withValues(alpha: 0.5),
          ],
        ),
      ),
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: AppTokens.gap24, vertical: AppTokens.gap48),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Hero Visual
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: const Duration(milliseconds: 1000),
                  curve: Curves.easeOutQuart,
                  builder: (context, value, child) {
                    return Opacity(
                      opacity: value,
                      child: Transform.translate(
                        offset: Offset(0, 30 * (1 - value)),
                        child: child,
                      ),
                    );
                  },
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: scheme.primaryContainer.withValues(alpha: 0.25),
                      boxShadow: [
                        BoxShadow(
                          color: scheme.primary.withValues(alpha: 0.15),
                          blurRadius: 40,
                          spreadRadius: 8,
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.terrain_rounded,
                      size: 72,
                      color: scheme.primary,
                    ),
                  ),
                ),
                const SizedBox(height: AppTokens.gap32),
                
                // Title & Subtitle
                Text(
                  'The Wanderer\'s Trail',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.8,
                    color: const Color(0xFF1A1C1E),
                  ),
                ),
                const SizedBox(height: AppTokens.gap12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppTokens.gap16),
                  child: Text(
                    'Forge your path through the unknown. Face the encounters, collect legendary gear, and survive the trail.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: muted,
                      height: 1.5,
                      letterSpacing: 0.1,
                    ),
                  ),
                ),
                const SizedBox(height: AppTokens.gap48),
                
                // Stats HUD Section
                Row(
                  children: [
                    _HubStatChip(
                      icon: Icons.emoji_events_rounded,
                      label: 'Record',
                      value: '${gs.profile.highScore}',
                      accent: Colors.amber,
                    ),
                    const SizedBox(width: AppTokens.gap12),
                    _HubStatChip(
                      icon: Icons.flag_circle_rounded,
                      label: 'Last Point',
                      value: canContinue ? 'Step ${gs.profile.savedStep}' : '—',
                      accent: scheme.secondary,
                    ),
                    const SizedBox(width: AppTokens.gap12),
                    _HubStatChip(
                      icon: Icons.monetization_on_rounded,
                      label: 'Coins',
                      value: '${gs.profile.coins}',
                      accent: const Color(0xFFFFD54F),
                    ),
                  ],
                ),
                const SizedBox(height: AppTokens.gap32),
                
                // Action Section
                SizedBox(
                  width: double.infinity,
                  height: 64,
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppTokens.r12 * 1.5),
                      ),
                      elevation: 12,
                      shadowColor: scheme.primary.withValues(alpha: 0.35),
                      backgroundColor: scheme.primary,
                      foregroundColor: scheme.onPrimary,
                    ),
                    onPressed: openStartDialog,
                    icon: const Icon(Icons.explore_rounded, size: 28),
                    label: const Text(
                      'Begin Expedition',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              ],
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
    required this.accent,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(AppTokens.gap16),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(AppTokens.r12 * 1.5),
          border: Border.all(
            color: scheme.outlineVariant.withValues(alpha: 0.3),
            width: 1.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(AppTokens.gap8),
              decoration: BoxDecoration(
                color: const Color(0xFFD1E4E2),
                borderRadius: BorderRadius.circular(AppTokens.r8),
              ),
              child: Icon(icon, size: 20, color: accent),
            ),
            const SizedBox(height: AppTokens.gap12),
            Text(
              label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: const Color(0xFF44474E),
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppTokens.gap4),
            Text(
              value,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w900,
                color: scheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum _StartChoiceType { newRun, resume, continueRun }

class _StartChoice {
  final _StartChoiceType type;
  final bool isEndless;
  final int? level;
  _StartChoice({required this.type, this.isEndless = false, this.level});
}

class _StartRunDialog extends StatefulWidget {
  final GameState gs;
  const _StartRunDialog({required this.gs});

  @override
  State<_StartRunDialog> createState() => _StartRunDialogState();
}

class _StartRunDialogState extends State<_StartRunDialog> {
  bool _isEndless = false;
  int _selectedLevel = 1;

  @override
  void initState() {
    super.initState();
    _selectedLevel = widget.gs.profile.highestUnlockedLevel;
  }

  @override
  Widget build(BuildContext context) {
    final gs = widget.gs;
    final canContinue = (gs.profile.savedStep ?? 0) > 0;
    final resumeStep = (gs.profile.highScore ~/ 50) * 50;

    return AlertDialog(
      title: const Text('Start Journey'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (canContinue)
              _ChoiceTile(
                title: 'Continue',
                subtitle: 'Step ${gs.profile.savedStep}',
                onTap: () => Navigator.pop(context, _StartChoice(type: _StartChoiceType.continueRun)),
              ),
            if (resumeStep >= 50)
              _ChoiceTile(
                title: 'Resume Checkpoint',
                subtitle: 'Step $resumeStep',
                onTap: () => Navigator.pop(context, _StartChoice(type: _StartChoiceType.resume)),
              ),
            const Divider(),
            SwitchListTile(
              title: const Text('Endless Mode', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('Classic mode with gifts'),
              value: _isEndless,
              onChanged: (v) => setState(() => _isEndless = v),
            ),
            if (!_isEndless) ...[
              const SizedBox(height: 8),
              const Text('Select Level:', style: TextStyle(fontSize: 12, color: Colors.black45)),
              const SizedBox(height: 4),
              Wrap(
                spacing: 8,
                children: List.generate(gs.profile.highestUnlockedLevel, (i) {
                  final lvl = i + 1;
                  final isSelected = _selectedLevel == lvl;
                  return ChoiceChip(
                    label: Text('Lvl $lvl'),
                    selected: isSelected,
                    onSelected: (v) => setState(() => _selectedLevel = lvl),
                  );
                }),
              ),
            ],
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.pop(context, _StartChoice(
                  type: _StartChoiceType.newRun,
                  isEndless: _isEndless,
                  level: _isEndless ? null : _selectedLevel,
                )),
                child: const Text('Begin New Run'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChoiceTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  const _ChoiceTile({required this.title, required this.subtitle, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}

class ActiveJourneyPage extends StatefulWidget {
  const ActiveJourneyPage({super.key, this.initialStep = 0, this.level});
  final int initialStep;
  final int? level;

  @override
  State<ActiveJourneyPage> createState() => _ActiveJourneyPageState();
}

class _ActiveJourneyPageState extends State<ActiveJourneyPage> with TickerProviderStateMixin {
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
            title: const Text('Leave journey?'),
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
      gs2.endJourney(saveStep: _step);
      gs2.setCombatActive(false);
      _stopCombat();
      if (mounted) Navigator.of(context).pop();
    }
  }

  int _step = 0;
  Monster? _monster;
  late final Random _rnd;
  GameState? _gsRef; // provider reference cached for use in dispose

  // World Travel Animation
  late final AnimationController _worldController;
  late final AnimationController _livingDriftController; // Phase 6: Continuous idle drift
  double _worldOffset = 0.0;
  double _lastWorldOffset = 0.0;

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
  bool _skeletonReassembled = false;
  bool _monsterDying = false; // Phase 3: Death animation delay

  // Status effects
  int _monsterBurnTicks = 0;
  int _monsterShatterTicks = 0;
  bool _isInvulnerable = false;
  Timer? _invulTimer;

  // Combat Log
  final List<_LogEntry> _logs = [];
  final ScrollController _logScrollController = ScrollController();

  /// Short on-screen notice when an encounter starts.
  String? _encounterBanner;
  Timer? _encounterBannerTimer;

  /// Bumps on each hit the monster takes — drives recoil / HP flash animations.
  int _monsterHitVersion = 0;

  /// After both you and the enemy resolve an attack, log HP lost this exchange.
  int _exchangeRound = 1;
  int _dmgToMonsterThisExchange = 0;
  int _dmgToPlayerThisExchange = 0;
  bool _playerResolvedExchange = false;
  bool _monsterResolvedExchange = false;

  final _shakeKey = GlobalKey<ShakeWidgetState>();

  bool _canUseSkill(GameState gs) {
    if (_monster == null) return false;
    final skillId = gs.profile.heroClass.skill?.id;
    if (skillId == null) return false;
    return gs.isSkillOffCooldown(skillId);
  }

  void _useActiveSkill(GameState gs) {
    final skill = gs.profile.heroClass.skill;
    if (skill == null || !_canUseSkill(gs) || _monster == null) return;
    
    gs.startSkillCooldown(skill.id);

    final now = DateTime.now();
    bool isEnemyTarget = false;
    double dmgMult = 1.0;
    
    if (['power_strike', 'fireball', 'arcane_burst', 'execution'].contains(skill.id)) {
      isEnemyTarget = true;
      if (skill.id == 'power_strike') dmgMult = 1.5;
      if (skill.id == 'fireball') dmgMult = 2.0;
      if (skill.id == 'arcane_burst') dmgMult = 5.0;
      if (skill.id == 'execution') dmgMult = 8.0;
    }

    if (isEnemyTarget) {
      int dmg = (gs.statsSummary.attack * dmgMult).round();
      
      if (skill.id == 'execution' && ((_monster!.hp / _monster!.maxHp) < 0.25)) {
        dmg = _monster!.hp; // Instant kill
        _floats.add(_DamageFloat(text: 'EXECUTED!', color: Colors.red, start: now, duration: const Duration(milliseconds: 2000), xFrac: 0.5, yFrac: 0.1, rise: 80, punch: true, fontSize: 32));
      } else {
        _floats.add(_DamageFloat(text: '$dmg (${skill.name}!)', color: Colors.deepOrangeAccent, start: now, duration: const Duration(milliseconds: 1500), xFrac: 0.5, yFrac: 0.2, rise: 50, punch: true, fontSize: 26));
      }
      
      _log('Used ${skill.name}! Deals $dmg damage.', gs.profile.heroClass.rarityColor, icon: Icons.local_fire_department);
      
      final finalDamage = _reduceByDefense(dmg, _monster!.defense);
      setState(() {
        _monsterHitVersion++;
        _monster = _monster!.hit(finalDamage);
      });
      _notePlayerDamageToMonster(finalDamage);
      
      if (skill.id == 'fireball') {
        _monsterBurnTicks += 5;
      } else if (skill.id == 'arcane_burst') {
        _monsterShatterTicks += 5;
      }
    } else {
      // Self-targeted or buffs
      if (skill.id == 'holy_aegis') {
        _log('Used Holy Aegis! Invulnerable for 5s.', gs.profile.heroClass.rarityColor, icon: Icons.security);
        setState(() => _isInvulnerable = true);
        _invulTimer?.cancel();
        _invulTimer = Timer(const Duration(seconds: 5), () {
          if (mounted) setState(() => _isInvulnerable = false);
        });
        
        final heal = (gs.profile.maxHealth * 0.3).round();
        gs.loseHealth(-heal);
        _floats.add(_DamageFloat(text: '+$heal', color: Colors.greenAccent, start: now, duration: const Duration(milliseconds: 1200), xFrac: 0.15, yFrac: 0.1, rise: 30));
      } else if (['iron_wall', 'shadow_strike', 'bloodlust'].contains(skill.id)) {
        _log('Activated ${skill.name}!', gs.profile.heroClass.rarityColor, icon: Icons.auto_awesome);
        gs.activateSkillBuff(skill.id);
        _floats.add(_DamageFloat(text: '${skill.name}!', color: Colors.purpleAccent, start: now, duration: const Duration(milliseconds: 1200), xFrac: 0.15, yFrac: 0.1, rise: 30));
      }
    }

    // Reset player attack timer to give instant gratification
    _nextPlayerHit = DateTime.now().add(Duration(milliseconds: _playerIntervalMs));

    if (_monster != null && _monster!.hp <= 0) {
      if (mounted) _onMonsterDefeated(gs);
    }
  }

  void _log(String text, Color color, {IconData? icon}) {
    setState(() {
      _logs.add(_LogEntry(text, color, icon: icon));
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

  int _scaleCombatMs(int ms, GameState gs) {
    final mult = gs.profile.speedMultiplier.clamp(0.01, 2.0);
    return (ms / mult).round();
  }

  /// Seconds until the scheduled automatic hit (for UI countdown).
  double _secondsUntilNextHit(DateTime? next) {
    if (next == null) return 0;
    final ms = next.difference(DateTime.now()).inMilliseconds;
    return (ms / 1000.0).clamp(0.0, 999.0);
  }

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
      const Color(0xFF00695C),
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
    _worldOffset = _step.toDouble() * 200.0;
    _lastWorldOffset = _worldOffset;
    
    _worldController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _livingDriftController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 120), // 2 min per loop
    )..repeat();
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
      _lastWorldOffset = _worldOffset;
      _worldController.forward(from: 0.0);
      
      final level = widget.level;
      final maxStages = level != null ? level * 10 : null;

      // Endless gifts check
      if (gs.isEndlessMode) {
        gs.processEndlessStep(_step);
      }

      // 35% chance to encounter a monster.
      if (maxStages != null && _step == maxStages) {
        // BOSS TIME
        _monster = Monster.bossForLevel(gs, level, _rnd);
        _startCombat(gs);
      } else if (_rnd.nextDouble() < 0.35) {
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
    _monsterHitVersion = 0;
    _monsterBurnTicks = 0;
    _monsterShatterTicks = 0;
    _skeletonReassembled = false;
    _monsterDying = false;
    context.read<GameState>().setCombatActive(true);
    _playerIntervalMs = _scaleCombatMs(_calcPlayerIntervalMs(gs), gs);
    _monsterIntervalMs = _scaleCombatMs(_monster!.attackMs, gs);
    final now = DateTime.now();
    _nextPlayerHit = now.add(Duration(milliseconds: _playerIntervalMs));
    _nextMonsterHit = now.add(Duration(milliseconds: _monsterIntervalMs));
    _combatRepaint.value++;

    final encounterName = _monster!.name;
    _log('Attacked by $encounterName!', Colors.orangeAccent, icon: Icons.warning_amber_rounded);
    _showEncounterBanner(encounterName);

    _combatTimer = Timer.periodic(const Duration(milliseconds: 100), (t) {
      if (!mounted || _monster == null) {
        _stopCombat();
        return;
      }
      final now = DateTime.now();
      // Safety: if somehow monster HP already 0, end immediately
      if (_monster!.hp <= 0 && !_monsterDying) {
        setState(() => _monsterDying = true);
        Future.delayed(const Duration(milliseconds: 600), () {
          if (mounted) _onMonsterDefeated(gs);
        });
        return;
      }

      // Status Tick: Burn
      if (_monsterBurnTicks > 0 && (_combatTimer?.tick ?? 0) % 10 == 0) {
        _monsterBurnTicks--;
        final burnDmg = max(1, (_monster!.maxHp * 0.05).round());
        _floats.add(_DamageFloat(text: '-$burnDmg (Burn)', color: Colors.orange, start: now, duration: const Duration(milliseconds: 800), xFrac: 0.7, yFrac: 0.1, rise: 20));
        setState(() => _monster = _monster!.hit(burnDmg));
        if (_monster!.hp <= 0 && !_monsterDying) {
          setState(() => _monsterDying = true);
          Future.delayed(const Duration(milliseconds: 600), () {
            if (mounted) _onMonsterDefeated(gs);
          });
          return;
        }
      }

      // Status Tick: Shatter expiry
      if (_monsterShatterTicks > 0 && (_combatTimer?.tick ?? 0) % 10 == 0) {
        _monsterShatterTicks--;
      }

      if (_nextPlayerHit != null && now.isAfter(_nextPlayerHit!)) {
        // Accuracy check
        final hitChance = (0.8 + _sumStat(gs, ItemStatType.accuracy)).clamp(
          0.1,
          0.98,
        );
        final hit = _rnd.nextDouble() < hitChance;
        bool evaded = false;
        if (hit && _monster!.evasion > 0) {
          // Check for Ghost-style evasion
          if (_rnd.nextDouble() < _monster!.evasion) {
            evaded = true;
          }
        }
        _nextPlayerHit = now.add(Duration(milliseconds: _playerIntervalMs));
        if (hit && !evaded) {
          var damage = _calcPlayerDamage(gs);
          if (_monsterShatterTicks > 0) damage = (damage * 1.5).round();
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
              const Color(0xFFC67100),
              icon: Icons.auto_awesome,
            );
          } else {
            _log('Hit ${_monster!.name} for $finalDamage.', const Color(0xFF2E7D32), icon: Icons.colorize);
          }

          setState(() {
            _monsterHitVersion++;
            _monster = _monster!.hit(finalDamage);
          });
          _onPlayerAttackResolved(finalDamage);
          if (_monster!.hp <= 0) {
            // Skeleton Reassemble check
            if (_monster!.type == MonsterType.skeleton && !_skeletonReassembled) {
              final chance = gs.cfgNum(['skeleton', 'reassemble', 'chance'], 0.3);
              if (_rnd.nextDouble() < chance) {
                _skeletonReassembled = true;
                final hpPct = gs.cfgNum(['skeleton', 'reassemble', 'hp_percent'], 0.35);
                final heal = (_monster!.maxHp * hpPct).toInt();
                _monster = _monster!.hit(-heal); // Heal back
                _log('Skeleton reassembled with $heal HP!', const Color(0xFF1A1C1E), icon: Icons.refresh);
                OverlayService.showToast('Skeleton rattling back to life!');
                // Spawn "REVIVE" float
                _floats.add(
                  _DamageFloat(
                    text: 'REASSEMBLE',
                    color: const Color(0xFF1A1C1E),
                    start: now,
                    duration: const Duration(milliseconds: 1200),
                    xFrac: 0.5,
                    yFrac: 0.24,
                    rise: 40,
                    punch: true,
                    fontSize: 22,
                  ),
                );
                return; // Continue combat
              }
            }
            setState(() => _monsterDying = true);
            Future.delayed(const Duration(milliseconds: 600), () {
              if (mounted) _onMonsterDefeated(gs);
            });
            return;
          }
        } else {
          // Miss or Evaded float
          final fx = 0.5 + (_rnd.nextDouble() - 0.5) * 0.18;
          final msg = evaded ? 'EVADED' : 'MISS';
          _log('You ${evaded ? "were evaded by" : "missed"} ${_monster!.name}.', const Color(0xFF42474E).withValues(alpha: 0.6), icon: Icons.close);
          _floats.add(
            _DamageFloat(
              text: msg,
              color: const Color(0xFF42474E).withValues(alpha: 0.7),
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
          if (_isInvulnerable) {
            final fx = 0.15 + (_rnd.nextDouble() - 0.5) * 0.12;
            _floats.add(_DamageFloat(text: 'BLOCKED', color: Colors.amber, start: now, duration: const Duration(milliseconds: 1000), xFrac: fx, yFrac: 0.08, rise: 26, fontSize: 20));
            _log('Blocked ${_monster!.name}\'s attack with Holy Aegis.', Colors.amber, icon: Icons.security);
            _onMonsterAttackResolved(0);
            return;
          }
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
          // Orc Crushing Blow check
          int finalDef = defense;
          bool crushed = false;
          if (_monster!.type == MonsterType.orc) {
            final chance = gs.cfgNum(['orc', 'crushing_blow', 'chance'], 0.25);
            if (_rnd.nextDouble() < chance) {
              final ignore = gs.cfgNum(['orc', 'crushing_blow', 'defense_ignore'], 0.5);
              finalDef = (defense * (1.0 - ignore)).round();
              crushed = true;
            }
          }
          final dmg = _reduceByDefense(raw, finalDef);
          monsterSwingDamage = dmg;
          if (crushed) {
            _log('Orc CRUSHING BLOW ignored some defense!', Colors.orangeAccent, icon: Icons.gavel);
            _floats.add(
              _DamageFloat(
                text: 'CRUSH',
                color: Colors.orangeAccent,
                start: now,
                duration: const Duration(milliseconds: 1000),
                xFrac: 0.15,
                yFrac: 0.05,
                rise: 20,
                fontSize: 18,
              ),
            );
          }
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
          _log('${_monster!.name} hit you for $dmg.', Colors.redAccent, icon: Icons.bolt);
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
              _log('Wolf double claw hit for $extra!', Colors.redAccent, icon: Icons.bolt);
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
                icon: Icons.monetization_on,
              );
            }
          }
          // Demon Lifesteal check
          if (_monster!.type == MonsterType.demon && monsterSwingDamage > 0) {
            final lPct = gs.cfgNum(['demon', 'lifesteal', 'percent'], 0.25);
            final minH = gs.cfgInt(['demon', 'lifesteal', 'min_heal'], 2);
            final heal = max(minH, (monsterSwingDamage * lPct).toInt());
            setState(() {
              _monster = _monster!.hit(-heal); // Heal
            });
            _log('Demon lifestole $heal HP!', Colors.redAccent, icon: Icons.favorite);
            _floats.add(
              _DamageFloat(
                text: '+$heal',
                color: Colors.lightGreenAccent,
                start: now,
                duration: const Duration(milliseconds: 1200),
                xFrac: 0.5,
                yFrac: 0.2,
                rise: 30,
                fontSize: 20,
              ),
            );
          }
          _onMonsterAttackResolved(monsterSwingDamage);
          if (gs.profile.health <= 0) {
            // gs.setCombatActive(false);
            _stopCombat();
            _handleDefeat();
            return;
          }
        } else {
          // Player evaded
          final fx = 0.15 + (_rnd.nextDouble() - 0.5) * 0.12;
          _log('You evaded ${_monster!.name} attack.', Colors.lightBlueAccent, icon: Icons.shield);
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
        _log('Poison deals $pdmg damage.', Colors.purpleAccent, icon: Icons.medical_services);
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
    _monsterBurnTicks = 0;
    _monsterShatterTicks = 0;
    _isInvulnerable = false;
    _invulTimer?.cancel();
    _invulTimer = null;
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
    final mult = gs.blessingAttackSpeedMultiplier;
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
    _poisonIntervalMs = _scaleCombatMs(intervalMs, context.read<GameState>());
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

  static String _monsterTypeEmoji(MonsterType type) {
    return switch (type) {
      MonsterType.slime => '🟢',
      MonsterType.wolf => '🐺',
      MonsterType.bandit => '🗡️',
      MonsterType.spider => '🕷️',
      MonsterType.skeleton => '💀',
      MonsterType.orc => '👹',
      MonsterType.ghost => '👻',
      MonsterType.demon => '😈',
    };
  }

  void _onMonsterDefeated(GameState gs) {
    if (_monster == null) return;
    _stopCombat();
    final mName = _monster!.name;
    final isBoss = _monster!.isBoss;
    final level = widget.level;

    final coins = _coinsForKill();
    if (coins > 0) {
      gs.addCoins(coins);
    }

    final drop = gs.maybeDrop(runScore: _step);
    
    if (isBoss) {
      // Boss rewards: Diamonds + Key + Progress
      gs.rewardBossDefeat(level!);
      _showBossVictoryDialog(gs, level, drop);
    } else {
      if (drop != null && mounted) {
        ItemDropPopup.show(context, drop, onEquip: () {
          gs.equip(drop);
          _log('Equipped ${drop.name}.', Colors.blueGrey);
        });
      } else {
        final msg = gs.applyTemporaryBlessing();
        if (mounted) {
          OverlayService.showToast(msg);
        }
      }
    }

    _log('Defeated $mName!', Colors.green);
    setState(() {
      _monster = null;
      _monsterDying = false;
    });
    
    _resetExchangeRoundTracking();
  }

  void _showBossVictoryDialog(GameState gs, int level, Item? drop) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('EXPEDITION SUCCESS!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.emoji_events_rounded, size: 72, color: Colors.amber),
            const SizedBox(height: 16),
            Text('Level $level Conquered', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('You have defeated the boss and earned your rewards!'),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.diamond_rounded, color: Colors.cyanAccent),
                Text(' +${50 + level * 10}'),
                const SizedBox(width: 16),
                const Icon(Icons.vpn_key_rounded, color: Colors.amberAccent),
                const Text(' +1 Key'),
              ],
            ),
            if (drop != null) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              const Text('Bonus Drop:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text(drop.name, style: TextStyle(color: drop.rarityColor)),
            ],
          ],
        ),
        actions: [
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context); // Go back to hub
            },
            child: const Text('Return to Hub'),
          ),
        ],
      ),
    );
  }

  void _handleDefeat() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _DefeatDialog(
        step: _step,
        onConfirm: () {
          Navigator.of(context).pop(); // close dialog
          Navigator.of(context).pop(); // leave battle page
        },
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
    _worldController.dispose();
    _livingDriftController.dispose();
    _combatTimer?.cancel();
    _encounterBannerTimer?.cancel();
    _logScrollController.dispose();
    _combatRepaint.dispose();
    _gsRef?.setCombatActive(false);
    _stopCombat(notify: false);
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
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.terrain_rounded, size: 18, color: Colors.white70),
              const SizedBox(width: 8),
              Text(
                'Step $_step',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 17,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
          centerTitle: true,
          backgroundColor: Colors.black.withValues(alpha: 0.75),
          foregroundColor: Colors.white,
          elevation: 0,
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xCC000000), Color(0x66000000)],
              ),
            ),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: _requestLeave,
          ),
          actions: [
            IconButton(
              tooltip: 'Character',
              icon: const Icon(Icons.person_rounded, color: Colors.white),
              onPressed: _openCharacterSheet,
            ),
            IconButton(
              tooltip: 'Leave',
              icon: const Icon(Icons.logout_rounded, color: Colors.white70),
              onPressed: _requestLeave,
            ),
          ],
        ),
        body: AnimatedBuilder(
          animation: Listenable.merge([_worldController, _livingDriftController]),
          builder: (context, _) {
            final advanceOffset = _lastWorldOffset + (_worldController.value * 200.0);
            final driftOffset = _livingDriftController.value * 1200.0; // Wide range for seamless wrapping
            final totalOffset = advanceOffset + driftOffset;
            return ShakeWidget(
              key: _shakeKey,
              child: Stack(
                children: [
                  // Immersive Living Parallax Environment
                  Positioned.fill(
                    child: _ParallaxEnvironment(
                      offset: totalOffset,
                      advanceProgress: _worldController.value,
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
                  // HUDs (top and enemy) stacked vertically in SafeArea
                  SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Panel(
                            child: Row(
                              children: [
                                // Step Info
                                Expanded(
                                  flex: 2,
                                  child: Row(
                                    children: [
                                      const Icon(Icons.terrain, color: Colors.white70, size: 18),
                                      const SizedBox(width: 8),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            'Step $_step',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                          Text(
                                            'Best: ${gs.profile.highScore}',
                                            style: const TextStyle(
                                              color: Colors.white38,
                                              fontSize: 11,
                                            ),
                                          ),
                                          if (gs.isBlessActive) ...[
                                            const SizedBox(height: 4),
                                            GestureDetector(
                                              onTap: () => _showBlessingInfo(context, gs),
                                              child: Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: Colors.amber.withValues(alpha: 0.15),
                                                  borderRadius: BorderRadius.circular(4),
                                                  border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
                                                ),
                                                child: Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    const Icon(Icons.auto_awesome, color: Colors.amber, size: 10),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      'BLESSED (${gs.blessRemainingSeconds}s)',
                                                      style: const TextStyle(color: Colors.amber, fontSize: 8, fontWeight: FontWeight.bold),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                // Coins
                                Expanded(
                                  flex: 1,
                                  child: Center(
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.monetization_on, color: Colors.amber, size: 20),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${p.coins}',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w800,
                                            fontSize: 15,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                // Player Stats (HP/Stamina)
                                Expanded(
                                  flex: 3,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Stack(
                                        clipBehavior: Clip.none,
                                        children: [
                                          StatBar(
                                            label: 'HP',
                                            value: p.health,
                                            max: p.maxHealth,
                                            color: Colors.red,
                                            icon: Icons.favorite,
                                          ),
                                          if (_isInvulnerable)
                                            Positioned(
                                              right: -8, top: -8,
                                              child: Container(
                                                padding: EdgeInsets.all(2),
                                                decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.amber),
                                                child: Icon(Icons.security, size: 14, color: Colors.white),
                                              ),
                                            ),
                                        ]
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
                              return AnimatedSwitcher(
                                duration: const Duration(milliseconds: 600),
                                switchInCurve: Curves.easeOutBack,
                                switchOutCurve: Curves.easeInCirc,
                                transitionBuilder: (Widget child, Animation<double> animation) {
                                  return FadeTransition(
                                    opacity: animation,
                                    child: ScaleTransition(
                                      scale: animation,
                                      alignment: Alignment.center,
                                      child: child,
                                    ),
                                  );
                                },
                                child: m == null
                                    ? const SizedBox.shrink(key: ValueKey('no_monster'))
                                    : Column(
                                        key: ValueKey('monster_${m.name}_${m.hp}'), // Use HP to distinguish same-name monsters if needed
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment: CrossAxisAlignment.stretch,
                                        children: [
                                          const SizedBox(height: 12),
                                          Panel(
                                            child: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Row(
                                                  mainAxisAlignment: MainAxisAlignment.center,
                                                  children: [
                                                    Text(
                                                      _monsterTypeEmoji(m.type),
                                                      style: const TextStyle(fontSize: 16),
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Text(
                                                      m.name,
                                                      style: const TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 20,
                                                        fontWeight: FontWeight.bold,
                                                      ),
                                                    ),
                                                    if (_monsterBurnTicks > 0)
                                                      const Padding(
                                                        padding: EdgeInsets.only(left: 6),
                                                        child: Icon(Icons.local_fire_department, size: 16, color: Colors.orange),
                                                      ),
                                                    if (_monsterShatterTicks > 0)
                                                      const Padding(
                                                        padding: EdgeInsets.only(left: 4),
                                                        child: Icon(Icons.auto_fix_high, size: 16, color: Colors.purpleAccent),
                                                      ),
                                                    const SizedBox(width: 8),
                                                    _TierStars(tier: m.tier),
                                                  ],
                                                ),
                                                const SizedBox(height: 8),
                                                _MonsterPortrait(
                                                  imageAsset: m.imageAsset,
                                                  hitVersion: _monsterHitVersion,
                                                  isDying: _monsterDying,
                                                  windUpScale: _progressTo(
                                                            _nextMonsterHit,
                                                            _monsterIntervalMs,
                                                          ) >
                                                          0.88
                                                      ? 1.0 +
                                                          0.04 *
                                                              sin(
                                                                DateTime.now()
                                                                        .millisecondsSinceEpoch /
                                                                    185.0,
                                                              )
                                                      : 1.0,
                                                ),
                                                const SizedBox(height: 8),
                                                Padding(
                                                  padding: const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                  ),
                                                  child: _MonsterHpBar(
                                                    current: m.hp,
                                                    max: m.maxHp,
                                                    damageFlashKey: _monsterHitVersion,
                                                    showPercent: true,
                                                  ),
                                                ),
                                                const SizedBox(height: 6),
                                                Padding(
                                                  padding: const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                  ),
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment.start,
                                                    children: [
                                                      Row(
                                                        children: [
                                                          const Icon(
                                                            Icons.schedule,
                                                            color: Colors.white70,
                                                            size: 18,
                                                          ),
                                                          const SizedBox(width: 8),
                                                          const Text(
                                                            'Attack timing',
                                                            style: TextStyle(
                                                              color: Colors.white,
                                                              fontWeight: FontWeight.w700,
                                                              fontSize: 14,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                      const SizedBox(height: 10),
                                                      _AttackTimeline(
                                                        icon: Icons.sports_martial_arts,
                                                        title: 'Your next swing',
                                                        progress: _progressTo(
                                                          _nextPlayerHit,
                                                          _playerIntervalMs,
                                                        ),
                                                        secondsLeft: _secondsUntilNextHit(
                                                          _nextPlayerHit,
                                                        ),
                                                        accent: Colors.lightGreenAccent,
                                                      ),
                                                      const SizedBox(height: 8),
                                                      _AttackTimeline(
                                                        icon: Icons.bolt,
                                                        title: "${m.name}'s next swing",
                                                        progress: _progressTo(
                                                          _nextMonsterHit,
                                                          _monsterIntervalMs,
                                                        ),
                                                        secondsLeft: _secondsUntilNextHit(
                                                          _nextMonsterHit,
                                                        ),
                                                        accent: Colors.redAccent,
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                              );
                            },
                          ),
                          Expanded(
                            child: _JourneyLogList(
                              logs: _logs,
                              controller: _logScrollController,
                            ),
                          ),
                          const SizedBox(height: 140),
                        ],
                      ),
                    ),
                  ),
                  // Floating damage numbers overlay
                  if (_monster != null || _floats.isNotEmpty)
                    Positioned.fill(
                      child: ValueListenableBuilder<int>(
                        valueListenable: _combatRepaint,
                        builder: (context, _, __) {
                          if (_floats.isEmpty) return const SizedBox.shrink();
                          return IgnorePointer(
                            child: Stack(
                              children: _floats.map((f) {
                                final align = Alignment(f.xFrac * 2 - 1, f.yFrac * 2 - 1);
                                final now = DateTime.now();
                                final rawP = (now.difference(f.start).inMilliseconds / f.duration.inMilliseconds).clamp(0.0, 1.0);
                                final moveP = Curves.easeOut.transform(rawP);
                                final dy = -f.rise * moveP;
                                final opacity = (1 - Curves.easeIn.transform(rawP)).clamp(0.0, 1.0);
                                final punchT = (rawP / 0.2).clamp(0.0, 1.0);
                                final punchScale = f.punch ? 1.32 - 0.32 * Curves.easeOut.transform(punchT) : 1.0;
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
                                            shadows: const [
                                              Shadow(blurRadius: 6, color: Colors.black87, offset: Offset(0, 2)),
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
                                  const Expanded(child: ElevatedButton(onPressed: null, child: Text('Advance'))),
                                  const SizedBox(width: 8),
                                  Expanded(child: OutlinedButton(onPressed: _requestLeave, child: const Text('Leave'))),
                                ],
                              )
                            else
                              SizedBox(
                                width: double.infinity,
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: ElevatedButton.icon(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: _monster == null
                                              ? const Color(0xFF1A6B3C)
                                              : Colors.grey.withValues(alpha: 0.3),
                                          foregroundColor: Colors.white,
                                          disabledBackgroundColor: Colors.grey.withValues(alpha: 0.2),
                                          disabledForegroundColor: Colors.white38,
                                        ),
                                        onPressed: _monster == null ? () => _advance(gs) : null,
                                        icon: Icon(
                                          _monster == null ? Icons.arrow_forward_rounded : Icons.sports_martial_arts_rounded,
                                          size: 18,
                                        ),
                                        label: Text(_monster == null ? 'Advance' : 'Fighting...'),
                                      ),
                                    ),
                                    if (_monster != null) ...[
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: _ClassSkillButton(
                                          name: gs.profile.heroClass.skill?.name ?? 'Strike',
                                          icon: 'assets/images/icons/skills/${gs.profile.heroClass.skill?.id ?? "power_strike"}.png',
                                          color: gs.profile.heroClass.rarityColor,
                                          canUse: _canUseSkill(gs),
                                          cooldownProgress: gs.getSkillCooldownProgress(gs.profile.selectedClassId),
                                          secondsLeft: gs.getSkillSecondsRemaining(gs.profile.heroClass.skill?.id ?? ""),
                                          onPressed: () => _useActiveSkill(gs),
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
            );
          },
        ),
      ),
    );
  }
}

class _InventoryBar extends StatelessWidget {
  String _statLine(ItemStatType t, double v) => formatStatEntry(t, v);

  Color _rarityColor(ItemRarity? r) => Color(rarityColorValue(r));

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
                      item.effectiveAssetPath,
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

    Widget cell(String label, Item? item) {
      final color = _rarityColor(item?.rarity);
      final hasItem = item != null;

      return Expanded(
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: !hasItem ? null : () => _showItemDetails(context, label, item),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              height: 94,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: color.withValues(alpha: hasItem ? 0.8 : 0.2),
                  width: hasItem ? 1.5 : 1,
                ),
                boxShadow: hasItem
                    ? [
                        BoxShadow(
                          color: color.withValues(alpha: 0.25),
                          blurRadius: 8,
                          spreadRadius: 1,
                        ),
                      ]
                    : null,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    label.toUpperCase(),
                    style: TextStyle(
                      color: color.withValues(alpha: 0.6),
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Expanded(
                    child: !hasItem
                        ? Icon(Icons.add_circle_outline, color: Colors.white10, size: 20)
                        : Tooltip(
                            message: item.stats.entries.map((e) => _statLine(e.key, e.value)).join('\n'),
                            preferBelow: false,
                            child: Image.asset(
                              item.effectiveAssetPath,
                              fit: BoxFit.contain,
                              errorBuilder: (c, e, s) => Icon(Icons.inventory_2, color: color, size: 24),
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Row(
      children: [
        cell('Weapon', p.journeyWeapon ?? p.weapon),
        const SizedBox(width: 8),
        cell('Armor', p.journeyArmor ?? p.armor),
        const SizedBox(width: 8),
        cell('Ring', p.journeyRing ?? p.ring),
        const SizedBox(width: 8),
        cell('Boots', p.journeyBoots ?? p.boots),
      ],
    );
  }
}

class _MonsterPortrait extends StatelessWidget {
  const _MonsterPortrait({
    required this.imageAsset,
    required this.hitVersion,
    required this.windUpScale,
    this.isDying = false,
  });

  final String imageAsset;
  final int hitVersion;
  final double windUpScale;
  final bool isDying;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      key: ValueKey(isDying),
      tween: Tween(begin: 0.0, end: isDying ? 1.0 : 0.0),
      duration: const Duration(milliseconds: 500),
      builder: (context, sink, child) {
        return Transform.translate(
          offset: Offset(0, sink * 100),
          child: Opacity(
            opacity: (1.0 - sink).clamp(0.0, 1.0),
            child: child,
          ),
        );
      },
      child: TweenAnimationBuilder<double>(
        key: ValueKey(hitVersion),
        tween: Tween(begin: 1.14, end: 1.0),
        duration: const Duration(milliseconds: 340),
        curve: Curves.elasticOut,
        builder: (context, recoil, child) {
          final flash = hitVersion > 0 && recoil > 1.02 ? (recoil - 1.0) * 5 : 0.0;
          return Transform.scale(
            scale: (hitVersion == 0 ? 1.0 : recoil) * windUpScale,
            child: Stack(
              children: [
                imageAsset.isNotEmpty
                    ? SizedBox(
                        height: 110,
                        width: 110,
                        child: Image.asset(
                          imageAsset,
                          fit: BoxFit.contain,
                          errorBuilder: (c, e, s) => const Icon(Icons.pest_control, color: Colors.white54, size: 64),
                        ),
                      )
                    : const Icon(Icons.pest_control, color: Colors.white54, size: 64),
                if (flash > 0)
                  Positioned.fill(
                    child: Opacity(
                      opacity: flash.clamp(0.0, 1.0),
                      child: imageAsset.isNotEmpty
                          ? Image.asset(
                              imageAsset,
                              fit: BoxFit.contain,
                              color: Colors.white,
                              colorBlendMode: BlendMode.srcIn,
                            )
                          : Container(color: Colors.white),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Clear attack schedule: label, live countdown, fill bar, glowing marker at the tip.
class _AttackTimeline extends StatelessWidget {
  const _AttackTimeline({
    required this.icon,
    required this.title,
    required this.progress,
    required this.secondsLeft,
    required this.accent,
  });

  final IconData icon;
  final String title;
  final double progress;
  final double secondsLeft;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final p = progress.clamp(0.0, 1.0);
    final striking = secondsLeft < 0.12;
    final timeLabel = striking ? 'Striking…' : '${secondsLeft.toStringAsFixed(1)} s';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: accent),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: striking ? 0.5 : 0.32),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: accent.withValues(alpha: striking ? 1 : 0.55),
                  width: striking ? 1.5 : 1,
                ),
              ),
              child: Text(
                timeLabel,
                style: TextStyle(
                  color: accent,
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LayoutBuilder(
          builder: (context, constraints) {
            final w = constraints.maxWidth;
            final fillW = max(0.0, w * p);
            final markerX = (p * w - 7).clamp(0.0, w - 14);
            return SizedBox(
              height: 22,
              width: w,
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.centerLeft,
                children: [
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(11),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: SizedBox(width: w, height: 22),
                  ),
                  Positioned(
                    left: 0,
                    top: 0,
                    width: fillW,
                    height: 22,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(11),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              accent.withValues(alpha: 0.55),
                              accent,
                            ],
                          ),
                        ),
                        child: const SizedBox.expand(),
                      ),
                    ),
                  ),
                  Positioned(
                    left: markerX,
                    top: 0,
                    child: Container(
                      width: 14,
                      height: 22,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: accent.withValues(alpha: 0.95),
                            blurRadius: 10,
                            spreadRadius: 0.5,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}

class _MonsterHpBar extends StatelessWidget {
  const _MonsterHpBar({
    required this.current,
    required this.max,
    this.damageFlashKey = 0,
    this.showPercent = false,
  });

  final int current;
  final int max;
  final int damageFlashKey;
  final bool showPercent;

  @override
  Widget build(BuildContext context) {
    final pct = (current / max).clamp(0, 1).toDouble();
    // Color transitions: green > yellow > orange > red as HP drops
    final barColor = pct > 0.6
        ? const Color(0xFFEF5350)
        : pct > 0.35
            ? const Color(0xFFFF7043)
            : const Color(0xFFFF1744);
    final barColorLight = pct > 0.6
        ? const Color(0xFFEF9A9A)
        : pct > 0.35
            ? const Color(0xFFFFAB91)
            : const Color(0xFFFF616F);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showPercent)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'HP',
                style: TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.w700),
              ),
              Text(
                '$current / $max  (${(pct * 100).round()}%)',
                style: TextStyle(
                  color: barColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        if (showPercent) const SizedBox(height: 4),
        LayoutBuilder(
          builder: (context, c) {
            final w = c.maxWidth;
            final rawFill = w * pct;
            final fillW = pct <= 0 ? 0.0 : (rawFill < 1 ? 1.0 : rawFill);
            return SizedBox(
              height: 18,
              width: w,
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(9),
                    child: ColoredBox(
                      color: Colors.white.withValues(alpha: 0.18),
                      child: SizedBox(width: w, height: 18),
                    ),
                  ),
                  Positioned(
                    left: 0,
                    top: 0,
                    width: fillW,
                    height: 18,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(9),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [barColor, barColorLight],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: barColor.withValues(alpha: 0.5),
                              blurRadius: 6,
                              spreadRadius: 0,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  if (damageFlashKey > 0)
                    Positioned.fill(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(9),
                        child: TweenAnimationBuilder<double>(
                          key: ValueKey(damageFlashKey),
                          tween: Tween(begin: 0.55, end: 0.0),
                          duration: const Duration(milliseconds: 420),
                          curve: Curves.easeOut,
                          builder: (_, flash, __) => ColoredBox(
                            color: Colors.white.withValues(alpha: flash),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ],
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

enum MonsterType { slime, wolf, bandit, spider, skeleton, orc, ghost, demon }

class Monster {
  final String name;
  final MonsterType type;
  final int tier; // art/behavior tier inferred from stats
  final int hp;
  final int maxHp;
  final int attackMs; // attack interval in milliseconds
  final int defense; // reduces damage taken
  final double accuracy; // 0..1 base accuracy
  final double evasion; // 0..1 chance to avoid being hit
  final String imageAsset; // enemy image asset path
  final bool isBoss;
  const Monster({
    required this.name,
    required this.type,
    required this.tier,
    required this.hp,
    required this.maxHp,
    required this.attackMs,
    required this.defense,
    required this.accuracy,
    required this.evasion,
    required this.imageAsset,
    this.isBoss = false,
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
    evasion: evasion,
    imageAsset: imageAsset,
    isBoss: isBoss,
  );

  static Monster randomForStep(GameState gs, int step, Random rnd) {
    final maxHp = 12 + (step ~/ 5);
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

    const names = [
      'Slime',
      'Wolf',
      'Bandit',
      'Spider',
      'Skeleton',
      'Skeleton Warrior',
      'Orc',
      'Orc Brute',
      'Ghost',
      'Ghost Wraith',
      'Demon',
      'Demon Lord'
    ];
    final String name = names[rnd.nextInt(names.length)];
    final type = switch (name) {
      'Slime' => MonsterType.slime,
      'Wolf' => MonsterType.wolf,
      'Bandit' => MonsterType.bandit,
      'Spider' => MonsterType.spider,
      'Skeleton' || 'Skeleton Warrior' => MonsterType.skeleton,
      'Orc' || 'Orc Brute' => MonsterType.orc,
      'Ghost' || 'Ghost Wraith' => MonsterType.ghost,
      'Demon' || 'Demon Lord' => MonsterType.demon,
      _ => MonsterType.slime,
    };

    // Calculate archetype adjustments
    double hpMul = 1.0;
    double defAdd = 0.0;
    int msSpeedBonus = 0;
    double accBonus = 0.0;
    double evaBonus = 0.0;

    switch (type) {
      case MonsterType.wolf:
        msSpeedBonus = 300;
        break;
      case MonsterType.skeleton:
        hpMul = 0.8;
        defAdd = 5.0 + (step ~/ 12);
        msSpeedBonus = -200; // Slow but armored
        break;
      case MonsterType.orc:
        hpMul = 1.4 + (step * 0.005);
        defAdd = 2.0;
        msSpeedBonus = -100; // Tanky bruiser
        break;
      case MonsterType.ghost:
        hpMul = 0.6;
        accBonus = 0.15;
        msSpeedBonus = 200; // Evasive glass cannon
        evaBonus = gs.cfgNum(['ghost', 'evasion', 'base_rate'], 0.15);
        break;
      case MonsterType.demon:
        hpMul = 1.2;
        accBonus = 0.1;
        msSpeedBonus = 350; // Elite threat
        break;
      default:
        break;
    }

    final int finalMaxHp = (maxHp * hpMul).toInt();
    final int finalHp = finalMaxHp;
    final int finalAttackMs = (ms - msSpeedBonus).clamp(400, 2000);
    final int finalDefense = (defense + defAdd).toInt();
    final double finalAccuracy = (accuracy + accBonus).clamp(0.4, 0.98);
    final double finalEvasion = evaBonus.clamp(0.0, 0.6);

    // Difficulty index derived from monster stats (not step)
    final hpDiv = gs.cfgNum(['score_weights', 'hp_div'], 50.0);
    final defDiv = gs.cfgNum(['score_weights', 'def_div'], 5.0);
    final spdDiv = gs.cfgNum(['score_weights', 'attack_speed_div'], 400.0);
    final accBias = gs.cfgNum(['score_weights', 'accuracy_bias'], 0.6);
    final accWeight = gs.cfgNum(['score_weights', 'accuracy_weight'], 5.0);
    final score =
        (finalMaxHp / hpDiv) +
        (finalDefense / defDiv) +
        ((1200 - finalAttackMs) / spdDiv) +
        ((finalAccuracy - accBias) * accWeight);
    // Keep combat tier behavior derived from stats as before
    final int tierIndex =
        max(0, min(999, score.isNaN ? 0 : score.floor())).toInt();
    // Image variant based on checkpoints of 50 steps: 0.. for [0-49]=0, [50-99]=1, etc.
    final int imageIndex = (step ~/ 50);
    // Use existing icons as placeholders for new types
    final String assetSearchName = switch (type) {
      MonsterType.skeleton => 'Skeleton',
      MonsterType.orc => 'Orc',
      MonsterType.ghost => 'Ghost',
      MonsterType.demon => 'Demon',
      _ => name,
    };
    final image = gs.pickEnemyImage(assetSearchName, difficultyIndex: imageIndex);

    return Monster(
      name: name,
      type: type,
      tier: tierIndex,
      hp: finalHp,
      maxHp: finalMaxHp,
      attackMs: finalAttackMs,
      defense: finalDefense,
      accuracy: finalAccuracy,
      evasion: finalEvasion,
      imageAsset: image,
      isBoss: false,
    );
  }

  static Monster bossForLevel(GameState gs, int? level, Random rnd) {
    if (level == null) return randomForStep(gs, 100, rnd);
    // bosses are much tougher
    final scale = 1.0 + (level * 0.5);
    final base = randomForStep(gs, level * 10, rnd);
    
    return Monster(
      name: 'BOSS: ${base.name}',
      type: base.type,
      tier: base.tier + 5,
      hp: (base.maxHp * 5 * scale).toInt(),
      maxHp: (base.maxHp * 5 * scale).toInt(),
      attackMs: (base.attackMs * 0.8).round().clamp(300, 2000),
      defense: (base.defense * 2 * scale).toInt(),
      accuracy: (base.accuracy + 0.1).clamp(0, 0.99),
      evasion: (base.evasion + 0.05).clamp(0, 0.8),
      imageAsset: base.imageAsset,
      isBoss: true,
    );
  }
}

class _LogEntry {
  final String text;
  final Color color;
  final IconData? icon;
  const _LogEntry(this.text, this.color, {this.icon});
}

class _JourneyLogList extends StatelessWidget {
  final List<_LogEntry> logs;
  final ScrollController controller;
  const _JourneyLogList({required this.logs, required this.controller});

  @override
  Widget build(BuildContext context) {
    if (logs.isEmpty) {
      return Container(
        margin: const EdgeInsets.only(top: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.black38,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white10),
        ),
        child: const Center(
          child: Text(
            'Combat events will appear here…',
            style: TextStyle(color: Colors.white24, fontSize: 12),
          ),
        ),
      );
    }
    return Container(
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        color: Colors.black45,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Log header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            child: Row(
              children: [
                const Icon(Icons.article_outlined, size: 13, color: Colors.white38),
                const SizedBox(width: 6),
                const Text(
                  'JOURNEY LOG',
                  style: TextStyle(
                    color: Colors.white38,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                  ),
                ),
                const Spacer(),
                Text(
                  '${logs.length} events',
                  style: const TextStyle(color: Colors.white24, fontSize: 10),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Colors.white10),
          Expanded(
            child: ListView.builder(
              controller: controller,
              padding: const EdgeInsets.symmetric(vertical: 4),
              itemCount: logs.length,
              itemBuilder: (context, index) {
                final log = logs[index];
                final isEven = index % 2 == 0;
                return Container(
                  color: isEven ? Colors.white.withValues(alpha: 0.03) : Colors.transparent,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Entry number badge
                      SizedBox(
                        width: 22,
                        child: Text(
                          '${index + 1}',
                          style: const TextStyle(
                            color: Colors.white24,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      if (log.icon != null) ...[
                        Icon(log.icon, size: 13, color: log.color),
                        const SizedBox(width: 6),
                      ] else
                        const SizedBox(width: 19),
                      Expanded(
                        child: Text(
                          log.text,
                          style: TextStyle(
                            color: log.color,
                            fontSize: 12.5,
                            fontWeight: log.color != Colors.white38 ? FontWeight.w600 : FontWeight.normal,
                            shadows: const [
                              Shadow(
                                color: Colors.black,
                                offset: Offset(1, 1),
                                blurRadius: 2,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
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

class _ParallaxEnvironment extends StatelessWidget {
  final double offset;
  final double advanceProgress;

  const _ParallaxEnvironment({
    required this.offset,
    required this.advanceProgress,
  });

  @override
  Widget build(BuildContext context) {
    // Walking bob: subtle vertical oscillation during advancement
    final bob = advanceProgress > 0 ? sin(advanceProgress * pi * 2) * 8.0 : 0.0;

    return Stack(
      children: [
        // Background Image Layer with horizontal wrapping
        _ParallaxLayer(
          offset: offset,
          speed: 1.0,
          child: Transform.translate(
            offset: Offset(0, bob),
            child: Image.asset(
              'assets/images/backgrounds/battle_bg.png',
              repeat: ImageRepeat.repeatX,
              fit: BoxFit.cover,
              height: double.infinity,
              width: double.infinity,
              alignment: Alignment.centerLeft,
            ),
          ),
        ),
        // Wind Particles / Speed Lines
        Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(
              painter: _WindParticlePainter(
                offset: offset,
                isAdvancing: advanceProgress > 0.01,
                advanceProgress: advanceProgress,
              ),
            ),
          ),
        ),
        // Vignette/Atmosphere overlay
        IgnorePointer(
          child: Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 1.4,
                colors: [
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.35),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ParallaxLayer extends StatelessWidget {
  final double offset;
  final double speed;
  final Widget child;

  const _ParallaxLayer({required this.offset, required this.speed, required this.child});

  @override
  Widget build(BuildContext context) {
    // Basic infinite wrapping for images
    // We use a larger width to ensure no gaps during fast movement
    const double width = 2400; 
    final x = -(offset * speed) % width;
    
    return Stack(
      children: [
        Positioned.fill(
          left: x,
          child: child,
        ),
        Positioned.fill(
          left: x + width,
          child: child,
        ),
        Positioned.fill(
          left: x - width,
          child: child,
        ),
      ],
    );
  }
}

class _WindParticlePainter extends CustomPainter {
  final double offset;
  final bool isAdvancing;
  final double advanceProgress;

  _WindParticlePainter({
    required this.offset,
    required this.isAdvancing,
    required this.advanceProgress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rnd = Random(42);
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: isAdvancing ? 0.25 : 0.1)
      ..strokeWidth = 1.2;

    final particleCount = isAdvancing ? 60 : 25;
    final speedMult = isAdvancing ? 4.0 : 1.0;

    for (int i = 0; i < particleCount; i++) {
      final xBase = rnd.nextDouble() * size.width;
      final y = rnd.nextDouble() * size.height;
      
      // Horizontal flow based on offset and speed multiplier
      final x = (xBase - (offset * 1.5 * speedMult)) % size.width;
      
      // Draw elongated speed lines during movement, dots otherwise
      if (isAdvancing) {
        final lineLen = 15.0 + rnd.nextDouble() * 25.0;
        canvas.drawLine(
          Offset(x, y),
          Offset(x + lineLen, y),
          paint,
        );
      } else {
        canvas.drawCircle(Offset(x, y), 1.0, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _WindParticlePainter oldDelegate) => 
    oldDelegate.offset != offset || oldDelegate.isAdvancing != isAdvancing;
}

/// Displays 1-3 star icons based on tier value for monster difficulty indication.
class _TierStars extends StatelessWidget {
  final int tier;
  const _TierStars({required this.tier});

  @override
  Widget build(BuildContext context) {
    final stars = (tier < 3 ? 1 : tier < 8 ? 2 : 3);
    final color = tier < 3
        ? Colors.white54
        : tier < 8
            ? Colors.amber
            : Colors.orangeAccent;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(
        stars,
        (i) => Icon(Icons.star_rounded, size: 12, color: color),
      ),
    );
  }
}

/// Class Skill button with dynamic styling and cooldown tracking
class _ClassSkillButton extends StatelessWidget {
  final String name;
  final String icon;
  final Color color;
  final bool canUse;
  final double cooldownProgress;
  final int secondsLeft;
  final VoidCallback onPressed;

  const _ClassSkillButton({
    required this.name,
    required this.icon,
    required this.color,
    required this.canUse,
    required this.cooldownProgress,
    required this.secondsLeft,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          height: 48,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            boxShadow: canUse
                ? [
                    BoxShadow(
                      color: color.withValues(alpha: 0.4),
                      blurRadius: 10,
                      spreadRadius: 1,
                    ),
                  ]
                : null,
          ),
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: canUse ? color : Colors.grey.withValues(alpha: 0.3),
              foregroundColor: canUse ? Colors.white : Colors.white38,
              disabledBackgroundColor: Colors.grey.withValues(alpha: 0.2),
              disabledForegroundColor: Colors.white38,
              elevation: canUse ? 4 : 0,
            ),
            onPressed: canUse ? onPressed : null,
            icon: canUse
                ? Image.asset(icon, width: 18, height: 18, color: Colors.white, errorBuilder: (c,e,s) => const Icon(Icons.flash_on, size: 18))
                : const Icon(Icons.hourglass_empty, size: 18),
            label: Text(
              canUse ? name.toUpperCase() : '${secondsLeft}s',
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
            ),
          ),
        ),
        if (!canUse)
          Positioned(
            right: 6,
            top: 6,
            child: SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                value: cooldownProgress,
                strokeWidth: 2,
                backgroundColor: Colors.white12,
                color: color,
              ),
            ),
          ),
      ],
    );
  }
}

/// Styled defeat dialog with icon, step summary, and back action.
class _DefeatDialog extends StatelessWidget {
  final int step;
  final VoidCallback onConfirm;

  const _DefeatDialog({required this.step, required this.onConfirm});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFF1A0A0A),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.red.withValues(alpha: 0.4), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.red.withValues(alpha: 0.25),
              blurRadius: 32,
              spreadRadius: 4,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.red.withValues(alpha: 0.15),
                border: Border.all(color: Colors.red.withValues(alpha: 0.4), width: 1.5),
              ),
              child: const Icon(
                Icons.heart_broken_rounded,
                color: Colors.redAccent,
                size: 36,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Defeated',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'You fell on step $step.',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.6),
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                const Icon(Icons.terrain_rounded, size: 14, color: Colors.white38),
                const SizedBox(width: 6),
                Text(
                  'Furthest reached: Step $step',
                  style: const TextStyle(color: Colors.white38, fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF8B0000),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: onConfirm,
                icon: const Icon(Icons.arrow_back_rounded),
                label: const Text(
                  'Return to Hub',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
