enum Difficulty {
  easy,
  normal,
  hard,
}

extension DifficultyX on Difficulty {
  // 0-based max variant index: easy=0, normal=1, hard=2
  int get maxVariantIndex => index;
  // 1-based tier for human-readable mapping: easy=1, normal=2, hard=3
  int get tier => index + 1;
}
