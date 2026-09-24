import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/expense_store.dart';
import '../theme/app_colors.dart';

/// Donut wired to [ExpenseStore]. Empty store renders an honest empty
/// state — never fake data.
class SpendingPieChart extends StatelessWidget {
  const SpendingPieChart({super.key});

  static const _colors = [
    AppColors.primary,
    AppColors.success,
    AppColors.expense,
    AppColors.primaryFixedDim,
    AppColors.amber,
    AppColors.coral,
  ];

  @override
  Widget build(BuildContext context) {
    final totals = context.watch<ExpenseStore>().totalsByCategory();
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
    final entries = totals.entries.toList();
    return SizedBox(
      height: 200,
      child: PieChart(
        PieChartData(
          centerSpaceRadius: 52,
          sectionsSpace: 2,
          sections: List.generate(entries.length, (i) {
            return PieChartSectionData(
              value: entries[i].value,
              color: _colors[i % _colors.length],
              radius: 36,
              showTitle: false,
            );
          }),
        ),
      ),
    );
  }
}
