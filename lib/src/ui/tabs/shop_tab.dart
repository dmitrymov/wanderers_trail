import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../theme/tokens.dart';
import '../../state/game_state.dart';
import '../../data/models/hero_class.dart';
import '../widgets/panel.dart';

class ShopTab extends StatelessWidget {
  const ShopTab({super.key});

  @override
  Widget build(BuildContext context) {
    final gs = context.watch<GameState>();
    final scheme = Theme.of(context).colorScheme;

    final healthCost = gs.permanentUpgradeCost(PermanentUpgrade.health);
    final staminaCost = gs.permanentUpgradeCost(PermanentUpgrade.stamina);
    final attackCost = gs.permanentUpgradeCost(PermanentUpgrade.attack);
    final defenseCost = gs.permanentUpgradeCost(PermanentUpgrade.defense);
    final speedCost = gs.permanentUpgradeCost(PermanentUpgrade.speed);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
      children: [
        Text(
          'Shop',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w900,
                color: Theme.of(context).colorScheme.onSurface,
              ),
        ),
        const SizedBox(height: 16),
        _ShopHeader(diamonds: gs.diamonds, coins: gs.profile.coins, keys: gs.profile.equipmentKeys),
        const SizedBox(height: 24),
        
        _SectionHeader(title: 'PREMIUM ENHANCEMENTS', color: scheme.primary),
        const SizedBox(height: 8),
        const Text(
          'Permanent upgrades that persist across all future runs.',
          style: TextStyle(
            fontSize: 12,
            color: Color(0xFF2D2E30), // Solid deep grey for high contrast
            fontWeight: FontWeight.w800,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 16),

        _ShopUpgradeCard(
          title: 'Imperial Vigor',
          subtitle: 'Max Health +${GameState.permHealthStep} (Level ${gs.permHealthLevel})',
          icon: Icons.favorite_rounded,
          iconColor: Colors.redAccent,
          cost: healthCost,
          canAfford: gs.diamonds >= healthCost,
          onPressed: () => gs.purchasePermanent(PermanentUpgrade.health),
        ),
        const SizedBox(height: 12),
        
        _ShopUpgradeCard(
          title: 'Endless Breath',
          subtitle: 'Max Stamina +${GameState.permStaminaStep} (Level ${gs.permStaminaLevel})',
          icon: Icons.bolt_rounded,
          iconColor: Colors.amberAccent,
          cost: staminaCost,
          canAfford: gs.diamonds >= staminaCost,
          onPressed: () => gs.purchasePermanent(PermanentUpgrade.stamina),
        ),
        const SizedBox(height: 12),

        _ShopUpgradeCard(
          title: 'Slayer\'s Edge',
          subtitle: 'Base Attack +${GameState.permAttackStep} (Level ${gs.permAttackLevel})',
          icon: Icons.flash_on_rounded,
          iconColor: Colors.orangeAccent,
          cost: attackCost,
          canAfford: gs.diamonds >= attackCost,
          onPressed: () => gs.purchasePermanent(PermanentUpgrade.attack),
        ),
        const SizedBox(height: 12),

        _ShopUpgradeCard(
          title: 'Titan\'s Resolve',
          subtitle: 'Base Defense +${GameState.permDefenseStep} (Level ${gs.permDefenseLevel})',
          icon: Icons.shield_rounded,
          iconColor: Colors.blueAccent,
          cost: defenseCost,
          canAfford: gs.diamonds >= defenseCost,
          onPressed: () => gs.purchasePermanent(PermanentUpgrade.defense),
        ),
        const SizedBox(height: 12),

        _ShopUpgradeCard(
          title: 'Chronos Blessing',
          subtitle: 'Max Combat Speed +${GameState.permSpeedStep.toStringAsFixed(1)}x (Level ${gs.profile.permSpeedLevel})',
          icon: Icons.speed_rounded,
          iconColor: Colors.cyanAccent,
          cost: speedCost,
          canAfford: gs.diamonds >= speedCost,
          onPressed: () => gs.purchasePermanent(PermanentUpgrade.speed),
        ),
        _ChestSection(gs: gs),
        const SizedBox(height: 32),

        _CurrencySection(gs: gs),
        const SizedBox(height: 32),
        
        _SectionHeader(title: 'HERO CLASSES', color: scheme.primary),
        const SizedBox(height: 8),
        const Text(
          'Unlock specialized classes with unique passive bonuses.',
          style: TextStyle(fontSize: 12, color: Colors.black45, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 16),
        ...HeroClass.allClasses().where((c) => c.id != 'survivor').map((c) {
          final isUnlocked = gs.profile.unlockedClassIds.contains(c.id);
          return Column(
            children: [
              _ClassPurchaseCard(
                heroClass: c,
                isUnlocked: isUnlocked,
                gs: gs,
              ),
              const SizedBox(height: 12),
            ],
          );
        }),
        
        if (kDebugMode) ...[
          const SizedBox(height: 32),
          const _SectionHeader(title: 'DEVELOPER TOOLS'),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => gs.addDiamonds(100),
            icon: const Icon(Icons.bug_report_rounded, size: 18),
            label: const Text('Add 100 Diamonds'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white38,
              side: const BorderSide(color: Colors.white10),
            ),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () => gs.addKeys(5),
            icon: const Icon(Icons.bug_report_rounded, size: 18),
            label: const Text('Add 5 Keys'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white38,
              side: const BorderSide(color: Colors.white10),
            ),
          ),
        ],
      ],
    );
  }
}

