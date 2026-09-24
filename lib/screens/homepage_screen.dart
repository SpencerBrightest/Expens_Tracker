import 'package:flutter/material.dart';

import '../data/dummy_data.dart';
import '../theme/app_colors.dart';

/// Homepage: public marketing screen, NOT dashboard.
class HomepageScreen extends StatelessWidget {
  const HomepageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.account_balance_wallet_outlined,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Ndoh',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          'Smart Finance',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceLow,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: const Text(
                        'Live v2.4',
                        style: TextStyle(
                          color: AppColors.successDeep,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Total Monthly Outflow',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          xafFormat.format(dummyMonthTotal),
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.64,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(999),
                          child: const LinearProgressIndicator(
                            value: 0.68,
                            minHeight: 8,
                            backgroundColor: AppColors.surfaceHigh,
                            valueColor: AlwaysStoppedAnimation(
                              AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Track effortlessly.\nMaster your spending.',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                    letterSpacing: -0.64,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Ndoh gives you complete clarity over your monthly expenses, '
                  'budget limits, and financial habits with zero clutter.',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 16),
                ...const [
                  _ValueBadge(
                    icon: Icons.bolt_outlined,
                    title: 'Instant expense logging',
                    subtitle: 'Record daily payments in under 3 seconds',
                  ),
                  _ValueBadge(
                    icon: Icons.pie_chart_outline,
                    title: 'Smart category caps',
                    subtitle: 'Gentle guardrails that curb impulse splurges',
                  ),
                  _ValueBadge(
                    icon: Icons.insights_outlined,
                    title: 'Clean visual insights',
                    subtitle: 'Understand spending without spreadsheet dread',
                  ),
                ],
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: () =>
                      Navigator.pushReplacementNamed(context, '/auth'),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Get started'),
                      SizedBox(width: 8),
                      Icon(Icons.arrow_forward, size: 20),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: () =>
                      Navigator.pushReplacementNamed(context, '/auth'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.surfaceLow,
                    foregroundColor: AppColors.primary,
                  ),
                  child: const Text('Log in'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ValueBadge extends StatelessWidget {
  const _ValueBadge({
    required this.icon,
    required this.title,
    required this.subtitle,
  });
  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.surfaceContainer,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppColors.primary),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}
