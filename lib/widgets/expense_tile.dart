import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../data/dummy_data.dart';
import '../models/expense.dart';
import '../providers/expense_store.dart';
import '../theme/app_colors.dart';
import '../theme/category_icons.dart';

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

  /// Builds a tile from store state (category lookup + XAF formatting).
  factory ExpenseTile.forExpense(BuildContext context, Expense expense) {
    final store = context.watch<ExpenseStore>();
    final cat = store.categoryFor(expense);
    final date = DateFormat('MMM d, y').format(expense.date);
    return ExpenseTile(
      title: expense.note,
      subtitle: '${cat.name} • $date',
      amountLabel: xafFormat.format(expense.amount),
      isIncome: false,
      icon: categoryIcon(cat.iconCodePoint),
      color: Color(cat.colorValue),
    );
  }

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