class _ChestSection extends StatelessWidget {
  final GameState gs;
  const _ChestSection({required this.gs});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(title: 'EQUIPMENT CHESTS', color: scheme.primary),
        const SizedBox(height: 8),
        Row(
          children: [
            const Icon(Icons.vpn_key_rounded, size: 16, color: Colors.amberAccent),
            const SizedBox(width: 8),
            Text(
              'Keys: ${gs.profile.equipmentKeys}',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Colors.amberAccent),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _ChestCard(
          title: 'Regular Chest',
          subtitle: 'Contains Uncommon to Legendary gear.',
          icon: Icons.inventory_2_rounded,
          iconColor: Colors.brown,
          diamondCost: 50,
          keyCost: 1,
          gs: gs,
          type: 'regular',
        ),
        const SizedBox(height: 12),
        _ChestCard(
          title: 'Epic Chest',
          subtitle: 'Higher chance for Legendary or Mystic gear.',
          icon: Icons.auto_awesome_motion_rounded,
          iconColor: Colors.deepPurpleAccent,
          diamondCost: 150,
          gs: gs,
          type: 'epic',
        ),
      ],
    );
  }
}

class _ChestCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final int diamondCost;
  final int? keyCost;
  final GameState gs;
  final String type;

  const _ChestCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.diamondCost,
    this.keyCost,
    required this.gs,
    required this.type,
  });

  @override
  Widget build(BuildContext context) {
    final canAffordDiamonds = gs.diamonds >= diamondCost;
    final canAffordKey = keyCost != null && gs.profile.equipmentKeys >= keyCost!;

    return Panel(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                    Text(subtitle, style: const TextStyle(fontSize: 11, color: Colors.black45)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _ChestButton(
                  label: diamondCost.toString(),
                  icon: Icons.diamond_rounded,
                  color: Colors.cyanAccent,
                  enabled: canAffordDiamonds,
                  onPressed: () {
                    final item = gs.openChest(type);
                    if (item != null) _showReward(context, item);
                  },
                ),
              ),
              if (keyCost != null) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: _ChestButton(
                    label: '${keyCost!} Key',
                    icon: Icons.vpn_key_rounded,
                    color: Colors.amberAccent,
                    enabled: canAffordKey,
                    onPressed: () {
                      final item = gs.openChest(type, useKey: true);
                      if (item != null) _showReward(context, item);
                    },
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  void _showReward(BuildContext context, dynamic item) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New Equipment!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.military_tech_rounded, size: 64, color: Colors.amber),
            const SizedBox(height: 16),
            Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            Text(item.rarity.toString().split('.').last.toUpperCase(), style: TextStyle(color: Colors.amber[700], fontWeight: FontWeight.w900)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Awesome!')),
        ],
      ),
    );
  }
}

