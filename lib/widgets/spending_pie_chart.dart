import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/dummy_data.dart';
import '../providers/expense_store.dart';
import '../theme/app_colors.dart';

/// Donut wired to [ExpenseStore], rendered with fl_chart.
///
/// Two modes (toggled from Analytics):
/// - Totals: slice titles show compact XAF amounts, center shows the
///   full total (`=SUM` of all expenses).
/// - Percentages: slice titles show each category's share of total
///   expenses (`=category total / total`), center shows 100%.
/// A legend below names every slice ("this percent on this").
/// Empty store renders an honest empty state — never fake data.
class SpendingPieChart extends StatelessWidget {
  const SpendingPieChart({super.key, this.showPercentage = false});

  final bool showPercentage;

  static const _colors = [
    AppColors.primary,
    AppColors.success,
    AppColors.expense,
    AppColors.primaryFixedDim,
    AppColors.amber,
    AppColors.coral,
  ];

  /// Compact slice label: 1500 -> "1.5k", 25000 -> "25k".
  static String shortAmount(double amount) {
    if (amount >= 1000000) {
      final v = amount / 1000000;
      return '${v.toStringAsFixed(v >= 10 ? 0 : 1)}M';
    }
    if (amount >= 1000) {
      final v = amount / 1000;
      return '${v.toStringAsFixed(v >= 10 ? 0 : 1)}k';
    }
    return amount.toInt().toString();
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<ExpenseStore>();
    final totals = store.totalsByCategory();
    if (totals.isEmpty) {
      return const SizedBox(
        height: 200,
        child: Center(
          child: Text(
            'No spending yet',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ),
      );
    }
    final total = store.totalSpent;
    final entries = totals.entries.toList();
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 200,
          child: Stack(
            children: [
              PieChart(
                PieChartData(
                  centerSpaceRadius: 52,
                  sectionsSpace: 2,
                  sections: List.generate(entries.length, (i) {
                    final amount = entries[i].value;
                    final share =
                        total > 0 ? amount / total : 0.0;
                    return PieChartSectionData(
                      value: amount,
                      color: _colors[i % _colors.length],
                      radius: 36,
                      showTitle: true,
                      title: showPercentage
                          ? '${(share * 100).round()}%'
                          : shortAmount(amount),
                      titleStyle: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    );
                  }),
                ),
              ),
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      showPercentage
                          ? '100%'
                          : xafFormat.format(total),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      showPercentage ? 'of spending' : 'total spent',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        ...List.generate(entries.length, (i) {
          final id = entries[i].key;
          final amount = entries[i].value;
          final share = total > 0 ? amount / total : 0.0;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: _colors[i % _colors.length],
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    store.categoryName(id),
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                Text(
                  showPercentage
                      ? '${(share * 100).toStringAsFixed(1)}%'
                      : xafFormat.format(amount),
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}
