import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../screens/dashboard_shell.dart';
import '../screens/homepage_screen.dart';
import '../screens/splash_screen.dart';
import '../services/auth_service.dart';

/// Auth-gated navigation. Listens to [AuthService.authStateChanges] —
/// never a one-time check. Signed-out users land on the public Homepage
/// (marketing), never the Dashboard.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    return StreamBuilder<NdohUser?>(
      stream: auth.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SplashScreen();
        }
        if (snapshot.data != null) {
          return const DashboardShell();
        }
        return const HomepageScreen();
      },
    );
  }
}
