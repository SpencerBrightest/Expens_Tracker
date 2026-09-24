import 'package:flutter/material.dart';

import 'screens/auth_screen.dart';
import 'screens/dashboard_shell.dart';
import 'screens/homepage_screen.dart';
import 'screens/splash_screen.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const NdohApp());
}

/// Ndoh root. Phase 1 uses temp bool gate; Phase 5 replaces with
/// authStateChanges() stream via AuthService.
class NdohApp extends StatefulWidget {
  const NdohApp({super.key});

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
    return MaterialApp(
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
    );
  }
}
