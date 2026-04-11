import 'item.dart';

/// Returns the display label for a given [ItemStatType].
String statTypeLabel(ItemStatType t) {
  switch (t) {
    case ItemStatType.attack:
      return 'Attack';
    case ItemStatType.defense:
      return 'Defense';
    case ItemStatType.accuracy:
      return 'Accuracy';
    case ItemStatType.agility:
      return 'Agility';
    case ItemStatType.critChance:
      return 'Crit Chance';
    case ItemStatType.critDamage:
      return 'Crit Damage';
    case ItemStatType.health:
      return 'Health';
    case ItemStatType.evasion:
      return 'Evasion';
    case ItemStatType.stamina:
      return 'Stamina';
    case ItemStatType.staminaCostReduction:
      return 'Stamina Cost Reduction';
  }
}

/// Returns true when [t] should be displayed as a percentage.
bool statTypeIsPercent(ItemStatType t) {
  switch (t) {
    case ItemStatType.accuracy:
    case ItemStatType.critChance:
    case ItemStatType.critDamage:
    case ItemStatType.evasion:
    case ItemStatType.staminaCostReduction:
      return true;
    default:
      return false;
  }
}

/// Formats a single stat entry as a human-readable string with a "+" prefix.
/// Example: "Crit Chance +5%" or "Agility +3.0"
String formatStatEntry(ItemStatType t, double v) {
  final label = statTypeLabel(t);
  if (statTypeIsPercent(t)) {
    return '$label +${(v * 100).toStringAsFixed(0)}%';
  } else {
    return '$label +${v.toStringAsFixed(v % 1 == 0 ? 0 : 1)}';
  }
}

/// Returns the base stat description for the equipped [item]'s primary stat.
String itemBaseStat(Item item) {
  switch (item.type) {
    case ItemType.weapon:
      return 'Attack +${item.power}';
    case ItemType.armor:
      return 'Defense +${item.power}';
    case ItemType.ring:
      return 'Accuracy +${item.power}';
    case ItemType.boots:
      return 'Defense +${item.power}';
  }
}

/// Maps [ItemRarity] to a display colour value (ARGB int).
/// Use as `Color(rarityColorValue(r))`.
int rarityColorValue(ItemRarity? r) {
  switch (r) {
    case ItemRarity.uncommon:
      return 0xFF4CAF50; // green
    case ItemRarity.rare:
      return 0xFF2196F3; // blue
    case ItemRarity.legendary:
      return 0xFFFFD700; // gold
    case ItemRarity.mythic:
      return 0xFFF44336; // red accent
    case ItemRarity.normal:
    default:
      return 0x99FFFFFF; // white70
  }
}
