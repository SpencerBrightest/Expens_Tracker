import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../screens/auth_screen.dart';
import '../screens/dashboard_shell.dart';
import '../screens/splash_screen.dart';
import '../services/auth_service.dart';

/// Auth-gated navigation. Listens to [AuthService.authStateChanges] —
/// never a one-time check. Signed-out users land on Login, never Dashboard.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthService>();
    return StreamBuilder<NdohUser?>(
      stream: auth.authStateChanges,
      initialData: auth.currentUser,
      builder: (context, snapshot) {
        if (snapshot.data != null) {
          return const DashboardShell();
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SplashScreen();
        }
        return const AuthScreen();
      },
    );
  }
}
