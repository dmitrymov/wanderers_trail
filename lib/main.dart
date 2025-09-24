import 'dart:async';

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

  final GameRepository repo = firestoreReady
      ? FirestoreGameRepository()
      : LocalGameRepository();

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
  int _index = 2; // Default to Battle tab.

  final _pages = const [
    ShopTab(),
    // CharacterTab(),
    BattleTab(),
    PetTab(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(child: _pages[_index]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.storefront), label: 'Shop'),
          // NavigationDestination(icon: Icon(Icons.person), label: 'Character'),
          NavigationDestination(icon: Icon(Icons.sports_esports), label: 'Battle'),
          NavigationDestination(icon: Icon(Icons.pets), label: 'Pet'),
        ],
      ),
    );
  }
}
