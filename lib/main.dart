import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'data/dummy_data.dart';
import 'models/category.dart';
import 'providers/expense_store.dart';
import 'screens/auth_screen.dart';
import 'screens/dashboard_shell.dart';
import 'screens/homepage_screen.dart';
import 'screens/splash_screen.dart';
import 'theme/app_theme.dart';

/// Seed Category models from Stitch dummy data (cached in Provider per
/// AGENTS perf rule — never refetched per screen).
List<Category> seedCategories() => [
      for (var i = 0; i < dummyCategories.length; i++)
        Category(
          id: 'c${i + 1}',
          name: dummyCategories[i].name,
          monthlyLimit: dummyCategories[i].limit,
          colorValue: dummyCategories[i].color.toARGB32(),
          iconCodePoint: dummyCategories[i].icon.codePoint,
        ),
    ];

void main() {
  runApp(NdohApp(store: ExpenseStore(categories: seedCategories())));
}

/// Ndoh root. Phase 1 uses temp bool gate; Phase 5 replaces with
/// authStateChanges() stream via AuthService.
class NdohApp extends StatefulWidget {
  const NdohApp({super.key, this.store});

  final ExpenseStore? store;

  @override
  State<NdohApp> createState() => _NdohAppState();
}

class _NdohAppState extends State<NdohApp> {
  bool _splashDone = false;
  final bool _loggedIn = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _splashDone = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<ExpenseStore>.value(
      value: widget.store ?? ExpenseStore(categories: seedCategories()),
      child: MaterialApp(
      title: 'Ndoh',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      home: _splashDone
          ? (_loggedIn ? const DashboardShell() : const HomepageScreen())
          : const SplashScreen(),
      routes: {
        '/home': (_) => const HomepageScreen(),
        '/auth': (_) => const AuthScreen(),
        '/dashboard': (_) => const DashboardShell(),
      },
      ),
    );
  }
}
