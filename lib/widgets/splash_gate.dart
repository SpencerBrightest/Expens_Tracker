import 'dart:async';

import 'package:flutter/material.dart';

import '../screens/splash_screen.dart';
import 'auth_gate.dart';

/// Cold-start gate: shows the custom Ndoh [SplashScreen] for [duration],
/// then hands off to [AuthGate] (which listens to authStateChanges and
/// routes signed-out users to Login, signed-in users to Dashboard).
class SplashGate extends StatefulWidget {
  const SplashGate({super.key, this.duration = const Duration(seconds: 2)});

  final Duration duration;

  @override
  State<SplashGate> createState() => _SplashGateState();
}

class _SplashGateState extends State<SplashGate> {
  bool _done = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(widget.duration, () {
      if (mounted) setState(() => _done = true);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_done) return const AuthGate();
    return const SplashScreen();
  }
}
