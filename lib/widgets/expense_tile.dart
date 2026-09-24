import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Shared transaction row: 44px avatar, title + meta, right XAF amount.
class ExpenseTile extends StatelessWidget {
  const ExpenseTile({
    super.key,
    required this.title,
    required this.subtitle,
    required this.amountLabel,
    required this.isIncome,
    required this.icon,
    required this.color,
  });
  final String title;
  final String subtitle;
  final String amountLabel;
  final bool isIncome;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 4,
        ),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12,
          ),
        ),
        trailing: Text(
          amountLabel,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: isIncome ? AppColors.success : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}
