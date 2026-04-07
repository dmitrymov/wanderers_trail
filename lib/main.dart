// App Architecture:
// The app follows a clean architecture pattern with separation of concerns.
// - Data Layer: Handles data operations, including local and Firestore storage.
// - Business Logic Layer: Manages game state and business rules.
// - UI Layer: Presents the user interface and handles user interactions.
// - Providers: Used for state management and dependency injection.

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'src/ui/theme/app_theme.dart';

import 'src/data/repositories/game_repository.dart';
import 'src/data/repositories/local_game_repository.dart';
import 'src/data/repositories/firestore_game_repository.dart';
import 'src/state/game_state.dart';
import 'src/ui/tabs/battle_tab.dart';
import 'src/ui/tabs/character_tab.dart';
import 'src/ui/tabs/pet_tab.dart';
import 'src/ui/tabs/shop_tab.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  bool firestoreReady = false;
  try {
    // Will succeed only if Firebase is configured (google-services files added).
    await Firebase.initializeApp();
    firestoreReady = true;
  } catch (_) {
    firestoreReady = false;
  }

  final GameRepository repo =
      firestoreReady ? FirestoreGameRepository() : LocalGameRepository();

  runApp(
    MultiProvider(
      providers: [
        Provider<GameRepository>.value(value: repo),
        ChangeNotifierProvider<GameState>(
          create: (ctx) => GameState(repo)..init(),
        ),
      ],
      child: const WanderersApp(),
    ),
  );
}

class WanderersApp extends StatelessWidget {
  const WanderersApp({super.key});
  static final navigatorKey = GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: "Wanderer's Trail",
      theme: buildAppTheme(Brightness.light),
      darkTheme: buildAppTheme(Brightness.dark),
      themeMode: ThemeMode.light,
      home: const HomeScaffold(),
    );
  }
}

class HomeScaffold extends StatefulWidget {
  const HomeScaffold({super.key});

  @override
  State<HomeScaffold> createState() => _HomeScaffoldState();
}

class _HomeScaffoldState extends State<HomeScaffold> {
  int _index = 2; // Default to Battle tab (0=Shop, 1=Character, 2=Battle, 3=Pet).

  final _pages = const [
    ShopTab(),
    CharacterTab(),
    BattleTab(),
    PetTab(),
  ];

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      extendBody: true,
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFFF0F8F7), // Ultra Soft Mint
                  scheme.surface,
                  const Color(0xFFF9FFF8), // Crystal White
                ],
                stops: const [0.0, 0.5, 1.0],
              ),
            ),
          ),
          SafeArea(
            child: _pages[_index],
          ),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: scheme.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: NavigationBar(
            selectedIndex: _index,
            onDestinationSelected: (i) => setState(() => _index = i),
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.storefront_outlined),
                selectedIcon: Icon(Icons.storefront),
                label: 'Shop',
              ),
              NavigationDestination(
                icon: Icon(Icons.person_outline),
                selectedIcon: Icon(Icons.person),
                label: 'Hero',
              ),
              NavigationDestination(
                icon: Icon(Icons.sports_esports_outlined),
                selectedIcon: Icon(Icons.sports_esports),
                label: 'Battle',
              ),
              NavigationDestination(
                icon: Icon(Icons.pets_outlined),
                selectedIcon: Icon(Icons.pets),
                label: 'Pet',
              ),
            ],
          ),
        ),
      ),
    );
  }
}