class _ChestButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool enabled;
  final VoidCallback onPressed;

  const _ChestButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.enabled,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: enabled ? onPressed : null,
      style: FilledButton.styleFrom(
        backgroundColor: color.withValues(alpha: 0.1),
        foregroundColor: color,
        disabledBackgroundColor: Colors.black12,
        disabledForegroundColor: Colors.black26,
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w900)),
          const SizedBox(width: 8),
          Icon(icon, size: 16),
        ],
      ),
    );
  }
}

class _ShopHeader extends StatelessWidget {
  final int diamonds;
  final int coins;
  final int keys;
  const _ShopHeader({required this.diamonds, required this.coins, required this.keys});

  @override
  Widget build(BuildContext context) {
    return Panel(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Text(
            'THE ROYAL SHOP',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w900,
              letterSpacing: 4,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _CurrencyDisplay(
                value: diamonds,
                icon: Icons.diamond_rounded,
                color: Colors.cyanAccent,
                label: 'DIAMONDS',
              ),
              const SizedBox(width: 32),
              _CurrencyDisplay(
                value: coins,
                icon: Icons.monetization_on_rounded,
                color: Colors.amberAccent,
                label: 'COINS',
              ),
              const SizedBox(width: 32),
              _CurrencyDisplay(
                value: keys,
                icon: Icons.vpn_key_rounded,
                color: Colors.amber,
                label: 'KEYS',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CurrencyDisplay extends StatelessWidget {
  final int value;
  final IconData icon;
  final Color color;
  final String label;

  const _CurrencyDisplay({
    required this.value,
    required this.icon,
    required this.color,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(width: 8),
            Text(
              value.toString(),
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ],
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            color: color.withValues(alpha: 0.5),
            letterSpacing: 1.5,
          ),
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final Color? color;
  const _SectionHeader({required this.title, this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
            color: color ?? Colors.white70,
          ),
        ),
        const SizedBox(width: 12),
        const Expanded(child: Divider(color: Colors.white10)),
      ],
    );
  }
}

class _ShopUpgradeCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final int cost;
  final bool canAfford;
  final VoidCallback onPressed;

  const _ShopUpgradeCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.cost,
    required this.canAfford,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Panel(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: AppTokens.panelOpacity),
              borderRadius: BorderRadius.circular(AppTokens.r12),
              border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
            ),
            child: Icon(icon, color: iconColor, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 11,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            height: 44,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: canAfford 
                    ? Colors.cyanAccent.withValues(alpha: 0.15) 
                    : Colors.white10,
                foregroundColor: canAfford ? Colors.cyanAccent : Colors.white24,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                side: BorderSide(
                  color: canAfford ? Colors.cyanAccent.withValues(alpha: 0.3) : Colors.transparent,
                ),
              ),
              onPressed: canAfford 
                  ? () {
                      HapticFeedback.lightImpact();
                      onPressed();
                    } 
                  : null,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    cost.toString(),
                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                  ),
                  const SizedBox(width: 6),
                  const Icon(Icons.diamond_rounded, size: 14),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ClassPurchaseCard extends StatelessWidget {
  final HeroClass heroClass;
  final bool isUnlocked;
  final GameState gs;

  const _ClassPurchaseCard({
    required this.heroClass,
    required this.isUnlocked,
    required this.gs,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final useDiamonds = heroClass.diamondCost > 0;
    final cost = useDiamonds ? heroClass.diamondCost : heroClass.coinCost;
    final canAfford = useDiamonds 
        ? gs.diamonds >= heroClass.diamondCost 
        : gs.profile.coins >= heroClass.coinCost;

    return Panel(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.black12),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Opacity(
                opacity: isUnlocked ? 1.0 : 0.6,
                child: Image.asset(heroClass.imageAsset, fit: BoxFit.cover),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  heroClass.name,
                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Color(0xFF1A1C1E)),
                ),
                const SizedBox(height: 2),
                Text(
                  heroClass.description,
                  style: const TextStyle(fontSize: 11, color: Colors.black45),
                ),
                const SizedBox(height: 4),
                _ClassBonusesMiniRow(heroClass: heroClass),
              ],
            ),
          ),
          const SizedBox(width: 12),
          if (isUnlocked)
            Icon(Icons.check_circle_rounded, color: scheme.primary)
          else
            SizedBox(
              height: 36,
              child: FilledButton(
                onPressed: canAfford ? () => gs.unlockClass(heroClass.id, cost, useDiamonds) : null,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  backgroundColor: scheme.primary.withValues(alpha: 0.1),
                  foregroundColor: scheme.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(cost.toString(), style: const TextStyle(fontWeight: FontWeight.w900)),
                    const SizedBox(width: 4),
                    Icon(useDiamonds ? Icons.diamond_rounded : Icons.monetization_on_rounded, size: 14),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ClassBonusesMiniRow extends StatelessWidget {
  final HeroClass heroClass;
  const _ClassBonusesMiniRow({required this.heroClass});

  @override
  Widget build(BuildContext context) {
    List<String> b = [];
    if (heroClass.healthBonus != 0) b.add('HP +${heroClass.healthBonus}');
    if (heroClass.staminaBonus != 0) b.add('STM +${heroClass.staminaBonus}');
    if (heroClass.attackBonus != 0) b.add('ATK +${heroClass.attackBonus}');
    if (heroClass.defenseBonus != 0) b.add('DEF ${heroClass.defenseBonus > 0 ? "+" : ""}${heroClass.defenseBonus}');
    if (heroClass.speedBonus != 0) b.add('SPD +${heroClass.speedBonus}x');

    return Text(
      b.join(' • '),
      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF49454F)),
    );
  }
}

