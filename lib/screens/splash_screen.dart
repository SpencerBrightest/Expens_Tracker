import 'dart:async';

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Splash: Stitch reference + 3 large solid dots centered near bottom.
/// Animation in Flutter: Timer 450ms, scale 1.2/0.8, opacity 1/0.4.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  int _active = 0;
  late final Timer _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 450), (_) {
      if (mounted) setState(() => _active = (_active + 1) % 3);
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(flex: 3),
            Center(
              child: Column(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(
                      Icons.account_balance_wallet_outlined,
                      size: 44,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Ndoh',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.64,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'SMART EXPENSE TRACKER',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 2.0,
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(flex: 3),
            // 3 large solid dots centered near bottom
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(3, (i) {
                final active = i == _active;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 6),
                  width: 12,
                  height: 12,
                  transform: Matrix4.identity()
                    ..scaleByDouble(
                      active ? 1.2 : 0.8,
                      active ? 1.2 : 0.8,
                      active ? 1.2 : 0.8,
                      1.0,
                    ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(
                      alpha: active ? 1.0 : 0.4,
                    ),
                    shape: BoxShape.circle,
                  ),
                );
              }),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
