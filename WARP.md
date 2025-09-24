# WARP.md

This file provides guidance to WARP (warp.dev) when working with code in this repository.

Project: Wanderer's Trail (Flutter)

Common commands (PowerShell on Windows)
- Install dependencies
```powershell path=null start=null
flutter pub get
```
- Run the app (Windows)
```powershell path=null start=null
flutter run -d windows
```
- Build release binaries
```powershell path=null start=null
# Windows
flutter build windows
# Web
flutter build web
# Android APK (if Android SDK/tools are set up)
flutter build apk --release
```
- Lint (static analysis)
```powershell path=null start=null
flutter analyze
```
- Format code
```powershell path=null start=null
dart format lib test
```
- Run all tests
```powershell path=null start=null
flutter test
```
- Run a single test file
```powershell path=null start=null
flutter test test/widget_test.dart
```
- Run a test by name pattern
```powershell path=null start=null
flutter test --name "App builds"
```
- Regenerate launcher icons (configured in pubspec.yaml)
```powershell path=null start=null
dart run flutter_launcher_icons
```
- Regenerate native splash screen (configured in pubspec.yaml)
```powershell path=null start=null
dart run flutter_native_splash:create
```

Architecture overview
- App entry and DI
  - lib/main.dart bootstraps Flutter, tries Firebase.initializeApp(); if Firebase isn’t configured, it falls back to a local storage repository.
  - Uses Provider for simple dependency injection:
    - Provides a GameRepository (either FirestoreGameRepository or LocalGameRepository).
    - Provides GameState as a ChangeNotifier driving the app state.
  - HomeScaffold hosts four tabs via NavigationBar: Shop, Character, Battle, and Pet.

- State management (GameState)
  - File: lib/src/state/game_state.dart
  - Responsibilities:
    - Loads/saves PlayerProfile through the injected GameRepository.
    - Manages gameplay state: stamina regen timer, combat activity flag, temporary “Blessing of Vigor” buff, coin and stat updates, save/checkpoint logic.
    - Aggregates equipment into StatsSummary with a small cache invalidated on equipment changes.
    - Scans AssetManifest.json at startup to:
      - Collect weapon image assets (assets/images/weapons/...).
      - Group enemy image variants by type from assets/images/enemies/...
        - Grouping uses folder name (enemies/<type>/...) when present; otherwise base filename without trailing digits.
      - Exposes enemyVariantPaths/count and a pickEnemyImage(type, difficultyIndex) helper used by combat.

- Data layer (Repository pattern)
  - GameRepository defines loadProfile/saveProfile.
  - LocalGameRepository persists the profile via shared_preferences (single local userId: "local").
  - FirestoreGameRepository persists under collection profiles/<userId> using cloud_firestore.
  - Selection happens at startup in main.dart based on whether Firebase.initializeApp() succeeds.

- Domain models
  - PlayerProfile contains the player’s core stats, equipment (weapon/armor/ring/boots), selectedPetId, and savedStep for continuing runs.
  - Item defines item types, rarity, and stat map; Item.randomDrop(runScore) generates drops and, for weapons, picks a sprite path using a naming convention.
    - Weapon sprite naming convention: assets/images/weapons/{category}_{rarityDigit}{id}.png
      - rarityDigit: normal=0, uncommon=1, rare=2, legendary=3, mystic=4
  - Pet offers starterPets constants with stamina regeneration bonuses.
  - StatsSummary aggregates equipped items into effective combat stats (attack, defense, accuracy/evasion, crit, attack speed, DPS).

- UI composition
  - Tabs under lib/src/ui/tabs: ShopTab (demo coin updates), CharacterTab (view equipment and computed stats with upgrade actions), BattleTab (step-forward loop with random encounters and auto-combat), PetTab (select starter pet).
  - Battle flow (ActiveBattlePage):
    - Advancing consumes stamina (reduced by equipment); when exhausted, steps drain HP.
    - Random encounters trigger auto-combat timers with hit/crit/evasion and DoT effects; on victory, maybeDrop() or a temporary blessing is granted.
    - Progress autosaves every 5 steps; visual “checkpoint” every 50 steps; defeat returns to tabs.
  - OverlayService uses a global navigatorKey to show transient toasts atop the UI.
  - Theme tokens in lib/src/ui/theme define consistent M3 styling.

- Graphics helpers (Flame integration)
  - lib/src/graphics provides Difficulty and EnemySpriteLoader (Flame Sprite utilities) that load enemy sprites by difficulty or randomly within a difficulty using paths exposed by GameState.

Platform and assets notes
- Assets are declared in pubspec.yaml under assets/images/, assets/config/monsters.json, etc. Add new folders/files there if you introduce new assets.
- Firebase usage is optional for development. Without platform Firebase config files, the app falls back to LocalGameRepository. To enable Firestore persistence, add standard Firebase config files for each platform (e.g., google-services.json on Android, GoogleService-Info.plist on iOS/macOS) and ensure firebase_core/cloud_firestore are initialized correctly.

Testing
- Current tests: a basic widget smoke test in test/widget_test.dart that pumps WanderersApp and checks for NavigationBar.
- Use the commands above to run the whole suite or target individual tests.

Referenced files worth knowing
- README.md: Default Flutter template (no additional project-specific instructions today).
- analysis_options.yaml: Includes flutter_lints (use flutter analyze as shown above).