class _CurrencySection extends StatelessWidget {
  final GameState gs;
  const _CurrencySection({required this.gs});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(title: 'CURRENCY VAULT', color: scheme.primary),
        const SizedBox(height: 8),
        const Text(
          'Top up your resources to unlock permanent upgrades and relics.',
          style: TextStyle(fontSize: 12, color: Colors.black45, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 16),
        
        Text('DIAMOND BUNDLES', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: scheme.primary, letterSpacing: 1.0)),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _CurrencyCard(gs: gs, type: 'diamonds', amount: 50, price: '\$0.99')),
            const SizedBox(width: 12),
            Expanded(child: _CurrencyCard(gs: gs, type: 'diamonds', amount: 200, price: '\$2.99', isPopular: true)),
            const SizedBox(width: 12),
            Expanded(child: _CurrencyCard(gs: gs, type: 'diamonds', amount: 1000, price: '\$9.99')),
          ],
        ),
        
        const SizedBox(height: 24),
        Text('GOLD PACKS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: scheme.primary, letterSpacing: 1.0)),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _CurrencyCard(gs: gs, type: 'coins', amount: 200, price: '\$0.99')),
            const SizedBox(width: 12),
            Expanded(child: _CurrencyCard(gs: gs, type: 'coins', amount: 1000, price: '\$3.99')),
            const SizedBox(width: 12),
            Expanded(child: _CurrencyCard(gs: gs, type: 'coins', amount: 5000, price: '\$14.99', isPopular: true)),
          ],
        ),
      ],
    );
  }
}

class _CurrencyCard extends StatelessWidget {
  final GameState gs;
  final String type;
  final int amount;
  final String price;
  final bool isPopular;

  const _CurrencyCard({
    required this.gs,
    required this.type,
    required this.amount,
    required this.price,
    this.isPopular = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDiamonds = type == 'diamonds';
    final tokenColor = isDiamonds ? Colors.cyanAccent : Colors.amberAccent;
    final tokenIcon = isDiamonds ? Icons.diamond_rounded : Icons.monetization_on_rounded;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Panel(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
          child: Column(
            children: [
              Icon(tokenIcon, color: tokenColor, size: 32),
              const SizedBox(height: 8),
              Text(
                amount.toString(),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 32,
                child: FilledButton(
                  onPressed: () {
                    // Mock purchase logic for debug
                    gs.buyCurrencyPack(type, amount);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Purchased $amount ${isDiamonds ? "Diamonds" : "Gold"}!'),
                        backgroundColor: Colors.green,
                        duration: const Duration(seconds: 1),
                      ),
                    );
                  },
                  style: FilledButton.styleFrom(
                    padding: EdgeInsets.zero,
                    backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                    foregroundColor: Theme.of(context).colorScheme.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: Text(price, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900)),
                ),
              ),
            ],
          ),
        ),
        if (isPopular)
          Positioned(
            top: -10,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.orange,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'BEST VALUE',
                  style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w900),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
